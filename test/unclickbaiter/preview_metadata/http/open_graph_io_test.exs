defmodule Unclickbaiter.PreviewMetadata.HTTP.OpenGraphIOTest do
  use ExUnit.Case, async: false

  import Req.Test

  alias Unclickbaiter.PreviewMetadata.HTTP.OpenGraphIO
  alias Unclickbaiter.PreviewMetadata.PreviewMetadata

  describe "fetch/1" do
    test "fetches metadata from the api" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        assert conn.path_info == [
                 "api",
                 "3.0",
                 "site",
                 "https%3A%2F%2Fexample.com"
               ]

        assert conn.query_string =~ "app_id="
        assert conn.query_string =~ "use_premium=true"
        assert conn.query_string =~ "use_superior=true"
        assert conn.query_string =~ "full_render=true"
        assert conn.query_string =~ "retry=true"

        Req.Test.json(conn, %{
          "hybridGraph" => %{
            "title" => "Hybrid Title",
            "description" => "Hybrid desc"
          },
          "openGraph" => %{
            "image" => %{
              "url" => "https://cdn.example.com/og.png",
              "width" => "1200"
            }
          }
        })
      end)

      assert {:ok,
              %PreviewMetadata{
                title: "Hybrid Title",
                description: "Hybrid desc",
                image_url: "https://cdn.example.com/og.png"
              }} = OpenGraphIO.fetch("https://example.com")
    end

    test "falls back to openGraph and htmlInferred sections" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        Req.Test.json(conn, %{
          "hybridGraph" => %{},
          "openGraph" => %{"title" => "OG Title"},
          "htmlInferred" => %{"description" => "Inferred desc"}
        })
      end)

      assert {:ok,
              %PreviewMetadata{
                title: "OG Title",
                description: "Inferred desc",
                image_url: nil
              }} = OpenGraphIO.fetch("https://example.com")
    end

    test "uses the opengraph.io api key from the encrypted secrets" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        assert conn.query_string =~
                 "app_id=ba4209ff-2eaa-414a-84d1-5209d98f81e3"

        Req.Test.json(conn, %{"hybridGraph" => %{"title" => "T"}})
      end)

      assert {:ok, %PreviewMetadata{}} =
               OpenGraphIO.fetch("https://example.com")
    end

    test "returns error on non-2xx status" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        Plug.Conn.send_resp(conn, 500, "nope")
      end)

      assert {:error, {:http_error, 500}} =
               OpenGraphIO.fetch("https://example.com")
    end

    test "returns error when the response is not json" do
      expect(Unclickbaiter.PreviewMetadata.HTTP, 1, fn conn ->
        Plug.Conn.send_resp(conn, 200, "not json")
      end)

      assert {:error, :invalid_response} =
               OpenGraphIO.fetch("https://example.com")
    end

    test "returns error for invalid urls" do
      assert {:error, :invalid_url} = OpenGraphIO.fetch(nil)
    end
  end
end
