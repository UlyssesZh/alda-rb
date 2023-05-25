# frozen_string_literal: true

require "test_helper"

class Alda::Test < Minitest::Test
	
	##
	# Transform a score's block into a Hash of string.
	# The keys are generations, and the values are the Alda::Score#to_s result.
	def q &block
		Alda::GENERATIONS.each_with_object({}) do |gen, result|
			Alda.generation = gen
			result[gen] = Alda::Score.new(&block).to_s
		end
	end
	
	def test_sequence
		assert_equal({v1: '[c d e]', v2: '[c d e]'},
		             q { c d e })
		assert_equal({v1: '[c d e]', v2: '[c d e]'},
		             q { s { c; d; e } })
	end
	
	def test_chord
		assert_equal({v1: 'c/d/e', v2: 'c/d/e'},
		             q { c/d/e })
		assert_equal({v1: 'c/d/e', v2: 'c/d/e'},
		             q { x { c; d; e } })
	end
	
	def test_accidentals_and_slur
		assert_equal({v1: '[c+ d- e_ f~ g+~ a-~ b_~]', v2: '[c+ d- e_ f~ g+~ a-~ b_~]'},
		             q { c! d? e_ f__ g__! a__? b___ })
	end
	
	def test_marker
		assert_equal({v1: '[%mm @mm]', v2: '[%mm @mm]'},
		             q { _mm __mm })
	end
	
	def test_inline_lisp
		assert_equal({v1: '(aa (bb (cc (dd 1))) (ee (ff (gg :c))))', v2: '(aa (bb (cc (dd 1))) (ee (ff (gg \'c))))'},
		             q { aa bb(cc dd 1), ee(ff gg :c) })
		assert_equal({v1: '(ee [(aa ) (bb ) (cc (dd ))])', v2: '(ee \'((aa ) (bb ) (cc (dd ))))'},
		             q { ee [aa, bb, cc(dd)] })
		assert_equal({v1: '(defn [x] (inc x))', v2: '(defn \'(x) (inc x))'},
		             q { defn [_x_], inc(_x_) })
	end
	
	def test_variable
		assert_equal({v1: "var = [c d e]\n var", v2: "var = [c d e]\n var"},
		             q { var__ c d e; var })
		assert_equal({v1: "var = [c d e]\n var", v2: "var = [c d e]\n var"},
		             q { var { c d e }; var })
		assert_equal({v1: "var = c d e\n var", v2: "var = c d e\n var"},
		             q { var__ c, d, e; var })
	end
	
	def test_alternate_endings
		assert_equal({v1: "[a'1 b'2]*2", v2: "[a'1 b'2]*2"},
		             q { s { a%1; b%2 }*2 })
	end
	
	def test_part
		assert_equal({v1: '[piano: violin "vio":]', v2: '[piano: violin "vio":]'},
		             q { piano_ violin_ 'vio' })
		assert_equal({v1: 'cello/violin:', v2: 'cello/violin:'},
		             q { cello_/violin_ })
		assert_equal({v1: 'cello/violin "str": str.cello:', v2: 'cello/violin "str": str.cello:'},
		             q { cello_/violin_('str'); str_.cello_ })
		assert_equal({v1: '[e str.cello: c d str.violin:]', v2: '[e str.cello: c d str.violin:]'},
		             q { e str_.cello_ c d str_.violin_ })
	end
	
	def test_voice
		assert_equal({v1: '[V1: V2: V0:]', v2: '[V1: V2: V0:]'},
		             q { v1 v2 v0 })
	end
	
	def test_example_inline_lisp
		test = self
		
		got = q do
			tempo! 108
			quant! 200
			piano_ c e g violin_ g2 e4
		end
		assert_equal({
			             v1: '(tempo! 108) (quant! 200) [piano: c e g violin: g2 e4]',
			             v2: '(tempo! 108) (quant! 200) [piano: c e g violin: g2 e4]'
		             }, got)
		
		got = q do
			piano_ c d e quant 200
			g o! c o? c2
		end
		assert_equal({
			             v1: '[piano: c d e (quant 200)] [g > c < c2]',
			             v2: '[piano: c d e (quant 200)] [g > c < c2]'
		             }, got)
		
		got = q do
			part 'piano'
			key_sig [:d, :major]
			note pitch :d
			note pitch :e
			note pitch(:f), duration(note_length 2)
		end
		assert_equal({
			             v1: '(part "piano") (key-sig [:d :major]) (note (pitch :d)) (note (pitch :e)) (note (pitch :f) (duration (note-length 2)))',
			             v2: '(part "piano") (key-sig \'(d major)) (note (pitch \'d)) (note (pitch \'e)) (note (pitch \'f) (duration (note-length 2)))'
		             }, got)
		
		got = q do
			piano_
			test.assert_equal Alda::InlineLisp, barline.event.class
			barline__ c d e f
			test.assert_equal Alda::GetVariable, barline.event.class
		end
		assert_equal({
			             v1: "piano: (barline ) barline = [c d e f]\n barline",
			             v2: "piano: (barline ) barline = [c d e f]\n barline"
		             }, got)
		
		got = q do
			piano_
			test.assert_equal Alda::InlineLisp, (tempo 108).event.class
			test.assert_equal Alda::SetVariable, tempo { c d }.event.class
			test.assert_equal Alda::GetVariable, tempo.event.class
			test.assert_equal Alda::InlineLisp, (tempo 60).event.class
		end
		assert_equal({
			             v1: "piano: (tempo 108) tempo = [c d]\n tempo (tempo 60)",
			             v2: "piano: (tempo 108) tempo = [c d]\n tempo (tempo 60)"
		             }, got)
		
		#got = q do
		#	println reduce _into_, {}, [{dog: 'food'}, {cat: 'chow'}]
		#end
		#assert_equal "[[:dog food] [:cat chow]]\n", `clj -e '#{got}'`
	end
	
	def test_example_event_container
		test = self
		
		got = q do
			test.assert_equal 2, (c*2).count
			test.assert_equal 15, (d*3*5).count
		end
		assert_equal({v1: 'c*2 d*15', v2: 'c*2 d*15'}, got)
		
		got = q do
			test.assert_equal Alda::Note, c.event.class
			test.assert_equal Alda::Chord, (e/g).event.class
			test.assert_equal Alda::Sequence, (a b).event.class
		end
		assert_equal({v1: 'c e/g [a b]', v2: 'c e/g [a b]'}, got)
		
		got = q do
			test.assert_equal [2], (c%2).labels
			test.assert_equal [2, 4..6], (c%[2,4..6]).labels
		end
		assert_equal({v1: "c'2 c'2,4-6", v2: "c'2 c'2,4-6"}, got)
		
		assert_equal({v1: "[b a'1]*2", v2: "[b a'1]*2"}, q { (b a%1)*2 })
		
		assert_equal({v1: 'piano: c/e-/g', v2: 'piano: c/e-/g'}, q { piano_; c/-e/g })
		
		assert_equal({v1: 'violin/viola/cello: e f g', v2: 'violin/viola/cello: e f g'},
		             q { violin_/viola_/cello_; e; f; g })
		
		got = q do
			container = c
			test.assert_equal Alda::EventContainer, container.class
			test.assert_equal false, container.respond_to?(:pitch)
			test.assert_equal 'c', container.pitch
			test.assert_equal false, container.respond_to?(:+@)
			test.assert_equal Alda::EventContainer, (+container).class
		end
		assert_equal({v1: 'c+', v2: 'c+'}, got)
	end
	
	def test_example_set_variable
		test = self
		
		got = q do
			test.assert_equal Alda::InlineLisp, var.event.class
			test.assert_equal Alda::SetVariable, (var c d e f).event.class
			test.assert_equal Alda::SetVariable, var { c d e f }.event.class
			test.assert_equal Alda::SetVariable, (var__ c d e f).event.class
			test.assert_equal Alda::SetVariable, var__ { c d e f }.event.class
			test.assert_equal Alda::Sequence, (var c d e f).event.class
			test.assert_equal Alda::GetVariable, var.event.class
			test.assert_equal Alda::InlineLisp, var(1).event.class
		end
		assert_equal({
			             v1: "(var ) var = [c d e f]\n var = [c d e f]\n var = [c d e f]\n var = [c d e f]\n [var c d e f] var (var 1)",
			             v2: "(var ) var = [c d e f]\n var = [c d e f]\n var = [c d e f]\n var = [c d e f]\n [var c d e f] var (var 1)"
		             }, got)
	end
	
	def test_example_cram
		assert_equal({v1: '[piano: c3 {[c2 d4 e f]}4] g2', v2: '[piano: c3 {[c2 d4 e f]}4] g2'},
		             q { piano_ c3 t4 {c2 d4 e f}; g2 })
		assert_equal({v1: 'piano: {a b}8', v2: 'piano: {a b}8'},
		             q { piano_; t8 { a; b }})
	end
	
	def test_example_note
		got = q do
			key_sig! [:d, :major]
			c4_2 d1108ms e2s
			f2!      # F sharp
			g20ms_4? # G flat
			a6_      # A natural
			c__      # C (slur)
			f___     # D natural (slur)
		end
		assert_equal({
			             v1: '(key-sig! [:d :major]) [c4~2 d1108ms e2s] f+2 g-20ms~4 a_6 c~ f_~',
			             v2: '(key-sig! \'(d major)) [c4~2 d1108ms e2s] f+2 g-20ms~4 a_6 c~ f_~'
		             }, got)
		
		assert_equal({v1: 'piano: c+', v2: 'piano: c+'}, q { piano_; +c })
		assert_equal({v1: 'piano: d-', v2: 'piano: d-'}, q { piano_; -d })
		assert_equal({v1: 'piano: (key-sig "f+") f_', v2: 'piano: (key-sig "f+") f_'},
		             q { piano_; key_sig 'f+'; ~f })
	end
	
	def test_example_event_list
		got = q do
			tempo! 108           # inline lisp
			piano_               # piano part
			o4                   # octave 4
			c8; d; e; f          # notes
			g4 g a f g e f d e c # a sequence
			d4_8                 # cannot have '~', use '_' instead
			o3 b8 o4 c2          # a sequence
		end
		assert_equal({
			             v1: '(tempo! 108) piano: o4 c8 d e f [g4 g a f g e f d e c] d4~8 [o3 b8 o4 c2]',
			             v2: '(tempo! 108) piano: o4 c8 d e f [g4 g a f g e f d e c] d4~8 [o3 b8 o4 c2]'
		             }, got)
	end
	
	def test_example_chord
		test = self
		
		got = q do
			test.assert_equal Alda::Chord, x{ c; e; g }.event.class
		end
		assert_equal({v1: 'c/e/g', v2: 'c/e/g'}, got)
		
		assert_equal({v1: 'piano: c/e-/g', v2: 'piano: c/e-/g'}, q { piano_; x { c; -e; g } })
	end
	
	def test_example_marker
		assert_equal({
			             v1: '[piano: V1: c d %here e2 V2: @here c4 d e2]',
			             v2: '[piano: V1: c d %here e2 V2: @here c4 d e2]'
		             }, q { piano_ v1 c d _here e2 v2 __here c4 d e2 })
	end
	
	def test_example_octave
		test = self
		
		got = q do
			test.assert_equal 4, (++++o).event.up_or_down
		end
		assert_equal({v1: '>>>>', v2: '>>>>'}, got)
		
		assert_equal({v1: 'piano: c > c', v2: 'piano: c > c'}, q { piano_; c; +o; c })
	end
end
