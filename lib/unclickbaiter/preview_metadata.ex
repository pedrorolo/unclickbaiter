defmodule Unclickbaiter.PreviewMetadata do
  @moduledoc """
  The PreviewMetadata context.

  Provides the public API for fetching and building preview metadata
  for previews.
  """

  import Ecto.Query, warn: false

  alias Unclickbaiter.PreviewMetadata.HTTP
  alias Unclickbaiter.PreviewMetadata.PreviewMetadata, as: PM
  alias Unclickbaiter.Previews
  alias Unclickbaiter.Repo

  @doc """
  Fetches the preview metadata for the given `url`.

  When a preview with `url` already has an `original_preview_metadata` stored,
  that metadata is returned without making any HTTP request. Otherwise the
  fetch is delegated to `Unclickbaiter.PreviewMetadata.HTTP`.

  Returns `{:ok, %PreviewMetadata.PreviewMetadata{}}` or
  `{:error, reason}` when the preview cannot be fetched.
  """
  def fetch(url) when is_binary(url) do
    case Previews.get_original_preview_metadata(url) do
      {:ok, pm} -> {:ok, pm}
      :error -> HTTP.fetch(url)
    end
  end

  def fetch(_url), do: {:error, :invalid_url}

  @doc """
  Deletes the preview metadata with the given `id` unless it is still
  referenced by another preview as its `original_preview_metadata`.
  """
  def delete_original_preview_metadata_if_unreferenced(id)
      when is_integer(id) do
    case Repo.get(PM, id) do
      nil ->
        :ok

      pm ->
        if PM.referencing_previews_count(id) == 0 do
          Repo.delete!(pm)
        end
    end
  end

  def delete_original_preview_metadata_if_unreferenced(_id), do: :ok
end
