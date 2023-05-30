require 'stringio'

##
# Contains patches to Ruby's core classes.
class Thread
	##
	# Because \Alda 2 uses quoted lists to denote lists (vectors) of symbols,
	# we have to keep track of whether we are inside a list already
	# (because this notation is inconsistent for inner lists and outer lists).
	attr_accessor :inside_alda_list
end

##
# Contains patches to Ruby's core classes.
class Array
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# See Alda::Event#to_alda_code.
	# Behaves differently for \Alda 1 and \Alda 2 (due to
	# {a breaking change}[https://github.com/alda-lang/alda/blob/master/doc/alda-2-migration-guide.md#attribute-syntax-has-changed-in-some-cases]).
	def to_alda_code
		contents = -> { map(&:to_alda_code).join ' ' }
		if Alda.v1?
			"[#{contents.()}]"
		else
			thread = Thread.current
			if thread.inside_alda_list
				"(#{contents.()})"
			else
				thread.inside_alda_list = true
				"'(#{contents.()})".tap { thread.inside_alda_list = false }
			end
		end
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent(...)
		reverse_each { _1.detach_from_parent(...) }
	end
end

##
# Contains patches to Ruby's core classes.
class Hash
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# See Alda::Event#to_alda_code.
	# Behaves differently for \Alda 1 and \Alda 2 (due to
	# {a breaking change}[https://github.com/alda-lang/alda/blob/master/doc/alda-2-migration-guide.md#attribute-syntax-has-changed-in-some-cases]).
	def to_alda_code
		contents = -> { map { "#{_1.to_alda_code} #{_2.to_alda_code}" }.join ' ' }
		if Alda.v1?
			"{#{contents.()}}"
		else
			thread = Thread.current
			if thread.inside_alda_list
				"(#{contents.()})"
			else
				thread.inside_alda_list = true
				"'(#{contents.()})".tap { thread.inside_alda_list = false }
			end
		end
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent(...)
		each.reverse_each { _1.detach_from_parent(...) }
	end
end

##
# Contains patches to Ruby's core classes.
class String
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# See Alda::Event#to_alda_code.
	def to_alda_code
		dump
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent(...)
	end
end

##
# Contains patches to Ruby's core classes.
class Symbol
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# See Alda::Event#to_alda_code.
	def to_alda_code
		"#{Alda.v1? ? ?: : Thread.current.inside_alda_list ? '' : ?'}#{to_s}"
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent(...)
	end
end

##
# Contains patches to Ruby's core classes.
class Numeric
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# See Alda::Event#to_alda_code.
	def to_alda_code
		inspect
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent(...)
	end
end

##
# Contains patches to Ruby's core classes.
class Range
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# See Alda::Event#to_alda_code.
	def to_alda_code
		"#{first}-#{last}"
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent(...)
	end
end

##
# Contains patches to Ruby's core classes.
class TrueClass
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# See Alda::Event#to_alda_code.
	def to_alda_code
		'true'
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent(...)
	end
end

##
# Contains patches to Ruby's core classes.
class FalseClass
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# See Alda::Event#to_alda_code.
	def to_alda_code
		'false'
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent(...)
	end
end

##
# Contains patches to Ruby's core classes.
class NilClass
	
	##
	# :call-seq:
	#   to_alda_code() -> String
	#
	# See Alda::Event#to_alda_code.
	def to_alda_code
		'nil'
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent(...)
	end
end

##
# Contains patches to Ruby's core classes.
class Proc
	
	##
	# :call-seq:
	#   proc * n -> n
	#
	# Runs +self+ for +n+ times.
	def * n
		if !lambda? || arity == 1
			n.times &self
		else
			n.times { self.() }
		end
	end
end

##
# Contains patches to Ruby's core classes.
class StringIO
	
	##
	# :call-seq:
	#   to_s() -> String
	#
	# Equivalent to <tt>string</tt>.
	def to_s
		string
	end
end
