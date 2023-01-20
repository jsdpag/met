
function  [ h , update , reset , recover , close ] = metrftuning
% 
% [ h , update , reset , recover , close ] = metrftuning
% 
% Matlab Electrophysiology Toolbox GUI. Creates MET RF Tuning GUI. This
% allows the firing rate for each unit to be computed as a function of a
% scheduled independent task variable. The amount of firing rate modulation
% over task variable values is summarised by an unbalanced, one-way ANOVA
% F-vale. This is computed for each unit and shown, ordered ascending, in
% the top bar-plot. The larger bottom-plot shows the spkikes per second per
% task variable value for a selected unit ; the GUI can automatically show
% the best-tuned unit i.e. max F-value. Drop-down menus allow for the
% selection of a specific channel and unit.
% 
% Right-click and select 'Properties' to view controls for setting the
% analysis window. This window is used to compute the firing rate for each
% unit in each correct or failed trial. The start and end time points are
% each given as a task logic state and millisecond offset. Thus the
% analysis window can either be a fixed width relative to one state, or
% variable width relative to two states. The task variable against which to
% compute tuning is also specified. A special selection is available in the
% state name popup menus, 'corr/fail' ; this says that the reference point
% must be the time that the trial ended, rather than a state transition
% time. The properties panel is unavailable when trials are running.
% 
% The default analysis window can be given in the accompanying
% metrftuning.csv file in the met/m/mgui directory. This is a MET .csv
% parameter file with parameters:
% 
%   taskvar - String naming default task variable to use, if available.
%   
%   chan - Either a number giving an index of the front end channel, from
%     1 to 128. Or 'max' if the channel with the maximum F-value is to be
%     used. Always a string.
%   
%   unit - Similar to chan, but gives the spike classification index, from
%     0 to 5. 'max' when unit with maximum F-value in selected channel
%     should be used. Always a string.
%   
%   state1 - Names the state that the start of the analysis window is
%     relative to, if available.
%   
%   msoffset1 - Gives the offset in milliseconds from state1. Can be a
%     positive or negative number
% 
%   state2, msoffset2 - The same, but for the end of the analysis window.
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
  TITBAR = 'MET RF Tuning' ;
  
  % Default parameter list , and numeric parameters
  DEFLST = { 'taskvar' , 'chan' , 'unit' , 'state1' , 'msoffset1' , ...
    'state2' , 'msoffset2' } ;
  DEFNUM = { 'msoffset1' , 'msoffset2' } ;
  
  % Unit maximum F-value string
  MAXFVL = 'max' ;
  
  % Maximum number of channels and units from cbmex trialdata
  MAXCHN = MCC.SHM.NSP.MAXCHN ;
  MAXUNI = MCC.SHM.NSP.MAXUNI ;
  
  % Default parameter file
  DEFNAM = fullfile (  MCC.GUIDIR  ,  'metrftuning.csv'  ) ;
  
  % Load defaults
  D = metreadcsv ( DEFNAM , DEFLST , DEFNUM ) ;
  
  % Valid unit selection
  if ( ~strcmp( D.chan , MAXFVL ) && ninval( D.chan , 1 , MAXCHN ) )  ||...
     ( ~strcmp( D.unit , MAXFVL ) && ninval( D.unit , 1 , MAXCHN ) )
    
    meterror (  [ 'metrftuning: .csv params ''chan'' and ''unit'' ' , ...
      'must be either ''%s'' or values between 1 and %d or 0 and %d' , ...
        ' , respectively' ]  ,  MAXFVL  ,  MCC.SHM.NSP.MAXCHN  ,  ...
          MCC.SHM.NSP.MAXUNI  )
    
  % Valid task variable and state selection
  elseif  isempty(  regexp( D.taskvar , MCC.REX.VALNAM , 'once' )  )  ||...
          isempty(  regexp( D.state1  , MCC.REX.VALNAM , 'once' )  )  ||...
          isempty(  regexp( D.state2  , MCC.REX.VALNAM , 'once' )  )
        
    meterror (  [ 'metrftuning: .csv params ''taskvar'' , ''state1''' , ...
      ' and ''state2'' must all have valid state names i.e. follow ' , ...
        'regular expression %s' ]  ,  MCC.REX.VALNAM  )
    
  % Valid offset values
  elseif  any ( mod(  [ D.msoffset1 , D.msoffset2 ]  ,  1  ) )
    
    meterror (  'metrftuning: .csv ''msoffset'' params must be integers'  )
    
  end % check default params
  
  
  %-- Common graphics object properties --%
  
  UIPANEL = { 'BackgroundColor' , 'k' , 'BorderType' , 'none' } ;
  
  AXES = { 'Color' , 'none' , 'Box' , 'off' , 'XColor' , 'w' , ...
    'YColor' , 'w' , 'LineWidth' , 1 , 'TickDir' , 'out' , ...
    'XGrid' , 'on' , 'YGrid' , 'on' , 'GridColor' , 'w' , ...
    'NextPlot' , 'add' } ;
  
  UICTXT = { 'Style' , 'text' , 'BackgroundColor' , 'none' , ...
    'ForegroundColor' , 'w' , 'HorizontalAlignment' , 'left' , ...
    'Units' , 'normalized' } ;
  
  UICEDT = { 'Style' , 'edit' , 'BackgroundColor' , 'none' , ...
    'ForegroundColor' , 'w' , 'HorizontalAlignment' , 'right' , ...
    'Units' , 'normalized' } ;
  
  UIPOPM = { 'Style' , 'popupmenu' , 'BackgroundColor' , 'none' , ...
    'ForegroundColor' , 'w' , 'Units' , 'normalized' } ;
  
  
  %%% Generate figure %%%
  
  % D are defaults from metrftuning.csv.
  % recflg is raised when recovery data is loaded , causes the next call to
  %   freset ( h , { 'sd' , sd } ) to lower the flag and then return with
  %   no further action
  % var is the subset of the current session descriptor's task variables
  %   that are scheduled independent.
  % logic is the current set of all available task logics.
  % task is the list of all current tasks.
  % taskvar is the currently selected task variable name.
  % xval is the vector of all unique task variable values, sorted
  %   ascending.
  % nval is the number of trials observed for each unique value of the task
  %   variable i.e. for each element of xval.
  % state1 and 2 name the task logic states to peg the start and end of the
  %   analysis window to.
  % msoffset1 and 2 are the number of milliseconds relative to state1 and 2
  %   that the window starts and stops. 
  % chan and unit each give the channel and unit index ( each starting from
  %   1 ) of the firing rates that will be plotted in the turnig curve.
  % fval the unbalanced, one-way ANOVA F-value has a row for each channel
  %   and a column for each unit ; this is -1 when no valid F-value is
  %   available.
  %
  % ANOVA statistics:
  %
  %   The following accumulate values that are used to compute F-values,
  %   means, and standard deviations of the spike rates. Here, group means
  %   group of spike rates, being the set of spike rates observed for a
  %   given value of the task variable, and tracked separately for each
  %   channel and unit.
  %
  % grpsum is the sum of spike rates per group. Groups are indexed along
  %   the third dimention while channel and unit are indexed along the
  %   first and second dimensions. Along with .nval, this can be used to
  %   compute the mean spike rate.
  % grpssq is the same as grpsum, but the spike rates are squared before
  %   adding them.
  % varsum is used to accumulate an estimate of the variance, trial by
  %   trial. This is done by adding the square of the difference between
  %   the current trial's spike rate and the current estimated mean spike
  %   rate. Of course, the estimate of the mean will be continuously
  %   refined. The only purpose, here, is to provide some idea of what the
  %   error in the tuning curve looks like without committing large amounts
  %   of time and memory. When the first value is added, it will simply be
  %   the observed spike rate, assuming a Poisson random variable. This
  %   will have the same layout as grpsum.
  %
  s = struct ( 'D' , D , 'recflg' , false , 'var' , [] , 'logic' , [] , ...
    'task' , [] , 'taskvar' , '' , 'xval' , [] , 'nval' , [] , ...
    'state1' , '' , 'msoffset1' , D.msoffset1 , 'state2' , '' , ...
    'msoffset2' , D.msoffset2 , 'chan' , 0 , 'unit' , 0 , ...
    'fval' , -ones( MAXCHN , MAXUNI + 1 ) , 'grpsum' , [] , ...
    'grpssq' , [] , 'varsum' , [] ) ;
  
  % Apply default channel and unit
  if  ~ strcmp ( D.chan , MAXFVL )
    s.chan = str2double ( D.chan ) ;
  end
  
  if  ~ strcmp ( D.unit , MAXFVL )
    s.unit = str2double ( D.unit ) + 1 ;
  end
  
  % Make figure
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Visible' , 'off' , 'DockControls' , 'off' , 'UserData' , s ) ;
  
  
  %%% UI panels %%%
  
  % Data panel
  p.data = uipanel ( 'Parent' , h , 'Visible' , 'off'  , ...
    'Tag' , 'data' , UIPANEL{ : } ) ;
  
  % Right-click context menu
  p.data.UIContextMenu = uicontextmenu ( 'Tag' , 'data' ) ;
  
  % Right-click menu item
  uimenu ( p.data.UIContextMenu , 'Label' , 'Properties' , ...
    'Callback' , @datmenu_cb )
  
  % Properties panel
  p.properties = uipanel ( 'Parent' , h , 'Visible' , 'on' , ...
    'ForegroundColor' , 'w' , 'Title' , 'Properties' , ...
    'Tag' , 'properties' , ...
    'Position' , [ 0.025 , 0.025 , 0.95 , 0.95 ] , UIPANEL{ : } ) ;
  
  
  %%% Data panel graphics objects %%%
  
  
  %-- Channel selector menu --%
  
	c.chnpop = popmenu ( UICTXT , UIPOPM , p.data , 0 , 1 , ...
    'Front-end channel' , 'chan' , @chnpop_cb ) ;
  
  % UserData holds field name of figure's UserData to be changed
  c.chnpop.UserData = 'chan' ;
  
  % Populate set of menu options. Bear in mind that both data-panel popup
  % menus have 'max fval' as the first entry i.e. their Value 1. Other
  % functions assume that if c.chnpop.Value is 1 then they should use the
  % maximum F-value.
  c.chnpop.String = [  { 'max fval' }  ,  ...
    arrayfun(  @( v )  sprintf( '%d' , v )  ,  1 : MAXCHN  ,  ...
      'UniformOutput'  ,  false  )  ] ;
  
  
  %-- Unit selector menus --%
  
  c.unipop = popmenu ( UICTXT , UIPOPM , p.data , ...
    sum(  c.chnpop.Position( [ 1 , 3 ] )  )  +  0.02 , 1 , ...
      'Unit' , 'unit' , @chnpop_cb ) ;
  
  % UserData holds field name of figure's UserData to be changed
  c.unipop.UserData = 'unit' ;
  
  % Populate set of menu options
  c.unipop.String = [  { 'max fval' }  ,  ...
    arrayfun(  @( v )  sprintf( '%d' , v )  ,  0 : MAXUNI  ,  ...
      'UniformOutput'  ,  false  )  ] ;
    
  
  %-- Set default selection --%
  
  if  ~ strcmp ( D.chan , MAXFVL )
    c.chnpop.Value = s.chan  +  1 ;
  end
  
  if  ~ strcmp ( D.unit , MAXFVL )
    c.unipop.Value = s.unit  +  1 ;
  end
  
  
  %-- Data axes --%
  
  % Make container panel to contain them
  p.contain = uipanel ( 'Parent' , p.data , UIPANEL{ : } , ...
    'UIContextMenu' , p.data.UIContextMenu ) ;
  
  % Position it just under the selector controls
  p.contain.Position = [ 0 , 0 , 1 , 1 - ...
    max(  [ c.chnpop.Position( 4 ) , c.unipop.Position( 4 ) ]  ) ] ;
	
	% ANOVA F-value bar chart
  c.fvalax = subplot ( 3 , 1 , 1 , 'Parent' , p.contain , AXES{ : } , ...
    'Tag' , 'fval' , 'UIContextMenu' , p.data.UIContextMenu , ...
    'ButtonDownFcn' , @fvalax_cb ) ;
  
  % F-value chart's y-axis label
  ylabel ( c.fvalax , 'F-value' )
  
  % Tuning curve
  c.tunaxe = subplot ( 3 , 1 , 3 , 'Parent' , p.contain , AXES{ : } , ...
    'Tag' , 'tuning' , 'UIContextMenu' , p.data.UIContextMenu ) ;
  
  % Adjust size
  c.tunaxe.Position( 4 ) = 2 * c.tunaxe.Position( 4 ) ;
  
  % Y-axis label
  ylabel ( c.tunaxe , sprintf ( 'Average\nspk/sec (sdev)' ) )
  
  
  %%% Properties panel graphics objects %%%
  
  
  %-- Task variable --%
  
  c.tskvar = popmenu ( UICTXT , UIPOPM , p.properties , 0 , 0.95 , ...
    'Task variable' , 'taskvar' , @tskvar_cb ) ;
  
  % Populate set of menu options
  c.tskvar.String = { '<none>' } ;
  
  % Resize
  c.tskvar.Position( 3 ) = 2 * c.tskvar.Position( 3 ) ;
  
  
  %-- State selection titles --%
  
  % Analysis window time point control titles
  c.txtsta = uicontrol ( p.properties , UICTXT{ : } , 'String' , 'State' );
  c.txtoff = uicontrol ( p.properties , UICTXT{ : } , ...
    'String' , 'Offset (ms)' ) ;
  
  % Make it wide enough to hold its label
  c.txtsta.Position( 3 : 4 ) = 1.1 * c.txtsta.Extent( 3 : 4 ) ;
  c.txtoff.Position( 3 : 4 ) = 1.1 * c.txtoff.Extent( 3 : 4 ) ;
  
  % Set to normalised units
  set ( [ c.txtsta , c.txtoff ] , 'Units' , 'normalized' )
  
  % Place controls
  c.txtsta.Position( 2 ) = c.tskvar.Position( 2 ) - ...
    c.txtsta.Position( 4 ) - 0.05 ;
  c.txtoff.Position( 2 ) = c.txtsta.Position( 2 ) ;
  
  
  %-- Analysis window controls --%
  
  % Task logic state selection menus
  c.state1 = popmenu ( UICTXT , UIPOPM , p.properties , 0 , ...
    c.txtsta.Position( 2 ) - 0.01 , 'Start' , 'state1' , ...
      @state_cb ) ;
    
  c.state2 = popmenu ( UICTXT , UIPOPM , p.properties , 0 , ...
    c.state1.Position( 2 ) - 0.01 , 'End' , 'state2' , ...
      @state_cb ) ;
    
  % Give them user data indicating the state index number , 1 or 2
  c.state1.UserData = 1 ;
  c.state2.UserData = 2 ;
  
  % Populate set of menu options
  c.state1.String = { '<none>' } ;
  c.state2.String = { '<none>' } ;
  
  % Resize
  c.state1.Position( 3 ) = 2 * c.state1.Position( 3 ) ;
  c.state2.Position( 3 ) = 2 * c.state2.Position( 3 ) ;
  
  % Align
  c.state1.Position( 1 ) = ...
    max ( [ c.state1.Position( 1 ) , c.state2.Position( 1 ) ] ) ;
  c.state2.Position( 1 ) = c.state1.Position( 1 ) ;
  
  % Millisecond offset edit boxes
  c.msoffset1 = uicontrol ( p.properties , UICEDT{ : } , ...
    'Tag' , 'msoffset1' , 'Callback' , @edit_cb , ...
    'UserData' , D.msoffset1 , 'String' , num2str ( D.msoffset1 ) ) ;
  
  c.msoffset2 = uicontrol ( p.properties , UICEDT{ : } , ...
    'Tag' , 'msoffset2' , 'Callback' , @edit_cb , ...
    'UserData' , D.msoffset2 , 'String' , num2str ( D.msoffset2 )) ;
  
  % Resize
  c.msoffset1.Position( 3 ) = 1.25 * c.msoffset1.Position( 3 ) ;
  c.msoffset2.Position( 3 ) = 1.25 * c.msoffset2.Position( 3 ) ;
  
  % Position at ends of state selection menus
  c.msoffset1.Position( 1 : 2 ) = c.state1.Position( 1 : 2 ) ;
  c.msoffset2.Position( 1 : 2 ) = c.state2.Position( 1 : 2 ) ;
  
  c.msoffset1.Position( 1 ) = ...
    c.msoffset1.Position( 1 ) + c.state1.Position( 3 ) + 0.02 ;
  c.msoffset2.Position( 1 ) = ...
    c.msoffset2.Position( 1 ) + c.state2.Position( 3 ) + 0.02 ;
  
  % Align titles
  c.txtsta.Position( 1 ) = c.state1.Position( 1 ) ;
  c.txtoff.Position( 1 ) = c.msoffset1.Position( 1 ) ;
  
  
  %-- Done button --%
  
  c.done = uicontrol ( p.properties , 'Style' , 'pushbutton' , ...
    'BackgroundColor' , 'none' , 'ForegroundColor' , 'w' , ...
    'String' , 'Done' , 'Tag' , 'properties' , ...
    'Callback' , @done_cb , 'Units' , 'normalized' ) ;
  
  % Resize
  c.done.Position( 3 : 4 ) = 1.1 * c.done.Extent( 3 : 4 ) ;
  
  % Position
  c.done.Position( 1 : 2 ) = c.msoffset2.Position( 1 : 2 ) ;
  c.done.Position( 1 ) = c.done.Position( 1 ) + ...
    c.msoffset2.Position( 3 ) - c.done.Position( 3 ) ;
  c.done.Position( 2 ) = c.done.Position( 2 ) - c.done.Position( 4 ) - ...
    0.05 ;
  
  
  %%% Blocked controls %%%
  
  % Get list of controls that are blocked during trials
  h.UserData.blockcntl = [  findobj( p.data , 'Type' , 'uicontrol' ) ;
    findobj( p.properties , 'Type' , 'uicontrol' )  ] ;
  
  % Make it a row vector
  h.UserData.blockcntl = reshape (  h.UserData.blockcntl  ,  ...
    1  ,  numel ( h.UserData.blockcntl )  ) ;
  
  
end % metrftuning


%%% MET GUI functions %%%


function  drawnew = fupdate ( h , sd , bd , ~ , ~ , tbuf )
%
% drawnew = update ( h , sd , bd , td , cbuf , tbuf )
%
  
  
  %%% Global variables %%%
  
  % MET and MET controller constants
  global  MC  MCC
  
  % MET signal identifier map
  MSID = MCC.MSID ;
  
  
  %%% Check environment %%%
  
  % Assume no change to plot
  drawnew = false ;
  
  % MET signals trial buffer
  msig = tbuf.msig ;
  
  % Pull out signal identifiers, cargos, and times
  sig = msig.b( 1 : msig.i , msig.sig ) ;
  crg = msig.b( 1 : msig.i , msig.crg ) ;
  tim = msig.b( 1 : msig.i , msig.tim ) ;
  
  % No task variable has been selected or no buffered nsp shm. Quit now.
  if  isempty ( h.UserData.taskvar )  ||  ~ isfield ( tbuf , 'nsp' )  ||...
      ~ tbuf.nsp.i  ||  ~ isfield ( tbuf.nsp , 'final' )
    return
  end
  
  % Trial neither correct nor failed
  mstop = sig  ==  MSID.mstop ;
  outcome = MC.OUT {  crg( mstop )  ,  1  } ;
  
  if  ~ any ( strcmp(  outcome  ,  { 'correct' , 'failed' }  ) )
    return
  end
  
  % We can now look for the current value of the task variable. First, find
  % the column of the trial deck that corresponds to the task variable.
  ivar = strcmp (  h.UserData.taskvar  ,  bd.varnam  ) ;
  
  % Now get the task variable value
  val = bd.deck( 1 , ivar ) ;
  
  % If the task variable is not used by this block, or its value is not
  % defined then quit
  if  ~ any ( ivar )  ||  isnan ( val )  ,  return  ,  end
  
  
  %%% Prepare NSP data %%%
  
  % nsp shared memory buffer , finalised by metgui
  nsp = tbuf.nsp.final ;
  
  % Locate front end channels ...
  fec = ~ cellfun (  @isempty  ,  ...
    regexp ( tbuf.nsp.label , MCC.SHM.NSP.SPKLAB )  ) ;
  
  % ... and get the channel index from the label
  chi = regexp(  tbuf.nsp.label( fec )  ,  '\d+$'  ,  'match'  ) ;
  chi = str2double (  [ chi{ : } ]  ) ;
  
  % Locate digital channel
  dig = strcmp ( tbuf.nsp.label , MCC.SHM.NSP.DINLAB ) ;
  
  % Point to digital input values
  vdig = nsp { dig , MCC.SHM.NSP.DINVAL - 1 } ;
  
  % Locate signal identifiers in digital input , and see which one is the
  % mstart signal , if any
  dsig = vdig <= MCC.SHM.NSP.SIGMAX  &  vdig == MSID.mstart ;
  
  % No mstart signal recorded or digin time values are missing , quit now
  if  ~ any ( dsig )
    
    met ( 'print' , 'metpsth: no nsp digin mstart signal' , 'E' )
    return
    
  % Size mismatch between digin signal times and values
  elseif  any (  size(  nsp{ dig , MCC.SHM.NSP.DINTIM - 1 }  )  ~=  ...
      size(  dsig  )  )
    
    met ( 'print' , 'metpsth: nsp digin time & value mismatch' , 'E' )
    return
    
  % What if we have the opposite problem and there are too many mstart
  % signals? Looks like there was lagging data from the last trial ...
  % REALLY lagging.
  elseif  sum ( dsig )  ~=  1
    
    met ( 'print' , 'metpsth: too many nsp digin mstart signals' , 'E' )
    
    % We take the last one
    dsig = find (  dsig  ,  1  ,  'last'  ) ;
    
  end % digin error checking
  
  % Now it is necessary to convert all buffered MET signals from local PTB
  % time to NSP time. Start by locating the mstart signal and zeroing all
  % signal times on that.
  mstart = sig  ==  MSID.mstart ;
  tim = tim  -  tim ( mstart ) ;
  
  % Add NSP mstart time , metcbmex should have converted from sample number
  % to seconds
  tim = tim  +  nsp{ dig , MCC.SHM.NSP.DINTIM - 1 }( dsig ) ;
  
  
  %%% Analysis window %%%
  
  % Allocate window tuple , values of -1 signal that time wasn't found
  w = [ 0 , 0 ] ;
  
  % Get the task logic state name to index mapping
  istate = sd.logic.(  ...
    sd.task.(  sd.var.(  h.UserData.taskvar  ).task  ).logic  ).istate ;
  
  % Find start and end times of analysis window relative to reference
  % events
  for  j = 1 : 2
    
    % UserData field names
     fstate = sprintf (    'state%d' , j ) ;
    foffset = sprintf ( 'msoffset%d' , j ) ;
    
    % Determine which kind of signal to find
    switch  h.UserData.( fstate )
      
      % Start state i.e. mstart signal
      case  'start'  ,  i = mstart ;
      
      % End state i.e. mstop signal
      case  'corr/fail'  ,  i = mstop ;
        
      % Not end state i.e. mstate signal
      otherwise  ,  i = sig  ==  MSID.mstate  &  ...
                        crg  ==  istate.( h.UserData.( fstate ) ) ;
        
    end
    
    % Time not found , quit now
    if  ~ any ( i )  ,  return  ,  end
    
    % Get relative time
    w( j ) = tim ( i )  +  h.UserData.( foffset ) ;
    
  end % analysis window times
  
  % Window duration
  d = diff ( w ) ;
  
  
  %%% Calculate firing rates %%%
  
  % Find which task variable value index
  i = h.UserData.xval  ==  val ;
  
  % Count one more trial in this group
  h.UserData.nval( i ) = h.UserData.nval( i )  +  1 ;
  
  % Compute and store latest spike rates
  spk = cellfun (  @( spk )  frate ( w , d , spk )  ,  nsp( fec , : )  ) ;
  
  
  %%% Accumulate ANOVA statistics %%%
  
  % Update the sum of spike rates
  h.UserData.grpsum( chi , : , i ) = ...
    h.UserData.grpsum( chi , : , i )  +  spk ;
  
  % Update the sum of squared spike rates
  h.UserData.grpssq( chi , : , i ) = ...
    h.UserData.grpssq( chi , : , i )  +  spk .^ 2 ;
  
  % Update the sum of squared differences i.e. the variance. If this is the
  % first trial observed then assume that the trial's spike rate is the
  % variance i.e. Poisson random variable
  if  h.UserData.nval( i )  ==  1
    
    h.UserData.varsum( chi , : , i ) = spk ;
    
  else
    
    % Squared difference to the mean
    spk = (  spk  -  ...
      h.UserData.grpsum( chi , : , i ) / h.UserData.nval( i )  )  .^  2 ;
    
    % Accumulate sum
    h.UserData.varsum( chi , : , i ) = ...
      h.UserData.varsum( chi , : , i )  +  spk ;
    
  end % variance
  
  
  %%% Unbalanced one-way ANOVA F-value %%%
  
  % Only compute F-value if every group has at least one sample firing rate
  if  all (  h.UserData.nval  )
    
    % Number of groups
    Ng = numel (  h.UserData.nval  ) ;
    
    % Number of samples per group
    Ns = reshape (  h.UserData.nval  ,  1  ,  1  ,  Ng  ) ;
    
    % Total number of samples, from all groups
    Nt = sum ( Ns ) ;
    
    % Sum of spike rates , per group
    Sg = h.UserData.grpsum( chi , : , : ) ;
    
    % Sum of squared spike rates , per group
    SgSq = h.UserData.grpssq( chi , : , : ) ;
    
    % Square of summed samples per group , divided by number of samples per
    % group , and summed over groups
    SSqSsNs = sum (  Sg .^ 2  ./  ...
      repmat ( Ns , numel( chi ) , size( Sg , 2 ) )  ,  3  ) ;
    
    % Sum of squares , treatments
    SST = SSqSsNs  -  sum ( Sg , 3 ) .^ 2  /  Nt ;

    % Sum of squares , errors
    SSE = sum (  SgSq  ,  3  )  -  SSqSsNs ;

    % Degrees of freedom , treatments
    DFT = Ng  -  1 ;

    % Degrees of freedom , errors
    DFE = Nt  -  Ng ;
    
    % F-value
    h.UserData.fval( chi , : ) = ( SST / DFT )  ./  ( SSE / DFE ) ;
  
  end % F-value
  
  
  %-- Find max F-value --%
  
  % Channel and unit selector popup menus
  chnpop = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
    'Tag' , 'chan' ) ;
  unipop = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
    'Tag' , 'unit' ) ;
  
  % Maximum F-value location
  fmax = max (  h.UserData.fval( : )  ) ;
  
  % Valid maximum F-value available
  fvalid = 0  <=  fmax ;
  
  % Determine which channel/unit is selected if max F-value is being used
  if  fvalid  &&  chnpop.Value  ==  1
    
    h.UserData.chan = ...
      find (  any( h.UserData.fval == fmax , 2 )  ,  1  ,  'first'  ) ;
    
  end
  
  if  fvalid  &&  unipop.Value  ==  1
    
    [ ~ , h.UserData.unit ] = ...
      max (  h.UserData.fval( h.UserData.chan , : )  ) ;
    
  end
  
  
  %%% Plot data %%%
  
  % Signal change to plot
  drawnew = true ;
  
  % Update F-value bar chart
  if  fvalid  ,  fvalplot ( h )  ,  end
  
  % And update the tuning curve plot
  tuneplot ( h )
  
  
end % fupdate


function  freset ( h , v )
%
%  Expects v to be a 2 element cell , first element is string 'sd' , 'bd' ,
%  or 'td' saying what kind of descriptor , second element is descriptor
%
  
  
  % Global MET controller constants
  global  MCC


  %%% Handle descriptor %%%
  
  switch  v { 1 }
    
    case  'sd'
      
      % Recovery flag is up. Lower it and return with no further action.
      if  h.UserData.recflg
        h.UserData.recflg = false ;
        return
      end
      
      % The new session descriptor
      sd = v{ 2 } ;
      
      
      %-- Find control handles --%
      
      % List of task variables , popup menu
      tvar = findobj ( h , 'Type' , 'uicontrol' , ...
          'Style' , 'popupmenu' , 'Tag' , 'taskvar' ) ;
      
      
      %-- Find set of scheduled independend task variables --%
        
      % Point to current set of task variables
      var = sd.var ;
      
      % Retrieve task variable dependencies
      dep = metgetfields ( var , 'depend' ) ;

      % And task var distribution types , along with variable names
      [ dist , vnam ] = metgetfields ( var , 'dist' ) ;

      % Find independent scheduled variables
      i = strcmp ( dep , 'none' )  &  strcmp ( dist , 'sched' ) ;
      
      % No valid task variables
      if  ~ any ( i )
        
        % Task logic state selector popup menus
        state1 = findobj ( h , 'Type' , 'uicontrol' , ...
            'Style' , 'popupmenu' , 'Tag' , 'state1' ) ;
        state2 = findobj ( h , 'Type' , 'uicontrol' , ...
            'Style' , 'popupmenu' , 'Tag' , 'state2' ) ;
        
        % Set popup menus to <none>
        set ( [ tvar , state1 , state2 ] , 'Value' , 1 , ...
          'String' , { '<none>' } )
        
        % Empty internal data
        h.UserData.taskvar = '' ;
        
        % Quit
        return
        
      end % no valid task vars
      
      % Keep only valid variables and their names
      var = rmfield (  var  ,  vnam ( ~i )  ) ;
      vnam = vnam ( i ) ;

      % Store this set of variables for future use ...
      h.UserData.var = var ;
      
      % Store the set of task logics
      h.UserData.logic = sd.logic ;
      
      % Store the set of tasks
      h.UserData.task = sd.task ;
      
      % Check whether previously selected task variable name exists in the
      % new set of independent scheduled task variables
      if  ~ any ( strcmp(  h.UserData.taskvar  ,  vnam  ) )
        
        % Empty internal data
        h.UserData.taskvar = '' ;
        
      end % old task var not in new set
      
      
      %-- Set task variable menu --%
      
      % Determine if any of the task variables match the default
      j = find (  strcmp ( h.UserData.D.taskvar , vnam )  ,  ...
        1  ,  'first'  ) ;
      
      % If not then choose the first variable in the list
      if  isempty ( j )  ,  j = 1 ;  end
      
      % Load task variable names into the task variable popup menu ...
      set ( tvar , 'String' , vnam , 'Value' , j )
      
      % ... and run its callback
      tvar.Callback ( tvar , [] )
      
      
    case  'reset'

      % Number of front end NSP channels and number of spike
      % classifications
      MAXCHN = MCC.SHM.NSP.MAXCHN ;
      MAXUNI = MCC.SHM.NSP.MAXUNI ;
  
      % X-axis values
      xval = h.UserData.xval ;
      
      % Number of values
      n = numel (  xval  ) ;
      
      % Reset the trial counter
      h.UserData.nval = zeros ( size(  xval  ) ) ;

      % Allocate new accumulators , these are used to sum up the firing
      % rates, squared firing rates, and variances trial-by-trial.
      h.UserData.grpsum = zeros (  MAXCHN  ,  MAXUNI + 1  ,  n  ) ;
      h.UserData.grpssq = zeros (  MAXCHN  ,  MAXUNI + 1  ,  n  ) ;
      h.UserData.varsum = zeros (  MAXCHN  ,  MAXUNI + 1  ,  n  ) ;

      % Reset F-value map
      h.UserData.fval( : ) = -1 ;
      
      % Clear F-value axes
      a = findobj ( h , 'Type' , 'axes' , 'Tag' , 'fval' ) ;
      cla ( a )
      
      % Clear tuning plot axes
      a = findobj ( h , 'Type' , 'axes' , 'Tag' , 'tuning' ) ;
      cla ( a )
      
      
  end % handle descriptors
  
end % freset


function  frecover ( h , d )
% 
% recover ( h , d ) saves recovery data in the current session
% directory at the end of each trial if d{ 1 } is 'save'. Or recovery data
% is retrieved if d{ 1 } is 'load'. d{ 2 } is always the MET GUI recovery
% directory for the current session.
% 
  
  
  %%% Constants %%%
  
  % UserData fields to save/load
  F = { 'var' , 'logic' , 'task' , 'taskvar' , 'xval' , 'nval' , ...
    'state1' , 'msoffset1' , 'state2' , 'msoffset2' , 'chan' , 'unit' , ...
    'fval' , 'grpsum' , 'grpssq' , 'varsum' } ;
  
  % Control's whose .String property should not be saved or loaded
  CFNOST = { 'chnpop' , 'unipop' } ;
  
  
  %%% Recovery file name %%%
  
  % Full path
  frec = fullfile (  d { 2 }  ,  'metrftuning.mat'  ) ;
  
  
  %%% Channel/Unit selectors %%%
  
  % Popup menus above the data axes
  c.chnpop = findobj ( h , 'Type' , 'uicontrol' , ...
    'Style' , 'popupmenu' , 'Tag' , 'chan' ) ;
  c.unipop = findobj ( h , 'Type' , 'uicontrol' , ...
    'Style' , 'popupmenu' , 'Tag' , 'unit' ) ;
  
  
  %%% Find property controls %%%
  
  % List of task variables , popup menu
  c.tvar = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
    'Tag' , 'taskvar' ) ;
  
  % Task logic state selector popup menus
  c.state1 = findobj ( h , 'Type' , 'uicontrol' , ...
    'Style' , 'popupmenu' , 'Tag' , 'state1' ) ;
  
  % Second state popup menu
  c.state2 = findobj ( h , 'Type' , 'uicontrol' , ...
    'Style' , 'popupmenu' , 'Tag' , 'state2' ) ;
  
  % Offset edit box 1
  c.msoffset1 = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'edit' , ...
    'Tag' , 'msoffset1' ) ;
  
  % Offset edit box 2
  c.msoffset2 = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'edit' , ...
    'Tag' , 'msoffset2' ) ;
  
  
  %%% Control prep %%%
  
  % Get row vector of field names
  CF = fieldnames (  c  ) ;
  CF = reshape (  CF  ,  1  ,  numel ( CF )  ) ;
  
  % Map to control field names ( in struc c ) of controls whose .String
  % value should be saved or loaded
  SAVSTR = [  CF  ;  num2cell( ~ ismember ( CF , CFNOST ) )  ] ;
  SAVSTR = struct (  SAVSTR { : }  ) ;
  
  
  %%% Handle recovery data %%%
  
  switch  d { 1 }
    
    case  'save'
      
      % Get a copy of GUI's user data
      s = h.UserData ;
      
      % All field names
      N = fieldnames ( s ) ;
      
      % Remove saved field names
      N = setdiff ( N , F ) ;
      
      % And remove un-saved fields from copy struct
      s = rmfield ( s , N ) ;
      
      % Add data for uicontrols
      for  F = CF  ,  f = F { 1 } ;
        
        % Save .String value if control not blacklisted , otherwise
        % guarantee an empty string place holder
        if  SAVSTR.( f )
          s.uicontrol.( f ).String = c.( f ).String ;
        else
          s.uicontrol.( f ).String = '' ;
        end
        
        % Always save control's Value
        s.uicontrol.( f ).Value  = c.( f ).Value  ;
        
      end % uicontrols
      
      % Write recovery file
      save ( frec , '-struct' , 's' )
      
    case  'load'
      
      % Recovery file not written yet , quit now
      if  ~ exist ( frec , 'file' )  ,  return  ,  end
      
      % Raise recovery flag
      h.UserData.recflg = true ;
      
      % Load recovery data into a struct
      s = load ( frec ) ;
      
      % Disperse saved fields into GUI's user data
      for  F = F  ,  f = F { 1 } ;
        h.UserData.( f ) = s.( f ) ;
      end % load saved fields
      
      % Disperse uicontrols data
      for  F = CF  ,  f = F { 1 } ;
        
        % Load control's .String value if not blacklisted
        if  SAVSTR.( f )
          c.( f ).String = s.uicontrol.( f ).String ;
        end
        
        % Always load control's .Value
        c.( f ).Value  = s.uicontrol.( f ).Value  ;
        
      end % uicontrols
      
      % Re-plot data
      fvalplot ( h )
      tuneplot ( h )
      
      % Make plots visible. First, find panels.
      datpan = findobj ( h , 'Type' , 'uipanel' , 'Tag' , 'data' ) ;
      propan = findobj ( h , 'Type' , 'uipanel' , 'Tag' , 'properties' ) ;

      % Then make sure that only the data panel is visible
      datpan.Visible = 'on'  ;
      propan.Visible = 'off' ;
      
  end % handle recovery data
  
  
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


% Front-end channel and unit selection pop-up menu callback in data panel
function  chnpop_cb ( h , ~ )
  
  % Calling figure
  f = h.Parent.Parent ;
  
  % Field name to change
  fn = h.UserData ;
  
  % Newly selected string
  s = h.String { h.Value } ;
  
  % Choose unit with maximum F-value
  if  strcmp ( s , 'max fval' )
    
    % Find channel with maximum F-value
    if  strcmp ( fn , 'chan' )

      [ ~ , f.UserData.( fn ) ] = ...
        max ( max(  f.UserData.fval  ,  []  ,  2  ) ) ;
      
      % Now find the unit selector
      h = findobj ( f , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
        'Tag' , 'unit' ) ;
      
      % Unit menu's selected string
      s = h.String { h.Value } ;
      
      % If unit selector wants automatic max fval then change fn to 'unit'
      % so that the maximum unit will be found
      if  strcmp ( s , 'max fval' )  ,  fn = 'unit' ;  end

    end

    % Find unit within channel that has maximum F-value
    if  strcmp ( fn , 'unit' )

      [ ~ , f.UserData.( fn ) ] = ...
        max (  f.UserData.fval(  f.UserData.chan  ,  :  )  ) ;

    end
    
  else
    
    % Convert string number to numeric value
    f.UserData.( fn ) = str2double ( s ) ;
    
    % Unit, we need to add 1 to get Matlab-style indexing
    if  strcmp ( fn , 'unit' )
      f.UserData.( fn ) = f.UserData.( fn )  +  1 ;
    end
    
  end
  
  % Update axes
  fvalplot ( f )
  tuneplot ( f )
  
end % chnpop_cb


% F-value axes button down callback. Uses mouse click on axes to select a
% specific channel and unit. Causes its tuning curve to be plotted.
function  fvalax_cb ( h , ~ )
  
  % The calling figure
  f = gcbf ;
  
  % Channel and unit selector popup menus
  chnpop = findobj ( f , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
    'Tag' , 'chan' ) ;
  unipop = findobj ( f , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
    'Tag' , 'unit' ) ;
  
  % If the popup menus are disabled then a trial is running and this
  % callback must end now
  if  strcmp (  chnpop.Enable  ,  'off'  )  ,  return  ,  end

  % The linear indeces of each unit , in the same order as the unit's
  % F-values are drawn in the axes
  i = h.UserData ;
  
  % Get x-axis value of click , minus one half , and rounded up to next
  % integer. This then becomes the ordinal index of the selected bar.
  j = ceil (  h.CurrentPoint ( 1 )  -  0.5  ) ;
  
  % If this is less than 1 or more than the number of drawn bars then quit
  if  j  <  1  ||  numel ( i )  <  j  ,  return  ,  end
  
  % Determine the channel and unit number from the linear index
  [ c , u ] = ind2sub (  size ( f.UserData.fval )  ,  i( j )  ) ;
  
  % No change , quit here
  if  f.UserData.chan == c  &&  f.UserData.unit == u  ,  return  ,  end
  
  % Set channel and unit
  f.UserData.chan = c ;
  f.UserData.unit = u ;
  
  % Update channel and unit selection in popup menus
  chnpop.Value = find (  strcmp( chnpop.String , num2str( c ) )  ,  1  ,...
    'first'  ) ;
  unipop.Value = find (  strcmp( unipop.String , num2str( u - 1 ) )  ,  ...
    1  ,  'first'  ) ;
  
  % Find F-value of the selected unit
  fval = f.UserData.fval ( c , u ) ;
  
  % Delete and replace rectangle highlighter
  delete ( findobj(  h  ,  'Type'  ,  'rectangle'  ) ) ;
  rectangle ( 'Parent' , h , 'Position' , [ j - 0.5 , 0 , 1 , fval ] ,...
    'EdgeColor' , 'none' , 'FaceColor' , 'r' )
  
  % At last, show the currently selected tuning curve
  tuneplot ( f )
  
end % fvalax_cb


% Task variable popup menu. Get unique set of task variable values and
% reset internal data structures.
function  tskvar_cb ( h , ~ )
  
  
  %-- Check selection --%
  
  % First, find calling figure
  f = h.Parent.Parent ;
  
  % Newly selected task variable name
  vnam = h.String { h.Value } ;
  
  % Quit immediately if selected string is <none> or if the selection
  % hasn't actually changed
  if  any ( strcmp(  vnam  , { '<none>' , f.UserData.taskvar }  ) )
    return
  end
  
  
  %-- New selection --%
  
  % Firing rate plot
  tunaxe = findobj ( f , 'Type' , 'axes' , 'Tag' , 'tuning' ) ;
  
  % Update x-axis label
  xlabel ( tunaxe , strrep ( vnam , '_' , '\_' ) )
  
  
  %-- Check task logic and value set --%
  
  % Get the new unique set of task variable values , ...
  xval = unique ( f.UserData.var.( vnam ).value ) ;
  
  % Find the new name of the task logic ...
  lnam = f.UserData.task.(  f.UserData.var.( vnam ).task  ).logic ;
  
  % ... and the name of the previously selected task logic
  if  isempty ( f.UserData.taskvar )
    lold = '' ;
  else
    lold = f.UserData.task.(  f.UserData.var.(  f.UserData.taskvar  ...
      ).task  ).logic ;
  end
  
  % Now we can save the new task variable name
  f.UserData.taskvar = vnam ;
  
  % New task logic is being used
  newlog = ~ strcmp ( lnam , lold ) ;
  
  % If the value set and task logic have not changed then no action is
  % necessary
  if  ~ newlog  &&  numel( xval ) == numel( f.UserData.xval )  &&  ...
      all (  xval  ==  f.UserData.xval  )
    return
  end
  
  % Otherwise, save the new task variable information
  f.UserData.xval = xval ;
  
  % Execute reset
  freset ( f , { 'reset' , [] } )
  
  % Set x-axis tick marks and x-axis limit
  tunaxe.XTick = xval ;
  
  if  numel( xval )  ==  1
    tunaxe.XLim = [ -0.025 , 0.025 ] * abs( xval )  +  xval ;
  else
    tunaxe.XLim = [ -0.025 , 1.025 ]  *  ...
      diff ( xval(  [ 1 , end ]  ) )  +  xval ( 1 ) ;
  end
  
  % Task logic has not changed , no further action
  if  ~ newlog  ,  return  ,  end
  
  
  %-- Update state name menus --%
  
  % Task logic state selector popup menus
  state1 = findobj ( f , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
    'Tag' , 'state1' ) ;
  
  % Get set of task logic state names, without end states. In place of end
  % states, put corr/fail. This signals that mstop times for correct and
  % failed trials should be used instead of mstate.
  snam = [  f.UserData.logic.( lnam ).nstate( 1 : end - 4 )  , ...
    { 'corr/fail' }  ] ;
  
  % See if any state matches default , otherwise default to start state
  j = find (  strcmp ( f.UserData.D.state1 , snam )  ,  1  ,  'first'  ) ;
  
  if  isempty ( j )  ,  j = 1 ;  end
  
  % Set menu options and value
  set ( state1 , 'String' , snam , 'Value' , j )
  
  % Then run callback
  state1.Callback ( state1 , [] )
  
  
end % tskvar_cb


% Task logic state selection popup menu callback. For setting the analysis
% window reference points
function  state_cb ( h , ~ )
  
  % Callback figure
  f = h.Parent.Parent ;

  % Get user data index. Tells us whether this is state 1 or state 2 i.e.
  % the start or end of the window.
  s = h.UserData ;
  
  % Build figure user data field names
  fstate = sprintf ( 'state%d' , s ) ;
  
  % Save the state name
  f.UserData.( fstate ) = h.String { h.Value } ;
  
  % If this is the first state then we need to handle the second state
  % popup menu , otherwise we can end here
  if  s  ==  2  ,  return  ,  end
  
  % Get the set of allowable task logic states, from state 1 to the end
  % states
  snam = h.String ( h.Value : end ) ;
  
  % Find second state popup menu
  state2 = findobj ( f , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
    'Tag' , 'state2' ) ;
  
  % Currently selected second state
  cstat2 = state2.String { state2.Value } ;
  
  % See if currently selected second state is there
  j = find (  strcmp( cstat2 , snam )  ,  1  ,  'first'  ) ;
  
  % If not then check whether the default second state is there
  if  isempty ( j )
    
    j = find (  strcmp( f.UserData.D.state2 , snam )  ,  1  ,  'first'  ) ;
    
    % It is not , default to the end state
    if  isempty ( j )  ,  j = numel ( snam ) ;  end
    
  end % find menu value
  
  % Save set of state names and selected state index in state 2 popup menu
  set ( state2 , 'String' , snam , 'Value' , j )
  
  % Run callback
  state2.Callback ( state2 , [] )
  
end % state_cb


% Millisecond offset edit box callback. Make sure that a scalar, real
% number was input. Converts from milliseconds to seconds of offset.
function  edit_cb ( h , ~ )
  
  % Convert new input to a number
  d = str2double ( h.String )  /  1e3 ;
  
  % Invalid entry
  if  isempty ( d )  ||  ~ isscalar ( d )  ||  isinf ( d )  ||  ...
      isnan ( d )  ||  ~ isreal ( d )
    
    % Revert to value pre-edit
    h.String = num2str ( h.UserData ) ;
    
  % Valid number
  else
    
    % Store numeric conversion in control's private data
    h.UserData = d ;
    
    % And also in the GUI's user data, for general access
    f = gcbf ;
    f.UserData.( h.Tag ) = d ;
    
  end
  
end % edit_cb


% Properties panel done button , switches back to data panel
function  done_cb ( ~ , ~ )
  
  % Figure
  f = gcbf ;
  
  % Find panels
  datpan = findobj ( f , 'Type' , 'uipanel' , 'Tag' , 'data' ) ;
  propan = findobj ( f , 'Type' , 'uipanel' , 'Tag' , 'properties' ) ;

  % Make sure we see the properties panel
  datpan.Visible = 'on'  ;
  propan.Visible = 'off' ;
  
end % done_cb


%%% Subroutines %%%

% Check if number is invalid. It is invalid and function returns true if
% value is not an integer between vmin and vmax.
function  i = ninval ( s , vmin , vmax )
  
  % Convert to numeric value
  v = str2double ( s ) ;

  % Determine validity of number
  i = mod ( v , 1 )  ||  v < vmin  ||  vmax < v  ;
  
end % ninval


% Make popup menu with label
function  pop = ...
  popmenu ( UICTXT , UIPOPM , parent , xref , yref , lab , tag , cb )
  
  % Unit menu label
  txt = uicontrol ( parent , UICTXT{ : } , 'String' , lab ) ;
  
  % Make it wide enough to hold its label
  txt.Position( 3 : 4 ) = 1.1 * txt.Extent( 3 : 4 ) ;
  
  % Place control
  txt.Position( 1 : 2 ) = [  xref  ,  yref - txt.Position( 4 )  ] ; 
  
  % Channel popup menu
  pop = uicontrol( parent , UIPOPM{ : } , 'Tag' , tag , 'Callback' , cb ) ;
    
	% Place control
  pop.Position( 1 : 3 ) = [  sum(  txt.Position( [ 1 , 3 ] )  )  ,  ...
    yref - pop.Position( 4 )  ,  1.5 * pop.Position( 3 )  ] ;
  
end % popmenu


% Computes firing rate for each unit
function  r = frate ( w , d , spk )
  
  % No spikes , rate is zero
  if  isempty ( spk )
    r = 0 ;
    return
  end
  
  % Locate spikes within the analysis window
  i = w ( 1 )  <=  spk  &  spk  <=  w ( 2 ) ;
  
  % Calculate firing rate
  r = sum ( i )  /  d ;
  
end % frate


% Plot the F-values
function  fvalplot ( h )
  
  % Locate F-value axes
  a = findobj ( h , 'Type' , 'axes' , 'Tag' , 'fval' ) ;
  
  % Find valid f-values , return the linear indeces
  i = find (  -1  <  h.UserData.fval ( : )  ) ;
  
  % No valid F-values , quit
  if  isempty ( i )  ,  return  ,  end
  
  % Clear the axes
  cla ( a )
  
  % Get valid f-values
  f = h.UserData.fval ( i ) ;
  
  % Sort F-values , ascending
  [ f , j ] = sort ( f ) ;
  
  % And re-order the linear index , save it for later
  i = i ( j ) ;
  a.UserData = i ;
  
  % Create bar graph
  bar ( a , 1 : numel ( f ) , f , 1 , 'EdgeColor' , 'none' , ...
    'FaceColor' , 'w' , ...
    'ButtonDownFcn' , @( ~ , ~ ) a.ButtonDownFcn( a , [] ) )
  
  % Set axis limits
  a.XLim = [ 0.5 , numel( f ) + 0.5 ] ;
  a.YLim = [ 0 , f( end ) ] ;
  
  % Determine the linear index of the selected channel
  sel = sub2ind (  size( h.UserData.fval )  ,  ...
    h.UserData.chan  ,  h.UserData.unit  ) ;
  
  % See where this unit is being represented in the bar graph
  j = find (  i  ==  sel  ,  1  ,  'first'  ) ;
  
  % Not represented or fvalue is insane, quit now
  if  isempty ( j )
    
    return
    
  elseif  isnan ( f( j ) )  ||  isinf ( f( j ) )  ||  f( j ) < 0
    
    met (  'print'  ,  sprintf ( [ 'metrftuning:fvalplot: f-value ' , ...
      '%d is insane , %f' ] , j , f( j ) )  ,  'E'  )
    return
    
  end % quitting conditions
  
  % Place a coloured rectangle over the selected unit , the one whose
  % tuning curve is plotted
  rectangle ( 'Parent' , a , 'Position' , [ j - 0.5 , 0 , 1 , f( j ) ] ,...
    'EdgeColor' , 'none' , 'FaceColor' , 'r' )
  
end % fvalplot

  
% Plot the selected tuning curve
function  tuneplot ( h )
  
  % Find tuning plot axes
  a = findobj ( h , 'Type' , 'axes' , 'Tag' , 'tuning' ) ;
  
  % Indeces of front end channel and unit
  c = h.UserData.chan ;
  u = h.UserData.unit ;
  
  % No unit selected , quit
  if  ~ c  ||  ~ u  ,  return  ,  end
  
  % Clear axes
  cla ( a )
  
  % Say which channel and unit is shown
  title (  a  ,  sprintf ( 'chan%d , unit%d , F-val %0.2f' , ...
    c , u - 1 , h.UserData.fval( c , u ) )  ,  'Color'  ,  'w'  )
  
  % The set of unique task variable values
  xval = h.UserData.xval ;
  
  % Number of samples per group
  Ns = h.UserData.nval ;
  
  % Estimate the current mean spike rate
  m = reshape (  h.UserData.grpsum( c , u , : )  ,  size( Ns )  )  ./  Ns ;
  
  % And the current standard deviation
  e = reshape (  h.UserData.varsum( c , u , : )  ,  size( Ns )  )  ./  Ns ;
  e = sqrt (  e  ) ;
  
  % Make sure that this is auto so that upper limit is set after call to
  % plot
  a.YLimMode = 'auto' ;
  
  % Plot error lines and mean locations
  plot (  a  ,  [ xval ; xval ]  ,  [ m - e ; m + e ]  ,  'w'  ,  ...
    xval  ,  m  ,  'wo--'  )
  
  % Make sure that no negative values are shown , in case error bars go
  % below zero
  if  a.YLim( 1 )  <  0
    a.YLim( 1 ) = 0 ;
  end
  
  % Only one task variable value , can't define x-axis limit
  if  numel ( xval )  ==  1  ,  return  ,  end
  
  % Set x-axis limits
  a.XLim = [ -0.025 , 1.025 ]  *  diff ( xval(  [ 1 , end ]  ) )  +  ...
    xval ( 1 ) ;
  
end % tuneplot

