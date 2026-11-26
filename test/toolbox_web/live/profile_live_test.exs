defmodule ToolboxWeb.ProfileLiveTest do
  use ToolboxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Toolbox.{ApiKeys, Repo, Users}

  describe "Profile Live View - Authenticated User" do
    setup do
      user = create(:user)

      {:ok, package1} =
        create(:package,
          name: "phoenix",
          description: "Peace of mind from prototype to production"
        )

      {:ok, package2} =
        create(:package,
          name: "ecto",
          description: "A toolkit for data mapping and language integrated query"
        )

      {:ok, _} = create(:hexpm_snapshot, package_id: package1.id)
      {:ok, _} = create(:hexpm_snapshot, package_id: package2.id)

      [user: user, package1: package1, package2: package2]
    end

    test "displays empty state when user has no followed packages", %{conn: conn, user: user} do
      conn = init_test_session(conn, %{user_id: user.id})

      {:ok, view, _html} = live(conn, ~p"/profile")

      assert has_element?(view, data_test_attr(:no_packages_title), "No packages yet")

      assert has_element?(
               view,
               data_test_attr(:no_packages_message),
               "Start following packages to see them here"
             )

      refute has_element?(view, data_test_attr(:profile_packages))
    end

    test "displays followed packages when user follows packages", %{
      conn: conn,
      user: user,
      package1: package1,
      package2: package2
    } do
      Users.follow_package(user.id, package1.id)
      Users.follow_package(user.id, package2.id)

      conn = init_test_session(conn, %{user_id: user.id})

      {:ok, view, _html} = live(conn, ~p"/profile")

      assert has_element?(view, data_test_attr(:profile_packages))
      assert has_element?(view, data_test_attr(:packages_list))
      assert has_element?(view, data_test_attr(:package_item, package1.name))
      assert has_element?(view, data_test_attr(:package_item, package2.name))
      assert has_element?(view, data_test_attr(:package_link, package1.name))
      assert has_element?(view, data_test_attr(:package_link, package2.name))
      refute has_element?(view, data_test_attr(:no_packages_title))
    end

    test "displays package details correctly", %{
      conn: conn,
      user: user,
      package1: package1
    } do
      Users.follow_package(user.id, package1.id)
      conn = init_test_session(conn, %{user_id: user.id})

      {:ok, view, _html} = live(conn, ~p"/profile")

      assert has_element?(view, data_test_attr(:package_link, package1.name), package1.name)
      assert has_element?(view, data_test_attr(:package_description), package1.description)
      assert has_element?(view, data_test_attr(:version, "1.7.0"), "1.7.0")
    end
  end

  describe "API Keys" do
    setup %{conn: conn} do
      user = create(:user)
      conn = init_test_session(conn, %{user_id: user.id})

      [conn: conn, user: user]
    end

    test "shows the empty state when the user has no keys", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      assert has_element?(view, data_test_attr(:no_api_keys_title), "No API Keys created yet")

      assert has_element?(
               view,
               data_test_attr(:no_api_keys_message),
               "Click Create API key to generate your first key and start connecting Observer with external tools and AI assistants."
             )

      refute has_element?(view, data_test_attr(:profile_api_keys))
    end

    test "lists the user's keys masked", %{conn: conn, user: user} do
      api_key =
        create(:api_key,
          user_id: user.id,
          name: "Claude Desktop",
          description: "Used for Claude Desktop integration."
        )
        |> Ecto.Changeset.change(inserted_at: ~U[2026-10-15 12:00:00Z])
        |> Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/profile")

      assert has_element?(view, data_test_attr(:profile_api_keys))
      assert has_element?(view, data_test_attr(:api_keys_list))

      item = data_test_attr(:api_key_item, api_key.id)

      assert has_element?(view, item, "Claude Desktop")
      assert has_element?(view, "#{item} #{data_test_attr(:api_key_status)}", "Unused")

      assert has_element?(
               view,
               "#{item} #{data_test_attr(:api_key_masked)}",
               ApiKeys.masked_key(api_key)
             )

      assert has_element?(
               view,
               "#{item} #{data_test_attr(:api_key_description)}",
               "Used for Claude Desktop integration."
             )

      assert has_element?(
               view,
               "#{item} #{data_test_attr(:api_key_created_at)}",
               "Created: Oct 15, 2026"
             )

      assert has_element?(
               view,
               "#{item} #{data_test_attr(:api_key_last_used)}",
               "Last used: Never"
             )

      refute has_element?(view, data_test_attr(:no_api_keys_title))
    end

    test "shows Active and relative last use after authentication", %{conn: conn, user: user} do
      {:ok, api_key, token} = ApiKeys.create_api_key(user.id, %{name: "Claude Desktop"})
      {:ok, _user} = ApiKeys.authenticate(token)

      {:ok, view, _html} = live(conn, ~p"/profile")

      item = data_test_attr(:api_key_item, api_key.id)

      assert has_element?(view, "#{item} #{data_test_attr(:api_key_status)}", "Active")
      assert has_element?(view, "#{item} #{data_test_attr(:api_key_last_used)}", "Last used: now")
    end

    test "does not show other users' keys", %{conn: conn} do
      other_api_key = create(:api_key, user_id: create(:user).id, name: "Other")

      {:ok, view, _html} = live(conn, ~p"/profile")

      refute has_element?(view, data_test_attr(:api_key_item, other_api_key.id))
      assert has_element?(view, data_test_attr(:no_api_keys_title))
    end

    test "shows the created key once and discards it after closing the modal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view |> element(data_test_attr(:create_api_key_button)) |> render_click()

      view
      |> form("#api-key-form", api_key: %{name: "Claude Desktop"})
      |> render_submit()

      [token] =
        Regex.run(
          ~r/obs_[a-zA-Z0-9]{30}/,
          view |> element(data_test_attr(:created_api_key)) |> render()
        )

      render_click(view, "close_api_key_modal", %{})

      refute has_element?(view, "#api-key-modal")
      refute render(view) =~ token

      # Reopening must show an empty form, not the previous key
      view |> element(data_test_attr(:create_api_key_button)) |> render_click()

      assert has_element?(view, "#api-key-form")
      refute render(view) =~ token
    end

    test "adds the created key to the list, masked", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/profile")

      view |> element(data_test_attr(:create_api_key_button)) |> render_click()

      view
      |> form("#api-key-form", api_key: %{name: "Claude Desktop"})
      |> render_submit()

      [api_key] = ApiKeys.list_api_keys(user.id)
      item = data_test_attr(:api_key_item, api_key.id)

      assert has_element?(view, item, "Claude Desktop")

      assert has_element?(
               view,
               "#{item} #{data_test_attr(:api_key_masked)}",
               ApiKeys.masked_key(api_key)
             )
    end

    test "shows errors in the create form on submit", %{conn: conn, user: user} do
      create(:api_key, user_id: user.id, name: "dup")

      {:ok, view, _html} = live(conn, ~p"/profile")

      view |> element(data_test_attr(:create_api_key_button)) |> render_click()

      view |> form("#api-key-form", api_key: %{name: ""}) |> render_submit()
      assert has_element?(view, "#api-key-form", "can't be blank")

      view |> form("#api-key-form", api_key: %{name: "dup"}) |> render_submit()
      assert has_element?(view, "#api-key-form", "has already been taken")
    end

    test "revokes a key after confirmation", %{conn: conn, user: user} do
      api_key = create(:api_key, user_id: user.id, name: "Claude Desktop")

      {:ok, view, _html} = live(conn, ~p"/profile")

      view |> element(data_test_attr(:revoke_api_key, api_key.id)) |> render_click()

      assert has_element?(view, "#revoke-api-key-modal", "Revoke API Key")
      assert has_element?(view, "#revoke-api-key-modal", "Claude Desktop")

      view |> element("#revoke-api-key-modal button", "Revoke") |> render_click()

      refute has_element?(view, "#revoke-api-key-modal")
      refute has_element?(view, data_test_attr(:api_key_item, api_key.id))
      assert has_element?(view, "#flash-info", "API key revoked")
      assert ApiKeys.list_api_keys(user.id) == []
    end

    test "handles a key already revoked elsewhere", %{conn: conn, user: user} do
      api_key = create(:api_key, user_id: user.id, name: "Claude Desktop")

      {:ok, view, _html} = live(conn, ~p"/profile")

      view |> element(data_test_attr(:revoke_api_key, api_key.id)) |> render_click()

      :ok = ApiKeys.revoke_api_key(user.id, api_key.id)

      view |> element("#revoke-api-key-modal button", "Revoke") |> render_click()

      refute has_element?(view, "#revoke-api-key-modal")
      refute has_element?(view, data_test_attr(:api_key_item, api_key.id))
      assert has_element?(view, "#flash-error", "API key not found")
    end
  end

  test "redirects unauthenticated user to home page with error flash", %{conn: conn} do
    result = live(conn, ~p"/profile")

    assert {:error, {:redirect, %{to: "/", flash: flash}}} = result
    assert flash["error"] == "You must be logged in to view your profile"
  end
end
