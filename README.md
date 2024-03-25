# alda-rb

[![Gem Version](https://badge.fury.io/rb/alda-rb.svg)](https://badge.fury.io/rb/alda-rb)

A Ruby library for live-coding music with [Alda](https://alda.io/).
Also provides an alda DSL in Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alda-rb'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install alda-rb

## Usage

[Install Alda](https://alda.io/install),
and try the following Ruby codes yourself:

```ruby
require 'alda-rb'

puts Alda.version

score = Alda::Score.new { o4; c4/e/g; -d8; r8_16; +f4; o5; c2 }

Alda::Score.new do
  piano_
  quant 200
  v1
  5.times do |t|
    transpose t
    import score
    note midi_note(30 + t * t), duration(note_length 1)
  end
  v2; o6
  motif = -> { c200ms; d500ms }
  8.times { motif * 2; e400ms_4; t4 { a; b; c } }
  _ended
  
  violin_
  __ended
  ->i do
    c2; d4; e2_4; e2; d4; c2_4; c2; e4; d2
    i == 0 ? (c4; d1_2) : (d4; c1_2)
  end * 2

end.play
```

There is also an interactive mode.
You can run it by running `alda-irb` in your command line if you installed the gem.
Run `bundle exec alda-irb` instead if you installed it using the bundler.

```plain
$ alda-irb
> p processes.last
{:id=>"dus", :port=>34317, :state=>nil, :expiry=>nil, :type=>:repl_server}
> piano_; c d e f
piano: [c d e f]
> 5.times do
.   c
>   end
c c c c c
> score_text
piano: [c d e f]
c c c c c
> play
Playing...
> save 'temp.alda'
> puts `cat temp.alda`
piano: [c d e f]
c c c c c
> system 'rm temp.alda'
> exit
```

You can also use it to programmatically communicate with the nREPL server:

```ruby
repl = Alda::REPL.new
repl.message :eval_and_play, code: 'piano: c d e f' # => nil
repl.message :eval_and_play, code: 'g a b > c' # => nil
repl.message :score_text # => "piano: [c d e f]\ng a b > c\n"
repl.message :eval_and_play, code: 'this will cause an error' # (raises Alda::NREPLServerError)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake test` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`,
which will create a git tag for the version,
push git commits and tags,
and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UlyssesZh/alda-rb.
This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to the
[code of conduct](https://github.com/UlyssesZh/alda-rb/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the alda-rb project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/UlyssesZh/alda-rb/blob/master/CODE_OF_CONDUCT.md).
