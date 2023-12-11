#include <xc.inc>

extrn	GLCD_Setup, GLCD_Send_I, GLCD_Send_D, LCM_Reset, LCD_delay_ms
extrn	GLCD_Read, LCM_Reset
extrn	propagation_setup, init_position, propagate
extrn	mv_right, mv_left, mv_up, mv_down
extrn	vert_line, x_pos, y_pos
extrn	array_setup
extrn   key_setup, key_reader
extrn	randgen_setup, spawn_food

global	Setup
psect	code, abs
rst:	org	0x0000	; reset vector
	goto	Setup

Setup:
    call    array_setup
    call    randgen_setup
    call    propagation_setup
    call    GLCD_Setup
    call    key_setup
    call    LCM_Reset
    call    init_position
    call    spawn_food
    
    
    movlw   0x0		    ; PortD all outputs
    movwf   TRISE, A
    
main:
    nop
    call    key_reader
    call    propagate
    ;movlw   4
    ;call    propagate
    ;movlw   50
    ;call    LCD_delay_ms
    ;movlw   250
    ;call    LCD_delay_ms
  
    nop
    bra	    main
    
    end	rst
