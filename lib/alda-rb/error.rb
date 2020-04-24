# The error is raised when one tries to
# run a non-existing subcommand of +alda+.
class Alda::CommandLineError < StandardError
	
	# The <tt>Process::Status</tt> object representing the status of
	# the process that runs +alda+ command.
	attr_reader :status
	
	# The port on which the problematic Alda server runs.
	# @example
	#   begin
	#     Alda.play({port: 1108}, code: "y")
	#   rescue CommandLineError => e
	#     e.port # => 1108
	#   end
	attr_reader :port
	
	# Create a CommandLineError# object.
	# @param status The status of the process running +alda+ command.
	# @param msg The exception message.
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

# This error is raised when one tries to
# append events in an EventList# in a wrong order.
# @example
#   Alda::Score.new do
#     motif = f4 f e e d d c2
#     g4 f e d c2 # It commented out, error will not occur
#     c4 c g g a a g2 motif # (OrderError)
#   end
class Alda::OrderError < StandardError
	
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
