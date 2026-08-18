defmodule UnclickbaiterWeb.OpenGraphComponentTest do
  use ExUnit.Case, async: true

  alias Unclickbaiter.Sites.Site
  alias UnclickbaiterWeb.Components.PreviewMetadata

  test "to_meta_tags builds tags from a metadata map and filters nils" do
    site = %Site{
      title: "Example",
      description: "A site",
      url: "https://example.com",
      image_url: "https://example.com/img.png"
    }

    metadata = %{
      site_name: "ExampleSite",
      title: site.title,
      description: site.description,
      url: site.url,
      image: site.image_url
    }

    assert metadata.title == "Example"
    assert metadata.description == "A site"
    assert metadata.url == "https://example.com"
    assert metadata.image == "https://example.com/img.png"
    assert metadata.site_name == "ExampleSite"

    tags = PreviewMetadata.to_meta_tags(metadata)
    assert {"og:title", "Example"} in tags
    assert {"og:image", "https://example.com/img.png"} in tags
    assert {"twitter:card", "summary_large_image"} in tags
  end
end
