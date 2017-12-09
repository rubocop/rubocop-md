require "test_helper"

class Rubocop::MdTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rubocop::Md::VERSION
  end

  def test_it_does_something_useful
    assert false
  end
end
