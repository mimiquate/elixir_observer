defmodule Toolbox.UsersTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.Users

  describe "upsert_from_github/1" do
    test "creates a new user when user does not exist" do
      github_user_info = %{
        id: 12345,
        login: "testuser",
        email: "test@example.com",
        primary_email: "test@example.com",
        name: "Test User",
        avatar_url: "https://avatars.githubusercontent.com/u/12345"
      }

      assert {:ok, user} = Users.upsert_from_github(github_user_info)
      assert user.github_id == 12345
      assert user.login == "testuser"
      assert user.email == "test@example.com"
      assert user.primary_email == "test@example.com"
      assert user.name == "Test User"
      assert user.avatar_url == "https://avatars.githubusercontent.com/u/12345"
    end

    test "updates existing user when user already exists" do
      github_user_info = %{
        id: 12345,
        login: "testuser",
        email: "test@example.com",
        primary_email: "test@example.com",
        name: "Test User",
        avatar_url: "https://avatars.githubusercontent.com/u/12345"
      }

      {:ok, user} = Users.upsert_from_github(github_user_info)
      original_inserted_at = user.inserted_at

      updated_github_info = %{
        id: 12345,
        login: "testuser",
        email: "newemail@example.com",
        primary_email: "newemail@example.com",
        name: "Updated Name",
        avatar_url: "https://avatars.githubusercontent.com/u/12345"
      }

      assert {:ok, updated_user} = Users.upsert_from_github(updated_github_info)
      assert updated_user.id == user.id
      assert updated_user.github_id == 12345
      assert updated_user.login == "testuser"
      assert updated_user.email == "newemail@example.com"
      assert updated_user.primary_email == "newemail@example.com"
      assert updated_user.name == "Updated Name"
      assert updated_user.inserted_at == original_inserted_at
    end
  end

  describe "get_by_github_id/1" do
    test "returns user when found" do
      user = create(:user, github_id: 99999)

      found_user = Users.get_by_github_id(99999)

      assert found_user.id == user.id
      assert found_user.github_id == 99999
    end

    test "returns nil when user not found" do
      assert Users.get_by_github_id(99999) == nil
    end
  end

  describe "get_user/1" do
    test "returns user when found" do
      user = create(:user)

      found_user = Users.get_user(user.id)

      assert found_user.id == user.id
      assert found_user.github_id == user.github_id
    end

    test "returns nil when user not found" do
      assert Users.get_user(Uniq.UUID.uuid7()) == nil
    end

    test "returns nil when id is nil" do
      assert Users.get_user(nil) == nil
    end
  end
end
