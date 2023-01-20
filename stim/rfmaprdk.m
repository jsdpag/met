
function  [ type , vpar , init , stim , close , chksum ] = rfmaprdk ( ~ )
% 
% [ type , vpar , init , stim , close , chksum ] = rfmaprdk ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Draws a mouse-controlled random-dot kinetogram on screen. By default, the
% rdk is always visible. But visibility can be toggled on and off by
% clicking the left mouse button. The mouse-wheel changes the orientation
% of the rdk ; the direction of coherent dot motion is orientation + 90
% degrees. If the shift key is held down then the mouse wheel changes the
% speed of motion, and if the control key is down then the mouse wheel
% changes the size of the rdk. Hitting the space key will print a readout
% of current rdk parameters in the terminal window such that it will be
% saved by any log file that is opened by metptb. Dots are 100% coherent.
% There are no dot lifetimes. Half of the dots are white, the other half
% are black. Circular dots. Mouse positions are mirrored when the stimulus
% screen has mirroring enabled. This makes the stimulus behave like a
% normal cursor on the stimulus screen ; keep in mind that the subject sees
% the mirror image.
% 
% Variable parameters
% 
% Null - This can be used to define a null task variable if none are
%   actually required.
% 
% maxwidth - The maximum diameter of the rdk patch, in degrees of visual
%   field. Default 12.
% 
% dot_width - The diameter of a dot in degrees of visual field. This will
%   be capped to the minimum or maximum dot width that the hardware
%   supports. Default 0.2.
% 
% dot_density - The fraction of the rdk patch that is covered with dots,
%   assuming no dot overlap. Default 0.25.
% 
% init_width - Initial diameter of rdk in degrees of visual field. Cannot
%   exceed maxwidth. Default 2. 
% 
% init_speed - Initial speed of coherent motion in degrees per second.
%   Default 1.
% 
% init_orientation - Initial orientation of rdk in degrees. Default 0.
% 
% click_enable - If non-zero then the left mouse button is used to toggle
%   visibility on and off. Otherwise the left mouse button is ignored and
%   the 'visible' variable parameter must be used to change visibility.
%   Default 1.
% 
% visible - If non-zero then the stimulus is drawn, otherwise no stimulus
%   appears on screen. Default 1.
% 
% Note that all MET stimulus events requesting a change to variable
% parameters during a trial will be ignored. Parameters may only change on
% initialisation of a new trial. Exceptions include click_enable and
% visible variable parameters.
% 
% Written by Jackson Smith - November 2017 - DPAG , University of Oxford
% 
  

  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set
  vpar = {  'Null'  , 'f' ,  0.00  , -Inf , +Inf ;
         'maxwidth' , 'f' , 12.00  ,    0 , +Inf ;
        'dot_width' , 'f' ,  0.20  ,    0 , +Inf ;
      'dot_density' , 'f' ,  0.25  ,    0 , +Inf ;
       'init_width' , 'f' ,  2.00  ,    0 , +Inf ;
       'init_speed' , 'f' ,  1.00  ,    0 , +Inf ;
 'init_orientation' , 'f' ,  0.00  , -Inf , +Inf ;
     'click_enable' , 'i' ,  1     ,  0   ,  1   ;
          'visible' , 'i' ,  1     ,  0   ,  1   } ;
            
  % Function handles
	 init = @finit ;
   stim = @fstim ;
  close = @fclose ;
 chksum = @fchksum ;
  

end % rfmaprdk


%%% Stimulus definition handles %%%

% Trial initialisation function
function  S = finit ( vpar , tconst , S_old )
  
  
  %%% Error check %%%
  
  if  vpar.maxwidth  <  vpar.init_width
    
    error ( 'MET:rfmaprdk:init_width' , ...
      'rfmaprdk:init_width may not exceed maxwidth' )
    
  end % error check
  
  
  %%% Return old stimulus descriptor %%%
  
  % We don't want to write-over our stimulus descriptor unless the variable
  % parameters have changed
  if  ~ isempty ( S_old )
    
    % Check each valid parameter
    for  F = S_old.h.C_VPAR
      
      % Inequality
      if  S_old.h.vp.( F{ 1 } )  ~=  vpar.( F{ 1 } )
        
        % Delete old data handle
        delete ( S_old.h )
        
        % And empty old stimulus descriptor
        S_old = [] ;
        
      end % inequality
      
    end % check var pars
    
    % At this point , if S_old is not empty then there was no change in var
    % pars and we can return immediately. Otherwise we need to set up a
    % whole new stimulus descriptor. Remember to update click_enable and
    % visible variable parameters, and internal visibility parameter.
    if  ~ isempty ( S_old )
      S = S_old ;
      S.h.vp.click_enable( 1 ) = vpar.click_enable ;
      S.h.vp.visible( 1 ) = vpar.visible ;
      S.h.v( 1 ) = vpar.visible ;
      return
    end
    
  end % old stimulus descriptor available
  
  % If we got this far then we need to make a new data handle
  S.h = rfmaprdk_handle ;
  
  % Point to it
  h = S.h ;
  
  
  %%% Constant initialisation %%%
  
  % Variable parameters
  h.vp = vpar ;
  
  % Circular hit region column indeces
  h.C_C6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  C6 = h.C_C6 ;
  

  %%% Initialise rdk parameters %%%
  
  % Initialise dynamic parameters
  h.orientation( 1 ) = h.vp.init_orientation ;
  h.speed( 1 ) = h.vp.init_speed ;
  h.width( 1 ) = h.vp.init_width ;
  
  % Normalised distance of dot travel per frame. Fraction of a RDK diameter
  % per frame: deg/sec * sec/frame * widths/deg. Times 2 to enter
  % normalised space.
  h.dnorm( 1 ) = 2  *  h.speed  *  tconst.flipint  /  h.width ;
  
  % Rotation matrix
  
    % Direction of motion
    d = h.orientation  +  90 ;

    % Calculate new rotation matrix , negative of orientation to
    % accound for PTB coordinate system. Plus 90 degrees to get
    % direction of motion.
    h.mrot( [ 1 , 4 ] ) = cosd ( d ) ;
    h.mrot( [ 2 , 3 ] ) = [ -1 , 1 ] * sind ( d ) ;
  
  % Set internal visibility parameter to match variable parameter
  h.v( 1 ) = h.vp.visible ;
  
  % Load screen parameters if mirror flags not yet obtained
  p = metscrnpar ;

  % Save values
  h.hmirror = p.hmirror ;
  h.vmirror = p.vmirror ;
  
  % Minimum and maximum dot width
  [ h.dotmin( 1 ) , h.dotmax( 1 ) ] = ...
    Screen ( 'DrawDots' , tconst.winptr ) ;
  
  % Compute dot width in pixels
  h.dotwid( 1 ) = h.vp.dot_width  *  tconst.pixperdeg ;
  
  % Cap to min or max
  if  h.dotwid  <  h.dotmin
    h.dotwid( 1 ) = h.dotmin ;
  elseif  h.dotwid  >  h.dotmax
    h.dotwid( 1 ) = h.dotmax ;
  end
  
  % Compute area of one dot
  h.adot( 1 ) = pi  *  ( h.dotwid  /  2 ) ^ 2 ;
  
  % Radius of rdk in pixels
  h.rrdk( 1 ) = tconst.pixperdeg  *  h.vp.init_width  /  2 ;
  
  % Compute area of rdk
  h.ardk( 1 )    = ( tconst.pixperdeg  *  h.vp.init_width )  ^  2 ;
  h.ardkmax( 1 ) = ( tconst.pixperdeg  *  h.vp.maxwidth   )  ^  2 ;
  
  % Number of dots in rdk
  h.ndot( 1 ) = round (  h.ardk  /  h.adot  *  h.vp.dot_density  ) ;
  h.ndotmax( 1 ) = round (  h.ardkmax  /  h.adot  *  h.vp.dot_density  ) ;
  
  % Linear index to used buffer positions
  h.idot = zeros ( h.ndot , 1 , 'uint16' ) ;
  h.idot( : ) = 1 : h.ndot ;
  
  % Dot buffers
  h.nxy = zeros ( 2 , h.ndotmax , 'single' ) ;
    
  % Actual location in degrees of visual field from the centre
  h.xy = zeros ( 2 , h.ndotmax ) ;

  % Colour lookup table values. Rows indexed by r, g, b, a and columns by
  % dot.
  h.clut = zeros ( 4 , h.ndotmax ) ;
  
  % Initialise normalised dot positions. Between -1 and 1 in both axes.
  h.nxy( : ) = 2 * rand ( 2 , h.ndotmax )  -  1 ;
  
  % Transform to pixel coordinates
  h.xy( : ) = h.rrdk  *  h.nxy ;
  
  % Alternate white and black dots
  h.clut( 1 : 3 , 1 : 2 : end ) = 1 ;
  h.clut( 1 : 3 , 2 : 2 : end ) = 0 ;
  
  % Dots that are within normalised radius of 1 of rdk centre are visible
  h.clut( 4 , : ) = sqrt( sum(  h.nxy .^ 2  ,  1  ) )  <=  1 ;
  
  % Initial values
  h.hitregion( C6.xcoord   ) = 0   ;
  h.hitregion( C6.ycoord   ) = 0   ;
  h.hitregion( C6.radius   ) = h.width  /  2 ;
  h.hitregion( C6.disp     ) = 0 ;
  h.hitregion( C6.dtoler   ) = 0.5 ;
  h.hitregion( C6.ignore   ) = 0 ;
  
  % Point to hitregion
  S.hitregion = h.hitregion ;
  
  % Attempt to clear any mouse-related buffers , particularly the mouse
  % wheel
  [ ~ , ~ , ~ , ~ ] = metgetmouse ;
  
  
end % finit


% Stimulation function
function  [ S , hit ] = fstim ( S , tconst , tvar )
  
  
  %%% Update stimulus appearance %%%
  
  % Data handle
  h = S.h ;
  
  % Hit region update not expected by default
  hit = false ;
  
  % Monoscopic mode or left-eye buffer is being drawn to
  if  tvar.eyebuf < 1
    
    % Any variable parameters changed?
    if  ~ isempty ( tvar.varpar )
      
      % Loop change requests
      for  i = 1 : size( tvar.varpar , 1 )
        
        % Must act on click_enable or visible parameters
        switch  tvar.varpar{ i , 1 }
          
          % Update internal parameter
          case  'visible'
            
            h.vp.visible( 1 ) = tvar.varpar{ i , 2 } ;
            h.v( 1 ) = h.vp.visible ;
            
          case  'click_enable'
            
            h.vp.click_enable( 1 ) = tvar.varpar{ i , 2 } ;
           
          % No other variable parameter changes are allowed
          otherwise
            continue
            
        end % click_enable or visible change
        
      end % change requests
      
    end % variable parameter change
    
    % Get state of the mouse
    [ x , y , b , w ] = metgetmouse ;
    
    % See the state of the keyboard
    [ ~ , ~ , k ] = KbCheck ;
    
    % Measure the time
    h.t( 1 ) = GetSecs ;
    
    
    % Is left mouse button being clicked?
    if  h.vp.click_enable  &&  b( h.C_LEFT )
      
      % Has minimum duration passed?
      if  h.C_MINDUR  <=  h.t - h.tclick
        
        % Yes , save new time and leave flag raised
        h.tclick( 1 ) = h.t ;
        
        % And swap visibility state
        h.v( 1 ) = ~ h.v ;
        
        % Mirror visibility state in variable parameter
        h.vp.visible( 1 ) = h.v ;
        
      end % min dur
      
    end % left mouse click
    
    
    % RDK is visible
    if  h.v
      
      % Horizontal mirroring
      if  h.hmirror  ,  x = tconst.winwidth   -  x ;  end
      
      % Vertical mirroring
      if  h.vmirror  ,  y = tconst.winheight  -  y ;  end
      
      % Position change
      if  h.crdk( 1 ) ~= x  ||  h.crdk( 2 ) ~= y
      
        % New location
        h.xcenter( 1 ) = +( x - tconst.wincentx )  /  tconst.pixperdeg ;
        h.ycenter( 1 ) = -( y - tconst.wincenty )  /  tconst.pixperdeg ;

        % Load new location as rdk centre , in pixels
        h.crdk( : ) = [ x , y ] ;
        
        % New hit region
        hit( 1 ) = 1 ;
      
      end % position change
      
      % Low speed and width flags
      speedflg = false ;
      widthflg = false ;
      
      % Mouse wheel clicks are buffered , update dynamic parameters
      if  w
        
        % State of modifier keys
        modshift = any (  k( h.C_SHIFT )  ) ;
        modctrl  = any (  k( h.C_CTRL  )  ) ;
        
        % No mod keys , change the orientation
        if  ~ modshift  &&  ~ modctrl
          
          % Update orientation
          h.orientation( 1 ) = ...
            mod (  h.C_dORIENT * w  +  h.orientation  ,  360  ) ;
          
          % Normalise between +/- 180 degrees
          if  180  <  h.orientation
            h.orientation( 1 ) = h.orientation  -  360 ;
          end
          
          % Direction of motion
          d = h.orientation  +  90 ;
          
          % Calculate new rotation matrix , negative of orientation to
          % accound for PTB coordinate system. Plus 90 degrees to get
          % direction of motion.
          h.mrot( [ 1 , 4 ] ) = cosd ( d ) ;
          h.mrot( [ 2 , 3 ] ) = [ -1 , 1 ] * sind ( d ) ;
        
        % Shift key down , change speed
        elseif  modshift  &&  ~ modctrl
          
          % New speed
          h.speed( 1 ) = max ( [  0  ,  h.C_dSPEED * w  +  h.speed  ] ) ;
          
          % Raise speed flag
          speedflg( 1 ) = 1 ;
          
        % Control key down , change width
        elseif  ~ modshift  &&  modctrl
          
          % New width
          nwid = max ( [  0  ,  h.C_dWIDTH * w  +  h.width  ] ) ;
          nwid( 1 ) = min ( [  h.vp.maxwidth  ,  nwid  ] ) ;
          
          % Change in width
          if  h.width  ~=  nwid
            
            % Assign new width
            h.width( 1 ) = nwid ;
            
            % Degrees to pixels
            nwid( 1 ) = tconst.pixperdeg  *  nwid ;
            
            % New rdk radius in pixels
            h.rrdk( 1 ) = nwid  /  2 ;
            
            % Calculate area
            h.ardk( 1 ) = nwid  ^  2 ;
  
            % Number of dots in rdk
            h.ndot( 1 ) = min ( [  h.ndotmax  ,  ...
              round(  h.ardk  /  h.adot  *  h.vp.dot_density )  ] ) ;
            
            % New dot index vector
            h.idot = zeros ( h.ndot , 1 , 'uint16' ) ;
            h.idot( : ) = 1 : h.ndot ;
            
            % Raise speed and width flags
            speedflg( 1 ) = 1 ;
            widthflg( 1 ) = 1 ;

            % Raise hit flag
            hit( 1 ) = 1 ;
            
          end % change in width
          
        end % mod keys
        
        % Alter normalised speed
        if  speedflg
          
          % Normalised speed
          h.dnorm( 1 ) = 2  *  h.speed  *  tconst.flipint  /  h.width ;
          
        end % change norm speed
        
      end % dynamic params
      
      % Update hit region
      if  hit
        
        % Hit region column mapping
        C6 = h.C_C6 ;
        
        h.hitregion( C6.xcoord ) = h.xcenter ;
        h.hitregion( C6.ycoord ) = h.ycenter ;
        h.hitregion( C6.radius ) = h.width  /  2 ;
        
        % Point to new hitregion
        S.hitregion = h.hitregion ;
        
      end % new hit region
      
      % Point to dot index vector
      idot = h.idot ;
      
      % Dots are moving
      if  h.speed
        
        % Apply horizontal step to dots in normalised space
        h.nxy( 1 , idot ) = h.nxy( 1 , idot )  +  h.dnorm ;
        
        % Find all dots that fell off the edge
        j = 1  <  h.nxy( 1 , idot ) ;
        
        % Sample new positions for them
        h.nxy( : , j ) = rand ( 2 , sum( j ) ) ;
        
        % x-coordinate should be some random amount inwards from the left
        % hand side , scaled by normalised step
        h.nxy( 1 , j ) = h.dnorm * h.nxy( 1 , j )  -  1 ;
        
        % The y-coordinate scales between -1 and 1
        h.nxy( 2 , j ) = 2 * h.nxy( 2 , j )  -  1 ;
        
        % Check visibility
        h.clut( 4 , idot ) = ...
          sqrt( sum(  h.nxy( : , idot ) .^ 2  ,  1  ) )  <=  1 ;
        
      end % moving dots
      
      % We need to transform normalised to pixel coordinates
      if  h.speed  ||  widthflg
        
        h.xy( : , idot ) = h.mrot  *  ( h.rrdk .* h.nxy( : , idot ) ) ;
        
      end % normalised to pixels
      
    end % visible rdk
    
    
    % Report the RDK's dynamic parametsr
    if  k( h.C_SPACE )
      
      % If enough time has passed to print a new readout
      if  h.C_MINDUR  <=  h.t - h.tspace
        
        % Build output string
        str = sprintf (  [ 'rfmaprdk: x %0.2f, y %0.2f, width %0.2f, ' ,...
          'speed %0.2f, orient %0.2f' ]  ,  ...
            h.xcenter - tconst.origin( 1 )  ,  ...
              h.ycenter - tconst.origin( 2 ) ,  ...
                h.width  ,  h.speed  ,  h.orientation  ) ;
        
        % Print output string to standard error and log file
        met ( 'print' , str , 'E' )
      
        % And remember approximately when it was printed
        h.tspace( 1 ) = h.t ;
        
      end % print readout
      
    end % Space is down
    
    
  end % update appearance
  
  
  %%% Draw to frame buffer %%%
  
  % Not visible , return now
  if  ~ h.v  ,  return  ,  end
  
  % Enable alpha blending for drawing dots
  Screen (  'BlendFunction'  ,  tconst.winptr  ,  ...
    'GL_SRC_ALPHA'  ,  'GL_ONE_MINUS_SRC_ALPHA'  ) ;
  
  % Point to dot buffer
  i = h.idot ;
  
  % Draw the dots
  Screen (  'DrawDots'  ,  tconst.winptr  ,  h.xy( : , i )  ,  ...
    h.dotwid  ,  h.clut( : , i )  ,  h.crdk  ,  2  ) ;
  
  
end % fstim


% Trial closing function
function  S = fclose ( S , type )
  
  % How do we want to close the function?
  switch  type
    
    % Trial , do nothing and return the descriptor as is
    case  't'
      
    % Session
    case  's'
      
      % Delete data handle
      delete ( S.h )
      
      % Return empty
      S = [] ;
      
    % Not recognised
    otherwise
      
      error ( 'MET:rfmaprdk:type' , 'rfmaprdk:fclose:invalid type given' )
      
  end % closure type
  
end % close


% Check-sum function
function  c = fchksum ( ~ )
  
  c = 0 ;
  
end % chksum

