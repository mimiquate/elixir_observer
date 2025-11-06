defmodule ToolboxWeb.AuthControllerTest do
  use ToolboxWeb.ConnCase, async: true

  import Helpers

  describe "GET /auth/github" do
    test "redirects to GitHub authorization URL", %{conn: conn} do
      oauth_server = test_server_github_oauth()

      conn = get(conn, ~p"/auth/github")

      location = redirected_to(conn, 302)
      assert location =~ "#{TestServer.url(oauth_server)}/login/oauth/authorize"

      # Validate query parameters sent to GitHub
      uri = URI.parse(location)
      params = URI.decode_query(uri.query)

      assert %{
               "client_id" => "test_client_id",
               "redirect_uri" => redirect_uri,
               "scope" => "user:email",
               "state" => state,
               "code_challenge_method" => "S256",
               "code_challenge" => code_challenge
             } = params

      assert redirect_uri =~ "/auth/github/callback"
      assert state =~ "/"
      assert code_challenge != nil

      # Validate code_challenge matches the code_verifier from session
      code_verifier = get_session(conn, :code_verifier)
      assert code_verifier != nil

      expected_challenge =
        Base.url_encode64(:crypto.hash(:sha256, code_verifier), padding: false)

      assert code_challenge == expected_challenge
    end

    test "includes current URL from referer in state parameter", %{conn: conn} do
      _oauth_server = test_server_github_oauth()

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
      oauth_server = test_server_github_oauth()
      api_server = test_server_github_api()
      state_url = "https://example.com/dashboard"

      # Mock GitHub OAuth token exchange
      TestServer.add(oauth_server, "/login/oauth/access_token",
        via: :post,
        match: fn conn ->
          {:ok, body, _conn} = Plug.Conn.read_body(conn)
          params = URI.decode_query(body)

          match?(
            %{
              "client_id" => "test_client_id",
              "client_secret" => "test_client_secret",
              "code" => "github_code_123",
              "code_verifier" => "test_verifier"
            },
            params
          )
        end,
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, ~s({"access_token": "test_access_token_123"}))
        end
      )

      # Mock GitHub user info endpoint
      TestServer.add(api_server, "/user",
        match: fn conn ->
          Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test_access_token_123"]
        end,
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(
            200,
            ~s({
              "id": 12345,
              "login": "testuser",
              "email": "test@example.com",
              "name": "Test User",
              "avatar_url": "https://avatars.githubusercontent.com/u/12345"
            })
          )
        end
      )

      # Mock GitHub user emails endpoint
      TestServer.add(api_server, "/user/emails",
        match: fn conn ->
          Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test_access_token_123"]
        end,
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(
            200,
            ~s([
              {"email": "test@example.com", "primary": true, "verified": true}
            ])
          )
        end
      )

      conn =
        conn
        |> init_test_session(%{code_verifier: "test_verifier"})
        |> get(~p"/auth/github/callback", %{
          "state" => state_url,
          "code" => "github_code_123"
        })

      assert redirected_to(conn, 302) =~ state_url
      assert get_session(conn, :user_id) != nil
      assert get_session(conn, :code_verifier) == nil
    end

    test "redirects back to state URL on authentication failure", %{conn: conn} do
      oauth_server = test_server_github_oauth()
      state_url = "https://example.com/dashboard"

      # Mock GitHub OAuth token exchange to fail
      TestServer.add(oauth_server, "/login/oauth/access_token",
        via: :post,
        to: fn conn ->
          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(401, ~s({"error": "bad_verification_code"}))
        end
      )

      conn =
        conn
        |> init_test_session(%{code_verifier: "test_verifier"})
        |> get(~p"/auth/github/callback", %{
          "state" => state_url,
          "code" => "invalid_code"
        })

      assert redirected_to(conn, 302) =~ state_url
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Authentication failed"
      assert get_session(conn, :user_id) == nil
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
