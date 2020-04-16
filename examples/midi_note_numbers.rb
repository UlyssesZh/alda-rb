# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	midi_calliope_lead_
	set_note_length 8
	(10...100).step(10) { |n| note midi_note n }
end.play
