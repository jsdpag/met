
function  [ type , vpar , init , stim , close , chksum ] = rfmaptool ( ~ )
% 
% [ type , vpar , init , close , stim , chksum ] = rfmaptool ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Manual receptive field mapping tool. Allows the user to control a
% stimulus on screen using a mouse. The stimulus appears when the left
% mouse button is pressed, and disappears when that button is released. If
% the right mouse button is pressed then the stimulus appears and remains
% on screen until the left or right mouse button is pressed. The middle
% button ( usually the mouse wheel ) drops/grabs the stimulus ; click once,
% this doesn't need to be held down.
% 
% The main number keys (above letters) are used to switch between stimulus
% types: 1 - bar , 2 - gabor , 3 - dot patch.
%
% For any stimulus, press the 'h' key to see the current parameters, such
% as location or orientation. Only prints when the stimulus is visible.
% 
% Stimulus keyboard controls
% 
%   Bar - The [ and ] keys decrease/increase height. If shift key is also
%     held down then the width is changed. With the control key, the
%     greyscale value is changed. The mouse wheel is used change the angle
%     of the bar, hold shift to change faster.
%   
%   Gabor - Without any modifier keys, the [ and ] keys decrease and
%     increase the width of the Gaussian. With a shift key down, they
%     decrease and increase the Michelson contrast against a mid-grey
%     background. With the control key down, the speed of motion of the
%     sinusoid is increased or decreased. The mouse wheel changes the angle
%     of the gabor, without modifiers. With the shift key, it changes the
%     phase of the sinusoid, and with the control key it changes the
%     sinusoidal frequency.
%   
%   Dot patch - Without modifiers, the [ and ] keys decrease and increase
%     the radius of the dot patch. With shift, these change the dot
%     density. With control, these change the dot diameters. With shift and
%     control together, these change the dot contrast against a mid-grey
%     background. The mouse wheel changes the rotation of the patch, hence
%     also the direction of motion. With shift, the speed of motion is
%     changed. With control, the disparity of all dots is changed.
%   
%   RF border lines - These are always available, regardless of stimulus
%     selection. The tool can draw lines onto the stimulus screen in a
%     colour that is known to be filtered out of the image by some means
%     before it is seen by the subject (e.g. by removing that colour
%     channel from the video signal). Line colour can be set by the colour
%     property, which is set to 1 for red, 2 for green, and 3 for blue
%     (default). Hitting the Alt key once creates a new line with one end
%     stuck to the spot where the mouse cursor was at the time of the key
%     press. The other end of the line tracks the mouse around until Alt is
%     hit a second time, at which point the end of the line remains where
%     it was at the time of the key press. Any number of lines can be
%     added. All lines will be deleted if the Backspace key is hit.
% 
% There is an additional null parameter that can be used to create a MET
% task variable for cases when nothing needs to vary from trial to trial.
% 
% Written by Jackson Smith - March 2017 - DPAG , University of Oxford
% 
  
  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Null variable parameter set
  vpar = {    'null'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
            'colour'  ,  'i'  ,  3     ,   1    ,   3    } ;
  
  % Function handles
	 init = @finit ;
   stim = @fstim ;
  close = @fclose ;
 chksum = @fchksum ;
  
end % rfmaptool


%%% Stimulus definition handles %%%

% Trial initialisation function
function  S = finit ( vpar , tconst , Sold )
  

  %%% Constants %%%
  
  % Mouse button indices , and minimum duration from right-clicking
  % stimulus on until it can be turned off.
  C.LEFT = 1 ;
  C.MIDDLE = 2 ;
  C.RIGHT = 3 ;
  C.TGATE = 0.15 ;
  
  % Stimulus selection key codes, 1 to 9
  STMKEY = { '1!' , '2@' , '3#' , '4$' , '5%' , '6^' , '7&' , '8*' , ...
    '9(' } ;
  C.STMKEY = arrayfun ( @KbName , STMKEY ) ;
  
  % Help key
  C.HLPKEY = KbName ( 'h' ) ;
  
  % Modifier keys
  C.SHIFT = [ KbName( 'LeftShift' ) , KbName( 'RightShift' ) ] ;
  C.CTRL = [ KbName( 'LeftControl' ) , KbName( 'RightControl' ) ] ;
  C.ALT = [ KbName( 'LeftAlt' ) , KbName( 'RightAlt' ) ] ;
  C.BRACKET = [ KbName( '[{' ) , KbName( ']}' ) ] ;
  C.BACK = KbName ( 'BackSpace' ) ;
  
  % Screen parameters
  p = metscrnpar ;
  
  % Remember the horizontal and vertical mirroring flags
  C.HMIRROR = p.hmirror ;
  C.VMIRROR = p.vmirror ;
  
  % RF border line colour
  C.LINCOL = [ 0 , 0 , 0 ] ;
  
  % Choose colour channel
  C.LINCOL( vpar.colour ) = 1 ;
  
  % Line width , in pixels
  C.LINWID = 5 ;
  
  
  %%% Build descriptor %%%
  
  % If Sold is empty then this is the first time that this stimulus is
  % being used in this session , so create a brand new descriptor.
  % Otherwise, return the old one.
  if  ~ isempty ( Sold )
    S = Sold ;
    return
  end
  
  % General form of descriptor , meant to accommodate switching between
  % different kinds of stimulus. x and y give the central location of the
  % stimulus. i is the index saying which stimulus to use. on is a scalar
  % logical that says whether the stimulus is currently visible. stmtim is
  % the last frame time that the stimulus selection was changed. rbtime is
  % the expected presentation time of the frame that responds to the right
  % mouse button. scrarg is a cell array with an element for each stimulus
  % that contains a cell array with input arguments needed by PTB Screen to
  % draw the stimulus. stmpar is a cell array of structs, each one tracking
  % the specific parameters of each stimulus type. stmfun is a cell array
  % of function handles, one for each stimulus type. hitregion is the ptb
  % hit region field, initialised to be a null square. C field has
  % constants. frame is the number of the last frame that the stimulus was
  % drawn in. drop is true when the mouse position should be ignored.
  % linflg tracks whether a RF border line is being defined. linxy is the
  % set of start and end points of all RF border lines. cursor is the
  % current x-y location of the mouse , for drawing a small mouse cursor
  % dot in the blue channel when no stimulus is on.
  S = struct ( 'C' , C , 'cursor' , [ 0 ; 0 ] , 'x' , tconst.wincentx , ...
    'y' , tconst.wincenty , 'b' , [] , 'w' , [] , 'keys' , [] ,'i' , 1 ,...
    'on' , false , 'drop' , false , 'stmtim' , 0 , 'rbtime' , 0 , ...
    'frame' , -1 , 'scrarg' , [] , 'stmpar' , [] , 'stmfun' , [] , ...
    'hitregion' , zeros( 1 , 8 ) , 'linflg' , false , 'linxy' , [] ) ;
  
  
  %%% Initialise each stimulus %%%
  
  % Total number of stimuli available
  N = 1 ;
  
  % Make cell arrays
  S.scrarg = cell ( N , 1 ) ;
  S.stmpar = cell ( N , 1 ) ;
  S.stmfun = cell ( N , 1 ) ;
  S.shelpf = cell ( N , 1 ) ;
  
  % Initialise stimulus index
  i = 0 ;
  
  
  %-- Bar --%
  
  % Bar is a rectangle drawn using FillPoly, because it must support any
  % rotation of the square
  scrarg = { 'FillPoly' , tconst.winptr , 1 , zeros( 4 , 2 ) , 1 } ;
  
  % There is a .square field that keeps the rotated but untranslated square
  % ready for translation to the central point. scaling factor is
  % multiplied or divided from width or height when it is changed. drotat
  % is the number of degrees to change by for each step of the mouse wheel.
  stmpar = struct ( 'width' , tconst.pixperdeg * 4 , ...
    'height' , tconst.pixperdeg * 0.5 , 'rotation' , 0 , ...
    'square' , zeros( 4 , 2 ) , 'scaling' , 1.1 , 'drotat' , 5 , ...
    'grey' , 1 , 'dgrey' , 0.05 , ...
    'shift' , C.SHIFT , 'ctrl' , C.CTRL  , 'bracket' , C.BRACKET ) ;
  
  % Make initial base square
  stmpar.square = [  stmpar.width   *  [ -0.5 , -0.5 , +0.5 , +0.5 ]  ;
                     stmpar.height  *  [ -0.5 , +0.5 , +0.5 , -0.5 ]  ]' ;
  scrarg{ 4 } = stmpar.square ;
  
  % Store properties
  i = i + 1 ;
  S.scrarg{ i } = scrarg ;
  S.stmpar{ i } = stmpar ;
  S.stmfun{ i } = @stim_bar ;
  S.shelpf{ i } = @help_bar ;
  
  
  %-- Gabor --%
  
  % Screen max dimention
  smxdim = max( [ tconst.winwidth , tconst.winheight ] ) ;
  
  % All gabor parameters with delta values. I is an index struct for
  % symbolic indexing of scrarg. Note speed is visual degres/sec ; we get
  % the phase change by visual degrees/sec * pix/v.deg. * cycles/pix (freq)
  % * 360deg/cycle
  stmpar = struct ( 'gwid' , 1.5 * smxdim , ...
    'gabor' , [] , 'grect' , [] , ...
    'angle' , 270 , 'dangle' , 5 , 'phase' , 0 , 'dphase' , 20 , ...
      'freq' , 1 / tconst.pixperdeg , 'dfreq' , 1.1 , ...
      'sigma' , tconst.pixperdeg , 'dsigma' , 1.1 , ...
      'contrast' , 1 , 'dcontrast' , 0.05 , ...
      'speed' , 0 , 'dspeed' , 0.05 , 'pspeed' , 0 , ...
    'I' , struct( 'rect' , 5 , 'angle' , 6 , 'aux' , 12 , 'phase' , 1 , ...
      'freq' , 2 , 'sigma' , 3 , 'contrast' , 4 ) , ...
    'shift' , C.SHIFT , 'ctrl' , C.CTRL , 'bracket' , C.BRACKET ) ;
  
  % Create Psych Toolbox procedural gabor object
  [ stmpar.gabor , stmpar.grect ] = CreateProceduralGabor ( ...
    tconst.winptr , stmpar.gwid , stmpar.gwid , 0 , ...
    [ 0.5 , 0.5 , 0.5 , 0.0 ] , 1 , 0.5 ) ;
  
  % Screen input arguments , will draw a gabor with given properties
  scrarg = { 'DrawTexture' , tconst.winptr , stmpar.gabor , [] , ...
    stmpar.grect , stmpar.angle , [], [] , [ 1 , 1 , 1 , 0 ] , [] , ...
    kPsychDontDoRotation , [ stmpar.phase , stmpar.freq , stmpar.sigma , ...
    stmpar.contrast , 1 , 0 , 0 , 0 ] } ;
  
  % Store properties
  i = i + 1 ;
  S.scrarg{ i } = scrarg ;
  S.stmpar{ i } = stmpar ;
  S.stmfun{ i } = @stim_gabor ;
  S.shelpf{ i } = @help_gabor ;
  
  
  %-- Dot patch --%
  
  % Dot maximum and default density , dots per square degree of visual
  % field
  maxden = 200 ;
  defden = 5 ;
  
  % Maximum and default radius in degrees of visual field
  maxrad = smxdim / 2 / tconst.pixperdeg ;
  defrad = 2 ;
  
  % Maximum and default number of dots in a patch with smxdim / 2 radius
  N = ceil ( pi * maxrad ^ 2  *  maxden ) ;
  n = ceil ( pi * defrad ^ 2  *  defden ) ;
  
  % Be aware that the internal representation of dots is in a normalised
  % coordinate system with a patch of radius 1
  stmpar = struct ( 'N' , N , 'n' , n , ...
    'maxden' , maxden , 'maxrad' , maxrad , ...
    'minwid' , [] , 'maxwid' , [] , ...
      'radius' , defrad , 'dradius' , 1.1 , ...
        'pixrad' , defrad * tconst.pixperdeg , ...
      'density' , defden , 'ddensity' , 0.5 , ...
      'contrast' , 1 , 'dcontrast' , 0.025 , ...
      'width' , 0.2 , 'dwidth' , 0.005 , ...
      'direction' , 0 , 'ddirection' , 5 , ...
        'cossin' , cosd ( [ 0 , -90 ] ) , ...
      'speed' , 0 , 'dspeed' , 0.1 , 'normspeed' , 0 , ...
      'disparity' , 0 , 'ddisparity' , 0.01 , 'pixdisp' , 0 , ...
    'pos' , zeros ( 2 , N ) , 'col' , zeros ( 3 , N ) , ...
    'rad' , zeros ( 1 , N , 'single' ) , ...
    'blendfun' , { { 'BlendFunction' , tconst.winptr , ...
      GL_SRC_ALPHA , GL_ONE_MINUS_SRC_ALPHA } } , ...
    'shift' , C.SHIFT , 'ctrl' , C.CTRL , 'bracket' , C.BRACKET , ...
    'I' , struct( 'pos' , 3 , 'wid' , 4 , 'col' , 5 , 'centre' , 6 ) ) ;
  
  % Retrieve minimum and maximum possible dot size and convert to degrees
  % of visual field
  [ stmpar.minwid , stmpar.maxwid ] = Screen( 'DrawDots' , tconst.winptr );
  stmpar.minwid = stmpar.minwid  /  tconst.pixperdeg ;
  stmpar.maxwid = stmpar.maxwid  /  tconst.pixperdeg ;
  
  % Sample positions of initial dot set
  stmpar.pos( : , 1 : n ) = rndpos ( 0 , 1 , n ) ;
  
  % Compute radius of each dot
  stmpar.rad( 1 : n ) = sum (  stmpar.pos( : , 1 : n )  .^  2  )  .^  0.5 ;
  
  % Initialise colour matrix
  stmpar.col( : , 1 : 2 : end ) = 1 ;
  stmpar.col = stmpar.col  -  0.5 ;
  
  % Screen drawing instructions
  scrarg = { 'DrawDots' , tconst.winptr , stmpar.pos( : , 1 : n ) , ...
    stmpar.width * tconst.pixperdeg , stmpar.col( : , 1 : n ) + 0.5 , ...
    [ 0 , 0 ] , 2 } ;
  scrarg{ 3 } = stmpar.pixrad  *  scrarg{ 3 } ;
  
  % Store properties
  i = i + 1 ;
  S.scrarg{ i } = scrarg ;
  S.stmpar{ i } = stmpar ;
  S.stmfun{ i } = @stim_dots ;
  S.shelpf{ i } = @help_dots ;
  
  
end % finit


% Stimulation function
function  [ S , h ] = fstim ( S , tconst , tvar )


  %%% Presentation status %%%
  
  % Eye buffer is monoscopic or left-eye
  eyeflg = tvar.eyebuf  <  1 ;
  
  % Time since last event
  tgate = S.rbtime + S.C.TGATE  <  tvar.ftime ;
  
  % Only check input devices and events if on the monoscopic or left eye
  % buffer
  if  eyeflg
  
  
    %-- Input device status --%

    % We must gather information about the mouse ...
    [ x , y , S.b , S.w ] = metgetmouse ;

    % ... and keyboard
    [ ~ , ~ , S.keys ] = KbCheck ;
    
    
    %-- Mirroring compensation --%
    
    % Horizontal mirroring applied , reflext mouse x-axis position across
    % centre of screen
    if  S.C.HMIRROR  ,  x = tconst.winwidth   -  x ;  end

    % Vertical mirroring applied , reflect mouse y-axis position across
    % centre of screen
    if  S.C.VMIRROR  ,  y = tconst.winheight  -  y ;  end
    
    % Remember the mouse position for cursor drawing
    S.cursor( : ) = [ x ; y ] ;
    

    %-- Permanent presentation status (right mouse button) --%

    % Determine whether stimulus stays on. If it is on, any button is
    % clicked, and sufficient time has passed since it turned on ...
    if  S.on  &&  any ( S.b(  [  S.C.LEFT  ,  S.C.RIGHT  ]  ) )  &&  tgate

      % ... then turn the stimulus off
      S.on = false ;

      % Remember when this happened
      S.rbtime = tvar.ftime ;

    % Stimulus is off and the right mouse button is clicked ...
    elseif  S.b ( S.C.RIGHT )  &&  ~ S.on  &&  tgate

      % ... then keep stimulus on
      S.on = true ;

      % Remember when this happened
      S.rbtime = tvar.ftime ;

    end % presentation status


    %-- Drop/grab --%

    % Grab stimulus if it is currently dropped, middle button is down, and
    % enough time has passed since last mouse event
    if  S.drop  &&  S.b ( S.C.MIDDLE )  &&  tgate

      % Disable dropped stimulus
      S.drop = false ;

      % Remember when
      S.rbtime = tvar.ftime ;

    % Drop the stimulus if middle button is down, stimulus is grabbed, and
    % enough time since last mouse event
    elseif  S.b ( S.C.MIDDLE )  &&  ~ S.drop  &&  tgate

      % Drop stimulus
      S.drop = true ;

      % Remember when
      S.rbtime = tvar.ftime ;

    end % drop/grab stim


    %-- Stimulus selection --%

    % Find which, if any, stimulus selection key is being pressed
    j = find (  S.keys ( S.C.STMKEY )  ,  1  ,  'first'  ) ;

    % A key is down, and some time has passed since the last selection
    if  ~ isempty ( j )  &&  S.stmtim + S.C.TGATE  <  tvar.ftime

      % Assign newly selected stimulus
      S.i = min (  [  j  ,  numel( S.scrarg )  ]  ) ;

      % Remember selection time
      S.stmtim = tvar.ftime ;

    end % new stimulus
    
    
    %-- RF border lines --%
    
    % Backspace is down
    if  S.keys ( S.C.BACK )  &&  tgate
      
      % Remove all lines
      S.linxy = [] ;
      
      % Lower line flag
      S.linflg = false ;
      
      % Remember when this happened
      S.rbtime = tvar.ftime ;
      
    % Alt key is down
    elseif  any ( S.keys(  S.C.ALT  ) )  &&  tgate
      
      % No line is being defined
      if  ~ S.linflg
        
        % Add another pair of end points at current mouse location
        S.linxy = [ S.linxy , [ x , x ; y , y ] ] ;
        
      end % select action
      
      % Flip flag value
      S.linflg = ~ S.linflg ;
      
      % Remember when this happened
      S.rbtime = tvar.ftime ;
      
    end % RF border lines
    
    % Line is being defined , update end point
    if  S.linflg  ,  S.linxy( : , end ) = [ x ; y ] ;  end
    
    
  % Right-eye buffer
  else
    
    % Current x and y values from storage
    x = S.x ;  y = S.y ;

  end % monoscopic or left-eye buffer
  
  
  %-- No stimulus presentation --%
  
  % If neither the stimulus is on nor is the left button down then quit
  if  ~ S.b ( S.C.LEFT )  &&  ~ S.on
    
    % If this is the first frame since we last presented the stimulus then
    % we need to return a null hit region i.e. give it zero height and
    % width. Only do this for monoscopic/left-eye frame buffer.
    if  eyeflg  &&  S.frame + 1  ==  tvar.frame
      h = true ;
      S.hitregion( 1 : 4 ) = 0 ;
    else
      h = false ;
    end
    
    % Draw RF border lines
    S = rfborder ( S , tconst ) ;
    
    % Draw a blue point to show where the mouse is , for when the mouse
    % cursor is hidden in the PTB window
    Screen ( 'DrawDots' , tconst.winptr , S.cursor , 3 , [ 0 , 0 , 1 ] ) ;
    
    % Quit
    return
    
  end % no presentation
  
  
  %%% Update stimulus %%%
  
  % Stimulus is dropped or drawing to right-eye frame buffer , x and y
  % don't change
  if  S.drop  ,  x = S.x ;  y = S.y ;  end
  
  % Package input device data
  indev = struct ( 'x' , x , 'y' , y , 'dx' , x - S.x , 'dy' , y - S.y ,...
    'w' , S.w , 'keys' , S.keys , 'first' , S.frame < tvar.frame - 1 ) ;
  
  % Current stimulus index
  i = S.i ;
  
  % Help requested
  if  S.keys ( S.C.HLPKEY )  &&  tgate
    
    % Compute centre of stimulus in degrees of visual field
    x = ( indev.x  -  tconst.wincentx )  /  tconst.pixperdeg ;
    y = ( tconst.winheight - indev.y - tconst.wincenty )  /  ...
      tconst.pixperdeg ;
    
    % Print message
    S.shelpf{ i }(  tconst  ,  x  ,  y  ,  S.stmpar{ i }  )
    
    % Remember time
    S.rbtime = tvar.ftime ;
    
  end
  
  % Frame number of current presentation
  S.frame = tvar.frame ;
  
  % Update stimulus position
  S.x = x ;  S.y = y ;
  
  % Update selected stimulus
  [ S.scrarg{ i } , S.stmpar{ i } , hit ] = S.stmfun{ i } ( tconst , ...
    tvar , indev , S.scrarg{ i } , S.stmpar{ i } ) ;
  
  % Hit region updated
  h = ~ isempty ( hit ) ;
  
  if  h  ,  S.hitregion = hit ;  end
  
  
  %%% Draw stimulus %%%
  
  Screen (  S.scrarg{ i }{ : }  ) ;
  
  
  %%% Draw RF border lines %%%
  
  S = rfborder ( S , tconst ) ;
  
  % Draw the cursor if the stimulus is on and dropped
  if  S.on  &&  S.drop
    Screen ( 'DrawDots' , tconst.winptr , S.cursor , 3 , [ 0 , 0 , 1 ] ) ;
  end
  
  
end % fstim


% Trial closing function
function  S = fclose ( S , type )
  
  % Switch on closure type
  switch  type
  
    % Closing trial
    case  't'
      
      % Need to reset frame number
      S.frame = -1 ;
  
    % Closing session
    case  's'
      
      % Release procedural gabor
      Screen ( 'Close' , S.stmpar{ 2 }.gabor ) ;
  
  end % closure type
  
end % close


% Check-sum function
function  c = fchksum ( ~ )
  
  c = 0 ;
  
end % chksum


%%% Stimulus help functions %%%

% Prints current properties
function  help_bar ( tconst , x , y , stmpar )
  
  % Gather location and size parameters , convert to degrees of visual
  % field
  w = stmpar.width   /  tconst.pixperdeg ;
  h = stmpar.height  /  tconst.pixperdeg ;
  
  % Rotation
  r = mod ( stmpar.rotation , 180 ) ;
  
  % Greyscale
  g = stmpar.grey ;
  
  % Build help string
  s = sprintf ( [ 'Bar stimulus properties\n' , ...
                  '    x-coord: %0.2f deg\n' , ...
                  '    y-coord: %0.2f deg\n' , ...
                  '      width: %0.2f deg\n' , ...
                  '     height: %0.2f deg\n' , ...
                  '   rotation: %0.2f deg\n' , ...
                  '  greyscale: %0.2f norm 0-1' ] , ...
                  x , y , w , h , r , g ) ;
  
	% Print message
  met ( 'print' , s , 'e' )
  
end % help_bar


% Prints current properties of gabor
function  help_gabor ( tconst , x , y , stmpar )
  
  % Gather parameters , convert to degrees of visual field when necessary.
  % We add 90 degrees to angle before mod because the procedural gabor
  % seems to interpret angle relative to the axis along which the sinusoid
  % varies ; hence angle of 0 has the grating oriented at 90. We want to
  % report orientation of the grating.
  ang = mod ( stmpar.angle + 90 , 360 ) ;
  pha = mod ( stmpar.phase , 360 ) ;
  fre = stmpar.freq  *  tconst.pixperdeg ;
  sig = stmpar.sigma  /  tconst.pixperdeg ;
  con = stmpar.contrast ;
  spe = stmpar.speed ;
  
  % Build help string
  s = sprintf ( [ 'Gabor stimulus properties:\n' , ...
                  '       x-coord: %0.2f deg\n' , ...
                  '       y-coord: %0.2f deg\n' , ...
                  '   orientation: %0.2f deg\n' , ...
                  '  phase of sin: %0.2f deg\n' , ...
                  '   freq of sin: %0.2f cycles/deg\n' , ...
                  '  Gauss. sigma: %0.2f deg\n' , ...
                  '      contrast: %0.2f\n' , ...
                  '  speed of sin: %0.2f deg/sec' ] , ...
                  x , y , ang , pha , fre , sig , con , spe ) ;
                
	% Print message
  met ( 'print' , s , 'e' )
  
end % help_gabor


% Prints current properties of dot patch
function  help_dots ( ~ , x , y , stmpar )
  
  % Gather parameters
  rad = stmpar.radius ;
  den = stmpar.density ;
  con = stmpar.contrast ;
  wid = stmpar.width ;
  dir = mod ( stmpar.direction , 360 ) ;
  spe = stmpar.speed ;
  dis = stmpar.disparity ;
  
  % Build help string
  s = sprintf ( [ 'Dot patch stimulus properties:\n' , ...
                  '       x-coord: %0.2f deg\n' , ...
                  '       y-coord: %0.2f deg\n' , ...
                  '  patch radius: %0.2f deg\n' , ...
                  '   dot density: %0.2f dots/deg^2\n' , ...
                  '  dot contrast: %0.2f\n' , ...
                  '  dot diameter: %0.2f deg\n' , ...
                  '    motion dir: %0.2f deg\n' , ...
                  '         speed: %0.2f deg/sec\n' , ...
                  '     disparity: %0.2f deg' ] , ...
                  x , y , rad , den , con , wid , dir , spe , dis ) ;
                
	% Print message
  met ( 'print' , s , 'e' )
  
end % help_dots


%%% Stimulus drawing functions %%%

% Each of these must return updated screen arguments, stimulus parameters,
% and hit regions. Thus, each must receive older versions of the argument
% and parameters, and receive trial constants and variables. Must also take
% indev, a struct with info about mouse and keyboard ; indev.x and .y is
% the latest position in PTB coordinates, indev.dx and .dy is the change in
% position since the last frame, indev.w is the current value of the mouse
% wheel, indev.keys is a logical vector of the on/off status of all keys,
% indev.first is true if this is the first frame that the stimulus is being
% presented on since it disappeared.

% Bar stimulus drawing function
function  [ scrarg , stmpar , hitregion ] = ...
  stim_bar ( tconst , tvar , indev , scrarg , stmpar )
  
  % Blending command
  Screen ( 'BlendFunction' , tconst.winptr , GL_ONE , GL_ZERO ) ;

  % There is nothing to update for the right-eye frame buffer
  if  tvar.eyebuf  ==  1
    hitregion = [] ;
    return
  end
  
  
  %%% User input %%%
  
  % Look to see if any shift key is down
  shift = any (  indev.keys ( stmpar.shift )  ) ;
  
  % Look to see if any control key is down
  ctrl = any (  indev.keys ( stmpar.ctrl  )  ) ;
  
  % Or whether the left ( 1 ) or right ( 2 ) bracket key is down
  bracket = indev.keys (  stmpar.bracket  ) ;
  
  % If only one bracket key is down then the size will change
  bkdflg = sum (  bracket  )  ==  1 ;
  
  % If the bar has not changed size or position then change nothing
  if  ~ indev.dx  &&  ~ indev.dy  &&  ~ indev.w  &&  ~ bkdflg
    
    % However , if this is the first frame of presentation then make a new
    % hit region
    if  indev.first
      hitregion = mkhitreg ( tconst , indev , ...
        stmpar.width , stmpar.height , stmpar.rotation ) ;
    else
      hitregion = [] ;
    end
    
    return
    
  end % No updates
  
  
  %%% Update square properties %%%
  
  % Change size of bar
  if  bkdflg  &&  ~ ( shift  &&  ctrl )
    
    % Control key is down , change greyscale
    if  ctrl
      
      % Left bracket, decrease greyscale
      if  bracket ( 1 )
        
        stmpar.grey = stmpar.grey  -  stmpar.dgrey ;
        stmpar.grey = max ( [ 0 , stmpar.grey ] ) ;
        
      % Right bracket , increase greyscale
      else
        
        stmpar.grey = stmpar.grey  +  stmpar.dgrey ;
        stmpar.grey = min ( [ 1 , stmpar.grey ] ) ;
        
      end
      
      % Assign to drawing instructions
      scrarg{ 3 } = stmpar.grey ;
      
    % Change size of bar
    else
    
      % Choose which parameter to change
      if  shift
        p = 'height' ;
      else
        p = 'width' ;
      end

      % Left bracket , decrease size
      if  bracket ( 1 )

        stmpar.( p ) = stmpar.( p )  /  stmpar.scaling ;

      % Right bracket , increase size
      elseif  bracket ( 2 )

        stmpar.( p ) = stmpar.( p )  *  stmpar.scaling ;

      end
    
    end % greyscale or size
    
  end % change size
  
  % Change rotation of bar
  if  indev.w
    
    % New angle
    stmpar.rotation = stmpar.rotation  +  ...
      ( 1 + shift )  *  stmpar.drotat  *  indev.w ;
    
  end % rotation
  
  
  %%% Update base square %%%
  
  % If size or rotation has changed
  if  bkdflg  ||  indev.w
    
    % Get vertices of un-rotated square
    V = [  stmpar.width   *  [ -0.5 , -0.5 , +0.5 , +0.5 ]  ;
           stmpar.height  *  [ -0.5 , +0.5 , +0.5 , -0.5 ]  ]' ;
    
    % Cosine and sine values for this rotation
    cs = cosd ( [ stmpar.rotation , stmpar.rotation - 90 ] ) ;
    
    % Apply rotation , this is actually a clockwise rotation because of the
    % PTB coordinate system
    stmpar.square = V  *  [ cs( 1 ) , -cs( 2 ) ;
                            cs( 2 ) ,  cs( 1 ) ] ;
    
  end % new base square
  
  
  %%% Update Screen input args %%%
  
  % Only need to change vertices
  scrarg{ 4 } = [  indev.x + stmpar.square( : , 1 )  ,  ...
                   indev.y + stmpar.square( : , 2 )  ] ;
	
	
	% New hit region
  hitregion = mkhitreg ( tconst , indev , ...
    stmpar.width , stmpar.height , stmpar.rotation ) ;
  
  
end % stim_bar


% Checks user input for any changes to gabor parameters, which are stored
% and set in Screen input parameter list.
function  [ scrarg , stmpar , hitregion ] = ...
  stim_gabor ( tconst , tvar , indev , scrarg , stmpar )
  
  % Blending command
  Screen ( 'BlendFunction' , tconst.winptr , GL_ONE , GL_ZERO ) ;
  
  % There is nothing to update for the right-eye frame buffer
  if  tvar.eyebuf  ==  1
    hitregion = [] ;
    return
  end
  
  
  %%% User input %%%
  
  % scrarg index map
  I = stmpar.I ;
  
  % Look to see if any shift key is down
  shift = any (  indev.keys ( stmpar.shift )  ) ;
  
  % Look to see if any control key is down
   ctrl = any (  indev.keys ( stmpar.ctrl  )  ) ;
  
  % Or whether the left ( 1 ) or right ( 2 ) bracket key is down
  bracket = indev.keys (  stmpar.bracket  ) ;
  
  % If only one bracket key is down then the size will change
  bkdflg = sum (  bracket  )  ==  1 ;
  
  % Change in position or size , or first frame of presentation. Make new
  % hit region.
  if  indev.dx  ||  indev.dy  ||  indev.first  ||  ...
      ( bkdflg  &&  ~ shift  &&  ~ ctrl  )
    
    hitregion = mkhitreg ( tconst , indev , 2 * stmpar.sigma , ...
      2 * stmpar.sigma , 0 ) ;
    
  else
    
    hitregion = [] ;
    
  end
  
  % The user has not changed anything about the gabor
  if  ~ indev.dx  &&  ~ indev.dy  &&  ~ indev.w  &&  ~ bkdflg
    
    % However, the sinusoid is in motion
    if  stmpar.pspeed
      stmpar.phase = stmpar.phase  +  stmpar.pspeed ;
      scrarg{ I.aux }( I.phase ) = stmpar.phase ;
    end
    
    return
    
  end % No updates
  
  
  %%% Update gabor properties %%%
  
  
  %-- New position --%
  
  if  indev.dx  ||  indev.dy
    
    % Recentre gabor rectangle on new position
    scrarg{ I.rect } = CenterRectOnPointd ( stmpar.grect , ...
      indev.x , indev.y ) ;
    
  end
  
  
  %-- Mouse wheel slide --%
  
  % Assume no change in frequency
  frqflg = false ;
  
  % Mouse wheel was rolled
  if  indev.w
    
    % If no modifier down then change angle. Shift changes phase. Control
    % changes frequency.
    if  shift  &&  ctrl
      
      % Do nothing
      
    elseif  shift
      
      % Shift down , change phase
      stmpar.phase = stmpar.phase  +  stmpar.dphase  *  indev.w ;
      scrarg{ I.aux }( I.phase ) = stmpar.phase ;
      
    elseif  ctrl
      
      % Control down , change frequency. Increase if wheel is positive.
      % Decrease otherwise
      if  0  <  indev.w
        stmpar.freq = stmpar.freq  *  stmpar.dfreq ;
      else
        stmpar.freq = stmpar.freq  /  stmpar.dfreq ;
      end
      
      % New frequency given to drawing instructions
      scrarg{ I.aux }( I.freq ) = stmpar.freq ;
      
      % Raise new frequency flag
      frqflg = true ;
      
    else
      
      % No modifier , change angle
      stmpar.angle = stmpar.angle  +  stmpar.dangle  *  indev.w ;
      scrarg{ I.angle } = stmpar.angle ;
      
    end % modifier keys
    
  end % mouse wheel
  
  
  %-- Bracket key down --%
  
  % Assume no acceleration
  accflg = false ;
  
  % One bracket key is down
  if  bkdflg
    
    % Decide which parameter to change. If shift is up then change Gaussian
    % sigma, otherwise change contrast.
    if  shift  &&  ctrl
      
      % Do nothing if both modifiers are down
      
    elseif  shift
      
      % Left bracket, reduce contrast if there is anything to reduce
      if  bracket ( 1 )  &&  stmpar.contrast
        
        stmpar.contrast = stmpar.contrast  -  stmpar.dcontrast ;
        stmpar.contrast = max ( [ 0 , stmpar.contrast ] ) ;
        
      % Right bracket, increase contrast if not reached 1
      elseif  stmpar.contrast  <  1
        
        stmpar.contrast = stmpar.contrast  +  stmpar.dcontrast ;
        stmpar.contrast = min ( [ 1 , stmpar.contrast ] ) ;
        
      end
      
      % Assign new contrast
      scrarg{ I.aux }( I.contrast ) = stmpar.contrast ;
      
    elseif  ctrl
      
      % Left bracket , decrease speed
      if  bracket ( 1 )

        stmpar.speed = stmpar.speed  -  stmpar.dspeed ;
        stmpar.speed = max ( [ 0 , stmpar.speed ] ) ;

      % Right bracket , increase speed
      else

        stmpar.speed = stmpar.speed  +  stmpar.dspeed ;

      end

      % Raise acceleration flag
      accflg = true ;
      
    else
      
      % Left bracket , reduce Gaussian sigma
      if  bracket ( 1 )
        
        stmpar.sigma = stmpar.sigma  /  stmpar.dsigma ;
        
      % Right bracket , increase sigma
      else
        
        stmpar.sigma = stmpar.sigma  *  stmpar.dsigma ;
        
      end
      
      % Assign new sigma
      scrarg{ I.aux }( I.sigma ) = stmpar.sigma ;
      
    end % shift modifier
    
  end % bracket key
  
  
  %-- Sinusoid motion --%
  
  % Change in speed or frequency means that we need to compute how many
  % degrees of phase shift will produce the desired motion, per frame.
  if  frqflg  ||  accflg
    
    % Speed is in visual degres/sec ; we get the phase change by visual
    % degrees/sec * sec/frame * pix/v.deg. * cycles/pix (freq) *
    % 360deg/cycle
    stmpar.pspeed = stmpar.speed * tconst.flipint * tconst.pixperdeg * ...
      stmpar.freq * 360 ;
    
  end % convert speed to degrees / second
  
  % Sinusoid is moving
  if  stmpar.pspeed
    
    % Add to phase
    stmpar.phase = stmpar.phase  +  stmpar.pspeed ;
    scrarg{ I.aux }( I.phase ) = stmpar.phase ;
    
  end % sinusoid motion
  
  
end % stim_gabor


% Updates the parameters for one dot patch

%   Dot patch - Without modifiers, the [ and ] keys decrease and increase
%     the radius of the dot patch. With shift, these change the dot
%     density. With control, these change the dot diameters. With shift and
%     control together, these change the dot contrast against a mid-grey
%     background. The mouse wheel changes the rotation of the patch, hence
%     also the direction of motion. With shift, the speed of motion is
%     changed. With control, the disparity of all dots is changed.

function  [ scrarg , stmpar , hitregion ] = ...
  stim_dots ( tconst , tvar , indev , scrarg , stmpar )
  
  % Guarantee that the correct blending function is in use
  Screen (  stmpar.blendfun{ : }  ) ;
  
  % Symbolic indices for scrarg
  I = stmpar.I ;
  
  % Initialise hitregion to empty
  hitregion = [] ;
  
  % Initialise position change flag , raised if we need to recompute dot
  % positions in scrarg
  posflg = false ;
  
  % Radius changed flag
  radflg = false ;
  
  % Only update internal parameters when drawing to monoscopic or left-eye
  % frame buffer
  if  tvar.eyebuf  <  1
  
    
    %%% User input %%%
    
    % Look to see if any shift key is down
    shift = any (  indev.keys ( stmpar.shift )  ) ;

    % Look to see if any control key is down
     ctrl = any (  indev.keys ( stmpar.ctrl  )  ) ;

    % Or whether the left ( 1 ) or right ( 2 ) bracket key is down
    bracket = indev.keys (  stmpar.bracket  ) ;

    % If only one bracket key is down then the size will change
    bkdflg = sum (  bracket  )  ==  1 ;
    
    
    %-- Bracket keys --%
    
    if  bkdflg
      
      % shift + control keys down
      if  shift  &&  ctrl
        
        % Left bracket key , decrease contrast
        if  bracket ( 1 )
          
          stmpar.contrast = stmpar.contrast  -  stmpar.dcontrast ;
          stmpar.contrast = max ( [ 0 , stmpar.contrast ] ) ;
          
        % Right bracket key , increase contrast
        else
          
          stmpar.contrast = stmpar.contrast  +  stmpar.dcontrast ;
          stmpar.contrast = min ( [ 1 , stmpar.contrast ] ) ;
          
        end % changed contrast
        
        % Update contrast matrix
        scrarg{ I.col } = ...
          stmpar.contrast * stmpar.col( : , 1 : stmpar.n )  +  0.5 ;
        
      % control key only
      elseif  ctrl
        
        % Left bracket key , decrease dot width
        if  bracket ( 1 )
          
          stmpar.width = stmpar.width  -  stmpar.dwidth ;
          stmpar.width = max ( [ stmpar.minwid , stmpar.width ] ) ;
          
        % Right bracket key , increase dot width
        else
          
          stmpar.width = stmpar.width  +  stmpar.dwidth ;
          stmpar.width = min ( [ stmpar.maxwid , stmpar.width ] ) ;
          
        end % changed width
        
        scrarg{ I.wid } = stmpar.width  *  tconst.pixperdeg ;
        
      % shift key only
      elseif  shift
        
        % Left bracket key , decrease density
        if  bracket ( 1 )
          
          stmpar.density = stmpar.density  -  stmpar.ddensity ;
          stmpar.density = max ( [ 0 , stmpar.density ] ) ;
          
          % Compute the number of dots on screen
          n = ceil ( pi * stmpar.radius ^ 2  *  stmpar.density ) ;
          n = max ( [ 1 , n ] ) ;
          stmpar.n = min ( [ n , stmpar.n ] ) ;
          
          
          % Reduce the position matrix in Screen drawing instructions
          scrarg{ I.pos } = scrarg{ I.pos }( : , 1 : stmpar.n ) ;
          scrarg{ I.col } = scrarg{ I.col }( : , 1 : stmpar.n ) ;
          
        % Right bracket key , increase density
        else
          
          stmpar.density = stmpar.density  +  stmpar.ddensity ;
          stmpar.density = min ( [ stmpar.maxden , stmpar.density ] ) ;
          
          % Compute the number of dots on screen
          n = ceil ( pi * stmpar.radius ^ 2  *  stmpar.density ) ;
          n = min ( [ n , stmpar.N ] ) ;
          
          % The number of dots has increased
          if  stmpar.n  <  n
            
            % Calculate the number of new dots , delta n
            dn = n  -  stmpar.n ;
            
            % Vector of new dot indices
            i = stmpar.n + 1 : n ;
            
            % Sample new dot positions
            stmpar.pos( : , i ) = rndpos ( 0 , 1 , dn ) ;
            
            % And compute their radii , unless there is any motion
            if  ~ stmpar.speed
              stmpar.rad( i ) = ...
                (  sum(  stmpar.pos( : , i )  .^  2  )  )  .^  0.5 ;
            end
            
            % Save new number
            stmpar.n = n ;
            
            % Update contrast matrix
            scrarg{ I.col } = ...
              stmpar.contrast * stmpar.col( : , 1 : stmpar.n )  +  0.5 ;
            
            % Raise position recalculation flag
            posflg = true ;
            
          end % increased dots
          
        end % change density
        
      % No modifiers
      else
        
        % Left bracket key , decrease radius
        if  bracket ( 1 )
          
          % New radius
          rnew = stmpar.radius  /  stmpar.dradius ;
          
          % Normalise new radius relative to the old
          rnrm = rnew  /  stmpar.radius ;
          
          % Find dots that still sit within new radius
          i = stmpar.rad( 1 : stmpar.n )  <=  rnrm ;
          
          % And those that don't
          ni = ~ i ;
          
          % Count number of kept dots
          n = sum ( i ) ;
          
          % Only delete dots if at least one remains
          if  n
            
            % Re-order dot buffer positions
            stmpar.pos( : , 1 : stmpar.n ) = ...
              [  stmpar.pos( : , i )  ,  stmpar.pos( : , ni )  ] ;
            stmpar.col( : , 1 : stmpar.n ) = ...
              [  stmpar.col( : , i )  ,  stmpar.col( : , ni )  ] ;
            stmpar.rad( 1 : stmpar.n ) = ...
              [  stmpar.rad( i )  ,  stmpar.rad( ni )  ] ;

            % And get subset of dots for Screen input args
            scrarg{ I.pos } = scrarg{ I.pos }( : , i ) ;
            scrarg{ I.col } = scrarg{ I.col }( : , i ) ;
          
          % No dots are kept
          else
            
            % Sample one dot
            n = 1 ;
            stmpar.pos( : , 1 ) = rndpos ( 0 , rnew , n ) ;
            scrarg{ I.col } = scrarg{ I.col }( : , 1 ) ;
            posflg = true ;
            
          end
          
          % Remember new radius
          stmpar.radius = rnew ;
          
          % Save number of kept dots
          stmpar.n = n ;
          
          % Adjust internal dot positions to offset decrease in radius
          stmpar.pos( : , 1 : stmpar.n ) = ...
            stmpar.pos( : , 1 : stmpar.n )  *  stmpar.dradius ;
          
          % Increase remaining radii proportionally
          stmpar.rad( 1 : stmpar.n ) = stmpar.rad( 1 : stmpar.n )  *  ...
            stmpar.dradius ;
          
          % Radius changed
          radflg = true ;
          
        % Right bracket key , increase radius
        else
          
          % New radius
          rnew = stmpar.radius  *  stmpar.dradius ;
          rnew = min ( [ stmpar.maxrad , rnew ] ) ;
          
          % The radius has increased
          if  stmpar.radius  <  rnew
          
            % Compute the number of dots on screen with new radius
            n = ceil ( pi * rnew ^ 2  *  stmpar.density ) ;
            n = min ( [ n , stmpar.N ] ) ;
            
            % Calculate the change in dot number i.e. the number of dots
            % added
            dn = n  -  stmpar.n ;
            
            % Normalise old radius relative to the new
            rnrm = stmpar.radius  /  rnew ;
            
            % Index vector for new dots
            i = stmpar.n + 1 : n ;
            
            % Sample new dot positions
            stmpar.pos( : , i ) = rndpos ( rnrm , 1 , dn ) ;
            
            % And compute their radii , if there is no motion
            if  ~ stmpar.speed
              stmpar.rad( i ) = ...
                (  sum(  stmpar.pos( : , i )  .^  2  )  )  .^  0.5 ;
            end
            
            % Adjust internal dot positions to offset increase in radius
            stmpar.pos( : , 1 : stmpar.n ) = ...
              stmpar.pos( : , 1 : stmpar.n )  *  rnrm ;
          
            % Reduce radii of old dots proportionally
            stmpar.rad( 1 : stmpar.n ) = ...
              stmpar.rad( 1 : stmpar.n )  *  rnrm ;
            
            % Save new number
            stmpar.n = n ;
            
            % Update contrast matrix
            scrarg{ I.col } = ...
              stmpar.contrast * stmpar.col( : , 1 : stmpar.n )  +  0.5 ;
            
            % Remember new radius
            stmpar.radius = rnew ;
            
            % Raise position recalculation flag
            posflg = true ;
            
            % Radius changed
            radflg = true ;

          end % increased radius
          
        end % change radius
        
        % Radius changed
        if  radflg
          
          % Convert from visual degrees to pixels
          stmpar.pixrad = stmpar.radius  *  tconst.pixperdeg ;
          
          % Recompute normalised motion step per frame with new radius
          stmpar.normspeed = ...
            stmpar.speed  *  tconst.flipint  /  stmpar.radius ;
          
        end % radius changed
        
      end % modifiers
      
    end % one bracket key down
    
    
    %-- Mouse wheel --%
    
    if  indev.w
      
      if  shift  &&  ctrl
        
        % Do nothing
        
      % Control only , and in stereoscopic mode
      elseif  ctrl
        
        if tconst.stereo
        
          % New disparity
          stmpar.disparity = stmpar.disparity  +  ...
            stmpar.ddisparity  *  indev.w ;

          % Compute number of pixels of offset between left and right eye
          % image
          stmpar.pixdisp = stmpar.disparity  *  tconst.pixperdeg ;

          % Raise position recalculation flag
          posflg = true ;
        
        end % stereo mode
        
      % Shift only
      elseif  shift
        
        % New speed
        stmpar.speed = stmpar.speed  +  stmpar.dspeed  *  indev.w ;
        stmpar.speed = max ( [ 0 , stmpar.speed ] ) ;
        
        % Recompute normalised motion step with new radius
        stmpar.normspeed = ...
          stmpar.speed  *  tconst.flipint  /  stmpar.radius ;
        
      % No modifier
      else
        
        % New direction
        stmpar.direction = stmpar.direction  +  stmpar.ddirection  *  indev.w ;
        
        % Get cos and sin value for this angle
        stmpar.cossin = cosd ( stmpar.direction - [ 0 , 90 ] ) ;
        
        % Raise position recalculation flag
        posflg = true ;
        
      end % modifiers
      
    end % mouse wheel
    
    
    %%% Apply motion %%%
    
    if  stmpar.speed
      
      % Index vector
      i = 1 : stmpar.n ;
      
      % Add normalised horizontal motion step to all dots
      stmpar.pos( 1 , i ) = stmpar.pos( 1 , i )  +  stmpar.normspeed ;
      
      % Recompute radii
      stmpar.rad( i ) = (  sum( stmpar.pos( : , i )  .^  2 )  )  .^  0.5 ;
      
      % Find dots that have fallen out of patch
      j = 1  <  stmpar.rad( i ) ;
      
      while  any ( j )
      
        % Number of fallen dots
        n = sum ( j ) ;

        % Give them random vertical positions
        stmpar.pos( 2 , j ) = 2 * rand( 1 , n )  -  1 ;

        % And compute corresponding horizontal positions on left edge of
        % circle
        stmpar.pos( 1 , j ) = ...
          - (  1  -  stmpar.pos( 2 , j ) .^ 2  )  .^  0.5 ;

        % Add a random amount of normalised motion step
        stmpar.pos( 1 , j ) = stmpar.pos( 1 , j )  +  ...
          stmpar.normspeed  *  rand ( 1 , n ) ;

        % And compute new radii
        stmpar.rad( j ) = ...
          (  sum( stmpar.pos( : , j )  .^  2 )  )  .^  0.5 ;
        
        % Find dots that have fallen out of patch
        j( j ) = 1  <  stmpar.rad( j ) ;
      
      end % fallen dots
      
      % Raise position recalculation flag
      posflg = true ;
      
    end % motion
    
    
    %%% Recalculate dot pixel positions %%%
    
    if  posflg
      
      % Cos and sin values for this direction
      c = stmpar.cossin ( 1 ) ;
      s = stmpar.cossin ( 2 ) ;
      
      % User clockwise rotation matrix to get counter-clockwise rotation,
      % because of PTB coordinate system. Scale up dot positions by radius.
      scrarg{ I.pos } = [ c , s ; -s , c ]  *  ...
        stmpar.pos ( : , 1 : stmpar.n )  *  stmpar.pixrad;
      
      % There is disparity in stereoscopic mode , shift to left-eye
      % position
      if  tconst.stereo  &&  stmpar.disparity
        
        scrarg{ I.pos }( 1 , : ) = scrarg{ I.pos }( 1 , : )  -  ...
          stmpar.pixdisp  /  2 ;
        
      end
      
    end % posflg
    
    
    %%% Patch position %%%
    
    if  indev.dx  ||  indev.dy
      
      scrarg{ I.centre } = [  indev.x  ,  indev.y  ] ;
      
    end
    
    
    %%% Hit region %%%
    
    % Position of dot patch has moved or radius has changed , or its the
    % first presentation frame since mouse button press
    if  radflg  ||  indev.dx  ||  indev.dy  ||  indev.first
      
      hitregion = mkhitreg ( tconst , indev , 2 * stmpar.radius , ...
        2 * stmpar.radius , 0 ) ;
      
    end
    
  end % monoscopic or left-eye frame buffer
  
  
  %%% Apply disparity %%%
  
  % Only apply if in stereoscopic mode , and if posflg is low. If posflg is
  % up then disparity already applied.
  if  ~ tconst.stereo  ||  posflg  ,  return  ,  end
  
  switch  tvar.eyebuf
  
    % Drawing to left-eye buffer , shift image to the left. Negative
    % disparity dots will go to the right.
    case  0  ,  scrarg{ I.pos }( 1 , : ) = scrarg{ I.pos }( 1 , : )  -  ...
                  stmpar.pixdisp ;
      
    % Drawing to the right eye buffer , shift image to the right. Negative
    % disparity dots will go to the left.
    case  1  ,  scrarg{ I.pos }( 1 , : ) = scrarg{ I.pos }( 1 , : )  +  ...
                  stmpar.pixdisp ;
      
  end % eye buffer
  
  
end % stim_dots


%%% Subroutines %%%

% Draw RF border lines
function  S = rfborder ( S , tconst )
  
  % No lines available , draw nothing
  if  isempty ( S.linxy )  ,  return  ,  end

  % Draw blue receptive/response field lines , and only blue. Don't touch
  % the red or green channels! [ FAULTY ]
  Screen (  'BlendFunction' ,  tconst.winptr ,  'GL_ONE' ,  'GL_ONE'  ) ;
  
  % Draw to frame buffer
  Screen ( 'DrawLines' , tconst.winptr , S.linxy , S.C.LINWID , ...
    S.C.LINCOL ) ;
  
end % rfborder


% For calculating the current hit region
function  hit = mkhitreg ( tconst , indev , w , h , r )

  % Make hit region array
  hit = [ indev.x , indev.y , w , h , r , 0 , 0 , 0 ] ;
  
  % Convert to Cartesian coordinate system centred in middle of screen
  hit( 1 ) = hit ( 1 )  -  tconst.wincentx ;
  hit( 2 ) = tconst.winheight - hit ( 2 )  -  tconst.wincenty ;
  
  % Convert from pixels to degrees of visual field
  hit( 1 : 4 ) = hit ( 1 : 4 )  /  tconst.pixperdeg ;
  
end % mkhitreg


% Random dot positions , returns 2 by n matrix with x-coordinates in first
% row and y-coordinates in the second row , each column defines one dot.
% rmin and rmax give the minimum and maximum radius that a dot may have.
% Uniformly distributed within specified radii.
function  pos = rndpos ( rmin , rmax , n )
  
  % rmin squared
  rmnsq = rmin  ^  2 ;
  
  % Convert from real number on [ 0 , 1 ] into an angle ...
  theta = 2 * pi * rand( 1 , n ) ;
  
  % ... and radius
  radius = (  ( rmax ^ 2 - rmnsq ) * rand( 1 , n )  +  rmnsq  )  .^  0.5 ;
    
  % Polar to cartesian coordinates
  pos = [  radius .* cos( theta )  ;  radius .* sin( theta )  ] ;
  
end % randdotxy

