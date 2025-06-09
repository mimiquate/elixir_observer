defmodule Toolbox.Package.HexpmVersionTest do
  use Toolbox.DataCase

  alias Toolbox.Package.HexpmVersion

  describe "build_version_from_api_response/1" do
    test "" do
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
end
