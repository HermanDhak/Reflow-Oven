$NOLIST

CSEG

Load_x_32 MAC
	mov x+0, #low (%0 % 0x10000) 
	mov x+1, #high(%0 % 0x10000) 
	mov x+2, #low (%0 / 0x10000) 
	mov x+3, #high(%0 / 0x10000) 
ENDMAC

Load_y_32 MAC
	mov y+0, #low (%0 % 0x10000) 
	mov y+1, #high(%0 % 0x10000) 
	mov y+2, #low (%0 / 0x10000) 
	mov y+3, #high(%0 / 0x10000) 
ENDMAC

Load_x MAC
	mov x+0, #low (%0) 
	mov x+1, #high(%0) 
ENDMAC

Load_y MAC
	mov y+0, #low (%0) 
	mov y+1, #high(%0) 
ENDMAC
	
initialLCD_Message: ;first start up message
	;Line 1
	mov a, #80H
	lcall LCD_command
	mov dptr, #STemp_Str
	lcall writeString
	mov a, bcdSTemp+2
	lcall LCD_put
	mov a, bcdSTemp+1
	lcall LCD_put
	mov a, bcdSTemp+0
	lcall LCD_put
	
	mov dptr, #STime_Str
	lcall writeString
	mov a, bcdSTime+2
	lcall LCD_put
	mov a, bcdSTime+1
	lcall LCD_put
	mov a, bcdSTime+0
	lcall LCD_put
	mov a, #'s'
	lcall LCD_put
	
	;line 2
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #RTemp_Str
	lcall writeString
	mov a, bcdRTemp+2
	lcall LCD_put
	mov a, bcdRTemp+1
	lcall LCD_put
	mov a, bcdRTemp+0
	lcall LCD_put
	
	mov dptr, #RTime_Str
	lcall writeString
	mov a, bcdRTime+2
	lcall LCD_put
	mov a, bcdRTime+1
	lcall LCD_put
	mov a, bcdRTime+0
	lcall LCD_put
	mov a, #'s'
	lcall LCD_put
	 ;4 second delay
	lcall wait1s
	lcall wait1s
	ret

Shift_Digits:
	mov R0, #4 ; shift left four bits
Shift_Digits_L0:
	clr c
	mov a, bcd+0
	rlc a
	mov bcd+0, a
	mov a, bcd+1
	rlc a
	mov bcd+1, a
	
	djnz R0, Shift_Digits_L0
	; R7 has the new bcd digit	
	mov a, R7
	orl a, bcd+0
	mov bcd+0, a
	; make the four most significant bits of bcd+1 zero
	mov a, bcd+1
	anl a, #0fH
	mov bcd+1, a
	ret

Wait50ms:
;33.33MHz, 1 clk per cycle: 0.03us
	mov R0, #30
L3: mov R1, #74
L2: mov R2, #250
L1: djnz R2, L1 ;3*250*0.03us=22.5us
    djnz R1, L2 ;74*22.5us=1.665ms
    djnz R0, L3 ;1.665ms*30=50ms
    ret

; Check if SW0 to SW15 are toggled up.  Returns the toggled switch in
; R7.  If the carry is not set, no toggling switches were detected.
ReadNumber:
	mov r4, SWA ; Read switches 0 to 7
	;mov r5, SWB ; Read switches 8 to 15
	mov a, SWB
	anl a, #00000011B
	mov r5, a
	mov a, r4
	orl a, r5
	jz ReadNumber_no_number
	lcall Wait50ms ; debounce
	mov a, SWA
	clr c
	subb a, r4
	jnz ReadNumber_no_number ; it was a bounce
	mov a, SWB
	anl a, #00000011B
	clr c
	subb a, r5
	jnz ReadNumber_no_number ; it was a bounce
	mov r7, #16 ; Loop counter
ReadNumber_L0:
	clr c
	mov a, r4
	rlc a
	mov r4, a
	mov a, r5
	rlc a
	mov r5, a
	jc ReadNumber_decode
	djnz r7, ReadNumber_L0
	sjmp ReadNumber_no_number	
ReadNumber_decode:
	dec r7
	setb c
ReadNumber_L1:
	mov a, SWA
	jnz ReadNumber_L1
ReadNumber_L2:
	mov a, SWB
	jnz ReadNumber_L2
	ret
ReadNumber_no_number:
	clr c
	ret
	
Wait1s:
	mov R2, #180
L6: mov R1, #250
L5: mov R0, #250
L4: djnz R0, L4 ; 3 machine cycles-> 3*30ns*250=22.5us
	djnz R1, L5 ; 22.5us*250=5.625ms
	djnz R2, L6 ; 5.625ms*180=1s (approximately)
	ret

writeString:
	clr a
	movc a, @a+dptr
	jz WSDone
	lcall LCD_put
	inc dptr
	sjmp writeString
WSDone:
	ret	

;puts the values in bcd to appropriate registers
BCD_Dump MAC
    mov a, bcd+1
	anl a, #0fH
	orl a, #30H
	mov %0, a
	;Digit 2
	mov a, bcd+0
	swap a
	anl a, #0fH
	orl a, #30H
	mov %1, a
	;Digit 1
	mov a, bcd+0
	anl a, #0fH
	orl a, #30H
	mov %2, a
ENDMAC

BCDReverseDump MAC
	mov a, %0
	anl a, #0fH
	mov bcd+1, a
	
	mov a, %1
	anl a, #0fh
	swap a
	
	mov b, %2
	anl b, #0fh
	
	orl a, b
	mov bcd+0, a
ENDMAC
			 		   
asciiConvert MAC
	mov x+0, %0
	mov x+1, #0
	lcall hex2bcd
	;Digit 3
	mov a, bcd+1
	anl a, #0fH
	orl a, #30H
	mov %1, a
	;Digit 2
	mov a, bcd+0
	swap a
	anl a, #0fH
	orl a, #30H
	mov %2, a
	;Digit 1
	mov a, bcd+0
	anl a, #0fH
	orl a, #30H
	mov %3, a
ENDMAC

;Puts the variables entered by user back into the originial
;soakTemp/Time and reflowTemp/Time variables
reloadUserVariables:
	BCDReverseDump(bcdSTemp+2,bcdSTemp+1,bcdSTemp+0)
	lcall bcd2hex
	mov soakTemp, x+0
	BCDReverseDump(bcdSTime+2,bcdSTime+1,bcdSTime+0)
	lcall bcd2hex
	mov soakTime, x+0
	BCDReverseDump(bcdRTemp+2,bcdRTemp+1,bcdRTemp+0)
	lcall bcd2hex
	mov reflowTemp, x+0
	BCDReverseDump(bcdRTime+2,bcdRTime+1,bcdRTime+0)
	lcall bcd2hex
	mov reflowTime, x+0
	ret

;Converts the time stored in the user variables from seconds
;to a combination of seconds and minutes so it can be loaded
;into the timer easily	
convertToMinutes:
	clr mf
	clr c
	Load_y(60)
	lcall x_gteq_y
	jb mf, addToMinutes
	sjmp secondsAreFine
addToMinutes:
	mov a, tempMin
	inc a
	mov tempMin, a
	mov a, x+0
	subb a, #60
	mov x+0, a
	sjmp convertToMinutes
secondsAreFine:
	;Convert seconds to bcd and store in tempSec
	lcall hex2bcd
	mov tempSec, bcd+0
	
	;Convert minutes to bcd and store in tempMin
	mov x+1, #0
	mov x+0, tempMin
	lcall hex2bcd
	mov tempMin, x+0
	ret
	
;This SR checks if all user inputted variables are within the
;allowable range of values. If not, they are rounded down to
;the nearest acceptable value and displayed
checkSTemp:
	clr valChanged
	BCDReverseDump(bcdSTemp+2,bcdSTemp+1,bcdSTemp+0)
	lcall bcd2hex
	Load_y(150)
	clr mf
	lcall x_gt_y
	jb mf, correctSTemp
	sjmp checkSTime
correctSTemp:
	mov bcdSTemp+2, #31H
	mov bcdSTemp+1, #35H
	mov bcdSTemp+0, #30H
	setb valChanged

checkSTime:
	BCDReverseDump(bcdSTime+2,bcdSTime+1,bcdSTime+0)
	lcall bcd2hex
	Load_y(120)
	clr mf
	lcall x_gt_y
	jb mf, correctSTime
	sjmp checkRTemp
correctSTime:
	mov bcdSTime+2, #31H
	mov bcdSTime+1, #32H
	mov bcdSTime+0, #30H
	setb valChanged
	
checkRTemp:
	BCDReverseDump(bcdRTemp+2,bcdRTemp+1,bcdRTemp+0)
	lcall bcd2hex
	Load_y(235)
	clr mf
	lcall x_gt_y
	jb mf, correctRTemp
	sjmp checkRTime
correctRTemp:
	mov bcdRTemp+2, #32H
	mov bcdRTemp+1, #33H
	mov bcdRTemp+0, #35H
	setb valChanged	

checkRTime:
	BCDReverseDump(bcdRTime+2,bcdRTime+1,bcdRTime+0)
	lcall bcd2hex
	Load_y(40)
	clr mf
	lcall x_gt_y
	jb mf, correctRTime
	ret
correctRTime:
	mov bcdRTime+2, #30H
	mov bcdRTime+1, #34H
	mov bcdRTime+0, #30H
	setb valChanged
	ret
		  
Wait40us:
	mov R0, #149
X1: 
	nop
	nop
	nop
	nop
	nop
	nop
	djnz R0, X1 ; 9 machine cycles-> 9*30ns*149=40us
    ret
    
LCD_command:
	mov	LCD_DATA, A
	clr	LCD_RS
	nop
	nop
	setb LCD_EN ; Enable pulse should be at least 230 ns
	nop
	nop
	nop
	nop
	nop
	nop
	clr	LCD_EN
	ljmp Wait40us

LCD_put:
	mov	LCD_DATA, A
	setb LCD_RS
	nop
	nop
	setb LCD_EN ; Enable pulse should be at least 230 ns
	nop
	nop
	nop
	nop
	nop
	nop
	clr	LCD_EN
	ljmp Wait40us
    
LCD_init:    
    ; Turn LCD on, and wait a bit.
    setb LCD_ON
    clr LCD_EN  ; Default state of enable must be zero
    lcall Wait40us
    
    mov LCD_MOD, #0xff ; Use LCD_DATA as output port
    clr LCD_RW ;  Only writing to the LCD in this code.
	
	mov a, #0ch ; Display on command
	lcall LCD_command
	mov a, #38H ; 8-bits interface, 2 lines, 5x7 characters
	lcall LCD_command
	mov a, #01H ; C	lear screen (Warning, very slow command!)
	lcall LCD_command
    
    ; Delay loop needed for 'clear screen' command above (1.6ms at least!)
   	mov R1, #40
    
Clr_loop:	
	lcall Wait40us
	djnz R1, Clr_loop
	ret
	
$LIST
