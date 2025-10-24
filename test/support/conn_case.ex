defmodule ToolboxWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ToolboxWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint ToolboxWeb.Endpoint

      use ToolboxWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ToolboxWeb.ConnCase
      import Toolbox.Factory
    end
  end

  setup tags do
    Toolbox.DataCase.setup_sandbox(tags)

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  def node_count(lazy_html) do
    lazy_html
    |> LazyHTML.to_tree()
    |> length()
  end

  def data_test_attr(name) do
    "[data-test-" <>
      (name
       |> to_string()
       |> String.replace("_", "-")) <> "]"
  end

  def data_test_attr(name, value) do
    "[data-test-" <>
      (name
       |> to_string()
       |> String.replace("_", "-")) <> "=\"#{value}\"]"
  end
end
