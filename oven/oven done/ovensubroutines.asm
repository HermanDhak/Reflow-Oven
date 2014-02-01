;ovensubroutines.asm
; This should contain all the subroutines to make the oven work. The sequence
; to call/use them (the myprogram part) is within ovenprogram.asm
;-----------------------------------------------------------------------------------------------

$NOLIST ;this prevents this subroutine file from printing if you print your code

;-----------------------------------------------------------------------------------------------
; ovenOff:
; This turns the oven off. Call it when you want to turn the oven off.
;-----------------------------------------------------------------------------------------------
ovenOff:
	setb P3.7
	ret

;-----------------------------------------------------------------------------------------------
; ovenOn:
; This turns the oven on. Call it when you want to turn the oven on.
;-----------------------------------------------------------------------------------------------
ovenOn: 
	clr  P3.7
	ret
	
;-----------------------------------------------------------------------------------------------
; tenthSecDelay:
; This delays for 1/10th of a second.
;-----------------------------------------------------------------------------------------------
tenthSecDelay:
	mov R2, #18
tenthSec3: mov R1, #250
tenthSec2: mov R0, #250
tenthSec1: djnz R0, tenthSec1 ;250*30ns*3 = 22.5us
	djnz R1, tenthSec2 ;250 * 22.5us = 5.63ms
	djnz R2, tenthSec3 ;18 * 5.63ms = 0.10s approx
	ret
	
;-----------------------------------------------------------------------------------------------
; FullPower:
; This turns on the oven to full power for 1 second. Place in a forever loop to make
; the oven continuously run at full power. Could insert a bit check to control this.
;-----------------------------------------------------------------------------------------------
FullPower:
	lcall ovenOn
	lcall tenthSecDelay ;ON
	lcall tenthSecDelay ;ON
	lcall tenthSecDelay ;ON
	lcall tenthSecDelay ;ON
	lcall tenthSecDelay ;ON
	lcall tenthSecDelay ;ON
	lcall tenthSecDelay ;ON
	lcall tenthSecDelay ;ON
	lcall tenthSecDelay ;ON
	lcall tenthSecDelay ;ON
	lcall ovenOff
	ret
	
;-----------------------------------------------------------------------------------------------
; HalfPower:
; This turns on the oven to half power for 1 second. Place in a forever loop to make
; the oven continuously run at 50% power. Could insert a bit check to control this.
;-----------------------------------------------------------------------------------------------
HalfPower:
	lcall ovenOn
	lcall tenthSecDelay ;ON
	lcall ovenOff
	lcall tenthSecDelay ;OFF
	lcall ovenOn
	lcall tenthSecDelay ;ON
	lcall ovenOff
	lcall tenthSecDelay ;OFF
	lcall ovenOn	
	lcall tenthSecDelay ;ON
	lcall ovenOff
	lcall tenthSecDelay ;OFF
	lcall ovenOn	
	lcall tenthSecDelay ;ON
	lcall ovenOff
	lcall tenthSecDelay ;OFF
	lcall ovenOn	
	lcall tenthSecDelay ;ON
	lcall ovenOff
	lcall tenthSecDelay ;OFF
	ret
	
	
;-----------------------------------------------------------------------------------------------
; TenthPercentPower:
; This turns on the oven to 10% power for 1 second. Place in a forever loop to make
; the oven continuously run at 10% power. Could insert a bit check to control this.
;-----------------------------------------------------------------------------------------------
TenthPower:
	lcall ovenOn
	lcall tenthSecDelay ;ON
	lcall ovenOff
	lcall tenthSecDelay ;OFF
	lcall tenthSecDelay ;OFF
	lcall tenthSecDelay ;OFF
	lcall tenthSecDelay ;OFF
	lcall tenthSecDelay ;OFF
	lcall tenthSecDelay ;OFF
	lcall tenthSecDelay ;OFF
	lcall tenthSecDelay ;OFF
	lcall tenthSecDelay ;OFF
	lcall tenthSecDelay ;OFF
	ret
	
$LIST