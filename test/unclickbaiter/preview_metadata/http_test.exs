defmodule Unclickbaiter.PreviewMetadata.HTTPTest do
  use ExUnit.Case, async: false

  import Req.Test

  alias Unclickbaiter.PreviewMetadata.HTTP
  alias Unclickbaiter.PreviewMetadata.HTTP.ProviderCache
  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

  setup do
    ProviderCache.clear()
    :ok
  end

  describe "fetch/1" do
    test "extracts og metadata from the html" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, fn conn ->
        html(conn, """
        <html>
          <head>
            <meta property="og:title" content="The Real Story" />
            <meta property="og:description" content="What actually happened" />
            <meta property="og:image" content="https://cdn.example.com/img.png" />
            <title>Clickbait Title</title>
          </head>
        </html>
        """)
      end)

      assert {:ok,
              %PreviewMetadata{
                title: "The Real Story",
                description: "What actually happened",
                image_url: "https://cdn.example.com/img.png"
              }} = HTTP.fetch("https://example.com")
    end

    test "falls back to title and meta description" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, fn conn ->
        html(conn, """
        <html>
          <head>
            <meta name="description" content="A fallback description" />
            <title>A Fallback Title</title>
          </head>
        </html>
        """)
      end)

      assert {:ok,
              %PreviewMetadata{
                title: "A Fallback Title",
                description: "A fallback description",
                image_url: nil
              }} = HTTP.fetch("https://example.com")
    end

    test "resolves relative image urls against the final url" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, fn conn ->
        html(conn, """
        <html>
          <head>
            <meta property="og:image" content="/images/og.png" />
            <title>Relative Image</title>
          </head>
        </html>
        """)
      end)

      assert {:ok,
              %PreviewMetadata{image_url: "https://example.com/images/og.png"}} =
               HTTP.fetch("https://example.com")
    end

    test "follows redirects and resolves against the redirected url" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 2, fn conn ->
        case conn.path_info do
          ["start"] ->
            conn
            |> Plug.Conn.put_resp_header(
              "location",
              "https://example.com/final"
            )
            |> Plug.Conn.send_resp(302, "")

          _ ->
            html(conn, """
            <html>
              <head>
                <meta property="og:image" content="/og.png" />
                <title>Final</title>
              </head>
            </html>
            """)
        end
      end)

      assert {:ok,
              %PreviewMetadata{
                title: "Final",
                image_url: "https://example.com/og.png"
              }} =
               HTTP.fetch("https://example.com/start")
    end

    test "returns error on non-2xx status" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 3, fn conn ->
        case conn.host do
          "example.com" -> Plug.Conn.send_resp(conn, 404, "nope")
          "jsonlink.io" -> Plug.Conn.send_resp(conn, 500, "nope")
          "opengraph.io" -> Plug.Conn.send_resp(conn, 500, "nope")
        end
      end)

      assert {:error, {:http_error, 500}} =
               HTTP.fetch("https://example.com")
    end

    test "returns error on transport errors" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 3, fn conn ->
        case conn.host do
          "example.com" -> transport_error(conn, :nxdomain)
          "jsonlink.io" -> Plug.Conn.send_resp(conn, 500, "nope")
          "opengraph.io" -> Plug.Conn.send_resp(conn, 500, "nope")
        end
      end)

      assert {:error, {:http_error, 500}} =
               HTTP.fetch("https://example.com")
    end

    test "returns error for invalid urls" do
      assert {:error, :invalid_url} = HTTP.fetch(nil)
    end

    test "returns error when the body cannot be parsed" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 3, fn conn ->
        case conn.host do
          "example.com" -> Req.Test.json(conn, %{"title" => "json"})
          "jsonlink.io" -> Plug.Conn.send_resp(conn, 500, "nope")
          "opengraph.io" -> Plug.Conn.send_resp(conn, 500, "nope")
        end
      end)

      assert {:error, {:http_error, 500}} = HTTP.fetch("https://example.com")
    end

    test "falls back to jsonlink.io when the site request fails" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 2, fn conn ->
        case conn.host do
          "example.com" ->
            Plug.Conn.send_resp(conn, 404, "nope")

          "jsonlink.io" ->
            Req.Test.json(conn, %{
              "title" => "JL Title",
              "description" => "JL desc",
              "image" => "https://cdn.example.com/jl.png"
            })
        end
      end)

      assert {:ok,
              %PreviewMetadata{
                title: "JL Title",
                description: "JL desc",
                image_url: "https://cdn.example.com/jl.png"
              }} = HTTP.fetch("https://example.com")
    end

    test "falls back to jsonlink.io when the site body cannot be parsed" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 2, fn conn ->
        case conn.host do
          "example.com" -> Req.Test.json(conn, %{"title" => "json"})
          "jsonlink.io" -> Req.Test.json(conn, %{"title" => "JL Title"})
        end
      end)

      assert {:ok, %PreviewMetadata{title: "JL Title"}} =
               HTTP.fetch("https://example.com")
    end

    test "falls back to opengraph.io when jsonlink.io returns empty metadata" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 3, fn conn ->
        case conn.host do
          "example.com" ->
            Plug.Conn.send_resp(conn, 404, "nope")

          "jsonlink.io" ->
            Req.Test.json(conn, %{"title" => "", "description" => ""})

          "opengraph.io" ->
            Req.Test.json(conn, %{
              "hybridGraph" => %{
                "title" => "OG Title",
                "description" => "OG desc"
              }
            })
        end
      end)

      assert {:ok, %PreviewMetadata{title: "OG Title", description: "OG desc"}} =
               HTTP.fetch("https://example.com")
    end

    test "returns error when the jsonlink.io fallback also fails" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 3, fn conn ->
        case conn.host do
          "example.com" -> Plug.Conn.send_resp(conn, 404, "nope")
          "jsonlink.io" -> Plug.Conn.send_resp(conn, 500, "nope")
          "opengraph.io" -> Plug.Conn.send_resp(conn, 500, "nope")
        end
      end)

      assert {:error, {:http_error, 500}} = HTTP.fetch("https://example.com")
    end
  end
end
