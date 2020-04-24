require 'colorize'
require 'irb/ruby-lex'
require 'json'
require 'readline'
require 'stringio'

# Start a REPL session.
def Alda.repl
	Alda::REPL.new.run
end

# An encapsulation for the REPL session for alda-rb.
class Alda::REPL
	
	# The score object used in REPL.
	# Includes Alda#, so it can refer to alda commandline.
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
	
	# The history.
	attr_reader :history
	
	# Initialization.
	def initialize
		@score = TempScore.new self
		@binding = @score.get_binding
		@lex = RubyLex.new
		@history = StringIO.new
	end
	
	# Runs the session. Includes the start, the main loop, and the termination.
	def run
		start
		while code = rb_code
			break unless process_rb_code code
		end
		terminate
	end
	
	# Starts the session.
	def start
	end
	
	# Reads the next Ruby codes input in the REPL session.
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
	
	# Processes the Ruby codes read.
	# Sending it to a score and sending the result to alda.
	# @return +true+ for continue looping, +false+ for breaking the loop.
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
	
	# Tries to run the block and rescue CommandLineError#.
	def try_command # :block:
		begin
			yield
		rescue Alda::CommandLineError => e
			puts e.message.red
		end
	end
	
	# Plays the score.
	def play_score code
		try_command do
			Alda.play code: code, history: @history
			@history.puts code
		end
	end
	
	# Terminates the REPL session.
	def terminate
		clear_history
	end
	
	# Clears the history.
	def clear_history
		@history = StringIO.new
	end
end
