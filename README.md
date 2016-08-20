# AuctionetSingleSignOnPlug

A library to add user authentication though Auctionet Admin SSO to phoenix apps.

See it in action in the [example app on heroku](https://auctionet-phoenix-sso-example.herokuapp.com).

## How to get started in dev in a phoenix app

### mix.exs

Add this to deps:

     {:auctionet_single_sign_on_plug, ">= 0.0.0", git: github_url("barsoom/auctionet_single_sign_on_plug")},

And below add this (will be needed later):

```
  defp github_url(path) do
    if System.get_env("MIX_ENV") == "prod" do
      "https://github.com/#{path}.git"
    else
      "git@github.com:#{path}"
    end
  end
```

Run `mix deps.get`

### dev.exs

Remember to change "your_app_name".

```
config :your_app_name,
  sso_secret_key: "dev secretdev secretdev secretdev secretdev secretdev secretdev secretdev secretdev secretdev secret",
  sso_request_url: "http://auctionet.dev/admin/login/request_sso?app=your_app_name",
  sso_logout_url: "http://auctionet.dev/admin/logout/sso"
```

### router.ex

```
  pipeline :require_valid_sso_login do
    plug AuctionetSingleSignOnPlug,
      sso_secret_key: Application.get_env(:your_app_name, :sso_secret_key),
      sso_request_url: Application.get_env(:your_app_name, :sso_request_url)
  end

  scope "/", MyAppName do
    # pipe_through :browser                           # <- replace this
    pipe_through [:browser, :require_valid_sso_login] # <- with this!

    # ...
  end
```

If you want some paths not to require SSO, create a different scope for those.

### Setup the app in auctionet

Ensure you have created a `SingleSignOnApplication` record in auctionet dev that matches this app. The `sso_login_url` should be something like `http://192.168.50.1:4000/` (does not need to be "/" but needs to be a path that is controlled by this plug).

### Start servers in auctionet

Start `foreman start -f Procfile.sso` and `dev web` in /projects/auctionet.

### Try it out

Visit the app in development and see if it authenticates with auctionet.dev.

If it works you will be returned to "/" on your app rendered by `PageController`. This means you're authenticated. Check `conn.assigns[:sso]` for user data!

Logging out from <http://auctionet.dev/admin> should log you out from the app (a background job in auctionet makes a call to the app in the background). Going to the app and logging in again should return you to the app with `conn.assigns[:sso]` set.

## CircleCI

Since this is a private project it's more complex to access. Circle has a way to give access, but as far as I can see that gives access to all __your__ private repos. So better to use that feature on the auctionet-ci user.

0. Give the [auctionet-ci-team](https://github.com/orgs/barsoom/teams/auctionet-ci/repositories) admin access to the app repo and read access to this repo.
0. Log into github as auctionet-ci (in another browser), go to circle, log in there, go to project settings, checkout ssh keys, authorize and add a key for auctionet-ci.
0. Then change from admin to read access again.
0. Don't trigger the build yet.

## Deploying to heroku

- Set heroku config for `GITHUB_AUTH_TOKEN` (auctionet_push has the right one) and add the [netrc](https://github.com/timshadel/heroku-buildpack-github-netrc) buildpack like this `heroku buildpacks:add -i 1 https://github.com/timshadel/heroku-buildpack-github-netrc.git` (needed to install this plug from a private repo).
- Set heroku configs for `SSO_SECRET_KEY` (pwgen -n 255), `SSO_REQUEST_URL`, and `SSO_LOGOUT_URL` (see auctionet_push config).
- In elixir_buildpack.config, add "SSO_SECRET_KEY SSO_REQUEST_URL" to config_vars_to_export, so that it at least has `config_vars_to_export=(SSO_SECRET_KEY SSO_REQUEST_URL)`.

## Push the code and make sure it's deployed, then:

Create a SingleSignOnApplication record in auctionet. Leave entitlements an empty array if only supers will use it.

Log in and out of auctionet admin and check that the SSO works.

Link to the app from Auctionet Admin.

Done!

### prod.exs

```
config :phoenix_sso_example,
  sso_secret_key: System.get_env("SSO_SECRET_KEY"),
  sso_request_url: System.get_env("SSO_REQUEST_URL"),
  sso_logout_url: System.get_env("SSO_LOGOUT_URL")
```

### More info

If something doesn't work, check how it's done in [phoenix_sso_example](https://github.com/barsoom/phoenix_sso_example).

The [example app](https://auctionet-phoenix-sso-example.herokuapp.com) also persists it's sessions as User records in a postgres database. That way sessions remain across app restarts and you can use the User records for other things.
