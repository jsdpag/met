
function  [ type , vpar , init , stim , close , chksum ] = circle ( rfdef )
% 
% [ type , vpar , init , close , stim , chksum ] = circle ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Draws a single, empty circle on screen, primarily for choice target.
% 
% Variable parameters
%
%   x_coord - Horizontal (x-axis) coordinate to the centre of the circle.
%     In degrees of visual field from the trial origin. Left is negative,
%     right is positive. Default 0. 
%   
%   y_coord - Vertical (x-axis) coordinate to the centre of the circle. In
%     degrees of visual field from the trial origin. Down is negative, up
%     is positive. Default 0.
% 
%   fradius - Formation radius, in degrees of visual field. The circle will
%     be placed on the edge of a formation circle with this radius that is
%     centred on x_coord and y_coord. This allows the circle to orbit
%     around the given point. Default 0.
%   
%   fangle - Formation angle, in degrees. The angle between the line
%     running from the centre of the formation circle to the circle and a
%     line parallel to the x-axis that also passes through the centre of
%     the circle. Default 0.
% 
%   fflip - Formation flip. The location of the circle on the formation
%     circle can be flipped an additional 180 degrees from fangle. This is
%     done for values less than zero. For values of zero or more, fangle is
%     used. This is mainly intended to be used in conjunction with positive
%     and negative coherences in a random-dot stimulus , allowing the empty
%     circle to serve as a choice target.
% 
%   disp - Disparity of the circle relative to the trial origin, in degrees
%     of visual field. Default 0.
%   
%   radius - Radius of the visible circle around the given x and y
%     coordinate, in degrees of visual field. Default 0.75.
%   
%   hradius - Radius from the centre of the circle defining a hit region.
%     If the subject selects a point within this region then the circle is
%     considered to be selected. In degrees of visual field. Default 0.75.
%   
%   hdisptol - Hit region disparity tolerance. Convergence may differ from
%     circle's disparity by up to this much for the subject to select the
%     stimulus. In degrees of visual field. Default 0.5.
%     
%   
%   linwid - Width of the line that draws the edge of the circle, in
%     degrees of visual field. Default 0.3.
%   
%   shade - The greyscale value applied to the edge of the circle,
%     normalised between 0 and 1. This is the value used when the flash
%     rate is 0 i.e. flashing is off. Default 0.8.
%   
%   frate - Flash rate of the circle edge greyscale, in cycles per second.
%     Set to 0 to disable flashing and use the greyscale given in 'shade'.
%     When flashing, greyscale changes sinusoidally between 0 and 1.
%     Default 0.
% 
% Written by Jackson Smith - April 2017 - DPAG , University of Oxford
% 
  
  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set
  vpar = {  'x_coord'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
            'y_coord'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
            'fradius'  ,  'f'  ,  4.5   ,     0  ,  +Inf  ;
             'fangle'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
              'fflip'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
               'disp'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
             'radius'  ,  'f'  ,  0.75   ,     0  ,  +Inf  ;
            'hradius'  ,  'f'  ,  1.5  ,     0  ,  +Inf  ;
           'hdisptol'  ,  'f'  ,  0.5   ,     0  ,  +Inf  ;
             'linwid'  ,  'f'  ,  0.3   ,     0  ,  +Inf  ;
              'shade'  ,  'f'  ,  0.8   ,     0  ,  +1    ;
              'frate'  ,  'f'  ,  0.0   ,     0  ,  +Inf  } ;
            
  % Function handles
	 init = @finit ;
   stim = @fstim ;
  close = @fclose ;
 chksum = @fchksum ;
 
 
%%% RF definition %%%
% No receptive/response field 

if numel(rfdef) > 1
  
%   % Get x location
%   i = strcmp (  varpar( : , 1 )  ,  'centre_x'  ) ;
%   varpar{ i , 3 } = rfdef(1).xcoord ;
  
  % Get y location
  i = strcmp (  vpar( : , 1 )  ,  'y_coord'  ) ;
  vpar{ i , 3 } = rfdef(end).ycoord ;
  
  % Get width
  i = strcmp (  vpar( : , 1 )  ,  'fradius'  ) ;
  vpar{ i , 3 } = abs(rfdef(end).xcoord) ;
  
  % Get rotation direction
  i = strcmp (  vpar( : , 1 )  ,  'fangle'  ) ;
  vpar{ i , 3 } = rfdef(end).orientation ;
  
% elseif numel(rfdef) == 1
%     
%   rf_wid = rfdef(1).width ; 
%   % Get x location
%   i = strcmp (  vpar( : , 1 )  ,  'fradius'  ) ;
%   vpar{ i , 3 } = abs(rfdef(1).xcoord) ;
%   
%   % Get y location
%   i = strcmp (  vpar( : , 1 )  ,  'y_coord'  ) ;
%   rf_y = rfdef(1).ycoord;
%   
%   if rf_y > 0
%       vpar{ i , 3 } = rfdef(1).ycoord - rf_wid/2 ;
%   else
%       vpar{ i , 3 } = rfdef(1).ycoord + rf_wid/2 ;
%   end
%   
%   % Get rotation direction
%   i = strcmp (  vpar( : , 1 )  ,  'fangle'  ) ;
%   vpar{ i , 3 } = rfdef(1).orientation ;

else
    
  return
  
end
  
end % circle


%%% Stimulus definition handles %%%

% Trial initialisation function
function  S = finit ( vpar , tconst , ~ )
  
  
  % Initialise stimulus descriptor with a copy of variable parameters
  S.vp = vpar ;
  
  % Add 180 degrees if fflip is negative
  flip = 180  *  ( S.vp.fflip  <  0 ) ;
  
  % Translation of the circle onto the edge of the formation circle.
  S.trans = [  S.vp.fradius  *  cosd( S.vp.fangle + flip )  ;
               S.vp.fradius  *  sind( S.vp.fangle + flip )  ] ;
  
  % Position rectangle , initialise to the correct dimensions but centred
  % on the origin. This is a PTB rectangle where origin is top-left corner
  % of window and positive directions are right and down. Degrees to
  % pixels.  NOTE , [ RectLeft , RectTop , RectRight , RectBottom ] gives
  % indeces 1 , 2 , 3 , 4 in PTB version 3.0.14.
  S.r = S.vp.radius  *  tconst.pixperdeg  *  [ -1 , -1 , 1 , 1 ] ;
  
  % Get a PTB position rectangle. Converts from degrees to pixels, finds
  % centre of circle in PTB coordinates.
  S.r = dotrect ( S , tconst ) ;
   
  % Half disparity becomes the amount that the image for each eye must be
  % shifted , relative to trial origin's disparity , converted to pixels
  S.disp_px = ( S.vp.disp  +  tconst.origin( 3 ) )  /  2 ;
  S.disp_px = S.disp_px  *  tconst.pixperdeg ;
  
  % Convert flash rate from hertz to angular frequency
  S.ang_freq = 2  *  pi  *  S.vp.frate ;
  
  % Initial colour
  if  S.vp.frate
    c = 0.5 ;
    
  else
    c = S.vp.shade ;
    
  end
  
  % Line width, in pixels
  S.lw = S.vp.linwid  *  tconst.pixperdeg ;
  
  
  % Add drawing command input arguments for Screen
  S.scrarg = {  'FrameOval'  ;   % 1 - Screen drawing command
              tconst.winptr  ;   % 2 - Window pointer
                          c  ;   % 3 - Colour value
                       S.r   ;   % 4 - Rectangle
                       S.lw  ;   % 5 - Pen width
                       S.lw  } ; % 6 - Pen height
          
	% Hit region is a 6-column circle definition
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  S.hitregion = zeros ( 1 , 6 ) ;
  
  S.hitregion( c6.xcoord ) = vpar.x_coord  +  S.trans ( 1 )  +  ...
    tconst.origin ( 1 ) ;
  S.hitregion( c6.ycoord ) = vpar.y_coord  +  S.trans ( 2 )  +  ...
    tconst.origin ( 2 ) ;
  S.hitregion( c6.radius ) = vpar.hradius ;
  S.hitregion( c6.disp   ) = vpar.disp  +  tconst.origin ( 3 ) ;
  S.hitregion( c6.dtoler ) = vpar.hdisptol ;
  S.hitregion( c6.ignore ) = 1 ;
  
end % init


% Stimulation function
function  [ S , h ] = fstim ( S , tconst , tvar )
  
  
  %%% Variable parameter changes %%%
  
  % Hit region update not expected by default
  h = false ;
  
  % Any variable parameters changed? If stereo mode is enabled, then only
  % run this once for the left-eye buffer , which is drawn to first.
  if  ~ isempty ( tvar.varpar )  &&  tvar.eyebuf < 1
    
    
    %-- Variables --%
    
    % Point to variable parameters and hit-region index map
    vp = tvar.varpar ;
    c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
    
    % Make a struct that tracks which parameters were changed , d for delta
    F = fieldnames( S.vp )' ;
    F = [  F  ;  num2cell(  false( size( F ) )  )  ] ;
    d = struct (  F { : }  ) ;
    
    
    %-- New values --%
    
    for  i = 1 : size ( vp , 1 )
      
      % Save
      S.vp.( vp{ i , 1 } ) = vp{ i , 2 } ;
      
      % Mark as changed
      d.( vp{ i , 1 } ) = true ;
      
    end % new values
    
    
    %-- Handle changes --%
    
    % Formation circle radius , degrees to pixels
    if  d.fradius  ,  S.frad = S.vp.fradius  *  tconst.pixperdeg ;  end
    
    % Formation circle change
    if  d.fradius  ||  d.fangle  ||  d.fflip
      
      % Add 180 degrees if fflip is negative
      flip = 180  *  ( S.vp.fflip  <  0 ) ;
      
      % New circle translation from given x and y coordinate
      S.trans = [  S.vp.fradius  *  cosd( S.vp.fangle + flip )  ;
                   S.vp.fradius  *  sind( S.vp.fangle + flip )  ] ;
      
    end % formation circle change
    
    % Radius changed , re-initialise position rectangle
    if  d.radius
      
      S.r( : ) = S.vp.radius  *  tconst.pixperdeg  *  [ -1 ; -1 ; 1 ; 1 ] ;
      
    end % rad
    
    % Have we changed the circle's position or radius?
    if  any ( [ d.x_coord , d.y_coord , d.fradius , d.fangle , ...
        d.fflip , d.radius ] )
      
      % Then find new PTB position rectangle
      S.r( : ) = dotrect ( S , tconst ) ;
      
      % And re-position hit region
      S.hitregion( c6.xcoord ) = S.vp.x_coord  +  tconst.origin ( 1 ) ;
      S.hitregion( c6.ycoord ) = S.vp.y_coord  +  tconst.origin ( 2 ) ;
      
      % If there is no disparity then set the Screen input argument array
      if  ~ S.vp.disp  ,  S.scrarg{ 4 } = S.r ;  end
      
    end % pos rect
    
    % Disparity changed
    if  d.disp
      
      % Update hit region
      S.hitregion( c6.disp   ) = S.vp.disp  +  tconst.origin ( 3 ) ;

      % Number of pixels to shift each eye's image
      S.disp_px = ...
        ( S.vp.disp + tconst.origin( 3 ) )  /  2  *  tconst.pixperdeg ;
      
    end % disp
    
    % Flashing rate changed
    if  d.frate
      
      % New angular frequency
      S.ang_freq = 2  *  pi  *  S.vp.frate ;
      
    end % frate
    
    % Hit region radius change , update hit region
    if  d.hradius  ,  S.hitregion( c6.radius ) = S.vp.hradius ;  end
    
    % Hit region disparity tolerance change , update hit region
    if  d.hdisptol  ,  S.hitregion( c6.dtoler ) = S.vp.hdisptol ;  end
    
    % Line width change , compute new width in pixels
    if  d.linwid
      S.lw = S.vp.linwid  *  tconst.pixperdeg ;
      S.scrarg{ 5 } = S.lw ;
      S.scrarg{ 6 } = S.lw ;
    end
    
    
    %-- Set final values --%
    
    % Dot is not flashing , set colour value
    if  ~ S.vp.frate  ,  S.scrarg{ 3 } = S.vp.shade ;  end
    
    % Report whether hit region has changed
    h = d.x_coord  ||  d.y_coord  ||  d.disp  ||  d.hradius  ||  ...
      d.hdisptol ;
    
  end % var par changes
  
  
  %%% Update parameters %%%
  
  % Flashing enabled
  if  S.vp.frate
    
    % Calculate greyscale value from time since the start of the trial
    S.scrarg{ 3 } = ( sin(  S.ang_freq  *  tvar.ftime  )  +  1 )  /  2 ;
    
  end % flash
  
  % Apply disparity
  if  S.vp.disp
    
    % Add or subtract horizontal position according to which eye's frame
    % buffer we're drawing to. Remember, PTB 3.0.14 assigns horizontal
    % positions to indeces 1 and 3 in a position rectangle.
    switch  tvar.eyebuf
      
      % Left eye frame buffer
      case  0
        
        % Subtraction moves left eye's image to the right for convergent
        % disparities and to the left for divergent disparities
        S.scrarg{ 4 }( [ 1 , 3 ] ) = S.r( [ 1 , 3 ] )  -  S.disp_px ;
        
      % Right eye frame buffer
      case  1
        
        % Addition moves right eye's image to the left for convergent
        % disparities and to the right for divergent disparities
        S.scrarg{ 4 }( [ 1 , 3 ] ) = S.r( [ 1 , 3 ] )  +  S.disp_px ;
      
    end
    
  end % disp
  
  
  %%% Draw the circle %%%
  
  Screen (  S.scrarg { : }  ) ;
  
  
end % stim


% Trial closing function
function  S = fclose ( ~ , ~ )
  
  S = [] ;
  
end % close


% Check-sum function
function  c = fchksum ( ~ )
  
  c = 0 ;
  
end % chksum


%%% Sub-routines %%%

function  r = dotrect ( S , tconst )
  
  % Find the location of the circle in degrees relative to the origin of a
  % Cartesian coordinate system centred on the window.
  x = S.vp.x_coord  +  tconst.origin ( 1 ) ;
  y = S.vp.y_coord  +  tconst.origin ( 2 ) ;
  
  % Convert to pixels from degrees and add to screen centre , for absolute
  % location. Also add formation circle translation.
  x = tconst.pixperdeg * ( x + S.trans ( 1 ) )  +  tconst.wincentx ;
  y = tconst.pixperdeg * ( y + S.trans ( 2 ) )  +  tconst.wincenty ;
  
  % Convert to PTB coordinate system
  y = tconst.winheight  -  y ;
  
  % Centre circle position rectangle at centre of circle
  r = CenterRectOnPointd (  S.r  ,  x  ,  y  ) ;
  
end % dotrect

