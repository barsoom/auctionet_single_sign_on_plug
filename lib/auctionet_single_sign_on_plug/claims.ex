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
      :entitlements,
      :external_id,
      :locale,
      :name,
      :session_id
    ]

    def parse(map) do
      %__MODULE__{
        active_session_ids: map["active_session_ids"],
        company_slug: map["company_slug"],
        email: map["email"],
        entitlements: map["entitlements"],
        external_id: map["external_id"],
        locale: map["locale"],
        name: map["name"],
        session_id: map["session_id"]
      }
    end
  end
end
