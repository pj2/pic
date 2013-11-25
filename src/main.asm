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
	acc3				; General counter
	acc4				; General counter
endc

; Program
INIT:
	BSF 	STATUS,	RP0 ; Set register bank select bit; use Bank1
	
	CLRF	TRISB		; Clear TRISB; PORTB becomes output
						
						; Setup PORTA
	MOVLW	0xFF		; Load 255 into W
	MOVWF	TRISA		; Set TRISA; PORTA becomes input
	
	BCF		STATUS, RP0	; Use Bank0 again
	
	CLRF	PORTA		; Clear SFRs and GPRs
	CLRF	acc1		
	CLRF	acc2
	CLRF	acc3
	CLRF	acc4
	CLRF	W			; Clear W

	MOVLW	0x0D		; pattern = 13 (if 0 is on and - is off, looks like this: 0-0-0--)
	MOVWF	pattern	

	GOTO	BINARY		; Goto main body

; Task 1 - Activates all the lights.
ALL:
	MOVLW 	0xFF		; 0xFF turns on all lights
	MOVWF	PORTB		; Move 0xFF to PORTB

	GOTO	ALL			; Loop forever

; Task 2 - Activates the lights according to the bitmask in register 'pattern' 
BITMASK: 
	MOVF	pattern, W	; Move pattern into W
	MOVWF	PORTB		; Move W to PORTB

	GOTO	BITMASK		; Loop forever

; Task 3 - Activates lights whose buttons are pressed. Only the first 4 lights are affected.
SWITCHES:
	MOVF	PORTA, W	; Read input bitmask into W
	XORLW	0x0F		; Flip input and keep the bottom 4 bits
	MOVWF	PORTB		; Move W into PORTB

	GOTO SWITCHES

; Task 4 - Activates X lights where X is the number of pressed buttons.
COUNT:
	MOVLW	0x0F		; W = all lights
	MOVWF	acc1		; acc1 = W

	BTFSC	PORTA, 0x00	; If bit 1 is high, button is not pressed
	RRF		acc1, F		; active lights -= 1

	BTFSC	PORTA, 0x01	; Repeat with bit 2
	RRF		acc1, F

	BTFSC	PORTA, 0x02	; Bit 3...
	RRF		acc1, F

	BTFSC	PORTA, 0x03	; Bit 4...
	RRF 	acc1, F
	
	MOVF	acc1, W		; W = acc1
	ANDLW	0x0F		; Ignore upper bits (might be set due to shifting)
	MOVWF	PORTB		; Output W to PORTB

	GOTO 	COUNT

; Task 5 - Counts from 0 to 255 every 30 seconds.
BINARY:
	MOVLW	0xA7		; acc2 = 167
	MOVWF	acc2
	MOVLW	0x35		; acc3 = 53
	MOVWF	acc3
delay_0:				; This loop executes around 255(acc3 - 1) + acc2 - 1 times
	DECFSZ	acc2, F		; It contains 6 cycles worth of instructions per loop, therefore
	GOTO	$+2			; it executes ~80556 instructions. That takes about 0.117s
	DECFSZ	acc3, F		; meaning the entire BINARY loop takes roughly 30 seconds (0.117 * 256) to complete.
	GOTO 	delay_0		
						; Adapted from code generated here: http://www.piclist.com/techref/piclist/codegen/delay.htm

	MOVF	acc1, W		; W = acc1
	MOVWF	PORTB		; PORTB = W
	
	INCF	acc1		; acc1++

	MOVF	acc1, W		; W = acc1
	XORLW	0xFF
	BTFSC	STATUS, Z	; Check if acc1 = 255
	CLRF	acc1		; If acc1 ^ 255 = 0 (AKA acc1 = 255), set acc1 to 0
	
	GOTO BINARY





	END					; Listing end

