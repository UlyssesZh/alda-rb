# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	piano_ c d e f g2 g4 f e d c2
end.play
