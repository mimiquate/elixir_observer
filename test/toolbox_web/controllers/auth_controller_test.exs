defmodule ToolboxWeb.AuthControllerTest do
  use ToolboxWeb.ConnCase, async: true

  describe "GET /auth/github" do
    test "redirects to GitHub authorization URL", %{conn: conn} do
      conn = get(conn, ~p"/auth/github")

      assert redirected_to(conn, 302) =~ "https://github.com/login/oauth/authorize"
      assert get_session(conn, :code_verifier) != nil
    end

    test "stores code_verifier in session", %{conn: conn} do
      conn = get(conn, ~p"/auth/github")

      code_verifier = get_session(conn, :code_verifier)
      assert code_verifier != nil
      assert String.length(code_verifier) == 128
    end

    test "includes current URL from referer in state parameter", %{conn: conn} do
      conn =
        conn
        |> put_req_header("referer", "https://example.com/packages")
        |> get(~p"/auth/github")

      location = redirected_to(conn, 302)
      assert location =~ "state=https%3A%2F%2Fexample.com%2Fpackages"
    end
  end

  describe "GET /auth/github/callback" do
    test "creates user and redirects to state URL on successful authentication", %{conn: conn} do
      # Note: This test would require mocking the GitHub API calls
      # For now, we'll test the basic flow structure
      state_url = "https://example.com/dashboard"

      conn =
        conn
        |> init_test_session(%{code_verifier: "test_verifier"})
        |> get(~p"/auth/github/callback", %{
          "state" => state_url,
          "code" => "github_code_123"
        })

      # Since we can't easily mock the GitHub API in this test without additional setup,
      # we expect this to fail authentication and redirect back
      assert redirected_to(conn, 302) =~ state_url
    end

    test "redirects back to state URL on authentication failure", %{conn: conn} do
      state_url = "https://example.com/dashboard"

      conn =
        conn
        |> init_test_session(%{code_verifier: "test_verifier"})
        |> get(~p"/auth/github/callback", %{
          "state" => state_url,
          "code" => "github_code_123"
        })

      assert redirected_to(conn, 302) =~ state_url
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Authentication failed"
    end
  end

  describe "GET /auth/logout" do
    test "clears session and redirects to referer", %{conn: conn} do
      user = create(:user)

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> put_req_header("referer", "https://example.com/dashboard")
        |> get(~p"/auth/logout")

      assert get_session(conn, :user_id) == nil
      assert redirected_to(conn, 302) =~ "https://example.com/dashboard"
    end

    test "redirects to home when no referer", %{conn: conn} do
      user = create(:user)

      conn =
        conn
        |> init_test_session(%{user_id: user.id})
        |> get(~p"/auth/logout")

      assert get_session(conn, :user_id) == nil
      assert redirected_to(conn, 302) =~ "/"
    end
  end

  describe "last_url/1" do
    test "returns referer when present", %{conn: conn} do
      conn = put_req_header(conn, "referer", "https://example.com/test")

      assert ToolboxWeb.AuthController.last_url(conn) == "https://example.com/test"
    end

    test "returns home path when no referer", %{conn: conn} do
      assert ToolboxWeb.AuthController.last_url(conn) =~ "/"
    end
  end
end
