
function  metbasic (  noquit  )
% 
% metbasic
% 
% Matlab Electrophysiology Toolbox. Runs a simple command-line based
% program that uses MET PTB stimulus definitions to run a simple
% experiment. Run by executing the metbasic command in a system command
% terminal. Session output goes to the current directory whence metbasic is
% run. The user sets the stimulus and its parameters, then chooses which of
% those parameters to vary between trials and the list of values to choose
% from. Values are randomly selected without replacement per repetition of
% trials. The length of a trial in seconds is set. During a trial, the
% stimulus will use a fixed set of parameter values. If more than one
% stimulus is selected then no variable parameter is varied between trials;
% set the parameters of the stimuli. A session runs until all trials are
% presented. Session output files include a .txt log file and a .mat file
% containing the trial id number, the start time as obtained by GetSecs,
% the variable parameter value (if applicable), and the state of the random
% number generator (.mat) file. The random number generator is either re-
% shuffled prior to initialising the stimulus on each trial, or it is re-
% set to Matlab's default seed. If a USB-DAQ device can be found using
% PsychToolbox functions, then it will be used to issue a TTL pulse at the
% start of each trial ; connect output to port A, pin 21 on an MCC
% USB-1208FS ; if more than one device is connected then no TTL output
% provided. A photodiode square can be presented and a sequence of pulses
% can be issued before the stimulus appears ; this always alternates
% between high and low shades, starting first with the high shade. Remember
% to set metscrnpar.csv correctly.
% 
% Parameter file met/m/metbasic.csv holds settings for photodiode square
% and TTL output. First line must be: 'param,value' followed by name/value
% pairs. In particular, we need:
%   
%    psq_halig - 'l' or 'r' for left or right justified to screen edge of
%      photodiode square
%    psq_valig - 'b' or 't' for bottom or top justification
%    psq_npulse - Number of pulses ( 0 or more ) at start of trial before
%      stimulus presentation.
%    psq_width - Width of photodiode square in millimeters
%    psq_high - Normalised greyscale value for high shade of photodiode
%      square
%    psq_low - Normalised greyscale value for low shade
%    ttl_low - TTL digital low value ( 0 to 255 )
%    ttl_high - TTL digital high value
%    ttl_mindur - Minimum duration of TTL high pulse in seconds
%    inter_trial - Inter-trial interval in seconds , to allow adaptation to
%      dissipate
%   
%   Example:
%   
%     param,value
%     psq_halig,l
%     psq_valig,b
%     psq_npulse,5
%     psq_width,40
%     psq_high,1
%     psq_low,0.25
%     ttl_low,0
%     ttl_high,1
%     ttl_mindur,0.005
%     inter_trial,0.5
% 
% Written by Jackson Smith - July 2018 - DPAG , University of Oxford
% 
  

  %%% Optional input %%%
  
  narginchk (  0  ,  1  )
  
  if  ~ nargin
    
    noquit = false ;
    
  elseif  ~ isscalar (  noquit  )  ||  ~ islogical (  noquit  )
    
    fprintf (  'metbasic: noquit must be scalar logical'  )
    exit
    
  end
  
  
  %%% CONSTANTS %%%
  
  % MET ptb stimulus definitions to remove from user option list
  HIDESTIM = {  'rfmapbar'  ,  'rfmaprdk'  ,  'rfmaptool'  } ;
  
  % Mapping stimuli
  MAPSTIM = {  'rfmapbar'  ,  'rfmaprdk'  } ;
  
  % Set of main menu options
  MAINMENU = { 'Set session number' , ...
               'Set trial duration' , ...
               'Set rand num seeding' , ...
               'Add stimulus' , ...
               'Remove stimulus' , ...
               'View stimulus help' , ...
               'View stimuli' , ...
               'Set variable' , ...
               'Set variable values' , ...
               'Set var value shuffling' , ...
               'Set no. of repetitions' , ...
               'RF mapping' , ...
               'Run session' , ...
               'Reset PsychToolbox' , ...
               'Quit' } ;
             
	% metbasic.csv required entries
  METBASCSV = { 'psq_halig' , 'psq_valig' , 'psq_npulse' , 'psq_width' ,...
    'psq_high' , 'psq_low' , 'ttl_low' , 'ttl_high' , 'ttl_mindur' , ...
    'inter_trial' } ;
  
  
  %%% DAQ device id %%%
  
  % E is a struct of metbasic environment variables
  try
    
    %  the first is the DAQ device index for TTL output
    E.DAQ = daq_search ;
    
    % DAQ found , set it up for digital output
    if  ~ isempty (  E.DAQ  )
      
      % Configure for output
      DaqDConfigPort (  E.DAQ  ,  0  ,  0  ) ;
      
      % Lower pins
      DaqDOut (  E.DAQ  ,  0  ,  0  ) ;
      
    end % daq setup
    
  % ERROR
  catch
    
    fprintf (  [ 'Error accessing DAQ devices\n' , ...
      'Try closing other Matlab sessions and re-run.' ]  )
    exit
    
  end % get DAQ device
  
  
  %%% Cleanup Object %%%
  
  % Current directory
  E.pwd = pwd ;
  
  % Needs to know which daq device to set to low state
  cleanupObj = ...
    onCleanup (  @( ) cleanup_function( E.DAQ , E.pwd , noquit )  ) ;
  
  
  %%% Environment setup %%%
  
  % MET controller constants
  E.MCC = metctrlconst ;
  
  % Get MET screen parameters
  E.p = metscrnpar ;
  
  % metbasic photodiode square and TTL output parameters
  E.b = metreadcsv (  strrep( which( 'metbasic' ) , '.m' , '.csv' )  ,  ...
    METBASCSV  ,  METBASCSV( 3 : end )  ) ;
  
    % Check parameter values
    checkpars (  E.b  )
  
  % Determine screen ID to use , -1 means to take the maximum value
  % returned by Screen ( 'Screens' )
  E.SID = E.p.screenid ;
  
  if  E.SID  ==  -1
    E.SID = max( Screen (  'Screens'  ) ) ;
  end
  
  % Screen width and height in pixels
  [ E.WSIZEW , E.WSIZEH ] = Screen (  'WindowSize'  ,  E.SID  ) ;
  
  % Photodiode square width in pixels
  E.b.psq_width = E.WSIZEW  /  E.p.width  *  E.b.psq_width ;
  
  % Photodiode rectangle
  E.psqrec = zeros (  1  ,  4  ) ;
  
    % Horizontal justification
    switch  E.b.psq_halig
      case  'l'
        E.psqrec( [ RectLeft , RectRight ] ) = [ 0 , E.b.psq_width ] ;
      case  'r'
        E.psqrec( [ RectLeft , RectRight ] ) = ...
          [ -E.b.psq_width , 0 ]  +  E.WSIZEW ;
    end
    
    % Vertical justification
    switch  E.b.psq_valig
      case  't'
        E.psqrec( [ RectTop , RectBottom ] ) = [ 0 , E.b.psq_width ] ;
      case  'b'
        E.psqrec( [ RectTop , RectBottom ] ) = ...
          [ -E.b.psq_width , 0 ]  +  E.WSIZEH ;
    end
    
  % Screen background colour
  E.BAKCOL = [ E.p.rbak , E.p.gbak , E.p.bbak ] ;
  
  % Screen to head parameters , keep values up to but not including the
  % first -1 encountered
  E.PTBS2H = { 'preference' , 'screentohead' , ...
    E.SID , E.p.newHeadId , E.p.newCrtcId , E.p.rank } ;
  
    % Find first -1 value
    i = find (  [ E.p.newHeadId , E.p.newCrtcId , E.p.rank ]  ==  -1  , ...
      1  ,  'first'  ) ;
    
    % Keep up to but not including it
    E.PTBS2H = E.PTBS2H ( 1 : 3 + i - 1 ) ;
    
  % Make sure that standard key names are used so that we can get the value
  % for the 'q' key
  KbName ( 'UnifyKeyNames' ) ;
  E.qkey = KbName (  'q'  ) ;
  E.tabkey = KbName (  'tab'  ) ;

  % Struct for trial constants
  E.tconst = E.MCC.SDEF.ptb.init ;
  E.tconst.pixperdeg = ...
    metpixperdeg (  E.p.width  ,  E.WSIZEW  ,  E.p.subdist  ) ;
  E.tconst.backgnd = [ E.p.rbak , E.p.gbak , E.p.bbak ] ;
  E.tconst.stereo = E.p.stereo ;
  E.tconst.origin = [ 0 , 0 , 0 ] ;
  
  % MET controller constants
  E.MCC = metctrlconst ;
  
  % Stimuli to hide from user list
  E.HIDESTIM = HIDESTIM ;
  
  % Mapping stimuli
  E.MAPSTIM = MAPSTIM ;
  
  % Stimulus directory
  E.stimdir = fileparts (  E.MCC.STMRES  ) ;
  
    % Go to it
    cd (  E.stimdir  )
  
  % Look for MET ptb stimulus definition functions
  E.stim = dir (  '*.m'  ) ;
  
    % NO STIMULI FOUND!
    if  isempty (  E.stim  )
      
      error (  'metbasic: no stimuli found in %s'  ,  E.stim  )
      
    end % no stim
    
    % Get stim names , rather than m-file names
    E.stim = strrep (  { E.stim.name }  ,  '.m'  ,  ''  ) ;
    
    % Convert to function handles
    E.fstim = cellfun (  @str2func  ,  E.stim  ,  ...
      'UniformOutput'  ,  false  ) ;
    
    % Find stimulus definition types
    i = cellfun (  @( f ) f( [] )  ,  E.fstim  ,  ...
      'UniformOutput'  ,  false  ) ;
    
    % Find non-ptb type definitions
    i = ~ strcmp (  i  ,  'ptb'  ) ;
    
    % And get rid of them
    E.stim( i ) = [] ;  E.fstim( i ) = [] ;
    
	% Main menu options
  E.MAINMENU = MAINMENU ;
    
	% Initialise session struct
  s = defsesspar ;
  
  
  %%% PTB window %%%
  
  % Reset flag
  rstflg = 1 ;
  
  % Reset loop , the ptb window can be opened again in an attempt to clear
  % bad skipped frame problems
  while  rstflg
    
    
    %-- PsychToolbox environment --%
    
    % Make sure that screen to head mapping is correct
    if  -1  <  E.p.newHeadId  ,  Screen (  E.PTBS2H { : }  ) ;  end
    
    % Make sure that standard key names are used
    KbName ( 'UnifyKeyNames' ) ;
    
    % Remove some of the initial diagnostic verbosity from PsychToolbox
    PsychTweak (  'ScreenVerbosity'  ,  2  ) ;
    
    % Setup PTB with default values
    PsychDefaultSetup (  2  ) ;
    
    % Black PTB startup screen
    Screen (  'Preference'  ,  'VisualDebugLevel'  ,  1  ) ;
    
    % How much does PTB-3 automatically tell you?
    Screen (  'Preference'  ,  'Verbosity'  ,  3  ) ;
    
    % Prepare Psych Toolbox environment.
    PsychImaging ( 'PrepareConfiguration' ) ;
    PsychImaging ( 'AddTask' , 'General' , ...
      'FloatingPoint32BitIfPossible' ) ;
    PsychImaging ( 'AddTask' , 'General' , ...
      'NormalizedHighresColorRange' ) ;
    
    % Handle any mirroring
    if  E.p.hmirror
      PsychImaging ( 'AddTask' , 'AllViews' , 'FlipHorizontal' ) ;
    end

    if  E.p.vmirror
      PsychImaging ( 'AddTask' , 'AllViews' , 'FlipVertical'   ) ;
    end
    
    % Open new psych toolbox window
    [ E.tconst.winptr , ...
      E.tconst.winrec ] = PsychImaging (  'OpenWindow'  ,  ...
      E.SID  ,  E.BAKCOL  ,  []  ,  []  ,  []  ,  E.p.stereo  ) ;
    
    % Screen dimensions
    E.tconst.winwidth  = ...
      diff (  E.tconst.winrec( [ RectLeft , RectRight ] )  ) ;
    E.tconst.winheight = ...
      diff (  E.tconst.winrec( [ RectTop , RectBottom ] )  ) ;

    % Screen centre
    E.tconst.wincentx = ...
      mean (  E.tconst.winrec( [ RectLeft , RectRight ] )  ) ;
    E.tconst.wincenty = ...
      mean (  E.tconst.winrec( [ RectTop , RectBottom ] )  ) ;

    % The flip interval
    E.tconst.flipint = Screen ( 'GetFlipInterval' , E.tconst.winptr ) ;
    
    % Screen parameter 'touch' requires mouse cursor to be hidden on the
    % PTB window
    if  E.p.touch  <  2  ,  HideCursor ( E.tconst.winptr ) ;  end
    
    % Set real time scheduling priority
    if  E.p.priority
    
      % Set maximum priority for this window
      Priority ( MaxPriority(  E.tconst.winptr  ) ) ;

    end % set priority
    
    
    %-- Run stimulus sessions --%
    
    [ rstflg , s ] = run (  E  ,  s  ) ;
    
    % Clear psych toolbox
    sca
    
    
  end % reset ptb win
  
  
end % metbasic


%%% Sub-routines %%%

% Uses PTB functions to look for USB-DAQ device for TTL output at the start
% of each trial. If more than one is found then ask which to use.
function  daq = daq_search
  
  % Look for DAQ devices
  daq = DaqDeviceIndex ;
  
  % None returned , end now
  if  isempty (  daq  )  ,  return  ,  end
  
  % Multiple devices found , throw warning and return empty
  if  ~ isscalar (  daq  )
    
    % Tell user
    warning (  [ 'metbasic: multiple USB-DAQ devices found , ' , ...
      'ignoring devices - NO TTL output' ]  )
    
    % Ignore devices
    daq = [] ;
    
  end % error
  
end % daq_search


% Cleanup object callback. When the cleanupObj variable is cleared then
% this function will run. Makes sure that the digital output ports are low
% and clear PsychToolbox. Exits Matlab.
function  cleanup_function (  daq  ,  dname  ,  noquit  )
  
  % Go back to original directory
  try
    cd (  dname  ) ;
  catch
  end

  % DAQ device used
  if  ~ isempty (  daq  )
    
    % Lower digital output pins
    try
      DaqDOut (  daq  ,  0  ,  0  ) ;
    catch
    end
    
  end % daq used
  
  % Explicity lower PTB realtime priority
  try
    Priority (  0  ) ;
  catch
  end
  
  % Clear psych toolbox
  try
    sca ;
  catch
  end
  
  % Exit Matlab
  if  ~ noquit  ,  exit  ,  end
  
end % cleanup_function


% Check that metbasic.csv parameters are legal
function  checkpars (  p  )
  
  % Justification characters
  if      ~ any ( strcmp(  p.psq_halig  ,  { 'l' , 'r' }  ) )
    
    error (  'metbasic.csv: psq_halig must be ''l'' or ''r'''  )
    
  elseif  ~ any ( strcmp(  p.psq_valig  ,  { 'b' , 't' }  ) )
    
    error (  'metbasic.csv: psq_valig must be ''b'' or ''t'''  )
    
  end
  
  % General numeric properties
  for  C = { 'psq_npulse' , 'psq_width' ,  'psq_high' , 'psq_low' , ...
      'ttl_low' , 'ttl_high' , 'ttl_mindur' , 'inter_trial' }
    
    % Get value
    x = p.( C{ 1 } ) ;
    
    % Check
    if  ~ isscalar (  x  )  ||  ~ isfinite (  x  )  ||  x < 0
      
      error (  [ 'metbasic.csv: param %s must be a scalar finite ' , ...
        'number of 0 or greater' ]  ,  C{ 1 }  )
      
    end % general errors
    
  end % general properties
  
  % Bounded to 1
  for  C = { 'psq_high' , 'psq_low' , 'ttl_low' , 'ttl_high' }
    
    % Get value
    x = p.( C{ 1 } ) ;
    
    % Check
    if  x  >  1
      
      error (  'metbasic.csv: param %s must be no greater than 1'  ,  ...
        C{ 1 }  )
      
    end
    
  end % bound to 1
  
  % Integer
  if  mod (  p.psq_npulse  ,  1  )
    
    error (  'metbasic.csv: psq_npulse must be an integer value'  )
      
  end
  
end % checkpars


% Default session parameters
function  s = defsesspar
  
  % Subject id
  s.sub = '' ;
  
  % Session number
  s.sessid = 1 ;
  
  % Trial duration in seconds
  s.tsecs = 2 ;
  
  % Random number generator , 'd'efault or 's'huffle
  s.rng = 's' ;
  
  % Stimuli
  s.stim.name  = {} ;
  s.stim.vpdef = {} ;
  s.stim.vpval = {} ;
  s.stim.init  = {} ;
  s.stim.stim  = {} ;
  s.stim.close = {} ;
  
  % Task variable name and definition record, the value set, and
  % repetitions of value set
  s.var.nam = '' ;
  s.var.def = [] ;
  s.var.val = [] ;
  s.var.shuffle = 'on' ;
  s.var.rep =  1 ;
    
	% Get subject id
  while  isempty (  s.sub  )
    
    % Get subject id
    s.sub = input (  'Please enter subject id: '  ,  's'  ) ;
    
    % Report to user
    fprintf (  'Subject id is %s (%d char)\n'  ,  ...
      s.sub  ,  numel( s.sub )  )
    
    % Verify
    if  ~ verify (  'Is this right?'  )  ,  s.sub = '' ;  end
    
  end % get subject id
  
end % default sess par


% List menu of items and get user's answer
function  u = getinput (  S  ,  opt  ,  msg  )
  
  % Return error value of 0 by default
  u = 0 ;
  
  % Size of set
  n = numel (  S  ) ;
  
  % Nothing in set
  if  ~ n  ,  return  ,  end
  
  % Is there an optional item?
  if  ~ isempty (  opt  )
    
    % Count it and add to the item set
    n = n + 1 ;
    S = [  S  ,  { opt }  ] ;
    
  end % optional item
  
  % Enumerate items
  I = 1 : n ;
  
  % Build list of options with selection numbers
  C = [  num2cell( I )  ;  S  ] ;
  
  % Present list
  if  ~ isempty (  msg  )  ,  fprintf (  '%s\n'  ,  msg  )  ,  end
  fprintf (  '%2d ) %s\n'  ,  C{ : }  )

  % User input
  u = str2double ( input(  ': '  ,  's'  ) ) ;

  % Find selection
  i = find (  I  ==  u  ) ;

  % Nothing selected
  if  ~ any (  i  )
    fprintf (  'Unrecognised answer\n'  )
    u = 0 ;
  end
  
end % getinput


% Set number of struct s field f with domain 'i'nteger or 'f'loating point.
% Minimum allowable value of mn and maximum value of mx , both inclusive.
% If finite is non-zero then Inf values are not allowed.
function  s = setnum (  s  ,  f  ,  d  ,  mn  ,  mx  ,  finite  )

  % Get user input
  u = input (  'Please enter new value: '  ,  's'  ) ;
  
  % Convert to numeric
  u = str2double (  u  ) ;
  
  % Error string
  e = '' ;
  
  % Nonsense
  if  isnan (  u  )
    
    e = sprintf (  'Unrecognised numeric input\n'  ) ;
    
  % Don't allow Inf values
  elseif  finite  &&  isinf (  u  )
    
    e = sprintf (  'Finite value required\n'  ) ;
  
  % Incorrect domain
  elseif  d  ==  'i'  &&  mod (  u   ,  1  )
    
    e = sprintf (  'Integer value expected\n'  ) ;
  
  % Below minimum
  elseif  u  <  mn
    
    e = sprintf (  'Below minimum allowable value of %f\n'  ,  mn  ) ;
  
  % Above maximum
  elseif  u  >  mx
    
    e = sprintf (  'Above maximum allowable value of %f\n'  ,  mx  ) ;
    
  end % error check
  
  % There was a problem , say so and quit before change applied
  if  ~ isempty (  e  )
    fprintf (  e  )
    return
  end
  
  % Value is fine , assign this to struct
  s.( f ) = u ;
  
  % Report
  fprintf (  'New value of %f assigned\n'  ,  u  )
  
end % setnum


% Verify user input with yes or no question , returns true for yes and
% false for no. Loops until recognised input provided
function  v = verify (  msg  )
  
  % Empty until valid value given
  v = [] ;
  
  % Input
  while  isempty (  v  )
    
    % Query string
    str = sprintf (  '%s\n(y)es or (n)o: '  ,  msg  ) ;    
    
    
    % Evaluate answer
    switch  input (  str  ,  's'  )
      
      % Yes
      case  { 'Y' , 'y' }  ,  v = true  ;
        
      % No
      case  { 'N' , 'n' }  ,  v = false ;
        
      % Invalid answer
      otherwise  ,  fprintf (  'Unrecognised answer\n'  )
        
    end % answer
    
  end % input
  
end % verify


% Run sessions function
function  [ rstflg , s ] = run (  E  ,  s  )
  
  % Default ptb reset flag is low
  rstflg = 0 ;
  
  % Default user input
  u = '' ;
  
  % Main menu loop
  while  ~ strcmp (  u  ,  'Quit'  )
    
    % Present session info
    fprintf (  [ '\nSubject %s - Session %d\n' , ...
                   'Trial dur: %0.6f secs\n' , ...
                   'Rand num gen seed: %s\n' , ...
                   'Stimuli: %s\n' , ...
                   'Variable: %s\n' , ...
                   'Var value: %s\n' , ...
                   'Var shuffle: %s\n' , ...
                   'Repetitions: %d\n\n' ]  ,  ...
      s.sub  ,  s.sessid  ,  s.tsecs  ,  s.rng  ,  ...
        strjoin( s.stim.name , ', ' )  ,  s.var.nam  ,  ...
          strjoin(  arrayfun( @num2str , s.var.val , ...
            'UniformOutput' , false )  ,  ','  )  ,  s.var.shuffle  ,  ...
              s.var.rep  )
    
    % Make sure that keyboard is released
    KbReleaseWait ;
            
    % Present main menu and get user response
    u = getinput (  E.MAINMENU  ,  ''  ,  ''  ) ;
    
    % Nothing selected
    if  ~ u  ,  continue  ,  end
    
    % Get selection string
    u = E.MAINMENU{ u } ;
    
    % Respond to user input
    switch  u
      
      case  'Set session number'
        s = setnum (  s  ,  'sessid'  ,  'i'  ,  1  ,  Inf  ,  true  ) ;
        
      case  'Set trial duration'
        s = setnum (  s ,  'tsecs' ,  'f' ,  E.tconst.flipint ,  Inf , ...
          true  ) ;
        
      case  'Set rand num seeding'
        
        u = getinput (  { 'Default seed always used' , ...
          'Shuffle seed on each trial' }  ,  ''  ,  ''  ) ;
        
        if      u  ==  1  ,  s.rng = 'd' ;
        elseif  u  ==  2  ,  s.rng = 's' ;
        end
        
      case       'Add stimulus'  ,  s = setstim (  s  ,  E  ,   'add'  ) ;
        
      case    'Remove stimulus'  ,  s = setstim (  s  ,  E  ,   'rem'  ) ;
        
      case  'View stimulus help' ,      setstim (  s  ,  E  ,  'help'  ) ;
        
      case  'View stimuli'  ,  s = viewstim (  s  ) ;
        
      case  'Set variable'
        
        % Refuse if there is not one stimulus
        if  1  ~=  numel (  s.stim.name  )
          fprintf (  'One stimulus required, var par ignored\n'  )
          continue
        end
        
        % Present list of variable parameters
        u = getinput (  s.stim.vpdef{ 1 }( : , 1 )'  ,  ''  ,  ...
          sprintf( 'Stim 1 %s parameters:' , s.stim.name{ 1 } )  ) ;
        
        % Nothing selected
        if  ~ u  ,  continue  ,  end
        
        % Store name
        s.var.nam = s.stim.vpdef{ 1 }{ u , 1 } ;
        
        % Store definition record
        s.var.def = s.stim.vpdef{ 1 }( u , : ) ;
        
      case  'Set variable values'
        
        % Refuse if there is not one stimulus
        if  1  ~=  numel (  s.stim.name  )
          fprintf (  'One stimulus required, var par ignored\n'  )
          continue
        elseif  isempty (  s.var.nam  )
          fprintf (  'No variable param selected\n'  )
          continue
        end
        
        % Instructions
        fprintf (  'Please enter comma-separated list of values\n'  )
        u = input (  ': '  ,  's'  ) ;
        
        % Remove all white space
        u(  isspace( u )  ) = [] ;
        
        % Nothing returned
        if  isempty (  u  )  ,  return  ,  end
        
        % Parse into number strings , then to double numeric values
        u = str2double ( strsplit(  u  ,  ','  ) ) ;
        
        % Any NaN means invalid input
        if  any ( isnan(  u  ) )
          
          fprintf (  'Unrecognised answer\n'  )
          
        % Values are less than minimum
        elseif  any (  u  <  s.var.def{ 4 }  )
          
          fprintf (  'Value below minimum\n'  )
          
        % Values are greater than maximum
        elseif  any (  u  >  s.var.def{ 5 }  )
          
          fprintf (  'Value above maximum\n'  )
          
        % Wrong numeric domain
        elseif  s.var.def{ 2 } == 'i'  &&  any ( mod(  u  ,  1  ) )
          
          fprintf (  'Integer values expected\n'  )
          
        % Values are fine , assign them
        else
          
          s.var.val = u ;
          
        end % error check
        
      case  'Set var value shuffling'
        
        u = getinput (  { 'Shuffle values' , ...
          'Present as given' }  ,  ''  ,  'Variable value order'  ) ;
        
        if  ~ u  ,  continue  ,  end
        
        if  u  ==  1
          s.var.shuffle = 'on' ;
        elseif  u  ==  2
          s.var.shuffle = 'off' ;
        end
        
      case  'Set no. of repetitions'
        s.var = setnum (  s.var ,  'rep' ,  'i' ,  1 ,  Inf ,  true  ) ;
        
      case  'RF mapping'  ,  rfmap (  E  )
        
      case  'Run session'
        
        runsession (  E  ,  s  )
        
        % Increment session id
        s.sessid = s.sessid  +  1 ;
        
      case  'Reset PsychToolbox'
        
        % Raise reset flag and return
        rstflg = 1 ;
        return
        
      case  'Quit'
        
        if  ~ verify (  'Are you sure?'  )  ,  u = '' ;  end
      
    end % user input
    
  end % main menu
  
end % run


% Add or remove a stimulus from the current set
function  s = setstim (  s  ,  E  ,  fun  )
  
  % Remove stimuli but there are none to remove
  if  strcmp (  'rem'  ,  fun  )  &&  isempty (  s.stim.name  )
    fprintf (  'None to remove\n'  )
    return
  end

  % Determine list of valid stimuli
  switch  fun
    case   'add'  ,  stim = setdiff (  E.stim  ,  E.HIDESTIM  ) ;
    case   'rem'  ,  stim = s.stim.name ;
    case  'help'  ,  stim = E.stim ;
  end
  
  % Guarantee row vector
  if  ~ isrow (  stim  )  ,  stim = stim( : )' ;  end
  
  % Get user input
  i = getinput (  stim  ,  ''  ,  'Please select stimulus:\n'  ) ;
  
  % None found
  if  ~ i  ,  return  ,  end
  
  % Isolate stimulus function name
  stim = stim{ i } ;
  
  % Action based on function
  switch  fun
    
    % Add to list
    case  'add'
      
      % Locate in master list
      i = strcmp (  stim  ,  E.stim  ) ;
      
      % Now get variable parameter definitions and function handles
      [ ~ , def , finit , fstim , fclose ] = E.fstim{ i }( [] ) ;
      
      % Default parameter struct
      val = def ( : , [ 1 , 3 ] )' ;  val = struct ( val { : } ) ;
      
      % Add to lists
      s.stim.name  = [  s.stim.name    ,  {   stim }  ] ;
      s.stim.vpdef = [  s.stim.vpdef   ,  {    def }  ] ;
      s.stim.vpval = [  s.stim.vpval   ,  {    val }  ] ;
      s.stim.init  = [  s.stim.init    ,  {  finit }  ] ;
      s.stim.stim  = [  s.stim.stim    ,  {  fstim }  ] ;
      s.stim.close = [  s.stim.close   ,  { fclose }  ] ;
      
      % Two stimuli? Print out warning that variable parameter set is
      % ignored.
      if  numel (  s.stim.name  )  ==  2
        
        fprintf (  'Two or more stimuli\n  Variable parameter ignored\n'  )
        
      end
      
    % Remove from list
    case  'rem'
      
      % Locate in stim list
      i = strcmp (  stim  ,  s.stim.name  ) ;
      
      % Remove
      s.stim.name ( i ) = [ ] ;
      s.stim.vpdef( i ) = [ ] ;
      s.stim.vpval( i ) = [ ] ;
      s.stim.init ( i ) = [ ] ;
      s.stim.stim ( i ) = [ ] ;
      s.stim.close( i ) = [ ] ;
      
    % Print MET ptb stimulus function help
    case  'help'
      
      help (  stim  )
      
  end % action
  
end % setstim


% View and set stimulus parameters
function  s = viewstim (  s  )
  
  % Number of stimuli
  n = numel (  s.stim.name  ) ;

  % No stimuli
  if  ~ n
    fprintf (  'No stimulus added yet\n'  )
    return
  end
  
  % Stimulus menu
  while  true
    
    % Get user input selecting stimulus
    i = getinput (  s.stim.name  ,  'Main menu'  ,  ...
      'Select stimulus to view params:'  ) ;
    
    % Nothing selected
    if  ~ i
      
      continue
      
    % Break condition
    elseif  i  ==  n + 1
      
      break
    
    end % check answer
    
    % Build set of name-value parameter pairings
    S = cellfun (  @( n , v ) sprintf( '%s = %0.6f' , n , v )  ,  ...
      s.stim.vpdef{ i }( : , 1 )  ,  struct2cell( s.stim.vpval{ i } )  ,...
        'UniformOutput'  ,  false  ) ;
      
    % Make it a column vector
    S = S( : )' ;
      
    % Number of params
    m = numel (  S  ) ;
    
    % Parameter menu
    while  true
      
      % Get user input selecting stimulus
      j = getinput (  S  ,  'View stimuli'  ,  ...
        'Select parameter to change:'  ) ;
      
      % Nothing selected
      if  ~ j
        
        continue
        
      % Break condition
      elseif  j  ==  m + 1
        
        break
        
      end % check answer
      
      % Get parameter name , domain , min and max
      par = s.stim.vpdef{ i }( j , [ 1 , 2 , 4 , 5 ] ) ;
      
      % Change parameter
      s.stim.vpval{ i } = setnum (  s.stim.vpval{ i } , par{ : } , false );
      
      % Update string
      S{ j } = sprintf (  '%s = %0.6f'  ,  ...
        par{ 1 }  ,  s.stim.vpval{ i }.( par{ 1 } )  ) ;
      
    end % param menu
    
  end % stimulus menu
  
end % viewstim


% RF mapping function. Not a live session , simply allows user to wave
% stuff around.
function  rfmap (  E  )
  
  
  %-- Setup --%
  
  % Half-flip interval , to set frame-swap deadlines
  hfi = E.tconst.flipint  /  2 ;
  
  % Some stereoscopic mode is in use , so loop both frame buffers ,
  % otherwise we always use the monocular flag value of -1
  if  E.tconst.stereo
    
    eyebuf = 0 : 1 ;
    
  else
    
    eyebuf = -1 ;
    
  end
  
  % Struct for trial variables
  tvar = E.tconst.MCC.SDEF.ptb.stim ;
  tvar.skip = false ;

  % Locate Rf mapping stimulus definitions
  i = ismember (  E.stim  ,  E.MAPSTIM  ) ;
  
  % Number of mapping stim
  n = numel (  E.MAPSTIM  ) ;
  
  % Get var par defs, init/stim/close functions
  [ ~ , vpar , finit , fstim , fclose ] = cellfun (  @( f ) f( [] )  ,  ...
    E.fstim( i )  ,  'UniformOutput'  ,  false  ) ;
  
  % Variable parameter struct pre-cursors
  vpar = cellfun (  @( v ) v( : , [ 1 , 3 ] )'  ,  vpar  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % Variable parameter structs
  vpar = cellfun (  @( v ) struct(  v{ : }  )  ,  vpar  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % Initialise stimuli
  S = cellfun (  @( f , v ) f( v , E.tconst , [] )  ,  finit  ,  vpar  ,...
    'UniformOutput'  ,  false  ) ;
  
  % Instruct user
  fprintf (  [ 'Use <Tab> key to toggle RF map stimuli\n' , ...
    'Hit ''q'' key to return to main menu\n' ]  )
  
  
  %-- Animate --%
  
  % Current stimulus
  i = 1 ;
  
  % Make sure that no keys are pressed
  KbReleaseWait ;
  
  % Synchronising flip
  [ vbl , stimon ] = Screen ( 'Flip' , E.tconst.winptr ) ;
  
  % First vbl time measurement is now the point of reference. This is the
  % time that the 'trial' started.
  time_zero = vbl ;
  
  % Animation loop
  while  true
    
    % Get keyboard press
    [ ~ , ~ , keys ] = KbCheck ;
    
    % Return to main menu
    if  keys(  E.qkey  )
      
      break
      
    % Toggle rfmap stimulus
    elseif  keys(  E.tabkey  )
      
      i = i  +  1 ;
      if  n  <  i  ,  i = 1 ;  end
    
    end % keyboard
    
    % Increment frame count
    tvar.frame = tvar.frame  +  1 ;
    
    % Expected stimulus onset time
    tvar.ftime = stimon  +  E.tconst.flipint  -  time_zero ;
    
    %-- Draw the stimulus --%
    
    % Eye frame buffer loop
    for  e = eyebuf
      
      % Assign buffer flag
      tvar.eyebuf = e ;
      
      % Set stereo drawing buffer
      if  -1  <  e
        Screen (  'SelectStereoDrawBuffer'  ,  E.tconst.winptr  ,  e  ) ;
      end
      
      % Draw MET ptb stimulus
      S{ i } = fstim{ i } ( S{ i } , E.tconst , tvar ) ;
      
    end % eye frame buffer
    
    % Tell PsychToolbox that there will be no more drawing to buffers.
    Screen (  'DrawingFinished'  ,  E.tconst.winptr  ) ;
    
    % New images to screen
    [ vbl , stimon , ~ , missed ] = ...
      Screen (  'Flip'  ,  E.tconst.winptr  ,  vbl + hfi  ) ;
    
    % Check for skipped frame
    tvar.skip = 0  <  missed ;
    
  end % annie loop
  
  % Clear screen
  Screen (  'Flip'  ,  E.tconst.winptr  ) ;
  
  
  %-- Close stimuli --%
  
  for  i = 1 : n  ,  fclose{ i }(  S{ i }  ,  's'  ) ;  end
  
  
end % rfmap


% Run session of trials
function  runsession (  E  ,  s  )
  
  
  % Quit if there are no stimuli
  if  isempty (  s.stim.name  )
    
    fprintf (  'No stimuli selected\n'  )
    return
    
  end
  
  
  %-- Setup --%
  
  % Photodiode square greyscale order
  psqcol = [  E.b.psq_high  ,  E.b.psq_low  ] ;
  
  % Half-flip interval , to set frame-swap deadlines
  hfi = E.tconst.flipint  /  2 ;
  
  % Some stereoscopic mode is in use , so loop both frame buffers ,
  % otherwise we always use the monocular flag value of -1
  if  E.tconst.stereo
    
    eyebuf = 0 : 1 ;
    
  else
    
    eyebuf = -1 ;
    
  end
  
  % Struct for trial variables
  tvar = E.tconst.MCC.SDEF.ptb.stim ;
  tvar.skip = false ;
  
  % Make a copy of variable parameter structs so that we don't overide
  % master copy
  vpval = s.stim.vpval ;
  
  % Initialise stimulus descriptors
  S = cell (  1  ,  numel( s.stim.name )  ) ;
  
    % Stimulus index list
    I = 1 : numel (  S  ) ;
    
  % Session data struct
  sdat.session = sprintf (  '%s.%d'  ,  s.sub  ,  s.sessid  ) ;
  
  % Log file name
  flog = fullfile (  E.pwd  ,  [ sdat.session , '.txt' ]  ) ;
  
  % Output files already exist
  if  exist (  flog  ,  'file'  )  ||  ...
      exist (  strrep( flog , '.txt' , '.mat' )  ,  'file'  )
    
    fprintf (  'Output files already exist for session\n%s\n'  ,  ...
      sdat.session  )
    
    return
    
  end % output files already exist
    
  % Date
  sdat.date = date ;
  
  % Matlab version
  sdat.matver = ver ;
  
  % Psychtoolbox version
  sdat.ptbver = PsychtoolboxVersion ;
  
  % Inter-frame interval
  sdat.flipint = E.tconst.flipint ;
  
  % Stimuli
  sdat.stim = s.stim.name ;
  
  % Stimulus base parameter sets
  sdat.stim_base_params = s.stim.vpval ;
  
  % Variable
  sdat.varname = s.var.nam ;
    
  % Generate random order of variable parameters , sampling without
  % replacement per repetition
  
    % Start by copying the variable value set for each repetition
    sdat.variable = repmat (  { s.var.val }  ,  1  ,  s.var.rep  ) ;
    
    % Then apply random permutation to each copy if shuffling is on
    switch  s.var.shuffle
      
      case  'on'
        
        % New random number generator seed
        rng (  'shuffle'  )
        
        % Random permutations
        sdat.variable = cellfun (  @( v ) v( randperm( numel( v ) ) )  ,...
          sdat.variable  ,  'UniformOutput'  ,  false  ) ;
  
    end % random permute
    
    % At last , collapse into a single vector
    sdat.variable = cell2mat (  sdat.variable  ) ;
  
  % Number of trials is number of reps when there is no variable
  if  numel (  s.stim.name  ) ~= 1  ||  isempty (  s.var.nam  )
    
    sdat.trials = s.var.rep ;
    varflg = false ;
    
  % Otherwise the number is the product of reps times variable values
  else
    
    sdat.trials = numel (  sdat.variable  ) ;
    varflg = true ;
    
  end % num trials
  
  % Trial start times
  sdat.start = zeros (  1  ,  sdat.trials  ) ;
  
  % Random number generator seeds
  switch  s.rng
    
    % Default , set now for safekeeping and keep just one copy
    case  'd'
      
      rng (  'default'  )
      sdat.rng = rng ;
      
    otherwise
      
      sdat.rng = repmat (  rng  ,  1  ,  sdat.trials  ) ;
      
  end % random seed
  
  % Open a log file
  flog = fullfile (  E.pwd  ,  [ sdat.session , '.txt' ]  ) ;
  met (  'logopn'  ,  flog  )
  
  % Abort flag
  abortf = false ;
  
  % Instruct user
  fprintf (  'Hit ''q'' key to abort session and return to main menu\n'  )
  
  
  %-- Trials --%
  
  for  t = 1 : sdat.trials
    
    % Update variable parameter for next trial
    if  varflg
      
      % I know that we only allow one stimulus with variable , but we do
      % this for the day the program is expanded
      for  i = I
        vpval{ i }.( s.var.nam ) = sdat.variable( t ) ;
      end
      logstr = sprintf (  '%0.6f'  ,  sdat.variable( t )  ) ;
      
    % No variables
    else
      
      logstr = 'n/a' ;
      
    end
    
    % Random number generator
    switch  s.rng
      case  'd'  ,  rng (  'default'  ) ;
      case  's'  ,  rng (  'shuffle'  ) ;  sdat.rng( t ) = rng ;
    end
    
    % Initialise stimulus descriptors
    for  i = I
      S{ i } = s.stim.init{ i } (  vpval{ i }  ,  E.tconst  ,  S{ i }  ) ;
    end
    
    % Time at start of trial
    sdat.start( t ) = GetSecs ;
    
    % Log string
    logstr = sprintf (  'trial %d, start %0.6f, var %s'  ,  ...
        t  ,  sdat.start( t )  ,  logstr  ) ;
    
    % Generate log and flush streams
    met (  'print'  ,  logstr  ,  'L'  )
    met (  'flush'  )
    
    % Generate TTL output
    if  ~ isempty (  E.DAQ  )
      
      % High state
      DaqDOut (  E.DAQ  ,  0  ,  E.b.ttl_high  ) ;
      
      % Minimum duration in high state
      WaitSecs (  E.b.ttl_mindur  ) ;
      
      % Low state
      DaqDOut (  E.DAQ  ,  0  ,  E.b.ttl_low  ) ;
      
    end % TTL
    
    % Photodiode no blending
    Screen (  'BlendFunction'  ,  E.tconst.winptr  ,  ...
      'GL_ONE'  ,  'GL_ZERO'  ) ;
    
    % Photodiode current state , start high
    pstat = 0 ;
    
    % Photodiode square preamble
    for  i = 1 : E.b.psq_npulse * 2
      
      % Photo square
      Screen (  'FillRect'  ,  E.tconst.winptr  ,  ...
        psqcol( pstat + 1 )  ,  E.psqrec  ) ;
      
      % Flip to screen
      Screen (  'Flip'  ,  E.tconst.winptr  ) ;
      
      % Swap states
      pstat( 1 ) = ~ pstat ;
      
    end % photodiode preamble
  
  
    %-- Animate --%

    % Make sure that no keys are pressed
    KbReleaseWait ;

    % Synchronising flip
    [ vbl , stimon ] = Screen ( 'Flip' , E.tconst.winptr ) ;

    % First vbl time measurement is now the point of reference. This is the
    % time that the 'trial' started.
    time_zero = vbl ;

    % Animation loop
    while  true

      % Get keyboard press
      [ ~ , ~ , keys ] = KbCheck ;

      % Return to main menu
      if  keys(  E.qkey  )

        % Raise abort flag so that we don't save any output
        abortf = true ;
        break

      end % keyboard

      % Increment frame count
      tvar.frame = tvar.frame  +  1 ;

      % Expected stimulus onset time
      tvar.ftime = stimon  +  E.tconst.flipint  -  time_zero ;

      % Runs until we exceed the trial duration
      if  s.tsecs  <  tvar.ftime  ,  break  ,  end


      %-- Draw the stimulus --%

      % Eye frame buffer loop
      for  e = eyebuf

        % Assign buffer flag
        tvar.eyebuf = e ;

        % Set stereo drawing buffer
        if  -1  <  e
          Screen (  'SelectStereoDrawBuffer'  ,  E.tconst.winptr  ,  e  ) ;
        end

        % Draw MET ptb stimulus
        for  i = I
          S{ i } = s.stim.stim{ i } ( S{ i } , E.tconst , tvar ) ;
        end
        
        % Photodiode blending
        Screen (  'BlendFunction'  ,  E.tconst.winptr  ,  ...
          'GL_ONE'  ,  'GL_ZERO'  ) ;
      
        % Photo square
        Screen (  'FillRect'  ,  E.tconst.winptr  ,  ...
          psqcol( pstat + 1 )  ,  E.psqrec  ) ;

        % Swap states
        pstat( 1 ) = ~ pstat ;

      end % eye frame buffer

      % Tell PsychToolbox that there will be no more drawing to buffers.
      Screen (  'DrawingFinished'  ,  E.tconst.winptr  ) ;

      % New images to screen
      [ vbl , stimon , ~ , missed ] = ...
        Screen (  'Flip'  ,  E.tconst.winptr  ,  vbl + hfi  ) ;

      % Check for skipped frame
      tvar.skip = 0  <  missed ;

    end % annie loop
  
    % Trial-close stimuli
    for  i = I  ,  S{ i } = s.stim.close{ i }(  S{ i }  ,  't'  ) ;  end
    
    % Clear screen
    Screen (  'Flip'  ,  E.tconst.winptr  ) ;
    
    % Abort flag up
    if  abortf  ,  break  ,  end
    
    % Intertrial interval
    WaitSecs (  E.b.inter_trial  ) ;
    
    
  end % trials
  
  
  %-- Close --%
  
  % Session-close stimuli
  for  i = I  ,  s.stim.close{ i }(  S{ i }  ,  's'  ) ;  end
  
  % Close log file
  met (  'logcls'  )
  
  % Abort flag raised
  if  abortf
    
    % Delete log file
    delete (  flog  )
    
  % no abort flag
  else
    
    % Save session data
    save (  strrep( flog , '.txt' , '.mat' )  ,  'sdat'  )
    
    % And attempt to remove write permissions from the data files
    logstr = sprintf(  'chmod a-w %s' ,  strrep( flog , '.txt' , '.*' )  );
    
    if  system (  logstr  )
      
      warning (  [ 'metbasic: failed to remove write permissions ' , ...
        'via $ %s' ]  ,  logstr  ) %#ok
      
    end
    
  end % abt flg
  
  
end % runsession

