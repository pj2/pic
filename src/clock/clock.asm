processor 16f84A 							; Using PIC16F84A
#include "p16f84A.inc"						; Load datasheet
__config _WDT_OFF & _RC_OSC & _PWRTE_OFF	; Watchdog timer off, RC oscillator, power-up timer off

org 	INIT							; Program starts at INIT label

#define d0			0x80
#define	d1			0xE3
#define d2			0x44
#define d3			0x41
#define d4			0x23
#define d5			0x11
#define d6			0x30
#define d7			0xC3
#define d8			0x00
#define d9			0x03

cblock	0x20							; Registers
	r1									; General register
	r2									; General register
	r3									; General register
	minute_1							; Left minute digit
	minute_2							; Right minute digit
	hour_1								; Left hour digit
	hour_2								; Right hour digit
	x1									; Output register 1
	x2									; Output register 2
	chour								; Hour counter
	cminute								; Minute counter
	cycles								; Loops between each minute
endc

; Macros
movlf 	macro l, f						; Sets file register f to literal l
	MOVLW	l							; W is also set to l
	MOVWF	f
	endm
movff	macro f1, f2					; Sets f2 = f1
	MOVF	f1, W
	MOVWF	f2
	endm
tiss 	macro on, off					; Test input skip if set, active and inactive are labels
	BTFSS	PORTA, 0x04					; Test switch input bit
	GOTO	on
	GOTO	off
	endm
bank0 	macro							; Sets current bank to 0
	BCF		STATUS, RP0
	endm
bank1 	macro							; Sets current bank to 1
	BSF		STATUS, RP0
	endm
swlel	macro k							; Skip if W is less or equal to literal, k is literal
	SUBLW	k
	BTFSS	STATUS, C
	endm

; Program body
INIT:
	bank1								; Bank1 to access TRIS registers

	movlf	0x10, TRISA					; TRISA = b10000 (bit 4 = input, rest = output)
	movlf	0x00, TRISB					; TRISB, all output

	CLRF	minute_1
	CLRF	minute_2
	CLRF	hour_1
	CLRF	hour_2
	CLRF	chour						; Clear memory
	CLRF	cminute

	CALL	Reset_cycles

	bank0
MAIN:
	CALL	Load_digits					; Load display digits

	movlf	0x01, PORTA					; Set minute digit 2
	movff	minute_2, PORTB

	CALL	Delay

	movlf	0x02, PORTA					; Set minute digit 1
	movff	minute_1, PORTB

	CALL	Delay

	movlf	0x04, PORTA					; Set hour digit 2
	movff	hour_2, PORTB

	CALL	Delay

	movlf	0x08, PORTA					; Set hour digit 1
	movff	hour_1, PORTB

	CALL	Delay

	CALL	Cycle_end					; Update timers
	GOTO 	MAIN						; Loop

; Functions
Delay:									; Delays for ~0.001s
	movlf	0xBA, r1
	movlf	0x02, r2
Delay_0:
	DECFSZ	r1, F
	GOTO	$+2
	DECFSZ	r2, F
	GOTO	Delay_0
	RETURN

Load_digits:							; Sets hour_1, hour_2, minute_1, minute_2 according to current time stored in cminute / chour
	movff	cminute, r2
	CALL	Get_digits

	MOVF	r3, W
	CALL	Lookup_digit
	MOVWF	minute_1

	MOVF	r2, W
	CALL	Lookup_digit
	MOVWF	minute_2

	movff	chour, r2
	CALL	Get_digits

	MOVF	r3, W
	CALL	Lookup_digit
	MOVWF	hour_1

	MOVF	r2, W
	CALL	Lookup_digit
	MOVWF	hour_2

	RETURN

Cycle_end:
	BTFSS	PORTA, 0x04					; If button pressed, update every cycle (i.e. fast)
	GOTO	on

	DECFSZ	cycles
	RETURN

on:
	CALL	Reset_cycles
	INCF	cminute, F					; Increment cminute

	MOVF	cminute, W					; W = cminute
	XORLW	0x3C						
	BTFSS	STATUS, Z					; If cminute != 60, return
	RETURN

	CLRF	cminute						; cminute = 0
	INCF	chour, F					; chour++
	
	MOVF	chour, W					; IF chour != 12, return
	XORLW	0x0C
	BTFSS	STATUS, Z
	RETURN
	
	CLRF	chour						; Loop back to 0:00
	
	RETURN

Lookup_digit:							; Returns 8-part display output value for digit stored in W
	ADDWF	PCL, F						; Advance W + 1 instructions
	RETLW	d0
	RETLW	d1
	RETLW	d2
	RETLW	d3
	RETLW	d4
	RETLW	d5
	RETLW	d6
	RETLW	d7
	RETLW	d8
	RETLW	d9

Get_digits:								; Calculate tens and ones columns (r3 = tens, r2 = ones). r3 should be initially set as the decimal (e.g. 53)
	CLRF	r3
Get_digits_0:
	MOVF	r2, W						; W = r2
	SUBLW	0x09						; Check if r2 is >= 10; if so, continue	
	BTFSC	STATUS, C
	RETURN								; r2 < 10

	INCF	r3, F						; Increment tens column
	MOVLW	0x0A						; r2 -= 10
	SUBWF	r2, F
	GOTO	Get_digits_0

Reset_cycles:
	movlf	0x24, cycles				; 36 cycles (roughly a second)
	RETURN

	END