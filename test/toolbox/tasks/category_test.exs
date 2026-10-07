defmodule Toolbox.Tasks.CategoryTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.Packages
  alias Toolbox.Tasks.Category

  setup do
    {:ok, package} =
      create(:package, name: "pager", description: "Pagination for Ecto queries")

    %{package: package}
  end

  describe "run/1" do
    test "updates the package category with the choice returned by Jev", %{package: package} do
      test_server = Helpers.test_server_jev()
      stub_choice(test_server, "92")

      assert {:ok, %{name: "pager"}} = Category.run(package)
      assert Packages.get_package_by_name("pager").category.id == 92
    end

    test "sends the package data to Jev", %{package: package} do
      test_server = Helpers.test_server_jev()
      stub_choice(test_server, "92")

      Category.run(package)

      assert_received {:jev_request, body}

      assert body["state"] == %{
               "name" => "pager",
               "description" => "Pagination for Ecto queries",
               "docs_url" => "https://hexdocs.pm/pager"
             }
    end

    @tag capture_log: true
    test "retries 429 and 529 and then succeeds", %{package: package} do
      test_server = Helpers.test_server_jev()
      stub_status(test_server, 429)
      stub_status(test_server, 529)
      stub_choice(test_server, "92")

      assert {:ok, _} = Category.run(package)
    end

    @tag capture_log: true
    test "retries a 5xx outside the usual list, e.g. 501", %{package: package} do
      test_server = Helpers.test_server_jev()
      stub_status(test_server, 501)
      stub_choice(test_server, "92")

      assert {:ok, _} = Category.run(package)
    end

    @tag capture_log: true
    test "returns the transport error when the connection keeps failing", %{package: package} do
      test_server = Helpers.test_server_jev()

      TestServer.stop(test_server)

      assert {:error, %Req.TransportError{reason: :econnrefused}} = Category.run(package)
    end
  end

  defp stub_choice(test_server, choice) do
    test_pid = self()

    TestServer.add(test_server, "/v1/systemone",
      via: :post,
      to: fn conn ->
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        send(test_pid, {:jev_request, Jason.decode!(raw)})

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"answers" => %{"category" => %{"choice" => choice}}})
        )
      end
    )
  end

  defp stub_status(test_server, status) do
    TestServer.add(test_server, "/v1/systemone",
      via: :post,
      to: fn conn ->
        {:ok, _raw, conn} = Plug.Conn.read_body(conn)

        Plug.Conn.send_resp(conn, status, "")
      end
    )
  end
end
