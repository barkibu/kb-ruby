lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kb/version'

Gem::Specification.new do |spec|
  spec.name          = 'barkibu-kb-fake'
  spec.version       = KB::VERSION
  spec.authors       = ['Léo Figea']
  spec.email         = ['leo@barkibu.com']

  spec.summary       = "Barkibu's Knowledge Base Fake API"
  spec.description   = "A fake API of Barkibu's Knowledge Base destined to be used in tests for application using the kb-ruby gem." # rubocop:disable Layout/LineLength
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
  spec.files = `git ls-files -- lib | grep fake`.split("\n").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.6'

  spec.add_runtime_dependency 'barkibu-kb', KB::VERSION
  spec.add_runtime_dependency 'countries'
  spec.add_runtime_dependency 'sinatra'
  spec.add_runtime_dependency 'webmock'
end
