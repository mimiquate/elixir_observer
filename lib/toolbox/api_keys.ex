defmodule Toolbox.ApiKeys do
  alias Toolbox.{ApiKey, Repo}
  import Ecto.Query

  @prefix "obs_"
  @alphabet "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  @length 30

  def list_api_keys(user_id) do
    from(k in ApiKey,
      where: k.user_id == ^user_id,
      order_by: [desc: k.inserted_at, desc: k.id]
    )
    |> Repo.all()
  end

  def change_api_key(user_id, attrs \\ %{}) do
    ApiKey.changeset(%ApiKey{user_id: user_id}, attrs)
  end

  @doc """
  Creates an API key for the user.
  Returns {:ok, api_key, token} or {:error, changeset}.
  The token is only available here; only its SHA-256 hash is stored.
  """
  def create_api_key(user_id, attrs) do
    random = Nanoid.generate(@length, @alphabet)
    token = @prefix <> random

    user_id
    |> change_api_key(attrs)
    |> Ecto.Changeset.put_change(:key_hash, hash(token))
    |> Ecto.Changeset.put_change(:key_first_chars, String.slice(random, 0, 4))
    |> Ecto.Changeset.put_change(:key_last_chars, String.slice(random, -4, 4))
    |> Repo.insert()
    |> case do
      {:ok, api_key} -> {:ok, api_key, token}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Authenticates an API key token and records its last use.
  Returns {:ok, user} for the key's owner or :error for an unknown key.
  """
  def authenticate(token) do
    hash = hash(token)

    query =
      from(k in ApiKey,
        join: u in assoc(k, :user),
        where: k.key_hash == ^hash,
        preload: [user: u]
      )

    case Repo.one(query) do
      nil ->
        :error

      api_key ->
        {:ok, _api_key} =
          api_key
          |> Ecto.Changeset.change(last_used_at: DateTime.utc_now(:second))
          |> Repo.update()

        {:ok, api_key.user}
    end
  end

  @doc """
  Revokes (deletes) one of the user's API keys.
  Returns :ok, or {:error, :not_found} when the key does not exist or belongs to another user.
  """
  def revoke_api_key(user_id, api_key_id) do
    case Repo.get_by(ApiKey, id: api_key_id, user_id: user_id) do
      nil ->
        {:error, :not_found}

      api_key ->
        {:ok, _api_key} = Repo.delete(api_key)
        :ok
    end
  end

  @doc """
  Returns the masked key for display, e.g. obs_9f3a•••••••••8d4c.
  The dot count is fixed so it does not reveal the key's length.
  """
  def masked_key(%ApiKey{key_first_chars: first, key_last_chars: last}) do
    @prefix <> first <> String.duplicate("•", 9) <> last
  end

  defp hash(token), do: :crypto.hash(:sha256, token)
end
