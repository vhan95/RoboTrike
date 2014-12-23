        NAME  SEGTAB14

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   SEGTAB14                                 ;
;                           Tables of 14-Segment Codes                       ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains tables of 14-segment codes.  The segment ordering is a to
; p followed by the decimal point with segment a in the low bit (bit 0) and
; segment p in bit 14 (the decimal point is in bit 7 for backward
; compatibility with 7-segment displays).  Bit 15 (high bit) is always zero
; (0).  The tables included are:
;    ASCIISegTable - table of codes for 7-bit ASCII characters
;    DigitSegTable - table of codes for hexadecimal digits
;
; Revision History:
;    12/6/95   Glen George              initial revision (from 11/7/95 version
;                                          of segtable.asm) 
;    12/7/95   Glen George              fixed patterns for 'D' and '1'
;    10/26/98  Glen George              updated comments
;    12/26/99  Glen George              changed segment name from PROGRAM to
;                                          CODE
;                                       added CGROUP group declaration
;                                       updated comments
;    12/25/00  Glen George              updated comments
;     2/6/05   Glen George              fixed/changed patterns for 'S', 'o',
;                                          'y' and '3'



; local include files
;    none




;setup code group and start the code segment
CGROUP  GROUP   CODE

CODE    SEGMENT PUBLIC 'CODE'




; ASCIISegTable
;
; Description:      This is the segment pattern table for ASCII characters.
;                   It contains the active-high segment patterns for all
;                   possible 7-bit ASCII codes.  Codes which do not have a
;                   "reasonable" way of being displayed on a 14-segment
;                   display are left blank.  None of the codes set the decimal
;                   point.  Some of the lowercase letters look identical to
;                   their uppercase equivalents and all lowercase letters with
;                   descenders are actually placed above the baseline.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Author:           Glen George
; Last Modified:    Dec. 7, 1995

ASCIISegTable   LABEL   BYTE
                PUBLIC  ASCIISegTable


;       DW       pmlkhgn.jfedcba                ;ASCII character

        DW      0000000000000000B               ;NUL
        DW      0000000000000000B               ;SOH
        DW      0000000000000000B               ;STX
        DW      0000000000000000B               ;ETX
        DW      0000000000000000B               ;EOT
        DW      0000000000000000B               ;ENQ
        DW      0000000000000000B               ;ACK
        DW      0000000000000000B               ;BEL
        DW      0000000000000000B               ;backspace
        DW      0000000000000000B               ;TAB
        DW      0000000000000000B               ;new line
        DW      0000000000000000B               ;vertical tab
        DW      0000000000000000B               ;form feed
        DW      0000000000000000B               ;carriage return
        DW      0000000000000000B               ;SO
        DW      0000000000000000B               ;SI
        DW      0000000000000000B               ;DLE
        DW      0000000000000000B               ;DC1
        DW      0000000000000000B               ;DC2
        DW      0000000000000000B               ;DC3
        DW      0000000000000000B               ;DC4
        DW      0000000000000000B               ;NAK
        DW      0000000000000000B               ;SYN
        DW      0000000000000000B               ;ETB
        DW      0000000000000000B               ;CAN
        DW      0000000000000000B               ;EM
        DW      0000000000000000B               ;SUB
        DW      0000000000000000B               ;escape
        DW      0000000000000000B               ;FS
        DW      0000000000000000B               ;GS
        DW      0000000000000000B               ;AS
        DW      0000000000000000B               ;US

;       DW       pmlkhgn.jfedcba                ;ASCII character

        DW      0000000000000000B               ;space
        DW      0000000000000000B               ;!
        DW      0000001000000010B               ;"
        DW      0000000000000000B               ;#
        DW      0001001101101101B               ;$
        DW      0000000000000000B               ;percent symbol
        DW      0000000000000000B               ;&
        DW      0000000000000010B               ;'
        DW      0000000000111001B               ;(
        DW      0000000000001111B               ;)
        DW      0111111101000000B               ;*
        DW      0001001101000000B               ;+
        DW      0000000000000000B               ;,
        DW      0000000101000000B               ;-
        DW      0000000000000000B               ;.
        DW      0010010000000000B               ;/
        DW      0000000000111111B               ;0
        DW      0001001000000000B               ;1
        DW      0000000101011011B               ;2
        DW      0000000001001111B               ;3
        DW      0000000101100110B               ;4
        DW      0000000101101101B               ;5
        DW      0000000101111101B               ;6
        DW      0010010000000001B               ;7
        DW      0000000101111111B               ;8
        DW      0000000101100111B               ;9
        DW      0000000000000000B               ;:
        DW      0000000000000000B               ;;
        DW      0000110000000000B               ;<
        DW      0000000101001000B               ;=
        DW      0110000000000000B               ;>
        DW      0001000001000011B               ;?

;       DW       pmlkhgn.jfedcba                ;ASCII character

        DW      0001000001011111B               ;@
        DW      0000000101110111B               ;A
        DW      0001001001001111B               ;B
        DW      0000000000111001B               ;C
        DW      0001001000001111B               ;D
        DW      0000000100111001B               ;E
        DW      0000000100110001B               ;F
        DW      0000000001111101B               ;G
        DW      0000000101110110B               ;H
        DW      0001001000001001B               ;I
        DW      0000000000011110B               ;J
        DW      0000110100110000B               ;K
        DW      0000000000111000B               ;L
        DW      0100010000110110B               ;M
        DW      0100100000110110B               ;N
        DW      0000000000111111B               ;O
        DW      0000000101110011B               ;P
        DW      0000100000111111B               ;Q
        DW      0000100101110011B               ;R
        DW      0000000101101101B               ;S
        DW      0001001000000001B               ;T
        DW      0000000000111110B               ;U
        DW      0100100000000110B               ;V
        DW      0010100000110110B               ;W
        DW      0110110000000000B               ;X
        DW      0101010000000000B               ;Y
        DW      0010010000001001B               ;Z
        DW      0000000000111001B               ;[
        DW      0100100000000000B               ;\
        DW      0000000000001111B               ;]
        DW      0000000000000000B               ;^
        DW      0000000000001000B               ;_

;       DW       pmlkhgn.jfedcba                ;ASCII character

        DW      0000000000100000B               ;`
        DW      0001000100011000B               ;a
        DW      0000000101111100B               ;b
        DW      0000000101011000B               ;c
        DW      0000000101011110B               ;d
        DW      0000000101111011B               ;e
        DW      0000000100110001B               ;f
        DW      0000000101101111B               ;g
        DW      0000000101110100B               ;h
        DW      0001000000000000B               ;i
        DW      0000000000001110B               ;j
        DW      0000110100110000B               ;k
        DW      0001001000000000B               ;l
        DW      0001000101010100B               ;m
        DW      0000000101010100B               ;n
        DW      0000000101011100B               ;o
        DW      0000000101110011B               ;p
        DW      0000000101100111B               ;q
        DW      0000000101010000B               ;r
        DW      0000000101101101B               ;s
        DW      0000000100111000B               ;t
        DW      0000000000011100B               ;u
        DW      0000100000000100B               ;v
        DW      0001000000011100B               ;w
        DW      0110110000000000B               ;x
        DW      0000000101101110B               ;y
        DW      0010010000001001B               ;z
        DW      0000000000000000B               ;{
        DW      0001001000000000B               ;|
        DW      0000000000000000B               ;}
        DW      0000000000000001B               ;~
        DW      0000000000000000B               ;rubout




; DigitSegTable
;
; Description:      This is the segment pattern table for hexadecimal digits.
;                   It contains the active-high segment patterns for all hex
;                   digits (0123456789ABCDEF).  None of the codes set the
;                   decimal point.  
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Author:           Glen George
; Last Modified:    Dec. 7, 1995

DigitSegTable   LABEL   BYTE
                PUBLIC  DigitSegTable


;       DW       pmlkhgn.jfedcba                ;Hex Digit

        DW      0000000000111111B               ;0
        DW      0001001000000000B               ;1
        DW      0000000101011011B               ;2
        DW      0000110100001001B               ;3
        DW      0000000101100110B               ;4
        DW      0000000101101101B               ;5
        DW      0000000101111101B               ;6
        DW      0010010000000001B               ;7
        DW      0000000101111111B               ;8
        DW      0000000101100111B               ;9
        DW      0000000101110111B               ;A
        DW      0001001001001111B               ;B
        DW      0000000000111001B               ;C
        DW      0001001000111001B               ;D
        DW      0000000100111001B               ;E
        DW      0000000100110001B               ;F




CODE    ENDS



        END
