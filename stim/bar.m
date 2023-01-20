
function  [ type , varpar , init , stim , close , chksum ] = bar ( rfdef )
% 
% [ type , varpar , init , stim , close , chksum ] = bar ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Draws an array of simple rectangular bars around a single point of
% reference. All bars will have 
% 
% Variable parameters:
%
%   
%   %-- formation circle --%
%   
%   The formation circle is an abstraction for placing each bar relative to
%   the others. The centre of each bar is placed at a unique point on the
%   circumfrance of the formation circle such that each neighbouring bar is
%   separated by the same angle. Thus, four bars will have pi/2 radians (90
%   degrees) between each pair of neighbours. The centre of the formation
%   circle is the default point of reference. Alternatively, the centre of
%   a specified bar can act as the reference point.
%   
%   fnum - The number of bars to draw.  Default 4.
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
%     degrees. That is, the rotation of bars around the centre of the
%     formation circle. When set to zero, the first bar is placed
%     immediately to the right of the formation circle centre ; at 90
%     degrees, the first bar is directly above. Default 0.
%   
%   ffirst - Index of the first drawn bar. This allows fewer bars to be
%     drawn than indicated by fnum, while retaining the same formation
%     as with fnum patches. For instance, if fnum is 4 but ffirst is
%     2 while fangle is 0, then 3 patches are drawn with angles of pi/2,
%     pi, and 3*pi/2 separating each neighbouring pair. Default 1.
%   
%   flast - Index of the final drawn patch. Must be equal to or greater
%     than ffirst, and equal to or less than fnum. Default 4.
%   
%   fyoke - Bar position index (see fposition), integer ranging from 0 to
%     N. If zero, then the centre of the formation circle is placed at the
%     point marked by fxcoord and fycoord. If non-zero, then all bars are
%     translated so that the yoked bar position is centred at ( fxcoord ,
%     fycoord ). But  the relative position of all patches remains the same
%     as if fyoke were zero. In other words, each bar is placed around the
%     centre of the formation circle according to its radius and rotation ;
%     then all bars are translated so that the specified bar has its centre
%     on ( fxcoord , fycoord ). May be less than ffirst or greater than
%     flast. Default 0.
%   
%   fposition - The first bar position sits on the edge of the formation
%     circle at fangle degrees of counter-clockwise rotation around the
%     circle's centre. The second to N positions are hence a further
%     360 / N degrees, each step. fposition says at which point the first
%     bar will be placed, followed counter-clockwise around the
%     circumfrance by the second to Nth bar. In other words, the ith bar
%     will be placed at fangle + 360 / N * ( i + fposition - 2 ) degrees
%     around the edge of the formation circle. Thus fposition must be an
%     integer of 1 to N. Default 1.
%   
%   
%   %-- bar parameters --%
%   
%   orientation - Reference orientation in the middle of the range of
%     orientations that will be sampled from, in Cartesian degrees. If
%     rfdef is given then this value matches rfdef( 1 ).orientation.
%     Default 90.
%   
%   range - Sampled orientations span values from orientation - range to
%     orientation + range. range is a value in degrees between 0 and 90.
%     Default 90 ; with default orientation of 90, this means that values
%     are sampled from 0 to 180 Cartesian degrees.
%   
%   number - The number of equal steps that the span of orientations is
%     divided into. Steps will be in ( 2 * range / number ) degrees. Thus
%     there will be number + 1 steps, if 2 * range < 180. If 2 * range is
%     180 then the last step is excluded. Default 4.
%   
%   step - The index of the orientation step to use for the bar at position
%     1. If 1 < ffirst then this is ignored. This will be an integer from 1
%     to number + 1 if 2 * range < 180 ; or it will be an integer from 1 to
%     number if 2 * range is 180. The orientation of the bar will be
%     orientation  -  range  +  ( step - 1 ) * ( 2 * range / number ).
%     Default 1.
%   
%   perm - The permutation index. Says what orientation the remaining bars
%     will have. The orientation used by 'step' will be excluded, the
%     remaining possible orientations are essentially sampled without
%     replacement, sequentially, for each remaining bar. The algorithm for
%     determining the orientation of each of K bars from N remaining
%     orientations is:
%     
%     For ith remaining bar:
%     
%       % The set of remaining orientation steps
%       S = { step1 , step2 , ... stepN-i+1 }
%     
%       % S[j] is the orientation to use for bar i
%       j = mod( perm - 1 , N ) + 1
%     
%       % Update the set of available orientation steps for bar i + 1
%       Snew = { step1 , ... stepj-1 , stepj+1 , ... stepN-i+1 }
% 
%       Repeat until all bars have an orientation
%   
%     Default value is 1.
%   
%   length - Length of the bars in degrees of visual field. If rfdef
%     provided then this matches rfdef( 1 ).width i.e. the diameter of the
%     receptive field. Default 4.
%   
%   width - The width of the bars in degrees of visual field. Do not
%     confuse this with receptive field width. Default 1.
%   
%   contrast - The contrast of the bars, a value from 0 to 1, assuming a
%     mid-grey background with greyscale 0.5. Default 1.
%   
%   shade - Either 0 or 1 saying that bars are darker (0) or lighter (1)
%     than mid-grey. If contrast is 1 and shade is 1 then the bars are full
%     white ; if contrast is 1 and shade is 0 then bars are full black ; if
%     contrast is 0 then the bars are mid-grey regardless. Default 1.
%   
%   hwidth - Diameter of circular hit regions centred on each bar. If rfdef
%     is provided then this matches rfdef( 1 ).width. Default 4 .
%   
%   hwidmin - The minimum allowable hit region diameter. hwidth is capped
%     at this value, internally. Default 1.5.
%   
%   hdisptol - Hit region disparity tolerance. Convergence may differ from
%     bar disparity by up to this much for the subject to select the
%     stimulus. In degrees of visual field. Default 0.5.
%   
%   hitcheck - A flag saying whether or not to compare the hit regions of
%     this stimulus against eye or touchscreen/mouse positions. A non-zero
%     value enables checking. A value of zero disables checking. May be 0
%     or 1. Default 1.
%   
%   
% To get a separate target bar and distractor bars, set up your MET task
% logic with two task stimulus names e.g. target and distractor. Both of
% these will be linked to the bar.m stimulus definition. For the target,
% make fflast 1 so that only one bar is drawn. For the distractor, make
% ffirst 2 so that 1 to fnum - 1 bars are drawn. When setting up task
% variables, randomly draw the value of step for the target bar. Make the
% distractor bar step value dependent and equal to to the target bar's
% step. Then randomly draw a perm value from the uniform discrete
% distribution from 1 to N! / (N - K)! where N is the number of steps minus
% one (which is used by the target) and K is the number of distractor bars.
% 
% NOTE: No stimulus events are currently implemented, so no dynamic
%   variable parameters are available yet. Stimulus events are silently
%   ignored.
% 
% NOTE: If rfdef provided but the array of bars will overlap each other,
%   then an asymmetrical formation is used, yoked to position 1 which is
%   placed over the receptive field.
% 
% 
% Written by Jackson Smith & Claire Poullias
% March 2019
% DPAG , University of Oxford
% 
  
  
  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set
  varpar = {    'fnum' , 'i' ,   4   ,  1   , +Inf ;
             'fxcoord' , 'f' ,   0.0 , -Inf , +Inf ;
             'fycoord' , 'f' ,   0.0 , -Inf , +Inf ;
             'fradius' , 'f' ,   4.0 ,  0.0 , +Inf ;
              'fangle' , 'f' ,   0.0 , -Inf , +Inf ;
              'ffirst' , 'i' ,   1   ,  1   , +Inf ;
               'flast' , 'i' ,   4   ,  1   , +Inf ;
               'fyoke' , 'i' ,   0   ,  0   , +Inf ;
           'fposition' , 'i' ,   1   ,  1   , +Inf ;
         'orientation' , 'f' ,  90.0 , -Inf , +Inf ;
               'range' , 'f' ,  90.0 ,  0.0 ,  180 ;
              'number' , 'i' ,   4   ,  1   , +Inf ;
                'step' , 'i' ,   1   ,  1   , +Inf ;
                'perm' , 'i' ,   1   ,  1   , +Inf ;
              'length' , 'f' ,   4.0 ,  0.0 , +Inf ;
               'width' , 'f' ,   1.0 ,  0.0 , +Inf ;
            'contrast' , 'f' ,   1.0 ,  0.0 ,  1.0 ;
               'shade' , 'i' ,   1   ,  0   ,  1   ;
              'hwidth' , 'f' ,   4.0 ,  0.0 , +Inf ;
             'hwidmin' , 'f' ,   1.5 ,  0.0 , +Inf ;
            'hdisptol' , 'f' ,   0.5 ,  0.0 , +Inf ;
            'hitcheck' , 'i' ,   1   ,  0   ,  1   } ;
  
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
  
  % Set formation circle radius and angle so that bar position 1 lands in
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
  
	% Match reference orientation, bar length, bar contrast, and bar hit
	% region width. C maps rfdef field name to variable parameter name.
  for  C = {  {  'orientation'  ,  'orientation'  }  ,  ...
              {        'width'  ,  'length'       }  ,  ...
              {     'contrast'  ,  'contrast'     }  ,  ...
              {        'width'  ,  'hwidth'       }  }
    
    % Give generic names to strings
    [ fn , vp ] = C{ 1 }{ : } ;
    
    % Copy RF preference to default variable param
    varpar{ i.( vp ) , 3 } = rfdef.( fn ) ;
    
  end % match RF prefs
  
  % bar total diameter i.e. the length of the bar
  w = varpar{ i.length , 3 } ;
  
  % Angle between neighbours
  a = 2 * pi  /  varpar{ i.fnum , 3 } ;
  
  % Coordinates of bar at positions 1 and 2 , assuming fangle is zero
  x = varpar{ i.fradius , 3 }  *  [  1  ;  cos( a )  ] ;
  y = varpar{ i.fradius , 3 }  *  [  0  ;  sin( a )  ] ;
  
	% Distance between centre of neighbouring bars
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
  
  
end % bar


%%% Stimulus definition handles %%%

% Trial initialisation function
function  S = finit ( vpar , tconst , ~ )
  
  
  %%% Check parameters %%%
  
  % Number of valid steps
  nstep = vpar.number + ( vpar.range < 90 ) ;
  
  % Neither ffirst , flast , fyoke, nor fposition may exceed N
  if  any( vpar.fnum  <  ...
      [ vpar.ffirst , vpar.flast , vpar.fyoke , vpar.fposition ] )
    
    error (  'MET:bar:badparam'  ,  [ 'bar: ' , ...
      'Neither ffirst (%d) , flast (%d) , fyoke (%d) , nor ' , ...
      'fposition (%d) may exceed fnum (%d)' ]  ,  ...
      vpar.ffirst  ,  vpar.flast  ,  vpar.fyoke  ,  vpar.fposition  ,  ...
      vpar.fnum  )
    
  % ffirst must be less than or equal to flast
  elseif  vpar.flast  <  vpar.ffirst
    
    error (  'MET:bar:badparam'  ,  [ 'bar: ' , ...
      'ffirst (%d) must not exceed flast (%d)' ]  ,  vpar.ffirst  ,  ...
      vpar.flast  )
    
  % Number of steps cannot be less than the total number of bars
  elseif  nstep  <  vpar.fnum
    
    error (  'MET:bar:badparam'  ,  [ 'bar: ' , ...
      'fnum (%d) must not exceed total number of steps (%d)' ]  ,  ...
      vpar.fnum  ,  nstep  )
    
  % step has to be less than or equal to number or number + 1 if range = 90
  elseif  nstep  <  vpar.step
    
    error (  'MET:bar:badparam'  ,  [ 'bar: ' , ...
      'stim (%d) must not exceed number of steps (%d)' ] ,  vpar.step , ...
      nstep  )
    
  end % first checks
  
  % Total number of possible permutations given remaining set of
  % orientation steps and the remaining number of bars
  nperm = factorial ( nstep - 1 )  /  factorial ( nstep - vpar.fnum ) ;
  
  % perm has to be a value between 1 and the total number of combinations
  if  nperm  <  vpar.perm
    
    error (  'MET:bar:badparam'  ,  [ 'bar: perm (%d) must not ' , ...
      'exceed number of orientation permutations (%d)' ] ,  vpar.perm , ...
      nperm  )
    
  end % conditional var param check
  
  
  %%% Trial initialisation %%%
  
  % Get a copy of variable parameters for stimulus descriptor
  S.vp = vpar ;
  
  % Number of bars drawn
  S.numbar = S.vp.flast  -  S.vp.ffirst  +  1 ;
  
  % Bar index vector
  S.ibar = S.vp.ffirst : S.vp.flast ;
  
  % Calculate formation circle coordinate
  S = getfc ( S , tconst ) ;
  
  % Calculate centre of each bar position around the formation circle
  % coordinate
  S = barpos ( S , tconst ) ;
  
  % Find the greyscale value for light or dark bars
  S = greyscale ( S ) ;
  
  % Orientation mapping to each bar position
  S.orimap = getorientations ( S , nstep ) ;
  
  % Calculate rotated vertices for each bar
  S.bar = cell (  S.vp.fnum  ,  1  ) ;
  
  % Bars
  for  i = 1 : S.vp.fnum
    
    % Allocate vertex memory
    S.bar{ i } = zeros (  2  ,  4  ) ;
    
    % Calculate un-rotated rectangle positions
    S.bar{ i }( 1 , [ 1 , 4 ] ) = - S.vp.length  /  2 ;
    S.bar{ i }( 1 , [ 2 , 3 ] ) = + S.vp.length  /  2 ;
    S.bar{ i }( 2 , [ 1 , 2 ] ) = - S.vp.width   /  2 ;
    S.bar{ i }( 2 , [ 3 , 4 ] ) = + S.vp.width   /  2 ;
    
    % Rotation matrix
    T = S.orimap( i ) ;
    R = [  cosd( T )  ,  -sind( T ) ;
           sind( T )  ,   cosd( T ) ] ;
         
    % Rotate rectangle
    S.bar{ i }( : ) = R  *  S.bar{ i } ;
    
    % Convert into list of vertices over rows
    S.bar{ i } = tconst.pixperdeg * S.bar{ i }' ;
    
    % Translation into position relative to trial origin
    S.bar{ i } = bsxfun (  @plus  ,  S.bar{ i }  ,  S.barp( i , : )  ) ;
    
  end % bars
  
  
  %-- Hit regions --%
  
  % We will use the 6-column form defining a set of circular regions
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  
  % Allocate hit regions
  S.hitregion = zeros (  S.numbar  ,  6  ) ;
  
  % Initialise hit region radius and disparity
  S.hitregion( : , c6.radius ) = max (  S.vp.hwidmin / 2  ,  ...
    S.vp.length / 2  ) ;
  S.hitregion( : , c6.disp   ) = tconst.origin( 3 ) ;
  S.hitregion( : , c6.dtoler ) = S.vp.hdisptol ;
  
  % Initialise hit region positions
  S = hitregpos ( S , tconst ) ;
  
  % Set whether or not to ignore the stimulus
  S.hitregion( : , c6.ignore ) = S.vp.hitcheck ;
  
  
end % finit


% Stimulation function
function  [ S , hitflg ] = fstim ( S , tconst , tvar )
  
  
  %%% Update the stimulus %%%
  
  % Hit region update not expected by default
  hitflg = false ;
  
  % Only update variable parameters or dot positions if this is the
  % left-eye frame buffer i.e. only do this once per stereo image
  if  tvar.eyebuf  <  1
    
    
    %-- Variable parameter changes --%
    
    % Point to variable parameters and hit-region index map
    vp = tvar.varpar ;
%     c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
    
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
    
    % Contrast change. Find new greyscale value for light or dark bars.
    if  d.contrast  ,  S = greyscale ( S ) ;  end
    
    
  end % update stimulus
  
  
  %%% Draw bars %%%
  
  % Turn off blending , no anti-aliasing I guess
  Screen (  'BlendFunction' ,  tconst.winptr ,  'GL_ONE' ,  'GL_ZERO'  ) ;
  
  % Bars
  for  i = S.ibar
    
    % Draw oriented bar
    Screen (  'FillPoly' ,  tconst.winptr ,  S.grey ,  S.bar{ i } ,  1  ) ;
    
  end % bars
  
  
end % fstim


% Trial closing function
function  Sout = fclose ( ~ , type )
% function  Sout = fclose ( Sin , type )
  
  % React to the requested type of stimulus closure
  switch  type
    
    % Close trial
    case  't'
      
      % Nothing kept between trials
      Sout = [] ;
      
    % Close session
    case  's'
      
      % No resources to release
      % Return empty array
      Sout = [] ;
    
  end % type of closure
  
end % fclose


% Check-sum function
function  c = fchksum ( ~ )
% function  c = fchksum ( Sin )
  
  c = 0 ;
  
end % chksum


%%% Sub-routines %%%


% Compute the formation circle coordinate
function  S = getfc ( S , tconst )

  % Formation circle coordinate from the centre of the screen , in
  % degrees
  S.fcoord( : ) = [ S.vp.fxcoord , S.vp.fycoord ]  +  ...
    tconst.origin( 1 : 2 ) ;

  % Convert unit from degrees to pixels and add the pixel coordinates
  % of the centre of the screen
  S.fcoord( : ) = tconst.pixperdeg * S.fcoord  +  ...
    [ tconst.wincentx , tconst.wincenty ] ;

  % Rmember to convert y-axis coordinate to PTB coordinate system where
  % down is up
  S.fcoord( 2 ) = tconst.winheight  -  S.fcoord( 2 ) ;

end % getfc


% Compute bar pixel coordinates of each bar position's centre.
function  S = barpos ( S , tconst )

  % Number of bar positions
  N = S.vp.fnum ;

  % Formation circle radius , in pixels
  radpix = S.vp.fradius  *  tconst.pixperdeg ;

  % Angle of each bar position , counter-clockwise around the formation
  % circle.
  a = 360 / N  *  ( 0 : N - 1 )  +  S.vp.fangle ;

  % Change bar positions from polar to Cartesian coordinates , in
  % pixels from the formation circle coordinate. The y-coord reflection
  % accounts for the PTB coordinate system.
  S.barp = [  + radpix  *  cosd( a )  ;
              - radpix  *  sind( a )  ]' ;

  % Translate bar positions so that the yoked position is centred in
  % the middle of the formation circle
  if  S.vp.fyoke

    % Patch index
    y = S.vp.fyoke ;

    % Translate positions
    S.barp( : , 1 ) = S.barp ( : , 1 )  -  S.barp ( y , 1 ) ;
    S.barp( : , 2 ) = S.barp ( : , 2 )  -  S.barp ( y , 2 ) ;

  end % formation yoke

  % Re-order bar positions so that first, second, ... Nth bars are
  % placed starting at fposition. Start by making an index vector that
  % will re-order the bar positions ...
  i = mod (  ( 0 : N - 1 ) + S.vp.fposition - 1  ,  N  )  +  1 ;

  % ... then re-order bar positions and add the formation circle coordinate
  S.barp( : ) = S.barp ( i , : )  +  repmat ( S.fcoord , N , 1 ) ;

end % barpos


% Calculates the greyscale value for light and dark to obtain the given
% Michelson contrast. Assumes a mid-grey background. Sets grey
% property.
function  S = greyscale ( S )

  % Greyscale value
  g = ( S.vp.shade - 0.5 ) * S.vp.contrast  +  0.5 ;
  
  % red, green, blue values
  S.grey = [ g , g , g ] ;

end % grey


% Get orientations for remainder of bars
function  O = getorientations (  S  ,  nstep  )
  
  % Orientation step size
  ssize = diff (  [ -S.vp.range , S.vp.range ]  )  /  S.vp.number ;
  
  % Allocate orientation per bar position
  O = zeros (  1  ,  S.vp.fnum  ) ;
  
  % Orientation set
  oriset = ( 0 : nstep - 1 ) * ssize  -  S.vp.range  +  S.vp.orientation ;
  oriset = - oriset ;
  
  % Get index of reserved orientation , for bar position 1
  ires = S.vp.step ;
  
  % Set orientation of bar 1
  O( 1 ) = oriset( ires ) ;
  
  % Get rid of reserved orientation
  oriset( ires ) = [] ;
  
  % Number of remaining orientations
  nori = numel (  oriset  ) ;
  
  % Number of remaining bar positions
  nbar = S.vp.fnum  -  1 ;
  
  % Number of remaining orientations per bar position
  N = nori  :  -1  :  nori - nbar + 1  ;
  
  % Calculate oriset index for each bar position
  I = mod (  S.vp.perm - 1  ,  N  )  +  1 ;
  
  % oriset indices
  for  i = 1 : S.vp.fnum  -  1
    
    % Record orientation for i+1th bar
    O( i + 1 ) = oriset( I( i ) ) ;
    
    % Get rid of assigned orientation from the set
    oriset( I( i ) ) = [] ;
    
  end % oriset indices
  
end % getorientations


% Calculate the position of each hit region, in degrees from the trial
% origin
function  S = hitregpos ( S , tconst )
  
  % Hit region index map
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  
  % x and y coordinate columns in hit region
  xy = [ c6.xcoord , c6.ycoord ] ;
  
  % Indices of presented bars
  i = S.ibar ;
  
  % Get PTB coordinate of bar centres
  S.hitregion( : , xy ) = S.barp( i , : ) ;
  
  % Subtract screen-centre coordinate
  S.hitregion( : , c6.xcoord ) = S.hitregion( : , c6.xcoord )  -  ...
    tconst.wincentx ;
  S.hitregion( : , c6.ycoord ) = S.hitregion( : , c6.ycoord )  -  ...
    tconst.wincenty ;
  
  % Flip from PTB-style y-axis to standard Cartesian
  S.hitregion( : , c6.ycoord ) = -  S.hitregion( : , c6.ycoord ) ;
  
  % Convert unit to degrees
  S.hitregion( : , xy ) = S.hitregion( : , xy )  ./  tconst.pixperdeg ;
  
end % hitregpos

