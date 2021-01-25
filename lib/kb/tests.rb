def require_or_exit(gem)
rescue LoadError
  puts "#{gem.capitalize} was not found, please add \"gem \"#{gem}\"\" to your Gemfile."
  exit 1
end

require_or_exit 'sinatra'
require_or_exit 'webmock'

require 'kb/tests/fake_api'
