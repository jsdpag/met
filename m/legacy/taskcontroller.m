
function  taskcontroller( sessiondir , ptbwin )
% 
% taskcontroller( sessiondir , ptbwin )
% 
% 
% A generic function for controlling the order and presentation of trials.
% 
% In brief, the task is described by a set of states that support an
% abstract set of stimuli. Concrete descriptions of each stimulus are
% separately provided, but these are mapped to each task stimulus. Thus,
% when a trial enters a state that presents the ith task stimulus, then all
% concrete stimuli that i maps to are shown. Blocks of trials are
% generated according to the definition provided ; a given block may use
% any task, any concrete stimuli, and vary any set of stimulus parameters
% from trial to trial.
% 
% 
% Input
% 
% sessiondir - string - Directory where all output will be written. Must
%   also contain a copy of each function provided for the following
%   parameters. This is to force documentation of the exact task, blocks,
%   mappings, and stimuli that were used in a language that both humans and
%   Matlab can read.
%
% ptbwin - A PTB window descriptor prepared by metlegtrg.
%
%
% The session directory must contain the following m-files:
%   
%   subj.m - Returns the subj struct, see below.
%   blockdef.m - Returns the block struct array, see below.
%   screenpar.m - OPTIONAL - Returns an spar struct, see below.
%   Any task and stimulus m-files referenced in blockdef.m
% 
% subj - struct - Describes essential information about the subject,
%   including fields
%   
%   .id - string - An anonymous subject identifier.
%   .dist_mm - numeric scalar - The distance of the subject's pupil from
%     the surface of the screen, in millimeters. [ Ignored ]
%   .reward_s - numeric scalar - The duration of reward pump activation on
%     correct trials, in seconds.
% 
% spar - struct - Describes the physical parameters of the screen. This
%   overrides Screen ( 'DisplaySize' ) when it is known to be wrong. spar
%   includes fields [ Now set by metscrnpar ]
%   
%   .width - The width of the screen, in millimeters.
%   .height - The height of the screen, in millimeters.
% 
% block - struct array - Defines the trial block structure, including
%   which stimuli are used and what their parameters are.
% 
% block(i) - the ith block of trials
%   
%   .origins - numerical, 4 element vector or N x 2 matrix - Used to
%     define the stimulus-drawing point of origin within the screen. A
%     different origin will be sampled, for variation in the absolute
%     position of stimuli. If a 4 element vector is given, then it will
%     have the format [ left edge , top edge , right edge , bottom edge ]
%     defining a box in degrees relative to the top-left of the screen. Any
%     origin may be sampled from within its bounds. The matrix format
%     provides a list of N points that are randomly sampled, with the
%     column order being [ x position , y position ] in degrees from the
%     top-left of the screen.
%     
%     See [ RectLeft , RectTop , RectRight , RectBottom ]
% 
%   .stim_map - struct array, row vector 1 x N - Describes the mapping
%     between each task stimulus and concrete stimulus descriptors. It is
%     required that all index vectors contained therein are sorted
%     ascending.
%   
%     stim_map(j) - Map for the ith task stimulus
%       .con - integer vector - indeces of concrete stimuli that map to the
%         jth abstract task stimulus.
%       .par - The corresponding index for the stimulus's parameter struct
%         array.  Thus stimulus .con(k) uses its .par(k)'th parameter set.
%   
%   .task_d - function handle - Returns a task descriptor struct with
%     information about the task and its behaviour.
% 
%   .stim_d - cell array of M elements - Contains stimulus descriptor
%     functions. One per concrete stimulus.
%   .stim_d{j} - function handle - Stimulus descriptor function. Returns
%     default parameters and trial initialiser, drawing, checksum, and
%     closing functions.
%   
%   .stim_par - cell array - contains parameter struct arrays for each
%     stimulus listed in .stim_d.
%   .stim_par{j} - struct array - The parameters for stimulus j, to be used
%     in this block of trials.
%   
%   .stim_var - cell array - one element per concrete stimulus - Describes
%     how to sample variable stimulus parameters from trial to trial.
%   .stim_var{j} - N x 1 struct array - Sampling schedule for jth concrete
%     stimulus. Make this an empty struct of the right kind if there are no
%     variable parameters for a given stimulus.
%   .stim_var{j}(k) - The kth variable parameter of the jth concrete
%     stimulus. Describes if it is sampled independently, or dependently on
%     a reference parameter.
%     
%     .param - string - Names the variable parameter. Must be in the set of
%       parameters from the stimulus descriptor function.
%     .pari - scalar integer - index of stimulus's parameter set.
%     .values - numeric vector - The set of values to sample from.
%     .rule - scalar integer - The sampling rule. 0 sample independently. 1
%       use the same value as the reference. -1 use any value other than
%       what the reference is using. If 0 then the .ref_* fields aren't
%       used and can have any place-holder value.
%     .ref_stim - scalar integer - Index of .stim_par, identifying the
%       reference stimulus containing the reference parameter.
%     .ref_par - string - Names the reference parameter.
%     .ref_pi - scalar integer - index of ref stim's parameter set.
%
%   .stim_schedule - one element struct - Describes hard-wired schedule of
%     parameter values per trial. These are presented in a randomised
%     order. If a trial is ignored, broken, or aborted then the parameters
%     are randomly reshuffled into the deck.
%     
%     .rep - scalar integer - Repetitions of the given schedule deck to
%       present in each block. 
%     .attempts - scalar integer - The number of times a single set of
%       parameters will be reshuffled into the deck following broken
%       trials. Doesn't count for ignored or aborted.
%     .sind - integer vector - N elements, one for each parameter in the
%       schedule. .sind(i) is the ith index that references corresponding
%       elements in .stim_d and .stim_par.
%     .pind - integer vector - N elements, one for each parameter in the
%       schedule. .pind(i) is the ith index that references which stimulus
%       parameters in .stim_par{ .sind(i) } to set. If 0, then the
%       scheduled value is applied to all .stim_par{ .sind(i) }( : ) sets.
%     .params - cell array vector of strings - N elements, names which
%       parameters to set. .params{i} refers to the same stimulus as
%       .sind(i) and .pind(i).
%     .deck - M x N double matrix - The set of scheduled parameter values.
%       Each record (row) describes the parameter values on a single trial.
%       Each field (column) corresponds to an element of .sind, .pind, and
%       .params. For example, .deck( m , n ) describes the value of
%       parameter .params{ n } in parameter set .pind( n ) for concrete
%       stimulus .sind( n ) ; while .deck( m , n + 1 ) describes the value
%       of the next parameter on the same trial.
% 
% 
% Output
% 
% In general, two copies are made of all output. A binary copy in Matlab's
% .mat format. And an ASCII text file. The .mat copy will contain 
% 
% 
% Dependencies
%   
%   Software - The following functions must be available: firsttrue,
%     qintersec, foutchar, runtimeplot
%   Hardware - Any DAQ must be PTB compatible
% 
% 
% Note: Assumes square pixels in the display. Also assumes that
%   Screen( 'displaysize' ) is accurate. Best to measure screen manually.
% 
%   About recovery. Looks for the hidden finalisation file. This is only
%   written when the session is ended on purpose. Also looks for recovery
%   file. Absence of the first and presence of the second indicates that we
%   need to enter a recovery state. This is automated to speed recovery.
% 
% 
% Version - 00.01.00 - First working version.
%           00.02.00 - OSX version with DAQ reward interface
%           00.03.00 - New task descriptor logic implemented. Records all
%             vbl, stim on, and flip time stamps & state change times.
%             Refresh random number generator each session. Record rng
%             state on every trial just before stimulus instantiation.
%           00.04.00 - Simplify stimulus and block descriptors. No longer
%             uses struct array of stimulus parameters, just a simple one
%             element struct.
%           00.05.00 - Added header output writer. Added trial output
%             writer. Log file added, uses Matlab's diary mode to capture
%             input and output.
%           00.06.00 - Recovery support. Saves a critical set of variables
%             afer every trial, which are reloaded after a crash.
%           00.07.00 - Supports multi-parameter-set concrete stimuli, and
%             one-to-many task to concrete stimulus mapping with parameter
%             indeces. Variable duration task state timeout supported. stim
%             initialiser gets sum of state timouts per parameter set.
%           00.08.00 - trial scheduling. Load subj and blockdef from
%             session directory
%           00.09.00 - run-time plots, writes footer
%           00.09.01 - Sets higher real-time priority at onset of drawing,
%             and switches it off after drawing. Fixes in struct2str to
%             handle empty structs. Priority change commented out, as this
%             seems to slow down everything without reducing missed frames
%             much.
%           00.09.02 - First version to go hot in live training. Tweaked to
%             run on user parkergroup of macmini setup, as of 2015-11-09.
%           00.09.03 - Stop saving Screen Flip timestamps on ignored
%             trials. Only check targeted stimulus against the present
%             state's task stimuli.
%           00.09.04 - Added optional debug argument
%           00.09.05 - Modular pointer to taskcontrol directory, platform
%             specific remove path.
%           00.09.06 - If only one monitor is detected then the PTB window
%             does not fill the whole screen.
%           00.10.00 - Modularise subject's input device. Add optional
%             screen.m function to session directory, for when
%             Screen ( 'DisplaySize' ) is wrong. Multiple directory checks
%             for taskcontroller functions. User-independent way of
%             checking for taskcontrol directory.
%           00.10.01 - Introducing the null target -1. Variable 'targeted'
%             is set to null target by default on every frame. This way, 0
%             can mean that no task stimulus is selected, although some
%             kind of fixation was reported.
%           00.10.02 - Header writer now recognises udp objects.
%           00.10.03 - Makes explicit the use of normalised colour values,
%             between 0.0 and 1.0. Switches off alpha blending of newly
%             opened PTB window. It is up to concrete stimulus draw
%             functions to set the appropriate alpha blending for that
%             stimulus.
%           00.10.04 - Has a new input argument 'stereo' for opening
%             psych-toolbox window in stereoscopic anaglyph mode , red left
%             and green right.
%           00.10.05 - New indev abilities to buffer user input and pass to
%             trial descriptor for saving , or to an online plot. New indev
%             also specifies how many samples in a row must land on the
%             same target to initiate a target switch. Uses new run time
%             plot with subject response figures.
%           00.11.00 - Looks for a specific DAQ USB-1208fs for triggering
%             reward delivery. struct2str can now handle logical arrays.
%             No longer polls indevd.check before indevd.init is run. If
%             it is necessary to make sure a device is in readiness then
%             it is the job of .init to make sure it is ; e.g. that the
%             touchscreen is not being touched or that some input buffer
%             has been flushed.
%           00.12.00 - Retrofitted to run with Matlab Electrophysiology
%             Toolbox. In particular, it sends and receives MET signals,
%             it reads from 'eye' shared memory, and it writes to 'stim'
%             shared memory. Other MET controllers running in parallel
%             handle the USB-DAQ units to read eye positions and drive
%             the reward pump.
% 
%   To do - blockdef validation function
%         - Set/unset top priority for drawing
% 
% 
% Written by Jackson Smith - Oct 2015 - DPAG, University of Oxford
% 
  
  
  %%% Pre-initialisation %%%
  
  % Try to force Matlab to recognise new versions of files
  rehash
  
  
  %%% Global constants %%%
  
  % MET constants and MET timer object
  global  MC  MTIM
  
  
  %%% Constants %%%
  
  TCINFO.name = 'taskcontroller' ;
  TCINFO.version = 'v00.12.00' ;

  % Stimulus parameter sampling rules. 0 independent variable, 1 same value
  % as reference, -1 different value from reference
  SVRULE.IND  = +0 ;
  SVRULE.REF  = +1 ;
  SVRULE.NREF = -1 ;
  
  % Outcome character codes. Write these to header, for clarity.
  OUTCHAR = foutchar ;
  
  % Subject file name
  FNSUBJ = 'subj.m' ;
  
  % Block definition file name.
  FNBLKD = 'blockdef.m' ;
  
  % Logfile name
  LOGNAME = 'log.txt' ;
  
  % Header and footer file name base
  HEADNAME = 'header' ;
  FOOTER = 'footer' ;
  
  % Trial directory
  TRIALDIR = 'trials' ;
  
  % Recovery file name
  RECFILE = 'recovery.mat' ;
  
  % Recovery variables, save periodically and load after a crash.
  RECVAR = { 'rec' ;
              'bc' ;
   'stim_schedule' ; 
               't' ;
           'tally' ;
        'rng_last' } ;
	
	FINFILE = '.finalised' ;
  
  % MET root directory trial number file name
  METTRIAL = fullfile ( MC.ROOT.ROOT , MC.ROOT.TRIAL ) ;
  
  % Reward key code , send mreward MET signal when user presses this key
  RDKEYC = KbName ( 'r' ) ;
  
  
  %%% Check input %%%
  
  % Old wording directory
  oldpwd = pwd ;
  
  % Check session directory
  checkin ( sessiondir , { FNSUBJ , FNBLKD } , FINFILE )
  
  % Go to session directory.
  cd ( sessiondir )
  
  % Retrieve subject and trial block information
  subj = checksub( FNSUBJ( 1 : end - 2 ) ) ;
  subj.dist_mm = getfield ( metscrnpar , 'subdist' ) ;
  
  % Retrieve and validate the block definition
  block = checkblock( FNBLKD( 1 : end - 2 ) ) ;
  
  
  %%% Initialise variables %%%
  
  % Block counter.
  bc = 0 ;
  
  % Trial counter.
  t = 0 ;
  
  % Tally, how many trials with each outcome
  tally = tallyinit ( OUTCHAR ) ;
  
  % Recovery counter.
  rec = 0 ;
  
  % Keyboard flag.
  nokb = true ;
  
  % Make trial descriptor structure
  trial_d = trialdescriptor ;
  
  
  %%% Initialise environment %%%
  
  % Create trial output directory
  if ~isempty( dir( TRIALDIR ) )
    % Skip attempt to make directory
  elseif ~mkdir( TRIALDIR )
    error( 'taskcontroller:mkdir:can''t make %s in %s' , TRIALDIR , pwd )
  end
  
  % Check recovery state
  recover = isempty( dir( FINFILE ) ) && ~isempty( dir( RECFILE ) ) ;
  
  % Open log file
  diary( LOGNAME ) ;
  
  % Random number generator. Get initial state for header.
  rng( 'shuffle' )
  trial_d.rng = rng ;
  trial_d.rng_check(:) = rand( size( trial_d.rng_check ) ) ;
  
  
  %%% Psych Toolbox Initiation %%%
  
  % This is now done during metlegctl initialisation
  
  % Convert blockdef origins from degrees of visual field to pixels, in
  % absolute coordinates.
  block = convertorigin( block , ptbwin ) ;
  
  
  %%% Open run-time plot %%%
  
  hrtp = runtimeplot ( [] , [] , [] , [] , ptbwin ) ;
  
  
  %%% Run task %%%
  
  % Write header file
  if ~recover
    write_header( HEADNAME , TCINFO , SVRULE , OUTCHAR , ...
      subj , ptbwin , block , trial_d.rng , trial_d.rng_check )
  end
  
  % Wait for operator to start
  noexit = prompt ( RDKEYC , subj.reward_s ) ;
  
  
  % Master loop - Produce one block of trials after another
  while noexit
    
    % Block index
    b = mod( bc , numel( block ) ) + 1 ;
    
    % Count block
    bc = bc + 1 ;
    
    % Initialise stimulus schedule
    stim_schedule = stimschedinit( block( b ).stim_schedule ) ;
    
    
    % Check recovery state. It's here because the system would have gone to
    % the while statement after saving the recovery file, but it crashed
    if recover
      
      % Don't need to recover any more
      recover = ~recover ;
      
      % Load variables
      load( RECFILE , RECVAR{:} )
      
      % Count this recovery attempt
      rec = rec + 1 ;
      
      % Set random number generator
      rng( rng_last )
      
      % Let the world know
      fprintf( ...
        '\nATTEMPTING RECOVERY %i FOLLOWING TRIAL %i BLOCK %i\n\n' ,...
        rec , t , bc )
      
    end % recovery
    
    
    % Loop trials until the block is spent, or the user hits the keyboard
    while  stim_schedule.rep  &&  nokb  % &&  ~KbCheck( -1 )
      
      % Count trial
      t = t + 1 ;
      
      % Choose a point of origin
      ptbwin.origin = rndorigin( block( b ).origins ) ;
      
      % Sample variable stimulus parameters
      block( b ).stim_par = rndparams( block( b ) , SVRULE ) ;
      
      % Set scheduled stimulus parameters
      block( b ).stim_par = schedparams( stim_schedule , block( b ) ) ;
      
      % Gather trial data
      trial_d.trial(1) = t ;
      trial_d.block_count(1) = bc ;
      trial_d.block_index(1) = b ;
      trial_d.stim_par = block( b ).stim_par ;
      
      % Update ~/.met/trial with current trial number
      fileID = fopen ( METTRIAL , 'w' ) ;
      fprintf ( fileID , '%d\n' , t ) ;
      fclose ( fileID ) ;
      
      % Run the trial
      [ trial_d , nokb ] = trialcontroller ...
                              ( ptbwin , block ( b ) , trial_d , RDKEYC ) ;
      
      % Reward handling
      trial_d.reward_s(1) = ptbdaqpulse( subj.reward_s , ...
        trial_d.outcome == OUTCHAR.CORRECT ) ;
      
      % Count the outcome
      tally.( trial_d.outcome ) = tally.( trial_d.outcome ) + 1 ;
      
      % Count down remaining trials in this block
      stim_schedule = ...
        shuffdeck( stim_schedule , block(b) , trial_d.outcome , OUTCHAR ) ;
      
      % Writing trial output file
      write_trial( trial_d , TRIALDIR , OUTCHAR )
      
      % Maintain current state of the experiment, for recovery from a crash
      rng_last = rng ;
      save( RECFILE , RECVAR{:} )
      
      % Update run-time plot
      hrtp = runtimeplot ( hrtp , tally , t , trial_d , ptbwin ) ;
      
    end % trial loop
    
    % Prompt user for instructions if keyboard was hit , keep MET IPC clear
    % in the meantime
    if ~nokb
      start ( MTIM )
      noexit = prompt ( RDKEYC , subj.reward_s ) ;
      nokb = true ;
    end
    
  end % master loop
  
  
  %%% Shut down %%%
  
  % Write footer
  write_footer ( FOOTER , OUTCHAR , t , tally )
  
  % Make it known
  fprintf( 'FINALISING SESSION\n\n' )
  
  % Suspend logging
  diary off
  
  % Finalisation file. No more writing to this directory
  if system( [ 'touch ' , FINFILE ] )
    warning( 'taskcontroller:finalisation:failed to set %s' , FINFILE )
  end
  
  % Recursively close and lock the session directory.
  if system( 'chmod -R a-w .' )
    warning( 'taskcontroller:chmod:failed a-w %s' , pwd )
  end
  
  % Go back to original directory
  cd( oldpwd )
  
  % Show cursor again
  ShowCursor ;
  
  % Delete old runtimeplot
  delete ( hrtp.fig )
  
end % taskcontroller


%%% SUBROUTINES %%%

function [ td , nokb ] = trialcontroller ( ptbwin , block , td , RDKEYC )
  
  
  %%% Global variables %%%
  
  global  MC MSID MOUT
  
  
  %%% Synchronise with MET controllers %%%
  
  % Reward request flag , used in animation loop
  mreward = false ;
  
  % Initialise keyCode , table of keys currently being pressed
  [ ~ , ~ , keyCode ] = KbCheck( -1 ) ;
  
  % Generate mready trigger , non-blocking
  if  ~ met ( 'send' , MSID.mready , MC.MREADY.TRIGGER , [] )
    
    error ( 'MET:metlegctl:mready' , ...
      'metlegctl: failed to send mready trigger' )
    
  end
  
  % Wait for it to come back
  n = 0 ;
  while  ~ n
    
    % Blocking read
    [ n , src , sig , crg ] = met ( 'recv' , 1 ) ;
    
    if  any ( sig == MSID.mquit )
      
      % Time to shut down
      error ( 'MET:GO:SHUTDOWN' , '' )
      
    elseif  ~ any (  src == MC.CD  &  ...
                     sig == MSID.mready  &  ...
                     crg == MC.MREADY.TRIGGER  )
      
      % No mready trigger returned , set n to keep looping
      n = 0 ;
      
    end
  
  end % wait for mready trigger
  
  
  %%% Variable memory allocation and initialisation %%%
  
  % Try to avoid run-time delays by forcing memory allocation, even for
  % scalars.
  
  
  %-- counter and time variables --%
  
  % Concrete stimulus index
  c = 0 ;
  
  % Stimulus parameter index
  p = 0 ;
  
  % Date and time string
  td.date = datetimestr( clock ) ;
  
  % The number of frames presented since the synchronising frame
  td.stim_frames(1) = 0;
  
  % The number of stable states encountered so far
  td.eventc(1) = 1 ;
  
  % Duration in time between the onset of the first frame and the latest
  % frame.
  td.stim_dur(1) = 0 ;
  
  % The latest vbl time stamp
  vbl_latest = 0 ;
  
  % touttime is allocated and initialised after the set of state
  % descriptors is returned
  
  
  %-- Stimulus variables --%
  
  % Flag raised when the set of hit boxes for visible stimuli should be
  % written to 'stim' MET shm.
  metshm = true ;
  
  % Point of origin on screen
  td.origin( : ) = ptbwin.origin ;
  
  % Currently targeted task stimulus. Defaults to null target
  targeted = -1 ;
  
  % and the corresponding hit box of the mapped concrete stimulus
  hitbox = 0 ;
  
  % Mapping of task-stimulus index to concrete stimulus indeces
  stim_map = block.stim_map ;
  
  % The reverse mapping
  smapr = revmap( stim_map ) ;
  
  
  %-- Task variables --%
  
  % Task descriptor
  task_d = block.task_d() ;
  
  % Record current task name
  td.task = task_d.name ;
  
  
  %-- State variables --%
  
  % Initial state of task
  s = 1 ;
  
  % The set of state descriptors
  states = task_d.states ;
  
  % Check each state descriptor.
  for i = 1 : numel( states )
    
    % Try to force Matlab to load the task's state-descriptor functions
    % into memory now, rather than in the draw loop.
    states( i ).fendcon( 0 ) ;
    states( i ).fnext( 0 , 0 ) ;
    
    % If any timeouts are function handles then get the return value.
    if isa ( states( i ).timeout , 'function_handle' )
      states( i ).timeout = states( i ).timeout () ;
    end
    
  end % state descriptors
  
  % Record the timeout constants for each state in this trial
  td.state_timeouts = [ states.timeout ] ;
  
  % Time relative to synchronising vbl time stamp when the current state
  % times out
  touttime = states( s ).timeout ;
  
  
  %%% Buffer memory allocation %%%
  
  % Allocate buffers large enough to record all vbl time stamps and state
  % changes in the longest possible trial, given a linear progression
  % through all states listed in the set of state descriptors.  Since the
  % task may loop between states, we cannot know for sure how long the
  % trial will be. The draw loop will check for buffer overruns and resize
  % them at need.
  
  % VBL time stamps. Does not include the initial synchronising stamp,
  % before and the draw loop
  [ td.vbl_trial , vblbuf_add ] = ...
    vblbuffer( states , ptbwin.flipinterval ) ;
  
  % Stimulus onset time stamp buffer. Second output from Screen Flip
  td.stim_trial = zeros( vblbuf_add , 1 ) ;
  
  % Flip time stamp. Third output from Screen Flip
  td.flip_trial = zeros( vblbuf_add , 1 ) ;
  
  % Missed frames output buffer.
  missed_frame = 0 ;
  
  % Missed frame flags. True if missed.
  td.missed_frames = false( vblbuf_add , 1 ) ;
  
  % Records the first frame number of each trial event i.e. stable state
  % switch. Allocate the next power of two.
  evntframbuf_add = 2 ^ ceil( log2( numel( states ) + 1 ) ) ;
  td.event_frame = zeros( evntframbuf_add , 1 ) ;
  td.event_frame( 1 ) = 1 ;
  
  % The order of stable states.
  % While the trial is active, we will record only the corresponding index
  % of 'states'. After the trial, we will convert this to a cell array of
  % state names.
  td.events = zeros( evntframbuf_add , 1 ) ;
  td.events( 1 ) = s ;
  
  % The task stimulus that was targeted at the onset of each stable state.
  td.event_targ = zeros( evntframbuf_add , 1 ) ;
  
  % To be more precise, record also the index of the hit box that the task
  % stimulus mapped to, as this will identify which part of the concrete
  % stimulus was targeted by the subject.
  td.event_hitbox = zeros( evntframbuf_add , 1 ) ;
  
  % mtarget buffer , remembers which task stimulus was selected and when
  td.mtarget = struct (  'n' , 0 , ...
    'taskstim' , zeros ( 100 , 1 ) , 'ptbtime' , zeros ( 100 , 1 )  ) ;
  
  
  %%% Instantiate concrete stimuli %%%
  
  % Concrete stimuli each have a specific descriptor that says how the
  % stimulus will be drawn by Psych Toolbox. Each concrete stimulus is
  % mapped to an abstract task stimulus.
  
  % Get current state of random number generator before instantiating
  % stimuli, for accurate replication of the stimulus
  td.rng = rng ;
  
  % Include a short sample of the pseudo-random number sequence, just to
  % see if you can replicate it later
  td.rng_check(:) = rand( size( td.rng_check ) ) ;
  
  % Get check sums from stimulus initialisation. When replicating the
  % stimulus later, you should be able to replicate this exact number.
  td.stim_chksum_start = zeros( size( block.stim_d ) ) ;
  td.stim_chksum_stop = zeros( size( block.stim_d ) ) ;
  
  % Stimulus descriptors
  sd = cell( size( block.stim_d ) ) ;
  
  % Animation loop stimulus drawing functions
  fdraw = cell( size( block.stim_d ) ) ;
  
  % Check sum functions of stimulus descriptor.
  fchksum = cell( size( block.stim_d ) ) ;
  
  % End of trial stimulus close functions
  fclose = cell( size( block.stim_d ) ) ;
  
  % Get parameter / duration list for each concrete stimulus
  pardur = durlist( states , stim_map ) ;
  
  % Store hit boxes for each stim
  td.hitbox = cell ( 1 , numel( block.stim_d ) ) ;
  
  % for each concrete stimulus
  for i = 1 : numel( block.stim_d )
    
    % Gather stimulus function handles.
    [ ~ , trialinit , fdraw{i} , fchksum{i} , fclose{i} ] = ...
      block.stim_d{i}() ;
    
    % Generate stimulus trial descriptor.
    sd{i} = trialinit( block.stim_par{i} , pardur{i} , ptbwin ) ;
    
    % Try to force Matlab to load the drawing function into memory now,
    % rather than in the draw loop.
    fdraw{i}( 1 , 0 , ptbwin.flipinterval , sd{i} ) ;
    
    % Compute starting checksum
    td.stim_chksum_start( i ) = fchksum{ i }( sd{ i } ) ;
    
    % Get hitboxes
    td.hitbox{ i } = sd{ i }.hitbox ;
    
  end % stimuli
  
  % Clear the frame buffer before anything is drawn.
  if  ptbwin.STEREOMODE
    for  i = 0 : 1
      Screen ( 'SelectStereoDrawBuffer' , ptbwin.ptr , i ) ;
      Screen( 'FillRect' , ptbwin.ptr , ptbwin.background ) ;
    end
  else
    Screen( 'FillRect' , ptbwin.ptr , ptbwin.background ) ;
  end
  
  
  %%% Make sure that keyboard is released %%%
  
  % Wait
  nokb( 1 ) = false ;
  while  ~ nokb
    
    % See if a key is pressed
    [ nokb( 1 ) , ~ , keyCode( : ) ] = KbCheck( -1 ) ;
    nokb( 1 ) = ~ nokb ;
    
%%%TESTING%%%
met ( 'print' , sprintf ( 'nokb: %d , keyCode ( %d ) %d' , ...
  nokb , RDKEYC , keyCode ( RDKEYC ) ) , 'e' )
%%%TESTING%%%
    
    % The reward key is down and the reward key deadline has been met
    if  keyCode ( RDKEYC )
      
      % Send reward request , non-blocking , one flip interval's worth
      met ( 'send' , MSID.mreward , 1e3 * ptbwin.flipinterval , [] ) ;
      
      % Wait one flip interval
      WaitSecs ( ptbwin.flipinterval ) ;
      
    end % reward request
    
  end % wait for key release
  
  % Is keyboard down?
  nokb( 1 ) = ~KbCheck( -1 ) ;
  
  
  %%% CRITICAL REGION STARTS %%%
  
  %-- Synchronise with MET controllers --%
  
  % Generate mready reply , non-blocking
  if  ~ met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] )
    
    error ( 'MET:metlegctl:mready' , ...
      'metlegctl: failed to send mready reply' )
    
  end
  
  % Wait for mstart
  n = 0 ;
  while  ~ n
    
    [ n , ~ , sig ] = met ( 'recv' , 1 ) ;
    
    if  any ( sig == MSID.mquit )
      
      % Time to shut down
      error ( 'MET:GO:SHUTDOWN' , '' )
      
    elseif  ~ any ( sig  ==  MSID.mstart )
      
      % No mstart , keep looping
      n = 0 ;
      
    end
  
  end % wait for mstart
  
  
  %-- Start times --%
  
  % A time measurement that can be compared between trials.
  td.start_s(1) = GetSecs ;
  
  % Initial flip to synchronise us to VBL at start of animation loop.
  [ td.vbl_zero(1) , ...
    td.stim_zero(1) , ...
    td.flip_zero(1) ] = Screen( 'Flip' , ptbwin.ptr ) ;
  
  % Initialise the latest vbl time.
  vbl_latest(1) = td.vbl_zero ;
  
  
  %-- Animation loop --%
  
  % While the keyboard is not being pressed.
  while nokb
    
    
    %-- Check for MET signals --%
    
    % Non-blocking read
    [ n , ~ , sig , crg , tim ] = met ( 'recv' ) ;
    
    % Signals received
    if  n
      
      % mquit received , shutdown controller
      if  any ( sig  ==  MSID.mquit )
        error ( 'MET:GO:SHUTDOWN' , '' )
      end
      
      % Otherwise , look for the latest mtarget signal. Have to subtract 1
      % from cargo because 0 is out of range ; see metlegtrg.
      i = find (  sig  ==  MSID.mtarget  ,  1  ,  'last'  ) ;
      sig = sig ( i ) ;  crg = crg ( i ) - 1 ;  tim = tim ( i ) ;
      
      
      %-- Find targeted task stimulus --%
      
      if  ~ isempty ( sig )
        
        % No target selected
        if  ~ crg

          targeted( 1 ) = 0 ;

        else
          
          % Map to the corresponding task stimulus. There may be many.
          % Constrain by the present task state's set of task stimuli.
          % NOTE! Pass only sorted data!
          targeted(1) = qintersec ( smapr{ crg } , states( s ).stim ) ;
          
        end
        
        % Next free space in buffer
        i = td.mtarget.n  +  1 ;
        
        % Buffer mtarget
        td.mtarget.n( 1 ) = i ;
        td.mtarget.taskstim( i ) = crg ;
        td.mtarget.ptbtime ( i ) = tim ;
        
      end % mtarget
      
    end % MET signals
    
    
    %-- State handling --%
    
    % Will the current state time out before the next frame is shown?
    td.timedout(1) = touttime <= td.stim_dur + ptbwin.flipinterval ;
    
    % Check for state end condition.
    if td.timedout || states( s ).fendcon( targeted )
      
      % Find the next state. Assume that targeted is still valid.
      % Search until a stable state is found.
      while true
        
        % This will be a valid states index, not an ascii code. Because we
        % end the trial before this line executes with an end state.
        s( 1 ) = states(s).fnext( td.timedout , targeted ) ;
        
        % Either end state or stable state was found, break the loop.
        if states( s ).isend || ~states( s ).fendcon( targeted )
          break ;
        end
          
      end % state search
      
      
      % Count that another state was enountered during the trial
      td.eventc(1) = td.eventc + 1 ;
      
      % Determine when the new state times out
      touttime(1) = td.stim_dur + ptbwin.flipinterval + ...
        states( s ).timeout ;
      
      
      % Check event buffers, and resize at need
      if numel( td.event_frame ) < td.eventc
        td.event_frame = [ td.event_frame ;
                           zeros( evntframbuf_add , 1 ) ] ;
        td.event_targ = [ td.event_targ ; zeros( evntframbuf_add , 1 ) ] ;
        td.event_hitbox = ...
          [ td.event_hitbox ; zeros( evntframbuf_add , 1 ) ] ;
        td.events = [ td.events ; zeros( evntframbuf_add , 1 ) ] ;
      end
      
      
      % Update event buffers.
      
      % The first frame that the new state is active in. If this is an end
      % state, then this will map to the final synchronising Screen Flip
      % following the draw loop.
      td.event_frame( td.eventc ) = td.stim_frames + 1 ;
      
      % The targeted task stimulus
      td.event_targ( td.eventc ) = targeted ;
      
      % and the corresponding hit box index
      td.event_hitbox( td.eventc ) = hitbox ;
      
      % Index of the new state's descriptor.
      td.events( td.eventc ) = s ;
      
      
      % End state encountered. End the trial.
      if states( s ).isend , break , end
      
      % Otherwise , write the next set of hit boxes to 'stim' MET shm
      metshm( 1 ) = 1 ;
      
    end % state handling
    
    
    %-- Draw to frame buffer --%
    
    % Another frame is about to be shown.
    td.stim_frames(1) = td.stim_frames + 1;
    
    % Is there drawing to do?
    if states(s).stim
      
      % For each task stimulus.
      for i = states(s).stim

        % Find which concrete stimuli it maps to, and loop them.
        for j = 1 : numel( stim_map( i ).con )
          
          % Find concrete stimulus index
          c(1) = stim_map( i ).con( j ) ;
          
          % Find stimulus parameter index
          p(1) = stim_map( i ).par( j ) ;
          
          % Execute stimulus's drawing function.
          sd{c} = fdraw{c} ( td.stim_frames , ... % frame count
                                td.stim_dur , ... % time to last frame on
                        ptbwin.flipinterval , ... % frame flip interval
                                      sd{c} , ... % stim state descriptor
                                          p ) ;   % parameter-set index

        end % concrete stimuli

      end % task stimuli
    
    end % draw block
    
    % Done drawing, let PTB know so it can work while we check buffers.
    Screen( 'DrawingFinished' , ptbwin.ptr ) ;
    
    
    % Write hitboxes to 'stim' MET shared memory , for presentation by
    % metlegeye alongside eye positions
    if  metshm
      
      % Locate visible stimuli
      I = [ stim_map( states(s).stim ).con ] ;
      H = cell ( size ( I ) ) ;
      
      % Collect hit boxes into one cell array
      for i = 1 : numel ( I )  ,  H{ i } = sd{ I( i ) }.hitbox ;  end
      
      % And write them to shm , non-blocking. We could use a better
      % solution to buffer hit boxes until they can be written. This is
      % simple, and should usually work.
      if  met ( 'write' , 'stim' , H , I )
      
        % Lower flag
        metshm( 1 ) = 0 ;
      
      end
      
    end % write to 'stim' shm
    
    % Reward requested by user , send MET signal and lower flag , the
    % requested duration will be for one flip interval
    if  mreward
      met ( 'send' , MSID.mreward , 1e3 * ptbwin.flipinterval , [] ) ;
      mreward( 1 ) = 0 ;
    end
    
    % Check if there is still space in the buffers. Resize at need.
    if numel( td.vbl_trial ) < td.stim_frames
      td.vbl_trial = [ td.vbl_trial ; zeros( vblbuf_add , 1 ) ] ;
      td.stim_trial = [ td.stim_trial ; zeros( vblbuf_add , 1 ) ] ;
      td.flip_trial = [ td.flip_trial ; zeros( vblbuf_add , 1 ) ] ;
      td.missed_frames = [ td.missed_frames ; false( vblbuf_add , 1 ) ] ;
    end
    
    i = numel ( td.mtarget.taskstim ) ;
    if  td.mtarget.n  ==  i
      td.mtarget.taskstim = [  td.mtarget.taskstim  ;  zeros( i , 1 )  ] ;
      td.mtarget.ptbtime  = [  td.mtarget.ptbtime   ;  zeros( i , 1 )  ] ;
    end
    
    
    % Flip the screen and record all time stamps, plus PTB's estimate of
    % whether the frame was missed
    [ td.vbl_trial( td.stim_frames ) , ...
      td.stim_trial( td.stim_frames ) , ...
      td.flip_trial( td.stim_frames ) , ...
      missed_frame(1) ] = ...
        Screen( 'Flip' , ptbwin.ptr , vbl_latest + ptbwin.halfflip ) ;
    
    % Missed frame flag
    td.missed_frames( td.stim_frames ) = 0 < missed_frame ;
    
    % Update the latest vbl time.
    vbl_latest(1) = td.vbl_trial( td.stim_frames ) ;
    
    % Duration since onset of first frame.
    td.stim_dur(1) = td.stim_trial( td.stim_frames ) - td.stim_trial( 1 ) ;
    
    
    % Last thing, check keyboard.
    [ nokb( 1 ) , ~ , keyCode( : ) ] = KbCheck( -1 ) ;
    
    % Reward key is pressed
    if  keyCode ( RDKEYC )
      
      % So raise 'no keyboard' flag
      nokb( 1 ) = 1 ;
      
      % And request a new reward
      mreward( 1 ) = 1 ;
      
    % Otherwise, we always flip the value of nokb
    else
      
      nokb( 1 ) = ~ nokb ;
      
    end % keypress check
    
    
  end % animation
  
  
  %-- Final time measurements --%
  
  % Check if there is still space in the buffer. Resize at need.
  if numel( td.vbl_trial ) == td.stim_frames
    td.vbl_trial = [ td.vbl_trial ; 0 ] ;
    td.stim_trial = [ td.stim_trial ; 0 ] ;
    td.flip_trial = [ td.flip_trial ; 0 ] ;
    td.missed_frames = [ td.missed_frames ; 0 ] ;
  end
  
  % Index of the stop frame
  td.stop_frame(1) = td.stim_frames + 1 ;
  
  % Terminal buffer swap
  [ td.vbl_trial( td.stop_frame )  , ...
    td.stim_trial( td.stop_frame ) , ...
    td.flip_trial( td.stop_frame ) , ...
    missed_frame(1) ] = ...
      Screen( 'Flip' , ptbwin.ptr , vbl_latest + ptbwin.halfflip ) ;
  
  % Clock time
  td.stop_s(1) = GetSecs ;
  
  % Missed frame flag
  td.missed_frames( td.stop_frame ) = 0 < missed_frame ;
  
  
  %-- Synchronise with MET controllers --%
  
  % Load mstop cargo with trial outcome
  if ~nokb
    
    % If keyboard was hit then the trial was aborted
    crg = MOUT.aborted ;
    
  % Otherwise, map the end state's ascii code
  else
    
    switch  states(s).fnext( td.timedout , targeted )
      
      case  'c'  ,  crg = MOUT.correct ;
      case  'f'  ,  crg = MOUT.failed ;
      case  'i'  ,  crg = MOUT.ignored ;
      case  'b'  ,  crg = MOUT.broken ;
      
    end
    
  end % load cargo
  
  % Send mstop with trial outcome , non-blocking
  if  ~ met ( 'send' , MSID.mstop , crg , td.stop_s )
    
    error ( 'MET:metlegctl:mstop' , ...
      'metlegctl: failed to send mstop' )
    
  end
  
  % Wait for it to come back
  n = 0 ;
  while  ~ n
    
    [ n , src , sig ] = met ( 'recv' , 1 ) ;
    
    if  any ( sig == MSID.mquit )
      
      % Time to shut down
      error ( 'MET:GO:SHUTDOWN' , '' )
      
    elseif  ~ any (  src == MC.CD  &  sig == MSID.mstop )
      
      % No mstop returned , set n to keep looping
      n = 0 ;
      
    end
  
  end % wait for mstop
  
  
  %%% CRITICAL REGION ENDS %%%
  
  
  %-- Free PTB memory and reset PTB default environmental parameters --%
  
  for i = 1 : numel( sd )
    
    % Get last checksum before anything can happen to the state descriptor.
    td.stim_chksum_stop( i ) = fchksum{ i }( sd{ i } ) ;
    
    % Release PTB resources and reset environment.
    fclose{i}( sd{i} , ptbwin )
    
  end
  
  
  %%% Trial outcome and other results %%%
  
  % If keyboard was hit, ...
  if ~nokb
    
    % ... then show that the trial was aborted
    td.outcome(1) = ptbwin.ABORTC ;
    
  % Otherwise, ...
  else
    
    % ... translate end state's ascii code to char
    td.outcome(1) = char( states(s).fnext( td.timedout , targeted ) ) ;
    
  end
  
  % Compute duration of the trial according to direct clock readings
  td.dur_s(1) = td.stop_s - td.start_s ;
  
  
  %-- Compute trial duration from synchronising time stamps --%
  
  % First, truncate the unset tail of the time-stamp buffers
  td.vbl_trial = td.vbl_trial( 1 : td.stop_frame ) ;
  td.stim_trial = td.stim_trial( 1 : td.stop_frame ) ;
  td.flip_trial = td.flip_trial( 1 : td.stop_frame ) ;
  td.missed_frames = td.missed_frames( 1 : td.stop_frame ) ;
  
  % Compute duration from onset of the first stimulus frame
  td.vbl_dur(1) = td.vbl_trial(end) - td.vbl_trial(1) ;
  td.stim_dur(1) = td.stim_trial(end) - td.stim_trial(1) ;
  td.flip_dur(1) = td.flip_trial(end) - td.flip_trial(1) ;
  
  
  %-- Finalise event buffers --%
  
  % Truncate unset tails
  td.event_frame = td.event_frame( 1 : td.eventc ) ;
  td.events = td.events( 1 : td.eventc ) ;
  td.event_targ = td.event_targ( 1 : td.eventc ) ;
  td.event_hitbox = td.event_hitbox( 1 : td.eventc ) ;
  
  td.mtarget.taskstim = td.mtarget.taskstim ( 1 : td.mtarget.n ) ;
  td.mtarget.ptbtime  = td.mtarget.ptbtime  ( 1 : td.mtarget.n ) ;
  
  % Get event vbl, stim on, and flip time stamps
  td.event_vbl = td.vbl_trial( td.event_frame ) ;
  td.event_stim = td.stim_trial( td.event_frame ) ;
  td.event_flip = td.flip_trial( td.event_frame ) ;
  
  % Convert stimulus decriptor indeces into state names, naming each event
  % in chronological order of occurrence
  td.events = sind2name( td.events , states ) ;
  
  
end % trialcontroller


function events = sind2name( ind , states )
  
  % allocate output
  events = cell( size( ind ) ) ;
  
  % for each state, in sequence of presentation
  for i = 1 : numel( ind )
    
    % retrieve state's name, to name the order of events
    events{ i } = states( ind(i) ).name ;
    
  end % loop events
  
end % sind2name


function pardur = durlist( states , stim_map )
  
  
  %%% CONSTANTS %%%
  
  PAR = 1 ;
  DUR = 2 ;
  
  
  %%% Setup %%%
  
  % Concrete stimulus list
  con = [ stim_map.con ] ;
  con = con( : ) ;
  
  % Parameter list
  par = [ stim_map.par ] ; 
  par = par( : ) ;
  
  % unique concrete stimulus indeces
  C = unique ( con ) ;
  
  % Allocate output
  pardur = cell ( max( C ) , 1 ) ;
  
  for i = 1 : numel ( C )
    c = C( i ) ;
    p = unique( par( con == c ) ) ;
    pardur{ c } = [ p , zeros( size( p ) ) ] ;
  end
  
  
  %%% Count durations %%%
  
  % Loop states and accumulate timeouts per stimulus parameter set
  for i = 1 : numel ( states )
    
    % Task stimuli
    t = states( i ).stim ;
    if ~t , continue , end
    
    % concrete stimuli
    con = [ stim_map( t ).con ] ;
    
    % parameter sets
    par = [ stim_map( t ).par ] ;
    
    % handle each concrete stimulus
    for j = 1 : numel ( con )
      
      c = con( j ) ;
      p = pardur{ c }( : , PAR ) == par( j ) ;
      
      pardur{ c }( p , DUR ) = pardur{ c }( p , DUR ) + ...
                               states( i ).timeout ;
      
    end % concrete
    
  end % states
  
  
end % durlist


function [ b , vblbuf_add ] = vblbuffer( sset , fint )
  
  % Number of frames in the longest trial without looping.
  n = ceil( sum( [ sset.timeout ] ) / fint ) ;
  
  % Next power of 2.
  n = ceil( log2( n ) ) ;
  
  % Make buffer an order of magnitude bigger than what we seem to need.
  % Convert to decimal. This is how much we add to buffer each time that it
  % resizes.
  vblbuf_add = 2 ^ ( n + 1 ) ;
  
  % Allocate the buffer.
  b = zeros( vblbuf_add , 1 ) ;
  
end % vblbuffer


function d = ptbdaqpulse( s , give )
  
  % MET signal identifiers , defined in metlegctl
  global  MSID
  
  % No correct performance
  if  ~ give
    d = 0 ;
    return
  end
  
  % Convert from seconds to milliseconds
  ms = round ( 1e3  *  s ) ;
  
  % Send reward request , non-blocking
  if  ~ met ( 'send' , MSID.mreward , ms , [] )
    
    % No mreward sent
    d = 0 ;
    warning ( 'MET:metlegctl:reward' , ...
      'metlegctl: failed to send mreward in taskcontroller>ptbdaqpulse' )
    
  else
    
    % Assume that metdaqout will deliver an accurate reward
    d = s ;
    
  end
  
end % ptbdaqpulse


function smapr = revmap( stim_map )
  
  % Return cell array where index is concrete stimulus, and vector lists
  % task stimulus indeces.
  
  
  %%% CONSTANTS %%%
  
  % Column indeces for list, task and concrete stimuli
  TAS = 1 ;
  CON = 2 ;
  
  
  %%% Build a list of each mapping %%%
  
  % We assemble in cell array, but get matrix of [task,concrete]
  list = cell( numel( stim_map ) , 1 ) ;
  
  for i = 1 : numel( stim_map )
    n = numel( stim_map(i).con ) ;
    list{ i } = [ i * ones(n,1) , stim_map(i).con(:) ] ;
  end
  
  list = cell2mat( list ) ;
  
  
  %%% Build reverse mapping %%%
  
  % Concrete stimulus indeces
  c = unique( list( : , CON ) ) ;
  
  % Allocate output
  smapr = cell( size( c ) ) ;
  
  % Gather reverse mapping
  for i = 1 : numel( c )
    j = list( : , CON ) == c( i ) ;
    smapr{ i } = list( j , TAS ) ;
  end
  
  
end % revmap


function stim_par = schedparams( stim_schedule , block )
  
  % Initialise output
  stim_par = block.stim_par ;
  
  % Number of scheduled parameters
  n = numel( stim_schedule.sind ) ;
  
  % Walk through and set the current scheduled parameters
  for i = 1 : n
    
    % Convenient 'pointers'
      s = stim_schedule.sind( i ) ;
      p = stim_schedule.pind( i ) ;
    par = stim_schedule.params{ i } ;
      d = stim_schedule.deck( 1 , i ) ;
    
    stim_par{ s }( p ).( par ) = d ;
    
  end
  
end % schedparams


function stim_par = rndparams( block , SVRULE )
  
  % Initialise output
  stim_par = block.stim_par ;
  
  N = numel( stim_par ) ;
  
  % Sort the sampling rules according to dependency. Independent variables
  % are queued first, then progressively dependent variables.
  % Q{i,1} number of variable parameters in ith stimulus. Q{i,2} sampling
  % rules.
  Q = cell( N , 2 ) ;
  
  % Load queue, unsorted
  for i = 1 : N
    
    % Make vector indexing stimulus i, for each rule
    n = numel( block.stim_var{ i } ) ;
    Q{ i , 1 } = i * ones( n , 1 ) ;
    
    % Sampling rules
    Q{ i , 2 } = block.stim_var{ i } ;
    
  end
  
  % Tranform into an index vector and struct vector.
  S = cell2mat( Q(:,1) ) ;
  Q = cell2mat( Q(:,2) ) ;
  
  % Initialise sort set to look for independent variable parameters
  I = [ Q.rule ] == SVRULE.IND ;
  
  % Loop through dependency tree
  while ~isempty( I )
    
    % Sample the sub set of ready parameters
    for i = find( I )
      
      % Reference stimulus index
      stm = Q(i).ref_stim ;
      
      % Reference stimulus parameter
      par = Q(i).ref_par ;
      
      % Reference stimulus parameter index
      pi = Q(i).ref_pi ;
      
      % Find the set of values we can sample from.
      val = Q(i).values ;
      
      % Remove reference value
      if Q(i).rule == SVRULE.NREF
        j = val ~= stim_par{ stm }( pi ).( par ) ;
        
      % Keep only the reference value
      elseif Q(i).rule == SVRULE.REF
        j = val == stim_par{ stm }( pi ).( par ) ;
        
      else
        j = true( size( val ) ) ;
        
      end % keep valid values
      
      val = val( j ) ;
      
      % Specify parameter
      stm = S(i) ;
      par = Q(i).param ;
      pi = Q(i).pari ;
      
      % Sample its value
      j = ceil( numel(val) * rand ) ;
      stim_par{ stm }( pi ).( par ) = val( j ) ;
      
    end % sampling
    
    % Find parameters dependent on current set I that we just sampled for.
    J = false( size( I ) ) ;
    
    for i = 1 : numel( Q )
      
      if I( i ) , continue , end
      
      J(i) = any( ...
        Q(i).ref_stim == S(I) & strcmp( Q(i).ref_par , { Q(I).param }' )...
        ) ;
      
    end
    
    % Handle the new set
    J = J( ~I ) ;
    S = S( ~I ) ;
    Q = Q( ~I ) ;
    
    I = J ;
    
  end % dependency tree
  
end % rndparams


function y = rndorigin( X )
  
  % Size of .origins
  s = size( X ) ;
  
  % N x 2 format, randomly chose a row
  if s(2) == 2
    
    i = ceil( rand * s(1) ) ;
    y = X( i , : ) ;
    
  % 1 x 4 format, randomly choose a point within the box
  else
    
    % Idex edges.
    w = [ RectLeft , RectRight ] ;
    h = [ RectTop , RectBottom ] ;
    
    % Random values, scaled to width and height of origin box.
    y = diff( [ X( w ) ; X( h ) ]' ) .* rand( 1 , 2 ) ;
    
    % Adjust positions.
    y = y + X( [ w(1) , h(1) ] ) ;
    
  end
  
end % rndorigin


function  s = shuffdeck( s , b , outcome , OUTCHAR )
  
  % Count down number of attempts if the trial was broken
  if  outcome == OUTCHAR.BROKEN
    s.attempts( 1 ) = s.attempts( 1 ) - 1 ;
  end
  
  % Pop off the top of the deck if the trial was correct or failed, or when
  % the number of attempts has been spent
  if  outcome == OUTCHAR.CORRECT  ||  outcome == OUTCHAR.FAILED   ||  ...
      ~s.attempts( 1 )
    
    % pop
    s.attempts = s.attempts( 2 : end ) ;
    s.deck = s.deck( 2 : end , : ) ;
    
    % handle empty deck
    if isempty( s.deck )
      
      % update number of repetitions
      s.rep = s.rep - 1 ;
      
      % quit if block is spent
      if ~s.rep , return , end
      
      % new deck and return, remember old rep number
      s = stimschedinit( b.stim_schedule , s.rep ) ;
      return
      
    end % new rep
    
  end % pop deck
  
  % Reshuffle unless the trial was correct or failed
  if  outcome ~= OUTCHAR.CORRECT  &&  outcome ~= OUTCHAR.FAILED
    
    % Get a random permutation of record indices
    n = size( s.deck , 1 ) ;
    i = randperm( n ) ;
    
    % apply to the deck
    s.attempts = s.attempts( i ) ;
    s.deck = s.deck( i , : ) ;
    
  end % reshuffle
  
end % shuffdeck


function  s = stimschedinit( s , rep )
  
  % The size of the schedule's deck
  m = size( s.deck , 1 ) ;
  
  % Expand the list of attempts taken
  s.attempts = repmat( s.attempts , m , 1 ) ;
  
  % Shuffle the deck
  s.deck = s.deck( randperm( m ) , : ) ;
  
  if nargin == 2
    s.rep = rep ;
  end
  
end % stimschedinit


function noexit = prompt ( RDKEYC , rd )
  
  
  %%% Global constants %%%
  
  % The MET timer object
  global  MTIM  MSID
  
  
  %%% Constants %%%
  
  % Reward character
  RDCHAR = KbName( RDKEYC ) ;
  
  % Allowable input characters
  INCHAR = [ 'yn' , RDCHAR ] ;
  
  % Message to operator.
  s = [ 10 , '   Run session?' , ...
        10 , '   Enter <y> to continue' , ...
        10 , '   Enter <n> to exit' , ...
        10 , '   Enter <' , RDCHAR , '> to run pump' , ...
        10 , '>> ' ] ;
  
  
  %%% Get instructions %%%
  
  % Allow Matlab to buffer keypresses on the command line
  ListenChar ( 0 ) ;
  
  % Wait for keyboard release.
  while KbCheck( -1 ) , end
  
  % Wait until we get some valid input.
  while true
    
    % Get lower-case input.
    i = lower( input( s , 's' ) ) ;
    
    % Remove white-space characters.
    i = i( ~isspace( i ) ) ;
    
    % Check break condition, valid input
    if  numel( i ) ~= 1  ||  all ( i ~= INCHAR ) , continue ; end
  
    % Handle input.
    switch  i
      
      % Exit session
      case  'n'
        noexit = false ;
        s = 'exit' ;
      
      % Continue session
      case  'y'

        % Block Matlab from buffering keypresses on the command line
        ListenChar ( -1 ) ;

        noexit = true ;
        s = 'continu' ;

        % Stop clearing MET IPC in background with MET Timer object
        stop ( MTIM )

        % Pedantically check that it has stopped
        while  strcmp ( MTIM.Running , 'on' )
          pause ( MTIM.Period )
        end
        
      % Give reward
      case  RDCHAR
        
        % Non-blocking
        met ( 'send' , MSID.mreward , 1e3 * rd , [] ) ;
        
        % And get more input
        continue
        
      % No recognisable input , try again
      otherwise  ,  continue
        
    end % handle input
    
    % Got input , break input loop
    break
    
  end % input loop
  
  % Feedback
  fprintf( '\n%sing session\n' , s ) ;
  
  % Allow time for keypress to end.
%   WaitSecs( 0.1 ) ;
  
  
end % prompt


function write_trial( trial_d , d , OUTCHAR )
  
  
  %%% CONSTANT %%%

  FILTER = { 'trial' ;
             'date' ;
             'block_count' ;
             'block_index' ;
             'task' ;
             'start_s' ;
             'stop_s' ;
             'dur_s' ;
             'timedout' ;
             'outcome' ;
             'reward_s' } ;
	
	FLPTIM = { 'missed_frames' ;
             'vbl_trial' ;
             'stim_trial' ;
             'flip_trial' }' ;
  
  
	%%% Prune time-stamp buffers when trial was ignored %%%
  
  if trial_d.outcome == OUTCHAR.IGNORED
    
    % Loop buffers
    for F = FLPTIM , f = F{1} ;
      
      % Empty
      trial_d.(f) = 0 ;
      
    end % buffers
    
  end % ignored trial
  
  
  %%% Binary copy %%%
  
  % File name base
  fout = [ 'trial' , num2str( trial_d.trial ) ] ;
  fout = fullfile( d , fout ) ;
  
  % Save binary copy
  save( [ fout '.mat' ] , 'trial_d' )
  
  % That was the easy bit. Now make a text copy
  
  
  %%% Text version %%%
  
  S = structlist( trial_d ) ;
  
  % Open output text file
  fileID = fopen( [ fout , '.txt' ] , 'w' ) ;
  
  % Write all lines to file
  fprintf( fileID , '%s\n' , strjoin( S , '\n' ) ) ;
  
  % Close file
  fclose(fileID);
  
  
  % Filter out unwanted information
  [ ~ , I ] = intersect( fieldnames( trial_d ) , FILTER ) ;
  I = sort( I ) ;
  S = S( I ) ;
  
  % Change the first delimiter
  S = regexprep( S , ',' , ':  ' , 'once' ) ;
  
  % Print to command window
  fprintf( '%s\n\n' , strjoin( S , '\n' ) ) ;
  
  
end % write_trial


function  write_footer ( FOOTER , OUTCHAR , N , tally )
  
  
  %%% Final calculations %%%
  
  % Get final percent correct
  c = OUTCHAR.CORRECT ; f = OUTCHAR.FAILED ;
  pc = tally.( c ) / ( tally.( c ) + tally.( f ) ) * 100 ;
  
  % Convert tally field names from codes to lower-case full descriptions
  for FN = fieldnames( OUTCHAR )' , F = FN{1} ;
    f = lower( F ) ;
    c = OUTCHAR.( F ) ;
    tally.( f ) = tally.( c ) ;
    tally = rmfield( tally , c ) ;
  end
  
  % Add some info
  tally.trial_count = N ;
  tally.percent_correct = pc ;
  
  % Convert to strings
  S = structlist( tally ) ;
  
  
  %%% Write output files %%%
  
  % Binary
  save ( [ FOOTER , '.mat' ] , 'tally' )
  
  % Open output text file
  fileID = fopen( [ FOOTER , '.txt' ] , 'w' ) ;
  
  % Write all lines to file
  fprintf( fileID , '%s\n' , strjoin( S , '\n' ) ) ;
  
  % Close file
  fclose(fileID);
  
  
  %%% Echo to command window %%%
  
  % Change the first delimiter
  S = regexprep( S , ',' , ':  ' , 'once' ) ;
  
  % Print to command window
  fprintf( '%s\n\n' , strjoin( S , '\n' ) ) ;
  
  
end % write_footer


function write_header( headname , TASKCON_INFO , SAMPVAR_RULE , ...
  OUTCOME_CHAR , SUBJECT , PTBWIN_INFO , BLOCKDEF , ...
  RANDNUMGEN , RNG_CHECK ) %#ok
  
  
  %%% Gather information %%%
  
  % Date and time at start of session
  DATE = datetimestr( clock ) ;
  
  % Computer name.
  [ ~ , COMPNAME ] = system( 'uname -a' ) ;
  COMPNAME = strtrim( COMPNAME ) ;
  
  % Computer type and endian-ness
  [ COMPARCH , ~ , ENDIAN ] = computer ;
  
  % Absolute path to session directory
  [ ~ , SESSDIR ] = system( 'echo $PWD' ) ;
  SESSDIR = strtrim( SESSDIR ) ;
  
  
  %%% Save binary copy %%%
  
  S = {         'DATE' ;
        'TASKCON_INFO' ;
            'COMPNAME' ;
            'COMPARCH' ;
              'ENDIAN' ;
             'SESSDIR' ;
        'SAMPVAR_RULE' ;
        'OUTCOME_CHAR' ;
             'SUBJECT' ;
         'PTBWIN_INFO' ;
            'BLOCKDEF' ;
          'RANDNUMGEN' ;
           'RNG_CHECK' } ;
  
  save( [ headname , '.mat' ] , S{:} )
  
  
  %%% Save abridged text copy %%%
  
  % Convert different data types into strings, there has to be a better way
  % ...
  S = { [ 'Date' , ',' , DATE ] ;
        [ TASKCON_INFO.name , ',' , TASKCON_INFO.version ] ;
        [ 'Computer' , ',' , COMPNAME ] ;
        [ 'Comp.Type' , ',' , COMPARCH ] ;
        [ 'Endian' , ',' , ENDIAN ] ;
        [ 'Session dir' , ',' , SESSDIR ] ;
        [ 'Subject ID' , ',' , SUBJECT.id ] ;
        [ 'Sub.dist mm' , ',' , num2str( SUBJECT.dist_mm ) ] ;
        [ 'Screen WxH pix' , numlist( PTBWIN_INFO.size_px ) ] ;
        [ 'Screen pix/degree' , ',' , num2str( PTBWIN_INFO.pixperdeg ) ] ;
        [ 'Screen flipinterval s' , ',' , ...
                                    num2str( PTBWIN_INFO.flipinterval ) ] ;
      } ;
  
  % Special formatting for multiple block definitions
  B = cell( numel( BLOCKDEF ) + 1 , 1 ) ;
  B{ 1 } = [ 'Block types' , ',' , num2str( numel( BLOCKDEF ) ) ] ;
  
  for i = 2 : numel( B )
    
    % Block id
    bstr = { [ 'Block' , ',' , num2str( i ) ] } ;
    
    % Convert to strings
    B{ i } = structlist( BLOCKDEF(i-1) ) ;
    
    % combine
    B{ i } = cat( 1 , bstr , B{i} ) ;
    
  end % block
  
  % Random number generator
  R = { [ 'Rand num gen' , ',' , struct2str( RANDNUMGEN ) ] } ;
  
  % Combine all data
  S = strjoin( cat( 1 , S , B{:} , R ) , '\n' ) ;
  
  % Open output text file
  fileID = fopen( [ headname , '.txt' ] , 'w' ) ;
  
  % Write all lines to file
  fprintf( fileID , '%s\n' , S ) ;
  
  % Close file
  fclose(fileID);
  
  % Echo the command window
  fprintf( '\nSESSION HEADER\n%s\n' , S ) ;
  
  
end % write_header


function S = structlist( str )
  
  % trial descriptor field names
  F = fieldnames( str ) ;
  
  % Output string components
  S = cell( numel( F ) , 1 ) ;
  
  % make string from each field
  for i = 1 : numel( F ) , f = F{ i } ;
    
    % Field name
    s1 = F{ i } ;
    
    % Contents string
    if isstruct( str.(f) )
      s2 = struct2str( str.(f) ) ;
      
    elseif iscell( str.(f) )
      s2 = listcell( str.(f) , isstruct( str.(f){1} ) ) ;
      
    elseif isnumeric( str.(f) ) || islogical( str.(f) )
      s2 = numlist( str.(f) ) ;
      
    elseif ischar( str.(f) )
      s2 = str.(f) ;
      
    elseif isa( str.(f) , 'function_handle' )
      s2 = func2str( str.(f) ) ;
      
    elseif isa( str.(f) , 'udp' )
      s2 = struct2str( str.(f) ) ;
      
    else
      error( 'taskcontroller:structlist:unrecognised data' )
      
    end
    
    S{ i } = [ s1 , ',' , s2 ] ;
    
  end % trial descriptor fields
  
end % structlist


function txt = struct2str( s )
  
  % Empty struct? A strange case, return default output
  if isempty ( s )
    txt = '0x0 struct' ;
    return
    
  % More than 1 element? Pack into a cell and list each one
  elseif 1 < numel( s )
    c = num2cell( s ) ;
    txt = listcell( c , true ) ;
    return
  end
  
  % Field names
  F = fieldnames( s ) ;
  
  % Allocate output
  txt = cell( numel( F ) , 2 ) ;
  
  % Build string for each field
  for i = 1 : numel( F ) , f = F{i} ;
    
    % Field
    txt{ i , 1 } = [ '(' , f ] ;
    
    % and contents to string
    if iscell( s.(f) )
      txt{ i , 2 } = listcell( s.(f) , true ) ;
      
    elseif isstruct ( s.(f) )
      txt{ i , 2 } = struct2str( s.(f) ) ;
      
    elseif isnumeric( s.(f) )
      txt{ i , 2 } = numlist( s.(f) ) ;
    
    elseif islogical( s.(f) )
      txt{ i , 2 } = numlist( double ( s.(f) ) ) ;
      
    elseif ischar( s.(f) )
      txt{ i , 2 } = s.(f) ;
    
    elseif isa ( s.(f) , 'function_handle' )
      txt{ i , 2 } = func2str( s.(f) ) ;
      
    elseif isa( s.(f) , 'udp' )
      txt{ i , 2 } = struct2str( s.(f) ) ;
      
    else
      error( 'taskcontroller:write_struct:unrecognised type' )
      
    end
    
    txt{ i , 2 } = [ txt{i,2} , ')' ] ;
    
  end % fields
  
  % Form a one dimensional list
  txt = reshape( txt' , 1 , numel( txt ) ) ;
  
  % concatenate
  txt = strjoin( txt , ',' ) ;
  
  
end % write_struct


function s = listcell( c , brace )
  
  s = cell( 1 , numel(c) ) ;
  
  if brace
    b1 = '(' ;
    b2 = ')' ;
  else
    b1 = '' ;
    b2 = '' ;
  end
  
  for i = 1 : numel( c )
    
    if isnumeric( c{i} )
      s{i} = [ b1 , numlist( c{i} ) , b2 ] ;
    elseif isa( c{i} , 'function_handle' )
      s{i} = [ b1 , func2str( c{i} ) , b2 ] ;
    elseif ischar( c{i} )
      s{i} = [ b1 , c{i} , b2 ] ;
    elseif iscell( c{i} )
      s{i} = [ b1 , listcell( c{i} , true ) , b2 ] ;
    elseif isstruct( c{i} )
      s{i} = [ b1 , struct2str( c{i} ) , b2 ] ;
    end
    
  end
  
  s = strjoin( s , ',' ) ;
  
end % listcell


function s = numlist( x )
  
  s = regexprep( num2str( x(:)' ) , ' +' , ',' ) ;
  
end % numlist

function DATE = datetimestr( clock )
  
  % Output of clock function expected as input 'clock' which is
  % numeric vector with format [year month day hour minute seconds]
  
  y = sprintf( '%04d' , clock(1) ) ;
  mon = sprintf( '%02d' , clock(2) ) ;
  d = sprintf( '%02d' , clock(3) ) ;
  h = sprintf( '%02d' , clock(4) ) ;
  min = sprintf( '%02d' , clock(5) ) ;
  s = sprintf( '%02d' , round( clock(6) ) ) ;
  
  DATE = [ y , '/' , mon , '/' , d , ',' , h , ':' , min , ':' , s ] ;
  
end % datetimestr


function block = convertorigin( block , ptbwin )
  
  % The central point of the screen.
  [ width , height ] = Screen( 'WindowSize' , ptbwin.ptr ) ;
  width = width / 2 ;
  height = height / 2 ;
  
  % Loop blocks.
  for i = 1 : numel( block )
    
    % Number of columns in .origins
    s = size( block(i).origins ) ;
    
    % Convert from degrees of visual field to pixels.
    block(i).origins = ptbwin.pixperdeg * block(i).origins ;
    
    % N x 2 case
    if s(2) == 2
      
      w = 1 ;
      h = 2 ;
      
    % Box definition, 1 x 4 case
    elseif all( s == [ 1 , 4 ] )
      
      w = [ RectLeft , RectRight ] ;
      h = [ RectTop , RectBottom ] ;
      
    end
    
    % x-axis i.e. azimuth, horizontal position
    block(i).origins(:,w) = block(i).origins(:,w) + width ;
    
    % y-axis i.e. elevation, vertival position
    block(i).origins(:,h) = block(i).origins(:,h) + height ;
    
  end % blocks
  
end % convertorigin


function  tally = tallyinit ( OUTCHAR )
  
  % Loop outcome characters, make them fields, initialise at zero
  for F = struct2cell( OUTCHAR )' , f = F{1} ;
    tally.(f) = 0 ;
  end
  
end % tallyinit


function trial_d = trialdescriptor
  
  trial_d = struct( 'trial' , 0 , ...
                    'date' , [] , ...
                    'block_count' , 0 , ...
                    'block_index' , 0 , ...
                    'task' , [] , ...
                    'state_timeouts' , [] , ...
                    'rng' , [] , ...
                    'rng_check' , zeros(1,5) , ...
                    'origin' , [ 0 , 0 ] , ...
                    'stim_par' , [] , ...
                    'stim_chksum_start' , [] , ...
                    'stim_chksum_stop' , [] , ...
                    'start_s' , 0 , ...
                    'vbl_zero' , 0 , ...
                    'stim_zero' , 0 , ...
                    'flip_zero' , 0 , ...
                    'stop_s' , 0 , ...
                    'dur_s' , 0 , ...
                    'vbl_dur' , 0 , ...
                    'stim_dur' , 0 , ...
                    'flip_dur' , 0 , ...
                    'stim_frames' , 0 , ...
                    'stop_frame' , 0 , ...
                    'missed_frames' , [] , ...
                    'vbl_trial' , [] , ...
                    'stim_trial' , [] , ...
                    'flip_trial' , [] , ...
                    'eventc' , 0 , ...
                    'event_frame' , [] , ...
                    'event_vbl' , [] , ...
                    'event_stim' , [] , ...
                    'event_flip' , [] , ...
                    'event_targ' , [] , ...
                    'event_hitbox' , [] , ...
                    'events' , [] , ...
                    'timedout' , 0 , ...
                    'outcome' , 'x' , ...
                    'reward_s' , 0 , ...
                    'mtarget' , [] , ...
                    'hitbox' , [] ) ;
  
end % initresult


function  block = checkblock ( fblockdef )
  
  % Retrieve block definition
  f = str2func ( fblockdef ) ;
  block = f () ;
  
  % block definition validation function
  %VALID BLOCK
  
end % checkblock


function  subj = checksub ( fsubj )
  
  % Retrieve subject information
  f = str2func ( fsubj ) ;
  subj = f () ;
  
  % Check subj
  if isempty( subj ) || ~isstruct( subj )
    error( 'taskcontroller:subj:requires non-empty struct' )
  end
  
  % Additional check on subj
  FSET = { { 'id' , @( f ) ischar(f) } ;
        { 'dist_mm' , @( f ) numel(f) == 1 && isnumeric(f) && 0 < f } ;
        { 'reward_s' , @( f ) numel(f) == 1 && isnumeric(f) && 0 <= f } } ;
  
  % Loop checks
  for F = FSET' , f = F{ 1 } ;
    
    if ~isfield( subj , f{1} )
      error( 'taskcontroller:invalid:subj lacks %s' , f{1} )
    
    elseif isempty( subj.( f{1} ) )
      error( 'taskcontroller:invalid:subj.%s is empty' , f{1} )
    
    elseif ~f{2}( subj.( f{1} ) )
      error( 'taskcontroller:invalid:subj.%s invalid' , f{1} )
      
    end
    
  end % checks
  
end % checksub


function  checkin ( sessiondir , FN_DIRS , FINFILE )
  
  % sessiondir must be a string ...
  if isempty( sessiondir ) || ~ischar( sessiondir )
    error( 'taskcontroller:invalid:sessiondir not a string' )
  
  % ... and name a directory that exists
  elseif ~exist( sessiondir , 'dir' )
    error( 'taskcontroller:invalid:%s does not exist' , sessiondir )
  end
  
  % sessiondir must contain the following files
  for F = FN_DIRS , f = F{1} ;
    if ~exist( fullfile( sessiondir , f ) , 'file' )
      error( 'taskcontroller:invalid:%s is missing %s' , ...
        sessiondir , f )
    end
  end
  
  % Check that the session was not finalised
  if exist( fullfile( sessiondir , FINFILE ) , 'file' )
    error( 'taskcontroller:invalid:%s has been finalised' , sessiondir )
  end
  
  % Check that we have write permission
  [ F , f ] = fileattrib( sessiondir ) ;
  if ~F
    error( 'taskcontroller:invalid:failed to assess permissions on %s', ...
      sessiondir )
  elseif ~f.UserRead || ~f.UserWrite
    error( 'taskcontroller:invalid:insufficient permissions for %s' , ...
      sessiondir )
  end
  
end % checkin

