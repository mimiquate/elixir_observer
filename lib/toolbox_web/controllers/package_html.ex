defmodule ToolboxWeb.PackageHTML do
  @moduledoc """
  This module contains pages rendered by PackageController.

  See the `package_html` directory for all templates available.
  """
  use ToolboxWeb, :html

  embed_templates "package_html/*"
end
