
% 
% This class provides a data structure for the rds_motion MET PTB
% stimulus. As a sub-class of the handle class, it maintains the same
% location in memory when it is modified within a function. In other words,
% there is no copy-on-write behaviour.
% 
% Written by Jackson Smith - April 2018 - DPAG , University of Oxford
% 

classdef  rds_motion_handle  <  handle
  
  
  %%% List all properties accessed in rds_motion %%%
  
  properties
    
    % Integer type used for index vectors , we can have intmax( itype )
    % dots PER RDS.
    itype = 'uint16' ;
    
    % Variable parameters that remain constant during a trial i.e. may not
    % change dynamically
    vpconst = { 'fnumrds' , 'ffirst' , 'flast' , 'centre_width' , ...
      'surround_width' , 'dot_type' , 'dot_width' , 'dot_density' , ...
      'secs_rnd' , 'orientation' , 'speed' } ;
    
    % Buffer index for left and right eye
    left = 1 ;
    right = 2 ;
    
    % Contains a struct of variable parameter values used on current trial
    vp
    
    % Formation circle PTB coordinate [ x , y ]
    fcoord = [ 0 , 0 ] ;
    
    % The PTB coordinate for the centre of each RDS position. Columns are
    % indexed by x and y coordinate. Rows are indexed by RDS position.
    % The order of positions starts with that specified by the fposition
    % variable parameter.
    rdsp
    
    % Number of RDS between ffirst and fflast
    numrds = 0 ;
    
    % Greyscale values for [ light , dark ] dots
    grey = [ 0 , 0 ] ;
    glight = 1 ;
    gdark  = 2 ;
    
    % Maximum and minimum width of dots in degrees of visual field
    dotmin = 0 ;
    dotmax = 0 ;
    
    % Dot width in pixels
    dotwid = 0 ;
    
    % Dot type code for Screen DrawDots
    dottyp = 0 ;
    
    % Central radius , surround inner radius , RDS radius in pixels ,
    % difference in inner surround and RDS radii , most pre-squared. Inner
    % radius of surround will be from the point where monocular centres
    % overlap.
    rcen  = 0 ;
    rcen2 = 0 ;
    rsin2 = 0 ; % dynamic
    rrds2 = 0 ;
    rdif2 = 0 ; % dynamic
    
    % Area of one dot , RDS , centre , and surround. Area of surround is
    % computed from inner to outer surround radius.
    adot = 0 ;
    ards = 0 ;
    acen = 0 ;
    asur = 0 ; % dynamic
    
    % Number of dots in one RDS image , in centre , in surround , in dot
    % buffer (see ibuf below)
    nrds = 0 ;
    ncen = 0 ;
    nsur = 0 ; % dynamic
    nbuf = 0 ;
    
    % The absolute disparity of central and surround dots. NOTE!
    % Disparities are half of a horizontal shift ; but there are two
    % shifts, one for each eye ; hence a full disparity is obtained in the
    % image. These are dynamic.
    dcen = 0 ;
    
    % Counter-clockwise rotation matrix. Applied to freshly sampled central
    % dots after their distance to the leading edge of the central aperture
    % is known.
    ccwrot = [ 0 , 0 ; 0 , 0 ] ;
    
    % Motion step size in pixels per frame
    step = 0 ;
    
    % Motion vector with length of step
    mvec = [ 0 , 0 ] ;
    
    % Index vectors. These are for accessing subsets of dots. They're not
    % buffers as they'll be replaced completely each time they are updated.
    % But they can be re-used frame after frame without need to re-create
    % them each time, unless there is a dynamic stimulus change. icen and
    % iuacen are constant in each trial ; the rest are dynamic.
    
      % icen and isur fetch central or surround dots. When dots are sampled
      % to create a new image, the dot buffer initially holds central and
      % surround dots in blocks that come one after another [ central ,
      % surround ]. Then these are shuffled.
      icen
      isur
      
      % idot refers to all used dots , avoiding dead tail in the buffers. 
      idot
      
      % The last position in the dot buffer that is used ; nbuf - ibuf
      % positions are still free.
      ibuf
      
      % The stimulus index , will always be h.vp.ffirst : h.vp.flast
      irds
    
    % Dot buffers , these hold blocks of memory that are not resized at any
    % time during a trial
    
      % Coordinates. Rows ordered by [ x , y ] axis coordinate , columns by
      % dot , layers by RDS.
      xy
      
      % Distance of central dots to edge of central RDS region. One row,
      % columns indexed by dots, layers by RDS.
      cdist
      
      % Visibility table. Rows ordered by [ left , right ] monocular
      % image , columns by dot , and layers by RDS.
      v
      
      % Randomness buffer. Random values will be sampled during
      % initialisation then scaled during stimulation. Values are simply
      % recycled if they are all used up before a trial is complete. Size
      % matches xy. The fourth dimension is indexed over frames. Since row
      % two will always provide polar coordinate dot angles, these can be
      % pre-computed and stored in r. ir is the index of the last used
      % frame. nr is the number of frames of values available.
      r
      ir = 0 ;
      nr = 0 ;
      
    % Dynamic dot buffers change size during a trial
      
      % Screen DrawDots input buffers for dot locations and colour lookup
      % table. These are loaded prior to calling
      % Screen ( 'DrawDots' , ... ). ddxy is 2 x nbuf. ddcl is 4 x nbuf.
      ddxy
      ddcl
      
    % Hit region array
    hitregion
    
  end % properties
  
  
end % rds_motion_handle

