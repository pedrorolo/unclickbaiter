defmodule UnclickbaiterWeb.PageControllerTest do
  use UnclickbaiterWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)
    assert body =~ "unclickbaiter"
    assert body =~ "Alternative social-media previews to existing pages"
  end
end
