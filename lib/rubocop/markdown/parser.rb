# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module RuboCop
  module Markdown
    # Retains code-block source coordinates before Kramdown normalizes their content.
    class Parser < Kramdown::Parser::GFM
      # Accept metadata after the language without replacing Kramdown's block parser.
      FENCED_CODEBLOCK_MATCH = /
        ^[ ]{0,3}(([~`])\2{2,})[ \t]*((\S+)[^\n]*?)?[ \t]*\n
        (.*?)^[ ]{0,3}\1\2*[ \t]*\n
      /mx.freeze

      protected

      def parse_codeblock_fenced
        first = @src.pos
        result = super
        return result unless result

        block = @tree.children.last
        indent = @src.string.byteslice(first..)[/\A */].length
        block.options[:code_start_line] = block.options[:location] + 1
        block.options[:code_lines] = block.value.lines(chomp: true).map do |line|
          line.sub(/\A {0,#{indent}}/, "")
        end
        result
      end

      def parse_codeblock
        first = @src.pos
        result = super
        block = @tree.children.last
        raw = @src.string.byteslice(first, @src.pos - first)
        block.options[:code_start_line] = block.options[:location]
        block.options[:code_lines] = raw.lines(chomp: true).map do |line|
          line.sub(Kramdown::Parser::Kramdown::INDENT, "")
        end
        result
      end
    end
  end
end
