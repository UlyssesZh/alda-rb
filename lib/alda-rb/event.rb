##
# The class of elements of Alda::EventList#events.
class Alda::Event
	
	##
	# The Alda::EventList object that contains it.
	#
	# Note that it may not be directly contained, but with an Alda::EventContainer
	# object in the middle.
	attr_accessor :parent
	
	##
	# The Alda::EventContainer object that contains it.
	# It may be +nil+ if there is not a container containing it,
	# especially probably when it itself is an Alda::EventContainer.
	attr_accessor :container
	
	##
	# The callback invoked when it is contained in an Alda::EventContainer.
	# It is overridden in Alda::InlineLisp and Alda::EventList.
	# It is called in Alda::EventContainer#on_containing.
	#
	#   class Alda::Note
	#     def on_contained
	#       super
	#       puts 'a note contained'
	#     end
	#   end
	#   Alda::Score.new { c } # => outputs "a note contained"
	def on_contained
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Converts to alda code. To be overridden in subclasses.
	def to_alda_code
		''
	end
	
	##
	# Delete itself from its #parent.
	# If it is not at its #parent's end, raises Alda::OrderError.
	#
	# Here is a list of cases where the method is invoked:
	#
	# 1. Using the sequence sugar when operating an Alda::EventList.
	#
	# 2. Using Alda::EventContainer#/ to create chords or
	#    parts of multiple instruments.
	#
	# 3. Using dot accessor of Alda::Part. See Alda::Part#method_missing.
	#
	# 4. Using the inline lisp sugar. See Alda::InlineLisp.
	#
	# This method needs invoking in these cases because
	# if an event is created using Alda::EventList sugars
	# (see Alda::EventList#method_missing), it is automatically
	# pushed to its #parent.
	# However, the cases above requires the event be contained
	# in another object.
	def detach_from_parent
		if @parent && self != (got = @parent.events.pop)
			raise Alda::OrderError.new self, got
		end
	end
end

##
# The class for objects containing an event.
#
# Alda::EventContainer objects are literally everywhere
# if you are a heavy user of event list sugars.
# See Alda::EventList#method_missing.
class Alda::EventContainer < Alda::Event
	
	##
	# The contained Alda::Event object.
	#
	#   Alda::Score.new do
	#     p c.event.class      # => Alda::Note
	#     p((e/g).event.class) # => Alda::Chord
	#     p((a b).event.class) # => Alda::Sequence
	#  end
	attr_accessor :event
	
	##
	# The repetition counts. +nil+ if none.
	#
	#   Alda::Score.new do
	#     p((c*2).count)   # => 2
	#     p((d*3*5).count) # => 15
	#   end
	attr_accessor :count
	
	##
	# The repetition labels. Empty if none.
	#
	#   Alda::Score.new do
	#     p((c%2).labels)        # => [2]
	#     p((c%[2,4..6]).labels) # => [2, 4..6]
	#   end
	attr_accessor :labels
	
	##
	# :call-seq:
	#   new(event, parent) -> Alda::EventContainer
	#
	# Creates a new Alda::EventContainer.
	# Invokes #on_containing.
	#
	# +event+ is the Alda::Event object to be contained.
	#
	# +parent+ is the Alda::EventList object containing the event.
	def initialize event, parent
		@event = event
		@parent = parent
		@labels = []
		on_containing
	end
	
	##
	# :call-seq:
	#   container / other -> container
	#
	# Makes #event an Alda::Chord object.
	#
	#   Alda::Score.new { piano_; c/-e/g }.play
	#   # (plays the chord Cm)
	#
	# If the contained event is an Alda::Part object,
	# makes #event a new Alda::Part object.
	#
	#   Alda::Score.new { violin_/viola_/cello_; e; f; g}.play
	#   # (plays notes E, F, G with three instruments simultaneously)
	def / other
		other.detach_from_parent
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
	
	##
	# :call-seq:
	#   container * num -> container
	#
	# Marks repetition.
	#
	# For examples, see #%.
	def * num
		@count = (@count || 1) * num
		self
	end
	
	##
	# :call-seq:
	#   container % labels -> container
	#
	# Marks alternative endings.
	#
	#   Alda::Score.new { (b a%1)*2 }.to_s
	#   # => "[b a'1]*2"
	def % labels
		labels = [labels] unless labels.is_a? Array
		@labels.replace labels.to_a
		self
	end
	
	##
	# :call-seq:
	#   event=(event) -> event
	#
	# Sets #event and invokes #on_containing.
	def event= event
		@event = event
		on_containing
		@event
	end
	
	##
	# A callback invoked in #event= and ::new.
	def on_containing
		if @event
			@event.container = self
			@event.parent = @parent
			@event.on_contained
		end
	end
	
	##
	# :call-seq:
	#   (missing method) -> obj
	#
	# Calls method on #event.
	#
	# Note that if the method of #event returns #event itself,
	# the method here returns the container itself.
	#
	#   Alda::Score.new do
	#     container = c
	#     p container.class              # => Alda::EventContainer
	#     p container.respond_to? :pitch # => false
	#     p container.pitch              # => "c"
	#     p container.respond_to? :+@    # => false
	#     p((+container).class)          # => Alda::EventContainer
	#     p to_s                         # => "c+"
	#   end
	def method_missing(...)
		result = @event.__send__(...)
		result = self if result == @event
		result
	end
end

##
# An inline lisp event. An Alda::EventContainer containing
# an Alda::InlineLisp can be derived using event list
# sugar. See Alda::EventList#method_missing.
#
# Sometimes you need help from Alda::LispIdentifier.
#
# It serves as attributes in alda codes.
#
#   Alda::Score.new do
#     tempo! 108
#     quant! 200
#     piano_ c e g violin_ g2 e4
#   end
#
# Here, <tt>tempo! 108</tt> and <tt>quant! 200</tt>
# are inline lisp events and serves for alda attributes.
#
# It can participate in the sequence sugar if it is
# at the end of the sequence.
#
#   Alda::Score.new do
#     piano_ c d e quant 200
#     g o! c o? c2
#   end
#
# You can operate a score by purely using inline lisp events.
#
#   Alda::Score.new do
#     part 'piano'
#     key_sig [:d, :major]
#     note pitch :d
#     note pitch :e
#     note pitch(:f), duration(note_length 2)
#   end
#
# When using event list sugar to create inline lisp events,
# note that it is not previously defined as a variable.
# See Alda::SetVariable and Alda::GetVariable.
#
#   Alda::Score.new do
#     piano_
#     p barline.event.class # => Alda::InlineLisp
#     barline__ c d e f
#     p barline.event.class # => Alda::GetVariable
#   end
#
# Whether it is an Alda::SetVariable, Alda::InlineLisp,
# or Alda::GetVariable is intelligently determined.
#
#   Alda::Score.new do
#     piano_
#     p((tempo 108).event.class)  # => Alda::InlineLisp
#     p tempo { c d }.event.class # => Alda::SetVariable
#     p tempo.event.class         # => Alda::GetVariable
#     p((tempo 60).event.class)   # => Alda::InlineLisp
#     p to_s
#     # => "piano: (tempo 108) tempo = [c d]\n tempo (tempo 60)"
#   end
#
# If you want, you can generate lisp codes using ruby.
#
#   Alda::Score.new do
#     println reduce _into_, {}, [{dog: 'food'}, {cat: 'chow'}]
#   end.save 'temp.clj'
#   `clj temp.clj` # => "[[:dog food] [:cat chow]]\n"
class Alda::InlineLisp < Alda::Event
	
	##
	# The function name of the lisp function
	attr_accessor :head
	
	##
	# The arguments passed to the lisp function.
	#
	# Its elements can be any object that responds to
	# +to_alda_code+ and +detach_from_parent+.
	attr_accessor :args
	
	##
	# :call-seq:
	#   new(head, *args) -> Alda::InlineLisp
	#
	# Creates a new Alda::InlineLisp.
	#
	# The underlines "_" in +head+ will be converted to hyphens "-".
	def initialize head, *args
		@head = head.to_s.gsub ?_, ?-
		@args = args
	end
	
	def to_alda_code
		"(#{head} #{args.map(&:to_alda_code).join ' '})"
	end
	
	def on_contained
		super
		@args.detach_from_parent
	end
end

##
# A note event. An Alda::EventContainer containing
# an Alda::Note can be derived using Alda::EventList sugar.
# See Alda::EventList#method_missing.
#
# There cannot be tildes and dots in (usual) ruby method names,
# so use underlines instead.
#
# The accidentals can be added using #+@, #-@, and #~, or by
# using exclamation mark, question mark or underline.
#
#   Alda::Score.new do
#     key_sig! [:d, :major]
#     c4_2 d1108ms e2s
#     f2!      # F sharp
#     g20ms_4? # G flat
#     a6_      # A natural
#     c__      # C (slur)
#     f___     # D natural (slur)
#   end
class Alda::Note < Alda::Event
	
	##
	# The string representing the pitch
	attr_accessor :pitch
	
	##
	# The string representing the duration.
	#
	# It ends with a tilde "~" if the note slurs.
	attr_accessor :duration
	
	##
	# :call-seq:
	#   new(pitch, duration) -> Alda::Note
	#
	# The underlines in +duration+ will be converted to tildes "~".
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
	
	##
	# :call-seq:
	#   +note -> note
	#
	# Append a sharp sign after #pitch.
	#
	#   Alda::Score.new { piano_; +c }.play
	#   # (plays a C sharp note)
	def +@
		@pitch.concat ?+
		self
	end
	
	##
	# :call-seq:
	#   -note -> note
	#
	# Append a flat sign after #pitch.
	#
	#   Alda::Score.new { piano_; -d }.play
	#   # (plays a D flat note)
	def -@
		@pitch.concat ?-
		self
	end
	
	##
	# :call-seq:
	#   ~note -> note
	#
	# Append a natural sign after #pitch.
	#
	#   Alda::Score.new { piano_; key_sig 'f+'; ~f }.play
	#   # (plays an F note)
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

##
# A rest event. An Alda::EventContainer containing an
# Alda::Rest can be created using event list sugar.
# See Alda::EventList#method_missing.
#
# When using event list sugar, its duration can be specified
# just like that of Alda::Note.
#
#   Alda::Score.new do
#     piano_ c8 r4 c8 r4 c4
#   end
class Alda::Rest < Alda::Event
	
	##
	# The string representing a duration.
	attr_accessor :duration
	
	##
	# :call-seq:
	#   new(duration) -> Alda::Rest
	#
	# Creates an Alda::Rest.
	#
	# Underlines "_" in +duration+ will be converted to tildes "~".
	def initialize duration
		@duration = duration.to_s.tr ?_, ?~
	end
	
	def to_alda_code
		?r + @duration
	end
end

##
# An octave event. An Alda::EventContainer containing
# an Alda::Octave can be derived using event list sugar.
# See Alda::EventList#method_missing.
#
# +o!+ means octave up, and +o?+ means octave down.
# You can also use #+@ and #-@ to denote octave up and down.
class Alda::Octave < Alda::Event
	
	##
	# The string representing the octave's number.
	#
	# It can be empty, in which case
	# it is purely serving for #+@ and #-@.
	attr_accessor :num
	
	##
	# Positive for up, negative for down, and +0+ as default.
	#
	#   Alda::Score.new do
	#     p((++++o).event.up_or_down) # => 4
	#   end
	attr_accessor :up_or_down
	
	##
	# :call-seq:
	#   new(num) -> Alda::Octave
	#
	# Creates an Alda::Octave.
	def initialize num
		@num = num.to_s
		@up_or_down = 0
	end
	
	##
	# :call-seq:
	#   +octave -> octave
	#
	# \Octave up.
	#
	#   Alda::Score.new { piano_; c; +o; c }.play
	#   # (plays C4, then C5)
	#
	# See #-@.
	def +@
		@up_or_down += 1
		self
	end
	
	##
	# :call-seq:
	#   -octave -> octave
	#
	# \Octave down.
	# See #+@.
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

##
# A chord event.
# Includes Alda::EventList.
#
# An Alda::EventContainer containing an Alda::Chord
# can be created using event list sugar.
# See Alda::EventList#method_missing.
#
#   Alda::Score.new do
#     p x{ c; e; g }.event.class # => Alda::Chord
#   end
#
# The event contained by an Alda::EventContainer
# can become an Alda::Chord by using Alda::EventContainer#/.
class Alda::Chord < Alda::Event
	include Alda::EventList
	
	##
	# :call-seq:
	#   new(*events, &block) -> Alda::Chord
	#
	# <tt>Alda::EventList#x</tt> (an event list sugar)
	# invokes this method, see Alda::EventList#method_missing.
	#
	# In most cases, +events+ should be empty.
	# Note that +events+ cannot be specified using the sugar.
	# +block+ is to be passed with the chord object as +self+.
	#
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

##
# A part event.
class Alda::Part < Alda::Event
	
	##
	# The names of the part. To be joined with +/+ as delimiter.
	attr_accessor :names
	
	##
	# The nickname of the part. +nil+ if none.
	attr_accessor :arg
	
	##
	# :call-seq:
	#   new(names, args=nil) -> Alda::Part
	#
	# Creates an Alda::Part.
	def initialize names, arg = nil
		@names = names.map { |name| name.to_s.tr ?_, ?- }
		@arg = arg
	end
	
	def to_alda_code
		result = @names.join ?/
		result.concat " \"#{@arg}\"" if @arg
		result.concat ?:
	end
	
	##
	# :call-seq:
	#   part.(component)_ -> Alda::EventContainer or Alda::Part
	#
	# Enables dot accessor.
	#
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
			unless @container
				@container = Alda::EventContainer.new nil, @parent
				@parent.events.delete self
				@parent.push @container
			end
			@container.event = Alda::Sequence.join self, args.first.tap(&:detach_from_parent)
			@container
		else
			@container || self
		end
	end
end

##
# A voice event.
class Alda::Voice < Alda::Event
	
	##
	# The string representing the voice's number.
	attr_accessor :num
	
	##
	# :call-seq:
	#   new(num) -> Alda::Voice
	#
	# Creates an Alda::Voice.
	def initialize num
		@num = num
	end
	
	def to_alda_code
		?V + num + ?:
	end
end

##
# A CRAM event.
#
# Includes Alda::EventList.
class Alda::Cram < Alda::Event
	include Alda::EventList
	
	##
	# The string representing the duration of the CRAM.
	attr_accessor :duration
	
	##
	# <tt>Alda::EventList#t</tt> invokes this method,
	# see Alda::EventList#method_missing
	# +block+ is to be passed with the CRAM object as +self+.
	#
	#   Alda::Score.new { piano_; t8 { x; y; }}
	def initialize duration, &block
		@duration = duration
		super &block
	end
	
	def to_alda_code
		"{#{events_alda_codes}}#@duration"
	end
end

##
# A marker event.
#
# See Alda::AtMarker.
class Alda::Marker < Alda::Event
	
	##
	# The marker's name
	attr_accessor :name
	
	##
	# :call-seq:
	#   new(name) -> Alda::Marker
	#
	# Creates an Alda::Marker.
	#
	# Underlines in +name+ is converted to hyphens.
	def initialize name
		@name = name.to_s.tr ?_, ?-
	end
	
	def to_alda_code
		?% + @name
	end
end

##
# An at-marker event.
#
# See Alda::Marker.
class Alda::AtMarker < Alda::Event
	
	##
	# The corresponding marker's name
	attr_accessor :name
	
	##
	# :call-seq:
	#   new(name) -> Alda::AtMarker
	#
	# Creates an Alda::AtMarker.
	#
	# Underlines "_" in +name+ is converted to hyphens "-".
	def initialize name
		@name = name.to_s.tr ?_, ?-
	end
	
	def to_alda_code
		?@ + @name
	end
end

##
# A sequence event.
#
# Includes Alda::EventList.
class Alda::Sequence < Alda::Event
	include Alda::EventList
	
	##
	# Using this module can fix a bug of <tt>Array#flatten</tt>.
	#
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
	
	##
	# :call-seq:
	#   join(*events) -> Alda::Sequence
	#
	# Creates an Alda::Sequence object by joining +events+.
	#
	# The Alda::EventContainer objects are extracted,
	# and the Alda::Sequence objects are flattened.
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

##
# A set-variable event.
#
# Includes Alda::EventList.
class Alda::SetVariable < Alda::Event
	include Alda::EventList
	
	##
	# The name of the variable.
	attr_accessor :name
	
	##
	# The events passed to it using arguments instead of a block.
	attr_reader :original_events
	
	##
	# :call-seq:
	#   new(name, *events, &block) -> Alda::SetVariable
	#
	# Creates an Alda::SetVariable.
	def initialize name, *events, &block
		@name = name.to_sym
		@original_events = events
		@events = events.clone
		super &block
	end
	
	##
	# Specially, the returned value ends with a newline "\n".
	def to_alda_code
		"#@name = #{events_alda_codes}\n"
	end
	
	def on_contained
		super
		@parent.variables.add @name
		@original_events.detach_from_parent
	end
end

##
# A get-variable event
class Alda::GetVariable < Alda::Event
	
	##
	# The name of the variable.
	attr_accessor :name
	
	##
	# :call-seq:
	#   new(name) -> Alda::GetVariable
	#
	# Creates an Alda::GetVariable.
	def initialize name
		@name = name
	end
	
	def to_alda_code
		@name.to_s
	end
end

##
# A lisp identifier event.
#
# It is in fact not a kind of event in alda.
# However, such a thing is needed when writing some
# lisp codes in alda.
#
# A standalone lisp identifier is useless.
# Use it together with Alda::InlineLisp.
class Alda::LispIdentifier < Alda::Event
	
	##
	# The name of the lisp identifier.
	attr_accessor :name
	
	##
	# :call-seq:
	#   new(name) -> Alda::LispIdentifier
	#
	# Creates an Alda::LispIdentifier.
	#
	# Underlines "_" in +name+ is converted to hyphens "-".
	def initialize name
		@name = name.tr ?_, ?-
	end
	
	def to_alda_code
		@name
	end
end
