defmodule ToolboxWeb.SearchFieldComponent do
  use ToolboxWeb, :live_component
  alias Toolbox.Packages

  attr :class, :string, default: ""
  attr :autofocus, :boolean, default: false

  def mount(socket) do
    {:ok,
     assign(socket, search_results: [], show_dropdown: false, search_term: "", selected_index: -1)}
  end

  def update(assigns, socket) do
    # Ensure class and autofocus have default values if not provided
    assigns =
      assigns
      |> Map.put_new(:class, "")
      |> Map.put_new(:autofocus, false)

    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div
      class="relative"
      phx-click-away="hide_dropdown_immediately"
      phx-target={@myself}
      {test_attrs(search_container: true)}
    >
      <.form
        for={nil}
        phx-submit="search"
        phx-target={@myself}
        class={"flex h-[40px] pr-3 py-2 justify-between items-center rounded-[6px] sm:border border-surface-alt focus-within:border-secondary-text bg-surface #{@class}"}
        {test_attrs(search_form: true)}
      >
        <input
          type="search"
          name="term"
          value={@search_term}
          placeholder="Find packages"
          class="grow border-0 focus:ring-0 bg-transparent placeholder:text-secondary-text"
          required
          autofocus={@autofocus}
          autocomplete="off"
          autocapitalize="off"
          phx-change="typeahead_search"
          phx-keydown="handle_keydown"
          phx-target={@myself}
          phx-debounce="300"
          phx-blur="hide_dropdown"
          phx-focus="show_dropdown_if_results"
          {test_attrs(search_input: true)}
        />
        <button
          type="submit"
          class="flex items-center justify-center"
          {test_attrs(search_button: true)}
        >
          <.icon name="hero-magnifying-glass" class="h-5 w-5 text-secondary-text" />
        </button>
      </.form>

      <%= if @show_dropdown do %>
        <div
          class="absolute top-full left-0 right-0 z-50 mt-1 bg-surface rounded-md shadow-lg max-h-60 overflow-auto"
          {test_attrs(search_dropdown: true)}
        >
          <%= if length(@search_results) > 0 do %>
            <% {exact_matches, other_matches} = split_exact_matches(@search_results, @search_term) %>

            <%= if length(exact_matches) > 0 do %>
              <div class="px-3 pt-2 text-[14px] text-secondary-text">
                Exact Match:
              </div>
              <ul {test_attrs(exact_matches_list: true)}>
                <li
                  :for={{package, index} <- Enum.with_index(exact_matches)}
                  class={"px-3 py-2 cursor-pointer last:border-b-0 truncate #{if index == @selected_index, do: "bg-surface-alt", else: "hover:bg-surface-alt"}"}
                  phx-click="select_result"
                  phx-value-name={package.name}
                  phx-target={@myself}
                  {test_attrs(search_result_item: package.name, search_result_index: index)}
                >
                  <div>
                    <span class="text-[16px] text-primary-text" {test_attrs(package_name: true)}>
                      {package.name}
                    </span>
                    <span class="text-[14px] text-secondary-text" {test_attrs(package_version: true)}>
                      {package.latest_hexpm_snapshot.data["latest_version"]}
                    </span>
                  </div>
                  <span
                    class="text-[14px] text-secondary-text"
                    {test_attrs(package_description: true)}
                  >
                    {package.latest_hexpm_snapshot.data["meta"]["description"]}
                  </span>
                </li>
              </ul>
            <% end %>

            <%= if length(other_matches) > 0 do %>
              <div class="px-3 pt-2 text-[14px] text-secondary-text">
                {length(other_matches)} Results Found:
              </div>
              <ul class="py-1" {test_attrs(other_results_list: true)}>
                <li
                  :for={{package, index} <- Enum.with_index(other_matches, length(exact_matches))}
                  class={"px-3 py-2 cursor-pointer truncate #{if index == @selected_index, do: "bg-surface-alt", else: "hover:bg-surface-alt"}"}
                  phx-click="select_result"
                  phx-value-name={package.name}
                  phx-target={@myself}
                  {test_attrs(search_result_item: package.name, search_result_index: index)}
                >
                  <div>
                    <span class="text-[16px] text-primary-text" {test_attrs(package_name: true)}>
                      {package.name}
                    </span>
                    <span class="text-[14px] text-secondary-text" {test_attrs(package_version: true)}>
                      {package.latest_hexpm_snapshot.data["latest_version"]}
                    </span>
                  </div>
                  <span
                    class="text-[14px] text-secondary-text"
                    {test_attrs(package_description: true)}
                  >
                    {package.latest_hexpm_snapshot.data["meta"]["description"]}
                  </span>
                </li>
              </ul>
            <% end %>
          <% else %>
            <div class="p-3" {test_attrs(no_results_message: true)}>
              <p>No results for "{@search_term}"</p>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  # Helper function to split exact matches from other matches
  defp split_exact_matches(packages, search_term) do
    Enum.split_with(packages, fn package ->
      String.downcase(package.name) == String.downcase(search_term)
    end)
  end

  def handle_event("typeahead_search", %{"term" => term}, socket) do
    term = String.trim(term)

    search_results =
      if String.length(term) >= 2 do
        {search_results, _} = Packages.search(term)
        search_results
      else
        []
      end

    # Only show dropdown if we have a valid search term (>= 2 characters)
    show_dropdown = String.length(term) >= 2

    {:noreply,
     assign(socket,
       search_results: search_results,
       show_dropdown: show_dropdown,
       search_term: term,
       selected_index: -1
     )}
  end

  def handle_event("handle_keydown", %{"key" => "ArrowDown"}, socket) do
    max_index = length(socket.assigns.search_results) - 1
    new_index = min(socket.assigns.selected_index + 1, max_index)
    {:noreply, assign(socket, selected_index: new_index)}
  end

  def handle_event("handle_keydown", %{"key" => "ArrowUp"}, socket) do
    new_index = max(socket.assigns.selected_index - 1, -1)
    {:noreply, assign(socket, selected_index: new_index)}
  end

  def handle_event("handle_keydown", %{"key" => "Enter"}, socket) do
    if socket.assigns.selected_index >= 0 and
         socket.assigns.selected_index < length(socket.assigns.search_results) do
      selected_result = Enum.at(socket.assigns.search_results, socket.assigns.selected_index)
      {:noreply, redirect(socket, to: ~p"/packages/#{selected_result.name}")}
    else
      # Let the form submission handle the search
      {:noreply, socket}
    end
  end

  def handle_event("handle_keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, show_dropdown: false, selected_index: -1)}
  end

  def handle_event("handle_keydown", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("search", %{"term" => term}, socket) do
    term = String.trim(term)
    {:noreply, redirect(socket, to: ~p"/searches/#{term}")}
  end

  def handle_event("select_result", %{"name" => name}, socket) do
    {:noreply, redirect(socket, to: ~p"/packages/#{name}")}
  end

  def handle_event("hide_dropdown", _params, socket) do
    # Use a shorter delay to allow click events on dropdown items to fire first
    Process.send_after(self(), {:hide_dropdown, socket.assigns.myself}, 100)
    {:noreply, socket}
  end

  def handle_event("hide_dropdown_immediately", _params, socket) do
    {:noreply, assign(socket, show_dropdown: false, selected_index: -1)}
  end

  def handle_event("show_dropdown_if_results", _params, socket) do
    show_dropdown = String.length(socket.assigns.search_term) >= 2

    {:noreply, assign(socket, show_dropdown: show_dropdown, selected_index: -1)}
  end

  def handle_info({:hide_dropdown, component_id}, socket) do
    if socket.assigns.myself == component_id do
      {:noreply, assign(socket, show_dropdown: false, selected_index: -1)}
    else
      {:noreply, socket}
    end
  end
end
