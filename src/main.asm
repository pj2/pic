; main.asm
; 
; Controls the lights board.
processor 16f84A 							; Using PIC16F84A
include <p16f84A.inc>						; Load datasheet
__config _WDT_OFF & _RC_OSC & _PWRTE_OFF	; Watchdog timer off, RC oscillator, power-up timer off

cblock	0x20			; Registers
	pattern				; Argument used by BITMASK to set lights
	acc1				; General counter
	acc2				; General counter
endc

INIT:
	BSF 	STATUS,	RP0 ; Set register bank select bit; use Bank1
	
	CLRF	TRISB		; Clear TRISB; PORTB becomes output
						
						; Setup PORTA
	MOVLW	0xFF		; Load 255 into W
	MOVWF	TRISA		; Set TRISA; PORTA becomes input
	
	BCF		STATUS, RP0	; Use Bank0 again
	CLRF	PORTA		; Clear PORTA

	GOTO	COUNT		; Goto main body

; Task 1 - Activates all the lights.
ALL:
	MOVLW 	0xFF		; 0xFF turns on all lights
	MOVWF	PORTB		; Move 0xFF to PORTB

	GOTO	ALL			; Loop forever

; Task 2 - Activates the lights according to the bitmask in register 'pattern' 
BITMASK: 
	MOVF	pattern, 0	; Move pattern into W
	MOVWF	PORTB		; Move W to PORTB

	GOTO	BITMASK		; Loop forever

; Task 3 - Activates lights whose buttons are pressed. Only the first 4 lights are affected.
SWITCHES:
	MOVF	PORTA, 0	; Read input bitmask into W
	XORLW	0x0F		; Flip input and keep the bottom 4 bits
	MOVWF	PORTB		; Move W into PORTB

	GOTO SWITCHES

; Task 4 - Activates X lights where X is the number of pressed buttons.
COUNT:
	MOVF	PORTA, 0	; Read input into W
	XORLW	0x0F		; Flip input and keep the bottom 4 bits
	MOVWF	acc1		; acc1 = W

	MOVLW	0x0F		; W = all lights
	BTFSS	acc1, 0x01	; Test bit 1
	RRF		W, 1		

	BTFSS	acc1, 0x02	; Test bit 2
	RRF		W, 1

	BTFSS	acc1, 0x04	; Test bit 3
	RRF		W, 1

	BTFSS	acc1, 0x08	; Test bit 4
	RRF 	W, 1

	MOVWF	PORTB		; PORTB = W

	GOTO 	COUNT
	END					; Listing end