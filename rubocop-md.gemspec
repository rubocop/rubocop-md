lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rubocop/markdown/version"

Gem::Specification.new do |spec|
  spec.name          = "rubocop-md"
  spec.version       = RuboCop::Markdown::VERSION
  spec.authors       = ["Vladimir Dementyev"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = %q{Run Rubocop against your Markdown files to make sure that code examples follow style guidelines.}
  spec.description   = %q{Run Rubocop against your Markdown files to make sure that code examples follow style guidelines.}
  spec.homepage      = "https://github.com/palkan/rubocop-md"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/rubocop-hq/rubocop-md/issues",
    "changelog_uri" => "https://github.com/rubocop-hq/rubocop-md/blob/master/CHANGELOG.md",
    "documentation_uri" => "https://github.com/rubocop-hq/rubocop-md/blob/master/README.md",
    "homepage_uri" => "https://github.com/rubocop-hq/rubocop-md",
    "source_code_uri" => "http://github.com/rubocop-hq/rubocop-md"
  }

  spec.required_ruby_version = ">= 2.6.0"

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rubocop", ">= 1.0"

  spec.add_development_dependency "bundler", ">= 1.15"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
