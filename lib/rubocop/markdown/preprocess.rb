# frozen_string_literal: true

require "ripper"

module RuboCop
  module Markdown
    # Transform source Markdown file into valid Ruby file
    # by commenting out all non-code lines
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
        |(^.*$) # If we are not in a codeblock, match the whole line
      /x.freeze

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
        # Revert preprocess changes.
        #
        # When autocorrect is applied, RuboCop re-writes the file
        # using preproccessed source buffer.
        #
        # We have to restore it.
        def restore_and_save!(file)
          contents = File.read(file)
          restore!(contents)
          File.write(file, contents)
        end

        def restore!(src)
          src.gsub!(/^#\s*#{MARKER}/m, "")
        end
      end

      attr_reader :config

      def initialize(file)
        @config = Markdown.config_store.for(file)
      end

      def call(src)
        src.gsub(MD_REGEXP) do |full_match|
          open_backticks, syntax, code, close_backticks, markdown = Regexp.last_match.captures

          if markdown
            # We got markdown outside of a codeblock
            mark_lines(markdown)
          elsif ruby_codeblock?(syntax, code)
            # The codeblock we parsed is assumed ruby, keep as is and append markers to backticks
            "#{mark_lines(open_backticks + syntax)}\n#{code}#{mark_lines(close_backticks)}"
          else
            # The codeblock is not relevant, comment it out
            mark_lines(full_match)
          end
        end
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

      def mark_lines(src)
        src.gsub(/^/, "##{MARKER}")
      end
    end
  end
end
