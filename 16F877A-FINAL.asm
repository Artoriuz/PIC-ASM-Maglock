    #INCLUDE <P16F877A.INC>
    __CONFIG _HS_OSC&_WDT_OFF&_PWRTE_ON&_CP_OFF
	
	#DEFINE OUTPUT_LED PORTC,3
	
	;#DEFINE PST_LCK   PORTC,0		;switch this to an internal memory address later
	;#DEFINE PST_OPN   PORTC,1		;switch this to an internal memory address later
	#DEFINE PST_LCK	   0x20,0		;general purpose register address
	#DEFINE PST_OPN	   0x20,1		;general purpose register address
	
	#DEFINE BT_OPN_CLS PORTB,7
	#DEFINE BT_PSW_CHG PORTB,6
	
	#DEFINE MATRIX_1   PORTD,6
	#DEFINE MATRIX_2   PORTD,5
	#DEFINE MATRIX_3   PORTD,4
	#DEFINE MATRIX_A   PORTD,3
	#DEFINE MATRIX_B   PORTD,2
	#DEFINE MATRIX_C   PORTD,1
	#DEFINE MATRIX_D   PORTD,0
	
	;Memory definitions
	#DEFINE PASS_PRESS_1 0x21
	#DEFINE PASS_PRESS_2 0x22
	#DEFINE PASS_PRESS_3 0x23
	#DEFINE PASS_PRESS_4 0x24
	
	#DEFINE PASSWORD_1 0x25
	#DEFINE PASSWORD_2 0x26
	#DEFINE PASSWORD_3 0x27
	#DEFINE PASSWORD_4 0x28
		
; Counter setup
	ORG	0x00
	GOTO	SETUP

; Interrupt routine
	ORG 	0x04				;Start of interrupt routine
	BTFSC	INTCON,0			;check which interruption happened (RBIF here)
	GOTO 	INTERRUPT_PRIORITY
	GOTO	INTR_EXIT
INTERRUPT_PRIORITY
	BTFSC	BT_OPN_CLS			
	GOTO 	BT_INT_CHECK
	
	BTFSC	BT_PSW_CHG
	GOTO 	PASSWORD_CHANGE
	
	GOTO	INTERRUPT_PRIORITY
	
PASSWORD_CHANGE
	BTFSS	BT_PSW_CHG
	GOTO 	PASSWORD_CHANGE_CONT
	GOTO	PASSWORD_CHANGE
PASSWORD_CHANGE_CONT
	BTFSC	PST_LCK
	GOTO	INTR_EXIT
	
	CALL	BT_PRESS_LOOP
	MOVWF	PASSWORD_1
	CALL	BT_PRESS_LOOP
	MOVWF	PASSWORD_2
	CALL	BT_PRESS_LOOP
	MOVWF	PASSWORD_3
	CALL	BT_PRESS_LOOP
	MOVWF	PASSWORD_4
	
	CLRW
	
	BSF	PST_LCK
	BCF	PST_OPN
	BSF	OUTPUT_LED
	
	GOTO	INTR_EXIT

BT_INT_CHECK				
	BTFSS	BT_OPN_CLS
	GOTO 	STATE_CHANGE_0
	GOTO	BT_INT_CHECK
	
STATE_CHANGE_0
	BTFSC	PST_LCK				;Check the previous state
	GOTO	STATE_CHANGE_PST_LCK
	BTFSC	PST_OPN
	GOTO	STATE_CHANGE_PST_OPN

STATE_CHANGE_PST_LCK				
	BTFSS	BT_OPN_CLS
	GOTO 	LCK
	GOTO	STATE_CHANGE_PST_LCK				

STATE_CHANGE_PST_OPN		
	BTFSS	BT_OPN_CLS
	GOTO 	OPN
	GOTO	STATE_CHANGE_PST_OPN

OPN
	BSF	PST_LCK
	BCF	PST_OPN
	BSF	OUTPUT_LED
	GOTO	INTR_EXIT
LCK
	
	BSF	PST_LCK
	BCF	PST_OPN
	BSF	OUTPUT_LED
	CALL	BT_PRESS_LOOP
	MOVWF	PASS_PRESS_1
	CALL	BT_PRESS_LOOP
	MOVWF	PASS_PRESS_2
	CALL	BT_PRESS_LOOP
	MOVWF	PASS_PRESS_3
	CALL	BT_PRESS_LOOP
	MOVWF	PASS_PRESS_4
	
	MOVF	PASS_PRESS_1,0
	SUBWF	PASSWORD_1,0
	BTFSS	STATUS,2
	GOTO	STAY_LOCKED
	
	MOVF	PASS_PRESS_2,0
	SUBWF	PASSWORD_2,0
	BTFSS	STATUS,2
	GOTO	STAY_LOCKED
	
	MOVF	PASS_PRESS_3,0
	SUBWF	PASSWORD_3,0
	BTFSS	STATUS,2
	GOTO	STAY_LOCKED
	
	MOVF	PASS_PRESS_4,0
	SUBWF	PASSWORD_4,0
	BTFSS	STATUS,2
	GOTO	STAY_LOCKED
	
	GOTO	CAN_OPEN
		
BT_PRESS_LOOP
	BSF	MATRIX_A
	BCF	MATRIX_B
	BCF	MATRIX_C
	BCF	MATRIX_D
	BTFSC	MATRIX_1
	GOTO	A_1_PRESSED
	BTFSC	MATRIX_2
	GOTO	A_2_PRESSED
	BTFSC	MATRIX_3
	GOTO	A_3_PRESSED
	
	BCF	MATRIX_A
	BSF	MATRIX_B
	BCF	MATRIX_C
	BCF	MATRIX_D
	BTFSC	MATRIX_1
	GOTO	B_1_PRESSED
	BTFSC	MATRIX_2
	GOTO	B_2_PRESSED
	BTFSC	MATRIX_3
	GOTO	B_3_PRESSED
	
	BCF	MATRIX_A
	BCF	MATRIX_B
	BSF	MATRIX_C
	BCF	MATRIX_D
	BTFSC	MATRIX_1
	GOTO	C_1_PRESSED
	BTFSC	MATRIX_2
	GOTO	C_2_PRESSED
	BTFSC	MATRIX_3
	GOTO	C_3_PRESSED
	
	BCF	MATRIX_A
	BCF	MATRIX_B
	BCF	MATRIX_C
	BSF	MATRIX_D
	BTFSC	MATRIX_1
	GOTO	D_1_PRESSED
	BTFSC	MATRIX_2
	GOTO	D_2_PRESSED
	BTFSC	MATRIX_3
	GOTO	D_3_PRESSED
	
	GOTO	BT_PRESS_LOOP

A_1_PRESSED
	MOVLW	b'00000001'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
A_2_PRESSED
	MOVLW	b'00000010'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
A_3_PRESSED
	MOVLW	b'00000011'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
B_1_PRESSED
	MOVLW	b'00000100'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
B_2_PRESSED
	MOVLW	b'00000101'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
B_3_PRESSED
	MOVLW	b'00000111'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
C_1_PRESSED
	MOVLW	b'00001000'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
C_2_PRESSED
	MOVLW	b'00001001'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
C_3_PRESSED
	MOVLW	b'00001010'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
D_1_PRESSED
	MOVLW	b'00001011'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
D_2_PRESSED
	MOVLW	b'00001100'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
D_3_PRESSED
	MOVLW	b'00001101'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN
D_4_PRESSED
	MOVLW	b'00001110'
	CALL	BT_RLS_CHK_ROUTINE
	RETURN

BT_RLS_CHK_ROUTINE
BT_RLS_CHK_1		
	BTFSS	MATRIX_1
	GOTO 	BT_RLS_CHK_2
	GOTO	BT_RLS_CHK_1
BT_RLS_CHK_2		
	BTFSS	MATRIX_2
	GOTO 	BT_RLS_CHK_3
	GOTO	BT_RLS_CHK_2
BT_RLS_CHK_3	
	BTFSS	MATRIX_3
	RETURN
	GOTO	BT_RLS_CHK_3
	
STAY_LOCKED
	BSF	OUTPUT_LED
	BSF	PST_LCK
	BCF	PST_OPN
	GOTO	INTR_EXIT

CAN_OPEN
	BCF	OUTPUT_LED
	BCF	PST_LCK
	BSF	PST_OPN
	GOTO	INTR_EXIT

INTR_EXIT	
	BCF	MATRIX_A
	BCF	MATRIX_B
	BCF	MATRIX_C
	BCF	MATRIX_D
	MOVLW	b'00000000'
	MOVWF	PASS_PRESS_1
	MOVWF	PASS_PRESS_2
	MOVWF	PASS_PRESS_3
	MOVWF	PASS_PRESS_4
	
	BCF	INTCON,0			;The interrupt flags must be cleared 
	RETFIE

SETUP
; Port configuration
	
	BSF     STATUS,5		  	;Switch to Bank 1               
	MOVLW   b'11110000'		  	;Set Port B pins to input/output
	MOVWF   TRISD
	MOVLW   b'11000000'	
	MOVWF   TRISB

	MOVLW   b'00000000'		  	;Set Port B pins to input/output
	MOVWF   TRISC
	MOVLW	b'000000'
	MOVWF	TRISA
	
	MOVLW	b'10001000';			;interrupt enable bits (global, RB7:RB4)
	MOVWF	INTCON;

	BCF     STATUS,5			;Switch to Bank 0
	MOVLW	b'00000000'
	MOVWF	PORTC
	
	CLRF	PORTB
	
	BCF	MATRIX_A
	BCF	MATRIX_B
	BCF	MATRIX_C
	BCF	MATRIX_D
	
	BSF	OUTPUT_LED
	
	BSF	PST_LCK
	BCF	PST_OPN

	BCF	PORTA,2
	BCF	PORTA,4
	
	MOVLW	b'00000000'
	MOVWF	PASS_PRESS_1
	MOVWF	PASS_PRESS_2
	MOVWF	PASS_PRESS_3
	MOVWF	PASS_PRESS_4
	
	;Temporary password set so it can be tested with the new system
	MOVLW	b'00000001'
	MOVWF	PASSWORD_1
	MOVLW	b'00000010'
	MOVWF	PASSWORD_2
	MOVLW	b'00000011'
	MOVWF	PASSWORD_3
	MOVLW	b'00000100'
	MOVWF	PASSWORD_4
	
	GOTO	START
START
	GOTO	START
	END