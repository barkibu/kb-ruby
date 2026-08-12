# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [unreleased]
- See diff: https://github.com/barkibu/kb-ruby/compare/v1.0.0...HEAD

## [1.0.0]
- [Breaking changes] Split the single global request timeout into per-phase budgets: `KB.config.request.connect_timeout` (default 1s, bounds TCP connect + TLS handshake), `write_timeout` (default 3s), `read_timeout` (default 5s). `KB.config.request.timeout` is removed — assigning it now raises `NoMethodError` at boot. Migration: a previous global `timeout` maps to `read_timeout` (e.g. `KB_REQUEST_TIMEOUT_SECONDS=12` → `read_timeout = 12`).
- [Breaking changes] Switch the HTTP adapter from http.rb (`faraday-http`) to Net::HTTP (`faraday-net_http`) — the stock adapter honours all three phase timeouts, aligns the KB client with the rest of our outbound HTTP, and opens a one-line upgrade path to `faraday-net_http_persistent` for connection reuse. Raw error classes change accordingly (`Net::OpenTimeout`/`Net::ReadTimeout`/`Net::WriteTimeout`/`Errno::*` instead of `HTTP::*`) — relevant to APM span queries on `error.type`.
- Faraday-level wrapping keeps the same three classes (`Faraday::TimeoutError`/`ConnectionFailed`/`SSLError`) with one movement between them: a connect/TLS-phase expiry now surfaces as `Faraday::ConnectionFailed` (was `Faraday::TimeoutError`), making `ConnectionFailed` cleanly mean "the request never got through the pipe".
- Net::HTTP's idempotent auto-retry stays disabled (`max_retries = 0`, enforced by the adapter and pinned by a spec) — no behaviour change vs. the previous no-retry client.
- There is no total request budget anymore; worst-case wall clock is the sum of the phase budgets rather than a single number.

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
