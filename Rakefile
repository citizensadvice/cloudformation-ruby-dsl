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

task :current_version do
  puts Cfn::Ruby::Dsl::VERSION
end

# We can normally assume that any integration to develop is going to lead to a minor release. Using this number forces the precedence of this package
# higher than the current release for any gem which allows develop prereleases.
# Build numbers don't reset with version, so even if we push a patch release instead of a minor release, there shouldn't be a conflict.
# We can use clean-up rules in nexus to clear out old versions as well.
task :prerelease_version, [:build_number] do |_, args|
  assumed_minor_version = Cfn::Ruby::Dsl::MINOR_VERSION + 1
  puts "#{Cfn::Ruby::Dsl::MAJOR_VERSION}.#{assumed_minor_version}.#{Cfn::Ruby::Dsl::PATCH_VERSION}-develop.#{args[:build_number]}"
end
