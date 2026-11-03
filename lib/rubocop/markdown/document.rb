# frozen_string_literal: true

require_relative "parser"

module RuboCop
  module Markdown
    # Original Markdown, its parsed blocks, and coordinates in the Ruby source buffer.
    class Document
      # A deliberate prose edit mapped into the shared Ruby correction buffer.
      class ProseRange < ::Parser::Source::Range; end

      attr_reader :buffer, :code_prefixes
      attr_accessor :processed_buffer

      def initialize(source, path)
        @buffer = ::Parser::Source::Buffer.new(path, source: source)
        @code_prefixes = {}
      end

      def code_blocks
        return enum_for(__method__) unless block_given?

        walk(root) { |node| yield node if node.type == :codeblock }
      end

      def code_lines(block)
        first = block.options.fetch(:code_start_line)
        block.options.fetch(:code_lines).each_with_index.to_h do |text, index|
          number = first + index
          original = line(number)
          unless original.end_with?(text)
            raise "Cannot map Markdown code block source on line #{number}"
          end

          code_prefixes[number] = original.delete_suffix(text)
          [number, text]
        end
      end

      def corrected_source(corrector)
        rewriter = ::Parser::Source::TreeRewriter.new(buffer)
        corrector.as_replacements.each do |range, replacement|
          text = replacement.dup
          Preprocess.restore!(text)
          prefix = code_prefixes[range.first_line]
          text = text.gsub("\n", "\n#{prefix}") if prefix
          rewriter.replace(original_range(range), text)
        end
        rewriter.process
      end

      def line(number)
        buffer.source_line(number)
      end

      def original_range(processed)
        return processed if processed.source_buffer.equal?(buffer)

        range(
          processed.first_line, [processed.column - line_offset(processed.first_line), 0].max,
          processed.last_line, [processed.last_column - line_offset(processed.last_line), 0].max
        )
      end

      def processed_range(original)
        return original if original.source_buffer.equal?(processed_buffer)

        ProseRange.new(
          processed_buffer,
          processed_position(original.first_line, original.column),
          processed_position(original.last_line, original.last_column)
        )
      end

      def range(first_line, first_column, last_line, last_column)
        ::Parser::Source::Range.new(
          buffer,
          buffer.line_range(first_line).begin_pos + first_column,
          buffer.line_range(last_line).begin_pos + last_column
        )
      end

      private

      def root
        @root ||= begin
          root, warnings = Markdown::Parser.parse(buffer.source, hard_wrap: false)
          warnings.each { |warning| warn "rubocop-md: #{warning}" }
          root
        end
      end

      def walk(node, &block)
        yield node
        node.children.each { |child| walk(child, &block) }
      end

      def line_offset(number)
        processed_buffer.source_line(number).length - line(number).length
      end

      def processed_position(number, column)
        processed_buffer.line_range(number).begin_pos + line_offset(number) + column
      end
    end
  end
end
