defmodule Toolbox.Tasks.CategoryTest do
  use Toolbox.DataCase, async: true

  import ExUnit.CaptureLog

  alias Toolbox.Packages
  alias Toolbox.Tasks.Category

  setup do
    {:ok, package} =
      create(:package, name: "pager", description: "Pagination for Ecto queries")

    %{package: package}
  end

  describe "categorize/2" do
    test "updates the package category with the choice returned by Jev", %{package: package} do
      test_server = Helpers.test_server_jev()
      stub_choice(test_server, "92")

      assert :ok = Category.categorize(package)
      assert Packages.get_package_by_name("pager").category.id == 92
    end

    test "logs when the category changes and log_on_update: true", %{package: package} do
      test_server = Helpers.test_server_jev()
      stub_choice(test_server, "92")

      log =
        capture_log(fn ->
          assert :ok = Category.categorize(package, log_on_update: true)
        end)

      assert log =~ "recategorized pager: none -> Pagination"
    end

    test "does not log when the category changes by default", %{package: package} do
      test_server = Helpers.test_server_jev()
      stub_choice(test_server, "92")

      log =
        capture_log(fn ->
          assert :ok = Category.categorize(package)
        end)

      refute log =~ "recategorized"
    end

    test "does not update the package when the category does not change" do
      test_server = Helpers.test_server_jev()
      {:ok, package} = create(:package, name: "same", category: 92)
      old_updated_at = ~U[2020-01-01 00:00:00Z]

      Repo.update_all(from(p in Toolbox.Package, where: p.id == ^package.id),
        set: [updated_at: old_updated_at]
      )

      stub_choice(test_server, "92")

      assert :ok = Category.categorize(Packages.get_package_by_name("same"))
      assert Packages.get_package_by_name("same").updated_at == old_updated_at
    end

    test "deletes the embedding when the category changes" do
      test_server = Helpers.test_server_jev()
      {:ok, package} = create(:package, name: "moves", category: 61)
      insert_embedding(package)
      stub_choice(test_server, "92")

      assert :ok = Category.categorize(Packages.get_package_by_name("moves"))
      assert "moves" in Packages.list_packages_names_with_no_embedding()
    end

    test "keeps the embedding when the category does not change" do
      test_server = Helpers.test_server_jev()
      {:ok, package} = create(:package, name: "same", category: 92)
      insert_embedding(package)
      stub_choice(test_server, "92")

      assert :ok = Category.categorize(Packages.get_package_by_name("same"))
      assert "same" not in Packages.list_packages_names_with_no_embedding()
    end

    test "sends the package data to Jev", %{package: package} do
      test_server = Helpers.test_server_jev()
      stub_choice(test_server, "92")

      Category.categorize(package)

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

      assert :ok = Category.categorize(package)
    end

    @tag capture_log: true
    test "retries a 5xx outside the usual list, e.g. 501", %{package: package} do
      test_server = Helpers.test_server_jev()
      stub_status(test_server, 501)
      stub_choice(test_server, "92")

      assert :ok = Category.categorize(package)
    end

    @tag capture_log: true
    test "returns the transport error when the connection keeps failing", %{package: package} do
      test_server = Helpers.test_server_jev()

      TestServer.stop(test_server)

      assert {:error, %Req.TransportError{reason: :econnrefused}} =
               Category.categorize(package)
    end
  end

  defp insert_embedding(package) do
    {:ok, _} =
      Packages.upsert_package_embeddings(%{
        package_id: package.id,
        embedding: List.duplicate(0.1, 768)
      })
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
