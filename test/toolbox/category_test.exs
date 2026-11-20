defmodule Toolbox.CategoryTest do
  use ExUnit.Case, async: true

  alias Toolbox.Category

  test "all/0 returns categories sorted alphabetically by name" do
    names = Enum.map(Category.all(), & &1.name)

    assert names == Enum.sort_by(names, &String.downcase/1)
  end
end
