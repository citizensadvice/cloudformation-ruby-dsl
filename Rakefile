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
  raise "Missing NEXUS_USER environment variable during release" if ENV.fetch("NEXUS_USER", "").empty?
  raise "Missing NEXUS_PASSWORD environment variable during release" if ENV.fetch("NEXUS_PASSWORD", "").empty?

  sh("gem nexus --credential \"\$NEXUS_USER:\$NEXUS_PASSWORD\" --nexus-config .nexus.config pkg/*.gem")
end
