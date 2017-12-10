require "ripper"

module RuboCop
  module Markdown
    # Transform source Markdown file into valid Ruby file
    # by commenting out all non-code lines
    module Preprocess
      # This is a regexp to extract code blocks from .md files.
      #
      # Only recognizes backticks-style code blocks.
      #
      # Try it: http://rubular.com/r/iJaKBkSrrT
      MD_REGEXP = /^([ \t]*`{3,4})([\w[[:blank:]]]*\n)([\s\S]+?)(^[ \t]*\1[[:blank:]]*\n)/m

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
        # rubocop:disable Metrics/MethodLength
        def call(src)
          parts = src.split(MD_REGEXP)

          walker = Walker.new

          parts.each do |part|
            if walker.code_body?
              next walker.next! if maybe_ruby?(@syntax) && valid_syntax?(part)
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
          syntax.empty? || RUBY_TYPES.include?(syntax)
        end

        # Try to parse with Ripper.
        # Invalid Ruby (non-Ruby) code returns `nil`.
        def valid_syntax?(src)
          !Ripper.sexp(src).nil?
        end

        def comment_lines!(src)
          return if src =~ /\A\n\z/
          src.gsub!(/^(.)/m, '#\1')
        end
      end
    end
  end
end
