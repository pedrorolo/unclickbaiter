defmodule UnclickbaiterWeb.LayoutsTest do
  use ExUnit.Case, async: true
  import Phoenix.LiveViewTest

  test "app renders title, description and inner content" do
    html =
      render_component(&UnclickbaiterWeb.Layouts.app/1, %{
        __changed__: %{inner_block: true},
        flash: %{},
        inner_block: fn -> "Hello Body" end
      })

    html = IO.iodata_to_binary(html)
    assert html =~ "unclickbaiter"
    assert html =~ "Alternative social-media previews to existing pages"
    assert html =~ "Hello Body"
  end

  test "theme_toggle contains theme buttons" do
    html =
      render_component(&UnclickbaiterWeb.Layouts.theme_toggle/1, %{
        __changed__: %{}
      })

    html = IO.iodata_to_binary(html)
    assert html =~ "data-phx-theme=\"system\""
    assert html =~ "data-phx-theme=\"light\""
    assert html =~ "data-phx-theme=\"dark\""
  end
end
