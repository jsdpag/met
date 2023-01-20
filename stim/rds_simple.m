
function  [ type , varpar , init , stim , close , chksum ] = ...
                                                       rds_simple ( rfdef )
% 
% [ type , varpar , init , stim , close , chksum ] = rds_simple ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
%
% Draws a set of random dot stereograms (RDS) in a circular formation
% around a reference point. Each RDS has a circular centre and an annular
% surround. The dots in either region can vary their binocular disparity,
% dispairty noise, or correlation separately from the other region. Hence,
% the purpose of the centre-surround arrangement is to mask any possible
% monocular cue, maximising the chance that the subject will use only
% binocular cues to perform a task.
% 
% Dot positions are randomly resampled when generating a new image, while
% images can be generated up to the maximum rate of the monitor. However,
% disparity noise is sampled only once from a uniform distribution during
% initialisation and then recycled for the remainder of the trial. Half the
% dots appear light and half appear dark ; but all dots have an even
% probability of occluding any other dot, should they overlap.
% 
% RDSs are intended to be similar to those used by:
% 
%   Cumming BG, Parker AJ. 1999. Binocular neurons in V1 of awake monkeys
%     are selective for absolute, not relative, disparity. J. Neurosci.
%     19(13):5602.
% 
% The difference between rds_simple and rds_Cumming99 is in how they handle
% the monocular artefact resulting from a non-zero relative disparity
% between central and surround dots. To create a monocular image, central
% dots are shifted by half of a disparity step. This leaves an empty region
% of the cicular centre, while creating a high-density region of overlap in
% the surround. The solution is to mask surround dots in the region of
% overlap, and to add binocularly uncorrelated dots to the empty region.
% 
% rds_simple tries to use a more straightforward approach. Some surround
% dots are wasted, but the tradeoff of this waste is simple code. The
% intention is that simpler code will be easier for Matlab to optimise,
% while reducing the opportunity for memory fragmentation, which can lead
% to serious frame skips.
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
%   dot_rate - The rate in Hertz at which new images are created. For any
%     non-zero value, the actual rate will be rounded up so that each image
%     lasts for an integer multiple of frames. Zero has a special meaning
%     that stands for the maximum frame rate of the monitor. Default 0.
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
%   %-- Binocular dot parameters --%
%   
%   disp_base - The baseline disparity in degrees of visual field. This
%     value is relative to the plane of fixation and is applied to all
%     dots, surround and centre. The convention used here is that negative
%     disparities are convergent, positive disparities are divergent, and
%     zero disparity is in plane with fixation. Default 0.
%   
%   disp_cent - The disparity of central RDS dots relative to baseline, in
%     degrees of visual field. Hence the absolute disparity of central dots
%     relative to the plane of fixation becomes disp_base + disp_cent.
%     Default 0.
%   
%   disp_surr - Same as disp_cent but for surround dots. Default 0.
%   
%   noise_cent - Continuous uniform distribution U( -A , +A ) is
%     sampled to provide disparity noise that is applied to each central
%     dot. noise_cent gives the value of A in degrees of visual field,
%     hence 2A is the range of uniformly distributed disparity noise. Note
%     that when a MET stimulus event changes the value of noise_cent during
%     a trial then the set of disparity noise values is not re-sampled ;
%     rather, it is re-scaled. Default 0.
%  
%   noise_surr - Same as noise_cent, but for surround dots. Default 0.
%   
%   corr_cent - The binocular correlation of central dots, a value in the
%     range of [ -1 , +1 ]. For a correlation of 1, all central dots have
%     the same zero-disparity position and contrast value in both monocular
%     images. Correlations in the range of [ 0 , +1 ) describe the fraction
%     of central dots with the same zero-disparity position. All other dots
%     are treated as binocularly uncorrelated, with positions sampled
%     independently for each monocular image ; however their contrast
%     values are the same. For negative correlation values, all dots have
%     the same zero-disparity position. But the fraction of dots that have
%     the same contrast value in both monocular images becomes 1 +
%     corr_cent, while the fraction of anti-correlated dots with opposite
%     contrast values in the two monocular images is the absolute value of
%     corr_cent. Default 1.
% 
%   corr_surr - Same as corr_cent but for surround dots. Default 1.
%   
%   
%   %-- Relative change parameters --%
%   
%   These values are added to the value of existing parameters to provide
%   additional relative changes to given parameters. When used with a MET
%   stimulus event, these changes become dynamic.
%   
%   delta_cdisp - Change in central dot disparity, in degrees of visual
%     field. The final absolute disparity of central dots becomes disp_base
%     + disp_cent + delta_cdisp. Default 0.
%   
%   delta_sdisp - Same as delta_cdisp but for surround dots. Default 0.
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
%   trial.
% 
% NOTE: Requires the rds_simple_handle class, a subclass of handle. This
%   should be in met/stim/met.stim.class
% 
% NOTE: Can run in monocular mode, but will reset all disparity variable
%   parameters to zero during initialisation, and ignores disparity related
%   stimulus events.
% 
% 
% Written by Jackson Smith - Octobre 2017 - DPAG , University of Oxford
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
            'dot_rate' , 'f' ,   0.00 ,  0   , +Inf ;
         'dot_density' , 'f' ,   0.20 ,  0   ,  1.0 ;
        'dot_contrast' , 'f' ,   1.00 ,  0.0 ,  1.0 ;
            'secs_rnd' , 'f' ,   3.00 ,  0.0 , +Inf ;
           'disp_base' , 'f' ,   0.00 , -Inf , +Inf ;
           'disp_cent' , 'f' ,   0.00 , -Inf , +Inf ;
           'disp_surr' , 'f' ,   0.00 , -Inf , +Inf ;
          'noise_cent' , 'f' ,   0.00 ,  0.0 , +Inf ;
          'noise_surr' , 'f' ,   0.00 ,  0.0 , +Inf ;
           'corr_cent' , 'f' ,   1.00 , -1.0 , +1.0 ;
           'corr_surr' , 'f' ,   1.00 , -1.0 , +1.0 ;
         'delta_cdisp' , 'f' ,   0.00 , -Inf , +Inf ;
         'delta_sdisp' , 'f' ,   0.00 , -Inf , +Inf ;
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
  for  C = {  {  'contrast' , 'dot_contrast' }  ,  ...
              {     'width' , 'centre_width' }  ,  ...
              { 'disparity' , 'disp_cent'    }  }
    
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
  
  
end % rds_simple


%%% Stimulus definition handles %%%

% Trial initialisation function
function  Sret = finit ( vpar , tconst , Sold )
  
  
  %%% Check parameters %%%
  
  % Monoscopic mode
  if  ~ tconst.stereo  &&  any (  [ vpar.monovis , vpar.disp_base , ...
      vpar.disp_cent , vpar.disp_surr , vpar.noise_cent , ...
      vpar.noise_surr , vpar.corr_cent - 1 , vpar.corr_surr - 1 , ...
      vpar.delta_cdisp , vpar.delta_sdisp ]  )
    
    fprintf (  [ 'rds_simple: ' , ...
      'monocular mode , all binocular params set to monoscopic values' ]  )
    
    % Give monocular-compatible values
    vpar.monovis = 0 ;  vpar.disp_base = 0 ;  vpar.disp_cent = 0 ;
    vpar.disp_surr = 0 ;  vpar.noise_cent = 0 ;  vpar.noise_surr = 0 ;
    vpar.corr_cent = 1 ;  vpar.corr_surr = 1 ;  vpar.delta_cdisp = 0 ;
    vpar.delta_sdisp = 0 ;

  end % mono mode
    
  % Neither ffirst , flast , fyoke, nor fposition may exceed N
  if  any( vpar.fnumrds  <  ...
      [ vpar.ffirst , vpar.flast , vpar.fyoke , vpar.fposition ] )
    
    error (  'MET:rds_simple:badparam'  ,  [ 'rds_simple: ' , ...
      'Neither ffirst (%d) , flast (%d) , fyoke (%d) , nor ' , ...
      'fposition (%d) may exceed fnumrds (%d)' ]  ,  ...
      vpar.ffirst  ,  vpar.flast  ,  vpar.fyoke  ,  vpar.fposition  ,  ...
      vpar.fnumrds  )
    
  % ffirst must be less than or equal to flast
  elseif  vpar.flast  <  vpar.ffirst
    
    error (  'MET:rds_simple:badparam'  ,  [ 'rds_simple: ' , ...
      'ffirst (%d) must not exceed flast (%d)' ]  ,  vpar.ffirst  ,  ...
      vpar.flast  )
    
  % Randomness buffer cannot be empty
  elseif  vpar.secs_rnd  <=  0
    
    error (  'MET:rds_simple:secs_rnd'  ,  [ 'rds_simple: ' , ...
      'secs_rnd must be non-zero i.e. rand buffer cannot be empty' ]  )
    
  end % varpar check
  
  
  %%% Session initialisation %%%
  
  % If Sold is empty then this is the first trial of the session , we need
  % to create a data structure object and set certain constants
  if  isempty ( Sold )
    
    % Create an instance of the handle class object used for rds_simple
    Sret.h = rds_simple_handle ;
    
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
  
  % Number of frames per RDS image
  imgframes ( h , tconst )
  
  % Reset image timer to trigger new image on first frame
  h.timer( 1 ) = h.frames ;
  
  % Dot internal parameters
  dotpar ( h , tconst )
  
  % Compute trial constant squared radii , areas , and number of dots
  
    % RDS
    h.rrds2( 1 ) = ( tconst.pixperdeg  *  ...
      ( h.vp.centre_width / 2  +  h.vp.surround_width ) )  ^  2 ;
    h.ards( 1 ) = pi  *  h.rrds2 ;
    h.nrds( 1 ) = round ( h.ards  /  h.adot  *  h.vp.dot_density ) ;
  
    % Centre
    h.rcen2( 1 ) = ( tconst.pixperdeg  *  h.vp.centre_width  /  2 )  ^  2 ;
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
      e = sprintf (  [ 'rds_simple: numerical overrun , can''t have ' , ...
        'more than %d dots per RDS' ]  ,  intmax( h.itype )  ) ;
      
      try
        
        met ( 'print' , e , 'E' )
        
      catch
        
        error ( 'MET:rds_simple:finit' , [ 'rds_simple: met not ' , ...
          'supported on this system\n%s' ] , e )
        
      end
      
      % Fire error message
      error ( 'MET:rds_simple:finit' , 'rds_simple: terminating program' )
      
    end % numerical overrun error
  
  % Find the half-shift absolute disparity for central and surround dots.
  % At this point, we are able to find the inner surround radius , surround
  % area , number of surround dots , and number of positions used in dot
  % buffer.
  disparity ( h , tconst ) ;
  
  % Halved range of disparity noise for central and surround dots above or
  % below the reference disparity. Since raw noise values span ( -1 , +1 ),
  % scaling them by the con-/di-vergent halved range gives the
  % half-horizontal shift required for a monoscopic image. One half-shift
  % per monoscopic image produces a full shift in the stereoscopic image.
  h.dncen( 1 ) = h.vp.noise_cent  *  tconst.pixperdeg   /  2 ;
  h.dnsur( 1 ) = h.vp.noise_surr  *  tconst.pixperdeg   /  2 ;
  
  % Number of un/anti-correlated central and surround dots
  h.ccen( 1 ) = ncorr ( h.vp.corr_cent , h.ncen ) ;
  h.csur( 1 ) = ncorr ( h.vp.corr_surr , h.nsur ) ;
  
  % Flag which dots set contains uncorrelated dots
  h.ucen( 1 ) = 0 <= h.vp.corr_cent  &&  h.vp.corr_cent < 1 ;
  h.usur( 1 ) = 0 <= h.vp.corr_surr  &&  h.vp.corr_surr < 1 ;
  
  % Dot index vectors
    
    % All central dots
    balloc ( h , 'icen' , [ 1 , h.ncen ] , h.itype )
    h.icen( : ) = 1 : h.ncen ;
    
    % RDS index vector
    balloc ( h , 'irds' , [ 1 , h.numrds ] , 'uint8' )
    h.irds( : ) = h.vp.ffirst : h.vp.flast ;
    
    % Prepare dynamic index vectors
    idynamic ( h , true , true , true )
    
    
  % Allocate buffers
  
    % Dot locations
    balloc ( h , 'xy' , [ 2 , h.nbuf , h.numrds , 2 ] , 'single' )
    
    % Greyscale mapping
    balloc ( h , 'acg' , [ 1 , h.nbuf ] , 'single' )
    
    % Colour lookup table
    balloc ( h , 'clut' , [ 3 , h.nbuf , 2 ] , 'single' )
    
    % Visibility table
    balloc ( h , 'v' , [ 2 , h.nbuf , h.numrds ] , 'uint8' )
    
    % Disparity noise , use single floating-point precision
    balloc ( h , 'n' , [ 2 , h.nbuf , h.numrds ] , 'single' )
    
    % Disparity noise weights, use single floating-point precision
    balloc ( h , 'wn' , [ 2 , h.nbuf , h.numrds ] , 'single' )
    
    % Anti-correlated dot map
    balloc ( h , 'acor' , [ 1 , h.nbuf ] , @false )
    
    % Screen DrawDots buffer for dot location and colour lookup table
    balloc ( h , 'ddxy' , [ 2 , h.ibuf ] )
    balloc ( h , 'ddcl' , [ 4 , h.ibuf ] )
    
    % Randomness buffer
      
      % How many frames? Round up to next frame.
      h.nr( 1 ) = ceil ( h.vp.secs_rnd  /  tconst.flipint );
      
      % Attempt to allocate buffer , this could be a big one so catch the
      % error and inform user
      try
        
        balloc( h , 'r' , [ 2 , h.nbuf , h.numrds , 2 , h.nr ] , 'single' )
        
      catch  E
        
        fprintf (  [ '\nrds_simple: failure to allocate randomness ' , ...
          'buffer containing %d bytes\n' ]  ,  ...
            4 * 2 * h.nbuf * h.numrds * 2 * h.nr  )
          
        rethrow (  E  )
        
      end % allocate rand buffer
      
    
  % Initialise buffers
  
    % Make sure that greyscale mapping is correct , and initialise colour
    % lookup table
    greymap ( h )
    
    % Sample disparity noise ...
    h.n( 1 , : , : ) = 2 * rand( 1 , h.nbuf , h.numrds , 'single' )  -  1 ;
    
    % ... and scale for central and surround dots
    h.n( 2 , h.icen , : ) = h.dncen  *  h.n( 1 , h.icen , : ) ;
    h.n( 2 , h.isur , : ) = h.dnsur  *  h.n( 1 , h.isur , : ) ;
    
    % Make sure that anti-correlation flag vector is low
    h.acor( : ) = 0 ;
    
    % Randomness buffer frame index
    h.ir( 1 ) = 0 ;
    
    % Sample random values
    h.r( : ) = rand( size(  h.r  ) ) ;
    
    % Pre-compute angles
    h.r( 2 , : , : , : , : ) = 2  *  pi  *  h.r( 2 , : , : , : , : ) ;
    
    % Initialise anti-correlation and colour lookup buffers
    anticor (  h  )
    
    
  %-- Hit regions --%
  
  % We will use the 6-column form defining a set of circular regions
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  
  % Allocate hit regions if needed
  balloc ( h , 'hitregion' , [ h.numrds , 6 ] )
  
  % Initialise hit region radius and disparity
  h.hitregion( : , c6.radius ) = max ( [  h.vp.hminrad  ,  ...
    h.vp.centre_width / 2 + h.vp.surround_width  ] ) ;
  h.hitregion( : , c6.disp   ) = h.vp.disp_base  +  tconst.origin( 3 ) ;
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
      F = [  F  ,  { 'hitpos' , 'anydisp' }  ;
             num2cell(  false( size( F ) + [ 0 , 2 ] )  )  ] ;
      d = struct (  F { : }  ) ;
      
      % Before updating values , grab old correlations
      oldcor_cent = h.vp.corr_cent ;
      oldcor_surr = h.vp.corr_surr ;
      
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
      
      % New frequency of new image presentations
      if  d.dot_rate  ,  imgframes ( h , tconst )  ,  end
      
      % Contrast change
      if  d.dot_contrast
        
        % New dot greyscale values required
        greyscale ( h )
        
        % Apply these to the greyscale and colour lookup table buffers
        greymap ( h )
        
      end % contrast
      
      % Any kind of disparity change in stereo mode
      if  tconst.stereo  &&  any ( [ d.disp_base , d.disp_cent , ...
          d.disp_surr , d.delta_cdisp , d.delta_sdisp ] )
        
        % Recompute disparities and dependent values , such as number of
        % surround dots
        if  disparity ( h , tconst )
        
          % There is a different number of surround dots to before. We must
          % update the number of un/anti-correlated surround dots. Raise
          % flag if it isn't already up.
          d.corr_surr( 1 ) = 1 ;
          
          % We must update any index vectors that rely on the number of
          % surround dots , so raise anydisp flag checked below alongside
          % correlation levels
          d.anydisp( 1 ) = 1 ;
          
          % And resize dynamic buffers at need
          balloc ( h , 'ddxy' , [ 2 , h.ibuf ] )
          balloc ( h , 'ddcl' , [ 4 , h.ibuf ] )
          
        end % surr dot num diff
        
      end % disparity change
      
      % Different amplitude i.e. range of disparity noise values for
      % central dots
      if  tconst.stereo  &&  d.noise_cent
        
        % Find new noise scaling
        h.dncen( 1 ) = h.vp.noise_cent  *  tconst.pixperdeg  /  2 ;
        
        % Apply new noise scaling
        h.n( 2 , h.icen , : ) = h.dncen  *  h.n( 1 , h.icen , : ) ;
        
      end % central disparity noise
      
      % Same again for surround disparity noise
      if  tconst.stereo  &&  d.noise_surr
        
        h.dnsur( 1 ) = h.vp.noise_surr  *  tconst.pixperdeg  /  2 ;
        h.n( 2 , h.isur , : ) = h.dnsur  *  h.n( 1 , h.isur , : ) ;
        
      end % surround disp noise
      
      % Central dot correlation change
      if  tconst.stereo  &&  d.corr_cent
        h.ccen( 1 ) = ncorr ( h.vp.corr_cent , h.ncen ) ;
        h.ucen( 1 ) = 0 <= h.vp.corr_cent  &&  h.vp.corr_cent < 1 ;
      end
      
      % Surround dot correlation change
      if  tconst.stereo  &&  d.corr_surr
        h.csur( 1 ) = ncorr ( h.vp.corr_surr , h.nsur ) ;
        h.usur( 1 ) = 0 <= h.vp.corr_surr  &&  h.vp.corr_surr < 1 ;
      end
      
      % Disparity change , or correlation change for central or surround
      % dots
      if  tconst.stereo  &&  ...
          ( d.anydisp  ||  d.corr_cent  ||  d.corr_surr )
        
        % Update index vectors
        idynamic ( h , d.anydisp , d.corr_cent , d.corr_surr )

        % Neither central nor surround dots are now anti-correlated but one
        % of them used to be
        if  0 <= h.vp.corr_cent  &&  0 <= h.vp.corr_surr  &&  ...
            ( oldcor_cent < 0  ||  oldcor_surr < 0 )

          % Re-initialise clut colours to correlated values in right-eye
          % buffer
          h.clut( : , : , h.right ) = h.clut( : , : , h.left ) ;

          % And make sure that anticorrelation markers are set to zero
          h.acor( : ) = 0 ;

        % There are now anti-correlated dots
        elseif  0 <= h.vp.corr_cent  ||  0 <= h.vp.corr_surr

          % Re-initialise colour lookup buffers for anticorrelation
          anticor (  h  )
          
        end % anti-correlation handling
      
      end % disparity i.e. number of dots change or correlation change
      
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
    
    % Image presented for required number of frames
    if  h.frames  <=  h.timer
      
      % Point to useful constants
       left = h.left  ;
      right = h.right ;
      
      % Point to useful index vectors
      icen = h.icen ;
      isur = h.isur ;
      iuacen = h.iuacen ;
      iuasur = h.iuasur ;
      idot = h.idot ;
      
      % Advance random-buffer index by one frame , loop back to frame one
      % if the buffer has run out
      h.ir( 1 ) = h.ir  +  1 ;
      
      if  h.nr  <  h.ir  ,  h.ir( 1 ) = 1 ;  end
      
      % Load up one frame's worth of random values into the xy buffer , row
      % 2 already has pre-computed radian angles
      h.xy( : ) = h.r( : , : , : , : , h.ir ) ;
      
      % Sample central dot positions relative to the centre of the RDS
      rnddot ( h , icen , left , h.rcen2 , 0 )
      
      % Sample surround dot positions
      rnddot ( h , isur , left , h.rdif2 , h.rsin2 )
      
      % Copy binocularly correlated dots from left eye buffer to right ,
      % including anti-correlated , excludes un-correlated
      h.xy( : , h.icorr , : , right ) = h.xy( : , h.icorr , : , left ) ;
      
      % Sample uncorrelated central dot positions for the right eye
      if  0 <= h.vp.corr_cent  &&  h.vp.corr_cent  <  1
        rnddot ( h , iuacen , right , h.rcen2 , 0 )
      end
      
      % Sample uncorrelated surround dot positions for the right eye
      if  0 <= h.vp.corr_surr  &&  h.vp.corr_surr  <  1
        rnddot ( h , iuasur , right , h.rdif2 , h.rsin2 )
      end
      
      % Assume no visible dots
%       h.v( : ) = 0 ;
      
      % All central dots are visible
      h.v( : , icen , : ) = 1 ;
      
      % Apply noisy disparities to central dots
      if  h.vp.noise_cent
        
        % Correlated/anti-corr. central dots
        icorc = h.icorc ;
        
        % Compute disparity noise-weights by distance to outer edge of
        % central circle
        dnweights ( h , icorc , 1 , h.rcen2 , h.dncen , false , true )
        
        % Left monocular
        h.xy( 1 , icorc , : , left  ) = h.xy( 1 , icorc , : , left  )  -...
          h.wn( 1 , icorc , : ) ;
        
        % Right monocular
        h.xy( 1 , icorc , : , right ) = h.xy( 1 , icorc , : , right )  +...
          h.wn( 1 , icorc , : ) ;
        
      end % disp noise cent
      
      % Apply noisy disparities to surround dots
      if  h.vp.noise_surr
        
        % Correlated/anti-cor. surround dots
        icors = h.icors ;
        
        % Compute disparity noise-weights by distance to outer edge of
        % surround ...
        dnweights ( h , icors , 1 , h.rrds2 , h.dnsur , false , false )
        
        % ... and to inner edge
        dnweights ( h , icors , 2 , h.rsin2 , h.dnsur , true  , true  )
        
        % Left monocular
        h.xy( 1 , icors , : , left  ) = h.xy( 1 , icors , : , left  )  -...
          h.wn( 1 , icors , : ) ;
        
        % Right monocular
        h.xy( 1 , icors , : , right ) = h.xy( 1 , icors , : , right )  +...
          h.wn( 1 , icors , : ) ;
        
      end % disp noise surr
      
      % Check surround visibility if there is a relative disparity
      % difference with central dots
      if  h.drel
        
        % Surround dots visible to the left ...
        h.v( left , isur , : ) = h.rcen2  <  ...
          ( h.xy( 1 , isur , : , left )  +  h.drel ) .^ 2  +  ...
            h.xy( 2 , isur , : , left ) .^ 2 ;

        % ... and right eyes
        h.v( right , isur , : ) = h.rcen2  <  ...
          ( h.xy( 1 , isur , : , right )  -  h.drel ) .^ 2  +  ...
            h.xy( 2 , isur , : , right ) .^ 2 ;
        
      else
        
        % All surround dots are visible
        h.v( : , isur , : ) = 1 ;
        
      end % surround dot visibility
      
      % Apply disparity shifts to central dots
      if  h.dcen
        
        h.xy( 1 , icen , : , left  ) = h.xy( 1 , icen , : , left  )  -  ...
          h.dcen ;
        h.xy( 1 , icen , : , right ) = h.xy( 1 , icen , : , right )  +  ...
          h.dcen ;
        
      end % disparity shift central dots

      % Apply disparity shifts to surround dots
      if  h.dsur
        
        h.xy( 1 , isur , : , left  ) = h.xy( 1 , isur , : , left  )  -  ...
          h.dsur ;
        h.xy( 1 , isur , : , right ) = h.xy( 1 , isur , : , right )  +  ...
          h.dsur ;
      
      end % disparity shift surround dots
      
      % Point to permutation index
      irpm = h.irpm ;
      
      % Shuffle dot order in all dot buffers
      h.xy( : , idot , : , : ) = h.xy( : , irpm , : , : ) ;
      h.v( : , idot , : ) = h.v( : , irpm , : ) ;
      
    end % new rds image
    
    
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
  
  % Eye buffer code into index value , guarantee it is at least 1 if in
  % monocular mode
  if  tconst.stereo
    e = tvar.eyebuf  +  1 ;
  else
    e = 1 ;
  end
  
  % Load colour lookup table
  h.ddcl( 1 : 3 , : ) = h.clut( : , i , e ) ;
  
  % Loop each RDS
  for  rds = 1 : h.numrds
    
    % Load visibility flags into alpha channel 1 - visible , 0 - invisible
    h.ddcl( 4 , : ) = h.v( e , i , rds ) ;
    
    % Load dot location buffer
    h.ddxy( : ) = h.xy( : , i , rds , e ) ;
    
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
  
  % Load in first frame of random values to the xy buffer
  h.xy( : ) = h.r( : , : , : , : , 1 ) ;
  
  % Sum across dots , rds , eyes , x-y coordinate. Return double value from
  % single.
  c = double ...
    (  ...
      sum ...
      (  ...
        sum( sum( sum(  h.xy  ,  2  ) ,  3 ) ,  4 )  ...
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


% Find the number of frames per RDS image
function  imgframes ( h , tconst )

  % Number of seconds given
  if  h.vp.dot_rate

    % Ideal duration of each RDS image , in seconds
    sec = 1  /  h.vp.dot_rate ;

    % Unit convert seconds to frames , rounding up to nearest
    h.frames( 1 ) = round (  sec  /  tconst.flipint  ) ;

  % dot_rate is zero , code for 1 frame to match maximum frame rate of
  % monitor
  else

    h.frames( 1 ) = 1 ;

  end

end % frames


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

end % dotwidpix


% Compute half-shift disparity, inner surround radius, difference in radii,
% and number of surround dots. Returns true if the number of surround dots
% has changed.
function  nsdiff = disparity ( h , tconst )
  
  % Compute absolute disparities in degrees , half a disparity shift
  dcend = ( h.vp.disp_base + h.vp.disp_cent + h.vp.delta_cdisp )  /  2 ;
  dsurd = ( h.vp.disp_base + h.vp.disp_surr + h.vp.delta_sdisp )  /  2 ;
  
  % Central relative to surround half-disparity in degrees
  dreld = dcend  -  dsurd ;
  
  % Check whether central half-disparity exceeds surround width
  if  h.vp.surround_width  <  abs ( dreld )
    
    % Inform user
    try
      met (  'print'  ,  [ 'rds_simple: central disp ' , ...
        'capped to surround width' ] ,  'E'  )
    catch
      fprintf ( [ 'rds_simple: central disp ' , ...
        'capped to surround width' ] )
    end
    
    % Cap central dot disparity to surround width
    dcend = dsurd  +  sign ( dreld ) * h.vp.surround_width ;
    
  end % cap central disp
  
  % Absolute dot disparities , half-shift , in pixels
  h.dcen( 1 ) = dcend  *  tconst.pixperdeg ;
  h.dsur( 1 ) = dsurd  *  tconst.pixperdeg ;
  
  % Relative disparity , half shift
  h.drel( 1 ) = h.dcen  -  h.dsur ;
  
  % Squared inner surround radius
  h.rsin2( 1 ) = ( h.rcen2 ^ 0.5  -  abs( h.drel ) )  ^  2 ;
  
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


% Calculate number of un/anti-correlated dots
function  r = ncorr ( c , n )
  
  % All dots are all binocularly correlated
  if  c  ==  1
    
    r = 0 ;
  
  % Dots are un-correlated
  elseif  0  <=  c
    
    r = ( 1 - c )  *  n ;
    
  % Dots are anti-correlated
  else
    
    r = abs ( c )  *  n ;
    
  end
  
  % Round result
  r = round ( r ) ;
  
end % ncorr


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
function  idynamic ( h , sur , uacen , uasur )
  
  % Number of surround dots is different
  if  sur
    
    % All surround dots
    balloc ( h , 'isur' , [ 1 , h.nsur ] , h.itype )
    h.isur( : ) = h.ncen + 1 : h.ibuf ;

    % All current dots in dot buffer , excluding unused tail of buffer
    balloc ( h , 'idot' , [ 1 , h.ibuf ] , h.itype )
    h.idot( : ) = 1 : h.ibuf ;

    % Random permutation index vector , generate a random permutation of
    % dot order
    balloc ( h , 'irpm' , [ 1 , h.ibuf ] , h.itype )

    % Randomly permute white dots
    x = 1 : 2 : h.ibuf ;
    h.irpm( x ) = x( randperm( numel( x ) ) ) ;

    % And randomly permute black dots
    x = 2 : 2 : h.ibuf ;
    h.irpm( x ) = x( randperm( numel( x ) ) ) ;
    
  end % num surr dots
  
  % Change in number of fully binocularly correlated dots
  if  sur  ||  uacen  ||  uasur
    
    % Determine number of un-correlated dots
    uncen = h.ucen  *  h.ccen ;
    unsur = h.usur  *  h.csur ;
    
    % Allocate indeces for correlated central ...
    balloc ( h , 'icorc' , [ 1 , h.ncen - uncen ] , h.itype )
    h.icorc( : ) = uncen + 1 : h.ncen ;
    
    % ... and surround dots
    balloc ( h , 'icors' , [ 1 , h.ibuf - unsur - h.ncen ] , h.itype )
    h.icors( : ) = h.ncen + unsur + 1 : h.ibuf ;
    
    % Attempt allocation then refresh index vector
    balloc ( h , 'icorr' , [ 1 , h.ibuf - uncen - unsur ] , h.itype )
    h.icorr( : ) = [  h.icorc  ,  h.icors  ] ;
    
  end % binocularly correlated dots
  
  % Change in un/anti-correlated central dots
  if  uacen
    
    balloc ( h , 'iuacen' , [ 1 , h.ccen ] , h.itype )
    h.iuacen( : ) = 1 : h.ccen ;
    
  end % un/anti central

  % Change in un/anti-correlated surround dots
  if  uasur
    
    balloc ( h , 'iuasur' , [ 1 , h.csur ] , h.itype )
    h.iuasur( : ) = h.ncen + 1 : h.ncen + h.csur ;
    
  end % un/anti surround
  
end % idynamic


% Update the greyscale to dot mapping for correlated and anti-correlated
% dots
function  greymap ( h )
  
  % Map light and dark contrasts onto left-eye clut buffer
  h.clut( : , 1 : 2 : end , h.left ) = h.grey( h.glight ) ;
  h.clut( : , 2 : 2 : end , h.left ) = h.grey( h.gdark  ) ;
  
  % Load anti-correlated greyscale buffer
  h.acg( 1 : 2 : end ) = h.grey( h.gdark  ) ;
  h.acg( 2 : 2 : end ) = h.grey( h.glight ) ;
  
  % Initialise lookup table for right-monocular image
  h.clut( : , : , h.right ) = h.clut( : , : , h.left ) ;
  
end % greymap


% Initialise anticorrelation and colour lookup buffers
function  anticor (  h  )
  
  % Right eye buffer index
  r = h.right ;
  
  % Reset right-eye colour lookup table buffer anywhere there was an
  % anticorrelated dot
  h.clut( : , h.acor , r ) = h.clut( : , h.acor , h.left ) ;

  % Zero anti-correlated dot flags
  h.acor( : ) = 0 ;

  % And raise flags on new anti-correlated dots
  if  h.vp.corr_cent < 0  ,  h.acor( h.iuacen ) = 1 ;  end
  if  h.vp.corr_surr < 0  ,  h.acor( h.iuasur ) = 1 ;  end

  % Shuffle raised flags showing which dots are anticorrelated
  h.acor( h.idot ) = h.acor( h.irpm ) ;

  % Then apply anti-correlated contrast to those dots
  h.clut( 1 , h.acor , r ) = h.acg( h.acor ) ;
  h.clut( 2 , h.acor , r ) = h.acg( h.acor ) ;
  h.clut( 3 , h.acor , r ) = h.acg( h.acor ) ;
  
end % anticor


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
% location in dot buffer given by index i. Data handle h. e is the eye
% index , either 1 for left or 2 for right.
function  rnddot ( h , i , e , w , r )
  
  % Convert row 1 into radii
  h.xy( 1 , i , : , e ) = sqrt (  w  *  h.xy( 1 , i , : , e )   +   r  ) ;
  
  % Transform polar coordinates to Cartesian and return
  h.xy( : , i , : , e ) = ...
    [  h.xy( 1 , i , : , e )  .*  cos(  h.xy( 2 , i , : , e )  )  ;
       h.xy( 1 , i , : , e )  .*  sin(  h.xy( 2 , i , : , e )  )  ] ;
  
end % rnddot


% Compute disparity noise weights for set of dots with column vector i. j
% says what row of wn to fill i.e. check outer ( 1 ) or inner ( 2 ) edge of
% the shape. r2 is the squared radius of the edge. nmax is the maximum
% disparity noise applied to a dot's monocular image i.e. maximum possible
% half-disparity shift. findmin and calcnoise are flags that evoke extra
% calculations when non-zero. findmin says to take the minimum weight in
% each column and to store it in row 1. calcnoise says to convert weights
% in row 1 into weighted disparity noise values.
function  dnweights ( h , i , j , r2 , nmax , findmin , calcnoise )
  
  % Left monocular image index
  left = h.left ;

  % Subtraction order of root-squared-difference versus absolute
  % x-coordinate depends on whether this is the inner or outer edge
  switch  j
    
    % Outer edge
    case  1
      
      h.wn( j , i , : ) = ...
        (  sqrt( r2  -  h.xy( 2 , i , : , left ) .^ 2 )  -  ...
          abs( h.xy( 1 , i , : , left ) )  )  ./  nmax ;
      
    % Inner edge
    case  2
      
      h.wn( j , i , : ) = (  abs( h.xy( 1 , i , : , left ) )  -  ...
        sqrt( r2  -  h.xy( 2 , i , : , left ) .^ 2 )  )  ./  nmax ;
    
  end % inner-outer switch
  
  % Maximum value may be 1
  h.wn( j , i , : ) = min (  h.wn( j , i , : )  ,  1  ) ;
  
  % Find the minimum weight between row 1 and 2 , column-wise
  if  findmin
    
    h.wn( 1 , i , : ) = min (  h.wn( : , i , : ) ,  [] ,  1  ) ;
    
  end % min weight
  
  % Calculate the weighted disparity noise
  if  calcnoise
    
    h.wn( 1 , i , : ) = h.wn( 1 , i , : )  .*  h.n( 2 , i , : ) ;
    
  end % weighted noise
  
end % dnweights

