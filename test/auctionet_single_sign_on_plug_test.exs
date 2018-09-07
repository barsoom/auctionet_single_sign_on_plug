defmodule AuctionetSingleSignOnPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @key "1122334455667788990011223344556677889900"

  @session Plug.Session.init(
             store: :cookie,
             key: "_app",
             encryption_salt: "salt",
             signing_salt: "salt"
           )
  setup do
    Application.put_env(:auctionet_single_sign_on_plug, :sso_secret_key, @key)
    Application.put_env(:auctionet_single_sign_on_plug, :sso_request_url, "sso-request-url")
  end

  test "a log_in event persists the session and redirects" do
    opts = init_plug()
    token = build_valid_login_token(session_id: "abc123", external_id: 100)

    conn =
      conn(:get, "/", jwt_authentication_token: token)
      |> set_up_session

    conn = AuctionetSingleSignOnPlug.call(conn, opts)

    # redirect
    assert conn.status == 302
    assert get_session(conn, :sso_session_id) == "abc123"
    assert get_session(conn, :sso_employee_id) == 100

    {active_sso_session_ids, _data} =
      AuctionetSingleSignOnPlug.PersistSsoSessionsInMemory.active_sso_session_ids_and_data(100)

    assert "abc123" in active_sso_session_ids
  end

  test "a update event persists the session change and responds with an ok" do
    opts = init_plug()
    unix_time = :os.system_time(:seconds)

    user = %{
      active_session_ids: ["abc123", "eee555"],
      session_id: "abc123",
      action: "update",
      external_id: 100
    }

    token =
      JsonWebToken.sign(
        %{action: "update", protocol_version: 3, user: user, exp: unix_time + 2},
        %{key: @key}
      )

    conn =
      conn(:get, "/", jwt_authentication_token: token)
      |> set_up_session

    AuctionetSingleSignOnPlug.PersistSsoSessionsInMemory.create_or_update(100, ["abc123"], %{})

    conn = AuctionetSingleSignOnPlug.call(conn, opts)

    assert conn.status == 200
    assert conn.resp_body == "ok"

    {active_sso_session_ids, _data} =
      AuctionetSingleSignOnPlug.PersistSsoSessionsInMemory.active_sso_session_ids_and_data(100)

    assert active_sso_session_ids == ["abc123", "eee555"]
  end

  test "a unknown event raises an error" do
    opts = init_plug()
    unix_time = :os.system_time(:seconds)

    token =
      JsonWebToken.sign(%{action: "jump", user: %{}, protocol_version: 3, exp: unix_time + 2}, %{
        key: @key
      })

    conn =
      conn(:get, "/", jwt_authentication_token: token)
      |> set_up_session

    assert_raise RuntimeError, ~r/Unknown action: jump/, fn ->
      AuctionetSingleSignOnPlug.call(conn, opts)
    end
  end

  test "a regular page load assigns data based on sso_employee_id" do
    opts = init_plug()

    conn =
      conn(:get, "/")
      |> set_up_session
      |> put_session(:sso_session_id, "abc123")
      |> put_session(:sso_employee_id, 100)

    AuctionetSingleSignOnPlug.PersistSsoSessionsInMemory.create_or_update(100, ["abc123"], %{
      some: "data"
    })

    conn = AuctionetSingleSignOnPlug.call(conn, opts)

    assert conn.assigns[:sso] == %{some: "data"}
    assert get_session(conn, :sso_session_id) == "abc123"
    assert get_session(conn, :sso_employee_id) == 100
  end

  test "a regular page load clears everything and requests a new sso session when the old one is invalid" do
    opts = init_plug()

    conn =
      conn(:get, "/")
      |> set_up_session
      |> put_session(:sso_session_id, "abc123")
      |> put_session(:sso_employee_id, 100)

    AuctionetSingleSignOnPlug.PersistSsoSessionsInMemory.create_or_update(100, ["ddd555"], %{})

    conn = AuctionetSingleSignOnPlug.call(conn, opts)

    # redirect
    assert conn.status == 302
    assert conn.assigns[:sso] == nil
    assert get_session(conn, :sso_session_id) == nil
    assert get_session(conn, :sso_employee_id) == nil
  end

  test "a regular page load clears everything and requests a new sso session if session info was lost" do
    opts = init_plug()

    conn =
      conn(:get, "/")
      |> set_up_session
      |> put_session(:sso_session_id, "abc123")
      |> put_session(:sso_employee_id, 100)

    # cookies exist, but no state (e.g. after server restart)

    conn = AuctionetSingleSignOnPlug.call(conn, opts)

    # redirect
    assert conn.status == 302
    assert conn.assigns[:sso] == nil
    assert get_session(conn, :sso_session_id) == nil
    assert get_session(conn, :sso_employee_id) == nil
  end

  test "a regular page requests a sso session when none exists" do
    opts = init_plug()

    conn =
      conn(:get, "/")
      |> set_up_session

    conn = AuctionetSingleSignOnPlug.call(conn, opts)

    # redirect
    assert conn.status == 302
    assert conn.assigns[:sso] == nil
    assert get_session(conn, :sso_session_id) == nil
    assert get_session(conn, :sso_employee_id) == nil
  end

  test "the requested URL is retained in session and redirected to after login" do
    opts = init_plug()

    # Try to visit an URL and get redirected for SSO
    conn = conn(:get, "/admin/items/5") |> set_up_session
    conn = AuctionetSingleSignOnPlug.call(conn, opts)

    # redirect
    assert conn.status == 302
    requested_path_stored_in_session = get_session(conn, :sso_requested_path)

    # Later we come back with a SSO login, the only shared data is the sso_requested_path in session
    token = build_valid_login_token(session_id: "test", external_id: 1)

    conn =
      conn(:get, "/", jwt_authentication_token: token)
      |> set_up_session
      |> put_session(:sso_requested_path, requested_path_stored_in_session)

    conn = AuctionetSingleSignOnPlug.call(conn, opts)

    assert get_session(conn, :sso_session_id) == "test"
    redirect_location = conn.resp_headers |> Enum.into(%{}) |> Map.get("location")
    assert redirect_location == "/admin/items/5"
  end

  test "throws an error if the data is expired" do
    opts = init_plug()
    unix_time = :os.system_time(:seconds)
    payload = JsonWebToken.sign(%{payload: %{app: "data"}, exp: unix_time - 1}, %{key: @key})

    conn =
      conn(:get, "/", jwt_authentication_token: payload)
      |> set_up_session

    assert_raise RuntimeError, ~r/too old/, fn ->
      AuctionetSingleSignOnPlug.call(conn, opts)
    end
  end

  defp init_plug() do
    AuctionetSingleSignOnPlug.init(
      sso_secret_key: {:application_env, :auctionet_single_sign_on_plug, :sso_secret_key},
      sso_request_url: {:application_env, :auctionet_single_sign_on_plug, :sso_request_url}
    )
  end

  defp build_valid_login_token(session_id: session_id, external_id: external_id) do
    unix_time = :os.system_time(:seconds)

    user = %{
      external_id: external_id,
      active_session_ids: [session_id],
      session_id: session_id,
      action: "log_in"
    }

    JsonWebToken.sign(%{action: "log_in", user: user, protocol_version: 3, exp: unix_time + 2}, %{
      key: @key
    })
  end

  defp set_up_session(conn) do
    conn
    |> Plug.Session.call(@session)
    |> Plug.Conn.fetch_session()
  end
end
