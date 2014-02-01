;buzzer_02.asm: should do a countdown timer too

$MODDE2

org 0000H
	ljmp myprogram
	
org 000BH
	ljmp ISR_timer0
	
org 001BH
	ljmp ISR_timer1
	
DSEG at 30H
count10ms: ds 1
countdown10ms: ds 1
sec:   ds 1
min:   ds 1
hrs:     ds 1
meridiem:  ds 1 ;keeps track of am/pm
secAlarm: ds 1
minAlarm: ds 1
hrsAlarm: ds 1
meridiemAlarm: ds 1

BSEG
still12: dbit 1
still12Alarm: dbit 1

CSEG

; Look-up table for 7-segment displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H
    DB 0FFH ; All segments off

XTAL           EQU 33333333
FREQ_0         EQU 100
TIMER0_RELOAD  EQU 65536-(XTAL/(12*FREQ_0)) ;clock
FREQ_1 		   EQU 2000 ;lets face it 2000hz is irritating as hell, 1000hz is way less awful
TIMER1_RELOAD  EQU 65536-(XTAL/(12*2*FREQ_1)) ;buzz

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
    jb SWA.0, ISR_Timer0_L0 ; Setting up time.  Do not increment anything
    
    ; Increment the counter and check if a second has passed
    
	inc count10ms
    mov a, count10ms
    cjne A, #100, ISR_Timer0_L0
    mov count10ms, #0
    
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

    mov a, hrs
    add a, #1
    da a
    mov hrs, a
    
    lcall checkMeridiem
    
    cjne A, #13H, ISR_Timer0_L0
    mov hrs, #1
    
    jb SWA.1, ISR_Timer_Countdown ;setting up alarm, do not display time
   
ISR_Timer0_L0:

	; Update the display.  This happens every 10 ms
	mov dptr, #myLUT
  
 	mov HEX0, meridiem
 	
	mov a, sec
	anl a, #0fH
	movc a, @a+dptr
	mov HEX2, a
	mov a, sec
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX3, a

	mov a, min
	anl a, #0fH
	movc a, @a+dptr
	mov HEX4, a
	mov a, min
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX5, a

	mov a, hrs
	anl a, #0fH
	movc a, @a+dptr
	mov HEX6, a
	mov a, hrs
	jb acc.4, ISR_Timer0_L1
	mov a, #0A0H
	
ISR_Timer0_L1:
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX7, a
	
ISR_Timer_Countdown:
	mov a, SWC
	anl a, #00000001B
	jz  ISR_End ;if we haven't pressed start yet, don't countdown

	dec countdown10ms
    mov a, countdown10ms
    cjne A, #100, ISR_End
    mov countdown10ms, #0
    
    mov a, secAlarm
    anl a, #0FH
    cjne A, #0, regularSec
    mov a, secAlarm
    swap a
    subb a, #1
    orl a, #10010000B
    swap a
    sjmp shiftBackSec
regularSec:
 	mov a, secAlarm
	subb a, #1  
shiftBackSec:
    mov secAlarm, a
    cjne A, #00H, ISR_End
    mov minAlarm, #59
   ; cjne A, #00H, ISR_End
   ; mov minAlarm, A
   ; cjne A, #00H, ISR_End
   ; mov hrsAlarm, A
   ; cjne A, #00H, ISR_End
   ; mov secAlarm, #59

    mov a, minAlarm
    subb a, #1
   ; da a
    mov minAlarm, a
    cjne A, #00H, ISR_End
    mov minAlarm, #59

    mov a, hrsAlarm
    subb a, #1
   ; da a
    mov hrsAlarm, a
    
    cjne A, #0H, ISR_End
    mov hrsAlarm, #12
    
    lcall DisplayAlarm
	

ISR_End:
	; Restore used registers
	pop dpl
	pop dph
	pop acc
	pop b
	pop psw    
	reti

;--------------------------------------   
;--------------------------------------   
;--------------------------------------      
;--------------------------------------      
   
ISR_Timer1:
	clr TF1 ;may not be necessary
	cpl P2.0
	cpl P2.1
    mov TH1, #high(TIMER1_RELOAD)
    mov TL1, #low(TIMER1_RELOAD)
	reti
	
;--------------------------------------   
;--------------------------------------   
;--------------------------------------      
;--------------------------------------  

Init_Timer0:	
	mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 ; Disable timer 0
	clr TF0
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    setb TR0 ; Enable timer 0
    setb ET0 ; Enable timer 0 interrupt
    ret
    
Init_Timer1:	
	mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR1 ; Disable timer 1
	clr TF1
    mov TH1, #high(TIMER1_RELOAD)
    mov TL1, #low(TIMER1_RELOAD)
    setb TR1 ; Enable timer 1, dont set interrupt yet
    ret


;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------

myprogram:
	mov SP, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	mov P2MOD, #00000011B ; P2.0, P2.1 are outputs.
	setb P2.0
	setb p2.1

	mov sec, #50H
	mov min, #59H
	mov hrs, #11H
	mov meridiem, #08H
	clr still12
	
	mov secAlarm, #15H
	mov minAlarm, #15H
	mov hrsAlarm, #01H
	mov meridiemAlarm, #0CH
	clr still12Alarm

	lcall Init_Timer0 ;set up
	lcall Init_Timer1
	
    setb EA  ; Enable all interrupts

M0: ;clock set loop
	
	jnb SWA.3, M0_Test
	lcall Alarm
	clr LEDRA.1
M0_Test:
	jb SWA.1, A0 ;alarm set mode
	jnb SWA.0, M0 ;clock set mode
	
	jb KEY.3, M1
    jnb KEY.3, $
    mov a, hrs
	add a, #1
	da a
	mov hrs, a
	lcall checkMeridiem
    cjne A, #13H, M1
    mov hrs, #1
M1:	
	jb KEY.2, M2
    jnb KEY.2, $
    mov a, min
	add a, #1
	da a
	mov min, a	
    cjne A, #60H, M2
    mov min, #0
M2:	
	jb KEY.1, M3
	jnb KEY.1, $
	mov a, sec
	add a, #1
	da a
	mov sec, a
    cjne A, #60H, M3
    mov sec, #0
M3:	
	ljmp M0
	
A0: ;alarm set loop
	jnb SWA.1, M0 
	lcall DisplayAlarm
	
	jb KEY.3, A1
hrdisp:	
	lcall DisplayAlarm
    jnb KEY.3, hrdisp
    mov a, hrsAlarm
	add a, #1
	da a
	mov hrsAlarm, a
    cjne A, #13H, A1
    mov hrsAlarm, #1
A1:	
	jb KEY.2, A2
mindisp:
	lcall DisplayAlarm
    jnb KEY.2, mindisp
    mov a, minAlarm
	add a, #1
	da a
	mov minAlarm, a	
    cjne A, #60H, A2
    mov minAlarm, #0
A2:	
	jb KEY.1, A3
secdisp:
	lcall DisplayAlarm
	jnb KEY.1, secdisp
	mov a, secAlarm
	add a, #1
	da a
	mov secAlarm, a
    cjne A, #60H, A3
    mov secAlarm, #0
A3:	
	ljmp A0

;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------------
; here's all the subroutines called in the main program

Alarm:
	setb LEDRA.1
	jb SWA.7, startStateBeeps
	jb SWA.6, nextStateBeeps
	jb SWA.5, openDoorBeeps
	jb SWA.4, coolEnoughBeeps
	jb SWA.3, Alarm
	ret
	
startStateBeeps:
	jb SWA.7, startStateBeeps
	setb LEDRA.2
	lcall shortBeep
	sjmp Alarm
	
nextStateBeeps:
	jb SWA.6, nextStateBeeps
	lcall shortBeep
	sjmp Alarm
	
openDoorBeeps:
	jb SWA.5, openDoorBeeps
	lcall longBeep
	sjmp Alarm
	
coolEnoughBeeps:
	jb SWA.4, coolEnoughBeeps
	lcall shortBeep	
	lcall shortBeep
	lcall shortBeep
	lcall shortBeep
	lcall shortBeep
	lcall shortBeep
	sjmp Alarm

	
longBeep:
	mov LEDRA, #11111111B
	mov LEDRB, #11111111B 
	mov LEDRC, #00000011B
    lcall buzzOn
	lcall WaitALittle
	lcall WaitALittle
	lcall WaitALittle
	lcall WaitALittle
	lcall WaitALittle
	lcall WaitALittle
	lcall WaitALittle
	lcall WaitALittle
	mov LEDRA, #00000000B
	mov LEDRB, #00000000B 
	mov LEDRC, #00000000B
    lcall buzzOff
    lcall WaitALittle
    ret
	
shortBeep:
	mov LEDRA, #11111111B
	mov LEDRB, #11111111B
	mov LEDRC, #00000011B
    lcall buzzOn
	lcall WaitALittle
	lcall WaitALittle
	mov LEDRA, #00000000B
	mov LEDRB, #00000000B 
	mov LEDRC, #00000000B
    lcall buzzOff
    lcall WaitALittle
    ret
    
buzzOn:
	setb ET1
	ret
	
buzzOff:
	clr ET1
	ret
	
;For a 33.33MHz clock, one cycle takes 30ns
WaitALittle:
	mov R2, #20
L3: mov R1, #250
L2: mov R0, #250
L1: djnz R0, L1
	djnz R1, L2
	djnz R2, L3
	ret
	
;---------------------------for when we display the alarm	
DisplayAlarm:
	; Update the display
	mov dptr, #myLUT
	
	mov HEX0, #0FFH ;clear am/pm display	

	mov a, secAlarm
	anl a, #0fH
	movc a, @a+dptr
	mov HEX2, a
	mov a, secAlarm
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX3, a

	mov a, minAlarm
	anl a, #0fH
	movc a, @a+dptr
	mov HEX4, a
	mov a, minAlarm
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX5, a

	mov a, hrsAlarm
	anl a, #0fH
	movc a, @a+dptr
	mov HEX6, a
	mov a, hrsAlarm
	jb acc.4, exitDispAlarm
	mov a, #0A0H	
exitDispAlarm:
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX7, a
	ret
	
;-------this checks and changes am/pm
checkMeridiem:
	mov a, hrs
    cjne A, #12H, not12 ;if it isn't 12, leave
    
    jb still12, out ;if it is 12 but was previously 12, do nothing
      
changeMeridiem: ;if it is 12 but was not previously 12 - now change meridiem
   	mov a, meridiem
   	cpl acc.2 ; changes 08H to 0CH and vice versa
  	mov meridiem, a	
	;display am/pm
	mov HEX0, meridiem
not12:
	clr still12
out:
	ret
	
END

