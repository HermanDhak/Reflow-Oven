$MODDE2

org 0000H
	ljmp myprogram

myprogram:
	mov SP, #7FHa
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	mov P3MOD, #10000000B ; P3.7 is output!
	mov P3, #0

ovenOff:
	jb SWA.0, ovenOn
	setb P3.7
	clr LEDRA.0
	sjmp ovenOff

ovenOn: 
	jnb SWA.0, ovenOff
	clr  P3.7
	setb LEDRA.0
	sjmp ovenOn
	
END