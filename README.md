# AuctionetSingleSignOnPlug

Middleware for plug-based apps that handles Auctionet Admin single-sign-on sessions.

Ensures you can only access the app when you are also logged into Auctionet Admin
and have access to this particular app (supers have access to everything).

The plug exposes the SSO related data to the app using "conn.assigns[:sso]".

## Usage

TODO
