TestProf provides a built-in shared context for RSpec to profile examples individually:

```
it "is doing heavy stuff", :rprof do
  ...
end
```

### Configuration

The most useful configuration option is `printer` – it allows you to specify a RubyProf [printer](https://github.com/ruby-prof/ruby-prof#printers).


Or in your code:

```
TestProf:: RubyProf. configure { |config|
  config.printer=:call_stack
}
```