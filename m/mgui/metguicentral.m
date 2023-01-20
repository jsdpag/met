
function  h = metguicentral ( H , mrstart )
% 
% h = metguicentral ( H , mremote )
% 
% Creates MET GUI Central, a control panel that allows the user to toggle
% the visibility of all loaded MET gui's on and off. It also provides a
% File menu for creating, copying, opening and closing MET sessions, and an
% option to close MET.
% 
% H is a vector of figure handles. Each figure gets its own visibility
% toggle button. The state of MET Remote's start (Run task , green
% triangle) button affects the availability of File options ; these are not
% available when a trial is running. mrstart is the uicontrol handle to
% the start toggle button.
% 
% To interface with metgui, MET GUI Central has a struct in its UserData
% with fields .guiflg (0 or 1) to signal that new data is ready and .sd
% (session descriptor) to convey that data. Field .mquit is initialised 0 ;
% it becomes 1 when the user chooses to shut down MET. Field .reset will
% contain a list of handles to MET GUIs that the user has requested to be
% reset.
% 
% Written by Jackson Smith - Sept 2016 - DPAG , University of Oxford
% 
  
  
  %%% Check input %%%
  
  if  ~ isa ( H , 'matlab.ui.Figure' )
    
    meterror (  'metguicentral: H is not figure'  )
    
  elseif  ~ isscalar ( mrstart )  ||  ...
      ~ isa ( mrstart , 'matlab.ui.control.UIControl' )  ||  ...
      ~ strcmp ( mrstart.Style , 'togglebutton' )
    
    meterror (  ...
      'metguicentral: mrstart must be a scalar togglebutton uicontrol'  )
    
  end
  
  
  %%% Global Constants %%%
  
  global  MC  MCC
  
  % If these haven't been set yet then set them. Note , only compile-time
  % MET constants asked for if not already declared.
  if  isempty (  MC )  ,   MC = met ( 'const' , 1 ) ;  end
  if  isempty ( MCC )  ,  MCC = metctrlconst    ;  end
  
  
  %%% Constants %%%
  
  % Title
  TITBAR = 'MET GUI Central' ;
  
  % Figure width and height, in centimetres
  FIGWH = [ 5 , 8 ] ;
  
  % Toggle button height , in centimetres
  TOGLBH = 0.75 ;
  
  % Toggle button border , in centimetres
  TOGBRD = 0.15 ;
  
  % Slider width , in centimetres
  SLIDRW = 0.5 ;
  
  % Slider and button colour
  SABCOL = 0.4 * [ 1 , 1 , 1 ] ;
  
  % File sub-menu name , separator line , callback, and c.b. argument
  FSMNAM = { 'New session' , 'Open session' , 'Clone session' , 'Quit' } ;
  FSMSEP = { 'off' , 'off' , 'off' , 'on' } ;
  FSMCLB = { @session_cb , @session_cb , @session_cb , @mgcclsreq_cb } ;
  FSMCBA = { { 'New'   , mrstart } ;
             { 'Open'  , mrstart } ;
             { 'Clone' , mrstart } ; 
                       { mrstart } } ;
                     
	% MET timer object error ID and string
  TIMEID = 'MET:metguicentral:mquit' ;
  TIMSTR = 'metguicentral: mquit received during modal callback' ;
  
  
  %%% Create figure %%%
  
  % Initialise UserData return session descriptor via metgui
  s = struct ( 'guiflg' , false , 'sd' , MCC.DAT.SD , 'mquit' , false , ...
    'timer' , mettimerobj( TIMEID , TIMSTR ) , 'reset' , gobjects( 0 ) ) ;
  
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Units' , 'centimeters' , 'Visible' , 'off' , 'UserData' , s , ...
    'Resize' , 'off' , 'DockControls' , 'off' ) ;
  
  % Set figure dimensions and get position
  h.Position( 3 : 4 ) = FIGWH ;
  hp = h.Position ;
  
  
  %%% Make toggle button panel and slider %%%
  
  % Panel width
  pw = hp( 3 )  -  SLIDRW ;
  
  % Panel height , a function of how many MET guis there are.
  ph = numel ( H ) * ( TOGLBH + TOGBRD )  +  TOGBRD ;
  
  % If panel height is less than figure , then crop figure
  if  ph  <  hp ( 4 )
    h.Position( 4 ) = ph ; 
    hp = h.Position ;
    
    % This might seem redundant , but figure position is rounded to nearest
    % pixel
    ph = hp ( 4 ) ;
  end
  
  % Panel vertical position
  pv = hp( 4 )  -  ph ;
  
  % Make panel
  p = uipanel ( h , 'Units' , 'centimeters' , 'BackgroundColor' , 'k' , ...
    'Position' , [ 0 , pv , pw , ph ] , 'BorderType' , 'none' ) ;
  
  % Disable slider if we don't need it
  if  ph  <=  hp( 4 )
    e = 'off' ;
  else
    e = 'on' ;
  end
  
  % Make slider if buttons extend past edge of figure , pv will be negative
  % or zero
  if  pv
    
    uicontrol ( h , 'Style' , 'slider' , 'BackgroundColor' , SABCOL , ...
      'Units' , 'centimeters' , ...
      'Position' , [ pw , 0 , SLIDRW , hp( 4 ) ] , ...
      'Min' , 0 , 'Max' , -pv , 'Value' , -pv , ...
      'SliderStep' ,  ( TOGLBH + TOGBRD ) * [ 0.1 , 1 ] , ...
      'Callback' , { @slider_cb , p } , 'Enable' , e )
  
  else
    
    % No slider , so centre panel in figure
    p.Position( 1 ) = SLIDRW / 2 ;
    
  end
  
  
  %%% Populate button panel %%%
  
  for  i = 1 : numel ( H )
    
    % Button position
    upos = [ TOGBRD , ph - i * ( TOGLBH + TOGBRD ) , ...
      pw - 2 * TOGBRD , TOGLBH ] ;
    
    % Make button
    b = uicontrol ( p , 'Style' , 'togglebutton' , ...
      'String' , H( i ).Name , ...
      'BackgroundColor' , SABCOL , 'ForegroundColor' , 'w' , ...
      'Units' , 'centimeters' , 'Position' , upos , 'Value' , 1 , ...
      'Callback' , @tbttn_cb , 'UserData' , H( i ) ) ;
    
    % Figure close button will only render it invisible , and pop out the
    % toggle button
    H( i ).CloseRequestFcn = { @figclsreq_cb , b } ;
    
  end % buttons
  
  
  %%% Make a File menu %%%
  
  % File
  m = uimenu ( h , 'Label' , 'File' , 'Callback' , @file_cb , ...
    'UserData' , mrstart ) ;
  
  % Sub-menu items
  for  i = 1 : numel ( FSMNAM )
    
    uimenu ( m , 'Label' , FSMNAM { i } , 'Separator' , FSMSEP { i } , ...
      'Callback' , [ FSMCLB( i ) , FSMCBA{ i } ] )
    
  end % sub-menu
  
  
  %%% Make a Reset menu %%%
  
  % Reset
  m = uimenu ( h , 'Label' , 'Reset' , 'Callback' , @file_cb , ...
    'UserData' , mrstart ) ;
  
  % Add first item that resets all MET GUIs
  uimenu ( m , 'Label' , 'All' , 'Separator' , 'off' , ...
      'Callback' , @reset_cb , 'UserData' , H )
    
  % Enable separator on the first item that follows , but no other
  FSMSEP = [  { 'on' }  ,  repmat( { 'off' } , 1 , numel( H ) - 1 )  ] ;
  
  % Add an item for each individual MET GUI
  for  i = 1 : numel ( H )
    
    uimenu ( m , 'Label' , H( i ).Name , 'Separator' , FSMSEP{ i } , ...
      'Callback' , @reset_cb , 'UserData' , H( i ) )
    
  end % add menu items
  
  
  %%% Close button behaviour %%%
  
  h.CloseRequestFcn = { @mgcclsreq_cb , mrstart } ;
  
  
  %%% Done %%%
  
  % Make MET GUI Central visible
  h.Visible = 'on' ;
  
  
end % metguicentral


%%% Callbacks %%%

% Slider changes button panel's vertical position
function  slider_cb ( h , ~ , p )
  
  p.Position ( 2 ) = -h.Value ;
  
end % slider_cb


% Toggle button affects visibility of associated figure , f
function  tbttn_cb ( h , ~ )
  
  if  h.Value
    h.UserData.Visible = 'on' ;
  else
    h.UserData.Visible = 'off' ;
  end
  
end % tbttn_cb


% File menu - disables sub-menu if play button pressed
function  file_cb ( h , ~ )
  
  % Select Enable property value for children
  if  h.UserData.Value
    e = 'off' ;
  else
    e = 'on' ;
  end
  
  % Enable/Disable sub-menu
  set ( h.Children , 'Enable' , e )
  
end % file_cb


% Reset menu item , adds MET GUI handles to list of guis that need to be
% reset
function  reset_cb ( h , ~ )
  
  % Get calling figure
  f = gcbf ;
  
  % Add MET GUI handle to reset list
  f.UserData.reset = [  f.UserData.reset  ,  h.UserData  ] ;
  
end % reset_cb


% MET gui figure's close button , close request merely makes the figure
% invisible and pops out the toggle button
function  figclsreq_cb ( h , ~ , b )
  
  b.Value = 0 ;
  h.Visible = 'off' ;
  
end % figclsreq_cb


% MET GUI Central's close button , ask user to confirm action , no close if
% MET Remote's start button is down
function  mgcclsreq_cb ( ~ , ~ , b )
  
  % The figure
  fh = gcbf ;
  
  % Start MET timer
  start (  fh.UserData.timer  )
  
  % Start i.e. Run Task button pressed , no quit
  if  b.Value  ,  return  ,  end
  
  % Confirm choice
  q = 'Shutdown Matlab Electrophysiology Toolbox?' ;
  s = questdlg ( q , 'MET' , 'Yes' , 'No' , 'No' ) ;
  
  % Don't shut down
  if  isempty ( s )  ||  strcmp ( s , 'No' )
    
    % Stop MET timer and terminate callback
    stoptimer (  fh.UserData.timer  )
    return
    
  end % no shut down
  
  % Signal shutdown
  h = gcbf ;
%   h.UserData.guiflg( 1 ) = true ; Reserve guiflg to signal new sd
   h.UserData.mquit( 1 ) = true ;
   
  % Finalise current session directory
  finalise ( h.UserData.sd )
  
  % Stop and destroy the timer
  stoptimer (  fh.UserData.timer  )
  delete (  fh.UserData.timer  )
  
end % mgcclsreq_cb


% Session-handling callback , called by File -> New session, Open session,
% Clone session. Arguments are a string command and MET Remote start button
% handle
function  session_cb ( ~ , ~ , cmd , b )
  
  
  %-- Global constants --%
  
  % Get MET constants and MET controller constants
  global  MC  MCC
  
  
  %-- Initialisation --%
  
  % Disable MET Remote start button , no session allowed to run while
  % session handling occurs
  b.Enable = 'off' ;
  
  % Make a fresh session descriptor
  sd = MCC.DAT.SD ;
  
  % The figure
  fh = gcbf ;
  
  
  %-- Start MET timer --%
  
  start (  fh.UserData.timer  )
  
  
  %-- Get session directory --%
  
  % Ask user to select a session directory if Open or Clone
  if  any ( strcmp ( cmd , { 'Open' , 'Clone' } ) )
    
    % Open , search from subject directory. Clone , use current parent
    % dir , if available.
    if  isempty ( fh.UserData.sd.session_dir )  ||  cmd( 1 )  ==  'O'
      pathnam = MCC.DEFSUB ;
    else
      pathnam = fileparts (  fh.UserData.sd.session_dir  ) ;
    end
    
    % User selects directory
    pathnam = uigetdir ( pathnam , [ cmd , ' MET session' ] ) ;
    
    % User cancelled or closed directory dialogue
    if  all (  ~ pathnam  )
      scberr ( 'No session dir selected.' , [ cmd ' MET session'] , ...
        fh , b )
      return
    end  %  directory error
    
    % Check if directory is a valid session directory
    try
      
      metsdpath ( pathnam )
      
    catch  E
      
      % How we handle a finalised session depends on intent. Cloning is
      % fine. Opening is very, very naughty.
      if  ~ (  strcmp ( cmd , 'Clone' )  &&  ...
               strcmp (  E.identifier  ,  'MET:metsdpath:finalise'  )  )
        
        scberr ( getReport ( E ) , [ cmd ' MET session'] , fh , b )
        return
      
      end
      
    end % verify session directory
    
    % The session descriptor has been or will be saved to this file
    sdfile = fullfile (  pathnam  ,  MCC.SDFNAM  ) ;
    
    % Different steps now for each command
    switch  cmd
      
      case  'Open'
        
        % Make sure session descriptor file exists. We will abort if it
        % does not.
        if  ~ exist (  sdfile  ,  'file'  )  ||  ...
            isempty ( whos(  '-file'  ,  sdfile  ,  'sd'  ) )
          
          scberr (  sprintf ( ...
            'Missing or invalid session descriptor file %s' ,...
              sdfile )  ,  [ cmd ' MET session']  ,  fh  ,  b  )
          return
          
        end % check sessdesc.mat
        
        % Load session descriptor
        sd = metdload ( MC , MCC , pathnam , '1' , 'sd' , ...
          'metguicentral' , true ) ;
        
      case  'Clone'

        % Extract subject data , date , experiment and session id, and tags
        sd = parsdirnam ( MCC , sd , pathnam ) ;

        % Check directory error
        if  isempty ( sd )
          
          scberr (  [ 'Session dir not valid:\n' , pathnam ]  ,  ...
            [ cmd ' MET session']  ,  fh  ,  b  )
          return
          
        end % directory err

        % Store session directory name in new session descriptor
        sd.session_dir = pathnam ;
    
        % Parse session directory , stimulus definition type strings are
        % obtained in the New and Clone section below
        try

          [ sd.logic , ...
              sd.vpar , ...
                sd.task , ...
                  sd.var , ...
                    sd.block , ...
                      sd.evar ] = metparse ( sd.session_dir ) ;

        catch  E

          scberr ( getReport ( E ) , [ cmd ' MET session'] , fh , b )
          return

        end % parse session dir

        % If session descriptor has been saved to disk then ...
        if  exist (  sdfile  ,  'file'  )  &&  ...
            ~ isempty ( whos(  '-file'  ,  sdfile  ,  'sd'  ) )

          % ... retrieve old descriptor from file.
          sd_old = metdload ( MC , MCC , ...
            pathnam , '1' , 'sd' , 'metguicentral' , true ) ;

          % Make enough rfdef elements to read in the old data
          sd.rfdef = MCC.DAT.RFDEF( : , 1 : 2 )' ;
          sd.rfdef = struct (  sd.rfdef{ : }  ) ;
          sd.rfdef = repmat (  sd.rfdef  ,  size ( sd_old.rfdef )  ) ;

          % Copy old session's RF definition data , looping field names
          % then elements
          for  F = fieldnames ( sd_old.rfdef )'  ,  f = F { 1 } ;
            for  i = 1 : numel (  sd_old.rfdef  )

              sd.rfdef( i ).( f ) = sd_old.rfdef( i ).( f ) ;

            end
          end

          % ... and copy the environment variables and RF definitions
          sd.rfdef = sd_old.rfdef ;
          sd.evar  = sd_old.evar  ;

        end % load sd or parse it
    
    end % Open or Clone , branching action
    
  end % ask for session dir
  
  
  %-- Build session --%
  
  % If New or Clone then use MET subject dialogue to specify or confirm
  % session directory
  if  any ( strcmp ( cmd , { 'New' , 'Clone' } ) )
    
    % Show subject dialogue , then RF manager , and show session dialogue
    for  i = 1 : 3
    
      % Choose which dialogue to open
      switch  i
        
        % MET subject dialogue , determine which subject , date ,
        % experiment and session IDs , and tags
        case  1  ,  hdlg = metsubjdlg ( cmd , sd , true ) ;
          
        % MET RF manager , allows user to define RF preferences so that
        % stimuli will automatically match their properties
        case  2  ,  hdlg = metrfmanager ( sd , true ) ;
        
        % Open session builder , either to define a session from scratch or
        % to modify the cloned version in some way
        case  3  ,  hdlg = metsessdlg ( sd , true ) ;
        
      end % choose dialogue
      
      % Make sure that MET GUI is grabbable
      metcheckgui ( hdlg ) ;
      
      % Wait for user to hit 'Done' , 'Cancel' , or 'Close' button
      uiwait ( hdlg ) ;

      % Get outcome
      done = hdlg.UserData.done ;

      % Harvest data from dialogue
      if  done
        
        % Always get updated session descriptor
        sd = hdlg.UserData.sd ;
        
        % Session dialogue also returns schedule.txt string
        if  i == 3  ,  sched = hdlg.UserData.sched ;  end
        
      end % harvest
      
      % Remove dialogue from memory
      delete ( hdlg )

      % User clicked cancel or close
      if  ~ done
        scberr ( 'No session created' , [ cmd ' MET session'] , fh , b )
        return
      end
    
    end % dialogues
    
    % Harvest task logic and stimulus definition file names
    tlogic = metgetfields (  sd.logic  ,  'file'  ) ;
    stimdef = cellfun ( @( s )  metgetfields ( s.link , 'def' )  ,  ...
       struct2cell ( sd.task )  ,  ...
      'UniformOutput' , false ) ;
    stimdef = unique ( [  stimdef{ : }  ] ) ;
    
    % Make new session directory
    [ i , E ] = ...
      metmkdir (  sd.session_dir  ,  tlogic  ,  stimdef  ,  sched ) ;
    
    if  i
      scberr ( [ 'New sess dir: ' , E ] , [ cmd ' MET session'] , fh , b )
      return
    end
    
    % Refresh variable parameter list from session's stimulus definitions
    sd.vpar = metparse (  fullfile ( sd.session_dir , MC.SESS.STIM )  , ...
      'p'  ,  sd.rfdef  ) ;
    
    % Get the type string of all MET stimulus definitions used by the
    % session
    sd.type = metstimdeftype ( MC , MCC , sd ) ;
    
    % Save the session descriptor as well
    save (  fullfile ( sd.session_dir , MCC.SDFNAM )  ,  'sd'  )
    
    % Make a header file
    header ( sd )
    
  end % session building
  
  
  %-- Refresh & finalise --%
  
  % Write current session directory name to ~/.met/session
  pathnam = fullfile (  MC.ROOT.ROOT  ,  MC.ROOT.SESS  ) ;
  cstr = sprintf (  'echo %s  >  %s'  ,  sd.session_dir  ,  pathnam  ) ;
  [ i , E ] = system (  cstr  ) ;
  
  % A system error requires special treatment. It seems that Matlab GUI
  % callbacks use error( ) that the callback ends and the message appears
  % at the terminal, but the MET controller is not terminated. So, manually
  % kill the process with exit( ).
  if  i
    
    meterror (  [ 'metguicentral: Failed to update %s with current ' , ...
      'session dir path\n  Attempted: %s\n  Got error: %s' ]  ,  ...
      pathnam  ,  cstr  ,  E  )
    
  end % system-level error
  
  % Was there an open session? Finalise it.
  finalise ( fh.UserData.sd )
  
  % Assign the main session descriptor
  fh.UserData.sd = sd ;
  
  % And signal that a new session is now running
  fh.UserData.guiflg = true ;
  
  % Report current session directory
  switch  cmd
    case  'Open'  ,  E = 'Opened' ;
    otherwise     ,  E = 'New' ;
  end
  
  met ( 'print' , ...
        sprintf ( '%s session directory\n  %s' , E , sd.session_dir ) , ...
        'E' )
  
  % Stop MET timer
  stoptimer (  fh.UserData.timer  )
  
  % Re-enable start button
  b.Enable = 'on' ;
  
  
end % session_cb


%%% Sub-routines %%%

function  finalise ( sd )
  

  %%% Check directory %%%
  
  if  ~ exist (  sd.session_dir  ,  'dir'  )
    
    % There is no session directory to finalise
    return
    
  end
  
  
  %%% Global Constants %%%
  
  % MET constants and MET controller constants
  global  MC  MCC
  
  
  %%% Save final copy of session descriptor %%%
  
  sdir = sd.session_dir ;
  save (  fullfile ( sdir , MCC.SDFNAM )  ,  'sd'  )
  
  
  %%% Write footer %%%
  
  footer ( sd )
  
  
  %%% Command strings %%%
  
  str = cell ( 2 , 1 ) ;
  
  
  %%% Flag file %%%
  
  % Full path to .finalise
  str{ 1 } = fullfile (  sdir  ,  MC.SESS.FIN  ) ;
  
  % System command string
  str{ 1 } = [ '>  ' , str{ 1 } ] ;
  
  
  %%% Recursively remove write permissions %%%
  
  str{ 2 } = [  'chmod  -R  a-w  '  ,  sdir  ] ;
  
  
  %%% Run finalisation commands %%%
  
  for  i = 1 : numel (  str  )
    
    [ stat , cout ] = system (  str { i }  ) ;

    if  stat
      
      meterror (  ...
        'metguicentral: Couldn''t run system command %s\n  %s'  ,  ...
          str { i }  ,  cout  )
      
    end
    
  end % commands
  
  
end % finalise


% session_cb error dialogue and return
function  scberr ( str , tit , fh , b )
  
  uiwait ( msgbox ( str , tit , 'modal' ) )
  
  % Re-enable start button if a session is still running
  if  ~isempty ( fh.UserData.sd.session_dir )
    b.Enable = 'on' ;
  end
  
  % Stop MET timer
  stoptimer (  fh.UserData.timer  )
  
end % scberr


% Extract session information from directory names
function  sd = parsdirnam ( MCC , sd , dpath )

  % No directory given , quit
  if  all ( ~dpath )  ,  return  ,  end
  
  % Split apart directory path to get directory names at each level
  dnames = strsplit ( dpath , filesep ) ;
  
  % There should be three directories at the very least ...
  if  numel ( dnames )  <  3
    
    % Set empty and quit
    sd = [] ;
    return
    
  end
  
  % Take the last three , should be subject's dir , date dir , session dir
  dnames = dnames ( end - 2 : end ) ;
  
  % Regular expression constants
  REX = MCC.REX ;
  
  % Token group names
  T = { 'sub' , 'dat' , 'ses' } ;
  
  % Reg ex names
  R = { 'SUBJECT' , 'DATESTR' , 'SESSDIR' } ;
  
  % Extract info
  for  i = 1 : numel ( T )
    
    rstr = REX.( R{ i } ) ;
    if  i  ==  3  ,  rstr = [ t.sub.subject_id , rstr ] ;  end  %#ok
    
    t.( T{ i } ) = regexp ( dnames { i } , rstr , 'names' ) ;
    
    % Failed to collect
    if  isempty ( t.( T{ i } ) )
      
      % Set empty and quit
      sd = [] ;
      return

    end
    
  end % extract
  
  % Map extracted info into session descriptor
  sd.subject_id = t.sub.subject_id ;
  sd.subject_name = t.sub.subject_name ;
  sd.date = t.dat.date ;
  sd.experiment_id = str2double ( t.ses.experiment_id ) ;
  sd.session_id = str2double ( t.ses.session_id ) ;
  
  if  ~ isempty ( t.ses.tags )
    sd.tags = strsplit ( t.ses.tags ( 2 : end ) , '.' ) ;
  end
  
end % parsdirnam


% A pedantic little function to make sure that the MET timer object has
% truly stopped
function  stoptimer (  t  )
  
  % Stop MET timer
  stop ( t )
  
  % Wait until the timer is off
  while  strcmp ( t.Running , 'on' )
    pause ( t.Period )
  end
  
end % stoptimer


% Function gathers information about the operating environment and saves
% this to the session directory
function  header ( sd )
  

  % MET constants and MET controller constants
  global  MC  MCC
  
  
  %-- Build up session info --%
  
  % Nab subject data from session descriptor
  h.subject_id = sd.subject_id ;
  h.subject_name = sd.subject_name ;
  h.experiment_id = sd.experiment_id ;
  h.session_id = sd.session_id ;
  h.session_dir = sd.session_dir ;
  h.tags = '' ;
  if  iscell ( sd.tags )
    h.tags = strjoin (  sd.tags  ,  ' , '  ) ;
  end
  
  % Get names of session components
  C = { 'logic' , 'task' ,    'vpar' ,     'var' , 'block' ;
        'logic' , 'task' , 'stimdef' , 'taskvar' , 'block' } ;
  h = fieldmapper ( h , sd , C ) ;
  
  % Add RF definition data
  for  F = MCC.DAT.RFDEF( : , 1 )'  ,  f = F{ 1 } ;
    
    h.( [ 'RFdef_' , f ] ) = [ sd.rfdef.( f ) ] ;
    
  end % rf definitions
  
  % Get date string and time
  h.date = sprintf (  '%04d/%02d/%02d , %02d:%02d:%02d'  ,  ...
    round ( clock )  );
  
  % Matlab's time value
  h.matlab_now = now ;
  
  % PsychToolbox time value
  h.ptb_getsecs = GetSecs ;
  
  % Local system information
  [ i , h.system ] = system ( 'uname -a' ) ;
  if  i
    meterror (  ...
      'metguicentral: failed to run uname -a\n  Got error: %s'  ,  ...
        h.system  )
  end
  h.system = regexprep ( h.system , '\n$' , '' ) ;
  
  % Computer type and endian-ness
  [ h.matlab_arch , h.matlab_maxsize , h.endian ] = computer ;
  
  % Screen physical properties
  C = {   'width' , 'scrn_width_mm'                  ;
         'height' , 'scrn_height_mm'                 ;
        'subdist' , 'subject_scrn_dist_mm'           ;
          'touch' , 'istouchscreen'                  ;
        'hmirror' , 'horizontal_scrn_mirroring'      ;
        'vmirror' , 'vertical_scrn_mirroring'        ;
       'screenid' , 'ptb_OpenWindow_ScreenID'        ;
         'stereo' , 'ptb_stereo_mode'                ;
           'rbak' , 'bakgnd_clut_red'                ;
           'gbak' , 'bakgnd_clut_green'              ;
           'bbak' , 'bakgnd_clut_blue'               ;
       'priority' , 'PTB_process_priority'           ;
      'newHeadId' , 'Scrn2Head_newHeadId'            ;
      'newCrtcId' , 'Scrn2Head_newCrtcId'            ;
           'rank' , 'Scrn2Head_rank'                 ;
          'sqwid' , 'photodiode_square_width'        ;
          'sqred' , 'photodiode_square_clut_red'     ;
          'sqgrn' , 'photodiode_square_clut_green'   ;
          'sqblu' , 'photodiode_square_clut_blue'    ;
          'sqwrd' , 'photodiode_square_weight_red'   ;
          'sqwgn' , 'photodiode_square_weight_green' ;
          'sqwbl' , 'photodiode_square_weight_blue'  }' ;
  h = fieldmapper ( h , metscrnpar , C ) ;
  
  if  h.ptb_OpenWindow_ScreenID  ==  -1
    h.ptb_OpenWindow_ScreenID = max( Screen(  'Screens'  ) ) ;
  end
  
  % Screen resolution and frame rate
  i = max ( Screen (  'Screens'  ) ) ;
  [ h.scrn_width_px , h.scrn_height_px ] = Screen ( 'WindowSize' , i ) ;
  h.scrn_frame_rate_hz = Screen ( 'FrameRate' , i ) ;
  
  % MET version
  h = catstr ( h , MCC.VERNAM , 'met_version' ) ;
  h.met_version = regexprep ( h.met_version , '\n' , '' ) ;
  
  % MET controller function attributes
  h = catstr ( h , MCC.MRCNTL , 'met_cntlattr' ) ;
  
  % Matlab version
  h.matlab_ver = ver ;
  
  % Get version of PsychToolbox
  h.ptb_version = ...
    regexprep (  PsychtoolboxVersion  ,  '\nFor more info.*'  ,  ''  ) ;
  
  % Save binary header information
  fhdr = fullfile (  sd.session_dir  ,  MC.SESS.HDR  ) ;
  save (  fhdr  ,  'h'  ) ;
  
  
  %-- String version --%
  
  % Fieldname and contents delimiter
  FNCDEL = ':  ' ;
  
  % Reformatting regular expressions
  f = [  '\n'  ,  repmat(  ' '  ,  1  ,  numel ( FNCDEL ) + 12  )  ] ;
  REX = {  { '\n$' , '\n' }  ,  { '' , f }  } ;
  
  % Format MET controller function attributes
  h.met_cntlattr = regexprep ( h.met_cntlattr , REX { : } ) ;
  
  % Format Matlab version
  C = struct2cell ( ver(  'matlab'  ) ) ;
  h.matlab_ver = strjoin ( C , ' , ' ) ;
  
  % Get all field names and allocate a cell array string buffer for
  % contents
  F = fieldnames (  h  ) ;
  C = cell ( size(  F  ) ) ;
  
  % Find char arrays for direct copy
  i = cellfun (  @( f )   ischar ( h.( f ) )  ,  F  ) ;
  C( i ) = cellfun (  @( f ) h.( f )  ,  F( i )  ,  ...
    'UniformOutput'  ,  false ) ;
  
  % Convert numeric array to string
  i = ~ i ;
  C( i ) = cellfun (  @( f )  num2str ( h.( f ) )  ,  F ( i )  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % Bind field names and string contents together
  S = cellfun (  @( f , c )  [ f , FNCDEL , c ]  ,  F  ,  C  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % Collapse into one string
  S = strjoin (  S  ,  sprintf ( '\n' )  ) ;
  
  % ASCII .txt file name
  fhdr = regexprep ( fhdr , 'mat$' , 'txt' ) ;
  
  % Write file
  metsavtxt ( fhdr , S , 'w' , 'metguicentral' )
  
end % header


% Map input struct field values to new fields in h. C is a two row N column
% cell array where row 1 contains the field name of s and row 2 contains
% the field name of h. The function performs
% h.( C{ 2 , i } ) = s.( C{ 1 , i } ) for i = 1 to N.
function  h = fieldmapper ( h , s , C )
  
  for  C = num2cell ( C , 1 )  ,  c = C { 1 } ;
    
    % s's field name
    f = c { 1 } ;
    
    % Gather h's field name
    g = c { 2 } ;
    if  isempty ( g )  ,  g = c { 1 } ;  end
    
    % Join component names together
    if  isstruct (  s.( f )  )
      h.( g ) = strjoin (  fieldnames( s.( f ) )  ,  ' , '  ) ;
    else
      h.( g ) = s.( f ) ;
    end
    
  end % session components
  
end % fieldmapper


% Use system call to cat function in order to return full contents of named
% file as a string to the named field of h
function  h = catstr ( h , ftxt , fnam )
  
  % Read file contents
  [ i , h.( fnam ) ] = system ( [ 'cat ' , ftxt ] ) ;
  
  % Error using cat
  if  i
    
    meterror (  'metguicentral: failed to run cat %s\n  Got error: %s' ,...
      ftxt  ,  h.( fnam )  )
    
  end
  
end % catstr


% Writes footer information to the session directory before finalisation
function  footer ( sd )
  
  % MET constants
  global  MC
  
  % Get block and trial information
  f.block_count = sd.block_id ;
  f.trial_count = sd.trial_id ;
  
  % Retrieve metgui's recovery outc data for the trial outcomes
  fn = fullfile (  sd.session_dir  ,  MC.SESS.REC  ,  'metgui_rec.mat'  ) ;
  
  if  exist ( fn , 'file' )
    load ( fn , 'outc' , 'blk' )
  else
    outc = [] ;
     blk = [] ;
  end
  
  % Outcomes , without ignored
  i = ~ strcmp ( MC.OUT( : , 1 ) , 'ignored' ) ;
  C = MC.OUT ( i , : ) ;
  
  % Count outcomes
  for  i = 1 : size ( C , 1 )
    
    % Outcome name and code
    on = C { i , 1 } ;
    oc = C { i , 2 } ;
    
    % Count
    f.( on ) = sum ( outc  ==  oc ) ;
    
  end % outcomes
  
  % Percent correct , requires correct or failed trials
  if  f.correct  ||  f.failed
    f.percent_corr = f.correct  /  ( f.correct  +  f.failed ) ;
  else
    f.percent_corr = [] ;
  end
  
  % The kept blocks of trials and their number
  f.num_kept_blocks = numel (  blk  ) ;
  f.kept_blocks = blk ;
  
  % Write footer file
  fn = fullfile (  sd.session_dir  ,  MC.SESS.FTR  ) ;
  save ( fn , 'f' )
  
  % Convert to string
  f.kept_blocks = reshape ( f.kept_blocks , 1 , numel( f.kept_blocks ) ) ;
  S = cellfun (  @( f , c )  [ f , ':  ' , num2str( c ) ]  ,  ...
    fieldnames ( f )  ,  struct2cell ( f )  , 'UniformOutput' , false  ) ;
  S = strjoin (  [ S ; { '' } ]  ,  sprintf ( '\n' )  ) ;
  
  % Write text footer file
  fn = regexprep ( fn , 'mat$' , 'txt' ) ;
  metsavtxt ( fn , S , 'w' , 'metguicentral' )
  
  
end % footer

