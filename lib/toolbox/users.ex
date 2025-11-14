defmodule Toolbox.Users do
  alias Toolbox.{User, Repo}
  import Ecto.Query

  @doc """
  Creates or updates a user based on GitHub authentication data.
  Returns {:ok, user} or {:error, changeset}.
  """
  def upsert_from_github(github_user_info) do
    attrs = %{
      github_id: github_user_info.id,
      login: github_user_info.login,
      email: github_user_info.email,
      primary_email: github_user_info.primary_email,
      name: github_user_info.name,
      avatar_url: github_user_info.avatar_url
    }

    case get_by_github_id(github_user_info.id) do
      nil -> %User{}
      user -> user
    end
    |> User.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc """
  Gets a user by their GitHub ID.
  """
  def get_by_github_id(github_id) do
    from(u in User, where: u.github_id == ^github_id)
    |> Repo.one()
  end

  @doc """
  Gets a user by their database ID.
  Returns nil if id is nil.
  """
  def get_user(nil), do: nil

  def get_user(id) do
    Repo.get(User, id)
  end
end
