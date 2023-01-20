
function  h = metptbgui ( MC , MCC , winptr , backgnd , photor )
% 
% h = metptbgui
% 
% Matlab Electrophysiology Toolbox. This is a unique and simple graphic
% user interface that is used by the metptb controller to provide the user
% with a way of switching a timeout screen on and off, and to set timeout
% screen durations following incorrect trials. MC is a scalar struct
% containing the current set of MET constants, as returned by 
% met ( 'const' ). MCC is the set of MET controller constants. winptr is
% the PsychToolbox window pointer that metptb received. backgnd is a three
% element vector giving normalised colour values of the window's background
% colour. photor is a struct with fields .msk, .mskrec, and .mskclu
% flagging whether to draw a masking square in the upper-right corner of
% the screen, the square's PsychRect, and greyscale colour lookup value.
% 
% Returns a handle to the figure GUI. The figure's UserData is a scalar
% struct. Field .tout is a double vector with an entry for each possible
% outcome, where .tout( i ) is the amount of time to show the timeout
% screen for following a trial with outcome MC.OUT{ i , 1 } ; correct and
% aborted trials default to zero. Field .type gives the kind of timeout
% screen to show following incorrect trials, 0 for a black screen and 1 for
% white noise.
% 
% MET .csv parameter file metptbgui.csv is expected in met/m/mgui and it
% must contain parameters type, contrast, failed, ignored, and broken. The
% first must be 1, 2, 3, or 4 saying what kind of timeout screen to show
% following an incorrect trial ; 1 for black screen, 2 for blank screen, 3
% for white noise, 4 for random lines. Greyscale values for types 3 and 4
% are found by adding or subtracting from the background colour by
% 'contrast' times the background. Blank screen uses the contrast level as
% a greyscale value for the whole screen. The rest provide default timeout
% durations following each incorrect trial type.
% 
% Written by Jackson Smith - April 2017 - DPAG , University of Oxford
% 
  
  
  %%% Constants %%%
  
  % Title bar
  TITBAR = 'Timeout' ;
  
  
  %-- Default parameters --%
  
  % Set of allowable type values ...
  TYPVAL = 1 : 4 ;
  
  % ... and associated strings
  TYPSTR = { 'Black' , 'Blank' , 'Noise' , 'Rand lines' } ;
  
  % Default parameter list , and numeric parameters
  DEFLST = { 'type' , 'contrast' , 'failed' , 'ignored' , 'broken' } ;
  
  % Default parameter file
  DEFNAM = fullfile (  MCC.GUIDIR  ,  'metptbgui.csv'  ) ;
  
  % Load defaults
  D = metreadcsv ( DEFNAM , DEFLST ) ;
  
  % Check that all defaults are zero or more
  for  F = DEFLST
    
    if  D.( F{ 1 } )  <  0
      
      error (  [ 'MET:metptbgui:' , F{ 1 } ]  ,  [ 'metptbgui: ' , ...
        'default parameter %s must be 0 or more' ]  ,  F{ 1 }  )
      
    end
    
  end % check defaults
  
  % Check that default parameter type is 0, 1, or 2
  if  all ( D.type  ~=  TYPVAL )
    
    error (  'MET:metptbgui:type'  ,  [ 'metptbgui: ' , ...
        'default parameter type must be: %s' ]  ,  ...
        strjoin ( num2cell( TYPVAL ) , ', ' )  )
      
  % Check that contrast doesn't exceed 1
  elseif  1  <  D.contrast
    
    error (  'MET:metptbgui:contrast'  ,  [ 'metptbgui: ' , ...
        'default parameter contrast must not exceed 1' ]  )
    
  end
  
  
  %-- MET trial outcomes --%
  
  % Outcome name to index map
  MOUT = MC.OUT' ;  MOUT = struct (  MOUT { : }  ) ;
  
  % Number of outcome types
  NOUT = size (  MC.OUT  ,  1  ) ;
  
  % The outcome types that can have timeouts
  OUTCTO = DEFLST ( 3 : end ) ;
  
  
  %-- Common graphics object properties --%
  
  UICTXT = { 'Style' , 'text' , 'BackgroundColor' , 'none' , ...
    'ForegroundColor' , 'w' , 'HorizontalAlignment' , 'left' , ...
    'Units' , 'normalized' } ;
  
  UICNTL = { 'BackgroundColor' , 'none' , 'ForegroundColor' , 'w' , ...
    'Units' , 'normalized' } ;
  
  
  %%% Generate figure %%%
  
  % winptr is the current PsychToolbox window pointer
  % w and h is the width and height of the PTB window
  % switch is a scalar logical saying whether the timeout screen is on
  %   ( 1 ) or off ( 0 )
  % uiswitch is a handle to the togglebutton that implements the switch
  s = struct ( 'type' , D.type , 'contrast' , D.contrast , ...
    'tout' , zeros( NOUT , 1 ) , 'winptr' , winptr , ...
    'backgnd' , backgnd , 'w' , [] , 'h' , [] , 'switch' , false , ...
    'uiswitch' , [] , 'photor' , photor , 'eyebuf' , [] , 'stereo' , [] ) ;
  
  % Set default timeouts
  for  F = OUTCTO
    
    % Get the index
    i = MOUT.( F{ 1 } ) ;
    
    % Set the default timeout
    s.tout( i ) = D.( F{ 1 } ) ;
    
  end % default timeouts
  
  % Get the width and height of the PTB window
  [ s.w , s.h ] = Screen (  'WindowSize'  ,  winptr  ) ;
  
  % Make figure
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Visible' , 'off' , 'DockControls' , 'off' , 'UserData' , s , ...
    'CloseRequestFcn' , [] , 'Resize' , 'on' ) ;
  
  
  %%% Add user controls %%%
  
  
  %-- Screen type --%
  
  % Popup menu for timeout screen type
  c = metlabcnt ( UICTXT , UICNTL , 'popupmenu' , h , 0 , 1 , ...
    'Screen type' , 'type' , @type_cb ) ;
  
  % Add options and set default value. Increase background colour,
  % slightly, so that the list shows against other text
  set ( c , 'String' , TYPSTR , 'Value' , s.type , ...
    'BackgroundColor' , [ 0.15 , 0.15 , 0.15 ] )
  
  % Get the vertical position of the bottom of this control
  y = c.Position ( 2 )  -  ...
    3 * max ( [  c.Extent( 4 ) - c.Position( 4 )  ,  0  ] ) ;
  
  
  %-- Contrast --%
  
  % Popup menu for timeout screen type
  c = metlabcnt ( UICTXT , UICNTL , 'edit' , h , 0 , y , ...
    'Contrast' , 'contrast' , @contrast_cb ) ;
  
  % Set default contrast value string and right-justification
  c.String = num2str (  D.contrast  ) ;
  c.HorizontalAlignment = 'right' ;
  
  % Get the vertical position of the bottom of this control
  y = c.Position ( 2 ) ;
  
  
  %-- Timeout duration title --%
  
  % Provide a title for timeout duration controls
  c = uicontrol ( h , UICTXT{ : } , ...
    'String' , 'Timeout duration (sec)' ) ;
  
  % Make it wide enough to hold its label
  c.Position( 3 : 4 ) = 1.1 * c.Extent( 3 : 4 ) ;
  
  % Place control
  c.Position( 1 : 2 ) = [  0  ,  y - c.Position( 4 ) - 0.05  ] ; 
  
  % Get the vertical position of the bottom of this control
  y = c.Position ( 2 ) ;
  
  
  %-- Timeout duration edits --%
  
  % Find maximum horizontal position of edits
  x = 0 ;
  
  % Make edits for each trial type timeout
  for  F = OUTCTO
    
    % Label is same as outcome type name , but capitalise the first
    % character
    lab = F { 1 } ;  lab( 1 ) = upper ( lab(  1  ) ) ;
    
    % Make the edit control
    c = metlabcnt ( UICTXT , UICNTL , 'edit' , h , 0 , y , lab , ...
      F{ 1 } , @tout_cb ) ;
    
    % UserData contains the index of this trial type
    c.UserData = MOUT.( F{ 1 } ) ;
    
    % Convert default timeout to string , and use right-justification
    c.String = num2str (  D.( F{ 1 } )  ) ;
    c.HorizontalAlignment = 'right' ;
    
    % Get the vertical position of the bottom of this control
    y = c.Position ( 2 ) ;
    
    % Find maximum x position
    if  x  <  c.Position ( 1 )  ,  x = c.Position ( 1 ) ;  end
    
  end % edits
  
  % Find all edit controls
  c = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'edit' ) ;
  
  % And align them
  for  i = 1 : numel ( c )  ,  c( i ).Position( 1 ) = x ;  end
  
  
  %-- Timeout screen switch --%
  
  % Make a button that toggles on and off
  c = metlabcnt ( UICTXT , UICNTL , 'togglebutton' , h , 0 , y - 0.05 , ...
      'Switch' , 'switch' , @switch_cb ) ;
  
  % Set the string according to current state of timeout screen
  c.String = 'off' ;
  
  % Store handle
  h.UserData.uiswitch = c ;
  
  
  %-- Align controls to bottom of figure --%
  
  % Find bottom of lowest control
  y = c.Position ( 2 ) ;
  
  % Reposition controls
  for  i = 1 : numel ( h.Children )
    
    % Point to controller
    c = h.Children ( i ) ;
    
    % Remove vertical position
    c.Position( 2 ) = c.Position ( 2 )  -  y ;
    
  end % reposition
  
  
  %-- Find maximum position of controls --%
  
  % Set figure and all children to have units of pixels
  set ( [ h ; h.Children ] , 'Units' , 'pixels' )
  
  % Use this as maximum
  y = 0 ;
  
  % Check all child controllers
  for  i = 1 : numel ( h.Children )
    
    % Point to controller
    c = h.Children ( i ) ;
    
    % Compute right hand position
    x = c.Position ( 1 )  +  c.Position ( 3 ) ;
    
    % Get maximum
    if  y  <  x  ,  y = x ;  end
    
  end % max right hand
  
  % Set figure width
  h.Position( 3 ) = y ;
  
  % Now find top control
  c = findobj ( h , 'Tag' , 'type' ) ;
  
  % Find maximum height
  y = c.Position ( 2 )  +  c.Position ( 4 ) ;
  
  % And set figure height
  h.Position( 4 ) = y ;
  
  
  %%% Reveal figure %%%
  
  h.Visible = 'on' ;
  
  
end % metptbgui


%%% Callbacks %%%

% Screen type popup menu callback
function  type_cb ( h , ~ )
  
  % Figure handle
  f = h.Parent ;
  
  % Set type of stimulus
  f.UserData.type = h.Value ;
  
end % type_cb


% Screen contrast edit callback
function  contrast_cb ( h , ~ )
  
  % Figure handle
  f = h.Parent ;

  % Convert entry to a double
  d = str2double (  h.String  ) ;
  
  % Check if number is valid
  if  numcheck ( d , 1 )
    
    % Not valid , get stored contrast string
    h.String = num2str ( f.UserData.contrast ) ;
    
    % Quit
    return
    
  end % invalid
  
  % Number is valid , save internally
  f.UserData.contrast = d ;
  
end % contrast_cb


% Timeout duration edit callback
function  tout_cb ( h , ~ )
  
  % Figure handle
  f = h.Parent ;
  
  % Outcome index
  i = h.UserData ;
  
  % Convert entry to a double
  d = str2double (  h.String  ) ;
  
  % Check if number is valid
  if  numcheck ( d , [] )
    
    % Restore saved value to string
    h.String = num2str (  f.UserData.tout ( i )  ) ;
    
    % Then quit
    return
    
  end % invalid
  
  % Number is valid , save internally
  f.UserData.tout( i ) = d ;
  
end % tout_cb


% Timeout screen switch button callback. Third argument is optional and
% defaults to true, saying whether or not to execute Screen Flip. The
% fourth argument is optional and defaults to false, saying whether or not
% to restore the random number generator state to its value before
% generating the timeout screen.
function  switch_cb ( h , ~ , flpflg , rngflg )
  
  % Check flip flag
  if  nargin  <  3  ,  flpflg = true ;  end
  
  % Check random number generator flag
  if  nargin  <  4  ,  rngflg = false ;  end
  
  % Figure handle
  f = h.Parent ;
  
  % Figure's user data
  s = f.UserData ;
  
  % Action depends on state of the switch
  if  s.switch
    
    % Switch is on , simply replace the button's string to off
    h.String = 'off' ;
    
    % And reset the background colour, if that was changed
    if  s.type  <  3
      
      for  e = s.eyebuf
        if  s.stereo
          Screen (  'SelectStereoDrawBuffer'  ,  s.winptr  ,  e  ) ;
        end
        Screen ( 'FillRect' , s.winptr , s.backgnd ) ;
      end
      
    end % reset bak colour
    
    % Guarantee that the button is up
    h.Value = 0 ;
    
  else
    
    % Switch is off. Start by flipping string to on.
    h.String = 'on' ;
    
    % RNG state flag is modified by the type of stimulus. If not noise or
    % lines then keep flag low, since RNG not used.
    rngflg = rngflg  &&  2 < s.type ;
    
    % Difference in colour between background and either lightest or
    % darkest at given contrast
    dc = min (  [ 1 - s.backgnd ; s.backgnd ]  ,  []  ,  1  )  *  ...
      s.contrast ;
    
    % Lightest colour
    l = s.backgnd  +  dc ;
    
    % Darkest colour
    d = s.backgnd  -  dc ;
    
    % Remember random number generator state when noise or lines stimulus
    % is in use
    if  rngflg  ,  srng = rng  ;  end
    
    % Select and draw the timout stimulus
    switch  s.type
      
      % Black and blank screens
      case  { 1 , 2 }
        
        % Determine colour based on type 1 - black , 2 - blank
        c = ( s.type - 1 )  *  s.contrast ;
        
        % Set background colour
        for  e = s.eyebuf
          if  s.stereo
            Screen (  'SelectStereoDrawBuffer'  ,  s.winptr  ,  e  ) ;
          end
          Screen ( 'FillRect' , s.winptr , c ) ;
        end
        
      % Noise
      case  3
        
        % Colour difference expanded to full range
        dc = 2  *  dc ;
        
        % Generate noise image assuming greyscale background
        i = dc ( 1 )  *  rand (  s.w  ,  s.h  )  +  d ( 1 ) ;
        
        % Create Psych Toolbox texture object from image ...
        t = Screen (  'MakeTexture'  ,  s.winptr  ,  i  ,  ...
          []  ,  []  ,  2  ) ;
        
        % ... and draw it to frame buffer        
        for  e = s.eyebuf
          if  s.stereo
            Screen (  'SelectStereoDrawBuffer'  ,  s.winptr  ,  e  ) ;
          end
          Screen (  'DrawTexture'  ,  s.winptr  ,  t  ,  []  ,  ...
            [ 0 , 0 , s.w , s.h ]  ) ;
        end
        
        % Free to clear texture from memory
        Screen (  'Close'  ,  t  ) ;
        
      % Random lines
      case  4
        
        % Number of lines to make
        N = 100 ;
        
        % Generate positions
        xy = rand (  2  ,  2 * N  ) ;
        
        % And scale them to screen size
        xy( 1 , : ) = xy( 1 , : )  *  s.w ;
        xy( 2 , : ) = xy( 2 , : )  *  s.h ;
        
        % Generate a colour matrix
        c = [  d( : )  ,  d( : )  ,  l( : )  ,  l( : )  ] ;
        c = repmat (  c  ,  1  ,  N / 2  ) ;
        
        % Draw all lines
        for  e = s.eyebuf
          if  s.stereo
            Screen (  'SelectStereoDrawBuffer'  ,  s.winptr  ,  e  ) ;
          end
          Screen ( 'DrawLines' , s.winptr, xy , 5 , c ) ;
        end
        
    end % draw stim
    
    % Restore random number generator state when noise or lines stimulus
    % is in use
    if  rngflg  ,  rng ( srng )  ;  end
    
    % Guarantee that the button is down
    h.Value = 1 ;
    
  end % switch action
  
  % Masking square enabled
  if  s.photor.msk
    
    % Draw square
    for  e = s.eyebuf
      if  s.stereo
        Screen (  'SelectStereoDrawBuffer'  ,  s.winptr  ,  e  ) ;
      end
      Screen ( 'FillRect' , s.winptr , s.photor.mskclu , s.photor.mskrec );
    end
    
  end % msk square
  
  % Flip switch state
  f.UserData.switch = ~ s.switch ;
  
  % Now flip the screen
  if  flpflg  ,  Screen (  'Flip'  ,  s.winptr  ) ;  end
  
end % switch_cb


%%% Subroutines %%%

% Check number validity , returns true if not valid
function  i = numcheck ( d , h )
  
  % Check whether value is scalar real double of 0 or more. No NaN or Inf.
  i = isnan ( d )  ||  isinf ( d )  ||  ~ isscalar ( d )  ||  ...
    ~ isreal ( d )  ||  ~ isa ( d , 'double' )  ||  d < 0 ;
  
  % Higher bound not given , return now
  if  isempty ( h )  ,  return  ,  end
  
  % Check that higher bound not exceeded
  i = i  ||  h  <  d ;
  
end % numcheck

