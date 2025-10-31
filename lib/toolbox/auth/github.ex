defmodule Toolbox.Auth.Github do
  @github_authorize_url "https://github.com/login/oauth/authorize"
  @github_access_token_url "https://github.com/login/oauth/access_token"

  use Phoenix.VerifiedRoutes,
    router: ToolboxWeb.Router,
    endpoint: ToolboxWeb.Endpoint

  def authorize_url(current_url, code_verifier) do
    client_id = Application.fetch_env!(:toolbox, :github_oauth_client_id)
    redirect_uri = url(~p"/auth/github/callback")

    params = %{
      client_id: client_id,
      redirect_uri: redirect_uri,
      scope: "user:email",
      state: current_url,
      code_challenge_method: "S256",
      code_challenge: Base.url_encode64(:crypto.hash(:sha256, code_verifier), padding: false)
    }

    "#{@github_authorize_url}?#{URI.encode_query(params)}"
  end

  def exchange_code_for_token(code, code_verifier) do
    client_id = Application.fetch_env!(:toolbox, :github_oauth_client_id)
    client_secret = Application.fetch_env!(:toolbox, :github_oauth_client_secret)

    case Req.post(@github_access_token_url,
      headers: [
        {"accept", "application/json"},
        {"user-agent", "toolbox"}
      ],
      form: [
        code_verifier: code_verifier,
        client_id: client_id,
        client_secret: client_secret,
        code: code,
      ]
    )  do
      {:ok, %{status: 200, body: %{"access_token" => access_token}}} ->
        {:ok, access_token}

      {:ok, body} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def generate_code_verifier() do
    length = 128
    byte_length = ceil(length * 3 / 4)

    :crypto.strong_rand_bytes(byte_length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end

  def get_user_info(access_token) do
    case Req.get("https://api.github.com/user",
           headers: [
             {"authorization", "Bearer #{access_token}"},
             {"user-agent", "toolbox"}
           ]
    ) do
      {:ok, %{status: 200, body: body}} ->
        user_info = %{
          id: body["id"],
          login: body["login"],
          email: body["email"],
          name: body["name"],
          avatar_url: body["avatar_url"],
        }

        {:ok, user_info}
      {:ok, body} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_primary_email(access_token) do
    case Req.get("https://api.github.com/user/emails",
           headers: [
             {"authorization", "Bearer #{access_token}"},
             {"user-agent", "toolbox"}
           ]
    ) do
      {:ok, %{status: 200, body: body}} ->
        %{"email" => email} = Enum.find(body, &(&1["primary"]))

        {:ok, email}
      {:ok, body} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
