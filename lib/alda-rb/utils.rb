##
# Some useful functions.
module Alda::Utils
	
	##
	# :call-seq:
	#   warn(message) -> nil
	#
	# Prints a warning message to standard error, appended by a newline.
	# The message is prefixed with the filename and lineno of the caller
	# (the lowest level where the file is not an alda-rb source file).
	def warn message
		location = caller_locations.find { !_1.path.start_with? __dir__ }
		Warning.warn "#{location.path}:#{location.lineno}: #{message}\n"
	end
	
	##
	# :call-seq:
	#   win_platform? -> true or false
	#
	# Returns whether the current platform is Windows.
	def win_platform?
		Gem.win_platform?
	end
	
	##
	# :call-seq:
	#   snake_to_slug(sym) -> String
	#
	# Converts a snake_case Symbol to a slug-case String.
	# The inverse of ::slug_to_snake.
	def snake_to_slug sym
		sym.to_s.gsub ?_, ?-
	end
	
	##
	# :call-seq:
	#   slug_to_snake(str) -> Symbol
	#
	# Converts a slug-case String to a snake_case Symbol.
	# The inverse of ::snake_to_slug.
	def slug_to_snake str
		str.to_s.gsub(?-, ?_).to_sym
	end
	
	module_function :warn, :win_platform?, :snake_to_slug, :slug_to_snake
end
