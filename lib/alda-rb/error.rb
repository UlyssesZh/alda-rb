##
# The error is raised when +alda+ command exits with nonzero status.
class Alda::CommandLineError < StandardError
	
	##
	# The <tt>Process::Status</tt> object representing the status of
	# the process that runs +alda+ command.
	attr_reader :status
	
	##
	# The port on which the problematic alda server runs.
	# This is only available for \Alda 1.
	#
	#   begin
	#     Alda[port: 1108].play code: 'y'
	#   rescue CommandLineError => e
	#     e.port # => 1108
	#   end
	def port
		Alda::GenerationError.assert_generation [:v1]
		@port
	end
	
	##
	# :call-seq:
	#   new(status, msg=nil) -> Alda::CommandLineError
	#
	# Create a Alda::CommandLineError object.
	# +status+ is the status of the process running +alda+ command (can be nil).
	# +msg+ is the output of +alda+ command. #port info is extracted from +msg+ in \Alda 1.
	def initialize status, msg = nil
		if Alda.v1? && msg && /^\[(?<port>\d+)\]\sERROR\s(?<message>.*)$/ =~ msg
			super message
			@port = port.to_i
		else
			super msg
		end
		@status = status
	end
end

##
# The error is raised when the \Alda nREPL server returns problems.
# This is only available for \Alda 2.
# See Alda::REPL#message.
class Alda::NREPLServerError < StandardError
	
	##
	# The hostname of the nREPL server.
	attr_reader :host
	
	##
	# The port of the nREPL server.
	attr_reader :port
	
	##
	# The problems returned by the nREPL server.
	# This is an Array of String.
	attr_reader :problems
	
	##
	# The status returned by the nREPL server.
	# It is an Array of Symbol.
	# Symbols must appear are +:done+, +:error+, and there may be +:unknown_op+.
	attr_reader :status
	
	##
	# :call-seq:
	#   new(host, port, problems, status) -> Alda::NREPLServerError
	#
	# Creates a Alda::NREPLServerError object.
	# Raises Alda::GenerationError if the current generation is not \Alda 2.
	def initialize host, port, problems, status
		Alda::GenerationError.assert_generation [:v2]
		@status = status.map { Alda::Utils.slug_to_snake _1 }
		if @status.include? :unknown_op
			super 'unknown operation'
		else
			super problems.join ?\n
		end
		@host = host
		@port = port
		@problems = problems
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
	
	##
	# Raises an Alda::GenerationError if the current generation is not in +fine_generations+.
	def self.assert_generation fine_generations
		raise new fine_generations unless fine_generations.include? Alda.generation
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
	# See #got.
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
