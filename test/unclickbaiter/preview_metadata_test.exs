defmodule Unclickbaiter.PreviewMetadataTest do
  use Unclickbaiter.DataCase, async: false

  import Req.Test

  alias Unclickbaiter.PreviewMetadata
  alias Unclickbaiter.PreviewMetadata.HTTP.ProviderCache
  alias Unclickbaiter.PreviewMetadata.PreviewMetadata, as: PM

  setup do
    ProviderCache.clear()
    :ok
  end

  describe "fetch/1" do
    test "returns the stored original preview metadata when a site exists for the url" do
      url = "https://example.com/cached"

      Unclickbaiter.Sites.create_site(%{
        url: url,
        preview_metadata: %{
          title: "Preview title",
          description: "Preview description"
        },
        original_preview_metadata: %{
          title: "Original title",
          description: "Original description"
        }
      })

      assert {:ok,
              %PM{
                title: "Original title",
                description: "Original description",
                image_url: nil
              }} = PreviewMetadata.fetch(url)
    end

    test "delegates to the http fetch when the site has no original preview metadata" do
      url = "https://example.com"

      Unclickbaiter.Sites.create_site(%{
        url: url,
        preview_metadata: %{
          title: "Preview title",
          description: "Preview description"
        }
      })

      expect(Unclickbaiter.PreviewMetadata.HTTP, fn conn ->
        html(conn, """
        <html>
          <head>
            <meta property="og:title" content="Fresh Title" />
          </head>
        </html>
        """)
      end)

      assert {:ok, %PM{title: "Fresh Title"}} = PreviewMetadata.fetch(url)
    end

    test "returns error for invalid urls" do
      assert {:error, :invalid_url} = PreviewMetadata.fetch(nil)
    end
  end
end
