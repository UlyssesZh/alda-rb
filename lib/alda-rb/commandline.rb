module Kernel
	# Runs the alda command.
	# Does not capture output.
	# @example
	#   alda 'version'
	#   alda 'play', '-c', 'piano: a'
	#   alda 'repl'
	def alda *args
		system Alda.executable, *args
	end
end

module Alda
	
	# The array of available subcommands of alda executable.
	#
	# Alda# is able to invoke +alda+ at the command line.
	# The subcommand is the name of the method invoked upon Alda#.
	#
	# The first argument (a hash) is interpreted as the options.
	# The keyword arguments are interpreted as the subcommand options.
	#
	# The return value is the string output by the command in STDOUT.
	#
	# If the exit code is nonzero, a CommandLineError# is raised.
	# @example
	#   Alda.version
	#   # => "Client version: 1.4.0\nServer version: [27713] 1.4.0\n"
	#   Alda.parse code: 'bassoon: o3 c'
	#   # => "{\"chord-mode\":false,\"current-instruments\":...}\n"
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
	
	# The path to the +alda+ executable.
	#
	# The default value is <tt>"alda"</tt>,
	# which will depend on your PATH.
	singleton_class.attr_accessor :executable
	@executable = 'alda'
	
	singleton_class.attr_reader :options
	@options = {}
	
	# @return Whether the alda server is up.
	def up?
		status.include? 'up'
	end
	
	# @return Whether the alda server is down.
	def down?
		status.include? 'down'
	end
	
	module_function :up?, :down?, *COMMANDS
	
	# Sets the options of alda command.
	# Not the subcommand options.
	def self.[] **opts
		@options.merge! opts
		self
	end
	
	# Clears the command line options.
	def self.clear_options
		@options.clear
	end
end
