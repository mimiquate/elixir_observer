defmodule Toolbox.Github do
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

  def parse_link(link) do
    Regex.named_captures(
      ~r/^https?:\/\/(?:www\.)?github.com\/(?<owner>[^\/]*)\/(?<repo>[^\/\n]*)/,
      link
    )
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
    characters_length = 128
    # 3 bytes -> 4 base 64 characters
    byte_length = ceil(characters_length * 3 / 4)

    :crypto.strong_rand_bytes(byte_length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, characters_length)
  end

  def get_user_info(access_token) do
    case Req.get("#{api_host().connect_url()}/user",
           headers: [
             {"authorization", "Bearer #{access_token}"},
             {"user-agent", "toolbox"}
           ]
         ) do
      {:ok,
       %{
         status: 200,
         body: %{
           "id" => id,
           "login" => login,
           "email" => email,
           "name" => name,
           "avatar_url" => avatar_url
         }
       }} ->
        {:ok, primary_email} = get_primary_email(access_token)

        user_info = %{
          id: id,
          login: login,
          email: email,
          primary_email: primary_email,
          name: name,
          avatar_url: avatar_url
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

  def get_repo(owner, repository_name) do
    get("repos/#{owner}/#{repository_name}")
  end

  def get_activity_and_changelog(owner, repository_name) do
    year_ago =
      DateTime.utc_now(:second)
      |> DateTime.shift(month: -12)
      |> Calendar.strftime("%x")

    query = """
      query {
        openIssueCount: search(type: ISSUE, query: "type:issue repo:#{owner}/#{repository_name} is:open created:>=#{year_ago}") {
          issueCount
        }
        closedIssueCount: search(type: ISSUE, query: "type:issue repo:#{owner}/#{repository_name} is:closed created:>=#{year_ago}") {
          issueCount
        }
        openPRCount: search(type: ISSUE, query: "type:pr repo:#{owner}/#{repository_name} is:open created:>=#{year_ago}") {
          issueCount
        }
        mergedPRCount: search(type: ISSUE, query: "type:pr repo:#{owner}/#{repository_name} is:merged created:>=#{year_ago}") {
          issueCount
        }
        repository(owner: \"#{owner}\", name: \"#{repository_name}\") {
          pullRequests(last: 5, states: [MERGED]) {
            nodes {
              createdAt
              mergedAt
              permalink
              mergedBy {
                login
                avatarUrl(size: 24)
              }
              title
            }
          }

          latestTag: refs(refPrefix: "refs/tags/", first: 1, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
            nodes {
              name
              compare(headRef: "HEAD") {
                aheadBy
              }
            }
          }

          changelog: object(expression: "HEAD:CHANGELOG.md") {
            oid
          }
        }
      }
    """

    Req.post(
      url: "#{api_host().connect_url()}/graphql",
      headers: [
        {"authorization", "Bearer #{authorization_token()}"},
        {"user-agent", "toolbox"}
      ],
      json: %{"query" => query}
    )
  end

  defp get(path) do
    Req.get("#{api_host().connect_url()}/#{path}",
      headers: [
        {"authorization", "Bearer #{authorization_token()}"},
        {"user-agent", "toolbox"}
      ]
    )
  end

  defp config, do: Application.fetch_env!(:toolbox, :github)

  defp oauth_host, do: Keyword.fetch!(config(), :oauth_host)
  defp api_host, do: Keyword.fetch!(config(), :api_host)
  defp authorization_token, do: Keyword.fetch!(config(), :authorization_token)
end
