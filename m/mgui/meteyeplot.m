
function  [ h , update , reset , recover , close ] = meteyeplot
% 
% [ h , update , reset , recover , close ] = meteyeplot
% 
% Displays a run-time plot of binoccular eye positions. One panel shows the
% estimated two-dimensional location of gaze from both eyes on the surface
% of the stimulus screen versus the hit regions of visible stimuli. The
% remainder show one-dimensional horizontal and vertical eye positions over
% time relative to state changes of the trial.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  % MET compile-time constants
  global  MC  MCC
  
  % If these haven't been set yet then set them
  if  isempty ( MC  )  ,   MC  = met ( 'const' , 1 ) ;  end
  if  isempty ( MCC )  ,   MCC = metctrlconst        ;  end
  
  
  %%% Constants %%%
  
  % MET signal identifiers
  C.MSID = MCC.MSID ;
  
  % Pixels per degree of visual angle %
  
  % Screen width, height, and distance from subject
  p = metscrnpar ;
  
  % Screen resolution , assumes that maximum screen index displays the
  % stimulus
  if  p.screenid  ==  -1
    i = max (  Screen ( 'Screens' )  ) ;
  else
    i = p.screenid ;
  end
  
  [ pxw , pxh ] = Screen ( 'WindowSize' , i ) ;
  
  % Pixels per degree along each spatial dimension
  ppd = metpixperdeg (  p.width  ,  pxw  ,  p.subdist  ) ;
  
  % Repack pixels per degree
  C.PXPDEG = ppd ;
  
  % Screen measurements in pixels
  C.SCRPIX.WIDTH  = pxw ;
  C.SCRPIX.HEIGHT = pxh ;
  
  % Halved screen measurements, in degrees
  C.SCHDEG.WIDTH  = pxw  /  C.PXPDEG  /  2 ;
  C.SCHDEG.HEIGHT = pxh  /  C.PXPDEG  /  2 ;
  
  % Plot box aspect ratio of 2D eye position plot
  E2DPBA = [ p.width , p.height , 1 ] ;
  
  % Remember whether or not touchscreen/mouse input is being used
  C.TOUCH = p.touch ;
  
  % Time gate for touchscreen/mouse positions , if this amount of time or
  % more passes since the last new data was drawn then add NaN values to
  % erase old positions from the tail of the line. In seconds. Note, this
  % is the duration of one touch/mouse sample ; any shorter and the
  % corresponding animated lines are erased faster than they are drawn.
  C.TGATES = 1 / MCC.SHM.EYE.MOUSEPOLL ;
  
  
  %-- Figure --%
  
  % Title
  TITBAR = 'MET eye position' ;
  
  % Operator's monitor screen size
  gr = groot ;
  pxh = gr.ScreenSize ( 4 ) ;
  
  % Height of figure in pixels
  HEIGHT = ceil ( pxh / 5 * 4 ) ;
  
  % Width of figure in pixels. Obeys aspect ratio of 2D plot's axes if it
  % were to occupy 2/3 the figure's height.
  WIDTH = ( p.width / p.height )  *  ( 2 * HEIGHT / 3 ) ;
  
  % Duration of 2D eye position samples, in seconds
  E2DDUR = 0.25 ;
  
  % Duration of 1D time plots , in seconds
  C.TIMDUR = 6 ;
  
  % Eye position sampling rate
  C.EYESHZ = MCC.SHM.EYE.SHZ ;
  
  % Animated line properties. Field name, colour, and number of samples.
  % Listed in order: left eye, right eye, touchscreen/mouse
  ALFNAM = {  'left'  ;  'right'  } ;
  ALFCOL = [  0.85 , 0 , 0  ;  0 , 0.5 , 1  ] ;
  ALFNUM = [ 1 ; 1 ]  *  ceil ( [ E2DDUR , C.TIMDUR ]  *  C.EYESHZ ) ;
  
  % If touchscreen/mouse is in use then add extra entry , assume roughly
  % the same sample rate as eye positions
  if  C.TOUCH
    
    ALFNAM = [  ALFNAM  ;  { 'touch' }  ] ;
    ALFCOL = [  ALFCOL  ;  0.75 , 0.5 , 1  ] ;
    ALFNUM = [  ALFNUM  ;
                ceil( [ E2DDUR , C.TIMDUR ]  *  MCC.SHM.EYE.MOUSEPOLL )  ];
    
    % Make a variable that remembers the last time that touchscreen/mouse
    % positions were drawn to the animated line. This, so that old samples
    % will continue to be erased even when no new positions are streaming
    % in through 'eye' shared memory
    C.tchtim = GetSecs ;
    
  end % touchscreen param is on
  
  
  %-- MET signal graphics object buffer --%
  
  % Signal times
  C.MBUF.tim = [] ;
  
  % Graphics object handles
  C.MBUF.goh = gobjects ( 0 , 3 ) ;
  
  
  %-- Receptive/response field markers --%
  
  % Will point to latest sd.rfdef struct
  C.RF.def = [] ;
  
  % Will hold a vector of rectangle graphics objects that mark RF locations
  C.RF.rec = gobjects ( 0 ) ;
  
  
  %-- MET ptb-type stimulus hit regions --%
  
  % Need to keep track of whether trial is initialising
  C.HREG.tinit = false ;
  
  % Task stimulus to stimulus link mapping
  C.HREG.lnkind = [] ;
  
  % Hit regions of ptb-type stimulus links
  C.HREG.hitregion = [] ;
  
  % Task logic in current use
  C.HREG.logic = [] ;
  
  % Stimulus links of type ptb
  C.HREG.ptblnk = [] ;
  
  % Current state of the trial
  C.HREG.state = [] ;
  
  % Graphics object array of the rectangles representing hit regions
  C.HREG.rect = {} ;
  
  
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
    makelines ( C.A.SCR , ALFNAM , ALFCOL , ALFNUM( : , 1 ) , '2D' ) ;
  
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
  C.A.HOR.UserData = ...
    makelines ( C.A.HOR , ALFNAM , ALFCOL , ALFNUM( : , 2 ) , '1D' ) ;
  
  % Label
  ylabel ( 'Azimuth' )
  
  
  %%% Vertical eye position over time %%%
  
  C.A.VER = mak1da ( h , [ 0.1 , 0.1 , 0.8 , 0.5 / 3 - 0.05 ] , ...
    C.TIMDUR , C.SCHDEG.HEIGHT ) ;
  
  % Eye position lines
  C.A.VER.UserData = ...
    makelines ( C.A.VER , ALFNAM , ALFCOL , ALFNUM( : , 2 ) , '1D' ) ;
  
  % Label
  ylabel ( 'Elevation' )
  xlabel ( 'Time (s)' )
  
  
  %%% Magnification factor %%%
  
  % uicontrol properties
  UICTXT = { 'Style' , 'text' , 'BackgroundColor' , 'none' , ...
    'ForegroundColor' , 'w' , 'HorizontalAlignment' , 'left' , ...
    'Units' , 'normalized' } ;
  
  UICNTL = { 'BackgroundColor' , 'none' , 'ForegroundColor' , 'w' , ...
    'Units' , 'normalized' } ;
  
  % Build labelled popup menu
  C.MAG = metlabcnt ( UICTXT , UICNTL , 'popupmenu' , h , 0 , 1 , ...
    'Magnification' , 'magnification' , @mag_cb ) ;
  
  % Shorten a bit
  C.MAG.Position( 3 ) = C.MAG.Position( 3 ) / 2 ;
  
  % List of magnification factor strings
  MAGFAC = arrayfun ( @( n ) sprintf( '%dX' , n ) , 1 : 5 , ...
    'UniformOutput' , false ) ;
  
  % Add list of options, brighten a bit, initialise origin data.
  set ( C.MAG , 'String' , MAGFAC , 'Value' , 1 ,...
    'BackgroundColor' , [ 0.15 , 0.15 , 0.15 ] , 'UserData' , [ 0 , 0 ] )
  
  
  %%% Highlighting task stimuli %%%
  
  % Create another labelled popup menu
  C.HIGH = metlabcnt ( UICTXT , UICNTL , 'popupmenu' , h , ...
    sum( C.MAG.Position( [ 1 , 3 ] ) ) , 1 , 'Highlight' , ...
    'highlight' , @high_cb ) ;
  
  % Make sure that user data has correct form
  C.HIGH.UserData = struct ( 'logic' , '' , 'stim' , '' ) ;
  
  % Set first item in list
  C.HIGH.String = { 'none' } ;
  
  % Widen control
  C.HIGH.Position( 3 ) = 2  *  C.HIGH.Position( 3 ) ;
  
  
  %%% Final settings %%%
  
  % Store constants for later use
  h.UserData = C ; 
  
  
  %%% Return function handles %%%
  
  update = @( h , sd , ~ , td , cbuf , ~ )  updatef( h , sd , td , cbuf ) ;
   reset = @resetf ;
 recover = @( ~ , ~ )  recoverf ;
   close = @closef ;
  
  
end % meteyeplot


%%% Callbacks %%%

% Magnification factor control
function  mag_cb ( h , ~ )
  
  % Figure
  f = h.Parent ;
  
  % Constants
  C = f.UserData ;
  
  % Magnification factor applied
  if  1  <  h.Value
    
    % Apply translation to axes
    dx = h.UserData ( 1 ) ;  dy = h.UserData ( 2 ) ;
    
  % No magnification
  else
    
    % No translation
    dx = 0 ;  dy = 0 ;
    
  end % translations
  
  % Calculate new axis limits
  XLim = C.SCHDEG.WIDTH  / h.Value  *  [ -1 , 1 ]  +  dx ;
  YLim = C.SCHDEG.HEIGHT / h.Value  *  [ -1 , 1 ]  +  dy ;
  
  % Rescale axes of the 2D plot
  set ( C.A.SCR , 'XLim' , XLim , 'YLim' , YLim )
  
end % mag_cb


% Task stimulus highliting control
function  high_cb ( h , ~ )
  
  % 'none selected , clear user data values and quit
  if  h.Value  ==  1
    h.UserData.logic = '' ;
    h.UserData.stim  = '' ;
    return
  end
  
  % Get selected string
  s = h.String {  h.Value  } ;
  
  % Separate task logic name from task stimulus
  s = strsplit ( s , ':' ) ;
  
  % Assign to user data
  h.UserData.logic = s { 1 } ;
  h.UserData.stim  = s { 2 } ;
  
end % high_cb


%%% Subroutines %%%

% MET GUI initialisation stage , make animated line objects for either
% two-dimentional or one-dimensional plots
function  ah = makelines ( PAR , NAM , COL , NUM , FLG )
  
  % Marker size
  MS = 4 ;

  switch  FLG
    case  '2D' ,  LS = 'none' ;  M =    '.' ;
    case  '1D' ,  LS =    '-' ;  M = 'none' ;
  end
  
  % Loop line properties and make a line for each set
  for  i = 1 : numel ( NAM )
    
    ah.( NAM{ i } ) = animatedline (  'Parent'  ,  PAR  ,  ...
      'MaximumNumPoints'  ,  NUM( i )  ,  'LineStyle'  ,  LS  ,  ...
      'Color'  ,  COL( i , : )  ,  'Marker'  ,  M  ,  ...
      'MarkerEdgeColor'  ,  COL( i , : )  ,  'MarkerSize'  ,  MS  ) ;
    
  end % lines
  
end % makelines


% Initialise one-dimensional plots
function  a = mak1da ( h , POS , DUR , HL )
  
  a = axes ( 'Parent' , h , 'Color' , 'none' , ...
    'TickDir' , 'out' , 'LineWidth' , 1 , 'XColor' , 'w' , ...
    'YColor' , 'w' , 'Box' , 'on' , 'Position' , POS , ... 
    'Xlim' , [ 0 , DUR ] , 'Ylim' , [ -1 , 1 ] * HL , ...
    'XGrid' , 'on' , 'YGrid' , 'on' , 'GridColor' , [1 1 1] * 0.85 ) ;
  
end % mak1da


% Change the visibility of rectangles representing the currently visible
% task stimuli
function  recvis (  HREG  ,  vis  )
  
  % Current task logic state name
  s = HREG.state ;
  
  % Currently visible task stimuli
  j = HREG.logic.stim.( s ) ;
  
  % Remove task stimulus 'none'
  j = j( j ~= 1 ) ;

  % Get set of linked ptb-type stimulus definitions
  j = [  HREG.lnkind{ j }  ] ;
  
  % Grab set of rectangles
  r = [  HREG.rect{ j }  ] ;

  % Change visibility
  if  ~ isempty ( r )  ,  set (  r  ,  'Visible'  ,  vis  )  ,  end
  
end % recvis


% Make rectangle graphics object to represent list of hit regions. u is
% optional , if provided then it is an array of rectangle objects that
% require updated positions and no output is required
function  g = mkrect ( h , hr , u )
  
  
  %%% Global constants %%%
  
  global  MCC
  
  
  %%% Find position %%%
  
  % Hit region list is empty , so return an empty graphics object place
  % holder
  if  isempty ( hr )
    if  nargin < 3  ,  g = gobjects ( 0 ) ;  end
    return
  end
  
  % Build position rectangle according to the hit region format , either it
  % defines a set of rectangles or a set of circles
  switch  size (  hr  ,  2  )
    
    % Set of circles
    case  6
      
      
      %-- Calculate bounding rectangles --%
      
      % Hit region constants
      H = MCC.SDEF.ptb.hitregion.sixcol ;
      
      % Position list
      p = [  hr( : , [ H.xcoord , H.ycoord ] )  -  ...
             hr( : , [ H.radius , H.radius ] )  ,  ...
             2  *  hr( : , [ H.radius , H.radius ] )  ] ;
      
      
      %-- Make rectangle objects --%

      % Number of rectangles
      n = size ( hr , 1 ) ;

      % Make new rectangle objects
      if  nargin  <  3

        % Empty list
        g = gobjects ( 1 , n ) ;

        % Fill list
        for  i = 1 : n
          g( i ) = rectangle (  'Parent'  ,  h.UserData.A.SCR  ,  ...
            'Position'  ,  p( i , : )  ,  'Curvature'  ,  [ 1 , 1 ]  ,  ...
            'EdgeColor'  ,  'w'  ,  'Visible'  ,  'off'  ) ;
        end

      % Update existing rectangles
      else

        for  i = 1 : n  ,  u( i ).Position( : ) = p( i , : ) ;  end

      end % make new rectangle objects
      
      
    % Set of rectangles
    case  8
      
      
      %-- Calculate rectangle vertices --%
      
      % Hit region constants
      H = MCC.SDEF.ptb.hitregion.eightcol ;
      
      % Get cos and sin value (columns) for each rectangle (rows)
      cossin = cosd (  [  hr( : , H.rotation )  ,  ...
                          hr( : , H.rotation ) - 90  ]  ) ;
      
      % Compute x and y coordinates of vertices of un-rotated and
      % un-translated rectangles
      x = hr( : , H.width  )  *  [ -0.5 , -0.5 , +0.5 , +0.5 ] ;
      y = hr( : , H.height )  *  [ -0.5 , +0.5 , +0.5 , -0.5 ] ;
      
      % Transform rectangles
      dx = zeros ( size( x ) ) ;
      dy = zeros ( size( y ) ) ;
      
      for  i = 1 : size ( x , 1 )
        
        % Rotate x-coordinates and add translation
        dx( i , : ) = [ 1 , -1 ]  .*  cossin ( i , : )  *  ...
          [  x( i , : )  ;  y( i , : )  ]  +  hr ( i , H.xcoord ) ;
        
        % ... then y-coordinates
        dy( i , : ) = cossin ( i , [ 2 , 1 ] )  *  ...
          [  x( i , : )  ;  y( i , : )  ]  +  hr ( i , H.ycoord )  ;
        
      end % rotate
      
      % Transpose the translated rectangles so that rectangles are indexed
      % by column , and vertices by row
      dx = dx' ;  dy = dy' ;
      
      
      %-- Make patch object --%
      
      % Make new patch
      if  nargin  <  3

        g = patch ( 'Parent' , h.UserData.A.SCR , ...
          'XData' , dx , 'YData' , dy , 'FaceColor' , 'none' , ...
          'EdgeColor' , 'w' , 'Visible' , 'off' ) ;
        
      % Update existing patch
      else
        
        u.XData = dx ;
        u.YData = dy ;
        
      end % patch object
      
      
    % Unrecognised format
    otherwise
      
      
      % If we get here then there is a big problem , throw an error
      meterror (  [ 'meteyeplot: hit region list has illegal format ,' ,...
        ' neither 5 nor 6 columns' ]  )
      
      
  end % rect positions
  
  
end % mkrect


%%% Figure functions %%%

function  resetf ( h , d )
  
  % Handle different cases
  switch  d { 1 }
    
    % New trial descriptor is available
    case  'td'
      
      % New trial descriptor
      td = d { 2 } ;
      
      % x- and y-axis location of trial origin , degrees from centre of
      % screen
      xorigin = td.origin( 1 ) ;
      yorigin = td.origin( 2 ) ;
      
      % RF definitions
      rf = h.UserData.RF.def ;
      
      % Rectangle handles
      r = h.UserData.RF.rec ;
      
      % Update location of RF markers according to trial origin
      for  i = 1 : numel ( rf )
        
        % RF radius
        rad = rf( i ).width  /  2 ;
        
        % New location
        r( i ).Position( 1 ) = rf( i ).xcoord  +  xorigin  -  rad ;
        r( i ).Position( 2 ) = rf( i ).ycoord  +  yorigin  -  rad ;
        
      end % update rf location
    
    % New session descriptor is available
    case  'sd'
      
      % New session descriptor
      sd = d { 2 } ;
      
      % Get latest set of RF definitions
      h.UserData.RF.def = sd.rfdef ;
      
      % Destroy any old RF markers
      if  ~ isempty (  h.UserData.RF.rec  )
        
        delete (  h.UserData.RF.rec  )
        
      end
      
      % Number of RF definitions
      n = numel (  sd.rfdef  ) ;
      
      % Create new set of rectangles
      h.UserData.RF.rec = gobjects ( 1 , n ) ;
      
      % RF definitions available
      if  n
      
        % Make rectangle objects
        for  i = 1 : n

          % Receptive field diameter
          w = sd.rfdef( i ).width ;

          % Starting positions
          xy = [ sd.rfdef( i ).xcoord , sd.rfdef( i ).ycoord ]  -  w / 2 ;

          % RF marker
          h.UserData.RF.rec( i ) = ...
            rectangle (  'Parent'  ,  h.UserData.A.SCR  ,  ...
              'Curvature'  ,  [ 1 , 1 ]  ,  'EdgeColor'  ,  'b'  ,  ...
              'Visible'  ,  'on'  ,  'LineWidth'  ,  2  ,  ...
              'Position'  ,  [ xy , w , w ]  ) ;

        end % make rects
      
      end % rf definitions
      
      % Set highlighting control's set of selectable strings. Start by
      % deleting existing strings.
      h.UserData.HIGH.String( 2 : end ) = [] ;
      
      % Loop task logic names and build logic name/stimulus pairs.
      for  TLOG = fieldnames ( sd.logic )  ,  l = TLOG { 1 } ;
        
        % Fetch set of task stimuli , excluding 'none'
        s = setdiff ( sd.logic.( l ).nstim , 'none' , 'stable' ) ;
        
        % Join logic/stimulus names
        s = cellfun (  @( c ) [ l , ':' , c ]  ,  s  ,  ...
          'UniformOutput'  ,  false  ) ;
        
        % Add to control's string set
        h.UserData.HIGH.String = [  h.UserData.HIGH.String  ,  s  ] ;
        
      end % task logic names
      
      % If highlight control has 'none' selected then quit now
      if  h.UserData.HIGH.Value  ==  1  ,  return  ,  end
      
      % Reproduce former selection
      s = [  h.UserData.HIGH.UserData.logic  ,  ':'  ,  ...
             h.UserData.HIGH.UserData.stim  ] ;
      
      % Look for new selection that matches former selection
      i = find ( strcmp(  h.UserData.HIGH.String  ,  s  ) ) ;
      
      % Not found
      if  isempty ( i )
        
        % Default to selecting first item in list 'none'
        h.UserData.HIGH.Value = 1 ;
        
        % Run callback to refresh user data
        h.UserData.HIGH.Callback ( h.UserData.HIGH , [] )
        
      else
        
        % Item found , set to that value
        h.UserData.HIGH.Value = i ;
        
      end
      
  end % handle cases
  
end % resetf


function  recoverf
  
  % No action required
  
end % recoverf


function  closef ( h )
  
  % Delete the figure , bypass close request callback
  delete ( h )
  
end % closef


function  drawnew = updatef ( h , sd , td , cbuf )
  
  
  %%% Global constants %%%
  
  global  MC  MCC
  
  % 'eye' shared memory column indeces
  TIME   = MCC.SHM.EYE.COLIND.TIME   ;
  XLEFT  = MCC.SHM.EYE.COLIND.XLEFT  ;
  YLEFT  = MCC.SHM.EYE.COLIND.YLEFT  ;
  XRIGHT = MCC.SHM.EYE.COLIND.XRIGHT ;
  YRIGHT = MCC.SHM.EYE.COLIND.YRIGHT ;
  
  
  %%% Figure constants %%%
  
  % All constants
  C = h.UserData ;
  
  % MET signal identifier map
  MSID = h.UserData.MSID ;
  
  
  %%% Trial handling %%%
  
  % Initialise output to report no changes to MET GUI
  drawnew = false ;
  
  % New signals
  if  cbuf.new_msig
    
    % mready MET signals
    i = cbuf.msig.sig  ==  MSID.mready ;
    
    % Trial initialisation is happening if there is an mready trigger
    if  any (  cbuf.msig.crg( i )  ==  MC.MREADY.TRIGGER  )
      
      % Raise initialisation flag for hit regions
      h.UserData.HREG.tinit = true ;
      
      % It is time to update the trial origin in the magnification factor
      % menu
      C.MAG.UserData( : ) = td.origin ( 1 : 2 ) ;
      
      % 2D plot is magnified , so relocate the axes to centre on that spot
      if  1  <  C.MAG.Value  ,  C.MAG.Callback ( C.MAG , [] )  ,  end
      
    end % begin trial initialisation
    
    % Change of task logic state
    i = cbuf.msig.sig  ==  MSID.mstate ;
    
    if  any ( i )  &&  ~ isempty(  h.UserData.HREG.rect  )
      
      % Remove visibility from rectangles that represent task stimuli in
      % the old state that we transitioned from
      recvis (  h.UserData.HREG  ,  'off'  )
      
      % New state , transitioned to
      j = cbuf.msig.crg( find(  i  ,  1  ,  'last'  ) ) ;
      h.UserData.HREG.state = h.UserData.HREG.logic.nstate{ j } ;
      
      % Grant visibility to rectangles representing task stimuli of the new
      % state
      recvis (  h.UserData.HREG  ,  'on'  )
      
      % Report change
      drawnew = true ;
      
    end % state change
    
    % End of trial
    if  any (  cbuf.msig.sig  ==  MSID.mstop  )
      
      % Delete hit region rectangles
      delete ( [  C.HREG.rect{ : }  ] )
      h.UserData.HREG.rect = {} ;
      
      % Move origin to centre of screen
      C.MAG.UserData( : ) = 0 ;
      
      % 2D plot is magnified , so relocate the axes to centre on that spot
      if  1  <  C.MAG.Value  ,  C.MAG.Callback ( C.MAG , [] )  ,  end
      
      % Report change
      drawnew = true ;
      
    end % of trial
    
  end % new signals
  
  
  %%% Handle new hit regions %%%
  
  % Check if shared memory is available
  newshm = ~ isempty ( cbuf.shm ) ;
  
  % Look for new readable shm data
  if  newshm  ,  rshm = [ cbuf.shm{ : , 2 } ]  ==  'r' ;  end
  
  % 'stim' shm ready for reading
  if  newshm  &&  any ( strcmp(  cbuf.shm( rshm , 1 )  ,  'stim'  ) )
    
    % Trial is initialising
    if  h.UserData.HREG.tinit
      
      % Hit region data
      HREG = h.UserData.HREG ;
      
      % Highlight control
      HIGH = h.UserData.HIGH ;
      
      % We now consider trial initiation to be over
      HREG.tinit = false ;
      
      % Initialise state of the trial
      HREG.state = 'start' ;
      
      % Process initialisation hit regions
      [ HREG.lnkind , HREG.hitregion , HREG.logic , HREG.ptblnk ] = ...
        metptblink ( sd , td , cbuf ) ;
      
      % Allocate rectangle cell array
      HREG.rect = cell ( size(  HREG.hitregion  ) ) ;
      
      % Make new hit region rectangles
      HREG.rect( HREG.ptblnk ) = cellfun (  @( hr )  mkrect ( h , hr ) ,...
        HREG.hitregion( HREG.ptblnk )  ,  'UniformOutput'  ,  false  ) ;
      
      % Highlighting applies to this logic
      if  strcmp (  HIGH.UserData.logic  ,  td.logic  )
        
        % Get index of highlighted task stimulus
        j = sd.logic.( td.logic ).istim.( HIGH.UserData.stim ) ;
        
        % Make a logical vector the same size as the cell array of rect
        % handles
        i = false ( size(  HREG.rect  ) ) ;
        
        % Set logical index to stimulus links for the named task stimulus
        i( HREG.lnkind{ j } ) = 1 ;
        
        % But only if they are of type 'ptb'
        i = i  &  reshape ( HREG.ptblnk , size( i ) ) ;
        
        % Apply highlighting to selected rectangle objects
        set ( [ HREG.rect{ i } ] , 'LineWidth' , 1.5 , 'EdgeColor' , 'r' )
        
      end % highlighting
      
      % Show stimulus hit regions
      recvis (  HREG  ,  'on'  )
      
      % Save new hit region data
      h.UserData.HREG = HREG ;
      
    % Trial is not initialising , nor has it stopped and deleted the old
    % hit regions.
    elseif  ~ isempty (  h.UserData.HREG.rect  )
      
      % Indeces of changed hit regions that belong to ptb-type stimuli
      i = cbuf.stim{ MCC.SHM.STIM.LINDEX }  &  h.UserData.HREG.ptblnk ;
      
      % Save the new hit regions
      h.UserData.HREG.hitregion( i ) = ...
        cbuf.stim( MCC.SHM.STIM.HITREG : end ) ;
      
      % We need to update the position of existing rectangles
      for  j = find ( i )'
        
        mkrect (  h  ,  ...
          h.UserData.HREG.hitregion{ j }  ,  h.UserData.HREG.rect{ j }  )
        
      end
      
    end % state of trial
    
    % Report change
    drawnew = true ;
    
  end % read 'stim'
  
  
  %%% Handle new eye positions %%%
  
  % Initialise new time axis limit , if tlim( 2 ) is zero then this has not
  % been set
  tlim = [ -C.TIMDUR , 0 ] ;
  
  % 'eye' shm ready for reading
  if  newshm  &&  any ( strcmp(  cbuf.shm( rshm , 1 )  ,  'eye'  ) )
    
    
    %-- Eye positions --%
    
    % Point to eye shared memory data
    eye = cbuf.eye { MCC.SHM.EYE.EYEIND } ;
    
    % New eye positions are available
    if  ~ isempty ( eye )

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
      tlim = tlim  +  eye ( end , TIME ) ;

    end % eye pos
    
    
    %-- Touchscreen/mouse position --%
    
    % Point to shared memory data
    if  C.TOUCH  ,  touch = cbuf.eye { MCC.SHM.EYE.IMOUSE } ;  end
  
    
  % No new 'eye' shared memory data , but touchscreen/mouse is enabled
  elseif  C.TOUCH
    
    % So return empty touch data , this will cause NaN to be added to lines
    touch = [] ;
    
  end % 'eye' shm
  
  % New time axis limits not yet set , so do it now
  if  ~ tlim ( 2 )  ,  tlim = tlim  +  GetSecs ;  end
  
  % New touch/mouse positions ready
  if  C.TOUCH
    
    % No new positions are available , so fill the animated lines with NaN
    % values to erase old points
    if  isempty ( touch )
      
      % Time that has passed since the last draw
      j = tlim ( 2 )  -  h.UserData.tchtim ;
      
      % If the time gate is met or exceeded ...
      if  C.TGATES  <=  j
        
        % ... then make empty array with as many samples as would have
        % otherwise been provided since the last draw. Fudge the thing, or
        % it erases old points a bit fast.
        touch = nan (  floor( 0.9 * j * MCC.SHM.EYE.MOUSEPOLL )  ,  3  ) ;
        
      else
        
        % Otherwise, do not change the lines
        touch = zeros ( 0 , 3 ) ;
        
      end % gate erasure of lines
      
    end % empty points

    % Add point to all lines
    ah = C.A.SCR.UserData.touch ;
    addpoints (  ah  ,  touch( : , XLEFT )  ,  touch( : , YLEFT )  )
    ah = C.A.HOR.UserData.touch ;
    addpoints (  ah  ,  touch( : , TIME  )  ,  touch( : , XLEFT )  )
    ah = C.A.VER.UserData.touch ;
    addpoints (  ah  ,  touch( : , TIME  )  ,  touch( : , YLEFT )  )
    
    % Update draw time if something was drawn
    if  ~ isempty ( touch )  ,  h.UserData.tchtim = tlim ( 2 ) ;  end

  end % touchscreen / mouse
  
  
  %%% Time axis %%%
  
  % Update axis limits if time axis is obsolete
  if  C.A.HOR.XLim( 2 )  <  tlim( 2 )
    set ( [ C.A.HOR , C.A.VER ] , 'XLim' , tlim )
    drawnew = true ;
  end
  
  
  %%% Handle new signals %%%
  
  % MET signal graphics handle buffer
  mbuf = h.UserData.MBUF ;
  
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
  
  % Find new signals that occur within the current time window that are
  % shown by the plot
  i = tlim ( 1 ) <= cbuf.msig.tim  &  ( cbuf.msig.sig == MSID.mstart  | ...
    cbuf.msig.sig == MSID.mstate  |  cbuf.msig.sig == MSID.mstop ) ;
  
  % Grab kept signals, cargos, and times
  sig = cbuf.msig.sig ( i ) ;
  crg = cbuf.msig.crg ( i ) ;
  tim = cbuf.msig.tim ( i ) ;
  
  % No visible signals
  if  isempty ( sig )  ,  return  ,  end
  
  % Report change
  drawnew = true ;
  
  % Make sure that time vector is column, not row
  if  size ( tim , 2 )  ~=  1
    tim = reshape ( tim , numel ( tim ) , 1 ) ;
  end
  
  % Make set of strings for kept signals
  S = cell ( size(  tim  ) ) ;
  
  for  j = 1 : numel ( S )
    
    % Handle different signals
    switch  sig ( j )
      
      % State change , return state name
      case  MSID.mstate
        S{ j } = h.UserData.HREG.logic.nstate{ crg( j ) } ;
        
      % Start of trial , return trial identifier
      case  MSID.mstart
        S{ j } = sprintf ( 'trial %d' , crg( j ) ) ;
        
      % Stop trial , return outcome
      case  MSID.mstop
        S{ j } = MC.OUT{ crg( j ) , 1 } ;
        
      % Unrecognised , return nothing
      otherwise
        S{ j } = '' ;
      
    end % handle sigs
    
  end % signal strings
  
  % Add new signals to time plots , keep handles to new objects
  hh = line ( [ tim , tim ]' , [ -C.SCHDEG.WIDTH  , C.SCHDEG.WIDTH  ] , ...
    'Parent' , C.A.HOR , 'LineWidth' , 1 , 'Color' , 'w' ) ;
  hv = line ( [ tim , tim ]' , [ -C.SCHDEG.HEIGHT , C.SCHDEG.HEIGHT ] , ...
    'Parent' , C.A.VER , 'LineWidth' , 1 , 'Color' , 'w' ) ;
  ht = text ( tim , repmat ( C.SCHDEG.WIDTH , size ( tim ) ) , ...
    S , 'Parent' , C.A.HOR , ...
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
  for  txt = ht'
    
    % Flip vertical position
    i = ~ i ;
    
    % Add height if i is on
    txt.Position( 2 ) = txt.Position ( 2 )  +  i * txt.Extent ( 4 ) ;
    
  end % stagger labels
  
  % Buffer new objects
  mbuf.tim = [ mbuf.tim ; tim ] ;
  mbuf.goh = [ mbuf.goh ; hh , hv , ht ] ;
  
  % Update graphics handle buffer
  h.UserData.MBUF = mbuf ;
  

end % updatef

