	PROCESSOR 6502
	LIST	ON
;
;------------------------------------------------------------------------
;  Apple 1 Basic by Steve Wozniak
;
;  This source was derived from BASIC disassembly done by Eric Smith.
;  This derivation is reproduced and distributed with permission of
;  Eric Smith
; 
;  Eric Smith's disassembly can be found at
;  http://www.brouhaha.com/~eric/retrocomputing/apple/apple1/basic/
;  
;  Do not reproduce or distribute without permission
;
;       copyright 2010, Mike Willegal
;	copyright 2003, Eric Smith
;
;------------------------------------------------------------------------
;  Disassembly of Apple 1 BASIC
; 17-Sep-2003
; Apple 1 BASIC was written by Steve Wozniak
; This disassembly is copyright 2003 Eric Smith <eric@brouhaha.com>
; http://www.brouhaha.com/~eric/retrocomputing/apple/apple1/basic/
;------------------------------------------------------------------------

;------------------------------------------------------------------------
;  build with 6502 assembler called DASM using the following command line
;
; Huston's version of  Basic (may be latest version available)
; http://www.apple1notes.com/Home/Programs.html 
;./dasm a1basic.asm -DHUSTNBASIC=0 -oa1hbas.o -la1hbas.lst
;
; Sander's version of  Basic (same as Eric Smith's original disassembly)
; http://www.apple1notes.com/Home/Programs.html
;./dasm a1basic.asm -DSNDERBASIC=0 -oa1sbas.o -la1sbas.lst
;
; Vince Briel's version of  Basic
; (can't find the link right now)
;./dasm a1basic.asm -DBRIELBASIC=0 -oa1bbas.o -la1bbas.lst
;
; Pagetable version of  Basic (only PIA address different from Briel's version)
;  http://www.pagetable.com/?p=32
;./dasm a1basic.asm -DPAGETBASIC=0 -oa1pbas.o -la1pbas.lst
;
;------------------------------------------------------------------------
;-------------------------------------------------------------------------
; Defines - this code can be built one of four ways
;	1. clone/real Apple 1 HW
;	2. runs in ram of real or virtual Apple 2
;	3. runs in virtual apple 2 as ROM
;	4. runs in plug in board of real Apple 2
;
;	select one of these three options
;-------------------------------------------------------------------------

;BLD4APPLE1		EQU	0	;ACTUAL APPLE 1 or CLONE
;BLD4RAM 		EQU	0	;RAM of virtual or real A2
;BLD4EMULROM 	EQU 	0	;ROM of virtual A2
;BLD4ROMBD		EQU 	0	;ROM board in Real A2


;------------------------------------------------------------------------
;  BASIC source taken from http://www.brouhaha.com
; IFCONST added to allow building Apple 1 basic version found
; on Vince Briels site
;------------------------------------------------------------------------
; up to four versions of Apple 1 Basic Known
; use defines to control which one we build
;SNDERBASIC		EQU	0		;from Wendell Sander's site (DEFAULT)
;SMITHBASIC		EQU	0		;original source from brouhaha.com
;BRIELBASIC		EQU	0		;version used in Replica 1
;HUSTNBASIC		EQU	0		;huston version from Wendell's site


;------------------------------------------------------------------------
;  Disassembly of Apple 1 BASIC
; 17-Sep-2003
; Apple 1 BASIC was written by Steve Wozniak
; This disassembly is copyright 2003 Eric Smith <eric@brouhaha.com>
; http://www.brouhaha.com/~eric/retrocomputing/apple/apple1/basic/
;------------------------------------------------------------------------

LOCZERO	EQU	$00
Z1d	EQU	$1d
ch	EQU	$24
cv	EQU	$25
zp48	EQU	$48
zp49	EQU	$49
lomem	EQU	$4a
zp4b	EQU	$4b
himem	EQU	$4c
zp4d	EQU	$4d
rnd	EQU	$4e
noun_stk_l	EQU	$50
syn_stk_h	EQU	$58
zp60		EQU	$60
noun_stk_h_str	EQU	$78
syn_stk_l  	EQU	$80
zp85		EQU	$85
noun_stk_h_int	EQU	$a0
txtndxstk	EQU	$a8
text_index	EQU	$c8
leadbl	EQU	$c9
pp	EQU	$ca
zpcb	EQU	$cb
pv	EQU	$cc
acc	EQU	$ce
zpcf	EQU	$cf
srch	EQU	$d0
tokndxstk	EQU	$d1
srch2	EQU	$d2
if_flag	EQU	$d4
cr_flag	EQU	$d5
current_verb	EQU	$d6
precedence	EQU	$d7
x_save	EQU	$d8
run_flag	EQU	$d9
aux	EQU	$da
pline	EQU	$dc
pverb	EQU	$e0
p1	EQU	$e2
p2	EQU	$e4
p3	EQU	$e6
token_index	EQU	$f1
pcon	EQU	$f2
auto_inc	EQU	$f4
auto_ln	EQU	$f6
auto_flag	EQU	$f8
char	EQU	$f9
leadzr	EQU	$fa
for_nest_count	EQU	$fb
gosub_nest_count	EQU	$fc
synstkdx	EQU	$fd
synpag	EQU	$fe
gstk_pverbl	EQU	$0100
gstk_pverbh	EQU	$0108
gstk_plinel	EQU	$0110
gstk_plineh	EQU	$0118
fstk_varl	EQU	$0120
fstk_varh	EQU	$0128
fstk_stepl	EQU	$0130
fstk_steph	EQU	$0138
fstk_plinel	EQU	$0140
fstk_plineh	EQU	$0148
fstk_pverbl	EQU	$0150
fstk_pverbh	EQU	$0158
fstk_tol	EQU	$0160
fstk_toh	EQU	$0168
buffer	EQU	$0200

	IFCONST	BLD4APPLE1
            IFCONST	SMITHBASIC
DSP	EQU	$D0F2		;DISPLAY port in PIA
KBDCR	EQU	$D0F1		;Keyboard control port
KBD	EQU	$D0F0		;KEYBOARD data port
            ENDIF
            IFCONST	BRIELBASIC
DSP	EQU	$D012		;DISPLAY port in PIA
KBDCR	EQU	$D011		;Keyboard control port (WS BASIC)
KBD	EQU	$D010		;KEYBOARD data port
            ENDIF
            IFCONST	SNDERBASIC
DSP	EQU	$D0F2		;DISPLAY port in PIA
KBDCR	EQU	$D011		;Keyboard control port (WS BASIC)
KBD	EQU	$D010		;KEYBOARD data port
            ENDIF
            IFCONST	HUSTNBASIC
DSP	EQU	$D0F2		;DISPLAY port in PIA
KBDCR	EQU	$D011		;Keyboard control port (WS BASIC)
KBD	EQU	$D010		;KEYBOARD data port
            ENDIF

	ENDIF
	IFCONST BLD4RAM 
		ORG $7000
	ELSE
		ORG $E000
	ENDIF

Pe000:	JMP	cold

rdkey:
	IFCONST	BLD4APPLE1
		LDA     KBDCR	        	;Wait for key press
                BPL     rdkey		;No key yet!
                LDA     KBD           ;Clear strobe
	ELSE
		    JSR	A2GETCHAR
		    NOP
		    NOP
		    NOP
		    NOP
		    NOP
	ENDIF
		RTS

Se00c:	TXA
		AND	#$20	; 32  
		BEQ	Le034

Se011:	LDA	#$a0	; 160  
		STA	p2
		JMP	cout

Se018:	LDA	#$20	; 32  

Se01a:	CMP	ch
		BCS	nextbyte
		LDA	#$8d	; 141 .
		LDY	#$07	; 7 .
Le022:	JSR	cout
		LDA	#$a0	; 160  
		DEY
		BNE	Le022

nextbyte:	LDY	#$00	; 0 .
		LDA	(p1),Y
		INC	p1
		BNE	Le034
		INC	p1+1
Le034:	RTS

list_comman:	JSR	get16bit
		JSR	find_line2
Le03b:		LDA	p1
		CMP	p3
		LDA	p1+1
		SBC	p3+1
		BCS	Le034
		JSR	list_line
		JMP	Le03b

list_all:	LDA	pp
		STA	p1
		LDA	pp+1
		STA	p1+1
		LDA	himem
		STA	p3
		LDA	himem+1
		STA	p3+1
		BNE	Le03b

list_cmd:	JSR	get16bit
		JSR	find_line
		LDA	p2
		STA	p1
		LDA	p2+1
		STA	p1+1
		BCS	Le034

list_line:	STX	x_save
		LDA	#$a0	; 160  
		STA	leadzr
		JSR	nextbyte
		TYA
list_int:	STA	p2
		JSR	nextbyte
		TAX
		JSR	nextbyte
		JSR	prdec
Le083:	JSR	Se018
		STY	leadzr
		TAX
		BPL	list_token
		ASL
		BPL	list_int
		LDA	p2
		BNE	Le095
		JSR	Se011
Le095:	TXA
Le096:	JSR	cout
Le099:	LDA	#$25	; 37 %
		JSR	Se01a
		TAX
		BMI	Le096
		STA	p2
list_token:	CMP	#$01	; 1 .
		BNE	Le0ac
		LDX	x_save
		JMP	crout
Le0ac:	PHA
		STY	acc
		LDX	#[syntabl2>>8]	; $ED, when from ROM, $AD from RAM
		STX	acc+1
		CMP	#$51	; 81 Q
		BCC	Le0bb
		DEC	acc+1	
		SBC	#$50	; 80 P
Le0bb:	PHA
		LDA	(acc),Y
Le0be:	TAX
		DEY
		LDA	(acc),Y
		BPL	Le0be
		CPX	#$c0	; 192 @
		BCS	Le0cc
		CPX	#$00	; 0 .
		BMI	Le0be
Le0cc:	TAX
		PLA
		SBC	#$01	; 1 .
		BNE	Le0bb
		BIT	p2
		BMI	Le0d9
		JSR	Seff8
Le0d9:	LDA	(acc),Y
		BPL	Le0ed
	 	TAX
	 	AND	#$3f	; 63 ?
	  	STA	p2
	    	CLC
	   	ADC	#$a0	; 160  
	   	JSR	cout
      	DEY
      	CPX	#$c0	; 192 @
	    	BCC	Le0d9
Le0ed:	JSR	Se00c
	  	PLA
      	CMP	#$5d	; 93 ]
	     	BEQ	Le099
      	CMP	#$28	; 40 (
	    	BNE	Le083
	     	BEQ	Le099

paren_substr:	JSR	Se118
		STA	noun_stk_l,X
      	CMP	noun_stk_h_str,X
Le102:	BCC	Le115
string_err:	LDY	#$2b	; 43 +
go_errmess_1:	JMP	print_err_msg

comma_substr:	JSR	getbyte
		CMP	noun_stk_l,X
		BCC	string_err
		JSR	Sefe4
		STA	noun_stk_h_str,X
Le115:	JMP	left_paren

Se118:	JSR	getbyte
		BEQ	string_err
	 	SEC
	   	SBC	#$01	; 1 .
	   	RTS

str_arr_dest:	JSR	Se118
		STA	noun_stk_l,X
		CLC
		SBC	noun_stk_h_str,X
		JMP	Le102
Le12c:	LDY	#$14	; 20 .
		BNE	go_errmess_1

dim_str:	JSR	Se118
		INX
Le134:	LDA	noun_stk_l,X
		STA	aux
		ADC	acc
		PHA
		TAY
	    	LDA	noun_stk_h_str,X
	   	STA	aux+1
	    	ADC	acc+1
	    	PHA
	    	CPY	pp
	    	SBC	pp+1
	    	BCS	Le12c
	   	LDA	aux
	   	ADC	#$fe	; 254 ~
	    	STA	aux
	   	LDA	#$ff	; 255 .
	   	TAY
	    	ADC	aux+1
	   	STA	aux+1
Le156:	INY
	   	LDA	(aux),Y
	  	CMP	pv,Y
	   	BNE	Le16d
	    	TYA
	   	BEQ	Le156
Le161:	PLA
	  	STA	(aux),Y
	   	STA	pv,Y
	  	DEY
	   	BPL	Le161
	   	INX
	  	RTS
	 	NOP                     	; "j"
Le16d:	LDY	#$80	; 128 .
Le16f:	BNE	go_errmess_1

input_str:	LDA	#$00	; 0 .
		JSR	push_a_noun_stk
	   	LDY	#$02	; 2 .
	   	STY	noun_stk_h_str,X
	  	JSR	push_a_noun_stk
	   	LDA	#$bf	; 191 ?
	   	JSR	cout
	  	LDY	#$00	; 0 .
	  	JSR	read_line
	   	STY	noun_stk_h_str,X
	    	NOP
	    	NOP
	    	NOP

string_lit:	LDA	noun_stk_l+1,X
	    	STA	acc
	  	LDA	noun_stk_h_str+1,X
	   	STA	acc+1
	   	INX
	   	INX
	  	JSR	Se1bc
Le199:	LDA	rnd,X
	 	CMP	syn_stk_h+30,X
	    	BCS	Le1b4
	  	INC	rnd,X
	   	TAY
	   	LDA	(acc),Y
	   	LDY	noun_stk_l,X
	  	CPY	p2
	   	BCC	Le1ae
	 	LDY	#$83	; 131 .
	  	BNE	Le16f
Le1ae:	STA	(aux),Y
	  	INC	noun_stk_l,X
	   	BCC	Le199
Le1b4:	LDY	noun_stk_l,X
	   	TXA
	   	STA	(aux),Y
	   	INX
	   	INX
	   	RTS

Se1bc:	LDA	noun_stk_l+1,X
	   	STA	aux
	   	SEC
	   	SBC	#$02	; 2 .
	  	STA	p2
	   	LDA	noun_stk_h_str+1,X
	   	STA	aux+1
	   	SBC	#$00	; 0 .
	  	STA	p2+1
	   	LDY	#$00	; 0 .
	    	LDA	(p2),Y
	   	CLC
	   	SBC	aux
	   	STA	p2
	   	RTS

string_eq:	LDA	noun_stk_l+3,X
	  	STA	acc
	   	LDA	noun_stk_h_str+3,X
	   	STA	acc+1
	   	LDA	noun_stk_l+1,X
	   	STA	aux
	  	LDA	noun_stk_h_str+1,X
	   	STA	aux+1
	   	INX
	   	INX
	   	INX
	   	LDY	#$00	; 0 .
	   	STY	noun_stk_h_str,X
	   	STY	noun_stk_h_int,X
	   	INY
	   	STY	noun_stk_l,X
Le1f3:	LDA	himem+1,X
	   	CMP	syn_stk_h+29,X
	    	PHP
	   	PHA
	  	LDA	rnd+1,X
	   	CMP	syn_stk_h+31,X
	    	BCC	Le206
	    	PLA
	  	PLP
		BCS	Le205
Le203:	LSR	noun_stk_l,X
Le205:	RTS
Le206:	TAY
	   	LDA	(acc),Y
	    	STA	p2
	   	PLA
	   	TAY
	   	PLP
	   	BCS	Le203
	   	LDA	(aux),Y
	   	CMP	p2
	    	BNE	Le203
	   	INC	rnd+1,X
	   	INC	himem+1,X
	   	BCS	Le1f3

string_neq:	JSR	string_eq
	 	JMP	not_op

mult_op:	JSR	Se254
Le225:	ASL	acc
	  	ROL	acc+1
	   	BCC	Le238
	   	CLC
	  	LDA	p3
	   	ADC	aux
	   	STA	p3
	  	LDA	p3+1
	    	ADC	aux+1
	    	STA	p3+1
Le238:	DEY
	  	BEQ	Le244
	     	ASL	p3
	    	ROL	p3+1
	    	BPL	Le225
	  	JMP	Le77e
Le244:	LDA	p3
	   	JSR	push_ya_noun_stk
	  	LDA	p3+1
	  	STA	noun_stk_h_int,X
	  	ASL	p2+1
	   	BCC	Le279
	  	JMP	negate

Se254:	LDA	#$55	; 85 U
	  	STA	p2+1
	  	JSR	Se25b

Se25b:	LDA	acc
	   	STA	aux
	   	LDA	acc+1
	  	STA	aux+1
	 	JSR	get16bit
	   	STY	p3
	   	STY	p3+1
	   	LDA	acc+1
	   	BPL	Le277
	   	DEX
	   	ASL	p2+1
	  	JSR	negate
	  	JSR	get16bit
Le277:	LDY	#$10	; 16 .
Le279:	RTS

mod_op:	JSR	See6c
		BEQ	Le244
		DC.B	$ff                     	; "."
Le280:	CMP	#$84	; 132 .
		BNE	Le286
	   	LSR	auto_flag
Le286:	CMP	#$df	; 223 _
		BEQ	Le29b
	   	CMP	#$9b	; 155 .
	    	BEQ	Le294
		STA	buffer,Y
	   	INY
	    	BPL	read_line
Le294:	LDY	#$8b	; 139 .
		JSR	Se3c4

Se299:	LDY	#$01	; 1 .
Le29b:	DEY
		BMI	Le294

read_line:	JSR	rdkey
		NOP
	   	NOP
	  	JSR	cout
	   	CMP	#$8d	; 141 .
	   	BNE	Le280
	   	LDA	#$df	; 223 _
	  	STA	buffer,Y
	   	RTS
cold:		JSR	mem_init_4k
warm:		JSR	crout
Le2b6:	LSR	run_flag
		LDA	#$be	; 190 >
	  	JSR	cout
	   	LDY	#$00	; 0 .
	   	STY	leadzr
	   	BIT	auto_flag
	   	BPL	Le2d1
	  	LDX	auto_ln
	  	LDA	auto_ln+1
	  	JSR	prdec
	   	LDA	#$a0	; 160  
	  	JSR	cout
Le2d1:	LDX	#$ff	; 255 .
	  	TXS
	 	JSR	read_line
	   	STY	token_index
	   	TXA
	   	STA	text_index
	   	LDX	#$20	; 32  
	   	JSR	Se491
	   	LDA	text_index
	   	ADC	#$00	; 0 .
	   	STA	pverb
	    	LDA	#$00	; 0 .
	    	TAX
	    	ADC	#$02	; 2 .
	   	STA	pverb+1
	    	LDA	(pverb,X)
	     	AND	#$f0	; 240 p
	   	CMP	#$b0	; 176 0
	   	BEQ	Le2f9
	  	JMP	Le883
Le2f9:	LDY	#$02	; 2 .
Le2fb:	LDA	(pverb),Y
	  	STA	pv+1,Y
	  	DEY
	  	BNE	Le2fb
	 	JSR	Se38a
	  	LDA	token_index
	   	SBC	text_index
	   	CMP	#$04	; 4 .
	   	BEQ	Le2b6
	  	STA	(pverb),Y	
	  	LDA	pp
	   	SBC	(pverb),Y
	  	STA	p2
	   	LDA	pp+1
	   	SBC	#$00	; 0 .
	   	STA	p2+1
	   	LDA	p2
	  	CMP	pv
	  	LDA	p2+1
	  	SBC	pv+1
	   	BCC	Le36b
Le326:	LDA	pp
	   	SBC	(pverb),Y
	  	STA	p3
	  	LDA	pp+1
	    	SBC	#$00	; 0 .
	   	STA	p3+1
	    	LDA	(pp),Y
	   	STA	(p3),Y
	  	INC	pp
	   	BNE	Le33c
	   	INC	pp+1
Le33c:	LDA	p1
	  	CMP	pp
	  	LDA	p1+1
	  	SBC	pp+1
	  	BCS	Le326
Le346:	LDA	p2,X
	 	STA	pp,X
	  	DEX
	   	BPL	Le346
	  	LDA	(pverb),Y
	   	TAY
Le350:	DEY
	  	LDA	(pverb),Y
	  	STA	(p3),Y
	  	TYA
	  	BNE	Le350
	  	BIT	auto_flag
	   	BPL	Le365
Le35c:	LDA	auto_ln+1,X
	  	ADC	auto_inc+1,X
	  	STA	auto_ln+1,X
	   	INX
	  	BEQ	Le35c
Le365:	BPL	Le3e5
	   	BRK
	  	BRK
		BRK
		BRK               	; "..."
Le36b:	LDY	#$14	; 20 .
		BNE	print_err_msg

del_comma:	JSR	get16bit
	  	LDA	p1
	   	STA	p3
	   	LDA	p1+1
	   	STA	p3+1
	  	JSR	find_line1
	   	LDA	p1
	    	STA	p2
	   	LDA	p1+1
	    	STA	p2+1
	    	BNE	Le395

del_cmd:	JSR	get16bit

Se38a:	JSR	find_line
	 	LDA	p3
	   	STA	p1
	 	LDA	p3+1
	   	STA	p1+1
Le395:	LDY	#$00	; 0 .
Le397:	LDA	pp
	  	CMP	p2
	  	LDA	pp+1
	   	SBC	p2+1
	   	BCS	Le3b7
	   	LDA	p2
	  	BNE	Le3a7
	  	DEC	p2+1
Le3a7:	DEC	p2
	  	LDA	p3
	  	BNE	Le3af
	  	DEC	p3+1
Le3af:	DEC	p3
	  	LDA	(p2),Y
	  	STA	(p3),Y
	   	BCC	Le397
Le3b7:	LDA	p3
	  	STA	pp
	  	LDA	p3+1
	   	STA	pp+1
	   	RTS
Le3c0:	JSR	cout
	  	INY

Se3c4:	LDA	error_msg_tbl,Y
	  	BMI	Le3c0

cout:		CMP	#$8d	; 141 .
 		BNE	Le3d3

crout:	LDA	#$00	; 0 .
	 	STA	ch
		LDA	#$8d	; 141 .
Le3d3:	INC	ch
Le3d5:
		IFCONST	BLD4APPLE1
			BIT	DSP
			BMI	Le3d5
			STA	DSP
		ELSE
			JSR	ECHO		; use monitor function to output
			nop
			nop
			nop
			nop
			nop
		ENDIF

	RTS
too_long_err:	LDY	#$06	; 6 
print_err_msg:	JSR	print_err_msg2
		BIT	run_flag
Le3e5:	BMI	Le3ea
		JMP	Le2b6
Le3ea:	JMP	Leb9a
Le3ed:	ROL
		ADC	#$a0	; 160  
		CMP	buffer,X
		BNE	Le448
	  	LDA	(synpag),Y
	  	ASL
	   	BMI	Le400
	   	DEY
	  	LDA	(synpag),Y
	   	BMI	Le428
	  	INY
Le400:	STX	text_index
	   	TYA
	   	PHA
	   	LDX	#$00	; 0 .
	  	LDA	(synpag,X)
	   	TAX
Le409:	LSR
	  	EOR	#$48	; 72 H
	  	ORA	(synpag),Y
	  	CMP	#$c0	; 192 @
	  	BCC	Le413
	   	INX
Le413:	INY
	  	BNE	Le409
	   	PLA
	   	TAY
	   	TXA
	  	JMP	Le4c0

put_token:	INC	token_index
		LDX	token_index
		BEQ	too_long_err
	 	STA	buffer,X
Le425:	RTS
Le426:	LDX	text_index
Le428:	LDA	#$a0	; 160  
Le42a:	INX
	 	CMP	buffer,X
	   	BCS	Le42a
	   	LDA	(synpag),Y
	   	AND	#$3f	; 63 ?
	   	LSR
	  	BNE	Le3ed
	  	LDA	buffer,X
	    	BCS	Le442
	   	ADC	#$3f	; 63 ?
	    	CMP	#$1a	; 26 .
	   	BCC	Le4b1
Le442:	ADC	#$4f	; 79 O
	   	CMP	#$0a	; 10 .
	   	BCC	Le4b1
Le448:	LDX	synstkdx
Le44a:	INY
	   	LDA	(synpag),Y
	  	AND	#$e0	; 224 `
	   	CMP	#$20	; 32  
	   	BEQ	Le4cd
	    	LDA	txtndxstk,X
	    	STA	text_index
	   	LDA	tokndxstk,X
	   	STA	token_index
Le45b:	DEY
	   	LDA	(synpag),Y
	   	ASL
	   	BPL	Le45b
	   	DEY
	   	BCS	Le49c
	  	ASL
	   	BMI	Le49c
	   	LDY	syn_stk_h,X
	  	STY	synpag+1
	  	LDY	syn_stk_l,X
	   	INX
	  	BPL	Le44a
Le470:	BEQ	Le425
	 	CMP	#$7e	; 126 ~
	 	BCS	Le498
	  	DEX
	  	BPL	Le47d
	 	LDY	#$06	; 6 .
	  	BPL	go_errmess_2
Le47d:	STY	syn_stk_l,X
	  	LDY	synpag+1
	   	STY	syn_stk_h,X
	   	LDY	text_index
	  	STY	txtndxstk,X
	   	LDY	token_index	
	   	STY	tokndxstk,X
	  	AND	#$1f	; 31 .
	   	TAY
		LDA	syntabl_index,Y

Se491:	ASL
	 	TAY
; when running from a000, shifts to AC or AD
; when running from e000 shifts to EC or ED
		LDA	#[syntabl_index>>9]
	  	ROL
	  	STA	synpag+1
Le498:	BNE	Le49b
	   	INY
Le49b:	INY
Le49c:	STX	synstkdx
	    	LDA	(synpag),Y
	   	BMI	Le426
	    	BNE	Le4a9
	  	LDY	#$0e	; 14 .
go_errmess_2:	JMP	print_err_msg
Le4a9:	CMP	#$03	; 3 .
	  	BCS	Le470
	  	LSR
	   	LDX	text_index
	  	INX
Le4b1:	LDA	buffer,X
	   	BCC	Le4ba
	  	CMP	#$a2	; 162 "
	  	BEQ	Le4c4
Le4ba:	CMP	#$df	; 223 _
	   	BEQ	Le4c4
	  	STX	text_index
Le4c0:	JSR	put_token
	   	INY
Le4c4:	DEY
	 	LDX	synstkdx
Le4c7:	LDA	(synpag),Y
    		DEY
	    	ASL
	  	BPL	Le49c
Le4cd:	LDY	syn_stk_h,X
	 	STY	synpag+1
	  	LDY	syn_stk_l,X
	   	INX
	  	LDA	(synpag),Y
	  	AND	#$9f	; 159 .
	  	BNE	Le4c7
	  	STA	pcon
	  	STA	pcon+1
	  	TYA
	   	PHA
	  	STX	synstkdx
	  	LDY	srch,X
	   	STY	leadbl
	 	CLC
Le4e7:	LDA	#$0a	; 10 .
	   	STA	char
	  	LDX	#$00	; 0 .
	   	INY
	 	LDA	buffer,Y
	   	AND	#$0f	; 15 .
Le4f3:	ADC	pcon
	  	PHA
	   	TXA
	  	ADC	pcon+1
	   	BMI	Le517
	  	TAX
	   	PLA
	   	DEC	char
	   	BNE	Le4f3
	    	STA	pcon
	   	STX	pcon+1
	  	CPY	token_index
	   	BNE	Le4e7
	  	LDY	leadbl
	   	INY
	   	STY	token_index
	  	JSR	put_token
	  	PLA
	   	TAY
	  	LDA	pcon+1
	  	BCS	Le4c0
Le517:	LDY	#$00	; 0 .
	   	BPL	go_errmess_2

prdec:	STA	pcon+1
	   	STX	pcon
	  	LDX	#$04	; 4 .
	  	STX	leadbl
Le523:	LDA	#$b0	; 176 0
	   	STA	char
Le527:	LDA	pcon
	 	CMP	dectabl,X
	   	LDA	pcon+1
	  	SBC	dectabh,X
	   	BCC	Le540
	  	STA	pcon+1
	   	LDA	pcon
	   	SBC	dectabl,X
	    	STA	pcon
	   	INC	char
	  	BNE	Le527
Le540:	LDA	char
	  	INX
	   	DEX
	   	BEQ	Le554
	  	CMP	#$b0	; 176 0
	  	BEQ	Le54c
	  	STA	leadbl
Le54c:	BIT	leadbl
	  	BMI	Le554
	   	LDA	leadzr
	   	BEQ	Le55f
Le554:	JSR	cout
	  	BIT	auto_flag
	   	BPL	Le55f
	  	STA	buffer,Y
	   	INY
Le55f:	DEX
		BPL	Le523
		RTS
dectabl:	DC.B	$01,$0a,$64,$e8,$10         	; "..dh."
dectabh:	DC.B	$00,$00,$00,$03,$27         	; "....'"

find_line:	LDA	pp
	   	STA	p3
	   	LDA	pp+1
	   	STA	p3+1

find_line1:	INX

find_line2:	LDA	p3+1
	   	STA	p2+1
	   	LDA	p3
	  	STA	p2
	   	CMP	himem
	  	LDA	p2+1
	   	SBC	himem+1
	  	BCS	Le5ac
	  	LDY	#$01	; 1 .
	  	LDA	(p2),Y
	   	SBC	acc
	   	INY
	  	LDA	(p2),Y
	  	SBC	acc+1
	  	BCS	Le5ac
	   	LDY	#$00	; 0 .
	   	LDA	p3
	  	ADC	(p2),Y
	   	STA	p3
	  	BCC	Le5a0
	   	INC	p3+1
	  	CLC
Le5a0:	INY
	   	LDA	acc
	   	SBC	(p2),Y
	   	INY
	   	LDA	acc+1
	   	SBC	(p2),Y
	   	BCS	find_line2
Le5ac:	RTS

new_cmd:	LSR	auto_flag
	    	LDA	himem
	   	STA	pp
	   	LDA	himem+1
	   	STA	pp+1

clr:		LDA	lomem
	   	STA	pv
	  	LDA	lomem+1
	   	STA	pv+1
	  	LDA	#$00	; 0 .
	   	STA	for_nest_count
	  	STA	gosub_nest_count
	   	STA	synpag
	  	LDA	#$00	; 0 .
	  	STA	Z1d
	   	RTS
Le5cc:	LDA	srch
	   	ADC	#$05	; 5 .
	   	STA	srch2
	    	LDA	tokndxstk
	   	ADC	#$00	; 0 .
	  	STA	srch2+1
	   	LDA	srch2
	   	CMP	pp
	   	LDA	srch2+1
	   	SBC	pp+1
	  	BCC	Le5e5
	  	JMP	Le36b
Le5e5:	LDA	acc
	  	STA	(srch),Y
	  	LDA	acc+1
	   	INY
	   	STA	(srch),Y
	  	LDA	srch2
	   	INY
	   	STA	(srch),Y
	   	LDA	srch2+1
	  	INY
	  	STA	(srch),Y
	   	LDA	#$00	; 0 .
	   	INY
	  	STA	(srch),Y
	  	INY
	  	STA	(srch),Y
	  	LDA	srch2
	  	STA	pv
	  	LDA	srch2+1
	  	STA	pv+1
	  	LDA	srch
	    	BCC	Le64f
execute_var:	STA	acc
	    	STY	acc+1
	  	JSR	get_next_prog_byte
	    	BMI	Le623
	    	CMP	#$40	; 64 @
	    	BEQ	Le623
	  	JMP	Le628
	    	DC.B	$06,$c9,$49,$d0,$07,$a9,$49   	; ".IIP.)I"
Le623:	STA	acc+1
		JSR	get_next_prog_byte
Le628:	LDA	lomem+1
		STA	tokndxstk
	   	LDA	lomem
Le62e:	STA	srch
	   	CMP	pv
	   	LDA	tokndxstk
	  	SBC	pv+1
	   	BCS	Le5cc
	    	LDA	(srch),Y
	   	INY
	   	CMP	acc
	  	BNE	Le645
	  	LDA	(srch),Y
	   	CMP	acc+1
	    	BEQ	Le653
Le645:	INY
	   	LDA	(srch),Y
	   	PHA
	   	INY
	   	LDA	(srch),Y
	   	STA	tokndxstk
	    	PLA
Le64f:	LDY	#$00	; 0 .
	   	BEQ	Le62e
Le653:	LDA	srch
	   	ADC	#$03	; 3 .
	   	JSR	push_a_noun_stk
	    	LDA	tokndxstk
	    	ADC	#$00	; 0 .
	    	STA	noun_stk_h_str,X
	     	LDA	acc+1
	    	CMP	#$40	; 64 @
	   	BNE	fetch_prog_byte
	   	DEY
	   	TYA
	  	JSR	push_a_noun_stk
	   	DEY
	  	STY	noun_stk_h_str,X
	  	LDY	#$03	; 3 .
Le670:	INC	noun_stk_h_str,X
	  	INY
	  	LDA	(srch),Y
	  	BMI	Le670
	  	BPL	fetch_prog_byte

execute_stmt:	LDA	#$00	; 0 .
	   	STA	if_flag
	   	STA	cr_flag
	  	LDX	#$20	; 32  
push_old_verb:	PHA
fetch_prog_byte:	LDY	#$00	; 0 .
	  	LDA	(pverb),Y
Le686:	BPL	execute_token
	   	ASL
	  	BMI	execute_var
	  	JSR	get_next_prog_byte
	  	JSR	push_ya_noun_stk
	  	JSR	get_next_prog_byte
	   	STA	noun_stk_h_int,X
Le696:	BIT	if_flag
	   	BPL	Le69b
	  	DEX
Le69b:	JSR	get_next_prog_byte
	  	BCS	Le686
execute_token:	CMP	#$28	; 40 (
	  	BNE	execute_verb
	  	LDA	pverb
	  	JSR	push_a_noun_stk
	  	LDA	pverb+1
	    	STA	noun_stk_h_str,X
	   	BIT	if_flag
	  	BMI	Le6bc
	  	LDA	#$01	; 1 .
	  	JSR	push_a_noun_stk
	  	LDA	#$00	; 0 .
	   	STA	noun_stk_h_str,X
Le6ba:	INC	noun_stk_h_str,X
Le6bc:	JSR	get_next_prog_byte
		BMI	Le6ba
	   	BCS	Le696
execute_verb:	BIT	if_flag
	  	BPL	Le6cd
	   	CMP	#$04	; 4 .
	   	BCS	Le69b
	  	LSR	if_flag
Le6cd:	TAY
	  	STA	current_verb
	  	LDA	verb_prec_tbl,Y
	  	AND	#$55	; 85 U
	   	ASL
	    	STA	precedence
Le6d8:	PLA
	   	TAY
	  	LDA	verb_prec_tbl,Y
	  	AND	#$aa	; 170 *
	   	CMP	precedence
	   	BCS	do_verb
	   	TYA
	   	PHA
	  	JSR	get_next_prog_byte
	 	LDA	current_verb
	   	BCC	push_old_verb
do_verb:	LDA	verb_adr_l,Y
	   	STA	acc
	   	LDA	verb_adr_h,Y
	   	STA	acc+1
	  	JSR	Se6fc
	   	JMP	Le6d8

Se6fc:		JMP	(acc)

get_next_prog_byte:	INC	pverb
		BNE	Le705
	   	INC	pverb+1
Le705:		LDA	(pverb),Y
	   	RTS

push_ya_noun_stk:	STY	syn_stk_h+31,X

push_a_noun_stk:	DEX
	   	BMI	Le710
	   	STA	noun_stk_l,X
	    	RTS
Le710:	LDY	#$66	; 102 f
go_errmess_3:	JMP	print_err_msg

get16bit:	LDY	#$00	; 0 .
	   	LDA	noun_stk_l,X
	   	STA	acc
	   	LDA	noun_stk_h_int,X
	   	STA	acc+1
	   	LDA	noun_stk_h_str,X
	   	BEQ	Le731
	   	STA	acc+1
	   	LDA	(acc),Y
	   	PHA
	   	INY
	   	LDA	(acc),Y
	   	STA	acc+1
	   	PLA
	   	STA	acc
	    	DEY
Le731:	INX
	   	RTS

eq_op:	JSR	neq_op

not_op:	JSR	get16bit
	 	TYA
	  	JSR	push_ya_noun_stk
	  	STA	noun_stk_h_int,X
	   	CMP	acc
	   	BNE	Le749
	   	CMP	acc+1
	   	BNE	Le749
	   	INC	noun_stk_l,X
Le749:	RTS

neq_op:	JSR	subtract
		JSR	sgn_fn

abs_fn:	JSR	get16bit
	   	BIT	acc+1
	   	BMI	Se772
Le757:	DEX
Le758:	RTS

sgn_fn:	JSR	get16bit
	   	LDA	acc+1
	   	BNE	Le764
	   	LDA	acc
	   	BEQ	Le757
Le764:	LDA	#$ff	; 255 .
	  	JSR	push_ya_noun_stk
	   	STA	noun_stk_h_int,X
	    	BIT	acc+1
	    	BMI	Le758

negate:	JSR	get16bit

Se772:	TYA
	   	SEC
	   	SBC	acc
	   	JSR	push_ya_noun_stk
	    	TYA
	   	SBC	acc+1
	  	BVC	Le7a1
Le77e:	LDY	#$00	; 0 .
	   	BPL	go_errmess_3

subtract:	JSR	negate

add:	JSR	get16bit
	   	LDA	acc
	   	STA	aux
	   	LDA	acc+1
	   	STA	aux+1
	  	JSR	get16bit

Se793:	CLC
	   	LDA	acc
	    	ADC	aux
	 	JSR	push_ya_noun_stk
	   	LDA	acc+1
	    	ADC	aux+1
	    	BVS	Le77e
Le7a1:	STA	noun_stk_h_int,X

unary_pos:	RTS

tab_fn:	JSR	get16bit
	   	LDY	acc
	   	BEQ	Le7b0
	   	DEY
	   	LDA	acc+1
	    	BEQ	Le7bc
Le7b0:	RTS

tabout:	LDA	ch
	   	ORA	#$07	; 7 .
	   	TAY
	   	INY
Le7b7:	LDA	#$a0	; 160  
	 	JSR	cout
Le7bc:	CPY	ch
	  	BCS	Le7b7
	   	RTS

print_com_num:	JSR	tabout

print_num:	JSR	get16bit
	   	LDA	acc+1
	   	BPL	Le7d5
	    	LDA	#$ad	; 173 -
	   	JSR	cout
	   	JSR	Se772
	    	BVC	print_num
Le7d5:	DEY
	   	STY	cr_flag
	   	STX	acc+1
	  	LDX	acc
	  	JSR	prdec
	   	LDX	acc+1
	  	RTS

auto_cmd:	JSR	get16bit
	  	LDA	acc
	  	STA	auto_ln
	    	LDA	acc+1
	   	STA	auto_ln+1
	  	DEY
	   	STY	auto_flag
	    	INY
	    	LDA	#$0a	; 10 .
Le7f3:	STA	auto_inc
	   	STY	auto_inc+1
	   	RTS

auto_com:	JSR	get16bit
	   	LDA	acc
	    	LDY	acc+1
	   	BPL	Le7f3

var_assign:	JSR	get16bit
	   	LDA	noun_stk_l,X
	   	STA	aux
	   	LDA	noun_stk_h_str,X
	   	STA	aux+1
	   	LDA	acc
	    	STA	(aux),Y
	    	INY
	    	LDA	acc+1
	   	STA	(aux),Y
	    	INX

Te816:	RTS

begin_line:	PLA
	       	PLA

colon:	BIT	cr_flag
	  	BPL	Le822

print_cr:	JSR	crout

print_semi:	LSR	cr_flag
Le822:	RTS

left_paren:	LDY	#$ff	; 255 .
	   	STY	precedence

right_paren:	RTS

if_stmt:	JSR	Sefcd
	  	BEQ	Le834
	   	LDA	#$25	; 37 %
	   	STA	current_verb
	  	DEY
	  	STY	if_flag
Le834:	INX
	     	RTS
run_warm:	LDA	pp
	    	LDY	pp+1
	    	BNE	Le896

gosub_stmt:	LDY	#$41	; 65 A
	    	LDA	gosub_nest_count
	    	CMP	#$08	; 8 .
	    	BCS	go_errmess_4
	    	TAY
	    	INC	gosub_nest_count
	   	LDA	pverb
	  	STA	gstk_pverbl,Y
	   	LDA	pverb+1
	  	STA	gstk_pverbh,Y
	    	LDA	pline
	   	STA	gstk_plinel,Y
	   	LDA	pline+1
	   	STA	gstk_plineh,Y

goto_stmt:	JSR	get16bit
	  	JSR	find_line
	   	BCC	Le867
	   	LDY	#$37	; 55 7
	   	BNE	go_errmess_4
Le867:	LDA	p2
	   	LDY	p2+1
run_loop:	STA	pline
	   	STY	pline+1
	IFCONST BLD4APPLE1
		BIT	KBDCR
	ELSE
		BIT	KBD
	ENDIF
	    	BMI	Le8c3
	    	CLC
	   	ADC	#$03	; 3 .
	   	BCC	Le87a
	   	INY
Le87a:	LDX	#$ff	; 255 .
	   	STX	run_flag
	   	TXS
	  	STA	pverb
	    	STY	pverb+1
Le883:	JSR	execute_stmt
	  	BIT	run_flag
	  	BPL	end_stmt
	   	CLC
	    	LDY	#$00	; 0 .
	    	LDA	pline
	   	ADC	(pline),Y
	    	LDY	pline+1
	    	BCC	Le896
	    	INY
Le896:	CMP	himem
	   	BNE	run_loop
	    	CPY	himem+1
	   	BNE	run_loop
	   	LDY	#$34	; 52 4
	   	LSR	run_flag
go_errmess_4:	JMP	print_err_msg

return_stmt:	LDY	#$4a	; 74 J
	   	LDA	gosub_nest_count
	   	BEQ	go_errmess_4
	   	DEC	gosub_nest_count
	   	TAY
	   	LDA	gstk_plinel-1,Y
	   	STA	pline
	  	LDA	gstk_plineh-1,Y
	   	STA	pline+1

		DC.B	$be,$ff,$00
;	   	LDX	synpag+1,Y

	   	LDA	gstk_pverbh-1,Y
Le8be:	TAY
	   	TXA
		JMP	Le87a
Le8c3:	LDY	#$63	; 99 c
		JSR	Se3c4
	   	LDY	#$01	; 1 .
	    	LDA	(pline),Y
	   	TAX
	  	INY
	    	LDA	(pline),Y
	  	JSR	prdec

end_stmt:	JMP	warm
Le8d6:	DEC	for_nest_count

next_stmt:	LDY	#$5b	; 91 [
	  	LDA	for_nest_count
Le8dc:	BEQ	go_errmess_4
	   	TAY
	  	LDA	noun_stk_l,X
	  	CMP	fstk_varl-1,Y
	   	BNE	Le8d6
	   	LDA	noun_stk_h_str,X
	   	CMP	fstk_varh-1,Y
	   	BNE	Le8d6
	  	LDA	fstk_stepl-1,Y
	   	STA	aux
	   	LDA	fstk_steph-1,Y
	   	STA	aux+1
	   	JSR	get16bit
	   	DEX
	  	JSR	Se793
	   	JSR	var_assign
	   	DEX
	   	LDY	for_nest_count
	  	LDA	fstk_toh-1,Y
	    	STA	syn_stk_l+31,X
	  	LDA	fstk_tol-1,Y
	   	LDY	#$00	; 0 .
	  	JSR	push_ya_noun_stk
	  	JSR	subtract
	  	JSR	sgn_fn
	   	JSR	get16bit
	    	LDY	for_nest_count
	    	LDA	acc
	   	BEQ	Le925
	   	EOR	fstk_steph-1,Y
	   	BPL	Le937
Le925:	LDA	fstk_plinel-1,Y
	   	STA	pline
	  	LDA	fstk_plineh-1,Y
	   	STA	pline+1
	  	LDX	fstk_pverbl-1,Y
	  	LDA	fstk_pverbh-1,Y
	    	BNE	Le8be
Le937:	DEC	for_nest_count
	    	RTS

for_stmt:	LDY	#$54	; 84 T
	    	LDA	for_nest_count
	   	CMP	#$08	; 8 .
	   	BEQ	Le8dc
	   	INC	for_nest_count
	    	TAY
	    	LDA	noun_stk_l,X
	   	STA	fstk_varl,Y
	   	LDA	noun_stk_h_str,X
	  	STA	fstk_varh,Y
	   	RTS

to_clause:	JSR	get16bit
	   	LDY	for_nest_count
	     	LDA	acc
	  	STA	fstk_tol-1,Y
	   	LDA	acc+1
	   	STA	fstk_toh-1,Y
	   	LDA	#$01	; 1 .
	  	STA	fstk_stepl-1,Y
	   	LDA	#$00	; 0 .
Le966:	STA	fstk_steph-1,Y
	  	LDA	pline
	 	STA	fstk_plinel-1,Y
	   	LDA	pline+1
	   	STA	fstk_plineh-1,Y
	    	LDA	pverb
	   	STA	fstk_pverbl-1,Y
	   	LDA	pverb+1
	   	STA	fstk_pverbh-1,Y
	     	RTS

Te97e:	JSR	get16bit
	   	LDY	for_nest_count
	    	LDA	acc
	  	STA	fstk_stepl-1,Y
	    	LDA	acc+1
	  	JMP	Le966
		DC.B	$00,$00,$00,$00,$00,$00,$00,$00	; "........"
	 	DC.B	$00,$00,$00               	; "..."
verb_prec_tbl:	DC.B	$00,$00,$00,$ab,$03,$03,$03,$03	; "...+...."
	     	DC.B	$03,$03,$03,$03,$03,$03,$03,$03	; "........"
	     	DC.B	$03,$03,$3f,$3f,$c0,$c0,$3c,$3c	; "..??@@<<"
	     	DC.B	$3c,$3c,$3c,$3c,$3c,$30,$0f,$c0	; "<<<<<0.@"
            IFCONST	HUSTNBASIC
                DC.B	$c3,$ff,$55,$00,$ab,$ab,$03,$03	; "L.U.++.."
            ELSE
                DC.B	$cc,$ff,$55,$00,$ab,$ab,$03,$03	; "L.U.++.."
            ENDIF
     		DC.B	$ff,$ff,$55,$ff,$ff,$55,$cf,$cf	; "..U..UOO"
                DC.B	$cf,$cf,$cf,$ff,$55,$c3,$c3,$c3	; "OOO.UCCC"
                DC.B	$55,$f0,$f0,$cf,$56,$56,$56,$55	; "UppOVVVU"
	    	DC.B	$ff,$ff,$55,$03,$03,$03,$03,$03	; "..U....."
                DC.B	$03,$03,$ff,$ff,$ff,$03,$03,$03	; "........"
                DC.B	$03,$03,$03,$03,$03,$03,$03,$03	; "........"
                DC.B	$03,$03,$03,$03,$03,$00,$ab,$03	; "......+."
        	DC.B	$57,$03,$03,$03,$03,$07,$03,$03	; "W......."
        	DC.B	$03,$03,$03,$03,$03,$03,$03,$03	; "........"
                DC.B	$03,$03,$aa,$ff,$ff,$ff,$ff,$ff	; "..*....."


verb_adr_l:
	DC.B	<begin_line,$ff,$ff,<colon,<list_cmd,<list_comman,<list_all,<Teff2
	DC.B	<Tefec,<del_cmd,<del_comma,<new_cmd,<clr,<auto_cmd,<auto_com,<man_cmd
	DC.B	<Tef80,<Tef96,<add,< subtract,<mult_op,<divide,<eq_op,<neq_op
  	DC.B	<Tec13,< Tec06,< Tec0b,<neq_op,<Tec01,< Tec40,< Tec47,<mod_op
    IFCONST	HUSTNBASIC
	DC.B	<bogus_eea6,$ff,<left_paren,<comma_substr,<goto_stmt,<Te816,<string_input,<input_num_comma
    ELSE
    	DC.B	$00,$ff,<left_paren,<comma_substr,<goto_stmt,<Te816,<string_input,<input_num_comma
    ENDIF
	DC.B	$ff,$ff,<paren_substr,$ff,$ff,<num_array_subs,<peek_fn,<rnd_fn
	DC.B	<sgn_fn,<abs_fn,$00,$ff,<left_paren,<unary_pos,<negate,<not_op
	DC.B	<left_paren,<string_eq,<string_neq,<len_fn,<bogus_eec2,<Teeae,<Teeba,<left_paren
	DC.B	$ff,$ff,<str_arr_dest,<dim_str,<dim_num,<print_str,<print_num,<print_semi
	DC.B	<print_str_comma,<print_com_num,$ff,$ff,$ff,<call_stmt,<dim_str,<dim_num
	DC.B	<tab_fn,<end_stmt,<string_input,<input_prompt,<input_num_stmt,<for_stmt,<var_assign,<to_clause  
	DC.B	<Te97e,<next_stmt,<next_stmt,<return_stmt,<gosub_stmt,$ff,<Te816,<goto_stmt  
	DC.B	<if_stmt,<print_str,<print_num,<print_cr,<poke_stmt,<Tef0c,<Tee4e,<poke_stmt     
	DC.B	<plot_comma,<poke_stmt,<bogus_eea6,<Teeb0,<poke_stmt,<Teebc,<Teec6,<vtab_stmt
	DC.B	<string_lit,<var_assign,<right_paren,$ff,$ff,$ff,$ff,$ff 
verb_adr_h:
	DC.B	>begin_line,$ff,$ff,>colon,>list_cmd,>list_comman,>list_all,>Teff2
	DC.B	>Tefec,>del_cmd,>del_comma,>new_cmd,>clr,>auto_cmd,>auto_com,>man_cmd
	DC.B	>Tef80,>Tef96,>add,> subtract,>mult_op,>divide,>eq_op,>neq_op
	DC.B	>Tec13,> Tec06,> Tec0b,>neq_op,>Tec01,> Tec40,> Tec47,>mod_op
    IFCONST	HUSTNBASIC
	DC.B	>bogus_eea6,$ff,>left_paren,>comma_substr,>goto_stmt,>Te816,>string_input,>input_num_comma
    ELSE
    	DC.B	$0,$ff,>left_paren,>comma_substr,>goto_stmt,>Te816,>string_input,>input_num_comma
    ENDIF
	DC.B	$ff,$ff,>paren_substr,$ff,$ff,>num_array_subs,>peek_fn,>rnd_fn
	DC.B	>sgn_fn,>abs_fn,$00,$ff,>left_paren,>unary_pos,>negate,>not_op
	DC.B	>left_paren,>string_eq,>string_neq,>len_fn,>bogus_eec2,>Teeae,>Teeba,>left_paren
	DC.B	$ff,$ff,>str_arr_dest,>dim_str,>dim_num,>print_str,>print_num,>print_semi
 	DC.B	>print_str_comma,>print_com_num,$ff,$ff,$ff,>call_stmt,>dim_str,>dim_num
	DC.B	>tab_fn,>end_stmt,>string_input,>input_prompt,>input_num_stmt,>for_stmt,>var_assign,>to_clause  
	DC.B	>Te97e,>next_stmt,>next_stmt,>return_stmt,>gosub_stmt,$ff,>Te816,>goto_stmt  
	DC.B	>if_stmt,>print_str,>print_num,>print_cr,>poke_stmt,>Tef0c,>Tee4e,>poke_stmt     
	DC.B	>plot_comma,>poke_stmt,>bogus_eea6,>Teeb0,>poke_stmt,>Teebc,>Teec6,>vtab_stmt
	DC.B	>string_lit,>var_assign,>right_paren,$ff,$ff,$ff,$ff,$ff 
error_msg_tbl:	DC.B	$be,$b3,$b2,$b7,$b6,$37,$d4,$cf	; ">32767TO"
           	DC.B	$cf,$a0,$cc,$cf,$ce,$47,$d3,$d9	; "O LONGSY"
           	DC.B	$ce,$d4,$c1,$58,$cd,$c5,$cd,$a0	; "NTAXMEM "
           	DC.B	$c6,$d5,$cc,$4c,$d4,$cf,$cf,$a0	; "FULLTOO "
           	DC.B	$cd,$c1,$ce,$d9,$a0,$d0,$c1,$d2	; "MANY PAR"
          	DC.B	$c5,$ce,$53,$d3,$d4,$d2,$c9,$ce	; "ENSSTRIN"
          	DC.B	$47,$ce,$cf,$a0,$c5,$ce,$44,$c2	; "GNO ENDB"
         	DC.B	$c1,$c4,$a0,$c2,$d2,$c1,$ce,$c3	; "AD BRANC"
          	DC.B	$48,$be,$b8,$a0,$c7,$cf,$d3,$d5	; "H>8 GOSU"
          	DC.B	$c2,$53,$c2,$c1,$c4,$a0,$d2,$c5	; "BSBAD RE"
         	DC.B	$d4,$d5,$d2,$4e,$be,$b8,$a0,$c6	; "TURN>8 F"
          	DC.B	$cf,$d2,$53,$c2,$c1,$c4,$a0,$ce	; "ORSBAD N"
          	DC.B	$c5,$d8,$54,$d3,$d4,$cf,$d0,$d0	; "EXTSTOPP"
      	DC.B	$c5,$c4,$a0,$c1,$d4,$20,$aa,$aa	; "ED AT **"
          	DC.B	$aa,$20,$a0,$c5,$d2,$d2,$0d,$be	; "*  ERR.>"
          	DC.B	$b2,$b5,$35,$d2,$c1,$ce,$c7,$45	; "255RANGE"
          	DC.B	$c4,$c9,$4d,$d3,$d4,$d2,$a0,$cf	; "DIMSTR O"
          	DC.B	$d6,$c6,$4c,$dc,$0d,$d2,$c5,$d4	; "VFL\.RET"
           	DC.B	$d9,$d0,$c5,$a0,$cc,$c9,$ce,$c5	; "YPE LINE"
           	DC.B	$8d,$3f                  	; ".?"
Leb9a:	LSR	run_flag
	      BCC	Leba1
	  	JMP	Le8c3
Leba1:	LDX	acc+1
	    	TXS
	   	LDX	acc
	  	LDY	#$8d	; 141 .
	   	BNE	Lebac

input_num_stmt:	LDY	#$99	; 153 .
Lebac:	JSR	Se3c4
	    	STX	acc
	   	TSX
	    	STX	acc+1
	    	LDY	#$fe	; 254 ~
	   	STY	run_flag
	    	INY
	   	STY	text_index
	   	JSR	Se299
	   	STY	token_index
	   	LDX	#$20	; 32  
	   	LDA	#$30	; 48 0
	   	JSR	Se491
	   	INC	run_flag
	   	LDX	acc

input_num_comma:	LDY	text_index
	   	ASL
Lebce:	STA	acc
	   	INY
	   	LDA	buffer,Y
	    	CMP	#$74	; 116 t
	    	BEQ	input_num_stmt
	    	EOR	#$b0	; 176 0
	   	CMP	#$0a	; 10 .
	   	BCS	Lebce
	    	INY
	   	INY
	    	STY	text_index
	   	LDA	buffer,Y
	   	PHA
	   	LDA	buffer-1,Y
	   	LDY	#$00	; 0 .
	  	JSR	push_ya_noun_stk
	    	PLA
	    	STA	noun_stk_h_int,X
	   	LDA	acc
	   	CMP	#$c7	; 199 G
	   	BNE	Lebfa
	  	JSR	negate
Lebfa:	JMP	var_assign
	    	DC.B	$ff,$ff,$ff,$50            	; "...P"

Tec01:	JSR	Tec13
	   	BNE	Lec1b

Tec06:	JSR	Tec0b
	    	BNE	Lec1b

Tec0b:	JSR	subtract
	   	JSR	negate
	   	BVC	Lec16

Tec13:	JSR	subtract
Lec16:	JSR	sgn_fn
	   	LSR	noun_stk_l,X
Lec1b:	JMP	not_op
	    	DC.B	$ff,$ff                  	; ".."
syntabl_index:	DC.B	$c1,$ff,$7f,$d1,$cc,$c7,$cf,$ce	; "A..QLGON"
	   	DC.B	$c5,$9a,$98,$8b,$96,$95,$93,$bf	; "E......?"
	    	DC.B	$b2,$32,$2d,$2b,$bc,$b0,$ac,$be	; "22-+<0,>"
	   	DC.B	$35,$8e,$61,$ff,$ff,$ff,$dd,$fb	; "5.a...]{"

Tec40:		JSR	Sefc9
	   	ORA	rnd+1,X
	   	BPL	Lec4c

Tec47:	JSR	Sefc9
	  	AND	rnd+1,X
Lec4c:	STA	noun_stk_l,X
	   	BPL	Lec1b
	  	JMP	Sefc9
	    	DC.B	$40,$60,$8d,$60,$8b,$00,$7e,$8c	; "@`.`..~."
      	DC.B	$33,$00,$00,$60,$03,$bf,$12,$00	; "3..`.?.."
	  	DC.B	$40,$89,$c9,$47,$9d,$17,$68,$9d	; "@.IG..h."
	  	DC.B	$0a,$00,$40,$60,$8d,$60,$8b,$00	; "..@`.`.."
	   	DC.B	$7e,$8c,$3c,$00,$00,$60,$03,$bf	; "~.<..`.?"
	   	DC.B	$1b,$4b,$67,$b4,$a1,$07,$8c,$07	; ".Kg4!..."
	   	DC.B	$ae,$a9,$ac,$a8,$67,$8c,$07,$b4	; ".),(g..4"
	   	DC.B	$af,$ac,$b0,$67,$9d,$b2,$af,$ac	; "/,0g.2/,"
	  	DC.B	$af,$a3,$67,$8c,$07,$a5,$ab,$af	; "/#g..%+/"
	   	DC.B	$b0,$f4,$ae,$a9,$b2,$b0,$7f,$0e	; "0t.)20.."
	   	DC.B	$27,$b4,$ae,$a9,$b2,$b0,$7f,$0e	; "'4.)20.."
	  	DC.B	$28,$b4,$ae,$a9,$b2,$b0,$64,$07	; "(4.)20d."
	   	DC.B	$a6,$a9,$67,$af,$b4,$af,$a7,$78	; "&)g/4/'x"
	   	DC.B	$b4,$a5,$ac,$78,$7f,$02,$ad,$a5	; "4%,x..-%"
	  	DC.B	$b2,$67,$a2,$b5,$b3,$af,$a7,$ee	; "2g"53/'n"
	   	DC.B	$b2,$b5,$b4,$a5,$b2,$7e,$8c,$39	; "254%2~.9"
	  	DC.B	$b4,$b8,$a5,$ae,$67,$b0,$a5,$b4	; "48%.g0%4"
	  	DC.B	$b3,$27,$af,$b4,$07,$9d,$19,$b2	; "3'/4...2"
	  	DC.B	$af,$a6,$7f,$05,$37,$b4,$b5,$b0	; "/&..7450"
	   	DC.B	$ae,$a9,$7f,$05,$28,$b4,$b5,$b0	; ".)..(450"
	   	DC.B	$ae,$a9,$7f,$05,$2a,$b4,$b5,$b0	; ".)..*450"
	   	DC.B	$ae,$a9,$e4,$ae,$a5,$00,$ff,$ff	; ".)d.%..."
syntabl2:	DC.B	$47,$a2,$a1,$b4,$7f,$0d,$30,$ad	; "G"!4..0-"
	   	DC.B	$a9,$a4,$7f,$0d,$23,$ad,$a9,$a4	; ")$..#-)$"
	   	DC.B	$67,$ac,$ac,$a1,$a3,$00,$40,$80	; "g,,!#.@."
	  	DC.B	$c0,$c1,$80,$00,$47,$8c,$68,$8c	; "@A..G.h."
	  	DC.B	$db,$67,$9b,$68,$9b,$50,$8c,$63	; "[g.h.P.c"
	   	DC.B	$8c,$7f,$01,$51,$07,$88,$29,$84	; "...Q..)."
	   	DC.B	$80,$c4,$80,$57,$71,$07,$88,$14	; ".D.Wq..."
	  	DC.B	$ed,$a5,$ad,$af,$ac,$ed,$a5,$ad	; "m%-/,m%-"
	  	DC.B	$a9,$a8,$f2,$af,$ac,$af,$a3,$71	; ")(r/,/#q"
	  	DC.B	$08,$88,$ae,$a5,$ac,$68,$83,$08	; "...%,h.."
	   	DC.B	$68,$9d,$08,$71,$07,$88,$60,$76	; "h..q..`v"
	  	DC.B	$b4,$af,$ae,$76,$8d,$76,$8b,$51	; "4/.v.v.Q"
	   	DC.B	$07,$88,$19,$b8,$a4,$ae,$b2,$f2	; "...8$.2r"
	   	DC.B	$b3,$b5,$f3,$a2,$a1,$ee,$a7,$b3	; "35s"!n'3"
	  	DC.B	$e4,$ae,$b2,$eb,$a5,$a5,$b0,$51	; "d.2k%%0Q"
	    	DC.B	$07,$88,$39,$81,$c1,$4f,$7f,$0f	; "..9.AO.."
	   	DC.B	$2f,$00,$51,$06,$88,$29,$c2,$0c	; "/.Q..)B."
	  	DC.B	$82,$57,$8c,$6a,$8c,$42,$ae,$a5	; ".W.j.B.%"
	  	DC.B	$a8,$b4,$60,$ae,$a5,$a8,$b4,$4f	; "(4`.%(4O"
	  	DC.B	$7e,$1e,$35,$8c,$27,$51,$07,$88	; "~.5.'Q.."
	   	DC.B	$09,$8b,$fe,$e4,$af,$ad,$f2,$af	; "..~d/-r/"
	   	DC.B	$e4,$ae,$a1,$dc,$de,$9c,$dd,$9c	; "d.!\^.]."
	   	DC.B	$de,$dd,$9e,$c3,$dd,$cf,$ca,$cd	; "^].C]OJM"
	  	DC.B	$cb,$00,$47,$9d,$ad,$a5,$ad,$af	; "K.G.-%-/"
	   	DC.B	$ac,$76,$9d,$ad,$a5,$ad,$a9,$a8	; ",v.-%-)("
	   	DC.B	$e6,$a6,$af,$60,$8c,$20,$af,$b4	; "f&/`. /4"
	   	DC.B	$b5,$a1,$f2,$ac,$a3,$f2,$a3,$b3	; "5!r,#r#3"
	  	DC.B	$60,$8c,$20,$ac,$a5,$a4,$ee,$b5	; "`. ,%$n5"
	   	DC.B	$b2,$60,$ae,$b5,$b2,$f4,$b3,$a9	; "2`.52t3)"
	   	DC.B	$ac,$60,$8c,$20,$b4,$b3,$a9,$ac	; ",`. 43),"
	   	DC.B	$7a,$7e,$9a,$22,$20,$00,$60,$03	; "z~." .`."
	   	DC.B	$bf,$60,$03,$bf,$1f         	; "?`.?."

print_str_comma:	JSR	tabout

print_str:	INX
	   	INX
	   	LDA	rnd+1,X
	  	STA	aux
	   	LDA	syn_stk_h+31,X
	  	STA	aux+1
	  	LDY	rnd,X
Lee0f:	TYA
	   	CMP	syn_stk_h+30,X
	   	BCS	Lee1d
	   	LDA	(aux),Y
	  	JSR	cout
	   	INY
	  	JMP	Lee0f
Lee1d:	LDA	#$ff	; 255 .
	   	STA	cr_flag
	   	RTS

len_fn:	INX
	   	LDA	#$00	; 0 .
	  	STA	noun_stk_h_str,X
	   	STA	noun_stk_h_int,X
	  	LDA	syn_stk_h+31,X
	    	SEC
	   	SBC	rnd+1,X
	    	STA	noun_stk_l,X
	   	JMP	left_paren
	    	DC.B	$ff                     	; "."

getbyte:	JSR	get16bit
   		LDA	acc+1
  		BNE	gr_255_err
	   	LDA	acc
Tee3d
	     	RTS
plot_comma:
    IFCONST	HUSTNBASIC
            JSR	push_ya_noun_stk
            STY	$a0,X
Tee43
            LDA	$D0
            BNE	Tee4b
            DEC	$D1
            BMI	Tee3d
Tee4b
            DEC	$D0
;            LDA	$D2
            DC.b	$a5
Tee4e:				;MJW wrong address, so we have to break this instruction
            DC.b	$d2

            LDY	#$00
            JSR	push_ya_noun_stk
man_cmd
            LDA	$D3
;            STA	$A0,X
            DC.b	$95
vtab_stmt:
            DC.b	$a0
            JSR	mult_op
            JMP Tee43
    ELSE

                JSR	getbyte
	 	LDY	text_index
	   	CMP	#$30	; 48 0
	  	BCS	range_err
	  	CPY	#$28	; 40 (
	   	BCS	range_err
	    	RTS
		NOP
		NOP


Tee4e:	JSR	getbyte
	    	RTS
        ENDIF
;
	IFCONST SNDERBASIC	;WSANDER BASIC HERE
		NOP
		NOP

man_cmd:	LSR	auto_flag
	   	RTS

vtab_stmt:	JSR	getbyte
	   	CMP	#$18	; 24 .
	   	BCS	range_err
	    	STA	cv
	    	RTS
		NOP
		NOP
	ELSE			;OTHER BASIC
            IFNCONST	HUSTNBASIC   ; omit next 12 bytes if Hustn basic	
	nop
Lee53
	txa
man_cmd:
	ldx	#$1
Lee56
;	ldy	acc,x
        DC.b	$B4
vtab_stmt:			;wrong address MJW
        DC.b	acc

	sty	himem,x
	ldy	zp48,x
	sty	pp,x
            
	dex
                IFCONST BRIELBASIC	;BRIEL BASIC HERE
	beq	Lee56
                ELSE
        beq	man_cmd
                ENDIF
	tax
	rts
            ELSE		;HUSTNBASIC
            STA	cv
            RTS
            NOP
            NOP
            ENDIF
        ENDIF
gr_255_err:	LDY	#$77	; 119 w
go_errmess_5:	JMP	print_err_msg
range_err:	LDY	#$7b	; 123 {
	   	BNE	go_errmess_5

See6c:	JSR	Se254
	   	LDA	aux
	   	BNE	Lee7a
	    	LDA	aux+1
	   	BNE	Lee7a
	   	JMP	Le77e
Lee7a:	ASL	acc
	   	ROL	acc+1
	    	ROL	p3
	     	ROL	p3+1
	     	LDA	p3
	     	CMP	aux
	     	LDA	p3+1
	     	SBC	aux+1
	    	BCC	Lee96
      	STA	p3+1
	    	LDA	p3
	    	SBC	aux
	     	STA	p3
	     	INC	acc
Lee96:	DEY
	    	BNE	Lee7a
	   	RTS
	   	DC.B	$ff,$ff,$ff,$ff,$ff,$ff      	; "......"

call_stmt:	JSR	get16bit
	 	JMP	(acc)
                IFCONST BRIELBASIC		;BRIEL BASIC
bogus_eea6:
	LDA	himem
	BNE	Leeac
	dec	zp4d
Leeac:
	dec	himem
Teeae:
	lda	zp48
Teeb0:
	bne	Leeb4
	dec	zp49
Leeb4:
	dec	zp48
Leeb6:
	ldy	#$00
	lda	(himem),y
Teeba:
	sta	(zp48),y
Teebc:
	lda	pp
	cmp	himem
	lda	zpcb
bogus_eec2:
	sbc	zp4d
	bcc	bogus_eea6
Teec6:	jmp	Lee53



	ELSE			;SANDER/HUSTON (NOT BREIL) BASIC HERE


bogus_eea6:		;DC.B	$20,$34,$ee,$c5,$c8,$90,$bb,$85	; " 4nEH.;."
            IFCONST SNDERBASIC	;WSANDER BASIC HERE
		JSR	getbyte
		CMP	text_index
		BCC	range_err
;		sta	LOCZERO
                DC.b	$85

Teeae:	LDA	himem+1

Teeb0:	PHA
		LDA	himem
	  	JSR	push_ya_noun_stk
Leeb6
	   	PLA
	  	STA	noun_stk_h_int,X
	   	RTS

Teeba:	LDA	lomem+1

Teebc:	PHA
	  	LDA	lomem
	 	JMP	Lefb3
bogus_eec2:
		LDA	zp85
		DC.b	$2D,$60
Teec6:	JSR	getbyte
            ELSE		;HUSTON BASIC HERE
                JSR	get16bit
                LDA	zpcf
                BPL	Leeb5
                TYA
Teeae
                DEX
;                JSR	push_ya_noun_stk
                DC.b	$20
Teeb0
                DC.b	$08,$e7

                STY	noun_stk_h_int,x
                rts
Leeb5
;                STA	tokndxstk
                DC.b	$85
Leeb6
                DC.b	$d1
                
                LDA	acc
;                STA	srch
                DC.b	$85
Teeba
                DC.b	$d0

;                JSR	get16bit
                DC.b	$20
Teebc
                DC.b	$15, $e7

                LDA	acc
                STA	srch2
bogus_eec2:
                LDA	zpcf
                STA	$d3
Teec6
                LDA	#$01
                JMP	plot_comma
            ENDIF
	ENDIF	
            IFNCONST	HUSTNBASIC   ; omit next 2 bytes if Hustn basic
	   	CMP	#$28	; 40 (
            ENDIF
Leecb:	BCS	range_err
	   	TAY
	    	LDA	text_index
	    	RTS
	NOP
	NOP

print_err_msg2:	TYA
	  	TAX
	   	LDY	#$6e	; 110 n
	  	JSR	Se3c4
	   	TXA
	   	TAY
	 	JSR	Se3c4
	   	LDY	#$72	; 114 r
	  	JMP	Se3c4

Seee4:	JSR	get16bit
Leee7:	ASL	acc
	    	ROL	acc+1
	   	BMI	Leee7
	   	BCS	Leecb
	   	BNE	Leef5
	   	CMP	acc
	   	BCS	Leecb
Leef5:	RTS

peek_fn:
        IFCONST BLD4APPLE1
        	JSR	get16bit
        ELSE
                JMP	A2PEEK
        ENDIF
	    	LDA	(acc),Y
	   	STY	syn_stk_l+31,X
	   	JMP	push_ya_noun_stk

poke_stmt:
        IFCONST BLD4APPLE1
                JSR	getbyte
        ELSE
                JMP	A2POKE
        ENDIF
	  	LDA	acc
	  	PHA
	  	JSR	get16bit
	   	PLA
	   	STA	(acc),Y

Tef0c:	RTS
	  	DC.B	$ff,$ff,$ff               	; "..."

divide:	JSR	See6c
	   	LDA	acc
	   	STA	p3
	   	LDA	acc+1
	   	STA	p3+1
	   	JMP	Le244

dim_num:	JSR	Seee4
		JMP	Le134

num_array_subs:	JSR	Seee4
	   	LDY	noun_stk_h_str,X
	    	LDA	noun_stk_l,X
	   	ADC	#$fe	; 254 ~
	    	BCS	Lef30
	    	DEY
Lef30:	STA	aux
	   	STY	aux+1
	    	CLC
	    	ADC	acc
	     	STA	noun_stk_l,X
	   	TYA
	    	ADC	acc+1
	    	STA	noun_stk_h_str,X
	   	LDY	#$00	; 0 .
	   	LDA	noun_stk_l,X
	   	CMP	(aux),Y
	   	INY
	   	LDA	noun_stk_h_str,X
	   	SBC	(aux),Y
	  	BCS	Leecb
	  	JMP	left_paren

rnd_fn:	JSR	get16bit
	 	LDA	rnd
	   	JSR	push_ya_noun_stk
	    	LDA	rnd+1
	   	BNE	Lef5e
	   	CMP	rnd
	    	ADC	#$00	; 0 .
Lef5e:	AND	#$7f	; 127 .
	   	STA	rnd+1
	   	STA	noun_stk_h_int,X
	   	LDY	#$11	; 17 .
Lef66:	LDA	rnd+1
	   	ASL
	    	CLC
	    	ADC	#$40	; 64 @
	   	ASL
	   	ROL	rnd
	  	ROL	rnd+1
	   	DEY
	   	BNE	Lef66
	   	LDA	acc
	  	JSR	push_ya_noun_stk
	   	LDA	acc+1
	    	STA	noun_stk_h_int,X
	  	JMP	mod_op

Tef80:	JSR	get16bit
	   	LDY	acc
	IFCONST SNDERBASIC	;SANDER BASIC HERE
	  	CPY	lomem
	   	LDA	acc+1
	   	SBC	lomem+1
	   	BCC	Lefab_efad
	   	STY	himem
	   	LDA	acc+1
	   	STA	himem+1
Lef93:	JMP	new_cmd

Tef96:	JSR	get16bit
	  	LDY	acc
	  	CPY	himem
	   	LDA	acc+1
	   	SBC	himem+1	
	    	BCS	Lefab_efad
	    	STY	lomem
	    	LDA	acc+1
	   	STA	lomem+1
	   	BCC	Lef93
Lefab_efad:	JMP	Leecb
	    	;DC.B	;$a5,$4d,$48,$a5,$4c         	; "%MH%L" 
		lda	zp4d
		pha
		lda	himem
	ELSE
            IFCONST	HUSTNBASIC
                CPY	lomem
                LDA	zpcf
                SBC	zp4b
                BCC	Lefab
                STY	himem
                LDA	zpcf
                STA	zp4d
Lef93
                JMP	new_cmd
Tef96
                JSR	get16bit
                LDY	acc
                CPY	himem
                LDA	zpcf
                SBC	zp4d
                BCS	Lefab
                STY	lomem
                LDA	zpcf
                sta	zp4b
                bcc	Lef93
Lefab
                JMP	Leecb
                LDA	zp4d
                PHA	
                LDA	himem	
            ELSE
	cpy	himem
	lda	zpcf
	sbc	zp4d
	bcc	Lefac
	sty	zp48
	lda	zpcf
	sta	zp49
	jmp	Leeb6
Tef96:
	jsr	get16bit
	ldy	acc
	cpy	pp
	lda	zpcf
	sbc	zpcb
	bcs	Lefac
	sty	lomem
	lda	zpcf
	sta	zp4b
	jmp	clr
Lefac
	jmp	Leecb

Lefab_efad:
	nop
	nop
	nop
	nop
            ENDIF
	ENDIF
Lefb3:	JSR	Sefc9

string_input:	JSR	input_str
		JMP	Lefbf

input_prompt:	JSR	print_str
Lefbf:	LDA	#$ff	; 255 .
	     	STA	text_index
	    	LDA	#$74	; 116 t
	  	STA	buffer
	    	RTS

Sefc9:	JSR	not_op
	   	INX

Sefcd:	JSR	not_op
	  	LDA	noun_stk_l,X
	   	RTS

mem_init_4k:	LDA	#$00	; 0 .
	   	STA	lomem
	   	STA	himem
	   	LDA	#$08	; 8 .
	   	STA	lomem+1
	   	LDA	#$10	; 16 .
	   	STA	himem+1
	 	JMP	new_cmd

Sefe4:	CMP	noun_stk_h_str,X
	    	BNE	Lefe9
	   	CLC
Lefe9:	JMP	Le102

Tefec:	JSR	clr
		JMP	run_warm

Teff2:	JSR	clr
		JMP	goto_stmt

Seff8:	CPX	#$80	; 128 .
		BNE	Leffd
		DEY
Leffd:	JMP	Se00c




