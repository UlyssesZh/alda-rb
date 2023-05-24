##
# Some useful functions.
module Alda::Utils
	module_function
	
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
end
