defmodule Unclickbaiter.SitesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Unclickbaiter.Sites` context.
  """

  @doc """
  Generate a site.
  """
  def site_fixture(attrs \\ %{}) do
    {:ok, site} =
      attrs
      |> Enum.into(%{
        url: "some url",
        preview_metadata: %{
          description: "some description",
          title: "some title",
          image_url: "https://example.com/image.png"
        }
      })
      |> Unclickbaiter.Sites.create_site()

    site
  end
end
