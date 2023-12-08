#include <xc.inc>

extrn	GLCD_Setup, GLCD_Send_I, GLCD_Send_D, LCM_Reset, LCD_delay_ms
extrn	GLCD_Read
extrn	propagation_setup, init_position, propagate
extrn	mv_right, mv_left, mv_up, mv_down
extrn	vert_line, x_pos, y_pos
extrn	array_setup
extrn   key_setup, key_reader
    
psect	code, abs
rst:	org	0x0000	; reset vector
	goto	Setup

Setup:
    call    array_setup
    call    propagation_setup
    call    GLCD_Setup
    call    init_position
    call    key_setup
    
    movlw   0x0		    ; PortD all outputs
    movwf   TRISE, A
    
    ;call    vert_line
    
main:
    nop
    movlw   4		; TODO CHANGE default move down
    call    key_reader
    call    propagate
    movlw   50
    call    LCD_delay_ms
    ;movlw   250
    ;call    LCD_delay_ms
  
    nop
    bra	    main
    
    end	rst
