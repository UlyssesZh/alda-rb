# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	piano_
	c8
	pppppp d
	ppppp  e
	pppp   f
	ppp    g
	pp     a
	p      b
	mp     o! c
	mf     o? b
	f      a
	ff     g
	fff    f
	ffff   e
	fffff  d
	ffffff c4
end.play
