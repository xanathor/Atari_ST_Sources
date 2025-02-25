;
; Protection Reader... by Martin Griffiths (c) July 1991
;
		
letsgo		CLR.W -(SP)
		PEA -1.W
		PEA -1.W
		MOVE #5,-(SP)
		TRAP #14
		LEA 12(SP),SP
		MOVE.L #200000,D0
.lp		SUBQ.L #1,D0
		BNE.S .lp
		CLR.L -(SP)
		MOVE #$20,-(SP)
		TRAP #1					; super
		ADDQ.L #6,SP
		BSR set_ints				; iniit ints
		LEA read_buffer,A0
		MOVE.W #20,track
		MOVE.W #0,side
		BSR read_track
protcheck	LEA read_buffer,A0
		MOVEQ #0,D0
.find_lp	CMP.B #'G',(A0)
		BNE.S .cont
		CMP.B #'R',1(A0)
		BNE.S .cont
		CMP.B #'I',2(A0)		; look for Griff.
		BNE.S .cont
		CMP.B #'F',3(A0)
		BNE.S .cont
		CMP.B #'F',4(A0)
		BNE.S .cont
.foundit	CMP #5085,D0
		BLE.S .itsacopy
		CMP #5089,D0
		BGE.S .itsacopy
.notacopy	ST notcopyflag			; not a copy so set flag
		BRA.S protcheckdone 
.cont		ADDQ.L #1,A0
		ADDQ.W #1,D0
		CMP.W #5150,D0
		BNE.S .find_lp
.itsacopy	SF notcopyflag			; tis a copy....
protcheckdone
		BSR res_ints				; restore ints
		MOVE.L #$00000777,$FFFF8240.W
		MOVE.L #$07770777,$FFFF8244.W
		MOVE #1,-(SP)
		PEA -1.W
		PEA -1.W
		MOVE #5,-(SP)
		TRAP #14
		LEA 12(SP),SP
		MOVE #37,-(SP)
		TRAP #14
		ADDQ.L #2,SP
		LEA copytext(PC),A0
		TST.B notcopyflag
		BEQ.S .tisacopy
		LEA notcopytext(PC),A0
.tisacopy	PEA (A0)
		MOVE #9,-(SP)
		TRAP #1
		ADDQ.L #6,SP 
		move #7,-(sp)
		trap #1
		addq.l #2,sp
		CLR -(SP)		
		TRAP #1					; see ya

notcopyflag	DC.W 0

copytext	DC.B 27,"EThis is a Chick-A-baw copy(cunt!!)",10,13,0
notcopytext	DC.B 27,"EThis is an Original(pat on the back!!)",10,13,0
		EVEN

; Read track.
; A0 -> address to load into.
				
read_track	MOVE.L A0,load_addr
		LEA $FFFF8606.W,A0
		LEA $FFFF8604.W,A1
		LEA $FFFFFA01.W,A2
		BSR seldrive
		BSR seektrack
		BSR Read_track
		BSR deselect
		RTS

; Write D7 tracks. 
; A0 -> address of data to save.

write_tracks	MOVE.L A0,save_addr
		LEA $FFFF8606.W,A0
		LEA $FFFF8604.W,A1
		LEA $FFFFFA01.W,A2
		BSR seldrive
		BSR seektrack
.track_lp	MOVE.W D7,-(SP)
		MOVEM.L A0-A6,-(SP)
		MOVE.L save_addr(PC),A3
		LEA write_buffer(PC),A4
		CLR.L (A4)+
		CLR.L (A4)+
		CLR.L (A4)+			; 12 bytes gap
		MOVE.B #$F5,(A4)+
		MOVE.B #$F5,(A4)+		; 3 bytes sync
		MOVE.B #$F5,(A4)+
		MOVE.B #'G',(A4)+
		MOVE.B #'R',(A4)+
		MOVE.B #'I',(A4)+		; data start identifier
		MOVE.B #'F',(A4)+
		MOVE.L A4,A0			; base of data
		MOVE #(23*256)/32-1,D0
.lp		REPT 32
		MOVE.B (A3)+,(A0)+
		ENDR
		DBF D0,.lp
		MOVE.L A3,save_addr
		LEA (A0),A5			; a6-> decode NO.
		LEA 2(A0),A6			; a6-> decode tab
		MOVEQ #0,D1			; no. of decodes=0
		MOVE #(23*256)-1,D0
.trans_lp	MOVEQ #0,D4
		MOVEQ #0,D5
		MOVE.B (A4),D4
		MOVE.B 1(A4),D5
		CMP.B #$F5,D4
		BEQ.S .clr
		CMP.B #$F6,D4
		BEQ.S .clr
		CMP.B #$F7,D4
		Bne.S .ok
.clr		MOVE.L #(23*256)-1,D2
		SUB D0,D2			
		BSET #3,d4
		ADD.L D2,D2
		REPT 3
		LSL.L #5,D2
		SWAP D2
		AND #$1F,D2
		MOVE.B D2,(A6)+
		SWAP D2
		ENDR
		MOVE.B #3,(A6)+			
		ADDQ #1,D1
.ok		MOVEQ #7,D7
.bit_lp		MOVE.W D4,D2
		MOVE.W D5,D3
		MOVEQ #8,D6
		SUB D7,D6
		LSL D6,D2
		LSR D7,D3
		OR.W D3,D2
		AND #%0000000111111111,D2
		CMP #%0000000000101001,D2	; is it fuckup code?!
		BNE.S .cont
		MOVE.L #(23*256)-1,D2
		SUB D0,D2			; offset within track
		MOVE.W D7,D6
		SUBQ #4,D6
		BGE.S .first
.second		ADDQ #8,D6
		ADDQ.W #1,D2
		BSET D6,D5			; change bit 0 ->1
		BRA.S .cont1
.first		BSET D6,D4			; change bit 0 ->1
.cont1		ADD.L D2,D2
		REPT 3
		LSL.L #5,D2
		SWAP D2
		AND #$1F,D2
		MOVE.B D2,(A6)+
		SWAP D2
		ENDR
		MOVE.B D6,(A6)+			; bit no. to change!
		ADDQ #1,D1			; inc no. of decodes
.cont		DBF D7,.bit_lp
		MOVE.B D4,(A4)+
		MOVE.B D5,(A4)
		DBF D0,.trans_lp
.ok1		MOVE.W D1,D2			; no. of decodes
		LSR #4,D1			; high 4 bits
		AND #$F,D2			; low 4 bits
		MOVE.B D1,(A5)+			; store no. of decodes
		MOVE.B D2,(A5)
		MOVEM.L (SP)+,A0-A6
		BSR Write_track
		BSR step_in
		MOVE.W (SP)+,D7
		DBF D7,.track_lp
		BSR deselect
		RTS

; Initialize interrupts.

set_ints	MOVE.W #$2700,SR
		LEA old_stuff(PC),A0
		MOVE.B $FFFFFA07.W,(A0)+
		MOVE.B $FFFFFA09.W,(A0)+
		MOVE.B $FFFFFA13.W,(A0)+
		MOVE.B $FFFFFA15.W,(A0)+
		MOVE.L $70.W,(a0)+
		MOVE.L #new_vbl,$70.W
		CLR.B $FFFFFA07.W
		CLR.B $FFFFFA09.W
		CLR.B $FFFFFA13.W
		CLR.B $FFFFFA15.W
		BCLR.B #3,$FFFFFA17.W
		MOVE.W #$2300,SR
		BSR flush
		RTS

; Restore old interrupts.

res_ints	MOVE #$2700,SR
		LEA old_stuff(PC),A0
		MOVE.B (A0)+,$FFFFFA07.W
		MOVE.B (A0)+,$FFFFFA09.W
		MOVE.B (A0)+,$FFFFFA13.W
		MOVE.B (A0)+,$FFFFFA15.W
		MOVE.L (A0)+,$70.W
		BSET.B #3,$FFFFFA17.W
		BSR flush
		MOVE #$2300,SR
		RTS

old_stuff	ds.l 8
new_vbl		RTE

; Select current drive/side
; d0 - 2 drive a, d0 - 4 drive b

seldrive	MOVEQ #2,D0
		OR side(PC),D0
		EOR.B #7,D0
select		MOVE.B #$E,$FFFF8800.W
		MOVE.B $FFFF8800.W,D1
		AND.B #$F8,D1
		OR.B D0,D1
		MOVE.B D1,$FFFF8802.W
		RTS

; Deselect current drive e.g turn motor off!

deselect	MOVE #$80,(A0)
wait		MOVE (A1),D0
		BTST #7,D0
		BNE.S wait
		MOVEQ #7,D0
		BRA select

; Place read/write head on the track in 'track'.

seektrack	MOVE #$80,(A0)
		MOVE #$07,(A1)
		BSR fdcwait
		MOVE #$86,(A0)
		MOVE track(PC),(A1)
		MOVE #$80,(A0)
		MOVE #%00010001,(A1)
		BSR fdcwait
		RTS

; Write (format) track.

Write_track	LEA data_ptr(PC),A3
		MOVE.L #write_buffer,(A3)+
		MOVE.B -(A3),$FFFF860D.w
		MOVE.B -(A3),$FFFF860B.w
		MOVE.B -(A3),$FFFF8609.w
		MOVE #$190,(A0)
		MOVE #$90,(A0)
		MOVE #$190,(A0)
		MOVE #15,(A1)
		MOVE #$180,(A0)
		MOVE #%11110000,(A1)
fdcwait1	BTST.B #5,(A2)
		BNE.S fdcwait1
		RTS

; Read track. (note the fdc dos no error checking!!)

Read_track	LEA data_ptr(PC),A3
		MOVE.L #read_buffer,(A3)+
		MOVE.B -(A3),$FFFF860D.w
		MOVE.B -(A3),$FFFF860B.w
		MOVE.B -(A3),$FFFF8609.w
		MOVE #$90,(A0)
		MOVE #$190,(A0)
		MOVE #$90,(A0)
		MOVE #15,(A1)
		MOVE #$80,(A0)
		MOVE #%11100000,(A1)
		MULU #1234,D0
.fdcwait1	BTST.B #5,(A2)
		BNE.S .fdcwait1
		RTS
data_ptr	DC.L 0

; Step_in a track

step_in		MOVE #$80,(A0)
		MOVE #$58,(A1)
fdcstep1	BTST.B #5,(A2)
		BNE.S fdcstep1
		RTS

; Wait for FDC
 	
fdcwait		MOVE.L D7,-(SP)
		MOVE.L #$50000,D7
fdcwait_lp	BTST.B #5,(A2)
		BEQ.S wait_done
		SUBQ.L #1,D7
		BNE.S fdcwait_lp
wait_done	MOVE.L (SP)+,D7
		RTS

; Flush keyboard

flush		BTST.B #0,$FFFFFC00.W
		BEQ.S .flok
		MOVE.B $FFFFFC02.W,D0
		BRA.S flush
.flok		RTS

log_base	DC.L 0

track		DC.W 0
side		DC.W 0
load_addr	DC.L 0
save_addr	DC.L 0

write_buffer	DS.B 15*512
read_buffer	DS.B 15*512
