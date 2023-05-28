# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	quiet { vol 25 }
	loud { vol 50 }
	louder { vol 75 }
	
	notes { c d e }
	
	piano_
	quiet notes
	loud notes
	louder notes
end.play
