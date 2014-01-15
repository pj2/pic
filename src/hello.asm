    #include "p16f84a.inc"
INIT:
    BSF  STATUS, RP0    ; Set register bank select bit (RP0) i.e. use Bank1
    CLRF  TRISB         ; Clear TRISB. PORTB (Pin 6) becomes output mode
    BCF  STATUS, RP0    ; Use Bank0
MAIN:
    MOVLW  0xAA         ; Set W to 170
    MOVWF  PORTB        ; Move W to PORTB
    GOTO  MAIN          ; Loop forever
    END