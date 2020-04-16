# frozen_string_literal: true

require 'alda-rb'

# transcribed from:
# https://www.rosegardenmusic.com/tutorials/supplemental/n-endings/index.html

Alda::Score.new do
	vibraphone_ 'vibes-1'
	panning 10
	s do
		a; b8; +o; d; -o; b; g; b; +o; c
		e4; -o; a; +o; c; -o; g
		s{ g; +o; g8; f; e; c; -o; a4 }%1..2
		s{ b8; +o; d; g2_4 }%3
	end * 3
	
	vibraphone_ 'vibes-2'
	panning 90
	s do
		a; +o; e; -o; a; r
		b; r; b; r
		s{ g; r; +o; g; -o; g }%1..2
		s{ +o; d; r; a; g }%3
	end * 3
end.play
