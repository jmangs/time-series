# rubocop: disable LeadingCommentSpace
#! /usr/bin/env rake
# rubocop: enable LeadingCommentSpace
require 'bundler/gem_tasks'
require 'yard'
require 'rspec/core/rake_task'
require 'reek/rake/task'
require 'rubocop/rake_task'

task default: :build

# If there are test failures, you'll need to write code to address them.
# So no point in continuing to run the style tests.
desc 'Runs unit/acceptance tests'
RSpec::Core::RakeTask.new(:spec) do |task|
  task.pattern = 'spec/acceptance/**/*.rb,spec/unit/**/*.rb'
end

desc 'Runs integration tests'
RSpec::Core::RakeTask.new(:integration) do |task|
  task.pattern = 'spec/integration/**/*.rb'
end

desc 'Runs yard'
YARD::Rake::YardocTask.new(:yard)

desc 'smells the lib directory, which Reek defaults to anyway'
Reek::Rake::Task.new(:reek) do |task|
  task.verbose = true
end

desc 'smells the spec directory, which is less important than lib'
Reek::Rake::Task.new(:reek_tests) do |task|
  task.source_files = 'spec/**/*.rb'
  task.verbose = true
end

desc 'runs Rubocop'
RuboCop::RakeTask.new

desc 'Runs test and code cleanliness suite: Rubocop, Reek, rspec, and yard'
task run_guards: [:spec, :yard, :reek, :reek_tests, :rubocop]

task build: :run_guards
