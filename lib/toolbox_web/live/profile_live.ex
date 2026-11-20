defmodule ToolboxWeb.ProfileLive do
  use ToolboxWeb, :live_view
  alias Toolbox.{ApiKeys, Packages}

  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]

    if current_user do
      packages = Packages.list_user_followed_packages(current_user.id)

      {
        :ok,
        assign(
          socket,
          page_title: "Profile",
          search_term: "",
          packages: packages,
          api_keys: ApiKeys.list_api_keys(current_user.id),
          api_key_form: nil,
          created_api_key: nil,
          created_api_key_token: nil
        )
      }
    else
      {
        :ok,
        socket
        |> put_flash(:error, "You must be logged in to view your profile")
        |> redirect(to: ~p"/")
      }
    end
  end

  def handle_event("open_api_key_modal", _params, socket) do
    form = to_form(ApiKeys.change_api_key(socket.assigns.current_user.id))

    {:noreply, assign(socket, api_key_form: form)}
  end

  def handle_event("create_api_key", %{"api_key" => params}, socket) do
    case ApiKeys.create_api_key(socket.assigns.current_user.id, params) do
      {:ok, api_key, token} ->
        {
          :noreply,
          assign(socket,
            created_api_key: api_key,
            created_api_key_token: token,
            api_keys: [api_key | socket.assigns.api_keys]
          )
        }

      {:error, changeset} ->
        {:noreply, assign(socket, api_key_form: to_form(changeset))}
    end
  end

  def handle_event("close_api_key_modal", _params, socket) do
    {
      :noreply,
      assign(socket, api_key_form: nil, created_api_key: nil, created_api_key_token: nil)
    }
  end

  def handle_info({:hide_dropdown, component_id}, socket) do
    send_update(ToolboxWeb.SearchFieldComponent, id: component_id.cid, show_dropdown: false)
    {:noreply, socket}
  end
end
