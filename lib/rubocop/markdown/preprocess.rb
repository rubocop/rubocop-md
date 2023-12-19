# frozen_string_literal: true

require "ripper"

module RuboCop
  module Markdown
    # Transform markdown into multiple ProcessedSources with offsets
    # from the original markdown for further use in RuboCop
    class Preprocess
      # This is a regexp to parse code blocks from .md files.
      #
      # Only recognizes backticks-style code blocks.
      #
      # Try it: https://rubular.com/r/YMqSWiBuh2TKIJ
      MD_REGEXP = /
        ^([[:blank:]]*`{3,4}) # Match opening backticks
        ([\w[[:blank:]]+]*)?\n # Match the code block syntax
        ([\s\S]+?) # Match everything inside the code block
        (^[[:blank:]]*\1[[:blank:]]*\n?) # Match closing backticks
      /x.freeze

      # See https://github.com/github/linguist/blob/v5.3.3/lib/linguist/languages.yml#L3925
      RUBY_TYPES = %w[
        ruby
        jruby
        macruby
        rake
        rb
        rbx
      ].freeze

      attr_reader :original_processed_source

      def initialize(original_processed_source)
        @original_processed_source = original_processed_source
      end

      # rubocop:disable Metrics/MethodLength
      def call
        original_processed_source.raw_source.to_enum(:scan, MD_REGEXP).map do
          m = Regexp.last_match
          open_backticks = m[1]
          syntax = m[2]
          code = m[3]

          next unless ruby_codeblock?(syntax, code)

          # The codeblock we parsed is assumed ruby
          code_indent = open_backticks.index("`")
          {
            offset: m.begin(3) + code_indent,
            processed_source: new_processed_source(code, code_indent, original_processed_source)
          }
        end.compact
      end
      # rubocop:enable Metrics/MethodLength

      private

      def new_processed_source(code, code_indent, original_processed_source)
        processed_source = RuboCop::ProcessedSource.new(
          strip_indent(code, code_indent),
          original_processed_source.ruby_version,
          original_processed_source.path
        )

        processed_source.config = original_processed_source.config
        processed_source.registry = original_processed_source.registry
        processed_source
      end

      # Strip indentation from code inside codeblocks
      def strip_indent(code, code_indent)
        code.gsub(/^[[:blank:]]{#{code_indent}}/, "")
      end

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
        RUBY_TYPES.include?(syntax)
      end

      def config
        original_processed_source.config
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
    end
  end
end
