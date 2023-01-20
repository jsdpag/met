
function  [ h , update , reset , recover , close ] = meteyeplot_legacy
% 
% [ h , update , reset , recover , close ] = meteyeplot_legacy
% 
% Displays a run-time plot of binoccular eye positions. One panel shows the
% estimated two-dimensional location of gaze from both eyes on the surface
% of the stimulus screen. The remainder show one-dimensional horizontal and
% vertical eye positions over time.
% 
% Written by Jackson Smith - Dec 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  % MET compile-time constants
  global  MC  MCC
  
  % If these haven't been set yet then set them
  if  isempty ( MC  )  ,   MC  = met ( 'const' , 1 ) ;  end
  if  isempty ( MCC )  ,   MCC = metctrlconst        ;  end
  
  
  %%% Constants %%%
  
  % MET signal codes for mnull, mready, and mwait
  i = ismember ( MC.SIG ( : , 1 ) , ...
    { 'mnull' , 'mready' , 'mwait' , 'mreward' } ) ;
  C.MSID = MC.SIG ( i , : )' ;
  C.MSID = struct ( C.MSID{ : } ) ;
  
  % Pixels per degree of visual angle %
  
  % Screen width, height, and distance from subject
  p = metscrnpar ;
  
  % Screen resolution , assumes that maximum screen index displays the
  % stimulus
  i = max (  Screen ( 'Screens' )  ) ;
  [ pxw , pxh ] = Screen ( 'WindowSize' , i ) ;
  
  % Pixels per degree along each spatial dimension
  ppd = ...
    metpixperdeg ( [ p.width , p.height ] , [ pxw , pxh ] , p.subdist ) ;
  
  % Repack pixels per degree
  C.PXPDEG.WIDTH  = ppd ( 1 ) ;
  C.PXPDEG.HEIGHT = ppd ( 2 ) ;
  
  % Screen measurements in pixels
  C.SCRPIX.WIDTH  = pxw ;
  C.SCRPIX.HEIGHT = pxh ;
  
  
  % Halved screen measurements, in degrees
  C.SCHDEG.WIDTH  = pxw  /  C.PXPDEG.WIDTH  /  2 ;
  C.SCHDEG.HEIGHT = pxh  /  C.PXPDEG.HEIGHT /  2 ;
  
  % Plot box aspect ratio of 2D eye position plot
  E2DPBA = [ p.width , p.height , 1 ] ;
  
  
  % Figure %
  
  % Title
  TITBAR = 'MET eye position (legacy)' ;
  
  % Operator's monitor screen size
  gr = groot ;
  pxh = gr.ScreenSize ( 4 ) ;
  
  % Height of figure in pixels
  HEIGHT = ceil ( pxh / 5 * 4 ) ;
  
  % Width of figure in pixels. Obeys aspect ratio of 2D plot's axes if it
  % were to occupy 2/3 the figure's height.
  WIDTH = ( p.width / p.height )  *  ( 2 * HEIGHT / 3 ) ;
  
  % Duration of 2D eye position samples, in seconds
  E2DDUR = 1 ;
  
  % Duration of 1D time plots , in seconds
  C.TIMDUR = 6 ;
  
  % Eye position sampling rate
  EYESHZ = MCC.SHM.EYE.SHZ ;
  
  % Left eye colour
  LCOL = [ 0.85 , 0 , 0 ] ;
  
  % Right eye colour
  RCOL = [ 0 , 0.5 , 1 ] ;
  
  
  %%% MET signal graphics object buffer %%%
  
  % Signal times
  C.MBUF.tim = [] ;
  
  % Graphics object handles
  C.MBUF.goh = gobjects ( 0 , 3 ) ;
  
  
  %%% Generate figure %%%
  
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Units' , 'pixels' , 'Visible' , 'off' , ...
    'DockControls' , 'off' ) ;
  
  % Set width and height
  h.Position ( 2 : 4 ) = [ 1 , WIDTH , HEIGHT ] ;
  
  
  %%% 2D eye position on screen %%%
  
  % Make axes
  C.A.SCR = axes ( 'Parent' , h , 'Color' , 'none' , ...
    'TickDir' , 'out' , 'LineWidth' , 1 , 'XColor' , 'w' , ...
    'YColor' , 'w' , 'Box' , 'on' , ...
    'Position' , [ 0.05 , 1/3 + 0.1 , 0.9 , 2/3 - 0.2 ] , ... 
    'Xlim' , [ -1 , 1 ] * C.SCHDEG.WIDTH , ...
    'Ylim' , [ -1 , 1 ] * C.SCHDEG.HEIGHT , ...
    'XGrid' , 'on' , 'YGrid' , 'on' , 'GridColor' , [1 1 1] * 0.85 ) ;
  
  % Make axis lenghts correspond to physical size of screen
  pbaspect ( C.A.SCR , E2DPBA )
  
  % Eye position lines
  C.A.SCR.UserData = ...
    makelines ( C.A.SCR , LCOL , RCOL , ceil( E2DDUR * EYESHZ ) , '2D' ) ;
  
  % Labels
  title ( 'Stimulus screen' , 'Color' , 'w' )
  xlabel ( 'Azimuth (deg)' )
  ylabel ( 'Elevation (deg)' )
  
  
  %%% Horizontal eye position over time %%%
  
  C.A.HOR = mak1da ( h , ...
    [ 0.1 , 0.5 / 3 + 0.05 , 0.8 , 0.5 / 3 - 0.05 ] , ...
    C.TIMDUR , C.SCHDEG.WIDTH ) ;
  
  C.A.HOR.XTickLabel = [] ;
  
  % Eye position lines
  C.A.HOR.UserData = makelines ( C.A.HOR , LCOL , RCOL , ...
    ceil ( C.TIMDUR * EYESHZ ) , '1D' ) ;
  
  % Label
  ylabel ( 'Azimuth' )
  
  
  %%% Vertical eye position over time %%%
  
  C.A.VER = mak1da ( h , [ 0.1 , 0.1 , 0.8 , 0.5 / 3 - 0.05 ] , ...
    C.TIMDUR , C.SCHDEG.HEIGHT ) ;
  
  % Eye position lines
  C.A.VER.UserData = makelines ( C.A.VER , LCOL , RCOL , ...
    ceil ( C.TIMDUR * EYESHZ ) , '1D' ) ;
  
  % Label
  ylabel ( 'Elevation' )
  xlabel ( 'Time (s)' )
  
  
  %%% Final settings %%%
  
  % Store constants for later use
  h.UserData = C ; 
  
  % Position it at the top-right corner
  h.Units = 'normalized' ;
  op = get ( h , 'OuterPosition' ) ;
  h.Position( 1 : 2 ) = 1  -  op ( 3 : 4 ) ;
  
  
  %%% Return function handles %%%
  
  update = @( h , ~ , ~ , ~ , cbuf , ~ )  updatef ( h , cbuf ) ;
   reset = @( ~ , ~ )  resetf ;
 recover = @( ~ , ~ )  recoverf ;
   close = @closef ;
  
  
end % metraster


%%% Subroutines %%%

function  ah = makelines ( PAR , LCOL , RCOL , N , FLG )
  
  switch  FLG
    case  '2D' ,  LS = 'none' ;  M =    '.' ;
    case  '1D' ,  LS =    '-' ;  M = 'none' ;
  end
  
  % Left eye line
  ah.left  = animatedline ( 'Parent' , PAR , 'MaximumNumPoints' , N , ...
    'LineStyle' , LS ,           'Color' , LCOL , ...
    'Marker'    ,  M , 'MarkerEdgeColor' , LCOL ) ;
  
  % Right eye line
  ah.right = animatedline ( 'Parent' , PAR , 'MaximumNumPoints' , N , ...
    'LineStyle' , LS ,           'Color' , RCOL , ...
    'Marker'    ,  M , 'MarkerEdgeColor' , RCOL ) ;
  
end % makelines


function  a = mak1da ( h , POS , DUR , HL )
  
  a = axes ( 'Parent' , h , 'Color' , 'none' , ...
    'TickDir' , 'out' , 'LineWidth' , 1 , 'XColor' , 'w' , ...
    'YColor' , 'w' , 'Box' , 'on' , 'Position' , POS , ... 
    'Xlim' , [ 0 , DUR ] , 'Ylim' , [ -1 , 1 ] * HL , ...
    'XGrid' , 'on' , 'YGrid' , 'on' , 'GridColor' , [1 1 1] * 0.85 ) ;
  
end % mak1da


%%% Figure functions %%%

function  resetf
  
  % No action
  
end % resetf


function  recoverf
  
  % No action
  
end % recoverf


function  closef ( h )
  
  % Delete the figure , bypass close request callback
  delete ( h )
  
end % closef


function  updatef ( h , cbuf )
  
  
  %%% Global constants %%%
  
  global  MC  MCC
  
  % 'eye' shared memory column indeces
  TIME   = MCC.SHM.EYE.COLIND.TIME   ;
  XLEFT  = MCC.SHM.EYE.COLIND.XLEFT  ;
  YLEFT  = MCC.SHM.EYE.COLIND.YLEFT  ;
  XRIGHT = MCC.SHM.EYE.COLIND.XRIGHT ;
  YRIGHT = MCC.SHM.EYE.COLIND.YRIGHT ;
  
  
  %%% Figure constants %%%
  
  C = h.UserData ;
  
  
  %%% Handle new eye positions %%%
  
  % Search for 'eye' in list of available shared memory
  if  isempty ( cbuf.shm )
    
    % No shared memory is ready. The following 'any' statement will return
    % 0 with these values.
    i = false ;
    cbuf.shm = cell ( 0 , 2 ) ;
    
  else
    
    % Get index of 'eye' in the list of available shared memory.
    i = strcmp ( cbuf.shm ( : , 1 ) , 'eye' ) ;
    
  end
  
  % Can read from 'eye' shared memory
  if  any (  [ cbuf.shm{ i , 2 } ]  ==  'r'  )
      
    % Point to eye shared memory
    eye = cbuf.eye{ 1 } ;

    % Mirror vertical eye positions
    eye( : , [ YLEFT , YRIGHT ] ) = ...
      C.SCRPIX.HEIGHT  -  eye( : , [ YLEFT , YRIGHT ] ) ;

    % Convert to degrees of visual field from centre of screen
    eye( : , [ XLEFT , XRIGHT ] ) = ...
      eye( : , [ XLEFT , XRIGHT ] )  /  C.PXPDEG.WIDTH   -  ...
      C.SCHDEG.WIDTH  ;
    eye( : , [ YLEFT , YRIGHT ] ) = ...
      eye( : , [ YLEFT , YRIGHT ] )  /  C.PXPDEG.HEIGHT  -  ...
      C.SCHDEG.HEIGHT ;

    % Add to 2D position lines on screen
    ah = C.A.SCR.UserData ;
    addpoints ( ah.left  , eye ( : , XLEFT  ) , eye ( : , YLEFT  ) )
    addpoints ( ah.right , eye ( : , XRIGHT ) , eye ( : , YRIGHT ) )

    % Add to 1D position time courses
    ah = C.A.HOR.UserData ;
    addpoints ( ah.left  , eye ( : , TIME ) , eye ( : , XLEFT  ) )
    addpoints ( ah.right , eye ( : , TIME ) , eye ( : , XRIGHT ) )

    ah = C.A.VER.UserData ;
    addpoints ( ah.left  , eye ( : , TIME ) , eye ( : , YLEFT  ) )
    addpoints ( ah.right , eye ( : , TIME ) , eye ( : , YRIGHT ) )

    % Adjust x-axis limits on 1D time plots
    tlim = [ -C.TIMDUR , 0 ]  +  eye ( end , TIME ) ;
    set ( [ C.A.HOR , C.A.VER ] , 'XLim' , tlim )
  
  else
    
    % Need x-axis limit of time plot
    tlim = C.A.HOR.XLim ;
    
  end
  
  
  %%% Handle new signals %%%
  
  % MET signal graphics handle buffer
  mbuf = C.MBUF ;
  
  % Signals that have fallen off the plot
  i = mbuf.tim  <  tlim ( 1 ) ;
  
  if  any ( i )
    
    % Delete lost signals
    delete ( mbuf.goh( i , : ) )
    
    % Remove from buffer
    i = ~ i ;
    mbuf.tim = mbuf.tim ( i ) ;
    mbuf.goh = mbuf.goh ( i , : ) ;
    
    % Update graphics handle buffer
    h.UserData.MBUF = mbuf ;
    
  end % lost signals
  
  % No new signals , terminate function
  if  ~ cbuf.new_msig  ,  return  ,  end
  
  % Find new signals that occur within the current time window that are not
  % mnull, mready, mwait, or mreward.
  i = tlim ( 1 ) <= cbuf.msig.tim  &  cbuf.msig.sig ~= C.MSID.mnull  & ...
    cbuf.msig.sig ~= C.MSID.mready  &  cbuf.msig.sig ~= C.MSID.mwait  & ...
    cbuf.msig.sig ~= C.MSID.mreward ;
  
  % Grab kept signals and times
  sig = cbuf.msig.sig ( i ) ;
  tim = cbuf.msig.tim ( i ) ;
  
  % No visible signals
  if  isempty ( sig )  ,  return  ,  end
  
  % Make sure that time vector is column, not row
  if  size ( tim , 2 )  ~=  1
    tim = reshape ( tim , numel ( tim ) , 1 ) ;
  end
  
  % Add new signals to time plots , keep handles to new objects
  hh = line ( [ tim , tim ]' , [ -C.SCHDEG.WIDTH  , C.SCHDEG.WIDTH  ] , ...
    'Parent' , C.A.HOR , 'LineWidth' , 1 , 'Color' , 'w' ) ;
  hv = line ( [ tim , tim ]' , [ -C.SCHDEG.HEIGHT , C.SCHDEG.HEIGHT ] , ...
    'Parent' , C.A.VER , 'LineWidth' , 1 , 'Color' , 'w' ) ;
  ht = text ( tim , repmat ( C.SCHDEG.WIDTH , size ( tim ) ) , ...
    MC.SIG ( sig + 1 , 1 ) , 'Parent' , C.A.HOR , ...
    'Color' , 'w' , 'FontSize' , 10 , 'Interpreter' , 'none' , ...
    'HorizontalAlignment' , 'center' , 'VerticalAlignment' , 'bottom' ) ;
  
  % Determine whether the last label is low or high
  if  isempty ( mbuf.tim )
    
    % No label before the new batch , call it high
    i = true ;
    
  else
    
    % High if the old label is above the new
    i = mbuf.goh( end , 3 ).Position( 2 )  >  ht( 1 ).Position( 2 ) ;
    
  end
  
  % Vertically stagger the text labels
  for  t = ht'
    
    % Flip vertical position
    i = ~ i ;
    
    % Add height if i is on
    t.Position( 2 ) = t.Position ( 2 )  +  i * t.Extent ( 4 ) ;
    
  end % stagger labels
  
  % Buffer new objects
  mbuf.tim = [ mbuf.tim ; tim ] ;
  mbuf.goh = [ mbuf.goh ; hh , hv , ht ] ;
  
  % Update graphics handle buffer
  h.UserData.MBUF = mbuf ;
  

end % updatef

