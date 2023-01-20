
function  calgrid ( a , d , viewdist , scrwid )
% 
% calgrid ( a , d , viewdist , scrwid )
% 
% Throws a calibration grid onto the screen where lines are all spaced by a
% degrees of visual angle from a central pair of lines that cross in the
% centre of the screen. A central fixation point is drawn. Dots will be
% displayed in the centre of each grid square if d is logical true. If d is
% a double matrix then its values are taken to be disparities in degrees of
% visual angle that are applied sequentially to each dot. viewdist is the
% distance from the viewer to the screen. scrwid is the width of the
% screen. Give all length measurements in millimetres.
% 
% Run sca from the command line to clear the screen.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Constants %%%
  
  % Dot size , degrees
  DOTSIZ = 0.25 ;
  
  % Screen ID
  SID = max ( Screen(  'Screens'  ) ) ;
  
  % Screen horizontal and vertical resolution
  [ HPX , VPX ] = Screen ( 'WindowSize' , SID ) ;
  
  % Screen centre , adds half a pixel if there are an even number of pixels
  SCH = HPX / 2  +  0.5 * ( ~mod( HPX , 2 ) ) ;
  SCV = VPX / 2  +  0.5 * ( ~mod( VPX , 2 ) ) ;
  
  % Stereo mode
  if  isa ( d , 'double' )
    
    STEREO = 6 ;
    DOTS = true ;
    
  else
    
    STEREO = 0 ;
    DOTS = d ;
    
  end
  
  
  %%% Compute pixels per degree %%%
  
  % Pixels per millimetre of screen
  pxmm = HPX  /  scrwid ;
  
  % Millimetres per visual degree
  mmdeg = viewdist  *  tand ( 1 ) ;
  
  % Pixels per degree
  pxdeg = pxmm  *  mmdeg ;
  
  
  %%% Grid and dot locations %%%
  
  % Grid spacing in pixels
  a = a  *  pxdeg ;
  
  % Dot size in pixels
  DOTSIZ = DOTSIZ  *  pxdeg ;
  
  % Number of grid lines per direction , round down to nearest odd number
  Ng = floor ( [ HPX , VPX ]  /  a )  +  1 ;
  Ng = Ng  +  ( mod( Ng , 2 ) - 1 ) ;
  
  % Vertical grid line x-axis positions
  Vx = ( ( 1 : Ng ( 1 ) )  -  ceil ( Ng( 1 ) / 2 ) )  *  a  +  SCH ;
  Vx = reshape (  [ Vx ; Vx ]  ,  1  ,  2 * Ng( 1 )  ) ;
  
  % Horizontal grid line y-axis positions
  Hy = ( ( 1 : Ng ( 2 ) )  -  ceil ( Ng( 2 ) / 2 ) )  *  a  +  SCV ;
  Hy = reshape (  [ Hy ; Hy ]  ,  1  ,  2 * Ng( 2 )  ) ;
  
  % Build line matrix
  xy = [  [ Vx  ;  repmat( [ 0 , VPX ] , 1 , Ng( 1 ) ) ]  ,  ...
          [ repmat( [ 0 , HPX ] , 1 , Ng( 2 ) )  ;  Hy ]  ] ;
        
  % Drawing dots
  if  DOTS
    
    % Dot positions , based from line positions
    dx = [ Vx( 1 : 2 : end ) , Vx( end ) + a ]  -  a / 2 ;
    dy = [ Hy( 1 : 2 : end ) , Hy( end ) + a ]  -  a / 2 ;
    
    % Get grid of dots
    [ dx , dy ] = meshgrid ( dx , dy ) ;
    dx = reshape ( dx , 1 , numel ( dx ) ) ;
    dy = reshape ( dy , 1 , numel ( dy ) ) ;
    
    % Half disparity shift , applied to each eye image to get full
    % disparity
    if  STEREO
      
      % Disparity in pixels
      d = d  *  pxdeg ;
      
      % Expand to get a disparity for each dot
      d = d (  mod (  0 : numel ( dx ) - 1  ,  numel ( d )  )  +  1  ) ;
      
      % Subtract half disparity to dot positions to get left eye image ,
      % which is drawn first
      dx = dx  -  d / 2 ;
      
    end % disparities
  
  end % dots
  
  
  
  %%% Prepare PsychToolbox %%%
  
  % Define environment
  PsychImaging ( 'PrepareConfiguration' ) ;
  PsychImaging ( 'AddTask' , 'General' , 'FloatingPoint32BitIfPossible' ) ;
  PsychImaging ( 'AddTask' , 'General' , 'NormalizedHighresColorRange' ) ;
  
  % Open PTB window
  winptr = PsychImaging ( 'OpenWindow' , SID , 0 , [] , [] , [] , STEREO );
  
  
  %%% Draw image %%%
  
  % Anti-aliasing blend function
  Screen ( 'BlendFunction' , winptr , ...
      'GL_SRC_ALPHA' , 'GL_ONE_MINUS_SRC_ALPHA' ) ;
  
  % Cycle eye frame buffers
  for  e = 0 : double ( 0 < STEREO )

    % Set frame buffer and apply disparity to dots
    if  STEREO
      Screen ( 'SelectStereoDrawBuffer' , winptr , e ) ;
    end

    % Draw grid
    Screen ( 'DrawLines' , winptr , xy , [] , [] , [] , 2 ) ;

    % Fixation point
    Screen ( 'DrawDots' , winptr , [ SCH ; SCV ] , DOTSIZ , ...
      [] , [] , 2 ) ;

    % Draw dots
    if  DOTS
        
        % Calculate right eye position
        if  e  ,  dx = dx  +  d ;  end
        
        % Dots
        Screen ( 'DrawDots' , winptr , [ dx ; dy ] , DOTSIZ , ...
          [] , [] , 2 ) ;
        
    end % dots
    
  end % eye buffers
   
  % Show image
  Screen ( 'Flip' , winptr ) ;

  
end % calgrid

