defmodule ToolboxWeb.Components.ApiKeyModal do
  use ToolboxWeb, :html

  attr :form, Phoenix.HTML.Form, required: true
  attr :created_api_key, Toolbox.ApiKey, default: nil
  attr :token, :string, default: nil

  def api_key_modal(assigns) do
    ~H"""
    <.modal id="api-key-modal" show on_cancel={JS.push("close_api_key_modal")}>
      <%= if @token do %>
        <h2 id="api-key-modal-title" class="text-[24px] text-primary-text font-semibold">
          API Key created
        </h2>
        <p class="mt-2 text-[14px] text-secondary-text">
          Please copy it now and write it down somewhere safe.
          <strong class="font-medium">You will not be able to see it again.</strong>
        </p>

        <div class="mt-6 p-5 rounded-md border border-stroke bg-surface-alt">
          <p class="text-[18px] text-primary-text">API key</p>

          <div class="mt-3 flex items-center gap-3">
            <div
              id="created-api-key"
              class="grow min-w-0 overflow-x-auto whitespace-nowrap select-all px-3 py-2 rounded-sm border border-stroke bg-lightest-violet text-[14px] text-accent"
              {test_attrs(created_api_key: true)}
            >
              {@token}
            </div>

            <.button
              type="button"
              class="cursor-pointer"
              phx-click={
                JS.dispatch("toolbox:clipboard", to: "#created-api-key")
                |> JS.hide(to: "#copy-label")
                |> JS.show(to: "#copied-label")
              }
            >
              <span id="copy-label">Copy</span>
              <span id="copied-label" class="hidden">Copied</span>
            </.button>
          </div>
        </div>

        <h3 class="mt-6 text-[18px] text-primary-text">Key details</h3>
        <div class="mt-3 grid grid-cols-[auto_minmax(0,1fr)] gap-x-8 gap-y-2 text-[14px]">
          <span class="text-secondary-text">Name</span>
          <span class="text-secondary-text break-words">{@created_api_key.name}</span>

          <%= if @created_api_key.description do %>
            <span class="text-secondary-text">Description</span>
            <span class="text-secondary-text break-words">{@created_api_key.description}</span>
          <% end %>

          <span class="text-secondary-text">Expiration</span>
          <span class="text-secondary-text">Never</span>
        </div>
      <% else %>
        <h2 id="api-key-modal-title" class="text-[24px] text-primary-text font-semibold">
          API Keys
        </h2>
        <p class="mt-2 text-[14px] text-secondary-text">
          Generate and manage API keys to connect Observer with external tools and AI assistants.
        </p>

        <.simple_form
          id="api-key-form"
          for={@form}
          phx-submit="create_api_key"
        >
          <.input
            field={@form[:name]}
            label="Name"
            placeholder="e.g. Claude Desktop"
            hint="A short, descriptive name to identify this key."
          />
          <.input
            field={@form[:description]}
            type="textarea"
            label="Description"
            optional
            placeholder="e.g. Used for Claude Desktop integration."
            hint="Add a note to remember what this key is used for."
          />

          <:actions>
            <button
              type="button"
              class="cursor-pointer text-[16px] text-medium-violet hover:underline"
              phx-click={JS.exec("data-cancel", to: "#api-key-modal")}
            >
              Cancel
            </button>
            <.button class="cursor-pointer">Create API key</.button>
          </:actions>
        </.simple_form>
      <% end %>
    </.modal>
    """
  end
end
