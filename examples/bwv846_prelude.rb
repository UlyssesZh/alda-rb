# frozen_string_literal: true

require 'alda-rb'

# Prelude and Fugue in C major, BWV 864
# (Prelude)
#
# J. S. Bach
#
# sheet music:
# http://www.freesheetpianomusic.com/bach/content/Well-Tempered%20Clavier_Book_1/Prelude%20and%20Fugue%20No.1%20C%20major%20BWV%20846.pdf

include Alda

Score.new do
	def Note.absolute event_list, pitch, duration
		/(?<letter>[a-g][-+_]*)(?<octave>\d*)/ =~ pitch
		octave = @last_octave ||= '4' if octave.empty?
		event_list.events.push new "o#{@last_octave = octave} #{letter}", duration
	end
	
	piano_; tempo 60
	%w[
		c e g c5 e
		c4 d a d5 f
		b3 d4 g d5 f
		c4 e g c5 e
		c4 e a e5 a
		c4 d f+ a d5
		b3 d4 g d5 g5
		b3 c4 e g c5
		a3 c4 e g c5
		d3 a d4 f+ c5
		g3 b d4 g b
		g3 b- e4 g c+5
		f3 a d4 a d5
		f3 a- d4 f b
		e3 g c4 g c5
		e3 f a c4 f
		d3 f a c4 f
		g2 d3 g b f4
		c3 e g c4 e
		c3 g b- c4 e
		f2 f3 a c4 e
		f+2 c3 a c4 e-
		a-2 f3 b c4 d
		g2 f3 g b d4
		g2 e3 g c4 e
		g2 d3 g c4 f
		g2 d3 g b f4
		g2 e-3 a c4 f+
		g2 e3 g c4 g
		g2 d3 g c4 f
		g2 d3 g b f4
		c2 c3 g b- e4
	].each_slice 5 do |n1, n2, *notes|
		s do
			v1; Note.absolute self, n1, '2'
			v2; r16; Note.absolute self, n2, '4..'
			v3; r8; s{ notes.each { Note.absolute self, _1, '16' } }*2
		end * 2
	end
	alda_code <<~ENDING
		V1:
			o2 c1 | c1 | c1~1s
		V2:
			o3 r16 c2... | r16 <b2... | >c1~1s
		V3:
			o3
			r8 f16 a > c f c < a > c < a f a f d f d
			r8 > g16 b > d f d < b > d < b g b d f e d
			e1~1s/g/>c
	ENDING
end.play
