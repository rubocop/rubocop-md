TestProf provides a built-in shared context for RSpec to profile examples individually:

```ruby
it "is doing heavy stuff", :rprof do
  ...
end
```

### Configuration

The most useful configuration option is `printer` – it allows you to specify a RubyProf [printer](https://github.com/ruby-prof/ruby-prof#printers).

You can specify a printer through environment variable `TEST_RUBY_PROF`:

```sh
TEST_RUBY_PROF=call_stack bundle exec rake test
```

Or in your code:

```ruby
TestProf::RubyProf.configure do |config|
  config.printer = :call_stack
end
```