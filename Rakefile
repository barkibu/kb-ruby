lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec/core/rake_task'
require 'kb/version'

RSpec::Core::RakeTask.new(:spec)

desc 'Build gem into the pkg directory'
task :build do
  FileUtils.rm_rf('pkg')
  Dir['*.gemspec'].each do |gemspec|
    system "gem build #{gemspec}"
  end
  FileUtils.mkdir_p('pkg')
  FileUtils.mv(Dir['*.gem'], 'pkg')
end

desc 'Tags version, pushes to remote, and pushes gem'
task release: :build do
  sh 'git', 'tag', '-m', changelog, "v#{KB::VERSION}"
  sh "git push origin v#{KB::VERSION}"
  sh 'ls pkg/*.gem | xargs -n 1 gem push'
end

def changelog
  File.read('CHANGELOG.md').split(/##.*$\n/)[1].gsub("\n\n", "\n")
end
