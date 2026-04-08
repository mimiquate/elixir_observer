defmodule Toolbox.Tasks.CategoryTest do
  use Toolbox.DataCase, async: true

  alias Toolbox.Packages
  alias Toolbox.Tasks.Category

  @gemini_path "/v1beta/models/gemini-2.5-flash\\:generateContent"

  defp test_server_gemini do
    {:ok, test_server} = TestServer.start()

    Application.put_env(:toolbox, :gemini_base_url, TestServer.url(test_server))
    Application.put_env(:toolbox, :gemini_api_key, "test-api-key")

    test_server
  end

  describe "run/1" do
    test "successfully categorizes packages when API returns 200" do
      test_server = test_server_gemini()

      {:ok, package1} =
        Packages.create_package(%{
          name: "test_package_1",
          description: "A test authentication package"
        })

      {:ok, package2} =
        Packages.create_package(%{name: "test_package_2", description: "A test web package"})

      # We'll use existing categories: id 6 = Authentication, id 2 = Algorithms and Data structures

      TestServer.add(test_server, @gemini_path,
        via: :post,
        to: fn conn ->
          response_body = %{
            "candidates" => [
              %{
                "content" => %{
                  "parts" => [
                    %{
                      "text" =>
                        Jason.encode!([
                          %{"name" => "test_package_1", "category" => %{"id" => 6}},
                          %{"name" => "test_package_2", "category" => %{"id" => 2}}
                        ])
                    }
                  ]
                }
              }
            ]
          }

          conn
          |> Plug.Conn.put_resp_header("content-type", "application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
        end
      )

      Category.run([package1, package2])

      updated_package1 = Packages.get_package_by_name("test_package_1")
      updated_package2 = Packages.get_package_by_name("test_package_2")

      assert updated_package1.category.id == 6
      assert updated_package2.category.id == 2
    end

    test "returns error tuple when API returns 5xx server error" do
      test_server = test_server_gemini()

      {:ok, package1} =
        Packages.create_package(%{name: "test_package_1", description: "A test package"})

      {:ok, package2} =
        Packages.create_package(%{name: "test_package_2", description: "Another test package"})

      # Mock server error response
      TestServer.add(test_server, @gemini_path,
        via: :post,
        to: fn conn ->
          Plug.Conn.send_resp(conn, 502, "Bad Gateway")
        end
      )

      result = Category.run([package1, package2])

      assert {:error, "failed to categorize test_package_1, test_package_2 with status 502"} =
               result
    end
  end
end
