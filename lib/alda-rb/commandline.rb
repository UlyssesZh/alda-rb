module Kernel
	##
	# :call-seq:
	#   alda(*args) -> true or false
	#
	# Runs the alda command.
	# Does not capture output.
	#
	#   alda 'version'
	#   alda 'play', '-c', 'piano: a'
	#   alda 'repl'
	#
	# Returns whether the exit status is +0+.
	def alda *args
		system Alda.executable, *args
	end
end

module Alda
	
	##
	# The array of available subcommands of alda executable.
	#
	# Alda is able to invoke +alda+ at the command line.
	# The subcommand is the name of the method invoked upon Alda.
	#
	# The keyword arguments are interpreted as the subcommand options.
	# To specify the command options, use ::[].
	#
	# The return value is the string output by the command in STDOUT.
	#
	# If the exit code is nonzero, an Alda::CommandLineError is raised.
	#
	#   Alda.version
	#   # => "Client version: 1.4.0\nServer version: [27713] 1.4.0\n"
	#   Alda.parse code: 'bassoon: o3 c'
	#   # => "{\"chord-mode\":false,\"current-instruments\":...}\n"
	#
	# The available commands are: +help+, +update+, +repl+, +up+,
	# +start_server+, +init+, +down+, +stop_server+, +downup+, +restart_server+,
	# +list+, +status+, +version+, +play+, +stop+, +parse+, +instruments+, and
	# +export+.
	COMMANDS = %i[
		help update repl up start_server init down stop_server
		downup restart_server list status version play stop parse
		instruments export
	].freeze
	
	COMMANDS.each do |command|
		define_method command do |*args, **opts|
			block = ->key, val do
				next unless val
				args.push "--#{key.to_s.tr ?_, ?-}"
				args.push val.to_s unless val == true
			end
			# executable
			args.unshift Alda.executable
			args.map! &:to_s
			# options
			Alda.options.each &block
			# subcommand
			args.push command.to_s
			# subcommand options
			opts.each &block
			# subprocess
			IO.popen(args, &:read).tap do
				raise CommandLineError.new $?, _1 if $?.exitstatus.nonzero?
			end
		end
	end
	
	class << self
		
		##
		# The path to the +alda+ executable.
		#
		# The default value is <tt>"alda"</tt>,
		# which will depend on your +PATH+.
		attr_accessor :executable
		
		##
		# The commandline options set using ::[].
		# Not the subcommand options.
		# Clear it using ::clear_options.
		attr_reader :options
		
		##
		# :call-seq:
		#   Alda[**opts] -> self
		#
		# Sets the options of alda command.
		# Not the subcommand options.
		#
		#   Alda[port: 1108].up # => "[1108] ..."
		#   Alda.status # => "[1108] ..."
		#
		# Further set options will be merged.
		# The options can be seen by ::options.
		# To clear them, use ::clear_options.
		def [] **opts
			@options.merge! opts
			self
		end
		
		##
		# :call-seq:
		#   clear_options() -> nil
		#
		# Clears the command line options.
		# Makes ::options an empty Array.
		def clear_options
			@options.clear
		end
	end
	
	@executable = 'alda'
	@options = {}
	
	##
	# :call-seq:
	#   up?() -> true or false
	#
	# Whether the alda server is up.
	def up?
		status.include? 'up'
	end
	
	##
	# :call-seq:
	#   down? -> true or false
	#
	# Whether the alda server is down.
	def down?
		status.include? 'down'
	end
	
	module_function :up?, :down?, *COMMANDS
	
end
