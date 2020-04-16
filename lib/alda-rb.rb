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
	#   # => Alda::CommandLineError (Expected a command, got sandwich)
	def self.method_missing name, *args, **opts
		name = name.to_s.gsub ?_, ?-
		args.concat opts.map { |key, val|
			["--#{key.to_s.gsub ?_, ?-}", val.to_s]
		}.flatten
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
	
	# The error raised when one tries to run a non-existing subcommand
	# of +alda+.
	class CommandLineError < Exception
		
		# The <tt>Process::Status</tt> object representing the status of
		# the process that runs +alda+ command.
		attr_accessor :status
		
		# Create a CommandLineError# object.
		# @param status The status of the process running +alda+ command.
		# @param msg The exception message.
		def initialize status, msg = nil
			super msg
			@status = status
		end
	end
	
	# Including this module can make your class have the ability
	# to have an event list.
	# See docs below to get an overview of its functions.
	module EventList
		
		# The array containing the events (Event# objects),
		# most of which are EventContainer# objects.
		attr_accessor :events
		
		# Make the object have the ability to appending its +events+
		# conveniently.
		#
		# Here is a list of sugar. When the name of a method meets certain
		# condition, the method is regarded as an event appended to +events+.
		#
		# 1. Starting with 2 lowercase letters and
		#    ending with underline character: instrument. See Part#.
		#
		# 2. Starting with 2 lowercase letters: inline lisp code.
		#    See InlineLisp#.
		#
		# 3. Starting with "t": CRAM. See Cram#.
		#
		# 4. Starting with one of "a", "b", ..., "g": note. See Note#.
		#
		# 5. Starting with "r": rest. See Rest#.
		#
		# 6. "x": chord. See Chord#.
		#
		# 7. "s": sequence. See Sequence#.
		#
		# 8. Starting with "o": octave. See Octave#.
		#
		# 9. Starting with "v": voice. See Voice#.
		#
		# 10. Starting with "__" (2 underlines): at marker. See AtMarker#.
		#
		# 11. Starting with "_" (underline): marker. See Marker#.
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
			case
			when /^(?<part>[a-z][a-z].*)_$/         =~ name
				Part.new [part], args.first
			when /^[a-z][a-z].*$/                   =~ name
				InlineLisp.new name, *args
			when /^t(?<duration>.*)$/               =~ name
				Cram.new duration, &block
			when /^(?<pitch>[a-g])(?<duration>.*)$/ =~ name
				Note.new pitch, duration
			when /^r(?<duration>.*)$/               =~ name
				Rest.new duration
			when /^x$/                              =~ name
				Chord.new &block
			when /^s$/                              =~ name
				Sequence.new *args, &block
			when /^o(?<num>\d*)$/                   =~ name
				Octave.new num
			when /^v(?<num>\d+)$/                   =~ name
				Voice.new num
			when /^__(?<head>.+)$/                  =~ name
				AtMarker.new head
			when /^_(?<head>.+)$/                   =~ name
				Marker.new head
			else
				super
			end.then do |event|
				EventContainer.new event, self
			end.tap &@events.method(:push)
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
		#     tempo! 108   # inline lisp
		#     piano_       # piano part
		#     o4           # octave 4
		#     c8; d; e; f  # notes
		#     g4; g; a; f; g; e; f; d; e; c
		#     d4_8         # cannot have '~', use '_' instead
		#     o3 b8 o4 c2
		#   end
		#   # => #<Alda::Score:0x... @events=[...]>
		def initialize &block
			@events ||= []
			instance_eval &block if block
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
	end
	
	# The class of elements of EventList#events.
	class Event
		
		# The EventList# object that contains it.
		# Note that it may not be directly contained, but with an EventContainer#
		# object in the middle.
		attr_accessor :parent
		
		# The callback invoked when it is contained in an EventContainer#.
		# It is overridden in InlineLisp#, so be aware if you want to
		# override InlineLisp#on_contained.
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
			@event.parent = @parent
			@labels = []
			@event.on_contained
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
			raise unless other == @parent.events.pop
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
		end
		
		# Marks alternative repetition.
		def % labels
			labels = [labels] unless labels.respond_to? :to_a
			@labels.replace labels.to_a
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
		# Array#, Hash#, Numeric#, String#, Symbol#, or InlineLisp#.
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
			@args.reverse_each do |event|
				raise if event.is_a?(Event) && event != @parent.events.pop
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
		def initialize pitch, duration
			@pitch = pitch.to_s
			@duration = duration.to_s.gsub ?_, ?~
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
			@duration = duration.to_s.gsub ?_, ?~
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
			@names = names.map { |name| name.to_s.gsub ?_, ?- }
			@arg = arg
		end
		
		def to_alda_code
			result = @names.join ?/
			result.concat " \"#{@arg}\"" if @arg
			result.concat ?:
		end
		
		# @example
		#   Alda::Score.new do
		#     violin_/viola_/cello_('strings'); g1_1_1
		#     strings_.cello_; -o; c1_1_1
		#   end.play
		def method_missing name, *args
			name = name.to_s
			return super unless name[-1] == ?_
			name[-1] = ''
			@names.last.concat ?., name
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
			@name = name.to_s.gsub ?_, ?-
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
			@name = name.to_s.gsub ?_, ?-
		end
		
		def to_alda_code
			?@ + @name
		end
	end
	
	# A sequence event. Includes EventList#.
	class Sequence < Event
		include EventList
		
		def to_alda_code
			@events.to_alda_code
		end
	end
end
