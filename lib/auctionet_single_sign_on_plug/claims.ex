defmodule AuctionetSingleSignOnPlug.Claims do
  defstruct [:action, :exp, :protocol_version, :user]

  def parse(map) do
    map = nulls_to_nil(map)

    %__MODULE__{
      action: map["action"],
      exp: map["exp"],
      protocol_version: map["protocol_version"],
      user: AuctionetSingleSignOnPlug.Claims.User.parse(map["user"])
    }
  end

  # JOSE decodes with OTP's :json by default, which turns JSON null into :null.
  defp nulls_to_nil(:null), do: nil
  defp nulls_to_nil(map) when is_map(map), do: Map.new(map, fn {k, v} -> {k, nulls_to_nil(v)} end)
  defp nulls_to_nil(list) when is_list(list), do: Enum.map(list, &nulls_to_nil/1)
  defp nulls_to_nil(other), do: other

  defmodule User do
    defstruct [
      :active_session_ids,
      :company_slug,
      :email,
      :external_company_id,
      :external_id,
      :locale,
      :name,
      :session_id,
      entitlements: [],
      scopes: %{}
    ]

    def parse(nil), do: %__MODULE__{}

    def parse(map) when is_map(map) do
      %__MODULE__{
        active_session_ids: map["active_session_ids"],
        company_slug: map["company_slug"],
        email: map["email"],
        entitlements: Map.get(map, "entitlements", []),
        scopes: Map.get(map, "scopes", %{}),
        external_company_id: map["external_company_id"],
        external_id: map["external_id"],
        locale: map["locale"],
        name: map["name"],
        session_id: map["session_id"]
      }
    end
  end
end
