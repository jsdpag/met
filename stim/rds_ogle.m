
function  [ type , varpar , init , stim , close , chksum ] = ...
                                                         rds_ogle ( rfdef )
% 
% [ type , varpar , init , stim , close , chksum ] = rds_ogle ( rfdef )
%
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Implements Ogle's induced effect by drawing a random dot stereogram with
% a square aperture. This works by compressing or expanding the dot
% positions in the horizontal and/or vertical directions in one or both of
% the monocular images. Dot positions are randomly sampled for each frame.
% One random half of dots the are lighter than the background and the other
% half are darker ; dot occlusion is random. The stimulus is created
% deterministically during initialisation and will not respond dynamically
% to stimulus events. Can generate an array of RDS objects on screen,
% arranged in a circle around a central point at a certain radius with even
% spacing in between. Uncorrelated dots are used to fill the square
% aperture when compressions under 100% are used.
% 
% Check sum is the sum of all dot cooridates over all frames:
% 
%   c = c  +  x( f , e , d )  +  y( f , e , d )
% 
%   where we index frames, then eye buffer, then dot.
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
%   %-- Global dot parameters --%
%   
%   These apply to all dots, in every RDS.
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
%   dot_seconds - The amount of time that the stimulus will be presented
%     for. The number of frames generated during initialisation will be
%     this duration divided by the duration of one frame, rounded up to
%     guarantee at least one frame. Default 1 second.
%   
%   apt_width - The width of the square apeterture in both dimentions in
%     degrees of visual field. Default 1 degree.
%   
%   
%   %- Monocular properties -%
%   
%   left_hor_comp - The percentage of horizontal compression in the left
%     eye's monocular image. Percentage of the aperture width. Default
%     100%.
%   
%   left_ver_comp - Percentage of vertical compression in left eye image.
%     Default 100%.
%   
%   right_hor_comp & right_ver_comp - Compression values for right eye
%     image. Default 100%.
%   
%   
%   %-- Hit region --%
%   
%   A hit region is defined for each RDS that is drawn. The region is
%   square in shape, centred on the RDS, and matches the aperture. If
%   the user selects a point on screen inside any of these hit regions,
%   then the associated task stimulus will be selected.
%   
%   hminwid - Minimum width of the hit region around each RDS, in degrees
%     of visual field. Default 0.75.
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
% When rfdef is non-empty, then default variable parameters will be set to
% match the preferences of RF number 1 i.e. rfdef( 1 ). The formation
% circles fradius and fangle are chosen so that RDS position 1 is
% centred on the RF. The RDS dot contrast and aperture width are matched to
% the RF preferences. If neighbours will overlap then the formation circle
% coordinate is centred in the RF and position 1 is yoked ; an fradius is
% chosen to put a 1-degree gap between neighbours ; the fangle set before
% yoking is used.
% 
% Written by Juan Carlos Nunez Mendez - June 2019 - DPAG, Uni. of Oxford
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
           'dot_width' , 'f' ,   0.16 ,  0   , +Inf ;
         'dot_density' , 'f' ,   0.20 ,  0   ,  1.0 ;
        'dot_contrast' , 'f' ,   1.00 ,  0.0 ,  1.0 ;
         'dot_seconds' , 'f' ,   1.00 ,  0.0 , +Inf ;
           'apt_width' , 'f' ,   1.00 ,  0.0 , +Inf ;
       'left_hor_comp' , 'f' , 100.00 ,  0.0 , +Inf ;
       'left_ver_comp' , 'f' , 100.00 ,  0.0 , +Inf ;
      'right_hor_comp' , 'f' , 100.00 ,  0.0 , +Inf ;
      'right_ver_comp' , 'f' , 100.00 ,  0.0 , +Inf ;
             'hminwid' , 'f' ,   0.75 ,  0.0 , +Inf ;
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
              {     'width' , 'apt_width' }  }
    
    % Give generic names to strings
    [ fn , vp ] = C{ 1 }{ : } ;
    
    % Copy RF preference to default variable param
    varpar{ i.( vp ) , 3 } = rfdef.( fn ) ;
    
  end % match RF prefs
  
  % RDS total diameter i.e. width , centre and surround
  w = sqrt (  2  *  varpar{ i.apt_width , 3 } ^ 2  ) ;
  
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
  
  
end % rnddot_ogle


%%% Stimulus definition handles %%%

% Trial initialisation function
function  S = finit ( vpar , tconst , ~ )
  
  
  %%% Check parameters %%%
      
  % Monoscopic mode
  if  ~ tconst.stereo  &&  any (  [ vpar.left_hor_comp , ...
      vpar.left_ver_comp , vpar.right_hor_comp , ...
        vpar.right_ver_comp ] ~= 100  )
    
    fprintf (  [ 'rds_ogle: ' , ...
      'monocular mode , all compression params set to 100%' ]  )
    
    % Compression values to 100%
     vpar.left_hor_comp = 100 ;
     vpar.left_ver_comp = 100 ;
    vpar.right_hor_comp = 100 ;
    vpar.right_ver_comp = 100 ;

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
    
  end % varpar check
  
  
  %%% Trial initialisation %%%
  
  
  %-- Preparation --%
  
  % Get working copy of trial variable parameter values
  h.vp = vpar ;
  
  % Number of frame buffers 1 - monocular , 2 - stereoscopic
  h.numeye = 1  +  ( 0  <  tconst.stereo ) ;
  
  % Number of RDS drawn
  h.numrds = vpar.flast  -  vpar.ffirst  +  1 ;
  
  % RDS index vector
  h.irds = vpar.ffirst : vpar.flast ;
  
  % Calculate formation circle coordinate
  h = getfc ( h , tconst ) ;
  
  % Calculate centre of each RDS position around the formation circle
  % coordinate
  h = rdspos ( h , tconst ) ;
  
  % Find the greyscale value for light and dark dots
  h = greyscale ( h ) ;
  
  % Minimum and maximum dot width in pixels
  h = dotminmax ( h , tconst ) ;
  
  % Dot internal parameters
  h = dotpar ( h , tconst ) ;
  
  % Width of aperture in pixels
  h.wid = vpar.apt_width  *  tconst.pixperdeg ;
  
    % Half width
    h.hwid = h.wid  /  2 ;
  
  % Minimum horizontal and vertical compression factors , convert to
  % fractions
  h.minhor = min (  vpar.left_hor_comp  ,  vpar.right_hor_comp  )  /  100 ;
  h.minver = min (  vpar.left_ver_comp  ,  vpar.right_ver_comp  )  /  100 ;
  
  % Apply compression factor to find uncompressed aperture size
  h.apthor = h.wid  /  h.minhor ;
  h.aptver = h.wid  /  h.minver ;
  
    % Half widths
    h.haphor = h.apthor  /  2 ;
    h.hapver = h.aptver  /  2 ;
  
  % Area of uncompressed aperture?
  h.aapt = h.apthor  *  h.aptver ;
  
  % How many dots per RDS?
  h.rdsdot = ceil (  h.aapt  /  h.adot  *  vpar.dot_density  ) ;
  
  % Total number of dots over all RDS
  h.numdot = h.rdsdot  *  h.numrds ;
  
  % Put compression parameters into matrix where horizontal and vertical
  % are indexed into rows 1 and 2, while left and right eyes are indexed
  % into columns 1 and 2 , converted to fractions
  comp = [  vpar.left_hor_comp  ,  vpar.right_hor_comp  ;
            vpar.left_ver_comp  ,  vpar.right_ver_comp  ]  ./  100 ;
          
  % Index vectors for accessing dots in each rds
  h.dotind = cell (  h.numrds  ,  1  ) ;
  
  for  j = 1 : h.numrds
    h.dotind{ j } = ( j - 1 ) * h.rdsdot + ( 1 : h.rdsdot ) ;
  end
  
  
  %-- Stimulus descriptor --%
  
  % Frame index , initialised to zero. We simply increment this number on
  % ever call to fstim with the left-eye (or monocular) frame buffer.
  S.frmind = 0 ;
  
  % Maximum number of frames to compute
  if  vpar.dot_seconds
    S.numfrm = ceil (  vpar.dot_seconds  /  tconst.flipint  ) ;
  else
    S.numfrm = 1 ;
  end
  
  % Allocate cell array for dot coordinates and dot colours, one element
  % per frame. S.xy has 2 columns in stereo mode, indexing [ left, right ].
  S.xy     = cell (  S.numfrm  ,  h.numeye  ) ;
  S.colour = cell (  S.numfrm  ,  h.numeye  ) ;
  
  % Remember dot diameter for later
  S.size = h.dotwid ;
  
  % Frames
  for  i = 1 : S.numfrm
    
    % Generate raw dot x- and y-axis coordinates for all RDS objects ,
    % with aperture centred at origin
    h.x_raw = h.apthor  *  rand (  1  ,  h.numdot  )  -  h.haphor ;
    h.y_raw = h.aptver  *  rand (  1  ,  h.numdot  )  -  h.hapver ;
    
    % Randomly sample colour index for each dot
    h.cind = (  0.5  <  rand( 1 , h.numdot )  )  +  1 ;
    
    % Left and right eye
    for  e = 1 : h.numeye
      
      % Apply horizontal and vertical compression
      h.x = h.x_raw  *  comp( 1 , e ) ;
      h.y = h.y_raw  *  comp( 2 , e ) ;
      
      % Find dots that still lie within the uncompressed aperture
      k = -h.hwid <= h.x  &  h.x <= +h.hwid  &  ...
          -h.hwid <= h.y  &  h.y <= +h.hwid ;
        
      % RDS objects
      for  j = 1 : h.numrds
        
        % Index for dots in this RDS
        d = h.dotind{ j } ;
        
        % RDS position index
        irds = h.irds( j ) ;
        
        % Shift dots to their absolute position on screen
        h.x( d ) = h.x( d )  +  h.rdsp( irds , 1 ) ;
        h.y( d ) = h.y( d )  +  h.rdsp( irds , 2 ) ;
        
      end % RDS
      
      % Make one frame's worth of dots
      S.xy{ i , e } = [  h.x( k )  ;  h.y( k )  ] ;
      
      % Colour matrix for this frame
      S.colour{ i , e } = repmat (  h.grey( h.cind( k ) )  ,  3  ,  1  ) ;
      
    end % left/right
    
  end % frames
  
  
  %-- Hit regions --%
  
  % We will use the 8-column form defining a set of circular regions
  c8 = tconst.MCC.SDEF.ptb.hitregion.eightcol ;
  
  % Initialise hit region positions
  h = hitregpos ( h , tconst ) ;
  
  % Allocate hit region memory
  S.hitregion = zeros (  h.numrds  ,  8  ) ;
  
  % Get hit region locations
  S.hitregion( : , [ c8.xcoord , c8.ycoord ] ) = h.hitregion ;
  
  % Initialise hit region radius and disparity
  S.hitregion( : , c8.width  ) = max ( [ vpar.hminwid , vpar.apt_width ] );
  S.hitregion( : , c8.height ) = S.hitregion( : , c8.width  ) ;
  S.hitregion( : , c8.rotation ) = 0 ;
  S.hitregion( : , c8.disp   ) = tconst.origin( 3 ) ;
  S.hitregion( : , c8.dtoler ) = vpar.hdisptol ;
  
  % Set whether or not to ignore the stimulus
  S.hitregion( : , c8.ignore ) = vpar.hitcheck ;
  
end  % finit


% Stimulation function
function  [ S , hitflg ] = fstim ( S , tconst , tvar )
  
  % Hit region update never happens , this is a deterministic stimulus
  hitflg = false ;
  
  % Monocular eye buffer
  if  tvar.eyebuf  ==  -1
    
    e = 1 ;
    
  % Stereoscopic mode
  else
    
    % Get eye buffer index
    e = tvar.eyebuf  +  1 ;
    
  end % stereo state
  
  % Update frame index for monocular or left eye frame buffer
  if  e  ==  1
    
    S.frmind = S.frmind  +  1 ;
    
    % Buffer over-run , reset to first frame
    if  S.numfrm  <  S.frmind  ,  S.frmind = 1 ;  end
  
  end % update frame index
  
  % Set alpha blending
  Screen (  'BlendFunction' ,  tconst.winptr ,  'GL_SRC_ALPHA' ,  ...
    'GL_ONE_MINUS_SRC_ALPHA'  ) ;
  
  % Draw dots
  Screen (  'DrawDots' ,  tconst.winptr ,  S.xy{ S.frmind , e } ,  ...
    S.size ,  S.colour{ S.frmind , e } ,  [] ,  2  ) ;
  
end % fstim


% Trial closing function
function  Sout = fclose ( ~ , type )

  % React to the requested type of stimulus closure
  switch  type
    
    % Close trial
    case  't'
      
      % Return empty array
      Sout = [ ] ;
      
    % Close session
    case  's'
      
      % Return empty array
      Sout = [ ] ;
    
  end % type of closure
  
end % fclose


% Check-sum function
function  c = fchksum ( S )
  
  % Initialise zero
  c = 0 ;

  % Frames
  for  i = 1 : S.numfrm
    
    % Eye buffers
    for  e = 1 : 2
        
      c = c  +  sum (  S.xy{ i , e }( : )  ) ;
        
    end % eye
  end % frames
  
end % fchksum


%%% Sub-routines %%%


% Compute the formation circle coordinate
function  h = getfc ( h , tconst )

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
function  h = rdspos ( h , tconst )

  % Number of RDS positions
  N = h.vp.fnumrds ;

  % Formation circle radius , in pixels
  radpix = h.vp.fradius  *  tconst.pixperdeg ;

  % Angle of each RDS position , counter-clockwise around the formation
  % circle.
  a = 360 / N  *  ( 0 : N - 1 )  +  h.vp.fangle ;

  % Change RDS positions from polar to Cartesian coordinates , in
  % pixels from the formation circle coordinate. The y-coord reflection
  % accounts for the PTB coordinate system.
  h.rdsp = [  + radpix  *  cosd( a )  ;
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
function  h = greyscale ( h )

  % Column 1 is light , 2 is dark
  h.grey = [ 0.5 , -0.5 ] * h.vp.dot_contrast  +  0.5 ;

end % grey

% Calculate the min and max dot width in degrees of visual field
function  h = dotminmax ( h , tconst )

  % Get minimum and maximum dot size in pixels , draws nothing
  [ h.dotmin( 1 ) , h.dotmax( 1 ) ] = Screen ( 'DrawDots' , ...
    tconst.winptr ) ;

end % dotminmax

% Dot internal parameters. Convert dot width to pixels and cap to system
% limits , if needed. Finds area of a dot. Assigns DrawDot type code.
function  h = dotpar ( h , tconst )

  % Convert from degrees of visual field to pixels on screen
  h.dotwid = h.vp.dot_width  *  tconst.pixperdeg ;

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
        sprintf( 'rds_ogle: capping dot width to system %s' , ...
          wstr )  ,  'E' )
        
    catch
    end

  end % dot cap warning
    
  % Area of round dots
  h.adot = pi  *  ( h.dotwid / 2 ) ^ 2 ;

end % dotwidpix


% Calculate the position of each hit region, in degrees from the trial
% origin
function  h = hitregpos ( h , tconst )
  
  % Hit region index map
  c8 = tconst.MCC.SDEF.ptb.hitregion.eightcol ;
  
  % x and y coordinate columns in hit region
  xy = [ c8.xcoord , c8.ycoord ] ;
  
  % Indices of presented RDSs
  i = h.irds ;
  
  % Get PTB coordinate of RDS centres
  h.hitregion = h.rdsp( i , : ) ;
  
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

