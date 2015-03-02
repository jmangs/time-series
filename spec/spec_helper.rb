require 'simplecov'
require 'webmock/rspec'

SimpleCov.start 'rails' do
  coverage_dir 'metrics/coverage'
end

pid = Process.pid
SimpleCov.at_exit do
  SimpleCov.result.format! if Process.pid == pid
end

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require File.expand_path('../fixtures.rb', __FILE__)
