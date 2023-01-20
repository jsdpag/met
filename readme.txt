

Matlab Electrophysiology Toolbox (MET)


This is a set of programs that synchronise the activity of multiple
processes (in a Unix sense) that run Matlab. Each one controls a
specific job, but the coordinated action is to run an
electrophysiological experiment in real time.


Setup

Place met directory someplace like ~/Documents

To make MET executables visible, modify the user account
~/.profile file to include:

# set PATH so it includes Matlab Electrophysiology Toolbox
if [ -d "$HOME/Documents/met" ] ; then
  PATH="$PATH:$HOME/Documents/met"
fi

Open matlab in super-user mode and save the met/m and
met/stim/met.stim.class folders to the Matlab path.
Run sudo matlab , or sudo ptb3-matlab. If your system has the
memory to spare, then also increase the amount of Java heap
memory in Matlab's Preferences>General>Java Heap Memory
Exit Matlab as soon as the path has been updated.

Make sure that the home directory contains sub-directories:

  ~/subject
  ~/subject/S000.Test

If using PsychToolbox to generate visual stimuli on a monitor
separate from the operator's, it may be necessary to set the
screentohead preference, if there is a problem with beam-position
queries. See metscrnpar.m and metscrnpar.csv.

If using cbmex then it may be necessary to set the socket read
buffer sizes. This can be done permanently in Ubuntu by adding
lines to /etc/sysctl.conf, including:

  net.core.rmem_max=16777216
  net.core.rmem_default=8388608

And reboot. To see if it worked, run:

  cat /proc/sys/net/core/rmem_max
  cat /proc/sys/net/core/rmem_default

Should multi-channel analogue input via the USB-1208fs be
required, say for collecting gaze positions, then it is
necessary to replace the PsychToolbox DaqAInScan.m function
with MET's custom version. A zipped copy is found in met/m.
To install, find out where the local PsychToolbox
installation resides by running >> which Screen from the
Matlab command line. You may get something like this:

  /usr/share/matlab/site/m/psychtoolbox-3/PsychBasic/
    Screen.mexa64

In a system command terminal, navigate to the
psychtoolbox-3 directory, and thence to the
PsychHardware/Daq subdirectory. First, back up the default
function, then unzip the met version:

  sudo mv DaqAInScan.m DaqAInScan.m.bak
  sudo unzip <parent dir>/met/m/DaqAInScan.m.met.zip

Where <parent dir> is the path to the directory that contains
met.

Main directory

~/Documents/met - The main directory where the programs metgo
  , metserver, and metbasic are found. These are the core
  programs of MET. default.cmet is a link to the default.cmet
  file in ./cmet.


Sub-directories

./c - C language source code. The MET header file met.h is kept
  here, along with the files that are compiled into metserver.
  MEX files are not kept here.

./c.mex - C language source code for MEX functions is kept here.
  met.h from ./c is linked. Compiled binaries made with mex are
  not kept here.

./c.util - C language source code for extra utilities that MET
  requires. Each utility will have its own sub-directory

  c.util/ivxudp - The MEX program that mediates UDP
    communication between the local system and iViewX on a SMI
    eye-tracking computer. Compiled MEX files should be moved
    to the m/ directory.
  
./cmet - MET .cmet text files are kept here. These tell metgo
  and metserver how many Matlab processes to run, and which
  child controller functions to use.

./m - Binary executable functions made with mex are kept here,
  along with child controler m-file functions. metcontroller.m
  and metparse.m are kept here. The user must have write
  permissions on this directory and the .csv files therein.

./m/mgui - Specifically for metgui, the MET GUI controller.
  Contains metgui.txt listing which MET GUIs to load. The user
  must have write permissions on this directory.

./tasklogic - All original .txt files describing MET task logic
  are kept here. These are copied to each session directory that
  uses them.

./stim - All MET stimulus definition m-file functions are kept
  here. These are also originals, and copies are made for each
  session directory that uses them. Sub-directory is:
  
  stim/resources - Any special resources required by stimulus
    definitions are kept here. For example, image or movie
    files can exist here.


Working directory

~/.met - Information is written and read from here to coordinate
  the activity of all child controllers.


Programs

metgo - BASH - The user runs this program to start up MET. If
  there is no input argument, then it uses ./default.cmet ;
  otherwise it requires one argument that names the .cmet file to
  use. Its job is to arrange the instructions in the .cmet file
  into command line argument strings for metserver, which it then
  runs. It also prepares and removes ~/.met.

metserver - C binary - Runs each Matlab controller process, then
  acts as a server for them to communicate MET signals. It
  receives broadcast requests from each controller, and
  then broadcasts signals to all controllers. As the parent
  process, it must also monitor the life of each Matlab controller
  and ensure that they all exit.

metbasic - BASH / m-file - This is a no-frills program with a
  single Matlab -nodesktop session running in the system
  terminal. It uses MET utilities and MET PTB stimulus
  definitions to provide a simple environment for running a
  basic experiment.

metcontroller - m-file - Each Matlab-based MET child controller
  runs this function to initialise itself and run the controller
  function. It will catch errors that originate in the controller
  function, and ensure that the child controller exits.

metparse - m-file - Reads in the task logics and schedule.txt of
  the current session directory, and converts this to a Matlab
  data structure that can be used by a MET controller.

met - mex binary , mexa64 - Matlab interface for MET inter-process
  communication. Uses a PsychToolbox-like syntax where the first
  argument specifies a MET function. This is used to receive and
  send MET signals, and to read or write to shared memory, and
  to obtain lists of MET constants.


Files

./c/met.h - C language header file with all MET constants, types,
  and so forth.

./version.txt - One line ASCII text file with the current version
  number string.

./readme.txt - This document. Contains overview of MET, and
  refers to itself in the 3rd person.

./default.cmet - Symbolic link onto ./cmet/default.cmet

./cmet/default.cmet - .cmet file with default MET controller
  options.


Written by Jackson Smith - DPAG, University of Oxford


Version plan - Describes development steps at each stage.

00.00.00 to 00.00.31 - MET server controller
00.01.00 to 00.01.32 - met.c and metcontroller.m
00.02.00 to 00.02.15 - task logic and stimulus support
00.03.00 to 00.03.?? - standard MET controllers , finalise
  metcontroller.m
00.04.00 to 00.04.?? - BETA testing
01.00.00 - Version 1 - First complete version of MET that is
  capable of running an experiment.
  
  Further sub-versions 01.XX.YY are numbered as such. YY increments
  with each bug fix. XX increments with each enhancement that
  doesn't change the core of MET e.g. MET startup, IPC, MET server.

02.00.00 - Version 2 - Allow any number of POSIX shared memory
  objects, with names and sizes defined in controller options.
  Any required expansion of MET signalling protocol. Any new
  standard MET controllers. Modularise special resources.
  
  Pass POSIX shared memory name as argument to metcontroller,
  along with opening flag, number of readers, and event fds. Then
  shared memory can be defined in the cmet file, as long as the
  writer is supplied with a name and size, and the reader supplied
  with the name.


History

23/06/2016 - 00.00.00 - First files and directories set up.
25/06/2016 - 00.00.01 - Increased metgo error checking.
27/06/2016 - 00.00.02 - metgo .cmet parsing and arg passing to
  metserver. metserver placeholder function added. metcontroller
  placeholder added. metgo does not make ~/.met or set socket
  buffer sizes for system.
28/06/2016 - 00.00.03 - metgo checks for shared memory writer-
  reader balance. metserver handles UNIX signals, starting
  input argument checking of metserver.
28/06/2016 - 00.00.04 - Finished basic input argument checking
  defined MET signal data types and structure.
29/06/2016 - 00.00.05 - Adding support for MET errors. Request
  and close unnamed IPC. metserver resource flags.
29/06/2016 - 00.00.06 - Improved metserver error handling. And
  laid down program framework ; the steps of initialisation and
  shut-down.
30/06/2016 - 00.00.07 - Improved UNIX signal handling. Expands
  set of handled signals. Does not restart system calls. Blocks
  other signals while handling. Catches SIGALRM for timeouts.
06/07/2016 - 00.00.08 - Initialise file descriptors to FDINIT,
  and improve internal error checking. POSIX shared memory
  creation ; not tested, needs unlinking function first.
07/07/2016 - 00.00.09 - POSIX shared memory unliking. First
  successful test added and removed shm from /dev/shm.
07/07/2016 - 00.00.10 - metsmunln now handles case where there are
  no readers and shm doesn't exist. Creates eventfd for 
  synchronising POSIX shared memory. Added const modifier to
  applicable input arguments in supporting functions.
08/07/2016 - 00.00.11 - Adding epoll support. Fixed bug in 
  metpipe.c where n was limited to SHMARG rather than MAXCHLD.
11/07/2016 - 00.00.12 - Gets atomic read/write size for pipes.
  First version of MET signal broadcasting function.
11/07/2016 - 00.00.13 - Broadcast initialisation mwait and final
  mquit. First version of MET signal request receiver function.
12/07/2016 - 00.00.14 - Better error handling in metgetreq.c
12/07/2016 - 00.00.15 - Tested metgetreq.c
13/07/2016 - 00.00.16 - New MET error codes for signal source and
  time protocol breach, and timeout while waiting. Added MET
  signal source and identifier checks to metgetreq.c
13/07/2016 - 00.00.17 - Tested new metgetreq.c checks. mready
  reply waiting by MET server controller during initialisation.
14/07/2016 - 00.00.18 - UNIX signal checking on EINTR. Waits for
  child processes.
14/07/2016 - 00.00.19 - Added concept of met.mexa64, which metgo
  now looks for in ./m. Begin laying framework for fork-exec
  MET child controllers.
15/07/2016 - 00.00.20 - Added metforx parent process code. Child
  process error handling and test code in place.
25/07/2016 - 00.00.21 - Adapting for use of met ( ... ) interface.
  No longer require metmatpnt_t typedef in met.h. Introducing MET
  shared memory header byte coding format. Prepares argument
  vector for MET child exec to Matlab ; now includes char flag
  for shared mem. Initialises child controller standard output
  redirected to /dev/null.
25/07/2016 - 00.00.22 - First tests of MET child controller exec to
  Psych Toolbox Matlab. Test code put in met.c, prints to stderr.
26/07/2016 - 00.00.23 - Building MET server controller server
  function. Not tested, lacks MET signal checking.
26/07/2016 - 00.00.24 - Adding MET signal checking.
27/07/2016 - 00.00.25 - First complete version of metsigsrv.c
27/07/2016 - 00.00.26 - metgo creates and removes MET root dir
  ~/.met.  First compilable version of metsigsrv.c. Remove FDINIT
  check on event fd's in metforx, because these will be
  uninitialised if there are no readers on the corresponding shm.
  First successful pilot test of complete MET server controller.
28/07/2016 - 00.00.27 - Added more error checking to start of
  metsigsrv.c.  Standard output no longer closed by MET child
  controllers ; a duplicate file descriptor is passed to
  metcontroller , which is re-duplicated back to STDOUT_FILENO.
29/07/2016 - 00.00.28 - [ All child processes forked from the MET
  server controller are placed into their own distinct process
  group ] But this causes Matlab to throw a phantom SIGCHLD during
  startup ; until this issue is resolved, all forked processes
  stay in the same process group as metserver, which it sends
  SIGKILL as a last resort measure. Signal handling improved to
  use sa_sigaction on caught signals rather than sa_handler.
29/07/2016 - 00.00.29 - Attempt placing child process group in
  foreground. Matlab seems to rely on this. Consequently, a call
  to tcsetpgrp must be made. As this can trigger a SIGTTOU, the
  MET server controller must first block it, SIGTTIN, and SIGTSTP.
  First successful direct cycle of MET signalling protocol states;
  need to check mwait in trial init and wait-for-mstart.
30/07/2016 - 00.00.30 - metserver gets terminal attributes before
  forking child MET controllers, then attempts to restore these
  during shutdown, in case Matlab left the terminal in a strange
  state. [ MAJOR PROBLEM!!! metgetreq seems to read in more bytes
  than there should be, and reports checking more pipes than it
  should have ] Resolved: due to faulty testing messages that
  reported the amount of free space in the buffer rather than the
  number of bytes returned.
31/07/2016 - 00.00.31 - Moved MET signal cargo and time range
  checks from metsigsrv.c to metgetreq.c, so that metsigsrv.c
  only checks for breaches related to MET signalling protocol
  states. Did more checks on metsigsrv.c
31/07/2016 - 00.01.00 - First complete version of MET server
  controller. Now move through development of met.c and
  metcontroller.m
31/07/2016 - 00.01.01 - First versions of metcontroller.m and
  met.c. Making first MET MEX function print.c.
01/08/2016 - 00.01.02 - print.c can now write to stdout or stderr,
  and also to the MET controller's logfile. The met_t structure
  now accommodates a logfile stream, and a pointer to the HOME
  environment variable.
02/08/2016 - 00.01.03 - met function const written, and open begun.
02/08/2016 - 00.01.04 - Added MET files to const output.
02/08/2016 - 00.01.05 - met functions open and close written.
03/08/2016 - 00.01.06 - met close now writes mquit to req. pipe.
  met logopn, logcls, and print now written and tested.
03/08/2016 - 00.01.07 - Added ME_MATLB MET error code for Matlab
  errors encountered in MEX programs. Existing met functions now
  assign MET error codes to the controller's mquit signal when
  error is encountered.
04/08/2016 - 00.01.08 - Add non-blocking check on pipes in met
  open. struct met_t now uses field 'p', 2 element int array
  rather than .br and .qw ; instead, elements are accessed with
  macros BCASTR and REQSTW for broadcast read and request write
  e.g. .p[ BCASTR ] retrieves broadcast read file descriptor.
  met const returns atomic write size of pipes.
04/08/2016 - 00.01.09 - met send for writing MET signals to the
  request pipe.
05/08/2016 - 00.01.10 - met recv for receiving MET signals from
  the broadcast pipe. First compilable version , untested.
05/08/2016 - 00.01.11 - Tested and refined met recv.
07/08/2016 - 00.01.12 - Event fd checking in met open.
07/08/2016 - 00.01.13 - MAJOR FLAW! This time it is real. Cannot
  have one wefd shared by all readers, because readers don't know
  whether they have already read from shared memory. Each reader
  needs its own wefd to monitor
08/08/2016 - 00.01.14 - Will make and deliver separate writer's efd
  for each reader. metcontroller input will have variable number of
  efd's depending on access mode. metserver.c modified up to
  metforx.c
08/08/2016 - 00.01.15 - Continuing writer's efd fix. metforx.c
  modified up to building line of Matlab for -r argument.
09/08/2016 - 00.01.16 - All MET server controller functions
  upgraded. Now metcontroller and met need servicing.
09/08/2016 - 00.01.17 - Started modifying metcontroller.m
09/08/2016 - 00.01.18 - metcontroller.m upgraded.
09/08/2016 - 00.01.19 - met 'open' and 'closed' functions adapted
  for writer's efd lists. Ready to resume 'read' and 'write'
  development.
10/08/2016 - 00.01.20 - Function to switch blocking mode on fd's
  deployed to met 'send' , 'recv' , 'read' , and 'write'. 'read'
  and 'write' check access permissions and don't allow a
  controller to do a blocked read/write on shared memory if it can
  also write/read the same memory ; thus avoiding a jam.
10/08/2016 - 00.01.21 - metxefdpost.c deployed to met 'read' and
  'write'.
10/08/2016 - 00.01.22 - Event fd sync testing of met 'read' and
  'write'.
11/08/2016 - 00.01.23 - Found a bug in metserver.c where wefd
  is defined ; made 2D array by advancing along 1D array by
  steps of SHMARG rather than number of child controllers.
  Another problem produces an infinite loop in a child controller.
  This may be related to met 'read' as all initialisation steps
  seem to be correct.
11/08/2016 - 00.01.24 - Found another bug. The event fd reading
  function metxefdread.c failed to catch read() system call errors
  other than EINTR, EGAIN, or EWOULDBLOCK. Rather, it increased
  the byte count and reversed the pointer because read() had
  returned -1, thus causing an infinite loop.
11/08/2016 - 00.01.25 - Fixed pointer passing to metxsetfl. Was
  passing int ** when doing wefdv + si, when int * was required.
  Fixed by advancing pointer and dereferencing i.e. wefdv[ si ].
  New and exciting problem. One process changes blocking mode of
  event fd, the same efd's blocking mode changes for another
  process. The reason, it turns out, is that they share the same
  file description, as opposed to file descriptors! If they use
  fcntl F_SETFL then the same description is affected, and the
  actions of one process will have unexpected consequences for the
  other. The solution is to reserve a separate event fd for each
  controller ; only that controller will change the blocking mode
  of its efd file description. Shared memory writers will only
  change blocking on the readers' efd (so that the writer can wait
  for readers) and only the readers will change blocking on the
  writer's efd (so that readers can wait for the writer).
12/08/2016 - 00.01.26 - Foundation laid for met 'select'. 'write'
  and 'read' still don't touch shared mem.
12/08/2016 - 00.01.27 - First complete and compilable version of
  met 'select'.
12/08/2016 - 00.01.28 - met 'select' seems to be running properly.
13/08/2016 - 00.01.29 - metxconst.c now returns the set of shared
  memory actions that are legal, given the permissions provided
  during met 'open'.
13/08/2016 - 00.01.30 - Write and read headers from shared mem.
14/08/2016 - 00.01.31 - Write and read struct header. Read now
  uses specified functions for making struct, cell array, and
  basic matrices.
14/08/2016 - 00.01.32 - Writes and reads structs, cells, and matrix
  values.
14/08/2016 - 00.02.00 - First complete version of the met()
  function. First functional, but incomplete, version of
  metcontroller.m ; this does not open/close special resources, as
  testing this requires access to specialised hardware. This will
  be implemented in version 00.03.XX.
19/08/2016 - 00.02.01 - Tweaked met 'send' and 'const'. For 'send',
  the tim argument can be an empty matrix [], causing 'send' to
  take a time measurement and apply it to all sent signals. 'const'
  now has an optional input argument that flags whether or not to
  return run-time constants.
21/08/2016 - 00.02.02 - Planned out the interface of metparse.m,
  now implement it.
22/08/2016 - 00.02.03 - metsdpath.m added to read ~/.met/session
  and verify current session directory. Started task logic file
  parsing.
23/08/2016 - 00.02.04 - Writing task state list parser.
25/08/2016 - 00.02.05 - Parses state list. On to edges.
30/08/2016 - 00.02.06 - State edge parser written , tested to line
  730.
31/08/2016 - 00.02.07 - Edge parser runs with simple example. Need
  to test error-checking.
01/09/2016 - 00.02.08 - Made metparse.m part of the mandatory set
  of MET files. First complete version of task logic parser.
02/09/2016 - 00.02.09 - schedule.txt task declaration parser runs,
  but not thoroughly tested. Started var declaration parser.
02/09/2016 - 00.02.10 - Task var parsing mostly written , except
  for distribution term checking. Also needs testing.
14/09/2016 - 00.02.11 - Started distribution checking on task
  variables. Still needs testing.
14/09/2016 - 00.02.12 - Task variable and block declaration parsing
  written. Working on eval. Need to check for unused stim defs, and
  do testing.
15/09/2016 - 00.02.13 - Parser written. schedule.txt parsing needs
  testing , so does unused logic/stim-def check. Nope , is missing
  schedule.txt check for task or vars that aren't used by any
  block.
15/09/2016 - 00.02.14 - Added check for unused task or var.
15/09/2016 - 00.02.15 - Checks form and content of stimulus 
  definition variable parameter output argument vpar. Tested.
16/09/2016 - 00.03.00 - metparser written. The essential pieces are
  now available to develop MET controllers.
19/09/2016 - 00.03.01 - Added ./m/mgui directory for metgui
  controller. Started GUI building. MET Remote.
20/09/2016 - 00.03.02 - Added more button behaviour to MET Remote.
  Writing metgui API functions.
21/09/2016 - 00.03.03 - MET remote ready. Started making MET GUI
  Central.
22/09/2016 - 00.03.04 - metparse returns vpar output argument of
  stim definition variable parameters. It also does basic error
  checking on input args. Can now return only task logic or var
  pars. These changes are needed to write a session builder for
  metgui. Generates metsubjdlg for getting session directory.
22/09/2016 - 00.03.05 - MET GUI Central session menu callback
  starting to take shape for generation of a session descriptor.
23/09/2016 - 00.03.06 - Adjustment to MET GUI API. GUI descriptor
  should be a field in figure's UserData. Thus, metgui only uses
  the figure handle, and passes that to the update, refresh, and
  close functions. Added event loop to metgui which reads new IPC
  and sends MET signals on behalf of MET Remote and MET GUI
  Central. test.m uses PTB and responds to signals from metgui.
27/09/2016 - 00.03.07 - metgui now uses metremote button values to
  trigger new trial generation. metremote has zero-value place
  holders for start and lock button MET signals. Trial outcome
  buffer.
28/09/2016 - 00.03.08 - Many more metctrlconst.m constants added.
  MET Subject Selector GUI mostly functional. Still needs the up
  and down buttons , and Done must return a new session descriptor.
29/09/2016 - 00.03.09 - metparse logic.<tlogN> struct has fields
  .file and .dir recording file name and directory of parsed file.
  Added metgetfields for convenient access to metparse output.
  MET Subject Dialogue is functional and returns its part of sess
  descriptor. Started schedule builder dialogue.
30/09/2016 - 00.03.10 - Finished layout of schedule builder. Give
  uicontrols and uitables normalised units so that dialogues can
  resize , and components will keep relative size and position.
  Added evar controls to schedule builder. Some functionality.
  Adding tool tips.
03/10/2016 - 00.03.11 - Added more basic callbacks to schedule
  builder.
04/10/2016 - 00.03.12 - First use of table popups and table
  UIContextMenu for selecting controlled lists.
04/10/2016 - 00.03.13 - Tested task var selection callback. Added
  task table selection callback, needs testing.
05/10/2016 - 00.03.14 - Cell edit callback written for tables.
  Next step , have task and var controls edit session descriptor.
05/10/2016 - 00.03.15 - Schedule builder initialised by populated
  session descriptor. Task and block list box selection changes
  control contents to show selected item's properties.
06/10/2016 - 00.03.16 - Various fixes. Next, add evar callback,
  min button check before delete , var list button callbacks ,
  add-remove from session descriptor.
06/10/2016 - 00.03.17 - Table add and remove buttons affect the
  figure's session descriptor. Now do the same for task/block add
  and remove buttons, and var popup menu buttons.
06/10/2016 - 00.03.18 - Saw weird bug where block list value was
  []. Don't know where this happened. Wrote metsd2str to convert
  session descriptor into schedule.txt string. All session builder
  controls now affect figure's session descriptor. Final validation
  functions in place. Requires viewing window. Also requires
  pruning down of task logic and variable parameter sets to only
  what will be used.
07/10/2016 - 00.03.19 - metcontroller now opens and closes cbmex
  on request. First version of metdaqout.m written. This controller
  function waits for MET signals, then transmits each one to the
  NSP via its DAQ's digital output.
08/10/2016 - 00.03.20 - metcbmex written but not run. This
  interfaces with the NSP, but still lacks use of trial
  descriptors.
10/10/2016 - 00.03.21 - MET signal buffering and writing out as
  comment footer in metcbmex. Various bug fixes. Shocking discovery
  that met 'read' and 'write' don't know how to handle an empty
  matrix ; the reason is that it never checks that an array has 0
  elements, while mxGetElementSize returns 0 on error ;
  multiplying the two indicates an error, but only if the array is
  not empty ; the fix is simply an if else statement that checks
  for an empty array first, and jumps to the finished escape point
  if it is. There is another problem , cell arrays generated by
  cell () will cause a crash, as their elements are all unset,
  although you are shielded from this by normal Matlab code. It
  seems to be impossible to tell the difference between an un-
  populated cell array and insufficient heap space. A workaround
  IS to explicitly initialise cell array elements with empties.
  For this reason, metcell is now written and used by MET
  controller functions. This is now a stable-ish demo.
10/10/2016 - 00.03.22 - metcbmex must keep calibration time points.
  New ones are written each trial. Problems with matching clock
  calibration time points , will need to test out sub-functions
  in specially set up environments. For now, don't bother
  converting clock values, but do convert NSP samples to
  seconds. Yes, do, it was an indexing error. Backup now.
  Mystery is what happens to spike time stamps at shm write.
10/10/2016 - 00.03.23 - metraster fixed. metcbmex seems stable.
  All's good, now cbmex is gone to buggery. Trying to use different
  'colour' for each comment, meaning max of 127 * 255 chars.
10/10/2016 - 00.03.24 - metcbmex now fixed to start file recording
  before starting cbmex buffering. Crucially, about a 20ms pause
  is placed between the two calls. This seems to resolve time-stamp
  jumping, and crawling backwards in time.
12/10/2016 - 00.03.25 - Schedule builder now allows user to view
  the schedule.txt file that results, and to accept or reject it.
13/10/2016 - 00.03.26 - Started metmkdir for creating session
  directories.
14/10/2016 - 00.03.27 - Added more environment checks in metmkdir
29/11/2016 - 00.03.28 - First operational version of metmkdir.m
15/12/2016 - 00.03.29 - Started writing metdaqeye.m for reading
  analogue eye positions and writing them to shared memory.
15/12/2016 - 00.03.30 - metdaqeye.m written but not tested.
  metscrnpar.csv added to the met/m directory as a way of providing
  screen information to all controllers, such as the width and
  height in millimeters, and the subject's distance to the screen.
16/12/2016 - 00.03.31 - Minor bug fix to metdaqeye.m due to copying
  code from another function, renaming variables. Wrote
  metscrnpar.m convenience function to access metscrnpar.csv
  values. Wrote metpixperdeg.m to compute pixels per degree of
  visual angle.
16/12/2016 - 00.03.32 - meteyeplot.m written but not tested.
17/12/2016 - 00.03.33 - mready reply added to metdaqeye, and
  meteyeplot tested offline. Reward pump control added to
  metdaqout. met/m has a zipped copy of DaqAInScan that was
  modified for streaming binoccular eye positions.
18/12/2016 - 00.03.34 - Retrofitting legacy taskcontroller.m and
  go.m to run using MET. To run them, metlegctl was made.
  mettimerobj made to clear MET IPC when controller is otherwise
  blocked for Matlab reasons. Started metlegeye to show eye
  position, but it's figures aren't showing, but -nojvm is not
  provided.
18/12/2016 - 00.03.35 - metlegeye fixed by adding drawnow. 'stim'
  now passes hit boxes from metlegctl to metlegeye and the eye
  plot changes dynamically during the trial. Next, get a legacy
  indev.m function to read eye positions from 'eye' shm.
19/12/2016 - 00.03.36 - Made dedicated legacy copy of meteyeplot,
  and removed response position plot from runtimeplot. Wrote
  metlegtrg, which also reads from 'stim' and generates mtarget
  signals when the eye position enters a new hit box. As such,
  the format of writes to 'stim' delivers hit box coordinates that
  are separated by task stimulus, and corresponding concrete
  stimulus indeces. metlegtrg does not yet use eye signals.
19/12/2016 - 00.03.37 - indev.m no longer required in session
  directory. metlegtrg now has eye input device descriptor.
19/12/2016 - 00.03.38 - metlegtrg now written. It runs, but need
  a pair of eyes to tell if it's working.
19/12/2016 - 00.03.39 - Tweak to mtarget interpretation in
  taskcontroller.m so that variable 'targeted' can hold 0 when
  nothing is targeted. The null target -1 can no longer be used
  during the trial, as it doesn't make sense to change the value
  of targeted if no new input arrives from the user. Conversely,
  assume that the same stimulus is being targeted. Added some
  templates to legacy directory, including a new fixation task.
20/12/2016 - 00.03.40 - Bundled mancal_indev.m and indev.m with the
  met/m/legacy folder for manual calibration of the eye tracker.
  The system has now been tested with human eyes in a fixation
  task. This runs nicely. Trying to have metlegctl open a master
  PTB window that can be re-used between calls to taskcontroller.
20/12/2016 - 00.03.41 - Finished launching master PTB window from
  metlegctl. Added touch column to metscrpar.csv to say whether
  the stimulus appears on a touchscreen.
22/12/2016 - 00.03.42 - Legacy retrofit taskcontroller.m can now
  generate mreward MET signals when the user hits a reward button,
  currently 'r'. This allows manual rewards during trials. There
  is also a menu option to send a reward. meteyeplot_legacy.m now
  ignores mrewards because they flood the timeline when a manual
  reward is given.
28/12/2016 - 00.03.43 - Added trial and block descriptor
  initialisers to MET controller constants, see metctrlconst.
  The metgui controller shuffles its Matlab random number
  generator during initialisation. metblock written but not tested.
  This is for generating and maintaining a trial block descriptor.
29/12/2016 - 00.03.44 - Block descriptor has new fields 'varnam'
  and 'var' , containing string names of variables and a struct
  with each variable attribute ; varnam{ i } is the name of the
  variable with attributes var( i ). Some testing of metblock.
  Need to test out different dependent variables, especially
  outcome-dependent.
30/12/2016 - 00.03.45 - metblock tested. Trial descriptor
  attributes changed to .block_name and .block_id. metcontroller
  attempts to delete any visible Matlab timer objects on closing.
  metnewtrial written to generate new trial descriptors and update
  session descriptor's trial identifier. Part tested, need to
  check with different names for all parts of schedule.txt and
  check with task variables for all components.
03/01/2017 - 00.03.46 - Further testing of metnewtrial. Added
  optional input argument to create a new trial directory and
  write the param_i.* files to it. Added optional output arg
  that returns the string written to param_i.txt.
03/01/2017 - 00.03.47 - Start incorporating new functions into
  metguicentral and metgui in order to create new session
  directories, create new blocks of trials, and create new
  trials. metmkdir now requires a fourth argument 'sched' which
  is the string to write to the new session directory's
  schedule.txt. metguicentral finalise and session_cb functions
  now written but not tested.
04/01/2017 - 00.03.48 - metguicentral updates ~/.met/session with
  new session directory name. Added SDFNAM to MET controller
  constants, the session descriptor file name, where the session
  descriptor is saved in the session directory. metgui improved
  with a re-organised event loop. MET controller constants added
  for stim and nsp shared memory data structures. Starting to add
  trial buffer support for metgui.
05/01/2017 - 00.03.49 - By convention , 'stim' shm will now be
  used to transfer hit regions rather than variable parameters.
  metctrlconst touched up , includes cbmex 'trialdata' sampling
  rate. Recovery added to metgui.
05/01/2017 - 00.03.50 - First complete version of metgui written.
  Not yet tested. metsdpath now returns optional second argument
  containing the trial identifier in ~/.met/trial.
06/01/2017 - 00.03.51 - metsubjdlg was missing access to MCC in one
  function , and hadn't initialised a list of subject directories
  when selecting the Clone option. metsessdlg did not make
  uicontextmenu's parent the same as the table being made.
  metguicentral , some small fixes ; proper variable names , 
  make unique list of stimulus definitions , MET constants access.
  metmkdir does not account for there being no date directory ;
  now makes date directory if it is not there. metgui set first
  element of outcome buffer to IGNORED , thus no first trial was
  generated. Still need to test shm transfer to metgui, trial
  buffering, aborting trial, opening new session or existing.
09/01/2017 - 00.03.52 - metnewtrial did not set ~/.met/trial
  when input arg w was non-zero , now it does. Tested eye and
  nsp shm transfer and trial buffering to metgui ; not extensively
  but it looks good by eye, so far.
09/01/2017 - 00.03.53 - Added new MET controller constants for the
  hit-region column indeces , and for param_<i>.mat formatting
  strings. Minor error in metsd2str indexing while making block
  string , confused counted for loop with cell array for loop and
  always returned the first element instead of the ith one ; also
  forgot to add 'evar' keyword for environment variables.
  metguicentral did not check validity of session directory
  given the Open or Clone command ; while metsdpath fails to
  check for .finalise , but not any more.
10/01/2017 - 00.03.54 - Need to add mettimer to metguicentral for
  when modal dialogues are displayed. Then shared memory will be
  cleared by metgui and writes will go through. Need to fix
  metsubjdlg and metsessdlg ; former to prevent duplicate
  subject ids, and latter to stop task variable addition before
  a task is available. metsessdlg Done button validation does
  not fist look for a lack of things, assuming they must be there,
  it overwrites return variable i as a for loop interator, and it
  does not even validate blocks ; it does not validate blocks since
  this is done by adding a new block and hitting 'OK' , but we must
  at least check that it's there. metsd2str could not handle
  lack of sub-declarations in task declaration. metsessdlg had
  to check dependency of block variables by task , but also had
  to prevent addition of dependent variables before the dependent
  variable was added, notwithstanding outcome-dependent variables.
11/01/2017 - 00.03.55 - metguicentral did not refresh variable
  parameter list following the use of metsessdlg. Was able to make
  a new session from scratch using MET GUIs. New MET controller
  constant for MET root directory file ; this will be written to
  by each child controller , and contain a line with the
  controller function name and shared memory attributes.
11/01/2017 - 00.03.56 - Add header and footer file writing to
  metguicentral. metscrnpar now returns a struct that includes
  fields hmirror and vmirror that say whether the monitor is
  mirrored in the horizontal or vertical direction. metsavtxt
  now written for saving a string to a text file. Needs testing.
12/01/2017 - 00.03.57 - MET and Matlab version information added
  to session header. Can't use metsavtxt to write cntlattrib
  because Matlab doesn't know how to write to a file that's open
  in another Matlab ; the solution is to use system commands with
  the >> redirection operator, which appends to an existing file
  and queue's writes with those from other processes. Header and
  footer writing now tested.
13/01/2017 - 00.03.58 - Abbridged trial information printed before
  each trial runs, and outcome printed at the end. Change
  metgui.txt to metgui.csv so that each MET GUI is treated as
  either a real-time GUI or it is only updated at the end of each
  trial.
14/01/2017 - 00.03.59 - Met remote now enables/disables MET
  Session Info block controls. metgui refreshes MET Session Info
  GUI when there is a newly opened session and when there is a new
  trial. Added 'flush' command to met function set, which will
  flush the standard output stream. metgui runs GUIs' recovery
  functions after Opening a session and at the end of each trial.
  metgui added a block buffer that remembers which blocks of trials
  were deemed useful for later analysis. metsessdlg was unable to
  update session descriptor after edits to existing objects. It
  also let slip empty block variable list.
18/01/2017 - 00.03.60 - Fixed problem with metlegtrg when assigning
  fewer eye samples than spaces available in the buffer. Removed
  the line header that was formerly appended in met 'print'.
  metgui now maintains a log file, and metcontroller will attempt
  to print error messages to both terminal and log file, if it
  exists. If there is no open log file then met 'logcls' silently
  returns without doing anything.
19/01/2017 - 00.03.61 - Made metgui's MET signal request buffer a
  global variable that special MET GUIs can add values to ; use
  metguiqsig to queue signals. Not tested.
20/01/2017 - 00.03.62 - metguiqsig tested, now ready to finish
  implementing MET Session Info GUI, which will have manual
  reward control that queues mrdtype and mreward. Evar origin is
  now given in degrees of visual field from the centre of the
  screen where up and right are positive, down and left are
  negative ; changed metparse and metsessdlg for that.
21/01/2017 - 00.03.63 - MET Session Info GUI largely written , but
  MET API functions not tested.
23/01/2017 - 00.03.64 - Tweaked MET GUI API so that recovery and
  reset functions accept a cell array as second input arg, where
  first value is a string saying what to do, and the second is
  context dependent. Tested MET Session Info's MET GUI API
  functions. metgui was only advancing outcome buffer index if
  last trial was ignored, the difference between == and ~=. There
  was also a mis-understanding about how to use outc.i, where
  a value of 0 was being considered the last outcome when no
  outcome has a value less than 1. Had to update metblock to
  account for the first trial when outcome input arg is [].
  Have now re-tooled so that outc.i indexes the outcome of the
  last trial to run. MET Sess Info GUI seems to be running
  properly.
24/01/2017 - 00.03.65 - Added MET controller constants that
  provide the form of an input struct for MET PTB stimulus
  trial initialiser and stimulation functions, and also hitregion
  column indeces. Started writing mettestptbstim for testing
  ptb stimuli in a single-threaded environment, but it is necessary
  to add more information to metscrnpar, including default
  background, screen id, and screen-to-head mappings. This is now
  added.
25/01/2017 - 00.03.66 - metlegtrg now checks targets in the reverse
  order to which they were drawn i.e. the one that is drawn on top.
  Removed 'mirror' field from the input struct for MET ptb stimulus
  trial initialiser functions. Added much error checking to
  mettestptbstim, need to finish checking input and output argument
  from stim def function handles, and need to add more information
  about stim def functions in the help.
26/01/2017 - 00.03.67 - Require MET ptb stimulus stim function to
  accept both trial constant and trial variable structs as the
  second and third arguments. Removed redundant fields from the
  trial variable struct. mettestptbstim now reads in the stimulus
  definition file and looks for Screen 'flip'. This is not
  foolproof, as the stimulus definition could return function
  handles to functions located in other files ; by convention,
  all handles from a stimulus definition function should point
  to functions defined in the same text file. The rest of the
  function is written but untested.
27/01/2017 - 00.03.68 - Caught a small problem in metsubjdlg where
  cell array was concatenated in the wrong dimension when making
  a new subject.
30/01/2017 - 00.03.69 - Fixed the stimulus definition documentation
  and verification to correct the init trial initialiser function 
  prototype.
06/02/2017 - 00.03.70 - Updated stimulus definition so that close
  returns a stimulus descriptor that is fed to init the next time
  that the stimulus link is used. This will allow for information
  to carry over from past trials, and is intended mainly for
  manually controlled stimuli. Made a start at the first stimulus
  definition, 'dot'. Half way through.
07/02/2017 - 00.03.71 - Extra screen parameters from metscrpar are
  now added to session headers , and also PsychToolbox version.
  Extra trial constants for MET ptb visual stimuli containing PTB
  window dimensions and centre point. MET ptb stimulus definition
  dot.m is written but untested. mettestptbstim needs to be
  updated to incorporate changes to MET specification.
08/02/2017 - 00.03.72 - Correcting mettestptbstim error messaging.
  Updating mettestptbstim MET ptb stim interface, fixed problem
  where variable parameter change list was not cleared after use.
  MET ptb visual stimulus definition dot.m written.
08/02/2017 - 00.03.73 - Started writing MET ptb stimulus definition
  for random dot kinetogram similar to that in Britten et al 1992.
09/02/2017 - 00.03.74 - rdk_Britten92 part of stimulus descriptor
  in trial initialiser.
10/02/2017 - 00.03.75 - More additions to rdk_Britten92 trial
  initialiser.
12/02/2017 - 00.03.76 - rdk_Britten92 largely written , but not
  tested , and variable parameter change requests are not yet
  handled by the stimulation function.
13/02/2017 - 00.03.77 - Added constant horizontal disparity
  displacement to rdk_Britten92 dot positions , to speed up
  function and to reduce time spent copying. Still need to add
  variable changes during trial then test.
13/02/2017 - 00.03.78 - rdk_Britten92 now runs in mettestptbstim
  and generates dots. Need to implement variable parameter changes
  and to further test stim def. mettestptbstim puts crosshairs
  at origin.
14/02/2017 - 00.03.79 - mettestptbstim now accepts an optional
  input argument with a variable parameter initialisation struct.
  Added fyoke variable parameter to rdk_Britten92 which , following
  rotation of formation circle , applies a translation so that
  the patch with index fyoke is centred on the origin defined by
  fcentre_x and fcentre_y. Disparity and binocular correlation
  settings tested. Still need to add variable parameter changes
  during trial.
15/02/2017 - 00.03.80 - Added calgrid.m as a standalone utility
  for calibrating screens/stereoscopes. rdk_Britten92 variable
  parameter changes during trial implemented but not tested.
16/02/2017 - 00.03.81 - First complete version of rdk_Britten92
  stimulus definition.
16/02/2017 - 00.03.82 - calibgrid stimulus definition mostly
  written. Need to add/test variable parameter changes during a
  trial.
17/02/2017 - 00.03.83 - calibgrid supports variable parameter
  changes during a trial. metteststim now works if it is bundled
  in the same directory with the named stimulus definition.
  metctrlconst.m will not crash if met is not visible.
17/02/2017 - 00.03.84 - Added parameters to dot stimulus definition
  allowing it to orbit around its x and y coordinate. Useful for
  providing choice targets in a 2AFC task. Updated 2afc.txt in the
  master met/tasklogic directory by adding a reaction time state
  where the test stimulus and choice targets are visible. By
  changing the timeout durations, a single task logic is
  configurable between classic forced presentation 2AFC or a
  reaction time version. Also, allows loss and recapture of gaze
  fixation prior to test stimulus presentation. Added the idea of
  a general purpose MET .csv file format for passing parameter to
  MET controllers. Helper function metreadcsv.m written, and MET
  controller constant added with column headers. Modified
  metscrnpar.m, metdaqeye.m, and metdaqout.m to use metreadcsv.
  Began writing MET controller function mettarget.m, an update of
  metlegtrg.m that is compatible with the MET specification.
18/02/2017 - 00.03.85 - Added MCC.SDEF.none = 1 so that there is
  a symbolic way of referring to the 'none' task stimulus, when
  no task stimulus is being selected by the subject. mettarget.m
  written but untested.
19/02/2017 - 00.03.86 - metctrlconst now accepts optional input
  argument MC so that a MET controller can pass in its run-time
  constants, allowing the standardised creation of certain data
  structures. For instance metctrlconst also now defines the 
  current buffer , used to grab the latest MET signals or shared
  memory contents and relies on information about available
  shared memory. Added some checks to mettarget to verify that
  sd and td were loaded , and stimdeftype no longer permanently
  changes the current directory. mettarget's stimdeftype and
  trialinit functions have been turned into their own helper
  functions for use by other controllers, called metstimdeftype.m
  and metptblink.m. Added field to session descriptor called .type,
  which contains the type string for each MET stimulus definition
  in use by that session ; this field directly receives the output
  from metstimdeftype. Field .type of the session descriptor is now
  set by metguicentral when it creates a new session directory,
  using metstimdeftyp ; hence this is no longer done in mettarget,
  and metptblink no longer requires a 'type' input argument, as it
  comes with the session descriptor. metptblink now looks for
  global copies of MET constants and controller constants MC & MCC,
  which mettarget now declares. metdaqeye now streams eye positions
  through 'eye' shared memory in degrees of visual field from the
  centre of the screen, where up and right are in the positive
  direction.
20/02/2017 - 00.03.87 - metrealtimeplot.m written to support a
  single MET GUI that updates in real time, to remove burden from
  metgui plus lessens the risk of creating a reader-writer
  bottleneck. Added path to MET GUI definitions in metctrlconst.
  metgui now refers to that, and so do real-time MET GUI wrapper
  functions. metptblink now does a better job of checking the
  session descriptor field set. metrteyes.m is a wrapper function
  that uses metrealtimeplot and meteyeplot to show the current
  position of the eyes versus the hit regions of visible stimuli.
  Changed metptblink to accept different input argument sets that
  bypass loading the trial descriptor or reading shared memory.
  metrealtimeplot implements a kind of home-made drawnow limitrate
  by only executing drawnow if at least 16ms have passed, for
  a refresh of about 60Hz. MET GUI definition changed so that
  the update( ) function returns a scalar logical saying whether
  the appearance of the GUI has changed, has been incorporated
  into metgui, metsessinfo, meteyeplot, metremote, metraster.
  meteyeplot updated for BETA version of MET, expects eye positions
  and hit regions to be in degrees of visual field, and only
  shows trial events on the time plot. Everything needs testing,
  but write the PTB visual stimulus controller, first.
22/02/2017 - 00.03.88 - Use of the -ivxudp, -ptbdaq, and -cbmex
  flags in .cmet files will be deprecated. metcontroller attempts
  to clear PsychToolbox as part of its shut-down procedure. All the
  same, good MET controller function design will explicitly clear
  PTB when it is used. Somehow, metscrnpar.m was not returning a
  stereo mode for Psych Toolbox ; now it does. metwaitfortrial
  written as a general purpose helper function for controllers
  to block until the next trial starts ; now replaces the
  await_new_trial subroutine of metcbmex. Defined MET controller
  constant MCC.DAT.VNAM containing a list of standard variable
  names for session, block, and trial descriptors ; this is
  important for loading and saving. metdload is a general purpose
  helper function for loading the latest session or trial
  descriptor ; applied to metptb, mettarget, and metrealtimeplot.
  Trial descriptor now includes stimulus definition type in the
  list of stimulus links, metnewtrial now provides this. Added
  checks in metctrlconst so that it runs when met/m is not on the
  Matlab path. metsavtxt didn't use the permission it's given , now
  it does. The metptb MET controller function for tracking the
  state of the trial and generating ptb-type MET stimuli is written
  but untested.
23/02/2017 - 00.03.89 - Added variable parameter checking to 
  metptb. metptb sevents function looped past the end of SEV, and
  compared ptb vector with something of different size. There is no
  need for MEV to be a cell array when it can be a struct array.
  stiminit forgot cellfun UniformOutput false. metptb logical
  vector h should be a column vector, according to 'stim' shm
  convention. metptb some comments clarified. State timeout was
  incorrectly computed. Added endflg to signal an end state was
  encountered. Incorrect index vector of unsent MET signals.
  Loop binary to ASCII data conversion. Updated line 209 try-
  catch statement syntax, then again at 270. mkbuf tried to
  allocate to an index field while creating buffer fields.
  MET GUIs not appearing for some reason.
24/02/2017 - 00.03.90 - It seems that MET GUIs can take so long to
  load that metserver times out while waiting for the initial
  mready reply. The first thing to try is to extend the timeout
  duration from 30s to 60s, in metsrv.h, and recompile metserver.
  metgui now reports loading progress. All controllers now report
  when initialisation is complete. The bad/good news is that the
  MET GUIs appear in the last stable version 00.03.69. Something
  has changed since then that is interfering with graphics.
  metcontroller removes more unused variables before calling the
  MET controller function. The reason the MET GUIs wouldn't show
  up is that drawnow had not been executed. metsessinfo needs to
  check that it has not popped off the edge of the screen.
  metgui will not execute drawnow during a trial unless it has
  been requested by a MET GUI. The check for whether a MET GUI
  has fallen off the screen is moved from metsessinfo to metgui,
  metguicentral, and metrealtimeplot so that no figure ever puts
  its title bar off the edge of the screen where the user can't
  grab it to move it back ; metcheckgui is a helper function that
  does this. Error in metparse! It was comparing a stimulus link
  name against the set of task stimulus names. metstimdeftype
  was looking for task variable names (var) rather than stimulus
  definition names (vpar) when initialising tye type field of the
  session descriptor ; and it was missing MCC input argument.
25/02/2017 - 00.03.91 - metsessdlg newblock was assigning the
  number of repetitions as the number of attempts. tabedit_cb did
  not skip accessing the session descriptor sub-struct when editing
  a task table while the task was still being declared. Environment
  variable table was checking wrong column when validating new
  reward value input. metstimdeftype executed one step too soon
  in metguicentral>session_cb, as it relies on the session
  descriptor .vpar field being set, which it is a step later.
  metguicentral failed to set session descriptor .type field when
  opening an existing session directory. metguicentral's
  parsdirnam and metsubjdlg assign different types to
  sd.experiment_id and sd.session_id ; the former sets string
  copies of the numbers, while the latter sets the numerical
  values. We will make parsdirnam conform to the metsubjdlg
  convention. metguicentral will load session descriptor from
  disk if it is there. Problem persists with appending to an
  existing log file, getting error message:
    met:logopn:fopen: No such file or directory
    MET:print:fopen
    MET ctrl 1:met:logopn: error opening log file
      ~/subject/M100.Nerd/20170225/M100.4.1.2acf_pres.rdk/logs/
      master_log.txt
    Error in metgui (line 625)
  On further thought, this might be because POSIX system calls
  seem unable to interpret command line shorthand, such as ~ for
  the home directory. Changed metctrlconst so that absolute paths
  are provided ; ~ is no longer used to indicate home directory.
  This seems to have been the problem. First attempt to run a trial
  got as far as creating new trial directory and descriptor.
27/02/2017 - 00.03.92 - metptblink>chkfrm used var name sd rather
  than simply d. metptb missing UniformOutput false from cellfun
  that converts stimulus definition function names to function
  handles. metptblink does not watch for mquit when waiting for
  'stim' shared memory. metptb sdl (stimulus descriptor list) was
  initialised as a column vector, but by convention, most other
  data structures inside of metptb are row vectors ; this is
  confusing to certain Matlab functions, so sdl is now a row
  vector. metptb sent initial hit region list but did not clear
  flags. However the animation loop call to met 'write' did not
  give the name of shared memory to use. metptb variable l (lower
  case L) is not initialised at the start of the trial. metptb
  did not perform unit conversion from seconds to microseconds
  before casting doubles to uint32. mettarget now returns empty
  [] matrices in x and y when querying mouse position if no button
  is down, this is in line with the eye position input device which
  may have no valid sample to report ; we do not want to change
  target in these cases. mettarget reversed order of istim twice,
  once while refreshing contents, twice at every check loop ;
  removed reversal at loop, it only needs to be done once during
  refresh. metptb was not converting checksums to strings properly.
  metremote needed to properly report changes to its appearance.
  MET stimulus definition dot.m failed to match its hit region
  to the drawn stimulus because it did not account for the
  formation circle properties. metgui only creates a new trial
  if the MET GUI signal buffer is empty. metgui, reorder tasks in
  the event loop: drawnow execution > make new trial > MET signals
  sent ; the idea is that drawnow might flush the callback event
  queue, which may in turn cause MET signals to appear in the MET
  GUI signal queue, which must halt the creation of a new trial
  until they are sent in case there is an mwait signal that goes
  out. metptb left the old frame on screen when trial finished,
  now it starts an asynchronous flip, completes trial closure, and
  completes the flip. Unless some means can be found of executing
  queued GUI callbacks without running drawnow, it will be
  necessary for metgui to run drawnow while a trial is running.
  Otherwise, metremote will not work. Therefore, lower the
  execution rate during a trial, to ease the burden. metptb was
  treating MAXBUF as a scalar double when checking for buffer
  overflow vs tbuf.ib. metnewtrial was assigning sevent index to
  istimlink. This is the first version that can run a series of
  trials. But it crashes when the trial-block controls are used
  in the MET Session Info GUI.
28/02/2017 - 00.03.93 - metptb state loop sets tout to 1 if the new
  state timeout is zero, but does not add 1 to turn this into an
  index that selects the correct lookup table. metgui was only
  reporting the mreward cargo without applying reward slope and
  baseline. metgui used ~= instead of == operator to check the
  MET Session Info GUI's .guiflg character. Skipping to next block
  by killing the deck in the current block descriptor caused
  confusion in metblock, which tried to access the empty deck; it
  now checks whether the deck is empty and responds appropriately.
  Wrote oddoneout.txt task logic. metptblink timeout warning
  message should not be presented when met 'select' returns due to
  incoming MET signals, rather than a timeout. Added the null MET
  stimulus definition. metsessdlg tried to get variable parameter
  info from the current session descriptor instead of the master
  copy held in the figure's UserData.C.VARPAR struct. Upgrade
  meteyeplot and metrteye to handle touchscreen/mouse input.
  metcontroller attenuates PsychToolbox printed messages. metrteyes
  is able to show hit regions and mouse/touchscreen position but
  seemingly only in 2D plot, while latency is bad.
01/03/2017 - 00.03.94 - metgui creates ASCII .txt version of MET
  signal data. metguicentral not clearing cloned session
  descriptor, causing trial identifier to initialise higher than 1.
  metrteye latency improved by preserving drawnow request from MET
  GUI ; danger was that request came before drawnow deadline,
  allowing another call to GUI update function that returned
  false. meteyeplot now shows mouse position in 2D plot and on time
  course plots. metcontroller now writes controller descriptor to
  the cntlattrib file.
01/03/2017 - 00.03.95 - metptb fails to prepare screen-to-head
  mapping. metctrlconst session descriptor prototype requires that
  .tags field is initialised with an empty cell array {}.
  metsubjdlg now checks if .tags string is empty. metctrlconst
  must initialise current buffer field .shm to empty cell with 2
  columns. meteyeplot accessing cbuf.shm, even when it is empty.
  metsessinfo checks if .tags field of session descriptor is
  empty. metptb tried to use empty .tags field. meteyeplot
  mismanaged converting hit region circle into matlab rectangle.
  metrealtimeplot prevents the MET GUI from ever being closed, it
  also deletes the figure handle, in case the MET GUI close
  function fails. metgui no longer applies reward slope & baseline
  when reporting reward size ; this is done by metptb before
  sending mreward. As a bonus, metptb now checks that all mevent
  cargos are capped at the maximum allowable cargo size. metserver
  error! It has tried to execute:
    metclose ( SHMARG * n , wefd_array )
  where SHMARG is the number of shared memory objects, and n is
  the number of child controllers. metclose returns an error if
  the first argument exceeds MAXCHLD (15) the maximum allowable
  number of MET child controllers. The way around this is to use a
  for loop and close the set of writer's event file descriptors
  made for each shared memory. Added constants to metctrlconst for
  file naming on the Blackrock Micro. Host PC. This version of MET
  was able to support a fixation task driven by fake analogue eye
  signals that were provided by the NSP ; over 2000 trials were
  'performed' by the system.
02/03/2017 - 00.03.96 - Added more NSP related constants to
  metctrlconst. NSP shared memory .data field will now contain
  type double row vectors. Improved metptb ASCII text files so
  that there is no danger of a tailing comma in lists of
  timestamps with a single number. metcontroller flushes standard
  output after opening
  cbmex. metcbmex brought up to date ; it appears to be functional
  and has been able to buffer and store data. Need to test whether
  the whole trial is saved, and whether data is being written to
  nsp shared memory. It is possible that metgui recovery is not
  working properly, including metsessinfo.
03/03/2017 - 00.03.97 - metspkplot written to display scrolling
  spike raster in time with trial events. Performance so far is
  erratic and buggy ; may be that Matlab is incapable of creating/
  destroying a large number of line objects in real time ... may
  be forced to use animated line objects ... or even just one ...
04/03/2017 - 00.03.98 - Reverse order of channel labels in
  metspkplot when first obtained from current buffer. tmax now
  always set to a new GetSecs time measurement. Alas, Matlab can
  not manage the tens of thousands of line objects that are
  required by a full raster plot - we must use an animated line
  object. metcbmex raises a flag if mready trigger obtained in the
  same call to 'recv' that returns an mstop signal ; this way, the
  trial loop proceeds and the controller is not stuck waiting for
  a trigger that arrived. Well, it seems that cbmex
  ( 'trialconfig' , ... , 'absolute' ) does not always produce
  increasing NSP event time stamps ; in fact, it seems that the
  NSP clock is reset to zero every time a new file is opened.
  metcbmex sending illegal mready signals that metserver rejects.
  Something is taking a loooong time during trial initialisation ,
  but not always.
06/03/2017 - 00.03.99 - It turns out that cbmex 'fileconfig' does
  intentionally reset the NSP clock, and 'trialconfig' absolute
  provides time since file recording began. Try a simpler approach
  Continue to estimate the NSP-to-PTB timestamp regression. But
  look in the output from cbmex 'trialdata' for event times. The
  question is then what 'nsp' shared memory should contain ; rather
  than PTB time stamps, have it convert NSP event times from number
  of NSP samples to number of seconds in type double vectors.
  metctrlconst has new constants about cbmex 'trialdata' output
  that says which columns contain digital input time stamps and
  values. metspkplot being re-worked to show only data from 'nsp'
  shared mem and to reset with each new trial , not a continuously
  scrolling plot. To keep from violating the MET signalling
  protocol, metgui will only send mwait signals during the trial-
  running state.
07/03/2017 - 00.03.100 - metgui now searches for the .blockcntl
  field in each listed MET GUI and then concatenates all together
  to pass to metremote's .blockcntl field, thus providing a way to
  enable/disable all controlls that must not be accessed when
  trials are running. metgui now performs reset on all MET GUIs
  when a new session is opened and when a new trial is created, to
  provide session, block, and trial descriptors.
08/03/2017 - 00.03.101 - It is clear that if the touchscreen
  flag is raised in metscrnpar.csv then mouse positions should be
  treated like eye positions i.e. they must be time stamped,
  buffered and provided to all listening controllers. metdaqeye
  will have the job of collecting and transmitting mouse positions
  through 'eye' shared memory, mettarget will use mouse positions
  to assess the subject's target selection, metgui will collect
  mouse positions in a trial buffer, and metrteyes will plot them.
  This is important so that a record can be kept of when/where
  touches occurred. It is also important so that the subjects
  exact responses can be analysed, for instance when computing
  psychometric curves. Implemented but still buggy.
09/03/2017 - 00.03.102 - metgui now saves trial-buffered eye/mouse
  positions as well as stimulus hit regions. metnewtrial unable
  to handle a lack of sevents or mevents. Hit region changes during
  a trial are not being communicated because metptb was only
  detecting changes, but not saving and sending them. Change to
  metgui reset policy required change to metremote, which had a
  reset function written before the MET GUI interface started to
  take concrete form. metperformance being written to show
  psychometric curves and reaction times.
10/03/2017 - 00.03.103 - metperformance now has all graphics
  objects and internal data structures. Responds to user input.
  Now requires update and recovery functions.
13/03/2017 - 00.03.104 - metperformance is largely written. Note
  that no MET GUI yet has a reset function that clears a
  previous session's data. This might be added into metguicentral's
  menu. metperformance is now performing on line, but not yet
  sure how accurately.
14/03/2017 - 00.03.105 - Added negative coherences to rdk_Britten92
  and polarity to dot MET ptb stimulus definitions. Caught a bug
  where rdk_Britten92 could increase coherence without properly
  handling old noise dots, causing new signal dot locations to be
  sampled from noise dots in the wrong patch. Added fflip param
  to dot.m which adds 180 degrees to value in fangle before placing
  dot, if fflip is negative. metperformance tested in basic task.
  Rectangular hit region definition now changed to allow rotated
  stimuli ; metctrlconst and meteyeplot updated , but not
  mettarget.
15/03/2017 - 00.03.106 - mettarget updated. How to test updates?
  Need a new MET stimulus definition. Begin creating a receptive
  field mapping tool with a bar. PTB type MET stimulus definition
  closing function takes a second input argument saying whether
  the trial or session is closing. So far so good. rfmaptool
  written to show mouse-controlled bar. Its hit region shows up
  in meteyeplot, but some 3.5 degrees below where the mouse is.
16/03/2017 - 00.03.107 - 3.5 degree error because subtracting
  tconst.wincentx from vertical position instead of .wincenty.
  rfmaptool can now drop stimulus so that it stays in one place,
  and grab again later. mettestptbstim now suppresses keyboard
  presses being mirrored on Matlab command line. mettestptbstim
  accepts a debug input argument that flags whether keyboard to
  Matlab command line is blocked. rfmaptool now produces a gabor!
17/03/2017 - 00.03.108 - Gabor supports motion of sinusoid. Bar
  supports greyscale change. Dot patch stimulus now supported.
  rfmaptool prints stimulus status if user hits 'h' key. However
  not sure that parameter values make sense e.g. speed values
  seem an order of magnitute too low.
21/03/2017 - 00.03.109 - Starting to add on-line analysis of neural
  activity. Began with extra nsp shared memory constants in
  metctrlconst. Started writing metrftuning , the GUI is now
  created but has no functionality.
22/03/2017 - 00.03.110 - Session descriptor reset and callbacks
  written for metrftuning. Now require update function.
23/03/2017 - 00.03.111 - metperformance did not check whether the
  block descriptor deck value is NaN for the selected task
  variable. metrftuning is written but untested. Starting to write
  custom metanova1 for improved speed.
24/03/2017 - 00.03.112 - Got titles to appear , and user can now
  control which channel/unit tuning curve is displayed.
  metrftuning runs a bit slow. Try using a spike-rate buffer
  instead of accumulating rates on each trial. Also, retool
  metanova1 to act upon a multi-dimensional numerical array +
  group sizes rather than cell arrays of vectors. On further
  reflection, the best solution is to maintain a set of sums for
  each spike-rate group/channel/unit that can be used to compute
  F-values ; this should reduce memory load and increase speed by
  an order of magnitude ; variance will be estimated by subtracting
  the current estimate of the mean from the latest spike rate ; if
  there is only one trial then assume poisson random variable.
  This also means that there is no need for metanova1, so it will
  be removed. Some final refinements will include pre-allocating
  graphics objects during reset, then update their parameters
  without creating whole new objects.
27/03/2017 - 00.03.113 - Started writing metpsth from a copy of
  metrftuning.
30/03/2017 - 00.03.114 - Further work on metpsth. Now has all
  controls. uicontrol callbacks written but not tested. Recovery
  function written but not tested. Need to finish update function,
  population axes button down callback, plotting functions.
31/03/2017 - 00.03.115 - metpsth written but not tested fully.
  A functional version is now made. Need to bring down some of the
  run time. Use a line buffer for error bars and mean rate line,
  then set y-axis data for each.
03/04/2017 - 00.03.116 - Found bug in metpsth where ind2sub used
  wrong number of channels. Channel/unit selector seems to work,
  and selected psth plotter appears to perform the correct 
  averaging. Default bin width set at 50ms instead of 20. update
  function now checks state and bin flags. Execution time of
  metpsth update now under 200ms, on the old development pc.
  Fixed problem with bin sample counting, comparing milliseconds
  and seconds ... really should have stuck to one internal unit.
  Done button automatically 'pressed' by channel/unit selector
  if the bin flag is up. PSTH binning appears to be functioning
  properly, in alignment with events. Added labels and made the
  population axis show the selected units. But popaxe_cb seems to
  be selecting the wrong unit ... or selpsthplot is wrong ... or
  the image forward and reverse index mapping is out.
04/04/2017 - 00.03.117 - metpsth popaxe_cb now sorted, because
  selpsthplot used reverse mapping instead of forward mapping to
  translate figure's .spk row index into image's CData row index.
  Added optional third input argument to metwaitfortrial that
  gives a timeout in seconds ; drawnow is run after each timeout
  until mstart or mquit is finally received. metptb will makes use
  of this to support a very simple GUI control that will provide
  a way for the user to switch timeout screens on and off.
  metptbgui returns this GUI, but hasn't yet got working callbacks.
05/04/2017 - 00.03.118 - Added contrast parameter to timeout
  screen control. Callbacks now written and tested. Next, need to
  integrate into metptb.
06/04/2017 - 00.03.119 - metptbgui worked into metptb.
  metwaitfortrial was checking for durations less than the timout,
  the reverse of what it should be doing. metperformance.m tried
  to use index vector i rather than ivar to access element of the
  block.deck. Timeout screens and GUI controls now tested and
  working. Removing bad hack from metsessdlg, that leaves num2str
  to decide the number of significant figures on its own ; in
  practice it should be recommended that inputs do not exceed
  five significant figures. Added blank greyscale screen to set of
  metptbgui timeout types. rfmaptool now compensates for mirroring
  of the Psych Toolbox window via PsychImaging FlipHorizontal and
  Vertical , but only in position and not in rotation ; this
  relies on proper setting of metscrnpar.csv. rfmaptool now
  supports RF border line drawing.
07/04/2017 - 00.03.120 - Added magnification control to meteyeplot
  that adjusts 2D plot axes down to lower limits, centred on 
  current trial origin. metrftuning recovery data fields out of
  date. metpsth recovery used wrong variable names. Bug
  detected: clicking Abort button while a trial is closing freezes
  the MET remote GUI. This appears to come about because the mwait
  signals that were added to metgui's buffer by metremote were
  stored at the head of the buffer, waiting for a trial that never
  came. Since that was done solely to prevent MET signalling
  protocol breaches during trial initialisation, mwait signals are
  now requested if metgui is in a state other than trial
  initialisation. metptb savedat crashes if a trial is aborted
  before any frames are shown.
10/04/2017 - 00.03.121 - metptb makes a record of the type and
  duration of the timeout screen after each trial. The metping
  set of functions written to support controllers that measure
  the amount of time required to transmit MET signals from one
  controller to another through the MET server controller.
11/04/2017 - 00.03.122 - metpsth spk2bin would check if input
  spike times were empty, but not for case where none of them
  were binnable. metperformance custom response table is covered
  by a slider. metcbmex takes a long time to transmit a text
  version of the trial descriptor ; this is happening when
  metping is running because a large number of MET signals must
  be transferred as comments ; transfer outcome, only, under the
  pretence that all signals are saved in NSP binary input events
  and by metgui. metpsth tries to access PSTH bins that it does
  not have ; the reason is that it did not zero event times on
  the start of the analysis window. metpsth and metrftuning do
  not seem to be getting spike times , but spike data is arriving
  from metgui , though its quality is now in question.
13/04/2017 - 00.03.123 - Make a streamlined version of DaqDOut to
  minimise latency, called metDaqDOut. Use PshychHID directly in
  metdaqout controller function to reduce some overhead.
19/04/2017 - 00.03.124 - Fixed metdaqeye buffer indexing error
  where b.i_eye was updated BEFORE new data was added i.e. data
  was skipping its proper position in the buffer and zeros were
  streaming in the eye position. metptb compensates for
  mirroring and guarantees that the photodiode stimulus is
  always in the upper left-hand corner of the screen.
  metptb guarantees that photodiode stimulus is full white on
  the first frame of every trial.
19/04/2017 - 00.04.00 - BETA version.
20/04/2017 - 00.04.01 - Tweaking the photodiode square in metptb
  to increase size and switch between 1.00 and 0.75 greyscale
  fill values.
25/04/2017 - 00.04.02 - Added ability to pause mettestptbstim
  during execution.
26/04/2017 - 00.04.03 - Add circle and cross choice target MET
  ptb stimuli to met/stim directory.
27/04/2017 - 00.04.04 - calibgrid.m updated for seven column
  square hit region. blank MET ptb stimulus definition added but
  needs thorough testing. mettarget does not seem to be checking
  hit regions in reverse order that stimulus links are listed.
  Actually, mettarget reverse checks task stimuli i.e. the
  abstract labels, not the reverse list of stim links. The
  solution is to change the order of task stimuli in the task
  logic, listing ctarg last. The order matters in the list of
  task stimuli for each state. Appears to have a problem with
  mettarget.m. metctrlconst.m obsolete comments about the
  square hit region column order. mettarget.m was confusing the
  top and bottom of the square hit regions.
02/05/2017 - 00.04.05 - MET Performance GUI update function was
  treating the custom response field as if it were relative to
  the centre of the screen ; it is now relative to the trial
  origin, as intended. A simple, if somewhat memory inefficient
  solution has been implemented to solve this problem with
  metblock:
    
    metblock's use of ismember is a problem when repeated
    values are used in scheduled task variables. Dependent
    scheduled task variables will vary only with the first
    listed instance of each scheduled value of the
    independent variable.
  
  The solution used is to build a copy of the trial deck that
  has the value indices for each scheduled independent variable.
08/05/2017 - 00.04.06 - Eye blink filter added to mettarget.
  metctrlconst now checks OS type before calling met.
22/05/2017 - 00.04.07 - metctrlconst still doesn't run outside
  of Linux environment. Added ismac and ispc checks. Had to
  update MCC.SDEF.ptb.hitregion.ncols = [ 5 , 7 ].
01/06/2017 - 00.04.08 - metptb error setting screentohead
  preferences, accidentally passes -1 as argument to Screen(...).
  The timeout screens cause a convoluted block in the eye shared
  memory ; metptb waits while showing the timeout screen ; in the
  meantime, a new trial is being prepared and mettarget waits for
  the new list of hit regions in stim shared memory ; however,
  metptb can't do this because it's showing a timeout screen ;
  this means that mettarget never clears eye shared memory ; thus
  metrteyes can't get new eye positions while the timeout screen
  is on. Fix this by clearing eye shared memory in metptblink.
15/06/2017 - 00.04.09 - Added mets2i, a custom subscript to linear
  index function ; as opposed to sub2ind, this will allow the use
  of the same kind of subscript indexing as a 2D array. Added MC.mat
  to the met/m directory for use in cross-platform data analysis.
  New MET PTB stimulus definition rdk_Cumming99.m for random dot
  stereograms. mettestptbstim only drew crosshairs in the right-
  eye frame buffer. metpixperdeg.m changed so that pixels per
  degree is calculated from the point of fixation rather than
  spanning the whole field ; there is a non-linear relationship
  due to the slight change in distance from viewer to the edges of
  the screen. Fix to mettestptbstim error message formatting.
  Added Maria Ruesseler's cylinder MET PTB stimulus definition.
27/06/2017 - 00.04.10 - Various bug fixes to new stimulus
  definitions. mettestptbstim makes sure that varpar parameters and
  values are legal.
26/07/2017 - 00.04.11 - Comment out 'Nothing received' message in
  MET's DaqAInScan.m. Adding receptive/response field definitions
  to session descriptor ; requires MET stimulus definitions of type
  'ptb' to alter default variable parameters accordingly ; this
  requires updates to metctrlconst.m, mettestptbstim.m,
  metguicentral.m, metptb.m, metparse.m, metstimdeftype.m, and all
  ptb-type MET stimulus def'n functions, and required a new MET
  GUI metrfmanager.m. Altered metsdpath to allow an optional
  .finalise check during session directory verification, and
  header comments improved. rds_Cumming99 ptb stim def's hitregion
  field was relative to trial origin, not centre of screen.
  metscrnpar.m now allows .touch to be 0, 1, or 2 for no mouse
  input, and mouse input without or with the mouse cursor visible
  in the PTB window. metptb.m now draws defined RFs using the blue
  colour channel, so that red/green anaglyph does not show them.
  meteyeplot.m displays defined RFs as well. rds_Cumming99 has new
  variable parameters fposition and disp_deltasig. mettestptbstim
  hides mouse cursor if metscrnpar.csv requests it. rfmaptool no
  longer calls Hide- or ShowCursor ; it draws a small dot where
  the mouse is located when no stimulus is showing, or when the
  stimulus is dropped and showing. Added regular expressions to
  metctrlconst to check edits in MET session dialogue's task-
  variable Value fields ; added colon-separated list expansion
  to MET session dialogue task-variable Value field. metsimspk
  is a new controller function that generates a spike train
  through audio output with a dynamic spike rate. mettarget
  should check for qflag before using hitregion. Add highlights
  to selected task stimulus in MET real time eye plot. mettarget
  had sudden unexpected error accessing shared memory output
  following advice of met 'select' ; adding error check on the
  output of 'read' to see if empty. Tweaking rfmaptool so that
  bar rotation better reflects how bar looks ; gabor help gives
  sensible orientation and speed ; dot patch gives better speed.
  metguicentral has Reset menu, and metgui watches for and calls
  MET GUI resets ; here, reset means making the MET GUI look as
  though it were freshly loaded, while maintaining any particular
  session, block, or trial data that it has. metsessinfo,
  metperformance (error in tvar_cb), metrftuning, and metpsth
  all now implement reset. metptblink clears readable eye shm if
  waiting for hit-regions, which causes an error in mettarget
  such that shm output of met 'select' is obsolete information
  that might trigger met 'read' on empty shm. metptblink now
  clears 'eye' and 'nsp' shm while waiting for 'stim'.
27/07/2017 - 00.04.12 - Last version made it difficult to clone
  old sessions. For better backwards compatability, metdload now
  has an optional input saying whether to copy a session
  descriptor directly, or field by field. Similarly, metparse
  will now check MET stimulus definition function for the number
  of inputs before using. meteyeplot failed to load list of
  task stimuli if there were no rf definitions.
19/09/2017 - 00.04.13 - rds_Cumming99 MET stim had monocular
  crescent artefacts when disp_deltasig changed during trial,
  and could not handle situation where signal_fraction < 1 but
  disp_signal not zero, and could not handle very small signal
  disparities and signal fractions less than one because not
  all RDSs had covered background dots to make visible while
  balancing the dot count, error computing first row index of
  noise dots following disp_deltasig change when signal
  fraction less than 1 and disp_signal non-zero. Added
  uncorrelated background and noise dots to rds_Cumming99,
  independent binary on/off flicker for the two monocular
  images, tweak dot lifetime to round to nearest frame. Also
  added hminrad variable parameter to rds_Cumming99. corr_sig
  and corr_noise parameters renamed to more intuitive
  anticor_sig and anticor_noise, while new anticor_back added
  for variable number of anticorrelated background dots, all
  in rds_Cumming99. rds_Cumming99 only correlated noise dots
  (by position, not contrast) sample random disparities, but
  that sample is taken once during initialisation i.e. the
  same noise disparities are used for a whole trial. Order
  that dots drawn is randomly permuted in rds_Cumming99.
  Gave task logic oddoneout.txt reactim state a 1 second
  timeout. metptblink.m now waits up to 10s when waiting for
  hit regions before issuing a warning message ; also, error
  in code corrected for checking shm list when it has more
  than one row. MET ptb stimulus definition dot.m now use
  default variable parameter values of shade=1.0, frate=5.0,
  and radius=0.15 ;  stimulation function now disables alpha
  blending before draw. New metscrnpar.csv parameters defining
  the photodiode square and PTB priority levels, implemented by
  metptb. metptb saves random number generator state following
  stimulus descriptor initialisation but prior to running
  trial. metptb ASCII data file has field name for Matlab
  version string. MET GUIs keep their position between uses of
  MET, includes changes to MET controller functions metgui,
  metrealtimeplot, and metptb. metptb disables alpha blending
  prior to drawing RF ovals and photodiode square. Improved
  installation instructions at top of the readme.txt file.
  metsessdlg text labels no longer cropped, and Add All button
  added. Added the singrating MET PTB stim definition. Larger
  linewidth for RF rectangles in meteyeplot. Added rds_bisect,
  a random-dot stereogram with two halves at different
  disparities. metnewtrial does not crash when task has no
  default parameter overrides. Added the c.util directory ;
  added ivxudp utility for UDP-based eye-position streaming
  from iViewX into Matlab. Adding support for pupil diameter
  streaming and storage ; includes changes to MET controller
  constants, metgui, and big internal overhall to metdaqeye and
  metdaqeye.csv. Added MOUSEPOLL sampling rate variable ;
  affects metdaqeye and meteyeplot. Trial descriptors now have
  a field containing a struct whose fields are named after the
  task variables and contain the value of each task variable on
  that given trial.
  
  rds_Cumming99 gets rid of distinction between central signal
  and noise dots ; rather all central dots get the signal
  disparity , then some fraction receives noisy disparity ; as
  such the disp_noise parameter has been removed ; noise dots
  are required to exist within RDS centre , after signal disp
  shift , in both monocular images otherwise they are discoed.

  metctrlconst MCC.SHM.NSP.SPKLAB is now '^(chan|elec)\d+$' to
  accomodate alternative naming of front-end channels ; added
  CRASHF and CRASHS constants with the name of a crash file
  that is written to a trial directory following recovery from
  a crash, and a format string that is written to it.

  XYSWAP added to metdaqeye.csv

  metgui now saves environment variables in recovery data.
  
  metguicentral updated header to support new metscrnpar
  parameters.

  MET controllers flush standard output at end of
  initialisation.

  metguicentral fails to update date in sd when sd loaded from
  file , solution is to parse sd from scratch then load old sd
  if it's there and copy over only the essentials , the .rfdef
  and .evar fields ;

  metcbmex now makes sure that Central File Storage application
  is open before completing initialisation ; incorrectly
  created trial number string for cbmex comment ; comment
  header now only lists task variable values ; rsbuf was in
  danger of resizing the tbuf.coef field ; added tbuf.timer
  field to help check for clock calibration timeout during
  trial initialisation ; File Storage crashed if the file name
  became 10.* , so added prefix trial_<id>.* ;
  
  metgui finalises NSP data with only data from the trial that
  just ran ; previously, lagging data would be buffered. Also
  tries to wait for lagging data before finalising trial
  buffer, but will time out and carry on to next trial ;
  handles recovery by writing crash message file to crashed
  trial directory rather than removing that directory, then
  increments trial identifier by one to skip to next trial.
  
  metpsth indexing error comparing digin signal value index
  to value + cargo index of the raw data ; imgpop.CData
  indexing got out of register when updating from
  h.UserData.spk ; forward mapping used where reverse mapping
  required in plotting function and button down callback ;
  all bins' trial count incremented on all trials, otherwise
  trailing bins can appear to have gigantic mean firing
  rate ; suppressed annoying caxis output ; checks for lack
  of digin signals , time and value mismatch , or too many
  mstart signals ; recovery data has all required info and
  recovery replots data , causes next 'sd' reset to be
  skipped ; can handle elec1-23 style NSP labels
  
  metrftuning did not check whether previously selected task
  variable still existed in task var set of a new session ;
  had same digin signal value indexing error as metpsth ;
  strange error that is difficult to reproduce when setting
  position of red rectangle , an error check has been added
  in attempt to avoid this in future ; dd not recover the
  properties uicontrols from a crash ; same digin error
  checking as metpsth ; recovery data has all required info
  and recovery replots data , causes next 'sd' reset to be
  skipped ; can now handle when independent scheduled var
  has only one unique value ; can handle elec1-23 style
  NSP labels
  
  metspkplot now has readable y-axis tick labels. Added
  checks for too many mstart or mstop events. Suspected
  CereLink cbmex bug causes some digin signals to come
  without their cargo and causing a crash. Testing seems
  to show that this only happens with mstop signals. It
  probably breaks down when trial events change very
  quickly, faster than a real subject can respond,
  unless the eye position is hovering on the edge of a
  hit region. Handling of digin signals cleaned up ; this
  should be much more robust than before.
  
  met/stim/resources directory added for stim def special
  files, like images and movies. Removed met/m/legacy and
  met/m/calgrid.m but not met/stim/calibgrid.m.

  Added meterror to help MET GUIs to properly bring down
  the calling MET controller.
  
  Added hit region flag saying whether or not to ignore the
  stimulus ; affects metctrlconst, mettarget, meteyeplot,
  and all MET PTB stimulus definitions

  metcbmex sends shorter comments, because v6.04 of
  Blackrock software drops anything longer.

  metptb draws black photodiode square on synchronising
  flip. RF outlines commented out because they could be
  seen.

  Added delta_orient parameter to singrating MET PTB
  stim def on 28/09/2017, such a minor addition will not be
  cause for a new version.
  
  Added sca to initialisation of metptb in attempt to clear
  residue following a crash ; added .monovis to singrating,
  rds_Cumming99, rds_edge, and dot stimuli that flags which
  monocular images are visible ; added disparity and
  delta_disp properties to singrating ; additions made on 
  02/10/2017 to version 4.13b.
  
  Extra metptb message regarding current process priority.
  singrating uses an eighth of the support "texels" that it
  used to, in attempt to speed up drawing. Added 04/10/2017
  to version 4.13c.

09/10/2017 - 00.04.14 - metdaqeye.m now has a maximum rate of
  writes to eye shared memory, in attempt to reduce the load
  on kernel latency, attempt to reduce skipped frames. New
  task logic delayedsaccade.txt for a delayed saccade task.
  
  Added rfmapbar MET PTB stimulus definition 10/10/2017.
11/10/2017 - 00.04.15 - metxflush.c now flushes the log file
  stream, if it exists. rfmapbar prints messages that are
  captured by metptb's log file, and metptb creates a log
  file for each session. rdk_Britten92 now adapts to the
  rfdef input. metxflush takes optional argument saying
  which streams to flush. cylinder_rotation.m now adapts to
  more rfdef fields.
16/10/2017 - 00.04.16 - Added met.stim.class sub-directory
  to met/stim and added MET controller constant
  MCC.CLASSDIR to locate it. rds_Cumming99_handle.m class
  file added and used in rds_Cumming99. metcontroller
  disables JxBrowser, which may cause spikes in Matlab's
  cpu consumption ; but this does not prevent really bad
  skipped frames. singrating MET PTB stim now uses the
  minimum necessary texture support size and ignores
  sevents that change width ; disparity was double that
  specified. Added chpa( ) utility to check the memory
  address of an array's real data. Minor change to
  rds_Cumming99 rnddot sub-function that *should* help to
  reduce memory usage. metptb java.lang.System.gc( ) in
  an attempt to force garbage collection by background
  Java memory management between trials. oddoneout.txt
  task logic now places fix at the end of the task stim
  list of each state, so that associated hit regions are
  checked first.
11/11/2017 - 00.04.17 - Added rfmaprdk MET ptb stimulus
  definition for mouse-controlled random dot patch. 
  metguicentral copies RF definition data into the header
  files. Tweaked metsubjdlg so that session id can be 1
  when experiment id is manually changed. Added
  rds_simple MET ptb stimulus definition , which reduces
  the memory and processing load for larger RDS patches.
  
  4.17a changes rds_simple so that the dot-buffer column
  permutation is sampled only during initialisation or
  sevents.
29/11/2017 - 00.04.18 - Expanded list of Matlab Linux
  command line options to include -desktop,
  -noFigureWindows, -nodisplay, -debug, -singleCompThread,
  -nouserjavapath, -softwareopengl, -nosoftwareopengl.
  rds_simple MET ptb stim def updates colour lookup table
  buffer only during initialisation and sevents rather
  than on each frame when there are anti-correlated dots.
  Added robustness to metcontroller close_resources sub-
  function so that -nojvm flag can be used without a
  crash when Java-dependent resources are not available.
  Added targ to edge from delay to broken state in the
  delayedsaccade task logic to prevent looking at sacc.
  target before saccade state. rds_simple tapers
  disparity noise towards zero as the dot nears the
  edge of its region, rather than rejecting the dot if
  one monocular image falls off the edge.
  
  00.04.18a - rfmaprdk has new variable parameters
    visible and click_enable for event-driven control
    of stimulus visibility. Its position is un-mirrored
    when stimulus screen mirroring is enabled.
    
  00.04.18b - metpsth added try-catch statement to stop
    line 659 from crashing until this can be properly
    fixed. metreadcsv now checks read-in values before
    feeding them to str2double , in case they already
    are doubles. mettarget now reads velocity and
    acceleration thresholds from mettarget.csv, along
    with a threshold scaling term and the blink filter
    duration.
01/04/2018 - 00.04.19 - mettestptbstim opens PTB
  window in lower-right quadrant when there is only
  one screen detected. metdaqeye now mirrors mouse
  positions if metscrnpar.csv hmirror or vmirror is
  non-zero ; fixed error that blocked mouse polling
  when eye samples unavailable. rds_simple code
  improvements to handling rfdef. cylinder_simple MET
  ptb simulus definition and supporting
  cylinder_simple_handle class added to generate dot
  cylinder stimulus like Dodd et al. 2001. rds_motion
  MET ptb stimulus definition and supporting
  rds_motion_handle class added to provide moving
  dots at different disparities for RF tuning a
  conjunction of motion and disparity.
16/07/2018 - 00.04.20 - Added MET ptb stimulus def
  movie_advisor. metptb initsdlc queried number of
  sd.task.( taskname ) fields NOT the number of
  sd.task.( taskname ).link fields , thus we did
  not get the number of stimulus links.
  mettestptbstim runt returns final version of
  stimulus descriptors for final call to fclose.
  Added metbasic system shell command that calls
  metbasic in a Matlab session ; for really basic
  experiments. rds_motion will run in monoscopic
  mode, but ignores disparity and delta_disp
  values, pegging them to zero ; so does
  rds_simple. Added oddoneout_MRI.txt to master
  met/tasklogic set of task logic files.
  metmridaq MET controller added to record MRI
  voltage output indicating each volume of a
  BOLD-fMRI collection sequence, for later
  synchronisation of MET/PTB events with MRI
  data. metptb checks for error when no shared
  memory is provided in cmet file. rds_simple had
  fprint not fprintf in warning about stereo mode.

  17/07/2018 - 00.04.20b Includes binaries
  recompiled in Ubuntu 18.04 with GCC 7.3.0
  and Linux kernel 4.15.0-23-generic

  18/07/2018 - 00.04.20c Fixes movie_advisor to
  only close movie resources at the end of a trial.
  Otherwise, session closure invokes the closure of
  an invalid movie handle, leading to a crash. Adds
  movie.cmet to run a copy of default.cmet where
  metptb runs with a full Matlab desktop environment
  that must be minimised. This is necessary to make
  PTB Gstreamer movies run on Matlab R2018a in
  Ubuntu 18.04.

05/02/2019 - 00.04.21 - Adds #include <sys/time.h>
  to met.h because compiler could no longer find
  gettimeofday( ) in Ubuntu 18.04 ... don't know
  what changed since Ubuntu 14.04. Had to move
  function prototypes from met.c to metx.h and
  add prototypes for remaining metx* functions;
  met now compiles in Matlab R2018b without any
  warnings or errors (except for the usual Matlab
  complaing about gcc versions). Had to include
  <arpa/inet.h> and <unistd.h> in invudp.c.
  Moved #include <string.h> from metx.h to met.h.
  metserver.c now declares shmfn as const char **.
  metrsv.h now has met* support function prototypes.

  Still getting compile warning although we have
  included unistd.h and fcntl.h in header files.
  
  $ gcc  *.c  -o metserver  -lrt
    metpipe.c: In function ‘metpipe’:
    metpipe.c:102:11: warning: implicit declaration of
    function ‘pipe2’; did you mean ‘pipe’?
    [-Wimplicit-function-declaration]
    if  ( pipe2 ( fd , flags )  ==  -1 )
          ^~~~~
          pipe
  
  When shutting down MET we are getting a fatal
  error and one of the child MATLABs is killed.
  
  00.04.21a - Adds #define _GNU_SOURCE to the top
  of met.h and removes from metsrv.h where it had
  been incorrectly placed ; this solves the implicit
  declaration warning for pipe2.

11/03/2019 - 00.04.22 - Added task logic
  matchtosample.txt and ptb stimulus definition bar.m

06/04/2019 - 00.04.23 - Added met/m/metgui.csv with
  options to enable serial port output at the start
  and end of each trial. This is to allow metgui.m to
  start and stop trial recording on a peripheral system
  (like Blackrock Microsystems' Cerebus) without
  launching a whole other MET child controller. Make
  sure that the system has a serial port, or add a USB
  to Serial converter e.g. StarTech.com #ICUSB2321F USB
  to Serial RS232 adapter. Added IOPort (  'CloseAll'  )
  to metcontroller.m close_resources( ).

06/05/2019 - 00.04.24 - metgui sends out Serial stop
  signal following arrival of mstop signal, but after
  all other mstop related tasks plus 20ms, to allow the
  recording equipment time to register end-of-trial data.
  dot.m adds the halfmoon parameter. Applied fix to
  rds_simple.m that keeps ratio of white:black dots
  close to 50% ; before, random shuffling was sometimes
  producing ratios that were visibly different from
  50%.

31/05/2019 - 00.04.25 - Updated all task logic files so
  that the fix stimulus is the last one drawn but the
  first one to be compared against the eye/touch position.

28/06/2019 - 00.04.26 - Implemented rds_ogle.m MET
  stimulus definition. New oddoneout_det.txt task logic
  definition for deterministic stimuli.

10/10/2019 - 00.04.27 - Added trigger ptb stimulus def'n
  for driving photodiode TTL signals in synchrony with
  stimulus events. Masking square added to metscrnpar,
  metptb, and metptbgui so that an event photodiode is
  not activated by background colour. metcbmex now has
  an additional wait period after opening a new file
  for recording, to prevent dropped data; FOPDUR const
  added to metctrlconst for that purpose. metptbgui
  now handles stereo eye buffers and allows resizing.

06/12/2019 - 00.04.28 - Add new parameter to metscrnpar.*
  defseed instructs metptb to reset Matlab's random number
  generator to the default seed at the start of each trial.
  This exists so that control experiments can be done in
  which the identical dot sequence is presented on each
  trial.

*** Fix alpha blending of metptb and rfmaptool rf outlines ***
*** metgui buffers signals from old trial ***
*** rfmaptool gets screwed up between trials ***
*** rds_Cumming99 dies if surround radius is 0 ***
*** Some unknown problem with metrftuning in session switch ***
*** Some unknown problem with creating procedural sin grating after session switch ***
  
  
  TO-DO in order of importance:
  ---------------------------- BETA -----------------------------
  - metrftuning fails reset when task variable set changes
    between sessions. Uses old taskvar name versus new task var
    set. See freset case 'sd' and taskvar_cb.
  - Latency testing of MET signals between MET controllers, and
    in a loop from NSP to MET to NSP.
  - A nice extension to met ( 'select' , ... ) would be the ability
    to provide a list of additional file descriptors to listen to
    e.g. a socket with incoming eye position data
  - MET subject GUI is erratic , can't handle system with no subject
    often gets the experiment and session ID wrong until manually
    refreshed
  - Does metgui clear first trial if no recovery data saved yet???
  - meteyeplot would crash if hit region for a given stimulus
    were to change shape or number.
  - metxwrite.c can assume that program runs in MEX mode, thus
    NULL returned by mxGetCell means unset element, not lack of
    heap memory. This can be handled differently, by immediately
    writing type and dims as empty double. Likewise, when reading 
    with metxread.c , simply skip empty arrays and leave unset ;
    but check this first with a test function.
  - For some arcane reason, MET controller names cannot be too
    long or else metchkargv() thinks that there is a problem
    when there isn't. This should not happen.
  - There is a small problem with metsd2str in which real numbers
    are rounded up to 4 decimal places by num2str. This can be
    confusing when a variable uses a value at the edge of a
    variable parameter's range.
  - metguicentral would not die on error in metgui unless an
    explicit delete ( figure handles ) was added to the
    metcontroller cleanup function ... even though it executes
    the exit command ... perhaps it doesn't if a figure still
    exists and returns to the command line
  
  Bugs:
  - metsessdlg.m , block list box Value goes to [] at uknown time
  

