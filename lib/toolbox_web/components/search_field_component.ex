defmodule ToolboxWeb.SearchFieldComponent do
  use ToolboxWeb, :live_component

  def render(assigns) do
    assigns =
      assigns
      |> assign(form: to_form(%{}))

    ~H"""
    <div>
      <.simple_form for={@form} phx-submit="search" phx-target={@myself}>
        <.input field={@form[:term]} placeholder="Search for packages" />
        <:actions>
          <.button>Search</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def handle_event("search", %{"term" => term}, socket) do
    {:noreply, redirect(socket, to: ~p"/searches/#{term}")}
  end
end
