
function  [ type , varpar , init , stim , close , chksum ] = ...
                                                       rds_motion ( rfdef )
% 
% [ type , varpar , init , stim , close , chksum ] = rds_motion ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
%
% Draws a set of random dot stereograms (RDS) in a circular formation
% around a reference point. Each RDS has a circular centre and an annular
% surround. Dots in the central region can vary their binocular disparity.
% Hence, the purpose of the centre-surround arrangement is to mask any
% possible monocular cue, maximising the chance that the subject will use
% only binocular cues to perform a task. On top of this, central dots can
% move in a particular direction and speed.
% 
% Dot positions are randomly resampled when generating a new image, while
% images can be generated up to the maximum rate of the monitor. Surround
% dots are resampled on every frame, while central dots are resampled when
% they leave the central region of the RDS. Half the dots appear light and
% half appear dark ; but all dots have an even probability of occluding any
% other dot, should they overlap.
% 
% RDSs are intended to be a variant of those used by:
% 
%   Cumming BG, Parker AJ. 1999. Binocular neurons in V1 of awake monkeys
%     are selective for absolute, not relative, disparity. J. Neurosci.
%     19(13):5602.
%
% The check-sum is calculated for each trial by summing the first frame's
% worth of values in the random-value pool. See variable parameter
% secs_rnd, below.
% 
%
% Variable parameters:
%
%   
%   %-- formation circle --%
%   
%   The formation circle is an abstraction for placing each RDS relative to
%   the others. The centre of each RDS is placed at a unique point on the
%   circumfrance of the formation circle such that each neighbouring RDS is
%   separated by the same angle. Thus, four RDSs will have pi/2 radians (90
%   degrees) between each pair of neighbours. The centre of the formation
%   circle is the default point of reference. Alternatively, the centre of
%   a specified RDS can act as the reference point.
%   
%   fnumrds - The number of RDSs to draw.  Default 4.
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
%     Default 4.
%   
%   fangle - Counter-clockwise rotation of the formation circle, in
%     degrees. That is, the rotation of RDSs around the centre of the
%     formation circle. When set to zero, the first RDS is placed
%     immediately to the right of the formation circle centre ; at 90
%     degrees, the first RDS is directly above. Default 0.
%   
%   ffirst - Index of the first drawn RDS. This allows fewer RDSs to be
%     drawn than indicated by fnumrds, while retaining the same formation
%     as with fnumrds patches. For instance, if fnumrds is 4 but ffirst is
%     2 while fangle is 0, then 3 patches are drawn with angles of pi/2,
%     pi, and 3*pi/2 separating each neighbouring pair. Default 1.
%   
%   flast - Index of the final drawn patch. Must be equal to or greater
%     than ffirst, and equal to or less than fnumrds. Default 4.
%   
%   fyoke - RDS position index (see fposition), integer ranging from 0 to
%     N. If zero, then the centre of the formation circle is placed at the
%     point marked by fxcoord and fycoord. If non-zero, then all RDSs are
%     translated so that the yoked RDS position is centred at ( fxcoord ,
%     fycoord ). But  the relative position of all patches remains the same
%     as if fyoke were zero. In other words, each RDS is placed around the
%     centre of the formation circle according to its radius and rotation ;
%     then all RDSs are translated so that the specified RDS has its centre
%     on ( fxcoord , fycoord ). May be less than ffirst or greater than
%     flast. Default 0.
%   
%   fposition - The first RDS position sits on the edge of the formation
%     circle at fangle degrees of counter-clockwise rotation around the
%     circle's centre. The second to N positions are hence a further
%     360 / N degrees, each step. fposition says at which point the first
%     RDS will be placed, followed counter-clockwise around the
%     circumfrance by the second to Nth RDS. In other words, the ith RDS
%     will be placed at fangle + 360 / N * ( i + fposition - 2 ) degrees
%     around the edge of the formation circle. Thus fposition must be an
%     integer of 1 to N. Default 1.
% 
% 
%   %-- Area parameters --%
%   
%   centre_width - Diameter of the circular, central area of the RDS, from
%     the centre of the RDS. In degrees of visual field. Default 2.
%   
%   surround_width - Additional radius of the annular, surrounding area of
%     the RDS. If other words, the width of the surrounding area, measured
%     along a radial line that comes from the centre of the RDS. Hence, the
%     sum of centre and surround radii is the total radius of the RDS. In
%     degrees of visual field. Default 1.
%   
%   
%   %-- Global dot parameters --%
%   
%   These apply to all dots, in every RDS.
%   
%   monovis - A flag stating which monocular images are visible. A non-zero
%     value causes the dots to be visible in either the left (1) or right
%     (2) eye, only. A value of zero allows both monocular images to be
%     seen. Default 0.
%   
%   dot_type - The shape of each dot. If 0 (zero) then square dots are
%     drawn. If 1 (one), then circular dots are drawn. Default 1.
%   
%   dot_width - The width of each dot. If dots are square, then this is the
%     length of each side. If dots are circles, then this is the diameter
%     of each dot. In degrees of visual field. Note, dot size will
%     automatically be capped to either the largest or smallest that the
%     hardware supports ; this may be less or more than requested. Default
%     0.16.
%   
%   dot_density - The fraction of area in the RDS that will be covered by
%     dots. This is a value between 0 and 1, inclusive. It assumes that no
%     dots overlap and that all dots fit within the RDS ; an assumption
%     that is violated at high dot density and width values. Rounds to the
%     nearest dot , even zero. Default 0.20.
%   
%   dot_contrast - Half of all dots are light relative to the background
%     colour, and half are dark. This parameter is the Michelson contrast
%     of light versus dark dots, assuming a mid-grey background i.e. with
%     greyscale value 0.5, where 0 is black and 1 is white. Default 1.
%   
%   secs_rnd - The number of seconds of random values to sample during
%     initialisation. One value is sampled for each dot in each RDS for
%     each frame, assuming a full magnitude of central relative to surround
%     disparity and that all dots are uncorrelated. This random-value pool
%     is used during the trial rather than generating values on the fly. If
%     the trial runs longer than the specified time then random values are
%     recycled. Cannot be zero. Rounds up to next frame. Default 3.
%   
%   
%   %-- Central dot parameters --%
%   
%   disparity - The disparity of central RDS dots relative to fixation, in
%     degrees of visual field. Default 0.
%   
%   orientation - The angle in degrees that a moving bar would require to
%     produce motion in the perpendicular direction. In other words, this
%     parameter sets the direction of motion, which is always orientation +
%     90 degrees. Default 90 (i.e. left-ward motion).
%   
%   speed - The speed in degrees per second that central dots move along
%     the direction of motion. Default 4.
%   
%   
%   %-- Relative change parameters --%
%   
%   These values are added to the value of existing parameters to provide
%   additional relative changes to given parameters. When used with a MET
%   stimulus event, these changes become dynamic.
%   
%   delta_disp - Change in central dot disparity, in degrees of visual
%     field. The final absolute disparity of central dots becomes
%     disparity + delta_disp. Default 0.
%   
%   
%   %-- Hit region --%
%   
%   A hit region is defined for each RDS that is drawn. The region is
%   circular in shape, centred on the RDS, and matches the outer radius. If
%   the user selects a point on screen inside any of these hit regions,
%   then the associated task stimulus will be selected.
%   
%   hminrad - Minimum radius of the hit region around each RDS, in degrees
%     of visual field. Defautl 0.75.
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
% circles fradius and fangle are chosen so that RDS position 1 is
% centred on the RF. The RDS dot contrast, centre width, and centre
% disparity are matched to the RF preferences. If neighbours will overlap
% then the formation circle coordinate is centred in the RF and position 1
% is yoked ; an fradius is chosen to put a 1-degree gap between
% neighbours ; the fangle set before yoking is used.
% 
% NOTE: Since the point of the surround is to mask monocular disparity
%   shifts in the centre, the disparity of the centre will be capped to
%   whatever can be masked by the width of the surround.
% 
% NOTE: Stimulus events that ask for a parameter changes that would affect
%   how many dots there are will be silently ignored. This includes
%   fnumrds, ffirst, flast, centre_radius, surround_width, dot_type,
%   dot_width, and dot_density. Likewise, secs_rnd can not change during a
%   trial, nor orientation or speed.
% 
% NOTE: Requires the rds_simple_handle class, a subclass of handle. This
%   should be in met/stim/met.stim.class
% 
% NOTE: Does not require Psych Toolbox window in stereo mode. But any
%   disparity parameters will be reset to 0, noisily.
% 
% 
% Written by Jackson Smith - April 2018 - DPAG , University of Oxford
% 
% 
  
  
    % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set
  varpar = { 'fnumrds' , 'i' ,   4    ,  1   , +Inf ;
             'fxcoord' , 'f' ,   0.00 , -Inf , +Inf ;
             'fycoord' , 'f' ,   0.00 , -Inf , +Inf ;
             'fradius' , 'f' ,   4.00 ,  0.0 , +Inf ;
              'fangle' , 'f' ,   0.00 , -Inf , +Inf ;
              'ffirst' , 'i' ,   1    ,  1   , +Inf ;
               'flast' , 'i' ,   4    ,  1   , +Inf ;
               'fyoke' , 'i' ,   0    ,  0   , +Inf ;
           'fposition' , 'i' ,   1    ,  1   , +Inf ;
        'centre_width' , 'f' ,   2.00 ,  0.0 , +Inf ;
      'surround_width' , 'f' ,   1.00 ,  0.0 , +Inf ;
             'monovis' , 'i' ,   0    ,  0   ,  2   ;
            'dot_type' , 'i' ,   1    ,  0   ,  1   ;
           'dot_width' , 'f' ,   0.16 ,  0   , +Inf ;
         'dot_density' , 'f' ,   0.20 ,  0   ,  1.0 ;
        'dot_contrast' , 'f' ,   1.00 ,  0.0 ,  1.0 ;
            'secs_rnd' , 'f' ,   3.00 ,  0.0 , +Inf ;
           'disparity' , 'f' ,   0.00 , -Inf , +Inf ;
         'orientation' , 'f' ,  90.00 , -Inf , +Inf ;
               'speed' , 'f' ,   4.00 ,  0.0 , +Inf ;
          'delta_disp' , 'f' ,   0.00 , -Inf , +Inf ;
             'hminrad' , 'f' ,   0.75 ,  0.0 , +Inf ;
            'hdisptol' , 'f' ,   0.50 ,  0.0 , +Inf ;
            'hitcheck' , 'i' ,   1    ,  0   ,  1   } ;
  
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
  
  % Set formation circle radius and angle so that RDS position 1 lands in
  % the centre of the RF
  
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
  
	% Match contrast, RDS centre width, and centre disparity to RF
	% preferences. C maps rfdef field name to variable parameter name.
  for  C = {  {    'contrast' , 'dot_contrast' }  ,  ...
              {       'width' , 'centre_width' }  ,  ...
              {   'disparity' , 'disparity'    }  ,  ...
              { 'orientation' , 'orientation'  }  ,  ...
              {       'speed' , 'speed'        }  }
    
    % Give generic names to strings
    [ fn , vp ] = C{ 1 }{ : } ;
    
    % Copy RF preference to default variable param
    varpar{ i.( vp ) , 3 } = rfdef.( fn ) ;
    
  end % match RF prefs
  
  % RDS total diameter i.e. width , centre and surround
  w = varpar{ i.centre_width , 3 }  +  2 * varpar{ i.surround_width , 3 } ;
  
  % Angle between neighbours
  a = 2 * pi  /  varpar{ i.fnumrds , 3 } ;
  
  % Coordinates of RDS at positions 1 and 2 , assuming fangle is zero
  x = varpar{ i.fradius , 3 }  *  [  1  ;  cos( a )  ] ;
  y = varpar{ i.fradius , 3 }  *  [  0  ;  sin( a )  ] ;
  
	% Distance between centre of neighbouring RDS
  d = sqrt( sum(  diff(  [ x , y ]  )  .^ 2  ) ) ;
  
  % There is no overlap between neighbours , we can quit here
  if  w  <=  d  ,  return  ,  end
  
  % Distance between RDS centres will be one RDS width plus 1 degree.
  % Divide by 2 to calculate required radius
  d = ( 1 + w )  /  2 ;
  
  % Half angle between neighbours
  a = a  /  2 ;
  
  % fradius to put required distance between neighbours
  varpar{ i.fradius , 3 } = d  /  sin( a ) ;
  
  % Set formation circle coordinate to centre of RF
  varpar{ i.fxcoord , 3 } = rfdef.xcoord ;
  varpar{ i.fycoord , 3 } = rfdef.ycoord ;
  
  % Yoke RDS position 1 to centre of RF
  varpar{ i.fyoke , 3 } = 1 ;
  
  
end % rds_motion


%%% Stimulus definition handles %%%

% Trial initialisation function
function  Sret = finit ( vpar , tconst , Sold )
  
  
  %%% Check parameters %%%
  
  % Monoscopic mode
  if  ~ tconst.stereo  &&  (  vpar.disparity  ||  vpar.delta_disp  ||  ...
      vpar.monovis  )
    
    % Report
    fprintf (  [ 'rds_motion: Monocular mode , setting disparity ' , ...
      'and delta_disp to 0' ]  )
    
    % Reset variable parameters
    vpar.disparity = 0 ;
    vpar.delta_disp = 0 ;
    vpar.monovis = 0 ;
    
  end % mono mode
    
  % Neither ffirst , flast , fyoke, nor fposition may exceed N
  if  any( vpar.fnumrds  <  ...
      [ vpar.ffirst , vpar.flast , vpar.fyoke , vpar.fposition ] )
    
    error (  'MET:rds_motion:badparam'  ,  [ 'rds_motion: ' , ...
      'Neither ffirst (%d) , flast (%d) , fyoke (%d) , nor ' , ...
      'fposition (%d) may exceed fnumrds (%d)' ]  ,  ...
      vpar.ffirst  ,  vpar.flast  ,  vpar.fyoke  ,  vpar.fposition  ,  ...
      vpar.fnumrds  )
    
  % ffirst must be less than or equal to flast
  elseif  vpar.flast  <  vpar.ffirst
    
    error (  'MET:rds_motion:badparam'  ,  [ 'rds_motion: ' , ...
      'ffirst (%d) must not exceed flast (%d)' ]  ,  vpar.ffirst  ,  ...
      vpar.flast  )
    
  % Randomness buffer cannot be empty
  elseif  vpar.secs_rnd  <=  0
    
    error (  'MET:rds_motion:secs_rnd'  ,  [ 'rds_motion: ' , ...
      'secs_rnd must be non-zero i.e. rand buffer cannot be empty' ]  )
    
  end % varpar check
  
  
  %%% Session initialisation %%%
  
  % If Sold is empty then this is the first trial of the session , we need
  % to create a data structure object and set certain constants
  if  isempty ( Sold )
    
    % Create an instance of the handle class object used for rds_motion
    Sret.h = rds_motion_handle ;
    
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
  
  % Number of RDS drawn
  h.numrds( 1 ) = h.vp.flast  -  h.vp.ffirst  +  1 ;
  
  % Calculate formation circle coordinate
  getfc ( h , tconst )
  
  % Calculate centre of each RDS position around the formation circle
  % coordinate
  rdspos ( h , tconst )
  
  % Find the greyscale value for light and dark dots
  greyscale ( h )
  
  % Dot internal parameters
  dotpar ( h , tconst )
  
  % Compute trial constant squared radii , areas , and number of dots
  
    % RDS
    h.rrds2( 1 ) = ( tconst.pixperdeg  *  ...
      ( h.vp.centre_width / 2  +  h.vp.surround_width ) )  ^  2 ;
    h.ards( 1 ) = pi  *  h.rrds2 ;
    h.nrds( 1 ) = round ( h.ards  /  h.adot  *  h.vp.dot_density ) ;
  
    % Centre
    h.rcen( 1 ) = tconst.pixperdeg  *  h.vp.centre_width  /  2 ;
    h.rcen2( 1 ) = h.rcen  ^  2 ;
    h.acen( 1 ) = pi  *  h.rcen2 ;
    h.ncen( 1 ) = round ( h.acen  /  h.adot  *  h.vp.dot_density ) ;
    
    % Maximum surround fill zone. This is the widest anulus rimming the
    % centre of the RDS that will be filled by surround dots when the
    % centre has a relative disparity that is twice the width of the
    % surround. Twice the width is the maximum central disparity that will
    % be allowed.
    rfill = max (  [  0  ,  ...
      ( tconst.pixperdeg * ( h.vp.centre_width / 2  -  ...
        h.vp.surround_width ) )  ]  ) ;
    afilz = h.acen  -  pi * rfill ^ 2 ;
    nfilz = ceil ( afilz  /  h.adot  *  h.vp.dot_density ) ;
    
    % Number of dots in buffer , enough for one RDS centre and one whole
    % RDS. This is to account for surround re-fill dots that are placed in
    % centre when the centre dots have a horizontal disparity shift.
    h.nbuf( 1 ) = h.nrds  +  nfilz ;
    
	  % Check that there is no numerical overrun with index vector type
    if  intmax (  h.itype  )  <  h.nbuf
      
      % Build error string
      e = sprintf (  [ 'rds_motion: numerical overrun , can''t have ' , ...
        'more than %d dots per RDS' ]  ,  intmax( h.itype )  ) ;
      
      try
        
        met ( 'print' , e , 'E' )
        
      catch
        
        error ( 'MET:rds_motion:finit' , [ 'rds_motion: met not ' , ...
          'supported on this system\n%s' ] , e )
        
      end
      
      % Fire error message
      error ( 'MET:rds_motion:finit' , 'rds_motion: terminating program' )
      
    end % numerical overrun error
  
  % Find the half-shift absolute disparity for central dots.
  % At this point, we are able to find the inner surround radius , surround
  % area , number of surround dots , and number of positions used in dot
  % buffer.
  disparity ( h , tconst ) ;
  
  % Rotation matrix applied to freshly sampled central dots after their
  % distance to the leading edge of the central aperture is known
  ccwrot ( h )
  
  % Calculate motion vector and step size , in pixels
  motvec ( h , tconst )
  
  
  % Dot index vectors
    
    % All central dots
    balloc ( h , 'icen' , [ 1 , h.ncen ] , h.itype )
    h.icen( : ) = 1 : h.ncen ;
    
    % RDS index vector
    balloc ( h , 'irds' , [ 1 , h.numrds ] , 'uint8' )
    h.irds( : ) = h.vp.ffirst : h.vp.flast ;
    
    % Prepare dynamic index vectors
    idynamic ( h , true )
    
    
  % Allocate buffers
  
    % Dot locations
    balloc ( h , 'xy' , [ 2 , h.nbuf , h.numrds ] , 'single' )
    
    % Central dot distance to central region edge
    balloc ( h , 'cdist' , [ 1 , h.ncen , h.numrds ] , 'single' )
    
    % Visibility table
    balloc ( h , 'v'  , [ 2 , h.nbuf , h.numrds ] , 'uint8' )
    
    % Screen DrawDots buffer for dot location and colour lookup table
    balloc ( h , 'ddxy' , [ 2 , h.ibuf ] )
    balloc ( h , 'ddcl' , [ 4 , h.ibuf ] )
    
    % Randomness buffer
      
      % How many frames? Round up to next frame.
      h.nr( 1 ) = ceil ( h.vp.secs_rnd  /  tconst.flipint );
      
      % Attempt to allocate buffer , this could be a big one so catch the
      % error and inform user
      try
        
        balloc( h , 'r' , [ 2 , h.nbuf , h.numrds , h.nr ] , 'single' )
        
      catch  E
        
        fprintf (  [ '\nrds_simple: failure to allocate randomness ' , ...
          'buffer containing %d bytes\n' ]  ,  ...
            4 * 2 * h.nbuf * h.numrds * h.nr  )
          
        rethrow (  E  )
        
      end % allocate rand buffer
      
    
  % Initialise buffers
  
    % Make sure that greyscale mapping is correct , and initialise colour
    % lookup table
    greymap ( h )
    
    % Randomness buffer frame index
    h.ir( 1 ) = 0 ;
    
    % Sample random values
    h.r( : ) = rand( size(  h.r  ) ) ;
    
    % Pre-compute angles , but only for surround dots
    i = h.ncen + 1 : h.nbuf ;
    h.r( 2 , i , : , : ) = 2  *  pi  *  h.r( 2 , i , : , : ) ;
    
    % Load up first frame's worth of random values into the xy buffer for
    % central dots , row 2 already has pre-computed radian angles
    h.xy( : , h.icen , : ) = h.r( : , h.icen , : , 1 ) ;
    
    % Convert y-axis value to an angle in radians so that rnddot will work
    h.xy( 2 , h.icen , : ) = 2  *  pi  *  h.xy( 2 , h.icen , : ) ;
    
    % Sample central dot positions relative to the centre of the RDS
    rnddot ( h , h.icen , h.rcen2 , 0 )
    
    % All central dots are visible
    h.v( : , h.icen , : ) = 1 ;
    
    % Calculate the projection of each dot on the right-hand edge of the
    % circle and subtract the edge x-coordinate by the dot's x-coordinate
    % to get the distance of the dot to the leading side of the circle.
    h.cdist( : ) = sqrt (  h.rcen2  -  h.xy( 2 , h.icen , : ) .^ 2  )  -...
      h.xy( 1 , h.icen , : ) ;
    
    % Apply rotation to central dots
    for  i = 1 : h.numrds
      
      h.xy( : , h.icen , i ) = h.ccwrot  *  h.xy( : , h.icen , i ) ;
      
    end % rotate central dots
    
    
  %-- Hit regions --%
  
  % We will use the 6-column form defining a set of circular regions
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  
  % Allocate hit regions if needed
  balloc ( h , 'hitregion' , [ h.numrds , 6 ] )
  
  % Initialise hit region radius and disparity
  h.hitregion( : , c6.radius ) = max ( [  h.vp.hminrad  ,  ...
    h.vp.centre_width / 2 + h.vp.surround_width  ] ) ;
  h.hitregion( : , c6.disp   ) = 0 ;
  h.hitregion( : , c6.dtoler ) = h.vp.hdisptol ;
  
  % Initialise hit region positions
  hitregpos ( h , tconst )
  
  % Set whether or not to ignore the stimulus
  h.hitregion( : , c6.ignore ) = h.vp.hitcheck ;
  
  % Return struct must point to hitregion
  Sret.hitregion = h.hitregion ;
  
    
end % finit


% Stimulation function
function  [ Sio , hitflg ] = fstim ( Sio , tconst , tvar )
  
  
  % Point to data handle
  h = Sio.h ;
  
  % Hit region update not expected by default
  hitflg = false ;
  
  % Point to useful constants
   left = h.left  ;
  right = h.right ;

  % Point to useful index vectors
  icen = h.icen ;
  isur = h.isur ;
  
  
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
      % change to hit region position. anydisp flag for any change to
      % disparity.
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
        rdspos ( h , tconst )
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
      
      % Any kind of disparity change in stereo mode
      if  tconst.stereo  &&  ( d.disparity  ||  d.delta_disp )
        
        % Recompute disparities and dependent values , such as number of
        % surround dots
        if  disparity ( h , tconst )
          
          % Resize dynamic buffers at need
          balloc ( h , 'ddxy' , [ 2 , h.ibuf ] )
          balloc ( h , 'ddcl' , [ 4 , h.ibuf ] )
          
          % Re-initialise ddcl with greyscale values
          greymap ( h )
          
          % We must update any index vectors that rely on the number of
          % surround dots
          idynamic ( h , true )
          
        end % surr dot num diff
        
      end % disparity change
      
      % Orientation change , get new rotation matrix
      if  d.orientation  ,  ccwrot ( h )  ,  end
      
      % Hit region update
      if  any ( [ d.hminrad , d.hdisptol , d.hitcheck , d.hitpos ] )
        
        % Make sure that flag is up
        hitflg( 1 ) = 1 ;
        
        % Change in minimum radius
        if  d.hminrad
          h.hitregion( : , c6.radius ) = max ( [  h.vp.hminrad  ,  ...
            h.hitregion( 1 , c6.radius )  ] ) ;
        end
        
        % Disparity tolerance change
        if  d.hdisptol
          h.hitregion( : , c6.dtoler ) = h.vp.hdisptol ;
        end
        
        % Set whether or not to ignore the stimulus
        if  d.hitcheck
          h.hitregion( : , c6.ignore ) = h.vp.hitcheck ;
        end
        
        % Change in position
        if  d.hitpos  ,  hitregpos ( h , tconst )  ,  end
        
        % Point struct field to updated hit region array
        Sio.hitregion = h.hitregion ;
        
      end % hit region
      
      
    end % variable parameter changes
    
    
    %  New RDS image  %

    % Advance random-buffer index by one frame , loop back to frame one
    % if the buffer has run out
    h.ir( 1 ) = h.ir  +  1 ;

    if  h.nr  <  h.ir  ,  h.ir( 1 ) = 1 ;  end

    % Load up one frame's worth of random values into the xy buffer for
    % surround dots , row 2 already has pre-computed radian angles
    h.xy( : , isur , : ) = h.r( : , isur , : , h.ir ) ;

    % Sample surround dot positions
    rnddot ( h , isur , h.rdif2 , h.rsin2 )
    
    % Move central dots
    h.xy( 1 , icen , : ) = h.xy( 1 , icen , : )  +  h.mvec( 1 ) ;
    h.xy( 2 , icen , : ) = h.xy( 2 , icen , : )  +  h.mvec( 2 ) ;
    
    % Compute distance to circle edge
    h.cdist = h.cdist  -  h.step ;
    
    % RDS's
    for  rds = 1 : h.numrds
      
      % Find dots that fell off edge of central region
      k = h.cdist( 1 , : , rds )  <  0 ;
      
      % No dots fell off , continue to next rds
      if   ~ any (  k  )  ,  continue  ,  end
      
      % Sample y-axis position , recall that xy columns are ordered in
      % blocks of dots by type [ central , surrount ]
      h.xy( 2 , k , rds ) = ...
        2  *  h.rcen  *  h.r( 2 , k , rds , h.ir )  -  h.rcen ;
      
      % Calculate the x-axis position of the dots when projected to the
      % right hand edge of the circle
      crx = sqrt (  h.rcen2  -  h.xy( 2 , k , rds ) .^ 2  ) ;
      
      % Now we can place dots on the tailing i.e. left hand edge of the
      % circle
      h.xy( 1 , k , rds ) = - crx ;
      
      % Jitter horizontal position of dots to simulate dots arriving from
      % outside of the aperture
      h.xy( 1 , k , rds ) = h.step  *  h.r( 1 , k , rds , h.ir )  +  ...
        h.xy( 1 , k , rds ) ;
      
      % Distance of dots to edge of circle
      h.cdist( 1 , k , rds ) = crx  -  h.xy( 1 , k , rds ) ;
      
      % At last, apply rotation
      h.xy( : , k , rds ) = h.ccwrot  *  h.xy( : , k , rds ) ;
      
    end % rds

    % Check surround visibility if there is a relative disparity
    % difference with central dots
    if  h.dcen

      % Surround dots visible to the left ...
      h.v( left , isur , : ) = h.rcen2  <  ...
        ( h.xy( 1 , isur , : )  +  h.dcen ) .^ 2  +  ...
          h.xy( 2 , isur , : ) .^ 2 ;

      % ... and right eyes
      h.v( right , isur , : ) = h.rcen2  <  ...
        ( h.xy( 1 , isur , : )  -  h.dcen ) .^ 2  +  ...
          h.xy( 2 , isur , : ) .^ 2 ;

    else

      % All surround dots are visible
      h.v( : , isur , : ) = 1 ;

    end % surround dot visibility
    
    
  end % update stimulus
  
  
  %%% Draw stimulus to frame buffer %%%
  
  % Skip drawing image to eye buffer , left visible/right buffer , right
  % visible/left buffer
  if  ( h.vp.monovis == 1  &&  tvar.eyebuf == 1 )  ||  ...
      ( h.vp.monovis == 2  &&  tvar.eyebuf == 0 )
    
    return
    
  end % skip drawing
  
  % Set alpha blending
  Screen ( 'BlendFunction' , tconst.winptr , 'GL_SRC_ALPHA' , ...
    'GL_ONE_MINUS_SRC_ALPHA' ) ;
  
  % Point to dot index
  i = h.idot ;
  
  % Eye buffer code into index value , guarantee we get at least 1 if we're
  % in monocular mode
  if  tconst.stereo
    e = tvar.eyebuf  +  1 ;
  else
    e = 1 ;
  end
  
  % Loop each RDS
  for  rds = 1 : h.numrds
    
    % Load visibility flags into alpha channel 1 - visible , 0 - invisible
    h.ddcl( 4 , : ) = h.v( e , i , rds ) ;
    
    % Load dot location buffer
    h.ddxy( : ) = h.xy( : , i , rds ) ;
    
    % Apply disparity
    if  h.dcen
      switch  e
        case  left   ,  h.ddxy( 1 , icen ) = h.ddxy( 1 , icen )  -  h.dcen;
        case  right  ,  h.ddxy( 1 , icen ) = h.ddxy( 1 , icen )  +  h.dcen;
      end
    end
    
    % Draw RDS
    Screen ( 'DrawDots' , tconst.winptr , h.ddxy , ...
      h.dotwid  ,  h.ddcl  ,  h.rdsp( h.irds( rds ) , : )  ,  ...
        h.dottyp ) ;
    
  end % rds
  
  
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
  
  % Sum across dots , rds , eyes , x-y coordinate. Return double value from
  % single.
  c = double ...
    (  ...
      sum ...
      (  ...
        sum( sum(  h.r( : , : , : , 1 )  ,  2  ) ,  3 )  ...
      )  ...
    ) ;
  
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


% Compute PTB pixel coordinates of each RDS position's centre.
function  rdspos ( h , tconst )

  % Number of RDS positions
  N = h.vp.fnumrds ;

  % Do we need to resize rdsp property?
  if  size ( h.rdsp , 1 )  ~=  N

    h.rdsp = zeros ( N , 2 ) ;

  end % resize rdsp

  % Formation circle radius , in pixels
  radpix = h.vp.fradius  *  tconst.pixperdeg ;

  % Angle of each RDS position , counter-clockwise around the formation
  % circle.
  a = 360 / N  *  ( 0 : N - 1 )  +  h.vp.fangle ;

  % Change RDS positions from polar to Cartesian coordinates , in
  % pixels from the formation circle coordinate. The y-coord reflection
  % accounts for the PTB coordinate system.
  h.rdsp( : ) = [  + radpix  *  cosd( a )  ;
                   - radpix  *  sind( a )  ]' ;

  % Translate RDS positions so that the yoked position is centred in
  % the middle of the formation circle
  if  h.vp.fyoke

    % Patch index
    y = h.vp.fyoke ;

    % Translate positions
    h.rdsp( : , 1 ) = h.rdsp ( : , 1 )  -  h.rdsp ( y , 1 ) ;
    h.rdsp( : , 2 ) = h.rdsp ( : , 2 )  -  h.rdsp ( y , 2 ) ;

  end % formation yoke

  % Re-order RDS positions so that first, second, ... Nth RDS are
  % placed starting at fposition. Start by making an index vector that
  % will re-order the RDS positions ...
  i = mod (  ( 0 : N - 1 ) + h.vp.fposition - 1  ,  N  )  +  1 ;

  % ... then re-order RDS positions and add the formation circle coordinate
  h.rdsp( : ) = h.rdsp ( i , : )  +  repmat ( h.fcoord , N , 1 ) ;

end % xyrdsc


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
        sprintf( 'rds_motion: capping dot width to system %s' , ...
          wstr )  ,  'E' )
        
    catch
    end

  end % dot cap warning
  
  % Area of one dot
  if  h.vp.dot_type
    
    % Round dots
    h.adot( 1 ) = pi  *  ( h.dotwid / 2 ) ^ 2 ;
    
    % While we're at it , get the PTB code for high-quality round dots
    h.dottyp( 1 ) = 2 ;
    
  else
    
    % Square dots
    h.adot( 1 ) = h.dotwid ^ 2 ;
    
    % PTB dot type code for squares
    h.dottyp( 1 ) = 0 ;
    
  end % dot area

end % dotpar


% Compute half-shift disparity, inner surround radius, difference in radii,
% and number of surround dots. Returns true if the number of surround dots
% has changed.
function  nsdiff = disparity ( h , tconst )
  
  % Compute absolute disparities in degrees , half a disparity shift
  dcend = (  h.vp.disparity  +  h.vp.delta_disp  )  /  2 ;
  
  % Check whether central half-disparity exceeds surround width
  if  h.vp.surround_width  <  abs ( dcend )
    
    % Inform user
    try
      met (  'print'  ,  [ 'rds_motion: central disp ' , ...
        'capped to surround width' ] ,  'E'  )
    catch
      fprintf ( [ 'rds_motion: central disp ' , ...
        'capped to surround width' ] )
    end
    
    % Cap central dot disparity to surround width
    dcend = sign ( dcend )  *  h.vp.surround_width ;
    
  end % cap central disp
  
  % Absolute dot disparity , half-shift , in pixels
  h.dcen( 1 ) = dcend  *  tconst.pixperdeg ;
  
  % Squared inner surround radius
  h.rsin2( 1 ) = ( h.rcen2 ^ 0.5  -  abs( h.dcen ) )  ^  2 ;
  
  % Area of surround is area of RDS minus area of circle with inner
  % surround radius
  h.asur( 1 ) = h.ards  -  pi * h.rsin2 ;
  
  % Number of surround dots
  nsur_old = h.nsur ;
  h.nsur( 1 ) = round ( h.asur  /  h.adot  *  h.vp.dot_density ) ;
  
  % Return true if number of surround dots is different
  if  nsur_old  ==  h.nsur
    nsdiff = false ;
  else
    nsdiff = true ;
  end
  
  % Difference of squared radii comparing outer and inner surround radius
  h.rdif2( 1 ) = h.rrds2  -  h.rsin2 ;
  
  % Index of final position in dot buffer that is used
  h.ibuf( 1 ) = h.ncen  +  h.nsur ;
  
end % disparity


% Calculate rotation matrix that is applied to freshly sampled central dots
% after their distance to the leading edge of the central aperture is
% known
function  ccwrot ( h )
  
  % Direction of motion , in degrees
  d = h.vp.orientation  +  90 ;
  
  % The counter-clockwise rotation matrix , due to PTB coordinate system
  % this is actually the conventional clockwise rotation matrix
  h.ccwrot( : ) = [  cosd( d )  ,  sind( d ) ;
                    -sind( d )  ,  cosd( d ) ] ;
  
end % ccwrot


% Motion vector and step size in pixels per frame
function  motvec ( h , tconst )
  
  % First get step size from speed parameter , pixels per frame
  h.step( 1 ) = h.vp.speed  *  tconst.pixperdeg  *  tconst.flipint ;
  
  % Calculate motion vector by applying rotation matrix
  h.mvec( : ) = h.ccwrot  *  [ h.step ; 0 ] ;
  
end % motvec


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


% Attempts to resize all dynamic index vectors
function  idynamic ( h , sur )
  
  % Number of surround dots is different
  if  sur
    
    % All surround dots
    balloc ( h , 'isur' , [ 1 , h.nsur ] , h.itype )
    h.isur( : ) = h.ncen + 1 : h.ibuf ;

    % All current dots in dot buffer , excluding unused tail of buffer
    balloc ( h , 'idot' , [ 1 , h.ibuf ] , h.itype )
    h.idot( : ) = 1 : h.ibuf ;
    
  end % num surr dots
  
end % idynamic


% Update the greyscale to dot mapping for correlated and anti-correlated
% dots
function  greymap ( h )
  
  % Map light and dark contrasts onto dots
  h.ddcl( 1 : 3 , 1 : 2 : end ) = h.grey( h.glight ) ;
  h.ddcl( 1 : 3 , 2 : 2 : end ) = h.grey( h.gdark  ) ;
  
end % greymap


% Calculate the position of each hit region, in degrees from the trial
% origin
function  hitregpos ( h , tconst )
  
  % Hit region index map
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  
  % x and y coordinate columns in hit region
  xy = [ c6.xcoord , c6.ycoord ] ;
  
  % Indices of presented RDSs
  i = h.irds ;
  
  % Get PTB coordinate of RDS centres
  h.hitregion( : , xy ) = h.rdsp( i , : ) ;
  
  % Subtract screen-centre coordinate
  h.hitregion( : , c6.xcoord ) = h.hitregion( : , c6.xcoord )  -  ...
    tconst.wincentx ;
  h.hitregion( : , c6.ycoord ) = h.hitregion( : , c6.ycoord )  -  ...
    tconst.wincenty ;
  
  % Flip from PTB-style y-axis to standard Cartesian
  h.hitregion( : , c6.ycoord ) = -  h.hitregion( : , c6.ycoord ) ;
  
  % Convert unit to degrees
  h.hitregion( : , xy ) = h.hitregion( : , xy )  ./  tconst.pixperdeg ;
  
end % hitregpos


% Transform top row of random values into radii , then transform from polar
% to cartesian coordinates. n dot positions in an annular region. The
% difference of squared radii between inner and outer radius is given as
% width w. The squared inner radius is given as r. Samples new dots at each
% location in dot buffer given by index i. Data handle h.
function  rnddot ( h , i , w , r )
  
  % Convert row 1 into radii
  h.xy( 1 , i , : ) = sqrt (  w  *  h.xy( 1 , i , : )   +   r  ) ;
  
  % Transform polar coordinates to Cartesian and return
  h.xy( : , i , : ) = ...
    [  h.xy( 1 , i , : )  .*  cos(  h.xy( 2 , i , : )  )  ;
       h.xy( 1 , i , : )  .*  sin(  h.xy( 2 , i , : )  )  ] ;
  
end % rnddot

