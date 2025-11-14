defmodule ToolboxWeb.PlugAttackTest do
  use ToolboxWeb.ConnCase, async: false

  describe "rate limiting" do
    test "allows local requests", %{conn: conn} do
      # Set remote_ip to localhost
      conn = %{conn | remote_ip: {127, 0, 0, 1}}

      # Make more than the limit from localhost
      Enum.each(1..2, fn _ ->
        conn = get(conn, "/")
        assert conn.status == 200
      end)
    end

    test "ban per ip after 1 request", %{conn: conn} do
      assert %{status: 200} =
               conn
               |> put_req_header("fly-client-ip", "198.51.100.50")
               |> get("/")

      assert %{status: 403} =
               conn
               |> put_req_header("fly-client-ip", "198.51.100.50")
               |> get("/")

      assert %{status: 200} =
               conn
               |> put_req_header("fly-client-ip", "198.51.100.51")
               |> get("/")
    end
  end
end
