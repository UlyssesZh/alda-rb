##
# Adding functions that is accessible everywhere.
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
		# The major version of the +alda+ command used.
		# Possible values: +:v1+ or +:v2+ (i.e. one of the values in Alda::GENERATIONS).
		# If you try to specify it to values other than those, an ArgumentError will be raised.
		# This affects several things due to some incompatible changes from \Alda 1 to \Alda 2.
		# You may use ::deduce_generation to automatically set it.
		attr_accessor :generation
		def generation= gen # :nodoc:
			raise ArgumentError, "bad generation: #{gen}" unless GENERATIONS.include? gen
			@generation = gen
		end
		
		##
		# :call-seq:
		#   Alda[**opts] -> self
		#
		# Sets the options of alda command.
		# Not the subcommand options.
		#
		#   # This example only works for Alda 1.
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
	@generation = :v2
	
	##
	# :call-seq:
	#   up?() -> true or false
	#
	# Whether the alda server is up.
	# Always returns true if ::generation is +:v2+.
	def up?
		generation == :v2 || status.include?('up')
	end
	
	##
	# :call-seq:
	#   down? -> true or false
	#
	# Whether the alda server is down.
	# Always returns false if ::generation is +:v2+.
	def down?
		generation != :v2 && status.include?('down')
	end
	
	##
	# :call-seq:
	#   deduce_generation -> one of Alda::GENERATIONS
	#
	# Deduce the generation of \Alda being used by running <tt>alda version</tt> in command line,
	# and then set ::generation accordingly.
	def deduce_generation
		/(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)/ =~ version
		@generation = major == '1' ? :v1 : :v2
	end
	
	module_function :up?, :down?, :deduce_generation
	
	##
	# The Array of possible values of ::generation.
	# It is just the array <tt>[:v1, :v2]</tt>
	#
	# You can use +:v1?+ and +:v2?+ to get whether the current generation is +:v1+ or +:v2+.
	# For example, <tt>Alda.v1?</tt> is the same as <tt>Alda.generation == :v1</tt>
	GENERATIONS = %i[v1 v2].freeze
	
	GENERATIONS.each do |gen|
		module_function define_method("#{gen}?") { generation == gen }
	end
	
	##
	# The available subcommands of alda executable.
	# This is a Hash, with keys being possible values of ::generation,
	# and values being an Array of symbols of the available commands of that generation.
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
	# The available commands are:
	#
	# * If ::generation is +:v1+:
	#   +help+, +update+, +repl+, +up+, +start_server+, +init+, +down+, +stop_server+,
	#   +downup+, +restart_server+, +list+, +status+, +version+, +play+, +stop+, +parse+,
	#   +instruments+, and +export+.
	# * If ::generation is +:v2+:
	#   +doctor+, +export+, +help+, +import+, +instruments+, +parse+, +play+,
	#   +ps+, +repl+, +shutdown+, +stop+, +telemetry+, +update+, and +version+.
	#
	# Trying to run a command that is not support by the current generation set by ::generation
	# will raise an Alda::GenerationError.
	COMMANDS_FOR_VERSIONS = {
		v1: %i[
			help update repl up start_server init down stop_server
			downup restart_server list status version play stop parse
			instruments export
		].freeze,
		v2: %i[
			doctor export help import instruments parse play ps repl shutdown stop
			telemetry update version
		].freeze
	}.freeze
	
	##
	# The Hash of available commands.
	# The symbols of commands are keys
	# and each value is an Array of generations where the command is available.
	COMMANDS = COMMANDS_FOR_VERSIONS.each_with_object({}) do |(gen, commands), r|
		commands.each { (r[_1] ||= []).push gen }
	end.freeze
	
	COMMANDS.each do |command, generations|
		define_method command do |*args, **opts|
			raise GenerationError.new generations unless generations.include? generation
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
			IO.popen(args, &:read).tap { raise CommandLineError.new $?, _1 if $?.exitstatus.nonzero? }
		end.tap { module_function _1 }
	end
	
end
