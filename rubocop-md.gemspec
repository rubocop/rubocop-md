lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rubocop/markdown/version"

Gem::Specification.new do |spec|
  spec.name          = "rubocop-md"
  spec.version       = Rubocop::Markdown::VERSION
  spec.authors       = ["Vladimir Dementyev"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = %q{Run Rubocop against your Markdown files to make sure that code examples follow style guidelines.}
  spec.description   = %q{Run Rubocop against your Markdown files to make sure that code examples follow style guidelines.}
  spec.homepage      = "https://github.com/palkan/rubocop-md"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "rubocop", "~> 0.50"
  spec.add_runtime_dependency "kramdown", "~> 1.16"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
