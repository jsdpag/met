function  [ type , varpar , init , stim , close , chksum ] = ...
                                                  cylinder_simple ( rfdef )
% 
% [ type , varpar , init , stim , close , chksum ] = cylinder_simple(rfdef)
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Draws a set of random-dot, structure from motion cylinders similar to
% that used by Dodd et al. (2001). Circular dots move back and forth along
% an axis of motion with a sinusoidal velocity profile that peaks in the
% middle of the cylinder. When coupled with a horizontal disparity shift,
% this causes dots to appear as though they are stuck to the edge of an
% invisible cylinder that is rotating around its central axis. Disparity is
% assigned such that half of dots are convergent from a fixation plane,
% while the other half are divergent. Hence there is always an even number
% of dots. The disparity profile also varies sinusoidally, with a peak in
% the middle of the cylinder. Half of dots are light and the other half are
% dark, while the nature of dot generation ensures that dots are drawn in a
% randomised order, which randomises occlusion. The checksum returns the
% sum across all values in the randomness pool.
% 
% 
% % Variable parameters:
%
%   
%   %-- formation circle --%
%   
%   The formation circle is an abstraction for placing each cylinder
%   relative to the others. The centre of each cylinder is placed at a
%   unique point on the circumfrance of the formation circle such that each
%   neighbouring cylinder is separated by the same angle. Thus, four
%   cylinders will have pi/2 radians (90 degrees) between each pair of
%   neighbours. The centre of the formation circle is the default point of
%   reference. Alternatively, the centre of a specified cylinder can act as
%   the reference point.
%   
%   fnumcyl - The number of cylinders to draw.  Default 4.
%   
%   fxcoord - Horizontal i.e. x-axis coordinate of the centre of the
%     formation circle. In degrees of visual field from the trial origin.
%     Left is negative, right is positive. Default 0.
%   
%   fycoord - Vertical i.e. y-axis coordinate of the centre of the
%     formation circle. In degrees of visual field from the trial origin.
%     Down is negative, up is positive. Default 0.
%   
%   fradius - Radius of the formation circle, in degrees of visual field.
%     Default 6.
%   
%   fangle - Counter-clockwise rotation of the formation circle, in
%     degrees. That is, the rotation of cylinders around the centre of the
%     formation circle. When set to zero, the first cylinder is placed
%     immediately to the right of the formation circle centre ; at 90
%     degrees, the first cylinder is directly above. Default 0.
%   
%   ffirst - Index of the first drawn cylinder. This allows fewer cylinders
%     to be drawn than indicated by fnumcyl, while retaining the same
%     formation as with fnumcyl patches. For instance, if fnumcyl is 4 but
%     ffirst is 2 while fangle is 0, then 3 patches are drawn with angles
%     of pi/2, pi, and 3*pi/2 separating each neighbouring pair. Default 1.
%   
%   flast - Index of the final drawn patch. Must be equal to or greater
%     than ffirst, and equal to or less than fnumcyl. Default 4.
%   
%   fyoke - Cylinder position index (see fposition), integer ranging from 0
%     to N. If zero, then the centre of the formation circle is placed at
%     the point marked by fxcoord and fycoord. If non-zero, then all
%     cylinders are translated so that the yoked cylinder position is
%     centred at ( fxcoord , fycoord ). But  the relative position of all
%     cylinders remains the same as if fyoke were zero. In other words,
%     each cylinder is placed around the centre of the formation circle
%     according to its radius and rotation ; then all cylinders are
%     translated so that the specified cylinder is centred on ( fxcoord ,
%     fycoord ). May be less than ffirst or greater than flast. Default 0.
%   
%   fposition - The first cylinder position sits on the edge of the
%     formation circle at fangle degrees of counter-clockwise rotation
%     around the circle's centre. The second to N positions are hence a
%     further 360 / N degrees, each step. fposition says at which point the
%     first RDS will be placed, followed counter-clockwise around the
%     circumfrance by the second to Nth cylinder. In other words, the ith
%     cylinder will be placed at fangle + 360 / N * ( i + fposition - 2 )
%     degrees around the edge of the formation circle. Thus fposition must
%     be an integer of 1 to N. Default 1.
% 
% 
%   %-- Dot parameters --%
%   
%   dot_width - The width of each dot i.e. their diameter in degrees of
%     visual field. Note, dot size will automatically be capped to either
%     the largest or smallest that the hardware supports ; this may be less
%     or more than requested. Default 0.16.
%   
%   dot_density - The fraction of area in the cylinder that will be covered
%     by dots. This is a value between 0 and 1, inclusive. It assumes that
%     no dots overlap and that all dots fit within the cylinder ; an
%     assumption that is violated at high dot density and width values.
%     Rounds to the nearest dot , even zero. Default 0.20.
%   
%   dot_contrast - Half of all dots are light relative to the background
%     colour, and half are dark. This parameter is the Michelson contrast
%     of light versus dark dots, assuming a mid-grey background i.e. with
%     greyscale value 0.5, where 0 is black and 1 is white. Default 1.
%   
%   dot_avglife - The average lifetime of a dot, in seconds. This is
%     interpreted as the mean of an exponential distribution that is
%     sampled to generate the lifetime of each dot when it is created.
%     Lifetimes are rounded up to the next frame, so dots will have a
%     minimum lifetime of one frame. Default 0.615.
%   
%   secs_rnd - The number of seconds of random values to sample during
%     initialisation. This pool of random values is then used to generate
%     new dot positions and lifetimes during the trial. One value is
%     sampled for each dot per frame. If the trial runs longer than the
%     specified time then random values are recycled. Cannot be zero.
%     Rounds up to next frame. Default 2.
%   
%   
%   %-- Cylinder parameters --%
%   
%   width - The width and height of each cylinder in degrees of visual
%     field. Default 4.
%   
%   mask - Width of the dot mask, in degrees of visual field. This mask is
%     applied to each edge, hence twice the width is masked. For instance,
%     a mask value of 0.1 degree will cause 0.1 degree of both edges to be
%     masked, and so 0.2 degree of the cylinder in total will be blocked. A
%     mask may be required to block out dots that reach the edges of the
%     cylinder's two-dimensional projection. These dots move slowly,
%     according to the sinusoidal velocity profile, and can appear
%     perceptually brighter. The mask blocks any dot that is within a given
%     distance to the edge from being drawn. Default 0.16.
%   
%   orientation - The angle in degrees that each cylinder is rotated around
%     its central point. In other words, the angle of each cylinder's three
%     dimensional axis of rotation. This is bounded between 0.01 and 179.99
%     degrees so that only the cylinder disparity can determine which way
%     the cylinder rotates. Default 90.
%   
%   speed - The maximum speed of any dot, in degrees per second. This is
%     only applied to dots lying directly along the axis of rotation, and
%     tapers off with a sinusoidal profile towards the edges. Default 4.
%   
%   cylinder_disparity - This has two components, a magnitude and a sign.
%     The magnitude gives the maximum disparity in degrees of visual field
%     of convergent and divergent dots when lying directly along the axis
%     of rotation ; the magnitude tapers off the same way as speed, towards
%     the edges. The sign of cylinder disparity determines which way the
%     cylinder rotates. Viewed from the top, a positive cylinder disparity
%     will cause the cylinder to rotate in a counter-clockwise direction,
%     while a negative cylinder disparity will cause a clockwise rotation.
%     At zero, all dots lie in the fixation plane and the direction of
%     rotation is ambiguous. Default -0.3.
%   
%   
%   %-- Relative change parameters --%
%   
%   These provide additional relative changes to some of the parameters
%   given above. When used with a MET stimulus events, these changes become
%   dynamic.
%   
%   delta_cdisp - Additional amount of cylinder disparity, in degrees of
%     visual field. The final cylinder disparity that is viewed will be the
%     sum of delta_disp + cylinder_disparity, when disp_mult is 1. This can
%     be used to cause a change in disparity relative to a starting
%     baseline value. Default 0.
%   
%   disp_mult - Cylinder disparity multiplier. The final cylinder disparity
%     that is viewed will be disp_mult * ( delta_disp +
%     cylinder_disparity ). This too can be used to cause a change in
%     disparity relative to a starting baseline. But it is also well suited
%     to changing the sign of cylinder disparity when its value is changed
%     to -1. Default 1.
%   
%   
%   %-- Hit region --%
%   
%   A hit region is defined for each cylinder that is drawn. The region is
%   square in shape, centred on the cylinder, and matches the width. If
%   the subject selects a point on screen inside any of these hit regions,
%   then the associated task stimulus will be selected.
%   
%   hminwid - Minimum width of the hit region around each cylinder, in
%     degrees of visual field. Default 1.5. 
%   
%   hdisptol - Hit region disparity tolerance. Convergence may differ from
%     dot patch disparity by up to this much for the subject to select the
%     stimulus. In degrees of visual field. Default 0.5.
%   
%   hitcheck - A flag saying whether or not to compare the hit regions of
%     this stimulus against eye or touchscreen/mouse positions. A non-zero
%     value enables checking. A value of zero disables checking. May be 0
%     or 1. Default 1.
% 
% 
% When rfdef is non-empty, then default variable parameters will be set to
% match the preferences of RF number 1 i.e. rfdef( 1 ). The formation
% circle's fradius and fangle are chosen so that cylinder position 1 is
% centred on the RF. The cylinder dot contrast, width, orientation, speed,
% and cylinder disparity are matched to the RF preferences. The cylinder
% orientation will be the RF orientation modulo 180, capped to 0.01 or
% 179.99. The RF preferred orientation implies preferred direction ( 90 +
% orientation ). This affects the way in which the RF preferred disparity
% is translated into cylinder disparity ; the magnitude is taken as is, but
% the sign is conditional. If the RF's preferred disparity is convergent,
% then the cylinder disparity is chosen to make the convergent half of the
% cylinder move in the RF's preferred direction. Likewise, a divergent RF
% preference leads to a cylinder disparity that makes the divergent half of
% the cylinder move in the preferred direction. When the preferred
% disparity is zero i.e. the fixation plane, then it is assumed to be
% convergent, and the convergent half of the cylinder is aligned with the
% preferred direction. If neighbouring cylinders get close enough to each
% other for overlap to occur then the formation circle coordinate is
% centred in the RF and position 1 is yoked ; an fradius is chosen to put a
% 1-degree gap between neighbours ; the fangle set before yoking is used.
% 
% 
% NOTE: Stimulus events that ask for a parameter changes that would affect
%   how many dots there are will be silently ignored. This includes
%   fnumcyl, ffirst, flast, width, dot_width, and dot_density. Likewise,
%   dot_avglife and secs_rnd can not change during a trial.
% 
% NOTE: Requires the rds_simple_handle class, a subclass of handle. This
%   should be in met/stim/met.stim.class
%   
% 
% Reference:
% 
%   Dodd, J. V., et al. (2001). "Perceptually bistable three-dimensional
%     figures evoke high choice probabilities in cortical area MT." J
%     Neurosci 21(13): 4809-4821.
% 
% 
% Written by Jackson Smith - March 2018 - DPAG , University of Oxford
% 
  
  
  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set:
  %
  %               NAME , TYPE, DEFAULT, MINVAL, MAXVAL
  varpar = { 'fnumcyl' , 'i' ,  4     ,  1    , +Inf    ;
             'fxcoord' , 'f' ,  0.00  , -Inf  , +Inf    ;
             'fycoord' , 'f' ,  0.00  , -Inf  , +Inf    ;
             'fradius' , 'f' ,  6.00  ,  0.0  , +Inf    ;
              'fangle' , 'f' ,  0.00  , -Inf  , +Inf    ;
              'ffirst' , 'i' ,  1     ,  1    , +Inf    ;
               'flast' , 'i' ,  4     ,  1    , +Inf    ;
               'fyoke' , 'i' ,  0     ,  0    , +Inf    ;
           'fposition' , 'i' ,  1     ,  1    , +Inf    ;
           'dot_width' , 'f' ,  0.16  ,  0.00 , +Inf    ;
         'dot_density' , 'f' ,  0.20  ,  0.00 ,    1.0  ;
        'dot_contrast' , 'f' ,  1.00  ,  0.00 ,    1.0  ;
         'dot_avglife' , 'f' ,  0.615 ,  0.00 , +Inf    ;
            'secs_rnd' , 'f' ,  2.00  ,  0.00 , +Inf    ;
               'width' , 'f' ,  4.00  ,  0.00 , +Inf    ;
                'mask' , 'f' ,  0.16  ,  0.00 , +Inf    ;
         'orientation' , 'f' , 90.00  ,  0.01 ,  179.99 ;
               'speed' , 'f' ,  4.00  ,  0.00 , +Inf    ;
  'cylinder_disparity' , 'f' , -0.30  , -Inf  , +Inf    ;
         'delta_cdisp' , 'f' ,  0.00  , -Inf  , +Inf    ;
           'disp_mult' , 'f' ,  1.00  , -Inf  , +Inf    ;
             'hminwid' , 'f' ,  1.50  ,  0.00 , +Inf    ;
            'hdisptol' , 'f' ,  0.50  ,  0.00 , +Inf    ;
            'hitcheck' , 'i' ,  1     ,  0    ,   1     } ;
  
  % Function handles
	 init = @finit ;
   stim = @fstim ;
  close = @fclose ;
 chksum = @fchksum ;
  
  
  %%% RF definition %%%

  % No receptive/response field defined , return stim def
  if  isempty ( rfdef )  ,  return  ,  end
  
  % Make an index structure that will map variable parameter names to rows
  % of varpar
  i = [  varpar( : , 1 )'  ;  num2cell(  1 : size( varpar , 1 )  )  ] ;
  i = struct (  i{ : }  ) ;
  
  % Guarantee just the first RF definition
  rfdef = rfdef( 1 ) ;
  
  % Get centre of RF
  x = rfdef.xcoord ;
  y = rfdef.ycoord ;
  
  % Set formation circle radius and angle so that cylinder position 1 lands
  % in the centre of the RF
  
    % Radius
    varpar{ i.fradius , 3 } = sqrt ( x ^ 2  +  y ^ 2 ) ;
    
    % Angle
    varpar{ i.fangle  , 3 } = atand ( y / x ) ;
  
    % Correct the output of atand so that the returned angle points towards
    % coordinate ( x , y )
    if  x < 0
      
      % Special case , 180 degrees
      if  y == 0
        
        varpar{ i.fangle , 3 } = 180 ;
        
      % General case
      else
        
        varpar{ i.fangle , 3 } = varpar{ i.fangle , 3 }  +  ...
          sign ( y ) * 180 ;
        
      end
      
    end % correct atand output
    
  % Guarantee that RF orientation lies between 0 and 360
  rfdef.orientation = mod (  rfdef.orientation  ,  360  ) ;
  
	% Match contrast, cylinder width, orientation, speed, and disparity to RF
	% preferences. C maps rfdef field name to variable parameter name.
  for  C = {  {    'contrast' , 'dot_contrast'        }  ,  ...
              {       'width' , 'width'               }  ,  ...
              { 'orientation' , 'orientation'         }  ,  ...
              {       'speed' , 'speed'               }  ,  ...
              {   'disparity' , 'cylinder_disparity'  }  }
    
    % Give generic names to strings
    [ fn , vp ] = C{ 1 }{ : } ;
    
    % Copy RF preference to default variable param
    varpar{ i.( vp ) , 3 } = rfdef.( fn ) ;
    
  end % match RF prefs
  
  % Take magnitude preferred disparity for cylinder disparity
  varpar{ i.cylinder_disparity , 3 } = ...
    abs (  varpar{ i.cylinder_disparity , 3 }  ) ;
  
  % Preferred direction is somewhere to the left
  if  0  <=  rfdef.orientation  &&  rfdef.orientation  <  180
    
    % Convergent preferred disparity , let this include zero
    if  rfdef.disparity  <=  0
      
      % Negative cylinder disparity makes convergent half of cylinder move
      % in the leftward direction
      varpar{ i.cylinder_disparity , 3 } = ...
        - varpar{ i.cylinder_disparity , 3 } ;
      
    end % con pref disp
    
    % Otherwise, if preferred disp is divergent, then the positive cylinder
    % disparity following application of the absolute value function
    % already makes the divergent half of the cylinder move in the
    % leftward direction.
    
  % Preferred direction is somewhere to the right
  else
    
    % Divergent preferred disparity
    if  0  <  rfdef.disparity
      
      % Negative cylinder disparity makes divergent half of cylinder move
      % in the rightward direction
      varpar{ i.cylinder_disparity , 3 } = ...
        - varpar{ i.cylinder_disparity , 3 } ;
      
    end % div pref disp
    
    % Like above, the alternative is covered
    
  end % sign cylinder disp
  
  % Constrain cylinder orientation between 0 and 180. First check special
  % case when RF orientation was exactly 0.
  if  rfdef.orientation  ==  0
    
    % Take minimum allowable cylinder orientation
    varpar{ i.orientation , 3 } = varpar{ i.orientation , 4 } ;
    
  % Second special case when RF orientation was exactly 180.
  elseif  rfdef.orientation  ==  180
    
    % Take maximum allowable cylinder orientation
    varpar{ i.orientation , 3 } = varpar{ i.orientation , 5 } ;
    
  % RF orientation was anything else
  else
    
    % Constrain between 0 and 180
    varpar{ i.orientation , 3 } = ...
      mod (  varpar{ i.orientation , 3 }  ,  180  ) ;
    
  end % cylinder orientation
  
  % Cylinder length from corner to corner
  w = 2  *  sqrt (  2  *  ( varpar{ i.width , 3 } / 2 ) ^ 2  ) ;
  
  % Angle between neighbours
  a = 2 * pi  /  varpar{ i.fnumcyl , 3 } ;
  
  % Coordinates of cylinders at positions 1 and 2 , assuming fangle is zero
  x = varpar{ i.fradius , 3 }  *  [  1  ;  cos( a )  ] ;
  y = varpar{ i.fradius , 3 }  *  [  0  ;  sin( a )  ] ;
  
	% Distance between centre of neighbouring RDS
  d = sqrt( sum(  diff(  [ x , y ]  )  .^ 2  ) ) ;
  
  % There is no overlap between neighbours , we can quit here
  if  w  <=  d  ,  return  ,  end
  
  % Distance between cylinder centres will be one cylinder width plus 1
  % degree. Divide by 2 to calculate required radius.
  d = ( 1 + w )  /  2 ;
  
  % Half angle between neighbours
  a = a  /  2 ;
  
  % fradius to put required distance between neighbours
  varpar{ i.fradius , 3 } = d  /  sin( a ) ;
  
  % Set formation circle coordinate to centre of RF
  varpar{ i.fxcoord , 3 } = rfdef( 1 ).xcoord ;
  varpar{ i.fycoord , 3 } = rfdef( 1 ).ycoord ;
  
  % Yoke RDS position 1 to centre of RF
  varpar{ i.fyoke , 3 } = 1 ;
  
  
end % cylinder_simple


%%% Stimulus definition handles %%%

% Trial initialisation function
function  Sret = finit ( vpar , tconst , Sold )
  
  
  %%% Check parameters %%%
  
  % Monoscopic mode
  if  ~ tconst.stereo
    
    error (  'MET:cylinder_simple:badparam'  ,  [ 'cylinder_simple: ' , ...
      'Cannot run in monocular mode , check metscrnpar.csv > stereo' ]  )
    
  % Neither ffirst , flast , fyoke, nor fposition may exceed N
  elseif  any( vpar.fnumcyl  <  ...
      [ vpar.ffirst , vpar.flast , vpar.fyoke , vpar.fposition ] )
    
    error (  'MET:cylinder_simple:badparam'  ,  [ 'cylinder_simple: ' , ...
      'Neither ffirst (%d) , flast (%d) , fyoke (%d) , nor ' , ...
      'fposition (%d) may exceed fnumcyl (%d)' ]  ,  ...
      vpar.ffirst  ,  vpar.flast  ,  vpar.fyoke  ,  vpar.fposition  ,  ...
      vpar.fnumcyl  )
    
  % ffirst must be less than or equal to flast
  elseif  vpar.flast  <  vpar.ffirst
    
    error (  'MET:cylinder_simple:badparam'  ,  [ 'cylinder_simple: ' , ...
      'ffirst (%d) must not exceed flast (%d)' ]  ,  vpar.ffirst  ,  ...
      vpar.flast  )
    
  % Randomness buffer cannot be empty
  elseif  vpar.secs_rnd  <=  0
    
    error (  'MET:cylinder_simple:secs_rnd'  ,  [ 'cylinder_simple: ' , ...
      'secs_rnd must be non-zero i.e. rand buffer cannot be empty' ]  )
    
  end % varpar check
  
  
  %%% Session initialisation %%%
  
  % If Sold is empty then this is the first trial of the session , we need
  % to create a data structure object and set certain constants
  if  isempty ( Sold )
    
    % Create an instance of the handle class object used for rds_simple
    Sret.h = cylinder_simple_handle ;
    
    % Minimum and maximum dot width in pixels
    dotminmax ( Sret.h , tconst )
    
  else
    
    % Copy old session descriptor , including reference to data handle
    Sret = Sold ;
    
  end % session init
  
  % Point to handle object
  h = Sret.h ;
  
  
  %%% Trial initialisation %%%
  
  % Get current trial variable parameter values
  h.vp = vpar ;
  
  % Number of cylinders drawn
  h.numcyl( 1 ) = h.vp.flast  -  h.vp.ffirst  +  1 ;
  
  % Calculate formation circle coordinate
  getfc ( h , tconst )
  
  % Calculate centre of each RDS position around the formation circle
  % coordinate
  cylpos ( h , tconst )
  
  % Find the greyscale value for light and dark dots
  greyscale ( h )
  
  % Dot internal parameters
  dotpar ( h , tconst )
  
  % Dot mask width , in radians
  dotmsk ( h )
  
  % Cylinder disparity in pixels , full horizontal shift of a point from
    % its position in one monocular image to another
    disparity (  h  ,  tconst  )
  
  
  % Compute trial's constants for this stimulus
  
    % Width in pixels
    h.width( 1 )  = h.vp.width   *  tconst.pixperdeg ;
    
    % Half width in pixels
    h.hwidth( 1 ) = h.width  /  2 ;
    
    % Rotation matrix. Applies anti-clockwise rotation in PTB coordinate
    % system.
    rotationmat (  h  )

    % Radians that each dot travel around axis of rotation per frame
    step (  h  ,  tconst  )

    % Area of cylinder rectangle
    h.arec( 1 ) = h.width  ^  2 ;
    
    % Number of dots in one cylinder , must be an even number
    h.ndot( 1 ) = round ( h.arec  /  h.adot  *  h.vp.dot_density ) ;
    if  mod (  h.ndot  ,  2  )
      h.ndot( 1 ) = h.ndot  +  1 ;
    end
    
    % Number of random values to sample
    h.rn( 1 ) = ...
      h.ndot  *  h.numcyl  *  ceil (  h.vp.secs_rnd  /  tconst.flipint  ) ;
    
	
	% Allocate buffers
  
    % Dot lifetimes
    balloc (  h  ,  'life'  ,  [ 1 , h.ndot , h.numcyl ]  ,  'uint16'  )
    
    % Dot positions around the axis of rotation
    balloc (  h  ,  'xrad'  ,  [ 1 , h.ndot , h.numcyl ]  ,  'single'  )

    % Dot position along the axis of rotation
    balloc (  h  ,  'ypix'  ,  [ 1 , h.ndot , h.numcyl ]  ,  'single'  )
    
    % Dot disparities
    balloc (  h  ,  'ddisp' ,  [ 1 , h.ndot , h.numcyl ]  ,  'single'  )
    
    % Dot visibility
    balloc (  h  ,  'vis'   ,  [ 1 , h.ndot , h.numcyl ]  ,     @true  )
    
    % Dot locations
    balloc (  h  ,  'xy'    ,  [ 2 , h.ndot , h.numcyl ]  ,  'single'  )
    
    % Dot location buffer , double precision
    balloc (  h  ,  'dxy'   ,  [ 2 , h.ndot ]  )
    
    % Colour lookup table , double precision
    balloc (  h  ,  'clut'  ,  [ 4 , h.ndot ]  )
    
    % Randomness buffer
    balloc (  h  ,  'r'     ,  [ 1 , h.rn ]  ,  'single'  )
    
    
	% Initialise buffers
  
    % Cylinder index vector
    balloc (  h  ,  'icyl'  ,  [ 1 , h.numcyl ]  ,  'uint8'  )
    h.icyl( : ) = h.vp.ffirst : h.vp.flast ;
  
    % Sample dot lifetimes
    h.life( : ) = ...
      ceil(  exprnd( h.vp.dot_avglife , numel( h.life ) , 1 )  /  ...
        tconst.flipint  ) ;
    
    % Sample radial position of dots
    h.xrad( : ) = 2  *  pi  *  rand ( size(  h.xrad  ) ) ;
    
    % Sample axial position of dots
    h.ypix( : ) = h.width  *  (  rand ( size(  h.ypix  ) )  -  0.5  ) ;
    
    % Set greyscale values
    greymap ( h )
  
    % Reset randomness index
    h.ri( 1 ) = 0 ;
    
    % Sample random values
    h.r( : ) = rand (  1  ,  h.rn  ) ;
    
    
  % Make sure that there are an even number of convergent and divergent
  % dots
  
    % Find divergent dots. We define these as those with values of exactly
    % 0 up to but less than pi.
    i = 0 <= h.xrad  &  h.xrad < pi ;
    
    % The number of dots to shift. A positive value gives number of
    % divergent dots to switch to convergent. A negative value gives the
    % opposite. Value per cylinder.
    n = sum (  i  ,  2  )  -  h.ndot / 2 ;
    
    % Cylinders
    for  c = 1 : h.numcyl
      
      % Even number of convergent/divergent dots , go to next cylinder
      if  n( c )  ==  0
        
        continue
      
      % Too many divergent dots
      elseif  n( c )  >  0
        
        % Find linear indices of divergent dots
        j = find (  i( 1 , : , c )  ) ;
        
      % Too many convergent dots
      else
        
        % Find linear indices of convergent dots
        j = find (  ~ i( 1 , : , c )  ) ;
        
      end
      
      % Scramble order of dot indices and take enough to correct overspill
      j = j(  randperm(  numel( j )  ,  abs( n( c ) )  )  ) ;
      
      % Swap overspill dots to opposite side of fixation plane
      h.xrad( 1 , j , c ) = ...
        mod (  h.xrad( 1 , j , c )  +  pi  ,  2 * pi  ) ;
      
    end % cylinders
    
    
	%-- Hit regions --%
  
  % We will use the 8-column form defining a set of rectangular regions
  c8 = tconst.MCC.SDEF.ptb.hitregion.eightcol ;
  
  % Allocate hit regions if needed
  balloc ( h , 'hitregion' , [ h.numcyl , 8 ] )
  
  % Initialise hit region radius and disparity
  h.hitregion( : , [ c8.width , c8.height ] ) = ...
    max (  h.vp.hminwid  ,  h.vp.width  ) ;
  h.hitregion( : , c8.disp ) = tconst.origin( 3 ) ;
  h.hitregion( : , c8.rotation ) = h.vp.orientation ;
  h.hitregion( : , c8.dtoler ) = h.vp.hdisptol ;
  
  % Initialise hit region positions
  hitregpos ( h , tconst )
  
  % Set whether or not to ignore the stimulus
  h.hitregion( : , c8.ignore ) = h.vp.hitcheck ;
  
  % Return struct must point to hitregion
  Sret.hitregion = h.hitregion ;
  
  
end % finit


% Stimulation function
function  [ Sio , hitflg ] = fstim ( Sio , tconst , tvar )
  
  
  % Point to data handle
  h = Sio.h ;
  
  % Hit region update not expected by default
  hitflg = false ;
  
  
  %%% Update the stimulus %%%
  
  % Only update variable parameters or dot positions if this is the
  % left-eye frame buffer i.e. only do this once per stereo image
  if  tvar.eyebuf  <  1
    
    
    %-- Variable parameter changes --%

    % Any variable parameters changed?
    if  ~ isempty ( tvar.varpar )
      
      
      %  Which var par will change?  %
      
      % Point to the list of variable parameter changes
      vp = tvar.varpar ;
      
      % Make a struct that tracks which parameters were changed , d for
      % delta i.e. change. There is one field for every variable parameter,
      % and has the same name. Each field contains a scalar logical that is
      % true if the parameter is dynamically changing. Add hitpos to flag
      % change to hit region position.
      F = fieldnames( h.vp )' ;
      F = [  F  ,  { 'hitpos' }  ;
             num2cell(  false( size( F ) + [ 0 , 1 ] )  )  ] ;
      d = struct (  F { : }  ) ;
      
      % Flag each var par change , unless the parameter is trial-constant
      for  j = 1 : size ( vp , 1 )

        % Ignored trial-constant variable parameter change , skip to next
        if  any ( strcmp(  vp{ j , 1 }  ,  h.vpconst  ) )
          continue
        end
        
        % Save in stimulus descriptor's copy of variable parameters
        h.vp.( vp{ j , 1 } ) = vp{ j , 2 } ;

        % Mark as changed
        d.( vp{ j , 1 } ) = true ;

      end % flag changes
      
      
      %  Implement var par changes , when required  %
      
      % Formation circle coordinate change , raise hitregion flag and hit
      % position flag
      if  d.fxcoord  ||  d.fycoord
        getfc ( h , tconst )
        hitflg( 1 ) = 1 ;
        d.hitpos( 1 ) = 1 ;
      end
      
      % Any change that affects the location of each RDS , raise hitregion
      % flag and hit pos flag
      if  any ( [ d.fxcoord , d.fycoord , d.fradius , d.fangle , ...
          d.fyoke , d.fposition ] )
        cylpos ( h , tconst )
        hitflg( 1 ) = 1 ;
        d.hitpos( 1 ) = 1 ;
      end
      
      % Contrast change
      if  d.dot_contrast
        
        % New dot greyscale values required
        greyscale ( h )
        
        % Apply these to the greyscale and colour lookup table buffers
        greymap ( h )
        
      end % contrast
      
      % Dot mask width
      if  d.mask  ,  dotmsk (  h  ) ;  end
      
      % Change of orientation , recompute rotation matrix
      if  d.orientation  ,  rotationmat (  h  ) ;  end
      
      % Change in dot speed
      if  d.speed  ,  step (  h  ,  tconst  ) ;  end
      
      % Any change in disparity
      if  d.cylinder_disparity  ||  d.delta_cdisp  ||  d.disp_mult
        disparity (  h  ,  tconst  )
      end
      
      % Hit region update
      if  any ( [ d.hminwid , d.hdisptol , d.hitcheck , d.hitpos ] )
        
        % Make sure that flag is up
        hitflg( 1 ) = 1 ;
        
        % Rectangular hit region constants
        c8 = tconst.MCC.SDEF.ptb.hitregion.eightcol ;
        
        % Change in minimum width
        if  d.hminwid
          h.hitregion( : , [ c8.width , c8.height ] ) = ...
            max ( [  h.vp.hminwid  ,  h.hitregion( 1 , c8.width )  ] ) ;
        end
        
        % Disparity tolerance change
        if  d.hdisptol
          h.hitregion( : , c8.dtoler ) = h.vp.hdisptol ;
        end
        
        % Set whether or not to ignore the stimulus
        if  d.hitcheck
          h.hitregion( : , c8.ignore ) = h.vp.hitcheck ;
        end
        
        % Change in position
        if  d.hitpos  ,  hitregpos ( h , tconst )  ,  end
        
        % Point struct field to updated hit region array
        Sio.hitregion = h.hitregion ;
        
      end % hit region
      
      
    end % variable parameter changes
    
    
    %-- Generate new dots --%
    
    % Find dead dots' linear indices
    i = find (  h.life  ==  0  ) ;
    
    % Number of dead dots
    n = numel (  i  ) ;
    
    % Resurrect dead dots
    if  n
    
      % Determine the indices of convergent dead dots before resampling
      j = i(  pi <= h.xrad( i )  &  h.xrad( i ) < 2 * pi  ) ;
      
      % Sample new lifetimes
      h.life( i ) = ceil (  - h.vp.dot_avglife  .*  ...
        log (  getrnd( h , n )  )  /  tconst.flipint  ) ;

      % Sample rotational positions for new dots , but constrain from 0 to
      % pi , all are divergent to start , but see below
      h.xrad( i ) = pi  *  getrnd( h , n ) ;

      % Sample axial positions for new dots
      h.ypix( i ) = h.width  *  (  getrnd( h , n )  -  0.5  ) ;

      % Make new dots convergent if they share an index with a dead
      % convergent dot
      h.xrad( j ) = h.xrad( j )  +  pi ;
      
    end % resurrection
    
    % Subtract one frame from all dot lifetimes for the current frame
    h.life = h.life  -  1 ;
    
    
    %-- Update dot locations and disparities --%
  
    % Find new dot angular position around the cylinder
    h.xrad( : ) = mod (  h.xrad  +  h.step  ,  2 * pi  ) ;
    
    % Locate newly divergent dots , these are within one step of 0 rad
    div = h.xrad  <  h.step ;
    
    % Locate newly convergent dots , these are within one step of pi
    con = pi <= h.xrad  &  h.xrad - pi  <  h.step ;
    
    % Find the difference in cross-overs , positive means there are too
    % many divergent , negative means too many convergent , zero means
    % equal number on both sides of fixation plane
    n = sum (  div  ,  2  )  -  sum (  con  ,  2  ) ;
    
    % Cylinders
    for  i = 1 : h.numcyl
      
      % Imbalance in number of convergent and divergent dots
      if  n( i )
        
        % Find indices of dots when too many are divergent ...
        if  n( i )  >  0
          
          j = find (  div( 1 , : , i )  ) ;
          
        % ... or when too many are convergent
        else
          
          j = find (  con( 1 , : , i )  ) ;
          
        end % dot indices
        
        % Absolute value of imbalance
        n( i ) = abs ( n(  i  ) ) ;
        
        % The number of dots that crossed the fixation plane is not equal
        % to the imbalance. Thus we must choose a subset of those dots to
        % flip across the fixation plane. This will not take from
        % randomness pool.
        if  n( i )  <  numel (  j  )
          
          j = j(  randperm(  numel( j )  ,  n( i )  )  ) ;
          
        end % index sub set
        
        % Flip imbalanced dots to other side of fixation plane
        h.xrad( 1 , j , i ) = mod(  h.xrad( 1 , j , i ) + pi ,  2 * pi  ) ;
        
        % And resample their axial position
        h.ypix( 1 , j , i ) = h.width  *  ( getrnd( h , n( i ) ) - 0.5 ) ;
        
      end % div con imbalance
      
      % Get dot pixel coordinates in the fixation plane i.e. at zero
      % disparity
      h.xy( : , : , i ) = h.romat  *  ...
        [  h.hwidth  *  cos( h.xrad( : , : , i ) )  ;
                             h.ypix( : , : , i )    ] ;
      
      % Cylinder index
      j = h.icyl( i ) ;
      
      % Apply horizontal and vertical translations
      h.xy( 1 , : , i ) = h.xy( 1 , : , i )  +  h.cylp( j , 1 ) ;
      h.xy( 2 , : , i ) = h.xy( 2 , : , i )  +  h.cylp( j , 2 ) ;
      
    end % cylinders
    
    % Dots disparities
    h.ddisp( : ) = h.disp  *  sin ( h.xrad ) ;
    
    % Dot visibility , visible if not within dot mask at cylinder edges
    h.vis( : ) = ...
      (       h.dmsk  <  h.xrad  &  h.xrad  <      pi - h.dmsk  )  |  ...
      (  pi + h.dmsk  <  h.xrad  &  h.xrad  <  2 * pi - h.dmsk  ) ;

    % Apply half a left-eye horizontal shift
    h.xy( 1 , : , : ) = h.xy( 1 , : , : )  -  h.ddisp / 2 ;
    
    
  % Right-eye frame buffer
  else
    
    
    % Apply a whole right-eye horizontal shift
    h.xy( 1 , : , : ) = h.xy( 1 , : , : )  +  h.ddisp ;
    
    
  end % update stimulus
  
  
  %%% Draw stimulus to frame buffer %%%
  
  % Set alpha blending
  Screen ( 'BlendFunction' , tconst.winptr , 'GL_SRC_ALPHA' , ...
    'GL_ONE_MINUS_SRC_ALPHA' ) ;
  
  % Cylinders
  for  i = 1 : h.numcyl
    
    % Transfer single precision dots into double precision buffer
    h.dxy( : ) = h.xy( : , : , i ) ;
    
    % Transfer dot visibility
    h.clut(  end  ,  :  ) = h.vis( 1 , : , i ) ;
    
    % Draw round high-quality anti-aliased dots
    Screen (  'DrawDots'  ,  tconst.winptr  ,  h.dxy  ,  h.dotwid  ,  ...
      h.clut  ,  []  ,  2  ) ;
    
  end % cylinders
  
  
end % fstim


% Trial closing function
function  Sout = fclose ( Sin , type )
  
  % React to the requested type of stimulus closure
  switch  type
    
    % Close trial
    case  't'
      
      % Return the stimulus descriptor as is , the handle object can be
      % recycled
      Sout = Sin ;
      
    % Close session
    case  's'
      
      % Destroy data handle object
      delete (  Sin.h  )
      
      % Return empty array
      Sout = [] ;
    
  end % type of closure
  
end % fclose


% Check-sum function
function  c = fchksum ( Sin )
  
  % Point to data handle
  h = Sin.h ;
  
  % Sum randomness pool
  c = double ( sum(  h.r( : )  ) ) ;
  
end % chksum


%%% Sub-routines %%%


% Compute the formation circle coordinate
function  getfc ( h , tconst )

  % Formation circle coordinate from the centre of the screen , in
  % degrees
  h.fcoord( : ) = [ h.vp.fxcoord , h.vp.fycoord ]  +  ...
    tconst.origin( 1 : 2 ) ;

  % Convert unit from degrees to pixels and add the pixel coordinates
  % of the centre of the screen
  h.fcoord( : ) = tconst.pixperdeg * h.fcoord  +  ...
    [ tconst.wincentx , tconst.wincenty ] ;

  % Rmember to convert y-axis coordinate to PTB coordinate system where
  % down is up
  h.fcoord( 2 ) = tconst.winheight  -  h.fcoord( 2 ) ;

end % getfc


% Compute PTB pixel coordinates of each cylinder position's centre.
function  cylpos ( h , tconst )

  % Number of cylinder positions
  N = h.vp.fnumcyl ;

  % Do we need to resize cylp property?
  if  size ( h.cylp , 1 )  ~=  N

    h.cylp = zeros ( N , 2 ) ;

  end % resize rdsp

  % Formation circle radius , in pixels
  radpix = h.vp.fradius  *  tconst.pixperdeg ;

  % Angle of each cylinder position , counter-clockwise around the
  % formation circle
  a = 360 / N  *  ( 0 : N - 1 )  +  h.vp.fangle ;

  % Change cylinder positions from polar to Cartesian coordinates , in
  % pixels from the formation circle coordinate. The y-coord reflection
  % accounts for the PTB coordinate system.
  h.cylp( : ) = [  + radpix  *  cosd( a )  ;
                   - radpix  *  sind( a )  ]' ;

  % Translate cylinder positions so that the yoked position is centred in
  % the middle of the formation circle
  if  h.vp.fyoke

    % Patch index
    y = h.vp.fyoke ;

    % Translate positions
    h.cylp( : , 1 ) = h.cylp ( : , 1 )  -  h.cylp ( y , 1 ) ;
    h.cylp( : , 2 ) = h.cylp ( : , 2 )  -  h.cylp ( y , 2 ) ;

  end % formation yoke

  % Re-order cylinder positions so that first, second, ... Nth cylinders
  % are placed starting at fposition. Start by making an index vector that
  % will re-order the cylinder positions ...
  i = mod (  ( 0 : N - 1 ) + h.vp.fposition - 1  ,  N  )  +  1 ;

  % ... then re-order cylinder positions and add the formation circle
  % coordinate
  h.cylp( : ) = h.cylp ( i , : )  +  repmat ( h.fcoord , N , 1 ) ;

end % cylpos


% Calculates the greyscale value for light and dark to obtain the given
% Michelson contrast. Assumes a mid-grey background. Sets grey
% property.
function  greyscale ( h )

  % Column 1 is light , 2 is dark
  h.grey( : ) = [ 0.5 , -0.5 ] * h.vp.dot_contrast  +  0.5 ;

end % grey


% Calculate the min and max dot width in degrees of visual field
function  dotminmax ( h , tconst )

  % Get minimum and maximum dot size in pixels , draws nothing
  [ h.dotmin( 1 ) , h.dotmax( 1 ) ] = Screen ( 'DrawDots' , ...
    tconst.winptr ) ;

end % dotminmax


% Dot internal parameters. Convert dot width to pixels and cap to system
% limits , if needed. Finds area of a dot. Assigns DrawDot type code.
function  dotpar ( h , tconst )

  % Convert from degrees of visual field to pixels on screen
  h.dotwid( 1 ) = h.vp.dot_width  *  tconst.pixperdeg ;

  % Cap dot width to system limitation
  if  h.dotwid  <  h.dotmin

    % Cap to minimum
    h.dotwid( 1 ) = h.dotmin ;
    wstr = 'minimum' ;

  elseif  h.dotwid  >  h.dotmax

    % Cap to maximum
    h.dotwid( 1 ) = h.dotmax ;
    wstr = 'maximum' ;

  else

    % No cap required
    wstr = '' ;

  end % cap dot width

  % Print warning
  if  ~ isempty ( wstr )
    
    % Try in case we aren't in Linux environment
    try
      
      met (  'print'  ,  ...
        sprintf( 'rds_simple: capping dot width to system %s' , ...
          wstr )  ,  'E' )
        
    catch
    end

  end % dot cap warning
  
  % Area of one square dot
  h.adot( 1 ) = pi  *  ( h.dotwid / 2 ) ^ 2 ;

end % dotwidpix


% Dot mask width converted to radians for comparison against xrad values
function  dotmsk (  h  )
  
  % Half cylinder width in degrees
  hwid = h.vp.width  /  2 ;
  
  % Special case , dot mask is wider than half the cylinder width so all
  % dots masked
  if  h.vp.mask  >  hwid
    
    % Guarantee that no dots will be visible
    h.dmsk( 1 ) = pi ;
    
    % Done
    return
    
  end % special case
  
  % Viewed from the top, the width of the mask is related to the cosine of
  % a dot's position around the axis of rotation. Convert mask width to
  % fraction of cylinder width, implying a unit circle. Then take the
  % distance from the cylinder centre to the edge, minus one mask width.
  % The arccossine returns radians around the axis of rotation.
  h.dmsk( 1 ) = acos (  1  -  h.vp.mask  /  hwid  ) ;
  
end % dotmsk


% Compute counter-clockwise rotation matrix that will give cylinder the
% correct orientation in standard Cartisian space , as opposed to PTB space
% where down is up
function  rotationmat (  h  )
  
  % Orientation in degrees , but implicitly we first compute dots as if
  % there is a 90 degree rotation , so subtract it here
  d = h.vp.orientation  -  90 ;
  
  % Compute matrix
  h.romat( : ) = [  + cosd( d )  ,  sind( d )  ;
                    - sind( d )  ,  cosd( d )  ] ;
  
end % rotationmat


% Compute radian step that dots take around the axis of rotation
function  step (  h  ,  tconst  )

  % Speed in deg per sec divided by circumfrance gives circumfrances per
  % second. There are 2pi radians per circumfrance, multiply by this to get
  % radians per second. Then multiply by seconds per frame for radians per
  % frame.
  h.step( 1 ) = ...
    h.vp.speed  /  ( pi * h.vp.width )  *  ( 2  *  pi )  *  tconst.flipint;
  
end % speed


% Computes disparity and half-disparity in pixels. Takes into account
% baseline disparity, delta disparity, and disparity multiplier.
function  disparity (  h  ,  tconst  )
  
  % Final cylinder disparity after all factors accounted for
  final = h.vp.disp_mult  *  ...
    (  h.vp.cylinder_disparity  +  h.vp.delta_cdisp  ) ;
  
  % Full disparity shift , in pixels
  h.disp( 1 ) = final  *  tconst.pixperdeg ;
  
end % disparity


% Buffer allocation , provide handle object , property name (where buffer
% lives) , and buffer size vector. Further input arguments are optional,
% but all are passed as a comma-separated list of input arguments to the
% zeros function ; this is a good way to optionally specify the numeric
% type. One final input argument is optional. If this is a string then it
% is taken to be a numeric type that is passed to the zeros function. On
% the other hand, it can be a function handle to an allocation function,
% such as fail or true.
function  balloc ( h , n , s , varargin )
  
  % Get current buffer size
  cs = size ( h.( n ) ) ;
  
  % New and current sizes are the same!  No need to allocate a new buffer.
  if  numel( cs )  ==  numel( s )  &&  all ( cs( : )  ==  s( : ) )
    
    return
    
  end
  
  % Allocate buffer
  if  3 < nargin  &&  isa( varargin{ 1 } , 'function_handle' )
    
    h.( n ) = varargin{ 1 } (  s  ) ;
    
  else
    
    h.( n ) = zeros (  s  ,  varargin{ : }  ) ;
    
  end
  
end % balloc


% Update the greyscale to dot mapping
function  greymap ( h )
  
  % Map light and dark contrasts onto dots
  h.clut( 1 : 3 , 1 : 2 : end ) = h.grey( h.glight ) ;
  h.clut( 1 : 3 , 2 : 2 : end ) = h.grey( h.gdark  ) ;
  
end % greymap


% Calculate the position of each hit region, in degrees from the trial
% origin
function  hitregpos ( h , tconst )
  
  % Hit region index map
  c8 = tconst.MCC.SDEF.ptb.hitregion.eightcol ;
  
  % x and y coordinate columns in hit region
  xy = [ c8.xcoord , c8.ycoord ] ;
  
  % Indices of presented cylinders
  i = h.icyl ;
  
  % Get PTB coordinate of cylinder centres
  h.hitregion( : , xy ) = h.cylp( i , : ) ;
  
  % Subtract screen-centre coordinate
  h.hitregion( : , c8.xcoord ) = h.hitregion( : , c8.xcoord )  -  ...
    tconst.wincentx ;
  h.hitregion( : , c8.ycoord ) = h.hitregion( : , c8.ycoord )  -  ...
    tconst.wincenty ;
  
  % Flip from PTB-style y-axis to standard Cartesian
  h.hitregion( : , c8.ycoord ) = -  h.hitregion( : , c8.ycoord ) ;
  
  % Convert unit to degrees
  h.hitregion( : , xy ) = h.hitregion( : , xy )  ./  tconst.pixperdeg ;
  
end % hitregpos


% Return the next n values from the randomness buffer
function  r = getrnd (  h  ,  n  )
  
  % Get indices of circular buffer
  i = mod (  h.ri : h.ri + n - 1  ,  h.rn  )  +  1 ;
  
  % Set index of last value accessed
  h.ri( 1 ) = i( end ) ;
  
  % Return random values
  r = h.r(  i  ) ;
  
end % getrnd

