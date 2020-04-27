require 'colorize'
require 'irb/ruby-lex'
require 'json'
require 'readline'
require 'stringio'

##
# :call-seq:
#   repl() -> nil
#
# Start a REPL session.
def Alda.repl
	Alda::REPL.new.run
end

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
# the executed codes. Use +p+ if you want.
#
# +Interrupt+ and +SystemExit+ exceptions are rescued and
# will not cause the process terminating.
# +exit+ terminates the \REPL session instead of the process.
#
# To start an \REPL session in a ruby program, use Alda::repl.
# To start an \REPL session conveniently from command line,
# run command <tt>ruby -ralda-rb -e "Alda.repl"</tt>.
#
#   $ ruby -ralda-rb -e "Alda.repl"
#   > puts status
#   [27713] Server up (2/2 workers available, backend port: 33245)
#   > piano_ c d e f
#   [piano: c d e f]
#   > 5.times do
#   > c
#   > end
#   c c c c c
#   > puts history
#   [piano: c d e f]
#   c c c c c
#   > play
#   > save 'temp.alda'
#   > puts `cat temp.alda`
#   [piano: c d e f]
#   c c c c c
#   > system 'rm temp.alda'
#   > exit
class Alda::REPL
	
	##
	# The score object used in Alda::REPL.
	#
	# Includes Alda, so it can refer to alda commandline.
	#
	# When you are in an \REPL session, you are actually
	# in an instance of this class,
	# so you can call the instance methods down here
	# when you play with an \REPL.
	class TempScore < Alda::Score
		include Alda
		
		Score.instance_methods(false).each do |meth|
			define_method meth, Score.instance_method(meth)
		end
		
		def initialize session
			super()
			@session = session
		end
		
		def to_s
			history
		end
		
		def history
			@session.history.to_s
		end
		
		def clear_history
			@session.clear_history
		end
		
		def get_binding
			binding
		end
		
		def score
			puts history
		end
		
		def map
			puts JSON.generate JSON.parse(parse),
			                   indent: '  ', space: ' ', object_nl: ?\n, array_nl: ?\n
		end
		
		alias quit exit
		alias new clear_history
	end
	
	##
	# The history.
	attr_reader :history
	
	##
	# :call-seq:
	#   new() -> Alda::REPL
	#
	# Creates a new Alda::REPL.
	def initialize
		@score = TempScore.new self
		@binding = @score.get_binding
		@lex = RubyLex.new
		@history = StringIO.new
	end
	
	##
	# :call-seq:
	#   run() -> nil
	#
	# Runs the session.
	# Includes the start, the main loop, and the termination.
	def run
		start
		while code = rb_code
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
		begin
			buf = Readline.readline '> '.green, true
			return unless buf
			result.concat buf, ?\n
			ltype, indent, continue, block_open = @lex.check_state result
		rescue Interrupt
			$stdout.puts
			retry
		end while ltype || indent.nonzero? || continue || block_open
		result
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
		rescue StandardError, ScriptError => e
			$stderr.print e.full_message
			return true
		rescue Interrupt
			return true
		rescue SystemExit
			return false
		end
		code = @score.events_alda_codes
		unless code.empty?
			$stdout.puts code.yellow
			play_score code
		end
		true
	end
	
	##
	# :call-seq:
	#   try_command() { ... } -> obj
	#
	# Tries to run the block and rescue Alda::CommandLineError.
	def try_command
		begin
			yield
		rescue Alda::CommandLineError => e
			puts e.message.red
		end
	end
	
	##
	# :call-seq:
	#   play_score(code) -> nil
	#
	# Plays the score by sending +code+ to command line alda.
	def play_score code
		try_command do
			Alda.play code: code, history: @history
			@history.puts code
		end
	end
	
	##
	# :call-seq:
	#   terminate() -> nil
	#
	# Terminates the REPL session.
	# Currently just clears #history.
	def terminate
		clear_history
	end
	
	##
	# :call-seq:
	#   clear_history() -> nil
	#
	# Clears #history.
	def clear_history
		@history = StringIO.new
		nil
	end
end
