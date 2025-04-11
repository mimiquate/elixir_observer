defmodule Toolbox.Github do
  @base_url "https://api.github.com"

  def get_repo(owner, repository_name) do
    get("repos/#{owner}/#{repository_name}")
  end

  def get_repo_activity(path) do
    get("repos/#{path}/activity")
  end

  defp get(path) do
    :httpc.request(
      :get,
      {
        ~c"#{@base_url}/#{path}",
        [
          {~c"authorization", "Bearer #{authorization_token()}"},
          {~c"user-agent", "elixir client"}
        ]
      },
      [
        ssl: [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          # Support wildcard certificates
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ],
      []
    )
  end

  defp authorization_token do
    Application.fetch_env!(:toolbox, :github_authorization_token)
  end
end
