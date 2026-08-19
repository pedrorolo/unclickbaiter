defmodule Unclickbaiter.PreviewMetadata.HTTPTest do
  use ExUnit.Case, async: true

  import Req.Test

  alias Unclickbaiter.PreviewMetadata.HTTP
  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

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
      expect(Unclickbaiter.PreviewMetadata.HTTP, fn conn ->
        Plug.Conn.send_resp(conn, 404, "nope")
      end)

      assert {:error, {:http_error, 404}} =
               HTTP.fetch("https://example.com")
    end

    test "returns error on transport errors" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, fn conn ->
        transport_error(conn, :nxdomain)
      end)

      assert {:error, %Req.TransportError{reason: :nxdomain}} =
               HTTP.fetch("https://example.com")
    end

    test "returns error for invalid urls" do
      assert {:error, :invalid_url} = HTTP.fetch(nil)
    end
  end
end
