# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	tempo! 180
	piano_
	%i[ionian dorian phrygian lydian mixolydian aeolian locrian].each do |mode|
		key_sig [:c, mode]
		o4; c4; d8; e; f; g; a; b; +o; c1
	end
end.play
