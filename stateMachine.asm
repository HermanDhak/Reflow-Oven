$MODDE2

org 0000H
   ljmp MyProgram


FREQ_1 		   EQU 2000 ;lets face it 2000hz is irritating as hell, 1000hz is way less awful
TIMER1_RELOAD  EQU 65536-(FREQ/(12*2*FREQ_1)) ;buzz

	DSEG at 30H
x:      		ds 2
y:      		ds 2
bcd:			ds 2
bcdSTemp:		ds 3 ;Temp values to write to LCD screen
bcdSTime:		ds 3 ;Temp values to write to LCD screen
bcdRTemp:		ds 3 ;Temp values to write to LCD screen
bcdRtime:		ds 3 ;Temp values to write to LCD screen
currentTemp:  	ds 2
soakTemp:  		ds 2
reflowTemp:  	ds 2
soakTime:  		ds 2
reflowTime:  	ds 2
junctionTemp:   ds 1  ;Store measured temps here
ovenTemp:       ds 1

	BSEG
mf:      	dbit 1
preSoak:   	dbit 1
soak:	 	dbit 1
preReflow: 	dbit 1
reflow:  	dbit 1
cooling: 	dbit 1
valChanged: dbit 1

CSEG

$include(math16.asm)
$include(LCDStates.asm)

STemp_Str:
	DB 'ST=', 0
STime_Str:
	DB 'C  St=', 0
RTemp_Str:
	DB 'RT=', 0
RTime_Str:
	DB 'C  Rt=', 0			
Keep_Settings1_Str:
	DB 'Keep settings?  ', 0
Keep_Settings2_Str:
	DB 'KEY3=Yes KEY2=No', 0
Next_Line_Str:
	DB 'Next: KEY.3     ', 0
JuntionTemp_Str:
	DB 'Tj=', 0
soakTemp_Str:
	DB 'SoakTemp:   ', 0
soakTime_Str:
	DB 'SoakTime:   ', 0
reflowTemp_Str:
	DB 'ReflowTemp: ', 0
reflowTime_Str:
	DB 'ReflowTime: ', 0	
ErrorMessage1_Str:
	DB 'Value(s) entered', 0
ErrorMessage2_Str:
	DB 'out of range    ', 0
preSoakState_Str:
	DB 'Soak Preheat    ', 0
soakState_Str:
	DB 'Soaking         ', 0
preReflowState_Str:
	DB 'Reflow Preheat  ', 0
reflowState_Str:
	DB 'Reflowing       ', 0
coolingState_Str:
	DB 'Cooling         ', 0	
	
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H 

MyProgram:
	mov sp, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	
	mov currentTemp, #0
	mov soakTemp, #120
	mov soakTime, #90
	mov reflowTemp, #210
	mov reflowTime, #35
	
	clr preSoak
	clr soak
	clr preReflow
	clr reflow
	clr cooling
	
	lcall LCD_init
	
initializationState:
	mov soakTemp, #120
	mov reflowTemp, #210
	mov soakTime, #90
	mov reflowTime, #35
	asciiConvert(soakTemp, bcdSTemp+2, bcdSTemp+1, bcdSTemp+0)
	asciiConvert(soakTime, bcdSTime+2, bcdSTime+1, bcdSTime+0)
	asciiConvert(reflowTemp, bcdRTemp+2, bcdRTemp+1, bcdRTemp+0)
	asciiConvert(reflowTime, bcdRtime+2, bcdRtime+1, bcdRtime+0)

	lcall initialLCD_Message ;display initial message
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #Keep_Settings1_str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #Keep_Settings2_str
	lcall writeString
	

getUserInput_L0:
	jnb KEY.3, keepSettings
	jnb KEY.2, rewriteSoakTemp
	sjmp getUserInput_L0
	
keepSettings:
	;---- FIGURE OUT WHAT TO DO WITH BEEPS HERE----
	lcall initialLCD_Message
	setb P2.0 
	lcall wait1s
	clr P2.0
	setb preSoak ;This enables timer to load the appropriate values
	ljmp preSoakState


;USER INPUT ===========================================
rewriteSoakTemp:
	mov a, #80H
	lcall LCD_command
	mov dptr, #Next_Line_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #soakTemp_Str
	lcall writeString
	
	mov a, bcdSTemp+2
	lcall LCD_put
	mov a, bcdSTemp+1
	lcall LCD_put
	mov a, bcdSTemp+0
	lcall LCD_put
	mov a, #'C'
	lcall LCD_put
	
	jnb KEY.3, rewriteSoakTimeDebounce ;Jump to next input
	lcall readNumber
	jnc rewriteSoakTemp
	lcall shift_digits
	BCD_Dump(bcdSTemp+2,bcdSTemp+1,bcdSTemp+0)
	
	ljmp rewriteSoakTemp

rewriteSoakTimeDebounce:
	jnb KEY.3, rewriteSoakTimeDebounce
rewriteSoakTime:
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #Next_Line_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #soakTime_Str
	lcall writeString
	
	mov a, bcdSTime+2
	lcall LCD_put
	mov a, bcdSTime+1
	lcall LCD_put
	mov a, bcdSTime+0
	lcall LCD_put
	mov a, #'s'
	lcall LCD_put
	
	jnb KEY.3, rewriteReflowTempDebounce ;Jump to next input
	lcall readNumber
	jnc rewriteSoakTime
	lcall shift_digits
	BCD_Dump(bcdSTime+2,bcdSTime+1,bcdSTime+0)
	
	ljmp rewriteSoakTime

rewriteReflowTempDebounce:
	jnb KEY.3, rewriteReflowTempDebounce
rewriteReflowTemp:
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #Next_Line_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #reflowTemp_Str
	lcall writeString
	
	mov a, bcdRTemp+2
	lcall LCD_put
	mov a, bcdRTemp+1
	lcall LCD_put
	mov a, bcdRTemp+0
	lcall LCD_put
	mov a, #'C'
	lcall LCD_put
	
	jnb KEY.3, rewriteReflowTimeDebounce ;Jump to next input
	lcall readNumber
	jnc rewriteReflowTemp
	lcall shift_digits
	BCD_Dump(bcdRTemp+2,bcdRTemp+1,bcdRTemp+0)
	
	ljmp rewriteReflowTemp

rewriteReflowTimeDebounce:
	jnb KEY.3, rewriteReflowTimeDebounce
rewriteReflowTime:
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #Next_Line_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #reflowTime_Str
	lcall writeString
	
	mov a, bcdRTime+2
	lcall LCD_put
	mov a, bcdRTime+1
	lcall LCD_put
	mov a, bcdRTime+0
	lcall LCD_put
	mov a, #'s'
	lcall LCD_put
	
	jnb KEY.3, checkValueDebounce ;Jump to next input
	lcall readNumber
	jnc rewriteReflowTime
	lcall shift_digits
	BCD_Dump(bcdRTime+2,bcdRTime+1,bcdRTime+0)
	
	ljmp rewriteReflowTime
	
; This checks if the entered user values are too high
;If so, they will be rounded down to the nearest acceptable standards	

checkValueDebounce:
	jnb KEY.3, checkValueDebounce
checkValue:
	lcall checkSTemp
	
	jb valChanged, displayErrorMessage
	sjmp displayCorrectedValues
displayErrorMessage:
	mov a, #80H
	lcall LCD_command
	mov dptr, #ErrorMessage1_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #ErrorMessage2_Str
	lcall writeString
		
	lcall wait1s
	lcall wait1s
	
displayCorrectedValues:	
	lcall initialLCD_Message ;display initial message
	
	lcall wait1s
	lcall wait1s
	lcall wait1s
	
	sjmp preSoakState
			
;END USER INPUT

;============================================================
;BEGIN STATE MACHINE HERE:	
init_Timers: ;Dummy SR
	ret


	
preSoakState: ;Dummy test ISR for now
	;Begin ramping up temperature here 
	;display junction temperature and oven temp
	;also write name of state
	mov a, #80H
	lcall LCD_command
	mov dptr, #preSoakState_Str
	lcall writeString
	
	mov LEDRA, #00000001B
	
	mov a, SWB
	jb acc.2, soakState
	sjmp preSoakState

soakState:
	mov a, #80H
	lcall LCD_command
	mov dptr, #SoakState_Str
	lcall writeString
	
	mov LEDRA, #00000010B
	
	mov a, SWB
	jb acc.3, preReflowState
	sjmp soakState

preReflowState:
	mov a, #80H
	lcall LCD_command
	mov dptr, #preReflowState_Str
	lcall writeString
	
	mov LEDRA, #00000100B
	
	mov a, SWB
	jb acc.4, reflowState
	sjmp preReflowState

reflowState:
	mov a, #80H
	lcall LCD_command
	mov dptr, #reflowState_Str
	lcall writeString
	
	mov LEDRA, #00001000B
	
	mov a, SWB
	jb acc.5, coolingState
	sjmp reflowState
	
coolingState:
	mov a, #80H
	lcall LCD_command
	mov dptr, #coolingState_Str
	lcall writeString
	
	mov LEDRA, #00010000B
	
	mov a, SWB
	jb acc.6, doneThisShit
	sjmp coolingState

doneThisShit:
	sjmp doneThisShit
; Put Helper methods at very end of program after
; the states
Wait100ms: ;allows enough time for keypress debounce
	mov R2, #20
L9: mov R1, #250
L8: mov R0, #250
L7: djnz R0, L7 ; 3 machine cycles-> 3*30ns*250=22.5us
	djnz R1, L8 ; 22.5us*250=5.625ms
	djnz R2, L9 ; 5.625ms*20=0.1s (approximately)
	ret

	
END	