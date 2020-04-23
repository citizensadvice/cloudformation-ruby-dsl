# frozen_string_literal: true
require "bundler/gem_tasks"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError # rubocop:disable Lint/SuppressedException
  # Recommended pattern from RSpec to prevent load failures
  # when development dependencies aren't available
end

task default: :spec
