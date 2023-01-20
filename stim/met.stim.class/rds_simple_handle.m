
% 
% This class provides a data structure for the rds_simple MET PTB
% stimulus. As a sub-class of the handle class, it maintains the same
% location in memory when it is modified within a function. In other words,
% there is no copy-on-write behaviour.
% 
% Written by Jackson Smith - October 2017 - DPAG , University of Oxford
% 

classdef  rds_simple_handle  <  handle
  
  
  %%% List all properties accessed in rds_simple %%%
  
  properties
    
    % Integer type used for index vectors , we can have intmax( itype )
    % dots PER RDS.
    itype = 'uint16' ;
    
    % Variable parameters that remain constant during a trial i.e. may not
    % change dynamically
    vpconst = { 'fnumrds' , 'ffirst' , 'flast' , 'centre_width' , ...
      'surround_width' , 'dot_type' , 'dot_width' , 'dot_density' , ...
      'secs_rnd' } ;
    
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
    
    % The number of frames presented per RDS image
    frames = 0 ;
    
    % Image timer , in frames. With this we will count how many frames have
    % been drawn. This allows us to accomodate dynamic changes to the draw
    % rate during a trial.
    timer = 0 ;
    
    % Maximum and minimum width of dots in degrees of visual field
    dotmin = 0 ;
    dotmax = 0 ;
    
    % Dot width in pixels
    dotwid = 0 ;
    
    % Dot type code for Screen DrawDots
    dottyp = 0 ;
    
    % Central radius , surround inner radius , RDS radius in pixels ,
    % difference in inner surround and RDS radii , all squared. Inner
    % radius of surround will be from the point where monocular centres
    % overlap.
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
    dsur = 0 ;
    
    % The disparity of central dots relative to surround dots. Half shift.
    drel = 0 ;
    
    % The range of disparity noise in central or surround dots. Halved to
    % get monocular shift in each eye.
    dncen = 0 ;
    dnsur = 0 ;
    
    % The number of dots that are un/anti-correlated
    ccen = 0 ;
    csur = 0 ;
    
    % Flags indicate whether central or surround dots are uncorrelated
    ucen = 0 ;
    usur = 0 ;
    
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
      
      % icorr fetch all binocularly correlated dots , including
      % anti-correlated. Excludes only uncorrelated dots.
      icorr
      
      % Subdivisions of icorr into central and surround dots
      icorc
      icors

      % iuacen and iuasur fetch un/anti-correlated central or surround
      % dots.
      iuacen
      iuasur
      
      % idot refers to all used dots , avoiding dead tail in the buffers. 
      idot
      
      % The last position in the dot buffer that is used ; nbuf - ibuf
      % positions are still free.
      ibuf
      
      % Random permutation index vector
      irpm
      
      % The stimulus index , will always be h.vp.ffirst : h.vp.flast
      irds
    
    % Dot buffers , these hold blocks of memory that are not resized at any
    % time during a trial
    
      % Coordinates. Rows ordered by [ x , y ] axis coordinate , columns by
      % dot , layers by RDS , and cubes by eye.
      xy
      
      % Anti-correlated greyscale value of each dot , indexed over dots
      acg
      
      % Colour lookup table buffer. Rows ordered by [ r , g , b ] without
      % alpha channel ,  columns by dot , and layers by eye
      % [ left , right ]. 
      clut
      
      % Visibility table. Rows ordered by [ left , right ] monocular
      % image , columns by dot , and layers by RDS.
      v
      
      % The disparity noise buffer. Columns indexed by dot , layers by RDS.
      % There are two rows. Row 1 contains a sample of random numbers from
      % the uniform distribution with support [ -1 , +1 ]. Row 2 contains
      % the values in row 1 scaled to the number of pixels required for a
      % monocular horizontal shift. In other words, row 2 contains the
      % disparity shift that is subtracted from a dot's left image, and
      % added to its right for a full stereoscopic disparity.
      n
      
      % Disparity noise weight. Used to taper disparity noise towards zero
      % as a dot approaches the edge of a circular or annular region. Row 1
      % is the weight for the outer edge, row 2 for the inner edge. Columns
      % are indexed by dot and layers by RDS.
      wn
      
      % Logical vector identifies anti-correlated dots
      acor
      
      % Randomness buffer. Random values will be sampled during
      % initialisation then scaled during stimulation. Values are simply
      % recycled if they are all used up before a trial is complete. Enough
      % space for uncorrelated dots in all RDS over a specified amount of
      % time. Size matches xy in the first four dimensions. The fifth
      % dimension is indexed over frames. Since row two will always provide
      % polar coordinate dot angles, these can be pre-computed and stored
      % in r. ir is the index of the last used frame. nr is the number of
      % frames of values available.
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
  
  
end % rds_simple_handle

