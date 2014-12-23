        NAME    DISPLAY

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   DISPLAY                                  ;
;                              Display Functions                             ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; InitDisplay, Display, DisplayNum, DisplayHex, and DisplayMux functions. 
; These functions allow for the multiplexed display of strings and numbers
; on the RoboTrike controller's digits of LEDs when used in tandem with the 
; functions in timer.asm. The Display, DisplayNum, and DisplayHex functions 
; write a string to a string buffer. Each time the Timer0EventHandler (defined 
; in timer.asm) is then called, it calls the DisplayMux function which then 
; outputs the next digit in the buffer to the display.
; For numbers, DisplayNum displays in signed decimal and DisplayHex displays in
; hexadecimal.
;
; Contents:
;     InitDisplay: This function initializes the display by clearing the 
;                  display buffer.
;     Display: This function is passed a <null> terminated string that it then
;              writes to the display buffer.
;     DisplayMux: This function displays the next digit in the display buffer to 
;                 be displayed and is called by the timer0 event handler for
;                 multiplexing.
;     DisplayNum: This function is passed a 16-bit signed value to write to the
;                 display buffer in decimal to output to the LED display.
;     DisplayHex: This function is passed a 16-bit unsigned value to write to the
;                 display buffer in hexadecimal to output to the LED display.
;
; Revision History:
;    12/13/14  Victor Han       changed display to use 14-segments instead of 7
;    11/08/14  Victor Han       wrote the assembly and debugged until it worked
;    11/03/14  Victor Han       initial revision


; local include files
$INCLUDE(display.inc)             ;includes definitions for constants 


CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP


; external function declarations

        EXTRN   ASCIISegTable:BYTE        ;table of segment patterns for a
		                                  ;  seven segment display
		EXTRN   Dec2String:NEAR           ;converts a binary value to a string
		                                  ;  with its signed decimal 
										  ;  representation
		EXTRN   Hex2String:NEAR           ;converts a binary value to a string
		                                  ;  with its unsigned hexadecimal
										  ;  representation
		
		
; InitDisplay
;
; Description:       This function initializes the display (clears the display 
;                    buffer) and must be called before any other display 
;                    function. The display buffer is currentStr.
;
; Operation:         This function sets all the digits in the display buffer to
;                    be blank.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   CX - digit counter.
;                    DI - pointer to display buffer and specific position in it.
; Shared Variables:  currentStr - display buffer that we will initialize here
; Global Variables:  None.
;
; Input:             None.
; Output:            None. The DisplayMux function does the actual output.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AL, CX, DI, ES
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/08/14  Victor Han      wrote the assembly code
;    11/03/14  Victor Han      initial revision
; 

InitDisplay     PROC    NEAR
                PUBLIC  InitDisplay

StartInitDisplay:                       ;start clearing the display buffer
        MOV     CX, NUM_DIGITS          ;number of digits to clear
        PUSH    DS                      ;setup for storing segment patterns
        POP     ES                      ;want ES so can use STOSB later
        MOV     DI, OFFSET(currentStr)  ;ES:DI now points to currentStr
        CLD                             ;make sure do auto-increment
        MOV     AX, LED_BLANK           ;get the blank segment pattern
        
        REP  STOSW                      ;blank all the digits in display buffer
		
EndInitDisplay:                         ;done initializing the display buffer
        RET

InitDisplay     ENDP


; InitLEDMux
;
; Description:       This procedure initializes the variables used by the code
;                    that multiplexes the LED display. Only curMuxDigit is 
;                    initialized.
;
; Operation:         The digit number to be multiplexed next is reset.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  curMuxDigit - set to NUM_DIGITS.
; Global Variables:  None.
;
; Input:             None.
; Output:            None.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: None.
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/08/14  Victor Han      wrote the assembly code
;    11/03/14  Victor Han      initial revision

InitLEDMux      PROC    NEAR
                PUBLIC  InitLEDMux

        MOV    curMuxDigit, NUM_DIGITS ;initialize the digit to multiplex

EndInitLEDMux:                            ;done initializing multiplex operation
        RET                               ;  just return

InitLEDMux      ENDP


; Display
;
; Description:       This function is passed a <null> terminated string that 
;                    it then writes to the display buffer. By having the string
;                    in the display buffer, we are able to display it by muxing
;                    it with the function DisplayMux. The display buffer is 
;                    named currentStr.
;
; Operation:         The function gets the digits from the passed string and
;                    converts them to 7-segment patterns and stores them in
;                    the display buffer. If the string length is less than 
;                    NUM_DIGITS in length, the string is displayed starting from
;                    the leftmost digit and is padded with blanks on the right
;                    side. If the string is greater than NUM_DIGITS in length,
;                    it is truncated to NUM_DIGITS.
;
; Arguments:         ES:SI - address  of the string to be displayed
; Return Value:      None.
;
; Local Variables:   CX - digit counters.
;                    DI - pointer to display buffer and specific position in it.
; Shared Variables:  currentStr - written with segment patterns for passed string
; Global Variables:  None.
;
; Input:             None.
; Output:            The passed string is output to the LED display (indirectly
;                    via DisplayMux).
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AL, BX, CX, SI, DI, ES
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/08/14  Victor Han      wrote the assembly code
;    11/03/14  Victor Han      initial revision
;         

Display       PROC        NEAR
              PUBLIC      Display

StartDisplay:
        MOV      CX, 0                         ;start with the first digit
        ;JMP     GetDigitLoop                  
	
GetDigitLoop:                                  ;loop through the string, placing
                                               ;  its segment patterns in buffer
	    CMP      CX, NUM_DIGITS                ;truncate if more than NUM_DIGITS
                                               ;  chars
	    JE       DisplayDone                   ;truncate means done
        CMP      BYTE PTR ES:[SI], ASCII_NULL  ;if end of string 
	    JE       BlankTheRest                  ;  blank rest of buffer
        ;JNE     GetPattern                    ;if not, get pattern for digit
	
GetPattern:
        MOV      BL, ES:[SI]                   ;get char
        MOV      BH, 0
        SHL      BX, 1       ;word table
	    MOV      AX, WORD PTR ASCIISegTable[BX]                 ;get pattern
	    MOV      BX, CX                        ;setup to put pattern in buffer
        SHL      BX, 1
	    LEA      BX, currentStr[BX]
	    MOV      [BX], AX                      ;put pattern in buffer
	    INC      SI                            ;increment place-keeping values
        INC      CX
	    JMP      GetDigitLoop                  ;recheck loop conditions
    
BlankTheRest:                                  ;clear rest of buffer
        MOV     DI, CX                         ;start where we left off
        MOV     CX, NUM_DIGITS                 ;remaining digits to clear
		SUB     CX, DI
        SHL     DI, 1
        PUSH    DS                             ;want ES so can use STOSB later
        POP     ES                      
        ADD     DI, OFFSET(currentStr)         ;ES:DI now points to where we 
                                               ;  left off in currentStr
        CLD                                    ;make sure do auto-increment
        MOV     AX, LED_BLANK                  ;get the blank segment pattern

        REP  STOSW                             ;blank remaining digits in buffer
		
DisplayDone:
        RET                                    ;done
	
Display	ENDP


; DisplayMux
;
; Description:       This procedure multiplexes the LED display under
;                    interrupt control. It is meant to be called at a regular
;                    interval of about 1 ms. Each time it is called, it displays
;                    the next digit in currentStr and wraps if need be.
;
; Operation:         This procedure outputs the next digit (from the
;                    currentStr buffer) to the memory mapped LEDs each time
;                    it is called. To do this, it updates curMuxDigit by 
;                    decrementing it, resetting it to NUM_DIGITS-1 if it becomes
;                    negative, and then it uses curMuxDigit as an index for both
;                    the currentStr display buffer and the LED to output on. It
;                    outputs the correct digit from currentStr to its 
;                    corresponding LED. One digit is output each time the
;                    function is called.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   BX - pointer to stored segment patterns and physical
;                         LEDs.
; Shared Variables:  currentSegs - an element of the buffer is written to the
;                                  LEDs and the buffer is not changed.
;                    curMuxSeg   - used to determine which buffer element to
;                                  output and updated to the next buffer
;                                  element.
; Global Variables:  None.
;
; Input:             None.
; Output:            The next digit is output to its corresponding memory 
;                    mapped LED display.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AL, BX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    11/08/14  Victor Han      wrote the assembly code
;    11/03/14  Victor Han      initial revision
;         

DisplayMux          PROC    NEAR
                    PUBLIC  DisplayMux

StartLEDMux:                            ;first get digit to mux this time
        DEC     curMuxDigit          ;go to next digit
        JNS     GetDigitPatt            ;if wasn't last digit - output it
        ;JS     ResetMuxDigit           ;else was last digit

ResetMuxDigit:                          ;was on last digit, reset to start
        MOV     curMuxDigit, NUM_DIGITS - 1 ;reset value (subtract 1 for DEC 
                                               ;  should've done above)
        ;JMP    GetDigitPatt            ;and output the digit pattern

GetDigitPatt:                           ;first get the digit pattern to output
        MOV     BX, curMuxDigit        ;get the digit pattern
        SHL     BX, 1
        MOV     AX, currentStr[BX]     
        ;JMP    DisplayDigit            ;and output it to the display

DisplayDigit:                           ;output digit pattern to the display
        MOV     DX, LEDDisplay14Seg
        XCHG    AL, AH
        OUT     DX, AL                  ;output 14-segment area digit pattern
        MOV     DX, LEDDisplay          ;get address of LED digit
        MOV     BX, curMuxDigit
        ADD     DX, BX
        MOV     AL, AH
		OUT     DX, AL                  ;output 7-segment area digit pattern
        ;JMP    EndLEDMux               ;all done

EndDisplayMux:                              ;done multiplexing LEDs - return
        RET

DisplayMux          ENDP


; DisplayNum
;
; Description:          This function is passed a 16-bit signed value to output
;                       to the LED display in decimal. 5 digits plus sign will
;                       be placed into the display buffer curentStr to be 
;                       outputted via muxing. The first digit will always be a
;                       sign. However, due to limitations of the 7-segment 
;                       display, '+' signs will show up as blank. If the number
;                       is less than 5 digits long, it will be padded on the
;                       left with zeros. The final two LED digits on the right
;                       will be blank.
;
; Operation:            Calls the external function Dec2String with the string
;                       buffer convertBuff as the output location for the 
;                       function. Once the ASCII string representing our signed
;                       value is in the buffer, it is then passed to Display to
;                       be written to the display buffer currentStr.
;
; Arguments:            AX (n) - the number to display
;
; Return Value:         None.
;
; Local Variables:      None.
; Shared Variables:     None.
;
; Global Variables:     None.
;
; Input:                None.
; Output:               None.
;
; Error Handling:       None.
;
; Algorithms:           None.
; Data Structures:      None.
;
; Registers Changed:    flags, AX, BX, CX, DX, SI, ES
; Known Bugs:           None.
; Limitations:          None.
; Special Notes:        None.
;
; Revision History:     
;    11/08/14  Victor Han      wrote the assembly code
;    11/03/14  Victor Han      initial revision
;


DisplayNum          PROC    NEAR
                    PUBLIC  DisplayNum
					
CallDecFunctions:
        MOV      SI, OFFSET(convertBuff);use a buffer so that Dec2String doesn't
                                        ;  write to a random location
        PUSH     SI                     ;save SI because Dec2String changes it
        CALL     Dec2String             ;get the signed decimal string
	    PUSH     DS                     ;set ES to DS because Display uses ES
	    POP      ES
	    POP      SI
	    CALL     Display                ;fill the display buffer with the string
	
DisplayNumDone:
        RET

DisplayNum          ENDP


; DisplayHex
;
; Description:          This function is passed a 16-bit unsigned value to output
;                       to the LED display in hexadecimal. 4 digits will be 
;                       placed into the display buffer curentStr to be 
;                       outputted via muxing. If the number is less than 4 
;                       digits long, it will be padded on the left with zeros. 
;                       The final four LED digits on the right will be blank.
;
; Operation:            Calls the external function Hex2String with the string
;                       buffer convertBuff as the output location for the 
;                       function. Once the ASCII string representing our unsigned
;                       value is in the buffer, it is then passed to Display to
;                       be written to the display buffer currentStr.
;
; Arguments:            AX (n) - the number to display
;
; Return Value:         None.
;
; Local Variables:      None.
; Shared Variables:     None.
;
; Global Variables:     None.
;
; Input:                None.
; Output:               None.
;
; Error Handling:       None.
;
; Algorithms:           None.
; Data Structures:      None.
;
; Registers Changed:    flags, AX, BX, CX, DX, SI, ES
; Known Bugs:           None.
; Limitations:          None.
; Special Notes:        None.
;
; Revision History:     
;    11/08/14  Victor Han      wrote the assembly code
;    11/03/14  Victor Han      initial revision
;


DisplayHex          PROC    NEAR
                    PUBLIC  DisplayHex
					
CallHexFunctions:
        MOV      SI, OFFSET(convertBuff);use a buffer so that Hex2String doesn't
                                        ;  write to a random location
        PUSH     SI                     ;save SI because Hex2String changes it
        CALL     Hex2String             ;get the unsigned hexadecimal string
	    PUSH     DS                     ;set ES to DS because Display uses ES
	    POP      ES
	    POP      SI
	    CALL     Display                ;fill the display buffer with the string
	
DisplayHexDone:
        RET

DisplayHex          ENDP


CODE    ENDS


;the data segment

DATA    SEGMENT PUBLIC  'DATA'

convertBuff    DB      NUM_DIGITS DUP (?) ;buffer holding the resulting strings
                                          ;  from the Dec2String and Hex2String
                                          ;  number to string convert functions

currentStr     DW      NUM_DIGITS DUP (?) ;buffer holding currently displayed 
                                          ;  segment patterns

curMuxDigit    DW      ?             ;current digit/LED number being multiplexed

DATA    ENDS


        END
