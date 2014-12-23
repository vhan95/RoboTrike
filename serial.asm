        NAME    SERIAL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    SERIAL                                  ;
;                               SERIAL Functions                             ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; InitSerial, SerialPutChar, SerialPutString, SetSerialBaudRate, SetSerialParity,  
; and INT2EventHandler functions. Together, these functions allow for serial I/O
; when used with the INT2 interrupt.
;
; Contents:
;     SerialInit: Initializes serial I/O software and shared variables.
;     SerialPutChar: Outputs the passed character to the serial channel.
;     SerialPutString: Outputs the passed NULL terminated string over serial.
;     SetSerialBaudRate: Sets the serial baud rate.
;     SetSerialParity: Sets the serial parity.
;     INT2EventHandler: Handles events from the serial element such as a 
;                       received character, errors, and an empty transmitter.
;
; Revision History:
;    12/14/14  Victor Han       updated comments
;    12/13/14  Victor Han       added SerialPutString
;    12/02/14  Victor Han       updated comments
;    11/28/14  Victor Han       wrote the assembly code
;    11/24/14  Victor Han       initial revision

; local include files
$INCLUDE(general.inc)    ; includes general definitions such as ASCII_NULL
$INCLUDE(serial.inc)     ; includes definitions for serial register addresses
                         ;   and values, as well as shared variable definitions. 
$INCLUDE(int2.inc)       ; includes definitions for the INT2 EOI 
$INCLUDE(queue.inc)      ; includes the queue struct definition

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA

CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        EXTRN   QueueInit:NEAR    ;initializes the transmit queue TransQueue
        EXTRN   QueueFull:NEAR    ;checks if TransQueue is full
        EXTRN   Enqueue:NEAR      ;adds a character to TransQueue
        EXTRN   QueueEmpty:NEAR   ;checks if TransQueue is empty
        EXTRN   Dequeue:NEAR      ;removes a character from TransQueue
        EXTRN   EnqueueEvent:NEAR ;saves received serial characters and errors
                                  ;  on an event queue
        
		
; InitSerial
;
; Description:       Initializes serial I/O software and shared variables. No 
;                    parity is set, the baud rate divisor is set to 
;                    BAUD_DIVISOR_9600, the transmit queue TransQueue is 
;                    initialized with byte sized elements, all serial interrupts
;                    are enabled, except for modem status interrupts, and
;                    the KickStartNeeded shared variable is set to 
;                    NOT_NEED_KICKSTART. Max data bits and min stop bits are 
;                    also set.
;
; Operation:         The appropriate values are written to the registers. LCR is
;                    written to to set up the data bits, stop bits, and no parity.
;                    SetSerialBaudRate is called to set the baud rate. QueueInit
;                    is called to set up the queue. IER is written to to enable
;                    the right interrupts.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  TransQueue - written to
;                    KickStartNeeded - written to
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
; Registers Changed: flags, AX, BX, DX, SI
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/02/14  Victor Han       updated comments
;    11/28/14  Victor Han       wrote the assembly code
;    11/23/14  Victor Han       initial revision

InitSerial      PROC    NEAR
                PUBLIC  InitSerial
        
        MOV     DX, LCR_ADDR                 ;set up num data bits, stop bits
        MOV     AL, INIT_LCR_VAL             ;  no parity
        OUT     DX, AL
        
        MOV     AX, BAUD_DIVISOR_9600        ;set up baud rate
        CALL    SetSerialBaudRate

        MOV     SI, OFFSET(TransQueue)       ;initialize TransQueue
        MOV     BL, SET_BYTE_SIZE
        CALL    QueueInit
        
        MOV     DX, IER_ADDR                 ;enable all serial interrupts except 
        MOV     AX, INIT_IER_VAL             ;  modem status
        OUT     DX, AL
        
        MOV     KickStartNeeded, NOT_NEED_KICKSTART  ;not initially needed
        
        RET

InitSerial      ENDP


; SerialPutChar
;
; Description:       The function outputs the passed character (c) to the serial 
;                    channel. It returns with the carry flag reset if the 
;                    character has been "output" (put in the channel’s queue, 
;                    not necessarily sent over the serial channel) and set 
;                    otherwise (transmit queue is full). The character (c) is 
;                    passed by value in AL.
;
; Operation:         Checks if TransQueue is full. If so, set teh carry flag
;                    and return. If not, enqueue the character and kickstart the
;                    transmitter holding register empty interrupt if needed.
;
; Arguments:         AL (c) - character to output to the serial channel.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  TransQueue - read and written to
;                    KickStartNeeded - read and written to
; Global Variables:  None.
;
; Input:             None.
; Output:            A character output to the serial channel indirectly through
;                    INT2EventHandler.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, CX, DX, SI
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:   
;    12/02/14  Victor Han      updated comments
;    11/28/14  Victor Han      wrote the assembly code  
;    11/24/14  Victor Han      initial revision


SerialPutChar       PROC    NEAR
                    Public  SerialPutChar

        MOV     CX, AX                   ;QueueFull changes AX, so save it
        MOV     SI, OFFSET(TransQueue)
        CALL    QueueFull                ;see if can add to TransQueue
        MOV     AX, CX
        JZ      CannotPutChar            ;if can't, set carry flag
        ;JNZ    PutChar

PutChar:
        MOV     SI, OFFSET(TransQueue)   ;if can, do it
        CALL    Enqueue
        CMP     KickStartNeeded, NEED_KICKSTART  ;see if the enable transmitter
                                                 ;  register requires action
        JNE     ClearCarryFlag                   ;if not, done
        ;JE     Kickstart

Kickstart:                                       ;if so, do the kickstart
                                                 ;  this makes it generate a new
                                                 ;  interrupt, which will make
                                                 ;  the handler pick up our char
                                                 ;  and transmit it
        MOV     KickStartNeeded, NOT_NEED_KICKSTART 
        MOV     DX, IER_ADDR                     ;read in IER and only change
        IN      AL, DX                           ;  ETBE bit
        MOV     BX, AX
        AND     AL, DISABLE_TRANS_EMPTY_INT
        OUT     DX, AL
        MOV     AX, BX
        OUT     DX, AL
        JMP     ClearCarryFlag                   ;done

CannotPutChar:
        STC                            ;set carry flag to indicate failure to 
                                       ;  send char over serial
        JMP     SerialPutCharDone

ClearCarryFlag:
        CLC                            ;clear carry flag to indicate success
        
SerialPutCharDone:
        RET
		
SerialPutChar       ENDP


; SerialPutString
;
; Description:       This function is passed a <null> terminated string that 
;                    it then outputs over the serial channel.
;
; Operation:         The function repeatedly gets characters from the passed
;                    string and calls SerialPutChar on them. If the character is
;                    ASCII_NULL, it sends over an ASCII_NULL character and stops.
;
; Arguments:         ES:SI - address of the string to be sent over serial
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
; Global Variables:  None.
;
; Input:             None.
; Output:            The passed string is output to the serial channel through
;                    SerialPutChar.
;
; Error Handling:    None.
;
; Algorithms:        None.
; Data Structures:   None.
;
; Registers Changed: flags, AX, BX, CX, DX, SI
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/13/14  Victor Han      initial revision
;         

SerialPutString     PROC        NEAR
                    PUBLIC      SerialPutString

SerialPutStringLoop:
        CMP      BYTE PTR ES:[SI], ASCII_NULL  ;if end of string 
	    JE       SerialPutStringEnd            ;done
        ;JNE     SerialPutStringSendChar       ;if not, get next char
	
SerialPutStringSendChar:
        MOV      AL, ES:[SI]                   ;get char
        PUSH     SI
        PUSH     AX
        
SerialPutStringCallPutChar:
        CALL     SerialPutChar                 ;send char over serial
        JC       SerialPutStringCallPutChar    ;if fail, gotta try again
        ;JNC     SerialPutStringSendCharCont
        
SerialPutStringSendCharCont:
        POP      AX
        POP      SI
	    INC      SI                            ;increment place-keeping values
	    JMP      SerialPutStringLoop           ;recheck loop conditions
    
SerialPutStringEnd:
        MOV      AL, ASCII_NULL                ;terminate string
        CALL     SerialPutChar
        RET                                    ;done
	
SerialPutString	ENDP


; SetSerialBaudRate
;
; Description:       Sets the serial baud rate given a baud rate divisor as
;                    an argument.
;
; Operation:         Disables interrupts because this is very critical code.
;                    Sets the DLAB bit on the LCR to access the divsor latch
;                    registers and write the baud rate divisor to them. Finally
;                    resets the DLAB bit.
;
; Arguments:         AX - desired baud rate divisor
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
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
; Registers Changed: AX, BX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/02/14  Victor Han      updated comments
;    11/28/14  Victor Han      wrote the assembly code 
;    11/24/14  Victor Han      initial revision

SetSerialBaudRate   PROC    NEAR
                    Public  SetSerialBaudRate

        CLI                            ;critical code protection
        
        MOV     BX, AX
        MOV     DX, LCR_ADDR
        IN      AL, DX 
        PUSH    AX
        OR      AL, DLAB_SET
        OUT     DX, AL                  ;allow access to divisor latch registers
        
        MOV     AX, BX                  ;set the registers to the divisor
        MOV     DX, DIV_LATCH_LSB_ADDR
        OUT     DX, AL
        
        XCHG    AL, AH
        MOV     DX, DIV_LATCH_MSB_ADDR
        OUT     DX, AL
        
        POP     AX                      ;return register access to normal
        MOV     DX, LCR_ADDR
        OUT     DX, AL
        
        STI                             ;done with critical code                            
        
        RET
               
SetSerialBaudRate   ENDP


; SetSerialParity
;
; Description:       Sets the serial parity. Can be set to no parity, even parity,
;                    odd parity, space parity, or mark parity respectively 
;                    depending on the value of AX. AX indexes the types in that
;                    order, starting from zero.
;
; Operation:         Sets the parity bits of LCR to set the parity settings
;                    corresponding to the value of AX.
;
; Arguments:         AX - index indicating which kind of paroty should be set.
;                         Determined by the Parity_Jump_Table.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  None.
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
; Registers Changed: flags, AX, BX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/02/14  Victor Han      updated comments
;    11/28/14  Victor Han      wrote the assembly code 
;    11/24/14  Victor Han      initial revision

SetSerialParity     PROC    NEAR
                    Public  SetSerialParity

        MOV     BX, AX                     ;update LCR parity bits
        MOV     DX, LCR_ADDR
        IN      AL, DX
        AND     AL, ALL_PARITY_BITS_OFF    ;start from a blank parity state
        SHL     BX, 1                      ;for indexing of word table
        JMP     CS:Parity_Jump_Table[BX]   ;set appropriate parity settings
        
SetNoParity:
        JMP     SetSerialParityDone
        
SetEvenParity:
        OR      AL, EVEN_PARITY
        JMP     SetSerialParityDone
        
SetOddParity:
        OR      AL, ODD_PARITY
        JMP     SetSerialParityDone
        
SetSpaceParity:
        OR      AL, SPACE_PARITY
        JMP     SetSerialParityDone
        
SetMarkParity:
        OR      AL, MARK_PARITY
        ;JMP    SetSerialParityDone
        
SetSerialParityDone:
        OUT     DX, AL
        RET
        
SetSerialParity     ENDP


; INT2EventHandler
;
; Description:       This procedure handles serial I/O related interrupts. If
;                    the transmitter holding register is empty, gets a new char
;                    from the TransQueue to transmit. If there is no new char,
;                    KickstartNeeded is set. If data is received, it is put
;                    into the event queue. If errors are reported, they are
;                    also put into the event queue.
;
; Operation:         Pushes all the registers, checks the interrupt type, and
;                    uses a jump table to execute the appropriate action. If the 
;                    interrupt is a transmitter empty interrupt, takes a char
;                    from TransQueue if it is not empty. If it is empty, sets
;                    the KickstartNeeded variable. Received data is handled
;                    eith EnqueueEvent. Errors are handled by looping through 
;                    the error bits from the line status register and calling
;                    EnqueueEvent for each error bit set. The function loops,
;                    checking interrupts as long as there is an interrupt 
;                    pending. When there isn't, sends an EOI, pops the registers,
;                    and returns.
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  TransQueue - read and written to
;                    KickstartNeeded - written to
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
; Registers Changed: flags, AX, BX, DX, SI
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/02/14  Victor Han      updated comments
;    11/28/14  Victor Han      wrote the assembly code 
;    11/24/14  Victor Han      initial revision

INT2EventHandler       PROC    NEAR
                       Public  INT2EventHandler

        PUSHA                             ;interrupt handlers should not change
                                          ;  register values
        
INT2EventHandlerLoop:
        MOV     DX, IIR_ADDR              ;loop while there is an interrupt 
        IN      AL, DX                    ;  pending
        TEST    AL, INTERRUPT_PENDING
        JNZ     INT2EventHandlerDone      ;if no more, done
        ;JZ     CheckInterruptType

CheckInterruptType:
        CBW                               ;prepare for jump table indexing
        MOV     BX, AX  
        JMP     CS:INT2Event_Jump_Table[BX] ;goto label corresponding to int type

HandleModemStatus:
        NOP                             ;we don't handle modem status interrupts
        JMP     INT2EventHandlerLoop

HandleTransmitterEmpty:
        MOV     SI, OFFSET(TransQueue)  ;check if there is another char to transmit
        CALL    QueueEmpty
        JZ      SetKickstartVar         ;if not, next time there is, ETBE needs 
        ;JNZ    TransmitVal             ;  a kickstart

TransmitVal:
        MOV     SI, OFFSET(TransQueue)  ;if there is, get it and transmit it
        CALL    Dequeue
        MOV     DX, TRANS_HOLD_ADDR
        OUT     DX, AL
        JMP     INT2EventHandlerLoop    ;handle next interrupt if any
        
SetKickStartVar:
        MOV     KickstartNeeded, NEED_KICKSTART ;indicate that a kickstart is needed
        JMP     INT2EventHandlerLoop            ;handle next interrupt if any

HandleReceivedData:
        MOV     DX, RECEIVER_BUFF_ADDR  ;get received chars and enqueue them in
        IN      AL, DX                  ;  the event queue for later use
        MOV     AH, BL
        CALL    EnqueueEvent
        JMP     INT2EventHandlerLoop

HandleReceiverStatus:
        MOV     DX, LINE_STATUS_ADDR  ;get register indicating which errors
        IN      AL, DX
        MOV     AH, BL
        MOV     BX, NUM_ERRORS
        ;JMP    ErrorCheckLoop

ErrorCheckLoop:
        DEC     BX                    ;individually check if each error bit is set
        JS      INT2EventHandlerLoop
        ;JNS    CheckError

CheckError:
        TEST    AL, CS:Error_Table[BX]
        JZ      ErrorCheckLoop
        ;JNZ    EnqueueError

EnqueueError:
        PUSH    AX                   ;put error in event queue if there is one
        MOV     AL, BL
        PUSH    BX
        CALL    EnqueueEvent
        POP     BX
        POP     AX
        JMP     ErrorCheckLoop

INT2EventHandlerDone:
        MOV     DX, INTCtrlrEOI   ;send a INT2 EOI (to clear out controller)
        MOV     AX, INT2_EOI
        OUT     DX, AL
        POPA
        IRET
		
INT2EventHandler       ENDP


; INT2Event_Jump_Table 
;
; Description:      Determines flow logic for responding to a serial interrupt
;                   type in the INT2EventHandler function. The serial interrupt 
;                   type used as an index allows for jumps to the right label.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    12/02/14  Victor Han      updated comments
;    11/22/14  Victor Han      initial revision

INT2Event_Jump_Table    LABEL   WORD
                        PUBLIC  INT2Event_Jump_Table


;       DW         label                     ;IIR lowest three bits
			
        DW         HandleModemStatus         ; 000B interrupt type
        DW         HandleTransmitterEmpty    ; 010B interrupt type
        DW         HandleReceivedData        ; 100B interrupt type
        DW         HandleReceiverStatus      ; 110B interrupt type

        
; Parity_Jump_Table 
;
; Description:      Determines flow logic for responding to the argument for the
;                   SetSerialParity function. The argument to the function 
;                   multiplied by two serves as the index for this table to
;                   go to the appropriate action.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    12/02/14  Victor Han      updated comments
;    11/22/14  Victor Han      initial revision

Parity_Jump_Table       LABEL   WORD
                        PUBLIC  Parity_Jump_Table
                        
;       DW         label
			
        DW         SetNoParity         ; AX is 0
        DW         SetEvenParity       ; AX is 1
        DW         SetOddParity        ; AX is 2
        DW         SetSpaceParity      ; AX is 3
        DW         SetMarkParity       ; AX is 4

; Error_Table 
;
; Description:      Bits to check in the line status register's value 
;                   corresponding to errors being raised. Used in a loop in
;                   INT2EventHandler.
;
; Notes:            READ ONLY tables should always be in the code segment so
;                   that in a standalone system it will be located in the
;                   ROM with the code.
;
; Revision History:
;    12/02/14  Victor Han      updated comments
;    11/22/14  Victor Han      initial revision

Error_Table         LABEL   BYTE
                    PUBLIC  Error_Table
                        
;       DB         byte to AND      ;Errror Type
            
        DB         00000010B        ; Overrun Error
        DB         00000100B        ; Parity Error
        DB         00001000B        ; Framing Error



CODE    ENDS

DATA    SEGMENT PUBLIC  'DATA'

TransQueue          QUEUE <>      ;the transmit queue. used to hold characters
                                  ;  as they wait to be send over the serial port

KickstartNeeded     DB      ?     ;indicates whether or not the enable transmitter
                                  ;  holding register empty interrupt needs to
                                  ;  be kickstarted to be fired again

DATA    ENDS

        END