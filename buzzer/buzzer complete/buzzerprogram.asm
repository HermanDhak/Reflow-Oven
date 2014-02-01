;buzzerprogram.asm
; This is a sample program to show the running of the buzzer. It is intended to 
; be adapted into the state machine. Keep in mind that these initializations are
; important! Be careful when including parts in the main code of the oven.

; Currently, state changes etc. are represented by switches 7..4. These can be replaced
; by bits to check - please replace them in the subroutine file.

; Here is what the switches (toggle up and down!) represent/should do:
; SWA.7 - starting the program (one beep)
; SWA.6 - moving to the next state (one beep)
; SWA.5 - the door needs to be open (one long beep)
; SWA.4 - the PCB is cool enough to touch (six beeps)

; The buzzers should be connected between GND and P2.0..2.3 respectively.
;----------------------------------------------------------------------------------

$MODDE2

org 0000H
	ljmp myprogram
	
org 001BH ;ISR for timer 1
	ljmp ISR_timer1	
	
CSEG


$include (buzzersubroutines.asm) ;don't forget to include this!!!

;---------------------------------------------------------
; CONSTANTS & LOOK UP TABLES
;---------------------------------------------------------
XTAL           EQU 33333333
FREQ_1 		   EQU 2000 ;200Hz buzzing
TIMER1_RELOAD  EQU 65536-(XTAL/(12*2*FREQ_1))

; Look-up table for 7-segment displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H
    DB 0FFH ; All segments off

myprogram:
	mov SP, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	
	;important part!
	mov P2MOD, #00001111B ; P2.0...2.3 are outputs! Lots of buzzers!!!!!!
	setb P2.0
	setb P2.1
	setb P2.2
	setb P2.3
	
	lcall Init_Timer1
	
    setb EA  ; Enable all interrupts

forever: ;continually check to see if we have triggered a buzz through a switch.
	lcall checkForBuzz
	sjmp forever
	
END