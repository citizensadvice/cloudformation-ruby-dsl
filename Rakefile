# frozen_string_literal: true
require "bundler/gem_tasks"
require "cloudformation-ruby-dsl/version"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError # rubocop:disable Lint/SuppressedException
  # Recommended pattern from RSpec to prevent load failures
  # when development dependencies aren't available
end

task default: :spec

Rake::Task["release:rubygem_push"].clear
task "release:rubygem_push" do
  sh("gem nexus --credential \"\$NEXUS_USER:\$NEXUS_PASSWORD\" --nexus-config .nexus.config pkg/*.gem")
end
