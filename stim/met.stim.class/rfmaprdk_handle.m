
% 
% This class provides a data structure for the rfmaprdk MET PTB
% stimulus. As a sub-class of the handle class, it maintains the same
% location in memory when it is modified within a function. In other words,
% there is no copy-on-write behaviour.
% 
% Written by Jackson Smith - November 2017 - DPAG , University of Oxford
% 

classdef  rfmaprdk_handle  <  handle
  
  
  %%% List all properties accessed in rfmaprdk %%%
  
  properties
    
    
    %%% Constants %%%
  
    % The set of variable parameters to check
    C_VPAR = { 'maxwidth' , 'dot_width' , 'dot_density' , ...
      'init_width' , 'init_speed' , 'init_orientation' } ;
    
    % Mouse button indices , and minimum duration from right-clicking
    % stimulus on until it can be turned off.
    C_LEFT = 1 ;
    C_MIDDLE = 2 ;
    C_RIGHT = 3 ;

    % Modifier keys
    C_SHIFT = [ KbName( 'LeftShift' ) , KbName( 'RightShift' ) ] ;
    C_CTRL = [ KbName( 'LeftControl' ) , KbName( 'RightControl' ) ] ;
    C_SPACE = KbName( 'space' ) ;

    % Rates of change, in degrees per click
    C_dORIENT = 5.0 ;
    C_dWIDTH  = 0.2 ;
    C_dSPEED  = 0.5 ;

    % Minimum duration between readouts
    C_MINDUR = 0.1 ;
    
    % Circular hit region column indeces
    C_C6
    
    
    %%% Variables %%%
    
    % Variable parameter set
    vp
    
    % Centre of rdk , taken from mouse position
    crdk = [ 0 , 0 ] ;
    
    % Minimum and maximum dot width in pixels
    dotmin = 0 ;
    dotmax = 0 ;
    
    % Width of a dot in pixels
    dotwid = 0 ;
    
    % Area of a dot in pixels-squared. Area of circle.
    adot = 0 ;
    
    % Area of rdk patch in pixels-squared , and maximum area. We calculate
    % area of a square for this.
    ardk = 0 ;
    ardkmax = 0 ;
    
    % Radius of rdk in pixels
    rrdk = 0 ;
    
    % Number of dots visible in rdk , and maximum number
    ndot = 0 ;
    ndotmax = 0 ;
    
    % Rotation matrix
    mrot = zeros ( 2 ) ;
    
    % Linear index vector of used positions in dot buffer
    idot
    
    % Last times that click was detected or that spacebar was pressed
    t = 0 ;
    tclick = 0 ;
    tspace = 0 ;
    
    % Visibility flag
    v = true ;
    
    % Horizontal and vertical mirroring flags based on the hmirror and
    % vmirror parameters in metscrnpar.csv
    hmirror = -1 ;
    vmirror = -1 ;
    
    % RDK dynamic parameters in degrees of visual field. Orient. is in
    % plain degrees. Speed in degrees per second.
    xcenter = 0 ;
    ycenter = 0 ;
    orientation = 0 ;
    speed = 0 ;
    width = 0 ;
    
    % Normalised distance of dot travel per frame
    dnorm = 0 ;
    
    % hit region
    hitregion = zeros ( 1 , 6 ) ;
    
    
    %%% Buffers %%%
    
    % Normalised location between -1 and 1 in the x and y axes. Rows
    % indexed by x and y coordinate , columns by dot.
    nxy
    
    % Actual location in degrees of visual field from the centre
    xy
    
    % Colour lookup table values. Rows indexed by r, g, b, a and columns by
    % dot.
    clut
    
    
  end % properties
  
  
end % rfmaprdk_handle

