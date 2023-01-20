
function  [ type , vpar , init , stim , close , chksum ] = calibgrid ( ~ )
% 
% [ type , vpar , init , stim , close , chksum ] = calibgrid ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Generates a calibration grid on screen with lines spaced by a set number
% of degrees of visual angle. Lines are spaced from a central pair that
% cross in the middle of the screen. A central fixation point is optional,
% as is a set of dots placed in the middle of each square ; the latter may
% have disparity added to it.
% 
% Variable parameters - can change value between or during trials:
% 
%   spacing - The grid spacing, in degrees of visual field. Default 5.
%   
%   linewid - Width of the line, in degrees of visual field. Default 0.05.
% 
%   linecol - Normalised greyscale value of the grid lines, where 0 is
%     black and 1 is white. Default 1.
%   
%   fixwid - Fixation point width, in degrees of visual field. Default 0.5.
%   
%   fixcol - Normalised greyscale value of the fixation point, where 0 is
%     black and 1 is white. Default 1.
%   
%   dots - If non-zero then dots are drawn in the centre of each square.
%   
%   dotwid - Width of dots placed at the centre of squares, in degrees of
%     visual field. Default 0.1.
%   
%   dotcol - Normalised greyscale value of the dots placed at the centre of
%     squares, where 0 is black and 1 is white. Default 1.
%   
%   If PsychToolbox is running in a stereoscopic mode , then the following
%   parameters apply. They are used to define a set of disparities that are
%   randomly assigned to each dot in the middle of a square. Together, they
%   are analogous to the Matlab colon operator
%   i.e. dismin : disstep : dismax
%   
%   dismin - The minimum disparity to apply to dots at the centre of
%    squares. Default -0.2.
%   
%   dismax - The maximum disparity to apply to dots at the centre of
%    squares. Default 0.2.
%   
%   disstep - The set of disparities applied to dots at the centre of
%     squares are all d = i * disstep + dismin where i is an integer of 0
%     or more such that dismin <= d <= dismax. Default 0.2.
%   
% NOTE: The trial initialiser checks that dismin <= dismax and that 0 is
%   less than spacing.
%   
%   If the width of either the lines or dots is too small for the hardware
%   to support then the smallest allowable width will be used, likewise if
%   the width is to big.
%   
%   If linewid, fixwid, or dotwid are zero then the associated feature is
%   not drawn. If disstep is zero then no disparities are applied.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set. Each row defines one variable parameter by
  % providing, in this order, the variable name, the numerical domain ('f'
  % for floating point or 'i' for integer), the default value, the minimum
  % value, the maximum value. The calling program must check that variable
  % parameters are in the specified range. It is up to the trial
  % initialiser function, however, to do further checks of correctness.
  vpar = {  'spacing'  ,  'f'  ,  5.00  ,  0    , +Inf  ;
            'linewid'  ,  'f'  ,  0.05  ,  0    , +Inf  ;
            'linecol'  ,  'f'  ,  1.00  ,  0    ,    1  ;
             'fixwid'  ,  'f'  ,  0.50  ,  0    , +Inf  ;
             'fixcol'  ,  'f'  ,  1.00  ,  0    ,    1  ;
               'dots'  ,  'i'  ,  0     ,  0    ,    1  ;
             'dotwid'  ,  'f'  ,  0.10  ,  0    , +Inf  ;
             'dotcol'  ,  'f'  ,  1.00  ,  0    ,    1  ;
             'dismin'  ,  'f'  , -0.20  , -Inf  , +Inf  ;
             'dismax'  ,  'f'  , +0.20  , -Inf  , +Inf  ;
            'disstep'  ,  'f'  ,  0.20  ,  0    , +Inf  }  ;
            
  % Function handles
	 init = @finit ;   % Trial initialiser
   stim = @fstim ;   % Stimulation
  close = @fclose ;  % Stimulus destructor
 chksum = @fchksum ; % Check sum
  
end % calibgrid


%%% Stimulus definition handles %%%

% Trial initialisation function. The calling program passes the value of
% each variable parameter in struct vpar. It also passes a set of constants
% in tconst with information about the running environment, including the
% screen dimensions and the number of pixels per degree. The initialisation
% function must return a stimulus descriptor, a scalar struct defining one
% instance of this class of stimulus.
function  S = finit ( vpar , tconst , ~ )
  
  
  %%% Variable parameter correctness checks %%%
  
  % We cannot allow spacing to be zero or for dismax to be less than
  % dismin.
  if  ~ vpar.spacing
    
    error ( 'MET:calibgrid:badparam' , [ 'calibgrid: ' , ...
      'spacing can not be zero' ] )
    
  elseif  vpar.dismax  <  vpar.dismin
    
    error ( 'MET:calibgrid:badparam' , [ 'calibgrid: ' , ...
      'dismax (%f) must not be less than dismin (%f)' ] , ...
      vpar.dismin , vpar.dismax )
    
  end
  
  
  %%% Build stimulus descriptor %%%
  
  % Start by holding a copy of the parameter values
  S.vp = vpar ;
  
  % Get minimum and maximum width of lines and dots. Here, we see that the
  % PsychToolbox window pointer is provided as a constant in tconst.
  [ S.minlin , S.maxlin ] = Screen ( 'DrawLines' , tconst.winptr ) ;
  [ S.mindot , S.maxdot ] = Screen ( 'DrawDots'  , tconst.winptr ) ;
  
  % We now need to determine spacing, line width, and dot width in pixels.
  % tconst provides an estimate of the conversion factor in pixperdeg.
  S.spacing = S.vp.spacing  *  tconst.pixperdeg ;
  S.linewid = S.vp.linewid  *  tconst.pixperdeg ;
  S.fixwid  = S.vp.fixwid   *  tconst.pixperdeg ;
  S.dotwid  = S.vp.dotwid   *  tconst.pixperdeg ;
  
  % Cap width to the minimum or maximum value that is supported by the
  % hardware
  F = { 'linewid' , 'fixwid' , 'dotwid' ;
         'minlin' , 'mindot' , 'mindot' ;
         'maxlin' , 'maxdot' , 'maxdot' } ;
	
  for  i = 1 : size ( F , 2 )
    
    % Value is too small
    if  S.( F{ 1 , i } )  <  S.( F{ 2 , i } )
      
      % Cap to minimum
      S.( F{ 1 , i } )  =  S.( F{ 2 , i } ) ;
      
    % Value is too big
    elseif  S.( F{ 3 , i } )  <  S.( F{ 1 , i } )
      
      % Cap to maximum
      S.( F{ 1 , i } )  =  S.( F{ 3 , i } ) ;
      
    end
    
  end % cap widths
  
  % Number of grid lines when central lines cross in the middle of the
  % screen , column order is number of lines crossed in each direction
  % [ x-axis , y-axis ]. tconst fields .wincentx and .wincenty give
  % coordinates of the centre of the screen.
  S.Ng = [ tconst.wincentx , tconst.wincenty ]  /  S.spacing  ;
  S.Ng = floor ( S.Ng )  +  1 ;
  S.Ng = 2 * S.Ng  -  1 ;
  
  % The number of lines on one side of the centre of the screen
  S.hNg = floor (  S.Ng  /  2  ) ;
  
  % Generate the set of line end points , if the width is non-zero
  if  S.vp.linewid
    
    S.linexy = linexy ( S , tconst ) ;
    
  end % line end points
  
  % Generate the set of dots placed in the centre of the squares in the
  % grid , if size is non-zero
  if  S.vp.dotwid
    
    S.dotxy = dotxy ( S , tconst ) ;
    
  end % dot positions
  
  % If dot width and disparity spacing are non-zero and we are in a
  % stereoscopic mode then calculate the set of dot disparities and map
  % them onto each dot.
  if  tconst.stereo  &&  S.vp.dotwid  &&  S.vp.disstep
    
    % Make disparity set
    S.disp = mkdisp ( S , tconst ) ;
    
    % Apply to dots. Initialise such that dots are as they would appear to
    % the right eye. This is because we want to flip to the left eye image
    % on the first invocation of the stimulation function. That function
    % first applies a full disparity shift, and then reverses the polarity
    % of the disparities, in preparation for generating the next eye's
    % image.
    S.dotxy( 1 , : ) = S.dotxy( 1 , : )  +  S.disp / 2 ;
    
    % Thus, reverse polarity of disp, so that we can get the left-eye image
    S.disp = - S.disp ;
    
  end % dot disparities
  
  
  %%% Hit-regions %%%
  
  % Normaly, we need to define hit regions for a stimulus e.g. for a
  % fixation point. This is so that the rest of MET can compare the
  % stimulus location to the eye or touch position of the subject. It might
  % be thought of as a way of saying what area of the screen contains the
  % stimulus. As the grid fills the screen, we return a rectangle that also
  % does so. The format of the .hitregion field can be either 6 or 8
  % columns, where each row defines a region that is circular (6 col) or
  % rectangular (8 col). tconst contains a copy of the MET controller
  % constants, one of which is the column mapping for hit regions. Hit
  % regions are in degrees of visual field using standard Cartesian
  % coordinates centred in the middle of the screen.
  c8 = tconst.MCC.SDEF.ptb.hitregion.eightcol ;
  S.hitregion = zeros ( 1 , 7 ) ;
  S.hitregion( c8.xcoord ) = 0 ;
  S.hitregion( c8.ycoord ) = 0 ;
  S.hitregion( c8.width  ) = tconst.winwidth ;
  S.hitregion( c8.height ) = tconst.winheight ;
  S.hitregion( c8.rotation ) = 0 ;
  S.hitregion( c8.disp ) = 0 ;
  S.hitregion( c8.dtoler ) = 0 ;
  S.hitregion = S.hitregion  /  tconst.pixperdeg ;
  
  % We will ignore this stimulus
  S.hitregion( c8.ignore ) = 0 ;
  
end % finit


% Stimulation function. Receives last-frame's stimulus descriptor. An
% updated copy is returned. In addition to the set of environmental
% constants in tconst, we also get information about the upcoming frame in
% tvar, including it's number, its estimated time, and whether it is the
% left or right eye's frame buffer. In stereoscopic mode, we must run fstim
% twice per frame, once for each eye. By convention, we always draw to the
% left eye's image first. Thus, it only makes sense to apply variable
% parameter changes before drawing to the left eye.
function  [ S , h ] = fstim ( S , tconst , tvar )
  
  
  %%% Apply variable parameter changes %%%
  
  % Part of defining a task may include associating states of the task
  % logic with dynamic changes to the stimulus parameters, called stimulus
  % events. A stimulus event is triggered once, upon transitioning to a new
  % state of the task, and results in tvar.varpar being loaded with
  % variable name/value pairs in an N by 2 cell array. Each row tells the
  % stimulation function what parameter to change (col 1) and what value to
  % change it to (col 2). There may be cases when it does not make sense to
  % allow such a change, in which case this may be silently ignored.
  % Otherwise, it is in keeping with MET's specification that a stimulation
  % function should be able to handle as many dynamic parameter changes as
  % possible.
  
  % Assume no change to hit-region. If changing a variable parameter causes
  % the stimulus to change size or location, then the hit region must also
  % be updated and a flag (h) must be raised to tell the calling program
  % that the hit region has changed. In a full MET session, the calling
  % program may then write the new hit regions to some dedicated shared
  % memory for other programs e.g. targeting or real-time eye position
  % displays. For a calibration grid, the hit region will never change.
  h = false ;
  
  % Only apply changes when about to draw the left eye's image , or if in
  % monocular mode. tvar.eyebuf will be 0 if drawing to left, or -1 if
  % monocular. Remember, we always draw to the left-eye frame buffer first,
  % when in stereo mode.
  if  ~ isempty ( tvar.varpar )  &&  tvar.eyebuf  <  1
    
    % Point to variable parameter change list , for convenience
    vp = tvar.varpar ;
    
    % Make a struct that tracks which parameters were changed , d for delta
    F = fieldnames( S.vp )' ;
    F = [  F  ;  num2cell(  false( size( F ) )  )  ] ;
    d = struct (  F { : }  ) ;
    
    % Step through the list of changes
    for  i = 1 : size ( vp , 1 )
      
      % Save new parameter value
      S.vp.( vp{ i , 1 } ) = vp{ i , 2 } ;
      
      % Mark parameter as changed
      d.( vp{ i , 1 } ) = true ;
      
    end % new values
    
    % Respond to a change in grid spacing
    if  d.spacing
      
      % Unit conversion of new value from degrees to pixels
      S.spacing = S.vp.spacing  *  tconst.pixperdeg ;
      
      % Recompute number of lines
      S.Ng = [ tconst.wincentx , tconst.wincenty ]  /  S.spacing  ;
      S.Ng = floor ( S.Ng )  +  1 ;
      S.Ng = 2 * S.Ng  -  1 ;
      S.hNg = floor (  S.Ng  /  2  ) ;
      
      % Define new line vertices
      if  S.vp.linewid  ,  S.linexy = linexy ( S , tconst ) ;  end
      
      % Define new dot positions , note that it will now be necessary to
      % re-map disparities to dots
      if  S.vp.dotwid  ,  S.dotxy = dotxy ( S , tconst ) ;  end
      
    end % spacing
    
    % New dot disparities needed , but only compute if dot width and the
    % disparity step are non-zero , and if we're in a stereoscopic mode
    if  any ( [ d.spacing , d.dismin , d.dismax , d.disstep ] )  &&  ...
        S.vp.dotwid  &&  S.vp.disstep  &&  tconst.stereo
      
      % Make sure that dismin does not exceed dismax
      if  S.vp.dismax  <  S.vp.dismin
        S.vp.dismax = S.vp.dismin ;
      end
      
      % Make disparity set
      S.disp = mkdisp ( S , tconst ) ;
    
      % Apply to dots.
      S.dotxy( 1 , : ) = S.dotxy( 1 , : )  +  S.disp / 2 ;
    
      % Reverse polarity of disp in prep. to make left-eye image
      S.disp = - S.disp ;
      
    end % disparities
    
    % Line width changed to non-zero value. Not using a loop, here, because
    % they generally add a time overhead.
    if  d.linewid  &&  S.vp.linewid
      
      % Unit conversion to pixels
      S.linewid = S.vp.linewid  *  tconst.pixperdeg ;
      
      % Cap range
      if      S.linewid  <  S.minlin   ,  S.linewid = S.minlin ;
      elseif  S.maxlin   <  S.linewid  ,  S.linewid = S.maxlin ;
      end
      
    end % line width change
    
    % Fixation point width change to non-zero value
    if  d.fixwid  &&  S.vp.fixwid
      
      % Unit conversion to pixels
      S.fixwid = S.vp.fixwid  *  tconst.pixperdeg ;
      
      % Cap range
      if      S.fixwid  <  S.mindot  ,  S.fixwid = S.mindot ;
      elseif  S.maxdot  <  S.fixwid  ,  S.fixwid = S.maxdot ;
      end
      
    end % fixation point width change
    
    % Dot width change to non-zero value
    if  d.dotwid  &&  S.vp.dotwid
      
      % Unit conversion to pixels
      S.dotwid = S.vp.dotwid  *  tconst.pixperdeg ;
      
      % Cap range
      if      S.dotwid  <  S.mindot  ,  S.dotwid = S.mindot ;
      elseif  S.maxdot  <  S.dotwid  ,  S.dotwid = S.maxdot ;
      end
      
    end % fixation point width change
    
  end % var par change
  
  
  %%% Update stimulus descriptor %%%
  
  % Apply disparity shift to dots if we are in a stereoscopic mode and dot
  % size is non-zero
  if  tconst.stereo  &&  S.vp.dotwid
    
    % Disparity shift
    S.dotxy( 1 , : ) = S.dotxy( 1 , : )  +  S.disp ;
    
    % Invert sign of disparity for next eye's image
    S.disp = - S.disp ;
    
  end % disp
  
  
  %%% Drawing commands %%%
  
  % Anti-aliasing blend function
  Screen ( 'BlendFunction' , tconst.winptr , ...
      'GL_SRC_ALPHA' , 'GL_ONE_MINUS_SRC_ALPHA' ) ;
  
  % Draw grid , if width non-zero
  if  S.vp.linewid
    
    Screen ( 'DrawLines' , tconst.winptr , S.linexy , S.linewid , ...
      S.vp.linecol , [] , 2 ) ;
    
  end
  
  % Draw fixation point , if width non-zero
  if  S.vp.fixwid
    
    Screen ( 'DrawDots' , tconst.winptr , ...
      [ tconst.wincentx ; tconst.wincenty ] , S.fixwid , S.vp.fixcol , ...
      [] , 2 ) ;
    
  end
  
  % Draw dots if they have width and the dot flag is up
  if  S.vp.dotwid  &&  S.vp.dots
    
    Screen ( 'DrawDots' , tconst.winptr , S.dotxy , S.dotwid , ...
      S.vp.dotcol , [] , 2 ) ;
    
  end
  
end % fstim


% Trial closing function. Does nothing because there are no special
% resources to release, in this case. However, if the stimulus had required
% PsychToolbox to store, say, some texture information (as a gabor stimulus
% might) then this is where we would delete that from memory. This is very
% important, otherwise we start a memory leak that can eventually bring
% down the system. The second input argument exists to tell the function if
% the trial or session is closing. It may be that certain resources can be
% retained from trial to trial, but should always be released at the end of
% a session.
function  S = fclose ( ~ , ~ )
  
  S = [] ;
  
end % close


% Check-sum function. Not needed for this stimulus. The purpose is to
% verify reconstructions of the same stimulus at a later time. For example,
% a random dot patch may sum all dot positions to provide the check-sum. At
% a later time, the same random number generator seed is loaded, and the
% stimulus regenerated using the same function. If the check sum is the
% same as the one generated during the experiment, then the chances are
% high that we have reconstructed the same stimulus. There is no guarantee,
% though, because there will be an infinite set of numbers that could
% produce the same checksum. In practice, though, this is unlikely.
function  c = fchksum ( ~ )
  
  c = 0 ;
  
end % chksum


%%% Sub-routines %%%

% In order to allow variable parameter changes during a trial, it is useful
% to have a set of sub-functions that can be used by both the trial
% initialiser and stimulation functions.

% Function returns the end-points for all grid lines. Data is arranged
% according to the requirements of Screen ( 'DrawLines' ). Note that tconst
% contains the screen pixel resolution in fields .winwidth and .winheight.
function  xy = linexy ( S , tconst )
  
  % The x-axis coordinates of vertical lines , those crossed by the x-axis
  vx = (  -S.hNg( 1 )  :  +S.hNg( 1 )  )  *  S.spacing ;
  vx = vx  +  tconst.wincentx  ; %+  0.5 ;
  
  % The y-axis coordinate of horizontal lines , those crossed by the y-axis
  hy = (  -S.hNg( 2 )  :  +S.hNg( 2 )  )  *  S.spacing ;
  hy = hy  +  tconst.wincenty  ; %+  0.5 ;
  
  % Repeat each coordinate , according to the requirements of Screen
  % 'DrawDots'
  vx = reshape (  [ vx ; vx ]  ,  1  ,  2 * S.Ng ( 1 )  ) ;
  hy = reshape (  [ hy ; hy ]  ,  1  ,  2 * S.Ng ( 2 )  ) ;
  
  % The y-axis coordinates of vertical lines
  vy = repmat (  [ 0 , tconst.winheight ]  ,  1  ,  S.Ng ( 1 )  ) ;
  
  % The x-axis coordinates of horizontal lines
  hx = repmat (  [ 0 , tconst.winwidth  ]  ,  1  ,  S.Ng ( 2 )  ) ;
  
  % Build line matrix for Screen 'DrawDots'
  xy = [  vx  ,  hx  ;
          vy  ,  hy  ] ;
  
end % linexy


% Returns location of dots on screen
function  xy = dotxy ( S , tconst )
  
  % The x-coordinate of dots
  x = (  -S.hNg( 1 )  :  +S.hNg( 1 ) + 1  )  *  S.spacing ;
  x = x  -  S.spacing / 2  +  tconst.wincentx ;
  
  % The y-coordinate of dots
  y = (  -S.hNg( 2 )  :  +S.hNg( 2 ) + 1  )  *  S.spacing ;
  y = y  -  S.spacing / 2  +  tconst.wincenty ;
  
  % Get grid of dots
  [ x , y ] = meshgrid ( x , y ) ;
  
  % Arrange for input to Screen 'DrawDots'
  xy = [ x( : ) , y( : ) ]' ;
  
end % dotxy


% Make disparity set for each dot
function  d = mkdisp ( S , tconst )
  
  % Disparity set , in degrees
  d = S.vp.dismin  :  S.vp.disstep  :  S.vp.dismax ;

  % Convert to pixels
  d = d  *  tconst.pixperdeg ;

  % Randomly map to dots
  i = mod( 0 : size( S.dotxy , 2 ) - 1  ,  numel( d ) )  +  1 ;
  i = i ( randperm(  numel ( i )  ) ) ;
  
  % Return disparity set
  d = d ( i ) ;
  
end % mkdisp

