$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "rubocop-md"

require "pry-byebug" rescue LoadError # rubocop:disable all

module SquigglyHeredoc
  refine String do
    def squiggly
      min = scan(/^[ \t]*(?=\S)/).min
      indent = min ? min.size : 0
      gsub(/^[ \t]{#{indent}}/, "")
    end
  end
end

require "minitest/pride"
require "minitest/autorun"
