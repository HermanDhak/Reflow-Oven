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
    ;lcall CheckState
    ;lcall CheckStart
    ;lcall CheckTemp
    ;lcall CheckTimer
    ;Increment the counter and check if a second has passed
    
    jb started, startClock ;**********************************************
    mov HEX0, #0C0H ;0
    mov HEX1, #0FFH
    mov HEX2, #0C0H ;0
    mov HEX3, #0FFH
    mov HEX4, #0C0H ;0
    mov HEX5, #0FFH
    mov HEX6, #0FFH
    mov HEX7, #0FFH
    ljmp ISR_End
     
startClock:    
	inc count10ms
    mov a, count10ms
    cjne A, #100, ISR_Timer0_L0
    mov count10ms, #0
    
    mov a, sec
    cpl LEDRA.5 ;TEST CODE ****************************************
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

    mov a, hrs
    add a, #1
    da a
    mov hrs, a
    cjne A, #13H, ISR_Timer0_L0
    mov hrs, #1
    
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
	
	jb soak, ISR_Timer_Countdown ;go to countdown
    jb reflow, ISR_Timer_Countdown
    
    mov HEX0, #0FFH
    mov HEX1, #0FFH
    mov HEX2, #0FFH
    mov HEX3, #0FFH
    
    sjmp ISR_End
       
ISR_Timer_Countdown:
	;mov a, SWC
	;anl a, #00000001B ;sw 16 is the "start" button
	;jz  ISR_End ;if we haven't pressed start yet, don't countdown
    
;--------- time conditions
    mov a, secAlarm
    anl a, #00FH
    cjne A, #0, regularSec ;can we subtract from lsb seconds?
    mov a, secAlarm ;nope, need to borrow
    anl a, #0F0H
    swap a
    cjne a, #0, borrowmsbSec ;can we borrow from msb seconds?
   	; nope
    ; 00 00 00 CASE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    mov LEDRA, #0FFH ;celebrate with lights! COUNTER DONE
    
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
	
    sjmp ISR_End
    
regularSec: ; -- -- -- ## case
 	mov a, secAlarm
	subb a, #1
	mov secAlarm, a
	sjmp ISR_END

borrowmsbSec: ;-- -- #0 case
    subb a, #1
    orl a, #10010000B
    swap a
    mov secAlarm, a
        
 

;-----------------------

ISR_End:
	; Restore used registers
	pop dpl
	pop dph
	pop acc
	pop b
	pop psw    
	reti

	
init_Timers: ;Dummy SR	
	mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 ; Disable timer 0
	clr TF0
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    setb TR0 ; Enable timer 0
    setb ET0 ; Enable timer 0 interrupt
    ret	
;--------------------------------------   
;--------------------------------------   
;--------------------------------------      
;--------------------------------------  
;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
$LIST