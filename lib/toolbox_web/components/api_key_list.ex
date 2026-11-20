defmodule ToolboxWeb.Components.ApiKeyList do
  use ToolboxWeb, :html

  attr :api_keys, :list, required: true

  def api_key_list(assigns) do
    ~H"""
    <ul {test_attrs(api_keys_list: true)}>
      <li
        :for={api_key <- @api_keys}
        class="mt-5 py-3 px-5 flex flex-col md:flex-row md:justify-between bg-surface rounded-md border border-stroke"
        {test_attrs(api_key_item: api_key.id)}
      >
        <div class="min-w-0">
          <div class="flex items-start">
            <span class="min-w-0 break-words text-[16px] sm:text-[18px] text-primary-text">
              {api_key.name}
            </span>

            <span
              class={[
                "ml-4 text-sm py-[2px] px-3 rounded-full",
                api_key.last_used_at && "bg-chip-bg-exact-match text-white",
                !api_key.last_used_at && "border border-accent text-accent"
              ]}
              {test_attrs(api_key_status: true)}
            >
              {if api_key.last_used_at, do: "Active", else: "Unused"}
            </span>
          </div>

          <p class="mt-2 font-mono text-[14px] text-secondary-text" {test_attrs(api_key_masked: true)}>
            {Toolbox.ApiKeys.masked_key(api_key)}
          </p>

          <p
            :if={api_key.description}
            class="mt-2 text-[14px] text-secondary-text break-words"
            {test_attrs(api_key_description: true)}
          >
            {api_key.description}
          </p>

          <div class="mt-2 flex flex-col gap-1 sm:flex-row sm:gap-3 text-[14px] text-primary-text">
            <span {test_attrs(api_key_created_at: true)}>
              Created: {humanized_datetime_with_day(api_key.inserted_at)}
            </span>
            <span {test_attrs(api_key_last_used: true)}>
              Last used: {last_used_label(api_key.last_used_at)}
            </span>
          </div>
        </div>

        <div class="mt-4 md:mt-0 md:ml-4">
          <button
            type="button"
            class="cursor-pointer text-[16px] text-accent hover:underline"
            phx-click="open_revoke_api_key_modal"
            phx-value-id={api_key.id}
            {test_attrs(revoke_api_key: api_key.id)}
          >
            Revoke
          </button>
        </div>
      </li>
    </ul>
    """
  end

  defp last_used_label(nil), do: "Never"

  defp last_used_label(last_used_at) do
    case relative_datetime(last_used_at) do
      {nil, label} -> label
      {number, label} -> "#{number} #{label}"
    end
  end
end
