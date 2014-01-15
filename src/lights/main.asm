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
	p1					; Parameter 1
	p2					; Parameter 2
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

	GOTO	KNIGHT		; Goto main body

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
	MOVLW	0xA7		; p1 = 167
	MOVWF	p1
	MOVLW	0x35		; p2 = 53
	MOVWF	p2
	CALL	delay

	MOVF	acc1, W		; W = acc1
	MOVWF	PORTB		; PORTB = W
	
	INCF	acc1		; acc1++

	MOVF	acc1, W		; W = acc1
	XORLW	0xFF
	BTFSC	STATUS, Z	; Check if acc1 = 255
	CLRF	acc1		; If acc1 ^ 255 = 0 (AKA acc1 = 255), set acc1 to 0
	
	GOTO 	BINARY

; Task 6 - Knight rider.
KNIGHT:
	MOVLW	0x01		; Initial setup - only runs once
	MOVWF	acc1		; acc1 = 1 (light state)
loop_0:
	MOVF	acc1, W		; W = acc1
	MOVWF	PORTB		; PORTB = acc1
	
	MOVLW	0x3A		; p1 = 58
	MOVWF	p1
	MOVLW	0x4C		; p2 = 76
	MOVWF	p2
	CALL	delay		; About 0.1333s per loop (15Hz)

	BTFSS	acc2, 0x00
	GOTO	test_right	; If acc2 = 0, try to move right (board direction, not binary direction)
	GOTO	test_left	; Otherwise, try to move left

test_right:
	INCF	acc1, W		; If acc1 == 128, W will be >128
	GOTO	end_0

test_left:
	MOVLW	0x02
	SUBWF   acc1, W		; If acc1 == 1, W will overflow and therefore be >128
	GOTO	end_0

end_0:
	SUBLW	0x80
	BTFSS	STATUS, C	; If the shifted value is > 128, flip direction
	COMF	acc2, F		; This happens if 1 is shifted right (overflows to 255) or 128 is shifted left

	BCF		STATUS, C	; Clear C so we shift in zeros
	BTFSS	acc2, 0x00
	GOTO	right		; acc2 = 0, move right
	GOTO	left		; acc2 = 0xFF, move left
right:
	RLF		acc1, F
	GOTO 	loop_0
left:
	RRF		acc1, F
	GOTO	loop_0

; Functions
delay:
	DECFSZ	p1, F		; This loop executes around 255(p2 - 1) + p1 - 1 times
						; There are 6 cycles worth of instructions per loop, therefore
	GOTO	$+2			; if p1 = 167 and p2 = 53 we execute ~80556 instructions. That takes about 0.117s
	DECFSZ	p2, F		; meaning the entire BINARY loop takes roughly 30 seconds (0.117 * 256) to complete.
	GOTO 	delay		
	RETURN				; Adapted from code generated here: http://www.piclist.com/techref/piclist/codegen/delay.htm

	END					; Listing end

