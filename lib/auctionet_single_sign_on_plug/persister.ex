defmodule AuctionetSingleSignOnPlug.Persister do
  @callback active_sso_session_ids_and_data(sso_employee_id :: term()) :: {list(), term()}
  @callback create_or_update(sso_employee_id :: term(), active_sso_session_ids :: list(), data :: term()) :: term()
  @callback update_if_exists(sso_employee_id :: term(), active_sso_session_ids :: list(), data :: term()) :: term()
end
