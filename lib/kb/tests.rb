if defined?(Sinatra)
  require 'kb/tests/fake_api'
else
  require 'kb/tests/fake_api_missing_sinatra'
end
