require 'colorize'
require 'irb/ruby-lex'
require 'json'
require 'reline'
require 'stringio'
require 'bencode'
require 'socket'

##
# An instance of this class is an \REPL session.
#
# It provides an Alda::REPL::TempScore for you to operate on.
# To see what methods you can call in an \REPL session,
# see instance methods of Alda::REPL::TempScore.
#
# The session uses "> " to indicate your input.
# Your input should be ruby codes, and the codes will be
# sent to an Alda::REPL::TempScore and executed.
#
# After executing the ruby codes, if the score is not empty,
# it is played, and the translated alda codes are printed.
#
# Note that every time your ruby codes input is executed,
# the score is cleared beforehand. To check the result of
# your previous input, run <tt>puts history</tt>.
#
# Unlike \IRB, this \REPL does not print the result of
# the executed codes. Use +p+ or +puts+ if you want.
#
# +Interrupt+ and +SystemExit+ exceptions are rescued and
# will not cause the process terminating.
# +exit+ terminates the \REPL session instead of the process.
#
# To start an \REPL session in a ruby program, use #run.
# To start an \REPL session conveniently from command line,
# run command <tt>alda-irb</tt>.
# For details about this command line tool, run <tt>alda-irb --help</tt>.
#
#   $ alda-irb
#   > p processes.last
#   {:id=>"dus", :port=>34317, :state=>nil, :expiry=>nil, :type=>:repl_server}
#   > piano_; c d e f
#   piano: [c d e f]
#   > 5.times do
#   .   c
#   >   end
#   c c c c c
#   > score_text
#   piano: [c d e f]
#   c c c c c
#   > play
#   Playing...
#   > save 'temp.alda'
#   > puts `cat temp.alda`
#   piano: [c d e f]
#   c c c c c
#   > system 'rm temp.alda'
#   > exit
#
# Notice that there is a significant difference between \Alda 1 \REPL and \Alda 2 \REPL.
# In short, \Alda 2 has a much more powerful \REPL than \Alda 1,
# so it dropped the <tt>--history</tt> option in the <tt>alda play</tt> command line interface
# ({alda-lang/alda#367}[https://github.com/alda-lang/alda/issues/367]).
# It has an nREPL server, and this class simply functions by sending messages to the nREPL server.
# However, for \Alda 1, this class maintains necessary information
# in the memory of the Ruby program,
# and the \REPL is implemented by repeatedly running <tt>alda play</tt> in command line.
# Therefore, this class functions differently for \Alda 1 and \Alda 2
# and you thus should not modify Alda::generation during an \REPL session.
#
# It is also possible to use this class as a Ruby wrapper of APIs of the \Alda nREPL server
# in \Alda 2.
# In this usage, you never need to call #run, and you call #message or #raw_message instead.
#
#   repl = Alda::REPL.new
#   repl.message :eval_and_play, code: 'piano: c d e f' # => nil
#   repl.message :eval_and_play, code: 'g a b > c' # => nil
#   repl.message :score_text # => "piano: [c d e f]\ng a b > c\n"
#   repl.message :eval_and_play, code: 'this will cause an error' # (raises Alda::NREPLServerError)
class Alda::REPL
	
	##
	# The score object used in Alda::REPL.
	#
	# Includes Alda, so it can refer to alda commandline.
	# However, the methods Alda::Score#play, Alda::Score#parse and Alda::Score#export
	# are still retained instead of being overridden by the included module.
	#
	# When you are in an \REPL session, you are actually
	# in an instance of this class,
	# so you can call the instance methods down here
	# when you play with an \REPL.
	class TempScore < ::Alda::Score
		include Alda
		
		%i[play parse export].each do |meth|
			define_method meth, Alda::Score.instance_method(meth)
		end
		
		##
		# :call-seq:
		#   new(session) -> TempScore
		#
		# Creates a new TempScore for the given \REPL session specified by +session+.
		# It is called in Alda::REPL::new.
		def initialize session
			super()
			@session = session
		end
		
		##
		# :call-seq:
		#   to_s -> String
		#
		# Overrides Alda::Score#to_s.
		# Returns the history.
		#
		#   $ alda-irb
		#   > harmonica_; a b c
		#   harmonica: [a b c]
		#   > guitar_; c g e
		#   guitar: [c g e]
		#   > p to_s
		#   "harmonica: [a b c]\nguitar: [c g e]\n"
		def to_s
			@session.history
		end
		
		##
		# :call-seq:
		#   clear_history() -> nil
		#
		# Clears all the modifications that have been made to the score
		# and start a new one.
		# See #score for an example.
		def clear_history
			@session.clear_history
		end
		alias new clear_history
		alias new_score clear_history
		
		##
		# :call-seq:
		#   get_binding() -> Binding
		#
		# Returns a Binding for the instance eval local environment of this score.
		# Different callings of this method will return different bindings,
		# and they do not share local variables.
		# This method is called in Alda::REPL::new.
		#
		#   $ alda-irb
		#   > p get_binding.receiver == self
		#   true
		def get_binding
			binding
		end
		
		##
		# :call-seq:
		#   score() -> nil
		#
		# Print the history (all \Alda code of the score).
		#
		#   $ alda-irb
		#   > violin_; a b
		#   violin: [a b]
		#   > score
		#   violin: [a b]
		#   > clear_history
		#   > score
		#   > viola_; c
		#   viola: c
		#   > score
		#   viola: c
		def score
			print @session.color ? @session.history.blue : @session.history
			nil
		end
		alias score_text score
		
		##
		# :call-seq:
		#   map() -> nil
		#
		# Prints a data representation of the score.
		# This is the output that you get when you call Alda::Score#parse.
		def map
			json = Alda.v1? ? parse : @session.message(:score_data)
			json = JSON.generate JSON.parse(json), indent: '  ', space: ' ', object_nl: ?\n, array_nl: ?\n
			puts @session.color ? json.blue : json
		end
		alias score_data map
		
		##
		# :call-seq:
		#   score_events() -> nil
		#
		# Prints the parsed events output of the score.
		# This is the output that you get when you call Alda::Score#parse with <tt>output: :events</tt>.
		def score_events
			json = Alda.v1? ? parse(output: :events) : @session.message(:score_events)
			json = JSON.generate JSON.parse(json), indent: '  ', space: ' ', object_nl: ?\n, array_nl: ?\n
			puts @session.color ? json.blue : json
		end
		
		alias quit exit
	end
	
	##
	# The host of the nREPL server. Only useful in \Alda 2.
	attr_reader :host
	
	##
	# The port of the nREPL server. Only useful in \Alda 2.
	attr_reader :port
	
	##
	# Whether the output should be colored.
	attr_accessor :color
	
	##
	# Whether a preview of what \Alda code will be played everytime you input ruby codes.
	attr_accessor :preview
	
	##
	# Whether to use Reline for input.
	# When it is false, the \REPL session will be less buggy but less powerful.
	attr_accessor :reline
	
	##
	# :call-seq:
	#   new(**opts) -> Alda::REPL
	#
	# Creates a new Alda::REPL.
	# The parameter +color+ specifies whether the output should be colored (sets #color).
	# The parameter +preview+ specifies whether a preview of what \Alda code will be played
	# everytime you input ruby codes (sets #preview).
	# The parameter +reline+ specifies whether to use Reline for input.
	#
	# The +opts+ are passed to the command line of <tt>alda repl</tt>.
	# Available options are +host+, +port+, etc.
	# Run <tt>alda repl --help</tt> for more info.
	# If +port+ is specified and +host+ is not or is specified to be <tt>"localhost"</tt>
	# or <tt>"127.0.0.1"</tt>, then this method will try to connect to an existing
	# \Alda REPL server.
	# A new one will be started only if no existing server is found.
	#
	# The +opts+ are ignored in \Alda 1.
	def initialize color: true, preview: true, reline: true, **opts
		@score = TempScore.new self
		@binding = @score.get_binding
		# IRB once changed the API of RubyLex#initialize. Take care of that.
		@lex = RubyLex.new *(RubyLex.instance_method(:initialize).arity == 0 ? [] : [@binding])
		@color = color
		@preview = preview
		@reline = reline
		setup_repl opts
	end
	
	##
	# :call-seq:
	#   setup_repl(opts) -> nil
	#
	# Sets up the \REPL session.
	# This method is called in ::new.
	# After you #terminate the session,
	# you cannot use the \REPL anymore unless you call this method again.
	def setup_repl opts
		if Alda.v1?
			@history = StringIO.new
		else
			@port = (opts.fetch :port, -1).to_i
			@host = opts.fetch :host, 'localhost'
			unless @port.positive? && %w[localhost 127.0.0.1].include?(@host) &&
			       Alda.processes.any? { _1[:port] == @port && _1[:type] == :repl_server }
				Alda.env(ALDA_DISABLE_SPAWNING: :no) { @nrepl_pipe = Alda.pipe :repl, **opts, server: true }
				/nrepl:\/\/[a-zA-Z0-9._\-]+:(?<port>\d+)/ =~ @nrepl_pipe.gets
				@port = port.to_i
				Process.detach @nrepl_pipe.pid
			end
			@socket = TCPSocket.new @host, @port
			@bencode_parser = BEncode::Parser.new @socket
		end
		nil
	end
	
	##
	# :call-seq:
	#   raw_message(contents) -> Hash
	#
	# Sends a message to the nREPL server and returns the response.
	# The parameter +contents+ is a Hash or a JSON string.
	#
	#   repl = Alda::REPL.new
	#   repl.raw_message op: 'describe' # => {"ops"=>...}
	def raw_message contents
		Alda::GenerationError.assert_generation [:v2]
		contents = JSON.parse contents if contents.is_a? String
		@socket.write contents.bencode
		@bencode_parser.parse!
	end
	
	##
	# :call-seq:
	#   message(op, **params) -> String or Hash
	#
	# Sends a message to the nREPL server with the following format,
	# with +op+ being the operation name (the +op+ field in the message),
	# and +params+ being the parameters (other fields in the message).
	# Then, this method analyzes the response.
	# If there is an error, raises Alda::NREPLServerError.
	# Otherwise, if the response contains only one field, return the content of that field (a String).
	# Otherwise, return the whole response as a Hash.
	#
	#   repl = Alda::REPL.new
	#   repl.message :eval_and_play, code: 'piano: c d e f' # => nil
	#   repl.message :eval_and_play, code: 'g a b > c' # => nil
	#   repl.message :score_text # => "piano: [c d e f]\ng a b > c\n"
	#   repl.message :eval_and_play, code: 'this will cause an error' # (raises Alda::NREPLServerError)
	def message op, **params
		result = raw_message op: Alda::Utils.snake_to_slug(op), **params
		result.transform_keys! { Alda::Utils.slug_to_snake _1 }
		if (status = result.delete :status).include? 'error'
			raise Alda::NREPLServerError.new @host, @port, result.delete(:problems), status
		end
		case result.size
		when 0 then nil
		when 1 then result.values.first
		else result
		end
	end
	
	##
	# :call-seq:
	#   run() -> nil
	#
	# Runs the session.
	# Includes the start (#start), the main loop, and the termination (#terminate).
	def run
		start
		while code = rb_code
			next if code.empty?
			break unless process_rb_code code
		end
		terminate
	end
	
	##
	# :call-seq:
	#   start() -> nil
	#
	# Starts the session. Currently does nothing.
	def start
	end
	
	##
	# :call-seq:
	#   rb_code() -> String
	#
	# Reads and returns the next Ruby codes input in the \REPL session.
	# It can intelligently continue reading if the code is not complete yet.
	def rb_code
		result = ''
		indent = 0
		begin
			result.concat readline(indent).tap { return unless _1 }, ?\n
			# IRB once changed the API of RubyLex#check_state. Take care of that.
			opts = @lex.method(:check_state).arity.positive? ? {} : { context: @binding }
			ltype, indent, continue, block_open = @lex.check_state result, **opts
		rescue Interrupt
			$stdout.puts
			return ''
		end while ltype || indent.nonzero? || continue || block_open
		result
	end
	
	##
	# :call-seq:
	#   readline(indent = 0) -> String
	#
	# Prompts the user to input a line.
	# The parameter +indent+ is the indentation level.
	# Twice the number of spaces is already in the input field before the user fills in
	# if #reline is true.
	# The prompt hint is different for zero +indent+ and nonzero +indent+.
	# Returns the user input.
	def readline indent = 0
		prompt = indent.nonzero? ? '. ' : '> '
		prompt = prompt.green if @color
		if @reline
			Reline.pre_input_hook = -> do
				Reline.insert_text '  ' * indent
				Reline.redisplay
				Reline.pre_input_hook = nil
			end
			Reline.readline prompt, true
		else
			$stdout.print prompt
			$stdout.flush
			$stdin.gets chomp: true
		end
	end
	
	##
	# :call-seq:
	#   process_rb_code(code) -> true or false
	#
	# Processes the Ruby codes read.
	# Sends it to a score and sends the result to command line alda.
	# Returns +false+ for breaking the \REPL main loop, +true+ otherwise.
	def process_rb_code code
		@score.clear
		begin
			@binding.eval code
		rescue StandardError, ScriptError, Interrupt => e
			$stderr.print e.full_message
			return true
		rescue SystemExit
			return false
		end
		code = @score.events_alda_codes
		unless code.empty?
			$stdout.puts @color ? code.yellow : code
			try_command { play_score code }
		end
		true
	end
	
	##
	# :call-seq:
	#   try_command() { ... } -> obj
	#
	# Run the block.
	# In \Alda 1, catches Alda::CommandLineError.
	# In \Alda 2, catches Alda::NREPLServerError.
	# If an error is caught, prints the error message (in red if #color is true).
	def try_command
		begin
			yield
		rescue Alda.v1? ? Alda::CommandLineError : Alda::NREPLServerError => e
			puts @color ? e.message.red : e.message
		end
	end
	
	##
	# :call-seq:
	#   play_score(code) -> nil
	#
	# Appends +code+ to the history and plays the +code+ as \Alda code.
	# In \Alda 1, plays the score by sending +code+ to command line alda.
	# In \Alda 2, sends +code+ to the nREPL server for evaluating and playing.
	def play_score code
		if Alda.v1?
			Alda.play code: code, history: @history
			@history.puts code
		else
			message :eval_and_play, code: code
		end
	end
	
	##
	# :call-seq:
	#   terminate() -> nil
	#
	# Terminates the REPL session.
	# In \Alda 1, just calls #clear_history.
	# In \Alda 2, sends a SIGINT to the nREPL server if it was spawned by the Ruby program.
	def terminate
		if Alda.v1?
			clear_history
		else
			if @nrepl_pipe
				if Alda::Utils.win_platform?
					unless IO.popen(['taskkill', '/f', '/pid', @nrepl_pipe.pid.to_s], &:read).include? 'SUCCESS'
						Alda::Warning.warn 'failed to kill nREPL server; may become zombie process'
					end
				else
					Process.kill :INT, @nrepl_pipe.pid
				end
				@nrepl_pipe.close
			end
			@socket.close
		end
	end
	
	##
	# :call-seq:
	#   history() -> String
	#
	# In \Alda 1, it is the same as an attribute reader.
	# In \Alda 2, it asks the nREPL server for its score text and returns it.
	def history
		if Alda.v1?
			@history
		else
			try_command { message :score_text }
		end
	end
	
	##
	# :call-seq:
	#   clear_history() -> nil
	#
	# In \Alda 1, clears #history.
	# In \Alda 2, askes the nREPL server to clear its history (start a new score).
	def clear_history
		if Alda.v1?
			@history = StringIO.new
		else
			try_command { message :new_score }
		end
		nil
	end
end
