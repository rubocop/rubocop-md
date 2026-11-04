# frozen_string_literal: true

module RuboCop
  module Cop
    module Markdown
      # Reports Markdown parser diagnostics through RuboCop's standard formatters.
      class Syntax < RuboCop::Cop::Base
        def on_new_investigation
          super
          document = processed_source.markdown_document
          return unless document

          warnings_by_line = document.warnings.group_by do |warning|
            warning_line(warning, document)
          end
          warnings_by_line.each do |number, warnings|
            range = document.range(number, 0, number, document.line(number).length)
            add_offense(document.processed_range(range), message: warnings.join("; "))
          end
        end

        def on_other_file
          super
          on_new_investigation
        end

        private

        def warning_line(warning, document)
          number = warning.scan(/\bline (\d+)\b/).last&.first&.to_i
          number&.between?(1, document.buffer.last_line) ? number : 1
        end
      end
    end
  end
end
