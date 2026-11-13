defmodule Toolbox.ApiKeysTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.{ApiKey, ApiKeys, User}

  setup do
    user = create(:user)

    [user: user]
  end

  describe "create_api_key/2" do
    test "returns a token with the obs_ format", %{user: user} do
      {:ok, _api_key, token} = ApiKeys.create_api_key(user.id, %{name: "Claude Desktop"})

      assert token =~ ~r/\Aobs_[a-zA-Z0-9]{30}\z/
    end

    test "generates a different token each time", %{user: user} do
      {:ok, _api_key, token1} = ApiKeys.create_api_key(user.id, %{name: "first"})
      {:ok, _api_key, token2} = ApiKeys.create_api_key(user.id, %{name: "second"})

      assert token1 != token2
    end

    test "stores the token's hash and its first and last 4 chars", %{user: user} do
      {:ok, %ApiKey{id: id}, token} = ApiKeys.create_api_key(user.id, %{name: "Claude Desktop"})
      "obs_" <> random = token

      stored_key = Repo.get!(ApiKey, id)

      assert stored_key.key_hash == :crypto.hash(:sha256, token)
      assert stored_key.key_first_chars == String.slice(random, 0, 4)
      assert stored_key.key_last_chars == String.slice(random, -4, 4)
    end

    test "rejects a name longer than 255 chars", %{user: user} do
      assert {:error, changeset} =
               ApiKeys.create_api_key(user.id, %{name: String.duplicate("a", 256)})

      assert "should be at most 255 character(s)" in errors_on(changeset).name
    end

    test "rejects a description longer than 1000 chars", %{user: user} do
      assert {:error, changeset} =
               ApiKeys.create_api_key(user.id, %{
                 name: "x",
                 description: String.duplicate("a", 1001)
               })

      assert "should be at most 1000 character(s)" in errors_on(changeset).description
    end

    test "rejects a duplicate name for the same user", %{user: user} do
      {:ok, _api_key, _token} = ApiKeys.create_api_key(user.id, %{name: "dup"})

      assert {:error, changeset} = ApiKeys.create_api_key(user.id, %{name: "dup"})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "allows the same name for different users", %{user: user} do
      other_user = create(:user)
      {:ok, _api_key, _token} = ApiKeys.create_api_key(user.id, %{name: "dup"})

      assert {:ok, _api_key, _token} = ApiKeys.create_api_key(other_user.id, %{name: "dup"})
    end
  end

  describe "masked_key/1" do
    test "shows obs_, first 4, 9 dots and last 4" do
      api_key = %ApiKey{key_first_chars: "9f3a", key_last_chars: "8d4c"}

      assert ApiKeys.masked_key(api_key) == "obs_9f3a•••••••••8d4c"
    end
  end

  describe "authenticate/1" do
    test "returns the owner for a valid key", %{user: user} do
      {:ok, _api_key, token} = ApiKeys.create_api_key(user.id, %{name: "Claude Desktop"})
      user_id = user.id

      assert {:ok, %User{id: ^user_id}} = ApiKeys.authenticate(token)
    end

    test "rejects an unknown key" do
      assert :error == ApiKeys.authenticate("obs_" <> String.duplicate("a", 30))
    end

    test "stores the time of last use", %{user: user} do
      {:ok, %ApiKey{id: id}, token} =
        ApiKeys.create_api_key(user.id, %{name: "Claude Desktop"})

      assert Repo.get!(ApiKey, id).last_used_at == nil

      {:ok, _user} = ApiKeys.authenticate(token)

      assert %DateTime{} = Repo.get!(ApiKey, id).last_used_at
    end
  end

  describe "revoke_api_key/2" do
    test "deletes the user's own key", %{user: user} do
      {:ok, %ApiKey{id: id}, _token} =
        ApiKeys.create_api_key(user.id, %{name: "Claude Desktop"})

      assert :ok == ApiKeys.revoke_api_key(user.id, id)
      assert ApiKeys.list_api_keys(user.id) == []
    end

    test "a revoked key no longer authenticates", %{user: user} do
      {:ok, %ApiKey{id: id}, token} =
        ApiKeys.create_api_key(user.id, %{name: "Claude Desktop"})

      :ok = ApiKeys.revoke_api_key(user.id, id)

      assert :error == ApiKeys.authenticate(token)
    end

    test "does not revoke another user's key", %{user: user} do
      other_user = create(:user)

      {:ok, %ApiKey{id: id}, token} =
        ApiKeys.create_api_key(user.id, %{name: "Claude Desktop"})

      assert {:error, :not_found} == ApiKeys.revoke_api_key(other_user.id, id)
      assert {:ok, _user} = ApiKeys.authenticate(token)
    end
  end

  describe "list_api_keys/1" do
    test "returns only the user's keys, newest first", %{user: user} do
      create(:api_key, user_id: user.id, name: "a")
      create(:api_key, user_id: user.id, name: "b")
      create(:api_key, user_id: create(:user).id, name: "other")

      assert Enum.map(ApiKeys.list_api_keys(user.id), & &1.name) == ["b", "a"]
    end
  end
end
