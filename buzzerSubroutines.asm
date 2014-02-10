;buzzersubroutines.asm
; This should contain all the subroutines to make the buzzers work. The sequence
; to call/use them (the myprogram part) is within buzzerprogram.asm
;-------- --------------------------------------------------------------------------------------


$NOLIST ;this prevents this subroutine file from printing if you print your code

;---------------------------------------------------------
; ISR_Timer1:
; This is the interrupt that allows the timer 1 to create the buzzing.
; Buzzers should be attached to ports 2.0..2.3.
;---------------------------------------------------------
ISR_Timer1:
	clr TF1 ;may not be necessary
	cpl P2.0
	cpl P2.1
	cpl P2.2
	cpl P2.3
    mov TH1, #high(TIMER1_RELOAD)
    mov TL1, #low(TIMER1_RELOAD)
	reti


;---------------------------------------------------------
; Init_Timer1:
; This is the initialization of timer 1 to create the buzzing.
; Note that the interrupt is NOT SET - that is how we trigger
; the buzzer within the beeping functions.
;---------------------------------------------------------	 
Init_Timer1:	
	mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR1 ; Disable timer 1
	clr TF1
    mov TH1, #high(TIMER1_RELOAD)
    mov TL1, #low(TIMER1_RELOAD)
    setb TR1 ; Enable timer 1, dont set interrupt yet
    ret


;---------------------------------------------------------
; checkForBuzz:
; This checks the switches 7..4 to see if a buzz should be
; triggered. The switches can be replaced by bits to check
; when states are switched. Here is what the switches represent:
; SWA.7 - starting the program
; SWA.6 - moving to the next state
; SWA.5 - the door needs to be open
; SWA.4 - the PCB is cool enough to touch 
;---------------------------------------------------------	 	 
checkForBuzz:
	jb SWA.7, startStateBeeps
	jb SWA.6, nextStateBeeps
	jb SWA.5, openDoorBeeps
	jb SWA.4, coolEnoughBeeps
	ret


;---------------------------------------------------------
; startStateBeeps:
; This creates the beeping for the start state. 
; Triggered by SWA.7.
;---------------------------------------------------------	 
startStateBeeps:
	jb SWA.7, startStateBeeps
	setb LEDRA.2
	lcall shortBeep
	sjmp checkForBuzz


;---------------------------------------------------------
; nextBeeps:
; This creates the beeping for the next state. 
; Triggered by SWA.6.
;---------------------------------------------------------	 
nextStateBeeps:
	jb SWA.6, nextStateBeeps
	lcall shortBeep
	sjmp checkForBuzz

;---------------------------------------------------------
; openDoorBeeps:
; This creates the beeping for when you need to open the door. 
; Triggered by SWA.5.
;---------------------------------------------------------	 	
openDoorBeeps:
	jb SWA.5, openDoorBeeps
	lcall longBeep
	sjmp checkForBuzz


;---------------------------------------------------------
; coolEnoughBeeps:
; This creates the beeping for when the PCB can be touched.
; Triggered by SWA.4.
;---------------------------------------------------------	 
coolEnoughBeeps:
	jb SWA.4, coolEnoughBeeps
	lcall shortBeep	
	lcall shortBeep
	lcall shortBeep
	lcall shortBeep
	lcall shortBeep
	lcall shortBeep
	sjmp checkForBuzz

;---------------------------------------------------------
; longBeep:
; This creates a long beep, and flashes all the red LEDs. 
;---------------------------------------------------------	 
longBeep:
	mov LEDRA, #11111111B
	mov LEDRB, #11111111B 
	mov LEDRC, #00000011B
    lcall buzzOn
	lcall BeepDelay
	lcall BeepDelay
	lcall BeepDelay
	lcall BeepDelay
	lcall BeepDelay
	lcall BeepDelay
	lcall BeepDelay
	lcall BeepDelay
	mov LEDRA, #00000000B
	mov LEDRB, #00000000B 
	mov LEDRC, #00000000B
    lcall buzzOff
    lcall BeepDelay
    ret

;---------------------------------------------------------
; shortBeep:
; This creates a short beep, and flashes all the red LEDs. 
;---------------------------------------------------------	 
shortBeep:
	mov LEDRA, #11111111B
	mov LEDRB, #11111111B
	mov LEDRC, #00000011B
    lcall buzzOn
	lcall BeepDelay
	lcall BeepDelay
	mov LEDRA, #00000000B
	mov LEDRB, #00000000B 
	mov LEDRC, #00000000B
    lcall buzzOff
    lcall BeepDelay
    ret
    
;---------------------------------------------------------
; buzzOn:
; This turns on the buzzer.
;---------------------------------------------------------	 
buzzOn:
	setb ET1
	ret


;---------------------------------------------------------
; buzzOff:
; This turns off the buzzer.
;---------------------------------------------------------	
buzzOff:
	clr ET1
	ret


;---------------------------------------------------------
; BeepDelay:
; A <0.5sec delay that is used to create the long and short beeps.
;---------------------------------------------------------	
BeepDelay:
	mov R2, #20
delay3: mov R1, #250
delay2: mov R0, #250
delay1: djnz R0, delay1
	djnz R1, delay2
	djnz R2, delay3
	ret
	
$LIST	