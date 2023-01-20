
function  mancal_indev ( fout , bgnd , rwrd )
% 
% For manually calibrating eye signal analogue output from iViewX/SMI.
% This program allows the user to present the fixation point in one of 9
% locations, to control the size of a hit-box around each fixation point,
% and to provide rewards ; if eye positions land in a hit-box then rewards
% are automatically triggered. A copy of the analogue eye positions is
% obtained by reading from a USB-1208fs DAQ with PsychToolbox Daq
% functions. A Matlab based figure window shows where the eye signal is
% positioned relative to fixation point and hit-box on screen. The user
% must then adjust the gain and offset in iViewX to make the eye trace
% cover the fixation point, when the subject is fixating.
% 
% When the calibration figure window is selected, the user can control the
% fixation point and reward using these key commands.
% 
% Present fixation points 1 through 9 by typing 1 to 9. The position is in
% the top left (1), top centre (2), top right (3), left (4), centre (5),
% right (6), bottom left (7), bottom centre (8), bottom right (9). Zero (0)
% extinguishes the fixation point.
% 
% Hit-box size is increased using the '+' key (no shift, as if to type '=')
% and it is decreased using the '-' key.
% 
% Issue a reward with the 'r' key.
% 
% Input
% 
% fout - string - Names the file that the diary function will write to once
%   the calibration file is running. That is, a copy of everything that is
%   printed to the command window will also be written to the named file.
%   If no copy is required then make empty []. Optional argument.
% 
% bgnd - Background value. Normalised from 0 to 1, where 0 is black and 1
%   is white. Fixation points are white, and will not be visible if bgnd is
%   1.
% 
% rwrd - Reward duration in seconds. Must be greater than 0.
% 
% Any input can be set to [] or left out for default values.
% 
% Note: Binoccular eye samples are produced by iViewX at 500Hz.
% 
% Written by Jackson Smith - Sept 2016 - DPAG, University of Oxford
% 
  
  
  %%% CONSTANTS %%%
  
  % Serial number of reward DAQ , this triggers the pump
  DAQSNO = '01AC1989' ;
  DAQPRD = 'USB-1208FS' ;
  d = PsychHID ( 'devices' ) ;
  d = strcmp ( DAQSNO , { d.serialNumber } )  &  ...
      strcmp ( DAQPRD , { d.product      } ) ;
  d = intersect ( DaqDeviceIndex , find ( d ) ) ;
  
  if  isempty ( d )
    error ( 'Cannot find DAQ %s with serial no %s' , DAQPRD , DAQSNO )
  end
  
  % The screen's physical width , in millimetres
  C.SCRWID = 392 ;
  
  % Distance of the subject to monitor screen , in millimeters
  C.S2SCRN = 700 ;
  
  % iViewX eye position sample rate, in HZ
  C.HZ = 500 ;
  
  % Eye trace colours
  C.COL.L = 'r' ;
  C.COL.R = 'c' ;
  
  % Reward DAQ
  C.REWDAQ = d ;
  
  % Reward channel
  C.DAQRCH = 0 ;
  
  % Reward duration, in seconds
  C.REWDUR = 0.25 ;
  
  
  % PTB Constants
  
  % Window background colour, in colour index 0 to 1.
  C.BAKGND = 0.5 ;
  
  % Fixation point colour
  C.FIXCOL = 1 ;
  
  % Fixation point size, in pixels
  C.FIXSIZ = 30 ;
  
  % Fixation point hit box width , in pixels
  C.FIXHIT = 4 * C.FIXSIZ ;
  
  % Hit-box size change factor. Always by 10%
  C.FHBDIF = 1.1 ;
  
  % Fixation point locations, as a fraction of screen width/height. Columns
  % are [ horizontal , vertical ]
  C.FIXPNT = [ 0.1 , 0.1 ;   % 1 - top left
               0.5 , 0.1 ;   % 2 - top centre
               0.9 , 0.1 ;   % 3 - top right
               0.1 , 0.5 ;   % 4 - left
               0.5 , 0.5 ;   % 5 - centre
               0.9 , 0.5 ;   % 6 - right
               0.1 , 0.9 ;   % 7 - bottom left
               0.5 , 0.9 ;   % 8 - bottom centre
               0.9 , 0.9 ] ; % 9 - bottom right
	
	
	%%% Check Input %%%
  
  % Defaults
  if  nargin < 1 , fout = [] ; end
  if  nargin < 2 , bgnd = [] ; end
  if  nargin < 3 , rwrd = [] ; end
  
  if  ~isempty ( fout )  &&  ~isvector ( fout )  &&  ~ischar ( fout )
    error ( 'Input argument fout must be a string' )
  end
  
  if  ~isempty ( bgnd )  &&  ...
      ( ~isscalar ( bgnd )  ||  bgnd < 0  ||  1 < bgnd )
    error ( 'Input argument bgnd must be scalar double from 0 to 1' )
  end
  
  if  ~isempty ( rwrd )  &&  ( ~isscalar ( rwrd )  ||  rwrd <= 0 )
    error ( 'Input argument rwrd must be scalar double from 0 to 1' )
  end
  
  % Use given values
  if  ~ isempty ( bgnd )  ,  C.BAKGND = bgnd ;  end
  if  ~ isempty ( rwrd )  ,  C.REWDUR = rwrd ;  end
  
  
  %%% Make reward timer %%%
  
  t = timer ( 'StartDelay' , C.REWDUR , ...
       'StartFcn' , @( ~ , ~ ) DaqAOut ( C.REWDAQ , C.DAQRCH , 1 ) , ...
       'TimerFcn' , @( ~ , ~ ) DaqAOut ( C.REWDAQ , C.DAQRCH , 0 ) ) ;
  
  
  %%% Psych Toolbox %%%
  
  % Try to get beamposition queries to work
  Screen( 'preference' , 'screentohead' , 1 , 0 , 0 , 0 ) ;
  
  % Standard setup - now colours mapped to range 0.0 - 1.0
  PsychDefaultSetup ( 2 )
  
  % Choose a screen
  PTB.SCR = max ( Screen ( 'screens' ) ) ;
  
  % Open window
  [ PTB.wptr , PTB.wrec ] = ...
    PsychImaging ( 'OpenWindow' , PTB.SCR , C.BAKGND ) ;
  
  % Make a taskcontroller.m style PTB window object with enough fields to
  % run indev.
  C.ptbwin.size_px = PTB.wrec ( 3 : 4 ) ;
  C.ptbwin.pixperdeg = PTB.wrec ( 3 ) / atand ( C.SCRWID / C.S2SCRN ) ;
  C.ptbwin.flipinterval = Screen ( 'getflipinterval' , PTB.wptr ) ;
  
  % Screen height and width
  C.SCRN.WIDTH = PTB.wrec ( 3 ) ;
  C.SCRN.HEIGHT = PTB.wrec ( 4 ) ;
  
  % PTB dot parameters
  PTB.DOT = { 'DrawDots' ;   % 1 - Screen command
                PTB.wptr ;   % 2 - window pointer place holder
                      [] ;   % 3 - dot position place holder
                C.FIXSIZ ;   % 4 - dot width in pixels
                C.FIXCOL ;   % 5 - dot colour
                      [] ;   % 6 - default origin, upper left of ptb window
                       2 } ; % 7 - drawing method, highest possible quality
  
	
	%%% Make a figure %%%
  
  f = figure ( 'Visible' , 'off' , 'CreateFcn' , { @fig_make , fout } , ...
    'CloseRequestFcn' , @fig_close , 'KeyPressFcn' , @fig_keypress ) ;
  
  
  %%% Prepare input DAQ for reading %%%
  
  try
    
    [ indevd , iddclose ] = indev ;
    indevd = indevd.init ( indevd , C.ptbwin ) ;
    iddclose = @( )  iddclose ( indevd ) ;
    
  catch  E
    
    shutdown ( t , [] )
    rethrow ( E )
    
  end
  
  
  %%% Run test program %%%
  
  try
    
    % Run test
    runt ( C , t , PTB , indevd , iddclose , f )
    
  catch E
    
    % Error detected, proceed to shutdown. But then rethrow error.
    shutdown ( t , @( ) iddclose ( indevd ) )
    delete ( f )
    rethrow ( E )
    
  end
  
end % mancal_indev


%%% SUBROUTINES %%%

function  shutdown ( t , iddclose )
  
  % Close PTB window
  fprintf ( 'mancal_indev: closing PTB\n' )
  sca
  
  % Delete timer object
  fprintf ( 'mancal_indev: deleting timer\n' )
  try
    delete ( t )
  catch
    fprintf ( 'mancal_indev: failed to close timer\n' )
  end
  
  % Return unless we're also closing input device
  if  isempty ( iddclose ) , return , end
  
  % Close input device
  fprintf ( 'mancal_indev: closing input device\n' )
  try
    iddclose ( )
  catch
    fprintf ( 'Could not shut down input device\n' )
  end
  
end % shutdown


function  runt ( C , t , PTB , indevd , iddclose , f )
  
  
  %%% Set up eye position plot %%%
  
  % Figure data , accessible in runt and in callbacks , pass values
  f.UserData.C   =   C ;
  f.UserData.t   =   t ;
  f.UserData.PTB = PTB ;
  
  % Quit flag , true when attempt to close figure
  f.UserData.clsflg = false ;
  
  % iViewX analogue eye position axes
  peye.a = axes ( 'parent' , f ) ;
  
  axis ( peye.a , 'equal' )
  grid ( peye.a , 'on' )
  
  peye.a.YDir = 'reverse' ;
  
  peye.a.XLim = [ 0 , C.SCRN.WIDTH  ] ;
  peye.a.YLim = [ 0 , C.SCRN.HEIGHT ] ;
  
  peye.a.TickDir = 'out' ;
  peye.a.XTickLabelRotation = 45 ;
  
  peye.a.XTick = 0 : 400 : C.SCRN.WIDTH  ;
  peye.a.YTick = 0 : 400 : C.SCRN.HEIGHT ;
  
  % Fixation point marker
  peye.F = rectangle ( 'Parent' , peye.a , 'linestyle' , '-' , ...
    'facecolor' , 'none' , 'linewidth' , 1 , 'visible' , 'off' , ...
    'curvature' , [ 1 , 1 ] , ...
    'position' , [ 0 , 0 , C.FIXSIZ , C.FIXSIZ ] ) ;
  f.UserData.F = peye.F ;
  
  % Fixation point hit-box
  peye.HB = rectangle ( 'Parent' , peye.a , 'linestyle' , ':' , ...
    'facecolor' , 'none' , 'linewidth' , 1 , 'visible' , 'off' , ...
    'position' , [ 0 , 0 , C.FIXHIT , C.FIXHIT ] ) ;
  f.UserData.HB = peye.HB ;

  % Eye position lines
  peye.L = animatedline ( 'linestyle' , 'none' , ...
    'marker' , '.' , 'markeredgecolor' , C.COL.L , ...
    'maximumnumpoints' , round ( 1 * C.HZ ) , 'Parent' , peye.a ) ;

  peye.R = animatedline ( 'linestyle' , 'none' , ...
    'marker' , '.' , 'markeredgecolor' , C.COL.R , ...
    'maximumnumpoints' , round ( 1 * C.HZ ) , 'Parent' , peye.a ) ;
  
  % Labels
  xlabel ( peye.a , 'Horizontal (pix)' )
  ylabel ( peye.a , 'Vertical (pix)' )
   title ( peye.a , 'Eye position, iViewX > NSP > cbmex' )
  
  
  %%% Draw loop %%%
  
  % Figure visible
  f.Visible = 'on' ;
  
  while  ~ f.UserData.clsflg
    
    % Update axes , execute callbacks
    drawnow  limitrate
    
    % Read in eye positions
    [ ~ , ~ , ~ , indevd ] = indevd.check ( indevd , C.ptbwin ) ;
    
    % Point to buffer
    b = indevd.indev_buf ;
    
    % No new data points
    if  b.N  ==  2  ,  continue  ,  end
    
    % Indeces of new data
    i = 3 : b.N ;
    
    % If hit-box is on then check if eyes have entered it
    if  strcmp ( peye.HB.Visible , 'on' )
    
      % First , grab indeces to valid data
      v = i ( b.valid ( i ) ) ;
      
      % Find top-left and bottom-right corners of hit-box
      tl = peye.HB.Position ( 1 : 2 ) ;
      br = tl  +  peye.HB.Position ( 3 : 4 ) ;
      
      % Compare eye positions against hit-box boundaries
      inbox = tl( 1 ) <= b.x( v , : )  &  ...
              tl( 2 ) <= b.y( v , : )  &  ...
              br( 1 ) >= b.x( v , : )  &  ...
              br( 2 ) >= b.y( v , : ) ;

      % If any data points from both eyes have entered hit-box then start
      % reward timer
      if  any ( all ( inbox ,  2 ) )
        stop  ( t )
        start ( t )
      end
      
    end % hit box on
    
    % Update animate lines
    addpoints ( peye.L , b.x( i , 1 ) , b.y( i , 1 ) )
    addpoints ( peye.R , b.x( i , 2 ) , b.y( i , 2 ) )
    
    % Reset indev buffer
    i = i ( end - 1 : end ) ;
    
    b.N = 2 ;
    b.x( 1 : 2 , : ) = b.x( i , : ) ;
    b.y( 1 : 2 , : ) = b.y( i , : ) ;
    
    indevd.indev_buf = b ;
    
  end % draw loop
  
  
  %%% Shut down %%%
  
  % Release resources
  shutdown ( t , iddclose )
  
  % Close figure
  delete ( f )
  
  
end % runt


function  fig_keypress ( f , d )
  
  
  %%% Handy-dandy short cuts %%%
  
  % Constants
  C = f.UserData.C ;
  
  % Psych Toolbox
  P = f.UserData.PTB ;
  
  % Fixation point
  F = f.UserData.F ;
  
  % Hit box
  HB = f.UserData.HB ;
  
  % Start time
  s = f.UserData.start ;
  
  
  %%% Respond to different key presses %%%
  
  switch  d.Character
    
    % Change fixation point location
    case  { '1' , '2' , '3' , '4' , '5' , '6' , '7' , '8' , '9' }
      
      % Figure out which point to show
      i = str2double ( d.Character ) ;
      i = C.FIXPNT( i , : ) .* [ C.SCRN.WIDTH , C.SCRN.HEIGHT ] ;
      
      % Update PTB
      P.DOT{ 3 } = i' ;
      Screen ( P.DOT{ : } ) ;
      Screen ( 'Flip' , P.wptr ) ;
      
      % Update eye trace figure fixation point ...
      F.Position( 1 ) = i( 1 )  -  F.Position( 3 ) / 2 ;
      F.Position( 2 ) = i( 2 )  -  F.Position( 4 ) / 2 ;
      F.Visible = 'on' ;
      
      % ... and hit-box
      HB.Position( 1 ) = i( 1 )  -  HB.Position( 3 ) / 2 ;
      HB.Position( 2 ) = i( 2 )  -  HB.Position( 4 ) / 2 ;
      HB.Visible = 'on' ;
      
      fprintf ( [ 'New fix pnt: %0.2f , %0.2f\n' , ...
                  'New fix pnt time: %0.6f\n' ] , ...
        i( 1 ) , i( 2 ) , GetSecs - s )
      
    % Extinguish fixation point
    case  '0'
      
      % Blank PTB
      Screen ( 'Flip' , P.wptr ) ;
      
      % Invisible fixation point and hit-box
       F.Visible = 'off' ;
      HB.Visible = 'off' ;
      
      fprintf ( 'Extinguish fix point time: %0.6f\n' , GetSecs - s )
      
    % Change size of hit-box
    case  { '-' , '=' }
      
      % Make it bigger or smaller?
      if  d.Character  ==  '-'
        
        % Divide by size factor , gets smaller
        C.FIXHIT = C.FIXHIT  /  C.FHBDIF ;
        
      else
        
        % Multiply by size factor , gets bigger
        C.FIXHIT = C.FIXHIT  *  C.FHBDIF ;
        
      end
      
      % Keep from getting too small
      if  C.FIXHIT  <  1  ,  C.FIXHIT = 1 ;  end
      
      % Remember value
      f.UserData.C = C ;
      
      % Determine half the horizontal and vertical difference
      d = ( HB.Position( 3 : 4 )  -  C.FIXHIT )  /  2 ;
      
      % Apply shift in position and new size
      HB.Position = [ HB.Position( 1 : 2 ) + d , C.FIXHIT , C.FIXHIT ] ;
      
      fprintf ( [ 'Hit-box width: %0.2f\n' , ...
                  'Hit-box width time: %0.6f\n' ] , ...
                  C.FIXHIT , GetSecs - s )
      
      
    % Reward
    case  'r'
      
      fprintf ( 'Reward time: %0.6f\n' , GetSecs - s )
      
      % Run reward timer
      stop  ( f.UserData.t )
      start ( f.UserData.t )
      
  end % respond to key press
  
  
end % fig_keypress


function  fig_make ( f , ~ , fout )
  
  % Record copy of all command window output
  if  ~isempty ( fout )
    
    diary ( fout )
    
  end
  
  % Get and report time of figure creation
  f.UserData = struct ( 'C' , [] , 't' , [] , 'PTB' , [] , 'start' , [] ) ;
  f.UserData.start = GetSecs ;
  fprintf ( 'Start manual calibration time: %0.6f\n' , f.UserData.start )
  
end % fig_make


function  fig_close ( f , ~ )
  
  % Get stop time and report duration of calibration session
  t = GetSecs ;
  fprintf ( [ 'Stop manual calibration time: %0.6f\n' , ...
              'Duration of calibration: %0.6f\n' ] , ...
    t , t - f.UserData.start )
  
  % Stop recording command window output
  diary off
  
  % Stop timer
  t = f.UserData.t ;
  stop ( t )
  
  % Raise close flag
  f.UserData.clsflg = true ;
  
end % fig_close

