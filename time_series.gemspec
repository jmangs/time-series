# -*- encoding: utf-8 -*-
# vim: ft=ruby

require File.expand_path('../lib/time_series/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Uday Jarajapu', 'Jan Mangs', 'Ravikumar Gudipati']
  gem.email         = %w(uday.jarajapu@opower.com jmangs@gmail.com ravikumar.gudipati@opower.com)
  gem.description = 'Provides a set of tools for working with time series data in OpenTSDB data store'
  gem.summary = 'OpenTSDB Gem'

  gem.files         = `git ls-files`.split($ORS)
  gem.executables   = gem.files.grep(/^bin\//).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(/^(test|spec|features)\//)
  gem.name          = 'time_series'
  gem.require_paths = %w(lib)
  gem.version       = Opower::TimeSeries::VERSION

  # dependencies.
  gem.add_dependency('excon')
  gem.add_dependency('dentaku', '~> 1.2.0')

  # development dependencies.
  gem.add_development_dependency('rspec', '~> 3.0')
  gem.add_development_dependency('simplecov', '~> 0.7.0')
  gem.add_development_dependency('guard', '~> 2.0')
  gem.add_development_dependency('guard-rspec', '~> 4.0')
  gem.add_development_dependency('rubocop', '~> 0.28.0')
  gem.add_development_dependency('rainbow', '~> 2.0')
  gem.add_development_dependency('guard-rubocop', '~> 1.0')
  gem.add_development_dependency('metric_fu', '~> 4.2.0')
  gem.add_development_dependency('guard-reek', '~> 0.0.4')
  gem.add_development_dependency('rake', '~> 10.0.1')
  gem.add_development_dependency('yard', '~> 0.8.7')
  gem.add_development_dependency('redcarpet', '~> 2.3.0')
  gem.add_development_dependency('webmock', '~> 1.20.0')
  gem.add_development_dependency('docker-api', '~> 1.17.0')
end
