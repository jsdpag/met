
function  metlegctl ( ~ )
% 
% metlegctl ( MC )
% 
% Matlab Electrophysiology Toolbox legacy task controller. This takes
% retrofitted versions of go.m and taskcontroller.m , which were used for
% training prior to the development of MET , and uses them to run
% eye-driven tasks. This is necessary because reading eye positions,
% plotting eye positions, and providing asynchronous rewards are needed,
% and they would bog down the older single-threaded version of
% taskcontroller.m.
% 
% This is intended to be a temporary solution until a more complete version
% of MET is ready.
% 
% MET signalling - This controller will generate mready triggers, mstop,
%   mwait abort, mstate, and mreward MET signals. The mreward signals
%   request pump activation by metdaqout.
% 
% MET shared memory - Reads from 'eye' shm, which metdaqeye is expected to
%   write to. Writes the hit box values of all visible stimuli to 'stim'
%   each time that the trial's state changes so that metlegeye can plot
%   them relative to the eye position.
% 
% Retrofitted versions along with supporting functions are found in
% met/m/legacy.
% 
% NOTE: No version of go.m or taskcontroller.m must be visible. If they
%   are, then a single threaded version might run ... and crash. For
%   example, if ~/Documents/sandbox/taskcontroller is on the path, then
%   this will not work until that directory is removed from the path.
% 
% Written by Jackson Smith - Dec 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global constants %%%
  
  global  MC  MCC  MSID  MOUT  MTIM
  
  % MET constants
    MC = met ( 'const' ) ;
  MSID = MC.SIG' ; MSID = struct ( MSID{ : } ) ;
  MOUT = MC.OUT' ; MOUT = struct ( MOUT{ : } ) ;
  
  % MET controller constants , includes information about default subject
  % directory and 'eye' shared memory format
  MCC = metctrlconst ;
  
  
  %%% Constants %%%
  
  % Location of legacy functions
  DNAM = fileparts (  which ( 'metlegctl' )  ) ;
  DNAM = fullfile ( DNAM , 'legacy' ) ;
  
  % Make sure directory exist
  if  ~ exist ( DNAM , 'dir' )
    
    error ( 'MET:metlegctl:dir' , [ 'metlegctl: Cannot' , ...
      'find ' , DNAME ] )
    
  end
  
  % go.m shutdown error identifier
  GOMEID = 'MET:GO:SHUTDOWN' ;
  
  % Pump index , metdaqout will run this one
  PMPIND = 1 ;
  
  % MET timer object
  MTIM = mettimerobj ( GOMEID , '' ) ;
  
  % Required MET shared memory , must have read access
  METSHM = { 'stim' , 'w' } ; % 'eye' , 'r' } ;
  
  % Psych Toolbox verbosity level.  
  %  0 - No output at all.
  %  1 - Only severe error messages.
  %  2 - Errors and warnings.
  %  3 - Additional information, e.g., startup output when opening an
  %      onscreen window.
  %  4 - Very verbose output, mostly useful for debugging PTB itself.
  %  5 - Even more information and hints. Usually not what you want.
  PTBVERB = 3 ;
  
  % Screen to head parameters
  PTBS2H = { 'preference' , 'screentohead' , 1 , 0 , 0 , 0 } ;
  
  % taskcontroller outcome character codes. Write these to header, for
  % clarity. Fill this when legacy directory added to path
  OUTCHAR = [] ;
  
  
  %%% Setup %%%
  
  % No access to any shm
  if  isempty ( MC.SHM )
    error ( 'MET:metlegctl:shm' , ...
      'metlegctl: No shm access given , check .cmet file' )
  end
  
  % Verify read access on required shm
  for  i = 1 : size ( METSHM , 1 )
    
    j = strcmp ( MC.SHM ( : , 1 ) , METSHM { i , 1 } ) ;
    
    if  all ( [ MC.SHM{ j , 2 } ]  ~=  METSHM { i , 2 } )
      error ( 'MET:metlegeye:shm' , ...
        'metlegctl: Needs %c access to shm ''%s'' , check .cmet file' , ...
        METSHM { i , 2 : -1 : 1 } )
    end
    
  end % shm read access
  
  % Check that neither go.m nor taskcontroller.m are currently visible.
  if  exist ( 'go.m' , 'file' )  ||  exist ( 'taskcontroller.m' , 'file' )
    
    error ( 'MET:metlegctl:path' , [ 'metlegctl: ' , ...
      'Another version of the legacy task controller is visible. ' , ...
      'Remove it from the path and try again.' ] )
    
  end
  
  % Temporarily add the legacy directory to the path
  addpath ( DNAM )
  
  % Finish assigning OUTCHAR
  OUTCHAR = foutchar ;
  
  % Send initialisation mready to metserver , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Wait for synchronising ready signal
  [ ~ , ~ , sig ] = met ( 'recv' , 1 ) ;
  
  % Return if any mquit signal received
  if  any ( sig  ==  MSID.mquit )
    rmpath ( DNAM )
    return
  end
  
  % Now make sure that the metdaqout controller knows which pump to run ,
  % non-blocking
  met ( 'send' , MSID.mrdtype , PMPIND , [] ) ;
  
  % Run the MET timer to keep incoming IPC clear
  start ( MTIM )
  
  
  %-- Open PsychToolbox Window --%
  
  % Make Psych Toolbox window descriptor.
  ptbwin = ptbwindescriptor( OUTCHAR.ABORT ) ;
  
  % Ask if this is a stereo task
  switch  ( questdlg ( 'Open PTB window in stereo mode?' , ...
                       'MET (legacy controller)' ) )
    case  'Yes' , STEREOMODE = 8 ; % Anaglyph red-left , blue-right
    case   'No' , STEREOMODE = 0 ; % Normal monoscopic
    case  { 'Cancel' , '' }
      error ( 'MET:metlegctl:stereo' , ...
        'metlegctl:Failed to determine stereo mode' )
  end
  
  ptbwin.STEREOMODE = STEREOMODE ;
  
  % Make sure that screen to head mapping is correct , this is for the
  % Linux - VGA splitter setup
  Screen ( PTBS2H{ : } ) ;
  
  % Setup PTB with default values
  PsychDefaultSetup ( 2 ) ;
  
  % Black PTB startup screen
  Screen ( 'Preference' , 'VisualDebugLevel' , 1 ) ;
  
  % How much does PTB-3 automatically tell you?
  Screen ( 'Preference' , 'Verbosity' , PTBVERB ) ;
  
  % Detect the stimulus monitor
  s = Screen ( 'Screens' ) ;
  if  isscalar ( s )
    error ( 'MET:metlegctl:screens' , ...
      'metlegctl: Only one screen connected' )
  end
  s = max ( s ) ;

  % Define black, white and grey
  ptbwin.black = BlackIndex ( s ) ;
  ptbwin.white = WhiteIndex ( s ) ;
  ptbwin.background = ( ptbwin.white - ptbwin.black ) / 2 * [ 1 , 1 , 1 ] ;
  
  % Prepare Psych Toolbox environment.
  PsychImaging ( 'PrepareConfiguration' ) ;
  PsychImaging ( 'AddTask' , 'General' , 'FloatingPoint32BitIfPossible' ) ;
  PsychImaging ( 'AddTask' , 'General' , 'NormalizedHighresColorRange' ) ;
  
  % Open PTB window.
  ptbwin.scrn = s ;
  ptbwin.ptr = PsychImaging ( 'OpenWindow' , ...
    s , ptbwin.background , [] , [] , [] , STEREOMODE ) ;
  
  % Disable OpenGL alpha blending function
  Screen ( 'BlendFunction' , ptbwin.ptr , GL_ONE , GL_ZERO ) ;
  
  
  %-- Complete gathering PTB window information --%
  
  % Get physical height and width of the screen in millimetres.
  spar = metscrnpar ;
  
  % Window size in pixels.
  [ ptbwin.size_px( 1 ) , ptbwin.size_px( 2 ) ]  =  ...
    Screen ( 'WindowSize' , ptbwin.ptr ) ;
  
  % Tangent of angle to left and right screen edges.
  t = spar.width / spar.subdist ;
  
  % Pixels per degree of visual field, assuming square pixels ...
  ptbwin.pixperdeg =  ptbwin.size_px( 1 ) / atand( t ) ;
  
  % Measured frame flip interval, in seconds.
  ptbwin.flipinterval = Screen ( 'GetFlipInterval' , ptbwin.ptr ) ;
  
  % One half flip interval
  ptbwin.halfflip = 0.5 * ptbwin.flipinterval ;
  
  
  %-- Discard unused variables --%
  
  clearvars -except  MC  MCC  MSID  MOUT  MTIM  DNAM  GOMEID  ptbwin
  
  
  %%% Run loop %%%
  
  try
    
    while  true
      go ( ptbwin )
    end
    
  catch  E
    
    % go.m will throw an error when the user wants to shut down, or if a
    % legitimate error occurs. Look at the error's identifier to find out.
    
  end
  
  
  %%% Clean up %%%
  
  % Shut down psych toolbox
  sca
  
  % Don't need legacy directory on the path any more
  rmpath ( DNAM )
  
  % Make sure that MET timer destroyed
    stop ( MTIM )
  delete ( MTIM )
  
  % Legitimate error was thrown , so pass it on
  if  ~ strcmp ( E.identifier , GOMEID )  ,  rethrow ( E ) ;  end
  
  
end % metlegctl


%%% SUBROUTINES %%%

function ptbwin = ptbwindescriptor( ABORT )
  
  ptbwin = ...
    struct( 'scrn' , [] , ...
             'ptr' , [] , ...
         'size_px' , [ 0 , 0 ] , ...
      'background' , [] , ...
          'origin' , [] , ...
       'pixperdeg' , [] , ...
    'flipinterval' , [] , ...
           'black' , [] , ...
           'white' , [] , ...
          'ABORTC' , ABORT , ...
      'STEREOMODE' , [] ) ;
  
end % init ptbwin

