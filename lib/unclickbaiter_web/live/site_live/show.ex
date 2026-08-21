defmodule UnclickbaiterWeb.SiteLive.Show do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata
  alias Unclickbaiter.Sites

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-3xl mx-auto mt-6 text-center">
        <p class="mt-2">
          The preview of the original site has been overwritten by unclickbaiter.
        </p>

        <div class="mt-6">
          <.button id="original-site-link" href={@site.url} variant="primary">
            <.icon name="hero-arrow-right" class="size-4" />
            Continue to {URI.parse(@site.url).host || @site.url}
          </.button>
        </div>

        <div class="mt-8 grid grid-cols-1 gap-6 text-left sm:grid-cols-2">
          <div>
            <h2 class="text-lg font-semibold leading-8">Original preview</h2>
            <.preview_card
              id="original-preview-card"
              class="mt-2"
              url={@site.url}
              title={@site.original_preview_metadata.title}
              description={@site.original_preview_metadata.description}
              image_url={@site.original_preview_metadata.image_url}
            />
          </div>
          <div>
            <h2 class="text-lg font-semibold leading-8">New preview</h2>
            <.preview_card
              id="new-preview-card"
              class="mt-2"
              url={@site.url}
              title={@site.preview_metadata.title}
              description={@site.preview_metadata.description}
              image_url={@site.preview_metadata.image_url}
            />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    site = Sites.get_site!(id)

    {:ok,
     socket
     |> assign(:site, %{
       site
       | original_preview_metadata:
           site.original_preview_metadata || %PreviewMetadata{}
     })
     |> assign(:metadata, site_to_metadata(site))
     |> assign(:page_title, site.preview_metadata.title)}
  end

  defp site_to_metadata(site) do
    pm = site.preview_metadata

    %{
      title: pm.title,
      description: pm.description,
      url: site.url,
      image: pm.image_url,
      type: "website",
      twitter_card: "summary_large_image"
    }
  end
end
