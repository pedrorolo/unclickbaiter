defmodule Unclickbaiter.PreviewMetadata.HTTP.JsonLinkTest do
  use ExUnit.Case, async: false

  import Req.Test

  alias Unclickbaiter.PreviewMetadata.HTTP.JsonLink
  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

  describe "fetch/1" do
    test "fetches metadata from the api" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        assert conn.query_string =~ "url="
        assert conn.query_string =~ "api_key="

        Req.Test.json(conn, %{
          "title" => "API Title",
          "description" => "API desc",
          "image" => "https://cdn.example.com/api.png"
        })
      end)

      assert {:ok,
              %PreviewMetadata{
                title: "API Title",
                description: "API desc",
                image_url: "https://cdn.example.com/api.png"
              }} = JsonLink.fetch("https://example.com")
    end

    test "falls back to the images list when image is missing" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        Req.Test.json(conn, %{
          "title" => "T",
          "image" => nil,
          "images" => ["https://cdn.example.com/img.png"]
        })
      end)

      assert {:ok,
              %PreviewMetadata{image_url: "https://cdn.example.com/img.png"}} =
               JsonLink.fetch("https://example.com")
    end

    test "uses the jsonlink api key from the encrypted secrets" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        assert conn.query_string =~
                 "api_key=pk_3d1aaaaf9abb4d7b8899c3f16c1aa00fc5a69718"

        Req.Test.json(conn, %{"title" => "T"})
      end)

      assert {:ok, %PreviewMetadata{}} = JsonLink.fetch("https://example.com")
    end

    test "returns error on non-2xx status" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        Plug.Conn.send_resp(conn, 500, "nope")
      end)

      assert {:error, {:http_error, 500}} =
               JsonLink.fetch("https://example.com")
    end

    test "returns error when the response is not json" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        Plug.Conn.send_resp(conn, 200, "not json")
      end)

      assert {:error, :invalid_response} =
               JsonLink.fetch("https://example.com")
    end

    test "returns error when the api returns empty metadata" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        Req.Test.json(conn, %{
          "title" => "",
          "description" => "",
          "images" => []
        })
      end)

      assert {:error, :empty_metadata} = JsonLink.fetch("https://example.com")
    end

    test "returns error for invalid urls" do
      assert {:error, :invalid_url} = JsonLink.fetch(nil)
    end
  end
end
