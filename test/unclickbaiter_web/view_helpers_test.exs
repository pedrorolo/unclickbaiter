defmodule UnclickbaiterWeb.ViewHelpersTest do
  use ExUnit.Case, async: true

  alias UnclickbaiterWeb.ViewHelpers

  test "format_date for DateTime and Date" do
    dt = DateTime.from_naive!(~N[2023-01-02 03:04:05], "Etc/UTC")
    assert ViewHelpers.format_date(dt) == "2023-01-02"

    d = ~D[2023-01-02]
    assert ViewHelpers.format_date(d) == "2023-01-02"

    assert ViewHelpers.format_date(nil) == ""
  end

  test "truncate_text" do
    assert ViewHelpers.truncate_text(nil, 10) == ""
    assert ViewHelpers.truncate_text("short", 10) == "short"

    assert ViewHelpers.truncate_text(String.duplicate("a", 15), 10) ==
             String.duplicate("a", 10) <> "…"
  end
end
