defmodule UnclickbaiterWeb.PreviewTagsTest do
  use ExUnit.Case, async: true

  alias UnclickbaiterWeb.Components.PreviewTags

  test "to_meta_tags/1 builds tags from a metadata map and filters nils" do
    metadata = %{
      site_name: "ExampleSite",
      title: "Example",
      description: "A site",
      url: "https://example.com",
      image: "https://example.com/img.png"
    }

    assert metadata.title == "Example"
    assert metadata.description == "A site"
    assert metadata.url == "https://example.com"
    assert metadata.image == "https://example.com/img.png"
    assert metadata.site_name == "ExampleSite"

    tags = PreviewTags.to_meta_tags(metadata)
    assert {"og:title", "Example"} in tags
    assert {"og:image", "https://example.com/img.png"} in tags
    assert {"twitter:card", "summary_large_image"} in tags
  end
end
