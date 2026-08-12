defmodule UnclickbaiterWeb.PageController do
  use UnclickbaiterWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
