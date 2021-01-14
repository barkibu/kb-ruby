require 'pathname'
require 'bundler/setup'
require 'sinatra'
require 'webmock/rspec'
require 'kb'

gem_root = Pathname.new('..').expand_path(File.dirname(__FILE__))
Dir[gem_root.join('spec/support/**/*.rb')].sort.each { |f| require f }

ENV['KB_API_URL_TEMPLATE'] = 'https://test.api.%<bounded_context>s.test_api_barkkb.com/%<version>s/%<entity>s'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
