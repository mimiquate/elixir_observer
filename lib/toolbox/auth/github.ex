defmodule Toolbox.Auth.Github do
  use Phoenix.VerifiedRoutes,
    router: ToolboxWeb.Router,
    endpoint: ToolboxWeb.Endpoint

  defmodule Host do
    @callback connect_url() :: String.t()
  end

  defmodule OAuthProdHost do
    @behaviour Host
    def connect_url, do: "https://github.com"
  end

  defmodule APIProdHost do
    @behaviour Host
    def connect_url, do: "https://api.github.com"
  end

  def authorize_url(current_url, code_verifier) do
    client_id = Keyword.fetch!(config(), :oauth_client_id)
    redirect_uri = url(~p"/auth/github/callback")

    params = %{
      client_id: client_id,
      redirect_uri: redirect_uri,
      scope: "user:email",
      state: current_url,
      code_challenge_method: "S256",
      code_challenge: Base.url_encode64(:crypto.hash(:sha256, code_verifier), padding: false)
    }

    "#{oauth_host().connect_url()}/login/oauth/authorize?#{URI.encode_query(params)}"
  end

  def exchange_code_for_token(code, code_verifier) do
    client_id = Keyword.fetch!(config(), :oauth_client_id)
    client_secret = Keyword.fetch!(config(), :oauth_client_secret)

    case Req.post("#{oauth_host().connect_url()}/login/oauth/access_token",
           headers: [
             {"accept", "application/json"},
             {"user-agent", "toolbox"}
           ],
           form: [
             code_verifier: code_verifier,
             client_id: client_id,
             client_secret: client_secret,
             code: code
           ]
         ) do
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
    case Req.get("#{api_host().connect_url()}/user",
           headers: [
             {"authorization", "Bearer #{access_token}"},
             {"user-agent", "toolbox"}
           ]
         ) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, primary_email} = get_primary_email(access_token)

        user_info = %{
          id: body["id"],
          login: body["login"],
          email: body["email"],
          primary_email: primary_email,
          name: body["name"],
          avatar_url: body["avatar_url"]
        }

        {:ok, user_info}

      {:ok, body} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_primary_email(access_token) do
    case Req.get("#{api_host().connect_url()}/user/emails",
           headers: [
             {"authorization", "Bearer #{access_token}"},
             {"user-agent", "toolbox"}
           ]
         ) do
      {:ok, %{status: 200, body: body}} ->
        %{"email" => email} = Enum.find(body, & &1["primary"])

        {:ok, email}

      {:ok, body} ->
        {:error, body}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp config, do: Application.fetch_env!(:toolbox, :github_auth)

  defp oauth_host, do: Keyword.fetch!(config(), :oauth_host)
  defp api_host, do: Keyword.fetch!(config(), :api_host)
end
