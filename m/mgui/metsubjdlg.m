
function  h = metsubjdlg ( cmd , sd , modal )
% 
% h = metsubjdlg ( cmd , sd , modal )
% 
% Generates a MET subject selector dialogue. This helps the user to select
% the subject and date directories in which to create new MET sessions.
% This is a MODAL dialogue that hmgc waits for with uiwait. It is very
% important that when the user closes the dialogue, it calls uiresume on
% hmgc. The dialogue must be removed with delete ( h ).
% 
% Input cmd is a string containing 'New' or 'Clone' giving context. sd is
% session descriptor used to initialise dialogue. modal is scalar, if
% non-zero then dialogue is modal.
% 
% The way to use this dialogue is to open it with an empty or initialised
% session descriptor in modal mode. Then call uiwait while the user edits
% the dialogue controls. When the user hits done , cancel , or close then
% the dialogue callback executes uiresume. The calling function can then
% check the dialogue's UserData for two fields. .done is a value that is
% non-zero if the user clicked 'Done'. If the user clicked 'Done' then the
% field .sd will contain a copy of the original session descriptor, but
% with subject*, date, *_id, tags, and session_dir fields updated to match
% the user's input.
% 
% Written by Jackson Smith - Sept 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  global  MCC
  
  % If these haven't been set yet then set them
  if  isempty ( MCC )  ,  MCC = metctrlconst    ;  end
  
  
  %%% Check input %%%
  
  if  ~ischar ( cmd )  ||  ~isvector ( cmd )  ||  ...
      ~ any ( strcmp ( cmd , { 'New' , 'Clone' } ) )
    
    meterror (  'metsubjdlg: cmd not "New" or "Clone"'  )
    
  elseif  isempty ( sd )  ||  ~ isstruct ( sd )  ||  ...
      numel( fieldnames( sd ) ) ~= numel( fieldnames( MCC.DAT.SD ) )  ||...
      ~all ( strcmp ( fieldnames( sd ) , fieldnames( MCC.DAT.SD ) ) )
    
    meterror (  ...
      'metsubjdlg: cmd is "Clone" but no valid session descriptor given'  )
    
  elseif  ~isscalar ( modal )  ||  ...
      ( ~isnumeric ( modal )  &&  ~islogical ( modal ) )
    
    meterror (  'metsubjdlg: modal must be scalar numeric or logical'  )
    
  end
  
  
  %%% Constants %%%
  
  % Title bar
  if  any ( strcmp ( cmd , { 'New' , 'Clone' } ) )
    TITBAR = 'New session' ;
  else
    TITBAR = 'Session' ;
  end
  
  % Window style
  WINSTY = 'normal' ;
  if  modal
    WINSTY = 'modal' ;
  end
  
  % Default spacing between controls and borders , in centimetres
  DEFSPC = 0.25 ;
  
  % Default subject directory
  DEFSUB = MCC.DEFSUB ;
  
  % List control field names
  UICFNM = { 'sdtxt' , 'subdir' , 'subtxt' , 'sub' , 'new' , 'dattxt' , ...
    'dd' , 'mm' , 'yyyy' , 'today' , 'eidtxt' , 'sidtxt' , 'eid' , ...
    'sid' , 'tagtxt' , 'tags' , 'add' , 'min' , 'up' , 'dwn' , 'done' , ...
    'cancel' } ;
  
  % List control strings
  UICSTR = { 'Subject directory' , DEFSUB , 'Select subject' , ...
    { 'none' } , ' New ' , 'Date ' , ' DD ' , ' MM ' , ' YYYY ' , ...
    ' Today ' , 'Exp. ID' , 'Sess. ID' , [] , [] , 'Tags' , [] , ...
    ' + ' , ' - ' , ' Up ' , ' Dn ' , ' Done ' , ' Cancel ' } ;
  
  % List of control styles
  UICSTY = { 'text' , 'edit' , 'text' , 'popupmenu' , 'pushbutton' , ...
    'text' , 'edit' , 'edit' , 'edit' , 'pushbutton' , 'text' , 'text' ,...
    'edit' , 'edit' ,'text' , 'listbox' , 'pushbutton' , 'pushbutton' , ...
    'pushbutton' , 'pushbutton' , 'pushbutton' , 'pushbutton' } ;
  
  % Number of vertical spaces below last control: -1 same level , 0 no
  % space , 1+ times DEFSPC
  UICVSC = [ 1 , 0 , 2 , 0 , -1 , 2 , 0 , -1 , -1 , -1 , 2 , -1 , 0 , ...
    -1 , 2 , 0 , 0 , -1 , -1 , -1 , 2 , -1 ] ;
  
  % Number of horizontal spaces to left , 0 or more , fractions allowed
  UICHSC = ones ( size ( UICFNM ) ) ;
  UICHSC ( [ 8:10 , 12 , 14 , 18 : 20 , 22 ] ) = ...
    [ 0.5 , 0.5 , 1.5 , 2 , 2 , 0 , 0 , 0 , 2 ] ;
  
  % Control callbacks
  UICCBK = { [] , @subdir_cb , [] , @sub_cb , @new_cb , [] , @date_cb , ...
    @date_cb , @date_cb , @today_cb , [] , [] , @esid , @esid , [] , ...
    [] , @addtag_cb , @rmtag_cb , @shift_cb , @shift_cb , ...
    @done_cb , @done_cb } ;
  
  
  %%% Generate figure %%%
  
  % User data , for input and output from dialogue
  s = struct ( 'sd' , sd , 'done' , false , 'c' , [] ) ;
  
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Units' , 'centimeters' , 'Visible' , 'off' , ...
    'Resize' , 'on' , 'DockControls' , 'off' , ...
    'WindowStyle' , WINSTY , 'UserData' , s ) ;
  
  clear  s
  
  
  %%% Add controls %%%
  
  % Initialise horizontal and vertical positions
  hp = 0 ;
  vp = h.Position ( 4 ) ;
  
  for  i = 1 : numel ( UICFNM )
    
    % Generate
    u = uicontrol ( h , 'Style' , UICSTY{ i } , ...
      'Units' , 'centimeters' , 'ForegroundColor' , 'w' , ...
      'BackgroundColor' , 'k' , 'Callback' , UICCBK{ i } ) ;
    
    % Make list box taller
    if  strcmp ( u.Style , 'listbox' )
      u.Position ( 4 ) = 3  *  u.Position( 4 ) ;
    end
    
    % Adjust vertical position
    if  -1  <  UICVSC( i )
      
      vp = vp  -  u.Position( 4 )  -  UICVSC( i ) * DEFSPC ;
      
      % New 'line' so wind back horizontal
      hp = 0 ;
      
    end
    
    % Horizontal position
    hp = hp  +  UICHSC( i ) * DEFSPC ;
    
    % Set position , advance horizontal
    u.Position ( 1 : 2 ) = [ hp , vp ] ;
    
    % If text , pushbutton , or edit box with string then adjust width to
    % accomodate all characters
    if  any ( strcmp ( u.Style , { 'text' , 'pushbutton' } ) )  ||  ...
      ( strcmp ( u.Style , 'edit' )  &&  ~isempty ( UICSTR { i } ) )
      
      u.Units = 'characters' ;
      u.Position ( 3 ) = 1.25 * numel ( UICSTR { i } ) ;
      u.Units = 'centimeters' ;
      
    end
    
    % Left align text string
    if  strcmp ( u.Style , 'text' )
      u.HorizontalAlignment = 'left' ;
    end
    
    % Update horizontal position for next control
    hp = hp  +  u.Position ( 3 ) ;
    
    % Set string
    if  ~ isempty ( UICSTR { i } )  ,  u.String = UICSTR { i } ;  end
    
    % Store in struct for setting behaviours
    s.( UICFNM{ i } ) = u ;
    
  end % add controls
  
  % Keep convenient access to controls
  h.UserData.c = s ;
  
  
  %%% Adjustments %%%
  
  % Find right most edge of today button
  hp = sum ( s.today.Position( [ 1 , 3 ] ) ) ;
  
  % Stretch out some controls
  s.subdir.Position( 3 ) = hp  -  s.subdir.Position( 1 ) ;
  s.tags.Position( 3 ) = s.subdir.Position( 3 ) ;
  
  % Match new button horizontal position with today
  s.new.Position ( [ 1 , 3 ] ) = s.today.Position ( [ 1 , 3 ] ) ;
  
  % Stretch drop-down menu
  s.sub.Position( 3 ) = s.new.Position ( 1 ) - ...
    sum( UICHSC ( 4 : 5 ) ) * DEFSPC ;
  
  % Subject dir , left alignment of text
  s.subdir.HorizontalAlignment = 'left' ;
  
  % Distribute Exp and Sess ID
  w = ( hp  -  sum ( UICHSC( 11 : 12 ) ) * DEFSPC )  /  2 ;
  s.eid.Position( 3 ) = w ;  s.sid.Position( 3 ) = w ;
  s.sid.Position( 1 ) = s.eid.Position( 1 ) + w + UICHSC( 12 ) * DEFSPC ;
  s.sidtxt.Position( 1 ) = s.sid.Position( 1 ) ;
  
  % Match done and cancel button size , then distribute
  s.done.Position( 3 ) = s.cancel.Position( 3 ) ;
  
  w = ( hp - s.done.Position( 1 ) - 2 * s.done.Position( 3 ) )  /  3 ;
  s.done.Position( 1 ) = s.done.Position( 1 )  +  w ;
  s.cancel.Position( 1 ) = sum ( s.done.Position( [ 1 , 3 ] ) )  +  w ;
  
  % Resize figure
  h.Position( 3 ) = hp  +  DEFSPC ;
  h.Position( 4 ) = sum ( [ s.sdtxt.Position( [ 2 , 4 ] ) , ...
    -s.done.Position( 2 ) , 2 * DEFSPC ] ) ;
  
  % And adjust vertical positions
  vp = s.done.Position( 2 )  -  DEFSPC ;
  for  i = 1 : numel ( h.Children )
    h.Children( i ).Position( 2 ) = h.Children( i ).Position( 2 )  -  vp ;
  end
  
  
  %%% Special default values %%%
  
  % Subjects' directory , inactive and only responds to mouse clicks
  s.subdir.Enable = 'inactive' ;
  s.subdir.ButtonDownFcn = @subdir_click_cb ;
  
  % Subject drop down and date edit boxes assigned default string values
  for  F = { 'subdir' , 'sub' , 'dd' , 'mm' , 'yyyy' } , f = F { 1 } ;
    
    s.( f ).UserData.defstr = s.( f ).String ;
    
  end
  
  % Date edit boxes require minimum and maximum input string length
  s.dd.UserData.dd   = [ 1 , 2 ] ;
  s.dd.UserData.mm   = [ 1 , 2 ] ;
  s.dd.UserData.yyyy = [ 4 , 4 ] ;
  
  % Minimum valid value for experiment and session id edit boxes
  s.eid.UserData.min = 1 ;
  s.eid.UserData.minsid = 1 ;
  s.sid.UserData.min = 1 ;
  
  % Move tags up and down
  s.up.UserData.dir = -1 ;
  s.dwn.UserData.dir = 1 ;
  
  
  %%% Closing behaviour %%%
  
  % Each button associates with an outcome value for UserData.done
    s.done.UserData.doneval = true ;
  s.cancel.UserData.doneval = false ;
  
  % Figure callback
  h.CloseRequestFcn = @( ~ , ~ )  done_cb ( s.cancel , [] ) ;
  
  
  %%% Set default values %%%
  
  % Today's date , non-negotiable
  s.today.Callback ( s.today , [] )
  set ( [ s.dd , s.mm , s.yyyy , s.today ] , 'Enable' , 'inactive' )
  
  % Initialise controls depending on command
  switch  cmd
    
    % New session
    case  'New'
      
      % Use default subject directory and detect subjects
      s.subdir.Callback ( s.subdir , [] )
  
    % Cloning a session
    case  'Clone'
      
      % Set subjects' directory and detect subjects
      s.subdir.String = getsubdir ( sd.session_dir ) ;
      s.subdir.Callback ( s.subdir , [] )
      
      % Set subject and suggest new experiment and session IDs
      s.sub.Value = getsubind ( s.sub , sd ) ;
      s.sub.Callback ( s.sub , [] )
      
      % Set tags
      s.tags.String = sd.tags ;
      
  end % init
  
  
  %%% Done %%%
  
  % Set all controls to normalised units
  u = findobj ( h , 'Type' , 'uicontrol' ) ;
  set ( u , 'Units' , 'Normalized' )
  
  % Make visible
  h.Visible = 'on' ;
  
  
end % metsubjdlg


%%% Callbacks %%%

function  subdir_click_cb ( h , ~ )
  
  % Default dir path
  dpath = h.UserData.defstr ;
  
  % Ask the user to choose a directory
  dpath = uigetdir ( dpath , 'Subjects'' directory' ) ;
  
  % No valid selection , use default
  if  all ( ~ dpath )  ,  dpath = h.UserData.defstr ;  end
  
  % Set control string with dir path
  h.String = dpath ;
  
  % Process selection
  h.Callback ( h , [] )
  
end % subdir_click_cb


function  subdir_cb ( h , ~ )
  
  % Global constants
  global  MCC
  
  % Local constant - subject dropbox control
  sub = h.Parent.UserData.c.sub ;
  
  % Check that entry is valid directory
  if  ~ isempty ( h.String )  &&  ~ exist ( h.String , 'dir' )
    
    % Inform user
    uiwait ( ...
      msgbox ( [ 'No such directory: ' , h.String ] , ...
        'Subject directory' , 'modal' ) )
    
    % Default string
    h.String = h.UserData.defstr ;
    
  end
  
  % Search for subject directories
  d = lsdir ( h.String , MCC.SCH.SUBJECT , MCC.REX.SUBJECT ) ;
  
  % No directories found
  if  isempty ( d )
    
    % Inform user
    uiwait( msgbox( 'No subjects found' , 'Subject directory' , 'modal' ) )
    
    % Assign default string
    d = sub.UserData.defstr ;
    
  end % no dirs
  
  % Set drop-down box string and update
  sub.Value = 1 ;
  sub.String = d ;
  sub.Callback ( sub , [] )
  
end % subdir_cb


function  sub_cb ( h , ~ )
  
  % Subject directory
  sdir = h.Parent.UserData.c.subdir ;
  
  % Experiment ID edit box
  eid = h.Parent.UserData.c.eid ;
  
  % Session ID edit box
  sid = h.Parent.UserData.c.sid ;
  
  % Date controls
  dd = h.Parent.UserData.c.dd ;
  mm = h.Parent.UserData.c.mm ;
  yy = h.Parent.UserData.c.yyyy ;
  daydir = [ yy.String , mm.String , dd.String ] ;
  daydir = fullfile ( sdir.String , h.String { h.Value } , daydir ) ;
  
  % Exp and sess id edit box strings and minimum values
  eids = '' ;
  sids = '' ;
  eidm =  1 ;
  sidm =  1 ;
  
  % Default session directory information
  d = [] ;
  
  % Subject found and chosen
  sfnd = ~ any ( strcmp ( h.String , h.UserData.defstr ) ) ;
  
  % Enable/Disable exp and sess id input boxes based on whether there are
  % any subjects
  if  sfnd
    set ( [ eid , sid ] , 'Enable' , 'on' )
  else
    set ( [ eid , sid ] , 'Enable' , 'off' )
  end
  
  % Make sure that subject directory still exists
  if  sfnd  &&  ...
      ~ exist ( fullfile ( sdir.String , h.String { h.Value } ) , 'dir' )
    
    % Inform user
    uiwait( ...
      msgbox( [ h.String{ h.Value } , ' doesn''t exist' ] , ...
        'Select subject' , 'modal' ) )
    
    % Only one item in list , so return to default
    if  numel ( h.String )  ==  1
      
      h.String = h.UserData.defstr ;
      
    else
      
      % Remove subject from list
      i = h.Value ;
      h.Value = 1 ;
      h.String = [ h.String( 1 : i - 1 ) , ...
                   h.String( i + 1 : end ) ] ;
      
    end
    
    % Quit
    return
    
  end
  
  % Parse information from session directory names
  if  sfnd
    
    % Search all sessions from this subject
    d = parsdir ( sdir.String , h.String { h.Value } ) ;
    
  end % subject found
  
  % Session directories found , get maximum existing experiment and session
  % ID + 1
  if  ~ isempty ( d )
    
    % Full list of experiment ids
    E = [ d.experiment_id ] ;
    
    % Find minimum experiment id that new session may have
    eidm = max ( E ) ;
    
    % Add 1 to this if there are no sessions done today
    eidm = ~ exist ( daydir , 'dir' )  +  eidm ;
    
    % Locate sessions with this experiment id
    i  =  E == eidm  ;
    
    % Find maximum session id
    if  any ( i )
      
      sidm = max ( [ d( i ).session_id ] )  +  1 ;
      
    end
    
  end % maximum exp and sess ids
  
  % Subject was selected
  if  sfnd
    
    % Convert numeric values to strings
    eids = num2str ( eidm ) ;
    sids = num2str ( sidm ) ;
    
  end
  
  % Assign experiment and session id strings and minimum allowable values
  eid.String = eids ;
  eid.UserData.min = eidm ;
  
  sid.String = sids ;
  sid.UserData.min = sidm ;
  eid.UserData.minsid = sidm ;
  
  % Remember subject directory data for later
  h.UserData.d = d ;
  
end % sub_cb


function  new_cb ( h , ~ )
  
  % Global constants
  global  MCC
  
  % Ask user for subject ID and name
  s = inputdlg ( { 'Subject ID' , 'Subject Name' } , 'New subject' ) ;
  
  % Close or cancel
  if  isempty ( s )  ,  return  ,  end
  
  % Build subject directory name
  newdir = sprintf ( MCC.FMT.SUBJECT , s { : } ) ;
  
  % Check that it parses
  rex = [ '^' , MCC.REX.SUBJECT , '$' ] ;
  p = regexp ( newdir , rex , 'names' ) ;
  
  % Input failed to parse
  if  isempty ( p )
    
    % Inform user of error
    s = sprintf ( 'Not valid\n  ID: "%s"\n  Name: "%s"' , s { : } ) ;
    uiwait( msgbox( s , 'New subject' , 'modal' ) )
    
    % Quit
    return
    
  end
  
  
  %-- Check that subject id and name are unique --%
  
  % Access subject directory field , this will be used later
  c = h.Parent.UserData.c ;
  
  % Search for subject directories
  d = dir (  fullfile ( c.subdir.String , MCC.SCH.SUBJECT )  ) ;
  
  % Pull out subject ids and names into a struct array
  d = regexp ( { d.name } , rex , 'names' ) ;
  d = [ d{ : } ] ;
  
  % Search for the given subject id
  s = '' ;
  if  any ( strcmpi(  p.subject_id  ,  { d.subject_id }  ) )
    
    s = sprintf (  'Subject ID %s already used in subjects dir %s'  ,  ...
      p.subject_id  ,  c.subdir.String  ) ;
    
  % Search for given subject name
  elseif  any ( strcmpi(  p.subject_name  ,  { d.subject_name }  ) )
    
    s = sprintf (  'Subject name %s already used in subjects dir %s'  , ...
      p.subject_name  ,  c.subdir.String  ) ;
    
  end
  
  % Error detected , inform user and terminate callback
  if  ~ isempty (  s  )
    uiwait( msgbox( s , 'New subject' , 'modal' ) )
    return
  end
  
  
  % Check that subject dir not already used , build full directory path
  fulldir = { c.subdir.String , newdir } ;
  fulldir = fullfile ( fulldir { : } ) ;
  
  % Yes, dir exists
  if  exist ( fulldir , 'dir' )
    
    % Inform user of error
    s = sprintf ( 'Subject %s-%s exists' , s { : } ) ;
    uiwait( msgbox( s , 'New subject' , 'modal' ) )
    
    % Quit
    return
    
  end
  
  % Subject doesn't exist , so make a new subject directory
  [ s , m ] = mkdir ( fulldir ) ;
  
  % Failed to make directory
  if  ~s
    
    % Inform user
    m = sprintf ( 'Make dir %s\n%s' , fulldir , m ) ;
    uiwait( msgbox( m , 'New subject' , 'modal' ) )
    
    % quit
    return
    
  end
  
  % Update subject listing and select new subject
  c.sub.String = [ c.sub.String ; { newdir } ] ;
  c.sub.Value = numel ( c.sub.String ) ;
  c.sub.Callback ( c.sub , [] )
  
end % new_cb


function  date_cb ( ~ , ~ )
end % date_cb


function  today_cb ( h , ~ )
  
  % Global constants
  global  MCC
  
  % Control struct
  c = h.Parent.UserData.c ;
  
  % Query today's date
  [ y , m , d ] = datevec ( now ) ;
  
  % Convert to strings
  y = sprintf ( MCC.FMT.DATESTR , y ) ;
  m = sprintf ( MCC.FMT.DATESTR , m ) ;
  d = sprintf ( MCC.FMT.DATESTR , d ) ;
  
  % Assign to date controls
    c.dd.String = d ;
    c.mm.String = m ;
  c.yyyy.String = y ;
  
end % today_cb


function  esid ( h , ~ )
  
  % Empty string , quit
  if  isempty ( h.String )  ,  return  ,  end
  
  % Convert string to numeric value
  n = str2double ( h.String ) ;
  
  % Can't be less than determined minimum
  if  isnan ( n )  ||  n < h.UserData.min
    
    % Set string to minimum
    h.String = num2str ( h.UserData.min ) ;
    n = h.UserData.min ;
    
  end % min check
  
  % Is this the experiment id edit box?
  if  h.Parent.UserData.c.eid  ==  h
    
    % If new value equals minimum then make sure that session id is the
    % default minimum
    if  n == h.UserData.min  &&  ...
        h.Parent.UserData.c.sid.UserData.min  ~=  h.UserData.minsid
      
      h.Parent.UserData.c.sid.UserData.min = h.UserData.minsid ;
      h.Parent.UserData.c.sid.String = num2str( h.UserData.minsid ) ;
      
    elseif  n > h.UserData.min
      
      % Otherwise new id is greater than minimum , this is a new experiment
      % so the minimum session id should be 1 and the session id edit
      % should also be 1.
      h.Parent.UserData.c.sid.UserData.min = 1 ;
      h.Parent.UserData.c.sid.String = '1' ;
      
    end
    
  end
  
end % esid


function  addtag_cb ( h , ~ )
  
  % Global constants
  global  MCC
  
  % Handle to list box
  tags = h.Parent.UserData.c.tags ;
  
  % Ask user for a new tag
  new = inputdlg ( 'New tag' ) ;
  
  % Close or cancel
  if  isempty ( new )  ,  return  ,  end
  
  % Try parsing
  p = regexp ( new{ 1 } , [ '^' , MCC.REX.TAG , '$' ] , 'once' ) ;
  
  if  isempty ( p )
    
    % Not valid
    new = sprintf ( 'Not valid tag "%s"' , new { 1 } ) ;
    uiwait ( msgbox ( new , 'New tag' ) )
    
    % Quit
    return
    
  end
  
  % Add new tag and select it
  tags.String = [  tags.String  ;  new  ] ;
  tags.Value = numel ( tags.String ) ;
  
end % listval_cb


function  rmtag_cb ( h , ~ )
  
  % Handle to list box
  tags = h.Parent.UserData.c.tags ;
  
  % One item left , set Value 1 , empty string
  if  numel  ( tags.String )  ==  1
    tags.Value = 1 ;
    tags.String = '' ;
  end
  
  % Empty string , quit
  if  isempty ( tags.String )  ,  return  ,  end
  
  % One item left , set Value 1 , empty string and quit
  if  numel  ( tags.String )  ==  1
    
    tags.Value = 1 ;
    tags.String = '' ;
    return
    
  end
  
  % Remember index of selected value
  i = tags.Value ;
  
  % Value should stay the same unless it is at the end of the list
  if  tags.Value  ==  numel ( tags.String )
    
    % Then reduce by 1
    tags.Value = tags.Value  -  1 ;
    
  end
  
  % Delete entry
  tags.String = [ tags.String( 1 : i - 1 ) ; tags.String( i + 1 : end ) ] ;
  
end % listval_cb


function  shift_cb ( h , ~ )
  
  % Tags list box handle
  tags = h.Parent.UserData.c.tags ;
  
  % New position of tag
  i = tags.Value  +  h.UserData.dir ;
  
  % Keep in range
  if  i  <  1
    i = 1 ;
  elseif  numel ( tags.String )  <  i
    i = numel ( tags.String ) ;
  end
  
  % If tag hasn't moved then quit
  if  i  ==  tags.Value  ,  return  ,  end
  
  % Otherwise swap places
  tags.String( [ i , tags.Value ] ) = tags.String( [ tags.Value , i ] ) ;
  tags.Value = i ;
  
end % shift_cb


% Close function , causes MET GUI Central to resume execution , and sets a
% return value to indicate success or failure. This is run by the Done or
% Cancel button
function  done_cb ( h , ~ )
  
  % Assign value to dialogue's UserData.done field
  h.Parent.UserData.done( 1 ) = h.UserData.doneval ;
  
  % Build output session descriptor
  if  h.UserData.doneval  ,  makesd ( h.Parent )  ,  end
  
  % Make dialogue invisible , overcomes modal behaviour in case of error
  h.Parent.Visible = 'off' ;
  
  % Allow MET GUI Central to resume after uiwait
  uiresume ( h.Parent )
  
end % done_cb


%%% Sub-routines %%%

function  makesd ( h )
  
  % Global constants
  global  MCC
  
  % Controls
  c = h.UserData.c ;
  
  % Session descriptor
  sd = h.UserData.sd ;
  
  % Parse subject ID and name
  rex = [ '^' , MCC.REX.SUBJECT , '$' ] ;
  i = c.sub.Value ;
  s = regexp ( c.sub.String { i } , rex , 'names' ) ;
  
  % Subject ID and name
  sd.subject_id   = s.subject_id   ;
  sd.subject_name = s.subject_name ;
  
  % Date
  sd.date = [ c.yyyy.String , c.mm.String , c.dd.String ] ;
  
  % Experiment and session IDs
  sd.experiment_id = str2double ( c.eid.String ) ;
  sd.session_id = str2double ( c.sid.String ) ;
  
  % Tags
  sd.tags = c.tags.String( : )' ;
  
  % Tag string
  if  isempty ( sd.tags )
    s = '' ;
  else
    s = sprintf ( MCC.FMT.TAGSTR , sd.tags { : } ) ;
  end
  
  % Session directory
  s = { sd.subject_id , sd.experiment_id , sd.session_id , s } ;
  s = sprintf ( MCC.FMT.SESSDIR , s { : } ) ;
  
  % Full path
  s = { c.subdir.String , c.sub.String{ i } , sd.date , s } ;
  sd.session_dir = fullfile ( s { : } ) ;
  
  % Store descriptor
  h.UserData.sd = sd ;
  
end % makesd


function  d = parsdir ( dirstr , substr )
  
  % Global constants
  global  MCC
  
  % Parse out subject ID
  sid = regexp ( substr , MCC.REX.SUBJECT , 'names' ) ;
  sid = sid.subject_id ;

  % Subject's directory and all date directories
  s = { dirstr , substr , MCC.SCH.DATESTR } ;
  s = fullfile ( s { 1 : 3 } ) ;

  % Session dir regular expression using subject id
  rex = [ sid , MCC.REX.SESSDIR ] ;

  % Session directories
  d = lsdir ( s , MCC.SCH.SESSDIR , rex ) ;

  % Parse out existing experiment and session IDs
  if  ~ isempty ( d )
    
    d = regexp ( d , rex , 'names' ) ;
    
  end

  % Collapse to struct array
  if  iscell ( d )  ,  d = [ d{ : } ] ;  end

  % Return if empty
  if  isempty ( d )  ,  return  ,  end
  
  % Loop experiment and session id fields
  for  F = { 'experiment_id' , 'session_id' } , f = F { 1 } ;

    % Get cell array of numeric values
    c = num2cell ( str2double ( { d.( f ) } ) ) ;

    % Assign back to struct
    [ d.( f ) ] = c { : } ;

  end % fields
  
end % parsdir


function  d = lsdir ( sdir , sstr , rex )
  
  % Full search string looks in named directory for directories that match
  % the sstr pattern
  s = fullfile ( sdir , sstr ) ;
  
  % Do search , separate file names into elements of a cell aray
  try
    
    d = strsplit ( ls ( '-d' , s ) ) ;
    
  catch
    
    % Couldn't find search string so return empty
    d = [] ;
    return
    
  end
  
  % Remove empty elements
  i = ~ cellfun ( @( c )  isempty ( c ) , d ) ;
  d = d ( i ) ;
  
  % Filter results using regular expression
  d = regexp ( d , rex , 'match' ) ;
  
  % Combine into a single cell array of strings
  d = [ d{ : } ] ;
  
end % lsdir


function  i = getsubind ( sub , sd )
  
  % Global constants
  global  MCC
  
  % Make subject directory name
  s = sprintf ( MCC.FMT.SUBJECT , sd.subject_id , sd.subject_name ) ;
  
  % Find in existing list
  i = find ( strcmp ( s , sub.String ) , 1 , 'first' ) ;
  
end % getsubind


function  sdir = getsubdir ( sdirfull )
  
  sdir = strsplit ( sdirfull , filesep ) ;
  
  for  i = 1 : numel ( sdir )
    if  ~isempty ( sdir { i } )  ,  continue  ,  end
    sdir{ i } = filesep ;
  end
  
  sdir = sdir ( 1 : end - 3 ) ;
  sdir = fullfile ( sdir { : } ) ;
  
end % getsubdir

