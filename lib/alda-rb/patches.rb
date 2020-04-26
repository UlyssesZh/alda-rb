require 'stringio'

class Array
	
	def to_alda_code
		"[#{map(&:to_alda_code).join ' '}]"
	end
	
	def detach_from_parent
		reverse_each &:detach_from_parent
	end
end

class Hash
	
	def to_alda_code
		"[#{map(&:to_alda_code).join ' '}]"
	end
	
	def detach_from_parent
		each.reverse_each &:detach_from_parent
	end
end

class String
	
	def to_alda_code
		dump
	end
	
	def detach_from_parent
	end
end

class Symbol
	
	def to_alda_code
		?: + to_s
	end
	
	def detach_from_parent
	end
end

class Numeric
	
	def to_alda_code
		inspect
	end
	
	def detach_from_parent
	end
end

class Range
	
	def to_alda_code
		"#{first}-#{last}"
	end
	
	def detach_from_parent
	end
end

class TrueClass
	
	def to_alda_code
		'true'
	end
	
	def detach_from_parent
	end
end

class FalseClass
	
	def to_alda_code
		'false'
	end
	
	def detach_from_parent
	end
end

class NilClass
	
	def to_alda_code
		'nil'
	end
	
	def detach_from_parent
	end
end

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
