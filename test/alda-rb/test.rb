# frozen_string_literal: true

require "test_helper"

class Alda::Test < Minitest::Test
	def test_version_number
		refute_nil ::Alda::VERSION
	end
	
	def test_sequence
		assert_equal '[c d e]',
		             Alda::Score.new { c d e }.events_alda_codes
		assert_equal '[c d e]',
		             Alda::Score.new { s { c; d; e } }.events_alda_codes
	end
	
	def test_chord
		assert_equal 'c/d/e',
		             Alda::Score.new { c/d/e }.events_alda_codes
		assert_equal 'c/d/e',
		             Alda::Score.new { x { c/d/e } }.events_alda_codes
	end
	
	def test_accidentals_and_slur
		assert_equal '[c+ d- e_ f~ g+~ a-~ b_~]',
		             Alda::Score.new { c! d? e_ f__ g__! a__? b___ }.events_alda_codes
	end
	
	def test_marker
		assert_equal '[%mm @mm]',
		             Alda::Score.new { _mm __mm }.events_alda_codes
	end
	
	def test_inline_lisp
		assert_equal '(aa (bb (cc (dd 1))) (ee (ff (gg :c))))',
		             Alda::Score.new { aa bb(cc dd 1), ee(ff gg :c) }.events_alda_codes
	end
	
	def test_variable
		assert_equal "var = [c d e]\n var",
		             Alda::Score.new { var__ c d e; var }.events_alda_codes
		assert_equal "var = [c d e]\n var",
		             Alda::Score.new { var { c d e }; var }.events_alda_codes
		assert_equal "var = c d e\n var",
		             Alda::Score.new { var__ c, d, e; var }.events_alda_codes
	end
	
	def test_alternate_endings
		assert_equal "[a'1 b'2]*2",
		             Alda::Score.new { s { a%1; b%2 }*2 }.events_alda_codes
	end
	
	def test_part
		assert_equal '[piano: violin "vio":]',
		             Alda::Score.new { piano_ violin_ 'vio' }.events_alda_codes
		assert_equal 'cello/violin:',
		             Alda::Score.new { cello_/violin_ }.events_alda_codes
		assert_equal 'cello/violin "str": str.cello:',
		             Alda::Score.new { cello_/violin_('str'); str_.cello_ }.events_alda_codes
		assert_equal '[str.cello: c d]',
		             Alda::Score.new { str_.cello_ c d }.events_alda_codes
	end
	
	def test_voice
		assert_equal '[V1: V2: V0:]',
		             Alda::Score.new { v1 v2 v0 }.events_alda_codes
	end
end
