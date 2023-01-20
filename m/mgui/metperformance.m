
function  [ h , update , reset , recover , close ] = metperformance
% 
% [ h , update , reset , recover , close ] = metperformance
% 
% Matlab Electrophysiology Toolbox GUI. Creates a MET Performance GUI that
% plots the percentage of the subject's responses that fall in one of two
% categories in one plot and the reaction times in another. In each plot,
% the independent variable on the x-axis is an independently scheduled task
% variable.
%
% By default the response categories are correct and failed, with the
% number of correct responses being plotted. However, the user may define a
% circular response region on the screen in terms of degrees of visual
% field. Trials when the subject looked at or touched the response field
% shortly before the final stimulus target was identified will be
% categorised as one response ; trials when this did not happen will be
% categorised as another ; only correct and failed trials are used for
% custom responses. In this case, the percentage of trials when the
% response field was hit will be plotted.
% 
% The reaction time plot can be based on either correct trials, failed
% trials, or both. Reaction time is taken to be the duration from onset of
% the final non-end state to the moment that the last stimulus targeting
% event occured.
%
% Right-click to open the properties panel. This panel is blocked when
% trials are running.
% 
% Returns row vector of handles to blocked controls in h.UserData.blockcntl
% 
% NOTE: Looks for metperformance.csv in the met/m/mgui directory. This will
%   be a MET .csv parameter file that gives default values for this MET
%   GUI. Parameters include:
%   
%   taskvar - String naming the task variable to use for the x-axis. This
%     is only applied if a task variable with that name is in use by the
%     current session, and if that variable is independent and scheduled.
%     Thus, this is an advisory parameter that may not be used.
%   correct - Non-zero if percentage correct is to be plotted. If zero,
%     then custom response is automatically selected and the default
%     response field is loaded, until it is replaced by the user.
%   resp_x - x-axis coordinate of response region, in degrees of visual
%     field relative to the trial origin. Standard Cartesian coordinates.
%   resp_y - y-axis coordinate of response region, in degrees of visual
%     field relative to the trial origin. Standard Cartesian coordinates.
%   resp_frad - Formation circle radius.
%   resp_fang - Formation circle angle. In degrees.
%   resp_rad - Radius of response region around the given x-y coordinate.
%   rt_trials - Must be a string. Either 'correct', 'failed', or 'both'
%     saying which set of trials to use in determining reaction time.
% 
% Written by Jackson Smith - March 2017 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  % MET controller constants
  global  MC  MCC
  
  % If these haven't been set yet then set them
  if  isempty ( MC  )  ,  MC  = met ( 'const' , 1 )  ;  end
  if  isempty ( MCC )  ,  MCC = metctrlconst         ;  end
  
  
  %%% Return MET GUI function handles %%%
  
  update = @fupdate ;
   reset = @freset ;
 recover = @frecover ;
   close = @fclose ;

	
	%%% Constants %%%
  
  % Title bar
  TITBAR = 'MET Performance' ;
  
  % Default parameter list , and numeric parameters
  DEFLST = { 'taskvar' , 'correct' , 'resp_x' , 'resp_y' , 'resp_rad' , ...
    'resp_frad' , 'resp_fang' , 'rt_trials' } ;
  DEFNUM = { 'correct' , 'resp_x' , 'resp_y' , 'resp_frad' , ...
    'resp_fang' , 'resp_rad' } ;
  
  % Valid strings for rt_trials
  VALSTR = { 'correct' , 'failed' , 'both' } ;
  
  % Default parameter file
  DEFNAM = fullfile (  MCC.GUIDIR  ,  'metperformance.csv'  ) ;
  
  % Load defaults
  D = metreadcsv ( DEFNAM , DEFLST , DEFNUM ) ;
  
  % Default task variable must be a string
  if  ~ ischar ( D.taskvar )  ||  ~ isvector ( D.taskvar )
    
    meterror (  'metperformance.csv: taskvar must be a string'  )
    
  % Radius values must be positive
  elseif  D.resp_frad  <  0  ||  D.resp_rad  <  0
    
    meterror (  [ 'metperformance.csv: resp_frad and resp_rad must ' , ...
      'not be less than zero' ]  )
    
  % Check rt_trials string
  elseif  ~ any ( strcmp(  D.rt_trials  ,  VALSTR  ) )
    
    meterror (  [ 'metperformance.csv: rt_trials must be one of the ' , ...
      'following - %s' ]  ,  strjoin ( VALSTR , ' , ' )  )
    
  end % check defaults
  
  
  %-- Common graphics object properties --%
  
  UIPANEL = { 'BackgroundColor' , 'k' , 'BorderType' , 'none' } ;
  
  AXES = { 'Color' , 'none' , 'Box' , 'off' , 'XColor' , 'w' , ...
    'YColor' , 'w' , 'LineWidth' , 1 , 'TickDir' , 'out' , ...
    'XGrid' , 'on' , 'YGrid' , 'on' , 'GridColor' , 'w' , ...
    'NextPlot' , 'add' } ;
  
  UICTXT = { 'Style' , 'text' , 'BackgroundColor' , 'none' , ...
    'ForegroundColor' , 'w' , 'Tag' , 'properties' , ...
    'HorizontalAlignment' , 'left' } ;
  
  TABSTR = sprintf ( [ 'Defines a circular region on screen\n' , ...
                       'in degrees of visual field. The x-\n' , ...
                       'and y-coordinate is relative to the\n' , ...
                       'trial''s origin. fradius and fangle\n' , ...
                       'together provide polar coordinates\n' , ...
                       'for the point on an invisible formation\n' , ...
                       'circle that is centred on the x & y\n' , ...
                       'coordinate. This point on the formation\n' , ...
                       'circle is where the response region\n' , ...
                       'is centred. radius refers to the response\n' , ...
                       'region, not the formation circle.' ] ) ;
                     
	TABCOL = { 'x_coord' , 'y_coord' , 'fradius' , 'fangle' , 'radius' } ;
  
  
  %%% Generate figure %%%
  
  % Initialise UserData struct. D holds defaults loaded from
  % metperformance.csv. blockcntl is a vector of graphics objects that must
  % be disabled when the trial runs. sd points to the subset of task
  % variables that are independently scheduled. taskvar is the string name
  % of the variable that is being used to test performance. xval is the
  % set of the named variable's unique scheduled values, ordered ascending,
  % that appear on the x-axis of the performance plots. Nc & Nf are vectors
  % the size of xval that count the number of correct and failed trials
  % observed using each value in xval. Nr is the number of custom responses
  % that were observed for each value in xval. RTc and RTf are the sets of
  % reaction times observed on correct and failed trials for each value of
  % xval. pcorr is the percent-correct flag, which is true if percent
  % correct is to be plotted and false if the percent of custom responses
  % is shown instead. rtset names the reaction time trial set to use, being
  % either 'correct', 'failed', or 'both'. custresp is a
  % struct containing the definition of the response region ; this has the
  % x and y coordinate of the centre of the response region relative to the
  % trial origin, and the square of its radius.
  s = struct ( 'D' , D , 'blockcntl' , gobjects ( 0 ) , 'var' , [] , ...
    'taskvar' , '' , 'xval' , [] , 'Nc' , [] , 'Nf' , [] , 'Nr' , [] , ...
    'RTc' , [] , 'RTf' , [] , 'pcorr' , [] , 'rtset' , '' , ...
    'custresp' , struct( 'x' , [] , 'y' , [] , 'r2' , [] ) ) ;
  
  % Make figure
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Visible' , 'off' , 'DockControls' , 'off' , 'UserData' , s ) ;
  
  
  %%% UI panels %%%
  
  % Data panel
  c.data = uipanel ( 'Parent' , h , 'Visible' , 'off'  , ...
    'Tag' , 'data' , UIPANEL{ : } ) ;
  
  % Properties panel
  c.properties = uipanel ( 'Parent' , h , 'Visible' , 'on' , ...
    'ForegroundColor' , 'w' , 'Title' , 'Properties' , ...
    'Tag' , 'properties' , ...
    'Position' , [ 0.025 , 0.025 , 0.95 , 0.95 ] , UIPANEL{ : } ) ;
  
  
  %%% Data panel graphics objects %%%
  
  % Right-click context menu
  c.data.UIContextMenu = uicontextmenu ( 'Tag' , 'data' ) ;
  
  % Right-click menu item
  uimenu ( c.data.UIContextMenu , 'Label' , 'Properties' , ...
    'Callback' , @datmenu_cb )
  
  % Percent response plot
  a = subplot ( 2 , 1 , 1 , 'Parent' , c.data , AXES{ : } , ...
    'YLim' , [ 0 , 100 ] , 'YTick' , 0 : 25 : 100 , ...
    'YTickLabel' , { 0 , [] , 50 , [] , 100 } , ...
    'UIContextMenu' , c.data.UIContextMenu , 'Tag' , 'percent' ) ;
  
  ylabel ( a , '% response (bin c.i.)' )
  
  % Reaction time plot
  a = subplot ( 2 , 1 , 2 , 'Parent' , c.data , AXES{ : } , ...
    'UIContextMenu' , c.data.UIContextMenu , 'Tag' , 'rt' ) ;
  
  ylabel ( a , 'Reaction time (ms)' )
  xlabel ( a , '< none >' )
  
  % We need to inform the user how to get to properties, since neither
  % figures nor axes have tool-tip strings
  u = uicontrol ( c.data , 'Style' , 'text' , ...
    'String' , 'right-click for properties' , UICTXT { 1 : end - 2 } , ...
    'FontSize' , 8 , 'Units' , 'normalized' , ...
    'HorizontalAlignment' , 'right' , 'Tag' , 'data' ) ;
  
  % Place instruction string
  u.Position( 3 : 4 ) = 1.1  *  u.Extent( 3 : 4 ) ;
  u.Position( 1 : 2 ) = [  1 - u.Position( 3 )  ,  0  ] ;
  clear  u
  
  
  %%% Properties panel graphics objects %%%
  
  
  %-- X-axis variable drop-down menu's label --%
  u.xvar = uicontrol ( c.properties , UICTXT{ : } , ...
    'String' , 'X-axis variable' ) ;
  
  % Make it wide enough to hold its label
  u.xvar.Position( 3 : 4 ) = 1.1 * u.xvar.Extent( 3 : 4 ) ;
  u.xvar.Units = 'normalized' ;
  
  % Place control
  u.xvar.Position( 1 : 2 ) = [ 0 , 0.95 - u.xvar.Extent( 4 ) ] ;
  
  
  %-- Task variable drop-down menu --%
  
  u.tvar = uicontrol ( c.properties , 'Style' , 'popupmenu' , ...
    'BackgroundColor' , 'none' , 'ForegroundColor' , 'w' , ...
    'String' , { '<none>' } , 'Tag' , 'properties' , ...
    'Units' , 'normalized' , 'Callback' , @tvar_cb ) ;
  
  % Place menu
  u.tvar.Position( 1 : 3 ) = [ 0 , ...
    u.xvar.Position( 2 ) - u.tvar.Position( 4 ) , u.xvar.Position( 3 ) ] ;
  
  
  %-- Response type radio buttons --%
  
  u.rbres = mkradgrp (  c.properties  ,  @rbres_cb  ,  ...
    'Response type'  ,  { 'Correct' , 'Custom' }  ,  u.xvar  ) ;
  
  
  %-- Reaction time trial set radio buttons --%
  
  u.rbrt = mkradgrp (  c.properties  ,  @rbrt_cb  ,  ...
    'RT trial type'  ,  { 'Correct' , 'Failed' , 'Both' }  ,  u.rbres  ) ;
  
  
  %-- Done button --%
  
  u.done = uicontrol ( c.properties , 'Style' , 'pushbutton' , ...
    'BackgroundColor' , 'none' , 'ForegroundColor' , 'w' , ...
    'String' , 'Done' , 'Tag' , 'properties' , ...
    'Callback' , @done_cb , 'Units' , 'normalized' ) ;
  
  % Place control
  u.done.Position( 1 ) = sum (  u.rbrt.Position( [ 1 , 3 ] )  ) ;
  u.done.Position( 2 ) = sum (  u.rbrt.Position( [ 2 , 4 ] )  )  -  ...
    u.done.Position( 4 ) ;
  
  
  %-- Centre top row of controls --%
  
  % Find horizontal offset
  hoff = ( 1  -  sum (  u.done.Position( [ 1 , 3 ] )  ) )  /  2 ;
  
  % Minimum vertical position
  mver = 1 ;
  
  % Add to controls
  for  F = { 'xvar' , 'tvar' , 'rbres' , 'rbrt' , 'done' }  ,  f = F{ 1 } ;
    
    % Horizontal shift
    u.( f ).Position( 1 ) = u.( f ).Position( 1 )  +  hoff ;
    
    % Get minimum vertical position
    if  u.( f ).Position( 2 )  <  mver
      mver = u.( f ).Position( 2 ) ;
    end
    
  end % hor shift
  
  
  %-- Custom response --%
  
  % Label
  u.crtxt = uicontrol ( c.properties , UICTXT{ : } , ...
    'String' , 'Response region' , 'Visible' , 'off' ) ;
  
  % Make it wide enough to hold its label
  u.crtxt.Position( 3 : 4 ) = 1.1 * u.crtxt.Extent( 3 : 4 ) ;
  u.crtxt.Units = 'normalized' ;
  
  % Input table
  u.crtab = uitable ( c.properties , 'Visible' , 'off' , ...
    'BackgroundColor' , [ 0.35 , 0.35 , 0.35  ] , ...
    'ForegroundColor' , 'w' , 'Units' , 'normalized' , ...
    'ColumnEditable' , true , 'TooltipString' , TABSTR , ...
    'Tag' , 'properties' , 'Data' , cell( size( TABCOL ) ) , ...
    'RowName' , [] , 'ColumnName' , TABCOL' , ...
    'ColumnFormat' , repmat( { 'numeric' } , size( TABCOL ) ) , ...
    'CellEditCallback' , @crtab_cb ) ;
  
  % Position label
  u.crtxt.Position( 1 ) = u.xvar.Position ( 1 ) ;
  u.crtxt.Position( 2 ) = mver  -  u.crtxt.Position ( 4 )  -  0.05 ;
  
  % And then the table
  u.crtab.Position( 1 ) = u.crtxt.Position( 1 ) ;
  u.crtab.Position( 3 ) = sum (  u.done.Position( [ 1 , 3 ] )  )  -  ...
    u.crtab.Position( 1 ) ;
  u.crtab.Position( 4 ) = 2  *  u.crtab.Extent( 4 ) ;
  u.crtab.Position( 2 ) = u.crtxt.Position( 2 )  -  u.crtab.Position( 4 ) ;
  
  % Adjust column widths
  u.crtab.Units = 'pixels' ;
  u.crtab.ColumnWidth = num2cell (  u.crtab.Position( 3 )  /  ...
    numel ( TABCOL )  *  ones ( size( TABCOL ) )  ) ;
  
  
  %-- Link controls --%
  
  % Response type button group needs link to custom response controls
  u.rbres.UserData = [ u.crtxt , u.crtab ] ;
  
  % Done button needs quick pointers to popup menu and custom response
  % table
  u.done.UserData = struct ( 'tvar' , u.tvar , 'crtab' , u.crtab ) ;
  
  % Get list of controls that are blocked during trials , make it a row
  % vector
  h.UserData.blockcntl = findobj ( h , 'Type' , 'uicontrol' , ...
    'Tag' , 'properties' ) ;
  h.UserData.blockcntl = reshape (  h.UserData.blockcntl  ,  ...
    1  ,  numel ( h.UserData.blockcntl )  ) ;
  
  
  %-- Apply default values --%
  
  % Get flags
  h.UserData.pcorr = D.correct ;
  h.UserData.rtset = D.rt_trials ;
  
  % Apply flags to radio buttons
  appflg ( h )
  
  % Set table values
  u.crtab.Data = ...
    [ D.resp_x , D.resp_y , D.resp_frad , D.resp_fang , D.resp_rad ] ;
  
  % Compute response region
  h.UserData.custresp = respreg (  u.crtab  ) ;
  
  
end % metperformance


%%% MET GUI functions %%%


function  drawnew = fupdate ( h , sd , bd , td , ~ , tbuf )
%
% drawnew = update ( h , sd , bd , td , cbuf , tbuf )
% 
% The job of fupdate is to mainly to gather information about the previous
% trial before calling a generic plotting function.
%
  
  
  %%% Global constants %%%
  
  % MET constants and controller constants
  global  MC  MCC
  
  % 'eye' shared memory column indices
   T = MCC.SHM.EYE.COLIND.TIME   ;
  XL = MCC.SHM.EYE.COLIND.XLEFT  ;
  YL = MCC.SHM.EYE.COLIND.YLEFT  ;
  XR = MCC.SHM.EYE.COLIND.XRIGHT ;
  YR = MCC.SHM.EYE.COLIND.YRIGHT ;
  
  % MET signal identifiers
  MSID = MCC.MSID ;
  
  
  %%% Check environment %%%
  
  % Assume no change to plot
  drawnew = false ;

  % Name of the task variable that MET Performance is monitoring
  tvar = h.UserData.taskvar ;
  
  % Column in the deck of trials that represents chosen task variable
  ivar = strcmp (  tvar  ,  bd.varnam  ) ;
  
  % Name data in separate variables
  msig = tbuf.msig ;
  i = 1 : msig.i ;
  sig = msig.b ( i , msig.sig ) ;
  crg = msig.b ( i , msig.crg ) ;
  tim = msig.b ( i , msig.tim ) ;
  
  % Index of the mstop signal
  istop = sig  ==  MSID.mstop ;
  
  % If there is no valid task variable selection, the monitored task
  % variable is not used by the current block of trials, or there is no
  % trial stop MET signal then quit.
  if  isempty ( tvar )  ||  ~ any ( ivar )  ||  ~ any (  istop  )  ||  ...
      isnan ( bd.deck( 1 , ivar ) )
    return
  end % update conditions
  
  
  %%% Handle trial outcome %%%
  
  % First , determine how the trial ended. Get associated UserData fields.
  switch  MC.OUT {  crg ( istop )  ,  1  }
    
    % Valid outcomes
    case  'correct'  ,  n  =  'Nc' ;  rt = 'RTc' ;
    case  'failed'   ,  n  =  'Nf' ;  rt = 'RTf' ;
      
    otherwise
      
      % Trial was ignored, broken, or aborted. There is nothing to update.
      return
    
  end % trial outcome
  
  
  %-- Tally number of correct/failed by category --%
  
  % Determine the index of the task variable's value
  v = h.UserData.xval  ==  bd.deck( 1 , ivar ) ;
  
  % Tally outcome by task-variable value
  h.UserData.( n )( v ) = h.UserData.( n )( v )  +  1 ;
  
  
  %-- Asses custom response --%
  
  % Index of the last mtarget MET signal , says when a stimulus was last
  % targeted before the trial ended
  j = find (  sig  ==  MSID.mtarget  ,  1  ,  'last'  ) ;
  
  % Time of the last targeting event
  ttrg = tim ( j ) ;
  
  % Find eye or touchscreen/mouse position at this point in time if the
  % 'eye' shared memory was buffered
  if  isfield ( tbuf , 'eye' )  &&  ( tbuf.eye.i_m  ||  tbuf.eye.i_b )
    
    % Point to trial buffer
    eye = tbuf.eye ;
    
    % Touchscreen/mouse positions provided, they take precedence over eyes
    if  eye.i_m
      
        j = eye.m( 1 : eye.i_m , T )  ==  ttrg ;
      pos = eye.m( j , [ XL , YL ] ) ;
      
    % Eye positions provided
    elseif  eye.i_b
      
        j = eye.b( 1 : eye.i_b , T )  ==  ttrg ;
      pos = [  eye.b( j , [ XL , YL ] )  ;  eye.b( j , [ XR , YR ] )  ] ;
      
    % No positions buffered , use a point that will never fall in the hit
    % region
    else
      
      pos = inf ( 1 , 2 ) ;
      
    end
    
    % Subtract trial origin , then hit region centre
    pos( : , 1 ) = ...
      pos( : , 1 )  -  td.origin ( 1 )  -  h.UserData.custresp.x ;
    pos( : , 2 ) = ...
      pos( : , 2 )  -  td.origin ( 2 )  -  h.UserData.custresp.y ;
    
    % Did selected position(s) fall within radius of hit region?
    if  all (  sum (  pos .^ 2  ,  2  )  <=  h.UserData.custresp.r2  )
      
      % Yes , then we can tally up one more custom response
      h.UserData.Nr( v ) = h.UserData.Nr( v )  +  1 ;
      
    end % hit region
    
  end % eye & touch/mouse position trial buffer
  
  
  %-- Get reaction time --%
  
  % Find all task logic state transitions that occurred before the last
  % targeting event
  j = sig  ==  MSID.mstate  &  tim  <  ttrg ;
  
  % Get the sets of state identifiers and transition times
  istate = crg ( j ) ;
  tstate = tim ( j ) ;
  
  % The last transition to a non-end state
  i = find (  istate  <  sd.logic.( td.logic ).istate.correct  ,  ...
    1  ,  'last'  ) ;
  
  % If there is such a state then it should have started before the final
  % stimulus targeting event
  if  ~ isempty ( i )  &&  tstate ( i )  <=  ttrg
    
    % Compute reaction time , convert from seconds to milliseconds
    h.UserData.( rt ){ v } = ...
      [  h.UserData.( rt ){ v }  ,  1e3 * ( ttrg - tstate( i ) )  ] ;
    
  end
  
  
  %%% Plot the results %%%
  
  plotdat ( h )
  
  % Request drawnow
  drawnew = true ;
  
  
end % fupdate


function  freset ( h , v )
%
%  Expects v to be a 2 element cell , first element is string 'sd' , 'bd' ,
%  or 'td' saying what kind of descriptor , second element is descriptor
%
  
  
  %%% Handle descriptor %%%
  
  switch  v { 1 }
    
    case  'sd'
      
      % List of task variables , popup menu
      tvar = findobj ( h , 'Type' , 'uicontrol' , ...
          'Style' , 'popupmenu' , 'Tag' , 'properties' ) ;
        
      % Point to current set of task variables
      var = v{ 2 }.var ;
      
      % Update task variable lists
      newtvarlist ( h , tvar , var )
      
    case  'reset'
      
      % Size of x-axis value vector
      s = size (  h.UserData.xval  ) ;
      
      % Reset trial counters
      h.UserData.Nc = zeros (  s  ) ;
      h.UserData.Nf = zeros (  s  ) ;
      h.UserData.Nr = zeros (  s  ) ;

      % New reaction time distribution accumulators
      h.UserData.RTc = cell (  s  ) ;
      h.UserData.RTf = cell (  s  ) ;

      % Find data axes
      apr = findobj ( h , 'Type' , 'axes' , 'Tag' , 'percent' ) ;
      art = findobj ( h , 'Type' , 'axes' , 'Tag' , 'rt'      ) ;

      % Clear axes
      cla ( apr )  ,  cla ( art )
      
  end % handle descriptors
  
end % freset


function  frecover ( h , d )
% 
% recover ( h , d ) saves recovery data in the current session
% directory at the end of each trial if d{ 1 } is 'save'. Or recovery data
% is retrieved if d{ 1 } is 'load'. d{ 2 } is always the MET GUI recovery
% directory for the current session.
% 
  
  % Constants , the set of field to save or load
  C = { 'var' , 'taskvar' , 'xval' , 'Nc' , 'Nf' , 'Nr' , 'RTc' , ...
    'RTf' , 'pcorr' , 'rtset' , 'custresp' } ;
  
  % Get path to recovery file
  f = fullfile (  d { 2 }  ,  'metperformance.mat'  ) ;
  
  % Find parameter controls: task var popup menu, response type button
  % group, rt trial set button group, hit region table control
   tvar = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
    'Tag' , 'properties' ) ;
  rbres = findobj ( h , 'Type' , 'uibuttongroup' , ...
    'Title' , 'Response type' ) ;
   rbrt = findobj ( h , 'Type' , 'uibuttongroup' , ...
    'Title' , 'RT trial type' ) ;
  crtab = findobj ( h , 'Type' , 'uitable' , 'Tag' , 'properties' ) ;
  
  % Handle request
  switch  d { 1 }
    
    case  'save'
      
      % It is necessary to name the struct to reference , so point to user
      % data with a transition variable
      s = h.UserData ;
      
      % Remove unwanted fields
      s = rmfield (  s  ,  setdiff( fieldnames ( s ) , C )  ) ; %#ok
      
      % Parameter control values
      parcon.tvar  = tvar.Value ;
      parcon.rbres = rbres.SelectedObject.String ;
      parcon.rbrt  = rbrt.SelectedObject.String ;
      parcon.crtab = crtab.Data ; %#ok
      
      % Save subset of fields as variables
      save (  f  ,  'parcon'  ,  's' )
      
    case  'load'
      
      % File does not exist , so quit
      if  ~ exist ( f , 'file' )  ,  return  ,  end
      
      % Stored data returned in a struct
      L = load (  f  ) ;
      parcon = L.parcon ;  s = L.s ;
      
      % Place in user data fields
      for  F = C  ,  f = F { 1 } ;
        
        h.UserData.( f ) = s.( f ) ;
        
      end
      
      % No task variable was selected , so don't try to set controls
      if  isempty ( h.UserData.taskvar )  ,  return  ,  end
      
      % Set parameter control values
      tvar.String = fieldnames ( h.UserData.var ) ;
      tvar.Value = parcon.tvar ;
      rbres.SelectedObject = findobj ( rbres , 'String' , parcon.rbres ) ;
       rbrt.SelectedObject = findobj (  rbrt , 'String' , parcon.rbrt  ) ;
      crtab.Data = parcon.crtab ;
      
      % Re-plot retreived data
      plotdat ( h )
      
  end % switch functions
  
end % frecover


function  fclose ( h )
  
  % Delete the figure , bypass close request callback
  delete ( h )
  
end % mgclose


%%% Callbacks %%%

% The Properties menu item must flip the visibility of the panels
function  datmenu_cb ( ~ , ~ )
  
  % Find figure of running callback
  f = gcbf ;
  
  % Find panels
  data = findobj ( f , 'Type' , 'uipanel' , 'Tag' , 'data' ) ;
  prop = findobj ( f , 'Type' , 'uipanel' , 'Tag' , 'properties' ) ;
  
  % Swap visibilities
  data.Visible = 'off' ;
  prop.Visible = 'on'  ;
  
end % datmenu_cb


% Task variable popup menu callback. This will reset the data plot x-axes
% as well as the figure's internal record-keeping data.
function  tvar_cb ( h , ~ )
  
  % Callback figure , can't use gcbf because tvar_cb is called directly ,
  % elsewhere
  f = h.Parent.Parent ;
  
  % Reaction time axes
  art = findobj ( f , 'Type' , 'axes' , 'Tag' , 'rt' ) ;
  
  % Current task variable name
  n = h.String {  h.Value  } ;
  
  % Store current task variable name
  f.UserData.taskvar = n ;
  
  % Set x-axis label
  xlabel (  art  ,  strrep( n , '_' , '\_' )  )
  
  % Get unique set of task variable values
  v = unique (  f.UserData.var.( n ).value  ) ;
  
  % Store in user data
  f.UserData.xval = v ;
  
  % Execute MET GUI reset
  freset ( f , { 'reset' , [] } )
  
end % tvar_cb


% Response type radio button group. Controls visibility of custom response
% controls
function  rbres_cb ( h , d )
  
  % Callback figure. Not using gcbf because rbres_cb might be called by
  % other code, then gcbf returns [].
  f = h.Parent.Parent ;
  
  % Point to currently selected radio button
  b = d.NewValue ;
  
  % Action depends on button's string , also raise or lower figure's
  % userdata flag
  switch  b.String
    
    case  'Correct'
      set ( h.UserData , 'Visible' , 'off' )
      f.UserData.pcorr = true ;
      
    case  'Custom'
      set ( h.UserData , 'Visible' , 'on' )
      f.UserData.pcorr = false ;
      
  end
  
  % Plot the change
  plotdat ( f )
  
end % rbres_cb


% Reaction time trial-type radio button group callback.
function  rbrt_cb ( h , d )
  
  % Callback figure
  f = h.Parent.Parent ;
  
  % Point to currently selected radio button
  b = d.NewValue ;
  
  % Set figure's userdata flag
  f.UserData.rtset = lower (  b.String  ) ;
  
  % Plot the change
  plotdat ( f )
  
end % rbrt_cb


% Custom response region table callback , runs when a value is changed
function  crtab_cb ( h , d )
  
  % Row and column indeces of edited cell
  r = d.Indices ( 1 ) ;
  c = d.Indices ( 2 ) ;
  
  % Get column header string
  cs = h.ColumnName { c } ;
  
  % Check if number is empty, inf, nan, or imaginary. Invalid number.
  invaln = isempty ( d.NewData )  ||     isinf ( d.NewData )  ||  ...
              isnan ( d.NewData )  ||  ~ isreal ( d.NewData ) ;
	
	% Then check if this is a radius value that is less than zero
  radltz = any ( strcmp(  cs  ,  { 'fradius' , 'radius' }  ) )  &&  ...
    d.NewData  <  0 ;
  
  % If either terrible offense is made then replace the new value with the
  % old value
  if  invaln  ||  radltz  ,  h.Data( r , c ) = d.PreviousData ;  end
  
end % crtab_cb


% Swap visibility of panels , but only if properties are correctly set
function  done_cb ( h , ~ )
  
  % Callback figure
  f = gcbf ;
  
  % First check that popup menu is set to something other than <none>
  s = h.UserData.tvar.String{  h.UserData.tvar.Value  } ;
  if  strcmp (  s  ,  '<none>'  )  ,  return  ,  end
  
  % Then compute the response region ...
  c = respreg (  h.UserData.crtab  ) ;
  
  % ... and determine if this has changed from the existing one
  if  f.UserData.custresp.x   ~=  c.x  ||  ...
      f.UserData.custresp.y   ~=  c.y  ||  ...
      f.UserData.custresp.r2  ~=  c.r2
    
    % It has changed , assign new response region
    f.UserData.custresp = c ;
    
  end
  
  % Find panels
  data = findobj ( f , 'Type' , 'uipanel' , 'Tag' , 'data' ) ;
  prop = findobj ( f , 'Type' , 'uipanel' , 'Tag' , 'properties' ) ;
  
  % Swap visibilities
  data.Visible = 'on' ;
  prop.Visible = 'off' ;
  
end % done_cb


%%% Subroutines %%%

% Makes a button group and populates it with radio buttons
function  g = mkradgrp ( par , bgcb , tit , str , ref )
  
  % Button group
  g = uibuttongroup ( par , 'BackgroundColor' , 'k' , ...
    'ForegroundColor' , 'w' , 'Title' , tit , ...
    'BorderType' , 'none' , 'Units' , 'pixels' , ...
    'SelectionChangedFcn' , bgcb ) ;
  
  % Add radio buttons
  b = gobjects ( size(  str  ) ) ;
  
  for  i = 1 : numel ( str )
    
    % Make radio button
    b( i ) = uicontrol ( g , 'Style' , 'radiobutton' , ...
      'BackgroundColor' , 'none' , 'ForegroundColor' , 'w' , ...
      'String' , str{ i } , 'Tag' , 'properties' , 'Units' , 'pixels' ) ;
    
    % Adjust radio button size to encompass extents
    b( i ).Position( 3 : 4 ) = 1.5  *  b( i ).Extent( 3 : 4 ) ;
    
  end % rad butt
  
  % Place radio buttons one on top of the other , all lined up on left
  b( end ).Position( 1 : 2 ) = 0 ;
  
  for  i = numel ( b ) - 1 : -1 : 1
    
    b( i ).Position( 1 : 2 ) = ...
      [  0  ,  sum(  b( i + 1 ).Position( [ 2 , 4 ] )  )  ] ;
    
  end
  
  % Adjust button group height
  g.Position( 4 ) = ( numel( b ) + 0.5 )  *  b( 1 ).Position( 4 ) ;
  
  % Adjust button group width
  g.Units = 'characters' ;
  g.Position( 3 ) = 1.25  *  numel ( g.Title ) ;
  
  % Place group horizontal position
  g.Units = 'normalized' ;
  g.Position( 1 ) = 0.05  +  sum (  ref.Position( [ 1 , 3 ] )  ) ;
  
  % Determine vertical position
  g.Position( 2 ) = sum ( ref.Position( [ 2 , 4 ] ) )  -  g.Position( 4 ) ;
  
end % mkradgrp


% Apply figure's flags to radio button groups
function  appflg ( h )
  
  % Find radio button groups
  rbres = findobj ( h , 'Type' , 'uibuttongroup' , ...
    'Title' , 'Response type' ) ;
  rbrt  = findobj ( h , 'Type' , 'uibuttongroup' , ...
    'Title' , 'RT trial type' ) ;
  
  % Response type string
  if  h.UserData.pcorr  ,  n = 'Correct' ;  else  n = 'Custom' ;  end
  
  % Find and set corresponding button
  rbres.SelectedObject = findobj ( rbres , 'String' , n ) ;
  
  % Run response type callback
  rbres.SelectionChangedFcn(  rbres  ,  ...
    struct ( 'NewValue' , rbres.SelectedObject )  )
  
  % Same steps for RT trial set
  n = h.UserData.rtset ;  n( 1 ) = upper (  n( 1 )  ) ;
  rbrt.SelectedObject = findobj ( rbrt , 'String' , n ) ;
  rbrt.SelectionChangedFcn(  rbrt  ,  ...
    struct ( 'NewValue' , rbrt.SelectedObject )  )
  
end % appflg


% Calculate the response region from values given in the table
function  c = respreg (  crtab  )
  
  % Make a parameter struct from the table
  p = [  crtab.ColumnName'  ;  num2cell( crtab.Data )  ] ;
  p = struct (  p { : }  ) ;
  
  % Calculate the centre of the response region
  c.x = p.fradius  *  cosd (  p.fangle  )  +  p.x_coord ;
  c.y = p.fradius  *  sind (  p.fangle  )  +  p.y_coord ;
  
  % And map radius value , squared
  c.r2 = p.radius  ^  2 ;
  
end % respreg


% Does the work of updating new task variable lists , and checking this
% against the former or default selection. If needed , it will run the
% popup menu's callback to reset the plots.
function  newtvarlist ( h , tvar , var )
  
  % Currently selected variable
  curvar = tvar.String {  tvar.Value  } ;

  % Retrieve task variable dependencies
  dep = metgetfields ( var , 'depend' ) ;

  % And task var distribution types , along with variable names
  [ dist , vnam ] = metgetfields ( var , 'dist' ) ;

  % Find independent scheduled variables
  i = strcmp ( dep , 'none' )  &  strcmp ( dist , 'sched' ) ;

  % Valid task variables found
  if  any ( i )

    % Keep only valid variables and their names
    var = rmfield (  var  ,  vnam ( ~i )  ) ;
    vnam = vnam ( i ) ;

    % Store this set of variables for future use
    h.UserData.var = var ;

    % Set list of task variables
    tvar.Value = 1 ;
    tvar.String = vnam ;

    % Look to see if either the previously selected variable or if the
    % default selection is in the new list
    for  V = { curvar , h.UserData.D.taskvar }

      % Check list
      i = strcmp (  V { 1 }  ,  vnam  ) ;

      % Variable was not found , check next possible selection
      if  ~ any ( i )  ,  continue  , end

      % Variable was found , highlight this value in the list
      tvar.Value = find ( i ) ;

      % If this was the previously selected value then we need to check
      % that the unique scheduled value sets are the same
      if  strcmp ( V{ 1 } , curvar )

        % Get new set of unique scheduled values
        v = unique (  var.( V{ 1 } ).value  ) ;

        % If the sets are the same then we don't need to refresh the
        % plots. We can end the function call here.
        if  numel ( h.UserData.xval )  ==  numel ( v )  &&  ...
            all (  h.UserData.xval  ==  v  )

          return

        end % same scheduled sets of values
        
      end % previously selected value

      % Don't check any more variables
      break

    end % look for vars
    
    % There is a new set of x-axis values to use. Refresh the figure's user
    % data by running the popup menu's callback.
    tvar.Callback (  tvar  ,  []  )

  % No valid task variables were found
  else

    % Set task variable menu to default selection
    tvar.Value = 1 ;
    tvar.String = { '<none>' } ;
    
    % Delete task variable name from figure's user data. This way, the
    % update function will do nothing.
    h.UserData.taskvar = '' ;

  end

  % There are no valid task variables , or no existing selection was
  % found. We need to switch to the parameter panel.
  if  ~ any ( i )

    % Find panels
    data = findobj ( h , 'Type' , 'uipanel' , 'Tag' , 'data' ) ;
    prop = findobj ( h , 'Type' , 'uipanel' , 'Tag' , 'properties' ) ;

    % Make properties panel visible
    data.Visible = 'off' ;
    prop.Visible = 'on' ;

  end % no task vars
  
end % newtvarlist


% Computes new plot and updates data axes
function  plotdat ( h )
  
  % No task variable selected , so don't run this
  if  isempty ( h.UserData.taskvar )  ,  return  ,  end
  
  % Point to data
  d = h.UserData ;
  
  % Find data axes
  apr = findobj ( h , 'Type' , 'axes' , 'Tag' , 'percent' ) ;
  art = findobj ( h , 'Type' , 'axes' , 'Tag' , 'rt'      ) ;
  
  % Clear axes
  cla ( apr )  ,  cla ( art )
  
  
  %-- Compute percent responses --%
  
  % Total number of trials per category
  N = d.Nc  +  d.Nf ;
  
  % Percent correct
  if  d.pcorr
    
    % Use the number of correct trials as the number of responses
    R = d.Nc ;
    
  else
    
    % Use the number of custom responses
    R = d.Nr ;
    
  end
  
  % Compute probability of success for each category
  y = R  ./  N ;
  
  % Estimate the error for each category , this is a basic type of binomial
  % confidence interval
  e = norminv ( 1 - 0.05/2 )  *  sqrt ( y .* ( 1 - y ) ./ N ) ;
  
  % From probabilities to percentages
  y = 100 * y ;
  e = 100 * e ;
  
  % Plot data
  plot (  apr  ,  [ d.xval ; d.xval ]  ,  [ y - e ; y + e ]  ,  'w'  ,  ...
    d.xval  ,  y  ,  'wo:'  )
  
  
  %-- Plot reaction time distributions --%
  
  % Get reaction time distributions according to which trial set is being
  % used
  switch  d.rtset
    
    case  'correct'  ,  RT = d.RTc ;
    case   'failed'  ,  RT = d.RTf ;
    case     'both'  ,  RT = cellfun (  @( c , f )  [ c , f ]  ,  ...
        d.RTc  ,  d.RTf  ,  'UniformOutput'  ,  false  ) ;
      
  end
  
  % Compute mean reaction time
  y = cellfun (  @mean  ,  RT  ) ;
  
  % Standard error
  e = cellfun (  @( rt )  std( rt ) / sqrt( numel( rt ) )  ,  RT  ) ;
  
  % Plot data
  plot (  art  ,  [ d.xval ; d.xval ]  ,  [ y - e ; y + e ]  ,  'w'  ,  ...
    d.xval  ,  y  ,  'wo:'  )
  
  
  %-- Set x-axis limits --%
  
  % Only one value , can't define limits
  if  numel ( d.xval )  ==  1  ,  return  ,  end
  
  % Find limits
  xmin = min( d.xval ) ;
  xlim = [ -0.025 , 1.025 ]  *  ( max( d.xval )  -  xmin )  +  xmin ;
  
  % Assign them to axes
  set (  [ apr , art ]  ,  'XLim'  ,  xlim  )
  
  
end % plotdat

