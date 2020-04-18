# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	vibraphone_
	quant 200
	
	key_signature 'f+ c+ g+'
	a8 b o! c d e f g a o?
	a b o! c_ d e f_ g_ a o?
	
	key_signature [:g, :minor]
	g a b o! c! d e f! g o?
	
	key_signature e: [:flat], b: [:flat]
	g1_1/b/d
end.play
