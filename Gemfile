source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in rubocop-md.gemspec
gemspec

gem "debug", platform: :mri unless ENV["CI"] == "true"

local_gemfile = "#{__dir__}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
end
