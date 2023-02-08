	PROCESSOR 6502
	LIST	ON
;
;-----------------------------------------------------------------------;
; The Wozanium Pack                                                     ;
; This file is part one of the Wozanium Pack.			        ;
; Apple 1 basic is the other part					;
;-----------------------------------------------------------------------;
;	Copyright 2010,2011 Mike Willegal                            	
;	A1 monitor and A1 apple cassette interface derived from
;	original Apple 1 implemenations by Steve Wozniak
;
;    The Wozanium Pack is free software: 
;    you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    The Wozanium Pack is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with the Wozanium Pack.  If not, see <http://www.gnu.org/licenses/>.
;
;-----------------------------------------------------------------------; 
;-------------------------------------------------------------------------
; Defines - this code can be built one of four ways
;	1. clone/real Apple 1 HW
;	2. runs in ram of real or virtual Apple 2
;	3. runs in virtual apple 2 as ROM
;	4. runs in plug in board of real Apple 2
;
;	select one of these three options
;-------------------------------------------------------------------------
; Build with dasm 6502 assembler and the following command line
;dasm a2a1emulv5_1.asm -DBLD4ROMBD=0 -DHUSTNBASIC=0 -oa2a1rbh.o -la2a1rbh.lst
;

;BLD4APPLE1		EQU	0	;ACTUAL APPLE 1 or CLONE
;BLD4RAM 		EQU	0	;RAM of virtual or real A2
;BLD4EMULROM 	EQU 	0	;ROM of virtual A2
;BLD4ROMBD		EQU 	0	;ROM board in Real A2

;-------------------------------------------------------------------------
;  Constants
;-------------------------------------------------------------------------

BS              EQU     $DF             ;Backspace key, arrow left key
CR              EQU     $8D             ;Carriage Return
ESC             EQU     $9B             ;ESC key
PROMPT          EQU     "\"             ;Prompt character

;-------------------------------------------------------------------------
; scratchpad memory - uses last 1k of apple ii 48k
;-------------------------------------------------------------------------
	MAC STORAGE
TURBO	DS.b	1	; any bit non-zero is turbo mode
TURBOUSR	EQU $01	; USER TURBO MODE
TURBOCMP	EQU $02	; COMPUTER DRIVEN TURBO MODE

RDCONVERT DS.b	1
READVECTOR DS.w 1	;allows user override of default keyboard read function
WRITVECTOR DS.w 1	;allows user override of default video out function

savey	DS.b	1
savex	DS.b	1
POWERUPINIT DS.b	1
SCRNCLRD DS.b	1
CHAR	DS.b	1
TMP1	DS.b	1
CURROW	DS.b	1
CURCOL	DS.b	1
COUNTER0 DS.b	1
COUNTER1 DS.b	1
CURSOR  DS.b	1
RDSTRTL	DS.b	1
RDSTRTH	DS.b	1
HEX2LB          DS.b	1             ;Begin address of dump block
HEX2HB          DS.b	1

;;; zero page back up so graphics routines can use them
TMPG0	DS.b	16
PG0SAVD DS.b	1
	ENDM
	IFNCONST BLD4APPLE1
		IFNCONST BLD4RAM
			ORG	$bc00
			STORAGE
		ENDIF
	ENDIF






;-------------------------------------------------------------------------
;  Memory declaration
;-------------------------------------------------------------------------


HEX1L           EQU     $24     	    ;End address of dump block
HEX1H           EQU     $25
HEX2L           EQU     $26             ;Begin address of dump block
HEX2H           EQU     $27

SAVEINDEX       EQU     $28             ;Save index in input buffer
LASTSTATE       EQU     $29             ;Last input state

IN              EQU     $0200	     	    ;Input buffer
	IFCONST	BLD4APPLE1
FLIP            EQU     $C000           ;Output flip-flop
TAPEIN          EQU     $C081           ;Tape input
KBD             EQU     $D010           ;PIA.A keyboard input
KBDCR           EQU     $D011           ;PIA.A keyboard control register
	ELSE
FLIP            EQU     $C020           ;Output flip-flop
TAPEIN          EQU     $C060           ;Tape input
KBD             EQU     $C000           ;keyboard input
KBDCR           EQU     $C010           ;keybaord strobe clear
	ENDIF

;-------------------------------------------------------------------------
;  Constants
;-------------------------------------------------------------------------

CR              EQU     $8D             ;Carriage Return
ESC             EQU     $9B             ;ASCII ESC
CNTSTRT		EQU	$E0

;---------------------------------------------------------------------------
; build in ACI Driver
;---------------------------------------------------------------------------
	IFCONST	BLD4EMULROM
		ORG $D000		; EMULATOR ROM image
	ELSE
		IFCONST	BLD4RAM 
                	ORG $6000	; build for memory
		ELSE
			ORG $C100	; real apple 1 or plug in ROM board for A2
		ENDIF
	ENDIF

;-------------------------------------------------------------------------
;
;  The WOZ Apple Cassette Interface for the Apple 1
;  Written by Steve Wozniak somewhere around 1976
;
;-------------------------------------------------------------------------
WOZACI

	        LDA     #$aa            ;Print the Tape prompt
	IFNCONST	BLD4APPLE1
		JMP	A2ACIDRIVER	;If not actual Apple 1, use A2 driver
	ELSE
                JSR     ECHO
 	ENDIF
               	LDA     #CR             ;And drop the cursor one line
                JSR     ECHO

                LDY     #-1             ;Reset the input buffer index
ACINEXTCHAR     INY

		
ACIWAITCHAR	LDA     KBDCR	        ;Wait for key press
                BPL     ACIWAITCHAR     ;No key yet!
                LDA     KBD           ;Clear strobe
                STA     IN,Y            ;Save it into buffer
                JSR     ECHO            ;And type it on the screen
                CMP     #ESC
                BEQ     WOZACI          ;Start from scratch if ESC!
                CMP     #CR
                BNE     ACINEXTCHAR     ;Read keys until CR

                LDX     #-1             ;Initialize parse buffer pointer

;-------------------------------------------------------------------------
; Start parsing first or a new tape command
;-------------------------------------------------------------------------

NEXTCMD         LDA     #0              ;Clear begin and end values
                STA     HEX1L
                STA     HEX1H
                STA     HEX2L
                STA     HEX2H

NEXTCHR         INX                     ;Increment input pointer
                LDA     IN,X            ;Get next char from input line
                CMP     #$d2            ;Read command?
                BEQ     READ            ;Yes!
                CMP     #$d7            ;Write command?
                BEQ     WRITE           ;Yes! (note: CY=1)
                CMP     #$ae            ;Separator?
                BEQ     SEP             ;Yes!
                CMP     #CR             ;End of line?
                BEQ     GOESC           ;Escape to monitor! We're done
                CMP     #$a0            ;Ignore spaces
                BEQ     NEXTCHR
                EOR     #$b0            ;Map digits to 0-9
                CMP     #9+1            ;Is it a decimal digit?
                BCC     ACIDIG             ;Yes!
                ADC     #$88            ;Map letter "A"-"F" to $FA-$FF
                CMP     #$FA            ;Hex letter?
                BCC     WOZACI          ;No! Character not hex!

ACIDIG          ASL                     ;Hex digit to MSD of A
                ASL
                ASL
                ASL

                LDY     #4              ;Shift count
ACIHEXSHIFT     ASL                     ;Hex digit left, MSB to carry
                ROL     HEX1L           ;Rotate into LSD
                ROL     HEX1H           ;Rotate into MSD
                DEY                     ;Done 4 shifts?
                BNE     ACIHEXSHIFT     ;No! Loop
                BEQ     NEXTCHR         ;Handle next character

;-------------------------------------------------------------------------
; Return to monitor, prints \ first
;-------------------------------------------------------------------------

GOESC           JMP     ESCAPE          ;Escape back to monitor

;-------------------------------------------------------------------------
; Separating . found. Copy HEX1 to Hex2. Doesn't clear HEX1!!!
;-------------------------------------------------------------------------

SEP             LDA     HEX1L           ;Copy hex value 1 to hex value 2
                STA     HEX2L
                LDA     HEX1H
                STA     HEX2H
                BCS     NEXTCHR         ;Always taken!

;-------------------------------------------------------------------------
; Write a block of memory to tape
;-------------------------------------------------------------------------

WRITE
           	LDA     #64             ;Write 10 second header
                JSR     WHEADER
WRNEXT          DEY                     ;Compensate timing for extra work
                LDX     #0              ;Get next byte to write
                LDA     (HEX2L,X)

                LDX     #8*2            ;Shift 8 bits (decremented twice)
WBITLOOP        ASL                     ;Shift MSB to carry
                JSR     WRITEBIT        ;Write this bit
                BNE     WBITLOOP        ;Do all 8 bits!

                JSR     INCADDR         ;Increment address
                LDY     #30             ;Compensate timer for extra work
                BCC     WRNEXT          ;Not done yet! Write next byte

RESTIDX  
	       LDX     SAVEINDEX       ;Restore index in input line
               BCS     NEXTCMD         ;Always taken!

;-------------------------------------------------------------------------
; For case when ACI must fit in c100-c1ff - the read function must be moved
; because the standard read doesn't fit with the extra mask instruction
; required for the Apple II hardware
;-------------------------------------------------------------------------

READ:	
		JSR	FULLCYCLE	;Wait until full cycle is detected
                LDA     #22             ;Introduce some delay to allow
                JSR     WHEADER        	; the tape speed to stabilize
              	JSR     FULLCYCLE       ;Synchronize with full cycle
NOTSTART 
       		LDY     #31             ;Try to detect the much shorter
                JSR     CMPLEVEL        ;  start bit
               	BCS     NOTSTART        ;Start bit not detected yet!
                JSR     CMPLEVEL        ;Wait for 2nd phase of start bit

                LDY     #58             ;Set threshold value in middle
RDBYTE          LDX     #8              ;Receiver 8 bits
RDBIT           PHA
                JSR     FULLCYCLE       ;Detect a full cycle
                PLA
                ROL                     ;Roll new bit into result
                LDY     #57             ;Set threshold value in middle
                DEX                     ;Decrement bit counter
                BNE     RDBIT           ;Read next bit!
                STA     (HEX2L,X)       ;Save new byte

                JSR     INCADDR         ;Increment address
                LDY     #53             ;Compensate threshold with workload
                BCC     RDBYTE          ;Do next byte if not done yet!
                BCS     RESTIDX         ;Always taken! Restore parse index

FULLCYCLE       JSR     CMPLEVEL        ;Wait for two level changes
CMPLEVEL        DEY                     ;Decrement time counter
                LDA     TAPEIN          ;Get Tape In data

;-------------------------------------------------------------------------
; the next instruction must be added for apple II
; since it doesn't fit in the 256 bytes allowed in the
; original PROM, a substitute A2 read function is called instead
; (READ_APPLE2_VERSION)which is located in a different bank
;
;		AND	#$80		;CLEAR floating bits
;-------------------------------------------------------------------------
                CMP     LASTSTATE       ;Same as before?
                BEQ     CMPLEVEL        ;Yes!
                STA     LASTSTATE       ;Save new data

                CPY     #128            ;Compare threshold
                RTS
;-------------------------------------------------------------------------
; Write header to tape
;
; The header consists of an asymmetric cycle, starting with one phase of
; approximately (66+47)x5=565us, followed by a second phase of
; approximately (44+47)x5=455us.
; Total cycle duration is approximately 1020us ~ 1kHz. The actual
; frequencywill be a bit lower because of the additional workload between
; the twoloops.
; The header ends with a short phase of (30+47)x5=385us and a normal
; phase of (44+47)x5=455us. This start bit must be detected by the read
; routine to trigger the reading of the actual data.
;-------------------------------------------------------------------------

WHEADER         STX     SAVEINDEX       ;Save index in input line
HCOUNT          LDY     #66             ;Extra long delay
                JSR     WDELAY          ;CY is constantly 1, writing a 1
                BNE     HCOUNT          ;Do this 64 * 256 time!
                ADC     #-2             ;Decrement A (CY=1 all the time)
                BCS     HCOUNT          ;Not all done!
                LDY     #30             ;Write a final short bit (start)

;-------------------------------------------------------------------------
; Write a full bit cycle
;
; Upon entry Y contains a compensated value for the first phase of 0
; bit length. All subsequent loops don't have to be time compensated.
;-------------------------------------------------------------------------

WRITEBIT        JSR     WDELAY          ;Do two equal phases
                LDY     #44             ;Load 250us counter - compensation

WDELAY          DEY                     ;Delay 250us (one phase of 2kHz)
                BNE     WDELAY
                BCC     WRITE1          ;Write a '1' (2kHz)

                LDY     #47             ;Additional delay for '0' (1kHz)
WDELAY0         DEY                     ; (delay 250us)
                BNE     WDELAY0

WRITE1
		LDY     FLIP,X          ;Flip the output bit
                LDY     #41             ;Reload 250us cntr (compensation)
                DEX                     ;Decrement bit counter
                RTS

;-------------------------------------------------------------------------
; Increment current address and compare with last address
;-------------------------------------------------------------------------
INCADDR         LDA     HEX2L           ;Compare current address with
                CMP     HEX1L           ; end address
                LDA     HEX2H
                SBC     HEX1H
                INC     HEX2L           ;And increment current address
                BNE     NOCARRY         ;No carry to MSB!
                INC     HEX2H
NOCARRY         RTS


;---------------------------------------------------------------------------
; all the following code is needed for the A2 version
; skip to Basic for the real thing 
;---------------------------------------------------------------------------
	IFNCONST BLD4APPLE1
;---------------------------------------------------------------------------
; build in an A2 ACI driver for ROM version
; if using an A2, the version at C100 jumps to this version
; and this version is at D000 (so slots 0 & 2-7 can be used)
;---------------------------------------------------------------------------
	IFNCONST	BLD4EMULROM
		IFNCONST	BLD4RAM
			ORG $D000		; A2 ROM  or image
		ENDIF
	ENDIF

;-------------------------------------------------------------------------
;  ACI DRIVER
;-------------------------------------------------------------------------
A2ACIDRIVER
	        LDA     #$aa            ;Print the Tape prompt
                JSR     ECHO
                LDA     #CR             ;And drop the cursor one line
                JSR     ECHO

                LDY     #-1             ;Reset the input buffer index
RB_ACINEXTCHAR     
		INY

		JSR	A2GETCHAR

                STA     IN,Y            ;Save it into buffer
                JSR     ECHO            ;And type it on the screen
                CMP     #ESC
                BEQ     A2ACIDRIVER      ;Start from scratch if ESC!
                CMP     #CR
                BNE     RB_ACINEXTCHAR  ;Read keys until CR

                LDX     #-1             ;Initialize parse buffer pointer

;-------------------------------------------------------------------------
; Start parsing first or a new tape command
;-------------------------------------------------------------------------

RB_NEXTCMD         
		LDA     #0              ;Clear begin and end values
                STA     HEX1L
                STA     HEX1H
                STA     HEX2L
                STA     HEX2H

RB_NEXTCHR
	        INX                     ;Increment input pointer
                LDA     IN,X            ;Get next char from input line
                CMP     #$d2            ;Read command?
                BEQ     RB_READ         ;Yes!
                CMP     #$d7            ;Write command?
                BEQ     RB_WRITE        ;Yes! (note: CY=1)
                CMP     #$ae            ;Separator?
                BEQ     RB_SEP          ;Yes!
                CMP     #CR             ;End of line?
                BEQ     RB_GOESC        ;Escape to monitor! We're done
                CMP     #$a0            ;Ignore spaces
                BEQ     RB_NEXTCHR
                EOR     #$b0            ;Map digits to 0-9
                CMP     #9+1            ;Is it a decimal digit?
                BCC     RB_ACIDIG       ;Yes!
                ADC     #$88            ;Map letter "A"-"F" to $FA-$FF
                CMP     #$FA            ;Hex letter?
                BCC     A2ACIDRIVER     ;No! Character not hex!

RB_ACIDIG  
	        ASL                     ;Hex digit to MSD of A
                ASL
                ASL
                ASL

                LDY     #4              ;Shift count
RB_ACIHEXSHIFT  
		ASL                     ;Hex digit left, MSB to carry
                ROL     HEX1L           ;Rotate into LSD
                ROL     HEX1H           ;Rotate into MSD
                DEY                     ;Done 4 shifts?
                BNE     RB_ACIHEXSHIFT  ;No! Loop
                BEQ     RB_NEXTCHR      ;Handle next character

;-------------------------------------------------------------------------
; Return to monitor, prints \ first
;-------------------------------------------------------------------------

RB_GOESC           JMP     ESCAPE          ;Escape back to monitor

;-------------------------------------------------------------------------
; Separating . found. Copy HEX1 to Hex2. Doesn't clear HEX1!!!
;-------------------------------------------------------------------------

RB_SEP             LDA     HEX1L           ;Copy hex value 1 to hex value 2
                STA     HEX2L
                LDA     HEX1H
                STA     HEX2H
                BCS     RB_NEXTCHR         ;Always taken!

;-------------------------------------------------------------------------
; Write a block of memory to tape
;-------------------------------------------------------------------------

RB_WRITE
;-------------------------------------------------------------------------
; save write start addresses
; so we can check for keyboard
; or console write sequences
; and dynamicly modify code to
; use original A1 driver
; and then revert later on
;-------------------------------------------------------------------------
	    	LDA	HEX2L 
 	   	STA	RDSTRTL
	    	LDA	HEX2H
 	   	STA 	RDSTRTH
                STX     SAVEINDEX       ;Save index in input line
                JSR	A2_WRITECONVERT ; convert I/O to A1 compatible format
;-------------------------------------------------------------------------
; now start write of this block
;-------------------------------------------------------------------------

           	LDA     #64             ;Write 10 second header
                JSR     RB_WHEADER

RB_WRNEXT          DEY                  ;Compensate timing for extra work
                LDX     #0              ;Get next byte to write
                LDA     (HEX2L,X)

                LDX     #8*2            ;Shift 8 bits (decremented twice)
RB_WBITLOOP        ASL                  ;Shift MSB to carry
                JSR     RB_WRITEBIT     ;Write this bit
                BNE     RB_WBITLOOP     ;Do all 8 bits!

                JSR     A2_INCADDR      ;Increment address
                LDY     #30             ;Compensate timer for extra work
                BCC     RB_WRNEXT       ;Not done yet! Write next byte

RB_RESTIDX  
                JSR	A2_READCONVERT	; convert buffer to A2 I/O
                LDX     SAVEINDEX       ;Restore index in input line
                JMP     RB_NEXTCMD      ;Always taken!

;-------------------------------------------------------------------------
; For case when ACI must fit in c100-c1ff - the read function must be moved
; because the standard read doesn't fit with the extra mask instruction
; required for the Apple II hardware
;-------------------------------------------------------------------------

RB_READ:
;-------------------------------------------------------------------------
; save read start addresses
; so we can check for keyboard
; or console write sequences
; and dynamicly modify code to
; use A2 driver
;-------------------------------------------------------------------------
	    	LDA	HEX2L 
 	   	STA	RDSTRTL
	    	LDA	HEX2H
 	   	STA 	RDSTRTH
	
		JSR	A2_FULLCYCLE	;Wait until full cycle is detected
                STX     SAVEINDEX       ;Save index in input line
                LDA     #22             ;Introduce some delay to allow
                JSR     RB_WHEADER        ; the tape speed to stabilize

;-------------------------------------------------------------------------
; 
; This read function will optionally convert and A1 keyboard reads
; to calls to use our driver to read from A2 hardware by scanning
; read data looking for one of three code sequences
;-------------------------------------------------------------------------
;
; Normal start
;
		JSR     A2_FULLCYCLE       ;Synchronize with full cycle
A2_NOTSTART     LDY     #28             ;Try to detect the much shorter
                JSR     A2_CMPLEVEL     ;  start bit
                BCS     A2_NOTSTART     ;Start bit not detected yet!
                JSR     A2_CMPLEVEL        ;Wait for 2nd phase of start bit

                LDY     #53             ;Set threshold value in middle
A2_RDBYTE       LDX     #8              ;Receiver 8 bits
A2_RDBIT        PHA
                JSR     A2_FULLCYCLE    ;Detect a full cycle
                PLA
                ROL                     ;Roll new bit into result
                LDY     #52             ;Set threshold value in middle
                DEX                     ;Decrement bit counter
                BNE     A2_RDBIT           ;Read next bit!
                STA     (HEX2L,X)       ;Save new byte

                JSR     A2_INCADDR         ;Increment address
                LDY     #46             ;Compensate threshold with workload
                BCC     A2_RDBYTE       ;Do next byte if not done yet!

		JMP	RB_RESTIDX



;-------------------------------------------------------------------------
; Write header to tape
;
; The header consists of an asymmetric cycle, starting with one phase of
; approximately (66+47)x5=565us, followed by a second phase of
; approximately (44+47)x5=455us.
; Total cycle duration is approximately 1020us ~ 1kHz. The actual
; frequencywill be a bit lower because of the additional workload between
; the twoloops.
; The header ends with a short phase of (30+47)x5=385us and a normal
; phase of (44+47)x5=455us. This start bit must be detected by the read
; routine to trigger the reading of the actual data.
;-------------------------------------------------------------------------

RB_WHEADER 
RB_HCOUNT       LDY     #72             ;Extra long delay
                JSR     RB_WDELAY       ;CY is constantly 1, writing a 1
                BNE     RB_HCOUNT       ;Do this 64 * 256 time!
                ADC     #-2             ;Decrement A (CY=1 all the time)
                BCS     RB_HCOUNT       ;Not all done!
                LDY     #32             ;Write a final short bit (start)

;-------------------------------------------------------------------------
; Write a full bit cycle
;
; Upon entry Y contains a compensated value for the first phase of 0
; bit length. All subsequent loops don't have to be time compensated.
;-------------------------------------------------------------------------

RB_WRITEBIT

                JSR     RB_WDELAY       ;Do two equal phases
                LDY     #47             ;Load 250us counter - compensation

RB_WDELAY       DEY                     ;Delay 250us (one phase of 2kHz)
                BNE     RB_WDELAY
                BCC     RB_WRITE1       ;Write a '1' (2kHz)

                LDY     #50             ;Additional delay for '0' (1kHz)
RB_WDELAY0      DEY                     ; (delay 250us)
                BNE     RB_WDELAY0

RB_WRITE1 
	
        	LDY     FLIP	        ;Flip the output bit

                LDY     #46             ;Reload 250us cntr (compensation)
                DEX                     ;Decrement bit counter
                RTS

;-------------------------------------------------------------------------
; Wait for FULL cycle (cmplevel- waits till level transisiton)
;-------------------------------------------------------------------------
A2_FULLCYCLE    JSR     A2_CMPLEVEL     ;Wait for two level changes
A2_CMPLEVEL     DEY                     ;Decrement time counter
                LDA     TAPEIN          ;Get Tape In data

; the next instruction must be added for apple II
		AND	#$80		;CLEAR floating bits
                CMP     LASTSTATE       ;Same as before?
                BEQ     A2_CMPLEVEL     ;Yes!
                STA     LASTSTATE       ;Save new data

                CPY     #128            ;Compare threshold
                RTS
;-------------------------------------------------------------------------
; Increment current address and compare with last address
;-------------------------------------------------------------------------
A2_INCADDR         LDA     HEX2L           ;Compare current address with
                CMP     HEX1L           ; end address
                LDA     HEX2H
                SBC     HEX1H
                INC     HEX2L           ;And increment current address
                BNE     A2_NOCARRY         ;No carry to MSB!
                INC     HEX2H
A2_NOCARRY         RTS

;-------------------------------------------------------------------------
;  one block read
;  modify A1 code that touches PIA to A2 version as it is loaded
;  these are keyboard and display functions
;
;  APPLE 1 version
;ACIWAITCHAR
; ad 11 d0	LDA     KBDCR	      ;Wait for key press
; 30 FB         BPL     ACIWAITCHAR   ;No key yet!
; ad 10 d0      LDA     KBD           ;Clear strobe
; converted to our version
; 20 3a d1	JSR	A2GETCHAR
; ea		NOP
; ea		NOP
; ea		NOP
; ea		NOP
; ea		NOP
;
;  instead if BPL is not present or has mismatching branch offset
; ad 11 d0	LDA	KBDCR
;  is converted to
; ad 00 c0 	LDA	KBD
;
;
; 
; ad 10 d0	LDA	KBD
;  is converted to
; 8d 10 c0 	STA	KBDCR	;Clear strobe	
;
;  finally there are some cases where presence of character is
;   determined with the bit command
; 2c 11 d0	BIT	KBDCR
;  is converted to
; 2c 00 c00     BIT	KBD
;
;
;
;-------------------------------------------------------------------------

CNVRTTERM	EQU	$77	; UNIQUE CHAR NEEDED TO TERMINATE CONVERSION STRINGS

A2_READCONVERT
	LDA	#0			; RDCONVERT can be turned off
	CMP	RDCONVERT
	BNE	A2_READCONVERTDONE	; not zero, then skip conversion
    LDX		#0
    LDY		#0
;
; check next string through all of memory
;

A2_READCONVERT_1		; for this string, scan all of read memory
    STY		savey		;save compare string starting point

    LDA		CNVRT_IN,Y
    CMP		#CNVRTTERM		; Termination character?
    BEQ		A2_READCONVERTDONE	;all done checking, exit
    
    LDA		RDSTRTL		; start of memory load
    STA		HEX2L
    LDA		RDSTRTH
    STA		HEX2H

;
; restart currnet string
;
A2_READCONVERT_8
    LDA		HEX2L		;save memory starting point
    STA		HEX2LB
    LDA		HEX2H
    STA		HEX2HB
    LDY		savey

A2_READCONVERT1
    LDA		(HEX2L),X			; fetch byte from memory
    CMP		CNVRT_IN,Y		; compare
    BEQ		A2_READCONVERT1_2	; this byte does match, process
;
; mo match, restart match string
;
    JSR		A2_INCADDR
    BCC		A2_READCONVERT_8	; not end of memory - restart scan for current string
    
;
; end of memory block - go to next string
;
A2_READCONVERT1_3
    INY
    LDA 	CNVRT_IN,Y
    CMP		#CNVRTTERM		; Termination character?
    BNE		A2_READCONVERT1_3	; not end of block, keep looking
    INY					; found end, move to start of next block
    JMP		A2_READCONVERT_1	; rescan memory with next string
;
; match - keep going until mismatch or end of string
;
A2_READCONVERT1_2
    INY
    LDA 	CNVRT_IN,Y
    CMP		#CNVRTTERM		; Termination character?
    BEQ		A2_READCONVERT3		; end of string - this is match do substitute
    JSR		A2_INCADDR			; next memory address
    BCC		A2_READCONVERT1		; not done - keep scanning

    JMP		A2_READCONVERT1_3	; not a complete match - try next string

;-------------------------------------------------------------------------
; Finished with READ
;-------------------------------------------------------------------------
A2_READCONVERTDONE
        RTS

;-------------------------------------------------------------------------
; Substitute string here
;-------------------------------------------------------------------------

A2_READCONVERT3				; match - substitute here
    LDY		savey

    LDA		HEX2LB			;restore memory starting point
    STA		HEX2L
    LDA		HEX2HB
    STA		HEX2H
A2_READCONVERT4
    LDA		CNVRT_IN,Y
    CMP		#CNVRTTERM		; Termination character?
    BEQ		A2_READCONVERT_8	; done with sustibute, continue checking
    LDA		CNVRT_OUT,Y
    INY
    STA		(HEX2L),X
    JSR		A2_INCADDR
    JMP		A2_READCONVERT4
    
;-------------------------------------------------------------------------
; conversion strings
;    	IN(what we are looking for 
;	 OUT (what we change it to)
;-------------------------------------------------------------------------

CNVRT_IN
CI1 LDA		$d011
    BPL		CI1
    LDA		$d010
    DC.b	CNVRTTERM
    LDA		$d011
    DC.b	CNVRTTERM
    LDA		$d010
    DC.b	CNVRTTERM
    BIT		$d011
    DC.b	CNVRTTERM
CI2
    BIT		$D012
    BMI		CI2
    STA		$D012
    DC.b	CNVRTTERM
            IFCONST BLD4RAM
    JSR		$FFEF
    DC.b	CNVRTTERM
                ENDIF
    DC.b	CNVRTTERM

CNVRT_OUT
    JSR		A2GETCHAR
    NOP
    NOP
    NOP
    NOP
    NOP
    DC.b	CNVRTTERM
    LDA		KBD
    DC.b	CNVRTTERM
    STA		KBDCR
    DC.b	CNVRTTERM
    BIT		KBD
    DC.b	CNVRTTERM
    JSR		ECHO
    NOP
    NOP
    NOP
    NOP
    NOP
    DC.b	CNVRTTERM
        IFCONST BLD4RAM
    JSR		ECHO
    DC.b	CNVRTTERM
        ENDIF
    DC.b	CNVRTTERM


;-------------------------------------------------------------------------
;  one block write
;  undo read convert when writing to tape so tape
;  can be loaded and run on a real actual A1
;-------------------------------------------------------------------------
A2_WRITECONVERT
	LDA	#0			; RDCONVERT can be turned off
	CMP	RDCONVERT
	BNE	A2_WRITECONVERTDONE	; not zero, then skip conversion
    LDX		#0
    LDY		#0
;
; check next string through all of memory
;

A2_WRITECONVERT_1		; for this string, scan all of read memory
    STY		savey		;save compare string starting point

    LDA		CNVRT_OUT,Y
    CMP		#CNVRTTERM		; Termination character?
    BEQ		A2_WRITECONVERTDONE	;all done checking, exit

    LDA		RDSTRTL		; reset block address
    STA		HEX2L
    LDA		RDSTRTH
    STA		HEX2H

;
; restart currnet string
;
A2_WRITECONVERT_8
    LDA		HEX2L		;save memory starting point
    STA		HEX2LB
    LDA		HEX2H
    STA		HEX2HB
    LDY		savey

A2_WRITECONVERT1
    LDA		(HEX2L),X			; fetch byte from memory
    CMP		CNVRT_OUT,Y		; compare
    BEQ		A2_WRITECONVERT1_2	; this byte does match, process
;
; mo match, restart match string
;
    JSR		A2_INCADDR
    BCC		A2_WRITECONVERT_8	; not end of memory - restart scan for current string
    
;
; end of memory block - go to next string
;
A2_WRITECONVERT1_3
    INY
    LDA 	CNVRT_OUT,Y
    CMP		#CNVRTTERM		; Termination character?
    BNE		A2_WRITECONVERT1_3	; not end of block, keep looking
    INY					; found end, move to start of next block
    JMP		A2_WRITECONVERT_1	; rescan memory with next string
;
; match - keep going until mismatch or end of string
;
A2_WRITECONVERT1_2
    INY
    LDA 	CNVRT_OUT,Y
    CMP		#CNVRTTERM		; Termination character?
    BEQ		A2_WRITECONVERT3	; end of string - this is match do substitute
    JSR		A2_INCADDR		; next memory address
    BCC		A2_WRITECONVERT1	; not done - keep scanning

    JMP		A2_WRITECONVERT1_3	; not a complete match - try next string

;-------------------------------------------------------------------------
; Finished with WRITE CONVERSION
;-------------------------------------------------------------------------
A2_WRITECONVERTDONE
    LDA		RDSTRTL		; reset block address
    STA		HEX2L
    LDA		RDSTRTH
    STA		HEX2H

                RTS
;-------------------------------------------------------------------------
; Substitute string here
;-------------------------------------------------------------------------

A2_WRITECONVERT3				; match - substitute here
    LDY		savey

    LDA		HEX2LB			;restore memory starting point
    STA		HEX2L
    LDA		HEX2HB
    STA		HEX2H
A2_WRITECONVERT4
    LDA		CNVRT_OUT,Y
    CMP		#CNVRTTERM		; Termination character?
    BEQ		A2_WRITECONVERT_8	; done with sustibute, continue checking
    LDA		CNVRT_IN,Y
    INY
    STA		(HEX2L),X
    JSR		A2_INCADDR
    JMP		A2_WRITECONVERT4

;-------------------------------------------------------------------------
; output driver - uses hires memory
;-------------------------------------------------------------------------

A2GETCHAR:
                JMP	(READVECTOR)	;Allow user override of default get char function
A2GETCHAR2:
		JSR	TOGGLE
		LDA     KBD	        ;Wait for key press
                BPL     A2GETCHAR      ;No key yet!
                STA     KBDCR           ;Clear strobe
		CMP	#$88		; left arrow
		BNE	A2_GC_NOT_BS	; brnch no
		LDA	#BS		; convert to _
A2_GC_NOT_BS:
		CMP	#$95		; right arrow
		BNE	A2_GC_RET	; no, exit
		JSR	CLEAR		; yes, clear screen and

		JMP	A2GETCHAR	; get next char (this is a special HW emulation
                                        ; function so skip call to READVECTOR)
A2_GC_RET:
		RTS


;-------------------------------------------------------------------------
; output driver - uses hires memory
;-------------------------------------------------------------------------
;;; Magic Numbers
SCRINIT EQU $f0
PG0SAVEFLG EQU $f0
;;; Definitions
HRPG1	EQU $C054
HRPG2	EQU $C055
LORES	EQU $C056
HIRES	EQU $C057
TXTCLR	EQU $C050
TXTMOD	EQU $C051
MIXCLR	EQU $C052
GETCHAR EQU $FD0C

;;; Page Zero Temps (8 locations reserved)
TRGLOW	EQU $00
TRGHIGH EQU $01
SRCLOW  EQU $02
SRCHIGH	EQU $03
CNT2	EQU $05
CNT3    EQU $06

; Last location of low res
LASTLOCATION EQU $7F8
	
;;; Entry point for testing
START	JSR INIT
L0	JSR GETCHAR
	JSR PUTCH
	JMP L0
	BRK

;;; Move the cursor
MVCSR	INC CURCOL
	LDA CURCOL
	CMP #40
	BPL NXTROW
MD
	LDA #0
	CMP TURBO
	BNE MR

	LDY #0
ML0	LDX #12		; speed fine tuning
ML1	INX
	BNE ML1
	INY
	CPY #$9
	BNE ML0
MR	RTS
NXTROW
        LDA #0
	STA CURCOL

	LDA CURROW	; don't increment current row until in case
                        ; we are already at bottom of screen 
        CMP #23		; if a reset comes in, it could leave us on an illegal row
	BMI NXTROW2

	JSR SCROLL	; scrolling bottom line, do not advance CURROW
        JMP MD

NXTROW2
        INC CURROW	; not at bottom of screen advance to next row (CURROW)
	JMP MD

;;; Toggle the cursor
TOGGLE
        
	INC COUNTER0
	BNE DT
	INC COUNTER1
	BNE DT
	PHA
        LDA #CNTSTRT
	STA COUNTER1
;
; if screen has not been cleared- toggle betweeen hi res pages
;
        LDA	SCRNCLRD
        BMI	TOGGLE2
;
; toggle from hi-res to low-res
;
        LDA	CURSOR
        BNE 	TOGGLE1
	LDA 	#32
	STA 	CURSOR
        LDA	HRPG1
        JMP	TOGGLE4
        
TOGGLE1
        LDA 	#0
        STA 	CURSOR
        LDA	HRPG2
        JMP	TOGGLE4
;
; else toggle cursor
;
TOGGLE2
	STX savex
	STY savey
	JSR SAVPG0

	LDA CURSOR
	BNE SETSPC
	LDA #32
	JMP DRWCUR
SETSPC  LDA #0
DRWCUR	STA CURSOR
	LDX CURCOL
	LDY CURROW
	JSR GETBLOK
	LDX CURSOR
	JSR GETCHB
	JSR DRAWCH
	JSR LODPG0
	LDX savex
	LDY savey
TOGGLE4
	PLA
DT	RTS

;;; Scrolls the screen at the end
SCROLL
;------------------------------------------------------------------------------------------------------------
;
; HIRES is organized
;	 into three blocks, offset by 0x28 bytes each, starting at 2000
;		each block holds 8 lines of text, offset by 0x80 bytes
;			each line of text is split into 8 rows of pixels offset by 0x400 bytes
;
; this function starts at second from top row copy all pixels to row above it and continues down the screen
;
;------------------------------------------------------------------------------------------------------------
; first block -set up starting addresses
;
        ldx	#0	;index into graphics table - starts at zero
; top loop - 24 lines of characters per page - copy bottom 23 lines (first line scrolls off top)
        LDA #23
        STA CNT2

;
; next line of text
;
scr1
        LDA PG1ROWS,x	; target
        STA TRGHIGH
        inx
        LDA PG1ROWS,x	; target
        STA TRGLOW
        inx
        LDA PG1ROWS,x	; src
        STA SRCHIGH
        inx
        LDA PG1ROWS,x	; scr
        STA SRCLOW
        DEX		;next pass target is current source
        LDA #8
        STA	CNT3
        JMP	scr2.1
;
; adjust address to next line of pixels
;
scr2

        LDA 	#$4
        CLC
        ADC	SRCHIGH
        STA	SRCHIGH
        LDA 	#$4
        CLC
        ADC	TRGHIGH
        STA	TRGHIGH
scr2.1
        LDY 	#39
;copy 40 characters that make up a line of pixels
scr3
        LDA 	(SRCLOW),y
        STA 	(TRGLOW),y
        DEY
        BPL	scr3	; repeat for 40 characters that make line of pixels
        DEC	CNT3
        BNE	scr2	; done with this line of pixels =- goto to next liine of pixels
        DEC	CNT2
        BNE	scr1    ; done with this line of characters - goto next line of chars
        
        JSR   CLEAR_LINE
	RTS

;
; clear  line - X contains line #
;
CLEAR_LINE
        LDA 	PG1ROWS,x	; target (was last source)
        STA 	TRGHIGH
        inx
        LDA 	PG1ROWS,x	; target
        STA 	TRGLOW

        LDA 	#8
        STA	CNT3
        JMP	CL4.1
;
; adjust address to next line of pixels
;
CL4
        LDA 	#$4
        CLC
        ADC	TRGHIGH
        STA	TRGHIGH
CL4.1
        LDY 	#39
        lda	#$0
;copy 40 characters that make up a line of pixels
CL5
        STA 	(TRGLOW),y
        DEY
        BPL	CL5	; repeat for 40 characters that make line of pixels
        DEC	CNT3
        BNE	CL4	; done with this line of pixels =- goto to next liine of pixels
        RTS


;;; Initialize the graphics system, set cursor and clear the screen
INIT
;
; Initialize default keyboard in and video out routines
        LDA	#<PUTCH2	;first video out
        STA	WRITVECTOR
        LDA	#>PUTCH2
        STA	WRITVECTOR+1
        
        LDA	#<A2GETCHAR2	;now keyboard in
        STA	READVECTOR
        LDA	#>A2GETCHAR2
        STA	READVECTOR+1
        
        LDA	TURBO		;clear computer driven turbo mode
        AND	#TURBOUSR	;but save user turbo mode
        STA	TURBO
;
; reset could have occurred during video driver operations
; attempt to restore page 0 if possible
; there is a case where we were in the process of saving
; or restoring page zero variables when reset occurred
; we cannot recover from that case
;
        JSR	LODPG0 		;restore page zero variables
;
; determine whether we should emulate power up screen
;
        LDA 	#SCRINIT
        CMP	POWERUPINIT	;have we initialized power up screen
        BNE	INITSCREEN	;no, let's do it	
        CMP 	SCRNCLRD	;has user cleared the screen?
        BNE	INITEXIT	;no, leave graphics mode alone	
        
;
; clear screen already done - set HGR PG 2 mode
;
        STA HIRES		; set high res pg 2 graphics mode
	STA HRPG2		; if this is power up, this will be changed below
	STA TXTCLR
	STA MIXCLR
INITEXIT
        RTS
;
; initialize lowres page 1 as startup screen
;

INITSCREEN
	LDA	#$04			;START ADDRESS
	STA	HEX2H
	LDA	#$0
	STA	HEX2L

	LDA	#$0B			;END ADDRESS
	STA	HEX1H
	LDA	#$F8
	STA	HEX1L

        LDY	#0

INIT1
        LDA	#$DF			; underbar
        STA	(HEX2L),y
	JSR	A2_INCADDR
	BCS	INIT2
        LDA	#$08		; check address range <800 use at sign
        BIT	HEX2H           ; >800 use space
        BNE	INIT1_1	
        LDA	#$C0		; at sign
        BMI	INIT1_2	
INIT1_1
        LDA	#$A0		; space
INIT1_2
        STA	(HEX2L),y	; save it
	JSR	A2_INCADDR
	BCC	INIT1

INIT2

        LDA	#0
        STA	SCRNCLRD		; now indicate that screen has been not cleared
        STA CURROW
	STA CURCOL
	STA TURBO			; default not turbo mode
	STA RDCONVERT			; default convert cassette reads
        LDA #CNTSTRT
	STA COUNTER1
    
        STA LORES			; set lowres pg 1 graphics mode for start up screen
	STA HRPG1			; use page 1
	STA TXTMOD
	STA MIXCLR

        LDA 	#SCRINIT
        STA	POWERUPINIT		; indicate power on init done

	RTS

;;; Clears hires page 1
CLEAR
        STY	savey
        STX	savex
	JSR SAVPG0

        LDX	#0
        
CLEAR2
        JSR	CLEAR_LINE
        INX
        CPX	#48
        BNE	CLEAR2
	;; page cleared
        
        LDA	#SCRINIT
        STA 	SCRNCLRD	;indicate screen cleared

        STA HIRES		; set high res pg 2 graphics mode
	STA HRPG2
	STA TXTCLR
	STA MIXCLR
        
        LDA #$00
;
; cursor to top left
;
	STA CURROW
	STA CURCOL

	JSR LODPG0
        LDY	savey
        LDX	savex
	RTS

;;; Prints character from A to the screen
PUTCH
        JMP	(WRITVECTOR)	;allow user override of default video out routine
PUTCH2:
	PHA
	STY savey
	STX savex
        
        LDY 	SCRNCLRD
        BPL	PUTCH_DROP	;if plus, screen has not been cleared, so drop

	JSR SAVPG0
	;; drop the high bit
	AND #$7F	
	;; check for return
	CMP #$0D
	BEQ ENTERKY
	;; it's a regular key
	JSR GETCODE
	STA CHAR
	;; get the block address
	LDX CURCOL
	LDY CURROW
	JSR GETBLOK
	;; get block bytes
	LDX CHAR
	JSR GETCHB
	;; render the char to the block
	JSR DRAWCH
	;; restore state and exit
PD	JSR MVCSR
	JSR LODPG0

PUTCH_DROP
	LDY savey
	LDX savex
	PLA
	RTS

ENTERKY			; print spaces until end of line (use turbo mode)
	LDA 	TURBO
	ORA 	#TURBOCMP ; set computer turbo mode
	STA 	TURBO	; turbo mode to clear end of line	
ENTERKY1
        LDY CURROW	
	LDX CURCOL
	CPX #40
	BEQ ENTERKY_EXIT
	JSR GETBLOK
	LDX #0		; space key
	JSR GETCHB
	JSR DRAWCH
	INC CURCOL
	JMP ENTERKY1

ENTERKY_EXIT
	LDA 	TURBO
	AND 	#TURBOUSR ; reset computer turbo mode, saving user mode
	STA 	TURBO	; 
        JMP	PD

;;; Draws character to block
DRAWCH	LDX #0
L6	TXA
	TAY
	LDA (SRCLOW),Y
	LDY #0
	STA (TRGLOW),Y
	INX
	LDA TRGHIGH
	CLC
	ADC #$4
	STA TRGHIGH
	CPX #8
	BMI L6
	RTS
	
;;; Get byte for char in X
GETCHB	LDY #<SPCODE
	STY SRCLOW
	LDY #>SPCODE
	STY SRCHIGH
L5	CPX #0
	BEQ D
	DEX
	LDA #8
	CLC
	ADC SRCLOW
	STA SRCLOW
	BCS AC
	JMP L5
AC	LDA #0
	ADC SRCHIGH
	STA SRCHIGH
	JMP L5
D	RTS
	
;;; Gets the block address at X,Y
GETBLOK TYA
	JSR GETROW
	;; add the column
	TXA
	CLC
	ADC TRGLOW
	STA TRGLOW
	BCS A1
	RTS
A1	LDA #0
	ADC TRGHIGH
	RTS

;;; Gets the row (A) address
GETROW	ASL			; multiply row by two, there are two bytes per address
	TAY
	LDA PG1ROWS,Y
	STA TRGHIGH
	INY
	LDA PG1ROWS,Y
	STA TRGLOW
	RTS
	
;;; Converts ASCII code to table index
GETCODE	SEC
	SBC #$20
	BMI NC
	CMP #$40
	BPL NC
	RTS
NC	LDA #0
	RTS

;;; Store page zero data
SAVPG0  PHA
	STX TMP1

	LDA #PG0SAVEFLG	;check saved flag
	CMP PG0SAVD
	BEQ SD		;already saved, just exit

	LDX #0
L1	LDA $00,X
	STA TMPG0,X
	INX
	CPX #$8
	BNE L1

        LDA #PG0SAVEFLG	;set save flag to saved after completely saved
        STA PG0SAVD	;this way, if a reset comes in before we are done
                        ;we will not corrupt zero page
                        ;as the reset code restores zero page if flag set

SD	LDX TMP1
	PLA
	RTS

;;; Restore page zero data
LODPG0	
	PHA
	STX TMP1

	LDA #PG0SAVEFLG	;checked saved flag
	CMP PG0SAVD
	BNE LD		;not saved, exit

	LDX #0
L2	LDA TMPG0,X
	STA $00,X
	INX
	CPX #$8
	BNE L2
        
        LDA #<(~PG0SAVEFLG) ;clear saved flag to not saved after completely restored
                        ;this way, if a reset comes in before we are done
	STA PG0SAVD	;as the reset code restores zero page if flag set

LD	LDX TMP1
	PLA
	RTS	


;;; tables
PG1ROWS	HEX 4000 4080 4100 4180 4200 4280 4300 4380 4028 40A8 4128 41A8 4228 42A8 4328 43A8 4050 40D0 4150 41D0 4250 42D0 4350 43D0
SPCODE	HEX 00 00 00 00 00 00 00 00
EXPCODE HEX 00 08 08 08 08 08 00 08
QUOCODE HEX 00 14 14 14 00 00 00 00
NUMCODE HEX 00 14 14 3e 14 3e 14 14
STRCODE HEX 00 08 3c 0a 1c 28 1e 08
PERCODE HEX 00 06 26 10 08 04 32 30
AMPCODE HEX 00 04 0a 0a 04 2a 12 2c
SQCODE	HEX 00 08 08 08 00 00 00 00
RPCODE  HEX 00 08 04 02 02 02 04 08
LPCODE  HEX 00 08 10 20 20 20 10 08
STACODE HEX 00 08 2a 1c 08 1c 2a 08
PLSCODE HEX 00 00 08 08 3e 08 08 00
CMACODE HEX 00 00 00 00 00 08 08 04
MINCODE HEX 00 00 00 00 3e 00 00 00
DOTCODE HEX 00 00 00 00 00 00 00 08
FSCODE  HEX 00 00 20 10 08 04 02 00
0CODE   HEX 00 1c 22 32 2a 26 22 1c
1CODE	HEX 00 08 0c 08 08 08 08 1c
2CODE	HEX 00 1c 22 20 18 04 02 3e
3CODE 	HEX 00 3e 20 10 18 20 22 1c
4CODE 	HEX 00 10 18 14 12 3e 10 10
5CODE	HEX 00 3e 02 1e 20 20 22 1c
6CODE	HEX 00 38 04 02 1e 22 22 1c
7CODE	HEX 00 3e 20 10 08 04 04 04
8CODE	HEX 00 1c 22 22 1c 22 22 1c
9CODE	HEX 00 1c 22 22 3c 20 10 0e
COLCODE	HEX 00 00 00 08 00 08 00 00
SEMCODE	HEX 00 00 00 08 00 08 08 04
LTCODE	HEX 00 10 08 04 02 04 08 10
EQCODE	HEX 00 00 00 3e 00 3e 00 00
GTCODE	HEX 00 04 08 10 20 10 08 04
QESCODE	HEX 00 1c 22 10 08 08 00 08
ATCODE  HEX 00 1C 22 2A 3A 1A 02 3C
ACODE 	HEX 00 08 14 22 22 3e 22 22
BCODE	HEX 00 1e 22 22 1e 22 22 1e
CCODE	HEX 00 1c 22 02 02 02 22 1c
DCODE	HEX 00 1e 22 22 22 22 22 1e
ECODE	HEX 00 3e 02 02 1e 02 02 3e
FCODE	HEX 00 3e 02 02 1e 02 02 02
GCODE	HEX 00 3c 02 02 02 32 22 3c
HCODE	HEX 00 22 22 22 3e 22 22 22
ICODE	HEX 00 1c 08 08 08 08 08 1c
JCODE	HEX 00 20 20 20 20 20 22 1c
KCODE	HEX 00 22 12 0a 06 0a 12 22
LCODE	HEX 00 02 02 02 02 02 02 3e
MCODE	HEX 00 22 36 2a 2a 22 22 22
NCODE	HEX 00 22 22 26 2a 32 22 22
OCODE	HEX 00 1c 22 22 22 22 22 1c
PCODE	HEX 00 1e 22 22 1e 02 02 02
QCODE	HEX 00 1c 22 22 22 2a 12 2c
RCODE	HEX 00 1e 22 22 1e 0a 12 22
SCODE	HEX 00 1c 22 02 1c 20 22 1c
TCODE	HEX 00 3e 08 08 08 08 08 08
UCODE	HEX 00 22 22 22 22 22 22 1c
VCODE	HEX 00 22 22 22 22 22 14 08
WCODE	HEX 00 22 22 22 2a 2a 36 22
XCODE	HEX 00 22 22 14 08 14 22 22
YCODE	HEX 00 22 22 14 08 08 08 08
ZCODE	HEX 00 3e 20 10 08 04 02 3e
LBCODE  HEX 00 3e 06 06 06 06 06 3e
BSCODE	HEX 00 00 02 04 08 10 20 00 
RBCODE	HEX 00 3e 30 30 30 30 30 3e
CRTCODE HEX 00 00 00 08 14 22 00 00
UNDCODE	HEX 00 00 00 00 00 00 00 3e



;------------------------------------------------------------------------
; BASIC SUPPORT FUNCTIONs
;	peek and poke of the PIA is emulated
; 	using A2 hardware drivers
;------------------------------------------------------------------------
;------------------------------------------------------------------------
; POKE of D012 is emulated by calling
; A2 putchar routine
;------------------------------------------------------------------------
ACC	EQU	$ce		; must be same as basic "acc"
A2POKE
                JSR	getbyte
	  	LDA	ACC
	  	PHA
	  	JSR	get16bit
		LDA	#$D0
                CMP	ACC+1
                BEQ	A2POKE2
A2POKE1
	   	PLA
	   	STA	(ACC),Y
                RTS
A2POKE2
                LDA	#$12
                CMP	ACC
                BNE	A2POKE1
;------------------------------------------------------------------------
; Poke D012 == A2 ECHO CALL
;------------------------------------------------------------------------
                PLA
                JMP	ECHO
                
;------------------------------------------------------------------------
; PEEK of D012, D011 and D010 is emulated by using
; equivalent A2 functionality
;------------------------------------------------------------------------

A2PEEK
	  	JSR	get16bit
                LDA	#$D0
                CMP	ACC+1
                BEQ	A2PEEK3
A2PEEK1
	    	LDA	(ACC),Y
A2PEEK2
	   	STY	syn_stk_l+31,X
	   	JMP	push_ya_noun_stk

;------------------------------------------------------------------------
; Peek D012 == determine if terminal is ready for output
;  in the A2 memory mapped video driver case - the answer 
;  is always yes -so return positive number(or zero in this case)
;------------------------------------------------------------------------
A2PEEK3
                LDA	#$12
                CMP	ACC
                BNE	A2PEEK4
                LDA	#$00
                JMP	A2PEEK2
;------------------------------------------------------------------------
; Peek D011 == A2 read c000 (does keyboard have char, yes if MSB set)
;------------------------------------------------------------------------
A2PEEK4
                LDA	#$11
                CMP	ACC
                BNE	A2PEEK5
                LDA	KBD
                JMP	A2PEEK2
;------------------------------------------------------------------------
; Peek D010 == A2 getchar (also clears strobe)
;------------------------------------------------------------------------
A2PEEK5
                LDA	#$10
                CMP	ACC
                BNE	A2PEEK1
                LDA	KBD
                STA	KBDCR
                JMP	A2PEEK2

            IFCONST BLD4RAM
                    STORAGE
		ENDIF   
	ENDIF			; end of A2 driver code
;------------------------------------------------------------------------
;  VERSION 
;------------------------------------------------------------------------
	IFCONST BLD4RAM 
		ORG $6FFE
	ELSE
		ORG $DFFE
	ENDIF
        DC.w	$0105

;------------------------------------------------------------------------
;  BASIC 
;------------------------------------------------------------------------
    INCLUDE	a1basic-universal.asm

;-------------------------------------------------------------------------
;
;  The WOZ Monitor for the Apple 1
;  Written by Steve Wozniak 1976
;
;-------------------------------------------------------------------------


	IFNCONST BLD4RAM
		ORG $FF00
	ENDIF

;-------------------------------------------------------------------------
;  Memory declaration
;-------------------------------------------------------------------------





XAML            EQU     $24             ;Last "opened" location Low
XAMH            EQU     $25             ;Last "opened" location High
STL             EQU     $26             ;Store address Low
STH             EQU     $27             ;Store address High
L               EQU     $28             ;Hex value parsing Low
H               EQU     $29             ;Hex value parsing High
YSAV            EQU     $2A             ;Used to see if hex value is given
MODE            EQU     $2B             ;$00=XAM, $7F=STOR, $AE=BLOCK XAM

IN              EQU     $0200		;Input buffer

	IFCONST BLD4APPLE1
MONDSP             EQU     $D012           ;PIA.B display output register
MONDSPCR           EQU     $D013           ;PIA.B display control register
	ENDIF

; KBD b7..b0 are inputs, b6..b0 is ASCII input, b7 is constant high
;     Programmed to respond to low to high KBD strobe
; DSP b6..b0 are outputs, b7 is input
;     CB2 goes low when data is written, returns high when CB1 goes high
; Interrupts are enabled, though not used. KBD can be jumpered to IRQ,
; whereas DSP can be jumpered to NMI.



;-------------------------------------------------------------------------
;  Let's get started
;
;  Remark the RESET routine is only to be entered by asserting the RESET
;  line of the system. This ensures that the data direction registers
;  are selected.
;-------------------------------------------------------------------------

RESET           CLD                     ;Clear decimal arithmetic mode
                CLI
	IFNCONST BLD4APPLE1
		JSR 	INIT		;init display driver
	ENDIF
                LDY     #$7f     	;Mask for DSP data direction reg
	IFCONST BLD4APPLE1
                STY     MONDSP             ; (DDR mode is assumed after reset)
	ENDIF
                LDA     #$a7    	;KBD and DSP control register mask
	IFCONST BLD4APPLE1
                 STA     KBDCR           ;Enable interrupts, set CA1, CB1 for
                 STA     MONDSPCR           ; positive edge sense/output mode.
	ELSE
			NOP
			NOP
			NOP
			NOP
			NOP
			NOP
	ENDIF

; Program falls through to the GETLINE routine to save some program bytes
; Please note that Y still holds $7F, which will cause an automatic Escape

;-------------------------------------------------------------------------
; The GETLINE process
;-------------------------------------------------------------------------

NOTCR           CMP     #BS             ;Backspace key?
                BEQ     BACKSPACE       ;Yes
                CMP     #ESC            ;ESC?
                BEQ     ESCAPE          ;Yes
                INY                     ;Advance text index
                BPL     NEXTCHAR        ;Auto ESC if line longer than 127

ESCAPE          LDA     #PROMPT         ;Print prompt character
                JSR     ECHO            ;Output it.

GETLINE         LDA     #CR             ;Send CR
                JSR     ECHO

                LDY     #0+1            ;Start a new input line
BACKSPACE       DEY                     ;Backup text index
                BMI     GETLINE         ;Oops, line's empty, reinitialize

NEXTCHAR
	IFCONST	BLD4APPLE1
        LDA     KBDCR	        ;Wait for key press
                BPL     NEXTCHAR        ;No key yet!
                LDA     KBD	           ;Clear strobe
	ELSE
		    JSR	A2GETCHAR
		    NOP
		    NOP
		    NOP
		    NOP
		    NOP
	ENDIF
                STA     IN,Y            ;Add to text buffer
                JSR     ECHO            ;Display character
                CMP     #CR
                BNE     NOTCR           ;It's not CR!

; Line received, now let's parse it

                LDY     #-1             ;Reset text index
                LDA     #0              ;Default mode is XAM
                TAX                     ;X=0

SETSTOR         ASL                     ;Leaves $7B if setting STOR mode

SETMODE         STA     MODE            ;Set mode flags

BLSKIP          INY                     ;Advance text index

NEXTITEM        LDA     IN,Y            ;Get character
                CMP     #CR
                BEQ     GETLINE         ;We're done if it's CR!
                CMP     #$AE		;"."
                BCC     BLSKIP          ;Ignore everything below "."!
                BEQ     SETMODE         ;Set BLOCK XAM mode ("." = $AE)
                CMP     #$BA		;":"
                BEQ     SETSTOR         ;Set STOR mode! $BA will become $7B
                CMP     #$d2		;"R"
                BEQ     RUN             ;Run the program! Forget the rest
                STX     L               ;Clear input value (X=0)
                STX     H
                STY     YSAV            ;Save Y for comparison

; Here we're trying to parse a new hex value

NEXTHEX         LDA     IN,Y            ;Get character for hex test
                EOR     #$B0            ;Map digits to 0-9
                CMP     #9+1            ;Is it a decimal digit?
                BCC     DIG             ;Yes!
                ADC     #$88            ;Map letter "A"-"F" to $FA-FF
                CMP     #$FA            ;Hex letter?
                BCC     NOTHEX          ;No! Character not hex

DIG             ASL
                ASL                     ;Hex digit to MSD of A
                ASL
                ASL

                LDX     #4              ;Shift count
HEXSHIFT        ASL                     ;Hex digit left, MSB to carry
                ROL     L               ;Rotate into LSD
                ROL     H               ;Rotate into MSD's
                DEX                     ;Done 4 shifts?
                BNE     HEXSHIFT        ;No, loop
                INY                     ;Advance text index
                BNE     NEXTHEX         ;Always taken

NOTHEX          CPY     YSAV            ;Was at least 1 hex digit given?
                BEQ     ESCAPE          ;No! Ignore all, start from scratch

                BIT     MODE            ;Test MODE byte
                BVC     NOTSTOR         ;B6=0 is STOR, 1 is XAM or BLOCK XAM

; STOR mode, save LSD of new hex byte

                LDA     L               ;LSD's of hex data
                STA     (STL,X)         ;Store current 'store index'(X=0)
                INC     STL             ;Increment store index.
                BNE     NEXTITEM        ;No carry!
                INC     STH             ;Add carry to 'store index' high
TONEXTITEM      JMP     NEXTITEM        ;Get next command item.

;-------------------------------------------------------------------------
;  RUN user's program from last opened location
;-------------------------------------------------------------------------

RUN             JMP     (XAML)          ;Run user's program

;-------------------------------------------------------------------------
;  We're not in Store mode
;-------------------------------------------------------------------------

NOTSTOR         BMI     XAMNEXT         ;B7 = 0 for XAM, 1 for BLOCK XAM

; We're in XAM mode now

                LDX     #2              ;Copy 2 bytes
SETADR          LDA     L-1,X           ;Copy hex data to
                STA     STL-1,X         ; 'store index'
                STA     XAML-1,X        ; and to 'XAM index'
                DEX                     ;Next of 2 bytes
                BNE     SETADR          ;Loop unless X = 0

; Print address and data from this address, fall through next BNE.

NXTPRNT         BNE     PRDATA          ;NE means no address to print
                LDA     #CR             ;Print CR first
                JSR     ECHO
                LDA     XAMH            ;Output high-order byte of address
                JSR     PRBYTE
                LDA     XAML            ;Output low-order byte of address
                JSR     PRBYTE
                LDA     #":"            ;Print colon
                JSR     ECHO

PRDATA          LDA     #" "            ;Print space
                JSR     ECHO
                LDA     (XAML,X)        ;Get data from address (X=0)
                JSR     PRBYTE          ;Output it in hex format
XAMNEXT         STX     MODE            ;0 -> MODE (XAM mode).
                LDA     XAML            ;See if there's more to print
                CMP     L
                LDA     XAMH
                SBC     H
                BCS     TONEXTITEM      ;Not less! No more data to output

                INC     XAML            ;Increment 'examine index'
                BNE     MOD8CHK         ;No carry!
                INC     XAMH

MOD8CHK         LDA     XAML            ;If address MOD 8 = 0 start new line
                AND     #$07
                BPL     NXTPRNT         ;Always taken.

;-------------------------------------------------------------------------
;  Subroutine to print a byte in A in hex form (destructive)
;-------------------------------------------------------------------------

PRBYTE          PHA                     ;Save A for LSD
                LSR
                LSR
                LSR                     ;MSD to LSD position
                LSR
                JSR     PRHEX           ;Output hex digit
                PLA                     ;Restore A

; Fall through to print hex routine

;-------------------------------------------------------------------------
;  Subroutine to print a hexadecimal digit
;-------------------------------------------------------------------------

PRHEX           AND     #$0F     	;Mask LSD for hex print
                ORA     #"0"            ;Add "0"
                CMP     #"9"+1          ;Is it a decimal digit?
                BCC     ECHO            ;Yes! output it
                ADC     #6              ;Add offset for letter A-F

; Fall through to print routine

;-------------------------------------------------------------------------
;  Subroutine to print a character to the terminal
;-------------------------------------------------------------------------
ECHO
	IFCONST	BLD4APPLE1
            BIT     MONDSP             	;DA bit (B7) cleared yet?
                BMI     ECHO            ;No! Wait for display ready
                STA     MONDSP             ;Output character. Sets DA
                RTS
	ELSE
		CMP	#$20
		BMI	ECHO1
		ORA	#$80
ECHO1
		JMP PUTCH		; use hi-res screen
	ENDIF

;-------------------------------------------------------------------------
;  Vector area
;-------------------------------------------------------------------------
	IFNCONST BLD4RAM
		ORG $fff8
                DC.W     $0000           ;Unused, what a pity
NMI_VEC         DC.W     $0F00           ;NMI vector
RESET_VEC       DC.W     RESET           ;RESET vector
IRQ_VEC         DC.W     $0000           ;IRQ vector
	ENDIF

;-------------------------------------------------------------------------


