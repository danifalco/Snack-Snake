#include <xc.inc>

global	propagation_setup, init_position, propagate, dsp_pos_head
global	mv_right, mv_left, mv_up, mv_down
global	remain, temp, counter, x_pos, y_pos
global	x_row_inst, y_col_inst, x_tail_old, y_tail_old, remain, x_temp
global	Y_POS_COMMAND, X_POS_COMMAND, dirty_read 

extrn	GLCD_Send_I, GLCD_Send_D, GLCD_Read, vert_line
extrn	ret_x_tail, ret_y_tail, ret_x_head, ret_y_head, snek_grow, snek_not_grow
extrn	check_if_in_snek
extrn	food_x, food_y, spawn_food
    
psect udata_acs	    ; named variables in access RAM

x_pos:	    ds	1   ; reserve 1 byte for current x position
y_pos:	    ds	1   ; reserve 1 byte for current y position
x_prev:	    ds	1   ; reserve 1 byte for previous x position
y_prev:	    ds	1   ; reserve 1 byte for previous y position
x_temp:	    ds	1   ; reserve 1 temporary byte for x
y_temp:	    ds	1   ; reserve 1 temporary byte for y
x_row_inst: ds	1   ; reserve 1 byte for the x row instruction 
y_col_inst: ds  1   ; reserve 1 byte for the y col instruction 
remain:	    ds	1   ; reserve 1 byte for the division remainder
temp:	    ds	1   ; reserve 1 byte for a versatile temp variable
counter:    ds	1   ; reserve 1 byte for a counter variable
x_tail_old: ds	1   ; reserve 1 byte for the previous tail x-position
y_tail_old: ds	1   ; reserve 1 byte for the previous tail y-position
grow_bool:  ds  1   ; reserve 1 byte for growth condition: 1=grow, 0=not
    
one:	    ds	1
two:	    ds  1
three:	    ds	1
four:	    ds  1
    
    Y_POS_COMMAND   EQU	01000000B
    X_POS_COMMAND   EQU 10111000B
 
psect propagation_code,class=CODE
    
propagation_setup:
    movlw   1
    movwf   one, A
    movlw   2
    movwf   two, A
    movlw   3
    movwf   three, A
    movlw   4
    movwf   four, A
    
    clrf    remain, A
    
    return    

init_position:
    call    ret_x_head
    movwf   x_pos, A
    call    ret_y_head
    movwf   y_pos, A
    
    ; Print the initial on-screen position
    movlw   01000000B
    call    GLCD_Send_I	    ; Select y=0 column
    movlw   10111000B
    call    GLCD_Send_I	    ; Select x=0 column
    movlw   11111110B
    call    GLCD_Send_D
    movlw   01000000B
    call    GLCD_Send_I	    ; Select y=0 column

    return
    
propagate:  ; Propagate: 1 - Right, 2 - Left, 3 - Up, 4 - Down
    
    ;movff    x_pos, x_prev, A
    ;movff    y_pos, y_prev, A
    clrf    grow_bool, A
    movwf   temp, A		    ; Hold WREG in temp since it will change
    clrf    remain, A
    call    ret_x_head
    movwf   x_pos, A
    call    ret_y_head
    movwf   y_pos, A
    movf    temp, W, A		    ; Move temp back to WREG for propagation
    
    cpfseq  one, A
    bra	    left
    call    mv_right
    bra	    dsp_pos_head	    ; Branch to display position
    
left:
    cpfseq  two, A
    bra	    up
    call    mv_left
    bra	    dsp_pos_head
    
up: 
    cpfseq  three, A
    bra	    down
    call    mv_up
    bra	    dsp_pos_head
   
down:
    ;cpfseq  four, A
    call    mv_down
    bra	    dsp_pos_head

dsp_pos_head:  ; Figure out the row and column of the snake head
    call    check_if_in_snek	; First of all check if snek ate itself
    movf    food_x, W, A	
    cpfseq  x_pos, A		; Compare if food_x and x_pos are the same
    bra	    continue
    movf    food_y, W, A	; If so check for y
    cpfseq  y_pos, A
    bra	    continue
    movlw   1
    movwf   grow_bool, A	; If it is in y, set grow_bool to 1 (true)

    continue:
    call    ret_x_tail
    movwf   x_tail_old, A	; Store the old tail position into its var
    call    ret_y_tail
    movwf   y_tail_old, A	; Store the old tail position into its var
    
    movf    y_pos, W, A		; Move new y position into WREG
    ;movwf   y_pos, A
    addlw   Y_POS_COMMAND	; Sum with the command vlaue and store in W
    movwf   y_col_inst, A
    
    ;	********** X-Position Code **********
    movff   x_pos, x_temp, A	; Move the x position to its temporary variable
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, F, A	; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 0, A
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, F, A		; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 1, A
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, F, A		; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 2, A
    ; Now x_temp has been divided by 8 (so this will be the x page) and the 
    ; carry variable contains the pixel to light up within this page (column)
    
    movf    x_temp, W, A		; Move new x position into WREG
    addlw   X_POS_COMMAND	; Sum with the command value and store in W
    movwf   x_row_inst, A
    
    movlw   00000001B
    movwf   temp, A
    movlw   0x0
    pos_loop:
	cpfsgt	remain, A
	bra	end_display
	addlw	1
	rlncf	temp, F, A
	bra	pos_loop
	
end_display:
    movff   temp, remain	; Free temp by moving temp to remain
    
    call    dirty_read
    
    movwf   temp, A		; Move the read result into temp variable
    
    movf    y_col_inst, W, A
    call    GLCD_Send_I		; Select y column
    
    movf    temp, W, A		; Restore value from GLCD_Read into WREG
    
    iorwf   remain, W, A	; OR W and remain, store in W
    call    GLCD_Send_D
    
    movf    y_pos, W, A		; Move new y position into WREG
    addlw   Y_POS_COMMAND	; Sum with the command vlaue and store in W
    call    GLCD_Send_I		; Reset y position since GLCD_Read +1'ed it
    
    movlw   1
    cpfseq  grow_bool, A	; Check if snake has grown
    bra	    dsp_pos_tail	; Case: Snek not grow
    call    snek_grow		; We haven't deleted the last pixel so snek grow
    call    spawn_food
    return    
   
dsp_pos_tail:	; Finds the row, col of the tail value (
    clrf    remain, A
    call    ret_y_tail		; Move y tail position into WREG
    addlw   Y_POS_COMMAND	; Sum with the command vlaue and store in W
    movwf   y_col_inst, A
    
    ;	********** X-Position Code **********
    call    ret_x_tail		; Move x tail position into WREG
    movwf   x_temp, A	    ; Move the x tail position to its temporary variable
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, F, A	; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 0, A
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, F, A		; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 1, A
    
    bcf	    CARRY		; Clear the carry flag ready for rotation
    rrcf    x_temp, F, A		; Divide x_temp by 8 (i.e. divide by 2 3 times)
    btfsc   CARRY
    bsf	    remain, 2, A
    ; Now x_temp has been divided by 8 (so this will be the x page) and the 
    ; carry variable contains the pixel to light up within this page (column)
    
    movf    x_temp, W, A	; Move new x position into WREG
    addlw   X_POS_COMMAND	; Sum with the command value and store in W
    movwf   x_row_inst, A
    
    movlw   00000001B
    movwf   temp, A
    movlw   0x0
    pos_loop_:
	cpfsgt	remain, A
	bra	end_display_
	addlw	1
	rlncf	temp, F, A
	bra	pos_loop_
	
end_display_:
    movff   temp, remain	; Free temp by moving temp to remain

    call    dirty_read

    movwf   temp, A		; Move the read result into temp variable

    movf    y_col_inst, W, A
    call    GLCD_Send_I		; Select y column

    movf    temp, W, A		; Restore value from GLCD_Read into WREG
    
    bsf	    CARRY
    subfwb  remain, W, A	; OR W and remain, store in W
    call    GLCD_Send_D

    movf    y_pos, W, A		; Move new y position into WREG
    addlw   Y_POS_COMMAND	; Sum with the command vlaue and store in W
    call    GLCD_Send_I		; Reset y position since GLCD_Read +1'ed it

    call    snek_not_grow	; We delete the last pixel so snek not grow
    return   
       
mv_right:
    movlw   63
    cpfslt  y_pos, A
    return
    incf    y_pos, A
    return
    
mv_left:
    movlw   0x0
    cpfsgt  y_pos, A
    return
    decf    y_pos, A
    return
    
mv_up:
    movlw   0x0
    cpfsgt  x_pos, A
    return
    decf    x_pos, F, A
    return
    
mv_down:
    movlw   63
    cpfslt  x_pos, A
    return
    incf    x_pos, A
    return
    
dirty_read:	
    ; For some reason, when we run the GLCD_Read subroutine once or twice it 
    ; doesn't work as intended, but if you run it many times it works flawlessly
    ; Perhaps something to do with timings, either way don't delete until 
    ; solution found
    
    movf    y_col_inst, W, A
    call    GLCD_Send_I		; Select y column
    movf    x_row_inst, W, A
    call    GLCD_Send_I		; Select x column
    call    GLCD_Read		; Read contents from screen in selected area
    
    movf    y_col_inst, W, A
    call    GLCD_Send_I		; Select y column
    movf    x_row_inst, W, A
    call    GLCD_Send_I		; Select x column
    call    GLCD_Read		; Read contents from screen in selected area
    movf    y_col_inst, W, A
    call    GLCD_Send_I		; Select y column
    movf    x_row_inst, W, A
    call    GLCD_Send_I		; Select x column
    call    GLCD_Read		; Read contents from screen in selected area
    movf    y_col_inst, W, A
    call    GLCD_Send_I		; Select y column
    movf    x_row_inst, W, A
    call    GLCD_Send_I		; Select x column
    call    GLCD_Read		; Read contents from screen in selected area
    
    return
    call    GLCD_Send_I		; Select x column
    call    GLCD_Read		; Read contents from screen in selected area
    
    return
