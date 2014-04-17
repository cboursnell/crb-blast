Gem::Specification.new do |gem|
  gem.name        = 'crb-blast'
  gem.version     = '0.0.1'
  gem.date        = '2014-04-17'
  gem.summary     = "Run conditional reciprocal best blast"
  gem.description = "See summary"
  gem.authors     = ["Chris Boursnell", "Richard Smith-Unna"]
  gem.email       = 'rds45@cam.ac.uk'
  gem.files       = ["lib/crb-blast.rb"]
  gem.homepage    = 'http://rubygems.org/gems/crb-blast'
  gem.license     = 'MIT'
  gem.add_dependency 'bio', '~> 1.4.3'
  gem.add_dependency 'which', '0.0.2'
end