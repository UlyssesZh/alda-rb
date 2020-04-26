# frozen_string_literal: true

require "test_helper"

class Alda::Test < Minitest::Test
	
	def test_order_error
		assert_raises Alda::OrderError do
			Alda::Score.new { m = a; b; c m }
		end
	end
	
=begin
	def test_command_line_error
		error = assert_raises Alda::CommandLineError do
			Alda[port: 1108].play code: 'y'
		end
		assert_equal 1108, error.port
		Alda.clear_options
	end
=end
end
