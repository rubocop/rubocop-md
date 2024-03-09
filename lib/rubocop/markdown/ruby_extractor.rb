# frozen_string_literal: true

module RuboCop
  module Markdown
    # Used by RuboCop to get parsed ruby from markdown
    class RubyExtractor
      # According to Linguist. mdx was dropped but is being kept for backwards compatibility.
      # See https://github.com/github-linguist/linguist/blob/8c380f360ce00b95fa08d14ce0ebccd481af1b33/lib/linguist/languages.yml#L4088-L4098
      # Keep in sync with config/default.yml
      MARKDOWN_EXTENSIONS = %w[
        .md
        .livemd
        .markdown
        .mdown
        .mdwn
        .mdx
        .mkd
        .mkdn
        .mkdown
        .ronn
        .scd
        .workbook
      ].freeze

      class << self
        def call(processed_source)
          new(processed_source).call
        end
      end

      def initialize(processed_source)
        @processed_source = processed_source
      end

      def call
        return unless markdown_file?

        Preprocess.new(@processed_source).call
      end

      private

      def markdown_file?
        MARKDOWN_EXTENSIONS.include?(File.extname(@processed_source.path || ""))
      end
    end
  end
end
