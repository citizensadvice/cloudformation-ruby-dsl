# frozen_string_literal: true
# Copyright 2013-2014 Bazaarvoice, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "cloudformation-ruby-dsl/version"

AUTHORS = [
  "Shawn Smith",
  "Dave Barcelo",
  "Morgan Fletcher",
  "Csongor Gyuricza",
  "Igor Polishchuk",
  "Nathaniel Eliot",
  "Jona Fenocchi",
  "Tony Cui",
  "Zhelyan Panchev",
  "Michele Sorcinelli",
  "Ruth Wells",
  "Simon Gill"
].freeze

AUTHOR_EMAILS = [
  "Shawn.Smith@bazaarvoice.com",
  "Dave.Barcelo@bazaarvoice.com",
  "Morgan.Fletcher@bazaarvoice.com",
  "Csongor.Gyuricza@bazaarvoice.com",
  "Igor.Polishchuk@bazaarvoice.com",
  "Nathaniel.Eliot@bazaarvoice.com",
  "Jona.Fenocchi@bazaarvoice.com",
  "Tony.Cui@bazaarvoice.com",
  "zhelyan.panchev@citizensadvice.org.uk",
  "michele.sorcinelli@citizensadvice.org.uk",
  "ruth.wells@citizensadvice.org.uk",
  "simon.gill@citizensadvice.org.uk"
].freeze

Gem::Specification.new do |gem| # rubocop:disable Metrics/BlockLength
  gem.name          = "cloudformation-ruby-dsl"
  gem.version       = Cfn::Ruby::Dsl::VERSION
  gem.authors       = AUTHORS
  gem.email         = AUTHOR_EMAILS
  gem.description   = "Ruby DSL library that provides a wrapper around the CloudFormation."
  gem.summary       = <<~SUMMARY
    Ruby DSL library that provides a wrapper around CloudFormation data structures.  Originally written by [Bazaarvoice](http://www.bazaarvoice.com)
    and forked by Citizens Advice to meet internal needs.
  SUMMARY
  gem.homepage = "http://github.com/citizensadvice/cloudformation-ruby-dsl"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  raise "RubyGems 2.0 or newer is required to protect against public gem pushes." unless gem.respond_to?(:metadata)

  gem.metadata["allowed_push_host"] = "https://nexus.devops.citizensadvice.org.uk/repository/citizensadvice/"

  gem.metadata["homepage_uri"] = gem.homepage
  gem.metadata["source_code_uri"] = "https://github.com/citizensadvice/cloudformation-ruby-dsl"
  gem.metadata["changelog_uri"] = "https://github.com/citizensadvice/cloudformation-ruby-dsl/CHANGELOG.md"

  gem.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w[lib bin]

  gem.required_ruby_version = "~> 2.6.5"

  gem.add_runtime_dependency    "aws-sdk-cloudformation", "~> 1.24"
  gem.add_runtime_dependency    "aws-sdk-s3", "~> 1.45"
  gem.add_runtime_dependency    "bundler", "~> 2.0"
  gem.add_runtime_dependency    "detabulator", "~> 0.1.0"
  gem.add_runtime_dependency    "diffy", "~> 3.3"
  gem.add_runtime_dependency    "highline", "~> 2.0"
  gem.add_runtime_dependency    "rake", "~> 12.3"

  gem.add_development_dependency "cfn-model", "~> 0.4.0"
  gem.add_development_dependency "nexus", "~> 1.4"
  gem.add_development_dependency "pry", "~> 0.12.0"
  gem.add_development_dependency "rspec", "~> 3.8"
  gem.add_development_dependency "simplecov", "~> 0.18.0"
  gem.add_development_dependency "yard", "~> 0.9.0"
end
