# frozen_string_literal: true

require "ripper"

module RuboCop
  module Markdown
    # Transform source Markdown file into valid Ruby file
    # by commenting out all non-code lines
    class Preprocess
      # This is a regexp to extract code blocks from .md files.
      #
      # Only recognizes backticks-style code blocks.
      #
      # Try it: https://rubular.com/r/YMqSWiBuh2TKIJ
      MD_REGEXP = /^([ \t]*`{3,4})([\w[[:blank:]]+]*\n)([\s\S]+?)(^[ \t]*\1[[:blank:]]*\n?)/m.freeze

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

      class Walker # :nodoc:
        STEPS = %i[text code_start code_attr code_body code_end].freeze

        STEPS.each do |step|
          define_method("#{step}?") do
            STEPS[current_step] == step
          end
        end

        attr_accessor :current_step

        def initialize
          @current_step = 0
        end

        def next!
          self.current_step = current_step == (STEPS.size - 1) ? 0 : current_step + 1
        end
      end

      class << self
        # Revert preprocess changes.
        #
        # When autocorrect is applied, RuboCop re-writes the file
        # using preproccessed source buffer.
        #
        # We have to restore it.
        def restore!(file)
          contents = File.read(file)
          contents.gsub!(/^##{MARKER}/m, "")
          File.write(file, contents)
        end
      end

      attr_reader :config

      def initialize(file)
        @config = Markdown.config_store.for(file)
      end

      # rubocop:disable Metrics/MethodLength
      def call(src)
        parts = src.split(MD_REGEXP)

        walker = Walker.new

        parts.each do |part|
          if walker.code_body? && maybe_ruby?(@syntax) && valid_syntax?(@syntax, part)
            next walker.next!
          end

          if walker.code_attr?
            @syntax = part.gsub(/(^\s+|\s+$)/, "")
            next walker.next!
          end

          comment_lines! part

          walker.next!
        end

        parts.join
      end
      # rubocop:enable Metrics/MethodLength

      private

      # Check codeblock attribute to prevent from parsing
      # non-Ruby snippets and avoid false positives
      def maybe_ruby?(syntax)
        (autodetect? && syntax.empty?) || ruby?(syntax)
      end

      # Check codeblack attribute if it's defined and of Ruby type
      def ruby?(syntax)
        RUBY_TYPES.include?(syntax)
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

      def comment_lines!(src)
        return if src =~ /\A\n\z/

        src.gsub!(/^(.)/m, "##{MARKER}\\1")
      end
    end
  end
end
