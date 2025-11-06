defmodule Toolbox.Auth.GithubTest do
  use Toolbox.DataCase, async: true

  import Helpers

  alias Toolbox.Auth.Github

  describe "generate_code_verifier/0" do
    test "generates a code verifier with 128 characters" do
      code_verifier = Github.generate_code_verifier()

      assert String.length(code_verifier) == 128
    end

    test "generates different code verifiers on each call" do
      code_verifier1 = Github.generate_code_verifier()
      code_verifier2 = Github.generate_code_verifier()

      assert code_verifier1 != code_verifier2
    end

    test "generates URL-safe characters" do
      code_verifier = Github.generate_code_verifier()

      # Should only contain URL-safe base64 characters (no padding)
      assert code_verifier =~ ~r/^[A-Za-z0-9_-]+$/
    end
  end

  describe "authorize_url/2" do
    test "generates a valid GitHub authorization URL" do
      _oauth_server = test_server_github_oauth()
      current_url = "https://example.com/dashboard"
      code_verifier = Github.generate_code_verifier()

      url = Github.authorize_url(current_url, code_verifier)

      assert url =~ "/login/oauth/authorize?"
      assert url =~ "client_id="
      assert url =~ "redirect_uri="
      assert url =~ "scope=user%3Aemail"
      assert url =~ "state=#{URI.encode_www_form(current_url)}"
      assert url =~ "code_challenge_method=S256"
      assert url =~ "code_challenge="
    end

    test "includes correct PKCE challenge derived from verifier" do
      _oauth_server = test_server_github_oauth()
      current_url = "https://example.com/dashboard"
      code_verifier = "test_verifier_123"

      url = Github.authorize_url(current_url, code_verifier)

      expected_challenge = Base.url_encode64(:crypto.hash(:sha256, code_verifier), padding: false)
      assert url =~ "code_challenge=#{URI.encode_www_form(expected_challenge)}"
    end
  end
end
