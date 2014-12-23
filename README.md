This code is the embedded software for the RoboTrike system.

The system is a three-wheeled robot capable of holonomic motion that is 
controlled by a remote user interface board. 
The systems consists of two main boards: a remote board and a RoboTrike board.
The RoboTrike board is connected to three motors and a laser through parallel
I/O using a 82C55A programmable peripheral interface. The RoboTrike board and
the remote board are also connected through serial I/O using a TL16C450
asynchronous communications element. Both boards use an Intel 80188 
microprocessor.
All user interfacing is handled by the remote board, where the user can type
into a 16 key keypad, which will change the RoboTrike's motion or turn the
RoboTrike's laser on or off. Status info about the RoboTrike's motion or laser
status is displayed on the 8 digit LED display on this remote board whenever
the RoboTrike successfully completes a command sent to it. Error messages are
also displayed to the user whenever an error occurs. The messages will indicate
which board the error originates from, as well as which error occurred.
The RoboTrike's speed can be increased or decreased, and its direction of 
motion can be turned both left and right relative to its current direction.

Operational details can be found in RoboTrike_functional_specification.txt.
