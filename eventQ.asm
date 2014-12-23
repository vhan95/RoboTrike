        NAME    eventQ

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                    EVENTQ                                  ;
;                            Event Queue Functions                           ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; InitEventQueue, EnqueueEvent, EventQueueEmpty, DequeueEvent, InitCritError,
; SetCritError, and GetCritError functions. Together, these functions initialize 
; the EventQueue and CritError and allow for the necessary reading and writing
; of these variables. 
;
; Contents:
;     InitEventQueue: Initializes the EventQueue.
;     EnqueueEvent: Enqueues an event onto the EventQueue if it has room, and 
;                   sets CritError if not.
;     EventQueueEmpty: Checks if the EventQueue is empty.
;     DequeueEvent: Pops the event on the top of the EventQueue.
;     InitCritError: Initializes CritError to FALSE.
;     SetCritError: Sets CritError to the passed in value.
;     GetCritError: Gets the current CritError value.
;
; Revision History:
;    12/08/14  Victor Han       initial revision

; local include files
$INCLUDE(general.inc) 
$INCLUDE(queue.inc)             ; includes definitions for constants for queues                            

CGROUP  GROUP   CODE
DGROUP  GROUP   DATA


CODE	SEGMENT PUBLIC 'CODE'

        ASSUME  CS:CGROUP, DS:DGROUP
        
        EXTRN   QueueInit:NEAR
        EXTRN   QueueEmpty:NEAR
        EXTRN   QueueFull:NEAR
        EXTRN   Dequeue:NEAR
        EXTRN   Enqueue:NEAR
        
; InitEventQueue
;
; Description:       Initializes the EventQueue.
;
; Operation:         Calls the QueueInit function on the EventQueue.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  EventQueue - written to
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
; Registers Changed: AX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/08/14  Victor Han      initial revision

InitEventQueue      PROC    NEAR
                    PUBLIC  InitEventQueue
        
        MOV     SI, OFFSET(EventQueue)
        MOV     BX, SET_WORD_SIZE
        CALL    QueueInit
        RET
        
InitEventQueue      ENDP


; EnqueueEvent
;
; Description:       Enqueues the passed in event into the EventQueue or sets
;                    the CritError shared variable if it cannot.
;
; Operation:         Checks if the EventQueue is full by calling QueueFull. If
;                    it is full, sets the CritError shared variable. If not,
;                    calls Enqueue with the passed in character.
;
; Arguments:         AL - an event to enqueue into the EventQueue.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  EventQueue - read and written to
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
; Registers Changed: AX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/08/14  Victor Han      initial revision
;
; Pseudocode
; if(QueueFull(EventQueue))
;     CritError = TRUE
; else
;     Enqueue(EventQueue, AL)

EnqueueEvent     PROC    NEAR
                 PUBLIC  EnqueueEvent
        
        PUSH    AX
        MOV     SI, OFFSET(EventQueue)
        CALL    QueueFull
        POP     AX
        JNZ     EnqueueEventEnqueue
        ;JZ     EnqueueEventCritError
        
EnqueueEventCritError:
        MOV     CritError, TRUE
        JMP     EnqueueEventEnd
        
EnqueueEventEnqueue:
        MOV     SI, OFFSET(EventQueue)
        CALL    Enqueue
        ;JMP    EnqueueEventEnd
        
EnqueueEventEnd:
        RET
        
EnqueueEvent     ENDP

; EventQueueEmpty
;
; Description:       Checks if the EventQueue is empty.
;
; Operation:         Calls the QueueEmpty function on the EventQueue.
;
; Arguments:         None.
; Return Value:      ZF - set if empty, reset if not
;
; Local Variables:   None.
; Shared Variables:  EventQueue - read
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
; Registers Changed: AX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/08/14  Victor Han      initial revision

EventQueueEmpty      PROC    NEAR
                     PUBLIC  EventQueueEmpty
                     
        MOV     SI, OFFSET(EventQueue)
        CALL    QueueEmpty
        RET
        
EventQueueEmpty      ENDP

; DequeueEvent
;
; Description:       Removes an event from the EventQueue and returns it.
;
; Operation:         Calls the Dequeue function on the EventQueue.
;
; Arguments:         None.
; Return Value:      AL - the event on the top of the EventQueue
;
; Local Variables:   None.
; Shared Variables:  EventQueue - read and written to
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
; Registers Changed: AX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/08/14  Victor Han      initial revision

DequeueEvent         PROC    NEAR
                     PUBLIC  DequeueEvent
        
        MOV     SI, OFFSET(EventQueue)
        CALL    Dequeue
        RET
        
DequeueEvent         ENDP

; InitCritError
;
; Description:       Initializes CritError to FALSE.
;
; Operation:         Sets CritError to FALSE.
;
; Arguments:         None.
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  CritError - written to
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
; Registers Changed: AX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/08/14  Victor Han      initial revision

InitCritError        PROC    NEAR
                     PUBLIC  InitCritError
                     
        MOV     CritError, FALSE
        RET
        
InitCritError        ENDP

; SetCritError
;
; Description:       Sets CritError to the passed in value.
;
; Operation:         Sets CritError to AX.
;
; Arguments:         AX - the value to set CritError to
; Return Value:      None.
;
; Local Variables:   None.
; Shared Variables:  CritError - written to
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
; Registers Changed: AX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/08/14  Victor Han      initial revision

SetCritError         PROC    NEAR
                     PUBLIC  SetCritError
                     
        MOV     CritError, AX
        RET
        
SetCritError         ENDP

; GetCritError
;
; Description:       Returns the CritError status.
;
; Operation:         Returns CritError in AX.
;
; Arguments:         None.
; Return Value:      AX - the current CritError value.
;
; Local Variables:   None.
; Shared Variables:  CritError - read
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
; Registers Changed: AX, DX
; Known Bugs:        None.
; Limitations:       None.
; Special Notes:     None.
;
; Revision History:     
;    12/08/14  Victor Han      initial revision

GetCritError         PROC    NEAR
                     PUBLIC  GetCritError
        
        MOV     AX, CritError
        RET
        
GetCritError         ENDP

CODE    ENDS


;the data segment

DATA    SEGMENT PUBLIC  'DATA'

EventQueue           QUEUE <>        
CritError            DW         ?

DATA    ENDS

        END