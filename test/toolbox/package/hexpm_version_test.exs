defmodule Toolbox.Package.HexpmVersionTest do
  use Toolbox.DataCase

  alias Toolbox.Package.HexpmVersion

  describe "build_version_from_api_response/1" do
    test "create the correct struct" do
      inserted_at = "2025-03-26T01:11:00.000000Z"

      response = %{
        "version" => "1.0.0",
        "meta" => %{"elixir" => ">= 1.7.0"},
        "requirements" => %{
          "ecto" => %{"requirement" => "~> 3.0", "optional" => false},
          "phoenix" => %{"requirement" => "~> 1.7", "optional" => true}
        },
        "retirement" => %{
          "message" => "Deprecated",
          "reason" => "security"
        },
        "inserted_at" => inserted_at,
        "publisher" => %{
          "username" => "test_user",
          "email" => "test@example.com"
        }
      }

      result = HexpmVersion.build_version_from_api_response(response)

      assert result.version == "1.0.0"
      assert result.elixir_requirement == ">= 1.7.0"
      assert result.published_at == inserted_at
      assert result.published_by_username == "test_user"
      assert result.published_by_email == "test@example.com"

      [required] = result.required
      assert required.name == "ecto"
      assert required.requirement == "~> 3.0"

      [optional] = result.optional
      assert optional.name == "phoenix"
      assert optional.requirement == "~> 1.7"
    end
  end

  describe "changeset/2" do
    test "publisher can be blank" do
      attrs =
        ~S(
        {
          "meta": {
            "elixir": "~\u003E 1.1",
            "app": "esync",
            "build_tools": [
              "mix"
            ]
          },
          "version": "0.0.1",
          "checksum": "28a59a0cbe885ec39dec4992aac8495147d1ec9b623883b01e8aa775cb334f03",
          "url": "https://hex.pm/api/packages/esync/releases/0.0.1",
          "has_docs": false,
          "inserted_at": "2016-01-08T04:55:16.925658Z",
          "updated_at": "2019-07-28T21:10:15.066586Z",
          "retirement": null,
          "downloads": 519,
          "publisher": null,
          "requirements": {

          },
          "docs_html_url": null,
          "package_url": "https://hex.pm/api/packages/esync",
          "configs": {
            "erlang.mk": "dep_esync = hex 0.0.1",
            "mix.exs": "{:esync, \"~\u003E 0.0.1\"}",
            "rebar.config": "{esync, \"0.0.1\"}"
          },
          "html_url": "https://hex.pm/packages/esync/0.0.1"
        }
      )
        |> Jason.decode!()
        |> HexpmVersion.build_version_from_api_response()

      changeset = HexpmVersion.changeset(%HexpmVersion{}, attrs)
      assert changeset.valid?
    end
  end
end
