defmodule UnclickbaiterWeb.PageControllerTest do
  use UnclickbaiterWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    body = html_response(conn, 200)
    assert body =~ "Unclickbaiter"
    assert body =~ "Share links with custom OpenGraph metadata"
  end
end
