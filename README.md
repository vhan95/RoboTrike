;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                            ;
;                                  RoboTrike                                 ;
;                           Functional Specification                         ;
;                                   EE/CS 51                                 ;
;                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Description
The system is a three-wheeled robot capable of holonomic motion that is 
controlled by a remote user interface board. 
The systems consists of two main boards: a remote board and a RoboTrike board.
The RoboTrike board is connected to three motors and a laser through parallel
I/O using a 82C55A programmable peripheral interface. The RoboTrike board and
the remote board are also connected through serial I/O using a TL16C450
asynchronous communications element.
All user interfacing is handled by the remote board, where the user can type
into a 16 key keypad, which will change the RoboTrike's motion or turn the
RoboTrike's laser on or off. Status info about the RoboTrike's motion or laser
status is displayed on the 8 digit LED display on this remote board whenever
the RoboTrike successfully completes a command sent to it. Error messages are
also displayed to the user whenever an error occurs. The messages will indicate
which board the error originates from, as well as which error occurred.
The RoboTrike's speed can be increased or decreased, and its direction of 
motion can be turned both left and right relative to its current direction.


Global Variables
None.


Inputs
The user can press keys on the keypad to change RoboTrike movement or chagne the
laser status.
There are 16 red keys on the external board in a 4x4 grid underneath the 
display. The following 4x4 grid represents what command of the keys stand for. 
        ____________ ____________ ____________ ____________
       |Move        |Turn Around |Turn Left   |Turn Right  |
       |____________|____________|____________|____________| 
       |Inc Speed   |Dec Speed   |Shift Left  |Shift Right |
       |____________|____________|____________|____________| 
       |Fire Laser  |Laser Off   |Do Nothing  |Do Nothing  |
       |____________|____________|____________|____________| 
       |Do Nothing  |Do Nothing  |Do Nothing  |Stop        |
       |____________|____________|____________|____________| 
       
The following describes each of these commands in more detail from left to right
and up to down. Pressing any keys simultaneously will result in no action.
    Move - Sets the RoboTrike speed to some constant initial speed
    Turn Around - Flips the RoboTrike's movement direction 180 degrees
    Turn Left - Changes the RoboTrike's direction to be 90 degrees to the left
    Turn Right - Changes the RoboTrike's direction to be 90 degrees to the right
    Inc Speed - Increases the RoboTrike's speed by some set amount. If the user
                attempts to increase the speed past the maximum speed, the 
                RoboTrike is just set to the max speed.
    Dec Speed - Decreases the RoboTrike's speed by some set amount. If the user
                attempts to decrease the speed below zero, the RoboTrike is just 
                set to zero speed.
    Shift Left - Changes the RoboTrike's direction to be 10 degrees to the left
    Shift Right - Changes the RoboTrike's direction to be 10 degrees to the 
                  right.
    Fire Laser - Turns the laser on
    Laser Off - Turns the laser off
    Do Nothing - Does nothing
    Stop - Sets the RoboTrike speed to zero. However, the direction of movement
           is not affected


Outputs
Laser - A laser is mounted on a turret on the robot. This laser can be toggled 
on and off by pressing the corresponding keys on the keypad. 
Display - There are 8 digits each with 14 segments with a right hand decimal 
point. This display is used to display the status of the RoboTrike as well as
error messages. The speed of the RoboTrike is displayed whenever it is changed.
The direction of the RoboTrike is displayed whenever it is changed. And error
messages are displayed whenever they are found on either the RoboTrike board or
the remote board. The error message will indicate which board it comes from and
what kind of error it is.
Motors - The movement of the robot is the main output. The motors move in ways 
that are predicted to fulfill the commands given. For example, if the robot is 
commanded to move forward, all of the motors move in tandem to attempt to 
produce this effect. Three DC motors are used to move the wheels.


User Interface
The user interface for this system is very simple. The user presses keys. These
keys then send commands to the RoboTrike board. Each time a command is executed,
status information is displayed back to the user. Speed status is reported if
speed was changed. Direction if direction was changed. Laser status if laser
status was changed. 
If there happens to be an error detected, the error type and the board of origin
are reported to the user through the display.


Error Handling
There are several types of errors that can be detected, and when any of them are
detected, they are reported to the user through the display with the error type
and board of origin. The specific error messages are defined in errortbl.asm.
Each type of error is described below.
Serial Overrun Error - Occurs when a received serial character is overwritten
                       before it was read
Serial Parity Error - Occurs when the parity is mismatched between the two 
                      serial sides
Serial Framing Error - Occurs when a received character does not have a valid
                       stop bit
Critical Error - Occurs when the system's EventQueue is full. The system then
                 needs to reset as it is losing too much data.
Unknown Error - Occurs when an unknown event is dequeued from the EventQueue
Parsing Error - Occurs when the RoboTrike board receives an invalid command
                string from the remote board


Algorithms
State Machine - A mealy state machine is used to parse command strings sent from
                the remote board to the RoboTrike board.


Data Structures
Queue - System events are stored in an EventQueue, which is repeatedly checked
        for events to be acted on. Examples of system events are keypresses,
        errors, and characters received over the serial connection. Each board
        has its own EventQueue.
        Queues are also used for storing characters waiting to be transmitted
        over the serial connection.


Limitations
Limited Feedback - The RoboTrike cannot keep track of its position or how far it 
has travelled. This is because its wheel motors are not equipped with encoders 
that allow them to keep track of how much they have rotated. Thus, only speed
and direction statuses can be displayed.
Wires - The robot is connected to the remote board via wires. Because of this, 
the robot will easily be caught in the wires, and thus is restrained in regards 
to some movements. For example, the robot cannot move and turn in the same 
direction very far otherwise it’ll get tangled in the wires. 
Small Display - The display is too small to display very easily readable 
information to a new user who does not understand how the system works.


Known Bugs
None.


Special Notes
None.
