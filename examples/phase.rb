# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	tempos = { violin_: 100, viola_: 105, cello_: 110 }
	
	tempos.each do |ins, tempo|
		__send__ ins
		tempo tempo
	end
	tempos.keys.lazy.map { __send__ _1 }.inject :/
	s{ e8; f; g }*99
end.play
