# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	tempo! 160
	
	riffA__ f8 f g! a o! c c d c o?
	riffB__ b8? b? o! c! d f f g f o?
	riffC__ o! c8 c d! e g g a g o?
	riffD do
		f8 f g! a o! c c d o? b o!
		c c o? b? b? a a g g
	end
	
	rockinRiff do
		riffA*4
		riffB*2; riffA*2
		riffC riffB riffD
	end
	
	electric_guitar_distorted_ 'guitar'; o2
	tenor_saxophone_ 'sax'; o3
	
	guitar_/sax_
	rockinRiff*8
end.play
