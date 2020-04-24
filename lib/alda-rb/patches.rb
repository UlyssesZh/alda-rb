require 'stringio'

# Define #to_alda_code
{
		Array      => -> { "[#{map(&:to_alda_code).join ' '}]" },
		Hash       => -> { "{#{to_a.reduce(:+).map(&:to_alda_code).join ' '}}" },
		String     => -> { dump },
		Symbol     => -> { ?: + to_s },
		Numeric    => -> { inspect },
		Range      => -> { "#{first}-#{last}" },
		TrueClass  => -> { 'true' },
		FalseClass => -> { 'false' },
		NilClass   => -> { 'nil' }
}.each { |klass, block| klass.define_method :to_alda_code, &block }

class Proc
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
	# Equivalent to #string.
	def to_s
		string
	end
end
