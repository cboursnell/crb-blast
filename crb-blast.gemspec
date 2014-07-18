Gem::Specification.new do |gem|
  gem.name        = 'crb-blast'
  gem.version     = '0.3'
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

  gem.add_dependency 'trollop', '~> 2.0'
  gem.add_dependency 'bio', '~> 1.4', '>= 1.4.3'
  gem.add_dependency 'which', '0.0.2'
  gem.add_dependency 'threach', '~> 0.2', '>= 0.2.0'
  gem.add_dependency 'bindeps', '~> 0.0', '>= 0.0.7'

  gem.add_development_dependency 'rake', '~> 10.3', '>= 10.3.2'
  gem.add_development_dependency 'turn', '~> 0.9', '>= 0.9.7'
  gem.add_development_dependency 'simplecov', '~> 0.8', '>= 0.8.2'
  gem.add_development_dependency 'shoulda-context', '~> 1.2', '>= 1.2.1'
  gem.add_development_dependency 'coveralls', '~> 0.7'
end
