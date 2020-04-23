# frozen_string_literal: true

require 'alda-rb'

# Clapping Music (1972)
# for two performers
#
# Steve Reich
#
# sheet music:
# https://sites.ualberta.ca/~michaelf/SEM-O/SEM-O_2014/Steve's%20piece/clapping_reich.jpg

Alda::Score.new do
	pattern = %i[clap clap clap rest clap clap rest clap rest clap clap rest]
	Alda::Sequence.class_exec do
		define_method(:clap) { +d }; define_method(:rest) { r }
		define_method(:play) { pattern.each { __send__ _1 } }
	end
	
	tempo! 172
	midi_percussion_ o2 set_note_length 8
	v1; s{ play }*12*13
	v2; 13.times { s{ play; pattern.rotate! }*12 }
end.play
