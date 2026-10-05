defmodule Toolbox.Workers.RecategorizeWorkerTest do
  # Not async: the Gemini base url is set through the global application env
  use Toolbox.DataCase, async: false
  use Oban.Testing, repo: Toolbox.Repo

  import ExUnit.CaptureLog

  alias Toolbox.Packages
  alias Toolbox.Workers.RecategorizeWorker

  @gemini_path "/v1beta/models/gemini-2.5-flash\\:generateContent"

  defp stub_gemini(status, classifications \\ []) do
    {:ok, test_server} = TestServer.start()
    Application.put_env(:toolbox, :gemini_base_url, TestServer.url(test_server))
    Application.put_env(:toolbox, :gemini_api_key, "test-api-key")

    TestServer.add(test_server, @gemini_path,
      via: :post,
      to: fn conn ->
        body = %{
          "candidates" => [
            %{
              "content" => %{
                "parts" => [
                  %{
                    "text" =>
                      Jason.encode!(
                        for {name, id} <- classifications do
                          %{"name" => name, "category" => %{"id" => id}}
                        end
                      )
                  }
                ]
              }
            }
          ]
        }

        conn
        |> Plug.Conn.put_resp_header("content-type", "application/json")
        |> Plug.Conn.send_resp(status, Jason.encode!(body))
      end
    )
  end

  describe "perform/1" do
    test "reclassifies the given packages and logs the ones that changed" do
      stub_gemini(200, [{"moves", 92}, {"stays", 85}])
      {:ok, _} = create(:package, name: "moves", category: 61)
      {:ok, _} = create(:package, name: "stays", category: 85)

      log =
        capture_log(fn ->
          assert :ok == perform_job(RecategorizeWorker, %{names: ["moves", "stays"]})
        end)

      assert Packages.get_package_by_name("moves").category.id == 92
      assert Packages.get_package_by_name("stays").category.id == 85
      assert log =~ "recategorized moves: ORM and Datamapping -> Pagination"
      refute log =~ "recategorized stays"
    end

    @tag capture_log: true
    test "returns the error when classification fails" do
      stub_gemini(502)
      {:ok, _} = create(:package, name: "moves", category: 61)

      assert {:error, "failed to categorize moves with status 502"} =
               perform_job(RecategorizeWorker, %{names: ["moves"]})
    end
  end
end
