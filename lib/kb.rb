require 'kb/version'
require 'active_model'
require 'active_record'
require 'active_support'
require 'active_support/core_ext/array'
require 'faraday'
require 'faraday_middleware'
require 'faraday/http'

module KB
end

require 'kb/inflections'

require 'kb/client_resolver'
require 'kb/error'
require 'kb/client'

require 'kb/concerns'
require 'kb/models'

require 'kb/validators'

require 'kb/tests'
