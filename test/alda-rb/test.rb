# frozen_string_literal: true

require "test_helper"

class Alda::Test < Minitest::Test
	def test_that_version_number
		refute_nil ::Alda::VERSION
	end
	
	def test_basic_functions
		score = Alda::Score.new { o4; c4/e/g; -d8; r8_16; +f4; o5; c2 }
		Alda::Score.new do
			piano_
			quant 200
			v1
			5.times do |t|
				transpose t
				import score
				note midi_note(30 + t * t), duration(note_length 1)
			end
			v2; o6
			motif = -> { c200ms; d500ms }
			8.times { motif * 2; e400ms_4; t4 { a; b; c } }
			_ended
			
			violin_
			__ended
			->i do
				c2; d4; e2_4; e2; d4 c2_4; c2; e4; d2
				i == 0 ? (c4; d1_2) : (d4; c1_2)
			end * 2
		end.play
	end
end
