;ovenSSRProgram.asm
;---------------------------------------
;This file contains the subroutines used for routine testing of state change bit triggers.
;As this code will be integrated into the main state machine program many parts will be left 
;unimplemented with just commments referencing code/instrcutions that have yet to be written.
;---------------------------------------

;---------------------------------------
;ISR Subroutine
;Purpose: periodically checks two state triggers, doneIP, atZero and heatDone. If either bit is set
;another bit indicating what state to transition to is set. The transition bit to be set depends on
;which state trigger bit is set. State transition bits: Presoak, Soak, Preflow, Reflow
;--------------------------------------

ISR_Timer0:
	; Reload the timer
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    
    ; Save used register into the stack
    push psw
    push b
    push acc
    push dph
    push dpl
    
    
ISR_0:
    ;jb SWA.0, ISR_Timer0_L0 ; Setting up time.  Do not increment anything
    lcall CheckState
    lcall CheckStart
    lcall CheckTemp
    lcall CheckTimer
    
    ;jb SWA.1, ISR_Timer0_L1 ;setting up alarm, do not display time
	
ISR_End:
	; Restore used registers
	pop dpl
	pop dph
	pop acc
	pop b
	pop psw    
	reti
	
;-------------------------------------
;CheckState
;Purpose: checks a series of bits to determine which state the program is currently in.
;Detemines which state triggers checks to call based on current state.
;-------------------------------------
CheckState:
	jb Presoak, doPresoak
	jb Soak, doSoak
	jb Preflow, doPreflow
	jb Reflow, doReflow
	ret

;-------------------------------------
;doPresoak:
;Purpose: is it the temp to go to soak?
;-------------------------------------
doPresoak:
	lcall checkTemp1
	ret

;-------------------------------------
;doSoak:
;Purpose: is it time to go to preflow?
;-------------------------------------
doSoak:
	lcall checkTime1
	ret
	

;-------------------------------------
;doPreflow:
;Purpose: is it temp to go to reflow?
;-------------------------------------
doPreflow:
	lcall checkTemp2
	ret
	
;-------------------------------------
;doReflow:
;Purpose: is it time to go to cooldown?
;-------------------------------------
doReflow:
	lcall checkTime2
	ret
	
;-------------------------------------
;checkTemp1:
;Purpose: Gets the current temperature, and compares it with the target soak temp. Sets soak and clears
; presoak if the correct temperature has been achieved. 
; currentTemp: the current temperature in the oven
; soakDesiredTemp: the user input for the desired soak temperature
;******************* MAY CHANGE VARIABLE NAMES!
;-------------------------------------
checkTemp1:
	mov a, currentTemp
	mov b, soakDesiredTemp
	subb a, b
	cjne a, #0, endCheckTemp1
	;else, the temperatures match!
	clr Presoak
	setb Soak
	;maybe fill up countdown timer here???
endCheckTemp1:
	ret
	
;-------------------------------------
;checkTemp2:
;Purpose: Gets the current temperature, and compares it with the target reflow temp. Sets reflow and clears
; preflow if the correct temperature has been achieved. 
; currentTemp2: the current temperature in the oven
; reflowDesiredTemp: the user input for the desired reflow temperature
;******************* MAY CHANGE VARIABLE NAMES!
;-------------------------------------
checkTemp2:
	mov a, currentTemp
	mov b, reflowDesiredTemp
	subb a, b
	cjne a, #0, endCheckTemp2
	;else, the temperatures match!
	clr Preflow
	setb Reflow 
	;maybe fill up countdown timer here???
endCheckTemp2:
	ret


;-----------------------------
;checkTime1
;Purpose: checks if the timer has reached the end of its countdown (ie 00:00:00). If has, Soak state bit
;bit is cleared and Preflow bit is set to indicate state machine needs to transition to Reflow Preheat next. 
;Otherwise state bits remain unchanged. 
;VARIABLES' NAMES MAY CHANGE AFTER INTEGRATION WITH STATE MACHNINE
;currently call on: alrmHrs, alrmMins, alrmSecs
;---------------------------------------
checkTime1:
	mov a, alrmHrs
	cjne a, #0, endTime1Check
	
	mov a, alrmMins
	cjne a, #0, endTime1Check
	
	mov a, alrmSecs
	cjne a, #0, endTime1Check
	
	clr Soak
	setb Preflow
	
endTime1Check:
	ret
	
;---------------------------------------	
	
;-----------------------------
;checkTime2
;Purpose: checks if the timer has reached the end of its countdown (ie 00:00:00). If has, Reflow state bit
;bit is cleared and Cooling bit is set to indicate state machine needs to transition to Cooling stage next. 
;Otherwise state bits remain unchanged. 
;VARIABLES' NAMES MAY CHANGE AFTER INTEGRATION WITH STATE MACHNINE
;currently call on: alrmHrs, alrmMins, alrmSecs
;---------------------------------------
checkTime2:
	mov a, alrmHrs
	cjne a, #0, endTime2Check
	
	mov a, alrmMins
	cjne a, #0, endTime2Check
	
	mov a, alrmSecs
	cjne a, #0, endTime2Check
	
	clr Reflow
	setb Cooling
	
endTime2Check:
	ret