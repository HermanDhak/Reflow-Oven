$NOLIST

CSEG
    
INIT_SPI:
    orl P0MOD, #00000110b ; Set SCLK, MOSI as outputs
    anl P0MOD, #11111110b ; Set MISO as input
    clr SCLK              ; For mode (0,0) SCLK is zero
	ret
	
DO_SPI_G:
	push acc
    mov R1, #0            ; Received byte stored in R1
    mov R2, #8            ; Loop counter (8-bits)
DO_SPI_G_LOOP:
    mov a, R0             ; Byte to write is in R0
    rlc a                 ; Carry flag has bit to write
    mov R0, a
    mov MOSI, c
    setb SCLK             ; Transmit
    mov c, MISO           ; Read received bit
    mov a, R1             ; Save received bit in R1
    rlc a
    mov R1, a
    clr SCLK
    djnz R2, DO_SPI_G_LOOP
    pop acc
    ret

Delay:
	mov R3, #255
D1:	mov R2, #255
D0: djnz R2, D0
	djnz R3, D1
	ret
	
waithalfsecond:
	mov R2, #90
M3: mov R1, #250
M2: mov R0, #250
M1: djnz R0, M1
	djnz R1, M2
	DJNZ R2, M3
	ret	
	
; Channel to read passed in register b
Read_ADC_Channel:
	clr CE_ADC
	mov R0, #00000001B ; Start bit:1
	lcall DO_SPI_G
	
	mov a, b
	swap a
	anl a, #0F0H
	setb acc.7 ; Single mode (bit 7).
	
	mov R0, a ;  Select channel
	lcall DO_SPI_G
	mov a, R1          ; R1 contains bits 8 and 9
	anl a, #03H
	mov R7, a
	
	mov R0, #55H ; It doesn't matter what we transmit...
	lcall DO_SPI_G
	mov a, R1    ; R1 contains bits 0 to 7
	mov R6, a
	setb CE_ADC
	ret

; Configure the serial port and baud rate using timer 2
InitSerialPort:
	clr TR2 ; Disable timer 2
	mov T2CON, #30H ; RCLK=1, TCLK=1 
	mov RCAP2H, #high(T2LOAD)  
	mov RCAP2L, #low(T2LOAD)
	setb TR2 ; Enable timer 2
	mov SCON, #52H
	ret

; Send a character through the serial port
putchar:
    JNB TI, putchar
    CLR TI
    MOV SBUF, a
    RET
  
send_number:
	push acc
	swap a
	anl a, #0fh
	orl a, #30h ; Convert to ASCII
	lcall putchar
	pop acc
	anl a, #0fh
	orl a, #30h ; Convert to ASCII
	lcall putchar
	ret

calculateRoomTemp:
	mov x+3, #0
 	mov x+2, #0
	mov x+1, R7
	mov x+0, R6
	
	; The temperature can be calculated as (ADC*500/1024)-273 (may overflow 16 bit operations)
	; or (ADC*250/512)-273 (may overflow 16 bit operations)
	; or (ADC*125/256)-273 (may overflow 16 bit operations)
	; or (ADC*62/256)+(ADC*63/256)-273 (Does not overflow 16 bit operations!)
	
	Load_y(62)
	lcall mul16
	mov R4, x+1
	
	mov x+3, #0
 	mov x+2, #0
	mov x+1, R7
	mov x+0, R6

	Load_y(63)
	lcall mul16
	mov R5, x+1
	
	mov x+0, R4
	mov x+1, #0
	mov y+0, R5
	mov y+1, #0

	mov x+3, #0
 	mov x+2, #0
	lcall add16
	
	Load_y(273)
	lcall sub16
	
	mov w+0, x+0
	mov w+1, x+1
	mov w+2, x+2
	mov w+3, x+3   

	lcall hex2bcd
	mov a, bcd
	lcall send_number
	mov a, #'\r'
	lcall putchar
	mov a, #'\n'
	lcall putchar
	ret

convert:
;mov dptr, #binarytovoltage
	mov a, x+0 ;x+0 is the low input
	mov b, #2
	mul ab		;b now contains the high result of this multiplication
	add a, dpl	; a contains low result
	mov dpl, a
		
	mov a, x+1
	addc a, x+1
	add a, b  ;combine the high number with the high result of multiplication
	addc a, dph
	mov dph, a
	
	clr a
	movc a, @a+dptr
	mov x+1, a
	inc dptr
	clr a
	movc a, @a+dptr
	mov x+0, a
	ret

opamp:
	mov b, #01H  ; Read channel 1
	lcall Read_ADC_Channel
	
	mov x+0, R6
	mov x+1, R7
	mov x+2, #0
	mov x+3, #0

	mov ledra, r6
	mov ledrb, r7
	
	;lcall convert
	Load_y_32(3125)
	lcall mul32
	
	Load_y_32(5248)
	lcall div32

	lcall hex2bcd_32
	ret

addingtemps:
	mov y+0, w+0
	mov y+1, w+1
	mov y+2, w+2
	mov y+3, w+3
	
	lcall add32
	
	
	ret
	
$LIST	