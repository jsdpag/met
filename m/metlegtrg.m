
function  metlegtrg ( MC )
% 
% metlegtrg ( MC )
% 
% Matlab Electrophysiology Toolbox legacy stimulus targeting. Uses either
% the clicked mouse position or streamed eye positions to determine which
% target the subject has currently selected. If mouse-driven, then the
% mouse is polled approximately once per frame. Otherwise, eye positions
% from metlegeye are waited for.
% 
% If eye-driven, then velocity and accelleration thresholds are applied.
% Valid eye positions must not exceed velocity and accelleration thresholds
% of 30 deg/s and 8000 deg/s^2. See Rayner et al. 2007. Vision Research,
% 47(21), 2714–2726.
% 
% Expects metlegctl to write to 'stim' the hit boxes for all visible
% stimuli, along with concrete stimulus indeces. When a stimulus is
% selected, mtarget is generated in reply, carrying the index of the
% selection. metlegeye is expected to write eye positions to 'eye' in pixel
% coordinates.
% 
% NOTE: If iViewX is the eye-tracking program, then make sure that
% out-of-range behaviour is set to clipping. That way, when the eyes are
% looking away from the screen, or the tracker can't detect the eyes, the
% voltage is raised to its maximum. When converted to pixels, this is the
% very bottom/right of the screen.
% 
% Written by Jackson Smith - Dec 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global constants %%%
  
  global  MCC
  
  % MET controller constants
  MCC = metctrlconst ;
  
  
  %%% Constants %%%
  
  % Select which device to use , 'm' for mouse and 'e' for eyes
  INDEV = 'm' ;
  
  if  all ( INDEV  ~=  'em' )
    error ( 'MET:metlegtrg:INDEV' , ...
      'metlegtrg: constant INDEV must be ''e'' or ''m''' )
  end
  
  % MET signal identifiers
  MSID = MC.SIG' ;  MSID = struct ( MSID { : } ) ;
  
  % Blocking read on met 'recv'
  WAIT_FOR_MSIG = 1 ;
  
  % Location of mgui directory with plotting user interface
  LEGDIR = fileparts (  which ( 'metlegtrg' )  ) ;
  LEGDIR = fullfile ( LEGDIR , 'legacy' ) ;
  
  % Required MET shared memory , must have read access
  METSHM = { 'stim' , 'eye' } ;
  
  % Shared memory error message
  SHMERR = [ 'metlegtrg: Needs read access to shm: ''' , ...
    strjoin( METSHM , ''' , ''' ) , ''' , check .cmet file' ] ;
  
  % Mouse poll rate , assumes that maximum screen index is stimulus screen.
  % Convert to duration of each sample , in seconds
  STMSCR = max ( Screen ( 'Screens' ) ) ;
  MPOLLR = 1  /  Screen ( 'FrameRate' , STMSCR ) ;
  
  % Screen dimensions in pixels
  [ SCRHOR , SCRVER ] = Screen ( 'WindowSize' , STMSCR ) ;
  
  % Eye velocity and acceleration thresholds , in degrees per second and
  % degrees per second-squared. Eye positions that exceed these thresholds
  % are not reported. Used factors of 1.6 , 2 , 2.5
%   VELTHR = 30 ;
%   ACCTHR = 8000 ;
VELTHR = 30 * 2.5 ;
ACCTHR = 8000 * 2.5 ;
  
  % Convert to pixels per second (squared) , assume that this is the same
  % in both dimensions
  [ VELTHR , ACCTHR ] = deg2pix ( SCRHOR , VELTHR , ACCTHR ) ;
  
  % Eye sampling rate
  EYESHZ = MCC.SHM.EYE.SHZ ;
  
  % Timeout for select , this is the mouse poll duration , or indefinite if
  % eye-driven
  switch  INDEV
    case  'm'  ,  TOUT = MPOLLR ;
    case  'e'  ,  TOUT =     [] ;
  end
  
  % Index for each hit box vertex
  HBL = RectLeft   ;
  HBR = RectRight  ;
  HBT = RectTop    ;
  HBB = RectBottom ;
  
  % List of variable names to clear before running controller
  CLRVAR = { 'INDEV' , 'METSHM' , 'SHMERR' , 'MPOLLR' , 'PLTDIR' , ...
    'STMSCR' , 'SCRHOR' , 'SCRVER' , 'VELTHR' , 'ACCTHR' , 'EYESHZ' , ...
    'CLRVAR' } ;
  
  
  %%% Environment check %%%
  
  % Look for legacy directory
  if  ~ exist ( LEGDIR , 'dir' )
    error ( 'MET:metlegtrg:legacy' , ...
       [ 'metlegtrg: Can''t find ' , LEGDIR ] )
  end
  
  % Change to legacy directory
  cd ( LEGDIR )
  
  % No access to any shm
  if  isempty ( MC.SHM )
    error ( 'MET:metlegtrg:shm' , SHMERR )
  end
  
  % Verify read access on required shm
  for  i = 1 : numel ( METSHM )
    
    j = strcmp ( MC.SHM ( : , 1 ) , METSHM { i } ) ;
    
    if  all ( [ MC.SHM{ j , 2 } ]  ~=  'r' )
      error ( 'MET:metlegtrg:shm' , SHMERR )
    end
    
  end % shm read access
  
  
  %%% Input device %%%
  
  % Set input device function and descriptor
  switch  INDEV
    
    % Mouse
    case  'm'  ,  indevf = @indev_mouse ;
                   indev = [] ;
      met ( 'printf' , 'metlegtrg: Using mouse as input device' , 'e' )
    
    % Eyes
    case  'e'  ,  indevf = @indev_eyes  ;
      
      % Define eye input device descriptor , start with constants
      indev.C = struct ( 'SCRHOR' , SCRHOR , 'SCRVER' , SCRVER , ...
        'VELTHR' , VELTHR , 'ACCTHR' , ACCTHR , 'EYESHZ' , EYESHZ , ...
         'T' , MCC.SHM.EYE.COLIND.TIME , ...
        'XL' , MCC.SHM.EYE.COLIND.XLEFT , ...
        'YL' , MCC.SHM.EYE.COLIND.YLEFT , ...
        'XR' , MCC.SHM.EYE.COLIND.XRIGHT , ...
        'YR' , MCC.SHM.EYE.COLIND.YRIGHT , ...
        'BUFSIZ' , 3 ) ;
      
      % Prepare a short eye position buffer so that velocity and
      % acceleration can be computed when only one eye sample is received.
      % Field .b holds the most recent 3 eye positions as they were
      % received from 'eye' shm, ordered chronologically by row. Field
      % .v( i ) is true if both eye positions in sample .b( i , : ) are in
      % the range [ 0 , maxpx ) where maxpx is the length of the screen in
      % that dimension, in pixels.
      indev.b = zeros ( indev.C.BUFSIZ , MCC.SHM.EYE.NCOL ) ;
      indev.v = false ( indev.C.BUFSIZ , 1 ) ;
      
      met ( 'printf' , 'metlegtrg: Using eye tracker as input device' , ...
        'e' )
      
    otherwise
      error ( 'MET:metlegtrg:INDEV' , ...
        [ 'metlegtrg: Unrecognised INDEV value ''' , INDEV , '''' ] )
    
  end % input device
  
  
  %%% Prepare variables %%%
  
  % Clear unneeded variables
  clear ( CLRVAR { : } )
  
  % Trial status , 0 - non running , 1 - running
  tstat = false ;
  
  % Eye positions read from shared memory
  eye = [] ;
  
  % Hit box definitions and task stimulus indeces
  H = [] ;  I = [] ;
  
  % True if a hit box was selected
  hit = false ;
  
  % Currently targeted concrete stimulus index , 0 means none
  targ = 0 ;
  
  
  %%% Complete MET initialisation %%%
  
  % Send mready signal , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Wait for synchronising ready signal
  [ ~ , ~ , sig ] = met ( 'recv' , WAIT_FOR_MSIG ) ;
  
  % Return if any mquit signal received
  if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
  
  
  %%% Event loop %%%
  
  while  true
    
    % Wait for next event
    [ ~ , msig , shm ] = met ( 'select' , TOUT ) ;
    
    
    %-- Get new MET signals --%
    
    if  msig
      
      % Non-blocking read
      [ ~ , ~ , sig , crg ] = met ( 'recv' ) ;
      
      % mquit received , terminate controller
      if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
      
      % mready trigger , send reply
      imrd = sig  ==  MSID.mready ;
      if  any (  crg ( imrd )  ==  MC.MREADY.TRIGGER  )
        met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
      end
      
      % Remove any mready
      sig = sig ( ~ imrd ) ;
      
      % mstart received , trial is running , reset targ
      if  any ( sig  ==  MSID.mstart )
        tstat( 1 ) = 1 ;
         targ( 1 ) = 0 ;
      end
      
      % mstop received , trial is not running
      if  any ( sig  ==  MSID.mstop  )  ,  tstat( 1 ) = 0 ;  end
      
    end % MET signals
    
    
    %-- Read shared memory --%
    
    if  ~ isempty ( shm )
      
      % Check available shared memory
      for  i = 1 : size ( shm , 1 )
        
        % Can't read this shm , go to next
        if  shm { i , 2 }  ~=  'r'  ,  continue  ,  end
        
        % Read shared memory
        C = met ( 'read' , shm { i , 1 } ) ;
        
        % Map new read to the appropriate variable(s)
        switch  shm { i , 1 }
          case  'stim'  ,  [ H , I ] = C { : } ;
          case   'eye'  ,        eye = C { 1 } ;
        end
        
      end % available shm
      
    end % read shared memory
    
    
    %-- Get currently selected point --%
    
    % Returns x and y as [] if no valid position, or returns vectors where
    % x( i ) and y( i ) give the location of the ith point. t is a scalar
    % time measurement.
    [ x , y , t , indev ] = indevf ( indev , eye ) ;
    
    % Discard used eye samples
    eye = [] ;
    
    
    %-- Determine selected target --%
    
    % Trial not running or , like Nigel , no valid point
    if  ~ tstat  ||  isempty ( x )  ,  continue  ,  end
    
    % Compare each concrete stimulus against the selected point. Run
    % backwards so that the last thing drawn is on top of everything else,
    % and is the first thing hit.
    for  i = numel ( H ) : -1 : 1
      
      % Point to current set of hit boxes
      h = H { i } ;
      
      % Initialise result
      hit = true ;
      
      % Check each selected point
      for  j = 1 : numel ( x )
      
        hit =  hit  &&  firsttrue (  ...
          h( HBL , : ) <= x( j )  &  x( j ) <= h( HBR , : ) & ...
          h( HBT , : ) <= y( j )  &  y( j ) <= h( HBB , : )  ) ;
                           
      end
      
      % Stimulus is selected
      if  hit  ,  break  ,  end
      
    end % task stimuli
    
    % Stimulus selected , map to concrete stimulus index
    if  hit
      i = I ( i ) ;
      
    % No stimulus selected
    else
      i = 0 ;
      
    end
    
    % Not a new selection
    if  targ  ==  i  ,  continue  ,  end
    
    % Newly selected stimulus , update selection and send mtarget. Have to
    % add 1 to cargo because 0 is out of range.
    targ = i ;
    met ( 'send' , MSID.mtarget , targ + 1 , t ) ;
    
  end % event loop
  
  
end % metlegtrg


%%% Subroutines %%%

function  varargout = deg2pix ( px , varargin )
  
  % Get screen dimensions in mm
  p = metscrnpar ;
  mm = p.width ;
  
  % Compute pixels per degree
  ppd = metpixperdeg ( mm , px , p.subdist ) ;
  
  % Convert input arguments from degrees per unit time to pixels
  varargout = cell ( 1 , nargin - 1 ) ;
  
  for  i = 1 : nargin - 1
    
    varargout{ i } = ppd  *  varargin { i } ;
    
  end
  
end % deg2pix


%%% Input device functions %%%

function  [ x , y , t , indev ] = indev_mouse ( indev , ~ )
  
  % Check mouse status
  [ x , y , buttons ] = GetMouse ;
  t = GetSecs ;
  
  % No buttons are down , return null position
  if  ~ any ( buttons )
    x = -1 ;
    y = -1 ;
  end
  
end % indev_mouse


function  [ x , y , t , indev ] = indev_eyes ( indev , eyepx )
  
  
  %%% Constants %%%
  
  C = indev.C ;
  
  
  %%% Initialise output arguments %%%
  
  x = [] ;  y = [] ;  t = [] ;
  
  
  %%% Update buffer %%%
  
  % No samples provided , so there are none to select , end function
  if  isempty ( eyepx )  ,  return  ,  end
  
  % Number of samples received
  n = size ( eyepx , 1 ) ;
  
  % Enough samples received to fill the buffer
  if  C.BUFSIZ  <=  n
    
    % Grab them
    n = C.BUFSIZ ;
    indev.b( : , : ) = eyepx ( end - n + 1 : end , : ) ;
    
  % Fewer were received
  else
    
    % Shift old samples already in the buffer
    indev.b( 1 : end - n , : ) = indev.b ( n + 1 : end , : ) ;
    indev.v( 1 : end - n     ) = indev.v ( n + 1 : end     ) ;
    
    % Place new samples
    indev.b ( end - n + 1 : end , : ) = eyepx ;
    
  end
  
  % Check new samples for validity i.e. have not clipped to screen edge
  % along the horizontal
  n = C.BUFSIZ  -  n  +  1 ;
  i = [ C.XL , C.XR ] ;
  indev.v( n : end ) = ...
    all ( indev.b ( n : end , i )  <  C.SCRHOR  ,  2 ) ;
  
  % Or the vertical
  i = [ C.YL , C.YR ] ;
  indev.v( n : end ) = indev.v( n : end )  &  ...
    all ( indev.b ( n : end , i )  <  C.SCRVER  ,  2 ) ;
  
  
  %%% Compute velocity and acceleration %%%
  
  % Not enough valid samples , no point selected , end function
  if  ~ all ( indev.v )  ,  return  ,  end
  
  % Compute the marginal velocity of new samples with column ordered by eye
  % [ left , right ]
  vx = diff (  indev.b ( : , [ C.XL , C.XR ] )  )  *  C.EYESHZ ;
  vy = diff (  indev.b ( : , [ C.YL , C.YR ] )  )  *  C.EYESHZ ;
  
  % Compute marginal acceleration of new samples
  ax = diff ( vx )  *  C.EYESHZ ;
  ay = diff ( vy )  *  C.EYESHZ ;
  
  % Vector velocity magnitude
  v = sqrt ( vx( end , : ) .^ 2  +  vy( end , : ) .^ 2 ) ;
  
  % Acceleration
  a = sqrt ( ax .^ 2  +  ay .^ 2 ) ;
  
  
  %%% Determine selected point %%%
  
  % Current eye position exceeds velocity or acceleration threshold , no
  % point selected , end function
  if  any (  C.VELTHR  <  v  |  C.ACCTHR  <  a  )  ,  return  ,  end
  
  % Return binoccular eye position and time point , eyes column ordered
  % [ Left , Right ]
  x = indev.b ( end , [ C.XL , C.XR ] ) ;
  y = indev.b ( end , [ C.YL , C.YR ] ) ;
  t = indev.b ( end , C.T ) ;
  
  
end % indev_eyes

