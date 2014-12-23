        NAME    QUEUE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                   QUEUE                                    ;
;                             Queue Functions                                ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; This file contains the functional specifications and implementations for the
; QueueInit, QueueEmpty, QueueFull, Dequeue, and Enqueue functions. These 
; functions together create and modify a queue data structure.
;
; Contents:
;     QueueInit:    initializes a queue of specified element size of bytes or 
;                   words at a particular address.
;     QueueEmpty:   returns whether a queue at a particular address is
;                   empty or not.
;     QueueFull:    returns whether a queue at a particular address is
;                   full or not.
;     Dequeue:      removes and returns the top element of a queue at a
;                   particular address.
;     Enqueue:      adds a passed in element to a queue at a particular
;                   address.
;
; Revision History:
;    12/14/14  Victor Han       updated comments
;    12/13/14  Victor Han       no longer has a length passed in by argument
;                               and changed some instructions to better reflect
;                               what they are doing
;    11/01/14  Victor Han       wrote the assembly code for the functions and
;                               debugged until they worked.
;    10/27/14  Victor Han       created functional specification for QueueEmpty,
;                               QueueFull, Dequeue, and Enqueue. Also completed
;                               functional specification for QueueInit.
;    10/25/14  Victor Han       initial revision
;     1/26/06  Glen George      created template


; local include files
$INCLUDE(queue.inc)             ; includes definitions for constants and the
                                ; struct containing the queue


CGROUP  GROUP   CODE


CODE	SEGMENT PUBLIC 'CODE'


        ASSUME  CS:CGROUP




; QueueInit
;
; Description:          This function initializes a queue. Given an element
;                       size and a starting address, this function prepares
;                       an empty queue that is ready for use. The element
;                       size can be either a byte or a word.
;
; Operation:            This function creates a struct with data values 
;                       representing the head of the queue, the tail of the
;                       queue, the size of an element in the queue, and the 
;                       actual data. 
;                       The elem_size data value is set to the value determined 
;                       by the element size argument. The head and tail data 
;                       values are both set to 0.
;                       The length data value is set to MAX_SIZE.
;
; Arguments:            BL (s) - Element size. If BL is non-zero, then the 
;                                elements of the queue are words. 
;                                Otherwise, they are bytes. 
;                       SI (a) - The address that the queue should start at.
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
; Data Structures:      A queue implemented using an array.
;
; Registers Changed:    flags
;
; Known Bugs:           None.
; Limitations:          The queue is set to be length MAX_SIZE in bytes.
;                       The queue cannot hold elements that are sizes other than
;                       bytes or words.
; Special Notes:        None.
;
; Author:               Victor Han
; Revision History:
;    12/14/14  Victor Han       updated comments
;    11/01/14  Victor Han       wrote the assembly code and debugged until it 
;                               worked.
;     

QueueInit       PROC        NEAR
                PUBLIC      QueueInit
				
InitializeHeadTail:                    ; set the head and tail to their initial
                                       ; values
	MOV      [SI].head, 0              ; head initially points at the first
                                       ; byte of the data array
	MOV      [SI].tail, 0              ; tail initially points at the first 
                                       ; byte of the data array
	TEST     BL, BL                    ; check if BL is non-zero
	JNZ      SetSizeWord               ; if so, the element size is a word
	;JMP     SetSizeByte
	
SetSizeByte:                           ; set the element size to be a byte
	MOV      [SI].elem_size, BYTE_SIZE ; set the elem_size field of the struct
	JMP      SetLength                 ; now go to set the length field
	
SetSizeWord:                           ; set the element size to be a word
    MOV      [SI].elem_size, WORD_SIZE ; set the elem_size field of the struct
    ;JMP     SetLength

SetLength:                             ; set the length field of the struct
	MOV      [SI].len, MAX_SIZE      
	;JMP EndQueueInit
	
EndQueueInit:	                       ; done
	RET

QueueInit	ENDP




; QueueEmpty
;
; Description:          This function checks if a queue at a particular address
;                       is empty or not. If it is empty, the zero flag is set.
;                       If not, the zero flag is reset.
;
; Operation:            This function checks if the head and tail values of the
;                       queue are equal. If so, then the queue is empty. If not,
;                       then the queue is not empty.
;
; Arguments:            SI (a) - The address of the queue to check.
;
; Return Value:         ZF (zero_flag) - set if the queue is empty. reset if
;                                        not.
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
; Registers Changed:    flags, DX
;
; Known Bugs:           None.
; Limitations:          None.
; Special Notes:        None.
;
; Author:               Victor Han
; Revision History:
;    12/14/14  Victor Han       updated comments
;    11/01/14  Victor Han       wrote the assembly code and debugged until it 
;                               worked.
;     

QueueEmpty      PROC        NEAR
                PUBLIC      QueueEmpty
				
TestIfEmpty:
    MOV     DX, [SI].head              
	CMP     DX, [SI].tail              ; check if [SI].head and [SI].tail are
                                       ; different. If so, ZF is not set. If not,
                                       ; ZF is set
	;JMP    EndQueueEmpty

EndQueueEmpty:                         ; done checking
	RET

QueueEmpty	ENDP




; QueueFull
;
; Description:          This function checks if a queue at a particular address
;                       is full or not. If it is full, the zero flag is set.
;                       If not, the zero flag is reset.
;
; Operation:            This function checks if the the tail value plus one
;                       element size modulus the length of the queue is equal 
;                       to the head value. That is, it checks if
;                           (tail + elem_size) MOD len == head
;                       If so, then the queue is full and the zero flag is set.
;                       If not, then the queue is not full and the zero flag
;                       is reset. The modulus is to account for wrapping around
;                       the data array size.
;
; Arguments:            SI (a) - The address of the queue to check.
;
; Return Value:         ZF (zero_flag) - set if the queue is full. reset if
;                                        not.
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
; Registers Changed:    flags, AX, BX, DX
;
; Known Bugs:           None.
; Limitations:          None.
; Special Notes:        None.
;
; Author:               Victor Han
; Revision History:
;    12/14/14  Victor Han       updated comments
;    11/01/14  Victor Han       wrote the assembly code and debugged until it 
;                               worked.
;     

QueueFull       PROC        NEAR
                PUBLIC      QueueFull

TestQueueFull:
    MOV      BX, AX                    ; temporarily store AX in BX
    MOV      AX, [SI].tail             ; start readying value to divide
    ADD	     AX, [SI].elem_size        ; value to divide is tail + elem_size
	MOV      DX, 0                     ; ready DX for division
	DIV      [SI].len                  ; divide the increased tail by the length
	CMP      DX, [SI].head             ; if this value is equal to head, then
                                       ; set the zero flag. If not, don't.
	MOV      AX, BX                    ; move the temp value back
	;JMP     EndQueueFull
	
EndQueueFull:                          ; done checking
	RET

QueueFull	ENDP




; Dequeue
;
; Description:          This function removes the top element of the queue at 
;                       the specified address and returns it in AL or AX 
;                       depending on the size of elements in the queue. AL for
;                       byte sized elements and AX for word sized elements.
;                       If the queue is empty when this function is called, this
;                       function does not return until an element is removed
;                       from the queue.
;
; Operation:            While the QueueEmpty function says that the queue is
;                       empty, this function waits and does nothing. If the
;                       QueueEmpty function says that the queue is not empty,
;                       this function sets the element at the head index of the
;                       queue's qdata array to AX or AL depending on the size
;                       of the element. Once it is done with doing that,
;                       this function adds one element size to the head value 
;                       of the queue and then takes that value modulus the 
;                       length of the queue in bytes. This provides wrapping
;                       around the data array length if need be.
;                       That is,
;                           head = (head + elem_size) MOD len
;
; Arguments:            SI (a) - The address of the queue to remove from.
;
; Return Value:         AX (w_value) - the element previously at the head of the
;                                      queue. The full AX register is the value
;                                      if the queue held word sized elements.
;                                      Only AL is used if the queue held byte
;                                      sized elements.
;                       AL (b_value) - the element previously at the head of the
;                                      queue. The full AX register is the value
;                                      if the queue held word sized elements.
;                                      Only AL is used if the queue held byte
;                                      sized elements.
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
; Registers Changed:    flags, AX, BX, CX, DX
;
; Known Bugs:           None.
; Limitations:          None.
; Special Notes:        None.
;
; Author:               Victor Han
; Revision History:
;    12/14/14  Victor Han       updated comments
;    11/01/14  Victor Han       wrote the assembly code and debugged until it 
;                               worked.
;     

Dequeue         PROC        NEAR
                PUBLIC      Dequeue

BlockIfEmpty:                          ; prevent action until the queue has an
                                       ; element. That is, can dequeue
	CALL     QueueEmpty                ; check if the queue is empty
	JZ       BlockIfEmpty              ; if so, check again
	;JMP     DequeueCheckElementSize   ; if not, continue to dequeue
	
DequeueCheckElementSize:               ; check what size element to remove
    TEST     [SI].elem_size, BYTE_SIZE ; test if the element size is a byte
	JNZ      RemoveByte                ; if so, remove a byte
	;JMP     RemoveWord                ; if not, remove a word
	
RemoveWord:                            ; remove a word
    MOV      BX, [SI].head             ; move for addressing
    MOV      CL, [SI].qdata[BX]        ; get the byte at the head of the queue
	MOV      CH, [SI].qdata[BX+1]      ; get the next byte too because we want
                                       ; a word
	JMP      EndDequeue                ; done
	
RemoveByte:                            ; remove a byte
    MOV      BX, [SI].head             ; move for addressing
    MOV      CL, [SI].qdata[BX]        ; get the byte at the head of the queue
	;JMP     EndDequeue
	
EndDequeue:                            ; move head forward one elem_size and 
                                       ; wrap around the data array if need to
    MOV      AX, [SI].head             ; begin moving value to take the modulus
                                       ; of
	ADD      AX, [SI].elem_size        ; move head forward one elem_size
	MOV      DX, 0                     ; prepare DX for division
	DIV      [SI].len                  ; find the modulus to wrap if need be
    MOV      [SI].head, DX             ; set head to this wrapped value
	MOV      AX, CX                    ; move the dequeued value to the return
                                       ; register
	RET                                ; done

Dequeue	ENDP




; Enqueue
;
; Description:          This function adds an element to the queue at a 
;                       specified address. The added element can be 8-bits or
;                       16-bits depending on the element size that the queue
;                       holds. If the queue is full when this function is 
;                       called, this function waits until the queue is not full
;                       before taking action.
;
; Operation:            While the QueueFull function says that the queue is
;                       full, this function waits and does nothing. If the
;                       QueueFull function says that the queue is not full,
;                       this function sets the address at the tail index of the
;                       queue's qdata array to AX or AL depending on the size
;                       of the queue's elements. Once it is done doing that,
;                       this function adds one element size to the tail value 
;                       of the queue and then takes that value modulus the 
;                       length of the queue. This provides wrapping around the
;                       data array if need be.
;                       That is,
;                           tail = (tail + elem_size) MOD len
;
; Arguments:            SI (a)   - The address of the queue to add to.
;                       AX (w_v) - Value to add to the queue if the queue
;                                  element size is words.
;                       AL (b_v) - Value to add to the queue if the queue
;                                  element size is bytes.
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
; Registers Changed:    flags, AX, BX, DX
;
; Known Bugs:           None.
; Limitations:          None.
; Special Notes:        None.
;
; Author:               Victor Han
; Revision History:
;    12/14/14  Victor Han       updated comments
;    11/01/14  Victor Han       wrote the assembly code and debugged until it 
;                               worked.
;     

Enqueue         PROC        NEAR
                PUBLIC      Enqueue
				
BlockIfFull:                           ; do not allow action unless can enqueue
	CALL     QueueFull                 ; check if there is space
	JZ       BlockIfFull               ; if not, check again
	;JMP     EnqueueCheckElementSize   ; if so, then can start enqueue-ing
	
EnqueueCheckElementSize:               ; check what element size should be added
    TEST     [SI].elem_size, BYTE_SIZE ; test if its a byte
	JNZ      AddByte                   ; if so, then add a byte
	;JMP     AddWord                   ; if not, then add a word
	
AddWord:                               ; enqueue a word
    MOV      BX, [SI].tail             ; move for addressing
    MOV      [SI].qdata[BX], AL        ; add the low byte of the word to the
                                       ; tail of the queue
	MOV      [SI].qdata[BX+1], AH      ; add the rest of the value to the next
                                       ; byte
	JMP      EndEnqueue                ; done adding
	
AddByte:
    MOV      BX, [SI].tail             ; move for addressing
    MOV      [SI].qdata[BX], AL        ; add the byte to the tail of the queue
	;JMP     EndEnqueue                ; done adding
	
EndEnqueue:                            ; update the tail value and wrap it if
                                       ; need be
	MOV      AX, [SI].tail             ; prepare the new tail value for mod
	ADD      AX, [SI].elem_size        ; make AX the unwrapped new tail value
	MOV      DX, 0                     ; prepare DX for division
	DIV      [SI].len                  ; take the modulus for wrapping
    MOV      [SI].tail, DX             ; move the wrapped result to tail
	RET                                ; done

Enqueue	ENDP


CODE    ENDS



        END
