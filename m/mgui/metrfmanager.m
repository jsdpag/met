
function  h = metrfmanager ( sd , modal )
% 
% h = metrfmanager ( sd , modal )
% 
% Presents a dialogue that allows the user to build a session schedule by
% means of a graphic-user-interface. sd is a session descriptor that is
% used to initialise the dialogue ; it may be empty. modal is a scalar
% numeric or logical ; if non-zero then the dialogue is modal. Returns a
% handle to the new figure. This has a struct in .UserData with fields
% .done and .sd ; 'done' is 0 or 1 , 1 meaning that a valid session
% descriptor is available in 'sd' , and 0 meaning that close or cancel was
% clicked. When the figure closes, it calls uiresume and hides itself. It
% must be cleared by delete ( h ).
% 
% Written by Jackson Smith - July 2017 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  global  MCC
  
  % If these haven't been set yet then set them.
  if  isempty ( MCC )  ,  MCC = metctrlconst    ;  end
  
  
  %%% Check input %%%
  
  % Must provide a valid session descriptor for sd
  if  isempty ( sd )  ||  ~ isstruct ( sd )  ||  ...
      numel( fieldnames( sd ) ) ~= numel( fieldnames( MCC.DAT.SD ) )  ||...
      ~all ( strcmp ( fieldnames( sd ) , fieldnames( MCC.DAT.SD ) ) )
    
    error ( 'MET:metgui:metrfmanager' , ...
     'metrfmanager: cmd is "Clone" but no valid session descriptor given' )
    
  % Must provide scalar numeric or logical for modal
  elseif  ~isscalar ( modal )  ||  ...
      ( ~isnumeric ( modal )  &&  ~islogical ( modal ) )
    
    error ( 'MET:metgui:metrfmanager' , ...
      'metrfmanager: modal must be scalar numeric or logical' )
    
  end
  
  
  %%% Constants %%%
  
  % Figure title
  TITBAR = 'RF manager' ;
  
  % Choose windowing style
  WINSTY = 'normal' ;
  if  modal  ,  WINSTY = 'modal' ;  end
  
  % uicontrol property constants , in name/value pairs
  UICCON = { 'BackgroundColor' , 'k' , 'ForegroundColor' , 'w' , ...
    'Units' , 'normalized' , 'Style' , 'pushbutton' } ;
  
  % ui object spacing
  UICSPC = 0.01 ;
  
  % Button strings
  BTNSTR = { 'Add' , 'Remove' , 'Load' , 'Clear' , 'Done' , 'Cancel' } ;
  
  % Button Tooltips
  BTNTIP = { 'Add new RF definition with defaults i.e. new column' , ...
    'Remove selected RF definition i.e. remove column' , ...
    'Load RF definitions from previous session' , ...
    'Remove all RF definitions i.e. all columns' , ...
    'Use RF definitions' , ...
    'Abort creating new session' } ;
  
  % Button callback functions
  BTNCBF = { @btnadd_cb , @btnrem_cb , @btnload_cb , @btnclr_cb , ...
    @btndone_cb , @figclsreqf_cb } ;
  
  % Index of done button
  IDONE = 5 ;
  
  % Table tooltip
  TABTIP = sprintf (  [ ...
    'Receptive/response Field definition table\n' , ...
    'xcoord,ycoord: centre of RF\n' , ...
    'contrast: Michelson contrast\n' , ...
    'width: diameter of RF\n' , ...
    'orientation: preferred angle of RF e.g. of a bar or grating\n' , ...
    'speed: preferred speed of RF perpendicular to orientation\n' , ...
    'disparity: preferred disparity of RF' ]  ) ;
  
  % uicontrol text strings and justifications
  TXTSTR = { 'Selected RF:' , '000' } ;
  TXTJUS = { 'right' , 'left' } ;
  
  
  %%% Generate figure %%%
  
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Visible' , 'off' , 'Resize' , 'on' , 'DockControls' , 'off' , ...
    'Units' , 'normalized' , 'WindowStyle' , WINSTY , ...
    'CloseRequestFcn' , @figclsreqf_cb ) ;
  
  % Set struct to user data. sd and done as outlined above. select tracks
  % which column in the RF table was last selected. For addition and
  % deletion of columns.
  h.UserData = struct (  'sd' ,  sd ,  'done' ,  0 ,  ...
    'select' ,  numel ( sd.rfdef )  ) ;
  
  
  %%% Create buttons %%%
  
  % Button handle vector
  v = gobjects (  1  ,  numel( BTNSTR )  ) ;
  
  % Starting horizontal location of control
  x = UICSPC ;
  
  % Create new buttons
  for  i = 1 : numel ( v )
    
    % Generate button
    v( i ) = uicontrol ( h , 'String' , BTNSTR{ i } , ...
      'TooltipString' , BTNTIP{ i } , 'Callback' , BTNCBF{ i } , ...
      UICCON{ : } ) ;
    
    % Match button size to extent of its string
    v( i ).Position( 3 : 4 ) = 1.1  *  v( i ).Extent( 3 : 4 ) ;
    
    % Line up buttons along the top , unless we have done or cancel button
    if  IDONE  <=  i  ,  continue  ,  end
    
    % Set horizontal position
    v( i ).Position( 1 ) = x ;
    
    % Then update horizontal position for the next button
    x = x  +  v( i ).Position( 3 )  +  UICSPC ;
    
  end % new buttons
  
  % Align done and cancel button to the bottom right
  x = 1 ;
  
  for  i = numel ( v ) : -1 : IDONE
    
    % Update horizontal location
    x = x  -  v( i ).Position( 3 )  -  UICSPC ;
    
    % Place button
    v( i ).Position( 1 : 2 ) = [ x , UICSPC ] ;
    
  end % done/cancel alignment
  
  
  %%% Create RF table %%%
  
  t = uitable ( h , 'ColumnName' , 'numbered' , ...
    'RowName' , MCC.DAT.RFDEF( : , 1 ) , 'Units' , 'normalized' , ...
    'Tooltipstring' , TABTIP , 'ForegroundColor' , 'w' , ...
    'BackgroundColor' , [ 0.35 , 0.35 , 0.35 ; 0.2 , 0.2 , 0.2 ] , ...
    'ColumnEditable' , true , 'CellSelectionCallback' , @tabsel_cb , ...
    'CellEditCallback' , @tabedit_cb ) ;
  
  % Table horizontal location
  t.Position( 1 ) =  UICSPC ;
  t.Position( 2 ) =  v( end ).Position( 4 )  +  2 * UICSPC ;
  
  % Table width , enough room for two columns. Use dummy data to estimate
  % extent.
  t.Data = zeros (  size( MCC.DAT.RFDEF , 1 )  ,  2  ) ;
  t.Position( 3 ) = 1.25  *  t.Extent( 3 ) ;
  
  % Table height , enough room for rows, column name, and slider bar. Use
  % dummy data to estimate extent.
  t.Data = zeros (  size( MCC.DAT.RFDEF , 1 )  ,  10  ) ;
  t.Position( 4 ) = 1.11  *  t.Extent( 4 ) ;
  
  % Remove dummy data
  t.Data = [] ;
  
  % Initialise table if RF definitions given
  if  ~ isempty ( sd.rfdef )
    
    % Allocate table array
    t.Data = zeros (  size( MCC.DAT.RFDEF , 1 )  ,  numel( sd.rfdef )  ) ;
    
    % Load in each row
    for  i = 1 : size ( MCC.DAT.RFDEF , 1 )
      
      % RF property string
      s = MCC.DAT.RFDEF { i , 1 } ;
      
      % Get values
      t.Data( i , : ) = [  sd.rfdef.( s )  ] ;
      
    end % load in rows
    
  end % init table
  
  % Align add/remove/load buttons to table
  y = sum (  t.Position( [ 2 , 4 ] )  )  +  UICSPC ;
  for  i = 1 : IDONE - 1  ,  v( i ).Position( 2 ) = y ;  end
  
  % Align done/cancel buttons to table
  x = 1  -  sum (  t.Position( [ 1 , 3 ] )  )  -  UICSPC ;
  for  i = IDONE : numel( v )
    v( i ).Position( 1 ) = v( i ).Position( 1 )  -  x ;
  end
  
  
  %%% Resize figure to match controls %%%
  
  % Switch units to pixels
  set (  [ h , v , t ]  ,  'Units'  ,  'pixels'  )
  
  % Get control spacing in pixels from horizontal location of left-most
  % button
  UICSPC = v( 1 ).Position( 1 ) ;
  
  % Figure width
  h.Position( 3 ) = 2 * UICSPC  +  t.Position( 3 ) ;
  
  % Figure height
  h.Position( 4 ) = ...
    4 * UICSPC  +  t.Position( 4 )  +  2 * v( 1 ).Position( 4 ) ;
  
  % Reset normalised units
  set (  [ h , v , t ]  ,  'Units'  ,  'normalized'  )
  
  
  %%% Add column selected labels %%%
  
  % Reset UICSPC to normalise units
  UICSPC = v( 1 ).Position( 1 ) ;
  
  % Make graphics object vector
  v = gobjects (  size(  TXTSTR  )  ) ;
  
  % Initialise horizontal position
  x = UICSPC ;
  
  % Make each label
  for  i = 1 : numel ( v )
    
    v( i ) = uicontrol ( h , UICCON{ 1 : end - 2 } , 'Style' , 'text' , ...
      'String' , TXTSTR{ i } , 'HorizontalAlignment' , TXTJUS{ i } ) ;
    
    % Set horizontal and vertical position
    v( i ).Position( 1 : 2 ) = [ x , UICSPC ] ;
    
    % Match label size to extent of its string
    v( i ).Position( 3 : 4 ) = 1.1  *  v( i ).Extent( 3 : 4 ) ;
    
    % Update horizontal position for next label
    x = sum (  v( i ).Position( [ 1 , 3 ] )  )  +  UICSPC ;
    
  end % make labels
  
  % Give variable label a tag
  v( 2 ).Tag = 'variable' ;
  
  % Default selection
  v( 2 ).String = num2str (  h.UserData.select  ) ;
  
  
  %%% Done making GUI %%%
  
  % Reveal GUI
  h.Visible = 'on' ;
  
  
end % metrfmanager


%%% Callbacks %%%

% Add button , creates new RF column following the last one selected.
% Adjusts figure's UserData.sd.rfdef accordingly.
function  btnadd_cb ( ~ , ~ )
  
  % MET controller constants
  global  MCC
  
  % Default RF parameters in a column vector
  defpar = [  MCC.DAT.RFDEF{ : , 2 }  ]' ;

  % Get figure handle
  h = gcbf ;
  
  % Index of selected column
  i = h.UserData.select ;
  
  % Find table
  t = findobj ( h , 'type' , 'uitable' ) ;
  
  % Add new column
  t.Data = ...
    [  t.Data( : , 1 : i )  ,  defpar  ,  t.Data( : , i + 1 : end )  ] ;
  
  % Update selected column index
  h.UserData.select = i  +  1 ;
  
  % Update label's string
  updatelabel ( h )
  
end % btnadd_cb


% Remove button , deletes selected RF column. Adjusts figure's
% UserData.sd.rfdef accordingly.
function  btnrem_cb ( ~ , ~ )
  
  % Get figure handle
  h = gcbf ;
  
  % Find table
  t = findobj ( h , 'type' , 'uitable' ) ;
  
  % Table is already empty , so quit here
  if  isempty ( t.Data )  ,  return ;  end
  
  % Otherwise , check that the user really meant to do this
  s = sprintf (  'Remove RF definition %d?'  ,  h.UserData.select  ) ;
  s = questdlg ( s , '' , 'Yes' , 'No' , 'No' ) ;
  
  % User thought again
  if  isempty ( s )  ||  strcmp ( s , 'No' )  ,  return  ,  end
  
  % Selected column index
  c = h.UserData.select ;
  
  % Delete column from table
  t.Data( : , c ) = [] ;
  
  % All RF definitions are destroyed , so set selection to 0
  if  isempty ( t.Data )
    
    h.UserData.select = 0 ;
    
  % Otherwise , select the column preceeding the deletion if the selection
  % was 2 or higher
  elseif  1  <  h.UserData.select
    
    h.UserData.select = h.UserData.select  -  1 ;
    
  end % update selection
  
  % If the selection was 1 but columns remain then keep 1 selected
  
  % Update label's string
  updatelabel ( h )
  
end % btnrem_cb


% Load button , allows user to load RF definitions from some previous
% session. Adjusts figure's UserData.sd.rfdef accordingly.
function  btnload_cb ( ~ , ~ )
  
  % MET controller constants
  global  MCC
  
  % Get figure handle
  h = gcbf ;
  
  % Get starting location for directory selection dialogue. Default is the
  % subject directory.
  d = MCC.DEFSUB ;
  
  % There is a session directory name
  if  ~ isempty ( h.UserData.sd.session_dir )
    
    % If directory doesn't exist yet then hop up to the parent directory
    while  ~ exist ( d , 'dir' )  ,  d = fileparts ( d ) ;  end
    
  end % named session directory
  
  % Have user select a previous session
  d = uigetdir ( d , 'Select previous session' ) ;
  
  % No valid selection returned
  if  ( isnumeric ( d )  &&  d == 0 )  ||  ...
      (    ischar ( d )  &&  ~ exist ( d , 'dir' ) )
    
    % Report problem and quit callback
    msgbox ( 'Not a valid session directory' , 'Error' )
    return
    
  end % no valid dir
  
  % Directory name was returned. But is it a valid session directory?
  try
    
    metsdpath ( d , false )
    
  catch
    
    % Report problem and quit callback
    msgbox ( 'Not a valid session directory' , 'Error' )
    return
    
  end % valid session directory
  
  % Look for saved session descriptor
  d = fullfile ( d , MCC.SDFNAM ) ;
  
  % No session descriptor
  if  ~ exist ( d , 'file' )
    
    % Report problem and quit callback
    msgbox ( 'No saved RF information found' , 'Error' )
    return
    
  end % no session descriptor
  
  % Load old session descriptor
  load ( d , 'sd' )
  
  % Look for RF definition struct vector
  if  ~ isfield ( sd , 'rfdef' )  ||  isempty ( sd.rfdef )
    
    % Report problem and quit callback
    msgbox ( 'No saved RF information found' , 'Error' )
    return
    
  end
  
  % Get old rfdef struct vector and field names
  rfdef = sd.rfdef ;
  FNAM = fieldnames ( rfdef )' ;
  
  % Create same sized struct vector. If there are new RF properties since
  % that session, we can put defaults in their place.
  s = MCC.DAT.RFDEF( : , 1 : 2 )' ;
  s = repmat (  struct( s { : } )  ,  size( rfdef )  ) ;
  
  % Load in old RF definitions
  for  i = 1 : numel ( rfdef )
    
    % Load in each property
    for  F = FNAM  ,  f = F { 1 } ;
      
      s( i ).( f ) = rfdef( i ).( f ) ;
      
    end % RF properties
    
  end % RF defs
  
  % Find table
  t = findobj ( h , 'type' , 'uitable' ) ;
  
  % Now mirror data in the RF table
  t.Data = reshape (  struct2array ( s )  ,  ...
    size ( MCC.DAT.RFDEF , 1 )  ,  numel ( s )  ) ;
  
  % And select the final column
  h.UserData.select = numel ( s ) ;
  
  % Update label's string
  updatelabel ( h )
  
end % btnload_cb


% Clear button , removes all RF definitions
function  btnclr_cb ( ~ , ~ )
  
  % Check that the user really meant to do this
  s = 'Clear all RF definitions?' ;
  s = questdlg ( s , '' , 'Yes' , 'No' , 'No' ) ;
  
  % User thought again
  if  isempty ( s )  ||  strcmp ( s , 'No' )  ,  return  ,  end
  
  % Get figure handle
  h = gcbf ;
  
  % Find table
  t = findobj ( h , 'type' , 'uitable' ) ;
  
  % Empty table
  t.Data = [] ;
  
  % Reset selected column index
  h.UserData.select = 0 ;
  
  % Update label's string
  updatelabel ( h )
  
end % btnclr_cb


% Done button , sets figure's UserData.done to 1 then calls the figure's
% closing callback
function  btndone_cb ( ~ , ~ )
  
  % MET controller constants
  global  MCC
  
  % Get figure handle
  h = gcbf ;
  
  % Find table
  t = findobj ( h , 'type' , 'uitable' ) ;
  
  % Convert table into struct vector if table not empty
  if  ~ isempty ( t.Data )
    
    s = [  t.RowName  ,  num2cell(  num2cell( t.Data )  ,  2  )  ]' ;
    s = struct (  s { : }  ) ;
    
  % Otherwise, use the empty RF def struct
  else
    
    s = MCC.DAT.SD.rfdef ;
    
  end
  
  % Save in session descriptor
  h.UserData.sd.rfdef = s ;
  
  % Raise done flag
  h.UserData.done = true ;
  
  % Close GUI
  figclsreqf_cb ( [] , [] ) ;
  
end % btndone_cb


% Table selected callback , stores the selected column in the figure's
% UserData.select
function  tabsel_cb ( ~ , d )
  
  % Invalid event
  if  isempty (  d.Indices  )  ,  return  ,  end

  % Get figure handle
  h = gcbf ;
  
  % Update selected column index
  h.UserData.select = d.Indices( end , 2 ) ;
  
  % Update label's string
  updatelabel ( h )
  
end % tabsel_cb


% Table edit callback , checks that a valid number was entered for the row.
% Adjusts figure's UserData.sd.rfdef accordingly.
function  tabedit_cb ( t , d )
  
  % MET controller constants
  global  MCC
  
  % Receptive/response field property definitions
  RFDEF = MCC.DAT.RFDEF ;
  
  % Get row and column index
  i = d.Indices( 1 ) ;
  j = d.Indices( 2 ) ;
  
  % Property name
  [ vmin , vmax ] = RFDEF {  i  ,  3 : 4  } ;
  
  % Invalid input , revert to previous value
  if  isnan ( d.NewData )  ||  ...
      (  d.NewData < vmin  ||  vmax < d.NewData )
    
    % Min and max property values
    t.Data( i , j ) = d.PreviousData ;
    
    % Report problem and quit callback
    msgbox ( [ 'Invalid value: ' , d.EditData ] , 'Error' )
    return
    
  end % invalid input

end % tabedit_cb


% Close figure
function  figclsreqf_cb ( ~ , ~ )
  
  % Calling figure
  h = gcbf ;
  
  % Verify choice if 'Done' button not pushed
  if  ~ h.UserData.done
    
    s = 'Close RF manager?' ;
    s = questdlg ( s , '' , 'Yes' , 'No' , 'No' ) ;
    
    % User thought again
    if  isempty ( s )  ||  strcmp ( s , 'No' )  ,  return  ,  end
    
  end
  
  % Make figure disappear
  h.Visible = 'off' ;
  
  % Allow uiwait blocked on schedule builder to continue
  uiresume ( h )
  
end % figclsreqf_cb


%%% Subroutines %%%

% Updates the string of the variable label to show which column is selected
function  updatelabel ( h )
  
  % Find variable label
  v = findobj ( h , 'Style' , 'text' , 'Tag' , 'variable' ) ;
  
  % Convert column index to string
  v.String = num2str (  h.UserData.select  ) ;
  
end % updatelabel

