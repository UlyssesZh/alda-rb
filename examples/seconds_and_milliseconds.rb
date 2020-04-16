# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	accordion_
	c500ms/e/g
	c1s/f/a
	c2s/e/g
end.play
