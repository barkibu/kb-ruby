# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]
- See diff: https://github.com/barkibu/kb-ruby/compare/v1.4.0...HEAD

## [1.4.0]
- Reuse connections to KB (keep-alive) with the stock faraday-net_http_persistent adapter. New runtime dependencies: `faraday-net_http_persistent ~> 1.2`, `net-http-persistent ~> 4.0` (4.0.8 accepts `connection_pool` 2.2.4 up to < 4). On by default; `KB.config.request.keep_alive = false` restores one connection per call. New `KB.config.request.idle_timeout` (default 30s, below the Heroku router's ~55s idle close).
- Every `KB::Client` now shares one Faraday connection (`KB::Connections`), so all model clients use one connection pool per process. Clients send full URLs and their own `x-api-key` header per request; URLs, headers and cache keys are unchanged. Settings are read when that connection is built, on the process's first KB call; `KB::Connections.reset!` applies later changes.
- A call with its own `read_timeout:` goes through a separate plain net_http connection, so its override never reaches the shared pool's other calls.
- With keep-alive, a connect timeout is `Faraday::TimeoutError` (was `Faraday::ConnectionFailed`) wrapping `Net::OpenTimeout`, and a refused connection is `Faraday::ConnectionFailed` wrapping `Net::HTTP::Persistent::Error`. Both still become `KB::Error` in model calls and are still retried for every verb: `KB::RetryPolicy.root_cause` unwraps `Net::HTTP::Persistent::Error` to the underlying `Errno`. Datadog `error.type` on connect-timeout spans changes accordingly.

## [1.3.0]
- Retry transport failures once (`faraday-retry`, already in the Faraday 1.10 bundle, now an explicit dependency). `KB::RetryPolicy` decides by the underlying error, not the Faraday class: failures where the request never left (`Net::OpenTimeout`, `ECONNREFUSED`, `EHOSTUNREACH`, `ENETUNREACH`, `EADDRNOTAVAIL`, `SocketError`) retry for every verb; any other transport failure (read/write timeout, reset, EOF, TLS) retries for GET/HEAD only (and not when the call raised its own `read_timeout:`, so a 30s read isn't doubled); HTTP error responses never retry. New settings `KB.config.request.retries` (default 1, 0 disables) and `retry_interval` (default 0.1s, randomized up to 2x). Worst-case latency is now two attempts' worth of phase budgets.
- `request.kb_client` payload gains `retries` and `retry_errors` on retried calls; the Datadog subscriber tags them as `kb.retries` / `kb.retry_errors`. The event and span cover all attempts, so a call that succeeded on retry is not an error.
- `KB::Listable.all` (and so `PetParent.all`, `Pet.all`, `Breed.all`, `Product.all`, `Plan.all`, `Assessment.all`) now wraps `Faraday::ConnectionFailed` in `KB::Error` like every other model call, instead of re-raising it raw. Code rescuing `Faraday::ConnectionFailed` around `.all` must rescue `KB::Error` instead; none of Funnel, Global Admin or connected_health does.

## [1.2.0]
- `KB::Client` emits one `request.kb_client` `ActiveSupport::Notifications` event per KB call (`KB::Client::REQUEST_EVENT`), wrapping cache lookup, connect, TLS, write, read and parsing. Payload: `verb`, `path`, `base_url`, `cache_hit` (GET only), `status`, plus ActiveSupport's `exception`/`exception_object` when the call raised. Every public method now goes through one private `perform` seam; no behaviour change (same cache keys, params and error classes).
- Add an opt-in Datadog subscriber: `require 'kb/instrumentation/datadog'` + `KB::Instrumentation::Datadog.subscribe!` turns each event into a `kb.client.request` APM span, opened on event start and closed on finish so the tracer's Net::HTTP spans nest under it. The span inherits the app's service and stays there (no `span.kind:client`/`peer.service`, so it is not attributed to the knowledge-base service), tags `peer.hostname`, `kb.method`, `kb.cache_hit`, `http.status_code`, and uses low-cardinality resources (`GET /v1/pets/?/contracts`). Motivation: connect timeouts happen before `Net::HTTP#request`, so the Datadog Net::HTTP tracer never sees them and they were invisible on our dashboards. Works with `ddtrace` 1.x and `datadog` 2.x; the tracer stays the app's dependency.

## [1.1.0]
- Add `read_timeout:` to `KB::Client#request` to raise the read budget for a single call (e.g. `GET /v1/pets/birthdays`, whose server-side work runs for seconds). Connect and write budgets stay global; the override does not leak into later calls on the same connection.

## [1.0.0]
- [Breaking changes] Split the single global request timeout into per-phase budgets: `KB.config.request.connect_timeout` (default 1s, bounds TCP connect + TLS handshake), `write_timeout` (default 3s), `read_timeout` (default 5s). `KB.config.request.timeout` is removed — assigning it now raises `NoMethodError` at boot. Migration: a previous global `timeout` maps to `read_timeout` (e.g. `KB_REQUEST_TIMEOUT_SECONDS=12` → `read_timeout = 12`).
- [Breaking changes] Switch the HTTP adapter from http.rb (`faraday-http`) to Net::HTTP (`faraday-net_http`) — the stock adapter honours all three phase timeouts, aligns the KB client with the rest of our outbound HTTP, and opens a one-line upgrade path to `faraday-net_http_persistent` for connection reuse. Raw error classes change accordingly (`Net::OpenTimeout`/`Net::ReadTimeout`/`Net::WriteTimeout`/`Errno::*` instead of `HTTP::*`) — relevant to APM span queries on `error.type`.
- Faraday-level wrapping keeps the same three classes (`Faraday::TimeoutError`/`ConnectionFailed`/`SSLError`) with one movement between them: a connect/TLS-phase expiry now surfaces as `Faraday::ConnectionFailed` (was `Faraday::TimeoutError`), making `ConnectionFailed` cleanly mean "the request never got through the pipe".
- Net::HTTP's idempotent auto-retry stays disabled (`max_retries = 0`, enforced by the adapter and pinned by a spec) — no behaviour change vs. the previous no-retry client.
- There is no total request budget anymore; worst-case wall clock is the sum of the phase budgets rather than a single number.
- barkibu-kb-fake: disable Sinatra's host authorization (`set :host_authorization, permitted_hosts: []`). Sinatra >= 4.1 authorizes the Host header and, when it infers a development environment, only permits localhost-style hosts — rejecting requests to the stubbed KB host with `403 Host not permitted`. Permitting the host on the consumer side stops working with the net_http adapter, because WebMock intercepts before Net::HTTP adds the Host header, so the header is absent and can never match a permitted list. Consumers can drop their own `set :host_authorization` workarounds.

## [0.32.0]
- Allow Ruby 3.3/3.4: raise `required_ruby_version` ceiling to `< 3.6` (floor stays `>= 2.6`)
- No runtime dependency changes — safe to take with a scoped conservative update (`bundle lock --update barkibu-kb barkibu-kb-fake --conservative`)
- Test-env only: add `base64`/`bigdecimal` dev dependencies and an `activesupport >= 7.1` floor (suite now also validated against ActiveSupport 8). Runtime constraints for consumers unchanged.

## [0.31.0]
- Add `KB::Pet#pet_parent`, a memoized lookup via `PetParent.find`

## [0.30.0]
- Add `KB::Pet.transfer` to call `POST /v1/pets/transfer`; add fake API route

## [0.29.0]
- Add `created_at` field to PetParent DATE_FIELDS

## [0.28.0]
- [Breaking changes] Remove Hubspot models

# [0.27.0]
- Add configuration option for request timeout

# [0.26.0]
- Add `#iban` and `#update_iban` to `PetParent`
- Add /iban endpoints in fake API

# [0.25.0]
- Add support for Ruby 3.2

# [0.24.1]
- Add support for `.referrers` method on `PetParent` in fake model

# [0.24.0]
- Add support for `.referrers` method on `PetParent`

# [0.23.0]
- Add support for `.search` method on `PetContract`

# [0.22.0]
- Fix error parsing if HTTP client returns no response

## [0.21.0]
- Add city attribute to PetParent model

## [0.20.0]
- Expose cache clearing API on client/model

## [0.19.0]
- Remove useless double splat argument usage on concern causing problem for ruby version >= 3

## [0.18.0]

- add support for `payment_interval_months` attribute on `PetContract`
- add active-record like comparison for models

## [0.17.0]

- add `KB::Referral` model to create a referral on a PetParent
- add `PetParent#referrals` to get a list of referrals

## [0.16.2]

- Rename gems to barkibu-kb / barkibu-kb-fake

## [0.16.0]

- Add `Hubspot` model to retrieve information from [Hubspot Relationship endpoint](https://knowledge-base-staging.herokuapp.com/swagger-ui/index.html#/Hubspot)
- Change `husbpot_id` attribute on PetContract, now it comes from the Hubspot Relationship

## [0.15.1]

- Fix Cache invalidation deleting wrong key

## [0.15.0]

- Add `husbpot_id` attribute on PetContract

## [0.14.2]

- Fix Merged Pet Parent instanciation

## [0.14.1]

- Convert API exception into KB::Error for admin `merge!` endpoint

## [0.14.0]

- Add admin `merge!` method on PetParent

## [0.13.0]

- Add `affiliate_code` attribute on PetParent

## [0.12.0]

- Add `phone_number_verified` and `email_verified` attributes on PetParent

## [0.11.0]

- Expose product_key on PetContract

## [0.10.0]

- Add KB::Product Entity

## [0.9.0]

- Add conversion_utm_adgroup_id and conversion_utm_campaign_id to PetContract

## [0.8.0]

- Add conversion*utm*\* attributes to PetContract

## [0.7.2]

- Fix kb-fake pet parent upsert with partial identification

## [0.7.1]

- Fix dsl-configurable positional arg deprecated warning

## [0.7.0]

- Add new Error classes
- Emulate the same behavior on Pet Parent Upsert

## [0.6.0]

- Add price_discount_yearly PetContract attribute

## [0.5.0]

- Switch to consume petfamily based consultation endpoint

## [0.4.10]

- Add affiliate PetContract attributes

## [0.4.9]

- Fix ActiveModel dirty implementation

## [0.4.8]

- Fix KB::Error not accepting nil body

## [0.4.7]

- Breed - Add external_id field

## [0.4.6]

- PetParent - Add more KB fields

## [0.4.5]

- Breeds - Add server endpoint for tests on fake gem

## [0.4.4]

- Breeds - Adjust fields definition to petfamily domain ones

## [0.4.3]

- Breeds - Change client resolver template to use petfamily domain

## [0.4.2]

- Assessment - Parse time from date

## [0.4.1]

- Add Pet Upsert method

## [0.4.0]

- Add Upsert Endpoint

## [0.3.6]

- Add cache to client request method

## [0.3.5]

- Add Dry gem and setup config
- Add cache as gem config settings
- Add log level as gem config settings
- Improve KB Exceptions definitions

## [0.3.4]

- Fix planName attributes wrongly named on Plan

## [0.3.3]

- Fix buyable and planLifeInMonths attributes wrongly named on Plan

## [0.3.2]

- Exposes `KB::PetContract` entity
- Add `contracts` method to `KB::Pet` and `KB::PetParent`

## [0.3.1]

- Fix Fake Consultation wrong endpoint version

## [0.3.0]

- Extracted `kb-fake` gem for client test purposes

## [0.2.7]

- Fix missing deleted_at accessors on PetParent and Pet entities

## [0.2.6]

- Exposes `Destroyable` concerns on PetParent and Pet entities

## [0.2.5]

- Exposes `FindOrCreatable` concerns on PetParent and Pet entities

## [0.2.4]

- Fix Assessment not properly localized

## [0.2.3]

- Fix missing ActiveSupport dependency loading

## [0.2.2]

- Fix custom array types returning single element
- Test dependency extracted

## [0.2.1]

- Fix gem loading order for tests

## [0.2.0]

- Provide FakeApi for client implementation testing
- Add Pet entity
- Add `AsKBWrapper` concern for easy activerecord wrapping
- Add `UniquenessValidator` for easy validation on wrapping model
- `AsKBWrapper` - add `skip_callback` option

## [0.1.1] - 2020-01-12

- Init Version: Breeds and limited PetParents/Consultations

[0.10.0]: https://github.com/barkibu/kb-ruby/compare/v0.9.0...0.10.0
[0.9.0]: https://github.com/barkibu/kb-ruby/compare/v0.8.0...0.9.0
[0.8.0]: https://github.com/barkibu/kb-ruby/compare/v0.7.2...0.8.0
[0.7.2]: https://github.com/barkibu/kb-ruby/compare/v0.7.1...v0.7.2
[0.7.1]: https://github.com/barkibu/kb-ruby/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/barkibu/kb-ruby/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/barkibu/kb-ruby/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/barkibu/kb-ruby/compare/v0.4.10...v0.5.0
[0.4.10]: https://github.com/barkibu/kb-ruby/compare/v0.4.9...v0.4.10
[0.4.9]: https://github.com/barkibu/kb-ruby/compare/v0.4.8...v0.4.9
[0.4.8]: https://github.com/barkibu/kb-ruby/compare/v0.4.7...v0.4.8
[0.4.7]: https://github.com/barkibu/kb-ruby/compare/v0.4.6...v0.4.7
[0.4.6]: https://github.com/barkibu/kb-ruby/compare/v0.4.5...v0.4.6
[0.4.5]: https://github.com/barkibu/kb-ruby/compare/v0.4.4...v0.4.5
[0.4.4]: https://github.com/barkibu/kb-ruby/compare/v0.4.3...v0.4.4
[0.4.3]: https://github.com/barkibu/kb-ruby/compare/v0.4.2...v0.4.3
[0.4.2]: https://github.com/barkibu/kb-ruby/compare/v0.4.1...v0.4.2
[0.4.1]: https://github.com/barkibu/kb-ruby/compare/v0.4.0...v0.4.1
[0.4.0]: https://github.com/barkibu/kb-ruby/compare/v0.3.6...v0.4.0
[0.3.6]: https://github.com/barkibu/kb-ruby/compare/v0.3.5...v0.3.6
[0.3.5]: https://github.com/barkibu/kb-ruby/compare/v0.3.4...v0.3.5
[0.3.4]: https://github.com/barkibu/kb-ruby/compare/v0.3.3...v0.3.4
[0.3.3]: https://github.com/barkibu/kb-ruby/compare/v0.3.2...v0.3.3
[0.3.2]: https://github.com/barkibu/kb-ruby/compare/v0.3.1...v0.3.2
[0.3.1]: https://github.com/barkibu/kb-ruby/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/barkibu/kb-ruby/compare/v0.2.7...v0.3.0
[0.2.7]: https://github.com/barkibu/kb-ruby/compare/v0.2.6...v0.2.7
[0.2.6]: https://github.com/barkibu/kb-ruby/compare/v0.2.5...v0.2.6
[0.2.5]: https://github.com/barkibu/kb-ruby/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/barkibu/kb-ruby/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/barkibu/kb-ruby/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/barkibu/kb-ruby/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/barkibu/kb-ruby/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/barkibu/kb-ruby/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/barkibu/kb-ruby/releases/tag/v0.1.1
