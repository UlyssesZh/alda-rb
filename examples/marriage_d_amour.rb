# frozen_string_literal: true

require 'alda-rb'

# Marriage D' Amour
#
# Richard Clayderman
# Paul de Senneville
#
# sheet music:
# https://musescore.com/user/153958/scores/154629

using Alda::Sequence::RefineFlatten

module Alda::EventList
	def up8 &block
		result = block.()
		result.events = result.events.map do |event|
			if event.is_event_of? Alda::Octave
				event
			else
				if event.respond_to? :labels
					labels = event.labels
					event.labels = []
				end
				sequence = Alda::Sequence.new
				sequence.events = [Alda::Chord.new(
					event,
					+Alda::Octave.new(''),
					event,
					-Alda::Octave.new('')
				)]
				container = Alda::EventContainer.new(sequence, result)
				container.labels = labels || []
				container
			end
		end
		result
	end
end

Alda::Score.new do
	key_sig! 'b- e-'
	tempo! 80
	piano_ 'right'
	piano_ 'left'
	
	right_
	r2_4_8_16 o5 g16
	left_
	o2 g8 o! d b d b d b d
	
	motif1 = -> do
		right_
		g16 a a b b a a g g d d o? b b g g o! f f e e d e f e4_8
		left_
		o2 g o! d b d b d b d e g o! e o? g o! e o? g
		
		right_
		v1 r16 e e f f g g a a f f c c e e d d c d e _marker1 d8_4
		v2 __marker1 r8 o6 d32 o! d8_16_32 v0
		left_
		v1 o? f o! c a c a c a o? b o! f o! d o? d8_4
		v2 __marker1 r8 o4 g4? v0
	end
	motif1.()
	
	motif2 = -> do
		right_
		o5 s{ (d8 o? g16 b o! d c)*2; d8 (o? g16 b o! e d e8)*2; e16 d e e_ f8 f16 g f g d4_8 o!}*2
		left_
		s{o2 g8 o! d b d b d o? g o! d b c g o! e o? g o! e o? g o? f o! c a o? b
		(o! b o? up8{s{a}})%1; up8{b a}%2}*2
	end
	motif2.()
	
	motif3 = -> do
		right_
		o5 b8_16 d16 d e e8_16 c16 a g a8_16 c16 c d d8 o? b16 b o! g f g8_16 o? b16 b o! c c8_16 o? a16 o! d c d4_8
		left_
		up8{s{g}}; o! d b c g o! e o? o? f o! c a o? b o! f o? a g o! d b o? a o! e o! c o? d o? up8{e_ g?}
	end
	motif3.()
	
	tt2 { s{o2 g o! d b c g o! e o? o? f o! c a o? b o! b o? up8{s{a}}; g o! d b c g o! e o? o? f o! c a o? g o! d b}*2 }
	motif4 = -> do
		tt1 = -> { (o5 b8_16 b16 b o! c c8_16 o? b16 a g f8_16 f16 g f d4_8%1)*2 }
		right_
		tt1.(); g4_8; up8{tt1.()}
		left_
		tt2 o4 d g b
	end
	motif4.()
	right_; up8{s{g2_4}}
	
	motif2.()
	
	motif4.()
	right_
	o5 up8{s{g2_8}}; r16 g16
	
	motif1.()
	motif2.()
	motif3.()
	
	tt1 = -> { (o5 b8_16 b16 b o! c c8_16 o? b16 a g f8_16 f16 g f d4_8%1)*2 }
	
	right_
	tt1.(); g4_8
	-> { up8{tt1.()}; up8{s{g4_8}} }*2
	up8{tt1.()}; up8{s{g1}}
	left_
	tt2*2; o4 d g o! d g r8_16 o! g4_8
end.play
