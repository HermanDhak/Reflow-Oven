;ovenprogram.asm
; This is a sample program to show the running of the oven. It is intended to 
; be adapted into the state machine. Keep in mind that these initializations are
; important! Be careful when including parts in the main code.

; Currently, oven state changes are represented by switch 1. These can be replaced
; by bits to check - please replace them in the subroutine file.

; The bjt should be connected to P3.7.
;----------------------------------------------------------------------------------

$MODDE2

org 0000H
	ljmp myprogram
	
CSEG

$include (ovensubroutines.asm) ;don't forget to include this!!!

myprogram:
	mov SP, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	
	mov P3MOD, #10000000B ; P3.7 is output. very important for initialization!
	mov P3, #0FFH

forever:
	jb SWA.0, FullPowerTest
	jb SWA.1, HalfPowerTest
	jb SWA.2, TenthPowerTest
	
	;if no switches are up, oven should be off
	lcall ovenOff
	sjmp forever
	
FullPowerTest:
	jnb SWA.0, forever
	lcall FullPower
	sjmp FullPowerTest
	
HalfPowerTest:
	jnb SWA.1, forever
	lcall HalfPower
	sjmp HalfPowerTest
	
TenthPowerTest:
	jnb SWA.0, forever
	lcall TenthPower
	sjmp TenthPowerTest
	
	
END