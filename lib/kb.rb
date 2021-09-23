require 'kb/version'
require 'active_model'
require 'active_record'
require 'active_support'
require 'active_support/core_ext/array'
require 'faraday'
require 'faraday_middleware'
require 'faraday/http'
require 'dry/configurable'

module KB
  extend Dry::Configurable

  setting :cache do
    setting :instance, ActiveSupport::Cache::NullStore.new
    setting :expires_in, 0
  end

  setting :log_level, :info
end

require 'kb/inflections'

require 'kb/cache'
require 'kb/client_resolver'
require 'kb/errors'
require 'kb/client'

require 'kb/concerns'
require 'kb/models'

require 'kb/validators'
