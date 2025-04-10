defmodule Toolbox.Number do
  import Number.Delimit, only: [number_to_delimited: 2]
  import Number.Decimal, only: [compare: 2]

  def to_human(number) do
    cond do
      compare(number, 999) == :gt && compare(number, 1_000_000) == :lt ->
        delimit(number, 1_000, "K")

      compare(number, 1_000_000) in [:gt, :eq] and compare(number, 1_000_000_000) == :lt ->
        delimit(number, 1_000_000, "M")

      compare(number, 1_000_000_000) in [:gt, :eq] and
          compare(number, 1_000_000_000_000) == :lt ->
        delimit(number, 1_000_000_000, "B")

      compare(number, 1_000_000_000_000) in [:gt, :eq] and
          compare(number, 1_000_000_000_000_000) == :lt ->
        delimit(number, 1_000_000_000_000, "T")

      compare(number, 1_000_000_000_000_000) in [:gt, :eq] ->
        delimit(number, 1_000_000_000_000_000, "Q")

      true ->
        number_to_delimited(number, precision: 1)
    end
  end

  defp delimit(number, divisor, label) do
    number =
      number
      |> Decimal.div(divisor)
      |> number_to_delimited(precision: 1)

    number <> " " <> label
  end
end
