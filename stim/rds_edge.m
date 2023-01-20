
function  [ type , varpar , init , stim , close , chksum ] = ...
                                                       rds_edge ( rfdef )
% 
% [ type , varpar , init , stim , close , chksum ] = rds_edge ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Draws one or more bisected random-dot stereograms (RDS), meaning that
% each RDS is comprised of two halves, each with its own set of dots that
% have their own binocular disparity. Each RDS is a circle, while each
% section is a half-circle. The orientation of the bisection is variable.
% Half of all dots are lighter than the background, and half are darker.
% 
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
%   surround_radius - Radius, or width, of an annular region filled with
%     uncorrelated dots. Default 1.
%   
%   centre_radius - Radius of one RDS from its centre, in degrees of visual
%     field. Default 2. 
%   
%   orientation - The orientation of the boundary between the two halves,
%     in counter-clockwise degrees of rotation where 0 is horizontal and 90
%     is vertical. Default 90.
%   
%   delta_orient - An additional amount added to orientation, in degrees.
%     The purpose is to allow a popout stimulus to change its orientation
%     relative to some baseline value, through a stimulus event. Default 0.
%   
%   elevation - The distance from the centre of the RDS circle to the
%     disparity boundary travelling in a direction that is orientation + 90
%     degrees, in degrees of visual field. Hence, if orientation is zero,
%     then positive values move the boundary towards the top, and negative
%     values towards the bottom. Default 0.
%   
%   disp_area1 , disp_area2 - The additional disparity in degrees of visual
%     field that is added to dots in areas 1 and 2. Area 1 is the
%     half-cicle that occupies the top half of the RDS when orientation is
%     0, while area 2 is the bottom half. Default 0.
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
% Written by Jackson Smith - August 2017 - DPAG , University of Oxford
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
     'surround_radius' , 'f' ,   1.00 ,  0.0 , +Inf ;
       'centre_radius' , 'f' ,   2.00 ,  0.0 , +Inf ;
         'orientation' , 'f' ,  90.00 , -Inf , +Inf ;
        'delta_orient' , 'f' ,   0.00 , -Inf , +Inf ;
           'elevation' , 'f' ,   0.00 , -Inf , +Inf ;
          'disp_area1' , 'f' ,   0.00 , -Inf , +Inf ;
          'disp_area2' , 'f' ,   0.00 , -Inf , +Inf ;
             'monovis' , 'i' ,   0    ,  0   ,  2   ;
            'dot_type' , 'i' ,   1    ,  0   ,  1   ;
           'dot_width' , 'f' ,   0.08 ,  0   , +Inf ;
        'dot_lifetime' , 'f' ,   0.00 ,  0   , +Inf ;
         'dot_density' , 'f' ,   0.25 ,  0   ,  1.0 ;
        'dot_contrast' , 'f' ,   1.00 ,  0.0 ,  1.0 ;
           'disp_base' , 'f' ,   0.00 , -Inf , +Inf ;
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
  
  % Set baseline dot disparity equal to RF's preference
  i = strcmp (  varpar( : , 1 )  ,  'disp_base'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).disparity ;
  
  % Match orientation
  i = strcmp (  varpar( : , 1 )  ,  'orientation'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).orientation ;
 
  
end % rds_edge


%%% Stimulus definition handles %%%

% Trial initialisation function
function  S = finit ( vpar , tconst , ~ )
  
  
  %%% Check parameters %%%
  
  % Monoscopic mode
  if  ~ tconst.stereo
    
    error (  'MET:rds_edge:badparam'  ,  [ 'rds_edge: ' , ...
      'Cannot run in monocular mode' ]  )
    
  % Neither ffirst , flast , fyoke, nor fposition may exceed N
  elseif  any( vpar.fnumrds  <  ...
      [ vpar.ffirst , vpar.flast , vpar.fyoke , vpar.fposition ] )
    
    error (  'MET:rds_edge:badparam'  ,  [ 'rds_edge: ' , ...
      'Neither ffirst (%d) , flast (%d) , fyoke (%d) , nor ' , ...
      'fposition (%d) may exceed fnumrds (%d)' ]  ,  ...
      vpar.ffirst  ,  vpar.flast  ,  vpar.fyoke  ,  vpar.fposition  ,  ...
      vpar.fnumrds  )
    
  % ffirst must be less than or equal to flast
  elseif  vpar.flast  <  vpar.ffirst
    
    error (  'MET:rds_edge:badparam'  ,  [ 'rds_edge: ' , ...
      'ffirst (%d) must not exceed flast (%d)' ]  ,  vpar.ffirst  ,  ...
      vpar.flast  )
    
  end % varpar check
  
  
  %%% Build stimulus descriptor %%%
  
  % Keep a copy of variable parameters in their original units
  S.vp = vpar ;
  
  % List stimulus constant parameters i.e. these ignore stimulus events
  S.const = { 'fnumrds' , 'ffirst' , 'flast' , 'surround_radius' , ...
    'centre_radius' , 'dot_type' , 'dot_width' , 'dot_density' , ...
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
  
  
  %-- Dot size limits --%
  
  % Get minimum and maximum dot size in pixels , draws nothing
  [ S.dotmin , S.dotmax ] = Screen ( 'DrawDots' , tconst.winptr ) ;
  
  
  %-- Unit change to pixels --%
  
  % Absolute disparity of each area
  S.d = tconst.pixperdeg  *  ...
    ( S.vp.disp_base  +  [ S.vp.disp_area1 , S.vp.disp_area2 ] ) ;
  
  % Half disparities
  S.hd = S.d  ./  2 ;
  
  % Radius of central RDS
  S.crad = tconst.pixperdeg  *  S.vp.centre_radius ;
  
  % Squared radius of centre
  S.crad2 = S.crad  ^  2 ;
  
  % Radius of annular surround region
  S.srad = tconst.pixperdeg  *  S.vp.surround_radius ;
  
  % Squared radius of entire RDS
  S.rdsrad2 = ( S.crad  +  S.srad )  ^  2 ;
  
  % Difference of squared radii
  S.sqrdif = S.rdsrad2  -  S.crad2 ;
  
  % Normalise orientation to a range between 0 and 360
  S.orientation = mod (  S.vp.orientation + S.vp.delta_orient  ,  360  ) ;
  if  S.orientation  <  0  ,  S.orientation  =  360 + S.orientation ;  end
  
  % Elevation, in pixels
  S.elevation = S.vp.elevation  *  tconst.pixperdeg ;
  
  % Slope of half-circle boundary line , take negative angle to compensate
  % for PTB coordinate system
  S.slope = tand (  - ( S.vp.orientation + S.vp.delta_orient )  ) ;
  
  % The x and y-axis offset to apply to the line depends on the elevation
  % term. Apply unary negation to the y offset to compensate for PTB
  % coordinate system.
  S.xoff = S.elevation  *  + cosd ( S.orientation  +  90 ) ;
  S.yoff = S.elevation  *  - sind ( S.orientation  +  90 ) ;
  
  % Dot width
  S.dotwid = tconst.pixperdeg  *  S.vp.dot_width ;
  
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
  
  
  %-- Areas --%
  
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
  
  % Area of RDS centre
  S.ards = pi  *  S.crad2 ;
  
  % Area of RDS surround
  S.asur = pi  *  S.rdsrad2  -  S.ards ;
  
  
  %-- Number of dots per RDS --%
  
  % Centre
  S.Nrds = ceil (  S.vp.dot_density  *  S.ards  /  S.adot  ) ;
  
  % Surround
  S.Nsur = ceil (  S.vp.dot_density  *  S.asur  /  S.adot  ) ;
  
  % Total number of central dots
  S.Nctotal = S.RDSn  *  S.Nrds ;
  
  % Total number of surround dots
  S.Nstotal = S.RDSn  *  S.Nsur ;
  
  % Total number of dots in all RDSs
  S.Ntotal = S.Nctotal  +  S.Nstotal ;
  
  
  %-- Define dot buffers --%
  
  % Buffers that represent all dots in all RDSs. We have enough space for
  % 2 * central dots plus surround. This is so that we can use a
  % brute-force approach to generating uncorrelated surround dots
  
  % Dot life timer i.e. image timer. This counts down the number of frames
  % per RDS image. Initialise zero so that an image is created on first
  % call to stimulation function.
  S.timer = 0 ;
  
  % Dot coordinates. We generate random numbers to get a meaningful
  % checksum. Row indexes by axis, x ( 1 ) and y ( 2 ). Columns index
  % across dots. See above re: 2D arrays, this is applied using column
  % indexing in this ( and all ) dot buffers. The size is 2 in the 3rd
  % dimension, containing the left- then right-eye dot buffers.
  S.xy = rand ( 2 , S.Ntotal + S.Nctotal , 2 ) ;
  
  % Dot greyscale index, makes odd dots light and even dots dark
  S.gi = repmat (  ...
    uint8 (  mod( 0 : 2 * S.Nrds + S.Nsur - 1 , 2 )  +  1  ) ,  S.RDSn ,...
      1  ) ;
  S.gi = S.gi( : )' ;
  
  
  %-- Hit regions --%
  
  % We will use the 5-column form defining a set of circular regions
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  S.hitregion = zeros ( S.RDSn , 5 ) ;
  
  % Initialise hit region radius and disparity
  S.hitregion( : , c6.radius ) = max ( [  S.vp.hminrad  ,  ...
    S.vp.centre_radius  +  S.vp.surround_radius  ] ) ;
  S.hitregion( : , c6.disp   ) = S.vp.disp_base  +  tconst.origin( 3 ) ;
  S.hitregion( : , c6.dtoler ) = S.vp.hdisptol ;
  
  % Initialise hit region positions
  S.hitregion( : , [ c6.xcoord , c6.ycoord ] ) = hitregpos ( tconst , S ) ;
  
  % Set whether or not to ignore the stimulus
  S.hitregion( : , c6.ignore ) = S.vp.hitcheck ;
  
  
end % finit


% Stimulation function
function  [ S , h ] = fstim ( S , tconst , tvar )

  
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
      
      % Orientation of half-circle boundary
      if  d.orientation  ||  d.delta_orient
        
        % Normalise
        S.orientation = ...
          mod (  S.vp.orientation  +  S.vp.delta_orient  ,  360  ) ;
        
        if  S.orientation  <  0
          S.orientation  =  360 + S.orientation ;
        end
        
        % Slope of half-circle boundary line
        S.slope = tand (  - ( S.vp.orientation  +  S.vp.delta_orient )  ) ;
        
      end % orientation
      
      % Elevation change
      if  d.elevation
        
        % Elevation, in pixels
        S.elevation = S.vp.elevation  *  tconst.pixperdeg ;
        
        % The x and y-axis offsets
        S.xoff = S.elevation  *  + cosd ( S.orientation  +  90 ) ;
        S.yoff = S.elevation  *  - sind ( S.orientation  +  90 ) ;
        
      end % elevation
      
      % Dot lifetime change
      if  d.dot_lifetime  ,  S = frames ( tconst , S ) ;  end
      
      % Contrast change
      if  d.dot_contrast  ,  S = grey ( S ) ;  end
      
      % Baseline or area 1 disparity change , find full and half disparity
      if  d.disp_base  ||  d.disp_area1
        S.d( 1 ) = tconst.pixperdeg  *  ...
          ( S.vp.disp_base  +  S.vp.disp_area1 ) ;
        S.hd( 1 ) = S.d( 1 )  /  2 ;
      end
      
      % Check again for area 2
      if  d.disp_base  ||  d.disp_area2
        S.d( 2 ) = tconst.pixperdeg  *  ...
          ( S.vp.disp_base  +  S.vp.disp_area2 ) ;
        S.hd( 2 ) = S.d( 2 )  /  2 ;
      end
      
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
      
      end % hit region change
      
    end % variable parameter change
    
    
    %-- Generate new image --%
    
    % Image lifetime expired
    if  ~ S.timer
      
      % Reset timer
      S.timer = S.frames ;
      
      % Index for central dots
      i = 1 : S.Nctotal ;
      
      % Start by sampling dots relative to RDS centre , get enough for all
      % RDSs
      S.xy( : , i , 1 ) = rnddot (  S.Nctotal  ,  S.crad2  ,  0  ) ;
      
      % Assign dots to disparity areas
      ai = assignarea ( S , i , 1 ) ;
      
      % Copy left-eye positions to the right dot buffer
      S.xy( : , i , 2 ) = S.xy( : , i , 1 ) ;
      
      % Apply left and right-eye disparities
      S.xy( 1 , i , 1 ) = S.xy( 1 , i , 1 )  -  S.hd( ai ) ;
      S.xy( 1 , i , 2 ) = S.xy( 1 , i , 2 )  +  S.hd( ai ) ;
      
      % Translate central dots into position with RDS index vector
      j = repmat (  S.vp.ffirst : S.vp.flast  ,  1  ,  S.Nrds  ) ;
      
      % Add RDS position to dots
      S.xy( : , i , : ) = S.xy( : , i , : )  +  ...
        repmat (  S.frdsxy( : , j )  ,  1  ,  1  ,  2  ) ;
      
      % Surround dot index
      i = S.Nctotal + 1 : S.Ntotal + S.Nctotal ;
      
      % Sample uncorrelated surround dots
      S.xy( : , i , : ) = reshape (  ...
        rnddot( 2 * S.Ntotal ,  S.rdsrad2 ,  0 )  ,  2  ,  S.Ntotal  ,  ...
          2  ) ;
        
      % Loop eye buffers
      for  e = 1 : 2
        
        % Find dots that might need to be removed i.e. do not have y-coord
        % above or below the top of the central circle
        k = repmat (  - S.crad  <=  S.xy( 2 , i , e )  &  ...
                      + S.crad  >=  S.xy( 2 , i , e )  ,  2  ,  1  ) ;
        
        % Loop disparity areas
        for  b = 1 : 2
          
          % Shift surround dots in the opposite direction to that of the
          % centre dots in this area. This has the effect of placing all
          % surround dots into a coordinate system that is relative to the
          % disparity area.
          switch  e
            case  1  ,  x = S.xy( 1 , i( k( b , : ) ) , e )  +  S.hd( b ) ;
            case  2  ,  x = S.xy( 1 , i( k( b , : ) ) , e )  -  S.hd( b ) ;
          end
          
          % And find dots within radial distance of centre
          r = (  x .^ 2  +  ...
            S.xy( 2 , i( k( b , : ) ) , e ) .^ 2  )  .^  0.5  <=  ...
              S.crad ;
            
          % Vertical line, we need to compare shifted x-coord versus the
          % y-axis i.e. coordinate zero
          if  any ( S.orientation  ==  [ 90 , 270 ] )
            
            % The test coordinates are the shifted x-coordinates
            c = x ;
            
            % And the boundary line coordinate is zero
            bcoord = 0 ;
            
          % Line is on some other angle
          else
            
            % The test coordinates are therefore the dots' y-axis locations
            c = S.xy( 2 , i( k( b , : ) ) , e ) ;
            
            % And the boundary line coordinate is the dots' projections
            % along a vertical line onto the disparity boundary
            bcoord = S.slope * ( x  -  S.xoff )  +  S.yoff ;
            
          end % horizontal line
          
          % Cases where rejected dots have coordinates greater than the
          % boundary line. Note that the bcoord versus c comparisons are
          % opposite to what we might expect in a Cartesian coordinate
          % system. Again, they are reversed to compensate for the PTB
          % coordinate system.
          if  ( b == 1  &&  ...
                ( S.orientation <= 90  ||  270 <  S.orientation )  )  ||...
              ( b == 2  &&  ...
                ( S.orientation >  90  &&  270 >= S.orientation )  )
            
            k( b , k( b , : ) ) = r  &  bcoord >= c ;
            
          % Otherwise rejected dots have coordinates less than the boundary
          % line
          else
            
            k( b , k( b , : ) ) = r  &  bcoord <= c ;
            
          end % Find rejected dots
          
        end % disparity areas
        
        % Now that we've found the dots to drop, we also know which ones to
        % keep
        k = all ( ~ k , 1 ) ;
        
        % Number of kept surround dots
        S.N( e ) = sum ( k ) ;
        
        % Indices of kept dots
        j = i (  1 : S.N( e )  ) ;
        
        % Reshuffle kept dots into place
        S.xy( : , j , e ) = S.xy( : , i( k ) , e ) ;
        
        % Get RDS index for each kept dot
        r = mod (  0 : S.N( e ) - 1  ,  S.RDSn  )  +  S.vp.ffirst ;
        
        % Translate surround dots to RDSs
        S.xy( : , j , e ) = S.xy( : , j , e )  +  S.frdsxy( : , r ) ;
        
      end % eye buffers
      
      % Total number of dots per dot buffer
      S.N = S.N  +  S.Nctotal ;
      
      
      %   Randomly permute drawing order   %
      
      % Find dots to mix
      j = 1 : min( S.N ) ;
      
      % Generate permutation
      i = randperm (  min( S.N )  ) ;
      
      % Apply
      S.xy( : , j , : ) = S.xy( : , i , : ) ;
      
      
    end % new image
    
    
  % Right-eye frame buffer
  else
    
    
    % Count down one more frame from the timer
    S.timer = S.timer  -  1 ;
    
    
  end % left-eye frame buffer
  
  
  %%% Draw monocular image %%%
  
  % monovis flag does not allow this monocular image to be seen.
  if  S.vp.monovis  &&  S.vp.monovis ~= tvar.eyebuf + 1
    return
  end
  
  % Set the anti-aliasing mode
  Screen ( 'BlendFunction' , tconst.winptr , ...
    'GL_SRC_ALPHA' , 'GL_ONE_MINUS_SRC_ALPHA' ) ;
  
  % Select dot buffer
  i = tvar.eyebuf  +  1 ;
  
  % Dot indices
  j = 1 : S.N( i ) ;
  
  % Draw to the frame buffer
  Screen (  'DrawDots'  ,  tconst.winptr  ,  S.xy( : , j , i )  ,  ...
    S.dotwid  ,  S.g( : , S.gi( j ) )  ,  S.fcxy  ,  S.dot_type  ) ;
  
  
end % fstim


% Trial closing function
function  S = fclose ( ~ , ~ )
  
  S = [] ;
  
end % close


% Check-sum function
function  c = fchksum ( S )

  % Return sorted sum
  c = sum ( sort(  S.xy( : )  ) ) ;
  
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
  
  % Sample uniformly distributed points. AT stands for 'A'ngular radius and
  % 'T'heta. Because we will next convert these into polar coordinates.
  AT = rand ( 2 , n ) ;
  
  % Convert row 1 into radii
  AT( 1 , : ) = (  w  * AT( 1 , : )  +  r  )  .^  0.5 ;
  
  % And convert row 2 into angles, in radians
  AT( 2 , : ) = 2 * pi * AT( 2 , : ) ;
  
  % Transform polar coordinates to Cartesian and return
  xy = [  AT( 1 , : )  .*  cos( AT( 2 , : ) )  ;
          AT( 1 , : )  .*  sin( AT( 2 , : ) )  ] ;
  
end % rnddot


function  ai = assignarea ( S , i , j )
  
  % Determine which dot landed in which area , first check the special
  % cases where the boundary is perfectly horizontal or vertical.
  % Remember to compensate for PTB coordinate system
  if  S.orientation  ==  0

    % Orientation of zero , area 1 is above horizontal line and area 2
    % is below
    ai = ( S.xy( 2 , i , j )  >  S.yoff )  +  1 ;

  elseif  S.orientation  ==  180

    % Orientation of 180 , area 1 is below horizontal line and area 2
    % is above
    ai = ( S.xy( 2 , i , j )  <  S.yoff )  +  1 ;

  elseif  S.orientation  ==  90

    % Orientation is 90 degrees , area 1 is to the left
    ai = ( S.xy( 1 , i , j )  >  S.xoff )  +  1 ;

  elseif  S.orientation  ==  270

    % Orientation is 270 degrees , area 1 is to the right
    ai = ( S.xy( 1 , i , j )  <  S.xoff )  +  1 ;

  else

    % Calculate the y-coordinate of the slope line that forms a
    % perfectly vertical line with each dot
    yhat = S.slope * ( S.xy( 1 , i , j )  -  S.xoff )  +  S.yoff ;
  
    % The orientation is at some other angle , so use the slope of the
    % line to categorise dots
    if  S.orientation < 90  ||  270 < S.orientation

      % Area 1 is above the line
      ai = ( S.xy( 2 , i , j )  >  yhat )  +  1 ;

    else

      % Area 1 is below the line
      ai = ( S.xy( 2 , i , j )  <  yhat )  +  1 ;

    end

  end % assign dots to areas
  
end

