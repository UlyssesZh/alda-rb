##
# The error is raised when +alda+ command exits with nonzero status.
class Alda::CommandLineError < StandardError
	
	##
	# The <tt>Process::Status</tt> object representing the status of
	# the process that runs +alda+ command.
	attr_reader :status
	
	##
	# The port on which the problematic alda server runs.
	#
	#   begin
	#     Alda[port: 1108].play code: 'y'
	#   rescue CommandLineError => e
	#     e.port # => 1108
	#   end
	attr_reader :port
	
	##
	# :call-seq:
	#   new(status, msg=nil) -> Alda::CommandLineError
	#
	# Create a Alda::CommandLineError object.
	# +status+ is the status of the process running +alda+ command.
	# +msg+ is output of +alda+ command. port# info is extracted from +msg+.
	def initialize status, msg = nil
		if match = msg&.match(/^\[(?<port>\d+)\]\sERROR\s(?<message>.*)$/)
			super match[:message]
			@port = match[:port].to_i
		else
			super msg
			@port = nil
		end
		@status = status
	end
end

##
# This error is raised when one tries to run commands that are not available for the generation
# of \Alda specified by Alda::generation.
#
#   Alda.v1!
#   Alda.import # (GenerationError)
class Alda::GenerationError < StandardError
	
	##
	# The actual generation that was set by Alda::generation when the error occurs.
	attr_reader :generation
	
	##
	# The generations that could have been set to avoid the error.
	# An Array.
	attr_reader :fine_generations
	
	##
	# :call-seq:
	#   new(fine_generations) -> Alda::GenerationError
	#
	# Creates a Alda::GenerationError object.
	def initialize fine_generations
		super "bad Alda generation for this action; good ones are #{fine_generations}"
		@generation = Alda.generation
		@fine_generations = fine_generations
	end
end

##
# This error is raised when one tries to
# append events in an Alda::EventList in a wrong order.
#
#   Alda::Score.new do
#     motif = f4 f e e d d c2
#     g4 f e d c2 # It commented out, error will not occur
#     c4 c g g a a g2 motif # (OrderError)
#   end
class Alda::OrderError < StandardError
	
	##
	# The expected element gotten if it is of the correct order.
	#
	# See #got
	#
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
	
	##
	# The actually gotten element.
	# For an example, see #expected.
	attr_reader :got
	
	##
	# :call-seq:
	#   new(expected, got) -> Alda::OrderError
	#
	# Creates a Alda::OrderError object.
	def initialize expected, got
		super 'events are out of order'
		@expected = expected
		@got = got
	end
end
