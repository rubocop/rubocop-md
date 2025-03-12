# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "debug" unless ENV["CI"] == "true"

if ENV["MD_LOAD_MODE"] == "options"
  $stdout.puts "⚙️ Run rubocop with '--plugin rubocop-md' options"
elsif ENV["MD_LOAD_MODE"] == "config"
  $stdout.puts "⚙️ Run rubocop with 'plugins: - rubocop-md' in .rubocop.yml"
end

require "minitest/autorun"

require "rubocop"
require "rubocop_assertions"
require "markdown_assertions"

# NOTE: Since a custom testing framework is used, the following abstraction
# for plugin callbacks during testing is not implemented yet.
# https://github.com/rubocop/rubocop/pull/13840
RuboCop::Plugin.integrate_plugins(RuboCop::Config.new, ["rubocop-md"])

RuboCop::Markdown.config_store = RuboCop::ConfigStore.new
