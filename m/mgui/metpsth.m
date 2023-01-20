
function  [ h , update , reset , recover , close ] = metpsth
% 
% [ h , update , reset , recover , close ] = metpsth
% 
% Matlab Electrophysiology Toolbox GUI. Creates MET Peri-stimulus Time
% Histogram (PSTH) GUI. This maintains a PSTH for each possible spike
% classification returned by the Blackrock Microsystem Neural Signal
% Processor. To compute PSTH, an analysis window is specified as two time
% points (in milliseconds) relative to a reference state transition of a
% given task logic from a given task. Along with a bin width, the PSTH is
% continuously updated after every correct and failed trial. Two panels are
% plotted. On the top, a colour-map shows the PSTH of all units, ordered
% from top to bottom by maximum firing rate. The bottom plot shows the PSTH
% for a single unit, the unit with maximum average firing rate, or the
% average of all units.
% 
% Analysis window properties are accessed by right-clicking and selecting
% Properties. Here, drop down menus allow the specific task and task logic
% state to be set, while edit boxes provide input for the millisecond
% offsets of the start and end of the window, relative to the state. These
% controls are unavailable while trials are running. A default analysis
% window can be given in the accompanying metpsth.csv file in the
% met/m/mgui directory. This is a MET .csv parameter file with parameters:
% 
%   task - String naming default task to use, if available.
%   
%   chan - Either a number giving an index of the front end channel, from
%     1 to 128. Write 'max' to select the channel with the maximum firing
%     rate, or 'avg' to show the average firing rate from all channels.
%   
%   unit - Similar to chan, but gives the spike classification index, from
%     0 to 5. 'max' and 'avg' have the same meanings, but in the context of
%     spike classification.
%   
%   state - Names the state that the analysis window offsets are aligned
%     to.
%   
%   msoffset1, msoffset2 - Gives the offset in milliseconds from state of
%     the start ( 1 ) and end ( 2 ) of the analysis window. Can be a
%     positive or negative number.
%   
%   binwid - Width of time bins to use, in milliseconds. Must be a positive
%     number. binwid or msoffset2 - msoffset1 is used, whichever is
%     smaller.
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
  TITBAR = 'MET PSTH' ;
  
  % Default parameter list , and numeric parameters
  DEFLST = { 'task' , 'state' , 'msoffset1' , 'msoffset2' , 'binwid' , ...
    'chan' , 'unit' } ;
  DEFNUM = { 'msoffset1' , 'msoffset2' , 'binwid' } ;
  
  % Unit maximum firing rate
  MAXFIR = 'max' ;
  
  % Average firing rate
  AVGFIR = 'avg' ;
  
  % Combination
  AVGMAX = { MAXFIR , AVGFIR } ;
  
  % Maximum number of channels and units from cbmex trialdata
  MAXCHN = MCC.SHM.NSP.MAXCHN ;
  MAXUNI = MCC.SHM.NSP.MAXUNI ;
  
  % Maximum number of spike classification types
  MAXCLA = MAXCHN  *  ( MAXUNI + 1 ) ;
  
  % Default parameter file
  DEFNAM = fullfile (  MCC.GUIDIR  ,  'metpsth.csv'  ) ;
  
  % Load defaults
  D = metreadcsv ( DEFNAM , DEFLST , DEFNUM ) ;
  
  % Valid unit selection
  if (  ~ any ( strcmp( D.chan , AVGMAX ) )  &&  ...
       ninval ( D.chan , 1 , MAXCHN )  )  ||  ...
     (  ~ any ( strcmp( D.unit , AVGMAX ) )  &&  ...
       ninval ( D.unit , 1 , MAXUNI )  )
    
    meterror (  [ 'metpsth: .csv params ''chan'' and ''unit'' must ' , ...
      'be either ''%s'', ''%s'', or ' , 'values between 1 and %d or ' , ...
        '0 and %d , respectively' ]  ,  AVGMAX { : }  ,  MAXCHN  ,  ...
          MAXUNI  )

  % Valid task and task logic state selection
  elseif  isempty (  regexp( D.task  , MCC.REX.VALNAM , 'once' )  )  || ...
          isempty (  regexp( D.state , MCC.REX.VALNAM , 'once' )  )
        
    meterror (  [ 'metpsth: .csv param ''task'' and ''state'' must ' , ...
      'have valid names i.e. follow regular expression %s' ]  ,  ...
        MCC.REX.VALNAM  )
    
  % Valid offset values
  elseif  any ( mod(  [ D.msoffset1 , D.msoffset2 ]  ,  1  ) )
    
    meterror (  'metpsth: .csv ''msoffset'' params must be integers'  )
    
  % Valid bid width
  elseif  mod ( D.binwid , 1 )  ||  D.binwid <= 0  ||  ...
      D.msoffset2 - D.msoffset1 < D.binwid
    
    meterror (  [ 'metpsth: .csv ''binwid'' param must be an integer ' ,...
      'greater than zero and no greater than msoffset2 - msoffset1 = ' ,...
        '%d' ]  ,  D.msoffset2 - D.msoffset1  )
    
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
  
  UICNTC = { 'BackgroundColor' , 'none' , 'ForegroundColor' , 'w' , ...
    'Units' , 'normalized' } ;
  
  
  %%% Generate figure %%%
  
  % D are defaults from metpsth.csv.
  % recflg is raised when recovery data is loaded , causes the next call to
  %   freset ( h , { 'sd' , sd } ) to lower the flag and then return with
  %   no further action
  % MAXCLA a derived constant. Maximum number of spike classifications over
  %   all front end channels.
  % chan and unit each give the channel and unit index ( each starting from
  %   1 ) of the selected spike classification whose PSTH will be
  %   individually plotted.
  % logic is the current set of all available task logics.
  % task is the list of all current tasks.
  % tasksel is the currently selected task name.
  % state names the task logic state to peg the start and end of the
  %   analysis window to.
  % staflg a scalar logical. When flag is up, signals that the reference
  %   state has changed and that buffers must change.
  % msoffset1 and 2 are the number of milliseconds relative to state1 and 2
  %   that the window starts and stops.
  % binwid is the width of each time bin, in milliseconds
  % nbins is the number of bins that fit into the given analysis window,
  %   rounded down to the nearest integer.
  % binflg is a scalar logical that says whether or not the number of
  %   bins has changed following a change to any offset or bin width.
  % xval is the time in seconds relative to the given state onset at the
  %   centre of each bin.
  % nval is a vector of nbin values where nval( i ) is the number of values
  %   observed in the ith time bin i.e. the number of trials. Type unsigned
  %   16-bit integers.
  % spk counts the number of spikes per time bin for each type of spike
  %   classification. The first dimension is indexed across all spike class
  %   types ; in other words, the linear indexing of a channel by unit
  %   matrix is rolled out onto a single dimention i.e. spk( i , : ) is the
  %   set of time bins for data{ i } of the trial-buffer nsp finalised
  %   field that contains only the first 128 rows. The second dimension of
  %   spk is indexed along all time bins. spk is of type uint32 and must be
  %   converted to double in order to obtain mean firing rates.
  % maxspk is a column vector with as many rows as spk, and stores the
  %   maximum firing rate observed from each spike classification.
  %   single-precision floating point.
  % var accumulates the spike rate variance per classification and time
  %   bin. It has the same arrangement as spk. But it is a single-precision
  %   floating point array. Variance is estimated on each trial by
  %   subtracting the current estimate of the mean spike rate from the
  %   current trial's spike rate, then taking the square. When the average
  %   of the squared differences is found then we have an estimate of the
  %   variance.
  % g is a struct that links to the channel/unit popup menus, and the
  %   population psth image. These things are frequently referenced.
  %
  s = struct ( 'D' , D , 'recflg' , false , 'MAXCLA' , MAXCLA , ...
    'chan' , 0 , 'unit' , 0 , ...
    'logic' , [] , 'task' , [] , 'tasksel' , '' , 'state' , '' , ...
    'staflg' , false , ...
    'msoffset1' , D.msoffset1 , 'msoffset2' , D.msoffset2 , ...
    'binwid' , D.binwid , 'binend' , 0 , ...
    'nbins' , floor (  ( D.msoffset2 - D.msoffset1 )  /  D.binwid  ) , ...
    'binflg' , true ,  'nval' , [] , 'xval' , [] , 'spk' , [] , ...
    'maxspk' , zeros( MAXCLA , 1 , 'single' ) , 'var' , [] , 'g' , [] ) ;
  
  % Apply default channel and unit
  if  ~ strcmp ( D.chan , AVGMAX )
    s.chan = str2double ( D.chan ) ;
  end
  
  if  ~ strcmp ( D.unit , AVGMAX )
    s.unit = str2double ( D.unit ) + 1 ;
  end
  
  % Compute end of the last bin , relative to state onset
  s.binend = s.nbins * s.binwid  +  s.msoffset1 ;
  
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
  
	c.chnpop = metlabcnt ( UICTXT , UICNTC , 'popupmenu' , ...
    p.data , 0 , 1 , 'Front-end channel' , 'chan' , @chnpop_cb ) ;
  
  % Link to figure
  h.UserData.g.chnpop = c.chnpop ;
  
  % Populate set of menu options. Bear in mind that both data-panel popup
  % menus have 'max fval' as the first entry i.e. their Value 1. Other
  % functions assume that if c.chnpop.Value is 1 then they should use the
  % maximum F-value.
  c.chnpop.String = [  { 'max' , 'avg' }  ,  ...
    arrayfun(  @( v )  sprintf( '%d' , v )  ,  1 : MAXCHN  ,  ...
      'UniformOutput'  ,  false  )  ] ;
    
  % UserData holds field name of figure's UserData to be changed
  c.chnpop.UserData = 'chan' ;
  
  
  %-- Unit selector menus --%
  
  c.unipop = metlabcnt ( UICTXT , UICNTC , 'popupmenu' , p.data , ...
    sum(  c.chnpop.Position( [ 1 , 3 ] )  )  +  0.02 , 1 , ...
      'Unit' , 'unit' , @chnpop_cb ) ;
    
  % Link to figure
  h.UserData.g.unipop = c.unipop ;
  
  % Populate set of menu options
  c.unipop.String = [  { 'max' , 'avg' }  ,  ...
    arrayfun(  @( v )  sprintf( '%d' , v )  ,  0 : MAXUNI  ,  ...
      'UniformOutput'  ,  false  )  ] ;
  
  % UserData holds field name of figure's UserData to be changed
  c.unipop.UserData = 'unit' ;
    
  
  %-- Set default selection --%
  
  % If default chan or unit is 'max' or 'avg' then set the value of the
  % corresponding control
  for  I = {  { 'chnpop' , 'chan' }  ,  { 'unipop' , 'unit' }  }
    
    % Get meaningful names
    [ cf , df ] = I{ 1 }{ : } ;
    
    % Interpret defaults
    switch  D.( df )
      case  'max'  ,  c.( cf ).Value = 1 ;
      case  'avg'  ,  c.( cf ).Value = 2 ;
      otherwise    ,  c.( cf ).Value = s.chan  +  2 ;
    end
    
  end % controls
  
  
  %-- Data axes --%
  
  % Make container panel to contain them
  p.contain = uipanel ( 'Parent' , p.data , UIPANEL{ : } , ...
    'UIContextMenu' , p.data.UIContextMenu ) ;
  
  % Position it just under the selector controls
  p.contain.Position = [ 0 , 0 , 1 , 1 - ...
    max(  [ c.chnpop.Position( 4 ) , c.unipop.Position( 4 ) ]  ) ] ;
	
	% Population PSTH plot
  c.popaxe = subplot ( 2 , 1 , 1 , 'Parent' , p.contain , AXES{ : } , ...
    'Tag' , 'popaxe' , 'UIContextMenu' , p.data.UIContextMenu , ...
    'YLim' , [ 0 , MAXCLA ] , 'ButtonDownFcn' , @popaxe_cb , ...
    'XTickLabel' , [] , 'YTickLabel' , [] , ...
    'TickLength' , [ 0.025 , 0.025 ] ) ;
  
  % Link to figure user data
  h.UserData.g.popaxe = c.popaxe ;
  
  % Set colour map to a finer grain
  colormap (  c.popaxe  ,  parula ( 2 ^ 8 )  )
  
  % Add axes labels
  ylabel ( c.popaxe , 'Selected' , 'Color' , 'w' )
  title ( c.popaxe , 'Population PSTH' , 'Color' , 'w' )
  
  % Selected PSTH. UserData contains direct links to graphics object handle
  % arrays. These are pre-allocated when Done button executes.
  c.selaxe = subplot ( 2 , 1 , 2 , 'Parent' , p.contain , AXES{ : } , ...
    'Tag' , 'selaxe' , 'UIContextMenu' , p.data.UIContextMenu , ...
    'UserData' , struct( 'mean' , gobjects ( 0 ) , ...
    'err' , gobjects( 0 ) ) ) ;
  
  % Link to figure user data
  h.UserData.g.selaxe = c.selaxe ;
  
  % Axis labels
  xlabel ( c.selaxe , 'Time from state onset (ms)' , 'Color' , 'w' )
  ylabel ( c.selaxe , sprintf ( 'Average\nspk/sec (sdev)' ) , ...
    'Color' , 'w' )
  
  % Preset the title so that we can change only its string, later on
  title ( c.selaxe , 'chan , unit' , 'Color' , 'w' )
  
  
  %-- Graphics objects --%
  
  % PSTH image , population. The UserData contains a struct with both a
  % forward and reverse mapping. The forward mapping is a one-to-one index
  % vector mapping rows of the figure's .UserData.spk to rows of the
  % image's CData, to produce an image that is sorted by the maximum firing
  % rate of each row. The reverse mapping is a one-to-one mapping of rows
  % of the image's CData back to the figure's .spk.
  h.UserData.g.imgpop = image ( 'Parent' , c.popaxe , ...
    'XData' , [] , 'YData' , 1 : MAXCLA , 'CData' , [] , ...
    'CDataMapping' , 'scaled' , 'Tag' , 'imgpop' , ...
    'ButtonDownFcn' , @popaxe_cb , ...
    'UserData'  ,  ...
      struct ( 'forward' , 1 : MAXCLA , 'reverse' , 1 : MAXCLA )  ) ;
     
	% State onset line
  line ( 'Parent' , c.popaxe , 'Color' , 'w' , 'LineWidth' , 1 , ...
    'XData' , [ 0 , 0 ] , 'YData' , [ 0.5 , MAXCLA + 0.5 ] , ...
    'Tag' , 'popaxe' )
  
  % Guarantee that population axes y-axis direction is normal i.e. larger
  % values go up
  c.popaxe.YDir = 'normal' ;
  
  
  %%% Properties panel graphics objects %%%
  
  
  %-- Task --%
  
  c.tasksel = metlabcnt ( UICTXT , UICNTC , 'popupmenu' , ...
    p.properties , 0 , 0.95 , 'Task' , 'tasksel' , @proppup_cb ) ;
  
  % Populate set of menu options
  c.tasksel.String = { '<none>' } ;
  
  % Resize
  c.tasksel.Position( 3 ) = 2 * c.tasksel.Position( 3 ) ;
  
  
  %-- Analysis window controls --%
  
  % Task logic state selection menu
  c.state = metlabcnt ( UICTXT , UICNTC , 'popupmenu' , ...
    p.properties , 0 , c.tasksel.Position( 2 ) - 0.01 , ...
      'State window ref' , 'state' , @proppup_cb ) ;
  
  % Populate set of menu options
  c.state.String = { '<none>' } ;
  
  % Resize
  c.state.Position( 3 ) = 2 * c.state.Position( 3 ) ;
  
  % Align the two popup menus
  c.tasksel.Position( 1 ) = c.state.Position( 1 ) ;
  
  % Millisecond offset edit boxes
  c.msoffset1 = metlabcnt ( UICTXT , UICNTC , 'edit' , ...
    p.properties , 0 , c.state.Position( 2 ) - 0.01 , ...
      'Window start (ms)' , 'msoffset1' , @edit_cb ) ;
  c.msoffset2 = metlabcnt ( UICTXT , UICNTC , 'edit' , ...
    p.properties , 0 , c.msoffset1.Position( 2 ) - 0.01 , ...
      'Window end (ms)' , 'msoffset2' , @edit_cb ) ;
  
  % Bin width edit box
  c.binwid = metlabcnt ( UICTXT , UICNTC , 'edit' , p.properties , 0 , ...
    c.msoffset2.Position( 2 ) - 0.01 , 'Bin width (ms)' , 'binwid' ,...
    @edit_cb ) ;
  
  % Resize
  c.msoffset1.Position( 3 ) = 1.25 * c.msoffset1.Position( 3 ) ;
  c.msoffset2.Position( 3 ) = 1.25 * c.msoffset2.Position( 3 ) ;
  c.binwid.Position( 3 ) = 1.25 * c.binwid.Position( 3 ) ;
  
  % Align
  mpos = max (  [  c.msoffset1.Position( 1 )  ,  ...
    c.msoffset2.Position( 1 )  ,  c.binwid.Position( 1 )  ]  ) ;
  c.msoffset1.Position( 1 ) = mpos ;
  c.msoffset2.Position( 1 ) = mpos ;
     c.binwid.Position( 1 ) = mpos ;
  
  % Set default values
  for  I = { 'msoffset1' , 'msoffset2' , 'binwid' }  ,  cf = I { 1 } ;
    
    % Set string in the edit box, visible to user ...
    c.( cf ).String = num2str (  D.( cf )  ) ;
    
    % ... and save in UserData as the most recent valid number string
    c.( cf ).UserData = c.( cf ).String ;
    
  end % default values
  
  % Right-justified strings
  set (  [ c.msoffset1 , c.msoffset2 , c.binwid ]  ,  ...
    'HorizontalAlignment'  ,  'right'  )
  
  
  %-- Done button --%
  
  c.done = uicontrol ( p.properties , 'Style' , 'pushbutton' , ...
    'BackgroundColor' , 'none' , 'ForegroundColor' , 'w' , ...
    'String' , 'Done' , 'Tag' , 'properties' , ...
    'Callback' , @done_cb , 'Units' , 'normalized' ) ;
  
  % Resize
  c.done.Position( 3 : 4 ) = 1.1 * c.done.Extent( 3 : 4 ) ;
  
  % Position
  c.done.Position( 1 : 2 ) = c.binwid.Position( 1 : 2 ) ;
  c.done.Position( 1 ) = c.done.Position( 1 ) + ...
    c.binwid.Position( 3 ) - c.done.Position( 3 ) ;
  c.done.Position( 2 ) = c.done.Position( 2 ) - c.done.Position( 4 ) - ...
    0.05 ;
  
  
  %%% Blocked controls %%%
  
  % Get list of controls that are blocked during trials
  h.UserData.blockcntl = [  findobj( p.data , 'Type' , 'uicontrol' ) ;
    findobj( p.properties , 'Type' , 'uicontrol' )  ] ;
  
  % Make it a row vector
  h.UserData.blockcntl = reshape (  h.UserData.blockcntl  ,  ...
    1  ,  numel ( h.UserData.blockcntl )  ) ;
  
  
end % metpsth


%%% MET GUI functions %%%


function  drawnew = fupdate ( h , sd , ~ , td , ~ , tbuf )
%
% drawnew = update ( h , sd , bd , td , cbuf , tbuf )
%
  
  
  %%% Global variables %%%
  
  % MET and MET controller constants
  global  MC  MCC
  
  % MET signal identifier map
  MSID = MCC.MSID ;
  
  % Maximum number of spike classification over all front end channels
  MAXCLA = h.UserData.MAXCLA ;
  
  
  %%% Check environment %%%
  
  % Assume no change to plot
  drawnew = false ;
  
  % Quit immediately if done button needs to be executed because properties
  % were changed
  if  h.UserData.staflg  ||  h.UserData.binflg  ,  return  ,  end
  
  % MET signals trial buffer
  msig = tbuf.msig ;
  
  % Pull out signal identifiers, cargos, and times
  sig = msig.b( 1 : msig.i , msig.sig ) ;
  crg = msig.b( 1 : msig.i , msig.crg ) ;
  tim = msig.b( 1 : msig.i , msig.tim ) ;
  
  % Get selected task's logic
  logic = sd.logic.(  sd.task.(  h.UserData.tasksel  ).logic  ) ;
  
  % No task has been selected, no logic state has been selected, no
  % buffered nsp shm, or selected task hasn't run on this trial. Quit now.
  if  isempty ( h.UserData.tasksel )  ||  ...
      isempty ( h.UserData.state )  ||  ~ isfield ( tbuf , 'nsp' )  ||  ...
      ~ tbuf.nsp.i  ||  ~ isfield ( tbuf.nsp , 'final' )  ||  ...
      ~ strcmp ( h.UserData.tasksel , td.task )
    return
  end
  
  % Find the mstart signal i.e. the start state
  mstart = sig  ==  MSID.mstart ;
  
  % Find mstop signal and determine the outcome
  mstop = sig  ==  MSID.mstop ;
  outcome = MC.OUT {  crg( mstop )  ,  1  } ;
  
  % Find the index of the selected reference state
  switch  h.UserData.state
  
    case  'corr/fail'
    
      % Correct and failed end of trial event
      refstate = mstop ;
    
    case  'start'
      
      % mstart time
      refstate = mstart ;
      
    otherwise
    
      % Locate first mstate signal that carries selected state
      refstate = find (  MSID.mstate == sig  & ...
        logic.istate.( h.UserData.state ) == crg  ,  1  ,  'first'  ) ;
    
  end % reference state
  
  % Trial neither correct nor failed , or reference state not found
  if  ~ any ( strcmp(  outcome  ,  { 'correct' , 'failed' }  ) )  ||  ...
      ~ any (  refstate  )
    return
  end
  
  
  %%% Prepare NSP data %%%
  
  % nsp shared memory buffer , finalised by metgui
  nsp = tbuf.nsp.final ;
  
  % Locate front end channels ...
  fec = ~ cellfun (  @isempty  ,  ...
    regexp ( tbuf.nsp.label , MCC.SHM.NSP.SPKLAB )  ) ;
  
  % ... and get the channel index from the label
  chi = regexp(  tbuf.nsp.label( fec )  ,  '\d+$'  ,  'match'  ) ;
  chi = str2double (  [ chi{ : } ]  ) ;
  
  % Guarantee that the nsp spike cell array will be full size i.e. for all
  % possible front end channels and spike classifications
  spk = cell ( MCC.SHM.NSP.MAXCHN , MCC.SHM.NSP.MAXUNI + 1 ) ;
  spk( chi , : ) = nsp ( fec , : ) ;
  
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
  tim = tim  -  tim ( mstart ) ;
  
  % Add NSP mstart time , metcbmex should have converted from sample number
  % to seconds
  tim = tim  +  nsp{ dig , MCC.SHM.NSP.DINTIM - 1 }( dsig ) ;
  
  
  %%% Bin spikes %%%
  
  
  %-- Analysis window --%
  
  % Calculate the start and end times of the analysis window for this
  % trial , relative to the reference state time
  w = [ h.UserData.msoffset1 , h.UserData.binend ] / 1e3  +  ...
    tim (  refstate  ) ;
  
  
  %-- Count spikes per bin --%
  
  % Now return the spike classification index, bin index, and number of
  % spikes per bin
  [ lind , nspk ] = arrayfun (  ...
    @( c , s )  spk2bin ( h.UserData , w , c , s{ 1 } )  , ...
      ( 1 : MAXCLA )' ,  spk ( : )  ,  'UniformOutput'  ,  false  ) ;
    
  % Concatenate output into row vectors
  lind = [  lind{ : }  ] ;
  nspk = [  nspk{ : }  ] ;
  
  % Find non-zero bins , this has been crashing for some reason so it is
  % wrapped in a try-catch statement until a solution can be found
  try
    
    k = 0  <  h.UserData.spk ( lind ) ;
    
  catch
    
    met (  'print'  ,  sprintf ( ...
      [ 'metpsth line 659 failure: k = 0  <  h.UserData.spk ( lind )\n',...
        '  size h.UserData.spk: [%s ]\n  size lind: [%s ]' ] , ...
          sprintf( ' %d' , size( h.UserData.spk ) ) , ...
            sprintf( ' %d' , size( lind ) ) )  ,  'E'  )
    return
    
  end % non-zero bins
  
  % Now add these values to existing buffers
  h.UserData.spk( lind ) = h.UserData.spk( lind )  +  nspk ;
  
  
  %-- Number of trials per bin --%
  
%   % Find index of the first bin to have even partial representation in this
%   % trial
%   if  w( 1 )  <  tim ( mstart )
%     b1 = ceil (  ...
%       ( tim( mstart )  -  w( 1 ) )  *  1e3  /  h.UserData.binwid  ) ;
%   else
%     b1 = 1 ;
%   end
%   
%   % Same, but for the last bin
%   if  tim ( mstop )  <  w ( 2 )
%     b2 = ceil(  ...
%       ( tim( mstop )  -  w( 1 ) )  *  1e3  /  h.UserData.binwid  ) ;
%   else
%     b2 = h.UserData.nbins ;
%   end
%   
%   % Make an index vector
%   j = b1 : b2 ;
  
  % Increase trial count for bins that were not entirely cut off by the
  % start or end of the trial
%   h.UserData.nval( j ) = h.UserData.nval( j )  +  1 ;
  h.UserData.nval( : ) = h.UserData.nval  +  1 ;
  
  
  %-- Average firing rate --%
  
  % Find the population firing rate image
  imgpop = h.UserData.g.imgpop ;
  
  % Compute the average firing rate for all updated bins , this also
  % updates the population firing rate plot
  imgpop.CData( : , : ) = ...
    single(  h.UserData.spk  )  /  h.UserData.binwid  *  1e3  ./  ...
      repmat(  single(  h.UserData.nval  )  ,  MAXCLA  ,  1  ) ;
   
  % Compute maximum firing rate for updates
  h.UserData.maxspk = max (  imgpop.CData  ,  []  ,  2  ) ;
  
  % And sort it ascending
  [ ~ , i ] = sort (  h.UserData.maxspk  ) ;
  
  % Save the mapping of figure .spk rows to image .CData rows. That is,
  % .forward( i ) returns the row of .spk that maps to row i of .CData.
  imgpop.UserData.forward = uint16 ( i ) ;
  
  % Sort the forward mapping to find the reverse mapping
  [ ~ , i ] = sort (  imgpop.UserData.forward  ) ;
  
  % Now .reverse( i ) returns the row of .CData that maps to row i of .spk
  imgpop.UserData.reverse = uint16 ( i ) ;
  
  % Set colour axis of population psth axes
  caxis (  imgpop.Parent  ,  [ 0 , h.UserData.maxspk( end ) ]  ) ;
  
  
  %-- Accumulate variance --%
  
  % Bins with no spikes get the current firing rate , which is the variance
  % assuming a Poisson process
  h.UserData.var(  lind( ~ k )  ) = single(  nspk( ~ k )  )  /  ...
    h.UserData.binwid  *  1e3 ;
  
  % Get subset of row and bin indeces, and spike count
  lind = lind ( k ) ;  nspk = nspk ( k ) ;
  
  % Bins with spikes accumulate variance by taking the squared difference
  % of the current trial firing rate with the current average firing rate
  h.UserData.var( lind ) = h.UserData.var( lind )  +  ...
    (  single ( nspk )  /  h.UserData.binwid  *  1e3  -  ...
      imgpop.CData ( lind )  )  .^  2 ;
  
  % Sort spike classification average rates by which one has the maximum.
  % We waited until now because we needed the averages to be ordered for
  % the previous operation. Notice that since .CData is set to be a scaled
  % version of .spk, it has the same row order. Now, if we apply the
  % forward mapping then .CData rows will be sorted the same way as
  % h.UserData.maxspk.
  imgpop.CData( : , : ) = imgpop.CData ( imgpop.UserData.forward , : ) ;
  
  % Look for units that have not produced any spikes
  k = h.UserData.maxspk  ==  0 ;
  
  % If any unit has binned spikes ...
  if  ~ all (  k  )
    
    % ... then set the y-axis limits to show only those units
    ylim (  imgpop.Parent  ,  [  sum(  k  )  ,  MAXCLA  ]  +  0.5  )
    
  end % imgpop YLim
  
  
  %%% Look for the maximum channel/unit %%%
  
  % Channel and unit selector popup menus
  chnpop = h.UserData.g.chnpop ;
  unipop = h.UserData.g.unipop ;
  
  % Find the channel and unit with the maximum firing rate
  j = [ 0 , 0 ] ;
  [ j( 1 ) , j( 2 ) ] = ind2sub (  ...
    [ MCC.SHM.NSP.MAXCHN , MCC.SHM.NSP.MAXUNI + 1 ]  ,...
      imgpop.UserData.forward ( end )  ) ;
  
  % Get the maximum channel
  if  chnpop.Value  ==  1
    h.UserData.chan = j ( 1 ) ;
  end
  
  % Get the maximum unit in the channel
  if  unipop.Value  ==  1
    h.UserData.unit = j ( 2 ) ;
  end
  
  
  %%% Plot data %%%
  
  % Signal change to plot
  drawnew = true ;
  
  % And update the selected average PSTH
  selpsthplot ( h )
  
  
end % fupdate


function  freset ( h , v )
%
%  Expects v to be a 2 element cell , first element is string 'sd' , 'bd' ,
%  or 'td' saying what kind of descriptor , second element is descriptor
%


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
      
      
      %-- Logic and task lists --%
      
      % Save task logic list
      h.UserData.logic = sd.logic ;
      
      % Save task list
      h.UserData.task  = sd.task  ;
      
      
      %-- Task menu --%
      
      % Find control
      tsel = findobj ( h , 'Type' , 'uicontrol' , ...
        'Style' , 'popupmenu' , 'Tag' , 'tasksel' ) ;
      
      % Get list of task names
      set (  tsel  ,  'String'  ,  fieldnames (  sd.task  )  ,  ...
        'Value'  ,  1  )
      
      % See whether currently selected task is in the new task list
      j = find (  strcmp ( tsel.String , h.UserData.tasksel )  ,  1  ,  ...
        'first'  ) ;
      
      if  isempty ( j )
        
        % Current selection not found. Look for default task name.
        j = find (  strcmp ( tsel.String , h.UserData.D.task )  ,  1  , ...
        'first'  ) ;
      
        if  isempty ( j )
          
          % Not found. Default to first item in the list
          j = 1;
          
        end
        
      end % set task
      
      % Set menu selection
      tsel.Value = j ;
      
      % Then run the task selection menu's callback to automatically set
      % the state menu, and save internal variables as well
      tsel.Callback ( tsel , [] )
      
      
      %-- Done button --%
      
      % Find parameters Done button
      donebt = findobj ( h , 'Type' , 'uicontrol' , ...
        'Style' , 'pushbutton' , 'Tag' , 'properties' ) ;
      
      % Execute the Done button callback to refresh buffers , at need ,
      % without swapping panel visibility
      donebt.Callback ( donebt , true )
      
      
    % Execute MET GUI reset
    case  'reset'
      
      % Find the population firing rate image
      imgpop = findobj ( h , 'Type' , 'image' , 'Tag' , 'imgpop' ) ;
      
      % Reset the buffers
      h.UserData.nval( : ) = 0 ;
      h.UserData.spk( : ) = 0 ;
      h.UserData.maxspk( : ) = 0 ;
      h.UserData.var( : ) = 0 ;
      imgpop.CData( : ) = 0 ;
      
      % Find the example PSTH axes ...
      selaxe = findobj ( h , 'Type' , 'axes' , 'Tag' , 'selaxe' ) ;
      
      % ... its line graphics objects ...
      g = selaxe.UserData ;
      
      % ... and set their y-axis values to NaN
      g.mean.YData( : ) = NaN ;
      for  i = 1 : h.UserData.nbins  ,  g.err( i ).YData( : ) = NaN ;  end
      
      
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
  F = { 'chan' , 'unit' , 'logic' , 'task' , 'tasksel' , 'state' , ...
    'msoffset1' , 'msoffset2' , 'binwid' , 'binend' , 'nbins' , 'nval' ,...
    'xval' , 'spk' , 'maxspk' , 'var' } ;
  
  % Control's whose .String property should not be saved or loaded
  CFNOST = { 'chnpop' , 'unipop' } ;
  
  
  %%% Recovery file name %%%
  
  % Full path
  frec = fullfile (  d { 2 }  ,  'metpsth.mat'  ) ;
  
  
  %%% Channel/Unit selectors %%%
  
  % Popup menus above the data axes
  c.chnpop = h.UserData.g.chnpop ;
  c.unipop = h.UserData.g.unipop ;
  
  
  %%% Find property controls %%%
  
  % Task selection popup menu
  c.tasksel = findobj ( h , 'Type' , 'uicontrol' , ...
        'Style' , 'popupmenu' , 'Tag' , 'tasksel' ) ;
  
  % State selection popup menu
  c.state = findobj ( h , 'Type' , 'uicontrol' , ...
    'Style' , 'popupmenu' , 'Tag' , 'state' ) ;
  
  % Bin width edit box
  c.msoffset1 = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'edit' , ...
    'Tag' , 'msoffset1' ) ;
  
  % Bin width edit box
  c.msoffset2 = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'edit' , ...
    'Tag' , 'msoffset2' ) ;
  
  % Bin width edit box
  c.binwid = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'edit' , ...
    'Tag' , 'binwid' ) ;
  
  
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
      
      % Make sure that we don't throw away our recovered data
      h.UserData.binflg = false ;
      
      % Disperse uicontrols data
      for  F = CF  ,  f = F { 1 } ;
        
        % Load control's .String value if not blacklisted
        if  SAVSTR.( f )
          c.( f ).String = s.uicontrol.( f ).String ;
        end
        
        % Always load control's .Value
        c.( f ).Value  = s.uicontrol.( f ).Value  ;
        
      end % uicontrols
      
      % Maximum number of units over all channels
      MAXCLA = h.UserData.MAXCLA ;
      
      % Number of bins in use
      nbins = h.UserData.nbins ;
      
      % Point to PSTH image object
      imgpop = h.UserData.g.imgpop ;
      
      % Get x-axis tick values
      imgpop.XData = h.UserData.xval ;
      
      % And set new x-axis limits for population PSTH parent axes
      imgpop.Parent.XLim = h.UserData.binwid * [ -0.5 , 0.5 ]  +  ...
        h.UserData.xval( [ 1 , end ] ) ;
      
      % Sort maximum spike rate of each channel/unit ascending
      [ ~ , i ] = sort (  h.UserData.maxspk  ) ;

      % Save the mapping of figure .spk rows to image .CData rows. That is,
      % .forward( i ) returns the row of .spk that maps to row i of .CData.
      imgpop.UserData.forward = uint16 ( i ) ;

      % Sort the forward mapping to find the reverse mapping
      [ ~ , i ] = sort (  imgpop.UserData.forward  ) ;

      % Now .reverse( i ) returns the row of .CData that maps to row i of
      % .spk
      imgpop.UserData.reverse = uint16 ( i ) ;

      % Set colour axis of population psth axes
      caxis (  imgpop.Parent  ,  [ 0 , h.UserData.maxspk( end ) ]  ) ;
      
      % Get forward mapping again
      i = imgpop.UserData.forward ;
      
      % Allocate memory for the image
      imgpop.CData = zeros (  h.UserData.MAXCLA  ,  nbins  , 'single'  ) ;
      
      % Replot the firing rates
      imgpop.CData( : , : ) = single(  h.UserData.spk( i , : )  )  /  ...
        h.UserData.binwid  *  1e3  ./  ...
          repmat(  single( h.UserData.nval ) ,  MAXCLA ,  1  ) ;
        
      % Look for units that have not produced any spikes
      k = h.UserData.maxspk  ==  0 ;

      % If any unit has binned spikes ...
      if  ~ all (  k  )

        % ... then set the y-axis limits to show only those units
        ylim (  imgpop.Parent  ,  [  sum(  k  )  ,  MAXCLA  ]  +  0.5  )

      end % imgpop YLim
        
      % Get axes with selected PSTH
      selaxe = h.UserData.g.selaxe ;
        
      % And allocate new lines for error bars ...
      selaxe.UserData.err = line ( ...
        [ h.UserData.xval ; h.UserData.xval ] , nan( 2 , nbins ) , ...
          'Parent' , selaxe  , 'Color' , 'w' ) ;

      % ... and average firing rate
      selaxe.UserData.mean = line ( 'Parent' , selaxe , ...
        'XData' , h.UserData.xval , 'YData' , nan( 1 , nbins ) , ...
        'Color' , 'w' , 'LineWidth' , 1 , 'Marker' , '.' , ...
        'MarkerEdgeColor' , 'w' ) ;
      
      % Replot selected PSTH
      selpsthplot ( h )
      
      % Find panels
      datpan = findobj ( h , 'Type' , 'uipanel' , 'Tag' , 'data' ) ;
      propan = findobj ( h , 'Type' , 'uipanel' , 'Tag' , 'properties' ) ;

      % Make sure we see the data panel
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
  
  % Global MET controller constants
  global  MCC

  % Calling figure
  f = h.Parent.Parent ;
  
  % Field name to change
  fn = h.UserData ;
  
  % Newly selected string
  s = h.String { h.Value } ;
  
  % Choose unit with maximum firing rate
  if  strcmp ( s , 'max' )
    
    % Find the population psth image
    imgpop = findobj ( f , 'Type' , 'image' , 'Tag' , 'imgpop' ) ;
    
    % Get maximum channel and unit
    [ c , u ] = ind2sub (  ...
      [ MCC.SHM.NSP.MAXCHN , MCC.SHM.NSP.MAXUNI + 1 ]  ,...
        imgpop.UserData.forward ( end )  ) ;
    
    % Find channel with maximum firing rate
    if  strcmp ( fn , 'chan' )

      f.UserData.( fn ) = c ;
      
      % Now find the unit selector
      h = findobj ( f , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
        'Tag' , 'unit' ) ;
      
      % Unit menu's selected string
      s = h.String { h.Value } ;
      
      % If unit selector wants automatic max fval then change fn to 'unit'
      % so that the maximum unit will be found
      if  strcmp ( s , 'max' )  ,  fn = 'unit' ;  end

    end

    % Find unit within channel that has maximum firing rate
    if  strcmp ( fn , 'unit' )  ,  f.UserData.( fn ) = u ;  end
    
  % Not chosen average , so set the internal value
  elseif  h.Value  ~=  2
    
    % Convert string number to numeric value
    f.UserData.( fn ) = str2double ( s ) ;
    
    % Unit, we need to add 1 to get Matlab-style indexing
    if  strcmp ( fn , 'unit' )
      f.UserData.( fn ) = f.UserData.( fn )  +  1 ;
    end
    
  end % handle selection
  
  % If the bin flag is up then automatically execute the Done button
  % callback
  if  f.UserData.binflg
    
    % Find parameters Done button
    donebt = findobj ( h , 'Type' , 'uicontrol' , ...
      'Style' , 'pushbutton' , 'Tag' , 'properties' ) ;

    % Execute the Done button callback to refresh buffers , at need ,
    % without swapping panel visibility
    donebt.Callback ( donebt , true )
      
  end % done button
  
  % Update axes if at least one bin counts spikes
  if  any (  f.UserData.nval  )  ,  selpsthplot ( f )  ,  end
  
end % chnpop_cb


% Population PSTH axes button down callback. Uses mouse click on axes to
% select a specific channel and unit. Causes its PSTH to be plotted.
function  popaxe_cb ( h , ~ )
  
  
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
  
  
  % Global MET controller constants
  global  MCC
  
  % Find the image object
  switch  h.Tag
    
    case  'popaxe'
      
      imgpop = ...
        findobj ( h.Children , 'Type' , 'image' , 'Tag' , 'imgpop' ) ;
  
    case  'imgpop'
      
      imgpop = h ;
      h = h.Parent ;
      
  end
  
  % The forward mapping .forward( r ) returns row indeces of .spk that maps
  % to row r of .CData
  i = imgpop.UserData.forward ;
  
  % Get y-axis value of click , rounded up to next integer. This then
  % becomes the ordinal index of the selected row.
  j = ceil (  h.CurrentPoint ( 1 , 2 )  ) ;
  
  % If this is less than 1 or more than the number of possible channel
  % selection then quit
  if  j  <  1  ||  size ( imgpop.CData , 1 )  <  j  ,  return  ,  end
  
  % Determine the channel and unit number from the linear index
  [ c , u ] = ind2sub (  ...
    [ MCC.SHM.NSP.MAXCHN , MCC.SHM.NSP.MAXUNI + 1 ]  ,  i ( j )  ) ;
  
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
  
  % At last , show the currently selected PSTH , if there is at least one
  % binned spike
  if  any (  f.UserData.nval  )  ,  selpsthplot ( f )  ,  end
  
end % popaxe_cb


% Task selection popup menu. Set the figure's internal UserData property.
function  proppup_cb ( h , ~ )
  
  % Callback figure
  f = h.Parent.Parent ;
  
  % popup menu's tag is also the name of the figure's UserData field to
  % fill
  fn = h.Tag ;
  
  % Selected string
  strsel = h.String { h.Value } ;
  
  % Name of the selection
  f.UserData.( fn ) = strsel ;
  
  % If this is the task selection menu then we must refresh the list of
  % task logic states in the state selection menu. Afterwards, try to
  % either maintain the same state selection, choose the default, or set
  % the start state. Otherwise, quit now.
  if  ~ strcmp ( fn , 'tasksel' )  ,  return  ,  end
  
  % Find the state selection menu
  s = findobj ( f , 'Type' , 'uicontrol' , 'Style' , 'popupmenu' , ...
    'Tag' , 'state' ) ;
  
  % Currently selected state
  css = s.String { s.Value } ;
  
  % Retrieve currently selected task logic
  logic = f.UserData.logic.(  f.UserData.task.(  strsel  ).logic  ) ;
  
  % Find the task logic list of states , exclude end states but add
  % 'corr/fail'
  nstate = [  logic.nstate( 1 : end - 4 )  ,  { 'corr/fail' }  ] ;
  
  % See whether current state selection is in the new list
  j = find (  strcmp( css , nstate )  ,  1  ,  'first'  ) ;
  
  if  isempty ( j )
    
    % Not found , look for default state
    j = find (  strcmp( f.UserData.D.state , nstate )  ,  1  ,  'first'  );
    
    if  isempty ( j )
      
      % Still not found , default to start state
      j = 1 ;
      
    end
    
    % In any case, the state has changed and we need to raise the state
    % flag , signalling a reset of buffers
    f.UserData.staflg = true ;
    
  end % state selection
  
  % Set new state list and selection
  set ( s , 'String' , nstate , 'Value' , j )
  
  % Save state selection
  f.UserData.state = nstate { j } ;
  
  
end % proppup_cb


% Millisecond offset edit box callback. Make sure that a scalar, real
% number was input. Converts from milliseconds to seconds of offset.
function  edit_cb ( h , ~ )
  
  % This is the binwidth edit uicontrol
  binwid = strcmp (  h.Tag  ,  'binwid'  ) ;
  
  % Convert new input to a number
  d = str2double ( h.String ) ;
  
  % Invalid entry
  if  isempty ( d )  ||  ~ isscalar ( d )  ||  isinf ( d )  ||  ...
      isnan ( d )  ||  ~ isreal ( d )  ||  mod ( d , 1 )  ||  ...
      ( binwid  &&  d <= 0 )  ||  zerowin ( h , d )
    
    % Revert to value pre-edit
    h.String = num2str ( h.UserData ) ;
    
    % Exit callback
    return
    
  end % invalid
    
  % Store numeric conversion in control's private data
  h.UserData = d ;

  % And also in the GUI's user data, for general access
  f = h.Parent.Parent ;
  f.UserData.( h.Tag ) = d ;
  
  % Find the analysis window width
  w = f.UserData.msoffset2  -  f.UserData.msoffset1 ;
  
  % If the current bin width is too big then reduce its size
  if  w  <  f.UserData.binwid
  
    % Otherwise, we must assign this as the new bin width
    f.UserData.binwid = w ;

    % And we must synchronise this change with the bin width edit uicontrol
    h = findobj ( h.Parent.Parent , 'Type' , 'uicontrol' , ...
      'Style' , 'edit' , 'Tag' , 'binwid' ) ;

    % Assign it the new window width string
    h.String = num2str ( w ) ;  h.UserData = h.String ;
  
  end % change binwid
  
  % Find the number of bins
  n = floor (  w  /  f.UserData.binwid  ) ;
  
  % The number of bins has changed
  if  n  ~=  f.UserData.nbins
    
    % Store that value
    f.UserData.nbins = n ;
    
    % And raise the bin flag , signalling that bin memory must be
    % re-allocated
    f.UserData.binflg = true ;
  
  end % changed bin number
  
  % Make sure that the end of the last bin is current
  f.UserData.binend = ...
    f.UserData.nbins * f.UserData.binwid  +  f.UserData.msoffset1 ;
  
end % edit_cb


% Properties panel done button , switches back to data panel. cbdat will be
% scalar logical true if executed programmatically
function  done_cb ( h , cbdat )
  
  % Figure
  f = h.Parent.Parent ;
  
  % Swap panel visibility if not executed programmatically
  if  ~ islogical ( cbdat )  ||  ~ cbdat
  
    % Find panels
    datpan = findobj ( f , 'Type' , 'uipanel' , 'Tag' , 'data' ) ;
    propan = findobj ( f , 'Type' , 'uipanel' , 'Tag' , 'properties' ) ;

    % Make sure we see the properties panel
    datpan.Visible = 'on'  ;
    propan.Visible = 'off' ;
  
  end % swap panel visibility
  
  % Find the population firing rate image
  imgpop = findobj ( f , 'Type' , 'image' , 'Tag' , 'imgpop' ) ;
  
  % If the bin flag is down
  if  ~ f.UserData.binflg
    
    % Check if the state flag is up
    if  f.UserData.staflg
      
      % Lower flag
      f.UserData.staflg = false ;
      
      % Execute reset
      freset ( f , { 'reset' , [] } )
      
      % It is , so we must reset the buffers
      f.UserData.nval( : ) = 0 ;
      f.UserData.spk( : ) = 0 ;
      f.UserData.maxspk( : ) = 0 ;
      f.UserData.var( : ) = 0 ;
      imgpop.CData( : ) = 0 ;
      
    end
    
    % Quit now
    return
    
  end % bin and state flags
  
  % Lower flags
  f.UserData.staflg = false ;
  f.UserData.binflg = false ;
  
  % Maximum number of spike classifications over all front end channels
  MAXCLA = f.UserData.MAXCLA ;
  
  % Number of bins
  nbins = f.UserData.nbins ;
  
  % Re-allocate memory for buffers
  f.UserData.nval = zeros ( 1 , nbins , 'uint16' ) ;
  f.UserData.xval = ( 1 : nbins ) * f.UserData.binwid  -  ...
    f.UserData.binwid / 2  +  f.UserData.msoffset1 ;
  f.UserData.spk = zeros (  MAXCLA  ,  nbins  ,  'uint32'  ) ;
  f.UserData.var = zeros (  MAXCLA  ,  nbins  ,  'single'  ) ;
  imgpop.CData = zeros (  MAXCLA  ,  nbins  ,  'single'  ) ;
  
  % Reset image XData
  imgpop.XData = f.UserData.xval ;
  
  % And set new x-axis limits for axes
  imgpop.Parent.XLim = f.UserData.binwid * [ -0.5 , 0.5 ]  +  ...
    f.UserData.xval( [ 1 , end ] ) ;
  
  % Find the example PSTH axes and set the x-axis limits
  selaxe = findobj ( f , 'Type' , 'axes' , 'Tag' , 'selaxe' ) ;
  selaxe.XLim = imgpop.Parent.XLim ;
  
  % Delete any old graphics objects
  delete (  [  selaxe.UserData.mean  ;  selaxe.UserData.err  ]  )
  
  % And allocate new lines for error bars ...
  selaxe.UserData.err = line ( [ f.UserData.xval ; f.UserData.xval ] , ...
    nan( 2 , nbins ) , 'Parent' , selaxe  , 'Color' , 'w' ) ;
  
  % ... and average firing rate
  selaxe.UserData.mean = line ( 'Parent' , selaxe , ...
    'XData' , f.UserData.xval , 'YData' , nan( 1 , nbins ) , ...
    'Color' , 'w' , 'LineWidth' , 1 , 'Marker' , '.' , ...
    'MarkerEdgeColor' , 'w' ) ;
  
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


% Returns true if the analysis window will have a width of zero or less.
% False otherwise. Input is handle to an edit uicontrol for millisecond
% offset and double version of edit's current string
function  i = zerowin ( h , d )
  
  % edit uicontrol is bin width
  if  strcmp ( h.Tag , 'binwid' )
    i = false ;
    return
  end
  
  % Calling figure
  f = h.Parent.Parent ;
  
  % Get the start and end offsets for the analysis window
  switch  h.Tag
    case  'msoffset1'  ,  s = d ;  e = f.UserData.msoffset2 ;
    case  'msoffset2'  ,  s = f.UserData.msoffset1 ;  e = d ;
  end
  
  % Determine if the analysis window has zero or negative width
  i = e  -  s  <=  0 ;
  
end % zerowin


% Return lind( j ) will give a spike-classification/bin linear index, while
% nspk( j ) is the number of spikes observed from that classification in
% that bin. ud is the figure's UserData. w is the earliest and latest spike
% time that will be binned. c is the classification index, this will be
% repeated and returned in ispk. s is the vector of spike times, in seconds
% on the NSP clock.
function  [ lind , nspk ] = spk2bin ( ud , w , c , s )
  
  % Initialise empty matrices
  lind = uint32 ( [] ) ;  nspk = uint32 ( [] ) ;

  % Look for spikes that sit within a bin
  i = w ( 1 )  <=  s  &  s  <=  w ( 2 ) ;
  
  % No binnable spikes , quit now
  if  ~ any ( i )  ,  return  ,  end
  
  % Get binnable spikes and zero time on start of analysis window. Then
  % divide by the bin width and round up to get the index of the bin that
  % each spike landed in.
  s = ceil ( 1e3 * (  s( i )  -  w( 1 )  )  /  ud.binwid ) ;
  
  % Look for any spike that landed on the very edge of the first bin. This
  % will have a bin index of 0, but it should belong to bin 1.
  s(  s  ==  0  ) = 1 ;
  
  % Spike times are already sorted chronologically. Therefore, take the
  % difference of the bin indeces. This will return 0 when a bin index is
  % repeated and non-zero where it is not. Hence why we add an element to
  % the end that is 1 plus the last observed bin. In other words, identify
  % the last spike to land in each bin.
  i = 0  <  [ s( 2 : end ) , s( end ) + 1 ]  -  s ;
  
  % Find the number of spikes to land in each bin
  nspk = uint32 ( diff(  [ 0 , find( i ) ]  ) ) ;
  
  % Compute linear indeces for each bin that receives spikes, for each
  % spike classification
  lind = uint32 (  ud.MAXCLA  *  ( s( i ) - 1 )  +  c  ) ;
  
end % spk2bin

  
% Plot the selected PSTH
function  selpsthplot ( h )
  
  % Find tuning plot axes
  a = h.UserData.g.selaxe ;
  
  % Indeces of front end channel and unit
  c = h.UserData.chan ;
  u = h.UserData.unit ;
  
  % No unit selected , quit
  if  ~ c  ||  ~ u  ,  return  ,  end
  
  % Get access to MET controller constants
  global  MCC
  
  % Channel and unit selector popup menus
  chnpop = h.UserData.g.chnpop ;
  unipop = h.UserData.g.unipop ;
  
  % Find image of population psths ...
  imgpop = h.UserData.g.imgpop ;
  
  % ... and get the forward mapping from figure's .spk to CData rows.
  % Remember, fmap( i ) returns the row index from .spk that is mapped to
  % row i of imgpop.CData
  rmap = imgpop.UserData.reverse ;
  
  % Average together all spike classifications
  if  chnpop.Value  ==  2  &&  unipop.Value  ==  2
    
    % Title
    tit = 'Average all chan/unit' ;
    
    % Index vector covers all spike classifications
    j = 1 : h.UserData.MAXCLA ;
    
  % Average together all channels' selected unit
  elseif  chnpop.Value  ==  2
    
    % Title
    tit = sprintf (  'Avg chan , unit%d'  ,  u - 1  ) ;
    
    % Index covers selected unit in all channels
    j = ( u - 1 ) * MCC.SHM.NSP.MAXCHN  +  ( 1 : MCC.SHM.NSP.MAXCHN ) ;
    
  % Average together all units in selected channel
  elseif  unipop.Value  ==  2
    
    % Title
    tit = sprintf (  'chan%d , Avg unit'  ,  c  ) ;
    
    % Units in selected channel
    j = ( 0 : MCC.SHM.NSP.MAXUNI ) * MCC.SHM.NSP.MAXCHN  +  c ;
    
  else
    
    % Title
    tit = sprintf (  'chan%d , unit%d'  ,  c  ,  u - 1  ) ;
    
    % Find .spk row of selected classification
    j = ( u - 1 ) * MCC.SHM.NSP.MAXCHN  +  c ;
    
  end
  
  % Say which channel and unit is shown
  a.Title.String = tit ;
  
  % Show selected units with tick lines
  h.UserData.g.popaxe.YTick = sort ( rmap( j ) ) ;
  
  % The set line graphics objects
  g = a.UserData ;
  
  % Number of samples per bin
  Ns = h.UserData.nval ;
  
  % Current mean spike rate for selected unit
  m = mean (  imgpop.CData(  rmap( j )  ,  :  )  ,  1  ) ;
  
  % And the current standard deviation, above and below the mean
  e = sqrt (  mean(  h.UserData.var( j , : )  ,  1  )  ./  single( Ns )  );
  e = [  m - e  ;  m + e  ] ;
  
  % Update average ...
  g.mean.YData( : ) = m ;
  
  % ... and error line YData
  for  i = 1 : h.UserData.nbins
    
    g.err( i ).YData( : ) = e ( : , i ) ;
    
  end % error
  
  % Find y-axis limits
  e = [  min( e(  1  ,  :  ) )  ,  max( e(  2  ,  :  ) )  ] ;
  
  % If the maximum is more than the minimum then set the limits
  if  e( 1 )  <  e( 2 )  ,  a.YLim( : ) = e ;  end
  
end % selpsthplot

