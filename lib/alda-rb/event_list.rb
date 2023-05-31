require 'set'

##
# Including this module can make your class have the ability
# to have an event list.
# See docs below to get an overview of its functions.
module Alda::EventList
	
	##
	# The array containing the events (Alda::Event objects),
	# most of which are Alda::EventContainer objects.
	attr_accessor :events
	
	##
	# The set containing the available variable names.
	attr_accessor :variables
	
	##
	# When the module is included by a subclass of Alda::Event,
	# this method overrides Alda::Event#on_contained.
	# When invoked, calls the overridden method (if any) and then evaluates the block
	# given when ::new was called.
	def on_contained
		super if defined? super
		instance_eval &@block if @block
	end
	
	##
	# :call-seq:
	#   (some sugar) -> Alda::EventContainer
	#
	# Make the object have the ability to append its #events conveniently.
	#
	# Here is a list of sugar. When the name of a method meets certain
	# condition, the method is regarded as an event appended to #events.
	#
	# 1. Ending with 2 underlines: set variable. See Alda::SetVariable.
	#
	# 2. Starting with 2 lowercase letters and
	#    ending with underline character: instrument. See Alda::Part.
	#    This will trigger a warning if we are using \Alda 2 because
	#    parts inside a sequence are not allowed in \Alda 2
	#    ({alda-lang/alda#441}[https://github.com/alda-lang/alda/discussions/441#discussioncomment-3825064]).
	#
	# 3. Starting with 2 lowercase letters: inline lisp code,
	#    set variable, or get variable.
	#    One of the above three is chosen intelligently.
	#    See Alda::InlineLisp, Alda::SetVariable, Alda::GetVariable.
	#
	# 4. Starting with "t": CRAM. See Alda::Cram.
	#
	# 5. Starting with one of "a", "b", ..., "g": note. See Alda::Note.
	#
	# 6. Starting with "r": rest. See Alda::Rest.
	#
	# 7. "x": chord. See Alda::Chord.
	#
	# 8. "s": sequence. See Alda::Sequence.
	#
	# 9. Starting with "o": octave. See Alda::Octave.
	#
	# 10. Starting with "v": voice. See Alda::Voice.
	#
	# 11. Starting with "__" (2 underlines): at marker. See Alda::AtMarker.
	#
	# 12. Starting with "_" (underline) and ending with "_" (underline):
	#     lisp identifier. See Alda::LispIdentifier.
	#
	# 13. Starting with "_" (underline): marker. See Alda::Marker.
	#
	# All the appended events are contained in an Alda::EventContainer object,
	# which is to be returned.
	#
	# These sugars forms a DSL. See ::new for examples.
	def method_missing name, *args, &block
		if @parent&.respond_to? name, true
			return @parent.__send__ name, *args, &block
		end
		sequence_sugar = ->event do
			if args.size == 1
				Alda::Sequence.join event, args.first.tap(&:detach_from_parent)
			else
				event
			end
		end
		case
		when /\A(?<head>[a-z][a-z].*)__\z/        =~ name
			Alda::SetVariable.new head, *args, &block
		when /\A(?<part>[a-z][a-z].*)_\z/         =~ name
			if args.first.is_a? String
				Alda::Part.new [part], args.first
			else
				Alda::Utils.warn 'parts in sequence not allowed in v2' if Alda.v2? && !args.empty?
				sequence_sugar.(Alda::Part.new [part])
			end
		when /\A[a-z][a-z].*\z/                   =~ name
			arg = args.first
			if block || !has_variable?(name) && args.size == 1 && arg.is_a?(Alda::Event) &&
					!arg.is_event_of?(Alda::InlineLisp) && !arg.is_event_of?(Alda::LispIdentifier)
				Alda::SetVariable.new name, *args, &block
			elsif has_variable?(name) && (args.empty? || args.size == 1 && arg.is_a?(Alda::Event))
				sequence_sugar.(Alda::GetVariable.new name)
			else
				Alda::InlineLisp.new name, *args
			end
		when /\At(?<duration>.*)\z/               =~ name
			Alda::Cram.new duration, &block
		when /\A(?<pitch>[a-g])(?<duration>.*)\z/ =~ name
			sequence_sugar.(Alda::Note.new pitch, duration)
		when /\Ar(?<duration>.*)\z/               =~ name
			sequence_sugar.(Alda::Rest.new duration)
		when /\Ax\z/                              =~ name
			Alda::Chord.new &block
		when /\As\z/                              =~ name
			Alda::Sequence.new *args, &block
		when /\Ao!\z/                             =~ name
			sequence_sugar.(Alda::Octave.new('').tap { _1.up_or_down = 1})
		when /\Ao\?\z/                            =~ name
			sequence_sugar.(Alda::Octave.new('').tap { _1.up_or_down = -1})
		when /\Ao(?<num>\d*)\z/                   =~ name
			sequence_sugar.(Alda::Octave.new num)
		when /\Av(?<num>\d+)\z/                   =~ name
			sequence_sugar.(Alda::Voice.new num)
		when /\A__(?<head>.+)\z/                  =~ name
			sequence_sugar.(Alda::AtMarker.new head)
		when /\A_(?<head>.+)_\z/                  =~ name
			sequence_sugar.(Alda::LispIdentifier.new head)
		when /\A_(?<head>.+)\z/                   =~ name
			sequence_sugar.(Alda::Marker.new head)
		else
			super
		end.then do |event|
			Alda::EventContainer.new event, self
		end.tap { @events.push _1 }
	end
	
	##
	# :call-seq:
	#   has_variable?(name) -> true or false
	#
	# Whether there is a previously declared alda variable
	# whose name is specified by +name+.
	#
	# Searches variables in #parent.
	def has_variable? name
		@variables.include?(name) || !!@parent&.has_variable?(name)
	end
	
	##
	# :call-seq:
	#   import(event_list) -> nil
	#
	# Append the events of another Alda::EventList object here.
	# This method covers the disadvantage of alda's being unable to
	# import scores from other files
	# ({alda-lang/alda-core#8}[https://github.com/alda-lang/alda-core/issues/8]).
	def import event_list
		@events.concat event_list.events
		nil
	end
	
	##
	# :call-seq:
	#   new(&block) -> Alda::EventList
	#
	# The parameter +block+ is to be passed with the Alda::EventList object as +self+.
	#
	# Note that +block+ is not called immediately.
	# It is instead called in #on_contained.
	# Specially, Alda::Score::new calls #on_contained.
	#
	#   Alda::Score.new do
	#     tempo! 108           # inline lisp
	#     piano_               # piano part
	#     o4                   # octave 4
	#     c8; d; e; f          # notes
	#     g4 g a f g e f d e c # a sequence
	#     d4_8                 # cannot have '~', use '_' instead
	#     o3 b8 o4 c2          # a sequence
	#   end
	#   # => #<Alda::Score:0x... @events=[...]>
	#
	# For a list of sugars, see #method_missing.
	def initialize &block
		@events ||= []
		@variables ||= Set.new
		@block ||= block
	end
	
	##
	# :call-seq:
	#   to_a -> Array
	#
	# Same as #events.
	def to_a
		@events
	end
	
	##
	# :call-seq:
	#   events_alda_codes(delimiter=" ") -> String
	#
	# Join the alda codes of #events with a specified delimiter.
	# Returns a string representing the result.
	def events_alda_codes delimiter = ' '
		@events.map(&:to_alda_code).join delimiter
	end
	
	##
	# :call-seq:
	#   event_list == other -> true or false
	#
	# Returns true if +other+ is of the same class as +event_list+
	# and they have the same (in the sense of <tt>==</tt>) #events and #variables.
	def == other
		super || self.class == other.class && @events == other.events && @variables == other.variables
	end
end

##
# Includes Alda::EventList and provides methods to #play, #parse, or #export.
class Alda::Score
	include Alda::EventList
	
	##
	# :call-seq:
	#   play(**opts) -> String
	#
	# Plays the score.
	#
	# Returns the command line output of the +alda+ command.
	#
	# Run command <tt>alda help</tt> to see available options
	# that can be specified in +opts+.
	#
	#   Alda::Score.new { piano_; c; d; e }.play
	#   # => "[27713] Parsing/evaluating...\n[27713] Playing...\n"
	#   # (and plays the sound)
	#   Alda::Score.new { piano_; c; d; e }.play from: 1
	#   # (plays only an E note)
	def play **opts
		Alda.play code: self, **opts
	end
	
	##
	# :call-seq:
	#   parse(**opts) -> String
	#
	# Parses the score.
	#
	# Returns the JSON string of the parse result.
	#
	# Run command <tt>alda help</tt> to see available options
	# that can be specified in +opts+.
	#
	#   Alda::Score.new { piano_; c }.parse output: :events
	#   # => "[{\"event-type\":...}]\n"
	def parse **opts
		Alda.parse code: self, **opts
	end
	
	##
	# :call-seq:
	#   export(**opts) -> String
	#
	# Exports the score.
	#
	# Returns the command line output of the +alda+ command.
	#
	# Run command <tt>alda help</tt> to see available options
	# that can be specified in +opts+.
	#
	#   Alda::Score.new { piano_; c }.export output: 'temp.mid'
	#   # (outputs a midi file called temp.mid)
	def export **opts
		Alda.export code: self, **opts
	end
	
	##
	# :call-seq:
	#   save(filename) -> nil
	#
	# Saves the alda codes into a file.
	def save filename
		File.open(filename, 'w') { _1.puts to_s }
	end
	
	##
	# :call-seq:
	#   load(filename) -> Alda::Raw
	#
	# Loads alda codes from a file.
	#
	# Actually appends a Alda::Raw event with the contents in the file +filename+.
	def load filename
		event = Alda::Raw.new File.read filename
		@events.push event
		event
	end
	
	##
	# :call-seq:
	#   to_s() -> String
	#
	# Returns a String containing the alda codes representing the score.
	def to_s
		events_alda_codes
	end
	
	##
	# :call-seq:
	#   new(&block) -> Alda::Score
	#
	# Creates an Alda::Score.
	def initialize(...)
		super
		on_contained
	end
	
	##
	# :call-seq:
	#   clear() -> nil
	#
	# Clears all the events and variables.
	def clear
		@events.clear
		@variables.clear
		nil
	end
	
	##
	# :call-seq:
	#   raw(contents) -> Alda::Raw
	#
	# Adds an Alda::Raw event to the event list and returns it.
	# The event is not contained by a container.
	#
	#   Alda::Score.new { raw 'piano: c d e' }.to_s # => "piano: c d e"
	def raw contents
		Alda::Raw.new(contents).tap { @events.push _1 }
	end
	
	##
	# :call-seq:
	#   l(head, *args) -> Alda::EventContainer
	#
	# Adds an Alda::EventContainer containing an Alda::InlineLisp event to the event list.
	# In most cases, #method_misssing is a more convenient way to add an inline Lisp event.
	# However, sometimes you may want to programmatically control which Lisp function to be called,
	# or the function name is already a valid Ruby method name
	# (for example, you want to use +f+ or +p+ as the dynamics but +f+ would be interpreted as a note
	# and +p+ is already a Ruby method for printing)
	# so that it cannot trigger #method_missing,
	# then you should use this method.
	#
	#   Alda::Score.new { piano_; l :p; c }.to_s # => "piano: (p ) c"
	def l head, *args
		Alda::EventContainer.new(Alda::InlineLisp.new(head, *args), self).tap { @events.push _1 }
	end
end
