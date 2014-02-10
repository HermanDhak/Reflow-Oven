$MODDE2

org 0000H
   ljmp MyProgram
   
org 000BH
	ljmp ISR_timer0

org 001BH ;ISR for timer 1
	ljmp ISR_timer1	
	
XTAL           EQU 33333333
FREQ_0         EQU 100
TIMER0_RELOAD  EQU 65536-(XTAL/(12*FREQ_0)) ;clock

FREQ_1 		   EQU 2000 ;lets face it 2000hz is irritating as hell, 1000hz is way less awful
TIMER1_RELOAD  EQU 65536-(FREQ/(12*2*FREQ_1)) ;buzz

FREQ   EQU 33333333
BAUD   EQU 115200
T2LOAD EQU 65536-(FREQ/(32*BAUD))

MISO   EQU  P0.0 
MOSI   EQU  P0.1 
SCLK   EQU  P0.2
CE_ADC EQU  P0.3

	DSEG at 30H
x:      		ds 4
y:      		ds 4
w:				ds 4
bcd:			ds 4
tempMin:		ds 1
tempSec: 		ds 1
bcdSTemp:		ds 3 ;Temp values to write to LCD screen
bcdSTime:		ds 3 ;Temp values to write to LCD screen
bcdRTemp:		ds 3 ;Temp values to write to LCD screen
bcdRTime:		ds 3 ;Temp values to write to LCD screen
bcdCTemp:		ds 3
bcdJTemp:		ds 3
currentTemp:  	ds 1
junctionTemp:	ds 1
soakTemp:  		ds 1
reflowTemp:  	ds 1
soakTime:  		ds 1
reflowTime:  	ds 1
op:     		ds 1
count10ms: 		ds 1
sec:   			ds 1
min:   			ds 1
secAlarm: 		ds 1
minAlarm: 		ds 1

	BSEG
mf:      	dbit 1
started:	dbit 1
preSoak:   	dbit 1
soak:	 	dbit 1
preReflow: 	dbit 1
reflow:  	dbit 1
cooling: 	dbit 1
valChanged: dbit 1
secondPassed: dbit 1

CSEG

$include(LCDStates.asm)
$include(countdownAndClock.asm)
$include(tempAndSPI.asm)
$include(math32.asm)
$include(buzzerSubroutines.asm)

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
Start_Line_Str:
	DB 'Start: KEY.3    ', 0
SelectProfile_Str:
	DB 'Select Profile: ', 0
Profiles_Str:
	DB 'SW 0 1 2(Custom)', 0
CurrentTemp_Str:
	DB 'To=', 0	
JunctionTemp_Str:
	DB '  Tj=', 0
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
    DB 0FFH

MyProgram:
	mov sp, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	
	orl P0MOD, #00111000b ; make all CEs outputs
	mov P2MOD, #00001111B ; P2.0...2.3 are outputs! Lots of buzzers!!!!!!
	setb P2.0
	setb P2.1
	setb P2.2
	setb P2.3
	
	mov sec, #00H
	mov min, #00H

	mov secAlarm, #00H
	mov minAlarm, #00H 
    
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
	clr started
	
	lcall LCD_init
	setb CE_ADC
	lcall INIT_SPI
    lcall InitSerialPort
    lcall init_Timers
    
    setb EA
    
initializationState:
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
	jnb KEY.2, selectProfile
	clr a
	mov bcd+0, a
	mov bcd+1, a
	sjmp getUserInput_L0
	
keepSettings:
	;---- FIGURE OUT WHAT TO DO WITH BEEPS HERE----
	lcall LCD_init
	lcall initialLCD_Message
	setb P2.0 
	lcall wait1s
	clr P2.0 
	clr a
	mov bcd+0, a
	mov bcd+1, a
	ljmp loadPreSoakState



;USER INPUT ===========================================
selectProfile:
	mov a, #80H
	lcall LCD_command
	mov dptr, #SelectProfile_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #Profiles_Str
	lcall writeString
	jb SWA.2, debounceSWA2
	;jb SWA.0, loadProfile0 ==============ADD These later
	;jb SWA.1, loadProfile1
	sjmp selectProfile

debounceSWA2:
  	jnb SWA.2, rewriteSoakTemp
  	sjmp debounceSWA2
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
	
	;Jump to next input
	jnb KEY.3, rewriteSoakTimeDebounce 
	lcall readNumber
	jnc rewriteSoakTemp
	lcall shift_digits
	BCD_Dump(bcdSTemp+2,bcdSTemp+1,bcdSTemp+0)
	
	ljmp rewriteSoakTemp

rewriteSoakTimeDebounce:
	jnb KEY.3, rewriteSoakTimeDebounce
	clr a
	mov bcd+0, a
	mov bcd+1, a
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
	clr a
	mov bcd+0, a
	mov bcd+1, a
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
	clr a
	mov bcd+0, a
	mov bcd+1, a
rewriteReflowTime:
	mov a, #80H
	lcall LCD_command
	mov dptr, #Start_Line_Str
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
	
	lcall LCD_init
	lcall reloadUserVariables
	sjmp loadPreSoakState
			
;END USER INPUT

;============================================================
;BEGIN STATE MACHINE HERE:	

loadPreSoakState:
	lcall LCD_init
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #preSoakState_Str
	lcall writeString
	
	lcall shortBeep
	setb preSoak
	setb started
preSoakState:
;Displays the current state, temp and elapsed time and keeps 
;updating the current temperature variable 
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel
	lcall calculateRoomTemp
	
	mov junctionTemp, x+0
	asciiConvert(junctionTemp, BCDJTemp+2,BCDJTemp+1,BCDJTemp+0)
	
	lcall Opamp
	lcall addingtemps
	
	mov currentTemp, x+0
	asciiConvert(currentTemp, BCDCTemp+2,BCDCTemp+1,BCDCTemp+0)
	
	mov LEDRA, #00000001B
	
;Uncomment this later ********************************
	;jnb preSoak, loadSoakState
	mov a, SWB
	jb acc.2, loadSoakState
	ljmp preSoakState

loadSoakState:
	lcall LCD_init
	lcall shortBeep
	mov a, #80H
	lcall LCD_command
	mov dptr, #SoakState_Str
	lcall writeString
	
	BCDReverseDump(bcdSTime+2,bcdSTime+1,bcdSTime+0)
	lcall bcd2hex
	mov secAlarm, bcd+0
	mov minAlarm, bcd+1
	setb soak
soakState:
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel
	lcall calculateRoomTemp
	
	mov junctionTemp, x+0
	asciiConvert(junctionTemp, BCDJTemp+2,BCDJTemp+1,BCDJTemp+0)
	
	lcall Opamp
	lcall addingtemps
	
	mov currentTemp, x+0
	asciiConvert(currentTemp, BCDCTemp+2,BCDCTemp+1,BCDCTemp+0)

	mov LEDRA, #00000010B
	
	jnb soak, loadPreReflowState
	ljmp soakState

loadPreReflowState:
	lcall LCD_init
	lcall shortBeep
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #preReflowState_Str
	lcall writeString
	
	setb preReflow
preReflowState:
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel
	lcall calculateRoomTemp
	
	mov junctionTemp, x+0
	asciiConvert(junctionTemp, BCDJTemp+2,BCDJTemp+1,BCDJTemp+0)
	
	lcall Opamp
	lcall addingtemps
	
	mov currentTemp, x+0
	asciiConvert(currentTemp, BCDCTemp+2,BCDCTemp+1,BCDCTemp+0)

	mov LEDRA, #00000100B
	
	;jnb preReflow, loadReflowState
	mov a, SWB
	jb acc.2, loadReflowState
	ljmp preReflowState
	
loadReflowState:
	lcall LCD_init
	lcall shortBeep
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #reflowState_Str
	lcall writeString
	
	mov a, #0
	mov tempMin, a
	mov tempSec, a
	mov x+0, reflowTime
	mov x+1, a
	lcall convertToMinutes
	mov secAlarm, tempSec
	mov minAlarm, tempMin
	setb reflow
reflowState:
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel
	lcall calculateRoomTemp
	
	mov junctionTemp, x+0
	asciiConvert(junctionTemp, BCDJTemp+2,BCDJTemp+1,BCDJTemp+0)
	
	lcall Opamp
	lcall addingtemps
	
	mov currentTemp, x+0
	asciiConvert(currentTemp, BCDCTemp+2,BCDCTemp+1,BCDCTemp+0)

	
	mov LEDRA, #00001000B
	
	jnb reflow, loadCoolingState
	ljmp reflowState
	
loadCoolingState:
	lcall LCD_init
	lcall shortBeep
		
coolingState:
	mov a, #80H
	lcall LCD_command
	mov dptr, #coolingState_Str
	lcall writeString
	
	mov LEDRA, #00010000B
	
	mov a, SWB
	jb acc.6, doneThisShit
	ljmp coolingState

doneThisShit:
	sjmp doneThisShit

	
END	