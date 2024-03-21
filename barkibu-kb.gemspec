lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kb/version'

Gem::Specification.new do |spec|
  spec.name          = 'barkibu-kb'
  spec.version       = KB::VERSION
  spec.authors       = ['Léo Figea']
  spec.email         = ['leo@barkibu.com']

  spec.summary       = "Barkibu's Knowledge Base API sdk"
  spec.description   = "A wrapper of Barkibu's Knowledge Base Endpoint to make those entities and their respective CRUD operations available to a ruby app" # rubocop:disable Layout/LineLength
  spec.homepage      = 'https://app.barkibu.com'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    # spec.metadata['allowed_push_host'] = 'http://mygemserver.com'

    spec.metadata['homepage_uri'] = spec.homepage
    # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
    # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
          'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6', '< 3.3'

  spec.add_dependency 'dry-configurable', '~> 0.9'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'webmock'
  spec.add_runtime_dependency 'activemodel', '>= 4.0.2'
  spec.add_runtime_dependency 'activerecord'
  spec.add_runtime_dependency 'activesupport', '>= 3.0.0'
  spec.add_runtime_dependency 'faraday'
  spec.add_runtime_dependency 'faraday-http'
  spec.add_runtime_dependency 'faraday_middleware'
  spec.add_runtime_dependency 'i18n'
end
