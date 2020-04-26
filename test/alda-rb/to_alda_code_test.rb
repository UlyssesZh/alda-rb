# frozen_string_literal: true

require "test_helper"

class Alda::Test < Minitest::Test
	
	# Transform a score's block into string.
	def q &block
		Alda::Score.new(&block).to_s
	end
	
	def test_sequence
		assert_equal '[c d e]',
		             q { c d e }
		assert_equal '[c d e]',
		             q { s { c; d; e } }
	end
	
	def test_chord
		assert_equal 'c/d/e',
		             q { c/d/e }
		assert_equal 'c/d/e',
		             q { x { c/d/e } }
	end
	
	def test_accidentals_and_slur
		assert_equal '[c+ d- e_ f~ g+~ a-~ b_~]',
		             q { c! d? e_ f__ g__! a__? b___ }
	end
	
	def test_marker
		assert_equal '[%mm @mm]',
		             q { _mm __mm }
	end
	
	def test_inline_lisp
		assert_equal '(aa (bb (cc (dd 1))) (ee (ff (gg :c))))',
		             q { aa bb(cc dd 1), ee(ff gg :c) }
		assert_equal '(ee [(aa ) (bb ) (cc (dd ))])',
		             q { ee [aa, bb, cc(dd)] }
		assert_equal '(defn [x] (inc x))',
		             q { defn [_x_], inc(_x_) }
	end
	
	def test_variable
		assert_equal "var = [c d e]\n var",
		             q { var__ c d e; var }
		assert_equal "var = [c d e]\n var",
		             q { var { c d e }; var }
		assert_equal "var = c d e\n var",
		             q { var__ c, d, e; var }
	end
	
	def test_alternate_endings
		assert_equal "[a'1 b'2]*2",
		             q { s { a%1; b%2 }*2 }
	end
	
	def test_part
		assert_equal '[piano: violin "vio":]',
		             q { piano_ violin_ 'vio' }
		assert_equal 'cello/violin:',
		             q { cello_/violin_ }
		assert_equal 'cello/violin "str": str.cello:',
		             q { cello_/violin_('str'); str_.cello_ }
		assert_equal '[e str.cello: c d str.violin:]',
		             q { e str_.cello_ c d str_.violin_ }
	end
	
	def test_voice
		assert_equal '[V1: V2: V0:]',
		             q { v1 v2 v0 }
	end
end
