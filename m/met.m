% 
% 
% [ ... ] = met ( metfun , ... )
% 
% 
% Matlab Electrophysiology Toolbox interface function. This allows a
% program written in Matlab to send or receive MET signals, and to read or
% write to POSIX shared memory.
% 
% The interface of met is similar to that of many Psych Toolbox functions,
% in that the first argument to met is always a string that names which
% function to use. The number and type of input and output arguments other
% than that is function-dependent.
% 
% In the MET environment, separate Matlab processes are created, and each
% one becomes a MET controller. These communicate with a central MET server
% controller to send and receive synchronising MET signals ; the server
% controller is responsible for creating each Matlab process, and is
% executed using the metgo program from the system command line. To move
% bulk data, shared memory can be accessed directly by specified
% controllers. Together, MET controllers provide all the functionality
% required to run an electrophysiological experiment.
% 
% To make full use of met functions requires familiarity with the concept
% of blocking and non-blocking input-output operations. This refers to
% whether or not an operation will wait for a chance to complete itself or
% not. For example, if 'recv' is run in blocking mode, then the program
% will wait until at least one MET signal has been broadcast. On the other
% hand, if run in non-blocking mode, 'revc' would return immediately if no
% new signals were available.
% 
% By blocking, or waiting with 'select', a program can synchronise itself
% with other MET controllers. With non-blocking, or timed calls to
% 'select', a controller is free to continue what it was doing. One can see
% how this is critical for a MET controller that uses Psych Toolbox to
% generate visual stimuli in step with the progress of a trial. Blocking on
% MET signals could be useful to synchronise with the start of the trial.
% But non-blocking would be critical during a trial, when regular calls to
% Screen ( 'flip' , ... ) must occur.
%
% Note that all functions rely on 'open' having been run during
% initialisation of the MET controller. These functions will not work,
% otherwise. Normally, this is done automatically by metcontroller.m before
% the MET controller function is executed.
% 
% The usual order of events in the life of a MET controller are as follows.
% metgo is executed from the system command line. This interprets the .cmet
% file that specifies what MET controllers to create, and passes arguments
% to metserver, a binary executable. metserver obtains all inter-process
% communication resources and then forks child processes, afterwards
% becomming the central MET signal server that synchronises all child MET
% controllers.
%
% Each child process executes PsychToolbox Matlab (ptb3-matlab). Once
% Matlab has finished loading, it runs metcontroller in order to prepare
% the local MET environment, this involves running met( 'open' ) and then
% running the MET controller function that was listed in the .cmet file.
% The controller function performs any required initialisation then sends
% an mready reply MET signal i.e. an mready signal with cargo 2 ; this
% tells the MET server controller (metserver) that initialisation is
% complete. The MET server controller requires all child MET controllers to
% signal the end of their initialisation. When all child MET controllers
% have completed initialisation, then the MET server sends an mwait init
% MET signal i.e. has cargo 1.
%
% Afterwards, trials are initiated when an mready trigger MET signal is
% broadcast i.e. mready with cargo 1. This puts all controllers into a
% trial initialisation state, where any preparation for the next trial is
% performed. When each MET controller is finished preparing, it sends an
% mready reply and waits. The trial itself begins when an mstart signal is
% broadcast ; only the MET server is allowed to generate an mstart, and it
% does so once all MET controllers have signalled the end of their trial
% initialisation.
% 
% During a trial, mstate MET signals are sent every time the task logic has
% transitioned to a new state. mtarget MET signals indicate when the
% subject has selected a new stimulus. mrdtype and mreward signals set the
% type and size of rewards for the subject. Some signals are valid whether
% or not a trial is running, such as mrdtype and mreward.
%
% An mstop signal is sent at the end of a trial, its cargo giving the
% outcome. Alternatively, an mwait signal may arrive during a trial. The
% cargo value will be either 1 or 2. The former value allows the current
% trial to run to completion, the latter value aborts the trial
% immediately. In both cases, a new trial can only be started manually by
% the experimenter. If an mquit signal is ever received then a MET
% controller is required to shut down immediately, whether a trial is
% running or not.
%
% Except for mstart, there is no restriction to which MET signals are
% created by which MET controllers. This is left to the discretion of the
% experimenter. Consequently, so is the way each MET controller interprets
% MET signals.
% 
% 
% Available function names are:
% 
%     'send' - Send MET signal requests to the MET server controller.
%    'write' - Write Matlab variables to named shared memory.
%     'recv' - Receive MET signals broadcast by the MET server controller.
%     'read' - Read Matlab variables from named shared memory.
%   'select' - Wait for new MET signals and shared mem read/write access.
%    'print' - Print to standard output , error, and or a log file.
%    'flush' - Flush the standard output stream.
%   'logopn' - Open a new log file.
%   'logcls' - Close currently open log file.
%     'open' - Obtain MET-specific resources from the system.
%    'close' - Release MET-specific resources and send closing signal.
%    'const' - Return MET constants, both compile and run-time.
% 
% The order matters. Function names are checked against the list in this
% order. Therefore, the least latency is required to run 'send', and the
% most latency is taken to run 'const'.
% 
% 
% Function descriptions:
% 
% 
% n = met ( 'send' , sig , crg , tim , blk )
% 
% Sends MET signal requests to the MET server controller. Up to the atomic
% write limit of signals can be sent, while the ith signal has MET signal
% identifier sig( i ), cargo crg( i ), and time tim( i ). All signals have
% a source value of the calling controller's controller descriptor. Returns
% the number of MET signals that were sent. sig, crg, and tim must be
% Matlab type double matrices. blk is optional ; if non-zero then a
% blocking write is performed on the request pipe. Otherwise, a
% non-blocking write is performed. If tim is an empty double i.e. [] then
% 'send' takes a time measurement and supplies this to all requested
% signals.
%
% 
% i = met ( 'write' , shm , ... )
% 
% Writes a set of Matlab arrays to the POSIX shared memory named by shm.
% All arguments provided after shm are written as a separate array. Returns
% 1 if all data is successfully written, or 0 if nothing was written ;
% throws an error, otherwise.
% 
% The shm string may be prefixed by one optional character, either '+' or
% '-', to indicate the blocking mode. If '+' is prefixed then 'write'
% blocks on the shared memory until the data can be written. If '-' is
% prefixed then the function immediately returns 0 if data can not be
% written ; this is the default action when no character is prefixed.
% 
% Data can be written only when all N readers of the named shared memory
% have posted 1 to the corresponding readers' event fd i.e. when all
% readers have read the current contents of the named shared memory. A
% blocking write fails as an error if the calling controller is also a
% reader of the shared memory.
% 
% Only struct, cell, char, logical, and numeric arrays may be written. Take
% heed , nested arrays in a struct or cell must be one of these types. Full
% matrices only, no sparse.
% 
% For versions 00.XX.XX and 01.XX.XX of MET, valid strings for shm are:
% 
%   'stim' - Stimulus variable parameter shared memory.
%    'eye' - Eye position shared memory.
%    'nsp' - Neural signal processor shared memory.
% 
%   e.g. blocking write to eye shm done by passing '+eye' and non-blocking
%   writes done by passing '-eye' or simply 'eye'.
% 
% 
% [ n , src , sig , crg , tim ] = met ( 'recv' , blk )
% 
% Receives MET signals from the MET server controller. The number of
% signals received is returned in n, with a value of 0 up to the MET signal
% atomic read/write limit. For the ith received signal, the source
% controller, signal identifier, cargo, and time are returned in src( i ),
% sig( i ), crg( i ), and tim( i ). By default, all reads are non-blocking.
% A non-blocking read when no MET signals are available will return n with
% a value of zero, and all other output arguments will be empty i.e. [].
% blk is an optional argument ; if non-zero then a blocking read is
% performed , non-blocking if zero.
% 
% 
% C = met ( 'read' , shm )
% 
% Reads Matlab arrays from the POSIX shared memory named by shm into cell
% array C. If the shared memory contains N arrays, then C will have N
% elements each contain one array, in the order that they were written.
% Returns an empty cell array if nothing was read.
% 
% The shm string may be prefixed by one optional character, either '+' or
% '-', to indicate the blocking mode. If '+' is prefixed then 'read'
% blocks on the shared memory until data has been written. If '-' is
% prefixed then the function immediately returns {} if there is no new
% data ; this is the default action when no character is prefixed.
% 
% A blocking read fails as an error if the calling controller is also a
% writer to the shared memory.
% 
% For versions 00.XX.XX and 01.XX.XX of MET, valid strings for shm are:
% 
%   'stim' - Stimulus variable parameter shared memory.
%    'eye' - Eye position shared memory.
%    'nsp' - Neural signal processor shared memory.
% 
%   e.g. blocking write to eye shm done by passing '+eye' and non-blocking
%   writes done by passing '-eye' or simply 'eye'.
% 
% 
% [ tim , msig , shm ] = met ( 'select' , tout )
% 
% Waits for any MET inter-process communication resources to be ready for
% reading/writing. Times out after at least tout seconds ; if not provided,
% or if empty i.e. [] then the function waits indefinitely. If MET signals
% are ready to be received with 'recv' then msig is 1 , otherwise it is 0.
% If N actions on POSIX shared memory are possible then cell array shm is
% returned with N rows and 2 columns ; if no actions are possible, then shm
% is an empty cell array i.e. {}. Each row of shm will contain the name of
% the shared memory in column 1 and the action that can be performed on it
% in column 2, given as a single char that is either 'r' for reading or 'w'
% for writing. A PsychToolbox-style time stamp is provided in tim, in
% seconds, which is taken immediately prior to returning.
% 
% For versions 00.XX.XX and 01.XX.XX of MET, valid names in shm col 1 are:
% 
%   'stim' - Stimulus variable parameter shared memory.
%    'eye' - Eye position shared memory.
%    'nsp' - Neural signal processor shared memory.
% 
% 
% met ( 'print' , str , out )
% 
% Prints string str to standard output if out is 'o' or standard error if
% out is 'e'. Written to standard output by default if out is omitted. If
% out is 'l' i.e. lower-case letter L then the string is written to only
% the current log file. If out is 'L' i.e. upper-case letter L then the
% string is written to both standard output and the current log file ; but
% if out is 'E' then the string is written to standard error and the log
% file. For options 'L' and 'E', if there is no open log file then
% the message is only printed to the terminal, as if 'o' or 'e' had been
% given ; for 'l', nothing happens. A newline is appended to the end of
% str.
% 
% 
% met ( 'flush' )
% met ( 'flush' , s )
% 
% Forces the standard output stream to write its contents to standard
% output i.e. the terminal window. This allows a series of met 'print'
% commands to be run with either the 'l' or 'L' option without writing to
% standard output each time. Instead, print commands are buffered in the
% standard output stream until the flush command is called, resulting in a
% single write to standard output. This can result in improved performance.
% The stream for any open log file is also flushed. Standard output and the
% logfile streams are both flushed by default. Optional input argument s is
% a single character saying which stream to flush. If it is 'b' then both
% streams are flushed, if 'o' then only standard output is flushed, of if
% 'l' (lower-case L) then only the log-file stream is flushed.
% 
% 
% met ( 'logopn' , n )
% 
% Creates a new log file with name taken from string n. All subsequent
% calls to met 'print' with out option 'l', 'L', or 'E' will write to this
% file. If a log file is already open when logopn is called then it will be
% closed before the new one is opened. If file n already exists, then it is
% appended to.
% 
% 
% met ( 'logcls' )
% 
% Closes the currently open log file. Silently returns if there is no open
% log file.
% 
% 
% MC = met ( 'open' , 
%                cd , stdofd , pfd , shmflg , shmnr , refd , wefd , wefdv )
% 
% Opens and initialises met. The standard output file descriptor is
% restored. POSIX shared memory is opened and mapped. A pointer for the
% HOME environment variable is obtained. The controller's descriptor and
% pipe file descriptors are stored. Returns a Matlab struct of MET
% constants, including MET signals, MET files, and MET error codes. This
% function is normally called by metcontroller.m. In the order listed,
% input arguments are the controller descriptor, duplicate standard output
% file descriptor, pipe file descriptors, shared memory flags, shared
% memory names, readers' (r) and writer's (w) event file descriptors, and
% writer's event file descriptor vector.
% 
% 
% met ( 'close' )
% met ( 'close' , keep )
% 
% Attempts to close any sytem resources used by met. This includes the
% broadcast and request pipe file descriptors, mapped POSIX shared memory,
% event file descriptors, and any open log file. An optional scalar numeric
% value can be provided in keep which, if non-zero, keeps the file
% descriptors open ; only the POSIX shared memory is unmapped, and the log
% file is closed. The field values of RTCONS are reset as resources are
% closed. Memory is freed, pointers are made NULL, and file descriptors are
% made FDINIT. Before closing the request pipe, an mquit signal is sent
% with cargo set to the run-time constant RTCONS.quit. This function is
% normally called by metcontroller.m.
% 
% 
% MC = met ( 'const' )
% 
% Returns a Matlab struct containing MET constants. Has fields:
% 
%   MC.CD - scalar double - Controller descriptor.
%   MC.AWMSIG - scalar double - Maximum number of MET signals that can be
%     atomically read or written from a pipe.
% 
%   Cell arrays , 2 columns with names in column 1 and numbers in column 2.
%   Each row acts as a record binding name to number.
%   MC.SIG - MET signal names and identifiers.
%   MC.OUT - Trial outcome names and codes.
%   MC.ERR - MET error names and codes.
%   MC.SHM - The POSIX shared memory objects (col 1) and associated I/O
%     actions (col 2) that this controller may perform. Actions are encoded
%     by a single character, either 'r' for read access or 'w' for write
%     access.
% 
%   Structs of valid cargo codes:
%   MC.MREADY - Has fields TRIGGER and REPLY.
%   MC.MWAIT - Has fields INIT, FINISH, and ABORT.
%   MC.MCALIBRATE - Has fields NONE.
% 
%   Structs of MET file and directory names:
%   MC.PROG - Program directory, stimulus and task logic template sub-dirs.
%   MC.ROOT - Root run-time directory trial and session indicator files.
%   MC.SESS - Session directory files and sub-dirs
%   MC.TRIAL - Trial directory parameter files.
% 
% If optional input argument nort is non-zero then no run-time constants
% are returned , their fields will contain empty matrices i.e. [].
% 
% Written by Jackson Smith - DPAG , University of Oxford
% 
% 