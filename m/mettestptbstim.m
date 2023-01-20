
function  s = mettestptbstim ( name , vpinit , rfdef , varpar , keymsk ,...
  stereo , mirror , S_old , debug )
% 
% s = mettestptbstim ( name , vpinit , rfdef , varpar , keymsk , stereo ,
%   mirror , S_old , debug )
% 
% Matlab Electrophysiology Toolbox, testing MET stimuli of type 'ptb'.
% Before running a stimulus in a multi-processing environment where
% debugging is harder to do, it is useful to test a ptb stimulus using this
% function.
% 
% name is a string of the path to the stimulus definition function. vpinit
% is a variable parameter initialisation struct, argument vpar for stimulus
% definition function init. rfdef is a struct vector where each element
% defines the properties of a different receptive or response field , and
% is passed directly to the stimulus definition function ; see below for
% field names and meanings. varpar is a cell array of N rows by 3 columns ;
% each row names a variable parameter, provides a new value, and a time
% when the new value must be applied (seconds since first Screen 'Flip').
% keymsk is a numeric vector of integer values containing key codes (as
% returned by KbCheck) that are ignored, or masked ; pause keys are masked
% by default (see below). stereo is a PsychToolbox stereomode value, for
% testing binoccular stimuli ; 0 is the default. mirror is a single char
% saying whether or not to mirror data during the drawing process, this is
% done using PsychToolbox so that the MET ptb stimulus does not have to ;
% it is 'n' for no mirroring (default), 'h' for horizontal (left->right) or
% 'v' for vertical (top->bottom) mirroring, or 'b' for horizontal and
% vertical mirroring. S_old is a stimulus descriptor as returned by the
% close() function from the same stimulus definition. debug can be scalar
% logical, defaults false ; if true, then keyboard input to Matlab command
% line is not blocked.
% 
% Except for name, all input arguments are optional and can be ignored by
% providing [].
%
% A PsychToolbox window is opened and the ptb stimulus is run until the
% user hits any key that is not listed in keymsk. The centre of the screen
% and surface is always used as the cartesian origin and disparity i.e.
% ( 0 , 0 , 0 ). If the user hits Alt+p then execution is paused until
% Alt+p is hit again (left or right alt key, but not both together). If
% only one screen is detected then the PsychToolbox window only occupies
% the lower-right quadrant of the screen, rather than the whole screen.
% 
% Scalar struct s is returned, which contains the stimulus definition
% function handles, initialisation variable parameter struct, and stimulus
% descriptor as returned by close().
% 
% 
% MET ptb stimulus definition function form:
% 
%   [ type , varpar , init , stim , close , chksum ] = stimdef ( rfdef )
%   
%   type - string - The type of MET stimulus, in this case 'ptb'.
%   varpar - cell array N x 5 - Defines variable parameters, each record
%     i.e. row contains { string name , 'i' or 'f' , default , min , max }.
%     The second value is 'i' if the variable must be an integer, or it is
%     'f' if the value can be floating point. The last three are the
%     default, minimum, and maximum values of the parameter.
%   init, stim, close, chksum - function handles - These prepare, display,
%     destroy, and validate a stimulus.
%   
%   rfdef is the sole input argument. It is a struct vector of N elements,
%   where rfdef( i ) describes properties of the ith receptive/response
%   field. The stimdef function must adjust the default variable parameter
%   values in varpar to match at least rfdef( 1 ). Fields of rfdef all
%   contain scalar, real, double values and include:
%   
%     .contrast - Michelson contrast
%     .xcoord - Horizontal position
%     .ycoord - Vertical position
%     .width - RF diameter
%     .orientation - Preferred orientation of stimulus e.g. a bar or
%       grating. Velocity is always orientation + 90 degrees at the given
%       speed.
%     .speed - Preferred speed of stimulus
%     .disparity - Preferred binocular disparity relative to the fixation
%       point.
% 
%   All values are in degrees of visual field. Exceptions are .contrast,
%   .orientation, and .speed which are in units of Michelson contrast,
%   degrees of counter-clockwise rotation, and degrees of visual field per
%   second. xcoord and ycoord define a point in standard Cartesian
%   coordinates relative to the trial origin.
% 
% 
% Trial initialiser function init has the form:
%   
%   S = init ( vpar , tconst , Sold )
%   
%   vpar is a scalar struct with a field for each variable parameter
%   defined in varpar; each field contains a scalar real double saying what
%   the value of that parameter will be on the upcoming trial.
%   tconst is a scalar struct that provides a set of trial constants,
%   as defined in the MET controller constants MCC.SDEF.ptb.init. Includes
%   a copy of MET controller constants, PsychToolbox window information,
%   the screen's physical characteristics, and a scalar struct containing
%   the value of each variable parameter that will be used by the stimulus.
%   Performs any necessary pre-processing of the stimulus and obtains any
%   special resources. Returns a stimulus descriptor, a scalar struct
%   containing any information necessary to generate a copy of the
%   stimulus. S must have at least one field called .hitregion that defines
%   areas of the screen that the subject can choose to select the stimulus.
%   Sold is the stimulus descriptor returned by close at the end of the
%   last trial in which this stimulus link was used ; it is initialised to
%   an empty matrix i.e. [] on first use.
% 
% 
% Stimulation function has the form:
%   
%   [ Snew , h ] = stim ( S , tconst , tvar )
%   
%   S is a stimulus descriptor as returned by init. tconst is the same set
%   of trial constants that are passed to init. tvar is a scalar struct
%   containing trial run-time information, including frame information and
%   any variable parameter changes. This performs any necessary drawing
%   operations using PsychToolbox functions ( but not screen flip! ) to
%   generate the visual stimulus. An updated stimulus descriptor Snew is
%   returned. h is non-zero if Snew contains a .hitregion that differs from
%   S.
% 
% 
% Stimulus destructor function has the form:
%   
%   S_old = close ( S , type )
% 
%   Releases any special resources requested by init. Returns a stimulus
%   descriptor S_old that is carried forward to the next trial that uses
%   this stimulus link. S_old is then provided to init and any relevant
%   information is used to modify the new stimulus descriptor. It is
%   advisable that S_old discards any large data structures that were in S,
%   if possible. If there is no need to carry over information then S_old
%   can be an empty matrix i.e. []. The second argument, type, is a single
%   char that gives context. What kind of closure do we want? If type is
%   't' then it is closure at the end of a trial ; the stimulus is free to
%   retain special resources in S_old, such as PTB procedural textures.
%   However, if type is 's' then it is a closure of the session and all
%   resources must be released permanently, or else a memory leak could
%   occur.
% 
% 
% Validation function has the form
%   
%   c = chksum ( S )
%   
%   Takes stimulus descriptor S and computes a checksum c for validating
%   stimulus reconstructions.
% 
% 
% mettestptbstim dependencies: PsychToolbox , metctrlconst , metscrnpar
% 
% 
% Written by Jackson Smith - Jan 2017 - DPAG , University of Oxford
% 
  
  
  %%% MET compile-time and controller constants %%%
  
  MCC = metctrlconst ;
  
  
  %%% Constants %%%
  
  % Get MET screen parameters
  p = metscrnpar ;
  
  % Determine screen ID to use , -1 means to take the maximum value
  % returned by Screen ( 'Screens' )
  SID = p.screenid ;
  
  if  SID  ==  -1
    SID = max( Screen (  'Screens'  ) ) ;
  end
  
  % Screen width and height in pixels
  [ WSIZEW , WSIZEH ] = Screen (  'WindowSize'  ,  SID  ) ;
  
  % OpenWindow rectangle , default [] means fill screen
  RECT = [] ;
  
    % If SID is the only screen then open a window in the lower-right
    % quadrant
    if  numel ( Screen(  'Screens'  ) )  ==  1
      
      RECT = zeros (  1  ,  4  ) ;
      RECT( RectLeft   ) = WSIZEW  /  2 ;
      RECT( RectTop    ) = WSIZEH  /  2 ;
      RECT( RectRight  ) = WSIZEW ;
      RECT( RectBottom ) = WSIZEH ;
      
    end % lower right quad
  
  % Background colour
  BAKCOL = [ p.rbak , p.gbak , p.bbak ] ;
  
  % Psych Toolbox verbosity level.  
  %  0 - No output at all.
  %  1 - Only severe error messages.
  %  2 - Errors and warnings.
  %  3 - Additional information, e.g., startup output when opening an
  %      onscreen window.
  %  4 - Very verbose output, mostly useful for debugging PTB itself.
  %  5 - Even more information and hints. Usually not what you want.
  PTBVERB = 3 ;
  
  % Screen to head parameters , keep values up to but not including the
  % first -1 encountered
  PTBS2H = { 'preference' , 'screentohead' , ...
    SID , p.newHeadId , p.newCrtcId , p.rank } ;
  
    % Find first -1 value
    i = find (  [ p.newHeadId , p.newCrtcId , p.rank ]  ==  -1  ,  ...
      1  ,  'first'  ) ;
    
    % Keep up to but not including it
    PTBS2H = PTBS2H ( 1 : 3 + i - 1 ) ;
    
  % Default values of input arguments
  DEFVAL = struct ( 'vpinit' , [] , 'rfdef' , MCC.DAT.SD.rfdef , ...
    'varpar' , [] , 'keymsk' , [] , 'stereo' , 0 , 'mirror' , 'n' , ...
    'S_old' , [] , 'debug' , false ) ;
  
  % Pausing, keyboard combination. To pause requires one modifier and one
  % other keys to be pressed together. Field .MOD is the list of potential
  % modifiers. Field .KEY is the list of keys. One key from .MOD and one
  % from .KEY and no others must be pressed to pause execution. Field .WAIT
  % is the duration in seconds that is used while polling the keyboard for
  % a second .MOD and .KEY press to continue execution.
  
    % Make sure that standard key names are used
    KbName ( 'UnifyKeyNames' ) ;
    
    % Modifier keys
    KBPAUS.MOD = [  KbName( 'LeftAlt' )  ,  KbName( 'RightAlt' )  ] ;
    
    % Other key
    KBPAUS.KEY = KbName ( 'p' ) ;
    
    % Polling duration of 100ms
    KBPAUS.WAIT = 0.15 ;
    
    
  %%% Check input %%%
  
  % name is always required
  if  ~ nargin
    
    error ( 'MET:mettestptbstim:name' , ...
      'mettestptbstim: name must be provided' )
    
  % name must provide the path to an existing m-file
  elseif  ~ isvector ( name )  ||  ~ ischar ( name )  ||  ...
      numel ( name )  <=  2  ||  any (  name ( end - 1 : end ) ~= '.m'  )
    
    error ( 'MET:mettestptbstim:name' , ...
      'mettestptbstim: name must be a string ending in ''.m''' )
    
  elseif  ~ exist (  name  ,  'file'  )
    
    error ( 'MET:mettestptbstim:name' , ...
      'mettestptbstim: name must be an m-file that exists' )
    
  % The function may not contain a Screen ( 'Flip' ) command
  elseif  has_flip ( name )
    
    error ( 'MET:mettestptbstim:name' , ...
      'mettestptbstim: contains Screen ( ''Flip'' , ... ) , %s' , name )
    
  % Check optional arguments. Additional checks on vpinit and varpar below.
  elseif  2 <= nargin  &&  ~ isempty( vpinit )  &&  check_vpinit( vpinit )
  elseif  3 <= nargin  &&  ~ isempty( rfdef  )  &&  check_rfdef ( MCC , ...
      rfdef )
  elseif  4 <= nargin  &&  ~ isempty( varpar )  &&  check_varpar( varpar )
  elseif  5 <= nargin  &&  ~ isempty( keymsk )  &&  check_keymsk( keymsk )
  elseif  6 <= nargin  &&  ~ isempty( stereo )  &&  check_stereo( stereo )
  elseif  7 <= nargin  &&  ~ isempty( mirror )  &&  check_mirror( mirror )
  elseif  8 <= nargin  &&  ~ isempty( S_old  )  &&  check_S_old ( S_old  )
  elseif  9 <= nargin  &&  ~ isempty( debug  )  &&  ...
      ( ~ isscalar ( debug )  ||  ~ islogical ( debug ) )
    
    error ( 'MET:mettestptbstim:debug' , ...
      'mettestptbstim: debug must be a scalar logical or []' )
    
  end % input checking
  
  
  %%% Set default values %%%
  
  if  nargin  <  2  ||  isempty( vpinit )  ,  vpinit = DEFVAL.vpinit ;  end
  if  nargin  <  3  ||  isempty( rfdef  )  ,  rfdef  = DEFVAL.rfdef  ;  end
  if  nargin  <  4  ||  isempty( varpar )  ,  varpar = DEFVAL.varpar ;  end
  if  nargin  <  5  ||  isempty( keymsk )  ,  keymsk = DEFVAL.keymsk ;  end
  if  nargin  <  6  ||  isempty( stereo )  ,  stereo = DEFVAL.stereo ;  end
  if  nargin  <  7  ||  isempty( mirror )  ,  mirror = DEFVAL.mirror ;  end
  if  nargin  <  8  ||  isempty( S_old  )  ,  S_old  = DEFVAL.S_old  ;  end
  if  nargin  <  9  ||  isempty( debug  )  ,  debug  = DEFVAL.debug  ;  end
  
  % Add pause keys to key mask
  keymsk = [  keymsk( : )  ;  KBPAUS.MOD( : )  ;  KBPAUS.KEY( : )  ] ;
  
  
  %%% Check stim def function %%%
  
  % Separate directory and function name without .m suffix
  [ fdir , fnam ] = fileparts (  name  ) ;
  fnam = strrep (  fnam  ,  '.m'  ,  ''  ) ;
  
  % Get function handle to stimulus definition function without changing
  % original directory
  d = pwd ;
  if  ~ isempty ( fdir )  ,  cd ( fdir )  ,  end
  stimdef = str2func (  fnam  ) ;
  cd ( d )
  
  % Does stimulus definition accept and return the correct number of
  % arguments?
  if  1  ~=  nargin  ( stimdef )
    
    error ( 'MET:mettestptbstim:nargin' , [ 'mettestptbstim: ' , ...
      'stimulus definition function %s must accept input argument ' , ...
      'rfdef' ] , fnam )
    
  elseif  6  ~=  nargout ( stimdef )
    
    error ( 'MET:mettestptbstim:nargout' , [ 'mettestptbstim: ' , ...
      'stimulus definition function %s must return 6 outputs' ] , fnam )
    
  end
  
  % Get MET ptb stimulus definition
  [ s.type , s.varpar , s.init , s.stim , s.close , s.chksum ] = ...
    stimdef (  rfdef  ) ;
  
  % Type must be string 'ptb'
  if  ~ isvector ( s.type )  ||  ~ ischar ( s.type )  ||  ...
      ~ strcmp ( s.type , 'ptb' )
    
    error ( 'MET:mettestptbstim:type' , ...
      'mettestptbstim: %s does not return ''ptb'' in type' , fnam )
    
  end
  
  % Check form of variable parameters
  check_svarpar ( fnam , s.varpar )
  
  % Check number of inputs and outputs
  check_snargs ( fnam , s )
  
  % Make sure that variable parameter initialisation set is valid. Throws
  % error if not.
  if  ~ isempty ( vpinit )  ,  check_vpinit_2 ( vpinit , s.varpar ) ;  end
  
  % Make sure that variable parameter change requests act on existing
  % parameters and provide new values within valid ranges
  if  ~ isempty ( varpar )  ,  check_varpar_2 ( varpar , s.varpar ) ;  end
  
  
  %%% Stimulus initialisation values %%%
  
  % Struct for trial constants
  tconst = MCC.SDEF.ptb.init ;
  tconst.pixperdeg = metpixperdeg (  p.width  ,  WSIZEW  ,  p.subdist  ) ;
  tconst.backgnd = BAKCOL ;
  tconst.stereo = stereo ;
  tconst.origin = [ 0 , 0 , 0 ] ;
  
  % Variable parameter set
  if  isempty ( vpinit )
    
    s.vpar_init = s.varpar(  :  ,  [ 1 , 3 ]  )' ;
    s.vpar_init = struct (  s.vpar_init { : }  ) ;
    
  else
    
    s.vpar_init = vpinit ;
    
  end
  
  
  %%% Open PsychToolbox window %%%
  
  % Stop mirroring keyboard presses in Matlab command line
  if  ~ debug  ,  ListenChar ( -1 ) ;  end
  
  % Make sure that screen to head mapping is correct
  if  -1  <  p.newHeadId  ,  Screen (  PTBS2H { : }  ) ;  end
  
  % Setup PTB with default values
  PsychDefaultSetup ( 2 ) ;
  
  % Black PTB startup screen
  Screen ( 'Preference' , 'VisualDebugLevel' , 1 ) ;
  
  % How much does PTB-3 automatically tell you?
  Screen ( 'Preference' , 'Verbosity' , PTBVERB ) ;
  
  % Prepare Psych Toolbox environment.
  PsychImaging ( 'PrepareConfiguration' ) ;
  PsychImaging ( 'AddTask' , 'General' , 'FloatingPoint32BitIfPossible' ) ;
  PsychImaging ( 'AddTask' , 'General' , 'NormalizedHighresColorRange' ) ;
  
  % Handle any mirroring
  if  any (  mirror  ==  'hb'  )
    PsychImaging ( 'AddTask' , 'AllViews' , 'FlipHorizontal' ) ;
  end
  
  if  any (  mirror  ==  'vb'  )
    PsychImaging ( 'AddTask' , 'AllViews' , 'FlipVertical'   ) ;
  end
  
  % Open PTB window.
  try
    
    [ tconst.winptr , ...
      tconst.winrec ] = PsychImaging (  'OpenWindow'  ,  ...
      SID  ,  BAKCOL  ,  RECT  ,  []  ,  []  ,  stereo  ) ;
  
  catch  E
    
    % Re-enable keyboard output to Matlab command line
    if  ~ debug  ,  ListenChar ( 0 ) ;  end
    
    % Clear PsychToolbox actions taken before doomed call to OpenWindow
    sca
    
    % Quit
    rethrow (  E  )
    
  end
  
  % Screen dimensions
  tconst.winwidth  = diff(  tconst.winrec( [ RectLeft , RectRight ] )  ) ;
  tconst.winheight = diff(  tconst.winrec( [ RectTop , RectBottom ] )  ) ;
  
  % Screen centre
  tconst.wincentx = mean(  tconst.winrec( [ RectLeft , RectRight ] )  ) ;
  tconst.wincenty = mean(  tconst.winrec( [ RectTop , RectBottom ] )  ) ;
  
  % The flip interval
  tconst.flipint = Screen ( 'GetFlipInterval' , tconst.winptr ) ;
  
  % Enable OpenGL alpha blending function
  Screen ( 'BlendFunction' , tconst.winptr , GL_ONE , GL_ZERO ) ;
  
  % Screen parameter 'touch' requires mouse cursor to be hidden on the PTB
  % window
  if  p.touch  <  2  ,  HideCursor ( tconst.winptr ) ;  end
  
  
  %%% Test the stimulus %%%
  
  % Allow time for release of keyboard following launch of mettestptbstim
  WaitSecs ( 0.1 ) ;
  
  % Empty errors
  E = [] ;  Z = [] ;
  
  
  % Get a MET ptb stimulus descriptor
  try
    
    s.S = s.init (  s.vpar_init  ,  tconst  ,  S_old  ) ;
    
  catch  E
    
    % Re-enable keyboard output to Matlab command line
    if  ~ debug  ,  ListenChar ( 0 ) ;  end
    
    % Close Psych Toolbox , error or not
    Screen ( 'CloseAll' )
    
    % Pass on the error
    rethrow ( E )
    
  end % stim descriptor
  
  
  % Stimulus descriptor must be a scalar struct with field .hitregion
  if  ~ isscalar ( s.S )  ||  ~ isstruct ( s.S )  ||  ...
      ~ isfield ( s.S , MCC.SDEF.ptb.hitregion.fieldname )
    
    % First attempt to release stimulus resources , but ignore errors
    try  s.close ( s.S , 's' ) ;  catch  ,  end
    
    % Re-enable keyboard output to Matlab command line
    if  ~ debug  ,  ListenChar ( 0 ) ;  end
    
    % Close Psych Toolbox , error or not
    Screen ( 'CloseAll' )
    
    % Report the problem
    error (  'MET:mettestptbstim:stimdesc'  ,  [ 'mettestptbstim: '  ,  ...
      'init function from %s must return a scalar struct with at '  ,  ...
      'least one field .%s' ]  ,  fnam  ,  ...
      MCC.SDEF.ptb.hitregion.fieldname  )
    
  end % stim descriptor form
  
  
  % Calculate a checksum
  try
    
    c = s.chksum ( s.S ) ;
    
  catch  E
    
    % First attempt to release stimulus resources , but ignore errors
    try  s.close ( s.S , 's' ) ;  catch  ,  end
    
    % Re-enable keyboard output to Matlab command line
    if  ~ debug  ,  ListenChar ( 0 ) ;  end
    
    % Close Psych Toolbox , error or not
    Screen ( 'CloseAll' )
    
    % Pass on the error
    rethrow ( E )
    
  end
  
  % Must return a scalar real double value
  if  ~ isscalar ( c )  ||  ~ isa ( c , 'double' )  ||  ~ isreal ( c )
    
    % First attempt to release stimulus resources , but ignore errors
    try  s.close ( s.S , 's' ) ;  catch  ,  end
    
    % Re-enable keyboard output to Matlab command line
    if  ~ debug  ,  ListenChar ( 0 ) ;  end
    
    % Close Psych Toolbox , error or not
    Screen ( 'CloseAll' )
    
    % Report the problem
    error (  'MET:mettestptbstim:chksum'  ,  [ 'mettestptbstim: '  ,  ...
      'chksum function from %s must return a scalar real double' ]  ,  ...
      fnam  )
    
  end
  
  
  % Test stimulus , but catch errors so that PTB can be cleared
  try
    
    % Draw stimulus
    s = runt ( s , tconst , fnam , varpar , keymsk , KBPAUS ) ;
    
  catch  E
  end % test stimulus
  
  
  % Attempt to free stimulus resources
  try
    
    s.S = s.close (  s.S , 's'  ) ;
    
  catch  Z
  end % close stimulus
  
  % Re-enable keyboard output to Matlab command line
  if  ~ debug  ,  ListenChar ( 0 ) ;  end
  
  % Close Psych Toolbox , error or not
  Screen ( 'CloseAll' )
  
  % Report errors
  if  ~ isempty ( E )  ,  rethrow ( E )  ,  end
  if  ~ isempty ( Z )  ,  rethrow ( Z )  ,  end
  
  
end % mettestptbstim


%%% Testing subroutine %%%

function  s = runt ( s , tconst , fnam , varpar , keymsk , KBPAUS )
  
  
  %%% Setup %%%
  
  % Half-flip interval , to set frame-swap deadlines
  hfi = tconst.flipint  /  2 ;
  
  % Some stereoscopic mode is in use , so loop both frame buffers ,
  % otherwise we always use the monocular flag value of -1
  if  tconst.stereo
    
    eyebuf = 0 : 1 ;
    
  else
    
    eyebuf = -1 ;
    
  end
  
  % Frame counter
  i = 0 ;
  
  % Struct for trial variables
  tvar = tconst.MCC.SDEF.ptb.stim ;
  tvar.skip = false ;
  
  % We are applying variable parameter changes during a trial , keep a
  % vector of change times handy , and 
  if  ~ isempty (  varpar  )
    
    vtim = cell2mat ( varpar(  :  ,  3  ) ) ;
    
  end
  
  % Pause time
  tpause = 0 ;
  
  
  %%% Cross-hairs %%%
  
  % Make a pair of lines at the location of the trial origin , make them
  % one half degree of visual field
  ch.xy = [ -0.25 , 0.25 ,  0.00 , 0.00 ;
             0.00 , 0.00 , -0.25 , 0.25 ]  ;
           
	% Place them at origin
  ch.xy( 1 , : ) = ch.xy( 1 , : )  +  tconst.origin ( 1 ) ;
  ch.xy( 2 , : ) = ch.xy( 2 , : )  +  tconst.origin ( 2 ) ;
  
  % Convert to pixels
  ch.xy = ch.xy  *  tconst.pixperdeg ;
  
  % Place relative to centre of screen
  ch.xy( 1 , : ) = ch.xy( 1 , : )  +  tconst.wincentx ;
  ch.xy( 2 , : ) = ch.xy( 2 , : )  +  tconst.wincenty ;
  
  % Disparity , in pixels , ready for a left-eye shift
  ch.disp = - tconst.origin ( 3 )  *  tconst.pixperdeg ;
  
  % Apply a right-eye shift
  ch.xy( 1 , : ) = ch.xy( 1 , : )  -  ch.disp ;
  
  
  %%% Test the stimulus %%%
  
  % Synchronising flip
  [ vbl , stimon ] = Screen ( 'Flip' , tconst.winptr ) ;
  
  % First vbl time measurement is now the point of reference. This is the
  % time that the 'trial' started.
  time_zero = vbl ;
  
  % Frame loop
  while  true
    
    
    %-- Keyboard --%
    
    % Check for keystroke
    [ ~ , ~ , key ] = KbCheck ;
    
    % Enough time has passed to allow another pause of execution
    if  KBPAUS.WAIT  <  vbl - tpause
    
      % Pause of execution , modifier keys
      m = key ( KBPAUS.MOD ) ;

      % One modifier pause key is down
      if  sum ( m )  ==  1

        % Other pause key
        pk = key ( KBPAUS.KEY ) ;

        % One other pause key is down , and only two keys are down
        if  sum ( pk )  ==  1  &&  sum ( key )  ==  2

          % Lower pause key flags
          key( [ KBPAUS.MOD , KBPAUS.KEY ] ) = false ;

          % Report that execution is paused
          fprintf ( 'mettestptbstim: pause execution\n' )

          % Wait for pause key combination
          while  ~ (  sum(  key  )  ==  2  &&  ...
              any( key(  KBPAUS.MOD  ) )  &&  any( key(  KBPAUS.KEY  ) )  )

            % Poll duration , return wakeup time
            tpause = WaitSecs (  KBPAUS.WAIT  ) ;

            % Check keyboard
            [ ~ , ~ , key ] = KbCheck ;

          end % poll pause key combo

          % Report that execution has resumed
          fprintf ( 'mettestptbstim: execution resumed\n' )

        end % pause key down

      end % pause , modifier down
    
    end % check for pause key combo
    
    % Unset masked keys
    key ( keymsk ) = false ;
    
    % Break loop if unmasked key was hit
    if  any (  key  )  ,  break  ,  end
    
    
    %-- Trial variables --%
    
    % Increment frame count
    i = i  +  1 ;
    tvar.frame = i ;
    
    % Expected stimulus onset time
    tvar.ftime = stimon  +  tconst.flipint  -  time_zero ;
    
    % If variable parameter changes are provided then look to see which
    % have met or passed their deadlines by the time that the next frame
    % appears
    if  ~ isempty (  varpar  )
      
      % Find change times that have been met
      j = vtim  <=  tvar.ftime ;
      
      if  any ( j )
        
        % Load them into task variables
        tvar.varpar = varpar ( j , 1 : 2 ) ;
        
        % Discard from set
        j = ~ j ;
        vtim = vtim ( j ) ;
        varpar = varpar (  j  ,  :  ) ;
        
      end
      
    end % variable parameter changes
    
    
    %-- Draw the stimulus --%
    
    % Eye frame buffer loop
    for  e = eyebuf
      
      
      % Assign buffer flag
      tvar.eyebuf = e ;
      
      % Set stereo drawing buffer
      if  -1  <  e
        Screen (  'SelectStereoDrawBuffer'  ,  tconst.winptr  ,  e  ) ;
      end
    
      % Draw MET ptb stimulus
      [ s.S , h ] = s.stim ( s.S , tconst , tvar ) ;
      
      % New stimulus descriptor must be a scalar struct with field
      % .hitregion
      if  ~ isscalar ( s.S )  ||  ~ isstruct ( s.S )  ||  ...
          ~ isfield ( s.S , tconst.MCC.SDEF.ptb.hitregion.fieldname )

        error (  'MET:mettestptbstim:stimdesc'  ,  ...
          [ 'mettestptbstim: stim function from %s must return a ' , ...
            'scalar struct with at least field .%s' ]  ,  ...
            fnam  ,  MCC.SDEF.ptb.hitregion.fieldname  )
          
      % Hit-region flag h must be scalar logical, numeric, or char
      elseif  ~ isscalar ( h )  ||  ...
          ~ ( islogical ( h )  ||  isnumeric ( h )  ||  ischar ( h ) )
        
        error (  'MET:mettestptbstim:hitregion'  ,  ...
          [ 'mettestptbstim: stim function from %s must return a ' , ...
            'scalar hit-region change flag h that is logical, ' , ...
            'numeric, or char' ]  ,  fnam  )

      end % stim descriptor form
      
      % Hit region has changed , report
      if  h
        
        % Report when hit region changed
        fprintf (  [ 'mettestptbstim: New hit region at ' , ...
          tconst.MCC.FMT.TIME , ' sec\n' ]  ,  tvar.ftime  )
        
        % And to what
        disp ( s.S.hitregion )
        
      end % hit region
      
      
      %-- Cross-hairs --%
    
      % Apply disparity shift
      ch.xy( 1 , : ) = ch.xy( 1 , : )  +  ch.disp ;

      % Reverse direction of shift for next image
      ch.disp = - ch.disp ;

      % Draw cross-hairs
      Screen (  'DrawLines'  ,  tconst.winptr  ,  ch.xy  ) ;
      
      
    end % eye frame buffers
    
    % Any variable parameter changes have been applied , clear change list
    % if not yet done
    if  ~ isempty (  tvar.varpar  )
      
      tvar.varpar = [] ;
      
    end % variable parameter changes
    
    
    %-- Flip screen --%
    
    % Tell PsychToolbox that there will be no more drawing to buffers.
    Screen (  'DrawingFinished'  ,  tconst.winptr  ) ;
    
    % New images to screen
    [ vbl , stimon , ~ , missed ] = ...
      Screen (  'Flip'  ,  tconst.winptr  ,  vbl + hfi  ) ;
    
    % Check for skipped frame
    tvar.skip = 0  <  missed ;
    
    
  end % frame loop
  
  
end % runt


%%% Input checking subroutines %%%

% Reads in the text file , removes comments , then looks for any occurrence
% of Screen ( 'Flip' ) , returns true if one is found , false otherwise
function  f = has_flip ( name )
  
  % Open file
  fid = fopen (  name  ,  'r'  ) ;
  
  if  fid  ==  -1
    
    error ( 'MET:mettestptbstim:fopen' , ...
      'mettestptbstim: cannot open for reading , %s' , name )
    
  end
  
  % Read all lines
  s = textscan (  fid  ,  '%s'  ,  'Delimiter'  ,  { '' }  ) ;
  
  % Close the file
  if  fclose (  fid  )  ==  -1
    
    error (  'MET:mettestptbstim:fclose'  ,  ...
      'mettestptbstim: failed to close %s\n  Got error: %s'  ,  ...
      ferror ( fid )  )
    
  end
  
  % No string returned
  if  isempty ( s )
    
    error ( 'MET:mettestptbstim:textscan' , ...
      'mettestptbstim: failed to read anything from %s' , name )
    
  % textscan returned a nested cell array
  elseif  iscell ( s )  &&  numel( s ) == 1  &&  iscell ( s { 1 } )
    
    s = s { 1 } ;
    
  % Guarantee cell array
  elseif  ischar ( s )
    
    s = { s } ;
    
  end
  
  % Remove comments and line continuation operators
  s = regexprep (  s  ,  { '%.*$' , '\.\.\.' }  ,  ''  ) ;
  i = ~ cellfun ( @( c )  isempty ( c ) , s ) ;
  s = s ( i ) ;
  
  % Append together into a single string
  s = strjoin ( s ) ;
  
  % Look for the offending Screen 'Flip' command
  f = regexp (  s , 'Screen *( *''[fF]lip' , 'once' ) ;
  
end % has_flip


% Returns logical false if vpinit is properly formed i.e. scalar struct
% with scalar double values that are neither inf 
function  l = check_vpinit ( v )
  
  % Scalar struct
  if  ~ isscalar ( v )  ||  ~ isstruct ( v )
    
    error ( 'MET:mettestptbstim:vpinit' , ...
      'mettestptbstim: vpinit must be [] or a scalar struct' )
    
  end
  
  % Get value of each field
  C = struct2cell ( v ) ;
  
  % All values must be scalar real doubles
  if  ~ all (  cellfun(  ...
      @( c )  isscalar( c )  &&  isa( c , 'double' )  &&  isreal( c )  ,...
      C  ) )
    
    error ( 'MET:mettestptbstim:vpinit' , [ 'mettestptbstim: ' , ...
      'vpinit all fields must contain scalar real doubles' ] )
    
  end
  
  % No duplicate parameter names allowed
  C = fieldnames ( v ) ;
  
  if  numel (  C  )  ~=  numel ( unique(  C  ) )
    
    error ( 'MET:mettestptbstim:vpinit' , [ 'mettestptbstim: ' , ...
      'vpinit has duplicate variable parameter names' ] )
    
  end
  
  % Success
  l = false ;
  
end % check_vpinit


% Returns logical false if rfdef is properly formed i.e. struct vector with
% the correct set of field names, each with a scalar real double value in
% the correct range.
function  l = check_rfdef ( MCC , rfdef )
  
  % Point to rfdef field name definition
  RFDEF = MCC.DAT.RFDEF ;
  
  % Check whether input is struct vector
  if  ~ isvector ( rfdef )  ||  ~ isstruct ( rfdef )
    
    error ( 'MET:mettestptbstim:rfdef' , [ 'mettestptbstim: ' , ...
      'rfdef must be a struct vector' ] )
    
  end % struct vector
  
  % Get list of field names
  F = fieldnames ( rfdef ) ;
  
  % Correct number of field names returned
  if  numel ( F )  ~=  size ( RFDEF , 1 )
    
    error ( 'MET:mettestptbstim:rfdef' , [ 'mettestptbstim: ' , ...
      'rfdef has incorrect number of fields' ] )
    
  end % field number
  
  % Check for invalid fieldnames
  i = ~ ismember (  F  ,  RFDEF ( : , 1 )  ) ;
  
  if  any ( i )
    
    error (  'MET:mettestptbstim:rfdef'  ,  [ 'mettestptbstim: ' , ...
      'rfdef has invalid fields: %s' ]  ,  strjoin( F( i ) , ' , ' )  )
    
  end % invalid fields
  
  % Check that each field contains scalar, real, double values
  C = struct2cell (  rfdef  ) ;
  
  i = ~ cellfun (  ...
    @( x )  isscalar( x )  &&  isreal( x )  &&  isa( x , 'double' )  , ...
    C( : )  ) ;
  
  if  any ( i )
    
    error ( 'MET:mettestptbstim:rfdef' , [ 'mettestptbstim: ' , ...
      'rfdef fields must only contain scalar, real, doubles' ] )
    
  end % scalar, real, doubles
  
  % Check that values are in range
  for  j = 1 : size ( RFDEF , 1 )
    
    % Field name
    f = RFDEF { j , 1 } ;
    
    % Get all values from this field
    v = [  rfdef.( f )  ] ;
    
    % Minimum and maximum value
    [ vmin , vmax ] = RFDEF { j , 3 : 4 } ;
    
    % Check range for this field
    if  any ( v < vmin  |  vmax < v )
      
      error (  'MET:mettestptbstim:rfdef'  ,  [ 'mettestptbstim: ' , ...
      'rfdef.%s must be in range [ %f , %f ]' ]  ,  f  ,  vmin  ,  vmax  )
      
    end
    
  end % check range
  
  % Success
  l = false ;
  
end % check_rfdef


% Returns logical true if vpinit does not have the same parameter set as
% in stimulus definition varpar or if any parameter is out of range.
function  l = check_vpinit_2 ( vpi , sdv )
  
  % Get list of parameters from initialisation struct
  F = fieldnames ( vpi ) ;
  
  % Check that all given parameters are in the stimulus definition
  i = find (  ~ ismember (  F  ,  sdv ( : , 1 )  )  ) ;
  
  if  i
    
    F = strjoin (  F( i )  ,  ' , '  ) ;
    
    error ( 'MET:mettestptbstim:vpinit' , [ 'mettestptbstim: ' , ...
      'vpinit parameters not in stimlulus definition: ' , F ] )
    
  end
  
  % Check that all variable parameters were given
  F = setdiff (  sdv ( : , 1 )  ,  F  ) ;
  
  if  ~ isempty ( F )
    
    F = strjoin (  F  ,  ' , '  ) ;
    
    error ( 'MET:mettestptbstim:vpinit' , [ 'mettestptbstim: ' , ...
      'vpinit missing parameters: ' , F ] )
    
  end
  
  % Check that all parameter values are in numerical range
  for  i = 1 : size ( sdv , 1 )
    
    % Parameter / field name
    F = sdv { i , 1 } ;
    
    % Integer set but non-integer parameter value
    if  sdv { i , 2 } == 'i'  &&  mod ( vpi.( F ) , 1 )
      
      error ( 'MET:mettestptbstim:vpinit' , [ 'mettestptbstim: ' , ...
      'vpinit parameter must be an integer , ' , F ] )
      
    % Parameter out of range
    elseif  vpi.( F ) < sdv { i , 4 }  ||  sdv { i , 5 } < vpi.( F )
      
      error ( 'MET:mettestptbstim:vpinit' , [ 'mettestptbstim: ' , ...
      'vpinit parameter %s out of range [ %f , %f ]' ] , ...
      F , sdv{ i , 4 } , sdv{ i , 5 }  )
    
    end
    
  end % num range
  
  % Success
  l = true ;
  
end % check_vpinit


% Makes sure that each variable parameter change names an existing
% parameter and provides a value within the stated numeric range
function  check_varpar_2 ( varpar , vpdef )
  
  % Find whether all parameters named in varpar are also listed in the
  % stimulus definition's parameter set
  [ i , j ] = ismember (  varpar( : , 1 )  ,  vpdef( : , 1 )  ) ;
  
  % Invalid parameter names were given
  if  ~ all ( i )
    
    % Inform user
    error (  'MET:mettestptbstim:varpar'  ,  [ 'mettestptbstim: ' , ...
      'varpar has invalid parameter names: %s' ]  ,  ...
      strjoin( varpar( ~ i , 1 ) , ' , ' )  )
    
  end
  
  % Check that each parameter change value is within range
  for  i = 1 : size ( varpar )
    
    % Fetch the parameter name and new value
    [ p , v ] = varpar { i , 1 : 2 } ;
    
    % Get the number set and range that the value must fall within
    [ s , vmin , vmax ] = vpdef {  j( i )  ,  [ 2 , 4 , 5 ]  } ;
    
    % Integer required but non-integer given
    if  s  ==  'i'  &&  mod ( v , 1 )
      
      error (  'MET:mettestptbstim:varpar'  ,  ...
        [ 'mettestptbstim: varpar attempts to assign non-integer ' , ...
        'to integer parameter ' , p ]  )
      
    end
    
    % Check range
    if  v  <  vmin  ||  vmax  <  v
      
      error (  'MET:mettestptbstim:varpar'  ,  [ 'mettestptbstim: ' , ...
      'varpar sets %s to out-of-range value' ]  ,  p  )
      
    end
    
  end % par changes
  
end % check_varpar_2


% Returns logical false if varpar is properly formed, throws an error
% otherwise. Does not validate parameter names or values.
function  l = check_varpar ( v )
  
  % varpar is a cell array
  if  ~ iscell ( v )
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: varpar must be [] or a cell array' )
    
  
  elseif  2  <  ndims ( v ) %#ok
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: varpar must have no more than 2 dimensions' )
    
  elseif  size ( v , 2 )  ~=  3
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: varpar must have 3 columns' )
    
  end
  
  % Check that all values in the first column are strings
  i = cellfun (  @( c )  isvector( c ) && ischar( c )  ,  v( : , 1 )  ) ;
  
  if  any ( ~ i )
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: varpar first column may only have strings' )
    
  end
  
  % Check second and third column are all scalar doubles without complex
  % component
  i = cellfun (  ...
    @( c )  isscalar( c ) && isa( c , 'double' ) && isreal( c )  ,  ...
    v( : , 2 : 3 )  ) ;
  
  if  any ( ~ i( : ) )
    
    error ( 'MET:mettestptbstim:varpar' , [ 'mettestptbstim: ' , ...
      'varpar columns 2 and 3 must be scalar real doubles' ] )
    
  end
  
  % All checks passed , say that there is no problem
  l = false ;
  
end % check_varpar


% Returns logical false if keymsk is properly formed, throws an error
% otherwise.
function  l = check_keymsk ( m )
  
  % The total number of keyboard mappings, the highest value that keymsk
  % can be
  kmax = numel( KbName( 'KeyNames' ) ) ;
  
  % keymsk must be integer vector of 1 or more
  if  ~ isnumeric ( m )  ||  any( mod( m( : ) , 1 ) )  ||  ...
      any( m( : ) < 1 )  ||  ~ isvector ( m )
    
    error ( 'MET:mettestptbstim:keymsk' , [ 'mettestptbstim: ' , ...
      'keymsk must be a vector of integers not less than 1' ] )
    
  % No value may exceed the number of keyboard mappings
  elseif  any (  kmax  <  m  )
    
    error ( 'MET:mettestptbstim:keymsk' , [ 'mettestptbstim: ' , ...
      'keymsk must not exceed %d' ] , kmax )
    
  end
  
  % Checks passed
  l = false ;
  
end % check_keymsk


% Returns logical false if stereo is properly formed, throws an error
% otherwise.
function  l = check_stereo ( s )
  
  % Must be a scalar integer
  if  ~ isscalar ( s )  ||  ~ isnumeric ( s )  ||  mod ( s , 1 )
    
    error ( 'MET:mettestptbstim:stereo' , ...
      'mettestptbstim: stereo must be a scalar integer' )
    
  % Cannot be less than 0 or more than 11
  elseif  s < 0  ||  11 < s
    
    error ( 'MET:mettestptbstim:stereo' , ...
      'mettestptbstim: stereo must be a value from 0 to 11' )
    
  end
  
  % Passed checks
  l = false ;
  
end % check_stereo


% Returns logical false if mirror is properly formed, throws an error
% otherwise.
function  l = check_mirror ( m )
  
  % Must be scalar char
  if  ~ isscalar ( m )  ||  ~ ischar ( m )
    
    error ( 'MET:mettestptbstim:mirror' , ...
      'mettestptbstim: mirror must be a single character' )
    
  % Not a valid character
  elseif  all ( m ~= 'nhvb' )
    
    error ( 'MET:mettestptbstim:mirror' , ...
      'mettestptbstim: mirror must be one of ''nhvb''' )
    
  end
  
  % Passed checks
  l = false ;
  
end % check_mirror


% Returns logical false if S_old is properly formed , throws an error
% otherwise
function  l = check_S_old ( S_old  )
  
  % Passed checks , won't return if there's an error , anyway
  l = false ;
  
  % Can be an empty matrix
  if  isempty ( S_old )  ,  return  ,  end
  
  % Otherwise , must be scalar struct
  if  ~ isscalar ( S_old )  ||  ~ isstruct ( S_old )
    
    error ( 'MET:mettestptbstim:S_old' , ...
      'mettestptbstim: mirror must be one of ''nhvb''' )
    
  end

end % check_S_old


% Check MET ptb stimulus variable parameter definition, throws error
function  check_svarpar ( fnam , v )
  
  % Must be a cell array
  if  ~ iscell ( v )
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: %s must return a cell array in varpar' , fnam )
    
  % May not be empty
  elseif  isempty ( v )
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: %s varpar may not be empty' , fnam )
    
  % Must have 2 dimensions
  elseif  ndims ( v )  ~=  2  %#ok
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: %s varpar must have 2 dimensions' , fnam )
    
  % Requires five columns
  elseif  size ( v , 2 )  ~=  5
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: %s varpar must have 5 columns' , fnam )
    
  end
  
  % First column must have strings
  i = cellfun ( @( c )  isvector( c ) && ischar( c )  ,  v( : , 1 )  ) ;
  
  if  any ( ~ i )
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: %s varpar column 1 must be non-empty strings' , ...
      fnam )
    
  end
  
  % Second column must be single characters , either 'i' or 'f'
  i = cellfun (  ...
    @( c )  isscalar( c )  &&  ischar( c )  &&  any( c == 'if' )  ,  ...
    v( : , 2 )  ) ;
  
  if  any ( ~ i )
    
    error ( 'MET:mettestptbstim:varpar' , [ 'mettestptbstim: ' , ...
      '%s varpar column 2 must be either ''i'' or ''f''' ] , ...
      fnam )
    
  end
  
  % Remaining columns must contain scalar real doubles
  i = cellfun (  ...
    @( c )  isscalar( c )  &&  isa( c , 'double' )  &&  isreal( c )  ,  ...
    v( : , 3 : end )  ) ;
  
  if  any ( ~ i( : ) )
    
    error ( 'MET:mettestptbstim:varpar' , ...
      'mettestptbstim: %s varpar column 1 must be non-empty strings' , ...
      fnam )
    
  end
  
  % Extract format characters, default values, minimum and maximum values
  fmt = cell2mat (  v ( : , 2 )  ) ;
  def = cell2mat (  v ( : , 3 )  ) ;
  vmn = cell2mat (  v ( : , 4 )  ) ;
  vmx = cell2mat (  v ( : , 5 )  ) ;
  
  % Max is not less than min
  i = find (  vmx < vmn  ,  1  ,  'first'  ) ;
  
  if  i
    
    error ( 'MET:mettestptbstim:varpar' , [ 'mettestptbstim: ' , ...
      '%s varpar %s row %d , maximum value less than minimum' ] , ...
      fnam , v{ i , 1 } , i )
    
  end
  
  % Default lies in range
  i = find (  def < vmn  |  vmx < def  ,  1  ,  'first'  ) ;
  
  if  i
    
    error ( 'MET:mettestptbstim:varpar' , [ 'mettestptbstim: ' , ...
      '%s varpar %s row %d , default falls out of range' ] , ...
      fnam , v{ i , 1 } , i )
    
  end
  
  % Integers have no fractional component
  i = find (  fmt == 'i'  &  ...
              any(  mod( [ def , vmn , vmx ] , 1 )  ,  2  )  ,  ...
              1  ,  'first'  ) ;
	
	if  i
    
    error ( 'MET:mettestptbstim:varpar' , [ 'mettestptbstim: ' , ...
      '%s varpar %s row %d , integer values required' ] , ...
      fnam , v{ i , 1 } , i )
    
  end
  
end % check_svarpar


% Makes sure that stimulus definition functions accept and return the
% expected number of arguments
function  check_snargs ( fnam , s )
  
  % Function names
  F = { 'init' , 'stim' , 'close' , 'chksum' } ;
  
  % Number of input arguments
  Nin  = [ 3 , 3 , 2 , 1 ] ;
  
  % Number of output arguments
  Nout = [ 1 , 2 , 1 , 1 ] ;
  
  % Check each stimulus function
  for  i = 1 : numel ( F )
    
    % Function handle
    f = s.( F { i } ) ;
    
    % Must have correct number of input and output arguments
    if  nargin ( f )  ~=  Nin ( i )  ||  nargout ( f )  ~=  Nout ( i )
      
      error (  'MET:mettestptbstim:snargs'  ,  [ 'mettestptbstim: ' , ...
      '%s''s %s function must take %d input argument and give ' , ...
      '%d output arguments' ]  ,  ...
      fnam  ,  F { i }  ,  Nin ( i )  ,  Nout ( i )  )
      
    end
    
  end % stimulus functions
  
end % check_snargs

