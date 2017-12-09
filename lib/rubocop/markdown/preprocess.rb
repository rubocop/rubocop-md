require "ripper"

module Rubocop
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
              next walker.next! if valid_syntax?(part)
            end

            next walker.next! if walker.code_attr?

            comment_lines! part

            walker.next!
          end

          parts.join
        end
        # rubocop:enable Metrics/MethodLength

        private

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
