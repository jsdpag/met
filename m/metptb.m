
function  metptb ( MC )
% 
% metptb ( MC )
% 
% Matlab Electrophysiology Toolbox controller function. PsychToolbox is
% used to present ptb-type MET stimulus definitions that are linked to task
% stimuli. Given how central the relationship is between state of the task
% and stimulus presentation, the controller is also responsible for
% tracking the task's current state, and thus signalling state changes.
% Because it must generate instances of ptb-type MET stimulus definitions,
% it also has the responsibility of sharing their hit region information by
% writing to the 'stim' shared memory ; as such, it provides the set of hit
% regions during trial initialisation. It will rely on another controller
% to provide information about which task stimulus is being targeted by the
% subject.
% 
% When initialising a trial, it will save information about the random
% number generator before creating instances of MET stimulus definitions.
% Afterwards it takes check-sums from all of ptb-type stimuli. During a
% trial, it will buffer PsychToolbox time stamps as well as the
% PsychToolbox estimate of whether frames were skipped ; time stamps will
% be the duration of time since the trial's mstart time stamp i.e. the
% mstart time stamp will be treated as time zero. At the end of
% the trial, check sums are again taken, along with the final state of the
% random number generator. Buffered data is saved in the current trial's
% directory after the trial has finished running, in a file called
% ptbframes_<i>.mat where <i> is replaced with the trial's identifier ; an
% ASCII version of the data will also be saved with a .txt suffix. Saved
% time stamps will be in units of microseconds since the mstart time i.e.
% trial start time and will be saved as unsigned 32-bit integers.
% 
% NOTE: Relies on the property values in metscrnpar.csv. Bear in mind that
%   this includes information about screen physical dimensions, subject
%   distance, default background colour, screen-to-head mapping, and
%   whether or not the image is physically mirrored. On the last point,
%   PsychToolbox will be configured to make sure than an un-mirrored image
%   is presented to the subject i.e. that the variable property value of
%   MET stimulus definitions corresponds to what the subject sees ; this
%   will, however, change the appearance of any reference copy of the image
%   that is presented to the operator, unless that too is mirrored.
% 
% NOTE: As per Matlab R2015a, the Mersenne Twister random number generator
%   is used.
% 
% NOTE: A square is drawn in the upper-left corner of the screen ,
%   regardless of mirroring. The size and colour of the square are provided
%   by the metscrnpar.csv parameters sqwid and ( sqred , sqgrn , sqblu ).
%   The first frame of every trial uses a square with that colour. The
%   second frame is the given colour weighted by the sq2nd value. All
%   remaining frames of the trial then alternate between the un-weighted
%   and weighted colour. A second square can be placed in the upper-right
%   corner of the screen to mask the background, using parameters mskwid
%   and mskclu.
% 
% NOTE: Creates a new log file for each session in logs/metptb_log.txt that
%   receives any string str that is printed using met( 'print' , str , n )
%   where n is 'l', 'L', or 'E'.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Constants %%%
  
  % MET controller constants
  MCC = metctrlconst ( MC ) ;
  
  % Maximum trial buffer size , here a trial buffer stores PsychToolbox
  % time stamps. There are two values. n gives the maximum number of
  % buffers to maintain during a trial, while dur gives the approximate
  % number of seconds of time stamps that can be stored in each one.
  % Multiply these figures for the total amount of time that time stamps
  % can be buffered.
  MAXBUF = struct ( 'n' , 10 , 'dur' , 10 ) ;
  
  % metptb trial data file name format , lacks file-type suffix
  DATFMT = 'ptbframes_%s' ;
  
  % Mandatory shared memory access rights , T is a temporary constants
  % struct
  T.SHMACC = { 'stim' , 'w' } ;
  
  % Number of received signals
  T.N = 0 ;
  
  % Approximate drawnow rate while waiting for new trials , in Hz
  T.DNOWHZ = 5 ;
  
  % Name of file containing previously used MET PTB GUI figure position
  FIGPOS = 'metptbgui_figpos.mat' ;
  
  
  %-- Screen parameters --%
  
  % metscrnpar parameters are constant at run time
  SCRPAR = metscrnpar ;
  
  % Determine screen ID to use , -1 means to take the maximum value
  % returned by Screen ( 'Screens' )
  T.SID = SCRPAR.screenid ;
  
  if  T.SID  ==  -1
    T.SID = max( Screen (  'Screens'  ) ) ;
  end
  
  % Screen width in pixels
  T.PIXWID = Screen ( 'WindowSize' , T.SID ) ;
  
  % Background colour
  T.BAKCOL = [ SCRPAR.rbak , SCRPAR.gbak , SCRPAR.bbak ] ;
  
  % Psych Toolbox verbosity level.  
  %  0 - No output at all.
  %  1 - Only severe error messages.
  %  2 - Errors and warnings.
  %  3 - Additional information, e.g., startup output when opening an
  %      onscreen window.
  %  4 - Very verbose output, mostly useful for debugging PTB itself.
  %  5 - Even more information and hints. Usually not what you want.
  T.PTBVERB = 2 ;
  
  % Screen to head parameters
  T.PTBS2H = { 'preference' , 'screentohead' , ...
    T.SID , SCRPAR.newHeadId , SCRPAR.newCrtcId , SCRPAR.rank } ;
    
    % Find null values i.e. -1 , return linear indeces relative to start of
    % T.PTBS2H
    i = find (  [ T.PTBS2H{ 4 : 6 } ]  ==  -1  )  +  3 ;
    
    % Replace null values with empty matrices
    T.PTBS2H( i ) = { [] } ;
    
	% Initial blending function
  T.BLNDINIT = { GL_ONE , GL_ZERO } ;
  
  % Photodiode rectangle parameters. i + 1 gives the colour of the
  % rectangle on the next frame ; once given, i = ~ i so that the colour
  % alternates on the following frame. colour is a 2 x 3 array where each
  % row gives a 3 element ( r , g , b ) clut vector. rect is a 4 element
  % PTB vector of pixel coordinates for the left, top, right, and bottom of
  % the rectangle.
  PHOTOR = struct ( 'i' , false , 'colour' , [] , 'rect' , [] ) ;
  
    % Start by copying the raw, unweighted colour in both rows
    PHOTOR.colour = ...
      repmat(  [ SCRPAR.sqred , SCRPAR.sqgrn , SCRPAR.sqblu ] ,  2 ,  1 ) ;
    
    % Then apply weights
    PHOTOR.colour = PHOTOR.colour  .*  ...
      [  1 ,  1 ,  1 ;  SCRPAR.sqwrd ,  SCRPAR.sqwgn ,  SCRPAR.sqwbl  ] ;
    
    % Build position rectangle
    PHOTOR.rect = T.PIXWID  /  SCRPAR.width  *  SCRPAR.sqwid  *  ...
      [ 0 , 0 , 1 , 1 ] ;
    
    % Set flag to true if upper-right corner masking square is to be drawn
    PHOTOR.msk = 0  <  SCRPAR.mskwid ;
    
    % Drawing masking square
    if  PHOTOR.msk
      
      % Create rectangle
      PHOTOR.mskrec = zeros( 4 , 1 ) ;
      PHOTOR.mskrec( [ RectLeft , RectTop , RectRight , RectBottom ] ) =...
        [ T.PIXWID - SCRPAR.mskwid , 0 , T.PIXWID , SCRPAR.mskwid ] ;
      
      % Greyscale
      PHOTOR.mskclu = SCRPAR.mskclu ;
        
    end % msk square
    
  % Use default random number generator seed
  DEFSEED = SCRPAR.defseed ;
	
	
	%%% Check environment %%%
  
  % Look for shared memory access rights
  for  i = 1 : size ( T.SHMACC , 1 )
    
    % Lack of correct access
    if  isempty (  MC.SHM  )  ||  ...
        ~ any (  strcmp(  T.SHMACC{ i , 1 }  ,  MC.SHM( : , 1 )  )  &  ...
          [ MC.SHM{ : , 2 } ]'  ==  T.SHMACC{ i , 2 }  )
             
      error (  'MET:metptb:shm'  ,  [ 'metptb: requires ''%s'' ' , ...
        'access to ''%s'' shared memory , check .cmet file' ]  ,  ...
        T.SHMACC { i , [ 2 , 1 ] }  )
             
    end
    
  end % shared mem
  
  
  %%% Initialisation %%%
  
  % Re-shuffle random number generator
  rng ( 'shuffle' , 'twister' )
  
  % Attempt to clear any Psych Toolbox residue , in case of a recent crash
  sca
  
  
  %-- Trial constants struct --%
  
  % Get prototype
  tconst = MCC.SDEF.ptb.init ;
  
  % Compute pixels per degree of visual angle
  tconst.pixperdeg = metpixperdeg (  SCRPAR.width  ,  T.PIXWID  ,  ...
    SCRPAR.subdist  ) ;
  
  % Default window background colour
  tconst.backgnd = T.BAKCOL ;
  
  % PsychToolbox window stereo mode
  tconst.stereo = SCRPAR.stereo ;
  
  % Default origin , will be replaced by origin from each new trial
  % descriptor
  tconst.origin = [ 0 , 0 , 0 ] ;
  
  
  %-- Open PsychToolbox window --%
  
  % Make sure that screen to head mapping is correct
  if  ~ all ( cellfun (  @isempty  ,  T.PTBS2H ( 4 : 6 )  ) )
    Screen (  T.PTBS2H { : }  ) ;
  end
  
  % Setup PTB with default values
  PsychDefaultSetup ( 2 ) ;
  
  % Black PTB startup screen
  Screen ( 'Preference' , 'VisualDebugLevel' , 1 ) ;
  
  % How much does PTB-3 automatically tell you?
  Screen ( 'Preference' , 'Verbosity' , T.PTBVERB ) ;
  
  % Prepare Psych Toolbox environment.
  PsychImaging ( 'PrepareConfiguration' ) ;
  PsychImaging ( 'AddTask' , 'General' , 'FloatingPoint32BitIfPossible' ) ;
  PsychImaging ( 'AddTask' , 'General' , 'NormalizedHighresColorRange' ) ;
  
  % Handle any mirroring
  if  SCRPAR.hmirror
    PsychImaging ( 'AddTask' , 'AllViews' , 'FlipHorizontal' ) ;
  end
  
  if  SCRPAR.vmirror
    PsychImaging ( 'AddTask' , 'AllViews' , 'FlipVertical'   ) ;
  end
  
  % Open PTB window with black background
  try
    
    [ tconst.winptr , ...
      tconst.winrec ] = PsychImaging (  'OpenWindow'  ,  ...
      T.SID  ,  0  ,  []  ,  []  ,  []  ,  SCRPAR.stereo  ) ;
  
  catch  E
    
    % Clear PsychToolbox actions taken before doomed call to OpenWindow
    try
      sca
    catch
    end
    
    % Quit
    rethrow (  E  )
    
  end % open window
  
  % Screen dimensions
  tconst.winwidth  = diff(  tconst.winrec( [ RectLeft , RectRight ] )  ) ;
  tconst.winheight = diff(  tconst.winrec( [ RectTop , RectBottom ] )  ) ;
  
  % Screen centre
  tconst.wincentx = mean(  tconst.winrec( [ RectLeft , RectRight ] )  ) ;
  tconst.wincenty = mean(  tconst.winrec( [ RectTop , RectBottom ] )  ) ;
  
  % The flip interval
  tconst.flipint = Screen ( 'GetFlipInterval' , tconst.winptr ) ;
  
  % Enable OpenGL alpha blending function
  Screen ( 'BlendFunction' , tconst.winptr , T.BLNDINIT{ : } ) ;
  
  % Set process priority to maximum if the flag is raised
  if  SCRPAR.priority
    
    % Get maximum priority for this window
    T.maxp = MaxPriority (  tconst.winptr  ) ;
    
    % Set maximum priority and report
    met (  'print'  ,  sprintf (  [ 'metptb: switching priority ' , ...
      'level from %d to %d' ] , Priority(  T.maxp  ) , T.maxp  )  ,  'L'  )
    met (  'print'  ,  sprintf (  [ 'metptb: priority level is now ' , ...
      '%d' ] , Priority  )  ,  'L'  )
    
  end % set priority
  
  % Photodiode rectangle , adjust position to compensate for mirroring. We
  % always want this in the top-left corner of the screen. And we always
  % want the masking square in the upper-right.
  
    % Compensate for horizontal mirroring
    if  SCRPAR.hmirror
      
      % Index of left and right edges
      i = [ RectLeft , RectRight ] ;
      
      % Place rectangle on the right edge of the image , thus left edge of
      % the screen.
      PHOTOR.rect( i ) = tconst.winrec( RectRight )  -  ...
        PHOTOR.rect( RectRight )  +  PHOTOR.rect( i ) ;
      
      % Masking square goes on left-edge of image, which becomes the right
      % edge after mirroring
      if  PHOTOR.msk
        PHOTOR.mskrec( i ) = tconst.winrec( RectRight )  -  ...
          PHOTOR.mskrec( [ RectRight , RectLeft ] ) ;
      end
      
    end % hmirror
    
    % Compensate for vertical mirroring
    if  SCRPAR.vmirror
      
      % Index of the top and bottom edges
      i = [ RectTop , RectBottom ] ;
      
      % Place rectangle on the bottom edge of the image , thus the top edge
      % of the screen
      PHOTOR.rect( i ) = tconst.winrec( RectBottom )  -  ...
        PHOTOR.rect( RectBottom )  +  PHOTOR.rect( i ) ;
      
      % And again for masking square
      if  PHOTOR.msk
        PHOTOR.mskrec( i ) = tconst.winrec( RectBottom )  -  ...
          PHOTOR.mskrec( [ RectBottom , RectTop ] ) ;
      end
      
    end % vmirror
    
  % Hide mouse cursor when it is over the PTB window , unless
  % metscrnpar.csv requests otherwise
  if  SCRPAR.touch  <  2  ,  HideCursor (  tconst.winptr  ) ;  end
  
  
  %-- Timeout GUI --%
  
  % Save current directory
  T.d = pwd ;
  
  % Go to met/m/mgui directory
  cd (  MCC.GUIDIR  )
  
  % Load timeout GUI tool. Fields link figure handle in .h and switch
  % button in .s. Minimum duration between calls to drawnow while waiting
  % for a new trial is in .dndurs , in seconds. Attempt to load old figure
  % Position value for timeout gui.
  try
    
    timgui.h = metptbgui ( MC , MCC , tconst.winptr , tconst.backgnd , ...
      PHOTOR ) ;
    timgui.s = timgui.h.UserData.uiswitch ;
    timgui.dndurs = 1  /  T.DNOWHZ ;
    
    if  exist (  FIGPOS  ,  'file'  )
      
      load (  FIGPOS  ,  'figpos'  )
      timgui.h.Position = figpos ; %#ok
      
    end
    
  catch  E
    
    % Close PsychToolbox
    sca
    
    % Quit
    rethrow ( E )
    
  end
  
  % Go back to original directory
  cd ( T.d )
  
  
  %-- Clear unnecessary variables --%
  
  clear  SCRPAR  T
  
  
  %%% Run controller %%%
  
  % Empty means no error detected
  E = '' ;
  
  % Catch any errors raised during operation
  try
    
    runc ( MC , MCC , MAXBUF , PHOTOR , DEFSEED , DATFMT , ...
      tconst , timgui )
    
  catch  E
  end
  
  % Clear PsychToolbox and close timeout GUI after saving its position
  try
    
    sca
    
    cd (  MCC.GUIDIR  )
    figpos = timgui.h.Position ; %#ok
    save (  FIGPOS  ,  'figpos'  )
    
    delete ( timgui.h )
    
  catch
  end
  
  % Report error
  if  ~ isempty ( E )  ,  rethrow ( E )  ,  end
  
  
end % metptb


%%% Subroutines %%%


% Run controller , executes the main event loop that iterates once per
% trial
function  runc ( MC , MCC , MAXBUF , PHOTOR , DEFSEED , DATFMT , ...
  tconst , timgui )
  
  
  %%% Constants %%%
  
  % MET signal identifier name-to-value map
  MSID = MCC.MSID ;
  
  % Stimulus definition struct construction cell array
  SDCELL = { 'type' , 'varpar' , 'init' , 'stim' , 'close' , 'chksum' ;
                 [] ,       [] ,     [] ,     [] ,      [] ,       [] } ;
  
  % Half-flip interval , to set frame-swap deadlines
  HFI = tconst.flipint  /  2 ;
  
  % Some stereoscopic mode is in use , so loop both frame buffers ,
  % otherwise we always use the monocular flag value of -1
  if  tconst.stereo
    
    EYEBUF = 0 : 1 ;
    
  else
    
    EYEBUF = -1 ;
    
  end
  
  % Blocking on MET signalling i.e. wait for operation
  WAIT_FOR_SIG = 1 ;
  
  % Trial abort outcome code
  ABORT = MC.OUT { strcmp( MC.OUT , 'aborted' ) , 2 } ;
  
  % Pass eyebuffer and stereo mode info to metptbgui object
  timgui.h.UserData.eyebuf = EYEBUF ;
  timgui.h.UserData.stereo = tconst.stereo ;
  
  
  %%% Trial buffers & Timeout GUI %%%
  
  % Make a MET signal buffer. n - total number that can be stored. i - the
  % index of the last signal placed in the buffer. sig, crg, tim - the
  % signal buffers, each is a n x 1 double vector. To return all signal
  % identifiers currently in the buffer, run .sig( 1 : i ).
  mbuf = struct (  'n'  ,  MC.AWMSIG  ,  'i'  ,  0  ,  ...
    'sig'  ,  zeros ( MC.AWMSIG , 1 )  ,  ...
    'crg'  ,  zeros ( MC.AWMSIG , 1 )  ,  ...
    'tim'  ,  zeros ( MC.AWMSIG , 1 )  ) ;
  
  % Make a fresh PsychToolbox timestamp buffer
  tbuf = mkbuf ( MAXBUF , tconst ) ;
  
  % Not really a buffer , but varies during the trial so we'll allocate it
  % here. The trial variable struct , is handed to the stimulation function
  % of ptb-type MET stimulus definitions.
  tvar = MCC.SDEF.ptb.stim ;
  
  
  %%% Set background colour %%%
  
  % Loop eye frame buffers
  for  e = EYEBUF

    % Set stereo drawing buffer
    if  tconst.stereo
      Screen (  'SelectStereoDrawBuffer'  ,  tconst.winptr  ,  e  ) ;
    end

    % Set background colour
    Screen (  'FillRect'  ,  tconst.winptr  ,  tconst.backgnd  ) ;
  
    % Masking square enabled
    if  PHOTOR.msk
      Screen( 'FillRect' , tconst.winptr , PHOTOR.mskclu , PHOTOR.mskrec );
    end

  end % eye frame buffs
  
  % Apply new background colour
  Screen (      'Flip'  ,  tconst.winptr  ) ;
  
  
  %%% Complete MET initialisation %%%
  
  % Send mready signal , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Report
  met (  'print'  ,  sprintf ( 'MET controller %d initialised: metptb' ,...
    MC.CD )  ,  'L'  )
  
  % Wait for mwait signal that finalises initialisation phase
  n = 0 ;
  sig = [] ;
  while  ~ n  ||  all ( sig  ~=  MSID.mwait )
    
    % Block on the next MET signal(s)
    [ n , ~ , sig ] = met ( 'recv' , 1 ) ;

    % Return if any mquit signal received
    if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
  
  end % initialising mwait
  
  % Flush messages to terminal
  met ( 'flush' )
  
  
  %%% Event loop %%%
  
  % Blank session descriptor is required for first iteration of the loop
  sd = MCC.DAT.SD ;
  
  % Blank stimulus definition list so that we don't crash the first time a
  % session is opened i.e. before D, ptb, or sdl are defined and sclose is
  % run
  D = {} ;
  
  
  % Trial loop , polls drawnow while waiting for new trial
  while  metwaitfortrial ( MC , 'metptb' , timgui.dndurs )
    
    
    %-- Timeout GUI --%
    
    % Remove GUI from view if visible
    if  strcmp (  timgui.h.Visible  ,  'on'  )
      
      timgui.h.Visible = 'off' ;
      drawnow
      
    end
    
    % Turn off timeout screen if it is on
    if  timgui.h.UserData.switch
      
      timgui.s.Callback ( timgui.s , [] )
      
    end % timeout off
    
    
    %-- Get trial parameters --%
    
    % Read current session directory name and trial identifier
    [ sdir , tid ] = metsdpath ;
    
    % Session directory has changed
    if  ~ strcmp (  sd.session_dir  ,  sdir  )
      
      % Load new session descriptor
      sd = metdload ( MC , MCC , sdir , tid , 'sd' , 'metptb' ) ;
      
      % Get current set of ptb-type MET stimulus definitions
      [ d , dnam ] = loadsdef ( MC , SDCELL , sd ) ;
      
      % Session-close all ptb-type stimuli
      if  ~ isempty ( D )  ,  sclose ( D , ptb , sdl , 's' ) ;  end
      
      % Prepare lists of closed stimulus descriptors , for passage to new
      % stimulus descriptors on next use of the stimulus link
      sdl_c = initsdlc ( sd ) ;
      
      % Open new log file for this session
      met (  'logcls'  )
      met (  'logopn'  ,  ...
        fullfile ( sd.session_dir , MC.SESS.LOGS , 'metptb_log.txt' )  )

    end % new sess dir
    
    % Record the current trial identifier in the log file
    met (  'print'  ,  [ 'Trial ID: ' , tid ]  ,  'l'  )
    
    % Load new trial descriptor
    td = metdload ( MC , MCC , sdir , tid , 'td' , 'metptb' ) ;
    
    % Locate ptb-type stimulus links , a logical index vector
    ptb = strcmp (  'ptb'  ,  { td.stimlink.type }  ) ;
    
    % Check that all variable parameters are present and within range
    vpcheck ( MCC , sd , td , ptb )
    
    % Point to trial's task logic
    tlog = sd.logic.( td.logic ) ;
    
    % Index of the first end state
    iends = tlog.N.state  -  3 ;
    
    % End of state flag , raise when an end state encountered
    endflg = false ;
    
    % Set any alternative timeout durations for task logic states
    t = tlog.T ;
    t( [ td.state.istate ] ) = [ td.state.timeout ] ;
    
    
    %-- Initialise constants and buffers --%
    
    % Un-weighted colour needed in the photodiode square on the first
    % frame. Thus, initialise .i to true so that it is flipped to false
    % before the first call to Screen 'FillRect'. Then false + 1 == 1 and
    % so the un-weighted colour is returned from .colour( 1 , : ).
    PHOTOR.i = true ;
    
    % Update trial origin in trial constants struct
    tconst.origin( : ) = td.origin ;
    
    % Reset PsychToolbox timestamp buffer. Start buffering in buffer number
    % 1 , the index of the last saved time measurement is 0
    tbuf.ib = 1 ;
    tbuf.i  = 0 ;
    
    % Reset MET signal buffer
    mbuf.i = 0 ;
    
    % May as well reset the trial variable struct at this point
    tvar.frame = 0 ;
    tvar.skip = false ;
    tvar.varpar = [] ;
    
    % No stimulus currently targeted by subject
    target = MCC.SDEF.none ;
    
    % Start state of the task logic
    state = 1 ;
    
    % No mwait signal yet observed during running trial
    mwait = false ;
    
    
    %-- Index and event mapping --%
    
    % ptb-style stimulus link to stimulus definition mapping. l2d( i )
    % contains value j such that d( j ) is the stimulus definition of the
    % ith stimulus link.
    l2d = zeros ( numel( td.stimlink ) , 1 ) ;
    l2d( ptb ) = cellfun (  @( c )  find( strcmp(  c  ,  dnam  ) )  ,  ...
      { td.stimlink( ptb ).stimdef }  ) ;
    
    % Build a stimulus definition list that maps each stimulus link to its
    % stimulus definition. D{ i }
    D = repmat (  struct (  SDCELL { : }  )  ,  size (  l2d  )  ) ;
    D( ptb ) = d( l2d(  ptb  ) ) ;
    
    % Task logic state mapping to stimulus link indeces
    S2L = state2linkmap ( ptb , td , tlog ) ;
    
    % Build sets of variable parameter change lists for each task logic
    % state , stimulus event maps
    SEV = sevents ( td , tlog , S2L ) ;
    
    % Allocate variable-parameter-change cell array vector with a space for
    % each stimulus link. Include accompanying logical index vector that is
    % true if the link has queued parameter changes.
    vpi = false ( size(  ptb  ) ) ;
    vpc =  cell ( size(  ptb  ) ) ;
    
    % Build lists of MET signal events for each task logic state
    MEV = mevents ( MCC , td , tlog ) ;
    
    % Initialise the list of ptb stimulus links presented in start state
    l = S2L { 1 } ;
    
    
    %-- Receptive/response field ovals --%
    
    % Calculate oval locations relative to trial origin
    rf = rfovals ( tconst , sd ) ;
    
    
    %-- Initialise stimulus descriptors --%
    
    % Reset the default random number seed
    if  DEFSEED
      
      rng ( 'default' ) ;
      
      % And remind the user of this folly
      met ( 'print' , ...
        sprintf( '\nWARNING: DEFAULT RAND NUM SEED USED!\n' ) , ...
          'E' ) ;
        
      % Flush output streams to make sure user sees this
      met ( 'flush' )
    
    end % reset rand number seed
    
    % Remember the state of the random number generator at the start of
    % trial
    rng_start = rng ;
    
    % Initialise stimulus descriptor list
    sdl = stiminit ( tconst , D , ptb , td , sdl_c.( td.task ) ) ;
    
    % Compute start-of-trial check-sums
    chksum_start = chksums ( D , ptb , td , sdl ) ;
    
    % Remember random number generator state following stimulus
    % initialisation
    rng_init = rng ;
    
    
    %-- Hit regions --%
    
    % Initialise the logical index vector for stimulus link hit regions.
    % h( i ) is true when link i has a new hit region.
    h = ptb' ;
    
    % Get the set of hit regions for ptb-type stimulus links
    H = cell ( size(  sdl  ) ) ;
    H( h ) = cellfun (  @( s ) s.hitregion  ,  sdl( ptb )  ,  ...
      'UniformOutput'  ,  false  ) ;
    
    % Write to 'stim' shared memory in order to complete the trial
    % initialisation process. Other controllers will be waiting for this.
    % Notice that this is a blocking write.
    while  ~ met ( 'write' , '+stim' , GetSecs , h , H{ h } )
      
      % Failed to write , better let them know
      met (  'print'  ,  [ 'metptb: failed to write hit regions to ' , ...
        '''stim'' while initialising trial , trying again ' , tid ]  ,  ...
        'E'  )
      
    end % write to 'stim'
    
    % Lower hit region flags
    h( h ) = false ;
    
    
    %-- Synchronise start of trial with MET --%
    
    % Empty the signal identifier logical index vector , i will be used as
    % such hereafter
    i = false ( 0 ) ;
    
    % Make the initial synchronising flip show a black square, for maximum
    % contrast against the following square of the first frame of trial
    for  e = EYEBUF % Loop eye frame buffers

      % Set stereo drawing buffer
      if  tconst.stereo
        Screen (  'SelectStereoDrawBuffer'  ,  tconst.winptr  ,  e  ) ;
      end
      
      % Black square
      Screen (  'FillRect'  ,  tconst.winptr  ,  0  ,  PHOTOR.rect  ) ;
      
      % Masking square enabled
      if  PHOTOR.msk
        Screen ( 'FillRect' , tconst.winptr , PHOTOR.mskclu , ...
          PHOTOR.mskrec ) ;
      end
      
    end % eye frame buffs
    
    % Send mready reply to MET server controller , blocking write
    met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] , WAIT_FOR_SIG ) ;
    
    % Wait for start of trial MET signal mstart
    while  ~ any ( i )
      
      % Block on the broadcast pipe
      [ ~ , ~ , sig , ~ , tim ] = met (  'recv'  ,  WAIT_FOR_SIG  ) ;
      
      % Immediately terminate the function if a quit signal received ,
      % after closing stimulus descriptors
      if  any ( sig  ==  MSID.mquit )
        sclose ( D , ptb , sdl , 's' ) ;
        return
      end
      
      % Look for start signal
      i = sig  ==  MSID.mstart ;
      
    end % mstart
    
    % Get trial's time zero
    trial_start = tim ( i ) ;
    
    % Initialise state onset time
    state_onset = trial_start ;
    
    % Synchronise with the vertical blanking period of the screen
    [ vbl , stimon ] = Screen ( 'Flip' , tconst.winptr ) ;
    
    
    %-- Animation loop --%
    
    while  true
      
      
      %-- Signal handling --%
      
      % Check for new MET signals , non-blocking read
      [ n , ~ , sig , crg , tim ] = met (  'recv'  ) ;
      
      % Signals received
      if  n
        
        % Quit signal , close stimulus descriptors and terminate function
        if  any ( sig  ==  MSID.mquit )
          sclose ( D , ptb , sdl , 's' ) ;
          return
        end
        
        % mwait signal received , next trial will not be automatically
        % generated
        if  any (  sig == MSID.mwait  )
          
          % Raise mwait flag
          mwait = true ;
          
          % Abort trial signal , break the animation loop
          if  any (  crg == MC.MWAIT.ABORT  )
            break
          end
          
        end % mwait
        
        % New stimulus targeted
        i = sig  ==  MSID.mtarget ;
        
        if  any ( i )
          
          % Keep only the relevant cargo and time stamps
          crg = crg ( i ) ;
          tim = tim ( i ) ;
          
          % Find the newest signal , j will be a linear index variable
          % hereafter
          [ ~ , j ] = max (  tim  ) ;
          
          % Set target
          target = crg ( j ) ;
          
        end % mtarget
        
      end % MET signals
      
      
      %-- Update trial variables --%
      
      % Increment the frame number
      tvar.frame = tvar.frame  +  1 ;
      
      % Determine next expected stimulus onset time
      stimon = stimon  +  tconst.flipint ;
      
      % Next frame's expected presentation time from the start of the trial
      tvar.ftime = stimon  -  trial_start ;
      
      
      %-- Task logic state tracking --%
      
      % Determine if this state has timed out. Convert to 3rd dimension
      % index for tlog.E , to switch lookup tables. Remember, + takes
      % precedence over <= .
      tout = ( t( state )  <=  stimon - state_onset )  +  1 ;
      
      % Is it time to change state? There might be a succession of
      % transitions depending on the timeout values. Therefore, we process
      % all of them. We check the lookup table. This returns a non-zero
      % value if we change state according to current state, current
      % target, and whether the current state has timed out.
      while  tlog.E ( state , target , tout )
        
        % Set new state
        state = tlog.E ( state , target , tout ) ;
        
        % This is an end state , break the loop
        if  iends  <=  state
          endflg = true ;
          break
        end
        
        % Expected time of state onset is the first moment that the screen
        % can respond to the state change, which is the next expected
        % stimulus onset time
        state_onset = stimon ;
        
        % Check if the state has timed out already , this can only be the
        % case if the timeout is 0 seconds. Add +1 to get an index for the
        % lookup table tlog.E. Remember, ~ takes precedence over + .
        tout = ~ t ( state )  +  1 ;
        
        % Get the list of ptb stimulus links presented in this state
        l = S2L { state } ;
        
        % Load stimulus events by adding to the list of variable parameter
        % changes that will be requested during the next call to the
        % stimulation functions
        vpc( l ) = cellfun (  @( v , n )  [ v ; n ]  ,  ...
          vpc( l )  ,  SEV{ state }  ,  'UniformOutput'  ,  false  ) ;
        
        % Mark down which stimulus link has variable parameter changes
        vpi( l ) = vpi( l )  |  ~ cellfun(  @isempty  ,  SEV{ state }  ) ;
        
        % Load MET signal buffer , first determine how many signals will be
        % loaded. There is at least a state change signal. There may also
        % be mevents.
        n = 1  +  MEV( state ).n ;
        
        % See if we overfill the buffer , in normal circumstances
        % this will never happen. If it does then raise an error.
        if  mbuf.n - mbuf.i  <  n
          C = buferr ( MCC , tid , sd , 'mbuf' ) ;
          error (  C { : }  ) ;
        end
        
        % Buffer positions to fill
        j = mbuf.i + 1 : mbuf.i + n ;
        
        % Fill buffer
        mbuf.i = j ( end ) ;
        mbuf.sig( j ) = [  MSID.mstate  ;  MEV( state ).sig  ] ;
        mbuf.crg( j ) = [        state  ;  MEV( state ).crg  ] ;
        mbuf.tim( j ) = stimon ;
        
        
      end % task logic states
      
      % We're forced to check again if it is an end state because Matlab
      % lacks a goto statement, which would be the perfect thing, here.
      if  endflg  ,  break  ,  end
      
      
      %-- Stimulus link stimulation --%
      
      % Loop eye frame buffers
      for  e = EYEBUF
        
        % Assign buffer flag
        tvar.eyebuf = e ;

        % Set stereo drawing buffer
        if  tconst.stereo
          Screen (  'SelectStereoDrawBuffer'  ,  tconst.winptr  ,  e  ) ;
        end
        
        % Draw blue receptive/response field ovals , and only blue. Don't
        % touch the red or green channels!
%         if  rf
%           Screen (  'BlendFunction'  ,  tconst.winptr  ,  ...
%             'GL_ONE'  ,  'GL_ZERO'  ) ;
%           Screen (  'FrameOval'  ,  tconst.winptr  ,  [ 0 , 0 , 1 ]  ,  ...
%             rf  ) ;
%         end

        % Masking square enabled , draw it
        if  PHOTOR.msk
          
          Screen (  'FillRect'  ,  tconst.winptr  ,  ...
            PHOTOR.mskclu  ,  PHOTOR.mskrec  ) ;
          
        end % msk square
        
        % Loop visible stimulus links
        for  j = l
          
          % Assign variable parameter change list
          tvar.varpar = vpc{ j } ;
          
          % Execute stimulation function
          [ sdl{ j } , hit ] = D( j ).stim ( sdl{ j } , tconst , tvar ) ;
          
          % Hit region updated , raise flag and save new hit region list
          if  hit
            h( j ) = true ;
            H{ j } = sdl{ j }.hitregion ;
          end
          
          % Variable parameter changes used
          if  vpi( j )
            vpi( j ) = false ;
            vpc{ j } = [] ;
          end
          
        end % stimulus links
        
        % Disable any alpha blending to draw photodiode rectangle
        Screen (  'BlendFunction'  ,  tconst.winptr  ,  ...
          'GL_ONE'  ,  'GL_ZERO'  ) ;
  
        % Photodiode rectangle , flip colour if not right-eye frame 
        % buffer , then draw
        if  e < 1  ,  PHOTOR.i = ~ PHOTOR.i ;  end
        Screen (  'FillRect'  ,  tconst.winptr  ,  ...
          PHOTOR.colour( PHOTOR.i + 1 , : )  ,  PHOTOR.rect  ) ;
        
      end % eye frame buffers
      
      
      %-- MET synchronisation --%
      
      % Tell PsychToolbox that there will be no more drawing to the frame
      % buffers
      Screen (  'DrawingFinished'  ,  tconst.winptr  ) ;
      
      % Send any new hit regions through 'stim' shared memory
      if  any ( h )
        
        % Non-blocking write to stim shared memory , lower the flags only
        % if the write was successful
        h( h ) = ~ met ( 'write'  , 'stim' , stimon , h , H{ h } ) ;
        
      end % 'stim' hit regions
      
      % Send any new MET signals
      if  mbuf.i
        
        % Index vector
        j = 1 : mbuf.i ;
        
        % Attempt to send a MET signal request to MET server controller.
        % Non-blocking write , so get the number of signals that were sent.
        j = met ( 'send' , mbuf.sig( j ) , mbuf.crg( j ) , mbuf.tim( j ) );
        
        % Not all signals were sent
        if  j  <  mbuf.i
          
          % Index vector of unsent signals
          j = j + 1 : mbuf.i ;
          
          % New position of last buffered signal
          mbuf.i = numel ( j ) ;
          
          % Transfer unsent signals to the front of the buffer
          mbuf.sig( 1 : mbuf.i ) = mbuf.sig ( j ) ;
          mbuf.crg( 1 : mbuf.i ) = mbuf.crg ( j ) ;
          mbuf.tim( 1 : mbuf.i ) = mbuf.tim ( j ) ;
          
          % Warn user
          met (  'print'  ,  ...
            sprintf ( 'metptb: rebuffering %d MET signals' , mbuf.i )  ,...
            'E'  )
          
        else
          
          % All signals were sent , clear the buffer
          mbuf.i = 0 ;
          
        end % resolve buffer
        
      end % send MET signals
      
      
      %-- Flip frame buffer to screen --%
      
      % First check state of the timestamp buffer , do we need to jump to
      % next buffer?
      if  tbuf.i  ==  tbuf.n
        
        % Yes , advance to first position of the next buffer
        tbuf.i  = 1 ;
        tbuf.ib = tbuf.ib  +  1 ;
        
        % Buffer overflow
        if  MAXBUF.n  <  tbuf.ib
          C = buferr ( MCC , tid , sd , 'tbuf' ) ;
          error (  C { : }  ) ;
        end
        
        % This buffer has not been allocated yet , grab memory for new
        % buffers
        if  isempty ( tbuf.VBLTimestamp{ tbuf.ib } )
          
          tbuf.VBLTimestamp{ tbuf.ib } = zeros ( tbuf.n , 1 ) ;
          tbuf.StimulusOnsetTime{ tbuf.ib } = zeros ( tbuf.n , 1 ) ;
          tbuf.FlipTimestamp{ tbuf.ib } = zeros ( tbuf.n , 1 ) ;
          tbuf.Missed{ tbuf.ib } = zeros ( tbuf.n , 1 ) ;
          tbuf.Beampos{ tbuf.ib } = zeros ( tbuf.n , 1 ) ;
          
        end
        
      % Nope , stay with current buffer
      else
        
        % Advance by one position
        tbuf.i = tbuf.i  +  1 ;
        
      end % check timestamp buffer
      
      % Flip frame buffer to screen
      [  tbuf.VBLTimestamp{ tbuf.ib }( tbuf.i )  ,  ...
         tbuf.StimulusOnsetTime{ tbuf.ib }( tbuf.i )  ,  ...
         tbuf.FlipTimestamp{ tbuf.ib }( tbuf.i )  ,  ...
         tbuf.Missed{ tbuf.ib }( tbuf.i )  ,  ...
         tbuf.Beampos{ tbuf.ib }( tbuf.i )  ]  =  ...
         Screen (  'Flip'  ,  tconst.winptr  ,  vbl + HFI  ) ;
      
      % Get latest vbl and stimulus onset times
         vbl = tbuf.VBLTimestamp{ tbuf.ib }( tbuf.i ) ;
      stimon = tbuf.StimulusOnsetTime{ tbuf.ib }( tbuf.i ) ;
      
      % Check for skipped frame
      tvar.skip = 0  <  tbuf.Missed{ tbuf.ib }( tbuf.i ) ;
      
      
    end % animation loop
    
    
    %-- End of the trial --%
    
    % Send any MET signals that remain in the buffer , blocking write
    if  mbuf.i
      j = 1 : mbuf.i ;
      met ( 'send' , mbuf.sig( j ) , mbuf.crg( j ) , mbuf.tim( j ) , ...
        WAIT_FOR_SIG ) ;
    end
    
    % Is this an aborted trial?
    if  state  <  iends
      
      % Then send only a trial stop signal with trial aborted outcome code
      j = 1 ;
      mbuf.sig( 1 ) = MSID.mstop ;
      mbuf.crg( 1 ) = ABORT ;
      
    % Nope , it ended on its own
    else
      
      % The number of mevents to load plus stop signal
      n = 1  +  MEV( state ).n ;
        
      % Check for overflow
      if  mbuf.n - mbuf.i  <  n
        C = buferr ( MCC , tid , sd , 'mbuf' ) ;
        error (  C { : }  ) ;
      end

      % Fill buffer
      j = 1 : n ;
      mbuf.sig( j ) = [  MEV( state ).sig  ;  MSID.mstop         ] ;
      mbuf.crg( j ) = [  MEV( state ).crg  ;  state - iends + 1  ] ;
      
    end % mbuf
    
    % Send stop signal
    met ( 'send' , mbuf.sig( j ) , mbuf.crg( j ) , [] , WAIT_FOR_SIG ) ;
    
    
    %-- Close trial --%
    
    % Get the mstop time
    i = false ( 0 ) ;
    while  ~ any ( i )
      
      [ ~ , ~ , sig , crg , tim ] = met ( 'recv' , WAIT_FOR_SIG ) ;
      
      % Quit signal , close stimulus descriptors , terminate function
      if  any ( sig  ==  MSID.mquit )
        sclose ( D , ptb , sdl , 's' ) ;
        return
      end
      
      % mstop signal
      i = sig  ==  MSID.mstop ;
      
    end % mstop
    
    % Timeout screen presentation duration for this outcome
    tout = timgui.h.UserData.tout (  crg ( i )  ) ;
    
    % Timeout screen required
    if  tout
      
      % Have the timeout GUI draw the screen. Be careful not to run Screen
      % Flip and to restore the state of the random number generator to
      % what it was at the end of the trial.
      timgui.s.Callback ( timgui.s , [] , false , true )
      
    end
    
    % Mask square enabled
    if  PHOTOR.msk
      
      % Loop eye frame buffers
      for  e = EYEBUF
        
        % Set stereo drawing buffer
        if  tconst.stereo
          Screen (  'SelectStereoDrawBuffer'  ,  tconst.winptr  ,  e  ) ;
        end

        % Masking square
        Screen ( 'FillRect' , tconst.winptr , PHOTOR.mskclu , ...
          PHOTOR.mskrec ) ;

      end % eye frame buffs
    end % msk square enabled
    
    % Begin clearing the screen , then continue closing the trial
    Screen (  'AsyncFlipBegin'  ,  tconst.winptr  ) ;
    
    % Trial stop time
    trial_end = tim ( i ) ;
    
    % End of trial state of the random number generator
    rng_end = rng ;
    
    % End of trial check-sums
    chksum_end = chksums ( D , ptb , td , sdl ) ;
    
    % Close stimulus descriptors , keep closed descriptors. Trial-close, so
    % some stimuli may not release all resources.
    sdl_c.( td.task ) = sclose ( D , ptb , sdl , 't' ) ;
    
    % Write data files to trial directory
    savedat ( MC , MCC , DATFMT , sd , tid , rng_start , chksum_start , ...
      rng_init , trial_start , tbuf , trial_end , rng_end , chksum_end ,...
      timgui.h , tout )
    
    % Flush messages to terminal and log file
    met ( 'flush' )
    
    % Try to force Java garbage collection , we do this here in case there
    % is a timeout screen being shown , then we double up the use of time
    java.lang.System.gc( )
    
    % Wait for screen to finish clearing , get estimated onset time
    [ ~ , stimon ] = Screen (  'AsyncFlipEnd'  ,  tconst.winptr  ) ;
    
    % Timeout screen required
    if  tout
      
      % Finish waiting for the minimum required timeout duration. Use pause
      % instead of WaitSecs as this may allow background Java threads to
      % keep working.
      pause ( max(  [ 0 , tout - GetSecs + stimon ]  ) ) ;
      
      % And turn off the timeout screen , allow Screen flip
      timgui.s.Callback ( timgui.s , [] )
      
    end % timeout
    
    % mwait received , hence no trial will follow for a time. Reveal the
    % timeout gui
    if  mwait  ,  timgui.h.Visible = 'on' ;  end
    
  end % trial loop
  
  
end % runc


% Returns a brand new ptb trial buffer. Field names store the following:
%
%   ib - buffer index
%   i - measurement index , points to the last mesurement to be buffered
%   n - number of time measurements per buffer
%   
%   VBLTimestamp ,
%   StimulusOnsetTime ,
%   FlipTimestamp ,
%   Missed ,
%   Beampos - Different buffer types. Each is used to store a different
%     output from Screen 'Flip'. Each one is a MAXBUF.n x 1 cell array,
%     where ib is the element of the buffer that is currently being filled.
%     Each element contains one buffer that is n by 1 elements, storing
%     approximately MAXBUF.dur seconds of time stamps.
% 
%   Example - let nb be 10 , i be 3 , and n be 600. The vertical-blanking
%     interval timestamp for the 1400th frame will be stored in
%     VBLTimestamp{ 3 }( 200 )
%
function  b = mkbuf ( MAXBUF , tconst )
  
  % Buffer field names
  C = { 'ib' , 'i' , 'n' , 'VBLTimestamp' , 'StimulusOnsetTime' , ...
    'FlipTimestamp' , 'Missed' , 'Beampos' } ;
  
  % Struct creation cell array
  C = [  C  ;  cell( size(  C  ) )  ] ;
  
  % Create buffer struct
  b = struct (  C { : }  ) ;
  
  % Initial buffer index and time measurement index
  b.ib = 1 ;
  b.i = 0 ;
  
  % Number of frames per buffer , round up to guarantee at least one
  b.n = ceil ( MAXBUF.dur  /  tconst.flipint ) ;
  
  % Allocate cell arrays and initialise the first buffer for type of
  % PsychToolbox time measurement
  for  i = 4 : size ( C , 2 )
    
    % Buffer field name
    f = C{ 1 , i } ;
    
    % Allocate buffer spaces
    b.( f ) = cell (  MAXBUF.n  ,  1  ) ;
    
    % Allocate first buffer
    b.( f ){ 1 } = zeros ( b.n , 1 ) ;
    
  end % buffers
  
end % mkbuf


% Load current set of ptb-type stimulus definitions and return their names
function  [ sdef , dnam ] = loadsdef ( MC , SDCELL , sd )
  
  % Get stimulus definition function names
  dnam = fieldnames ( sd.type ) ;
  
  % Get stimulus definition type strings
  T = struct2cell ( sd.type ) ;
  
  % Identify ptb-type stimulus definitions
  i = strcmp ( T , 'ptb' ) ;
  
  % No ptb stimulus definitions in use
  if  ~ any ( i )
    met ( 'print' , 'metptb: no ptb-type stimuli in use' , 'E' )
    sdef = [] ;
    return
  end
  
  % Keep function names of only ptb stimuli
  dnam = dnam ( i ) ;
  
  % Name of directory containing current session's set of stimulus
  % definitions
  d = fullfile (  sd.session_dir  ,  MC.SESS.STIM  ) ;
  
  % Navigate to that directory , this will force Matlab to use the
  % functions that it finds there before any other , if the function name
  % exists in multiple places on the Matlab path
  cd ( d )
  
  % Convert function names to handles
  H = cellfun (  @str2func  ,  dnam  ,  'UniformOutput'  ,  false  ) ;
  
  % Initialise stimulus definition struct
  sdef = repmat (  struct (  SDCELL { : }  )  ,  ...
    size ( dnam )  ) ;
  
  % Load stimulus definitions
  for  i = 1 : numel ( dnam )
    
    % Stimulus definition , pass in RF definitions so that variable
    % parameter defaults are matched to RF preferences
    [ sdef( i ).type   , ...
      sdef( i ).varpar , ...
      sdef( i ).init   , ...
      sdef( i ).stim   , ...
      sdef( i ).close  , ...
      sdef( i ).chksum ] = H{ i }( sd.rfdef ) ;
    
  end % stim def
  
end % loadsdef


% Initialise an empty list of closed stimulus descriptors for each stimulus
% link on a task-by-task basis
function  sdl_c = initsdlc ( sd )
  
  % Loop the set of task names
  for  T = fieldnames ( sd.task )'  ,  t = T { 1 } ;
    
    % The number of stimulus links in this task
    n = numel ( fieldnames(  sd.task.( t ).link  ) ) ;
    
    % Build empty list attached to the name of this task
    sdl_c.( t ) = cell ( n , 1 ) ;
    
  end % tasks
  
end % initsdlc


% Make sure that variable parameters of ptb-type stimuli are all within
% numerical range. Also checks stimulus events.
function  vpcheck ( MCC , sd , td , ptb )
  
  % Tag string
  if  isempty ( sd.tags )
    tags = '' ;
  else
    tags = sprintf (  MCC.FMT.TAGSTR  ,  sd.tags{ : }  ) ;
  end
  
  % Session string
  S = sprintf (  MCC.FMT.SESSDIR  ,  sd.subject_id  ,  ...
    sd.experiment_id  ,  sd.session_id  ,  ...
    tags  ) ;
  
  % Loop ptb-type stimulus links
  for  i = find ( ptb )
    
    % Stimulus definition name
    n = td.stimlink( i ).stimdef ;
    
    % Variable parameter definition
    vpd = sd.vpar.( n ) ;
    
    % Stim link's variable parameter set
    sls = td.stimlink( i ).vpar ;
    
    % link variable parameter names
    sln = fieldnames ( sls ) ;
    
    % link variable parameter values
    slv = struct2cell ( sls ) ;
    
    % Check that all variable parameters are accounted for
    j = find (  ~ ismember(  vpd( : , 1 )  ,  sln  )  ,  1  ,  'first'  ) ;
    
    if  j
      
      error (  'MET:metptb:vpar'  ,  [ 'metptb: session %s , ' , ...
        'trial %d , stim link %s , var.par. %s is missing' ]  ,  ...
        S  ,  td.trial_id  ,  td.stimlink( j ).name  ,  vpd{ j , 1 }  )
      
    end % missing parameter
    
    % Check that no value is inf or nan
    j = find (  cellfun(  @( v )  isnan( v ) || isinf( v )  ,  slv  )  ,...
      1  ,  'first'  ) ;
    
    if  j
      
      error (  'MET:metptb:vpar'  ,  [ 'metptb: session %s , ' , ...
        'trial %d , stim link %s , var.par. %s is NaN or Inf' ]  ,  ...
        S  ,  td.trial_id  ,  td.stimlink( j ).name  ,  sln{ j }  )
      
    end % inf or nan
    
    % Check that all values are scalar real doubles
    j = find (  ~ cellfun (  ...
      @( v )  isscalar( v )  &&  isreal( v )  &&  isa( v , 'double' )  ,...
      slv  )  ,  1  ,  'first'  ) ;
    
    if  j
      
      error (  'MET:metptb:vpar'  ,  [ 'metptb: session %s , ' , ...
        'trial %d , stim link %s , var.par. %s is not a scalar real ' , ...
        'double' ]  ,  S  ,  td.trial_id  ,  td.stimlink( j ).name  ,  ...
        sln{ j }  )
      
    end % scalar real double
    
    % Check that values are within numerical range
    j = find (  cellfun(  ...
      @( p , mn , mx )  sls.( p ) < mn  ||  mx < sls.( p )  ,  ...
      vpd( : , 1 )  ,  vpd( : , 4 )  ,  vpd( : , 5 )  )  ,  ...
      1  ,  'first'  ) ;
    
    if  j
      
      error (  'MET:metptb:vpar'  ,  [ 'metptb: session %s , ' , ...
        'trial %d , stim link %s , var.par. %s falls out of range' ]  , ...
        S  ,  td.trial_id  ,  td.stimlink( j ).name  ,  sln{ j }  )
      
    end % scalar real double
    
    % Check that values are in the correct numerical domain
    j = find (  cellfun(  ...
      @( p , d )  d == 'i'  &&  mod( sls.( p ) , 1 )  ,  ...
      vpd( : , 1 )  ,  vpd( : , 2 )  )  ,  1  ,  'first'  ) ;
    
    if  j
      
      error (  'MET:metptb:vpar'  ,  [ 'metptb: session %s , ' , ...
        'trial %d , stim link %s , var.par. %s not an integer' ]  , ...
        S  ,  td.trial_id  ,  td.stimlink( j ).name  ,  sln{ j }  )
      
    end % domain check
    
  end % stim link
  
  % No stimulus events , end here
  if  isempty ( td.sevent )  ,  return  ,  end
  
  % Loop stimulus events
  for  i = 1 : numel ( td.sevent )
    
    % Stimulus link index
    j = td.sevent( i ).istimlink ;
    
    % Jump to next sevent if link hasn't got ptb-type stim def
    if  ~ ptb ( j )  ,  continue  ,  end
    
    % Stimulus definition name
    n = td.stimlink( j ).stimdef ;
    
    % Variable parameter definition
    vpd = sd.vpar.( n ) ;
    
    % Find definition for the variable parameter that's changed by sevent
    j = strcmp (  vpd( : , 1 )  ,  td.sevent( i ).vpar  ) ;
    
    % Value that sevent wants to assign to variable parameter
    v = td.sevent( i ).value ;
    
    % Check Inf or NaN
    if  isinf ( v )  ||  isnan ( v )
      
      error (  'MET:metptb:vpar'  ,  [ 'metptb: session %s , trial %d' ,...
        ' , sevent %s , var.par. %s is NaN or Inf' ]  ,  S  ,  ...
        td.trial_id  ,  td.sevent( i ).name  ,  td.sevent( i ).vpar  )
      
    % Check scalar real double
    elseif  ~ isscalar( v )  ||  ~ isreal( v )  ||  ~ isa( v , 'double' )
      
      error (  'MET:metptb:vpar'  ,  [ 'metptb: session %s , trial %d' ,...
        ' , sevent %s , var.par. %s is not a scalar real double' ]  ,  ...
        S  ,  td.trial_id  ,  td.sevent( i ).name  ,  ...
        td.sevent( i ).vpar  )
      
    % Check if values in range
    elseif  v < vpd{ j , 4 }  ||  vpd{ j , 5 } < v
      
      error (  'MET:metptb:vpar'  ,  [ 'metptb: session %s , trial %d' ,...
        ' , sevent %s , var.par. %s is out of range' ]  ,  ...
        S  ,  td.trial_id  ,  td.sevent( i ).name  ,  ...
        td.sevent( i ).vpar  )
      
    % Check if in the right numerical domain
    elseif  vpd{ j , 2 } == 'i'  &&  mod( v , 1 )
      
      error (  'MET:metptb:vpar'  ,  [ 'metptb: session %s , trial %d' ,...
        ' , sevent %s , var.par. %s integer expected but floating ' , ...
        'value given' ]  ,  S  ,  td.trial_id  ,  td.sevent( i ).name  ,...
        td.sevent( i ).vpar  )
      
    end % check sevent value
    
  end % stimulus events
  
  
end % vpcheck


% Task logic state to stimulus link index map. S2L{ i } returns a vector of
% stimulus link indeces such that those links are presented in the ith
% state. Does not provide a mapping for end states, thus S2L has 4 fewer
% elements than there are task logic states.
function  S2L = state2linkmap ( ptb , td , tlog )
  
  % Get state to task stimulus mapping in a cell array
  C = struct2cell (  tlog.stim  ) ;
  
  % Remove end states
  C( end-3 : end ) = [] ;
  
  % Get the list of task stimulus indeces for each stimulus link
  istim = [ td.stimlink.istim ] ;
  
  % Detect which links are connected to each task. Here C{ i }( j ) is a
  % logical value that is true if the jth link is connected to a task
  % stimulus listed in the ith state
  C = cellfun (  @( c )  ismember ( istim , c )  &  ptb  ,  ...
    C  ,  'UniformOutput'  ,  false  ) ;
  
  % Convert logical indeces to linear indeces , the desired output
  S2L = cellfun (  @( c )  find ( c )  ,  C  ,  ...
    'UniformOutput'  ,  false  ) ;
  
end % state2linkmap


% Return stimulus event sets for each task logic state. This becomes a
% nested cell array where SEV{ i }{ j }( k , : ) returns a 2-element cell
% array specifying the kth variable parameter name and value pair for the
% jth stimulus link in the ith state. It matters that index j can be handed
% to S2L{ i }( j ) to return the master index value for that stimulus link.
function  SEV = sevents ( td , tlog , S2L )
  
  % Get the task logic state index from each stimulus event
  istate = [ td.sevent.istate ] ;
  
  % Get the stimulus link index for each stimulus event
  istimlink = [ td.sevent.istimlink ] ;
  
  % Allocate the outer cell array with a space for each task logic state
  % that is not an end state
  SEV = cell ( tlog.N.state - 4 , 1 ) ;
  
  % Loop states
  for  i = 1 : numel ( SEV )
    
    % Find stim events attached to this state
    se = istate  ==  i ;
    
    % Allocate middle nested cell array with a space for each stimulus link
    % presented in state i
    SEV{ i } = cell (  1  ,  numel( S2L{ i } )  ) ;
    
    % Loop stimulus links attached to this state , j advances through the
    % mid-layer cell array , k advances through the master indeces
    j = 0 ;
    for  k = S2L{ i }  ,  j = j + 1 ;
      
      % Find all stimulus events attached to this stimulus link in this
      % state. Remember that the == operator takes precedence over &.
      % Because of how S2L is made in state2linkmap, this keeps only events
      % concerning ptb-type stimulus links.
      sse = istimlink == k  &  se ;
      
      % Build list of variable parameter name and value pairs , this is the
      % inner-most nested cell array
      SEV{ i }{ j } = {  td.sevent( sse ).vpar  ;
                         td.sevent( sse ).value  }' ;
      
    end % stim links
    
  end % states
  
end % sevents


% Build a list of MET signal events. MEV( i ) is a struct listing all
% events in state i ; field .n gives the number of events, .sig gives the
% MET signal identifier for each event, and .crg gives the cargo for each
% event
function  MEV = mevents ( MCC , td , tlog )
  
  % MET signal identifier name-to-value map
  MSID = MCC.MSID ;
  
  % Allocate struct array with a space for each state , including end
  % states
  MEV = repmat (  struct ( 'n' , [] , 'sig' , [] , 'crg' , [] )  ,  ...
    tlog.N.state  ,  1  ) ;
  
  % State index vector showing which events are attached to which state
  istate = [ td.mevent.istate ] ;
  
  % Loop states
  for  i = 1 : tlog.N.state
    
    % Events attached to this state
    j = istate  ==  i ;
    
    % Build struct
    MEV( i ) = struct (  'n'  ,  sum ( j )  ,  ...
                       'sig'  ,  [ td.mevent( j ).msig  ]'  ,  ...
                       'crg'  ,  [ td.mevent( j ).cargo ]'  ) ;
                     
    % Look for mreward MET signals
    j = MEV( i ).sig  ==  MSID.mreward ;
    
    % Apply reward slope and baseline to mreward cargos , round up to next
    % integer i.e. millisecond
    if  any ( j )
      
      MEV( i ).crg( j ) = ceil (  ...
        td.reward( 1 )  +  td.reward( 2 )  *  MEV( i ).crg( j )  ) ;
      
    end % mreward cargo
    
    % Cap MET signal cargo value at maximum allowable size
    j = MCC.DAT.MAXCRG  <  MEV( i ).crg ;
    MEV( i ).crg( j ) = MCC.DAT.MAXCRG ;
    
  end % states
  
end % mevents


% Determine oval PTB rectangles for receptive/response field definitions
function  rf = rfovals ( tconst , sd )
  
  % No RF definitions? Return empty array.
  if  isempty (  sd.rfdef  )
    rf = [] ;
    return
  end
  
  % Centre of RFs relative to trial origin, in degrees
  x = [ sd.rfdef.xcoord ]  +  tconst.origin( 1 ) ;
  y = [ sd.rfdef.ycoord ]  +  tconst.origin( 2 ) ;
  
  % Find radius of RFs in degrees
  rad = [ sd.rfdef.width ]  /  2 ;
  
  % Initialise rf rectangle array , in degrees from centre of screen. Row
  % order [ left ; top ; right ; bottom ].
  rf = [  x - rad  ;  y + rad  ;  x + rad  ;  y - rad  ] ;
  
  % Convert to pixels from the centre of the screen
  rf = tconst.pixperdeg  *  rf ;
  
  % Pixels from edge of screen in horizontal ...
  rf( [ 1 , 3 ] , : ) = rf( [ 1 , 3 ] , : )  +  tconst.wincentx ;
  
  % ... and vertical
  rf( [ 2 , 4 ] , : ) = rf( [ 2 , 4 ] , : )  +  tconst.wincenty ;
  
  % Cartesian to PTB coordinate system
  rf( [ 2 , 4 ] , : ) = tconst.winheight  -  rf( [ 2 , 4 ] , : ) ;
  
end % rfovals


% Run stimulus definition trial initialisation functions and return the new
% set of stimulus descriptors
function  sdl = stiminit ( tconst , D , ptb , td , sdl_c )
  
  % Allocate cell array with a space for each stimulus link , regardless of
  % type
  sdl = cell (  1  ,  numel( td.stimlink )  ) ;
  
  % Stimulus link index to cell array
  istimlink = num2cell ( find(  ptb  ) ) ;
  
  % Variable parameter sets cell array
  vpar = { td.stimlink( ptb ).vpar } ;
  
  % Make new stimulus descriptors for each ptb-type stimulus link
  sdl( ptb ) = cellfun (  ...
    @( i , v )  D( i ).init ( v , tconst , sdl_c{ i } )  ,  ...
    istimlink  ,  vpar  ,  'UniformOutput'  ,  false  ) ;
  
  
end % stiminit


% Compute check sum from each stimulus descriptor
function  c = chksums ( D , ptb , td , sdl )
  
  % Allocate zeros
  c = zeros ( size(  td.stimlink  ) ) ;
  
  % Stimulus link index to cell array
  istimlink = num2cell ( find(  ptb  ) ) ;
  
  % Compute check sums
  c( ptb ) = cellfun (  @( i , s )  D( i ).chksum( s )  ,  ...
    istimlink  ,  sdl( ptb )  ) ;
  
end % chksums


% Close stimulus descriptors , return closed descriptors
function  sdl_c = sclose ( D , ptb , sdl , type )
  
  % Allocate closed descriptors
  sdl_c = cell ( size(  sdl  ) ) ;
  
  % Stimulus link index to cell array
  istimlink = num2cell ( find(  ptb  ) ) ;
  
  % Close descriptors
  sdl_c( ptb ) = cellfun (  @( i , s )  D( i ).close( s , type )  ,  ...
    istimlink  ,  sdl( ptb )  ,  'UniformOutput'  ,  false  ) ;
  
end % sclose


% Generate input arguments for error( ) to report a buffer overflow
function  C = buferr ( MCC , tid , sd , bnam )
  
  % Buffer type string
  switch  bnam
    case  'mbuf'  ,  t = 'MET signal' ;
    case  'tbuf'  ,  t = 'PTB timestamp' ;
  end
  
  % Assemble input arguments
  C = {  [ 'MET:metptb:' , bnam ]  ,  [ 'metptb: ' , t , ' buffer ' , ...
    'overflow during trial ' , tid , ' of session ' , MCC.FMT.SESSDIR ],...
    sd.subject_id  ,  sd.experiment_id  ,  sd.session_id  ,  ...
    sprintf( MCC.FMT.TAGSTR , sd.tags{ : } )  } ;
  
end % buferr


% Write buffered data to files in the current trial directory
function  savedat ( MC , MCC , DATFMT , sd , tid , ...
  rng_start , chksum_start , rng_init , trial_start , tbuf , trial_end ,...
  rng_end , chksum_end , h , tout )
  
  % Data file base name , replace %s with trial identifier string , no file
  % type suffix
  DATFMT = sprintf (  DATFMT  ,  tid  ) ;
  
  % Full path to data file , no suffix
  f = fullfile (  sd.session_dir  ,  MC.SESS.TRIAL  ,  tid  ,  DATFMT  ) ;
  
  
  %-- Binary data --%
  
  % Build data struct
  d.mat_version = version ;
  d.rng_start = rng_start ;
  d.chksum_start = chksum_start ;
  d.rng_init = rng_init ;
  d.trial_start = trial_start ;
  d.rng_end = rng_end ;
  d.chksum_end = chksum_end ;
  d.trial_end = trial_end ;
  
  % Make index vector for filled timestamp buffers
  ftb = 1 : tbuf.ib - 1 ;
  ib = tbuf.ib ;
  
  % And another for filled positions in the last buffer
  flb = 1 : tbuf.i ;
  
  % Timestamp buffer names , remove index and size
  F = setdiff ( fieldnames( tbuf )' , { 'ib' , 'i' , 'n' } ) ;
  
  % Concatenate into single vectors
  for  i = 1 : numel ( F )  ,  fn = F{ i } ;
    
    d.( fn ) = [  cell2mat( tbuf.( fn )( ftb ) )  ;
                  tbuf.( fn ){ ib }( flb )  ] ;
    
  end % concat buff
  
  % Convert timestamp buffers into uint32 measuring microseconds from start
  % of trial
  F = setdiff (  F  ,  { 'Missed' , 'Beampos' }  ) ;
  
  for  i = 1 : numel ( F )  ,  fn = F{ i } ;
    
    d.( fn ) = uint32 (  1e6  *  ( d.( fn ) - trial_start )  ) ;
    
  end % time unit conversion
  
  % Convert Missed buffer into a logical vector where true means skipped
  % frame
  d.Missed = 0  <  d.Missed ;
  
  % Report any missed frames
  if  any ( d.Missed )
    met (  'print'  ,  ...
      sprintf ( '  [ %d skipped frames ]' , sum ( d.Missed ) )  ,  'E'  )
  end
  
  % Convert beam positions into uint32 as well , but don't subtract start
  % time
  d.Beampos = uint32 ( d.Beampos ) ;
  
  % Find timeout type popup menu
  c = findobj ( h , 'Style' , 'popupmenu' , 'Tag' , 'type' ) ;
  
  % Tag on information about the timout screen type and duration
  d.Timeout_type = c.String {  c.Value  } ;
  d.Timeout_secs = tout ;
  
  % Save binary copy of the data
  save (  [ f , '.mat' ]  ,  '-struct'  ,  'd'  )
  
  
  %-- ASCII data --%
  
  % Matlab version string
  d.mat_version = [ 'mat_version: ' , d.mat_version ] ;
  
  % PTB-style time stamps
  for  F = { 'trial_start' , 'trial_end' }  ,  fn = F { 1 } ;
    d.( fn ) = sprintf (  [ fn , ': ' , MCC.FMT.TIME ]  ,  d.( fn )  ) ;
  end
  
  % Random number generator
  for  F = { 'rng_start' , 'rng_init' , 'rng_end' }  ,  fn = F { 1 } ;
    
    d.( fn ) = sprintf (  '%s_Type: %s\n%s_Seed: %d\n%s_State: %d%s'  , ...
      fn  ,  d.( fn ).Type  ,  fn  ,  d.( fn ).Seed  ,  fn  ,  ...
      d.( fn ).State( 1 )  ,  ...
      list2str( d.( fn ).State( 2 : end ) , ',%d' )  ) ;
  
  end
  
  % Check sums
  for  F = { 'chksum_start' , 'chksum_end' }  ,  fn = F { 1 } ;
    
    d.( fn ) = sprintf (  '%s: %f%s'  ,  fn  ,  d.( fn )( 1 )  ,  ...
      list2str( d.( fn )( 2 : end ) , ',%f' )  ) ;
    
  end
  
  % Convert remaining fields
  F = setdiff (  fieldnames( tbuf )'  ,  { 'ib' , 'i' , 'n' }  ) ;
  
  for  i = 1 : numel ( F )  ,  fn = F{ i } ;
    
    % If no frames shown then have header without anything else
    if  isempty (  d.( fn )  )
      d.( fn ) = [ fn , ': ' ] ;
      continue
    end
    
    % Convert frame times to strings
    d.( fn ) = sprintf (  '%s: %d%s'  ,  fn  ,  d.( fn )( 1 )  ,  ...
      list2str ( d.( fn )( 2 : end ) , ',%d' )  ) ;
    
  end % concat buff
  
  % Convert Timout type and duration
  d.Timeout_type = [ 'Timeout_type: ' , d.Timeout_type ] ;
  d.Timeout_secs = sprintf ( [ 'Timeout_secs: ' , MCC.FMT.TIME ] , tout ) ;
  
  % Concatenate into a single string
  d = strjoin ( struct2cell( d ) , '\n' ) ;
  
  % Save ASCII file
  metsavtxt (  [ f , '.txt' ]  ,  d  ,  'w'  ,  'metptb'  )
  
  
end % savedat


% Converts vector into string of values. This will repeat the format string
% f once for every value
function  s = list2str ( L , f )
  
  if  isempty ( L )
    s = '' ;
    return
  end
  
  s = sprintf (  f  ,  L  ) ;
  
end % list2str

