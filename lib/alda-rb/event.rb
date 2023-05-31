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
	# Delete itself (or its topmost container if it has) from its #parent.
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
	#
	# The parameter +except+ specifies an Array of classes.
	# If #parent is an instance of any of the classes in +except+,
	# the method does nothing.
	def detach_from_parent except = []
		event = self
		event = event.container while event.container
		if @parent && except.none? { @parent.is_a? _1 } && event != (got = @parent.events.pop)
			raise Alda::OrderError.new event, got
		end
	end
	
	##
	# :call-seq:
	#   is_event_of?(klass) -> true or false
	#
	# Whether it is an event of the given class (+klass+).
	# By default, this is the same as +is_a?(klass)+.
	# It is overridden in Alda::EventContainer.
	def is_event_of? klass
		is_a? klass
	end
	
	##
	# :call-seq:
	#   event == other -> true or false
	#
	# Whether it is equal to +other+.
	# To be overriden.
	#
	# Note that #parent and #container should not be taken into account when comparing two events.
	def == other
		super
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
	#
	# When setting this attribute, #on_containing is invoked.
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
		super()
		@event = event
		@labels = []
		@count = 1
		self.parent = parent
		on_containing
	end
	
	##
	# :call-seq:
	#   container / other -> container
	#
	# If at first #event is not an Alda::Part,
	# makes #event an Alda::Chord object.
	#
	#   Alda::Score.new { piano_; c/-e/g }.play
	#   # (plays the chord Cm)
	#
	# This usage assumes that +other+ is an Alda::EventContainer and will extract the contained event
	# out from +other+.
	# This will lose some information about +other+, such as #count and #labels,
	# and potentially lead to confusing results.
	#
	# Because the #labels information about +other+ is lost,
	# the label on +d+ disappears in the following example:
	#
	#   Alda::Score.new { c/(d%1) }.to_s # => "c/d"
	#
	# The following example shows that the two ways of writing a chord with a label are equivalent:
	# adding the label and then using slash, or using slash and then adding the label.
	# This is because #labels and #count are retained while the #event is updated when #/ is called.
	#
	#   Alda::Score.new { p c%1/d == c/d%1 }.to_s # (prints "true") => "c/d'1 c/d'1"
	#
	# If at first #event is an Alda::Part object,
	# makes #event a new Alda::Part object.
	# The meaning is to play the two parts simultaneously.
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
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		result = @event.to_alda_code
		result.concat ?', @labels.map(&:to_alda_code).join(?,) unless @labels.empty?
		result.concat ?*, @count.to_alda_code if @count != 1
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
		check_in_chord
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
		check_in_chord
		self
	end
	
	def event= event # :nodoc:
		@event = event.tap { on_containing }
	end
	
	##
	# :call-seq:
	#   check_in_chord() -> true or false
	#
	# This method is called in #%, #*, and #parent=.
	# It checks if #parent is an Alda::Chord and warns about potential dangers.
	# Returns true if there is no danger, and false otherwise.
	#
	# Because \Alda 2 does not support specifying alternative endings inside a chord
	# (something like <tt>a'1/b</tt>)
	# ({alda-lang/alda#383}[https://github.com/alda-lang/alda/issues/383#issuecomment-886084486]),
	# this method will warn about this if such thing happens and we are using \Alda 2.
	#
	#   Alda.v2!
	#   Alda::Score.new { x{a%1;b} }.to_s # (warns) => "a'1/b"
	#
	# This method will warn about repetitions inside a chord in both generations
	# because the resultant \Alda code is not valid.
	#
	#   Alda::Score.new { x{a*2;b} }.to_s # (warns) => "a*2/b"
	def check_in_chord
		if @parent.is_a?(Alda::Event) && @parent.is_event_of?(Alda::Chord)
			Alda::Utils.warn 'alternative endings in chord not allowed in v2' if Alda.v2? && !@labels&.empty?
			Alda::Utils.warn 'repetitions in chord not allowed' if @count && @count != 1
			false
		else
			true
		end
	end
	
	##
	# :call-seq:
	#  parent=(event) -> event
	#
	# Overrides Alda::Event#parent=.
	# Sets the Alda::Event#parent of the container as well as that of #event.
	def parent= event
		@parent = event
		check_in_chord
		@event.parent = event
	end
	
	##
	# A callback invoked in #event= and ::new.
	def on_containing
		return unless @event
		@event.container = self
		@event.parent = @parent
		@event.on_contained
	end
	
	##
	# :call-seq:
	#   is_event_of?(klass) -> true or false
	#
	# Overrides Alda::Event#is_event_of?.
	# Whether it is an event of the given class (+klass+)
	# or the contained event is.
	def is_event_of? klass
		super || @event.is_event_of?(klass)
	end
	
	##
	# :call-seq:
	#   container == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::EventContainer object
	# and #event, #count and #labels are all equal (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::EventContainer) &&
				@event == other.event && @count == other.count && @labels == other.labels
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
		result == @event ? self : result
	end
end

##
# An inline lisp event. An Alda::EventContainer containing
# an Alda::InlineLisp can be derived using event list
# sugar (see Alda::EventList#method_missing) or by using Alda::EventList#l.
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
# The following example only works in \Alda 1 due to breaking changes in \Alda 2
# ({alda-lang/alda#483}[https://github.com/alda-lang/alda/issues/483],
# {alda-lang/alda#484}[https://github.com/alda-lang/alda/issues/484]).
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
#   Alda.generation = :v1
#   Alda::Score.new do
#     println reduce _into_, {}, [{dog: 'food'}, {cat: 'chow'}]
#   end.save 'temp.clj'
#   `clojure temp.clj` # => "{:dog food, :cat chow}\n"
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
		super()
		@head = Alda::Utils.snake_to_slug head
		@args = args
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		"(#{head} #{args.map(&:to_alda_code).join ' '})"
	end
	
	##
	# See Alda::Event#on_contained.
	def on_contained
		super
		@args.detach_from_parent
	end
	
	##
	# :call-seq:
	#   inline_lisp == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::InlineLisp
	# and has the same #head and #args as +inline_lisp+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::InlineLisp) && @head == other.head && @args == other.args
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
		super()
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
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		result = @pitch + @duration
		result.concat ?*, @count.to_alda_code if @count
		result
	end
	
	##
	# :call-seq:
	#   note == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::Note
	# and has the same #pitch and #duration as +note+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::Note) && @pitch == other.pitch && @duration == other.duration
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
		super()
		@duration = duration.to_s.tr ?_, ?~
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		?r + @duration
	end
	
	##
	# :call-seq:
	#   rest == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::Rest
	# and has the same #duration as +rest+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::Rest) && @duration == other.duration
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
		super()
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
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
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
	
	##
	# :call-seq:
	#   octave == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::Octave
	# and has the same #num and #up_or_down as +octave+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::Octave) && @num == other.num && @up_or_down == other.up_or_down
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
	# There is an event list sugar invoking this method.
	# See Alda::EventList#method_missing.
	#
	# In most cases, +events+ should be empty.
	# Note that +events+ cannot be specified using the sugar.
	# +block+ is to be passed with the chord object as +self+.
	#
	#   Alda::Score.new { piano_; x { c; -e; g } }.play
	#   # (plays chord Cm)
	def initialize *events, &block
		events.each { _1.parent = self if _1.is_a? Alda::Event }
		@events = events
		super &block
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	#
	# Behaves differently for \Alda 1 and \Alda 2:
	# because \Alda 2 does not allow octave changes as part of a chord
	# (something like <tt>a/>/c</tt>, and we have to write <tt>a>/c</tt> or <tt>a/>c</tt> instead)
	# ({alda-lang/alda#383}[https://github.com/alda-lang/alda/issues/383]),
	# the code generated by this method will omit the slash before an octave change.
	#
	#   Alda.generation = :v1
	#   Alda::Score.new { a/o!/c; a/o5/c }.to_s # => "a/>/c a/o5/c"
	#   Alda.generation = :v2
	#   Alda::Score.new { a/o!/c; a/o5/c }.to_s # => "a>/c a o5/c"
	def to_alda_code
		return events_alda_codes ?/ if Alda.v1?
		@events.each_with_index.with_object '' do |(event, i), result|
			if i == 0
				# concat nothing
			elsif event.is_event_of? Alda::Octave
				result.concat ' ' unless event.num.empty?
			else
				result.concat '/'
			end
			result.concat event.to_alda_code
		end
	end
end

##
# A part event. An Alda::EventContainer containing an
# Alda::Part can be derived using event list sugar.
# See Alda::EventList#method_missing.
#
# A part can have nickname.
#
#   Alda::Score.new do
#     piano_ 'player1'
#     c4 d e e e1
#     piano_ 'player2'
#     e4 d g g g1
#   end
#
# You can use Alda::EventContainer#/ to have a set of
# instruments.
#
#   Alda::Score.new do
#     violin_/viola_
#     c2 d4 e2_4
#   end
#
# A set of instruments can also have nickname.
# You can also access an instruments from a set.
# See #method_missing.
#
#   Alda::Score.new do
#     violin_/viola_/cello_('strings')
#     g1_1_1
#     strings_.cello_
#     c1_1_1
#   end
class Alda::Part < Alda::Event
	
	##
	# The names of the part. To be joined with +/+ as delimiter.
	attr_accessor :names
	
	##
	# The nickname of the part. +nil+ if none.
	attr_accessor :arg
	
	##
	# :call-seq:
	#   new(names, arg=nil) -> Alda::Part
	#
	# Creates an Alda::Part.
	def initialize names, arg = nil
		super()
		@names = names.map { Alda::Utils.snake_to_slug _1 }
		@arg = arg
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		result = @names.join ?/
		result.concat " \"#{@arg}\"" if @arg
		result.concat ?:
	end
	
	##
	# :call-seq:
	#   part.(component)_() -> Alda::EventContainer or Alda::Part
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
			arg = args.first.tap &:detach_from_parent
			detach_from_parent
			container = Alda::EventContainer.new Alda::Sequence.join(self, arg), @parent
			@parent.events.push container
			container
		else
			@container || self
		end
	end
	
	##
	# :call-seq:
	#   part == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::Part
	# and has the same #names and #arg as +part+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::Part) && @names == other.names && @arg == other.arg
	end
end

##
# A voice event. An Alda::EventContainer containing an
# Alda::Voice can be created using event list sugar.
# See Alda::EventList#method_missing.
#
#   Alda::Score.new do
#     piano_ v1 c d e f v2 e f g a
#   end
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
		super()
		@num = num
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		?V + num + ?:
	end
	
	##
	# :call-seq:
	#   voice == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::Voice
	# and has the same #num as +voice+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::Voice) && @num == other.num
	end
end

##
# A CRAM event.
# Includes Alda::EventList.
#
# An Alda::EventContainer containing an Alda::Cram
# can be created using event list sugar.
# See Alda::EventList#method_missing.
#
# The duration of a cram event can be specified
# just like that of an Alda::Note.
#
#   Alda::Score.new do
#     piano_ c3 t4 { c2 d4 e f }; g2
#   end
class Alda::Cram < Alda::Event
	include Alda::EventList
	
	##
	# The string representing the duration of the CRAM.
	attr_accessor :duration
	
	##
	# There is an event list sugar invoking this method,
	# see Alda::EventList#method_missing.
	#
	# +block+ is to be passed with the CRAM object as +self+.
	#
	#   Alda::Score.new { piano_; t8 { a; b }}
	def initialize duration, &block
		@duration = duration
		super &block
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		"{#{events_alda_codes}}#@duration"
	end
	
	##
	# :call-seq:
	#   cram == other -> true or false
	#
	# Overrides Alda::EventList#==.
	# Returns true if the super method returns true and +other+
	# has the same #duration as +cram+ (using <tt>==</tt>).
	def == other
		super && @duration == other.duration
	end
end

##
# A marker event. An Alda::EventContainer containing an
# Alda::Marker can be created using event list sugar.
# See Alda::EventList#method_missing.
#
# It should be used together with Alda::AtMarker.
#
#   Alda::Score.new do
#     piano_ v1 c d _here e2 v2 __here c4 d e2
#   end
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
		super()
		@name = Alda::Utils.snake_to_slug name
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		?% + @name
	end
	
	##
	# :call-seq:
	#   marker == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::Marker
	# and has the same #name as +marker+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::Marker) && @name == other.name
	end
end

##
# An at-marker event. An Alda::EventContainer containing
# an Alda::AtMarker can be created using event list sugar.
# See Alda::EventList#method_missing.
#
# It should be used together with Alda::Marer.
# For examples, see Alda::Marker.
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
		super()
		@name = Alda::Utils.snake_to_slug name
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		?@ + @name
	end
	
	##
	# :call-seq:
	#   at_marker == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::AtMarker
	# and has the same #name as +at_marker+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::AtMarker) && @name == other.name
	end
end

##
# A sequence event. Includes Alda::EventList.
#
# An Alda::EventContainer containing
# an Alda::Sequence can be created using event list sugar.
# See Alda::EventList#method_missing.
#
#   Alda::Score.new do
#     p s{ c; d; e; f }.event.class # => Alda::Sequence
#   end
#
# There is also a special sequence sugar.
#
#   Alda::Score.new do
#     p((c d e f).event.class) # => Alda::Sequence
#   end
#
# The effects of the two examples above are technically the same
# although actually the generated list of events are slightly different.
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
			##
			# Overrides Array#flatten.
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
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		"[#{events_alda_codes}]"
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
				while event.is_a?(Alda::EventContainer) && event.count == 1 && event.labels.empty?
					event = event.event
				end
				event.is_a?(Alda::Sequence) ? event.events : event
			end.flatten
		end
	end
end

##
# A set-variable event. Includes Alda::EventList.
#
# An Alda::EventContainer containing an Alda::SetVariable
# can be derived using event list sugar.
# See Alda::EventList#method_missing.
#
# There are several equivalent means of setting variable.
# Some of them can be ambiguous with Alda::InlineLisp or
# Alda::GetVariable, but it is intelligently chosen.
#
#   Alda::Score.new do
#     p var.event.class               # => Alda::InlineLisp
#     p((var c d e f).event.class)    # => Alda::SetVariable
#     p var { c d e f }.event.class   # => Alda::SetVariable
#     p((var__ c d e f).event.class)  # => Alda::SetVariable
#     p var__ { c d e f }.event.class # => Alda::SetVariable
#     p((var c d e f).event.class)    # => Alda::Sequence
#     p var.event.class               # => Alda::GetVariable
#     p var(1).event.class            # => Alda::InlineLisp
#   end
class Alda::SetVariable < Alda::Event
	include Alda::EventList
	
	##
	# The name of the variable.
	attr_accessor :name
	
	##
	# :call-seq:
	#   new(name, *events, &block) -> Alda::SetVariable
	#
	# Creates an Alda::SetVariable.
	def initialize name, *events, &block
		@name = name.to_sym
		@events = events
		super &block
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Specially, the returned value ends with a newline "\\n".
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		"#@name = #{events_alda_codes}\n"
	end
	
	##
	# See Alda::Event#on_contained.
	def on_contained
		super
		@parent.variables.add @name
		@events.detach_from_parent [self.class]
		@events.each { _1.parent = self if _1.is_a? Alda::Event }
	end
	
	##
	# :call-seq:
	#   set_variable == other -> true or false
	#
	# Overrides Alda::EventList#==.
	# Returns true if the super method returns true and +other+
	# has the same #name as +set_variable+ (using <tt>==</tt>).
	def == other
		super && @name == other.name
	end
end

##
# A get-variable event. An Alda::EventContainer containing
# an Alda::GetVariable can be derived using event list sugar.
# See Alda::EventList#method_missing.
#
# This can be ambiguous with Alda::SetVariable and
# Alda::InlineLisp. For examples, see Alda::SetVariable.
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
		super()
		@name = name
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		@name.to_s
	end
	
	##
	# :call-seq:
	#   get_variable == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::GetVariable
	# and has the same #name as +get_variable+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::GetVariable) && @name == other.name
	end
end

##
# A lisp identifier event. An Alda::EventContainer containing
# an Alda::Lisp
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
		super()
		@name = Alda::Utils.snake_to_slug name
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		@name
	end
	
	##
	# :call-seq:
	#   lisp_identifier == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::LispIdentifier
	# and has the same #name as +lisp_identifier+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::LispIdentifier) && @name == other.name
	end
end

##
# A special event that contains raw \Alda codes.
# This is a walkaround for the absence of <tt>alda-code</tt> function in \Alda 2
# ({alda-lang/alda#379}[https://github.com/alda-lang/alda/issues/379]).
# You can use Alda::EventList#raw to add an Alda::Raw event to the event list.
class Alda::Raw < Alda::Event
	
	##
	# The raw \Alda codes.
	attr_accessor :contents
	
	##
	# :call-seq:
	#   new(code) -> Alda::Raw
	#
	# Creates an Alda::Raw.
	def initialize contents
		super()
		@contents = contents
	end
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# Overrides Alda::Event#to_alda_code.
	def to_alda_code
		@contents
	end
	
	##
	# :call-seq:
	#   raw == other -> true or false
	#
	# Overrides Alda::Event#==.
	# Returns true if +other+ is an Alda::Raw
	# and has the same #contents as +raw+ (using <tt>==</tt>).
	def == other
		super || other.is_a?(Alda::Raw) && @contents == other.contents
	end
end
