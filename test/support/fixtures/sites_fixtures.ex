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
        description: "some description",
        title: "some title",
        url: "some url"
      })
      |> Unclickbaiter.Sites.create_site()

    site
  end
end
