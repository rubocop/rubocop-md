require "test_helper"

class Rubocop::MarkdownTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rubocop::Markdown::VERSION
  end
end
