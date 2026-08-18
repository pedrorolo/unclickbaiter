defmodule UnclickbaiterWeb.ViewHelpers do
  @moduledoc """
  Small view helpers available in templates.

  Functions:
  - format_date/1: formats Date/DateTime to ISO date
  - truncate_text/2: truncates long text with ellipsis
  """

  def format_date(%DateTime{} = dt),
    do: dt |> DateTime.to_date() |> Date.to_iso8601()

  def format_date(%Date{} = d), do: Date.to_iso8601(d)
  def format_date(_), do: ""

  def truncate_text(nil, _), do: ""

  def truncate_text(text, max)
      when is_binary(text) and is_integer(max) and max > 0 do
    if String.length(text) > max,
      do: String.slice(text, 0, max) <> "…",
      else: text
  end
end
