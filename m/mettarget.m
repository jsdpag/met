
function  mettarget ( MC_in )
% 
% mettarget ( MC )
% 
% Matlab Electrophysiology Toolbox stimulus targeting. Uses either
% the clicked mouse position or streamed eye positions to determine which
% visual stimulus the subject is currently selecting. The controller waits
% for new positions of either kind to arrive in 'eye' shared memory. To
% switch between mouse- and eye-driven targeting, set the value of the
% metscrnpar.csv parameter 'touch' to either 1 (screen is a touchscreen
% i.e. mouse-driven) or 0 (screen is not a touchscreen i.e. eye-driven).
% 
% If eye-driven, then velocity and accelleration thresholds are applied.
% Valid eye positions must not exceed velocity and accelleration thresholds
% of 30 deg/s and 8000 deg/s^2. See Rayner et al. 2007. Vision Research,
% 47(21), 2714–2726. (Note: In practice, higher thresholds are necessary to
% make the controller sensitive to brief fixations, but these can be set in
% the mettarget.csv MET parameter file along with the blink filter
% duration). A simple blink filter is applied to eye positions, allowing no
% more than 200 ms of invalid samples before the controller sends a mtarget
% signal with 'none' for cargo i.e. it reports that nothing on screen is
% being targeted.
% 
% Shared memory 'stim' and 'eye' must be readable. Positions received
% through eye shared memory must be in degrees of visual stimulus in a
% standard Cartesian coordinate system centred on the middle of the screen,
% where up and right are in the positive direction, while down and left are
% in the negative direction.
% 
% It is expected that a full set of hit-regions for each ptb-type stimulus
% link will be shared during the trial initialisation phase ; only ptb-type
% stimulus links should come over stim shm. That is, after receiving an
% mready trigger but before receiving mstart. mettarget will only send an
% mready reply after it has received the initialising hit-regions. mstate
% events are used to determine which stimuli are currently visible.
% 
% NOTE: If iViewX is the eye-tracking program, then make sure that
% out-of-range behaviour is set to clipping. That way, when the eyes are
% looking away from the screen, or the tracker can't detect the eyes, the
% voltage is raised to its maximum. When converted to pixels, this is the
% very bottom/right of the screen.
% 
% The mettarget.csv file must have column headers param,value and list
% parameters: THRMUL , VELTHR , ACCTHR , FBLINK. VELTHR is the velocity
% threshold in degrees per second, and ACCTHR is the acceleration threshold
% in degrees per second-squared. THRMUL is a scaling term that is
% multiplied into both thresholds, for convenience. FBLINK is the duration
% of the blink filter in seconds.
%
%   Example:
% 
%   param,value
%   THRMUL,2.5
%   VELTHR,30
%   ACCTHR,8000
%   FBLINK,0.2
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Global constants %%%
  
  global  MC  MCC
  
  % MET constants
  MC = MC_in ;
  
  % MET controller constants
  MCC = metctrlconst ;
  
  
  %%% Constants %%%
  
  % Select which device to use , 'm' for mouse and 'e' for eyes. Since
  % screen parameters are being read, this is also the time to get the
  % stimulation screen index and the number of pixels per degree.
  [ INDEV , STMSCR , PIXDEG ] = readindev ;
  
  if  all ( INDEV  ~=  'em' )
    error ( 'MET:mettarget:INDEV' , ...
      'mettarget: constant INDEV must be ''e'' or ''m''' )
  end
  
  % MET signal identifier name-to-value map
  MSID = MCC.MSID ;
  
  % Blocking read on met 'recv'
  WAIT_FOR_MSIG = 1 ;
  
  % Required MET shared memory , must have read access
  METSHM = { 'stim' , 'eye' } ;
  
  % Shared memory error message
  SHMERR = [ 'mettarget: Needs read access to shm: ''' , ...
    strjoin( METSHM , ''' , ''' ) , ''' , check .cmet file' ] ;
  
  % Screen dimensions in pixels
  [ SCRHOR , SCRVER ] = Screen ( 'WindowSize' , STMSCR ) ;
  
  % Eye velocity and acceleration thresholds , in degrees per second and
  % degrees per second-squared. Eye positions that exceed these thresholds
  % are not reported. Blink filter maximum blink duration in seconds.
  [ VELTHR , ACCTHR , FBLINK ] = readpar ;
  
  % Eye sampling rate
  EYESHZ = MCC.SHM.EYE.SHZ ;
  
  % Choose wich element of the 'eye' shared memory is returned , either
  % that containing eye positions or that containing mouse positions
  switch  INDEV
    case  'm'  ,  EYEIND = MCC.SHM.EYE.IMOUSE ;
    case  'e'  ,  EYEIND = MCC.SHM.EYE.EYEIND ;
  end
  
  % List of variable names to clear before running controller
  CLRVAR = { 'INDEV' , 'METSHM' , 'SHMERR' , 'MPOLLR' , ...
    'STMSCR' , 'SCRHOR' , 'SCRVER' , 'VELTHR' , 'ACCTHR' , 'EYESHZ' , ...
    'PIXDEG' , 'FBLINK' , 'CLRVAR' } ;
  
  
  %%% Environment check %%%
  
  % No access to any shm
  if  isempty ( MC.SHM )
    error ( 'MET:mettarget:shm' , SHMERR )
  end
  
  % Verify read access on required shm
  for  i = 1 : numel ( METSHM )
    
    j = strcmp ( MC.SHM ( : , 1 ) , METSHM { i } ) ;
    
    if  all ( [ MC.SHM{ j , 2 } ]  ~=  'r' )
      error ( 'MET:mettarget:shm' , SHMERR )
    end
    
  end % shm read access
  
  
  %%% Blink filter %%%
  
  % Bundle together into a struct. maxdur is the maximum duration in
  % seconds that a blink is allowed to take. If this is set to zero
  % then no blink filter is used ; this is done if the touchscreen/mouse is
  % the main input device. flag is raised when a putative blink has been
  % detected, and time is approximately when. Note, flag is down if there
  % is no blink going on , flag is up if a blink is occurring.
  fblink = struct ( 'maxdur' , FBLINK , 'flag' , false , 'time' , 0 ) ;
  
  
  %%% Input device %%%
  
  % Set input device function and descriptor
  switch  INDEV
    
    % Mouse
    case  'm'  ,  indevf = @indev_mouse ;
      
      % Turn off the blink filter
      fblink.maxdur = 0 ;
      
      % Mouse input device descriptor contains constants for converting the
      % mouse position unit from pixels to visual degrees from the centre
      % of the stimulation screen
      indev = struct (  'T'  ,  MCC.SHM.EYE.COLIND.TIME  ,  ...
                       'XL'  ,  MCC.SHM.EYE.COLIND.XLEFT  ,  ...
                       'YL'  ,  MCC.SHM.EYE.COLIND.YLEFT  ) ;
      
      met ( 'printf' , 'mettarget: Using mouse as input device' , 'e' )
    
    % Eyes
    case  'e'  ,  indevf = @indev_eyes  ;
      
      % Define eye input device descriptor , start with constants
      indev.C = struct ( ...
        'MINHOR' , - SCRHOR / 2 / PIXDEG , ...
        'MINVER' , - SCRVER / 2 / PIXDEG , ...
        'MAXHOR' , + SCRHOR / 2 / PIXDEG , ...
        'MAXVER' , + SCRVER / 2 / PIXDEG , ...
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
      
      met ( 'printf' , 'mettarget: Using eye tracker as input device' , ...
        'e' )
      
    otherwise
      error ( 'MET:mettarget:INDEV' , ...
        [ 'mettarget: Unrecognised INDEV value ''' , INDEV , '''' ] )
    
  end % input device
  
  
  %%% Prepare variables %%%
  
  % Clear unneeded variables
  clear ( CLRVAR { : } )
  
  % Session descriptor
  sd = MCC.DAT.SD ;
  
  % Trial status , 0 - non running , 1 - running
  tstat = false ;
  
  % Eye positions read from shared memory
  newpos = [] ;
  
  % Currently targeted concrete stimulus index , 0 means none
  targ = 0 ;
  
  
  %%% Complete MET initialisation %%%
  
  % Send mready signal , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Report
  met (  'print'  ,  sprintf ( ...
    'MET controller %d initialised: mettarget' , MC.CD )  ,  'L'  )
  
  % Flush any outstanding messages to terminal
  met ( 'flush' )
  
  % Wait for synchronising ready signal
  [ ~ , ~ , sig ] = met ( 'recv' , WAIT_FOR_MSIG ) ;
  
  % Return if any mquit signal received
  if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
  
  % We won't use this again
  clear  WAIT_FOR_MSIG
  
  
  %%% Event loop %%%
  
  while  true
    
    % Wait for next event , return the time when we wake up
    [ tim , msig , shm ] = met ( 'select' ) ;
    
    
    %-- Get new MET signals --%
    
    if  msig
      
      % Non-blocking read
      [ ~ , ~ , sig , crg ] = met ( 'recv' ) ;
      
      % mquit received , terminate controller
      if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
      
      % mready trigger
      isig = sig  ==  MSID.mready ;
      
      if  any (  crg( isig )  ==  MC.MREADY.TRIGGER  )
        
        % Read current session directory name and trial identifier
        [ sdir , tid ] = metsdpath ;
        
        % Session directory has changed
        if  ~ strcmp (  sd.session_dir  ,  sdir  )
          
          % Load new session descriptor
          sd = metdload ( MC , MCC , sdir , tid , 'sd' , 'mettarget' ) ;
          
        end % new sess dir
        
        % Initialise trial variables. List of task stimulus indeces per
        % stimulus link. Initial hit-regions. And the set of stimulus links
        % that are currently visible. Returns pointer to current task
        % logic.
        [ lnkind , hitregion , logic , I ] = metptblink( sd , tid , shm ) ;
        
        % MET signal identifier returned
        if  ~ iscell (  lnkind  )
          
          % mquit returned , terminate immediately
          if  lnkind  ==  MSID.mquit  ,  return
            
          % mwait returned , wait for new events
          elseif  lnkind  ==  MSID.mwait  ,  continue
          end
          
        % Otherwise we got hit regions , but shm may now be out of date
        else
          
          % Refresh shm list
          [ ~ , ~ , shm ] = met ( 'select' , 0 ) ;
          
        end % MET SID returned
        
        % Take square hit region lists , return reverse translation for
        % application to eye/touchscreen positions , and un-translated
        % square
        hitregion( I ) = cellfun (  @prephitsquare  ,  hitregion( I )  ,...
          'UniformOutput'  ,  false  ) ;
        
        % Determine which task stimuli are currently shown
        state = logic.nstate { 1 } ;
        
        % Get task stimuli indeces , reverse the order , see below for
        % reason.
        istim = logic.stim.( state )( end : -1 : 1 ) ;
        
        % Send mready reply to report that this controller is ready to run
        % the new trial
        met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
        
      end % mready
      
      % Remove any mready
      sig = sig ( ~ isig ) ;
      
      % mstart received , trial is running , reset targ to task stimulus
      % 'none'
      if  any ( sig  ==  MSID.mstart )
        tstat( 1 ) = 1 ;
         targ( 1 ) = MCC.SDEF.none ;
      end
      
      % mstate received , update list of task stimuli that are currently
      % visible
      fsig = find (  sig  ==  MSID.mstate  ,  1  ,  'last'  ) ;
      
      if  fsig
        
        % Get state name
        state = logic.nstate{ crg( fsig ) } ;
        
        % Get task stimuli indeces , reverse the order , see below for
        % reason.
        istim = logic.stim.( state )( end : -1 : 1 ) ;
        
      end % mstate received
      
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
          
          % New eye positions available
          case   'eye'  ,  newpos = C { EYEIND } ;
            
          case  'stim'
            
            % Logical index of stimulus links with new hit regions
            I = C {  MCC.SHM.STIM.LINDEX  } ;
            
            % Copy the new hit regions
            hitregion( I ) = C (  MCC.SHM.STIM.HITREG : end  ) ;
            
            % Get square hit region targeting data
            hitregion( I ) = cellfun (  @prephitsquare  ,  ...
              hitregion( I )  ,  'UniformOutput'  ,  false  ) ;
          
        end % map shm output
        
      end % available shm
      
    end % read shared memory
    
    
    %-- Get currently selected point --%
    
    % Returns x and y as [] if no valid position, or returns vectors where
    % x( i ) and y( i ) give the location of the ith point. t is a scalar
    % time measurement.
    [ x , y , t , indev ] = indevf ( indev , newpos ) ;
    
    % Discard used eye samples
    if  ~ isempty (  newpos  )  ,  newpos = [] ;  end
    
    
    %-- No valid data --%
    
    % Trial not running , so continue to next event
    if  ~ tstat
      
      continue
      
    % No valid point selection available at this time
    elseif  isempty ( x )
    
      % If the blink filter is on then we suspect that a blink is why there
      % is currently no eye data available
      if  fblink.maxdur
        
        % We are monitoring the duration of an ongoing blink
        if  fblink.flag
          
          % This blink has lasted too long to be considered a blink. The
          % eyes are shut or the subject is looking off screen. We need to
          % take action if we still think that an on-screen stimulus is
          % being targeted.
          if  fblink.maxdur  <  tim - fblink.time  &&  ...
              targ  ~=  MCC.SDEF.none

            % No stimulus is being targeted
            targ = MCC.SDEF.none ;

            % Report this with an mtarget MET signal
            met (  'send'  ,  MSID.mtarget  ,  targ  ,  tim  ) ;

          end % nothing selected
          
        % This appears to be a new blink
        else

          % Raise the flag i.e. a blink is going on
          fblink.flag( 1 ) = true ;
          
          % Remember approximately when it started
          fblink.time( 1 ) = tim ;
        
        end % handle blink
        
      end % blink filter
      
      % To the next event
      continue
      
    % There is valid data and we were monitoring an ongoing blink
    elseif  fblink.flag
      
      % Lower blink filter flag , there is no longer any blink to time
      fblink.flag( 1 ) = false ;
      
    end % no valid data
    
    
    %-- Determine selected target --%
    
    % Compare each concrete stimulus against the selected point. Run
    % backwards so that the last thing drawn is on top of everything else,
    % and is the first thing hit. When the loop finally breaks, i will be
    % the index of the task stimulus that is currently selected.
    for  i = istim

      % Stimulus link indeces , if li is empty then cellfun returns nothing
      % and any returns false
      li = lnkind { i } ;
      
      % Check each linked hit region , empty matrix place holders where
      % ptb-style stimuli are absent
      hit = any ( cellfun(  @( h )  hitchk ( MCC , x , y , h )  ,  ...
        hitregion( li )  ) ) ;
      
      % Task stimulus i is being targeted by the subject
      if  hit  ,  break  ,  end
      
    end % task stimuli
    
    % This stimulus is already being targeted , continue to next event
    if  targ  ==  i  ,  continue  ,  end
    
    % Newly targeted stimulus , update selection and report with an mtarget
    % MET signal
    targ = i ;
    met (  'send'  ,  MSID.mtarget  ,  targ  ,  t  ) ;
    
  end % event loop
  
  
end % mettarget


%%% Subroutines %%%

% Reads in mettarget.csv parameter file and returns relevant parameters
function  [ VELTHR , ACCTHR , FBLINK ] = readpar
  
  % Location of metdaqeye.csv , first get containing directory then add
  % file name
  f = fileparts ( which ( 'mettarget' ) ) ;
  f = fullfile ( f , 'mettarget.csv' ) ;
  
  % Make sure that the file exists
  if  ~ exist ( f , 'file' )
    
    error ( 'MET:mettarget:csv' , 'mettarget: Can''t find %s' , f )
    
  end
  
  % Parameter name set
  PARNAM = { 'THRMUL' , 'VELTHR' , 'ACCTHR' , 'FBLINK' } ;
  
  % Numeric parameters
  NUMPAR = PARNAM ;
  
  % Read in parameters
  p = metreadcsv ( f , PARNAM , NUMPAR ) ;
  
  % Must all be values of 0 or more
  for  F = PARNAM  ,  fn = F{ 1 } ;
    
    if  ~ isscalar ( p.( fn ) )  ||  ~ isnumeric ( p.( fn ) )  ||  ...
      ~ isreal ( p.( fn ) )  ||  p.( fn ) < 0
      
      error ( 'MET:mettarget:csv' , ...
        'mettarget: %s must be a non-negative real number' , fn )
      
    end
    
  end % check params
  
  % Return scaled thresholds ...
  VELTHR = p.VELTHR  *  p.THRMUL ;
  ACCTHR = p.ACCTHR  *  p.THRMUL ;
  
  % ... and blink filter duration
  FBLINK = p.FBLINK ;
  
end % readpar


% Determines if targeting is mouse- or eye-driven according to the value of
% the metscrnpar.csv 'touch' parameter. While we're checking screen
% parameters, we can also return the stimulation screen's identifier, and
% the screen dimensions in degrees of visual angle.
function  [ INDEV , STMSCR , PIXDEG ] = readindev
  
  % Screen parameters
  p = metscrnpar ;
  
  % Touchscreen i.e. mouse-driven
  if  p.touch
    
    INDEV = 'm' ;
    
  % Eye-driven
  else
    
    INDEV = 'e' ;
    
  end
  
  % Return screen index
  if  p.screenid  ==  -1
    
    % Null screen id means that we should take the maximum index
    STMSCR = max ( Screen(  'Screens'  ) ) ;
    
  else
    
    % A valid id was provided so return that
    STMSCR = p.screenid ;
    
  end
  
  % Screen horizontal resolution
  px = Screen (  'WindowSize'  ,  STMSCR  ) ;
  
  % Compute pixels per degree
  PIXDEG = metpixperdeg (  p.width  ,  px  ,  p.subdist  ) ;
  
  
end % readindev


% Turns information about square hit regions into a reverse translation
% that is applied to eye/touchschreen positions, along with an
% un-translated square. Column order [ x-axis translation ,
% y-axis translation , cosine of clockwise rotation , sin of cwr ,
% left of square , top , right , bottom , ignore ]
function  t = prephitsquare ( h )
  

  %%% Global MET controller constants %%%
  
  global  MCC
  
  
  %%% Check input %%%
  
  % If h is empty or defines circular hit regions then return it
  % immediately
  if  isempty ( h )  ||  size ( h , 2 )  ==  6
    t = h ;
    return
  end
  
  
  %%% Convert hit region %%%
  
  % Get rectangular hit region constants
  C = MCC.SHM.STIM.RECT8 ;
  
  % Build output matrix , each row is a different square , initialised to
  % [ x-trans , y-trans , cos , sin , left , right , bottom , top , ignore]
  %         1 ,       2 ,   3 ,   4 ,    5 ,     6 ,      7 ,   8 ,      9
  t = [  -h( : , [ C.XCOORD , C.YCOORD ] )  ,  ...
         cosd( -[ h( : , C.ROTATION ) , h( : , C.ROTATION ) - 90 ] )  , ...
         h( : , C.WIDTH  ) * [ -0.5 , 0.5 ]  ,  ...
         h( : , C.HEIGHT ) * [ -0.5 , 0.5 ]  ,  ...
         h( : , C.IGNORE )  ] ;
  
	% Swap column positions of right, bottom, and top so that we return
	% PsychToolbox-style rectangles [ left , top , right , bottom ]
  t( : , 6 : 8 ) = t ( : , [ 8 , 6 , 7 ] ) ;
  
  
end % prephitsquare


% Hit-check. Return true if the selected point lands in any of the listed
% hit regions
function  hit = hitchk ( MCC , x , y , h )
  
  % Not a ptb-style stimulus , hence h is empty
  if  isempty ( h )
    hit = false ;
    return
  end
  
  % Hit regions are either rectangular (9 columns) or circular (6 columns)
  switch  size (  h  ,  2  )
    
    % Rectangular hit regions , 9 columns because of prephitsquare
    case  9
      
      % Transform selected position into 'rectangle' space , start with
      % translation then apply rotation
      P = cell2mat (  ...
            arrayfun (  ...
              @( x , y , c , s )  [ x , y ]  *  [ c , s ; -s , c ]  ,  ...
                x( 1 ) + h( : , 1 )  ,  y( 1 ) + h( : , 2 )  ,  ...
                h( : , 3 )  ,  h( : , 4 )  ,  ...
                  'UniformOutput'  ,  false  )  ) ;
      
      % Check left eye/mouse position versus hit regions
      hit = any (  h( : , 9 )  &  ...
        h( : , 5 ) <= P( : , 1 )  &  P( : , 1 ) <= h( : , 7 )  &  ...
        h( : , 8 ) <= P( : , 2 )  &  P( : , 2 ) <= h( : , 6 )  ) ;
      
      % Mouse position only returns one selected point
      if  numel ( x )  ==  1  ,  return  ,  end
      
      % Tranform right-eye position
      P = cell2mat (  ...
            arrayfun (  ...
              @( x , y , c , s )  [ x , y ]  *  [ c , s ; -s , c ]  ,  ...
                x( 2 ) + h( : , 1 )  ,  y( 2 ) + h( : , 2 )  ,  ...
                h( : , 3 )  ,  h( : , 4 )  ,  ...
                  'UniformOutput'  ,  false  )  ) ;
      
      % Two points returned by eyes , so check second point. Both points
      % must sit within the hit region for the stimulus to be selected.
      hit = hit  &&  any (  ...
        h( : , 5 ) <= P( : , 1 )  &  P( : , 1 ) <= h( : , 7 )  &  ...
        h( : , 8 ) <= P( : , 2 )  &  P( : , 2 ) <= h( : , 6 )  ) ;
      
      
    % Circular hit regions
    case  6
      
      % Circular hit region constants
      C = MCC.SHM.STIM.CIRC6 ;
      
      % Squared radii
      r2 = h( : , C.RADIUS )  .^  2 ;
      
      % Compute squared distance between selected point and centre of each
      % hit region
      d2 = ( h( : , C.XCOORD ) - x( 1 ) ) .^ 2  +  ...
           ( h( : , C.YCOORD ) - y( 1 ) ) .^ 2  ;
      
      % Hit region is selected if any distance is at most the radius
      hit = any (  h( : , C.IGNORE )  &  d2  <=  r2  ) ;
      
      % Mouse position only returns one selected point
      if  numel ( x )  ==  1  ,  return  ,  end
      
      % Two points returned by eyes , so compute squared distance of second
      % point
      d2 = ( h( : , C.XCOORD ) - x( 2 ) ) .^ 2  +  ...
           ( h( : , C.YCOORD ) - y( 2 ) ) .^ 2  ;
      
      % Both points must sit within the hit region for the stimulus to be
      % selected
      hit = hit  &&  any (  d2  <=  r2  ) ;
      
    % Internal error , wrong hit region format sent
    otherwise
      
      error ( 'MET:mettarget:hitregion' , ...
        'mettarget: unrecognised hit region format' )
    
  end % hit check
  
end % hitchk


%%% Input device functions %%%

function  [ x , y , t , indev ] = indev_mouse ( indev , mousepos )
  
  
  %%% Initialise output arguments %%%
  
  x = [] ;  y = [] ;  t = [] ;
  
  
  %%% Return position %%%
  
  % No samples provided , so there are none to select , end function
  if  isempty ( mousepos )  ,  return  ,  end
  
  % Gather the most recent sample
  x = mousepos ( end , indev.XL ) ;
  y = mousepos ( end , indev.YL ) ;
  t = mousepos ( end , indev.T  ) ;
  
  
end % indev_mouse


function  [ x , y , t , indev ] = indev_eyes ( indev , eyepos )
  
  
  %%% Constants %%%
  
  C = indev.C ;
  
  
  %%% Initialise output arguments %%%
  
  x = [] ;  y = [] ;  t = [] ;
  
  
  %%% Update buffer %%%
  
  % No samples provided , so there are none to select , end function
  if  isempty ( eyepos )  ,  return  ,  end
  
  % Number of samples received
  n = size ( eyepos , 1 ) ;
  
  % Enough samples received to fill the buffer
  if  C.BUFSIZ  <=  n
    
    % Grab them
    n = C.BUFSIZ ;
    indev.b( : , : ) = eyepos ( end - n + 1 : end , : ) ;
    
  % Fewer were received
  else
    
    % Shift old samples already in the buffer
    indev.b( 1 : end - n , : ) = indev.b ( n + 1 : end , : ) ;
    indev.v( 1 : end - n     ) = indev.v ( n + 1 : end     ) ;
    
    % Place new samples
    indev.b ( end - n + 1 : end , : ) = eyepos ;
    
  end
  
  % Check new samples for validity i.e. have not clipped to screen edge
  % along the horizontal
  n = C.BUFSIZ  -  n  +  1 ;
  i = [ C.XL , C.XR ] ;
  indev.v( n : end ) = all (  C.MINHOR  <  indev.b ( n : end , i )  &  ...
    indev.b ( n : end , i )  <  C.MAXHOR  ,  2  ) ;
  
  % Or the vertical
  i = [ C.YL , C.YR ] ;
  indev.v( n : end ) = indev.v( n : end )  &  ...
    all (  C.MINVER  <  indev.b ( n : end , i )  &  ...
      indev.b ( n : end , i )  <  C.MAXVER  ,  2  ) ;
  
  
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

