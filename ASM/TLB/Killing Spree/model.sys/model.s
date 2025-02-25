 		******************************
	     ******                        ******
           ****      3D MODELLING SYSTEM       ****
	  ****      	     BY		        ****
          ****	TIM MOSS FOR SPACECRAFT CALCS   ****
          ****        IN 'KILLING SPREE'	****
           ****   (C) LOST BOYS DEVELOPMENT    ****
             ******                        ******
                ******************************

			OPT	O+,W-

*****************************USEFUL EQUATES**********************************

MARKS			EQU	0
DMA			EQU	0
	IFEQ	DMA
MEG			EQU	$200000   
	ENDC
	IFNE	DMA
MEG			EQU	$0
			ORG	$2000+$1C
	ENDC

SCREEN1			EQU	$70000+MEG
SCREEN2			EQU	$78000+MEG

**************************END OF USEFUL EQUATES******************************

*IN THE BEGINNING THERE WAS NOTHING.................

START:
	IFEQ	DMA
	CLR.L	-(SP)
	MOVE.W	#$20,-(SP)
	TRAP	#1
	ADDQ.L	#6,SP
	MOVE.L	D0,OLDSSP
	LEA	OURSTACK,A7
	ENDC
	IFNE	DMA
	MOVE.L	A7,OLDSSP
	LEA	OURSTACK,A7
	ENDC

	MOVEM.L	$FFFF8240.W,D0-D7	STORE STANDARD PALETTE
	MOVEM.L	D0-D7,OLD_PALETTE

	IFEQ	DMA
	MOVE.W	#0,-(SP)		SWITCH INTO LOWRES
	MOVE.L	#-1,-(SP)
	MOVE.L	#-1,-(SP)
	MOVE.W	#5,-(SP)
	TRAP	#14
	ADD.L	#12,SP
	ENDC

	MOVEQ 	#$12,D0			TURN OFF MOUSE
	BSR 	IKBD
	MOVEQ 	#$1A,D0			JOYSTICK AUTO RETURN(?)
	BSR 	IKBD

	BSR	CLEAR_SCREENS

	BSR	HBL_ON

	BSR	VSYNC

****************************************************************************
* THE VSYNC ROUTINE
****************************************************************************

VSYNC
	TST.W	VBLIND
	BEQ.S	VSYNC
	CLR.W	VBLIND
	RTS

*****************************************************************************
* THIS IS WHERE ALL THE INTERRUPTS ARE KEPT!!
*****************************************************************************

KEY_VECTOR:				*THE NEW KEY VECTOR
	MOVE.L	A0,-(A7)
	MOVE.L 	D2,-(SP)
AND_AG:	MOVE.B 	$FFFFFC00.W,D2		
	BTST 	#7,D2			ANY CHARACTER WAITING?
	BEQ.S	VECTOREND		NO THEN END
	MOVEQ	#0,D2
	MOVE.B 	$FFFFFC02.W,D2		READ CHARACTER INTO  'KBUFF'
	TST.W	NEXT_JOY1
	BNE.S	JOY_PACKAGE1		GET THE JOYSTICK PACK FOR PORT 0
	TST.W	NEXT_JOY2
	BNE.S	JOY_PACKAGE2		GET THE JOYSTICK PACK FOR PORT 1
	CMP.B	#$FE,D2
	BEQ.S	JOY1
	CMP.B	#$FF,D2			IS IT A JOYSTICK PACKAGE
	BNE.S	NORMAL_KEY
	ST	NEXT_JOY1
	BRA.S	AND_AG
	
NORMAL_KEY:
	LEA	KEY_BUFFER(PC),A0
	TST.B	D2			KEY PRESSED
	BPL.S	.SET_KEY
.CLR_KEY:
	BCLR	#7,D2			ELSE KEY DEPRESSED
	SF	(A0,D2.W)
	BRA.S	.1
.SET_KEY:
	ST	(A0,D2.W)
.1	BTST	#4,$FFFFFA01.W
	BEQ.S	AND_AG
VECTOREND:
	MOVE.L 	(SP)+,D2
	MOVE.L	(SP)+,A0
	RTE

JOY_PACKAGE1:
	MOVE.B 	D2,JBUFF
	CLR.W	NEXT_JOY1
	BRA.S	AND_AG

JOY1:	ST	NEXT_JOY2
	BRA.S	AND_AG

JOY_PACKAGE2:
	MOVE.B 	D2,JBUFF1
	CLR.W	NEXT_JOY2
	BRA.S	AND_AG
	
*********************
NEXT_JOY1:	DC.W	0
NEXT_JOY2:	DC.W	0
JBUFF:		DC.W	0
JBUFF1:		DC.W	0
*********************

KEY_BUFFER	DS.B	128

*****************************************************************************
* THIS IS THE QUIT ROUTINE
*****************************************************************************

QUIT
	MOVE.W 	#$2700,SR		TURN OFF INTS
	BSR 	HBLOFF			RESET VALUES
	LEA 	$FFFF8800.W,A1		BLANK SOUNDCHIP
	MOVE.L 	#$8080000,(A1)
	MOVE.L 	#$9090000,(A1)
	MOVE.L 	#$A0A0000,(A1)
	MOVE.W 	#$2300,SR		TURN BACK ON INTS
	MOVEQ 	#$14,D0			TURN MOUSE
	BSR 	IKBD	
	MOVEQ 	#$8,D0			AND JOYSTICKS BACK ON
	BSR 	IKBD
	MOVEM.L	OLD_PALETTE,D0-D7	PUT BACK OLD PALETTE
	MOVEM.L	D0-D7,$FFFF8240.W
	IFEQ	DMA
	MOVE.W	#1,-(SP)		SWITCH BACK TO MEDIUM RES
	MOVE.L	#-1,-(SP)
	MOVE.L	#-1,-(SP)
	MOVE.W	#5,-(SP)
	TRAP	#14
	ADD.L	#12,SP
	MOVE.L	OLDSSP,-(A7)		RESTORE STACK
	MOVE.W	#$20,-(SP)		AND PUT BACK INTO USER MODE
	TRAP	#1
	ADDQ.L	#6,SP

	ILLEGAL
	ENDC
	IFNE	DMA
	MOVE.L	OLDSSP,A7
	MOVE.W	#$2500,SR
	RTS
	ENDC

******************************************************************************
* ROUTINE FOR SETTING UP OF GENERAL INTERRUPTS
******************************************************************************

HBL_ON
	MOVE.L 	$FFFF8200.W,OLD_PHYS
	MOVE.L 	$120.W,OLD_TB		SAVE INTERRUPTS
	MOVE.L 	$70.W,OLD_VBL
	MOVE.L 	$118.W,OLD_KEY
	MOVE.L	$68.W,OLDHBL
	MOVE.L	$114.W,OLD_TIMER_C
	MOVE.L	$20.W,OLD_PRIV
	MOVE.B 	$FFFFFA07.W,OLD_07
	MOVE.B 	$FFFFFA09.W,OLD_09
	MOVE.B 	$FFFFFA0F.W,OLD_0F
	MOVE.B 	$FFFFFA13.W,OLD_13
	MOVE.B 	$FFFFFA1B.W,OLD_1B
	MOVE.B	$FFFFFA17.W,OLD_17
	MOVE.B	$FFFFFA1D.W,OLD_1D
	MOVE.B	$FFFFFA1F.W,OLD_1F
	MOVE.B	$FFFFFA23.W,OLD_23
	MOVE.B	$FFFFFA15.W,OLD_15
	MOVE.B	$FFFFFA11.W,OLD_11
	MOVE.B	$FFFFFA0D.W,OLD_0D
	MOVE.L	USP,A0
	MOVE.L	A0,OLD_USP
	AND.B 	#$DF,$FFFFFA09.W	THEN SET UP OURS
	AND.B 	#$FE,$FFFFFA07.W
	MOVE.L 	#TIMERB_1,$120.W	FIRST TIMER B
	MOVE.L 	#PICTURE_VBL,$70.W		FIRST VBL
	BCLR	#3,$FFFFFA17.W
	OR.B 	#1,$FFFFFA07.W
	OR.B 	#1,$FFFFFA13.W
	BCLR 	#6,$FFFFFA09.W		PUT IN OUR NEW 
	MOVE.L 	#KEY_VECTOR,$118.W	KEY VECTOR
	BSET 	#6,$FFFFFA09.W
	MOVE.W	#$2300,SR
	RTS

**************************************************************************
* RESTORE ALL THE PREVIOUSLY STORED INTERRUPTS
**************************************************************************

HBLOFF	MOVE.W 	SR,-(SP)		TAKE OUT ALL OF OUR INTS
	MOVE.W 	#$2700,SR
	MOVE.B 	OLD_07(PC),$FFFFFA07.W
	MOVE.B 	OLD_09(PC),$FFFFFA09.W
	MOVE.B 	OLD_0F(PC),$FFFFFA0F.W
	MOVE.B 	OLD_13(PC),$FFFFFA13.W
	MOVE.B 	OLD_1B(PC),$FFFFFA1B.W
	MOVE.B	OLD_17(PC),$FFFFFA17.W
	MOVE.B	OLD_1D(PC),$FFFFFA1D.W
	MOVE.B	OLD_1F(PC),$FFFFFA1F.W
	MOVE.B	OLD_1D(PC),$FFFFFA1D.W
	MOVE.B	OLD_15(PC),$FFFFFA15.W
	MOVE.B	OLD_11(PC),$FFFFFA11.W
	MOVE.L	OLD_USP(PC),A0
	MOVE.L	A0,USP
	MOVE.B	#180,$FFFFFA23.W
	MOVE.L 	OLD_TB(PC),$120.W
	MOVE.L 	OLD_VBL(PC),$70.W
	MOVE.L 	OLD_KEY(PC),$118.W
	MOVE.L	OLDHBL(PC),$68.W
	MOVE.L	OLD_TIMER_C(PC),$114.W
	MOVE.L	OLD_PRIV(PC),$20.W
	MOVE.L 	OLD_PHYS(PC),$FFFF8200.W
	MOVE.W 	(SP)+,SR
	RTS

**************************************************************************
* WRITE DATA TO KEYBOARD PROCESSOR. ENTER WITH VALUE IN TO BE SENT IN D0
**************************************************************************

IKBD	LEA 	$FFFFFC00.W,A1		WRITE TO THE KEYBOARD
IKLOOP	MOVE.B 	(A1),D1			PROCESSOR
	BTST 	#1,D1			READY TO RECIEVE DATA?
	BEQ.S 	IKLOOP
	MOVE.B 	D0,2(A1)		SEND DATA
	RTS

OLDSSP		DC.L	0		*OLDSTACK
OLD_PALETTE	DS.L	8		*OLD ST PALETTE
OLD_TB		DC.L	0
OLD_VBL		DC.L	0
OLD_KEY		DC.L	0
OLD_PHYS	DC.L	0
OLDHBL		DC.L	0
OLD_TIMER_C:	DC.L	0
OLD_PRIV:	DC.L	0
OLD_USP:	DC.L	0
OLD_07		DC.B	0
OLD_09		DC.B	0
OLD_0F		DC.B	0
OLD_13		DC.B	0
OLD_17		DC.B	0
OLD_1B		DC.B	0
OLD_1D		DC.B	0
OLD_1F		DC.B	0
OLD_23		DC.B	0
OLD_15		DC.B	0
OLD_0D		DC.B	0
OLD_11		DC.B	0
		EVEN
VBLIND		DC.W	0
		EVEN

; ********************************
; *      Level 4 Interrupt       *
; ********************************

NEW_VBL:
	ST	VBLIND
	RTE

*********************************
*      TIMER B INTERRUPTS       *
*********************************

TIMERB_1:
	RTE

CLEAR_SCREENS:
	LEA	SCREEN1,A0
	LEA	MEG+$80000,A1
.LOOP	CLR.L	(A0)+
	CMP.L	A1,A0
	BLT.S	.LOOP
	RTS

	SECTION	BSS
