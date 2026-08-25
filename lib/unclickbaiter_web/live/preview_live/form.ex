defmodule UnclickbaiterWeb.PreviewLive.Form do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.PreviewMetadata.HTTP
  alias Unclickbaiter.PreviewMetadata.PreviewMetadata
  alias Unclickbaiter.Previews
  alias Unclickbaiter.Previews.Preview

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        {@page_title}
        <:subtitle>
          Use this form to manage preview records in your database.
        </:subtitle>
      </.header>

      <%= if @saved_preview do %>
        <div class="alert alert-info mb-6 flex items-center gap-3">
          <.icon name="hero-information-circle" class="size-5 shrink-0" />
          <span>
            Preview saved!
            <.link
              navigate={~p"/p/#{@saved_preview}"}
              class="underline font-semibold"
            >View it here</.link>
          </span>
          <button
            type="button"
            class="btn btn-xs btn-ghost"
            phx-click="copy-show-url"
            phx-value-slug={@saved_preview.slug}
          >
            <.icon name="hero-clipboard" class="size-4" /> Copy to clipboard
          </button>
        </div>
      <% end %>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <.form for={@form} id="preview-form" phx-change="validate" phx-submit="save">
          <.input field={@form[:url]} type="text" label="Url" />
          <%= if preview_url(@form) do %>
            <%= if @metadata_fetching do %>
              <p class="mt-1 text-sm text-slate-500">Fetching preview metadata…</p>
            <% end %>
            <%= if @metadata_fetch_failed do %>
              <div
                id="metadata-fetch-error"
                class="mt-2 flex items-start gap-2 rounded-lg border border-amber-500/40 bg-amber-500/10 p-3 text-sm text-amber-700 dark:text-amber-300"
              >
                <.icon
                  name="hero-exclamation-triangle"
                  class="mt-0.5 size-4 shrink-0"
                />
                <p>
                  We couldn't fetch the preview metadata for this preview. Please fill in the
                  fields manually.
                </p>
              </div>
            <% end %>
            <.inputs_for :let={pm} field={@form[:preview_metadata]}>
              <.input field={pm[:title]} type="textarea" label="Title" rows={2} />
              <.input
                field={pm[:description]}
                type="textarea"
                label="Description"
                rows={4}
              />
              <.input field={pm[:image_url]} type="text" label="Image URL" />
            </.inputs_for>
            <%= if has_original_preview_metadata?(@preview) ||
                    Map.has_key?(@form.params, "original_preview_metadata") do %>
              <.inputs_for
                :let={original_pm}
                field={@form[:original_preview_metadata]}
              >
                <.input field={original_pm[:title]} type="hidden" />
                <.input field={original_pm[:description]} type="hidden" />
                <.input field={original_pm[:image_url]} type="hidden" />
              </.inputs_for>
            <% end %>
          <% end %>
          <footer>
            <.button
              :if={preview_url(@form)}
              phx-disable-with="Saving..."
              variant="primary"
            >Save Preview</.button>
            <.button navigate={return_path(@return_to, @preview)}>Cancel</.button>
          </footer>
        </.form>

        <div>
          <.preview_card
            id="preview-card"
            class="mt-2"
            fetching={@metadata_fetching}
            url={if @preview.slug, do: ~p"/p/#{@preview}", else: preview_url(@form)}
            title={preview_value(@form, :title)}
            description={preview_value(@form, :description)}
            image_url={preview_image_url(@form)}
          />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> assign(:preview_params, %{})
     |> assign(:fetched_url, nil)
     |> assign(:metadata_fetch_ref, nil)
     |> assign(:metadata_fetching, false)
     |> assign(:metadata_fetch_failed, false)
     |> assign(:saved_preview, nil)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"slug" => slug}) do
    preview = Previews.get_preview_by_slug!(slug)

    if preview.user_id != socket.assigns.current_scope.user.id do
      socket
      |> Phoenix.LiveView.put_flash(
        :error,
        "You can only edit your own previews"
      )
      |> Phoenix.LiveView.redirect(to: ~p"/p")
    else
      saved_preview =
        if socket.assigns.flash["saved_preview_slug"] == slug, do: preview

      socket
      |> assign(:page_title, "Edit Preview")
      |> assign(:preview, preview)
      |> assign(:fetched_url, preview.url)
      |> assign(:form, to_form(Previews.change_preview(preview)))
      |> assign(:saved_preview, saved_preview)
    end
  end

  defp apply_action(socket, :new, _params) do
    preview = %Preview{}

    socket
    |> assign(:page_title, "New Preview")
    |> assign(:preview, preview)
    |> assign(:form, to_form(Previews.change_preview(preview)))
  end

  @impl true
  def handle_event("validate", %{"preview" => preview_params}, socket) do
    changeset = Previews.change_preview(socket.assigns.preview, preview_params)

    socket =
      assign(socket,
        preview_params: preview_params,
        form: to_form(changeset, action: :validate),
        saved_preview: nil
      )

    {:noreply, fetch_preview_metadata(socket, preview_params)}
  end

  def handle_event("save", %{"preview" => preview_params}, socket) do
    save_preview(socket, socket.assigns.live_action, preview_params)
  end

  def handle_event("copy-show-url", %{"slug" => slug}, socket) do
    url = "/p/#{slug}"
    {:noreply, push_event(socket, "copy-to-clipboard", %{url: url})}
  end

  @impl true
  def handle_info({:preview_metadata_fetched, ref, result}, socket) do
    if ref != socket.assigns.metadata_fetch_ref do
      {:noreply, socket}
    else
      {:noreply, apply_fetched_metadata(socket, result)}
    end
  end

  defp fetch_preview_metadata(socket, %{"url" => url}) when is_binary(url) do
    if HTTP.fetchable_url?(url) and url != socket.assigns.fetched_url do
      ref = make_ref()
      pid = self()

      Task.start(fn ->
        send(
          pid,
          {:preview_metadata_fetched, ref,
           Unclickbaiter.PreviewMetadata.fetch(url)}
        )
      end)

      socket
      |> assign(:metadata_fetch_ref, ref)
      |> assign(:metadata_fetching, true)
      |> assign(:metadata_fetch_failed, false)
    else
      socket
    end
  end

  defp fetch_preview_metadata(socket, _preview_params), do: socket

  defp apply_fetched_metadata(socket, {:ok, pm}) do
    preview_params =
      socket.assigns.preview_params
      |> merge_metadata(pm)

    changeset = Previews.change_preview(socket.assigns.preview, preview_params)

    socket
    |> assign(:preview_params, preview_params)
    |> assign(:fetched_url, preview_params["url"])
    |> assign(:metadata_fetching, false)
    |> assign(:metadata_fetch_failed, false)
    |> assign(:form, to_form(changeset))
  end

  defp apply_fetched_metadata(socket, {:error, _reason}) do
    socket
    |> assign(:metadata_fetching, false)
    |> assign(:metadata_fetch_failed, true)
  end

  defp merge_metadata(preview_params, pm) do
    fields = %{
      "title" => pm.title,
      "description" => pm.description,
      "image_url" => pm.image_url
    }

    preview_params
    |> Map.update("preview_metadata", fields, &Map.merge(&1, fields))
    |> Map.update("original_preview_metadata", fields, &Map.merge(&1, fields))
  end

  defp save_preview(socket, :edit, preview_params) do
    preview = socket.assigns.preview

    if preview.user_id != socket.assigns.current_scope.user.id do
      {:noreply,
       socket
       |> Phoenix.LiveView.put_flash(
         :error,
         "You can only edit your own previews"
       )
       |> Phoenix.LiveView.redirect(to: ~p"/p")}
    else
      case Previews.update_preview(preview, preview_params) do
        {:ok, preview} ->
          changeset = Previews.change_preview(preview)

          {:noreply,
           socket
           |> assign(:preview, preview)
           |> assign(:form, to_form(changeset))
           |> assign(:saved_preview, preview)}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:noreply, assign(socket, form: to_form(changeset))}
      end
    end
  end

  defp save_preview(socket, :new, preview_params) do
    case Previews.create_preview(
           socket.assigns.current_scope.user,
           preview_params
         ) do
      {:ok, preview} ->
        {:noreply,
         socket
         |> put_flash("saved_preview_slug", preview.slug)
         |> push_navigate(to: ~p"/p/#{preview}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _preview), do: ~p"/p"
  defp return_path("show", preview), do: ~p"/p/#{preview}"

  defp has_original_preview_metadata?(%{
         original_preview_metadata: %PreviewMetadata{} = pm
       }) do
    not is_nil(pm.id)
  end

  defp has_original_preview_metadata?(_preview), do: false

  defp preview_value(form, field) do
    case form[:preview_metadata] do
      %Phoenix.HTML.FormField{value: %Ecto.Changeset{} = cs} ->
        Map.get(cs.changes, field) || Map.get(cs.data || %{}, field)

      %Phoenix.HTML.FormField{value: value} when is_struct(value) ->
        Map.get(value, field)

      %Phoenix.HTML.Form{} = pm_form ->
        pm_form[field].value

      _ ->
        nil
    end
  end

  defp preview_image_url(form) do
    case preview_value(form, :image_url) do
      url when is_binary(url) and url != "" -> url
      _ -> nil
    end
  end

  defp preview_url(form) do
    case form[:url] do
      %Phoenix.HTML.FormField{value: value} -> value
      %Phoenix.HTML.Form{} -> form[:url].value
      _ -> nil
    end
  end
end
