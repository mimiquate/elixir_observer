defmodule ToolboxWeb.Components.RevokeApiKeyModal do
  use ToolboxWeb, :html

  attr :api_key, Toolbox.ApiKey, required: true

  def revoke_api_key_modal(assigns) do
    ~H"""
    <.modal id="revoke-api-key-modal" show on_cancel={JS.push("close_revoke_api_key_modal")}>
      <h2 id="revoke-api-key-modal-title" class="text-[24px] text-primary-text font-semibold">
        Revoke API Key
      </h2>
      <p class="mt-2 text-[14px] text-secondary-text break-words">
        Are you sure you want to revoke the API key <strong class="font-medium">{@api_key.name}</strong>?
      </p>

      <div class="mt-6 flex items-center justify-end gap-6">
        <button
          type="button"
          class="cursor-pointer text-[16px] text-medium-violet hover:underline"
          phx-click={JS.exec("data-cancel", to: "#revoke-api-key-modal")}
        >
          Cancel
        </button>
        <.button type="button" class="cursor-pointer" phx-click="revoke_api_key">
          Revoke
        </.button>
      </div>
    </.modal>
    """
  end
end
