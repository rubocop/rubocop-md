# frozen_string_literal: true

require_relative "lib/rubocop/markdown/version"

Gem::Specification.new do |spec|
  spec.name          = "rubocop-md"
  spec.version       = RuboCop::Markdown::VERSION
  spec.authors       = ["Vladimir Dementyev"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = %q{Run Rubocop against your Markdown files to make sure that code examples follow style guidelines.}
  spec.description   = %q{Run Rubocop against your Markdown files to make sure that code examples follow style guidelines.}
  spec.homepage      = "https://github.com/rubocop/rubocop-md"
  spec.license       = "MIT"

  spec.files = Dir.glob("lib/**/*") + Dir.glob("config/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/rubocop/rubocop-md/issues",
    "changelog_uri" => "https://github.com/rubocop/rubocop-md/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://github.com/rubocop/rubocop-md/blob/master/README.md",
    "homepage_uri" => "https://github.com/rubocop/rubocop-md",
    "source_code_uri" => "http://github.com/rubocop/rubocop-md"
  }

  spec.required_ruby_version = ">= 2.6.0"

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rubocop", ">= 1.0"

  spec.add_development_dependency "bundler", ">= 1.15"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
