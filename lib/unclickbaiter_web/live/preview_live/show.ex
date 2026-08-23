defmodule UnclickbaiterWeb.PreviewLive.Show do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata
  alias Unclickbaiter.Previews

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-3xl mx-auto mt-6 text-center">
        <p class="mt-2">
          The preview of the original preview has been overwritten by unclickbaiter.
        </p>

        <div class="mt-6">
          <.button id="original-preview-link" href={@preview.url} variant="primary">
            <.icon name="hero-arrow-right" class="size-4" />
            Continue to {URI.parse(@preview.url).host || @preview.url}
          </.button>
        </div>

        <div class="mt-8 grid grid-cols-1 gap-6 text-left sm:grid-cols-2">
          <div>
            <h2 class="text-lg font-semibold leading-8">Original preview</h2>
            <.preview_card
              id="original-preview-card"
              class="mt-2"
              url={@preview.url}
              title={@preview.original_preview_metadata.title}
              description={@preview.original_preview_metadata.description}
              image_url={@preview.original_preview_metadata.image_url}
            />
          </div>
          <div>
            <h2 class="text-lg font-semibold leading-8">New preview</h2>
            <.preview_card
              id="new-preview-card"
              class="mt-2"
              url={@preview.url}
              title={@preview.preview_metadata.title}
              description={@preview.preview_metadata.description}
              image_url={@preview.preview_metadata.image_url}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    preview = Previews.get_preview_by_slug!(slug)

    {:ok,
     socket
     |> assign(:preview, %{
       preview
       | original_preview_metadata:
           preview.original_preview_metadata || %PreviewMetadata{}
     })
     |> assign(:metadata, preview_to_metadata(preview))
     |> assign(:page_title, preview.preview_metadata.title)}
  end

  defp preview_to_metadata(preview) do
    pm = preview.preview_metadata

    %{
      title: pm.title,
      description: pm.description,
      url: preview.url,
      image: pm.image_url,
      type: "website",
      twitter_card: "summary_large_image"
    }
  end
end
