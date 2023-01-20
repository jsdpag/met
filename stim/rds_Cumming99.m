
function  [ type , varpar , init , stim , close , chksum ] = ...
                                                    rds_Cumming99 ( rfdef )
% 
% [ type , varpar , init , stim , close , chksum ] = rds_Cumming99( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Draws one or more random dot stereograms (RDS) in a circular formation.
% RDSs each have a central circular aperture with an annular surround. The
% central area contains dots, half light and half dark, that vary from the
% surround in their binocular disparity or binocular contrast correlation.
% Although all RDSs have the same properties, each has its own unique set
% of dots.
% 
% RDSs are intended to be similar to those used by:
% 
%   Cumming BG, Parker AJ. 1999. Binocular neurons in V1 of awake monkeys
%     are selective for absolute, not relative, disparity. J. Neurosci.
%     19(13):5602.
% 
% See also the Parker Group Random Dot Stereogram stimulus specification.
% 
% In effect, each RDS has two sets of dots. One set inhabits the annular
% surround. The other inhabits the circular centre. The number of dots
% in each set is such that the dot density is uniform across the RDS.
% Across time, the RDS consists of a sequence of images that are each
% presented for one or more consecutive video frames. The location of each
% dot is randomly sampled for each image. All dots are given the same
% baseline disparity. But dots in the centre may have an additional signal
% disparity, relative to the baseline. Some percentage of Central dots may
% also receive an additional amount of disparity noise, sampled from a
% uniform distribution ; in this case, the signal disparity becomes the
% mean disparity of noisy dots.
% 
% The purpose is to create a binocular stimulus in which the relative
% disparity of dots in the circular centre is the only cue that the subject
% can use to perform a task. There are no monocular cues. For instance, the
% RDS centre changes its distance to other objects on screen, per monocular
% image ; hence the job of the annular surround is to hide this distance
% change.
%
% When central dots are shifted horizontally, it is necessary to remove
% annular surround dots where the dot density increases, and to sample new
% surround dots in regions of the centre where the dot density decreases.
% Newly sampled dots have correlated positions where visible to the two
% eyes. Otherwise, there is a unique set of surround dots that are
% exclusive to one monocular image or the other. The unmatched dots present
% the opportunity for a second binocular cue, aside from the binocular
% disparity of central dots.
% 
% The check-sum is calculated by sorting the x and y-axis coordinates of
% all dots into one vector of ascending values, and then summing. This will
% mitigate some finite-precision machine error by adding small values with
% small values so that they aren't lost by first summing with very large
% values.
% 
% Variable parameters:
%
%   
%   %-- formation circle --%
%   
%   The formation circle is used only to position RDSs relative to each
%   other ; it is not drawn. The centre of each RDS is placed at a unique
%   point on the circumfrance of the formation circle such that every pair
%   of neighbouring RDSs is separated by the same angle as every other
%   pair. Thus, four RDSs on the formation circle's circumfrance will have
%   pi/2 radians (90 degrees) between each pair. Typically, the centre of
%   the formation circle is provided and then RDS centres are rotated
%   around that. Alternatively, one RDS centre can be pinned to a point
%   while the rest of the formation circle is spun around it.
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
%     Default 4.5.
%   
%   frotation - Counter-clockwise rotation of the formation circle, in
%     degrees. That is, the rotation of RDSs around the centre of the
%     formation circle. When set to zero, the first RDS is placed
%     immediately to the right of the formation circle centre ; at 90
%     degrees, the first RDS is directly above. Default 0.
%   
%   ffirst - Index of the first drawn RDS. This allows fewer RDSs to be
%     drawn than indicated by fnumrds, while retaining the same formation
%     as with fnumrds patches. For instance, if fnumrds is 4 but ffirst is
%     2 while frotation is 0, then 3 patches are drawn with angles of pi/2,
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
%     circle at frotation degrees of counter-clockwise rotation around the
%     circle's centre. The second to N positions are hence a further
%     360 / N degrees, each step. fposition says at which point the first
%     RDS will be placed, followed counter-clockwise around the
%     circumfrance by the second to Nth RDS. In other words, the ith RDS
%     will be placed at frotation + 360 / N * ( i + fposition - 2 ) degrees
%     around the edge of the formation circle. Thus fposition must be an
%     integer of 1 to N. Default 1.
% 
% 
%   %-- Area parameters --%
%   
%   centre_radius - Radius of the circular, central area of the RDS, from
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
%     drawn. If 1 (one), then circular dots are drawn. In either case,
%     alpha-blending is used to achieve anti-aliasing and sub-pixel
%     resolution. Default 1.
%   
%   dot_width - The width of each dot. If dots are square, then this is the
%     length of each side. If dots are circles, then this is the diameter
%     of each dot. In degrees of visual field. Default 0.08. Note, dot size
%     will automatically be capped to either the largest or smallest that
%     the hardware supports ; this may be less or more than requested.
%   
%   dot_lifetime - The ideal amount of time that each RDS stereoscopic
%     image is presented for ; therefore, the dot lifetime as well. In
%     practise, this is limited by the refresh rate of the monitor. Thus if
%     the dot lifetime takes longer than an integer multiple of frames,
%     then the lifetime will be rounded to the nearest frame ( minimum 1 ).
%     If the value is positive and non-zero then dot_lifetime is taken to
%     be in seconds. However, if 0 (zero) is provided, then lifetime will
%     be set to the inter-frame interval of the monitor i.e. the shortest
%     possible dot lifetime. Default 0.
%   
%   dot_density - The fraction of area in the RDS that will be covered by
%     dots. This is a value between 0 and 1, inclusive. It assumes that no
%     dots overlap and that all dots fit within the RDS ; an assumption
%     that is violated at high dot density and width values. Default 0.25.
%   
%   dot_contrast - Half of all dots are light relative to the background
%     colour, and half are dark. This parameter is the Michelson contrast
%     of light versus dark dots, assuming a mid-grey background i.e. with
%     greyscale value 0.5, where 0 is black and 1 is white. Default 1.
%   
%   disp_base - The baseline disparity of all dots relative to the
%     point of fixation. All other dot disparities will themselves be
%     relative to this value. Thus, dots in the annular surround will all
%     have this disparity. Central dots will have this disparity plus or
%     minus an additional amount. In degrees of visual field. Default 0.
%
%
%   %-- Annular surround area/background dot parameters --%
%   
%   These apply only to background dots in the annular surround, or that
%   refill the central area when signal dots have a non-zero disparity.
%   
%   anticor_back - The fraction, from 0 to 1, of all background dots that
%     are binocularly anti-correlated. This means that a light dot in one
%     monocular image is matched with a dark dot in the other. Default 0.
%   
%   uncorr_back - The fraction of background dots, from 0 to 1, that will
%     be uncorrelated. Here an uncorrelated dot is one that has its
%     position sampled independently for each monocular image. Default 0.
%   
%   
%   %-- Central area dot parameters --%
%   
%   These apply only to dots in the circular, central area of the RDS.
%   There are two distinct populations of dots, here. Signal dots are
%   so-called because they will all have the same relative disparity that
%   the subject is expected to discriminate in some way. Noise dots,
%   however, will have randomly sampled disparities with the purpose of
%   masking the disparity value of signal dots.
%   
%   signal_fraction - The fraction of central dots that use the following
%     disp_signal disparity without any additional disparity noise or
%     uncorrelation. As this value is lowered, the number of dots with
%     either additional randomly sampled noise or uncorrelated dot
%     positions increases. Default 1.
%   
%   disp_signal - The mean disparity relative to the baseline disparity of
%     all central dots. In degrees of visual field. Default 0.
%   
%   disp_deltasig - Some small change to signal-dot disparity. This value
%     is added to disp_signal before dots are drawn. The purpose is that
%     when rfdef specifies a disparity preference, then disp_signal will
%     match that preference. There is no way to know what that value is
%     beforehand. Thus, to allow trial-by-trial variation in signal-dot
%     disparity, it is necessary to have this additional disparity
%     parameter. In degrees of visual field. Default 0.
%   
%   disp_nlim - Disparity noise is sampled from a uniform distribution that
%     with range disp_signal +/- disp_nlim. In degrees of visual field.
%     Default 0.
%   
%   anticor_sig - The fraction of signal dots that are anticorrelated.
%     Default 0.
%   
%   anticor_noise - The fraction of noise dots that are anticorrelated.
%     Default 0.
% 
%   uncorr_noise - The fraction of noise dots, from 0 to 1, that will be
%     uncorrelated. Here an uncorrelated dot is one that has its position
%     sampled independently for each monocular image. Default 0.
%   
%   
%   %-- Monocular image flicker --%
%   
%   As in the Sherrington flicker task, it is possible to make the left or
%   right eye's image flicker on and off. Each monocular image is handled
%   separately, with its own flicker rate and phase. Therefore, the rate
%   and phase can be chosen to cause the two monocular images to show at
%   the same time, separate times, or overlapping times.
%   
%   flick_rate_left , flick_rate_right - The flicker rate for the left and
%     right monocular images, in Hertz. Since the images can either be on
%     or off, one full flicker cycle starts with half a cycle of showing
%     the image followed by half a cycle without showing the image. Each
%     half of the cycle will be an equal duration of time. Note that the
%     duration of half a flicker cycle will be rounded to the nearest video
%     frame ( minimum 1 ). If the flicker rate is zero then the monocular
%     image stays on, permanently. Default 0.
%   
%   flick_phase_left , flick_phase_right - The starting phase of the left
%     and right monocular image flicker cycle, in degrees from 0 to 360. A
%     value in the range [ 0 , 180 ) puts the image in the first half of
%     the flicker cycle, when the image is shown ; while a value from
%     [ 180 , 360 ) puts the image in the second half of the flicker cycle
%     when the image is not shown. Values are rounded to the nearest frame
%     e.g. for a flicker rate that is half of the monitor's frame rate, a
%     starting phase of 0 to 90 will round down to 0, while a phase over 90
%     to 180 will round up to 180. Default 0 and 180 for left and right.
%   
%   
%   %-- Hit region --%
%   
%   hminrad - Minimum radius of the hit region around each RDS, in degrees
%     of visual field. Defautl 0.8.
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
% circle radius will be adjusted to run through the RF location, while the
% formation circle rotation will be adjusted to place the first RDS onto
% the RF. The diameter of the central circular area of all RDS stimuli will
% match that RF, while the signal-dot disparity will match the RF's
% preferred disparity.
% 
% 
% NOTE: Stimulus events that ask for a parameter changes that would affect
%   how many dots there are will be silently ignored. This includes
%   fnumrds, ffirst, flast, centre_radius, surround_width, dot_type,
%   dot_width, dot_density, and hminrad.
% 
% NOTE: Will only allow a maximum signal dot disparity of 2 times the
%   surround width.
% 
% NOTE: Will throw an error if the PsychToolbox window is open in a
%   monocular mode.
% 
% 
% Written by Jackson Smith - June 2017 - DPAG , University of Oxford
%   
  
  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set
  varpar = { 'fnumrds' , 'i' ,   4    ,  1   , +Inf ;
             'fxcoord' , 'f' ,   0.00 , -Inf , +Inf ;
             'fycoord' , 'f' ,   0.00 , -Inf , +Inf ;
             'fradius' , 'f' ,   4.50 ,  0.0 , +Inf ;
           'frotation' , 'f' ,   0.00 , -Inf , +Inf ;
              'ffirst' , 'i' ,   1    ,  1   , +Inf ;
               'flast' , 'i' ,   4    ,  1   , +Inf ;
               'fyoke' , 'i' ,   0    ,  0   , +Inf ;
           'fposition' , 'i' ,   1    ,  1   , +Inf ;
       'centre_radius' , 'f' ,   2.00 ,  0.0 , +Inf ;
      'surround_width' , 'f' ,   1.00 ,  0.0 , +Inf ;
             'monovis' , 'i' ,   0    ,  0   ,  2   ;
            'dot_type' , 'i' ,   1    ,  0   ,  1   ;
           'dot_width' , 'f' ,   0.08 ,  0   , +Inf ;
        'dot_lifetime' , 'f' ,   0.00 ,  0   , +Inf ;
         'dot_density' , 'f' ,   0.25 ,  0   ,  1.0 ;
        'dot_contrast' , 'f' ,   1.00 ,  0.0 ,  1.0 ;
           'disp_base' , 'f' ,   0.00 , -Inf , +Inf ;
     'signal_fraction' , 'f' ,   1.00 ,  0.0 ,  1.0 ;
         'disp_signal' , 'f' ,   0.00 , -Inf , +Inf ;
       'disp_deltasig' , 'f' ,   0.00 , -Inf , +Inf ;
           'disp_nlim' , 'f' ,   0.00 , -Inf , +Inf ;
        'anticor_back' , 'f' ,   0.00 ,  0.0 ,  1.0 ;
         'anticor_sig' , 'f' ,   0.00 ,  0.0 ,  1.0 ;
       'anticor_noise' , 'f' ,   0.00 ,  0.0 ,  1.0 ;
         'uncorr_back' , 'f' ,   0.00 ,  0.0 ,  1.0 ;
        'uncorr_noise' , 'f' ,   0.00 ,  0.0 ,  1.0 ;
     'flick_rate_left' , 'f' ,   0.00 ,  0.0 , +Inf ;
    'flick_rate_right' , 'f' ,   0.00 ,  0.0 , +Inf ;
    'flick_phase_left' , 'f' ,   0.00 ,  0.0 ,  360 ;
   'flick_phase_right' , 'f' , 180.00 ,  0.0 ,  360 ;
             'hminrad' , 'f' ,   0.80 ,  0.0 , +Inf ;
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

  % Get centre of RF
  x = rfdef( 1 ).xcoord ;
  y = rfdef( 1 ).ycoord ;

  % Set formation circle radius
  i = strcmp (  varpar( : , 1 )  ,  'fradius'  ) ;
  varpar{ i , 3 } = sqrt ( x ^ 2  +  y ^ 2 ) ;

  % Formation circle rotation
  i = strcmp (  varpar( : , 1 )  ,  'frotation'  ) ;
  varpar{ i , 3 } = atand ( y / x ) ;
  
    % Correct the output of atand so that the returned angle points towards
    % coordinate ( x , y )
    if  x < 0
      
      % Special case , 180 degrees
      if  y == 0
        
        varpar{ i , 3 } = 180 ;
        
      % General case
      else
        
        varpar{ i , 3 } = varpar{ i , 3 }  +  sign ( y ) * 180 ;
        
      end
      
    end % correct atand output
  
  % Match central radius to RF diameter
  i = strcmp (  varpar( : , 1 )  ,  'centre_radius'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).width  /  2 ;
  
  % Set signal dot disparity equal to RF's preference
  i = strcmp (  varpar( : , 1 )  ,  'disp_signal'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).disparity ;
  
  
end % rds_Cumming99


%%% Stimulus definition handles %%%

% Trial initialisation function
function  Sret = finit ( vpar , tconst , Sold )
  
  
  %%% Check parameters %%%
  
  % Monoscopic mode
  if  ~ tconst.stereo
    
    error (  'MET:rds_Cumming99:badparam'  ,  [ 'rds_Cumming99: ' , ...
      'Cannot run in monocular mode' ]  )
    
  % Neither ffirst , flast , fyoke, nor fposition may exceed N
  elseif  any( vpar.fnumrds  <  ...
      [ vpar.ffirst , vpar.flast , vpar.fyoke , vpar.fposition ] )
    
    error (  'MET:rds_Cumming99:badparam'  ,  [ 'rds_Cumming99: ' , ...
      'Neither ffirst (%d) , flast (%d) , fyoke (%d) , nor ' , ...
      'fposition (%d) may exceed fnumrds (%d)' ]  ,  ...
      vpar.ffirst  ,  vpar.flast  ,  vpar.fyoke  ,  vpar.fposition  ,  ...
      vpar.fnumrds  )
    
  % ffirst must be less than or equal to flast
  elseif  vpar.flast  <  vpar.ffirst
    
    error (  'MET:rds_Cumming99:badparam'  ,  [ 'rds_Cumming99: ' , ...
      'ffirst (%d) must not exceed flast (%d)' ]  ,  vpar.ffirst  ,  ...
      vpar.flast  )
    
  end % varpar check
  
  
  %%% Build stimulus descriptor %%%
  
  % Make a data object for storing all information about the stimulus ,
  % this might be a previously defined instance of the function if Sold is
  % not empty
  if  ~ isempty ( Sold )
    
    % Retrieve existing data object
    S = Sold ;
    
  % This is the first use of rds_Cumming99 this session , we need to get a
  % new instance of the data object
  else
    
    S = rds_Cumming99_handle ;
    
  end % get data object
  
  % Form return struct that has a reference to this object
  Sret.S = S ;
  
  % Keep a copy of variable parameters in their original units
  S.vp = vpar ;
  
  % List stimulus constant parameters i.e. these ignore stimulus events
  S.const = { 'fnumrds' , 'ffirst' , 'flast' , 'centre_radius' , ...
    'surround_width' , 'dot_type' , 'dot_width' , 'dot_density' , ...
    'hminrad' } ;
  
  
  %-- Formation circle --%
  
  % Formation circle coordinates, on the PTB axes
  S.fcxy = fcentre ( tconst , S ) ;
  
  % The location of each RDS centre relative to the formation circle
  % coordinate
  S.frdsxy = frdscentre ( tconst , S ) ;
  
  % The number of presented RDSs , which may differ from the number of RDS
  % positions
  S.RDSn = S.vp.flast  -  S.vp.ffirst  +  1 ;
  
  
  %-- Greyscale values for light and dark --%
  
  % Find the two greyscale sets for light and dark
  S = grey ( S ) ;
  
  
  %-- Lifetime --%
  
  % Get number of frames per RDS stere image
  S = frames ( tconst , S ) ;
  
  
  %-- Flicker --%
  
  % Find number of frames per half cycle, starting state of frame counter,
  % and starting state of image
  S = flicker ( tconst , S , true , true ) ;
  
  
  %-- Dot size limits --%
  
  % Get minimum and maximum dot size in pixels , draws nothing
  [ S.dotmin , S.dotmax ] = Screen ( 'DrawDots' , tconst.winptr ) ;
  
  
  %-- Variable parameters , change unit to pixels --%
  
  % Central area radius
  S.crad = S.vp.centre_radius  *  tconst.pixperdeg ;
  
  % Annular surround width
  S.swid = S.vp.surround_width  *  tconst.pixperdeg ;
  
  % RDS radius
  S.rdsrad = S.crad  +  S.swid ;
  
  % Squared central radius
  S.crad2 = S.crad  ^  2 ;
  
  % Squared RDS radius
  S.rdsrad2 = S.rdsrad  ^  2 ;
  
  % Difference of squared radii
  S.drad2 = S.rdsrad2  -  S.crad2 ;
  
  % Dot width
  S.dotwid = S.vp.dot_width  *  tconst.pixperdeg ;
  
  % Cap dot width to hardware limits , issue a warning at need
  wstr = '' ;
  
  if  S.dotwid  <  S.dotmin
    
    % Dot is too small , cap to minimum
    S.dotwid = S.dotmin ;
    
    % Problem string
    wstr = 'small' ;
    
  elseif  S.dotwid  >  S.dotmax
    
    % Dot is too large , cap to maximum
    S.dotwid = S.dotmax ;
    
    % Problem string
    wstr = 'large' ;
    
  end % cap dot width
  
  % Dot-width warning issued
  if  ~ isempty ( wstr )
    
    % Build warning string
    wstr = sprintf (  [ 'rds_Cumming99: dot width %f is too %s , ' , ...
      'capping at hardware limit of %f' ]  ,  S.vp.dot_width , wstr , ...
      S.dotwid / tconst.pixperdeg  ) ;
    
    % Send warning
    met (  'print'  ,  wstr  ,  'E'  )
  
  end % dot-width warning
  
  % Find disparities
  S = fdisp ( tconst , S , true , true , true ) ;
  
  
  %-- Measure area , in pixels squared --%
  
  % Area of one dot
  if  S.vp.dot_type
    
    % Round dots
    S.adot = pi  *  ( S.dotwid / 2 ) ^ 2 ;
    
    % While we're at it , get the PTB code for high-quality round dots
    S.dot_type = 2 ;
    
  else
    
    % Square dots
    S.adot = S.dotwid ^ 2 ;
    
    % PTB dot type code for squares
    S.dot_type = 0 ;
    
  end % dot area
  
  % Area of RDS
  S.ards = pi  *  S.rdsrad2 ;
  
  % Area of centre
  S.acen = pi  *  S.crad2 ;
  
  % Area of surround
  S.asur = S.ards  -  S.acen ;
  
  % Calculate areas of central circle that lose dot density when a
  % horizontal disparity is applied to signal dots. Do so first for the
  % maximum allowable disparity.
  S = acfill ( S , S.swid ) ;
  
  % Calculate the maximum number of dots required to replenish the central
  % area, assuming maximum allowable disparity and no noise dots. Per RDS.
  S.Ncfillmax = floor (  S.vp.dot_density  *  S.acfill  /  S.adot  ) ;
  
  % Now re-calculate central areas using the current signal disparity
  S = acfill ( S , S.hsig ) ;
  
  
  %-- Number of dots per area , per RDS --%
  
  % Number of dots in RDS with no signal dot disparity
  S.Nrds = ceil (  S.vp.dot_density  *  S.ards  /  S.adot  ) ;
  
  % Number of dots in the annular surround
  S.Nsur = floor (  S.asur  /  S.ards  *  S.Nrds  ) ;
  
  % Number of dots in the circular centre
  S.Ncen = S.Nrds  -  S.Nsur ;
  
  % Number of signal and noise dots
  S = numdots ( S , true , true ) ;
  
  % Number of binocularly contrast correlated signal and noise dots
  S = numcorr ( S , true , true , true , false ) ;
  
  % Number of uncorrelated dots i.e. dots with independently sampled
  % positions in each monocular image
  S = numuncorr ( S , true , true ) ;
  
  % Maximum possible total number of dots per RDS
  S.Ntotalmax = S.Nrds  +  S.Ncfillmax ;
  
  % Maximum grand total number of dots , across RDSs
  S.Ngtotalmax = S.Ntotalmax  *  S.RDSn ;
  
  
  %-- Define dot buffers --%
  
  % Buffers that represent all dots have enough capacity to store all dots
  % when signal dots are at maximum magnitude of disparity. These are
  % treated as 2D arrays, where each element refers to one dot but may
  % contain a tuple. Array size is treated as [ S.Ntotal , S.RDSn ]. That
  % is, row indexing across dots and column indexing across RDSs. Dot types
  % are arranged into blocks. The first is a S.Nsur + S.Ncfill row block
  % that represents background dots in the surround and re-filled central
  % zone. Starting at row S.Nsur + S.Ncfill + 1, a second block of S.Nsig
  % rows represents all signal dots. Lastly, from row S.Nsur + S.Ncfill +
  % S.Nsig + 1, a final block of S.Nnoise rows represent all noise dots.
  
  % Size of '2D' array
  S.s = [ S.Ntotal , S.RDSn ] ;
  
  % Column index vector for all RDSs
  S.c = 1 : S.RDSn ;
  
  % Obtain indices for the first row in each block ; including ib -
  % background dots, is - signal dots, in - noise dots.
  S.ib = 1 ;
  S.is = S.Nsur  +  S.Ncfill  +  1 ;
  S.in = S.is  +  S.Nsig ;
  
  % Dot life timer i.e. image timer. This counts down the number of frames
  % per RDS image. Initialise zero so that an image is created on first
  % call to stimulation function.
  S.timer = 0 ;
  
  % Allocation flag , true if we actually need to alocate space for each
  % buffer , this is the case if we are using this stimulus for the first
  % time and the data object has also not been used yet. Or, the properties
  % of the RDS have differed from the last trial and require a different
  % number of dots.
  ALLOCF = size( S.xy , 2 )  ~=  S.Ngtotalmax ;
  
  % Dot coordinates. We generate random numbers to get a meaningful
  % checksum. The two layers i.e. 3rd dimensional elements are two dot
  % position buffers. The first layer i.e. S.xy( : , : , 1 ) contains the
  % position of dots as seen by the left eye. The second layer
  % S.xy( : , : , 2 ) contains the position of dots as seen by the right
  % eye. That is, dot positions are stored with disparities applied. This
  % permits dynamic changes in the number of uncorrelated dots.
  if  ALLOCF  ,  S.xy = zeros ( 2 , S.Ngtotalmax , 2 ) ;  end
  S.xy( : , : , : ) = rand ( 2 , S.Ngtotalmax , 2 ) ;
  
  % Monocular visibility buffer. Logical index. Rows indexed by eye frame
  % buffer: 1 for left and 2 for right.
  if  ALLOCF  ,  S.v = false ( 2 , S.Ngtotalmax ) ;  end
  
  % Randomly permuted visibility buffer
  if  ALLOCF  ,  S.vrp = false ( 2 , S.Ngtotalmax ) ;  end
  
  % Dot greyscale index , only ever 1 or 2 so use small integers. Rows are
  % indexed by eye frame buffer.
  if  ALLOCF  ,  S.gi = zeros ( 2 , S.Ngtotalmax , 'uint8' ) ;  end
  
  % Randomly permuted greyscale index
  if  ALLOCF  ,  S.girp = zeros ( 2 , S.Ngtotalmax , 'uint8' ) ;  end
  
  % Noise dot disparity buffer. We are required to use a single sample of
  % noise disparities per trial. Recycle the random numbers used to
  % initialise S.xy for this. We keep them in the 0 to 1 range for dynamic
  % changes to disp_nlim. But that is only in row 1. Row 2 contains the
  % absolute disparity values for a half-shift in one monocular image ;
  % these values can be added to dots with some existing disparity in order
  % to add noise.
  if  size( S.ndisp , 2 )  ~=  S.RDSn * S.Ncen
    S.ndisp = zeros ( 2 , S.RDSn * S.Ncen ) ;
  end
  S.ndisp( : , : ) = S.xy(  :  ,  1 : S.RDSn * S.Ncen  ) ;
  
  
  %-- Initialise dot buffer --%
  
  % Set the greyscale index for each dot, in each eye
  S = igrey ( S , true , true , true , true ) ;
  
  % Set the signal and noise dots to be visible in both eyes
  i = mets2i ( S.s , S.is : S.Ntotal , S.c , true ) ;
  S.v( : , i ) = 1 ;
  
  % If there is no signal dot disparity then all surrounding background
  % dots are visible
  if  S.vp.disp_signal + S.vp.disp_deltasig  ==  0
    i = mets2i ( S.s , 1 : S.Nsur , S.c , true ) ;
    S.v( : , i ) = 1 ;
  end
  
  % Compute noise absolute disparity values
  S.ndisp( 2 , : ) = S.dnmin  +  S.dnrng * S.ndisp( 1 , : ) ;
  
  
  %-- Hit regions --%
  
  % We will use the 5-column form defining a set of circular regions
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  if  isempty ( S.hitregion )
    S.hitregion = zeros ( S.RDSn , 6 ) ;
  end
  
  % Initialise hit region radius and disparity
  S.hitregion( : , c6.radius ) = max ( [  S.vp.hminrad  ,  ...
    S.vp.centre_radius + S.vp.surround_width  ] ) ;
  S.hitregion( : , c6.disp   ) = S.vp.disp_base  +  tconst.origin( 3 ) ;
  S.hitregion( : , c6.dtoler ) = S.vp.hdisptol ;
  
  % Initialise hit region positions
  S.hitregion( : , [ c6.xcoord , c6.ycoord ] ) = hitregpos ( tconst , S ) ;
  
  % Set whether or not to ignore the stimulus
  S.hitregion( : , c6.ignore ) = S.vp.hitcheck ;
  
  % Return struct must point to hitregion
  Sret.hitregion = S.hitregion ;
  
  
end % finit


% Stimulation function
function  [ Sio , h ] = fstim ( Sio , tconst , tvar )
  
  % Access data object from input/output struct
  S = Sio.S ;
  
  
  %%% Update the stimulus values %%%
  
  % Hit region update not expected by default
  h = false ;
  
  % Only update variable parameters or dot positions if this is the
  % left-eye frame buffer i.e. only do this once per stereo image
  if  tvar.eyebuf  <  1
    
    
    %-- Variable parameter changes --%

    % Any variable parameters changed?
    if  ~ isempty ( tvar.varpar )
      
      
      %   Get/make lists   %
      
      % Point to the list of variable parameter changes
      vp = tvar.varpar ;

      % Make a struct that tracks which parameters were changed , d for
      % delta i.e. change. There is one field for every variable parameter,
      % and has the same name.
      F = fieldnames( S.vp )' ;
      F = [  F  ;  num2cell(  false( size( F ) )  )  ] ;
      d = struct (  F { : }  ) ;
      
      
      %   New values   %
    
      for  i = 1 : size ( vp , 1 )

        % Ignored variable parameter change , skip to next
        if  any ( strcmp(  vp{ i , 1 }  ,  S.const  ) )
          continue
        end
        
        % Save in stimulus descriptor's copy of variable parameters
        S.vp.( vp{ i , 1 } ) = vp{ i , 2 } ;

        % Mark as changed
        d.( vp{ i , 1 } ) = true ;

      end % new values
      
      
      %   Update stimulus descriptor   %
      
      % Formation circle coordinate change , raise hitregion flag
      if  d.fxcoord  ||  d.fycoord
        S.fcxy = fcentre ( tconst , S ) ;
        h = true ;
      end
      
      % RDS formation change , raise hitregion flag
      if  d.fradius  ||  d.frotation  ||  d.fyoke  ||  d.fposition
        S.frdsxy = frdscentre ( tconst , S ) ;
        h = true ;
      end
      
      % Dot lifetime change
      if  d.dot_lifetime  ,  S = frames ( tconst , S ) ;  end
      
      % Flicker rate or phase change
      S = flicker (  tconst ,  S ,  ...
         d.flick_rate_left ||  d.flick_rate_right ,  ...
        d.flick_phase_left || d.flick_phase_right  ) ;
      
      % Contrast change
      if  d.dot_contrast  ,  S = grey ( S ) ;  end
      
      % Disparity changes
      S = fdisp ( tconst , S , d.disp_base , ...
        d.disp_signal || d.disp_deltasig , d.disp_nlim ) ;
      
      % Signal disparity change
      if  d.disp_signal  ||  d.disp_deltasig
        
        % Update area of re-fill zone in centre
        S = acfill ( S , S.hsig ) ;
        
        % If there is no signal dot disparity then all annular surrounding
        % background dots are visible
        if  S.dsig  ==  0
          i = mets2i ( S.s , 1 : S.Nsur , S.c , true ) ;
          S.v( : , i ) = 1 ;
        end
        
      end % signal disparity change
      
      % Noise disparity change , compute noise absolute disparity values
      if  d.disp_nlim
        S.ndisp( 2 , : ) = S.dnmin  +  S.dnrng * S.ndisp( 1 , : ) ;
      end
      
      % Number of signal and noise dots
      S = numdots (  S  ,  d.signal_fraction  ,  ...
        d.signal_fraction || d.disp_signal || d.disp_deltasig  ) ;
      
      % Number of uncorrelated dots
      S = numuncorr (  S  ,  d.uncorr_back  ,  ...
        d.signal_fraction || d.uncorr_noise  ) ;
      
      % Number of background or signal and noise dots has changed
      if  d.disp_signal  ||  d.disp_deltasig  ||  d.signal_fraction
        
        % Recompute starting indeces for blocks of rows
        S.s( 1 ) = S.Ntotal ;
        S.is = S.Nsur  +  S.Ncfill  +  1 ;
        S.in = S.is  +  S.Nsig ;
        
        % And set the signal and noise dots to be visible in both eyes
        i = mets2i ( S.s , S.is : S.Ntotal , S.c , true ) ;
        S.v( : , i ) = 1 ;
  
      end % dot type row indeces & visibility

      % Number of binocularly contrast correlated signal and noise dots
      S = numcorr (  S ,  d.anticor_back ,  d.anticor_sig ,  ...
        d.anticor_noise ,  d.signal_fraction  ) ;
      
      % Greyscale index , per eye
      S = igrey (  S ,  d.disp_signal || d.disp_deltasig ,  ...
        d.signal_fraction ,  d.anticor_back ,  d.anticor_sig ,  ...
        d.anticor_noise  ) ;
      
      % Hit region changed
      if  h  ||  d.hitcheck  ||  d.hdisptol
        
        % Get hit region index constants
        c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
        
        % Change position of hit regions
        if  h

          S.hitregion( : , [ c6.xcoord , c6.ycoord ] ) = ...
            hitregpos ( tconst , S ) ;

        end
        
        % Hit region ignore flag has changed status , set to new value and
        % raise hit region flag
        if  d.hitcheck
          S.hitregion( : , c6.ignore ) = S.vp.hitcheck ;
          h = true ;
        end
      
        % Hit region disparity tolerance changed , raise hit region flag if
        % not already done
        if  d.hdisptol
          S.hitregion( : , c6.dtoler ) = S.vp.hdisptol ;
          h = true ;
        end
        
        % Make sure that output struct has refreshed hitregion#
        Sio.hitregion = S.hitregion ;
      
      end % hit region change
      
      
    end % variable parameter changes
    
    
    %-- Generate new image --%
    
    % Image lifetime expired
    if  ~ S.timer
      
      % Reset timer
      S.timer = S.frames ;
      
      
      %   Do the easy things first   %
      
      % Find signal and noise dot indices , ...
      N = S.Ncen  *  S.RDSn ;
      i = mets2i (  S.s ,  S.is : S.Ntotal ,  S.c ,  true  ) ;
      
      % ... and sample dot positions relative to RDS centre.
      S.xy( : , i , 1 ) = rnddot (  N  ,  S.crad2  ,  0  ) ;
      
      % Check to see if there are any uncorrelated noise dots
      if  S.Nuncorn
        
        % Find indices of uncorrelated noise dots. We will uncorrelate the
        % first N noise dots.
        i = mets2i (  S.s ,  S.in : S.in + S.Nuncorn - 1 ,  S.c ,  true  );
        
        % Total number of uncorrelated noise dots
        N = S.Nuncorn  *  S.RDSn ;
        
        % Sample noise dot positions for right eye image
        S.xy( : , i , 2 ) = rnddot (  N  ,  S.crad2  ,  0  ) ;
        
        % Now get the subset of positionally correlated central dots. These
        % exist on either side of the uncorrelated dots because of
        % functionality that has since been removed from the stimulus. It
        % could be fixed ; but a rapid solution is presently required.
        i = mets2i (  S.s  ,  [ S.is : S.is + S.Nsig - 1 , ...
          S.in + S.Nuncorn : S.in + S.Nnoise - 1 ]  ,  ...
            S.c  ,  true  ) ;
        
      end % uncorrelated noise dots

      % Copy left-eye dot buffer to right-eye dot buffer for all signal
      % dots
      S.xy( : , i , 2 ) = S.xy( : , i , 1 ) ;
      
      % There is baseline or signal dot disparity
      if  S.hbase  ||  S.hsig
        
        % Absolute disparity of a half-shift
        adisp = S.hbase  +  S.hsig ;

        % Apply disparity to the left- ...
        S.xy( 1 , i , 1 ) = S.xy( 1 , i , 1 )  -  adisp ;
        
        % ... and right-eye monocular images
        S.xy( 1 , i , 2 ) = S.xy( 1 , i , 2 )  +  adisp ;
        
      else
        
        % We need a sensible value for adisp when adding disparity noise ,
        % next section
        adisp = 0 ;
        
      end % signal dot disparity
      
      % If there are positionally correlated noise dots, and noisy
      % disparities
      if  S.Nuncorn < S.Nnoise  &&  S.vp.disp_nlim
        
        % Get indices of correlated noise dots ...
        i = mets2i (  S.s ,  S.in + S.Nuncorn : S.in + S.Nnoise - 1 ,  ...
          S.c ,  true  ) ;
        
        % The total number of correlated noise dots
        N = ( S.Nnoise  -  S.Nuncorn )  *  S.RDSn ;
        
        % Find the right-hand x-axis location of the edge of the central
        % circle at the same y-axis location as each noisy dot
        j = sqrt (  S.crad2  -  S.xy( 2 , i , 1 ) .^ 2  ) ;
        
        % Calculate noise weight , this is the distance of noisy dots to
        % the edge of the centre divided by one half disparity shift of
        % maximum range of disparity noise. This will taper the amount of
        % extra noisy disparity towards zero as the dot gets closer to the
        % edge.
        j = ( j  -  abs( S.xy( 1 , i , 1 )  +  adisp ) )  /  S.dnhsh ;
        
        % Cap weights at 1
        j( 1 < j ) = 1 ;
        
        % Compute weighted disparity noise
        j = j  .*  S.ndisp( 2 , 1 : N ) ;
        
        % Apply noise to the left- ...
        S.xy( 1 , i , 1 ) = S.xy( 1 , i , 1 )  -  j ;
        
        % ... and right-eye monocular images
        S.xy( 1 , i , 2 ) = S.xy( 1 , i , 2 )  +  j ;
        
      end % noise dot disparity
      
      
      %   Sample background dots in annular surround   %
      
      % Find annular surround dots
      N = S.Nsur  *  S.RDSn ;
      i = mets2i (  S.s  ,  1 : S.Nsur  ,  S.c  ,  true  ) ;
      
      % And sample dot positions for the left eye
      S.xy( : , i , 1 ) = rnddot (  N  ,  S.drad2  ,  S.crad2  ) ;
      
      % Are there uncorrelated background dots?
      if  S.Nuncorb_surr
        
        % Yep , so find their indices
        j = mets2i (  S.s  ,  1 : S.Nuncorb_surr  ,  S.c  ,  true  ) ;
        
        % Total number of uncorrelated annular background dots
        N = S.Nuncorb_surr  *  S.RDSn ;
        
        % And sample new positions for the right eye
        S.xy( : , j , 2 ) = rnddot (  N  ,  S.drad2  ,  S.crad2  ) ;
        
        % Now get indices for correlated background dots
        i = mets2i (  S.s ,  S.Nuncorb_surr + 1 : S.Nsur ,  S.c ,  true  );
        
      else
        
        % No uncorrelated dots , return empty index vector
        j = [] ;
        
      end % uncorrelated dots
      
      % Copy left-eye dot positions to right-eye buffer for correlated
      % dots. At this point, i is the set of indices to correlated dots,
      % and j has indices to uncorrelated dots.
      S.xy( : , i , 2 ) = S.xy( : , i , 1 ) ;
      
      % We only need to check visibility if signal dot disparity is
      % non-zero
      if  S.dsig
      
        % Make another copy of the uncorrelated index vector for the
        % right-eye buffer. j is now for the left eye.
        k = j ;

        % Set all surround dots above or below the top/bottom of the centre
        % to be visible in both eyes
        S.v( 1 , i ) = S.crad  <=  abs( S.xy( 2 , i , 1 ) ) ;
        S.v( 2 , i ) = S.v( 1 , i ) ;
        
        S.v( : , j ) = S.crad  <=  ...
          abs(  [  S.xy( 2 , j , 1 )  ;  S.xy( 2 , j , 2 )  ]  ) ;

        % Find surround dots that are not above or below the centre ...
        i(  S.v( 1 , i )  ) = [] ;
        j(  S.v( 1 , j )  ) = [] ;
        k(  S.v( 2 , k )  ) = [] ;

        % ... and determine which of them are beyond the reach of the
        % signal dot disparity shift. Set those visible in both eyes, too.
        S.v( 1 , i ) = ...
          S.crad  +  abs( S.hsig )  <  abs( S.xy( 1 , i , 1 ) ) ;
        S.v( 2 , i ) = S.v( 1 , i ) ;
        
        S.v( 1 , j ) = ...
          S.crad  +  abs( S.hsig )  <  abs( S.xy( 1 , j , 1 ) ) ;
        S.v( 2 , k ) = ...
          S.crad  +  abs( S.hsig )  <  abs( S.xy( 1 , k , 2 ) ) ;

        % Find surround dots that might be in danger of being covered by
        % disparity-shifted signal dots
        i(  S.v( 1 , i )  ) = [] ;
        j(  S.v( 1 , j )  ) = [] ;
        k(  S.v( 2 , k )  ) = [] ;

        % Determine which of the remaining background dots are visible to
        % which eyes
        S = vischk ( S , i , 'b' ) ; % , false ) ;
        S = vischk ( S , j , 'l' ) ; % , false ) ;
        S = vischk ( S , k , 'r' ) ; % , false ) ;
      
      end % check background dot visibility
      
      
      %   Sample in low-density zone of centre   %
      
      % Check if we actually need new dots
      if  S.Ncfill
      
        % Find first index of central background dots
        j = S.Nsur + 1 ;

        % If disparity is larger than the diameter of the centre ...
        if  S.crad  <=  abs ( S.hsig )

          % Then low density zone is the entire centre. Find remaining
          % background dots.
          N = S.Ncfill  *  S.RDSn ;
          i = mets2i (  S.s  ,  j : j + S.Ncfill - 1  ,  S.c  ,  true  ) ;

          % Sample dots as for signal and noise dots
          S.xy( : , i , 1 ) = rnddot (  N  ,  S.crad2  ,  0  ) ;
          
          % Are there uncorrelated background re-fill dots?
          if  S.Nuncorb_fill
            
            % Yep , so find their indices
            i = mets2i (  S.s ,  j : j + S.Nuncorb_fill - 1 ,  S.c ,  ...
              true  ) ;

            % Total number of uncorrelated fill dots
            N = S.Nuncorb_fill  *  S.RDSn ;
            
            % And sample new positions for the right eye
            S.xy( : , i , 2 ) = rnddot (  N  ,  S.crad2  ,  0  ) ;
            
            % Check which of uncorrelated fill dots are visible to each eye
            S = vischk ( S , i , 'l' ) ; % , false ) ;
            S = vischk ( S , i , 'r' ) ; % , false ) ;

            % Now get indices for correlated background re-fill dots
            i = mets2i (  S.s ,  S.Nuncorb_fill + j : S.Nsur ,  S.c ,  ...
              true  );
            
          end % uncorrelated refill
          
          % Copy correlated dot positions from left to right eye buffer
          S.xy( : , i , 2 ) = S.xy( : , i , 1 ) ;
          
          % Check which of correlated fill dots are visible to each eye
          S = vischk ( S , i , 'b' ) ; % , false ) ;

        % There is a lens in the centre that is covered by signal dots in
        % both monocular images
        else

          % Are there any segment dots?
          if  S.Nseg
          
            % Find dots in top and bottom segments of central area that
            % touch the top and bottom point of the lens. That is, find
            % segment dots. 
            N = S.Nseg  *  S.RDSn ;
            i = mets2i (  S.s  ,  j : j + S.Nseg - 1  ,  S.c  ,  true  ) ;

            % Sample coordinates , all in the top segment
            S.xy( : , i , 1 ) = rndsegdot ( N , S.pmin , S.prng , S.hsny );

            % Half of segment dots
            N = S.Nseg  /  2 ;

            % Odd number of segment dots , so round j down , and toss a
            % coin to decide which side of the segment will get the odd dot
            if  mod ( N , 1 )
              N = floor ( N )  +  ( rand  <  0.5 ) ;
            end
            
            % Are there uncorrelated segment dots?
            if  S.Nuncorb_segs
              
              % Find nested index vector of uncorrelated dots. This must
              % split them evenly top and bottom segments following
              % reflection (see below). Get half number of uncorr. seg dots
              k = S.Nuncorb_segs  /  2  *  [ 1 , 1 ] ;
              
              % Distribute dots between top and bottom segment based on
              % whether there is an odd or even number of them
              if  mod ( k , 1 )
                
                % Round down and up
                k = floor( k ) + [ 0 , 1 ] ;
                
                % Coin toss to decide which group the odd dot goes to
                if  rand  <  0.5
                  k = k( [ 2 , 1 ] ) ;
                end
                
              end % distribute
              
              % Row indices to expand across columns
              j = [  1 : k( 1 )  ,  N + 1 : N + k( 2 )  ] ;
              
              % Nested index vector
              j = mets2i (  [ S.Nseg , S.RDSn ] ,  j ,  S.c ,  true  ) ;
              
              % Sample right-eye coordinates for uncorrelated dots
              S.xy( : , i( j ) , 2 ) = ...
                rndsegdot ( numel( j ) , S.pmin , S.prng , S.hsny ) ;
              
            else
              
              % No uncorrelated segment dots , but we need k later to
              % generalise finding correlated dot indices
              k = [ 0 , 1 ] ;
              
              % There are no uncorrelated dots
              j = [] ;
              
            end % uncorrelated segment dots
            
            % Scale from unit circle to a circle with the centre's pixel
            % radius
            S.xy( : , i , : ) = S.crad  *  S.xy( : , i , : ) ;
            
            % Get uncorrelated dot indices
            j = i (  j  ) ;
            
            % And check which are visible to each eye. We don't need to
            % perform a reflection yet for this.
            S = vischk ( S , j , 'l' ) ; % , true ) ;
            S = vischk ( S , j , 'r' ) ; % , true ) ;
            
            % Nested index vector. Apply to i for half of the segment dots.
            j = mets2i (  [ S.Nseg , S.RDSn ] ,  1 : N ,  S.c ,  true  ) ;

            % Reflect half the segment dots from top to bottom
            S.xy( 2 , i( j ) , : ) = - S.xy( 2 , i( j ) , : ) ;
            
            % Find correlated dots
            j = [  k( 1 ) + 1 : N  ,  N + k( 2 ) : S.Nseg  ] ;
            j = mets2i (  [ S.Nseg , S.RDSn ] ,  j ,  S.c ,  true  ) ;
            i = i (  j  ) ;
            
            % And copy left-eye dot buffer to right
            S.xy( : , i , 2 ) = S.xy( : , i , 1 ) ;
            
            % Then do a visibility check
            S = vischk ( S , i , 'b' ) ; % , true ) ;
            
          end % segment dots

          % We can now sample in the right-hand curved rectangle
          N = S.Ncrec  *  S.RDSn ;
          i = mets2i (  S.s  ,  S.Nsur + S.Nseg + 1 : S.is - 1 ,  S.c  ,...
            true  ) ;

          % Get y-axis coordinates
          S.xy( 2 , i , 1 ) = 2 * S.hsny * rand ( 1 , N )  -  S.hsny ;

          % Compute x-coordinate of circle edge for each y-coordinate
          S.xy( 1 , i , 1 ) = ( 1  -  S.xy( 2 , i , 1 ) .^ 2 )  .^  0.5 ;

          % Sample x-coordinate of dots
          S.xy( 1 , i , 1 ) = S.xy( 1 , i , 1 )  -  ...
            S.hsnorm * rand ( 1 , N ) ;

          % Odd number of dots in the curved rectangle. Toss a coin to see
          % which side gets the odd dot.
          N = S.Ncrec  /  2 ;
          
          if  mod ( N , 1 )
            N = floor ( N )  +  ( rand  <  0.5 ) ;
          end

          % Nested index vector to half of dots in curved rectangle
          j = mets2i (  [ S.Ncrec , S.RDSn ] ,  1 : N ,  S.c ,  true  ) ;
          
          % Return subset of indices, k now refers to dots on the left side
          % of the centre
          k = i (  j  ) ;

          % Reflect half of dots from right to left
          S.xy( 1 , k , 1 ) = - S.xy( 1 , k , 1 ) ;
          
          % Scale from unit circle to a circle with the centre's pixel
          % radius
          S.xy( : , i , 1 ) = S.crad  *  S.xy( : , i , 1 ) ;
          
          % Copy from left-eye dot buffer to right
          S.xy( : , i , 2 ) = S.xy( : , i , 1 ) ;
          
          % Nested index vector to other half of dots in curved rectangle
          j = mets2i (  [ S.Ncrec , S.RDSn ] ,  N + 1 : S.Ncrec ,  S.c ,...
            true  ) ;
          
          % Return dots on the right side of the centre
          j = i (  j  ) ;
          
          % The visibility of dots depends on what the direction of signal
          % dot disparity , positive or negative. Normalise variables so
          % that i holds indices to dots visible in left eye and j holds
          % dots visible in right.
          if  S.dsig  <  0
            
            % Negative, then dots on the left are visible to the left. j is
            % the way it should be
            i = k ;
            
          else
            
            % Positive, dots on the right are visible to the left ...
            i = j ;
            
            % ... and dots on the left are visible to the right
            j = k ;
            
          end
          
          % Make left-eye dots visible in left image but not right
          S.v( 1 , i ) = true  ;
          S.v( 2 , i ) = false ;
          
          % Make right-eye dots visible in right image but not left
          S.v( 1 , j ) = false ;
          S.v( 2 , j ) = true  ;

        end % sample in low-density zone
        
      end % refill low-density zone
      
      % Add basline disparity to visible backround dots
      if  S.hbase
        
        % Get indices to all background dots
        i = mets2i (  S.s  ,  1 : S.is - 1  ,  S.c  ,  true  ) ;

        % Apply disparity to the left- ...
        S.xy( 1 , i , 1 ) = S.xy( 1 , i , 1 )  -  S.hbase ;
        
        % ... and right-eye monocular images
        S.xy( 1 , i , 2 ) = S.xy( 1 , i , 2 )  +  S.hbase ;
        
      end % baseline to visible 
      
      
      %   Translate each RDS into position   %
      
      % RDS index vector
      i = repmat (  S.vp.ffirst : S.vp.flast  ,  S.Ntotal  ,  1  ) ;
      
      % Add RDS position to dots
      S.xy( : , 1 : S.Ngtotal , : ) = S.xy( : , 1 : S.Ngtotal , : )  +  ...
        repmat( S.frdsxy( : , i ) ,  1 ,  1 ,  2 ) ;
      
      
      %   Randomly permute the drawing order  %
      
      % Linear index to used part of dot buffer
      i = 1 : S.Ngtotal ;
      
      % Random permutation of dot indices
      j = i ( randperm(  S.Ngtotal  ) ) ;
      
      % Apply this to the dot position, visibility, and greyscale index
      % buffers
      S.xy( : , i , : ) = S.xy( : , j , : ) ;
      S.vrp( : , i ) = S.v( : , j ) ;
      S.girp( : , i ) = S.gi( : , j ) ;
      
    end % new image
    
  end % left-eye frame buffer
  
  
  %%% Timer %%%
  
  % Right-eye target buffer , Screen Flip will occur before the next call
  % to fstim
  if  tvar.eyebuf  ==  1
    
   % Subtract a frame from the image timer
   S.timer = S.timer  -  1 ;
    
  end % Chose direction of disparity shift
  
  
  %%% Draw monocular image %%%
  
  % Set the anti-aliasing mode
  Screen ( 'BlendFunction' , tconst.winptr , ...
    'GL_SRC_ALPHA' , 'GL_ONE_MINUS_SRC_ALPHA' ) ;
  
  % Choose row index based on eye buffer index
  i = 1  +  tvar.eyebuf ;
  
  % Update flicker state for this monocular image. If nframes is zero then
  % flicker rate is also zero , meaning that image is always on.
  if  S.flick( i ).nframes
    
    % Flicker timer has run out. Thus finishes another half-cycle.
    if  S.flick( i ).timer  <=  0
      
      % Invert visibility state
      S.flick( i ).invisible = ~ S.flick( i ).invisible ;
      
      % And reset timer for another half-cycle
      S.flick( i ).timer = S.flick( i ).nframes ;
      
    end % timeout
    
    % Count down another frame from the timer
    S.flick( i ).timer = S.flick( i ).timer  -  1 ;
    
  end % flicker state
  
  % Monocular image is in second half of flicker cycle i.e. not visible so
  % terminate function before drawing to frame buffer. Or monovis flag does
  % not allow this image to be seen.
  if  S.flick( i ).invisible  ||  ...
      ( S.vp.monovis  &&  S.vp.monovis ~= tvar.eyebuf + 1 )
    return
  end
  
  % Dot linear permuted index vector. Only draw dots visible to this eye.
  j = S.vrp(  i  ,  1 : S.Ngtotal  ) ;
  
  % Draw to the frame buffer
  Screen (  'DrawDots'  ,  tconst.winptr  ,  S.xy( : , j , i )  ,  ...
    S.dotwid  ,  S.g( : , S.girp( i , j ) )  ,  S.fcxy  ,  S.dot_type  ) ;
  
  
end % fstim


% Trial closing function
function  Sout = fclose ( Sin , type )

  % React to the requested type of stimulus closure
  switch  type
    
    % Close trial
    case  't'
      
      % Return the data object for use on the next trial
      Sout = Sin.S ;
      
    % Close session
    case  's'
      
      % Destroy data object
      delete (  Sin.S  )
      
      % Return empty array
      Sout = [] ;
    
  end % type of closure
  
end % close


% Check-sum function
function  c = fchksum ( Sin )
  
  % Index used part of dot buffer
  i = mets2i ( [ 2 , Sin.S.Ngtotal ] , 1 : 2 , 1 : Sin.S.Ngtotal , true ) ;

  % Return sorted sum
  c = sum ( sort(  Sin.S.xy(  i ( : )  )  ) ) ;
  
end % chksum


%%% Sub-routines %%%


% Absolute screen location of the formation circle centre.
function  c = fcentre ( tconst , S )
  
  % Centre of formation circle from the centre of the screen , in degrees
  c = [ S.vp.fxcoord , S.vp.fycoord ]  +  tconst.origin( 1 : 2 ) ;
  
  % Convert unit from degrees to pixels and add the pixel coordinates of
  % the centre of the screen
  c = tconst.pixperdeg * c  +  [ tconst.wincentx , tconst.wincenty ] ;
  
  % Rmember to convert y-axis coordinate to PTB coordinate system where
  % down is up
  c( 2 ) = tconst.winheight  -  c( 2 ) ;
  
end % fcentre


% Pixel coordinates of each RDS centre on screen. Columns are indexed by
% RDS, so that xy( : , i ) is the centre of the ith RDS. This is different
% from RDS positions, which are fixed around the formation circle, but can
% be assigned to different RDSs.
function  xy = frdscentre ( tconst , S )
  
  % Number of RDS positions
  N = S.vp.fnumrds ;
  
  % Formation circle radius , in pixels
  radpix = S.vp.fradius  *  tconst.pixperdeg ;
  
  % Angle of each RDS position , counter-clockwise around the formation
  % circle.
  a = 360 / N  *  ( 0 : N - 1 )  +  S.vp.frotation ;
  
  % Change RDS positions from polar to Cartesian coordinates , in pixels
  % from the centre of the formation circle. The reflection accounts for
  % the PTB coordinate system.
  xy = [  + radpix  *  cosd( a )  ;  - radpix  *  sind( a )  ] ;
  
  % Translate RDS positions so that the yoked position is centred in the
  % middle of the formation circle
  if  S.vp.fyoke
    
    % Patch index
    y = S.vp.fyoke ;
    
    % Translate positions
    xy( 1 , : ) = xy ( 1 , : )  -  xy ( 1 , y ) ;
    xy( 2 , : ) = xy ( 2 , : )  -  xy ( 2 , y ) ;
    
  end % formation yoke
  
  % Re-order RDS positions so that first, second, ... Nth RDS are placed
  % starting at fposition. Start by making an index vector that will
  % re-order the RDS positions
  i = mod (  ( 0 : N - 1 ) + S.vp.fposition - 1  ,  N  )  +  1 ;
  
  % Re-order RDS to RDS position mapping
  xy = xy ( : , i ) ;
  
end % xyrdsc


% Calculates the greyscale value for light and dark to obtain the given
% Michelson contrast. Assumes a mid-grey background.
function  S = grey ( S )
  
  % Column 1 is light , 2 is dark
  S.g = [ 0.5 , -0.5 ] * S.vp.dot_contrast  +  0.5 ;
  
  % Per colour channel
  S.g = repmat (  S.g  ,  3  ,  1  ) ;
  
end % grey


% Find the number of frames per RDS image
function  S = frames ( tconst , S )
  
  % Number of seconds given
  if  S.vp.dot_lifetime
    
    % Unit convert seconds to frames , rounding to nearest frame
    S.frames = round (  S.vp.dot_lifetime  /  tconst.flipint  ) ;
    
    % Guarantee at least one frame
    S.frames = max ( [  1  ,  S.frames  ] ) ;
  
  % dot_lifetime is zero , code for 1 frame
  else
    
    S.frames = 1 ;
    
  end
  
end % frames


% Calculate monocular image flicker properties. Flags left and right say
% whether to compute this for each respective monocular image.
function  S = flicker ( tconst , S , left , right )
  
  % Flag vector , invert values so that a raised value in f says NOT to
  % compute flicker values
  f = ~ [ left , right ] ;
  
  % Loop left and right
  for  i = 1 : 2
    
    % Not setting flicker properties for this image , go to next image
    if  f ( i )  ,  continue  ,  end
    
    % Get rate and phase
    switch  i
      
      % Left eye
      case  1  ,  r = S.vp.flick_rate_left ;   p = S.vp.flick_phase_left ;
        
      % Right eye
      case  2  ,  r = S.vp.flick_rate_right ;  p = S.vp.flick_phase_right ;
        
    end % rate and phase
    
    % Flicker rate is zero
    if  r  ==  0
      
      % Image always on
      S.flick( i ).nframes = 0 ;
      S.flick( i ).timer = 0 ;
      S.flick( i ).invisible = false ;
      
      % Next eye
      continue
      
    end % zero flicker rate
    
    % Convert rate from Hertz to number of frames per half-cycle
    hc = round (  1  /  r  /  tconst.flipint  /  2  ) ;
    
    % Guarantee at least one frame per half-cycle
    hc = max ( [  1  ,  hc  ] ) ;
    
    % Number of frames in a full cycle
    fc = 2  *  hc ;
    
    % Convert starting phase from degrees to frames. Round up to nearest
    % frame.
    p = round ( p  /  360  *  fc ) ;
    
    % Store number of frames per half-cycle
    S.flick( i ).nframes = hc ;
    
    % Determine number of frames remaining in current half-cycle
    S.flick( i ).timer = hc  -  mod ( p , hc ) ;
    
    % Determine whether image is currently visible
    S.flick( i ).invisible = hc <= p  &&  p < fc ;
    
  end % left / right
  
end % flicker


% Unit conversion of disparities from degrees to pixels. Non-zero flags say
% whether to update the baseline ( bd ) , signal ( sd ) , or noise ( nd )
% disparity values
function  S = fdisp ( tconst , S , bd , sd , nd )
  

  % Make sure that relative signal and noise disparities are capped at this
  % maximum relative disparity , twice the width of the annular region
  dmax = 2 * S.swid ;

  % Update baseline
  if  bd
  
    % Baseline disparity , add disparity of trial origin
    S.dbase = ...
      ( S.vp.disp_base + tconst.origin( 3 ) )  *  tconst.pixperdeg ;

    % Half-baseline disparity
    S.hbase = S.dbase  /  2 ;
  
  end % baseline
  
  
  % Update signal disparities
  if  sd
  
    % Signal disparity
    S.dsig = ...
      ( S.vp.disp_signal + S.vp.disp_deltasig )  *  tconst.pixperdeg ;

    % Signal relative disparity exceeds maximum magnitude
    if  abs ( S.dsig )  >  dmax

      % Cap at maximum or minimum
      S.dsig = dmax  *  sign ( S.dsig ) ;

      % Issue warning
      met (  'print'  ,  sprintf ( [ 'rds_Cumming99: capping ' , ...
        'relative signal disparity at 2 x surround width %f' ] , ...
          S.dsig / tconst.pixperdeg )  ,  'E'  )

    end % cap signal disp

    % Half signal disparity
    S.hsig = S.dsig  /  2 ;

    % Half-signal disparity , normalised for the unit circle. Also
    % normalised to positive value. BEWARE: .hsnorm drops disparity
    % direction.
    S.hsnorm = abs (  S.hsig  /  S.crad  ) ;
    
    % Corresponding y-coordinate
    S.hsny = ( 1  -  S.hsnorm ^ 2 )  ^  0.5 ;
    
    % Get the Wigner semicircle distribution CDF at the normalised
    % disparity, subtract 0.5, and multiply by 2 for the full range of
    % probabilities to sample.
    S.prng = (  S.hsnorm  *  S.hsny  +  asin ( S.hsnorm )  )  /  pi  *  2 ;
    
    % Determine the minimum probability value to sample
    S.pmin = 0.5  *  ( 1 - S.prng ) ;
  
  end % signal or baseline
  
  
  % Update noise disp values
  if  nd
    
    % Noise disparity range for a half-shift. When a half shift is applied
    % twice to a zero-disparity dot position, once per monocular image,
    % then we get the full disparity.
    S.dnrng = S.vp.disp_nlim  *  tconst.pixperdeg ;

    % Noise minimum half disparity , add baseline to get absolute
    S.dnmin = - S.vp.disp_nlim  /  2  *  tconst.pixperdeg ;
    
    % Half disparity shift of maximum possible noise disparity, magnitune
    % only
    S.dnhsh = - S.dnmin ;
  
  end % noise
  
  
end % fdisp


% Calculate areas of central circle that need to be replenished when signal
% dots are horizontally disparity shifted by h pixels in each monocular
% image , for a total disparity of 2 * h
function  S = acfill ( S , h )

  % Take absolute value of disparity. The direction doesn't matter when
  % finding areas , only when finding visibility.
  h = abs ( h ) ;
  
  % If 1 / 2 horizontal disparity is more than central radius then there is
  % no lense or curved rectangular regions. That is, signal dots are
  % completely shifted off the central circle in both eyes.
  if  S.crad  <=  h
    
    % Lens
    S.theta = 0 ;
    S.alens = 0 ;
    
    % Re-fill region is entire central circle
    S.acfill = S.acen ;
    
    % Segments
    S.phi = pi ;
    S.aseg = S.acen ;
    
    % Covered part of annular surround , monocular
    S.gamma = pi ;
    S.abshift = S.acen ;
    
  % There is a lens in the central circle that is covered by signal dots
  % when monocular images are overlaid
  else
    
    % Angle spanning lens
    S.theta = 2  *  atan2 (  ( S.crad2  -  h ^ 2 ) ^ 0.5  ,  h  ) ;

    % Area of lens
    S.alens = S.crad2  *  ( S.theta  -  sin ( S.theta ) ) ;

    % The sub-region of the central area that requires new dots
    S.acfill = S.acen  -  S.alens ;

    % The angle spanning the top (or bottom) segment that caps the central
    % area. This is itself a subregion of the cfill area.
    S.phi = pi  -  S.theta ;

    % Area of the two segments , together
    S.aseg = S.crad2  *  ( S.phi  -  sin ( S.phi ) ) ;
    
    % A quarter disparity shift
    q = h  /  2 ;
    
    % When signal dots are horizontally shifted in a monocular image, then
    % there is a lense of the circular region of signal dots that will not
    % overlap the annular surround. Find the angle of this.
    S.gamma = 2  *  atan2 (  ( S.crad2  -  q ^ 2 ) ^ 0.5  ,  q  ) ;
    
    % Find area of the annular surround that is covered by shifted signal
    % dots. Yes, we subtract the area of a lens from a circle. This is
    % because the central circle of dots is shifted into the surround.
    % Overlapping that circle with the original central circle defines a
    % lens region. Take that region from a central circle and we get the
    % area of crescent in the overlapped part of the surround.
    S.abshift = S.acen  -  S.crad2 * ( S.gamma  -  sin ( S.gamma ) ) ;
    
  end % calc area based on disparity shift size
  
  % Area of curved rectangles , the complimentary region between segments
  % in cfill
  S.acrec = S.acfill  -  S.aseg ;
  
end % acfill


% Find the number of signal dots and noise dots in the central area , and
% also the number of dots required to replenish the central area after a
% signal dot disparity shift. When non-zero , flags say whether to
% calculate the number of signal and noise dots ( sn ) or the number of
% central re-fill dots ( cfill ).
function  S = numdots ( S , sn , cfill )

  % Find number of signal and noise dots
  if  sn
  
    % Number of signal dots
    S.Nsig = ceil (  S.vp.signal_fraction  *  S.Ncen  ) ;

    % Number of noise dots
    S.Nnoise = S.Ncen  -  S.Nsig ;
  
  end % s & n dots
  
  % Number of central refill dots
  if  cfill
    
    % Number of dots required to replenish low-density part of central
    % circle after signal dots are disparity shifted
    S.Ncfill = floor (  S.vp.dot_density  *  S.acfill  /  S.adot  ) ;
    
    % Number of dots in top and bottom segments , if there are any re-fill
    % dots
    if  S.Ncfill
      S.Nseg = floor (  S.aseg  /  S.acrec  *  S.Ncfill  ) ;
    else
      S.Nseg = 0 ;
    end
    
    % Number of dots in both curved rectangular areas
    S.Ncrec = S.Ncfill  -  S.Nseg ;
    
    % Total number of dots per RDS , after replenishing low-density central
    % area
    S.Ntotal = S.Nrds  +  S.Ncfill ;
    
    % Grand total number of dots , across all RDSs
    S.Ngtotal = S.Ntotal  *  S.RDSn ;
    
    % The annular surround is covered by a circular area of signal dots in
    % a monocular image. The number of background dots to keep i.e.
    % maintain visible in this area is found, here. This maintains the
    % overall dot density.
    S.Nbshift = floor (  ( 1 - S.vp.signal_fraction )  *  ...
      S.vp.dot_density  *  S.abshift  /  S.adot  ) ;
    
  end % refill dots
  
end % numsndots


% Find number of signal or noise dots that are binocularly correlated.
% Flags bd, sd, nd, and sf say whether correlation for background, signal
% or noise dots has changed (bd, sd, nd) or whether the signal fraction has
% changed (sf).
function  S = numcorr ( S , bd , sd , nd , sf )
  
  % Number of correlated background dots , in surround and in segments of
  % the central fill area
  if  bd
    S.Ncsur = ceil ( ( 1 - S.vp.anticor_back )  *  S.Nsur ) ;
    S.Ncseg = ceil ( ( 1 - S.vp.anticor_back )  *  S.Nseg ) ;
  end

  % Number of correlated signal dots
  if  sd || sf
    S.Ncsig = ceil ( ( 1 - S.vp.anticor_sig )  *  S.Nsig ) ;
  end
  
  % Number of correlated noise dots
  if  nd || sf
    S.Ncnoise = ceil ( ( 1 - S.vp.anticor_noise )  *  S.Nnoise ) ;
  end
  
end % numcorr


% Number of uncorrelated dots i.e. dots with independently sampled
% positions in each monocular image. Flags bd and nd say whether to
% recompute the number of uncorrelated background dots ( bd , annular
% surround and central refill ) or the number of uncorrelated noise dots
% ( nd ).
function  S = numuncorr ( S , bd , nd )
  
  % Number of uncorrelated background dots
  if  bd
    
    % Number of uncorrelated dots in the annular surround
    S.Nuncorb_surr = ceil ( S.vp.uncorr_back  *  S.Nsur ) ;
    
    % Number of uncorrelated dots in circlular centre, if it is fully
    % visible
    S.Nuncorb_fill = ceil ( S.vp.uncorr_back  *  S.Ncfill ) ;
    
    % Number of uncorrelated dots in the central refill segments
    S.Nuncorb_segs = ceil ( S.vp.uncorr_back  *  S.Nseg ) ;
    
  end % background dots
  
  % Number of uncorrelated noise dots
  if  nd  ,  S.Nuncorn = ceil ( S.vp.uncorr_noise  *  S.Nnoise ) ;  end
  
end % numuncorr


% Set the greyscale index for each dot and eye. Non-zero flags indicate
% that number of background dots has changed ( b ), the proportion of
% signal to noise dots has changed ( sn ), the background dot correlation
% has changed ( rb ), the signal dot correlation has changed ( rs ), or the
% noise dot correlation has changed ( rn ).
function  S = igrey ( S , b , sn , rb , rs , rn )
  
  
  %%% No changes required %%%
  
  % Terminate function
  if  ~ ( b  ||  sn  ||  rb  ||  rs  ||  rn )  ,  return  ,  end
  
  
  %%% Load queue %%%
  
  % Queue array. Each row is a record describing which dots to set, and
  % what greyscale index to use for each eye. Column order [ starting row
  % index , ending row index , left eye greyscale index , right eye
  % greyscale index ]. Rows cover background-odd and -even, background
  % surround anticorrelated-odd and -even, background-odd and -event,
  % background segment anticorrelated-odd and -even, background curved
  % rectangle-odd and -even, signal correlated-odd and -even, signal
  % anticorrelated-odd and -even, noise correlated-odd and -even, noise
  % anticorrelated-odd and -even.
  q = [  1                    , S.Ncsur              , 1 , 1 ;
         2                    , S.Ncsur              , 2 , 2 ;
         S.Ncsur + 1          , S.Nsur               , 1 , 2 ;
         S.Ncsur + 2          , S.Nsur               , 2 , 1 ;
         S.Nsur + 1           , S.Nsur + S.Ncseg - 1 , 1 , 1 ;
         S.Nsur + 2           , S.Nsur + S.Ncseg - 1 , 2 , 2 ;
         S.Nsur + S.Ncseg     , S.Nsur + S.Nseg - 1  , 1 , 2 ;
         S.Nsur + S.Ncseg + 1 , S.Nsur + S.Nseg - 1  , 2 , 1 ;
         S.Nsur + S.Nseg      , S.is - 1             , 1 , 1 ;
         S.Nsur + S.Nseg + 1  , S.is - 1             , 2 , 2 ;
         S.is                 , S.is + S.Ncsig - 1   , 1 , 1 ;
         S.is + 1             , S.is + S.Ncsig - 1   , 2 , 2 ;
         S.is + S.Ncsig       , S.is + S.Nsig - 1    , 1 , 2 ;
         S.is + S.Ncsig + 1   , S.is + S.Nsig - 1    , 2 , 1 ;
         S.in                 , S.in + S.Ncnoise - 1 , 1 , 1 ;
         S.in + 1             , S.in + S.Ncnoise - 1 , 2 , 2 ;
         S.in + S.Ncnoise     , S.Ntotal             , 1 , 2 ;
         S.in + S.Ncnoise + 1 , S.Ntotal             , 2 , 1  ] ;
	
       
  % Find first queued record to use
  if  b  ||  rb
    
    % Different number of background dots , or different proportion of
    % anticorrelated ones
    f = 1 ;
    
  elseif  sn  ||  rs
    
    % Change in signal to noise dot ration , or number of anti. signal dots
    f = 11 ;
    
  elseif  rn
    
    % Change in number of anti. noise dots
    f = 15 ;
    
  else
    
    error ( 'MET:rds_Cumming99:impossible' , ...
      'rds_Cumming99: logical failure setting first record in igrey' )
    
  end % first record
  
  
  % Find last queued record to use
  if  b  ||  sn  ||  rn
    
    % Different num. background dots, sig-to-noise dot ratio , or num.
    % anti. noise dots
    l = size ( q , 1 ) ;
    
  elseif  rs
    
    % Different num. anti. signal dots
    l = 14 ;
    
  elseif  rb
    
    % Different num. anti. background dots
    l = 8 ;
    
  else
    
    error ( 'MET:rds_Cumming99:impossible' , ...
      'rds_Cumming99: logical failure setting last record in igrey' )
    
  end % last record
  
  
  %%% Update dot greyscale indices %%%
  
  % Loop each record in queue
  for  r = f : l
    
    % Get indices for this set of dots
    i = mets2i (  S.s  ,  q( r , 1 ) : 2 : q( r , 2 )  ,  S.c  ,  true  ) ;
    
    % Eyes have the same greyscale index
    if  q( r , 3 )  ==  q( r , 4 )
      
      % Set both eyes at once
      S.gi( : , i ) = q( r , 3 ) ;
      
    % Different greyscale indices
    else
      
      % Left eye
      S.gi( 1 , i ) = q( r , 3 ) ;
      
      % Right eye
      S.gi( 2 , i ) = q( r , 4 ) ;
      
    end % set greyscale index
    
  end % records
  
  
end % igrey


% Calculate the position of each hit region, in degrees from the trial
% origin
function  p = hitregpos ( tconst , S )
  
  % Indices of presented RDSs
  i = S.vp.ffirst : S.vp.flast ;
  
  % Get x-y coordinates relative to formation circle's centre , in pixels
  p = S.frdsxy ( : , i )' ;
  
  % Flip from PTB-style coordinate system to standard Cartesian
  p( : , 2 ) = -  p( : , 2 ) ;
  
  % Convert unit to degrees
  p = p  ./  tconst.pixperdeg ;
  
  % Add formation circle coordinate
  p( : , 1 ) = p( : , 1 )  +  S.vp.fxcoord  +  tconst.origin( 1 ) ;
  p( : , 2 ) = p( : , 2 )  +  S.vp.fycoord  +  tconst.origin( 2 ) ;
  
end % hitregpos


% Randomly sample n dot positions in an annular region. The difference of
% squared radii between inner and outer radius is given as width w. The
% squared inner radius is given as r. Returns x-axis position in row 1 and
% y-axis positions in row 2, where dots are indexed by column.
function  xy = rnddot ( n , w , r )
  
  % Sample uniformly distributed points. Row 1 will hold angular radii and
  % row 2 will hold angles. Each column provides the polar coordinates for
  % one dot.
  xy = rand ( 2 , n ) ;
  
  % Convert row 1 into radii
  xy( 1 , : ) = (  w  * xy( 1 , : )  +  r  )  .^  0.5 ;
  
  % And convert row 2 into angles, in radians
  xy( 2 , : ) = 2 * pi * xy( 2 , : ) ;
  
  % Transform polar coordinates to Cartesian and return
  xy( : , : ) = [  xy( 1 , : )  .*  cos( xy( 2 , : ) )  ;
                   xy( 1 , : )  .*  sin( xy( 2 , : ) )  ] ;
  
end % rnddot


% Randomly sample dot positions inside a segment at the top of a unit
% circle, such that the flat edge is parallel to the x-axis. Inputs are
% number of dots, minimum probability, probability range, y-coordinate
% where flat edge of segment intersects circle. Returns x- and y-coordinate
% vector, column indexed by dot ; coordinates are relative to the centre of
% the unit circle.
function  xy = rndsegdot ( N , pmin , prng , hsny )
  
  % No dots required? Return empty.
  if  ~ N
    xy = [] ;
    return
  end

  % Preallocate output array
  xy = zeros ( 2 , N ) ;

  % Start by generating a sample of probability values, within a certain
  % interval that corresponds to the full range of x-coordinates that we
  % want
  xy( 1 , : ) = prng * rand( N , 1 )  +  pmin ;

  % Use the inverse Wigner CDF i.e. scaled inverse Beta CDF to transform
  % probability values into x-coordinates
  xy( 1 , : ) = 2 * betainv ( xy( 1 , : ) , 1.5 , 1.5 )  -  1 ;

  % Sample y-coordinates between the flat bottom and curved top
  % of the segment
  xy( 2 , : ) = ( ( 1 - xy( 1 , : ) .^ 2 ) .^ 0.5  -  hsny )  .*  ...
    rand ( 1 , N )  +  hsny ;
  
end % rndsegdot


% Which of dots are visible to which eye i.e. which dots are not covered by
% disparity-shifted signal dots when seen from the left eye or the right?
% Find the Euclidian distance to the centre of the shifted circle. Those
% beyond one radius are visible. The fcfill flag is true when i contains
% indices to re-fill dots plotted in the central circle. eye is a single
% character saying which eye position buffer(s) to check ; if it is 'b'
% then the dots listed in i are considered to be positionally correlated in
% both monocular images and both the left and right buffer are checked ; if
% 'l' or 'r' then only the left or right buffer is checked.
function  S = vischk ( S , i , eye ) % , fcfill )
  
  % List which eyes to check
  switch  eye
    case  'b'  ,  e = 1 : 2 ;
    case  'l'  ,  e = 1 ;
    case  'r'  ,  e = 2 ;
  end

  % Special cases , there are no dots to check
  if  isempty ( i )
    
    return
  
  % There is no signal disparity
  elseif  ~ S.vp.disp_signal
    
    % All background dots are visible. Done.
    S.v( e , i ) = 1 ;
    return
    
  end % no signal dots

  % Square of the y-coordinate. By default, use left-eye buffer values,
  % unless we're checking the right-eye buffer. Left eye is used for
  % correlated dots.
  y2 = S.xy(  2 ,  i ,  1 + ( eye == 'r' )  )  .^  2 ;
  
  % Dots visible to the left eye
  if  eye  ~=  'r'
    
    S.v( 1 , i ) = S.crad  <  ...
      ( ( S.xy( 1 , i , 1 )  +  S.hsig ) .^ 2  +  y2 )  .^  0.5 ;
    
  end % left eye check
      
  % Dots visible to the right eye
  if  eye  ~=  'l'
    
    S.v( 2 , i ) = S.crad  <  ...
      ( ( S.xy( 1 , i , 2 )  -  S.hsig ) .^ 2  +  y2 )  .^  0.5 ;
  
  end % right eye check
  
  % We can now terminate function. We've checked dots that re-fill the
  % centre. Or, all central dots are signal dots.
%   if  fcfill  ||  S.vp.signal_fraction  ==  1  ,  return  ,  end
%   
%   % Only a few signal dots overlap the annular surround. We must choose a
%   % few surrounding background dots to keep visible in order to maintain
%   % the dot density. Do so separately for each eye.
%   for  e = e
%     
%     % Find linear index of each background dot that is in the crescent of
%     % overlap, for this monocular image
%     b = i ( ~ S.v( e , i ) ) ;
%     
%     % But there are none. To the next eyeball!
%     if  isempty ( b )  ,  continue  ,  end
%     
%     % Determine which RDS each dot belongs to
%     rds = ceil ( b / S.Ntotal ) ;
%     
%     % Find the last dot in each RDS
%     j = [  find(  diff(  rds  )  )  ,  numel(  rds  )  ] ;
%     
%     % Find the first dot in each RDS
%     first = [  1  ,  j( 1 : end - 1 )  +  1  ] ;
%     
%     % Find the last crescent dot to make visible, per RDS, in order to
%     % balance dot density
%     j = first  +  min (  j - first  ,  S.Nbshift  ) ;
%     
%     % For each RDS with invisible dots
%     for  rds = 1 : numel (  first  )
%       
%       % Set selected dots visible to this eye
%       S.v(  e  ,  b (  first( rds ) : j( rds )  )  ) = 1 ;
%       
%     end % rds
%     
%   end % eyes
  
      
end % vischk

