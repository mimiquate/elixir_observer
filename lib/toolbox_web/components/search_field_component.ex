defmodule ToolboxWeb.SearchFieldComponent do
  use ToolboxWeb, :live_component

  attr :class, :string, default: ""
  attr :autofocus, :boolean, default: false
  attr :search_term, :string, default: ""

  def mount(socket) do
    {:ok,
     assign(socket,
       results: [],
       show_dropdown: false,
       search_term: "",
       focused: false
     )}
  end

  def update(assigns, socket) do
    # Ensure class and autofocus have default values if not provided
    assigns =
      assigns
      |> Map.put_new(:class, "")
      |> Map.put_new(:autofocus, false)
      |> Map.put_new(:search_term, "")

    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    ~H"""
    <div
      class="relative"
      phx-click-away="hide_dropdown"
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
        <div class="relative grow" phx-hook="SearchHighlight" id="search-highlight-container">
          <input
            type="search"
            name="term"
            value={@search_term}
            placeholder="Find packages"
            class="w-full border-0 focus:ring-0 bg-transparent text-transparent placeholder:text-secondary-text caret-primary-text"
            required
            autofocus={@autofocus}
            autocomplete="off"
            autocapitalize="off"
            phx-change="typeahead_search"
            phx-keydown="handle_keydown"
            phx-target={@myself}
            phx-debounce="300"
            phx-focus="handle_focus"
            phx-blur="handle_blur"
            {test_attrs(search_input: true)}
            id="search-input"
          />
          <div
            id="search-highlight"
            class="pl-3 absolute inset-0 pointer-events-none flex items-center z-10"
          >
          </div>
        </div>
        <button
          type="submit"
          class="flex items-center justify-center"
          {test_attrs(search_button: true)}
        >
          <.icon name="hero-magnifying-glass" class="h-5 w-5 text-secondary-text" />
        </button>
      </.form>

      <%= if @focused and !@show_dropdown and String.length(@search_term) < 2 do %>
        <div
          class="absolute top-full left-0 right-0 z-50 mt-1 bg-surface rounded-md shadow-lg border border-surface-alt"
          {test_attrs(semantic_search_help: true)}
        >
          <div class="p-4">
            <h3 class="text-sm font-semibold text-primary-text mb-2">Search Tips</h3>
            <div class="text-sm text-secondary-text space-y-1">
              <p>
                • Type <span class="font-mono bg-surface-alt px-1 rounded">type:semantic</span>
                for AI-powered semantic search
              </p>
              <p>• Search by package name, description, or functionality</p>
            </div>
          </div>
        </div>
      <% end %>

      <%= if @show_dropdown do %>
        <div
          class="absolute top-full left-0 right-0 z-50 mt-1 bg-surface rounded-md shadow-lg max-h-60 overflow-auto"
          {test_attrs(search_dropdown: true)}
        >
          <%= if length(@results) > 0 do %>
            <ul class="py-1" {test_attrs(results_list: true)}>
              <li
                :for={{package, index} <- Enum.with_index(@results)}
                class="px-3 py-2 cursor-pointer truncate hover:bg-surface-alt"
                phx-click="select_result"
                phx-value-name={package.name}
                phx-target={@myself}
                {test_attrs(search_result_item: package.name, search_result_index: index)}
              >
                <div class="flex items-center">
                  <span class="text-[16px] text-primary-text" {test_attrs(package_name: true)}>
                    {package.name}
                  </span>
                  <span
                    class="text-[16px] text-secondary-text ml-4"
                    {test_attrs(package_version: true)}
                  >
                    {package.latest_hexpm_snapshot.data["latest_version"]}
                  </span>
                  <span
                    :if={package.name == String.downcase(@search_term)}
                    class="text-xs ml-4 mr-1 py-[2px] px-2 rounded-full text-text-secondary-button text-white bg-chip-bg-exact-match inline-block"
                    {test_attrs(exact_match: package.name)}
                  >
                    Exact match
                  </span>
                </div>
                <span class="text-[14px] text-secondary-text" {test_attrs(package_description: true)}>
                  {package.description}
                </span>
              </li>
            </ul>
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

  def handle_event("typeahead_search", %{"term" => term}, socket) do
    do_search(socket, term)
  end

  def handle_event("handle_keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, show_dropdown: false)}
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
    {:noreply, assign(socket, show_dropdown: false)}
  end

  def handle_event("handle_focus", _params, socket) do
    do_search(socket, socket.assigns.search_term)
  end

  def handle_event("handle_blur", _params, socket) do
    {:noreply, assign(socket, focused: false)}
  end

  def handle_event("show_dropdown_if_results", _params, socket) do
    # Use the same logic as typeahead_search to determine if we should show dropdown
    %{clean_term: clean_term} =
      parsed_search = Toolbox.PackageSearch.parse(socket.assigns.search_term)

    {_results, _has_more?} =
      if Toolbox.PackageSearch.executable?(parsed_search) do
        Toolbox.PackageSearch.execute(parsed_search)
      else
        {[], false}
      end

    show_dropdown = String.length(clean_term) >= 3

    {:noreply, assign(socket, show_dropdown: show_dropdown)}
  end

  defp do_search(socket, term) do
    term = String.trim(term)

    %{clean_term: clean_term} = parsed_search = Toolbox.PackageSearch.parse(term)

    {results, _has_more?} =
      if Toolbox.PackageSearch.executable?(parsed_search) do
        Toolbox.PackageSearch.execute(parsed_search)
      else
        {[], false}
      end

    # Only show dropdown if we have a valid search term after removing filter patterns
    # The backend requires at least 3 characters in the clean term for actual search
    show_dropdown = String.length(clean_term) >= 3

    {:noreply,
     assign(socket,
       results: results,
       show_dropdown: show_dropdown,
       search_term: term
     )}
  end
end
