# frozen_string_literal: true

require 'alda-rb'

SYMBOLS = %i[c d e f g a b]
class Solfege
	attr_accessor :i, :octave
	def initialize i, octave
		@i = i
		@octave = octave
		update
	end
	def update
		old_octave = @octave
		@octave, @i = @i.divmod SYMBOLS.size
		@octave += old_octave
	end
	def letter
		SYMBOLS[@i]
	end
end

class Alda::Sequence
	def play_solfege solfege
		v1; octave solfege.octave; note pitch solfege.letter
		v2; octave solfege.octave-1; note pitch solfege.letter
	end
	def play_hanon ary, octave, delta
		solfeges = ary.map { Solfege.new _1, octave }
		14.times do
			solfeges.each do |solfege|
				play_solfege solfege
				solfege.i += delta
				solfege.update
			end
		end
	end
end

Alda::Score.new do
	piano_; set_note_length 16
	def play_hanon ary1, ary2
		s do
			play_hanon ary1, 3, 1
			play_hanon ary2, 5, -1
		end * 2
	end
	play_hanon [0, 2, 3, 4, 5, 4, 3, 2], [4, 2, 1, 0, -1, 0, 1, 2]
	play_hanon [0, 2, 5, 4, 3, 4, 3, 2], [4, 1, -1, 0, 1, 0, 1, 2]
	v1; o3; c2; v2; o2; c2
end.play
