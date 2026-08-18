defmodule UnclickbaiterWeb.OpenGraphTest do
  use ExUnit.Case, async: true

  alias Unclickbaiter.Sites.Site
  alias UnclickbaiterWeb.OpenGraph

  test "from_site builds struct and to_meta_tags filters nils" do
    site = %Site{
      title: "Example",
      description: "A site",
      url: "https://example.com",
      image_url: "https://example.com/img.png"
    }

    og = OpenGraph.from_site(site, site_name: "ExampleSite")

    assert %OpenGraph{} = og
    assert og.title == "Example"
    assert og.description == "A site"
    assert og.url == "https://example.com"
    assert og.image == "https://example.com/img.png"
    assert og.site_name == "ExampleSite"

    tags = OpenGraph.to_meta_tags(og)
    assert {"og:title", "Example"} in tags
    assert {"og:image", "https://example.com/img.png"} in tags
    assert {"twitter:card", "summary_large_image"} in tags
  end
end
