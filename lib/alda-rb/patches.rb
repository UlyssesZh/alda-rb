require 'stringio'

##
class Array
	
	##
	# See Alda::Event#to_alda_code.
	def to_alda_code
		"[#{map(&:to_alda_code).join ' '}]"
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent
		reverse_each &:detach_from_parent
	end
end

##
class Hash
	
	##
	# See Alda::Event#to_alda_code.
	def to_alda_code
		"[#{map(&:to_alda_code).join ' '}]"
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent
		each.reverse_each &:detach_from_parent
	end
end

##
class String
	
	##
	# See Alda::Event#to_alda_code.
	def to_alda_code
		dump
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent
	end
end

##
class Symbol
	
	##
	# See Alda::Event#to_alda_code.
	def to_alda_code
		?: + to_s
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent
	end
end

##
class Numeric
	
	##
	# See Alda::Event#to_alda_code.
	def to_alda_code
		inspect
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent
	end
end

##
class Range
	
	##
	# See Alda::Event#to_alda_code.
	def to_alda_code
		"#{first}-#{last}"
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent
	end
end

##
class TrueClass
	
	##
	# See Alda::Event#to_alda_code.
	def to_alda_code
		'true'
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent
	end
end

##
class FalseClass
	
	##
	# See Alda::Event#to_alda_code.
	def to_alda_code
		'false'
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent
	end
end

##
class NilClass
	
	##
	# See Alda::Event#to_alda_code.
	def to_alda_code
		'nil'
	end
	
	##
	# See Alda::Event#detach_from_parent.
	def detach_from_parent
	end
end

##
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
