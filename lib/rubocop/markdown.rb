require "rubocop/markdown/version"

module Rubocop
  # Plugin to run Rubocop against Markdown files
  module Markdown
    require_relative "./markdown/preprocess"
  end
end
