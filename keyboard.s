#include <xc.inc>

global	key_reader, key_setup, key_val
    
psect	udata_acs
	
high_byte:  ds 1    
delay_count:ds 1    ; Reserve 1 byte ofr counter in the delay routine
key_val:    ds 1    ; Reserve 1 byte for the key result (binary)
    
psect	keyboard_code, class=CODE

key_setup:
    ; SETUP KEYBOARD
    movlb   15
    bsf	    REPU
    movlb   0
    clrf    LATE
    return

key_reader:
    ; For propagation: 2=up, 8=down, 4=left, 6=right
    ; Begin row read
    movlw   0xF0
    movwf   TRISE
    call    delay
    movff   PORTE, high_byte
    
    ; Begin column read
    movlw   0x0F
    movwf   TRISE
    call    delay
    movf    PORTE, W
    iorwf   high_byte, A
    movff   high_byte, key_val	    ; Store button value (binary) in key_val

; Decode
is_2:	    ; This is up, so return 3 to WREG
    movlw   0xED
    cpfseq  key_val, A
    bra	    is_4
    movlw   3
    bra	    output
    
is_4:	    ; This is left, so return 2 to WREG
    movlw   0xDE
    cpfseq  key_val, A
    bra	    is_6
    movlw   2
    bra	    output
    
is_6:	    ; This is right, so return 1 to WREG
    movlw   0xDB
    cpfseq  key_val, A
    bra	    is_8
    movlw   1
    bra	    output
    
is_8:	    ; This is down so return 4
    movlw   0xBD
    cpfseq  key_val, A
    bra	    invalid
    movlw   4
    bra	    output
    
invalid:
    goto    key_reader

output:
    return
    
delay:	
    decfsz  delay_count, A	; decrement until zero
    bra	    delay
    return
