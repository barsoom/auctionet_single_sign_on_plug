defmodule AuctionetSingleSignOnPlug do
  import Plug.Conn

  # sso_session_persister API
  #
  # The "data" argument is SSO data when persisted, but can be anything you like
  # when returned to be set in assigns[:sso], like a user record.
  #
  # This is because there is no need to persist anything but active_sso_session_ids.

  def init(options) do
    options
    |> Keyword.put(
      :sso_session_persister,
      options[:sso_session_persister] || AuctionetSingleSignOnPlug.PersistSsoSessionsInMemory
      )
  end

  def call(conn, options) do
    if auctionet_admin_sso_request?(conn) do
      parse_sso_data(conn, options)
      |> respond_to_sso(conn, options)
    else
      conn
      |> respond_to_other(options)
    end
  end

  defp auctionet_admin_sso_request?(conn) do
    conn.params != %Plug.Conn.Unfetched{aspect: :params} &&
      conn.params["source"] == "auctionet_admin_sso"
  end

  defp parse_sso_data(%{ params: %{ "payload" => payload } }, options) do
    sso_secret_key = options[:sso_secret_key]
    {:ok, data} = JsonWebToken.verify(payload, %{ key: sso_secret_key })

    if :os.system_time(:seconds) > data.exp do
      raise "Auctionet SSO token is too old. Possible causes: - The request took to long to run. - The system clock is very out of sync between the servers. - Someone is trying to reuse old authentication data."
    end

    if data[:protocol_version] == 2 do
      data
    else
      payload = data.payload

      %{
        action: payload.action,
        protocol_version: 2,
        user: Map.merge(payload.profile, %{
          active_session_ids: payload.known_session_ids,
          session_id: payload.session_id,
        })
      }
    end
  end

  defp respond_to_sso(data, conn, options) do
    user = data.user

    if data[:action] == "log_in" do
      sso_employee_id = user.external_id
      active_sso_session_ids = user.active_session_ids

      options[:sso_session_persister].create_or_update(sso_employee_id, active_sso_session_ids, data)

      conn
      |> put_session(:sso_session_id, user.session_id)
      |> put_session(:sso_employee_id, sso_employee_id)
      |> Plug.Conn.put_resp_header("location", "/")
      |> Plug.Conn.resp(302, "Logged in")
      |> Plug.Conn.halt
    else
      if data[:action] == "update" do
        sso_employee_id = user.external_id
        active_sso_session_ids = user.active_session_ids

        options[:sso_session_persister].update_if_exists(sso_employee_id, active_sso_session_ids, user)

        conn
        |> Plug.Conn.resp(200, "ok")
        |> Plug.Conn.halt
      else
        raise "Unknown action: #{data[:action]}"
      end
    end
  end

  defp respond_to_other(conn, options) do
    sso_session_id = get_session(conn, :sso_session_id)
    sso_employee_id = get_session(conn, :sso_employee_id)

    {active_sso_session_ids, custom_data} = options[:sso_session_persister].active_sso_session_ids_and_data(sso_employee_id)

    if sso_session_id in active_sso_session_ids do
      assign(conn, :sso, custom_data)
    else
      conn
      |> put_session(:sso_session_id, nil)
      |> put_session(:sso_employee_id, nil)
      |> Plug.Conn.put_resp_header("location", options[:sso_request_url])
      |> Plug.Conn.resp(302, "Requesting SSO")
      |> Plug.Conn.halt
    end
  end
end
