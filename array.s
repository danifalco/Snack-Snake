#include <xc.inc>

extrn	x_pos, y_pos
    
global	array_setup
    
psect	udata_acs
snek_len:	ds  1	    ; Reserve 1 byte for length of snake
loop_cnt:	ds  1	    ; Reserve 1 byte for a loop counter
x_poos:		ds  1	    ; TODO DELETE
psect	udata_bank1	    ; We store the x-values array in bank 0
x_Arr:		ds  0xFF    ; We can have a snake of length up to 256
psect	udata_bank2	    ; Store the y-values in bank 0
y_Arr:		ds  0xFF    

psect	array_code,class=CODE

array_setup:
    movlw   7 ; TODO DELETE
    movwf   x_poos, A ; TODO DELETE
    
    lfsr    0, x_Arr	    ; Load FSR0 to point to x_Arr
    lfsr    1, y_Arr	    ; Load FSR1 to point to y_Arr
    
    movlw   0		    ; Start snake at y=0, x=1, 2, 3
    movwf   POSTINC1, B	    
    movwf   POSTINC1, B
    movwf   POSTINC1, B
    movlw   1
    movwf   POSTINC0, B
    movlw   2
    movwf   POSTINC0, B
    movwf   snek_len, A	    ; Snake initially has length 3 so it has value 2
    movlw   3
    movwf   POSTINC0, B
    
    lfsr    0, x_Arr	    ; Reload FSR Pointers
    lfsr    1, y_Arr	    
    bra	    snek_grow_x
snek_grow_x:
    movf    snek_len, W, A  ; Load snek length into W
    addwf   FSR0L, B	    ; Select the nth position of the list
    movlw   0x0
    movwf   loop_cnt, A
    snek_grow_loop_x:
	movf    INDF0, W, B	; Move the value of n to WREG
	incf    FSR0L, B	; Select position n+1
	movwf   INDF0, B	; Move WREG to n+1
	decf    FSR0L, B	; Move pointer back to n
	movf	snek_len, W, A	; Move snek len to W to compare in next inst
	cpfslt	loop_cnt, A ; Break loop once snek_len iterations are performed
	bra	in_new_x
	decf    FSR0L, B	; Move pointer to n-1 (if loop hasn't terminated)
	incf	loop_cnt, A	; Increment the counter
	bra	snek_grow_loop_x
    in_new_x:
	lfsr	0, x_Arr	; Set FRS0 back to back to the first point
	movff	x_pos, INDF0
	incf	snek_len, A
	return
