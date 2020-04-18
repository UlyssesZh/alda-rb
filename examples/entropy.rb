# frozen_string_literal: true

require 'alda-rb'

REST_RATE = 0.15
MS_LOWER = 30
MS_UPPER = 3000
OCTAVE_UPPER = 9

Alda::Score.new do
	random_note = -> do
		ms = -> { duration ms rand(MS_UPPER - MS_LOWER) + MS_LOWER }
		if rand < REST_RATE
			pause ms.()
			octave rand OCTAVE_UPPER
			note pitch('abcdefg'[rand 7].to_sym,
			           %i[sharp flat natural].sample), ms.()
		end
	end
	
	midi_electric_piano_1_
	panning 25
	random_note * 50
	
	midi_timpani_
	panning 50
	random_note * 50
	
	midi_celesta_
	panning 75
	random_note * 50
end.play
