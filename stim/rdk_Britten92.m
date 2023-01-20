
function  ...
[ type , varpar , init , stim , close , chksum ] = rdk_Britten92 ( rfdef )
% 
% [ type , varpar , init , stim , close , chksum ] = rdk_Britten92( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Draws one or more random dot kinetograms in a circular arrangement in
% orbit around a central point. Dot patches each have a circular aperture.
% Although all patches have the same properties, each has its own unique
% set of dots.
% 
% The dot dynamics are made to follow the methods in:
% 
%   Britten KH, Shadlen MN, Newsome WT, Movshon JA. 1992. The analysis of
%     visual motion: a comparison of neuronal and psychophysical
%     performance. J Neurosci. 12(12):4745-65.
% 
% In short, every dot patch has two sets of dots. Noise dots are randomly
% replotted at a different location within the dot patch aperture on every
% frame. Signal dots all move along a given motion vector. However, signal
% dots have a limited lifetime that is randomly sampled for each dot from a
% geometric distribution. When a signal dot is extinguished then it is
% randomly replotted within the aperture and a new lifetime is sampled.
% Signal dots that move off of the aperture are randomly replotted at the
% other edge of the aperture. If possible, new signal dots are placed at
% the same position of randomly selected noise dots from the previous
% frame ; the purpose is to keep the number of signals dots approximately
% constant between every pair of consecutive frames.
% 
% The check-sum is calculated by sorting the x and y-axis coordinates of
% all dots into one vector of ascending values, and then summing. This will
% mitigate some finite-precision machine error by adding small values with
% small values so that they aren't lost by first summing with very large
% values.
% 
% 
% Variable parameters:
%
%   
%   %-- formation circle --%
%   
%   N - The number of dot patches to draw. Each patch is
%     drawn an equal distance from its two neighbours on the circumfrance
%     of an imaginary circle, called here the formation circle. Thus, N
%     patches will be placed on N points of the formation circle that
%     divide the circumfrance into N segments with the same length. In
%     other words, 360 / N degrees will separate every pair of neighbouring
%     points along the circumfrance of the formation circle. Default 1.
%   
%   fcentre_x - Horizontal i.e. x-axis coordinate of the centre of the
%     formation circle. In degrees of visual field from the trial origin.
%     Left is negative, right is positive. Default 0.
%   
%   fcentre_y - Vertical i.e. y-axis coordinate of the centre of the
%     formation circle. In degrees of visual field from the trial origin.
%     Down is negative, up is positive. Default 0.
%   
%   fradius - Radius of the formation circle, in degrees of visual field.
%     Default 6.5.
%   
%   frotation - Counter-clockwise rotation of the formation circle, in
%     degrees. That is, the rotation of rdk patch centres around the centre
%     of the formation circle. Or the angle between two straight lines
%     drawn from the centre of the formation circle to its edge ; one line
%     is perpendicular to the x-axis and touches the right hand edge of the
%     circle, the other lands in the centre of the first dot patch. Default
%     45.
%   
%   ffirst - Index of the first drawn patch. This allows fewer rdk patches
%     to be drawn than indicated by N, while retaining the same formation
%     as with N patches. For instance, if N is 4 but ffirst is 2 while
%     frotation is 0, then 3 patches are drawn at angles of pi/2, pi, and
%     3*pi/2. Default 1.
%   
%   flast - Index of the final drawn patch. Must be equal to or greater
%     than ffirst, and equal to or less than N. Default 1.
%   
%   fyoke - Dot patch index , range from 0 to N. If zero, then the centre
%     of the formation circle is placed at the point marked by fcentre_x
%     and fcentre_y. If non-zero, then all dot patches are translated so
%     that the yoked patch's aperture is centred of fcentre_x and fcentre_y
%     such that the relative position of all patches remains the same as if
%     fyoke were zero. May be less than ffirst or greater than flast.
%     Default 0.
%   
%   
%   %-- dot parameters --%
%   
%   radius - Radius of each rdk circular aperture, in degrees of visual
%     field. Default 3. 
%   
%   coherence - Fraction of dots that move with the same motion vector. In
%     practice, this will always be slightly less than stated, as some
%     coherent dots are continually being extinguished and replotted
%     elsewhere. Negative coherence causes the motion vector to reverse
%     direction from that stated in the direction parameter.
%   
%   direction - The counter-clockwise angle of the motion vector that
%     signal dots follow, in degrees. Default 0.
%   
%   speed - The length of the motion vector that signal dots follow i.e.
%     the amount that each dot is displaced in the motion direction on each
%     frame. In degrees of visual field per second. Default 3.
%   
%   density - The number of dots per squared degrees of visual field,
%     within each dot patch aperture. This measure only counts the number
%     of dot centres per unit area of screen ; it does not account for
%     overlapping dots. Default 4.
%   
%   maxdens - The maximum allowable density. This can be set to a value
%     higher than the density if the dot density will change during a
%     trial. Default 4.
%   
%   width - The width of each dot, in degrees of visual field. Default 0.2.
%     Note that the width will automatically be capped to the minimum or
%     maximum size supported by the hardware.
%   
%   avglife - The average lifetime of a signal dot, in seconds. Default
%     0.045.
%   
%   contrast - If greater than zero then this is the Michelson contrast of
%     dark dots and light dots relative to the background. Noise and signal
%     dots are evenly split into groups of dark and light. Odd dots are
%     light and even dots are dark , as enumerated over all patches.
%     If zero then the shade property is applied to all dots. Default 1.
%   
%   bincorr - Binocular correlation of dot shading. If contrast is
%     non-zero, then bincorr gives the fraction of dots that have the same
%     greyscale value relative to the background in both eyes, producing
%     correlated dots. The remainder of dots have opposite greyscale
%     values, producing anti-correlated dots. Ignored if contrast is 0.
%     Default 1.
%   
%   shade - The normalised greyscale value of all dots if contrast is 0.
%     Default 1.
%   
%   disp - The binocular disparity of the dots relative to the trial
%     origin, in degrees of visual field. Negative disparities are
%     convergent, positive are divergent. Default 0.
%
%   hdisptol - Hit region disparity tolerance. Convergence may differ from
%     dot patch disparity by up to this much for the subject to select the
%     stimulus. In degrees of visual field. Default 0.5.
%   
%   dot_type - The value provided to Screen DrawDots. Says how to render
%     dots. 0 draws square dots. 1, 2, and 3 draw circular dots with
%     different levels of anti-aliasing ; 1 favours performance [speed?], 2
%     is the highest available quality supported by the hardware, and 3 is
%     a [PTB?] builtin implementation which is automatically used if
%     options 1 or 2 are not supported by the hardware. 4 , which is
%     optimised for rendering square dots of different sizes is not
%     available as all dots will have the same size. Default 2.
% 
% 
% NOTE: Stimulus events asking for changes to variable parameters N,
%   ffirst, flast, radius, and maxdens are silently ignored. All other
%   variable paremeters may change while a trial is running.
% 
% NOTE: Test run Feb 13 to 14 ~24h continuous run, Screen Flip missed
%   presentation deadline about 14 times out of a total of 4438958 flips.
%   This on an older 2-core system.
% 
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set
  varpar = {         'N' , 'i' ,  4    ,  1   , +Inf ;
             'fcentre_x' , 'f' ,  0.0  , -Inf , +Inf ;
             'fcentre_y' , 'f' ,  0.0  , -Inf , +Inf ;
               'fradius' , 'f' ,  6.5  ,  0.0 , +Inf ;
             'frotation' , 'f' , 45    , -Inf , +Inf ;
                'ffirst' , 'i' ,  1    ,  1   , +Inf ;
                 'flast' , 'i' ,  4    ,  1   , +Inf ;
                 'fyoke' , 'i' ,  0    ,  0   , +Inf ;
                'radius' , 'f' ,  3.0  ,  0.0 , +Inf ;
             'coherence' , 'f' ,  0.5  , -1.0 ,  1.0 ;
             'direction' , 'f' ,  0.0  , -Inf , +Inf ;
                 'speed' , 'f' ,  3.0  ,  0.0 , +Inf ;
               'density' , 'f' ,  4.0  ,  0.0 , +Inf ;
               'maxdens' , 'f' ,  4.0  ,  0.0 , +Inf ;
                 'width' , 'f' ,  0.2  ,  0.0 , +Inf ;
               'avglife' , 'f' , 45e-3 ,  0.0 , +Inf ;
              'contrast' , 'f' ,  1.0  ,  0.0 ,  1.0 ;
               'bincorr' , 'f' ,  1.0  ,  0.0 ,  1.0 ;
                 'shade' , 'f' ,  1.0  ,  0.0 ,  1.0 ;
                  'disp' , 'f' ,  0.0  , -Inf , +Inf ;
              'hdisptol' , 'f' ,  0.5  ,  0.0 , +Inf ;
              'dot_type' , 'i' ,  2    ,  0   ,  3   } ;
  
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
  i = strcmp (  varpar( : , 1 )  ,  'radius'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).width  /  2 ;
  
  % Match motion direction to preferred orientation i.e. orientation + 90
  % degrees
  i = strcmp (  varpar( : , 1 )  ,  'direction'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).orientation  +  90 ;
  
  % Match speed preference
  i = strcmp (  varpar( : , 1 )  ,  'speed'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).speed ;
  
  % Match disparity preference
  i = strcmp (  varpar( : , 1 )  ,  'disp'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).disparity ;
  
  % Match contrast preference
  i = strcmp (  varpar( : , 1 )  ,  'contrast'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).contrast ;
  
    % Make sure that value is never exactly zero , just very small ,
    % otherwise shade is applied to all dots
    varpar{ i , 3 } = max( [ varpar{ i , 3 } , realmin ] ) ;
  
  
end % rdk_Britten92


%%% Stimulus definition handles %%%

% Trial initialisation function
function  S = finit ( vpar , tconst , ~ )
  
  
  %%% Check parameters %%%
  
  % Neither ffirst , flast , nor fyoke may exceed N
  if  any (  vpar.N  <  [ vpar.ffirst , vpar.flast , vpar.fyoke ]  )
    
    error (  'MET:rdk_Britten92:badparam'  ,  [ 'rdk_Britten92: ' , ...
      'Neither ffirst (%d) , flast (%d) , nor fyoke (%d) ' , ...
      'may exceed N (%d)' ]  ,  ...
      vpar.ffirst  ,  vpar.flast  ,  vpar.fyoke  ,  vpar.N  )
    
  % ffirst must be less than or equal to flast
  elseif  vpar.flast  <  vpar.ffirst
    
    error (  'MET:rdk_Britten92:badparam'  ,  [ 'rdk_Britten92: ' , ...
      'ffirst (%d) must not exceed flast (%d)' ]  ,  vpar.ffirst  ,  ...
      vpar.flast  )
    
  % Density may not exceed maxdens
  elseif  vpar.maxdens  <  vpar.density
    
    error (  'MET:rdk_Britten92:badparam'  ,  [ 'rdk_Britten92: ' , ...
      'density (%f) must not exceed maxdens (%f)' ]  ,  vpar.density  , ...
      vpar.maxdens  )
    
  % Disparity requested but PsychToolbox is in a monocular mode
  elseif  vpar.disp  &&  ~ tconst.stereo
    
    error (  'MET:rdk_Britten92:badparam'  ,  [ 'rdk_Britten92: ' , ...
      'disparity non-zero but PsychToolbox opened monocular window' ]  )
    
  end % varpar check
  
  % radius , density , and maxdens should never be zero
  for  F = { 'radius' , 'density' , 'maxdens' }
    
    if  ~ vpar.( F{ 1 } )
      error (  'MET:rdk_Britten92:badparam'  ,  [ 'rdk_Britten92: ' , ...
        'dot patch %s is zero' ]  ,  F{ 1 }  )
    end
    
  end % warnings
  
  
  %%% Build stimulus descriptor %%%
  
  % Keep a copy of variable parameters in their original units
  S.vp = vpar ;
  
  % Variable parameter changes that are ignored during a trial
  S.ignored = { 'N' , 'ffirst' , 'flast' , 'radius' , 'maxdens' } ;
  
  % Get minimum and maximum dot size , without drawing anything , in pixels
  [ S.minwid , S.maxwid ] = Screen ( 'DrawDots' , tconst.winptr ) ;
  
  
  %-- Formation circle --%
  
  % Number of patches that are drawn
  S.Np = S.vp.flast  -  S.vp.ffirst  +  1 ;
  
  % Patch index cell array vector
  S.P = num2cell (  1 : S.Np  ) ;
  
  % Absolute screen location of the formation circle centre. This is
  % provided to Screen DrawDots, which applies the final transformation and
  % allows us to regard formation circle centre as origin [ 0 , 0 ]. Called
  % .centre after name of the DrawDots input argument.
  S.centre = fcentre ( tconst , S ) ;
  
  % Pixel coordinates of each dot patch centre of screen
  S.xypatc = xypatc ( tconst , S ) ;
  
  
  %-- Patch properties --%
  
  % We will use an internal direction and coherence parameters that can
  % account for the sign of the input coherence, thus leaving the original
  % values untouched, for reference.
  S.coherence = S.vp.coherence ;
  S.direction = S.vp.direction ;
  
  % Coherence is negative. Therefore, add 180 degrees to the direction
  % parameter, then make coherence positive.
  if  S.coherence  <  0
    S.direction = 180  +  S.direction ;
    S.coherence = - S.coherence ;
  end
  
  % Radius of a dot patch aperture , in pixels
  S.radius = tconst.pixperdeg  *  S.vp.radius ;
  
  % Squared radius , pre-computed for distance to edge comparisons
  S.rad_sq = S.radius ^ 2 ;
  
  % Dots per patch is dots/deg^2  X  deg^2 , round up so that we always get
  % at least one dot if density non-zero
  S.Nd     = ceil (  pi * S.vp.radius ^ 2  *  S.vp.density  ) ;
  
  % Maximum number of dots per patch at specified maximum density
  S.Nd_max = ceil (  pi * S.vp.radius ^ 2  *  S.vp.maxdens  ) ;
  
  % Total number of dots in all patches
  S.Nd_total     = S.Np  *  S.Nd     ;
  S.Nd_total_max = S.Np  *  S.Nd_max ;
  
  % Number of signal dots moving along motion vector , round up so that
  % small coherences produce at least one signal dot
  S.Nsig = ceil (  S.coherence  *  S.Nd  ) ;
  
  % Number of noise dots per dot patch
  S.Nnoise = S.Nd  -  S.Nsig ;
  
  % Number of binocularly correlated noise and signal dots , round up
  S.Nbcor_s = ceil (  S.Nsig  *  S.vp.bincorr  ) ;
  S.Nbcor_n = ceil (  ( S.Nd - S.Nsig )  *  S.vp.bincorr  ) ;
  
  % Total number of signal and noise dots across patches
  S.Nsig_total = S.Nsig  *  S.Np ;
  S.Nnoise_total = S.Nnoise * S.Np ;
  S.Nbcor_s_total = S.Nbcor_s  *  S.Np ;
  S.Nbcor_n_total = S.Nbcor_n  *  S.Np ;
  
  % Pixels travelled by a signal dot between each frame
  S.step = tconst.pixperdeg  *  S.vp.speed  *  tconst.flipint ;
  
  % Number and direction of pixels travelled along the x- and y-axes by a
  % signal dot on each frame. Once again , account for PTB coordinate
  % system's y-axis.
  S.xstep = + S.step  *  cosd ( S.direction ) ;
  S.ystep = - S.step  *  sind ( S.direction ) ;
  
  % The counter-clockwise rotation matrix , due to PTB coordinate system
  % this is actually the conventional clockwise rotation matrix
  S.ccwrot = [  cosd( S.direction )  ,  sind( S.direction ) ;
               -sind( S.direction )  ,  cosd( S.direction ) ] ;
  
  % The clock-wise rotation matrix , see above.
  S.cwrot = [  cosd( S.direction )  , -sind( S.direction ) ;
               sind( S.direction )  ,  cosd( S.direction ) ] ;
	
	% Dot diameter , in pixels , i.e. size in DrawDots parlance
  S.size = tconst.pixperdeg  *  S.vp.width ;
  
  % Cap to the min or max dot diameter that is supported by the hardware
  if  S.size  <  S.minwid
    
    S.size = S.minwid ;
    
  elseif  S.maxwid  <  S.size
    
    S.size = S.maxwid ;
    
  end
  
  % Find the minimum range of colour values from background to either white
  % or black , for contrast calculation
  S.colrng = min (  [  tconst.backgnd - BlackIndex( tconst.winptr )  ;
                       WhiteIndex( tconst.winptr ) - tconst.backgnd  ]  ) ;
	
  S.colrng = S.colrng ( : ) ;
  
  % Compute the light and dark colour values for dots given the contrast
  S.light = S.vp.contrast * S.colrng  +  tconst.backgnd' ;
  S.dark  = tconst.backgnd'  -  S.vp.contrast * S.colrng ;
  
  % Probability of survival. Used to sample a geometric distribution for
  % signal dot lifetimes.
  S.prob_survival = 1  /  ( S.vp.avglife / tconst.flipint )  ;
  
  % In a stereo mode
  if  tconst.stereo
  
    % Disparity relative to trial origin , in pixels. The sign is used to
    % say in which direction the dots must shift when drawing to the next
    % frame buffer. We apply a negative unary operator because the first
    % image will be drawn to the left eye frame buffer, and the dots will
    % be initialised as though they had been drawn to the right-eye frame
    % buffer.
    S.disp = - tconst.pixperdeg  *  ( S.vp.disp  +  tconst.origin( 3 ) ) ;

    % Displacement of dot horizontal position. .xy first row will always be
    % shifted either to the right or left, depending on which eye buffer
    % was last drawn to. Halved because each eye's image must shift in
    % opposite directions on screen by this much. Undo the sign reversal
    % because we initialise such that the dots were last drawn to the
    % right-eye frame buffer.
    S.displacement = - S.disp  /  2 ;
  
  % Monocular mode
  else
    
    S.disp = 0 ;  S.displacement = 0 ;
    
  end % stereo mode
  
  
  %-- Dot buffers --%
  
  % Buffer indexing will work as follows. The value(s) for signal dots from
  % all patches are stored in columns 1 to S.Nsig * S.Np, while value(s)
  % for noise dots are kept in columns S.Nsig * S.Np + 1 to S.Nd * S.Np.
  % Within the set of signal or noise dot columns, dots are grouped by dot
  % patch. For instance, signal dot i from patch j is ordered as follows:
  % d_1_1 , d_2_1 , ... d_Nsig_1 , d_1_2 , d_2_2 , ... d_Nsig_2 , d_1_3 ,
  % ... d_i_j , ... d_Nsig-1_Np , d_Nsig_Np. Noise dots are ordered
  % similarly. Put another way, dots are odered first by patch then by
  % signal or noise identity.
  
  % Position buffer , named after the input argument for Screen DrawDots.
  % Contains x-coord in row 1 and y-coord in row 2.
  S.xy = zeros (  2  ,  S.Nd_total_max  ) ;
  
  % Initialise positions but don't add translation, yet
  S.xy( : , 1 : S.Nd_total ) = rndpos ( S.radius , S.Nd_total ) ;
  
  % Translation buffer , we're trading use of memory for speed of
  % translations
  S.translation = zeros (  2  ,  S.Nd_total_max  ) ;
  
  % Initialise translation buffer , maps a dot patch centre to each dot
  S.translation( : , 1 : S.Nd_total ) = translation ( S ) ;
  
  % Distance buffer , stores distance of signal dots from the edge of the
  % dot patch aperture
  S.distance = zeros (  1  ,  S.Nd_total_max  ,  'single'  ) ;
  
  % Calculate distance for each signal dot. First build index vector ...
  i = 1 : S.Nsig_total ;
  
  % ... then undo rotation on signal dots ...
  rxy = S.cwrot  *  S.xy( : , i ) ;
  
  % ... and compute distance to edge.
  S.distance( i ) = ...
    sqrt (  S.rad_sq  -  rxy( 2 , : ) .^ 2  )  -  rxy ( 1 , : ) ;
  
  % Now that we've computed distances , translate all dot patches into
  % position
  S.xy( : , 1 : S.Nd_total ) = ...
    S.xy( : , 1 : S.Nd_total )  +  S.translation( : , 1 : S.Nd_total ) ;
  
  % Apply disparity displacement if in stereo mode
  if  tconst.stereo
    S.xy( 1 , 1 : S.Nd_total ) = ...
      S.xy( 1 , 1 : S.Nd_total )  +  S.displacement ;
  end
  
  % Signal dot lifetime , in frames. Initialise all to zero.
  S.lifetime = zeros (  1  ,  S.Nd_total_max  ,  'uint16'  ) ;
  
  % Initialise signal dot lifetimes from a geometric distribution , add 1
  % so that the first signal dots are guaranteed to get at least 2 frames
  S.lifetime( i ) = ...
    ceil( log( rand( size( i ) ) )  /  log( 1 - S.prob_survival ) )  +  1 ;
  
  % Colour buffer , initialise with one layer for monocular, or two for
  % binocular
  S.colbuf = zeros(  3  ,  S.Nd_total_max  ,  ( 0 < tconst.stereo ) + 1  );
  
  % Point either to the colour buffer or the shade value depending on the
  % contrast
  if  S.vp.contrast
    
    % Assign light and dark colours to each dot
    S.colbuf( : , : , 1 ) = dotcol ( S ) ;
    
    % If stereoscopic
    if  tconst.stereo
      
      % Copy colours from left to right eye colour buffer for correlated
      % dots , and reverse the colour for anti-correlated dots
      S.colbuf( : , : , 2 ) = bincorcol ( tconst , S ) ;
      
    end % stereoscopic
    
    % Point to colour buffer
    S.colour = S.colbuf ;
    
  % Constrast is off
  else
    
    % Use same greyscale value for all dots
    S.colour = S.vp.shade ;
    
  end % colour pointer
  
  
  %-- Hit regions --%
  
  % We will use the 5-column form defining a set of circular regions
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  S.hitregion = zeros ( S.Np , 6 ) ;
  
  % Initialise hit region radius and disparity
  S.hitregion( : , c6.radius ) = S.vp.radius ;
  S.hitregion( : , c6.disp   ) = S.vp.disp  +  tconst.origin( 3 ) ;
  S.hitregion( : , c6.dtoler ) = S.vp.hdisptol ;
  
  % Initialise hit region locations
  S.hitregion( : , [ c6.xcoord , c6.ycoord ] ) = hitregloc ( tconst , S ) ;
  
  % Do not ignore stimulus
  S.hitregion( : , c6.ignore ) = 1 ;
  
  
end % finit


% Stimulation function
function  [ S , h ] = fstim ( S , tconst , tvar )
  
  % Hit region update not expected by default
  h = false ;
  
  % Don't update variable parameters or dots if we're drawing to the
  % right-eye frame buffer because it has already been done for the
  % left-eye frame buffer
  if  tvar.eyebuf  <  1
    
    
    %%% Variable parameter changes %%%

    % Any variable parameters changed?
    if  ~ isempty ( tvar.varpar )
      
      
      %-- Get/make lists --%
      
      % Point to the list of variable parameter changes
      vp = tvar.varpar ;

      % Make a struct that tracks which parameters were changed , d for
      % delta i.e. change
      F = fieldnames( S.vp )' ;
      F = [  F  ;  num2cell(  false( size( F ) )  )  ] ;
      d = struct (  F { : }  ) ;
      
      
      %-- New values --%
    
      for  i = 1 : size ( vp , 1 )

        % Ignored variable parameter change , skip to next
        if  any ( strcmp(  vp{ i , 1 }  ,  S.ignored  ) )
          continue
        end
        
        % Save in stimulus descriptor's copy of variable parameters
        S.vp.( vp{ i , 1 } ) = vp{ i , 2 } ;

        % Mark as changed
        d.( vp{ i , 1 } ) = true ;

      end % new values
      
      
      %-- Update stimulus descriptor --%
      
      % Change in direction , update internal direction parameter based on
      % polarity of coherence
      if  d.direction
        
        % Save to internal parameter
        S.direction = S.vp.direction ;
        
        % Go in opposite direction if coherence is negative
        if  S.vp.coherence  <  0
          S.direction = 180  +  S.direction ;
        end
        
      end % internal dir
      
      % Change in coherence , update internal coherence parameter. Then
      % check whether the input direction and internal direction correspond
      % to the new coherence.
      if  d.coherence
        
        % Save internal parameter
        S.coherence = S.vp.coherence ;
        
        % Coherence is negative
        if  S.coherence  <  0
          
          % Reverse polarity
          S.coherence = - S.coherence ;
          
          % If input and internal directions are the same, then they are
          % set according to a previous positive coherence.
          if  S.direction  ==  S.vp.direction
            
            % We will reset the direction and raise the direction flag
            d.direction = true ;
            S.direction = 180  +  S.vp.direction ;
            
          end % opposite dir
          
        % Coherence is positive , but input and internal directions are not
        % equal. That means the direction was set according to a previous
        % negative coherence.
        elseif  S.direction  ~=  S.vp.direction
          
          % We will reset the direction and raise the direction flag
          d.direction = true ;
          S.direction = S.vp.direction ;
          
        end
        
      end % coh or dir
      
      % Changed formation circle position , recalculate absolute location
      if  d.fcentre_x  ||  d.fcentre_y
        
        S.centre = fcentre ( tconst , S ) ;
        
      end % formation circle position
      
      % Changed formation circle arrangement
      if  any ( [ d.fradius , d.frotation , d.fyoke ] )
        
        % New pixel coordinates of dot patch centres
        S.xypatc = xypatc ( tconst , S ) ;
        
        % Signal change to formation circle arrangement , raise flag
        fcaflg = true ;
        
      else
        
        % Lower formation circle arrangement flag
        fcaflg = false ;
        
      end % formation circle arrangement
      
      % Dot density change
      if  d.density
        
        % Density may not exceed maximum.
        if  S.vp.maxdens  <  S.vp.density
          
          S.vp.density = S.vp.maxdens ;
          
        end % max density
        
        % The number of dots per patch
        S.Nd = ceil (  pi * S.vp.radius ^ 2  *  S.vp.density  ) ;
        
        % Total number of dots
        S.Nd_total = S.Nd  *  S.Np ;
        
      end % density
      
      % Change in disparity of dots relative to fixation point , and in a
      % stereo mode
      if  d.disp  &&  tconst.stereo
        
        % Recalculate disparity in pixels
        S.disp = - tconst.pixperdeg  *  ...
          ( S.vp.disp  +  tconst.origin( 3 ) ) ;
        
        % Remove current disparity displacement from dots
        S.xy( 1 , 1 : S.Nd_total ) = S.xy( 1 , 1 : S.Nd_total )  -  ...
          S.displacement ;
  
        % New displacement of dots
        S.displacement = - S.disp  /  2 ;
        
        % Apply displacement so that dots appear as they would to the right
        % eye , this is so that we can subtract one whole disparity shift
        % in preparation for drawing the left eye image
        S.xy( 1 , 1 : S.Nd_total ) = S.xy( 1 , 1 : S.Nd_total )  +  ...
          S.displacement ;
        
      end % disparity change
      
      % Change in the number of signal dots , either by change in density
      % or coherence
      if  d.coherence  ||  d.density
        
        % Map existing signal dots to new locations in buffers, and set
        % lifetimes for any new signal dots to zero for regeneration in the
        % next image flipped to screen. However, it is also important to
        % remap noise dots as well, so that regenerated signal dots sample
        % from the correct pool.
        S = remapsd ( S ) ;
        
      end % signal dots
      
      % Change either in formation circle arrangement, dot density, or
      % coherence means that we need to remap translation buffer
      if  d.coherence  ||  d.density  ||  fcaflg
        
        % Undo translation of all dot patches so that they all sit in
        % formation circle centre , if formation changed
        if  fcaflg
          S.xy( : , 1 : S.Nd_total ) = S.xy( : , 1 : S.Nd_total )  -  ...
            S.translation( : , 1 : S.Nd_total ) ;
        end
        
        % Update translation buffer
        S.translation( : , 1 : S.Nd_total ) = translation ( S ) ;
        
        % Apply new translation to all dots , if formation changed
        if  fcaflg
          S.xy( : , 1 : S.Nd_total ) = S.xy( : , 1 : S.Nd_total )  +  ...
            S.translation( : , 1 : S.Nd_total ) ;
        end
        
      end % remap translation buffer
      
      % Change in dot contrast , if non-zero
      if  d.contrast  &&  S.vp.contrast
        
        % Redefine light and dark
        S.light = S.vp.contrast * S.colrng  +  tconst.backgnd' ;
        S.dark  = tconst.backgnd'  -  S.vp.contrast * S.colrng ;
        
        % Assign new light and dark colours to each dot
        S.colbuf( : , : , 1 ) = dotcol ( S ) ;
        
      end % contrast
      
      % Change in number of binocularly correlated dots or contrast , if in
      % stereoscopic mode and contrast is non-zero
      if  any ( [ d.density , d.coherence , d.contrast , ...
          d.bincorr ] )  &&  tconst.stereo  &&  S.vp.contrast
        
        % Number of binocularly correlated noise and signal dots , round up
        S.Nbcor_s = ceil (  S.Nsig  *  S.vp.bincorr  ) ;
        S.Nbcor_n = ceil (  S.Nnoise  *  S.vp.bincorr  ) ;

        % Total number of correlated dots
        S.Nbcor_s_total = S.Nbcor_s  *  S.Np ;
        S.Nbcor_n_total = S.Nbcor_n  *  S.Np ;
        
        % Remap right-eye dot colours according to number of correlated
        % dots
        S.colbuf( : , : , 2 ) = bincorcol ( tconst , S ) ;
        
      end % bincor
      
      % Change in motion
      if  d.speed  ||  d.direction
        
        % Recalculate step size , ...
        S.step = tconst.pixperdeg  *  S.vp.speed  *  tconst.flipint ;
        S.xstep = + S.step  *  cosd ( S.direction ) ;
        S.ystep = - S.step  *  sind ( S.direction ) ;

        % ... counter-clockwise and ...
        S.ccwrot( 1 : 2 , 1 ) = [ cosd( S.direction )  ;
                                 -sind( S.direction ) ] ;
        
        S.ccwrot( 1 , 2 ) = - S.ccwrot( 2 , 1 ) ;
        S.ccwrot( 2 , 2 ) =   S.ccwrot( 1 , 1 ) ;
                   
        % ... clockwise rotation matrices.
        S.cwrot( : , : ) = S.ccwrot' ;
        
        % Recompute distance of signal dots to aperture edge , if they are
        % moving
        if  S.vp.speed
          
          % Remove translation , all dot patches at centre of formation
          % circle
          rxy = S.xy( : , 1 : S.Nsig_total )  -  ...
            S.translation( : , 1 : S.Nsig_total ) ;
          
          % Clockwise rotation so that direction of motion is parallel to
          % x-axis
          rxy = S.cwrot  *  rxy ;
          
          % ... and compute distance to edge of patch aperture.
          S.distance( 1 : S.Nsig_total ) = ...
            sqrt (  S.rad_sq  -  rxy( 2 , : ) .^ 2  )  -  rxy ( 1 , : ) ;
          
        end % distance
        
      end % motion change
      
      % Change in width of dots
      if  d.width
        
        % New size in pixels
        S.size = tconst.pixperdeg  *  S.vp.width ;
  
        % Cap to the min or max allowable dot diameter
        if  S.size  <  S.minwid
          S.size = S.minwid ;
        elseif  S.maxwid  <  S.size
          S.size = S.maxwid ;
        end
        
      end % size change
      
      % New average life span
      if  d.avglife
        
        % New probability of survival
        S.prob_survival = 1  /  ( S.vp.avglife / tconst.flipint )  ;
        
      end % change life times
      
      % Make sure that .colour is pointing to the correct matrix
      if  S.vp.contrast
        S.colour = S.colbuf ;
      else
        S.colour = S.vp.shade ;
      end
      
      % The hit-region column index map
      c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
        
      % Any change requiring an update to hit region location
      if  any ( [ d.fcentre_x , d.fcentre_y , d.fradius , d.frotation , ...
          d.fyoke ] )
        
        % Signal change of hit region
        h = true ;
        
        % Position of dot patch hit regions
        S.hitregion( : , [ c6.xcoord , c6.ycoord ] ) = ...
          hitregloc ( tconst , S ) ;
        
      end % hit region location
      
      % Change to hit region disparity
      if  d.disp  &&  tconst.stereo
        S.hitregion( : , c6.disp   ) = S.vp.disp  +  tconst.origin( 3 ) ;
      end % hit region disparity
      
      % Change to hit region disparity tolerance
      if  d.hdisptol
        S.hitregion( : , c6.dtoler ) = S.vp.hdisptol ;
      end % hit region disparity
      
      
    end % variable parameter change
    
    
    %%% Update dots %%%
    
    %-- Signal dots --%

    % Skip if dot motion coherence is zero i.e. no signal dots
    if  S.vp.coherence
      
      % Signal dot index vector
      sd = 1 : S.Nsig_total ;
      
      
      %-- Handle dead dots --%
      
      % Find dead signal dot indeces
      dead = find (  ~ S.lifetime ( sd )  ) ;
      
      % Skip if no dead dots
      if  dead
        
        % Find noise dots from the last frame to convert into signal dots.
        % Return indeces of dead signal dots to replace, noise dots to
        % replace them, and indeces of dead signal dots that were not
        % replaced. Do separately per patch.
        [ drep , nrep , norep ] = ...
          cellfun (  @( p )  noise2sig ( S , p , dead )  ,  S.P  ,  ...
          'UniformOutput'  ,  false  ) ;
        
        % Combine all indices together
        drep  = cell2mat (  drep ) ;
        nrep  = cell2mat (  nrep ) ;
        norep = cell2mat ( norep ) ;
        
        % Copy noise dot positions to signal dots , but undo patch
        % translation and disparity displacement , for distance-to-edge
        % computation
        S.xy( : , drep ) = S.xy( : , nrep )  -  S.translation( : , nrep ) ;
        S.xy( 1 , drep ) = S.xy( 1 , drep )  -  S.displacement ;
        
        % Sample new dot positions for signal dots that were not replaced
        % by a noise dot
        S.xy( : , norep ) = rndpos (  S.radius  ,  numel ( norep )  ) ;
        
        % Undo rotation of new signal dots ...
        rxy = S.cwrot  *  S.xy( : , dead ) ;
  
        % ... and compute distance to edge of patch aperture.
        S.distance( dead ) = ...
          sqrt (  S.rad_sq  -  rxy( 2 , : ) .^ 2  )  -  rxy ( 1 , : ) ;
        
        % Translate new signal dots into place , and apply disparity
        % displacement
        S.xy( : , dead ) = S.xy( : , dead )  +  S.translation( : , dead ) ;
        
        % And apply disparity displacement
        S.xy( 1 , dead ) = S.xy( 1 , dead )  +  S.displacement ;
        
        % Sample lifetimes for new dots , use geometric distribution
        S.lifetime( dead ) = ceil( log( rand( size( dead ) ) )  /  ...
          log( 1 - S.prob_survival ) )  +  1 ;
        
        % Add 1 to dots that were not replaced by an existing noise dot ,
        % so that all signal dots exist for at least 2 frames
        S.lifetime( norep ) = S.lifetime( norep ) + 1 ;
        
      end % dead dots
      
      
      %-- Wrap around --%
      
      % Find signal dots that are about to fall off the leading edge of the
      % aperture i.e. edge in direction of motion vector , where tailing
      % edge is on opposite side
      fall = S.distance ( sd )  <  S.step ;
      
      % Number of doomed dots
      nfall = sum ( fall ) ;
      
      % Skip if no dots are in peril
      if  nfall
        
        % In a circle centred on origin with no rotation, give these dots a
        % random y-axis location , use patch radius
        S.xy( 2 , fall ) = 2  *  S.radius  *  rand ( 1 , nfall )  -  ...
          S.radius ;
        
        % Find x-coordinate where horizontal line intercepts leading edge
        % of circle
        e = sqrt (  S.rad_sq  -  S.xy ( 2 , fall ) .^ 2  ) ;
    
        % Nudge dots just off the tailing edge so that one frame's worth of
        % travel will bring them in by some random fraction of a step
        S.xy( 1 , fall ) = -e  -  S.step  *  rand ( 1 , nfall ) ;
        
        % Compute distance of dots to leading edge of aperture
        S.distance( fall ) = e  -  S.xy( 1 , fall ) ;
        
        % Apply rotation then translation relative to formation's centre ,
        % and finally disparity displacement
        S.xy( : , fall ) = S.ccwrot  *  S.xy ( : , fall )  +  ...
          S.translation ( : , fall ) ;
        S.xy( 1 , fall ) = S.xy( 1 , fall )  +  S.displacement ;

      end % wrap dots around
      
      
      %-- Move signal dots --%
      
      % But only if there is any speed
      if  S.vp.speed
        
        % Horizontal step i.e. x-axis
        S.xy( 1 , sd ) = S.xy( 1 , sd )  +  S.xstep ;

        % Vertical step i.e. y-axis
        S.xy( 2 , sd ) = S.xy( 2 , sd )  +  S.ystep ;

        % New distance of signal dots to edge of aperture
        S.distance( sd ) = S.distance( sd )  -  S.step ;
      
      end % move dots
      
      % Count down one frame from signal dot lifetimes
      S.lifetime( sd ) = S.lifetime( sd )  -  1 ;
      
      
    end % signal dots


    %-- Noise dots --%

    % Noise dot index vector
    nd = S.Nsig_total + 1 : S.Nd_total ;

    % Sample new dot positions
    S.xy( : , nd ) = ...
      rndpos (  S.radius  ,  S.Nnoise_total  ) ;
    
    % And apply translation
    S.xy( : , nd ) = S.xy( : , nd )  +  S.translation ( : , nd ) ;
    
    
  end % not right-eye frame buffer
  
  
  %%% Draw dots %%%
  
  % Which colour buffer, left/monocular or right eye?
  ceye = 1  +  ( tvar.eyebuf == 1 ) ;
  
  % Apply horizontal shift if there is any disparity
  if  S.disp
    
    % Shift dots
    S.xy( 1 , 1 : S.Nd_total ) = S.xy( 1 , 1 : S.Nd_total )  +  S.disp ;
    
    % Change sign of disparity and displacement
    S.disp = - S.disp ;
    S.displacement = - S.displacement ;
    
  end % apply disparity
  
  % Set appropriate alpha blending for correct anti-aliasing of dots
  Screen (  'BlendFunction'  ,  tconst.winptr  ,  ...
    GL_SRC_ALPHA  ,  GL_ONE_MINUS_SRC_ALPHA  ) ;
  
  % Dot index vector
  i = 1 : S.Nd_total ;
  
  % Should we use the same index vector for colour values? If applying the
  % same shade to all , then access a single column
  if  S.vp.contrast
    ccol = i ;
  else
    ccol = 1 ;
  end
  
  % Submit drawing instructions to PTB
  Screen (  'DrawDots'  ,  tconst.winptr  ,  S.xy ( : , i )  ,  ...
    S.size  ,  S.colour ( : , ccol , ceye )  ,  S.centre  ,  ...
    S.vp.dot_type  ) ;
  
  
end % fstim


% Trial closing function
function  S = fclose ( ~ , ~ )
  
  S = [] ;
  
end % close


% Check-sum function
function  c = fchksum ( S )
  
  c = sum( sort( double(  S.xy( : )  ) ) ) ;
  
end % chksum


%%% Sub-routines %%%


% Absolute screen location of the formation circle centre.
function  centre = fcentre ( tconst , S )
  
  centre = tconst.pixperdeg  *  ...
    ( [ S.vp.fcentre_x , S.vp.fcentre_y ] + tconst.origin( 1 : 2 ) )  + ...
    [ tconst.wincentx , tconst.wincenty ] ;
  
  % Rmember to convert y-axis coordinate to PTB coordinate system where
  % down is up
  centre( 2 ) = tconst.winheight  -  centre( 2 ) ;
  
end % fcentre


% Pixel coordinates of each dot patch centre of screen
function  xy = xypatc ( tconst , S )
  
  % Formation circle radius , in pixels
  fcrpix = S.vp.fradius  *  tconst.pixperdeg ;
  
  % Angle of each patch centre relative to the formation circle. Add
  % rotation of formation circle. A * I + R where A is angle
  % between each neighbouring patch on the circle, I is the index vector
  % for patches (starting at 0 and going to N-1), and R is the circle
  % rotation.
  ang = 360 / S.vp.N  *  ( 0 : S.vp.N - 1 )  +  S.vp.frotation ;
  
  % Find locations on screen , relative to centre of formation circle. In
  % PTB coordinates , hence subtraction of y-axis coordinates after
  % converting polar to cartesian coordinates
  xy = [  +fcrpix  *  cosd( ang )  ;  -fcrpix  *  sind( ang )  ] ;
  
  % Translate formation so that the yoked dot patch is centred on the
  % origin
  if  S.vp.fyoke
    
    % Patch index
    i = S.vp.fyoke ;
    
    % Translate
    xy( 1 , : ) = xy ( 1 , : )  -  xy ( 1 , i ) ;
    xy( 2 , : ) = xy ( 2 , : )  -  xy ( 2 , i ) ;
    
  end % formation yoke
  
end % xypatc


% Map each dot to a dot patch centre for rapid translations
function  t = translation ( S )
  
  % Map every dot to the centre of its dot patch aperture ...
  i = ceil (  [  ( 1 : S.Nsig_total   ) / S.Nsig  ,  ...
                 ( 1 : S.Nnoise_total ) / S.Nnoise  ]  ) ;
               
	% ... adjust patch index ...
  i = i  +  S.vp.ffirst  -  1 ;
  
  % ... and copy.
  t = S.xypatc ( : , i ) ;
  
end % translation


% Map light and dark colours to left/monocular dot colour buffer
function  c = dotcol ( S )
  
  % Allocate output arg
  c = zeros ( 3 , S.Nd_total_max ) ;
  
  % Number of odd dots
  i = floor (  S.Nd_total_max / 2  )  +  mod ( S.Nd_total_max , 2 ) ;

  % Set left eye / monocular row's colour , odd dots are light
  c( : , 1 : 2 : end ) = repmat ( S.light , 1 , i ) ;

  % Number of even dots
  i = i - mod ( S.Nd_total_max , 2 ) ;

  % And even dots are dark
  c( : , 2 : 2 : end ) = repmat ( S.dark  , 1 , i ) ;
  
end % dotcol


% Map correlated and anti-correlated colours to right-eye dots
function  c = bincorcol ( tconst , S )
  
  % Allocate output arg
  c = zeros ( 3 , S.Nd_total_max ) ;
  
  % Then find correlated signal dots ...
  i = 1 : S.Nbcor_s ;
  i = repmat (  i  ,  S.Np  ,  1  )  +  ...
      repmat (  S.Nsig * ( 0 : S.Np - 1 )'  ,  1  ,  numel ( i )  ) ;

  % ... and noise dots ...
  j = 1 : S.Nbcor_n ;
  j = repmat (  j  ,  S.Np  ,  1  )  +  ...
      repmat (  S.Nsig_total + S.Nnoise * ( 0 : S.Np - 1 )'  ,  ...
        1  ,  numel ( j )  ) ;

  % ... and copy colour from left eye to right eye image.
  c( : , [ i , j ] ) = S.colbuf(  :  ,  [ i , j ]  ,  1  ) ;

  % Now find anti-correlated signal dots ...
  i = 1 : S.Nsig - S.Nbcor_s ;
  i = repmat (  i  ,  S.Np  ,  1  )  +  ...
      repmat ( S.Nbcor_s + S.Nsig * ( 0 : S.Np - 1 )'  ,  ...
        1  ,  numel ( i )  ) ;

  % ... and noise dots ...
  j = 1 : S.Nnoise - S.Nbcor_n ;
  j = repmat (  j  ,  S.Np  ,  1  )  +  ...
      repmat (  ...
        S.Nsig_total + S.Nbcor_n + S.Nnoise * ( 0 : S.Np - 1 )'  ,  ...
        1  ,  numel ( j )  ) ;

  % And flip colour values
  c( : , [ i , j ] ) = ...
    2 * repmat( tconst.backgnd' , 1 , numel( i ) + numel( j ) )  -  ...
    S.colbuf( : , [ i , j ] , 1 ) ;
  
end % bincorcol


% Remap existing signal dots to new locations in dot buffers because the
% number of signal dots has changed
function  [ S , ns ] = remapsd ( S )
  
  % New number of signal dots , per patch
  ns = ceil (  S.coherence  *  S.Nd  ) ;
  
  % Total number of signal dots , all patches
  ns_total = ns  *  S.Np ;
  
  % New number of noise dots
  nn = S.Nd  -  ns ;

  % Number of existing dots to be kept , per patch
  k = min ( [ ns , S.Nsig ] ) ;
  
  % Number of noise dots to be kept , per patch
  kn = min ( [ nn , S.Nnoise ] ) ;
  
  % Number of de novo signal dots , per patch
  dn = ns  -  k ;
  
  % Number of de novo noise dots , per patch
  dnn = nn  -  kn ;

  % Base index sets for signal and noise dots
  b = repmat ( ( 1 : k  )' , 1 , S.Np ) ;
  d = repmat ( ( 1 : kn )' , 1 , S.Np ) ;
  
  % Indeces of current signal dots that will be kept
  a = b  +  repmat ( S.Nsig * ( 0 : S.Np - 1 ) , k , 1 ) ;
  
  % Indices where kept signal dots will be mapped to
  b = b  +  repmat ( ns * ( 0 : S.Np - 1 ) , k , 1 ) ;
  
  % Indeces of current noise dots that will be kept
  c = d  +  repmat( S.Nsig_total + S.Nnoise * ( 0 : S.Np - 1 ) , kn , 1 ) ;
  
  % Indices where kept noise dots will be mapped to
  d = d  +  repmat ( ns_total + nn * ( 0 : S.Np - 1 ) , kn , 1 ) ;
  
  % Decide which order to shift buffers in. If the number of signal dots
  % has decreased, then shift them first. Otherwise, shift noise dots
  % first. This way, we don't loose information about any set of kept dots.
  if  ns  <=  S.Nsig
    I = { { a , b , true  } , { c , d , false } } ;
  else
    I = { { c , d , false } , { a , b , true  } } ;
  end
  
  % Transfer buffer contents , omit colour buffer as this is handled
  % separately
  for  I = I  ,  [ i , j , sigflg ] = I{ 1 }{ : } ;
    
    % Transfer position for all dot types
    S.xy( : , j ) = S.xy ( : , i ) ;
    
    % Only transfer distance and lifetime if handling signal dots
    if  sigflg
      S.distance( j ) = S.distance ( i ) ;
      S.lifetime( j ) = S.lifetime ( i ) ;
    end
    
  end % transfer kept dots
  
  % Indeces of de novo signal dots
  a = repmat ( ( 1 : dn )' , 1 , S.Np )  +  ...
    repmat ( k + ns * ( 0 : S.Np - 1 ) , dn , 1 ) ;
  
  % Kill these dots for immediate regeneration
  S.lifetime( a ) = 0 ;
  
  % Indeces of de novo noise dots
  c = repmat ( ( 1 : dnn )' , 1 , S.Np )  +  ...
    repmat ( ns_total + kn + nn * ( 0 : S.Np - 1 ) , dnn , 1 ) ;
  
  % Re-sample de novo noise dot positions , and translate into position
  S.xy( : , c ) = rndpos ( S.radius , numel( c ) )  +  ...
    S.translation ( : , c ) ;
  
  % Number of signal dots
  S.Nsig       = ns ;
  S.Nsig_total = ns_total ;
  
  % Number of noise dots
  S.Nnoise       = S.Nd  -  S.Nsig ;
  S.Nnoise_total = S.Nnoise  *  S.Np ;
  
end % remapsd


% Calculate location of hit region centres in degrees relative to the
% centre of the screen
function  hitloc = hitregloc ( tconst , S )
  
  % x (col 1) and y-axis (col 2) coordinates for all dot patch hit regions
  hitloc = zeros ( S.Np , 2 ) ;
  
  % Compute angle of each dot patch
  ang = 360 / S.vp.N  *  ( S.vp.ffirst - 1 : S.vp.flast - 1 )  +  ...
    S.vp.frotation ;
  
  % Basic position around centre of formation circle
  hitloc( : , 1 ) = S.vp.fradius  *  cosd ( ang ) ;
  hitloc( : , 2 ) = S.vp.fradius  *  sind ( ang ) ;
  
  % Yoke to given dot patch
  if  S.vp.fyoke
    
    % Patch index
    i = S.vp.fyoke ;
    
    % Apply to formation of hit regions
    hitloc( : , 1 ) = hitloc ( : , 1 )  -  hitloc ( i , 1 ) ;
    hitloc( : , 2 ) = hitloc ( : , 2 )  -  hitloc ( i , 2 ) ;
    
  end % yoking
  
  % Translate into place , relative to centre of the screen
  hitloc( : , 1 ) = S.vp.fcentre_x  +  tconst.origin( 1 )  +  ...
    hitloc( : , 1 ) ;
  hitloc( : , 2 ) = S.vp.fcentre_y  +  tconst.origin( 2 )  + ...
    hitloc( : , 2 ) ;
  
end % hitregloc


% Random dot positions , returns 2 by n matrix with x-coordinates in first
% row and y-coordinates in the second row , each column defines one dot
function  pos = rndpos ( r , n )
  
  % Convert from real number on [ 0 , 1 ] into an angle ...
  theta = 2 * pi * rand( 1 , n ) ;
  
  % ... and radius
  radius = r * sqrt( rand( 1 , n ) ) ;
    
  % Polar to cartesian coordinates
  pos = [  radius .* cos( theta )  ;  radius .* sin( theta )  ] ;
  
end % randdotxy


% Find noise dots from the last frame to convert into signal dots. Return
% indeces of dead signal dots to replace, noise dots to replace them, and
% indeces of dead signal dots that were not replaced. Do separately per
% patch.
function  [ drep , nrep , norep ] = noise2sig ( S , p , d )
  
  % Find indices of dead dots from patch p
  i = d (  ( p - 1 ) * S.Nsig < d  &  d <= p * S.Nsig  ) ;
  
  % Number of dead dots in patch
  n = numel ( i ) ;
  
  % Noise dots that we can transform to signal dots
  nrep = S.Nsig_total  +  ( p - 1 ) * S.Nnoise  +  ...
    ( 1 : min ( [ S.Nnoise , n ] ) ) ;
  
  % Number of noise dots tranformed
  n = numel ( nrep ) ;
  
  % Return indeces of signal dots that have a noise dot to replace it
  drep = i ( 1 : n ) ;
  
  % Return indeces of signal dots that were not replaced
  norep = i ( n + 1 : end ) ;
  
end % noise2sig

