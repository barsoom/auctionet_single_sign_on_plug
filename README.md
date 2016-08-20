# AuctionetSingleSignOnPlug

Middleware for plug-based apps that handles Auctionet Admin single-sign-on sessions.

Ensures you can only access the app when you are also logged into Auctionet Admin
and have access to this particular app (supers have access to everything).

The plug exposes the SSO related data to the app using "conn.assigns[:sso]".

## Usage

See [phoenix_sso_example](https://github.com/barsoom/phoenix_sso_example) for how to use this.

### Basic setup

#### Making it possible to install this private hex package on heroku

- Set up the dependency like we've done in [mix.exs](https://github.com/barsoom/phoenix_sso_example/blob/master/mix.exs)
- Set heroku config for `GITHUB_AUTH_TOKEN` and add the [netrc](https://github.com/timshadel/heroku-buildpack-github-netrc) buildpack.

#### Heroku config

- Set heroku configs for `SSO_SECRET_KEY`, `SSO_REQUEST_URL`, and `SSO_LOGOUT_URL`.

#### dev.exs

Remember to change "your_app_name".

```
config :phoenix_sso_example,
  sso_secret_key: "dev secretdev secretdev secretdev secretdev secretdev secretdev secretdev secretdev secretdev secret",
  sso_request_url: "http://auctionet.dev/admin/login/request_sso?app=your_app_name",
  sso_logout_url: "http://auctionet.dev/admin/logout/sso"
```

#### prod.exs

```
config :phoenix_sso_example,
  sso_secret_key: System.get_env("SSO_SECRET_KEY"),
  sso_request_url: System.get_env("SSO_REQUEST_URL"),
  sso_logout_url: System.get_env("SSO_LOGOUT_URL")
```

#### router.ex

In the bottom of "pipeline :browser do", add:

```
  plug AuctionetSingleSignOnPlug,
    sso_secret_key: Application.get_env(:phoenix_sso_example, :sso_secret_key),
    sso_request_url: Application.get_env(:phoenix_sso_example, :sso_request_url)
```

You can also set `sso_session_persister` to something else, but only do that after you get something running without it.
