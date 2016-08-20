# AuctionetSingleSignOnPlug

Middleware for plug-based apps that handles Auctionet Admin single-sign-on sessions.

Ensures you can only access the app when you are also logged into Auctionet Admin
and have access to this particular app (supers have access to everything).

The plug exposes the SSO related data to the app using "conn.assigns[:sso]".

## How to get started in dev in a phoenix app

### Basic setup

- Set up the dependency like we've done in [mix.exs](https://github.com/barsoom/phoenix_sso_example/blob/master/mix.exs)

#### dev.exs

Remember to change "your_app_name".

```
config :phoenix_sso_example,
  sso_secret_key: "dev secretdev secretdev secretdev secretdev secretdev secretdev secretdev secretdev secretdev secret",
  sso_request_url: "http://auctionet.dev/admin/login/request_sso?app=your_app_name",
  sso_logout_url: "http://auctionet.dev/admin/logout/sso"
```

#### router.ex

In the bottom of "pipeline :browser do", add:

```
  plug AuctionetSingleSignOnPlug,
    sso_secret_key: Application.get_env(:phoenix_sso_example, :sso_secret_key),
    sso_request_url: Application.get_env(:phoenix_sso_example, :sso_request_url)
```

You can also set `sso_session_persister` to something else, but only do that after you get SSO to work without it.

If you want some paths not to require SSO, create a different pipeline for those.

### Auctionet setup

Ensure you have created a `SingleSignOnApplication` record in auctionet dev that matches this app. The `sso_login_url` should be something like `http://192.168.50.1:4000/` (does not need to be "/" but needs to be a path that is controlled by this plug).

### Trying it out

Visit the app in development and see if it authenticates with auctionet.dev.

If it works you will see "/" on your app rendered by `PageController`. This means you're authenticated. Check `conn.assigns[:sso]` for user data!

## Deploying to heroku

- Set heroku config for `GITHUB_AUTH_TOKEN` and add the [netrc](https://github.com/timshadel/heroku-buildpack-github-netrc) buildpack.
- Set heroku configs for `SSO_SECRET_KEY`, `SSO_REQUEST_URL`, and `SSO_LOGOUT_URL`.

#### prod.exs

```
config :phoenix_sso_example,
  sso_secret_key: System.get_env("SSO_SECRET_KEY"),
  sso_request_url: System.get_env("SSO_REQUEST_URL"),
  sso_logout_url: System.get_env("SSO_LOGOUT_URL")
```

#### More info

If something doesn't work, check how it's done in [phoenix_sso_example](https://github.com/barsoom/phoenix_sso_example).
