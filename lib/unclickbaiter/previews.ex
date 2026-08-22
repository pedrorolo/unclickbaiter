defmodule Unclickbaiter.Previews do
  @moduledoc """
  The Previews context.
  """

  import Ecto.Query, warn: false
  alias Unclickbaiter.Repo

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata
  alias Unclickbaiter.Previews.Preview
  alias Unclickbaiter.Slug

  @doc """
  Returns the list of previews.

  ## Examples

      iex> list_sites()
      [%Preview{}, ...]

  """
  def list_sites do
    Preview
    |> Repo.all()
    |> Repo.preload([:preview_metadata, :original_preview_metadata])
  end

  @doc """
  Gets a single preview.

  Raises `Ecto.NoResultsError` if the Preview does not exist.

  ## Examples

      iex> get_preview!(123)
      %Preview{}

      iex> get_preview!(456)
      ** (Ecto.NoResultsError)

  """
  def get_preview!(id) do
    Repo.get!(Preview, id)
    |> Repo.preload([:preview_metadata, :original_preview_metadata])
  end

  @doc """
  Gets a single preview by its slug.

  Raises `Ecto.NoResultsError` if no preview exists with the given slug.

  ## Examples

      iex> get_preview_by_slug!("some-slug")
      %Preview{}

      iex> get_preview_by_slug!("unknown-slug")
      ** (Ecto.NoResultsError)

  """
  def get_preview_by_slug!(slug) when is_binary(slug) do
    Repo.get_by!(Preview, slug: slug)
    |> Repo.preload([:preview_metadata, :original_preview_metadata])
  end

  @doc """
  Creates a preview.

  ## Examples

      iex> create_preview(%{field: value})
      {:ok, %Preview{}}

      iex> create_preview(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_preview(attrs) do
    Slug.with_new_slug(
      Preview,
      fn changeset ->
        changeset
        |> Preview.changeset(attrs)
        |> Repo.insert()
        |> preload_preview_metadata()
      end
    )
  end

  @doc """
  Updates a preview.

  ## Examples

      iex> update_preview(preview, %{field: new_value})
      {:ok, %Preview{}}

      iex> update_preview(preview, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_preview(%Preview{} = preview, attrs) do
    preview
    |> Preview.changeset(attrs)
    |> Repo.update()
    |> preload_preview_metadata()
  end

  @doc """
  Deletes a preview.

  ## Examples

      iex> delete_preview(preview)
      {:ok, %Preview{}}

      iex> delete_preview(preview)
      {:error, %Ecto.Changeset{}}

  """
  def delete_preview(%Preview{} = preview) do
    Repo.transaction(fn ->
      Repo.delete_all(
        from(p in PreviewMetadata, where: p.id == ^preview.preview_metadata_id)
      )

      Repo.delete!(preview)

      Unclickbaiter.PreviewMetadata.delete_original_preview_metadata_if_unreferenced(
        preview.original_preview_metadata_id
      )
    end)

    {:ok, preview}
  end

  @doc """
  Returns the original preview metadata of a preview with the given `url`, if any.

  Returns `{:ok, %PreviewMetadata{}}` or `:error`.

  ## Examples

      iex> get_original_preview_metadata("some url")
      :error

  """
  def get_original_preview_metadata(url) do
    query =
      from(s in Preview,
        where: s.url == ^url and not is_nil(s.original_preview_metadata_id),
        order_by: [asc: s.id],
        preload: [:original_preview_metadata]
      )

    case query |> limit(1) |> Repo.one() do
      %Preview{original_preview_metadata: %PreviewMetadata{} = pm} -> {:ok, pm}
      _ -> :error
    end
  end

  defp preload_preview_metadata({:ok, preview}) do
    {:ok,
     Repo.preload(preview, [:preview_metadata, :original_preview_metadata])}
  end

  defp preload_preview_metadata({:error, changeset}), do: {:error, changeset}

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking preview changes.

  ## Examples

      iex> change_preview(preview)
      %Ecto.Changeset{data: %Preview{}}

  """
  def change_preview(%Preview{} = preview, attrs \\ %{}) do
    Preview.changeset(preview, attrs)
  end
end
