defmodule Unclickbaiter.PreviewMetadata do
  @moduledoc """
  The PreviewMetadata context.

  Provides the public API for fetching and building preview metadata
  for sites.
  """

  alias Unclickbaiter.PreviewMetadata.HTTP

  @doc """
  Fetches the preview metadata for the given `url`.

  Returns `{:ok, %PreviewMetadata.PreviewMetadata{}}` or
  `{:error, reason}` when the site cannot be fetched.
  """
  defdelegate fetch(url), to: HTTP
end
