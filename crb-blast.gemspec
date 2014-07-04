Gem::Specification.new do |gem|
  gem.name        = 'crb-blast'
  gem.version     = '0.2'
  gem.date        = '2014-04-28'
  gem.summary     = "Run conditional reciprocal best blast"
  gem.description = "See summary"
  gem.authors     = ["Chris Boursnell", "Richard Smith-Unna"]
  gem.email       = 'cmb211@cam.ac.uk'
  gem.files       = ["lib/crb-blast.rb", "lib/hit.rb", "bin/crb-blast"]
  gem.executables = ["crb-blast"]
  gem.require_paths = %w( lib )
  gem.homepage    = 'http://rubygems.org/gems/crb-blast'
  gem.license     = 'MIT'

  gem.add_dependency 'trollop'
  gem.add_dependency 'rake'
  gem.add_dependency 'bio', '~> 1.4', '>= 1.4.3'
  gem.add_dependency 'which', '0.0.2'

  gem.add_development_dependency 'turn'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'shoulda-context'
  gem.add_development_dependency 'coveralls', '>= 0.6.7'
end