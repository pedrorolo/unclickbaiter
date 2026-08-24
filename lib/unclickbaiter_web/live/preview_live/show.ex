defmodule UnclickbaiterWeb.PreviewLive.Show do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata
  alias Unclickbaiter.Previews

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="max-w-3xl mx-auto mt-6 text-center">
        <div class="mt-4">
          <p id="countdown-message" class="mb-3 text-sm text-base-content/60">
            Redirecting in <strong id="countdown">10</strong>
            seconds unless you press
            <button
              type="button"
              id="stop-countdown"
              class="btn btn-xs btn-warning"
            >Stop!</button>
          </p>
          <.button id="original-preview-link" href={@preview.url} variant="primary">
            <.icon name="hero-arrow-right" class="size-4" />
            Continue to {URI.parse(@preview.url).host || @preview.url}
          </.button>
          <p class="mt-4 text-sm text-base-content/60">
            The preview of the original preview has been overwritten by unclickbaiter:
          </p>
        </div>

        <div class="mt-8 grid grid-cols-1 gap-6 text-left sm:grid-cols-2">
          <div>
            <h2 class="text-lg font-semibold leading-8">Original</h2>
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
            <h2 class="text-lg font-semibold leading-8">New</h2>
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
      <div
        id="redirect-countdown"
        phx-hook=".RedirectCountdown"
        data-url={@preview.url}
        class="hidden"
      >
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".RedirectCountdown">
        export default {
          mounted() {
            const url = this.el.getAttribute("data-url")
            const countdownEl = document.getElementById("countdown")
            const messageEl = document.getElementById("countdown-message")
            const stopBtn = document.getElementById("stop-countdown")
            let seconds = 10

            const timer = setInterval(() => {
              seconds--
              countdownEl.textContent = seconds

              if (seconds <= 0) {
                clearInterval(timer)
                window.location.href = url
              }
            }, 1000)

            stopBtn.addEventListener("click", () => {
              clearInterval(timer)
              messageEl.remove()
            })
          }
        }
      </script>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    preview = Previews.get_preview_by_slug!(slug)

    {:ok,
     socket
     |> assign_new(:current_scope, fn -> nil end)
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
