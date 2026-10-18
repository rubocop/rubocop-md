# frozen_string_literal: true

require "ripper"

module RuboCop
  module Markdown
    # Transform source Markdown file into valid Ruby file
    # by commenting out all non-code lines
    class Preprocess
      MARKER = "<--rubocop/md-->"

      # See https://github.com/github/linguist/blob/v5.3.3/lib/linguist/languages.yml#L3925
      RUBY_TYPES = %w[
        ruby
        jruby
        macruby
        rake
        rb
        rbx
      ].freeze

      class << self
        # Remove preprocessing markers from correction text.
        def restore!(src)
          src.gsub!(/^#\s*#{MARKER}/m, "")
        end
      end

      attr_reader :config

      def initialize(file)
        @file = file
        @config = Markdown.config_store.for(file)
      end

      def call(src, document: Document.new(src, @file))
        code = {}
        document.code_blocks.each do |block|
          syntax = block.options[:lang].to_s
          lines = block.options.fetch(:code_lines)
          next unless ruby_codeblock?(syntax, "#{lines.join("\n")}\n")

          code.merge!(document.code_lines(block))
        end
        src.lines.each_with_index.map do |line, index|
          code.key?(index + 1) ? code.fetch(index + 1) + line[/\r?\n\z/].to_s : comment_lines(line)
        end.join
      end

      private

      def ruby_codeblock?(syntax, src)
        maybe_ruby?(syntax) && valid_syntax?(syntax, src)
      end

      # Check codeblock attribute to prevent from parsing
      # non-Ruby snippets and avoid false positives
      def maybe_ruby?(syntax)
        (autodetect? && syntax.empty?) || ruby?(syntax)
      end

      # Check codeblack attribute if it's defined and of Ruby type
      def ruby?(syntax)
        RUBY_TYPES.include?(syntax.split.first)
      end

      # Try to parse with Ripper
      # Invalid Ruby code (or non-Ruby) returns `nil`.
      # Return true if it's explicit Ruby and warn_invalid?
      def valid_syntax?(syntax, src)
        return true if ruby?(syntax) && warn_invalid?

        !Ripper.sexp(src).nil?
      end

      # Whether to show warning when snippet is not a valid Ruby
      def warn_invalid?
        config["Markdown"]&.fetch("WarnInvalid", true)
      end

      # Whether to try to detect Ruby by parsing codeblock.
      # If it's set to false we lint only implicitly specified Ruby blocks.
      def autodetect?
        config["Markdown"]&.fetch("Autodetect", true)
      end

      def comment_lines(src)
        src.gsub(/^/, "##{MARKER}")
      end
    end
  end
end
