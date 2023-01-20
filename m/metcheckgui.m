
function  c = metcheckgui ( H )
% 
% c = metcheckgui ( H )
% 
% Matlab Electrophysiology Toolbox. Helper function will reposition any
% figure listed in the graphics object array H if its title bar is off the
% edge screen where it can't be reached by the mouse. Returns a scalar
% logical that is true if any figures were repositioned.
% 
% Written by Jackson Smith - Feb 2017 - DPAG, University of Oxford
% 
  
  
  %%% Check input %%%
  
  % H not given
  if  ~ nargin
    
    H = [] ;
    
  
  elseif  ~ isempty ( H )  &&  ~ isa ( H , 'matlab.ui.Figure' )
    
    error ( 'MET:metcheckgui:H' , ...
      'metcheckgui: H must be an array of figure handles' )
    
  end % check input
  
  
  %%% Check figures %%%
  
  % Initialise output
  c = false ;
  
  % Nothing given
  if  isempty ( H )  ,  return  ,  end
  
  % Get the size of the screen in pixels
  gp = get (  groot  ,  'ScreenSize'  ) ;
  
  % Loop figures
  for  h = H( : )'
    
    % Remember the units
    u = h.Units ;
    
    % Set units to pixels
    h.Units = 'pixels' ;
    
    % Get figure outer position
    p = h.OuterPosition ;
    
    % Right position
    r = sum ( p(  [ 1 , 3 ]  ) ) ;
    
    % Position of the top
    t = sum ( p(  [ 2 , 4 ]  ) ) ;
    
    % Top of figure has fallen off the screen vertically
    if  t  <  gp ( 2 )  ||  gp ( 4 )  <  t
      
      % Put fig so that top is flush with top of screen
      h.OuterPosition( 2 ) = gp ( 4 )  -  p ( 4 ) ;
      
      % Position change
      c = true ;

    end % vertical
    
    % Figure has fallen off the screen horizontally to the left ...
    if  r  <=  gp ( 1 )
      
      % Put left of figure and screen together
      h.OuterPosition( 1 ) = gp ( 1 ) ;
      
      % Position change
      c = true ;
      
    % ... or to the right
    elseif  gp ( 3 )  <=  p ( 1 )
      
      % Put right of fig and screen together
      h.OuterPosition( 1 ) = gp ( 3 )  -  p ( 3 ) ;
      
      % Position change
      c = true ;
      
    end % horizontal
    
    % Restore original units
    h.Units = u ;
    
  end % figures
  
  
end % metcheckgui

