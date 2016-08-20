# In memory persistence of SSO session data.
#
# Fast and easy. No dependencies or configuration.
#
# Data is lost on server restarts. Users will then have to wait for
# redirects to re-fetch SSO info.
#
# Not recommended for form heavy apps.

defmodule AuctionetSingleSignOnPlug.PersistSsoSessionsInMemory do
  def active_sso_session_ids_and_data(nil), do: {[], nil}
  def active_sso_session_ids_and_data(sso_employee_id) do
    Agent.get agent, fn (state) ->
      Map.get(state, sso_employee_id) || {[], nil}
    end
  end

  def create_or_update(sso_employee_id, active_sso_session_ids, data) do
    Agent.update agent, fn (state) ->
      Map.put(state, sso_employee_id, {active_sso_session_ids, data})
    end
  end

  def update_if_exists(sso_employee_id, active_sso_session_ids, data) do
    Agent.update agent, fn (state) ->
      if state[sso_employee_id] do
        Map.put(state, sso_employee_id, {active_sso_session_ids, data})
      end
    end
  end

  defp agent do
    pid = Process.whereis(__MODULE__)

    if pid do
      pid
    else
      {:ok, pid} = Agent.start_link(fn -> %{} end, name: __MODULE__)
      pid
    end
  end
end
