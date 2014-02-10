$NOLIST

;-----------------------------
;-----------------------------
;-----------------------------
;-----------------------------

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
	;Checks if a state needs to change
    lcall checkState
	
    ;Increment the counter and check if a second has passed
    
    jb started, startClock ;**********************************************IS THIS ACTUALLY BEING SET SOMEWHERE
    mov HEX0, #0FFH
    mov HEX1, #0FFH
    mov HEX2, #0FFH
    mov HEX3, #0FFH
    mov HEX4, #0FFH
    mov HEX5, #0FFH
    mov HEX6, #0FFH
    mov HEX7, #0FFH
    ljmp ISR_end
     
startClock:  
	
	;Waits until a seconds has passed  
	inc count10ms
    mov a, count10ms
    clr secondPassed
    cjne A, #100, ISR_Timer0_L0
    setb secondPassed
    mov count10ms, #0
    
    ;Updates the LCD screen with temp values
    mov a, #0C0H
	lcall LCD_command
	mov dptr, #currentTemp_Str
	lcall writeString
	
	mov a, bcdCTemp+2
	lcall LCD_put
	mov a, bcdCTemp+1
	lcall LCD_put
	mov a, bcdCTemp+0
	lcall LCD_put
	mov a, #'C'
	lcall LCD_put
	
	mov dptr, #junctionTemp_Str
	lcall writeString
	
	mov a, bcdJTemp+2
	lcall LCD_put
	mov a, bcdJTemp+1
	lcall LCD_put
	mov a, bcdJTemp+0
	lcall LCD_put
	mov a, #'C'
	lcall LCD_put
	
	;Elapsed time math
    mov a, sec
    add a, #1
    da a
    mov sec, a
    cjne A, #60H, ISR_Timer0_L0
    mov sec, #0
 
    mov a, min
    add a, #1
    da a
    mov min, a
    cjne A, #60H, ISR_Timer0_L0
    mov min, #0

ISR_Timer0_L0:

	; Update the display.  This happens every 10 ms
	mov dptr, #myLUT
	
	mov a, sec
	anl a, #0fH
	movc a, @a+dptr
	mov HEX4, a
	mov a, sec
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX5, a

	mov a, min
	anl a, #0fH
	movc a, @a+dptr
	mov HEX6, a
	mov a, min
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX7, a 

	jnb secondPassed, ISR_End
		
	jb soak, ISR_Timer_Countdown ;go to countdown
    jb reflow, ISR_Timer_Countdown
    
    mov HEX0, #0FFH
    mov HEX1, #0FFH
    mov HEX2, #0FFH
    mov HEX3, #0FFH
    
    sjmp ISR_End
       
ISR_Timer_Countdown:
    mov a, secAlarm
    anl a, #00FH
    cjne A, #0, regularSec ;can we subtract from lsb seconds?
    mov a, secAlarm ;nope, need to borrow
    anl a, #0F0H
    swap a
    cjne a, #0, borrowmsbSec ;can we borrow from msb seconds?
   	
   	;Called minAlarm but actually hundreds digit of seconds
   	mov a, minAlarm
    anl a, #00FH
    cjne A, #0, borrowLSBMin
    mov LEDRA, #0FFH ;celebrate with lights! COUNTER DONE
    sjmp displayCountdown
    
regularSec: ; -- -- -- ## case
 	mov a, secAlarm
	subb a, #1
	mov secAlarm, a
	sjmp displayCountdown

borrowmsbSec: ;-- -- #0 case
    subb a, #1
    orl a, #10010000B
    swap a
    mov secAlarm, a
    sjmp displayCountdown
        
borrowlsbMin: ;-- ## 00 case
	mov a, minAlarm
	subb a, #1
	mov minAlarm, a
	mov secAlarm, #99H
	sjmp displayCountdown

;-----------------------
displayCountdown:
	mov a, secAlarm
	anl a, #0fH
	movc a, @a+dptr
	mov HEX0, a
	mov a, secAlarm
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX1, a
	mov a, minAlarm
	anl a, #0fh
	movc a, @a+dptr
	mov HEX2, a
	
ISR_End:
	; Restore used registers
	pop dpl
	pop dph
	pop acc
	pop b
	pop psw    
	reti

	
init_Timers:	
	;TIMER 0 (USED FOR CLOCK/DISPLAY/STATE CHANGE CHECKS)
	mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 
	clr TF0
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    setb TR0
    setb ET0
    
    ;TIMER 1 (USED FOR BUZZERS)
    mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR1
	clr TF1
    mov TH1, #high(TIMER1_RELOAD)
    mov TL1, #low(TIMER1_RELOAD)
    setb TR1
    
    ret	

checkState:
	jb preSoak, preSoakTempCheck
	jb soak, soakTimeCheck
	jb preReflow, preReflowTempCheck
	jb reflow, reflowTimeCheck
	ret
	
preSoakTempCheck:
	;clr mf
	;mov x+0, currentTemp
	;mov x+1, #0
	;mov y+0, soakTemp
	;mov y+1, #0
	;lcall x_gteq_y
	;jb mf, changeToSoak
	clr c
	mov a, soakTemp
	subb a, #5
	subb a, currentTemp
	jc changeToSoak
	ret
changeToSoak:	
	clr preSoak
	ret

soakTimeCheck:
	mov a, minAlarm
	cjne a, #0, changeToPreReflow
	
	mov a, secAlarm
	cjne a, #0, changeToPreReflow
	
	clr soak
	ret
changeToPreReflow:
	ret
		
preReflowTempCheck:
	clr c
	mov a, soakTemp
	subb a, #5
	subb a, currentTemp
	jc changeToSoak
	ret
changeToReflow:	
	clr preReflow
	ret
	
reflowTimeCheck:
	mov a, minAlarm
	cjne a, #0, changeToCooling
	mov a, secAlarm
	cjne a, #0, changeToCooling
	
	clr reflow
	ret
changeToCooling:
	ret
	
$LIST