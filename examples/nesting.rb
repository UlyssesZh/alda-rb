# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	piano_
	
	v1
	c8; d; e; f; g2_
	
	v2
	s{ c8; d }*2; e
	f; g*3
	t do
		t{ c; c }
		s{ g/e/c; s{ d }*2 }
		s{ c; d }*5
	end * 5
	a/b/c; b; c/e
	
	v3
	a8; b; +o; c2_
	
	clarinet_
	a2; e
end.play
