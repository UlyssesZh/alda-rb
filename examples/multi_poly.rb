# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	piano_ set_duration 4
	harp_  set_duration 2; octave 3
	
	piano_/harp_
	t{ e f g }; t{ a b o! c }
	
	harp_
	t{ d e f }; t { g a b }
end.play
