# CHANGELOG

## v0.3.0 (not released)

### Changes for \Alda 2

Added API for support \Alda 2 while still being able to support \Alda 1:

- Added Alda::COMMANDS_FOR_VERSIONS and Alda::GENERATIONS.
- Added Alda::generation, which can be `:v1` or `:v2`.
Specifically, one of the values in the array Alda::GENERATIONS.
- Added Alda::v1? and Alda::v2? (See Alda::GENERATIONS).
- Added Alda::deduce_generation.
- Added Alda::GenerationError.
- In Alda::Chord#to_alda_code, considering an undocumented breaking change about chords,
the behavior is slightly different for \Alda 1 and \Alda 2.
- Added Thread#inside_alda_list.

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
- Alda::Array#to_alda_code, Alda::Hash#to_alda_code.

Examples that are modified to work in \Alda 2:

- clapping_music,
- dot_accessor,
- marriage_d_amour.

### New things

New features:

- Added warnings about structures that probably trigger errors in \Alda.
See Alda::EventContainer#check_in_chord, Alda::EventList#method_missing.

New APIs:

- Added Alda::Utils::warn.
- Added Alda::Event#is_event_of?. It is overridden in Alda::EventContainer#is_event_of?.
- Added Alda::Event#== and Alda::EventList#==. It is overridden in many subclasses.
- Added Alda::EventContainer#check_in_chord.

Slightly improved docs:

- Alda::EventContainer#event.
- The overriding +to_alda_code+'s and +on_contained+'s.
- Alda::Sequence, Alda::Sequence::RefineFlatten#flatten.
- The patches to Ruby's core classes.
- Alda::repl.
- Kernel.
- Alda::EventList::new.
- Alda::OrderError::new.

Much better docs:

- Alda::EventContainer#/.
- Alda::EventList#on_contained.
- Alda::REPL::TempScore.

New examples:

- dynamics.

### Fixed bugs

- Fixed: sometimes Alda::Event#parent returns wrong result
because it is not updated in some cases.
- Fixed (potentially BREAKING): Hash#to_alda_code returns `[[k1 v1] [k2 v2]]`.
Now, it returns `{k1 v1 k2 v2}`.

### Others

- Added CHANGELOG.md.
- Modified the homepage and changelog URI in gemspec.

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
- Fixed the bug that dot accessor of `Alda::Part` does not return the container (or the part itself).
- Added Alda::LispIdentifier.
- Fixed Alda::EventList#import now returns `nil`.
- Added some unit tests.
- Fixed the bug that creating an Alda::GetVariable occasionally crashes.
- Fixed bug that inline lisp is mistakenly interpreted as set-variable.

## v0.1.4 (2020-04-23)

- The Ruby requirements become `">= 2.7"`, so update your Ruby.
- Added a colorful REPL! Run `Alda::repl` and see.
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
