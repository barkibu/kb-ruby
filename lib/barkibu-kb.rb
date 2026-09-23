require 'kb/version'
require 'active_model'
require 'active_record'
require 'active_support'
require 'active_support/core_ext/array'
require 'faraday'
require 'faraday_middleware'
require 'dry/configurable'

module KB
  extend Dry::Configurable

  setting :cache do
    setting :instance, default: ActiveSupport::Cache::NullStore.new
    setting :expires_in, default: 0
  end

  setting :log_level, default: :info

  setting :request do
    setting :connect_timeout, default: 1
    setting :write_timeout, default: 3
    setting :read_timeout, default: 5
    # Retries after a transport failure, per KB::RetryPolicy. 0 disables retries.
    setting :retries, default: 1
    setting :retry_interval, default: 0.1
    # Reuse connections to KB across calls (KB::PersistentAdapter). false falls
    # back to one connection per call (faraday-net_http).
    setting :keep_alive, default: true
    # Seconds an idle pooled connection is kept before the next call reconnects.
    # Keep it below the Heroku router's idle close (~55s, measured on KB staging).
    setting :idle_timeout, default: 30
  end
end

require 'kb/inflections'

require 'kb/cache'
require 'kb/client_resolver'
require 'kb/errors'
require 'kb/retry_policy'
require 'kb/persistent_adapter'
require 'kb/client'

require 'kb/concerns'
require 'kb/models'

require 'kb/validators'
