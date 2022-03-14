# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rubocop"
require "rubocop-md"

RuboCop::Markdown.config_store = RuboCop::ConfigStore.new

module SquigglyHeredoc
  refine String do
    def squiggly
      min = scan(/^[ \t]*(?=\S)/).min
      indent = min ? min.size : 0
      gsub(/^[ \t]{#{indent}}/, "")
    end
  end
end

require "minitest/pride"
require "minitest/autorun"
