
require File.expand_path('../lib/crb-blast/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'crb-blast'
  gem.version     = CRB_Blast::VERSION::STRING.dup
  gem.date        = '2015-05-19'
  gem.summary     = "Run conditional reciprocal best blast"
  gem.description = "See summary"
  gem.authors     = ["Chris Boursnell", "Richard Smith-Unna"]
  gem.email       = 'cmb211@cam.ac.uk'
  gem.files       = `git ls-files`.split("\n")
  gem.executables = ["crb-blast"]
  gem.require_paths = %w( lib )
  gem.homepage    = 'https://github.com/cboursnell/crb-blast'
  gem.license     = 'MIT'

  gem.add_dependency 'trollop', '~> 2.0'
  gem.add_dependency 'bio', '~> 1.4', '>= 1.4.3'
  gem.add_dependency 'fixwhich', '~> 1.0', '>= 1.0.2'
  gem.add_dependency 'threach', '~> 0.2', '>= 0.2.0'
  gem.add_dependency 'bindeps', '~> 1.0', '>= 1.0.3'

  gem.add_development_dependency 'rake', '~> 10.3', '>= 10.3.2'
  gem.add_development_dependency 'turn', '~> 0.9', '>= 0.9.7'
  gem.add_development_dependency 'simplecov', '~> 0.8', '>= 0.8.2'
  gem.add_development_dependency 'shoulda-context', '~> 1.2', '>= 1.2.1'
  gem.add_development_dependency 'coveralls', '~> 0.7'
end
