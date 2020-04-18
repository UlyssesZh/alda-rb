require 'set'
require 'alda-rb/version'

class Array
	def to_alda_code
		"[#{map(&:to_alda_code).join ' '}]"
	end
end
class Hash
	def to_alda_code
		"{#{to_a.reduce(:+).map(&:to_alda_code).join ' '}}"
	end
end
class String
	def to_alda_code
		inspect
	end
end
class Symbol
	def to_alda_code
		?: + to_s
	end
end
class Numeric
	def to_alda_code
		inspect
	end
end
class Range
	def to_alda_code
		"#{first}-#{last}"
	end
end
class Proc
	# Runs +self+ for +n+ times.
	def * n
		if !lambda? || arity == 1
			n.times &self
		else
			n.times { self.() }
		end
	end
end

# The module serving as a namespace.
module Alda
	
	# The path to the +alda+ executable.
	#
	# The default value is <tt>"alda"</tt>,
	# which will depend on your PATH.
	singleton_class.attr_accessor :executable
	@executable = 'alda'
	
	# The method give Alda# ability to invoke +alda+ at the command line,
	# using +name+ as subcommand and +args+ as arguments.
	# +opts+ are converted to command line options.
	#
	# The return value is the string output by the command in STDOUT.
	#
	# If the exit code is nonzero, a CommandLineError# is raised.
	# @example
	#   Alda.version
	#   # => "Client version: 1.4.0\nServer version: [27713] 1.4.0\n"
	#   Alda.parse code: 'bassoon: o3 c'
	#   # => "{\"chord-mode\":false,\"current-instruments\":...}\n"
	#   Alda.sandwich
	#   # Alda::CommandLineError (Expected a command, got sandwich)
	def self.method_missing name, *args, **opts
		name = name.to_s.gsub ?_, ?-
		opts.each do |key, val|
			args.push "--#{key.to_s.gsub ?_, ?-}", val.to_s
		end
		output = IO.popen [executable, name, *args], &:read
		raise CommandLineError.new $?, output if $?.exitstatus.nonzero?
		output
	end
	
	# @return Whether the alda server is up.
	def self.up?
		status.include? 'up'
	end
	
	# @return Whether the alda server is down.
	def self.down?
		status.include? 'down'
	end
	
	# The error is raised when one tries to
	# run a non-existing subcommand of +alda+.
	class CommandLineError < Exception
		
		# The <tt>Process::Status</tt> object representing the status of
		# the process that runs +alda+ command.
		attr_reader :status
		
		# Create a CommandLineError# object.
		# @param status The status of the process running +alda+ command.
		# @param msg The exception message.
		def initialize status, msg = nil
			super /ERROR\s*(?<message>.*)$/ =~ msg ? message : msg&.lines(chomp: true).first
			@status = status
		end
	end
	
	# This error is raised when one tries to
	# append events in an EventList# in a wrong order.
	# @example
	#   Alda::Score.new do
	#     motif = f4 f e e d d c2
	#     g4 f e d c2 # It commented out, error will not occur
	#     c4 c g g a a g2 motif # OrderError
	#   end
	class OrderError < Exception
		
		# The expected element gotten if it is of the correct order.
		# @see #got
		# @example
		#   Alda::Score.new do
		#     motif = f4 f e e d d c2
		#     g4 f e d c2
		#     p @events.size # => 2
		#     c4 c g g a a g2 motif
		#   rescue OrderError => e
		#     p @events.size # => 1
		#     p e.expected   # => #<Alda::EventContainer:...>
		#     p e.got        # => #<Alda::EventContainer:...>
		#   end
		attr_reader :expected
		
		# The actually gotten element.
		# For an example, see #expected.
		# @see #expected
		attr_reader :got
		
		def initialize expected, got
			super 'events are out of order'
			@expected = expected
			@got = got
		end
	end
	
	# Including this module can make your class have the ability
	# to have an event list.
	# See docs below to get an overview of its functions.
	module EventList
		
		# The array containing the events (Event# objects),
		# most of which are EventContainer# objects.
		attr_accessor :events
		
		# The set containing the available variable names.
		attr_accessor :variables
		
		# The block to be executed.
		attr_accessor :block
		
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
						raise OrderError.new expected, got
					end
					Sequence.join event, joined
				else
					event
				end
			end
			case
			when /^(?<head>[a-z][a-z].*)__$/        =~ name
				SetVariable.new head, *args, &block
			when /^(?<part>[a-z][a-z].*)_$/         =~ name
				if args.first.is_a? String
					Part.new [part], args.first
				else
					sequence_sugar.(Part.new [part])
				end
			when /^[a-z][a-z].*$/                   =~ name
				if block
					SetVariable.new name, *args, &block
				elsif has_variable?(name) && (args.empty? || args.size == 1 && args.first.is_a?(Event))
					sequence_sugar.(GetVariable.new name)
				else
					InlineLisp.new name, *args
				end
			when /^t(?<duration>.*)$/               =~ name
				Cram.new duration, &block
			when /^(?<pitch>[a-g])(?<duration>.*)$/ =~ name
				sequence_sugar.(Note.new pitch, duration)
			when /^r(?<duration>.*)$/               =~ name
				sequence_sugar.(Rest.new duration)
			when /^x$/                              =~ name
				Chord.new &block
			when /^s$/                              =~ name
				Sequence.new *args, &block
			when /^o!$/                             =~ name
				sequence_sugar.(Octave.new('').tap { _1.up_or_down = 1})
			when /^o\?$/                            =~ name
				sequence_sugar.(Octave.new('').tap { _1.up_or_down = -1})
			when /^o(?<num>\d*)$/                   =~ name
				sequence_sugar.(Octave.new num)
			when /^v(?<num>\d+)$/                   =~ name
				sequence_sugar.(Voice.new num)
			when /^__(?<head>.+)$/                  =~ name
				sequence_sugar.(AtMarker.new head)
			when /^_(?<head>.+)$/                   =~ name
				sequence_sugar.(Marker.new head)
			else
				super
			end.then do |event|
				EventContainer.new event, self
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
	class Score
		include EventList
		
		# Plays the score.
		# @return The command line output of the +alda+ command.
		# @example
		#   Alda::Score.new { piano_; c; d; e }.play
		#   # => "[27713] Parsing/evaluating...\n[27713] Playing...\n"
		#   # (and plays the sound)
		#   Alda::Score.new { piano_; c; d; e }.play from: 1
		#   # (plays only an E note)
		def play **opts
			Alda.stop
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
		
		def to_s
			events_alda_codes
		end
		
		def initialize(...)
			super
			on_contained
		end
	end
	
	# The class of elements of EventList#events.
	class Event
		
		# The EventList# object that contains it.
		# Note that it may not be directly contained, but with an EventContainer#
		# object in the middle.
		attr_accessor :parent
		
		# The EventContainer# object that contains it.
		# It may be +nil+, especially probably when
		# it itself is an EventContainer#.
		attr_accessor :container
		
		# The callback invoked when it is contained in an EventContainer#.
		# It is overridden in InlineLisp# and EventList#.
		# @example
		#   class Alda::Note
		#     def on_contained
		#       puts 'a note contained'
		#     end
		#   end
		#   Alda::Score.new { c } # => outputs "a note contained"
		def on_contained
		end
		
		# Converts to alda code. To be overridden.
		def to_alda_code
			''
		end
	end
	
	# The class for objects containing an event.
	class EventContainer < Event
		
		# The contained Event# object.
		attr_accessor :event
		
		# The repetition counts. +nil+ if none.
		attr_accessor :count
		
		# The repetition labels. Empty if none.
		attr_accessor :labels
		
		# @param event The Event# object to be contained.
		# @param parent The EventList# object containing the event.
		def initialize event, parent
			@event = event
			@parent = parent
			@labels = []
			on_containing
		end
		
		# Make #event a Chord# object.
		# @example
		#   Alda::Score.new { piano_; c/-e/g }.play
		#   # (plays the chord Cm)
		#
		# If the contained event is a Part# object,
		# make #event a new Part# object.
		# @example
		#   Alda::Score.new { violin_/viola_/cello_; e; f; g}.play
		#   # (plays notes E, F, G with three instruments simultaneously)
		def / other
			unless (expected = other) == (got = @parent.events.pop)
				raise OrderError.new expected, got
			end
			@event =
					if @event.is_a? Part
						Part.new @event.names + other.event.names, other.event.arg
					else
						Chord.new @event, other.event
					end
			self
		end
		
		def to_alda_code
			result = @event.to_alda_code
			unless @labels.empty?
				result.concat ?', @labels.map(&:to_alda_code).join(?,)
			end
			result.concat ?*, @count.to_alda_code if @count
			result
		end
		
		# Marks repetition.
		def * num
			@count = num
			self
		end
		
		# Marks alternative repetition.
		def % labels
			labels = [labels] unless labels.is_a? Array
			@labels.replace labels.to_a
			self
		end
		
		def event= event
			@event = event
			on_containing
			@event
		end
		
		def on_containing
			if @event
				@event.container = self
				@event.parent = @parent
				@event.on_contained
			end
		end
		
		def method_missing name, *args
			result = @event.__send__ name, *args
			result = self if result == @event
			result
		end
	end
	
	# Inline lisp event.
	class InlineLisp < Event
		
		# The function name of the lisp function
		attr_accessor :head
		
		# The arguments passed to the lisp function.
		# Its elements can be
		# Array#, Hash#, Numeric#, String#, Symbol#, or Event#.
		attr_accessor :args
		
		# The underlines in +head+ will be converted to hyphens.
		def initialize head, *args
			@head = head.to_s.gsub ?_, ?-
			@args = args
		end
		
		def to_alda_code
			"(#{head} #{args.map(&:to_alda_code).join ' '})"
		end
		
		def on_contained
			super
			@args.reverse_each do |event|
				if event.is_a?(Event) && (expected = event) != (got = @parent.events.pop)
					raise OrderError.new expected, got
				end
			end
		end
	end
	
	# A note event.
	class Note < Event
		
		# The string representing the pitch
		attr_accessor :pitch
		
		# The string representing the duration.
		# It ends with +~+ if the note slurs.
		attr_accessor :duration
		
		# The underlines in +duration+ will be converted to +~+.
		# Exclamation mark and question mark in +duration+
		# will be interpreted as accidentals in #pitch.
		#
		# The number of underlines at the end of +duration+ means:
		# neither natural nor slur if 0,
		# natural if 1,
		# slur if 2,
		# both natural and slur if 3.
		def initialize pitch, duration
			@pitch = pitch.to_s
			@duration = duration.to_s.gsub ?_, ?~
			case (/(?<str>~*)$/ =~ @duration ? str.size : return)
			when 0 # no slur or natural
				case @duration[-1]
				when ?! # sharp
					@pitch.concat ?+
					@duration[-1] = ''
				when ?? # flat
					@pitch.concat ?-
					@duration[-1] = ''
				end
			when 1 # natural
				@pitch.concat ?_
				@duration[-1] = ''
			when 2 # slur
				@duration[-1] = ''
			when 3 # slur and natural
				@pitch.concat ?_
				@duration[@duration.size - 2..] = ''
			end
		end
		
		# Append a sharp sign after #pitch.
		# @example
		#   Alda::Score.new { piano_; +c }.play
		#   # (plays a C\# note)
		def +@
			@pitch.concat ?+
			self
		end
		
		# Append a flat sign after #pitch.
		# @example
		#   Alda::Score.new { piano_; -d }.play
		#   # (plays a Db note)
		def -@
			@pitch.concat ?-
			self
		end
		
		# Append a natural sign after #pitch
		# @example
		#   Alda::Score.new { piano_; key_sig 'f+'; ~f }.play
		#   # (plays a F note)
		def ~
			@pitch.concat ?_
			self
		end
		
		def to_alda_code
			result = @pitch + @duration
			result.concat ?*, @count.to_alda_code if @count
			result
		end
	end
	
	# A rest event.
	class Rest < Event
		
		# The string representing a duration.
		attr_accessor :duration
		
		# Underlines in +duration+ will be converted to +~+.
		def initialize duration
			@duration = duration.to_s.tr ?_, ?~
		end
		
		def to_alda_code
			?r + @duration
		end
	end
	
	# An octave event.
	class Octave < Event
		
		# The string representing the octave's number.
		# It can be empty, serving for #+@ and #-@.
		attr_accessor :num
		
		# Positive for up, negative for down, and 0 as default.
		attr_accessor :up_or_down
		
		def initialize num
			@num = num.to_s
			@up_or_down = 0
		end
		
		# Octave up.
		# @example
		#   Alda::Score.new { piano_; c; +o; c }.play
		#   # (plays C4, then C5)
		# @see #-@
		def +@
			@up_or_down += 1
			self
		end
		
		# Octave down.
		# @see #+@.
		def -@
			@up_or_down -= 1
			self
		end
		
		def to_alda_code
			case @up_or_down <=> 0
			when 0
				?o + @num
			when 1
				?> * @up_or_down
			when -1
				?< * -@up_or_down
			end
		end
	end
	
	# A chord event.
	# Includes EventList#.
	class Chord < Event
		include EventList
		
		# EventList#x invokes this method.
		# @see EventList#method_missing
		# @param events In most cases, should not be used.
		# @param block To be passed with the Chord# object as +self+.
		# @example
		#   Alda::Score.new { piano_; x { c; -e; g } }.play
		#   # (plays chord Cm)
		def initialize *events, &block
			@events = events
			super &block
		end
		
		def to_alda_code
			events_alda_codes ?/
		end
	end
	
	# A part event.
	class Part < Event
		
		# The names of the part. To be joined with +/+ as delimiter.
		attr_accessor :names
		
		# The nickname of the part. +nil+ if none.
		attr_accessor :arg
		
		def initialize names, arg = nil
			@names = names.map { |name| name.to_s.tr ?_, ?- }
			@arg = arg
		end
		
		def to_alda_code
			result = @names.join ?/
			result.concat " \"#{@arg}\"" if @arg
			result.concat ?:
		end
		
		# Enables dot accessor.
		# @example
		#   Alda::Score.new do
		#     violin_/viola_/cello_('strings'); g1_1_1
		#     strings_.cello_; -o; c1_1_1
		#   end.play
		def method_missing name, *args
			str = name.to_s
			return super unless str[-1] == ?_
			str[-1] = ''
			@names.last.concat ?., str
			if args.size == 1
				joined = args.first
				unless (got = @parent.events.pop) == (expected = joined)
					raise OrderError.new expected, got
				end
				unless @container
					@container = EventContainer.new nil, @parent
					@parent.events.delete self
					@parent.push @container
				end
				@container.event = Sequence.join self, joined
			end
		end
	end
	
	# A voice event.
	class Voice < Event
		
		# The string representing the voice's number.
		attr_accessor :num
		
		def initialize num
			@num = num
		end
		
		def to_alda_code
			?V + num + ?:
		end
	end
	
	# A CRAM event. Includes EventList#.
	class Cram < Event
		include EventList
		
		# The string representing the duration of the CRAM.
		attr_accessor :duration
		
		# EventList#t invokes this method.
		# @see EventList#method_missing
		# @param block To be passed with the CRAM as +self+.
		# @example
		#   Alda::Score.new { piano_; t8 { x; y; }}
		def initialize duration, &block
			@duration = duration
			super &block
		end
		
		def to_alda_code
			"{#{events_alda_codes}}#@duration"
		end
	end
	
	# A marker event.
	# @see AtMarker#
	class Marker < Event
		
		# The marker's name
		attr_accessor :name
		
		# Underlines in +name+ is converted to hyphens.
		def initialize name
			@name = name.to_s.tr ?_, ?-
		end
		
		def to_alda_code
			?% + @name
		end
	end
	
	# An at-marker event.
	# @see Marker#
	class AtMarker < Event
		
		# The corresponding marker's name
		attr_accessor :name
		
		# Underlines in +name+ is converted to hyphens.
		def initialize name
			@name = name.to_s.tr ?_, ?-
		end
		
		def to_alda_code
			?@ + @name
		end
	end
	
	# A sequence event. Includes EventList#.
	class Sequence < Event
		include EventList
		
		# Using this module can fix a bug of Array#flatten.
		# @example
		#   def (a = Object.new).method_missing(...)
		#     Object.new
		#   end
		#   [a].flatten rescue $! # => #<TypeError:...>
		#   using Alda::Sequence::RefineFlatten
		#   [a].flatten # => [#<Object:...>]
		module RefineFlatten
			refine Array do
				def flatten
					each_with_object [] do |element, result|
						if element.is_a? Array
							result.push *element.flatten
						else
							result.push element
						end
					end
				end
			end
		end
		using RefineFlatten
		
		def to_alda_code
			@events.to_alda_code
		end
		
		# Creates a Sequence# object by joining +events+.
		# The EventContainer# objects are extracted,
		# and the Sequence# objects are flattened.
		def self.join *events
			new do
				@events = events.map do |event|
					while event.is_a?(EventContainer) && !event.count && event.labels.empty?
						event = event.event
					end
					event.is_a?(Sequence) ? event.events : event
				end.flatten
			end
		end
	end
	
	# A set-variable event.
	# Includes EventList#.
	class SetVariable < Event
		include EventList
		
		# The name of the variable.
		attr_accessor :name
		
		# The events passed to it using arguments instead of a block.
		attr_reader :original_events
		
		def initialize name, *events, &block
			@name = name.to_sym
			@original_events = events
			@events = events.clone
			super &block
		end
		
		# Specially, the result ends with a newline.
		def to_alda_code
			"#@name = #{events_alda_codes}\n"
		end
		
		def on_contained
			super
			@parent.variables.add @name
			@original_events.reverse_each do |event|
				unless (expected = event) == (got = @parent.events.pop)
					raise OrderError.new expected, got
				end
			end
		end
	end
	
	# A get-variable event
	class GetVariable < Event
		
		# The name of the variable
		attr_accessor :name
		
		def initialize name
			@name = name
		end
		
		def to_alda_code
			@name.to_s
		end
	end
end
