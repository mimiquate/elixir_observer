defmodule ToolboxWeb.AuthController do
  use ToolboxWeb, :controller

  alias Toolbox.Auth.Github, as: GithubAuth
  alias Toolbox.Users

  def authorize(conn, _params) do
    code_verifier = GithubAuth.generate_code_verifier()
    authorize_url = GithubAuth.authorize_url(last_url(conn), code_verifier)

    conn
    |> put_session(:code_verifier, code_verifier)
    |> put_resp_header("location", authorize_url)
    |> send_resp(302, "")
  end

  def callback(conn, %{"state" => url, "code" => code}) do
    code_verifier = get_session(conn, "code_verifier")

    with {:ok, access_token} <- GithubAuth.exchange_code_for_token(code, code_verifier),
      {:ok, user_info} <- GithubAuth.get_user_info(access_token),
      {:ok, user} <- Users.upsert_from_github(user_info)
    do
      conn
      |> delete_session(:code_verifier)
      |> put_session(:user_id, user.id)
      |> redirect(external: url)
    else
      _err ->
        conn
        |> put_flash(:error, "Authentication failed")
        |> redirect(external: url)
    end
  end

  def logout(conn, _params) do
    conn
    |> clear_session()
    |> redirect(external: last_url(conn))
  end

  def last_url(conn) do
    referer = case get_req_header(conn, "referer") do
      [referer] -> referer
      [] -> url(~p"/")
    end
  end
end
