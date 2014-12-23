;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  SERIAL.INC                                ;
;                             Serial I/O Functions                           ;
;                                 Include File                               ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; This file contains the definitions for the serial I/O functions (serial.asm). 
; Included are constants regarding the accessible registers of the TL16C450
; asynchronous communications element, serial I/O shared variable values, and
; more specific properties of serial I/O such as parity settings, baud rate
; divisor, and number of possible errors.
;
; Revision History:
;    12/14/14   Victor Han    removed SET_BYTE
;    12/02/14   Victor Han    updated comments
;    11/28/14   Victor Han    initial revision

; Addresses

SERIAL_ADDR             EQU     0100H            ;base serial element address
LCR_ADDR                EQU     SERIAL_ADDR + 3  ;line control register address
IER_ADDR                EQU     SERIAL_ADDR + 1  ;interrupt enable register addr
IIR_ADDR                EQU     SERIAL_ADDR + 2  ;interrupt identification 
                                                 ;  register address
TRANS_HOLD_ADDR         EQU     SERIAL_ADDR + 0  ;transmitter holding register addr
RECEIVER_BUFF_ADDR      EQU     SERIAL_ADDR + 0  ;receiver buffer register addr
LINE_STATUS_ADDR        EQU     SERIAL_ADDR + 5  ;line status register address
DIV_LATCH_LSB_ADDR      EQU     SERIAL_ADDR + 0  ;divisor latch (LSB) address
DIV_LATCH_MSB_ADDR      EQU     SERIAL_ADDR + 1  ;divisor latch (MSB) address

; Register Values

INIT_IER_VAL            EQU     00000111B  ;initial IER value set to enable all
                                           ;  interrupts except modem status
                                           ;0000---- reserved
                                           ;----0--- disable modem status int
                                           ;-----1-- enable receiver line status int
                                           ;------1- enable trans hold reg empty int
                                           ;-------1 enable received data avail int
INIT_LCR_VAL            EQU     00000011B  ;initial LCR val set to have a max size
                                           ;  word, least stop bits, and no parity
                                           ;0------- DLAB not set
                                           ;-0------ Don't set break
                                           ;--xx---- Parity options
                                           ;----0--- Disable parity
                                           ;-----0-- 1 stop bit
                                           ;------11 8 bit word length
BAUD_DIVISOR_9600       EQU     60         ;divisor needed for a 9600 baud rate
                                           ;  assuming a 9.216MHz clock
DLAB_SET                EQU     10000000B  ;OR this with hte LCR val to set the 
                                           ;DLAB bit
DISABLE_TRANS_EMPTY_INT EQU     11111101B  ;AND this is the IER value to disable
                                           ;  the trans hold reg empty interrupt
INTERRUPT_PENDING       EQU     00000001B  ;used to test the interrupt pending bit
                                           ;  from the IIR

; Parity

ALL_PARITY_BITS_OFF     EQU     11100011B  ;AND this with the LCR value to disable
                                           ;  all parity bits
EVEN_PARITY             EQU     00011000B  ;OR this is the LCR val to enable even
                                           ;  parity after using ALL_PARITY_BITS_OFF
ODD_PARITY              EQU     00010000B  ;OR this is the LCR val to enable odd
                                           ;  parity after using ALL_PARITY_BITS_OFF
SPACE_PARITY            EQU     00011100B  ;OR this is the LCR val to enable space
                                           ;  parity after using ALL_PARITY_BITS_OFF
MARK_PARITY             EQU     00010100B  ;OR this is the LCR val to enable mark
                                           ;  parity after using ALL_PARITY_BITS_OFF

; Shared Variable Defintions

NEED_KICKSTART          EQU     1          ;indicates that the enable transmitter
                                           ;  holding register empty interrupt
                                           ;  needs to be kickstarted
NOT_NEED_KICKSTART      EQU     0          ;indicates that the enable transmitter
                                           ;  holding register empty interrupt
                                           ;  does not need to be kickstarted

; Flow Control

NUM_ERRORS              EQU     3          ;used to determine the max index for
                                           ;  iterating through possible serial
                                           ;  I/O errors                                           