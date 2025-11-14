defmodule ToolboxWeb.ProfileLiveTest do
  use ToolboxWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Toolbox.Users

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
      assert has_element?(view, data_test_attr(:results_list))
      assert has_element?(view, data_test_attr(:result_item, package1.name))
      assert has_element?(view, data_test_attr(:result_item, package2.name))
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

  test "redirects unauthenticated user to home page with error flash", %{conn: conn} do
    result = live(conn, ~p"/profile")

    assert {:error, {:redirect, %{to: "/", flash: flash}}} = result
    assert flash["error"] == "You must be logged in to view your profile"
  end
end
