defmodule Unclickbaiter.PreviewsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Unclickbaiter.Previews` context.
  """

  @doc """
  Generate a preview.
  """
  def preview_fixture(attrs \\ %{}) do
    {:ok, preview} =
      attrs
      |> Enum.into(%{
        url: "some url",
        preview_metadata: %{
          description: "some description",
          title: "some title",
          image_url: "https://example.com/image.png"
        }
      })
      |> Unclickbaiter.Previews.create_preview()

    preview
  end
end
