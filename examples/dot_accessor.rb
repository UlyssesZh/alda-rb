# frozen_string_literal: true

require 'alda-rb'

Alda::Score.new do
	violin_/viola_/cello_('strings'); g1_1_1
	strings_.cello_; -o; c1_1_1
end.play
