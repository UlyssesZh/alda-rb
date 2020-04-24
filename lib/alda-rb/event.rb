# The class of elements of EventList#events.
class Alda::Event
	
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
class Alda::EventContainer < Alda::Event
	
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
				if @event.is_a? Alda::Part
					Alda::Part.new @event.names + other.event.names, other.event.arg
				else
					Alda::Chord.new @event, other.event
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
		@count = (@count || 1) * num
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
class Alda::InlineLisp < Alda::Event
	
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
			if event.is_a?(Alda::Event) && (expected = event) != (got = @parent.events.pop)
				raise Alda::OrderError.new expected, got
			end
		end
	end
end

# A note event.
class Alda::Note < Alda::Event
	
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
		@duration = duration.to_s.tr ?_, ?~
		case @duration[-1]
		when ?! # sharp
			@pitch.concat ?+
			@duration[-1] = ''
		when ?? # flat
			@pitch.concat ?-
			@duration[-1] = ''
		end
		waves = /(?<str>~+)\z/ =~ @duration ? str.size : return
		@duration[@duration.length - waves..] = ''
		if waves >= 2
			waves -= 2
			@duration.concat ?~
		end
		@pitch.concat ?_ * waves
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
class Alda::Rest < Alda::Event
	
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
class Alda::Octave < Alda::Event
	
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
class Alda::Chord < Alda::Event
	include Alda::EventList
	
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
class Alda::Part < Alda::Event
	
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
				raise Alda::OrderError.new expected, got
			end
			unless @container
				@container = Alda::EventContainer.new nil, @parent
				@parent.events.delete self
				@parent.push @container
			end
			@container.event = Alda::Sequence.join self, joined
		end
	end
end

# A voice event.
class Alda::Voice < Alda::Event
	
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
class Alda::Cram < Alda::Event
	include Alda::EventList
	
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
class Alda::Marker < Alda::Event
	
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
class Alda::AtMarker < Alda::Event
	
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
class Alda::Sequence < Alda::Event
	include Alda::EventList
	
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
				while event.is_a?(Alda::EventContainer) && !event.count && event.labels.empty?
					event = event.event
				end
				event.is_a?(Alda::Sequence) ? event.events : event
			end.flatten
		end
	end
end

# A set-variable event.
# Includes EventList#.
class Alda::SetVariable < Alda::Event
	include Alda::EventList
	
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
				raise Alda::OrderError.new expected, got
			end
		end
	end
end

# A get-variable event
class Alda::GetVariable < Alda::Event
	
	# The name of the variable
	attr_accessor :name
	
	def initialize name
		@name = name
	end
	
	def to_alda_code
		@name.to_s
	end
end
