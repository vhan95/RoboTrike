        NAME    CONVERTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   CONVERTS                                 ;
;                             Conversion Functions                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; File Description:
;     This file contains two functions: Dec2String and Hex2String. Functional
;     specifications and documentation are included. Both functions are number
;     conversion routines.
; Contents:
;     Dec2String: Converts signed value into a decimal representation and
;                 stores it as a string.
;     Hex2String  Converts unsigned value into a hexadecimal representation
;                 and stores it as a string.
;
; Revision History:
;     12/14/14 Victor Han       removed pseudocode, updated comments, and
;                               changed NULL_CHAR to ASCII_NULL
;     10/25/14 Victor Han       wrote assembly code for both functions.
;                               debugged until they worked as specified.
;     10/20/14 Victor Han       updated documentation for Dec2String and
;                               created initial revision for Hex2String
;     10/17/14 Victor Han       initial revision 
;     1/26/06  Glen George      created template


; local include files
$INCLUDE(general.inc)    ;general definitions such as ASCII_NULL
$INCLUDE(converts.inc)   ;definitions such as offsets for particular types of
                         ;  ASCII characters and resulting conversion decimal
                         ;  places


CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP




; Dec2String
;
; Description:      This function converts a 16-bit signed value into a decimal
;                   value. The 16-bit signed value is passed in AX by value and 
;                   an address to store the result is passed in SI by value.
;                   The resulting decimal value is stored as a string starting 
;                   at the given address. The string is a 5-digit <null> 
;                   terminated decimal representation of the value in ASCII
;                   with a char representing the sign in front.
;
; Operation:        In converting the 16-bit signed value, this function first
;                   determines whether the value is positive or negative. If it
;                   is negative, a negative sign character is stored and 
;                   the value is changed to its 2's complement. If it is
;                   positive, a positive sign is stored instead, and the value 
;                   is not changed. In order to do the conversion, the function
;                   now treats the value as an unsigned value to find its
;                   representation in decimal. To do this, the function
;                   repeatedly divides the value by decreasing powers of 10, 
;                   starting at 10^4 because this is the greatest power of 10 
;                   the input can be more than. In each iteration, the 
;                   resulting value of the division is a digit of the decimal 
;                   value corresponding to the power of 10 that it was divided 
;                   by. After storing this value, the remainder of the same 
;                   division is then used as the new value in the next 
;                   iteration. Once the power is less than 10^0, the loop ends 
;                   and we have our decimal representation of our value. 
;                   Throughout this process, the resulting decimal digits are 
;                   stored as chars, forming a string.
;
; Arguments:        AX - binary value to convert to decimal and store as a
;                        string.
;                   SI - starting address that the resulting string should be
;                        stored at.
; Return Value:     None.
;
; Local Variables:  digit (AX) - computed decimal digit.
;                   arg (BX)   - copy of passed signed binary value to convert.
;                   index (SI) - address to store the next char.
;                   pwr10 (CX) - current power of 10 being computed.
;                   array (DS) - segment where string is saved.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       Divide by largest power of 10 to get the first digit, take
;                   remainder and divide by next largest power of 10 to get next
;                   digit. Repeat until power of 10 is less than 10^0.
; Data Structures:  None.
;
; Registers Changed:flags, AX, BX, CX, DX, SI
; Stack Depth:      0 words.
;
; Known Bugs:       None.
; Limitations:      Only converts 16 bit unsigned values. Cannot convert values
;                   of larger magnitude.
;
; Author:           Victor Han
; Last Modified:    10/25/14


Dec2String      PROC        NEAR
                PUBLIC      Dec2String

                
Dec2StringInit:                        ;initialization
        MOV     BX, AX                 ;BX = arg
        MOV     CX, BIGGEST_DEC_DIGIT  ;start with 10^4 (10000's digit)
        TEST    BX, SIGN_BIT           ;test if sign bit is 1
        JS      WriteNegSign           ;write neg sign if sign bit is 1
        ;JMP    WritePosSign
        
        
WritePosSign:                          ;if sign bit was 0, write '+' char
        MOV     AL, '+'                ;temporarily store '+' at AX
        MOV     [SI], AL               ;write '+' char to DS:SI
        JMP     Dec2StringLoop         ;now start looping to get digits
        
        
WriteNegSign:                          ;if sign bit was 1, write '-' char
        MOV     AL, '-'                ;temporarily store '-' at AX
        MOV     [SI], AL               ;write '-' char to DS:SI
        NEG     BX                     ;need to change representation of arg to
                                       ;its positive equivalent to find digits
        ;JMP    Dec2StringLoop         ;now start looping to get digits
        
        
Dec2StringLoop:                        
        INC     SI                     ;increment SI to write at next location
        CMP     CX, 0                  ;check if power of 10 is greater than 0
        JLE     EndDec2StringLoop      ;if not, then have all digits and done
        ;JMP    Dec2StringLoopBody
                
                
Dec2StringLoopBody:                    ;get and write a digit
        MOV     AX, BX                 ;put arg into AX to be divided
        MOV     DX, 0                  ;set up for arg/pwr10 division
        DIV     CX                     ;digit (AX) = arg/pwr10
        ADD     AL, ASCII_NUM_OFFSET   ;get ASCII representation of digit
        MOV     [SI], AL               ;write ASCII digit to DS:SI
        MOV     BX, DX                 ;remainder of division is new arg
        MOV     AX, CX                 ;prepare to get next smaller power of 10
        MOV     CX, 10                 ;prepare to divide the power of 10 by 10
        MOV     DX, 0                  ;set up for arg/pwr10 division
        DIV     CX                     ;divide power of 10 by 10
        MOV     CX, AX                 ;set pwr10 to be result of division
        JMP     Dec2StringLoop         ;go back to check loop conditions
        
        
EndDec2StringLoop:                     ;loop is done     
        MOV     AL, ASCII_NULL          ;temporarily store null character
        MOV     [SI], AL               ;write ASCII null character at end
        RET                            ;return

        
Dec2String	ENDP




; Hex2String
;
; Description:      This function converts a 16-bit unsigned value into a hex
;                   value. The 16-bit signed value is passed in AX by value and 
;                   an address to store the result is passed in SI by value.
;                   The resulting hex value is stored as a string starting 
;                   at the given address. The string is a 4-digit <null> 
;                   terminated hexadecimal representation of the value in 
;                   ASCII.
;
; Operation:        In converting the 16-bit unsigned value, the function
;                   repeatedly divides the value by decreasing powers of 16, 
;                   starting at 16^3 because this is the largest the input can 
;                   be as it is 16 bits. In each iteration, the resulting value
;                   of the division is a digit of the hex value corresponding
;                   to the power of 16 that it was divided by. After storing 
;                   this value, the remainder of the same division is then
;                   used as the new value in the next iteration. Once the power
;                   is less than 16^0, the loop ends and we have our hex
;                   representation of our value. Throughout this process, the
;                   resulting hexadecimal digits are stored as chars, forming
;                   a string.
;
; Arguments:        AX - binary value to convert to hexadecimal and store as a
;                        string.
;                   SI - starting address that the resulting string should be
;                        stored at.
; Return Value:     None.
;
; Local Variables:  digit (AX) - computed hexadecimal digit.
;                   arg (BX)   - copy of passed unsigned value to convert.
;                   index (SI) - address to store the next char.
;                   pwr16 (CX) - current power of 16 being computed.
;                   array (DS) - segment where string is saved.
; Shared Variables: None.
; Global Variables: None.
;
; Input:            None.
; Output:           None.
;
; Error Handling:   None.
;
; Algorithms:       Divide by largest power of 16 to get the first digit, take
;                   remainder and divide by next largest power of 16 to get 
;                   next digit. Repeat until power of 16 is less than 16^0.
; Data Structures:  None.
;
; Registers Changed:flags, AX, BX, CX, DX, SI
; Stack Depth:      0 words.
;
; Known Bugs:       None.
; Limitations:      Cannot be used to convert numbers with more than 16 bits.
;
; Author:           Victor Han
; Last Modified:    10/25/14

Hex2String      PROC        NEAR
                PUBLIC      Hex2String
                
                
Hex2StringInit:                        ;initialization
        MOV     BX, AX                 ;BX = arg
        MOV     CX, BIGGEST_HEX_DIGIT  ;start with 16^3 (4th hex digit)
        ;JMP Hex2StringLoop
        
        
Hex2StringLoop:
        CMP     CX, 0                  ;check if power of 16 > 0
        JLE     EndHex2StringLoop      ;if not, then have all digits and done
        ;JMP    Hex2StringLoopBody
                
                
Hex2StringLoopBody:                    ;get a digit
        MOV     AX, BX                 ;put arg into AX to be divided
        MOV     DX, 0                  ;set up for arg/pwr16 division
        DIV     CX                     ;digit (AX) = arg/pwr16
        CMP     AX, 10                 ;check if digit is greater than 10
        JGE     WriteLetter            ;if so, then the hex value is a letter
        ;JMP    WriteNumber
        
   
WriteNumber:                           ;write a digit as an ASCII digit
        ADD     AL, ASCII_NUM_OFFSET   ;get ASCII representation of digit
        MOV     [SI], AL               ;write ASCII digit to DS:SI
        JMP     PrepareNextIteration   ;continue with the loop
        
        
WriteLetter:                           ;write a digit as an ASCII letter
        ADD     AL, ASCII_CHAR_OFFSET  ;get ASCII representation of digit
        MOV     [SI], AL               ;write ASCII digit to DS:SI
        ;JMP    PrepareNextIteration
        
       
PrepareNextIteration:                  ;update values for next loop iteration
        INC     SI                     ;increment SI to write at next location
        MOV     BX, DX                 ;remainder of division is new arg
        MOV     AX, CX                 ;prepare to get next smaller power of 16
        MOV     CX, 10h                ;prepare to divide the power of 16 by 16
        MOV     DX, 0                  ;set up for arg/pwr16 division
        DIV     CX                     ;divide power of 16 by 16
        MOV     CX, AX                 ;set pwr16 to be result of division
        JMP     Hex2StringLoop         ;go back to check loop conditions

        
EndHex2StringLoop:                     ;loop is done
        MOV     AL, ASCII_NULL          ;temporarily store null character
        MOV     [SI], AL               ;write ASCII null character at end
        RET                            ;return
        

Hex2String	ENDP



CODE    ENDS



        END
