# CHANGELOG

## v0.3.1 (2023-06-03)

New features and new API:

- Added Alda::NREPLServerError#status.
- Added Alda::env.
- Alda::down? and Alda::up? is now useful in \Alda 2.
- Added Alda::REPL#reline.

BREAKING changes of API:

- Now `status` should be specified as a parameter of Alda::NREPLServerError::new.

Fixed bugs:

- Fixed: `alda-irb` does not run correctly in Ruby 3.
- Fixed: cannot handle unknown-op error of nREPL server.
- Fixed: an excess message printed when exiting \REPL on Windows.

Other changes:

- Fixed dependencies.
- Fixed some changelog of 0.3.0.
- Added a gem badge in README.
- Updated bundler version.

## v0.3.0 (2023-05-29)

### Changes for \Alda 2

Added API for support \Alda 2 while still being able to support \Alda 1:

- Added Alda::COMMANDS_FOR_VERSIONS and Alda::GENERATIONS.
- Added Alda::generation, which can be `:v1` or `:v2`.
  Specifically, one of the values in the array Alda::GENERATIONS.
- Added Alda::v1?, Alda::v2?, Alda::v1!, Alda::v2! (See Alda::GENERATIONS).
- Added Alda::deduce_generation.
- Added Alda::GenerationError.
- In Alda::Chord#to_alda_code, considering an undocumented breaking change about chords,
  the behavior is slightly different for \Alda 1 and \Alda 2.
- Added Thread#inside_alda_list.
- Added Alda::REPL#message and Alda::REPL#raw_message.

APIs that are modified to support \Alda 2:

- (BREAKING CHANGE!) Changed Alda::COMMANDS from an array of symbols into a hash.
  The keys are the names of the commands,
  and the values are arrays of generations where the command is available.
- Because \Alda 2 does not have the notion of down and up, if we are in v2,
  Alda::down? will always return false and Alda::up? will always return true.
- Array#to_alda_code and Hash#to_alda_code behaves differently for \Alda 1 and \Alda 2 regarding
  [a breaking change](https://github.com/alda-lang/alda/blob/master/doc/alda-2-migration-guide.md#attribute-syntax-has-changed-in-some-cases).

Documents that modified for notice about \Alda 2:

- Alda::[], Alda::up?, Alda::down?, Alda::COMMANDS.
- Alda::EventList#method_missing.
- Alda::InlineLisp.
- Array#to_alda_code, Hash#to_alda_code.
- Alda::REPL.
- Alda::CommandLineError#port.

Examples that are modified to work in \Alda 2:

- clapping_music,
- dot_accessor,
- marriage_d_amour.

### New things

New features:

- Added warnings about structures that probably trigger errors in \Alda.
  See Alda::EventContainer#check_in_chord, Alda::EventList#method_missing.
- Now you can specify a parameter in Alda::Event#detach_from_parent to exclude some
  classes of parents that will be detached from.
- (Potentially BREAKING) Alda::Event#detach_from_parent now tries to detach the topmost container
  instead of the event itself from the parent.
- Added a commandline program called `alda-irb`. See Alda::REPL.
- Traceback of exception will also be printed now if an Interrupt is caught in \REPL.
- <kbd>Ctrl</kbd>+<kbd>C</kbd> can now be used to discard the current input in \REPL.
- Now, Alda::REPL takes better care of indents.
- Added no-color mode and no-preview mode for \REPL.
- Now Alda::REPL::TempScore#score and Alda::REPL::TempScore#map output in blue color.

New APIs:

- Added Alda::Raw.
- Added Alda::Utils::warn, Alda::Utils::win_platform?,
  Alda::Utils::snake_to_slug, Alda::Utils::slug_to_snake.
- Added Alda::Event#is_event_of?. It is overridden in Alda::EventContainer#is_event_of?.
- Added Alda::Event#== and Alda::EventList#==. It is overridden in many subclasses.
- Added Alda::EventContainer#check_in_chord.
- Added Alda::EventList#l.
- Added Alda::EventList#raw.
- Added Alda::REPL#color, Alda::REPL#preview.
- Added Alda::REPL#setup_repl, Alda::REPL#readline.
- Added Alda::REPL::TempScore#new_score, Alda::REPL::TempScore#score_text,
  Alda::REPL::TempScore#score_data, Alda::REPL::TempScore#score_events.
- Added Alda::pipe.
- Added Alda::processes.
- Added Alda::NREPLServerError.
- Added Alda::GenerationError::assert_generation.

Slightly improved docs:

- Alda::EventContainer#event.
- The overriding `to_alda_code`'s and `on_contained`'s.
- Alda::Sequence, Alda::Sequence::RefineFlatten#flatten.
- The patches to Ruby's core classes.
- Kernel.
- Alda::EventList::new.
- Alda::OrderError::new.
- Alda::InlineLisp.
- Alda::OrderError#expected.

Much better docs:

- Alda::EventContainer#/.
- Alda::EventList#on_contained.
- Alda::REPL::TempScore.

New examples:

- dynamics,
- track-volume,
- variables-2.

### BREAKING changes

Removed APIs:

- Removed Alda::SetVariable#original_events.
- Removed Alda::repl. Now calling `Alda.repl` will trigger commandline `alda repl`.
  For the old REPL function, use `Alda::REPL.new.run` instead.
- Removed Alda::REPL::TempScore#history.

Modified APIs or features:

- Now Alda::REPL#play_score does not call Alda::REPL#try_command.
- Alda::Score#load now use Alda::Raw instead of an Alda::InlineLisp to load a file.

### Fixed bugs

- Fixed: sometimes Alda::Event#parent returns wrong result
  because it is not updated in some cases.
- Fixed (potentially BREAKING): Hash#to_alda_code returns `[[k1 v1] [k2 v2]]`.
  Now, it returns `{k1 v1 k2 v2}`.
- Use reline instead of readline in Alda::REPL
  because Ruby 3.3 is dropping the shipment of readline-ext.

### Others

- Added changelog.
- Modified the homepage and changelog URI in gemspec.
- Fixed the email in code of conduct.

## v0.2.1 (2020-08-13)

- Fixed the bug in `examples/bwv846_prelude.rb`.
  The file isn't changed when the version change
  from [v0.1.4](#v014-2020-04-23) to [v0.2.0](#v020-2020-05-08)
  but the new features in 0.2.0 made some codes in that file stop working.

## v0.2.0 (2020-05-08)

- Separated `alda-rb.rb` into several files.
- REPL now supports `map`, `score`, and `new`.
- Added a lot of docs. Can be seen [here](https://ulysseszh.github.io/doc/alda-rb).
- Added Alda::Event#detach_from_parent.
- Fixed the bug that dot accessor of Alda::Part does not return the container (or the part itself).
- Added Alda::LispIdentifier.
- Fixed Alda::EventList#import now returns `nil`.
- Added some unit tests.
- Fixed the bug that creating an Alda::GetVariable occasionally crashes.
- Fixed bug that inline lisp is mistakenly interpreted as set-variable.

## v0.1.4 (2020-04-23)

- The Ruby requirements become `">= 2.7"`, so update your Ruby.
- Added a colorful REPL! Run Alda::repl and see.
```
$ ruby -ralda-rb -e "Alda.repl"
> puts status
[27713] Server up (2/2 workers available, backend port: 33245)
> piano_ c d e f
[piano: c d e f]
> 5.times do
> c
> end
c c c c c
> puts history
[piano: c d e f]
c c c c c
> play
> save 'temp.alda'
> puts `cat temp.alda`
[piano: c d e f]
c c c c c
> system 'rm temp.alda'
> exit
```
- More than 2 events written together will become an Alda::Sequence object
  (contained by an Alda::EventContainer).
  Events that can use such sugar includes:
  part (supports dot accessor), note, rest, octave, voice, marker, at-marker.
```ruby
Alda::Score.new { p((c d e).event.class) } # => Alda::Sequence
```
- Added: `o!` means octave up, `o?` means octave down. This is to be compatible with the sugar above.
- Similarly added: `!` at the end of a note means sharp, and `?` for flat, `_` for natural. It conflicts with slur, so `__` means slur, and `___` means slur and natural.
```ruby
Alda::Score.new { piano_ c o? b? o! c o? b? }.to_s
# => "[piano: c < b- > c < b-]"
```
- Added attr accessor Alda::Event#container.
- Fixed the bug occurring when one uses a dot accessor wrongly.
- Added Alda::Sequence::join to join several events into a flatten sequence.
- Fixed the bug in `examples/alternate_endings.rb`.
- Some of the examples are rewritten using the new sugar feature.
- Assign an alda variable by using a method ending with 2 underlines, or pass a block for it. The following three are equivalent:
```ruby
Alda::Score.new { var__ c d e; piano_ var }
```
```ruby
Alda::Score.new { var { c d e }; piano_ var }
```
```ruby
Alda::Score.new { var__ { c d e }; piano_ var }
```
This one is slightly different but has the same effect:
```ruby
Alda::Score.new { var__ c, d, e; piano_ var }
```
The name of a variable can be same as that of a lisp function if there is no ambiguity.
- The message of Alda::CommandLineError is optimized.
- Added Alda::OrderError, which is used instead of RuntimeError, representing a disorder of events.
```ruby
Alda::Score.new do
  motif = f4 f e e d d c2
  g4 f e d c2
  p @events.size # => 2
  c4 c g g a a g2 motif
rescue OrderError => e
  p @events.size # => 1
  p e.expected   # => #<Alda::EventContainer:...>
  p e.got        # => #<Alda::EventContainer:...>
end
```
- The block passed to an Alda::EventList object is now called in Alda::Event#on_contained, so `@parent`, `@container` etc can be gotten inside.
- Alda::EventList can access methods in `@parent`.
- Canceled Alda::method_missing. Use meta-programming to define methods instead. You can now use `include Alda` to import such commands.
```ruby
include Alda
version # => "Client version: 1.4.1\nServer version: [27713] 1.4.1\n"
```
- Added Kernel#alda. It runs `alda` at command line and does not capture the output.
```ruby
alda 'version'
```
- Use Alda::[] to specify command options (not subcommand options):
```ruby
Alda[quiet: true].play code: 'piano: c d e f' # => ""
```
The options specified will be remembered. Invoke `Alda::clear_options` to forget them.
- Added Alda::CommandLineError#port.
```ruby
begin
  Alda[port: 1108].play code: 'y'
rescue CommandLineError => e
  e.port # => 1108
end
```
- Added Alda::Score#save and Alda::Score#load to save and load \Alda files.
```ruby
Alda::Score.new { c d e }.save 'temp.alda'
File.read 'temp.alda' #  => "[c d e]\n"
```

## v0.1.2 (2020-04-16)

- Added examples
- Fixed bug when writing `key_sig b: [:flat]`
- Added sequence sugar(s) and alternative repetition sugar (`%`) (see examples/alternate_endings.rb)
- Write options naturally for alda command line (`Alda.play code: 'piano: c'`)
- Can pass scores to alda command line (`Alda.play code: Alda::Score.new`)
- Added Alda::Score#parse, Alda::Score#export, and Alda::Score#to_s
- Fixed bug when writing `+o/c`
- Added support for dot accessor (see example/dot_accessor.rb)
- Fixed some mistakes in docs and README

## v0.1.0 (2020-04-15)

The original version.
