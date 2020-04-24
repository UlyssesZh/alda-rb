require 'set'

# Including this module can make your class have the ability
# to have an event list.
# See docs below to get an overview of its functions.
module Alda::EventList
	
	# The array containing the events (Event# objects),
	# most of which are EventContainer# objects.
	attr_accessor :events
	
	# The set containing the available variable names.
	attr_accessor :variables
	
	def on_contained
		instance_eval &@block if @block
	end
	
	# Make the object have the ability to appending its +events+
	# conveniently.
	#
	# Here is a list of sugar. When the name of a method meets certain
	# condition, the method is regarded as an event appended to +events+.
	#
	# 1. Ending with 2 underlines: set variable. See SetVariable#.
	#
	# 2. Starting with 2 lowercase letters and
	#    ending with underline character: instrument. See Part#.
	#
	# 3. Starting with 2 lowercase letters: inline lisp code,
	#    set variable, or get variable.
	#    One of the above three is chosen intelligently.
	#    See InlineLisp#, SetVariable#, GetVariable#.
	#
	# 4. Starting with "t": CRAM. See Cram#.
	#
	# 5. Starting with one of "a", "b", ..., "g": note. See Note#.
	#
	# 6. Starting with "r": rest. See Rest#.
	#
	# 7. "x": chord. See Chord#.
	#
	# 8. "s": sequence. See Sequence#.
	#
	# 9. Starting with "o": octave. See Octave#.
	#
	# 10. Starting with "v": voice. See Voice#.
	#
	# 11. Starting with "__" (2 underlines): at marker. See AtMarker#.
	#
	# 12. Starting with "_" (underline): marker. See Marker#.
	#
	# Notes cannot have dots.
	# To tie multiple durations, +_+ is used instead of +~+.
	#
	# All the appended events are contained in an EventContainer# object,
	# which is to be returned.
	#
	# These sugars forms a DSL.
	# @see #initialize.
	# @return an EventContainer# object.
	def method_missing name, *args, &block
		if @parent&.respond_to? name, true
			return @parent.__send__ name, *args, &block
		end
		sequence_sugar = ->event do
			if args.size == 1
				joined = args.first
				unless (got = @events.pop) == (expected = joined)
					raise Alda::OrderError.new expected, got
				end
				Alda::Sequence.join event, joined
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
				sequence_sugar.(Alda::Part.new [part])
			end
		when /\A[a-z][a-z].*\z/                   =~ name
			if block
				Alda::SetVariable.new name, *args, &block
			elsif has_variable?(name) && (args.empty? || args.size == 1 && args.first.is_a?(Event))
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
		when /\A_(?<head>.+)\z/                   =~ name
			sequence_sugar.(Alda::Marker.new head)
		else
			super
		end.then do |event|
			Alda::EventContainer.new event, self
		end.tap &@events.method(:push)
	end
	
	def has_variable? name
		@variables.include?(name) || !!@parent&.has_variable?(name)
	end
	
	# Append the events of another EventList# object here.
	# This method covers the disadvantage of alda's being unable to
	# import scores from other files.
	# See https://github.com/alda-lang/alda-core/issues/8.
	def import event_list
		@events.concat event_list.events
	end
	
	# @param block to be passed with the EventList# object as +self+.
	# @example
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
	def initialize &block
		@events ||= []
		@variables ||= Set.new
		@block ||= block
	end
	
	# Same as #events
	def to_a
		@events
	end
	
	# Join the alda codes of #events with a specified delimiter.
	# Returns a string representing the result.
	def events_alda_codes delimiter = ' '
		@events.map(&:to_alda_code).join delimiter
	end
end

# The class mixes in EventList# and provides methods to play or parse.
class Alda::Score
	include Alda::EventList
	
	# Plays the score.
	# @return The command line output of the +alda+ command.
	# @example
	#   Alda::Score.new { piano_; c; d; e }.play
	#   # => "[27713] Parsing/evaluating...\n[27713] Playing...\n"
	#   # (and plays the sound)
	#   Alda::Score.new { piano_; c; d; e }.play from: 1
	#   # (plays only an E note)
	def play **opts
		Alda.play code: self, **opts
	end
	
	# Parses the score.
	# @return The JSON string of the parse result.
	# @example
	#   Alda::Score.new { piano_; c }.parse output: :events
	#   # => "[{\"event-type\":...}]\n"
	def parse **opts
		Alda.parse code: self, **opts
	end
	
	# Exports the score.
	# @return The command line output of the +alda+ command.
	# @example
	#   Alda::Score.new { piano_; c }.export output: 'temp.mid'
	#   # (outputs a midi file called temp.mid)
	def export **opts
		Alda.export code: self, **opts
	end
	
	# Saves the alda codes into a file.
	def save filename
		File.open(filename, 'w') { _1.puts to_s }
	end
	
	# Loads alda codes from a file.
	def load filename
		event = Alda::InlineLisp.new :alda_code, File.read(filename)
		@events.push event
		event
	end
	
	# @return Alda codes.
	def to_s
		events_alda_codes
	end
	
	# The initialization.
	def initialize(...)
		super
		on_contained
	end
	
	# Clears all the events and variables.
	def clear
		@events.clear
		@variables.clear
		self
	end
end
