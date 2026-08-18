defmodule UnclickbaiterWeb.SiteLive.Show do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.Sites

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-3xl mx-auto mt-6 text-center">
        <%= if @site.image_url do %>
          <img src={@site.image_url} alt={@site.title} class="mx-auto mb-4 rounded shadow-sm w-full max-w-md object-cover" />
        <% end %>

        <p
          id="redirect-notice"
          phx-hook=".RedirectToSite"
          phx-update="ignore"
          data-url={@site.url}
          class="mt-2"
        >
          The preview of the original site has been overwritten by unclickbaiter.
        </p>

        <p class="mt-2">
          Redirecting to {URI.parse(@site.url).host || @site.url} in 3 seconds...
        </p>

        <script :type={Phoenix.LiveView.ColocatedHook} name=".RedirectToSite">
          export default {
            mounted() {
              setTimeout(() => {
                window.location.href = this.el.dataset.url
              }, 3000)
            }
          }
        </script>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    site = Sites.get_site!(id)

    {:ok,
     socket
     |> assign(:page_title, site.title)
     |> assign(:page_description, site.description)
     |> assign(:site, site)}
  end
end
