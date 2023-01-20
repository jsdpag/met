
function  cnt = metlabcnt ( UICTXT , UICNTL , style , parent , ...
  xref , yref , lab , tag , cb )
% 
% cnt = metlabcnt ( UICTXT , UICNTL , style , parent , xref , yref , lab ,
%   tag , cb )
% 
% Quick and dirty helper function for MET GUIs. Makes a labelled uicontrol,
% thus creating two controls together with a text on the left and a
% uicontrol of type style on the right. The UICTXT and UICNTL inputs must
% be cell arrays with parameter name/value pairs that are handed to
% uicontrol for the label and main control. parent is a handle to a figure
% or uipanel, or any object that may contain a uicontrol. xref and yref are
% the left and top positions of the pair of uicontrols in the parent
% graphics object. The label uses string lab, and the main control receives
% tag string tag. cb is a function handle to the callback that the main
% control will use. The main control is returned in cnt.
% 
% Written by Jackson Smith - April 2017 - DPAG , University of Oxford
% 
  
  % Unit menu label
  txt = uicontrol ( parent , UICTXT{ : } , 'String' , lab ) ;
  
  % Make it wide enough to hold its label
  txt.Position( 3 : 4 ) = 1.1 * txt.Extent( 3 : 4 ) ;
  
  % Place control
  txt.Position( 1 : 2 ) = [  xref  ,  yref - txt.Position( 4 )  ] ; 
  
  % Channel popup menu
  cnt = uicontrol( parent , UICNTL{ : } , 'Style' , style , ...
    'Tag' , tag , 'Callback' , cb ) ;
    
	% Place control
  cnt.Position( 1 : 3 ) = [  sum(  txt.Position( [ 1 , 3 ] )  )  ,  ...
    yref - cnt.Position( 4 )  ,  1.5 * cnt.Position( 3 )  ] ;
  
end % metlabcnt