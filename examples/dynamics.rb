# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	piano_
	c8
	pppppp; d
	ppppp;  e
	pppp;   f
	ppp;    g
	l :pp;  a
	l :p;   b
	mp;     o! c
	mf;     o? b
	l :f;   a
	ff;     g
	fff;    f
	ffff;   e
	fffff;  d
	ffffff; c4
end.play
