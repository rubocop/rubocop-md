require "test_helper"

using SquigglyHeredoc

class RuboCop::Markdown::PreprocessTest < Minitest::Test
  def described_module
    RuboCop::Markdown::Preprocess
  end

  def test_no_code_snippets
    source = <<-SOURCE.squiggly
      # Header

      Boby text
    SOURCE

    expected = <<-SOURCE.squiggly
      ## Header
      #
      #Boby text
    SOURCE

    assert_equal expected, described_module.call(source)
  end

  def test_with_one_snippet
    source = <<-SOURCE.squiggly
      # Header

      Code example:

      ```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      ```
    SOURCE

    expected = <<-SOURCE.squiggly
      ## Header
      #
      #Code example:
      #
      #```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      #```
    SOURCE

    assert_equal expected, described_module.call(source)
  end

  def test_only_snippet
    source = <<-SOURCE.squiggly
      ```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      ```
    SOURCE

    expected = <<-SOURCE.squiggly
      #```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      #```
    SOURCE

    assert_equal expected, described_module.call(source)
  end

  def test_many_snippets
    source = <<-SOURCE.squiggly
      # Header

      Code example:

      ```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      ```

      More texts and lists:
      - One
      - Two

      ```ruby
      require "minitest/pride"
      require "minitest/autorun"

      ```
    SOURCE

    expected = <<-SOURCE.squiggly
      ## Header
      #
      #Code example:
      #
      #```
      class Test < Minitest::Test
        def test_valid
          assert false
        end
      end
      #```
      #
      #More texts and lists:
      #- One
      #- Two
      #
      #```ruby
      require "minitest/pride"
      require "minitest/autorun"

      #```
    SOURCE

    assert_equal expected, described_module.call(source)
  end

  def test_invalid_syntax
    source = <<-SOURCE.squiggly
      # Header

      Code example:

      ```
      class Test < Minitest::Test
        def test_valid
          ...
        end
      end
      ```
    SOURCE

    expected = <<-SOURCE.squiggly
      ## Header
      #
      #Code example:
      #
      #```
      #class Test < Minitest::Test
      #  def test_valid
      #    ...
      #  end
      #end
      #```
    SOURCE

    assert_equal expected, described_module.call(source)
  end

  def test_non_ruby_snippet
    source = <<-SOURCE.squiggly
      # Header

      Code example:

      ```
      -module(evlms).
      -export([martians/0, martians/1]).
      ```
    SOURCE

    expected = <<-SOURCE.squiggly
      ## Header
      #
      #Code example:
      #
      #```
      #-module(evlms).
      #-export([martians/0, martians/1]).
      #```
    SOURCE

    assert_equal expected, described_module.call(source)
  end

  def test_ambigious_non_ruby_snippet
    source = <<-SOURCE.squiggly
      # Header

      ```ruby
      it "is doing heavy stuff", :rprof do
        ...
      end
      ```

      Code example:

      ```sh
      TEST_RUBY_PROF=call_stack bundle exec rake test
      ```

      Or in your code:

      ```ruby
      TestProf::RubyProf.configure do |config|
        config.printer = :call_stack
      end
      ```
    SOURCE

    expected = <<-SOURCE.squiggly
      ## Header
      #
      #```ruby
      #it "is doing heavy stuff", :rprof do
      #  ...
      #end
      #```
      #
      #Code example:
      #
      #```sh
      #TEST_RUBY_PROF=call_stack bundle exec rake test
      #```
      #
      #Or in your code:
      #
      #```ruby
      TestProf::RubyProf.configure do |config|
        config.printer = :call_stack
      end
      #```
    SOURCE

    assert_equal expected, described_module.call(source)
  end
end
