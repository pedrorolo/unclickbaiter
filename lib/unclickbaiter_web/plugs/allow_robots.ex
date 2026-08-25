defmodule UnclickbaiterWeb.Plugs.AllowRobots do
  @moduledoc """
  Overrides `x-robots-tag` to allow indexing for public preview pages.

  Gigalixir's `*.gigalixirapp.com` hosts are served behind Google Frontend
  which injects `x-robots-tag: noindex, nofollow` by default. For the
  public `GET /p/:slug` preview we want WhatsApp/Facebook crawlers to
  index and show large image previews.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> delete_resp_header("x-robots-tag")
    |> put_resp_header("x-robots-tag", "index, follow, max-image-preview:large")
  end
end
