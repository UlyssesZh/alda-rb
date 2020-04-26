# frozen_string_literal: true

require "test_helper"

class Alda::Test < Minitest::Test
	
	def test_version_number
		refute_nil ::Alda::VERSION
	end
end
