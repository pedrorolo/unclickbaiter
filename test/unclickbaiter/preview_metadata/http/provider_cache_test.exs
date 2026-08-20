defmodule Unclickbaiter.PreviewMetadata.HTTP.ProviderCacheTest do
  use ExUnit.Case, async: false

  import Req.Test

  alias Unclickbaiter.PreviewMetadata.HTTP
  alias Unclickbaiter.PreviewMetadata.HTTP.JsonLink
  alias Unclickbaiter.PreviewMetadata.HTTP.OpenGraphIO
  alias Unclickbaiter.PreviewMetadata.HTTP.ProviderCache
  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

  setup do
    ProviderCache.clear()
    :ok
  end

  describe "provider caching" do
    test "only caches the provider when the domain is not already cached" do
      assert ProviderCache.put_if_new("example.com", JsonLink)

      assert ProviderCache.get("example.com") == JsonLink
      refute ProviderCache.put_if_new("example.com", OpenGraphIO)

      assert ProviderCache.get("example.com") == JsonLink
    end

    test "uses the cached json_link provider directly, skipping the failed providers" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 2, fn conn ->
        case conn.host do
          "example.com" -> Plug.Conn.send_resp(conn, 404, "nope")
          "jsonlink.io" -> Req.Test.json(conn, %{"title" => "JL Title"})
        end
      end)

      assert {:ok, %PreviewMetadata{title: "JL Title"}} =
               HTTP.fetch("https://example.com/article")

      assert ProviderCache.get("example.com") == JsonLink

      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        assert conn.host == "jsonlink.io"
        Req.Test.json(conn, %{"title" => "JL Title 2"})
      end)

      assert {:ok, %PreviewMetadata{title: "JL Title 2"}} =
               HTTP.fetch("https://example.com/other-article")
    end

    test "caches opengraph_io when jsonlink also fails" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 3, fn conn ->
        case conn.host do
          "example.com" ->
            Plug.Conn.send_resp(conn, 404, "nope")

          "jsonlink.io" ->
            Plug.Conn.send_resp(conn, 500, "nope")

          "opengraph.io" ->
            Req.Test.json(conn, %{"hybridGraph" => %{"title" => "OG Title"}})
        end
      end)

      assert {:ok, %PreviewMetadata{title: "OG Title"}} =
               HTTP.fetch("https://example.com")

      assert ProviderCache.get("example.com") == OpenGraphIO

      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        assert conn.host == "opengraph.io"
        Req.Test.json(conn, %{"hybridGraph" => %{"title" => "OG Title 2"}})
      end)

      assert {:ok, %PreviewMetadata{title: "OG Title 2"}} =
               HTTP.fetch("https://example.com/other-article")
    end

    test "does not cache when the direct fetch succeeds" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        html(conn, """
        <html>
          <head>
            <title>Direct</title>
          </head>
        </html>
        """)
      end)

      assert {:ok, %PreviewMetadata{title: "Direct"}} =
               HTTP.fetch("https://example.com")

      assert ProviderCache.get("example.com") == nil
    end

    test "returns the error when the cached jsonlink provider fails" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 2, fn conn ->
        case conn.host do
          "example.com" -> Plug.Conn.send_resp(conn, 404, "nope")
          "jsonlink.io" -> Req.Test.json(conn, %{"title" => "JL Title"})
        end
      end)

      assert {:ok, %PreviewMetadata{title: "JL Title"}} =
               HTTP.fetch("https://example.com")

      assert ProviderCache.get("example.com") == JsonLink

      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        assert conn.host == "jsonlink.io"
        Plug.Conn.send_resp(conn, 500, "nope")
      end)

      assert {:error, {:http_error, 500}} =
               HTTP.fetch("https://example.com/other-article")

      assert ProviderCache.get("example.com") == JsonLink
    end
  end
end
