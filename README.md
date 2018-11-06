What is this?
=============

This is a collection of scripts and configuration that work together
to automate deployment of [bitwarden\_rs](https://github.com/dani-garcia/bitwarden\_rs)
in a singular docker container.

At a glance
-----------

This is more or less an extension of the image distribution by [@mprasil](https://github.com/mprasil).

Rather than directly starting bitwarden\_rs; however, this image

   * Starts `cron`
   * Attempts to issue a certificate for `$DOMAIN` using certbot, if one is not already available in `/data`
   * Starts `nginx`, which serves as the public-facing HTTP server.
   * Starts `bitwarden_rs`

Details
-------

### Environment variables

All environment variables noted in the README for bitwarden\_rs still apply. `$DOMAIN` is of particular importance
in this configuration, and must be set for proper certificate issuance. The assumption is made that this container will
have a dedicated DNS name (e.g. a subdomain of your website such as `bitwarden.example.org`, in which case `$DOMAIN` is `bitwarden.example.org`).
This has the side effect of enabling U2F support (once it gets fixed).

The following environment variables are set by the startup script and _cannot_ be overriden, as other applications expect these to be
certain values,

| Variable            | Value                         | Purpose                                        |
|---------------------|-------------------------------|------------------------------------------------|
| `ROCKET_ENV`        | `production`                  | Primarily to prevent excessive logging traffic |
| `ROCKET_PORT`       | `8080`                        | bitwarden\_rs sits behind a reverse proxy      |
| `ROCKET_ADDRESS`    | `127.0.0.1`                   |                                                |
| `WEBSOCKET_ENABLED` | `true`                        | Reverse proxy routes WS requests               |
| `DATA_FOLDER`       | `/data/bitwarden`             | To make bwrs share `/data`                     |

In addition to the aforementioned environment variables, the following _new_ environment variables exist,

| Variable           | Default              | Purpose                                                                                 |
|--------------------|----------------------|-----------------------------------------------------------------------------------------|
| `ACME_TRUSTWORTHY` | _unset_              | Setting this will cause certbot to trust invalid certificates (for testing with pebble) |
| `ACME_SERVER`      | _unset_              | ACME service endpoint for certbot                                                       |
| `ACME_DRY`         | _unset_              | Setting this adds `--dry-run` to the initial certbot invocation                         |
| `ACME_STAGE`       | _unset_              | Setting this add `--staging` to the intiial certbot invocation                          |
| `ACME_EMAIL`       | `nobody@example.org` | ACME customer email. You _absolutely_ should change this.                               |

### NginX configuration

The NginX configuration exists as a template which is processed by `envsubst` at runtime, in order to accomodate changes to `$DOMAIN`.


NginX has been configured in such a manner that it scores A+ on SSLLabs certification, specifically

   * HSTS is enabled with a very long max-age
   * OCSP stapling is enabled
   * Only TLSv1.2 is accepted
   * The client cipher offering should be ignored
   * Plaintext HTTP (port 80) is configured only to redirect to HTTPS
   * `/.well-known/acme-challenge` is set up such that certbot's `webroot` authenticator can coexist with the bitwarden API
   * `/notifications/hub` and `/notifications/hub/negotiate` are properly handled so as to enable WebSocket notification support
   * gzip is enabled, as is HTTP/2 support

### Logging and Log Rotation

Logrotate is installed and configured to look for certbot and NginX logs in their subdirectories beneath `/data`. NginX log files
are rotated on a weekly basis with three weeks of history retained. Certbot logs are rotated on a monthly basis with twelve monnths
of history retained.

bitwarden\_rs output is not logged; however, it (as of writing) has no meaningful output and is more or less silent when `ROCKET_ENV` is
not set to one of the development/testing values.

Notes
-----

Practically speaking, there should be no friction resulting from changes to `$DOMAIN`; hoever, the certbot renewal INIs for any historic
value of `$DOMAIN` will persist, resulting in renewal errors.

On the subject of multiple current of historic values for domains, the current design does not accomodate multiple values for `$DOMAIN`.
`-d $DOMAIN` is passed directly to certbot, and the manner in which bitwarden\_rs interprets the value for `$DOMAIN` may limit the
ability to pass multiple values in some fashion via the variable.

Because of this, even previous domains remain configured to point at the server, historic renewal configuations will almost certainly to fail,
as the NginX template includes the `server_name ${DOMAIN}` directive.
