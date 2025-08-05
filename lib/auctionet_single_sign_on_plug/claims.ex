defmodule AuctionetSingleSignOnPlug.Claims do
  defstruct [:action, :exp, :protocol_version, :user]

  def parse(map) do
    %__MODULE__{
      action: map["action"],
      exp: map["exp"],
      protocol_version: map["protocol_version"],
      user: AuctionetSingleSignOnPlug.Claims.User.parse(map["user"])
    }
  end

  defmodule User do
    defstruct [
      :active_session_ids,
      :company_slug,
      :email,
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
        external_id: map["external_id"],
        locale: map["locale"],
        name: map["name"],
        session_id: map["session_id"]
      }
    end
  end
end
