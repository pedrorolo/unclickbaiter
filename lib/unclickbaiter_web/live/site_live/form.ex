defmodule UnclickbaiterWeb.SiteLive.Form do
  use UnclickbaiterWeb, :live_view

  alias Unclickbaiter.PreviewMetadata.PreviewMetadata
  alias Unclickbaiter.Sites
  alias Unclickbaiter.Sites.Site

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@page_title}
        <:subtitle>
          Use this form to manage site records in your database.
        </:subtitle>
      </.header>

      <.form for={@form} id="site-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:url]} type="text" label="Url" />
        <.inputs_for :let={pm} field={@form[:preview_metadata]}>
          <.input field={pm[:title]} type="text" label="Title" />
          <.input field={pm[:description]} type="text" label="Description" />
          <.input field={pm[:image_url]} type="text" label="Image URL" />
        </.inputs_for>
        <%= if has_original_preview_metadata?(@site) do %>
          <.inputs_for :let={original_pm} field={@form[:original_preview_metadata]}>
            <.input field={original_pm[:title]} type="hidden" />
            <.input field={original_pm[:description]} type="hidden" />
            <.input field={original_pm[:image_url]} type="hidden" />
          </.inputs_for>
        <% end %>
        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Site</.button>
          <.button navigate={return_path(@return_to, @site)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    site = Sites.get_site!(id)

    socket
    |> assign(:page_title, "Edit Site")
    |> assign(:site, site)
    |> assign(:form, to_form(Sites.change_site(site)))
  end

  defp apply_action(socket, :new, _params) do
    site = %Site{}

    socket
    |> assign(:page_title, "New Site")
    |> assign(:site, site)
    |> assign(:form, to_form(Sites.change_site(site)))
  end

  @impl true
  def handle_event("validate", %{"site" => site_params}, socket) do
    changeset = Sites.change_site(socket.assigns.site, site_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"site" => site_params}, socket) do
    save_site(socket, socket.assigns.live_action, site_params)
  end

  defp save_site(socket, :edit, site_params) do
    case Sites.update_site(socket.assigns.site, site_params) do
      {:ok, site} ->
        {:noreply,
         socket
         |> put_flash(:info, "Site updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, site))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_site(socket, :new, site_params) do
    case Sites.create_site(site_params) do
      {:ok, site} ->
        {:noreply,
         socket
         |> put_flash(:info, "Site created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, site))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _site), do: ~p"/sites"
  defp return_path("show", site), do: ~p"/sites/#{site}"

  defp has_original_preview_metadata?(%{
         original_preview_metadata: %PreviewMetadata{} = pm
       }) do
    not is_nil(pm.id)
  end

  defp has_original_preview_metadata?(_site), do: false
end
