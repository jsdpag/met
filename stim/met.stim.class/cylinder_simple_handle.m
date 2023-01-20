
% 
% This class provides a data structure for the cylinder_simple MET PTB
% stimulus. As a sub-class of the handle class, it maintains the same
% location in memory when it is modified within a function. In other words,
% there is no copy-on-write behaviour.
% 
% Written by Jackson Smith - March 2018 - DPAG , University of Oxford
% 

classdef  cylinder_simple_handle  <  handle
  
  
  %%% List all properties accessed in rds_simple %%%
  
  properties
    
    % Variable parameters that remain constant during a trial i.e. may not
    % change dynamically
    vpconst = { 'fnumrds' , 'ffirst' , 'flast' , 'width' , 'dot_width' ,...
      'dot_density' , 'dot_avglife' , 'secs_rnd' } ;
    
    % Contains a struct of variable parameter values used on current trial
    vp
    
    % Formation circle PTB coordinate [ x , y ]
    fcoord = [ 0 , 0 ] ;
    
    % The PTB coordinate for the centre of each cylinder position. Columns
    % are indexed by x and y coordinate. Rows are indexed by cylinder
    % position. The order of positions starts with that specified by the
    % fposition variable parameter.
    cylp
    
    % Number of cylinders between ffirst and fflast
    numcyl = 0 ;
    
    % Greyscale values for [ light , dark ] dots
    grey = [ 0 , 0 ] ;
    glight = 1 ;
    gdark  = 2 ;
    
    % Maximum and minimum width of dots in degrees of visual field
    dotmin = 0 ;
    dotmax = 0 ;
    
    % Dot width in pixels
    dotwid
    
    % Area of a dot in pixels-squared
    adot
    
    % Width of cylinder in pixels
    width

    % Half width
    hwidth
    
    % Dot mask , in radians
    dmsk
    
    % Rotation matrix turns dots around the centre of cylinder to achieve
    % desired cylinder orientation
    romat = [ 0 , 0 ; 0 , 0 ] ;

    % Radians per frame that each dot moves around the axis of rotation.
    % This is the right amount to get the desired maximum speed.
    step

    % Cylinder disparity in pixels , full horizontal shift of a point from
    % its position in one monocular image to another
    disp

    % Area of cylinder rectangle i.e. area of the 2D projection of the
    % cylinder onto the fixation plane
    arec
    
    % Number of dots in a single cylinder
    ndot
    
    % Dot buffers , these hold blocks of memory that are not resized at any
    % time during a trial
      
      % Cylinder index vector. Lists which cylinders are drawn.
      icyl
    
      % Remaining dot lifetimes , in frames
      life
    
      % Dot positions around the axis of rotation , in radians. This is
      % used to compute the x-axis location of each dot in a 2D projection
      % of the cylinder in a coordinate space centred and aligned to the
      % cylinder.
      xrad

      % Dot position along the axis of rotation from an origin in the
      % centre of the cylinder , in pixels
      ypix
      
      % Disparity of each dot
      ddisp
      
      % Dot visibility. This is really the alpha value. 0 means invisible,
      % 1 means opaque.
      vis
    
      % Coordinates. Rows ordered by [ x , y ] axis coordinate , columns by
      % dot , layers by cylinder.
      xy
      
      % Double precision buffer of dot positions
      dxy
      
      % Colour lookup table buffer. Rows ordered by [ r , g , b , a ] with
      % alpha channel in bottom row,  columns by dot.
      clut
      
      % Randomness buffer. Stores randomly sampled values obtained during
      % initialisation. These are then available for use during the trial.
      % It is a circular buffer , so values will be recycled if the
      % stimulus is presented for long enough.
      r
      
        % Index of the last value used from randomness buffer. Increment
        % from one past this index to get the next set of random values.
        ri
        
        % The total number of values in the randomness buffer
        rn
    
    % Hit region array
    hitregion
    
  end % properties
  
  
end % cylinder_simple_handle

