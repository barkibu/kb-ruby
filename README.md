# Barkibu's Knowledge Base API sdk

A wrapper of Barkibu's Knowledge Base Endpoint to make those entities and their respective CRUD operations available to a ruby app.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'barkibu-kb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install kb

## Development

Specs and RuboCop run on every pull request (`.github/workflows/ci.yml`) on Ruby 3.4. Locally:

```sh
docker compose run --rm kb bundle exec rspec
docker compose run --rm kb bundle exec rubocop lib spec
```

## Usage

This gem wraps the Knowledge Base Api and exposes CRUD-_able_ entities into the requiring application.

### Configuration

The configuration of the connection to the Knowledge Base is done using ENV variable:

- **KB_API_KEY**: the Knowledge Base API Key
- **KB_PARTNER_KEY**: the Partner KB Key
- **KB_API_URL_TEMPLATE**: the template url of the Knowledge Base where will be extrapolated _bounded_context_, _version_ and _entity_.

  For instance: `https://dev.api.%{bounded_context}.barkkb.com/%{version}/%{entity}`.

#### Cache configuration

We add the ability to cache GET responses. To enable it, just set KB.config.cache properties:
```ruby
# config/initializers/kb_ruby.rb
KB.config.cache.instance = Rails.cache # ActiveSupport::Cache::NullStore.new
KB.config.cache.expires_in = 1.second # 0 by default
KB.config.log_level = :debugger # :info by default
```

#### Request timeout configuration

Timeouts are per phase, and each phase fails with its own error class:
`connect_timeout` maps to Net::HTTP's `open_timeout`, bounding TCP connect plus
the TLS handshake (`Net::OpenTimeout`); `read_timeout` bounds the wait for the
response (`Net::ReadTimeout`); `write_timeout` bounds sending the request
(`Net::WriteTimeout`).

```ruby
# config/initializers/kb_ruby.rb
KB.config.request.connect_timeout = 2 # 1 by default; TCP connect + TLS handshake
KB.config.request.write_timeout = 4   # 3 by default
KB.config.request.read_timeout = 10   # 5 by default
```

The read budget can be raised for a single call through `KB::Client#request`, for
the few endpoints whose server-side work legitimately runs for seconds. Connect
and write budgets stay global:

```ruby
KB::Pet.kb_client.request('birthdays', filters: { month: 9, day: 22, size: 1000 }, read_timeout: 30)
```

#### Retries

The client retries a failed call once when the failure is in the transport, never
when KB answered with an HTTP error. Which calls retry depends on whether the
request can have reached KB (`KB::RetryPolicy`):

| Failure | Retried for |
|---|---|
| Never sent: connect/TLS timeout (`Net::OpenTimeout`), connection refused, host/network unreachable, DNS failure | every verb, POST included |
| Maybe sent: read/write timeout, connection reset, EOF, TLS error mid-stream | GET and HEAD only |
| HTTP 4xx/5xx | never |

PUT and DELETE are not retried on "maybe sent" failures: `upsert` and
`PetParent#merge!` are PUTs whose second run is not a no-op on KB's side, and a
repeated DELETE would turn a success into a 404. A call that raised its own read
budget (`read_timeout:` on `KB::Client#request`) is not retried on "maybe sent"
failures either, so a 30s birthdays read can't become 60s; failures that never
reached KB are still retried.

```ruby
# config/initializers/kb_ruby.rb
KB.config.request.retries = 1          # default; 0 disables retries
KB.config.request.retry_interval = 0.1 # default, seconds; each wait is 1x-2x this
```

Like the timeouts, these are read when a client builds its connection, i.e. on
its first call, so set them in an initializer.

Worst case, a call now takes two attempts' worth of phase budgets plus the
interval, e.g. a GET that read-times-out twice takes about 2 x (1 + 3 + 5)s with
the default timeouts.

#### Keep-alive connections

KB calls reuse TCP/TLS connections instead of opening a new one per call
(`KB::PersistentAdapter`, net-http-persistent under faraday-net_http_persistent).
One pool per process is shared by every model's client, and each thread checks a
connection out per call. A pooled connection that has been idle longer than
`idle_timeout` is closed and reopened on the next call.

```ruby
# config/initializers/kb_ruby.rb
KB.config.request.keep_alive = true # default; false opens a connection per call (faraday-net_http)
KB.config.request.idle_timeout = 30 # default, seconds
```

Keep `idle_timeout` below the Heroku router's own idle close: it drops an idle
client connection after about 55 seconds (measured against KB staging, both
`kb-staging.barkibu.com` and the herokuapp.com host, 2026-09-23). A connection the
router already closed is detected before reuse and reopened, but staying below
the router's limit avoids the race.

Per-call timeouts (`read_timeout:` on `KB::Client#request`) apply to that call
only, and error classes are the same as without keep-alive: a connect timeout is
`Faraday::ConnectionFailed` wrapping `Net::OpenTimeout`, a refused connection is
`Faraday::ConnectionFailed` wrapping `Errno::ECONNREFUSED`.

Two differences from `keep_alive = false`: `connect_timeout` and `idle_timeout`
are read once per process, when the shared pool is built on the first KB call
(set them in an initializer, or call `KB::PersistentAdapter.reset!` after changing
them), and `HTTP(S)_PROXY` environment variables are not honoured.

On forking servers (Puma cluster, Sidekiq swarm), connection_pool drops pooled
connections in the child after fork on Ruby >= 3.1. A preloading parent that
calls KB before forking shares those sockets with its children; the parent
recovers by reconnecting on the next call.

#### Instrumentation

Every KB call emits one `request.kb_client` event through
`ActiveSupport::Notifications`, wrapping the whole call: cache lookup, TCP
connect, TLS, write, read and JSON parsing. The payload carries `verb`, `path`,
`base_url`, `cache_hit` (GET calls only), `status` (when a response arrived),
`retries` and `retry_errors` (only when the call was retried: the count, and the
underlying error class of each failed attempt, e.g. `["Net::OpenTimeout"]`),
`connections` (with keep-alive: `"new"` or `"reused"` per attempt, e.g.
`["reused", "new"]` for a call whose reused connection failed and whose retry
opened a fresh one) and
ActiveSupport's `exception` / `exception_object` when the call raised. The event
covers the whole call including retries, so `exception` is set only when every
attempt failed. Subscribe to it for logging, metrics or anything else:

```ruby
ActiveSupport::Notifications.subscribe(KB::Client::REQUEST_EVENT) do |event|
  Rails.logger.info("KB #{event.payload[:verb]} #{event.payload[:path]} #{event.duration.round}ms")
end
```

##### Datadog

A ready-made subscriber turns each event into a `kb.client.request` APM span.
Opt in from the app's Datadog initializer, after `Datadog.configure`. Works with
both `ddtrace` 1.x and `datadog` 2.x; the tracer gem is the app's dependency.

```ruby
# config/initializers/datadog_tracer.rb
Datadog.configure { |c| ... }

require 'kb/instrumentation/datadog'
KB::Instrumentation::Datadog.subscribe!
```

The span opens when the event starts and closes when it finishes, so the
tracer's own Net::HTTP spans nest under it. It inherits the app's service
(`c.service`), so nothing new appears in the APM service list, and it carries no
`span.kind:client` or `peer.service`, so Datadog does not attribute it to the
knowledge-base service either: it measures the client's whole call, not a KB
operation. Resources are low-cardinality (`GET /v1/pets/birthdays`,
`GET /v1/pets/?/contracts`). Tags: `peer.hostname` (the KB host used),
`kb.method`, `kb.cache_hit` (GET calls only), `http.status_code`,
`kb.connections` (e.g. `reused` or `reused,new`), `kb.retries` and
`kb.retry_errors` (retried calls only), plus the standard
`error.type`/`error.message` when the call raises. A span with `kb.retries` and
no error is a failure the retry absorbed.

Why not rely on the Net::HTTP tracer alone: faraday-net_http opens the socket
before `Net::HTTP#request`, the method that tracer patches, so a connect timeout
produces no http span at all. This span sees every phase.

### Exposed Entities

#### Pet Parent 🧍🏾

`KB::PetParent` acts almost like an `ActiveRecord` implementing `ActiveModel::Model` exposing:

- `find`
  - arg: `key` string
  - returns: a PetParent instance when provided an existing key or raise `ActiveRecord::RecordNotFound`
- `create`
  - arg: `attributes` to initialize the entity
  - returns: the raw attributes of the created PetParent instance
  - throws an `KB::Error` exception if something went wrong
- `find_or_create_by`
  - arg: `attributes`, `additional_attributes` to look for or initialize the entity
  - returns: look for a PetParent matching the passed attributes or initialize and persist one with the given attributes and launching the block provided
  - throws an `KB::Error` exception if something went wrong
- `all`
  - arg: `filters` hash of filters
  - returns: an array of PetParent instances matching the filters
- `save!`
  - persists (create or update) the entity to the Knowledge Base
  - throws an `KB::Error` exception if something went wrong
- `destroy!`
  - deletes the entity in the Knowledge Base
  - throws a `KB::Error` exception if something went wrong
- `contracts`
  - returns all the KB::PetContract associated with this pet parent
- `referrals`
  - returns all the KB::Referral associated with this pet parent
- `referrers`
  - returns all the KB::Referral associated with any of the pet parent's pets
- `iban`
  - returns the IBAN of the pet parent
- `update_iban`
  - arg: `iban` string
  - updates the IBAN of the pet parent and reloads the entity

#### Assessment 📄

`KB::Assessment` represents a read-only resource exposing:

- `find`
  - arg: `key` string
  - returns: an Assessment instance when provided an existing key or raise `ActiveRecord::RecordNotFound`
- `all`
  - arg: `filters` hash of filters
  - returns: an array of Assessment instances matching the filters

#### Condition 🏷

`KB::Condition` represents a read-only resource.

#### Symptom 🩺

`KB::Symptom` represents a read-only resource.

#### Pet 🐶🐱

`KB::Pet` represents a resource exposing:

- `all`
  - arg: `filters` hash of filters
  - returns: an array of Pet instances matching the filters
- `create`
  - arg: `attributes` to initialize the entity
  - returns: the raw attributes of the Pet instance
  - throws an `KB::Error` exception if something went wrong
- `find_or_create_by`
  - arg: `attributes`, `additional_attributes` to look for or initialize the entity
  - returns: look for a Pet matching the passed attributes or initialize and persist one with the given attributes and launching the block provided
  - throws an `KB::Error` exception if something went wrong
- `save!`
  - persists (create or update) the entity to the Knowledge Base
  - throws an `KB::Error` exception if something went wrong
- `destroy!`
  - deletes the entity in the Knowledge Base
  - throws a `KB::Error` exception if something went wrong
- `contracts`
  - returns all the KB::PetContract associated with this pet
- `upsert`
  - updates KB:Pet if exists a Pet with same name for its PetParent
  - creates a new KB:Pet if not exists a Pet with same name for its PetParent

#### PetContract 📝

`KB::PetContract` represents a resource exposing:

- `find`
  - arg: `key` the key of the contract in the Knowledge Base
  - returns the contract with the matching key
  - throws an `KB::Error` or `KB::ResourceNotFound` exception if something went wrong
- `find_by_contract_number`
  - arg: `contract_number` the contract number to find
  - returns the identified KB::PetContract
  - throws an `KB::Error` or `KB::ResourceNotFound` exception if something went wrong
- `create`
  - arg: `attributes` to initialize the entity
  - returns: the raw attributes of the PetContract instance
  - throws an `KB::Error` exception if something went wrong
- `save!`
  - persists (create or update) the entity to the Knowledge Base
  - throws an `KB::Error` exception if something went wrong
- `search`
  - arg: `filters` hash. Currently, KB API supports these keys:
    - `page`: results page number. Default 0.
    - `size`: amount of results per page. Default 10.
    - `chip`: searches contracts by insured pet chip
  - returns: a hash including:
    - `total`: total amount of contracts found
    - `page`: current page number
    - `elements`: array of PetContract instances matching the filters

#### Plan 🗺

`KB::Plan` represents a resource exposing:

- `all`
  - returns: the array of available plans

#### Breed

```
> KB Breed endpoint requires `locale` as param. By default is set to 'es-es' but can be override setting **KB_BREEDS_DEFAULT_LOCALE** ENV var
```

`KB::Breed` represents a resource exposing:

- `all`
  - arg: `filters` hash of filters
  - returns: and array of Breed instances matching the filters
- `dogs` (alias for all(species: 'dog'))
  - arg: `filters` hash of filters
  - returns: and array of Dog Breed instances matching the filters
- `cats` (alias for all(species: 'cat'))
  - arg: `filters` hash of filters
  - returns: and array of Cat Breed instances matching the filters

#### Referral
`KB::Referral` represets a referral resource

- `create`
  - arg: `pet_parent_key`, `attributes` to initialize the entity
  - returns: the raw attributes of the Referral instance
  - throws an `KB::Error` exception if something went wrong

### Make an ActiveRecord wrap a KB entity

The `KB::Concerns::AsKBWrapper` concern has been created in order to easily make an ActiveRecord model wrap a KB model.

To use it:

- include it into your wrapping model, define an attribute `kb_key` on your wrapping model
- call `wrap_kb` with the wrapped KB model class (available option: `skip_callback`)

You have then access to the wrapped model under `kb_model` and can delegate attributes to it, for instance:

```ruby
class User < ActiveRecord::Base
  include KB::Concerns::AsKBWrapper

  wrap_kb model: KB::PetParent

  KB_DELEGATED_ATTRIBUTES = %i[email first_name].freeze

  KB_DELEGATED_ATTRIBUTES.each do |attribute|
    delegate attribute, to: :kb_model, prefix: false
    delegate "#{attribute}=", to: :kb_model, prefix: false
  end
end

user = User.create(first_name: 'Léo', email: 'leo@barkibu.com')
p user.kb_model
# => #<KB::PetParent: 0x000055fd72d32c30 key: "373ad90e-c2ce-46cb-9749-deb2b03be995", first_name: "Léo", ..., email: "leo@barkibu.com">
```

### Mock the API calls in test environment

For testing purposes, you may want to fake Knowledge Base’s API calls. We provide a FakeApi app that you can use including the `kb-fake` gem in your dev/test dependencies.

Add gem webmock and gem sinatra to your Gemfile to use the following configuration:

```ruby
    # ...

    RSpec.configure do |config|
        # ...
        config.before(:all) do
            stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::Api)
        end

        config.around(:each) do |example|
            snapshot = KB::Fake::Api.snapshot()
            stub_request(:any, /test_api_barkkb.com/).to_rack(KB::Fake::Api)
            example.run
            KB::Fake::Api.restore snapshot
        end
        # ...
    end
```

Make sure to set the `KB_API_URL_TEMPLATE` to something that will match above the request interceptor, for instance: `http://test_api_barkkb.com/%{version}/%{entity}`

You should be able to use the API seemlessly and the calls to the API will be intercepted and a local one used instead in a similar fashion to how ActiveRecord operations are wrapped into a transaction in a rails app with `use_transactional_fixtures` activated.

## Development & Testing

```bash
docker compose run --rm kb bash
> bundle install
> rspec
```

You can also start an interactive console if needed:
```bash
KB_API_URL_TEMPLATE=https://example.com/%{version}/%{entity} \
KB_API_KEY=YourKbApiKey \
KB_PARTNER_KEY=YourKbPartnerKey \
bin/console
```
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/kb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the KB project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kb/blob/master/CODE_OF_CONDUCT.md).
