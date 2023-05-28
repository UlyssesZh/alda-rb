# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	tempo! 105
	
	piano_
	pmotif do
		s do
			o3
			vol 100; a16
			vol 90;  -b
			vol 80;  a
			vol 70;  -b
			vol 60;  o! c d
			vol 50;  e f
		end * 2
	end
	
	70.step(10, -20) { track_vol _1; pmotif }
	
	clarinet_
	cmotif do
		quant 100; o5
		vol 60; d8
		vol 70; c
		vol 80; o? +f2_4
	end
	
	10.step(70, 20) { track_vol _1; cmotif }
end.play
