
function  h = metsessdlg ( sd , modal )
% 
% h = metsessdlg ( sd , modal )
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
% Written by Jackson Smith - Sept 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  global  MC  MCC
  
  % If these haven't been set yet then set them. Note , only compile-time
  % MET constants asked for if not already declared.
  if  isempty (  MC )  ,   MC = met ( 'const' , 1 ) ;  end
  if  isempty ( MCC )  ,  MCC = metctrlconst    ;  end
  
  
  %%% Check input %%%
  
  % Must provide a valid session descriptor for sd
  if  isempty ( sd )  ||  ~ isstruct ( sd )  ||  ...
      numel( fieldnames( sd ) ) ~= numel( fieldnames( MCC.DAT.SD ) )  ||...
      ~all ( strcmp ( fieldnames( sd ) , fieldnames( MCC.DAT.SD ) ) )
    
    meterror (  ...
      'metsessdlg: cmd is "Clone" but no valid session descriptor given'  )
    
  % Must provide scalar numeric or logical for modal
  elseif  ~isscalar ( modal )  ||  ...
      ( ~isnumeric ( modal )  &&  ~islogical ( modal ) )
    
    meterror (  'metsessdlg: modal must be scalar numeric or logical'  )
    
  end
  
  
  %%% Constants %%%
  
  % MET task logics
  TLOGIC = metparse ( MC.PROG.TLOG , 'l' ) ;
  
  % MET stimulus definition variable parameters
  VARPAR = metparse ( MC.PROG.STIM , 'p' , sd.rfdef ) ;
  
  % Figure title
  TITBAR = 'Schedule builder' ;
  
  % Figure units
  FIGUNI = 'centimeters' ;
  
  % Control spacing
  CNTSPC = 0.25 ;
  
  % Control area width
  CNTWID = 16 ;
  
  % Figure width
  FIGWID = CNTWID + 2 * CNTSPC ;
  
  % Choose windowing style
  WINSTY = 'normal' ;
  if  modal  ,  WINSTY = 'modal' ;  end
  
  
  %%% Generate figure %%%
  
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Units' , FIGUNI , 'Visible' , 'off' , ...
    'Resize' , 'on' , 'DockControls' , 'off' , ...
    'WindowStyle' , WINSTY , 'CloseRequestFcn' , @figclsreqf_cb ) ;
  
  % Set width
  h.Position ( 3 ) = FIGWID ;
  
  % Set struct to user data
  h.UserData = struct ( 'C' , [] , 'task' , [] , 'var' , [] , ...
    'block' , [] , 'evar' , [] , 'sd' , sd , 'sched' , '' , 'done' , 0 ) ;
  
  % Store constants
  h.UserData.C = struct ( 'CNTSPC' , CNTSPC , 'TLOGIC' , TLOGIC , ...
    'VARPAR' , VARPAR ) ;
  
  
  %%% Make exit buttons %%%
  
  % Cancel button
  c = uicontrol ( h , 'Style' , 'pushbutton' , 'String' , 'Cancel' , ...
    'Callback' , @figclsreqf_cb , 'CreateFcn' , ...
    { @exbtncreat_cb , h.Position( 3 ) , 1 } ) ;
  c.TooltipString = 'Do not open a new session.' ;
  
  % View schedule.txt
  c = uicontrol ( h , 'Style' , 'pushbutton' , 'String' , 'View txt' , ...
    'Callback' , { @done_cb , true } , 'CreateFcn' , ...
    { @exbtncreat_cb , c.Position( 1 ) , 0.5 } ) ;
  c.TooltipString = 'View pending schedule.txt for approval' ;
  
  % Done button
  c = uicontrol ( h , 'Style' , 'pushbutton' , 'String' , 'Done' , ...
    'Callback' , { @done_cb , false } , 'CreateFcn' , ...
    { @exbtncreat_cb , c.Position( 1 ) , 0.5 } ) ;
  c.TooltipString = 'Open new session, do not view schedule.txt' ;
  
  % Top of buttons with spaces
  y = sum ( c.Position ( [ 2 , 4 ] ) )  +  2 * CNTSPC ;
  
  
  %%% Make environment variable table %%%
  
  [ h.UserData.evar , y ] = uievar ( h , CNTSPC , y , CNTWID ) ;
  
  % Vertical position of next group , remember that block name edit hangs
  % low ... so to speak
  y = y  +  2 * CNTSPC  +  h.UserData.evar.txt.Position ( 4 ) ;
  
  
  %%%  Make block edit controls %%%
  
  [ h.UserData.block , y ] = uiblock ( h , CNTSPC , y , CNTWID ) ;
  
  % Vertical position of next group
  y = y  +  2 * CNTSPC ;
  
  
  %%% Make task variable table %%%
  
  % Column names
  c = { { 'Name' , 'Task' , 'Type' , 'Object' , 'VarPar' , 'Depend' , ...
    'Dist' , 'Value' } , [] } ;
  c{ 2 } = repmat ( { 'char' } , size ( c{ 1 } ) ) ;
  c{ 2 }{ 3 } = { 'state' , 'stim' , 'sevent' , 'mevent' } ;
  
  % Make
  [ h.UserData.var , y ] = mktable ( h , 'var' , true , ...
    'Task variables' , c{ : } , CNTSPC , y , CNTWID , 4 , 'var' );
  
  % Tool tips
  h.UserData.var.tab.TooltipString = sprintf ( ...
    [ 'Each row defines a task variable. These are added\n' , ...
      'to a block to specify what changes from one trial\n' , ...
      'to the next. Task variables are specific to one\n' , ...
      'named instance of a task. The variable parameters\n' , ...
      'of any linked stimulus definition, the value of a\n' , ...
      'stimulus event, or the Value (i.e. cargo) of a MET\n' , ...
      'signal event may be asked to vary. Multiple values\n' , ...
      'can be entered in Value as a comma-separated list;\n' , ...
      'a comma-separated list can be defined by a colon-\n' , ...
      'separated list with format:\n' , ...
      '<central value>:<number of values>:<spacing>' ] ) ;
    
  % Editable columns
  h.UserData.var.tab.ColumnEditable = false ( size ( c { 1 } ) ) ;
  h.UserData.var.tab.ColumnEditable( [ 1 , 3 , 8 ] ) = true ;
  
  % Adjust column widths to make Values wider
  c = cell2mat ( h.UserData.var.tab.ColumnWidth ) ;
  c( 1 : 7 ) = 6 / 7  *  c( 1 : 7 ) ;
  c( 8 ) = h.UserData.var.tab.Position( 3 )  -  sum ( c ( 1 : 7 ) ) ;
  h.UserData.var.tab.ColumnWidth = num2cell ( c ) ;
  
  % Add callbacks
  h.UserData.var.add.Callback = { @tabadd_cb , 'var' } ;
  h.UserData.var.min.Callback = { @tabmin_cb , 'var' } ;
  
  % Vertical position of next group
  y = y  +  2 * CNTSPC ;
  
  
  %%% Make task controls %%%
  
  [ h.UserData.task , y ] = uitask ( h , CNTSPC , y , CNTWID ) ;
  
  % UserData uilinks to var table
  h.UserData.var.add.UserData.uilink = h.UserData.task.tsklst ;
  h.UserData.var.min.UserData.uilink = h.UserData.task.tskadd ;
  
  % Add top spacer
  y = y  +  CNTSPC ;
  
  
  %%% Touch ups %%%
  
  % Match height of figure to top of controls
  h.Position ( 4 ) = y ;
  
  % Switch to normalised units for UI controls and tables , to ease
  % resizing
  c = [ findobj( h , 'Type' , 'uicontrol' ) ;
        findobj( h , 'Type' ,   'uitable' ) ] ;
  set ( c , 'Units' , 'Normalized' )
  
  % Add names to the logic popup menu
  c = [ h.UserData.task.logpop.String  ;  fieldnames( TLOGIC ) ] ;
  h.UserData.task.logpop.String = c ;
  
  % Initialise task list
  if  ~ isempty ( sd.task )
    c = h.UserData.task.tsklst ;
    set ( c , 'Value' , 1 , 'String' , fieldnames ( sd.task ) )
    c.Callback ( c , [] )
  end
  
  % Initialise task variable table
  if  ~ isempty ( sd.var )

    c = { fieldnames( sd.var ) , ...
      'task' , 'type' , 'name' , 'vpar' , 'depend' , 'dist' , 'value' } ;

    for  i = 2 : numel ( c )
      c{ i } = metgetfields( sd.var , c{ i } )' ;
    end
    c = [ c{ : } ] ;

    for  i = 1 : size ( c , 1 )

      % Bad hack , we want numbers in highest precision that machine can
      % do. Can't figure out how to get the max num of decimal points , so
      % we give a high number. As of MET version 00.03.119 this is removed.
      c{ i , end } =  num2str ( c { i , end } ) ; %, 1000 ) ;
      c{ i , end } = regexprep( c { i , end } , ' +' , ',' ) ;

    end

    h.UserData.var.tab.Data = c ;
    h.UserData.block.varpop.String = [ h.UserData.block.varpop.String ; 
                                       c( : , 1 ) ] ;

  end % init task var table
  
  % Initialise block list
  if  ~ isempty ( sd.block )
    c = h.UserData.block.blklst ;
    set ( c , 'Value' , 1 , 'String' , fieldnames ( sd.block ) )
    c.Callback ( c , [] )
  end % block list
  
  % Initialise environment variables
  c = h.UserData.evar.tab.Data ;
  c( 1 , 1 : numel ( sd.evar.origin ) ) = num2cell ( sd.evar.origin ) ;
  c( 2 , 1 : numel ( sd.evar.disp   ) ) = num2cell ( sd.evar.disp   ) ;
  c( 3 , 1 : numel ( sd.evar.reward ) ) = num2cell ( sd.evar.reward ) ;
  h.UserData.evar.tab.Data = c ;
  
  % Find all Pushbuttons with a plus sign
  c = findobj ( h , 'Type' , 'uicontrol' , 'Style' , 'pushbutton' , ...
    'String' , '+' ) ;
  
  % Temporarily set their strings to 'OK'
  set ( c , 'String' , 'OK' )
  
  % Now make sure that their width matches the extent of that string ,
  % shift leftwards to accommodate
  for  i = 1 : numel ( c )
    y = c( i ).Position( 3 ) ;
    c( i ).Position( 3 ) = 1.1 * c( i ).Extent( 3 ) ;
    c( i ).Position( 1 ) = c( i ).Position( 1 )  -  ...
      c( i ).Position( 3 )  +  y ;
  end
  
  % Reset buttons to have '+' string
  set ( c , 'String' , '+' )
  
  
  %%% Reveal %%%
  
  h.Visible = 'on' ;
  
  
end % metsessdlg


%%% Callbacks %%%

% Environment variables table cell edit
function  evar_cb ( h , d )
  
  % Row and column
  r = d.Indices ( 1 ) ;
  c = d.Indices ( 2 ) ;
  
  % Previous Data , New Data , Edit data
  PD = d.PreviousData ;
  ND = d.NewData ;
  ED = d.EditData ;
  
  % Do not allow dashed cells to change
  if  ischar ( PD )  &&  strcmp ( PD , '---' )
    
    h.Data{ r , c } = d.PreviousData ;
    return
    
  % Empty input string or spaces will cause space to be assigned
  elseif  isempty ( ED )  ||  ~ isempty ( regexp ( ED , '^ *$' , 'once' ) )
    
    h.Data{ r , c } = [] ;
    
    % Also empty any non-dashed cell to the right
    i = ~ strcmp ( h.Data( r , c + 1 : end ) , '---' ) ;
    i = find ( i ) ;
    h.Data( r , c + i ) = { [] } ;
    
    return
  
  % Otherwise, is this a valid number?
  elseif  any ( isnan ( ND )  |  isinf ( ND )  |  ~ isreal ( ND ) )
    
    h.Data{ r , c } = d.PreviousData ;
    return
    
  % There is an empty cell to the left, reject input
  elseif  any (  ...
      cellfun ( @( c ) isempty ( c ) , h.Data( r , 1 : c - 1 ) )  )
    
    h.Data{ r , c } = d.PreviousData ;
    return
    
  end
  
  % Now check validity of input with respect to other values , based on
  % which row
  e = '' ;
  
  switch  h.RowName{ r }
    
    case  'Origin'
      
      % Editing x0 when x1 is full , or editing x1
      if      (  c == 1  &&  ~ isempty ( h.Data{ r , 3 } )  )  ||  c == 3
        
      	if  h.Data{ r , 3 } <= h.Data{ r , 1 }
          e = 'Right extent of origin less than or equal to the left.' ;
        end
        
      % Editing y0 when y1 is full , or editing y1
      elseif  (  c == 2  &&  ~ isempty ( h.Data{ r , 4 } )  )  ||  c == 4
        
        if  h.Data{ r , 2 } <= h.Data{ r , 4 }
          e = 'Bottom extent of origin above or equal to the top.' ;
        end
        
      % Editing gridding value
      elseif  c == 5  &&  ( mod ( d.NewData , 1 )  ||  d.NewData <= 0 )
        
        e = 'Grid number must be positive integer' ;
        
      end
      
    case  'Disparity'
      
      if      1 < c  &&  h.Data{ r , 2 } < h.Data{ r , 1 }
        
        e = 'Far disparity is closer than near.' ;
        
      elseif  c == 3  &&  ( mod ( d.NewData , 1 )  ||  d.NewData <= 0 )
        
        e = 'Space number must be positive integer' ;
        
      end
      
    case  'Reward'
      
      if      c == 1  &&  d.NewData < 0
        
        e = 'Negative baseline reward.' ;
        
      elseif  c == 2  &&  d.NewData <= 0
        
        e = 'Non-positive reward slope.' ;
        
      end
      
  end % rows
  
  if  ~ isempty ( e )
    errmsg ( e ) ;
    h.Data{ r , c } = d.PreviousData ;
    return
  end
  
  
end % evar_cb


% Block variable list buttons
function  blkvarbtn_cb ( h , ~ )
  
  % Figure
  f = h.Parent ;
  
  % Figure block user data
  b = f.UserData.block ;
  
  % Handle to var popup , and var list
  pop = b.varpop ;
  lst = b.varlst ;
  
  % Get selected item from popup
  var = pop.String { pop.Value } ;
  
  % Add variable to list , unless popup shows <empty>
  if  strcmp ( h.String , '+' )  &&  ~ strcmp ( var , '<empty>' )
    
    % Get variable's dependency
    vdep = f.UserData.sd.var.( var ).depend ;

    % Get list of allowable dependency values
    ldep = [  { 'none' ; 'outcome' }  ;  lst.String  ] ;

    % Check variable dependency, if dependent on another task variable
    % then it must already be in this block's list of task variables
    if  ~ any (  strcmp (  vdep  ,  ldep  )  )

      errmsg ( sprintf ( '%s depends on %s which is not listed' , ...
        var , vdep ) )
      return

    end
    
    % List is empty
    if  isempty ( lst.String )
      
      lst.Value = 1 ;
      lst.String = { var } ;
      
    % Append
    else
      
      % Already in list
      if  any ( strcmp ( var , lst.String ) )  ,  return  ,  end
      
      lst.String = [ lst.String ; { var } ] ;
      lst.Value = numel ( lst.String ) ;
      
    end
    
  % Remove item selected in var list, unless list is empty
  elseif  strcmp ( h.String , '-' )  &&  ~ isempty ( lst.String )
    
    % List has one item
    if  1  == numel ( lst.String )
      
      lst.Value = 1 ;
      lst.String = '' ;
      
    % Remove selected item if no other task variable in the list depends on
    % it
    else
      
      % Location in the list
      i = lst.Value ;
        
      % Get dependency and name of all task variables
      [ vdep , var ] = ...
        metgetfields ( h.Parent.UserData.sd.var , 'depend' ) ;

      % Reduce down to list of variables that are dependent on selected
      % variable
      j = strcmp ( vdep , lst.String{ i } ) ;
      var =  var ( j ) ;
       
      % Find subset of listed task variables that are dependent on that
      % which is selected
      var = intersect (  var  ,  lst.String  ) ;
      
      % There are still listed task variables that depend on the selected
      % one
      if  ~ isempty ( var )
        
        errmsg ( sprintf ( 'vars in list still depends on %s: %s' , ...
          lst.String{ i } , strjoin ( var , ' , ' ) ) )
        return
        
      end
      
      % Remove selection
      lst.Value = max ( [ 1 , i - 1 ] ) ;
      lst.String = lst.String ( [ 1 : i - 1 , i + 1 : end ] ) ;
      
    end
    
  else
    
    % No action required
    return
    
  end % button actions
  
  % Assign new list to session descriptor, unless this is a new block.
  if  strcmp ( b.blkadd.String , 'OK' )  ,  return  ,  end
  
  % Find name of block
  nam = b.blklst.String { b.blklst.Value } ;
  
  % Assign new variable set , row cell vector of strings
  f.UserData.sd.block.( nam ).var = lst.String ( : )' ;
  
end % blkvarbtn_cb


% Add all button's callback
function  addall_cb ( h , ~ )
  
  % Figure
  f = h.Parent ;
  
  % Figure block user data
  b = f.UserData.block ;
  
  % Handle to var popup , var list , and add var button
  pop = b.varpop ;
  lst = b.varlst ;
  add = b.varadd ;
  
  % There are no task variables or no blocks , quit now
  if  isempty ( b.blklst.String )  ||  isempty ( pop.String )  ||  ...
      (  numel( pop.String ) == 1  &&  ...
         strcmp( pop.String{ 1 } , '<empty>' )  )
    return
  end
  
  % See which task variables have been added , and look for <empty> string
  i = ismember (  pop.String  ,  lst.String  )  |  ...
    strcmp ( pop.String , '<empty>' ) ;
  
  % Make row vector
  i = reshape ( i , 1 , numel( i ) ) ;
  
  % Add each unlisted variable to the list
  for  i = find ( ~ i )
    
    % Select variable in list of available variables
    pop.Value = i ;
    
    % Add variable to block's list of variables
    add.Callback ( add , [] )
    
  end % add vars
  
  
end % addall_cb


% Block list box , select item shows block's values in block controls
function  blklst_cb ( h , ~ )
  
  % Parent figure
  P = h.Parent ;
  
  % Session descriptor
  sd = P.UserData.sd ;
  
  % UserData block struct
  bu = P.UserData.block ;
  
  % Name , repeat , and attempts edit boxes. Task var popup and list box.
  nam = bu.bnmedt ;
  rep = bu.repedt ;
  atm = bu.atmedt ;
  pop = bu.varpop ;
  lst = bu.varlst ;
  
  % No blocks listed
  if  isempty ( h.String )
    set ( [ nam , rep , atm , lst ] , 'String' , '' )
    pop.Value = 1;
    return
  end
  
  % Block name
  bnam = h.String { h.Value } ;
  
  % Session descriptor block struct
  b = sd.block.( bnam ) ;
  
  % Set of strings
  S = { bnam , num2str( b.reps ) , num2str( b.attempts ) , b.var( : ) } ;
  
  % Apply to controls
  lst.Value = 1 ;
  C = [ nam , rep , atm , lst ] ;
  [ C.String ] = S { : } ;
  
end % blklst_cb


% Task list box , selecting an item causes task controls to be populated
% with data from the session descriptor
function  tsklst_cb ( h , ~ )
  
  % Figure , parent of control
  P = h.Parent ;
  
  % Session descriptor
  sd = P.UserData.sd ;
  
  % UserData task structure
  tu = P.UserData.task ;
  
  % Find all task tables , name edit , and logic popup
  tab = [ tu.link.tab , tu.sevent.tab , tu.mevent.tab , tu.def.tab ] ;
  nam = tu.namedt ;
  log = tu.logpop ;
  
  % List box is empty , so empty everything else
  if  isempty ( h.String )
    set ( tab , 'Data' , [] )
    nam.String = '' ;
    log.Value = 1 ;
    log.UserData.value = 1 ;
    return
  end
  
  % Task name and logic
  tnam = h.String { h.Value } ;
  
  % Task struct
  ts = sd.task.( tnam ) ;
  
  % Get table data where internal structure is the same for different
  % objects , initialise data gathering structure
  D.link   = { [] , 'stim' , 'def' } ;
  D.sevent = { [] , 'state' , 'link' , 'vpar' , 'value' } ;
  D.mevent = { [] , 'state' , 'msignal' , 'cargo' } ;
  
  % Loop fields and replace strings with data returned from named field
  F = fieldnames ( D ) ;
  
  for  i = 1 : numel ( F ) , f = F{ i } ;
    
    % Empty field , assign empty and go to next table
    if  isempty ( ts.( f ) )
      D.( f ) = [] ;
      continue
    end
    
    % Object names
    D.( f ){ 1 } = fieldnames ( ts.( f ) ) ;
    
    % Replace each field name with contents
    for  j = 2 : numel ( D.( f ) )
        
      D.( f ){ j } = metgetfields ( ts.( f ) , D.( f ){ j } )' ;
      
    end % sd fields
    
    % Append together in a single layered cell array
    D.( f ) = [ D.( f ){ : } ] ;
    
  end % D fields
  
  % Default values , different internal structure , get field names and
  % initialise data gathering array
  if  ~ isempty ( ts.def )
    
    F = fieldnames ( ts.def ) ;
    D.def = cell ( 1 , numel ( F ) ) ;

    % Gather values
    for  i = 1 : numel ( F )
      D.def{ i } = { ts.def.( F{ i } ) }' ;
    end

    % Stick together with field names in cell array with one level
    D.def = [ D.def{ : } ] ;
  
  else
    
    D.def = [] ;
    
  end
  
  % Append table data together in another cell array
  D = { D.link , D.sevent , D.mevent , D.def } ;
  
  % Find task logic from popup list and set value
  i = strcmp ( log.String , ts.logic ) ;
  log.Value = find ( i ) ;
  log.UserData.value = log.Value ;
  log.Callback ( log , [] )
  
  % Set name
  nam.String = tnam ;
  
  % Set tables
  [ tab.Data ] = D { : } ;
  
end % tsklst_cb


% Table cell edit callback. Action depends on whether this is a new row. If
% new row being added then any edit is allowed. Otherwise, only Value can
% be changed.
function  tabedit_cb ( h , d )
  
  % If old and new data match then there's no point in doing anything
  if  (  ischar ( d.NewData )  &&  ...
         strcmp ( d.PreviousData , d.NewData )  )  ||  ...
      (  isnumeric ( d.NewData )  &&  ...
         numel ( d.PreviousData ) == numel ( d.NewData )  &&  ...
         all ( d.PreviousData == d.NewData )  )
    
    return
    
  end
  
  % Global constants
  global  MCC
  
  % Constants
  clrset = { 'Stim' , 'Type' , 'Object' , 'VarPar' } ;
  
  % Row and column
  if  2  ~=  numel ( d.Indices )
    meterror (  'metsessdlg: tabedit_cb d.Indices more than 2 elements'  )
  end
  
  row = d.Indices( 1 ) ;
  col = d.Indices( 2 ) ;
  
  % Editing new row? Check add button string. Current row should be last.
  add = h.UserData.uilink ;
  newrow = strcmp ( add.String , 'OK' ) ;
  
  % Column name
  cnam = h.ColumnName { col } ;
  
  % Error checking
  e = '' ;
  
  % If this is not a new row being setup (i.e. add button is '+' , not
  % 'OK') then flag an error if anything other than the 'Value' column is
  % being changed
  if  ~ newrow  &&  ~ strcmp ( cnam , 'Value' )
    
    e = sprintf ( 'Cannot edit %s column\nof existing row' , cnam ) ;
    
  % New row not yet set to descriptor , but the user has selected and
  % entered a value in another row
  elseif  newrow  &&  row < size ( h.Data , 1 )
    
    e = sprintf ( 'Must complete new row first\nHit OK button' ) ;
    
  % Editing 'Name' column
  elseif  strcmp ( cnam , 'Name' )
    
    % Get list of all names for other objects of this type
    nam = lookup ( h , ':' , 'Name' ) ;
    nam = nam ( [ 1 : row - 1 , row + 1 : end ] ) ;
    
    % Format is wrong
    if  badname ( d.EditData )
    
      e = 'Name not valid' ;
      
    % Name already in use
    elseif  any ( strcmp ( d.NewData , nam ) )
      
      e = sprintf ( 'Name %s already in use' , d.NewData ) ;
      
    end
    
  % Editing 'Dist'
  elseif  strcmp ( cnam , 'Dist' )
    
    % Parametric distribution
    if  any ( strcmp ( d.NewData , fieldnames ( MCC.DIST.IND ) ) )
    
      % Session descriptor
      sd = h.Parent.UserData.sd ;

      % Get var par domain
      dom = '' ;
      [ tsk , typ , obj , vpn ] = ...
        lookup ( h , row , { 'Task' , 'Type' , 'Object' , 'VarPar' } ) ;

      % Handle special cases
      switch  typ
        case  'state' , dom = 'f' ;
        case 'mevent' , dom = 'i' ;
        case 'sevent'
          obj = sd.( tsk ).( typ ).( obj ).link ;
      end

      % Find linked stim def and get vpar domain
      if  isempty ( dom )
        def = sd.task.( tsk ).link.( obj ).def ;
        i = strcmp ( vpn , h.Parent.UserData.C.VARPAR.( def )( : , 1 ) ) ;
        dom = h.Parent.UserData.C.VARPAR.( def ){ i , 2 } ;
      end

      % Check if numerical domain matches variable parameter's
      if  dom == 'i'  &&  MCC.DIST.DOMAIN.( d.NewData ){ 1 }( 1 ) == 'f'

        e = sprintf ( [ 'Dist. %s has incompatible numerical\n' , ...
          'domain with variable parameter %s' ] , d.NewData , vpn ) ;

      end
      
    % Dependent distribution : same or diff
    elseif  any ( strcmp ( d.NewData , { 'same' , 'diff' } ) )
      
      % In this case , put a space in Value for this row. That way the +/OK
      % button callback will run successfully, as the cell is not empty.
      % Neither does it contain any number, which is not valid.
      setcell ( h , row , 'Value' , ' ' )
    
    end % param dist
    
    
  % Attempting to set the Value field. Branch based on which control group
  % we're using
  elseif  strcmp ( cnam , 'Value' )
    
    % If this is var table and Dist is same or diff
    if  strcmp ( h.Tag , 'var' )  &&  ...
        any( strcmp( lookup ( h , row , 'Dist' ) , { 'same' , 'diff' } ) )
      
      % Then scold the naughty user
      e = 'No edits to Value allowed when distribution is same or diff' ;
      
    else
      
      % Otherwise validate the input
      e = valerr ( h , d ) ;
      
    end
    
  end % error checks
  
  % Error detected , undo edit and quit
  if  ~ isempty ( e )
    h.Data { row , col } = d.PreviousData ;
    errmsg ( e )
    return
  end
  
  % This is a new row. Certain actions are possible.
  if  newrow
    
    % If either Stim, Type, object, or VarPar have been edited, then clear
    % all columns to the right, because they may no longer be valid. Or
    % clear if this it the Task column in the Task variable table.
    if  any ( strcmp ( cnam , clrset ) )  ||...
         ( strcmp ( h.Tag , 'var' )  &&  strcmp ( cnam , 'Task' ) )
      
      % Find column indeces , excluding VarPar if Type is not stim. We will
      % have deliberately set VarPar when Type was chosen, and we don't
      % want to overwrite that.
      col = col + 1 : size ( h.Data , 2 ) ;
      if  any ( strcmp ( h.ColumnName , 'Type' ) )  &&  ...
          ~ strcmp ( lookup ( h , row , 'Type' ) , 'stim' )
        col = col (  ~strcmp( h.ColumnName ( col ) , 'VarPar' )  ) ;
      end
      
      % Blank columns
      h.Data ( row , col ) = { [] } ;

    end
  
    % Type column edited , and type is not a stimulus link. Map the only
    % option directly to VarPar.
    if  strcmp ( cnam , 'Type' )
      
      if  strcmp ( d.NewData , 'stim' )
        setcell ( h , row , 'VarPar' , [] )
      else
        setcell ( h , row , 'VarPar' , MCC.VPMAP.( d.NewData ) )
      end
      
    end
    
  % Not a new row. Change must be commited to session descriptor. Some care
  % must be taken in the case of a task component table while the task is
  % still being built. The table's own add-button String might be '+' while
  % the task's add button String in still 'OK', meaning that the task does
  % not have a corresponding sub-struct in the session descriptor. If we
  % are editing a task table while a new task if being declared, then skip
  % this.
  elseif  ~ ( strcmp (  h.Tag  ,  'task'  )  &&  ...
              strcmp (  h.Parent.UserData.task.tskadd.String  ,  'OK'  ) )
    
    % Changing task variable
    if  strcmp (  h.Tag  ,  'var'  )
      
      % Get task variable name and its new value
      [ nam , val ] = lookup ( h , row , { 'Name' , 'Value' } ) ;
      
      % Convert comma separated list of values to numeric form
      val = str2double ( strsplit ( val , ',' ) ) ;
      if  any ( isnan ( val ) )  ,  val = [] ;  end
      
      % Set task variable value
      h.Parent.UserData.sd.var.( nam ).value = val ;
      
    % Changing part of the task
    else
      
      % Current selected task
      ctsk = h.Parent.UserData.task.tsklst ;
      ctsk = ctsk.String { ctsk.Value } ;
      
      % Current object type
      ctyp = h.UserData.tag ;
      
      % Get task sub-struct
      ts = h.Parent.UserData.sd.task.( ctsk ).( ctyp ) ;
      
      % Assign Value according to task component type
      switch  ctyp
        
        % Stimulus link
        case  'link'
          
          meterror (  [ 'metsessdlg: should not be able to edit ' , ...
            'existing rows of link table' ]  )
          
        % Default values
        case  'def'
          
          % Get new value
          val = lookup ( h , row , 'Value' ) ;
          
          % Assign
          ts( row ).value = val ;
          
        % Stimulus and MET signalling events
        otherwise
          
          % Get task variable name and its new value
          [ nam , val ] = lookup ( h , row , { 'Name' , 'Value' } ) ;
          
          % Assign value
          switch  ctyp
            case  'sevent'  ,  ts.( nam ).value = val ;
            case  'mevent'  ,  ts.( nam ).cargo = val ;
          end
        
      end
      
      % Save to session descriptor
      h.Parent.UserData.sd.task.( ctsk ).( ctyp ) = ts ;
      
    end % Update session descriptor
  
  end % new row
  
end % tabedit_cb


% Table selection callback. Checks for empty columns and warns user. Loads
% selected column with list of choices, where applicable. Not used for
% environment variables
function  tabsel_cb ( h , I )
  
  % Check that only one cell selected
  if  1  ~=  size ( I.Indices , 1 )
    
    % Empty means no selection , only show error if multiple cells selected
    if  ~ isempty ( I.Indices )
      errmsg ( 'Please select only one cell' ) ;
    end
    
    % Set null selection in case of error , context menu option may require
    % this to stay as it was
    if  h.UserData.keepsel
      h.UserData.keepsel( 1 ) = false ;
    else
      h.UserData.selected( : ) = 0 ;
      delete ( h.UIContextMenu.Children )
    end
    
    return
    
  end % one cell check
  
  % Row and column index
  r = I.Indices ( 1 ) ;  c = I.Indices ( 2 ) ;
  
  % Clear context menu
  delete ( h.UIContextMenu.Children )
  
  % Check that all leftward cells in same row are full
  i = cellfun( @( c )  isempty ( c ) , h.Data( r , 1 : c - 1 ) ) ;
  i = find ( i , 1 , 'first' ) ;
  
  if  i
    i = sprintf ( 'Please fill the cell at\nrow %d and col %d' , r , i ) ;
    errmsg ( i )
    h.Data{ r , c } = [] ;
    h.UserData.selected( : ) = 0 ;
    return
  end
  
  % Set selection
  h.UserData.selected( : ) = [ r , c ] ;
  h.UserData.keepsel( 1 ) = false ;
  
  % Get column header
  chdr = h.ColumnName{ c } ;
  
  % Initialise drop-down list
  switch  h.Tag
    case  'task'
      S = tsktab_dd ( h , chdr , r ) ;
    case  'var'
      S = vartab_dd ( h , chdr , r ) ;
  end
  
  % Initialise context menu
  cxmenu ( h , S )
  
end % tabsel_cb


% Context menu option - runs when user right-clicks to bring up context
% menu, then selects item on list
function  cxmopt_cb ( h , ~ )
  
  % Table
  t = h.UserData ;
  
  % Currently selected cell
  i = t.UserData.selected ;
  
  % Keep current selection
  t.UserData.keepsel( 1 ) = true ;
  
  % Build callback struct
  d.Indices = i ;
  d.PreviousData = t.Data{ i( 1 ) , i( 2 ) } ;
  d.EditData = h.Label ;
  d.NewData = h.Label ;
  d.Error = '' ;
  
  % Assign label
  t.Data{ i( 1 ) , i( 2 ) } = h.Label ;
  
  % Run callback
  t.CellEditCallback ( t , d )
  
end % cxmopt_cb


% Task logic popup menu , checks task list , if no task then sets default.
% This can only be edited 
function  logpop_cb ( h , ~ )
  
  % Parent figure
  f = h.Parent ;
  
  % Task listbox
  htlb = f.UserData.task.tsklst ;
  
  % Task add button
  hadd = f.UserData.task.tskadd ;
  
  % Task tables
  htab = findobj ( f , 'Tag' , 'task' , 'Type' , 'uitable' ) ;
  
  % Empty error string
  e = '' ;
  
  % If empty task list then set default and quit
  if  isempty ( htlb.String )
    
    e = 'No task defined yet' ;
    h.Value = 1 ;
    
  % New task and name string still empty
  elseif  isempty ( htlb.String { htlb.Value } )
    
    e = 'Task name not yet given' ;
    h.Value = 1 ;
    
  % Value is being changed
  elseif  h.Value  ~=  h.UserData.value
    
    % Not a new task , i.e. add button is '+' not 'OK' , can't change logic
    % of existing task
    if  strcmp ( hadd.String , '+' )
      
      e = 'Can''t change logic of existing task' ;
    
    % Task tables are not empty , task components rely on this logic
    elseif  any( cellfun( @( c )  ~isempty( c ) , get ( htab , 'Data' ) ) )
      
      e = sprintf ( ...
        'Can''t change task logic unless\ntask tables are empty' ) ;
      
    % Chanted back to <empty>
    elseif  strcmp ( h.String { h.Value } , '<empty>' )
      
      e = '<empty> is not a valid choice' ;
      
    end
    
    % Revert value
    if  ~ isempty ( e )  ,  h.Value = h.UserData.value ;  end
    
  end
  
  % Error detected
  if  ~ isempty ( e )
    
    errmsg ( e )
    return
    
  end
  
  % No errors , change user data value
  h.UserData.value = h.Value ;
  
  % Point to the task logic struct
  T = h.String { h.Value } ;
  T = f.UserData.C.TLOGIC.( T ) ;
  
  % Change state name set in task table State columns
  S = T.nstate ;
  tabpopset ( htab , 'State' , S )
  
  % Change task stimulus set in stimulus link table , omit 'none' stimulus
  htab = f.UserData.task.link.tab ;
  S = setdiff ( T.nstim , 'none' ) ;
  tabpopset ( htab , 'Task' , S )
  
end % logpop_cb


% Table add button. tg is table group name , names struct in parent
% figure's UserData. Either .UserData.var or .UserData.task.link, .sevent,
% .mevent, or .def
function  tabadd_cb ( h , ~ , tg )
  
  % Find table group and uicontrol handles
  [ tg , U ] = tabbtn_prep ( h , tg ) ;
  
  % Task add button
  hadd = h.Parent.UserData.task.tskadd ;
  
  % Task list box , htmp - temporary handle
  htmp = findobj ( h.UserData.uilink , ...
    'Tag' , 'task' , 'Style' , 'listbox' ) ;
  
  % Add new row to table
  if  strcmp ( h.String , '+' )
    
    % Quit if there are no tasks
    if  isempty ( htmp.String )
      errmsg ( 'No task defined yet' )
      return
    end
    
    % Error check , depending on user data tag
    e = '' ;
    
    switch  h.UserData.tag
      
      case  { 'link' , 'mevent' , 'def' }
      
        % Stim link , Met signal , default. Can't add unless task logic
        % given.
        htmp = h.Parent.UserData.task.logpop ;
        if  strcmp ( htmp.String { htmp.Value } , '<empty>' )
          e = 'No task logic given' ;
        end
        
      case  'sevent'
      
        % Stim event. Can't add unless stim link given.
        htmp = h.Parent.UserData.task.link.tab ;
        if  isempty ( htmp.Data )
          e = 'No stimulus links given' ;
        end
      
    end % user data tag
    
    % Error detected
    if  ~ isempty ( e )
      errmsg ( e )
      return
    end
    
    % Inactivate controls
    set ( U , 'Enable' , 'inactive' )
    
    % Vector of table controls , this will be enabled at end of function
    U = struct2array ( tg ) ;
    U = findobj ( U , '-not' , 'Style' , 'text' ) ;
    
    % Swap label
    h.String = 'OK' ;
    
    % Add new row
    n = numel ( tg.tab.ColumnName ) ;
    tg.tab.Data = [  tg.tab.Data  ;  cell( 1 , n )  ] ;
    
  % Complete adding new row
  elseif  strcmp ( h.String , 'OK' )
    
    % New row of data
    r = tg.tab.Data ( end , : ) ;
    
    % Check row is complete
    if  any ( cellfun ( @( c )  isempty ( c ) , r ) )
      
      % Tell user
      errmsg ( sprintf ( 'New row %d is incomplete' , ...
        size ( tg.tab.Data , 1 ) ) )
      
      % Quit
      return
      
    end
    
    % Add to session descriptor if this is task variable table.
    if  strcmp ( h.Tag , 'var' )
      
      % Get all properties for new record
      [ nam , tsk , typ , obj , vpn , dep , dis , val ] = r { : } ;
      
      % Convert comma separated list of values to numeric form
      val = str2double ( strsplit ( val , ',' ) ) ;
      if  any ( isnan ( val ) )  ,  val = [] ;  end
      
      % Task variable struct
      vs = h.Parent.UserData.sd.var ;
      
      % Get task, type, name, and vpar from all existing task variables
      etsk = metgetfields ( vs , 'task' ) ;
      etyp = metgetfields ( vs , 'type' ) ;
      eobj = metgetfields ( vs , 'name' ) ;
      evpn = metgetfields ( vs , 'vpar' ) ;
      
      % Has this object already been linked to a task variable?
      if  findreps (  {  tsk ,  typ ,  obj ,  vpn } , ...
                      { etsk , etyp , eobj , evpn }  )
        
        errmsg ( 'This object''s var.par. already assigned' )
        return
        
      end
      
      % Add fields for new task variable
      vs.( nam ).task   = tsk ;
      vs.( nam ).type   = typ ;
      vs.( nam ).name   = obj ;
      vs.( nam ).vpar   = vpn ;
      vs.( nam ).depend = dep ;
      vs.( nam ).dist   = dis ;
      vs.( nam ).value  = val ;
      
      % Assign struct
      h.Parent.UserData.sd.var = vs ;
      
      % Add item to block's variable list
      varpop = h.Parent.UserData.block.varpop ;
      
      if  ~ any ( strcmp ( varpop.String , nam ) )
        varpop.String = [ varpop.String ; { nam } ] ;
      end
      
    % Or if it is a task table , and the task add button is '+' i.e. not a
    % new task
    elseif  strcmp ( h.Tag , 'task' )  &&  strcmp ( hadd.String , '+' )
      
      % Current selected task
      ctsk = h.Parent.UserData.task.tsklst ;
      ctsk = ctsk.String { ctsk.Value } ;
      
      % Current object type
      ctyp = h.UserData.tag ;
      
      % Get task sub-struct
      ts = h.Parent.UserData.sd.task.( ctsk ).( ctyp ) ;
      
      % Error detection
      e = false ;
      
      % Assign them according to object type. Each case assigns the newly
      % defined record to symbolic names. In most cases, these are checked
      % against existing objects of the same type
      switch  ctyp
        
        case   'link'
          
          % Stimulus link
          [ nam , stm , def ] = r{ : } ;
          ts.( nam ).stim = stm ;
          ts.( nam ).def  = def ;
          
        case 'sevent'
          
          % Stimulus event
          [ nam , sta , stm , vpn , val ] = r{ : } ;
          
          esta = metgetfields ( ts , 'state' ) ;
          estm = metgetfields ( ts , 'link' ) ;
          evpn = metgetfields ( ts , 'vpar' ) ;
          
          if  findreps ( {  sta ,  stm ,  vpn } , { esta , estm , evpn } )
            
            e = true ;
            
          else
          
            ts.( nam ).state = sta ;
            ts.( nam ).link  = stm ;
            ts.( nam ).vpar  = vpn ;
            ts.( nam ).value = val ;
            
          end
          
        case 'mevent'
          
          % MET signal event
          [ nam , sta , sig , val ] = r{ : } ;
          
          esta = metgetfields ( ts , 'state'   ) ;
          esig = metgetfields ( ts , 'msignal' ) ;
          
          if  findreps ( { sta , sig } , { esta , esig } )
            
            e = true ;
            
          else
            
            ts.( nam ).state   = sta ;
            ts.( nam ).msignal = sig ;
            ts.( nam ).cargo   = val ;
          
          end
            
        case    'def'
          
          % Default value
          [ typ , obj , vpn , val ] = r{ : } ;
          
          etyp = { ts.type } ;
          eobj = { ts.name } ;
          evpn = { ts.vpar } ;
          
          if  findreps ( { typ , obj , vpn } , { etyp , eobj , evpn } )
            
            e = true ;
            
          else
            
            ts( end + 1 ).type  = typ ;
            ts( end     ).name  = obj ;
            ts( end     ).vpar  = vpn ;
            ts( end     ).value = val ;

          end
          
      end % make new object
      
      % Error detected
      if  e
        errmsg ( ...
          sprintf ( 'Another %s object has the same properties' , ctyp ) )
        return
        
      % Assign sessdion descriptor
      else
        h.Parent.UserData.sd.task.( ctsk ).( ctyp ) = ts ;
      end
      
    end % Modify session descriptor
    
    % Swap label
    h.String = '+' ;
    
    % If this is a task control then we should only re-enable other task
    % controls
    if  strcmp ( h.Tag , 'task' )  &&  strcmp ( hadd.String , 'OK' )
      
      U = findobj ( U , 'Tag' , h.Tag , '-not' , 'Style' , 'text' );
      
    end
    
  end % button actions
  
  % Swap tool tips
  ttswap ( [ h , tg.min ] )
  
  % Enable controls
  set ( U , 'Enable' , 'on' )
  
end % tabadd_cb


function  rep = findreps ( n , E )
  
  n = reshape ( n , numel ( n ) , 1 ) ;
  E = reshape ( E , numel ( E ) , 1 ) ;
  
  rep = cellfun ( @( n , E )  strcmp ( n , E ) , ...
    n , E , 'UniformOutput', false ) ;
  rep = cell2mat ( rep ) ;
  
  rep = any ( all ( rep , 1 ) ) ;
  
end % findreps


function  tabmin_cb ( h , ~ , tg )
  
  % Find table group and uicontrol handles
  [ tg , U ] = tabbtn_prep ( h , tg ) ;
  
  % Task add button
  hadd = findobj ( h.UserData.uilink , ...
    'Tag' , 'task' , 'Style' , 'pushbutton' ) ;
  
  % Nothing to do if there's no row , or if there is no valid selection
  if  isempty ( tg.tab.Data )  ||  any ( ~tg.tab.UserData.selected )
    return
  end
  
  % Action depends on task and table add-button labels
  if  strcmp ( tg.add.String , '+' )
    
    % Error detection
    e = '' ;
    
    % Parent figure
    f = h.Parent ;
    
    % Session descriptor , for reading only
    sd = f.UserData.sd ;
    
    % Set index to last selected row
    i = tg.tab.UserData.selected ( 1 ) ;
    
    % Object name
    nam = lookup ( tg.tab , i , 'Name' ) ;
    
    % Check that we don't break the session descriptor. This doesn't matter
    % if it is a task table and the task add button is 'OK' - meaning that
    % a new task is being defined
    if  strcmp ( h.Tag , 'task' )
      
      % Task name
      tsk = f.UserData.task.tsklst ;
      tsk = tsk.String { tsk.Value } ;
      
      if  strcmp ( hadd.String , 'OK' )
      
        % No action
        
      % This is a default value definition. No possible adverse effect of
      % removing this.
      elseif  strcmp ( h.UserData.tag , 'def' )
        
        f.UserData.sd.task.( tsk ).def = ...
          sd.task.( tsk ).def( [ 1 : i - 1 , i + 1 : end ] ) ;
        
      % Check session descriptor then remove item
      else
        
        % Object type
        typ = h.UserData.tag ;
        
        % Object is a stimulus link
        if  strcmp ( typ , 'link' )
          
          % translate 'link' to 'stim'
          typ = 'stim' ;
          
          % Get stim names from sevent, and type/names from def statements
          snam = metgetfields ( sd.task.( tsk ).sevent , 'link'   ) ;
          dtyp = { sd.task.( tsk ).def.type } ;
          dnam = { sd.task.( tsk ).def.name } ;
          
        end
        
        % Get task, name, and type in each task variable
        vtsk = metgetfields ( sd.var , 'task' ) ;
        vtyp = metgetfields ( sd.var , 'type' ) ;
        vnam = metgetfields ( sd.var , 'name' ) ;
        
        % Check if any of these conjoin, if so then we cannot remove the
        % item
        if  strcmp ( typ , 'stim' )  &&  ...
            (  any ( strcmp ( nam , snam ) ) || ...
               any ( strcmp ( typ , dtyp )  &  strcmp ( nam , dnam ) )  )
        
          e = 'stim event or default value' ;
        
        elseif  any (  strcmp ( tsk , vtsk )  &  ...
                       strcmp ( typ , vtyp )  &  strcmp ( nam , vnam )  )
        
          e = 'task variable' ;
          
        % Remove from sess desc
        else
          
          % Get type again
          typ = h.UserData.tag ;
          
          % Task sub-struct
          tss = sd.task.( tsk ).( typ ) ;
          
          % Remove field
          tss = rmfield ( tss , nam ) ;
          if  ~ numel ( fieldnames ( tss ) )  ,  tss = [] ;  end
          
          % Assign modified sub-struct
          f.UserData.sd.task.( tsk ).( typ ) = tss ;
        
        end % remove from sess desc
        
      end % task tab checks
      
    % Check validity of change. Task link/sevent/mevent used by any task
    % var? , or any task var used by any block?
    elseif  strcmp ( h.Tag , 'var' )
      
      % Get all sets of task variable names from blocks
      vnam = metgetfields ( sd.block , 'var' ) ;
      vnam = [ vnam{ : } ] ;
      
      % Get set of all task variable dependencies
      vdep = metgetfields ( sd.var , 'depend' ) ;
      
      % Named task var is in list from blocks
      if  any ( strcmp ( nam , vnam ) )
        
        e = 'block' ;
        
      % Dependent variable linked to the selected variable
      elseif  any ( strcmp ( nam , vdep ) )
        
        e = 'dependent variable' ;
        
      % Edit session descriptor
      else
        
        % Task variable struct
        vs = sd.var ;
        
        % Remove named var
        vs = rmfield ( vs , nam ) ;
        if  ~ numel ( fieldnames ( vs ) )  ,  vs = [] ;  end
        
        % Assign back to session descriptor
        f.UserData.sd.var = vs ;
        
        % Remove item from block variable popup
        varpop = f.UserData.block.varpop ;
        vs = ~ strcmp ( varpop.String , nam ) ;
        varpop.String = varpop.String ( vs ) ;
        
      end % task var checks
      
    end % Can we edit sess desc?
    
    % Error detected
    if  ~ isempty ( e )
      errmsg ( sprintf ( 'A %s still uses this object' , e ) )
      return
    end
    
    
  % Abort adding new row
  elseif  strcmp ( tg.add.String , 'OK' )
    
    % Swap add button label
    tg.add.String = '+' ;
    
    % Swap tool tips
    ttswap ( [ h , tg.min ] )
    
    % If this is a task control and a new task is being added then only
    % re-enable other task controls
    if  strcmp ( h.Tag , 'task' )  &&  strcmp ( hadd.String , 'OK' )
      
      U = findobj ( U , 'Tag' , h.Tag , '-not' , 'Style' , 'text' ) ;
      
    end
    
    % Enable controls
    set ( U , 'Enable' , 'on' )
    
    % Set index to last row
    i = size ( tg.tab.Data , 1 ) ;
    
  end % button actions
  
  % Remove row
  if  size ( tg.tab.Data , 1 )  ==  1

    tg.tab.Data = [] ;

  else

    tg.tab.Data = tg.tab.Data ( [ 1 : i - 1 , i + 1 : end ] , : ) ;

  end
  
end % tabmin_cb


% Name edit boxes
function  namedt_cb ( h , ~ )
  
  % Linked add button and listbox
  hadd = findobj ( h.UserData.uilink , 'Style' , 'pushbutton' ) ;
  hlst = findobj ( h.UserData.uilink , 'Style' ,    'listbox' ) ;
  
  
  % Empty string means no error , the reset string
  e = '' ;
  r = '' ;
  
  % Name has invalid form
  if  badname ( h.String )
    
    e = sprintf ( 'Invalid name: "%s"' , h.String ) ;
    
  % There is nothing in the listbox
  elseif  isempty ( hlst.String )
    
    e = sprintf ( 'No %s selected' , h.Tag ) ;
    
  % Is the name already in use?
  elseif  any ( strcmp(  h.String  ,  ...
        hlst.String( [ 1 : hlst.Value - 1 , hlst.Value + 1 : end ] )  ) )
    
    e = sprintf ( 'Name already used: "%s"' , h.String ) ;
    
    % Get reset string if existing component
    if  strcmp ( hadd.String , '+' )
      r = hlst.String { hlst.Value } ;
    end
    
  % Changing task name , this is not a brand new task , and changing task
  % name could break task variables that name it
  elseif  strcmp ( h.Tag , 'task' )
    
    [ vartsk , varnam ] = ...
      metgetfields ( h.Parent.UserData.sd.var , 'task' ) ;
    i = strcmp ( hlst.String { hlst.Value } , vartsk ) ;
    
    % Check task variables
    if  any ( i )
      
      r = hlst.String { hlst.Value } ;
      e = sprintf (  'Task vars refering to this task as ''%s'': %s'  , ...
        r  ,  strjoin ( varnam ( i ) , ',' )  ) ;
      
    end
    
  end % invalid name
  
  % Error detected , tell user , reset edit to empty , and quit
  if  ~ isempty ( e )
    errmsg ( e )
    h.String = r ;
    return
  end
  
  % Update session descriptor if not a new task
  if  strcmp ( hadd.String , '+' )
    
    % Old name and new name
    old = hlst.String { hlst.Value } ;
    new = h.String ;
    
    % If these are the same then we can quit
    if  strcmp ( old , new )  ,  return  ,  end
    
    % Tasks structure
    s = h.Parent.UserData.sd.( h.Tag ) ;
    
    % Old field names , to preserve old order of fields
    f = fieldnames ( s ) ;
    
    % Find and change field name in list
    f{ strcmp( f , old ) } = new ;
    
    % Make new field with new task name and assign struct from old task
    % name
    s.( new ) = s.( old ) ;
    
    % Remove old field name
    s = rmfield ( s , old ) ;
    
    % Re-order fields
    s = orderfields ( s , f ) ;
    
    % Save changes
    h.Parent.UserData.sd.( h.Tag ) = s ;
    
  end
  
  % Set name to list
  hlst.String { hlst.Value } = h.String ;
  
end % namedt_cb


% Block repeat and attempts edit boxes
function  blkrepatm_cb ( h , ~ )
  
  % Block add button and list box
  hadd = findobj ( h.UserData.uilink , 'Style' , 'pushbutton' ) ;
  hlst = findobj ( h.UserData.uilink , 'Style' , 'listbox' ) ;
  
  % Error message
  e = '' ;
  
  % List box is empty
  if  isempty ( hlst.String )
    
    e = 'No block selected' ;
    
  % Natural numbers only , from 1
  elseif  ~ isempty ( h.String )
    
    n = str2double ( h.String ) ;
    
    % Check form
    if  isnan ( n )  ||  n  <  1  ||  mod ( n , 1 )
      
      e = 'Must be natural number , 1 or more' ;
      
    end
    
  end % Actions
  
  % Error detected
  if  ~ isempty ( e )
    
    errmsg ( e )
    h.String = '' ;
    return
    
  end
  
  % This is an existing block
  if  strcmp ( hadd.String , '+' )
    
    % What we assign value to depends on which control this is
    if  h  ==  h.Parent.UserData.block.repedt
      f = 'reps' ;
    elseif  h  ==  h.Parent.UserData.block.atmedt
      f = 'attempts' ;
    else
      meterror (  'metsessdlg: block edit object unrecognised'  )
    end
    
    % Get block name
    b = hlst.String { hlst.Value } ;
    
    % User entered empty string , so reset existing value
    if  isempty ( h.String )
      
      h.String = num2str ( h.Parent.UserData.sd.block.( b ).( f ) ) ;
      
    % Otherwise , save the change
    else
      
      h.Parent.UserData.sd.block.( b ).( f ) = n ;
      
    end
    
  end % edit session descriptor
  
end % blkrepatm_cb


% Task and block list buttons
function  tskblkbtn_cb ( h , ~ )
  
  % Figure
  f = h.Parent ;
  
  % Find all controls and tables without the tag
  U = findobj ( f , 'Type' , 'uicontrol' , '-or' , 'Type' , 'uitable' ) ;
  U = findobj ( U , '-not' , 'Tag' , h.Tag , '-not' , 'Style' , 'text' ) ;
  
  % Linked listbox
  hlst = findobj ( h.UserData.uilink , 'Style' , 'listbox' ) ;
  U = [ U ; hlst ] ;
	
  % Adding a new item to list
  if  strcmp ( h.String , '+' )
    
    % Is this the block add button?
    if  strcmp ( h.Tag , 'block' )
      
      % Yes , now find the task listbox and var table
      htlb = f.UserData.task.tsklst ;
      hvar = f.UserData.var.tab ;
      
      % Can't define a block if there are no tasks or task variables
      e = '' ;
      if  isempty ( htlb.String )
        e = 'No tasks available' ;
      elseif  isempty ( hvar.Data )
        e = 'No task variables available' ;
      end
      
      if  ~ isempty ( e )
        errmsg ( e )
        return
      end
      
      % Empty task variable listbox
      hvar = f.UserData.block.varlst ;
      hvar.Value = 1 ;
      hvar.String = '' ;
      
    end % block add check
    
    % Find edits and set to ''
    hedt = findobj ( f , 'Tag' , h.Tag , 'Style' , 'edit' ) ;
    set ( hedt , 'String' , '' )
    
    % Find popup menu and set to value 1 , the <empty> place holder
    hpop = findobj ( h.UserData.uilink , 'Style' , 'popupmenu' ) ;
    hpop.Value = 1 ;
    
    % Find tables and set Data to empty
    htab = findobj ( f , 'Tag' , h.Tag , 'Type' , 'uitable' ) ;
    if  ~ isempty ( htab )
      set ( htab , 'Data' , [] )
    end
    
    % Disable unrelated controls
    set ( U , 'Enable' , 'inactive' )

    % Re-label button
    h.String = 'OK' ;
    
    % Change tool tips
    hmin = findobj ( h.UserData.uilink , 'Style' , 'pushbutton' ) ;
    ttswap ( [ h , hmin ] )
    
    % Add empty string to list box
    if  isempty ( hlst.String )
      hlst.Value = 1 ;
      hlst.String = { '' } ;
    else
      hlst.String = [  hlst.String  ;  { '' }  ] ;
      hlst.Value = numel ( hlst.String ) ;
    end
    
    
  % Finished adding new item
  elseif  strcmp ( h.String , 'OK' )
    
    % Are entries valid?
    if  ~ validate_list ( f , h.Tag )
      
      % They are not
      return
      
    end
    
    % Name of item to add
    nam = hlst.String { hlst.Value } ;
    
    % Make new struct with item's information
    switch  h.Tag
      case  'task' , s = newtask  ( f ) ;
      case 'block' , s = newblock ( f ) ;
    end
    
    % Add to session descriptor
    f.UserData.sd.( h.Tag ).( nam ) = s ;
    
    % Enable unrelated controls
    set ( U , 'Enable' , 'on' )

    % Restore button
    h.String = '+' ;
    
    % Restore tooltips
    hmin = findobj ( h.UserData.uilink , 'Style' , 'pushbutton' ) ;
    ttswap ( [ h , hmin ] )
    
  % Otherwise this is the minus button
  elseif  strcmp ( h.String , '-' )
    
    % Determine handle of add button and associate list
    hadd = findobj ( h.UserData.uilink , 'Style' , 'pushbutton' ) ;
    
    % Name of item to remove
    nam = hlst.String { hlst.Value } ;
    
    % If the paired add button says 'OK' then we're free to stop
    if  strcmp ( hadd.String , 'OK' )
      
      % Enable the blocked controls
      set ( U , 'Enable' , 'on' )
      
      % Restore add button string
      hadd.String = '+' ;
      
      % Restore tooltips
      ttswap ( [ h , hadd ] )
      
    % If removing task then check if we're in danger of breaking the
    % session descriptor
    elseif  strcmp ( h.Tag , 'task' )  &&  ...
        any( strcmp ( nam , metgetfields( f.UserData.sd.var , 'task' ) ) )
      
      % Can't remove
      errmsg ( 'Task variable still uses this task' )
      return
      
    % Remove from session descriptor
    else
      
      % Sub-struct
      s = f.UserData.sd.( h.Tag ) ;
      
      % Remove item
      s = rmfield ( s , nam ) ;
      if  ~ numel ( fieldnames ( s ) )  ,  s = [] ;  end
      
      % Assign to session descriptor
      f.UserData.sd.( h.Tag ) = s ;
      
    end
    
    % Add empty string to list box
    if  numel ( hlst.String )  ==  1
      hlst.Value = 1 ;
      hlst.String = '' ;
    else
      i = hlst.Value ;
      hlst.Value = max ( [ 1 , i - 1 ] ) ;
      hlst.String = hlst.String ( [ 1 : i - 1 , i + 1 : end ] ) ;
    end
    
    % Run list callback to update task controls
    hlst.Callback ( hlst , [] )
    
  end % button actions
  
end % tbladd_cb


% Done exit button callback. Check for unused scheduling components then
% set figure's .done to true.
function  done_cb ( ~ , ~ , show_sched )
  
  % Figure
  h = gcbf ;
  
  % Validate session descriptor
  if  valblock ( h )  ||  valtskvar ( h )  ||  valtask ( h )  ||  ...
      valevar ( h )
    
    % Not valid
    return
    
  end
  
  % Make schedule.txt text
  h.UserData.sched = metsd2str ( h.UserData.sd ) ;
  
  % Show text, if requested
  if  show_sched
    
    % Create viewer
    sdv = sdviewer ( h.UserData.sched ) ;
    
    % Block on viewer
    uiwait ( sdv )
    
    % Return value , and delete viewer
    done = sdv.UserData ;
    delete ( sdv )
    
    % User clicked cancel button
    if  ~ done  ,  return  ,  end
    
  end % schedule.txt viewer
  
  % Reduce task logic down do what's used , first get name of task logics
  % used by declared tasks
  T = unique ( metgetfields ( h.UserData.sd.task , 'logic' ) ) ;
  
  % Remove these from the list of all available task logic names
  F = setdiff ( fieldnames ( h.UserData.C.TLOGIC ) , T ) ;
  
  % Return only used task logics to session descriptor
  h.UserData.sd.logic = rmfield ( h.UserData.C.TLOGIC , F ) ;
  
  % All's right
  h.UserData.done = true ;
  
  % Close figure
  figclsreqf_cb ( [] , [] )
  
end % done_cb


% Create exit button - right hand border , number spaces
function  exbtncreat_cb ( h , ~ , rhb , ns )
  
  % Figure
  f = h.Parent ;
  
  % Match units
  h.Units = f.Units ;
  
  % Spacing
  s = f.UserData.C.CNTSPC ;
  
  % Find true right-hand border
  rhb = rhb  -  ns * s ;
  
  % Now find proper left-hand border
  lhb = rhb  -  h.Position ( 3 ) ;
  
  % Set position
  h.Position( 1 : 2 ) = [ lhb , s ] ;
  
  % And set colours
  h.BackgroundColor = 'k' ;
  h.ForegroundColor = 'w' ;
  
end % exbtncreat_cb


% Close figure
function  figclsreqf_cb ( ~ , ~ )
  
  % Calling figure
  h = gcbf ;
  
  % Verify choice if 'Done' button not pushed
  if  ~ h.UserData.done
    
    s = 'Close schedule builder?' ;
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

% Validate tasks , all must be used by at least one task variable , also
% check that all task stimuli are linked , returns 0 on success , takes
% figure handle
function  i = valtask ( h )
  
  % Default failure ( 1 ), until we get to the end
  i = true ;
  
  % Task logic constant
  T = h.UserData.C.TLOGIC ;
  
  % Session descriptor
  sd = h.UserData.sd ;
  
  % No tasks have been declared
  if  isempty (  sd.task  )
    
    errmsg (  'No task declared yet'  )
    return
    
  end
  
  % Get list of task names
  tsk = fieldnames ( sd.task )' ;
  
  % Check each set of task stimuli
  for  tsk_i = 1 : numel ( tsk ) , f = tsk{ tsk_i } ;
    
    % Task's logic
    log = sd.task.( f ).logic ;
    
    % Get full set of task stim , minus 'none'
    TS = setdiff ( T.( log ).nstim , 'none' ) ;
    
    % Get task's set of task stim
    ts = metgetfields ( sd.task.( f ).link , 'stim' ) ;
    
    % Find set of task stim that aren't linked
    j = ~ ismember ( ts , TS ) ;
    
    if  any ( j )
      
      s = strjoin ( ts ( j ) , ' , ' ) ;
      s = sprintf ( 'Task %s has un-linked task stimuli: %s' , f , s ) ;
      errmsg ( s )
      return
      
    end
    
  end % task stim
  
  % Get the set of task variable's task names
  vtsk = unique (  metgetfields ( sd.var , 'task' )  ) ;
  
  % Look for unused tasks
  j = ~ ismember ( tsk , vtsk ) ;
  
  if  any ( j )
    
    s = strjoin ( tsk ( j ) , ' , ' ) ;
    errmsg ( [ 'Unused tasks: ' , s ] )
    return
    
  end
  
  % Tasks are fine
  i( 1 ) = 0 ;
  
end % valtask


% Validate task variables , figure handle in , 0 out on success
function  i = valtskvar ( h )
  
  % Are there any task variables?
  if  isempty (  h.UserData.sd.var  )
    
    i = true ;
    errmsg (  'No task variables declared yet'  )
    return
    
  end
  
  % Get list of task variable names
  var = fieldnames ( h.UserData.sd.var )' ;
  
  % Get list of all used task variabled from blocks' lists
  bvl = metgetfields ( h.UserData.sd.block , 'var' ) ;
  bvl = unique ( [ bvl{ : } ] ) ;
  
  % Find unused task variables
  u = ~ ismember ( var , bvl ) ;
  i = any ( u ) ;
  
  if  i
    
    s = strjoin ( var ( u ) , ' , ' ) ;
    errmsg ( [ 'Unused task variables: ' , s ] ) ;
    return
    
  end
  
  % Make sure that there is at least 
  
end % valtskvar


% Block validation should be done by block controls , but we must check
% that at least one has been declared
function   i = valblock ( h )
  
  % Default failure
  i = true ;
  
  % Error string , empty if no error
  e = '' ;

  % Are there any task blocks?
  if  isempty (  h.UserData.sd.block  )
    e = 'No trial blocks declared yet' ;
  end
    
  % Do any blocks have empty variable lists?
  var = metgetfields ( h.UserData.sd.block , 'var' ) ;
  
  if  any ( cellfun( @( v )  isempty ( v ) , var ) )
    e = 'A block has empty var list' ;
  end
  
  % Error detected
  if  e
    errmsg ( e )
    return
  end
  
  i = false ;
  
end % valblock


% Validate environment variables , 0 on success , input figure handle
function  i = valevar ( h )
  
  % Default output argument
  i = false ;
  
  % Table data
  d = h.UserData.evar.tab.Data ;
  
  % Find cells that are neither empty nor dashed
  c = ~ cellfun ( @( c ) isempty ( c ) || strcmp ( c , '---' ) , d( : ) ) ;
  c = reshape ( c , size ( d ) ) ;
  
  % Number of filled columns, by row
  n = sum ( c , 2 ) ;
  
  % Origin
  if      all ( n( 1 ) ~= [ 2 , 4 , 5 ] )
    
    errmsg ( 'Environment var origin must have 2 , 4 , or 5 values' )
    i( 1 ) = 1 ;
    
  % Disparity
  elseif  n( 2 ) < 1
    
    errmsg ( 'Environment var disparity must have 1 to 3 values' )
    i( 1 ) = 1 ;
    
  % Reward
  elseif  n( 3 ) ~= 2
    
    errmsg ( 'Environment var reward must have 2 values' )
    i( 1 ) = 1 ;
    
  end
  
  % We can now assign values to session descriptor
  h.UserData.sd.evar.origin = cell2mat ( d ( 1 , 1 : n( 1 ) ) ) ;
  h.UserData.sd.evar.disp   = cell2mat ( d ( 2 , 1 : n( 2 ) ) ) ;
  h.UserData.sd.evar.reward = cell2mat ( d ( 3 , 1 : n( 3 ) ) ) ;
  
end % valevar


% Make new block struct
function  s = newblock ( f )
  
  % Block struct field names
  F = { 'reps' , 'attempts' , 'var' } ;
  
  % Block control handles
  b = f.UserData.block ;
  
  % Repeats
  rep = str2double ( b.repedt.String ) ;
  
  % Attempts
  atm = str2double ( b.atmedt.String ) ;
  
  % Task variable list , must pack in a cell for struct () to work properly
  var = { b.varlst.String( : )' } ;
  
  % Gather field names and data together into a cell array
  C = [ F ; { rep , atm , var } ] ;
  
  % Make new struct
  s = struct ( C { : } ) ;
  
end % newblock


% Make new task struct
function  s = newtask ( f )
  
  % Figure's UserData
  U = f.UserData ;
  
  % Struct's field names
  SFNAM = { 'logic' ,  'link' ,   'def' , 'sevent' , 'mevent' } ;
  
  % Field names for sub structs
  SUBFNM.link = { 'stim' , 'def' } ;
  SUBFNM.sevent = { 'state' , 'link' , 'vpar' , 'value' } ;
  SUBFNM.mevent = { 'state' , 'msignal' , 'cargo' } ;
  SUBFNM.def = { 'type' , 'name' , 'vpar' , 'value' } ;
  
  % Handles to logic popup, link table, default table, sevent table, and
  % mevent table.
  logpop = U.task.logpop ;
  lnktab = U.task.link.tab ;
  deftab = U.task.def.tab ;
  sevtab = U.task.sevent.tab ;
  mevtab = U.task.mevent.tab ;
  
  % Data gathering cell array
  C = cell ( size ( SFNAM ) ) ;
	
	% Get task logic
  C{ 1 } = logpop.String{ logpop.Value } ;
  
  % Gather data from named items i.e. links, sevents, mevents
  for  F = {  {   'link' , lnktab } ;
              { 'sevent' , sevtab } ;
              { 'mevent' , mevtab }  }'
    
    % Task struct field name and table handle
    f = F { 1 }{ 1 } ;
    h = F { 1 }{ 2 } ;
    
    % Skip if table is empty
    if  isempty ( h.Data )  ,  continue  ,  end
    
    % Index of field name
    i = strcmp ( f , SFNAM ) ;
    
    % Take names
    N = h.Data ( : , 1 ) ;
    
    % Fresh struct
    subs = struct ;
    
    % Data gathering cell array
    SC = [ SUBFNM.( f ) ; cell( size ( SUBFNM.( f ) ) ) ] ;
    
    % Loop names
    for  j = 1 : numel ( N )
      
      % Gather data in cell array , sub-cell
      SC( 2 , : ) = h.Data( j , 2 : end ) ;
      
      % Make into a struct
      subs.( N{ j } ) = struct ( SC { : } ) ;
      
    end % names
    
    % Assign to main gathering array
    C{ i } = subs ;
    
  end % named items
  
  % Gather default values
  if  ~ isempty ( deftab.Data )
    
    % First, split columns into separate cell arrays
    SC = num2cell ( deftab.Data , 1 ) ;
    
    % Paste together with field names
    SC = [ SUBFNM.def ; SC ] ;
    
    % And build struct
    i = strcmp ( 'def' , SFNAM ) ;
    C{ i } = struct ( SC { : } ) ;
    
  end % default values
  
  % Paste task struct field names onto collected data
  C = [ SFNAM ; C ] ;
  
  % Return built task struct
  s = struct ( C { : } ) ; 
  
end % newtask


% Add items to context menu for a task table
function  S = tsktab_dd ( h , chdr , row )
  
  % Global MET constants
  global  MC
          
  % Figure
  f = h.Parent ;
  
  % Figure user data
  U = f.UserData ;
  
  % Initialise empty set
  S = [] ;
  
  % Choose menu item set based on column
  switch  chdr
      
    case  'Stim'
      
      % List of stimulus links
      tab = U.task.link.tab ;
      S = lookup ( tab , ':' , 'Name' , true ) ;
      
    case  'Object'
      
      % Get the type of object
      typ = lookup ( h , row , 'Type' ) ;
      
      % Menu set depends on type
      switch  typ
        
        case 'state'
          
          % Task logic
            i = U.task.logpop.Value ;
          log = U.task.logpop.String{ i } ;

          % List of task state names , no end states
          S = U.C.TLOGIC.( log ).nstate ;
          S = setdiff ( S , MC.OUT ( : , 1 ) ) ;
          
        case  'stim'
          
          % List of stimulus links
          tab = U.task.link.tab ;
          S = lookup ( tab , ':' , 'Name' , true ) ;
          
      end
      
    case  'VarPar'
      
      % Depends on exactly which table
      switch  h.UserData.tag
        
        % Get name of stimulus link
        case 'sevent'
          
          % Name of stimulus link
          lnk = lookup ( h , row , 'Stim' ) ;
          
        case    'def'
          
          % Get type of object and its name
          [ typ , lnk ] = lookup ( h , row , { 'Type' , 'Object' } ) ;
          
          % Set depends on type. If this is a default state timeout then
          % quit. The only option should have been set when Type was chosen
          if  strcmp ( typ , 'state' )  ,  return  ,  end
          
      end % table
      
      % Link table
      tab = U.task.link.tab ;
      
      % Set of link names in this task
      nam = lookup ( tab , ':' , 'Name' ) ;

      % Linked stimulus definition
      row = find ( strcmp ( lnk , nam ) ) ;
      def = lookup ( tab , row , 'Def''n' ) ;

      % Get variable parameter set for linked stimulus definition
      S = U.C.VARPAR.( def )( : , 1 ) ;
    
  end % menu set
  
end % tsktab_dd


% Find out how to load up the table's context menu for right click
% selection
function  S = vartab_dd ( h , chdr , row )
  
  % Global constants
  global  MC MCC
  
  % Figure
  f = h.Parent ;
  
  % Session descriptor
  sd = f.UserData.sd ;
  
  % Default
  S = [] ;
  
  % Choose set of context menu options based on the column
  switch  chdr
    
    case   'Task'
      
      % List of tasks defined so far
      S = fieldnames ( sd.task ) ;
      
    case 'Object'
      
      % Get task name and type of variable
      [ tsk , typ ] = lookup ( h , row , { 'Task' , 'Type' } ) ;
      
      switch  typ
        
        case  'state'
          
          % A state variable , get list of state names , no end states
          log = sd.task.( tsk ).logic ;
          S = f.UserData.C.TLOGIC.( log ).nstate ;
          S = setdiff ( S , MC.OUT ( : , 1 ) ) ;
          
        otherwise
          
          % Translate to internal lingo - stim means stimulus link
          if  strcmp ( typ , 'stim' ) , typ = 'link' ; end
          
          % Get the set of object names
          S = fieldnames ( sd.task.( tsk ).( typ ) ) ;
          
      end
      
    case 'VarPar'
      
      typ = lookup ( h , row , 'Type' ) ;
      
      if  ~ strcmp ( typ , 'stim' )  ,  return  ,  end
          
      % Get the list of variable parameters in the linked stimulus
      % definition
      [ tsk , lnk ] = lookup ( h , row , { 'Task' , 'Object' } ) ;
      lnk = sd.task.( tsk ).link.( lnk ).def ;
      S = f.UserData.C.VARPAR.( lnk )( : , 1 ) ;
      
    case 'Depend'
      
      % What is name and task of this variable?
      [ nam , tsk ]  = lookup ( h , row , { 'Name' , 'Task' } ) ;
      
      % Get list of all task variables, their task and dependency
      [ N , T , D ] = lookup ( h , ':' , { 'Name' , 'Task' , 'Depend' } ) ;
      
      % Find list of independent task variables from the same task
      i = strcmp ( tsk , T )  &  strcmp ( 'none' , D ) ;
      
      % Get set of names , minus currently selected var
      S = setdiff ( N ( i ) , nam ) ;
      
      % Append 'none' for independent variables, and 'outcome' for those
      % dependent on correct/failed result
      S = [  { 'none' ; 'outcome' }  ;  S  ] ;
      
    case   'Dist'
      
      % Get dependency
      dep = lookup ( h , row , 'Depend' ) ;
      
      % Distribution of independent variable
      disind = '' ;
      
      % Distribution sets
      switch  dep
        case  'none'
          S = fieldnames ( MCC.DIST.IND ) ;
        case  'outcome'
          S = MC.OUT( : , 1 ) ;
        otherwise
          S = MCC.DIST.DEP( : ) ;
          nam = lookup ( h , ':' , 'Name' ) ;
          row = strcmp ( dep , nam ) ;
          disind = lookup ( h , row , 'Dist' ) ;
      end
      
      % Append 'sched' for scheduled distribution unless we have a variable
      % that depends on outcome or an independent variable with dist
      % different from sched
      if  ~ strcmp ( dep , 'outcome' )  ||  strcmp ( disind , 'sched' )
        S = [ { 'sched' }  ;  S ] ;
      end
    
  end % menu options
  
end % vartab_dd


% Value column error checking. Returns '' if no error found. Otherwise,
% returns error message.
function  e = valerr ( h , d )
  
  % Global constants
  global  MCC
  
  % Figure user data
  U = h.Parent.UserData ;
  
  % Session descriptor
  sd = U.sd ;
  
  % Current row
  row = d.Indices ( 1 ) ;
  
  % Task or var table? task if false , var if true
  vartab = strcmp ( h.Tag , 'var' ) ;
  
  % Function handle for parametric range and domain checks
  % @( [ min , max ] , val )
  % @( [ c1 , c2 , ... ] , val )
  fh_rng = @( m , v )  v  <  m( 1 )  ||  m( 2 ) < v ;
  fh_dom = @( c , v )  any (  c  ==  'i'  &  mod ( v , 1 )  ) ;
  
  % Default return value , if no error detected
  e = '' ;
  
  % Get input value(s)
  if  vartab
    
    % Task variable table. In this case, we need to get a comma separated
    % list of values.
    
    % Strip any white space
    s = d.EditData ;
    s( isspace(  s  ) ) = [] ;
    
    % Is this colon-separated list expansion?
    if  regexp (  s  ,  MCC.REX.EXPANSION  )
      
      % Get colon-separated values. <centre>:<no. vals>:<spacing>
      val = str2double ( strsplit ( s , ':' ) ) ;
      
      % Expand into full list. Create list of N values with spacing s, and
      % centred on value c. Steps: 1) Create list of values 1 : N, 2)
      % subtract the median from that list, 3) multiply by s, 4) add c.
      % s * ( ( 1 : N )  -  ( N + 1 ) / 2 )  +  c
      val = val( 3 ) * ( ( 1 : val( 2 ) )  -  ( val( 2 ) + 1 ) / 2  )  +...
        val( 1 ) ;
      
      % Generate comma-separated list of values
      s = strjoin (  ...
        arrayfun( @num2str , val , 'UniformOutput' , false )  ,  ','  ) ;
      
      % And place in table , this will be replaced with previous value on
      % error
      d.Source.Data{ d.Indices( 1 ) , d.Indices( 2 ) } = s ;
      
    % Is this a list of values?
    elseif  regexp (  s  ,  MCC.REX.LIST  )
      
      % Get comma-separated values
      val = str2double ( strsplit ( s , ',' ) ) ;
      
    % No valid format
    else
      
      e = 'Invalid list of values' ;
      
    end
    
  else
    
    val = d.NewData ;
    
  end
  
  % Check valid values
  if  any ( isnan ( val )  |  ~ isreal ( val ) )
    e = 'Invalid number detected' ;
    return
  end
  
  % Task variable table
  if  vartab
    
    % Get all variable names , dependencies , and distributions
    [ nam , dep , dis ] = ...
      lookup ( h , ':' , { 'Name' , 'Depend' , 'Dist' } , true ) ;
    
    % Save variable's name , dependency , and distribution type for later
    var = struct ( 'nam' , nam { row } , 'dep' , dep { row } , ...
      'dis' , dis { row } ) ;
    
    % Scheduled distribution. If independent then check if number of values
    % matches any scheduled dependent variables. If dependent, then check
    % that the number of values matches the independent variable.
    if  strcmp ( dis { row } , 'sched' )
      
      % Get number of values to compare
      switch  dep { row }
        
        case  'none'
          
          % Find variables dependent on this , with scheduled
          I = strcmp ( dep , nam { row } )  &  strcmp ( dis , 'sched' ) ;
          I = find ( I' ) ;
          
          % find will return 0 by 1 or 1 by 0 matrix , that screws up for i
          if  isempty ( I ) , I = [] ; end
          
          % Number of values
          N = zeros ( size ( I ) ) ;
          
          for  i = 1 : numel ( I )
            N( i ) = numel ( sd.var.( nam{ I( i ) } ).value ) ;
          end
          
          nam = nam ( I ) ;
          
        otherwise
          
          N = numel ( sd.var.( dep { row } ).value ) ;
          nam = dep ( row ) ;
          
      end % n vals
      
      % Compare number of values
      if  any ( numel ( val )  ~=  N )
        
        e = [ 'Mismatched scheduled values with ' , ...
          strjoin( nam , ' , ' ) ] ;
        
      end
      
    % Nope , independent variable? In this case, we need to make sure that
    % parametric distribution arguments are valid, case by case.
    elseif  strcmp ( dep { row } , 'none' )
      
      % Get domain info for this distribution
      dis = dis { row } ;
      dom = MCC.DIST.DOMAIN.( dis ) ;
      
      % Check for infinite values
      if  any ( isinf ( val ) )
        
        e = 'No parametric parameter can be Inf' ;
        
      % Compare number of arguments
      elseif  numel ( val )  ~=  numel ( dom ) - 1
        
        e = sprintf ( '%s needs %d parameter(s)' , ...
          dis , numel( dom ) - 1 ) ;
        
      % Make sure that all parameters are in range and have correct domain
      else
        
        i = num2cell ( val ) ;
        i = cellfun ( fh_rng , dom ( 2 : end ) , i )  |  ...
            cellfun ( fh_dom , num2cell ( dom{ 1 }( 2 : end ) ) , i );
        i = find ( i , 1 , 'first' ) ;
        
        if  i
          
          e = sprintf ( [ 'Parameter %f out of range [ %d , %d ]\n' , ...
            'or floating given when integer expected' ], ...
            val ( i ) , dom{ i + 1 }( 1 ) , dom{ i + 1 }( 2 ) ) ;
          
        % Special check for uniform distribution values
        elseif  any ( strcmp ( dis , { 'unic' , 'unid' } ) )  && ...
            val ( 2 ) <= val ( 1 )
          
          e = sprintf ( '%s a b , a is not less than b' , dis ) ;
          
        end
        
      end % parametric distribution error checking
      
    end % sched or parametric distribution checks
    
    % Error found , return
    if  ~ isempty ( e )  ,  return  ,  end
    
  end % task var table
  
  % Get variable parameter information. Depends on which table. Get object
  % type, name, and vpar name.
  vpar = [] ;
  switch  h.UserData.tag
    
    case  'sevent'
      
      typ = 'stim' ;
      [ obj , vpn ] = lookup ( h , row , { 'Stim' , 'VarPar' } ) ;
      
    case  'mevent'
      
      typ = h.UserData.tag ;
      
    case  { 'def' , 'var' }
      
      [ typ , obj , vpn ] = ...
        lookup ( h , row , { 'Type' , 'Object' , 'VarPar' } ) ;
      
  end
  
  % Object is stim and table is task
  if  ~ vartab  &&  strcmp ( typ , 'stim' )
    
    % Get list of stim link and stim def names
    [ lnks , def ] = ...
      lookup ( U.task.link.tab , ':' , { 'Name' , 'Def''n' } ) ;

    % Find stim def
    i = strcmp ( lnks , obj ) ;
    def = def { i } ;
    
  % Object is stim or sevent , will only be true for var table
  elseif  any ( strcmp ( typ , { 'stim' , 'sevent' } ) )
    
    % Get task
    tsk = lookup ( h , row , 'Task' ) ;
    
    % If sevent then get stim link and variable parameter name
    if  strcmp ( typ , 'sevent' )
      vpn = sd.task.( tsk ).sevent.( obj ).vpar ;
      obj = sd.task.( tsk ).sevent.( obj ).link ;
    end
    
    % Get stim def name
    def = sd.task.( tsk ).link.( obj ).def ;
    
  % Information always known for state timeout and mevent reward/rdtype
  else
    
    switch  typ
      case  'state' , vpar = { '' , 'f' , [] , 0 , Inf } ;
      case 'mevent' , vpar = { '' , 'i' , [] , 1 , Inf } ;
    end
    
  end
  
  % If vpar still empty then we need to check session descriptor
  if  isempty ( vpar )
    
    % Return var par list for stim def
    vpar = U.C.VARPAR.( def ) ;

    % Return specific data for named parameter
    i = strcmp ( vpn , vpar ( : , 1 ) ) ;
    vpar = vpar ( i , : ) ;
    
  end
  
  % Check new values against variable parameter's requirements
  
  % Task variables with parametric distributions
  if  vartab  &&  strcmp ( var.dep , 'none' )  &&  ...
      ~ strcmp ( var.dis , 'sched' )
    
    % No further action required
  
  % Floating point values , but integer var par
  elseif  vpar{ 2 } == 'i'  &&  any ( mod ( val , 1 ) )
    
    e = sprintf ( 'Floating point values for\ninteger domain parameter' ) ;
    
  % Values out of range
  elseif  any ( val < vpar{ 4 }  |  vpar{ 5 } < val )
    
    e = sprintf ( 'All values must be in range [ %d , %d ]' , ...
      vpar { 4 : 5 } ) ;
    
  end
  
  
end % valerr


% Populate context menu with menu options
function  cxmenu ( h , S )
  
  % Context menu
  cxm = h.UIContextMenu ;
  
  % Delete any children that it had
  delete ( cxm.Children )
  
  % Populate a fresh set
  for  i = 1 : numel ( S )
    uimenu ( cxm , 'Label' , S{ i } , 'Callback' , @cxmopt_cb , ...
      'UserData' , h )
  end
  
end % cxmenu


% Set value to cell by row number and column name
function  setcell ( tab , row , col , val )
  
  % Get column index
  col = strcmp ( col , tab.ColumnName ) ;
  
  if  ~ any ( col )
    meterror (  'metsessdlg: setcell couldn''t find column index'  )
  end
  
  % Set value
  tab.Data{ row , col } = val ;
  
end % setcell


% Lookup value in table by row number and column name
function  varargout = lookup ( tab , row , col , n2cfrc )
  
  % num2cell force , default false
  if  nargin  <  4  ,  n2cfrc = false ;  end
  
  % Default
  varargout{ 1 } = [] ;
  
  % Row can be ':' , here we expand it to an index vector across all rows
  if  isscalar ( row )  &&  ischar ( row )  &&  row == ':'
    row = 1 : size ( tab.Data , 1 ) ;
  end
  
  % Wrap char array in cell
  if  ischar ( col )  ,  col = { col } ;  end
  
  % Find columns
  [ ~ , i ] = ismember ( col , tab.ColumnName ) ;
  if  isempty ( i )  ||  ~ any ( i )  ,  return  ,  end
  
  % Return values
  if  1  <  numel ( row )  ||  n2cfrc
    varargout ( 1 : numel ( i ) ) = num2cell ( tab.Data( row , i ) , 1 ) ;
  else
    varargout ( 1 : numel ( i ) ) = tab.Data( row , i ) ;
  end
  
end % lookup


function  tabpopset ( htab , cname , cfmt )
  
  % Loop tables
  for  i = 1 : numel ( htab )
    
    % Find column to change
    c = strcmp ( htab( i ).ColumnName , cname ) ;
    if  ~ any ( c )  ,  continue  ,  end
    
    % Give new set of choices
    htab( i ).ColumnFormat { c } = cfmt ;
    
  end % tables
  
end % tabpopset


function  [ g , U ] = tabbtn_prep ( h , n )
  
  % Locate table control group
  if  strcmp ( n , 'var' )
    
    g = h.Parent.UserData.var ;
    
  else
    
    g = h.Parent.UserData.task.( n ) ;
    
  end
  
  % Find all controls
  U = findobj ( h.Parent , 'Type' , 'uicontrol' , ...
    '-not' , 'Style' , 'text' ) ;
  
end % tabbtn_prep


function  ttswap ( H )
  
  for  i = 1 : numel ( H )
    
    % Alternative tooltip
    t = H( i ).UserData.alt_tooltip ;
    
    % Store current tool tip
    H( i ).UserData.alt_tooltip = H( i ).TooltipString ;
    
    % Swap
    H( i ).TooltipString = t ;
    
  end
  
end % ttswap


function  v = validate_list ( f , tag )
  
  % Brace for failure ... it happens all the time
  v = false ;
  
  % Figure user data , struct of all things
  S = f.UserData ;
  
  % Edit boxes must not have empty strings
  E = findobj ( f , 'Tag' , tag , 'Style' , 'edit' ) ;
  E = cellfun ( @( c )  isempty ( c ) , { E.String } ) ;
  
  if  any ( E )
    
    errmsg ( 'Unfilled edit box' )
    return
    
  end
  
  % Tasks declaration
  if  strcmp ( tag , 'task' )
    
    % Popup menu
    u = S.task.logpop ;
    
    % Pop-up menu must not be empty
    if  strcmp ( u.String { u.Value } , '<empty>' )
      
      errmsg ( 'No task logic provided' )
      return
      
    end
    
    % There must be at least one stimulus link
    u = S.task.link.tab ;
    
    if  isempty ( u.Data )
      
      errmsg ( 'At least one stim link required' )
      return
      
    end
    
    % Tables
    u = findobj ( f , 'Tag' , tag , 'Type' , 'uitable' ) ;
    
    % Look for incomplete rows
    for  i = 1 : numel ( u )
      
      % Link to data
      d = u( i ).Data ;
      
      % Check rows
      if  ~ isempty ( d )  &&  ...
          any( cellfun( @( c ) isempty( c ) , d( : ) ) )
        
        errmsg ( 'Incomplete row in table' )
        return
        
      end
      
    end % tables
    
  % Block declaration
  else
    
    % Variable list must not be empty
    if  isempty ( S.block.varlst.String )
    
      errmsg ( 'No task variables selected' )
      return
    
    end
    
    % Get the block's set of task variables
    var = fieldnames (  S.sd.var  ) ;
    var = setdiff ( var , S.block.varlst.String ) ;
    var = rmfield (  S.sd.var  ,  var  ) ;
    
    % Get their task names and dependencies
    tas = metgetfields (  var  ,    'task'  ) ;
    dep = metgetfields (  var  ,  'depend'  ) ;
    
    % For each task used by this block
    for  T = unique ( tas )
      
      % Find dependencies of task variables connected to this task
      i = strcmp (  T { 1 }  ,  tas  ) ;
      
      % There must be at least one independent task variable
      if  ~ any (  strcmp (  dep ( i )  ,  'none'  )  )

        errmsg ( [ 'No independent task variable for task ' , T{ 1 } ] )
        return

      end
      
    end % task variables
    
  end % task or block controls
  
  % Checks passed
  v = true ;
  
end % validate_list


function  errmsg ( s )
  
  uiwait ( msgbox ( s , '' , 'modal' ) )
  
end % errmsg


function  i = badname ( n )
  
  % Global contants
  global  MCC
  
  % Validating regular expression
  rex = MCC.REX.VALNAM ;
  
  % Check form of name
  i = isempty ( regexp ( n , rex , 'once' ) ) ;
  
end % checkname








%%% Creation sub-routines %%%

function  h = sdviewer ( s )
  
  % Spacing, in normalised units
  SPC = 0.01 ;
  
  % Make dialogue
  h = figure ( 'Name' , 'schedule.txt' , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Visible' , 'off' , 'Resize' , 'on' , 'DockControls' , 'off' , ...
    'WindowStyle' , 'modal' , 'UserData' , false ) ;
  
  % Closing callback
  h.CloseRequestFcn = @sdvclose_cb ;
  
  % Make and position cancel button
  cancel = uicontrol ( h , 'Style' , 'pushbutton' , ...
    'String' , 'Reject' , 'Units' , 'Normalized' , ...
    'ForegroundColor' , 'w' , 'BackgroundColor' , 'k' , ...
    'Callback' , @sdvclose_cb ) ;
  
  cancel.Position ( 1 ) = 1  -  SPC  -  cancel.Position ( 3 ) ;
  cancel.Position ( 2 ) = SPC ;
  
  % Make and position done button
  done = uicontrol ( h , 'Style' , 'pushbutton' , ...
    'String' , 'Accept' , 'Units' , 'Normalized' , ...
    'ForegroundColor' , 'w' , 'BackgroundColor' , 'k' ) ;
  
  done.Position ( 1 ) = ...
    cancel.Position ( 1 )  -  SPC  -  done.Position ( 3 ) ;
  done.Position ( 2 ) = SPC ;
  
  done.Callback = @sdvdone_cb ;
  
  % Make and position edit box
  e = uicontrol ( h , 'Style' , 'edit' , 'Units' , 'normalized' , ...
    'HorizontalAlignment' , 'left' , 'Enable' , 'inactive' ) ;
  
  e.Position( 1 : 2 ) = [ SPC , sum( done.Position( [ 2 , 4 ] ) ) + SPC ] ;
  e.Position( 3 : 4 ) = [ 1 - 2 * SPC , 1 - e.Position( 2 ) - SPC ] ;
  
  % Set edit box string , need to match max number of lines to those in sd
  % string
  e.Max = sum ( s  ==  sprintf ( '\n' ) ) ;
  e.String = s ;
  
  % Make figure visible
  h.Visible = 'on' ;
  
  
  %%% Callbacks %%%
  
  % Make viewer invisible , allows uiwait on this figure to continue
  function  sdvclose_cb ( ~ , ~ )
    h.Visible = 'off' ;
    uiresume ( h )
  end
  
  % Done button callback , raises fig's user data , allows modal figure to
  % return true , calls figures close callback
  function  sdvdone_cb ( ~ , ~ )
    h.UserData = true ;
    sdvclose_cb ( [] , [] )
  end
  
  
end % sdviewer


function [ t , top ] = uitask ( h , x , y , wid )
  
  
  %   Make tables   %
  
  % Control tag
  tag = 'task' ;
  
  % Spacing
  SPC = h.UserData.C.CNTSPC ;
  
  % Height of tables
  H = 3.5 ;
  
  % Table column headers
  CH.link = { 'Name' , 'Task' , 'Def''n' } ;
  CH.sevent = { 'Name' , 'State' , 'Stim' , 'VarPar' , 'Value' } ;
  CH.mevent = { 'Name' , 'State' , 'MetSig' , 'Value' } ;
  CH.def = { 'Type' , 'Object' , 'VarPar' , 'Value' } ;
  
  % Table column formats
  CF.link = { 'char' , 'char' , fieldnames( h.UserData.C.VARPAR )' } ;
  CF.sevent = { 'char' , 'char' , 'char' , 'char' , 'numeric' } ;
  CF.mevent = { 'char' , 'char' , { 'mreward' , 'mrdtype' } , 'numeric' } ;
  CF.def = { { 'stim' , 'state' } , 'char' , 'char' , 'numeric' } ;
  
  % Column editable
  CE.link = true ;
  CE.sevent = logical (  [ 1 , 1 , 0 , 0 , 1 ]  ) ;
  CE.mevent = true ;
  CE.def = logical (  [ 1 , 0 , 0 , 1 ]  ) ;
  
  % Width minus spacer
  W = wid  -  SPC ;
  
  % Table widths
  W = [ tabwid( W , CH.link   , CH.sevent ) ;
        tabwid( W , CH.sevent , CH.link   ) ;
        tabwid( W , CH.mevent , CH.def    ) ;
        tabwid( W , CH.def    , CH.mevent ) ] ;
  
	% Table X and Y positions
  X = [ 0 , W( 1 ) + SPC , 0 , W( 3 ) + SPC ]  +  x ;
  Y = [ H + SPC , H + SPC , 0 , 0 ]  +  y ;
  
  % Table constants: title , columns , x pos , y pos , width , field name
  C = ...
    { 'Stimulus links' , CH.link   , CF.link , ...
                                      X( 1 ) , Y( 1 ) , W( 1 ) , 'link' ;
     'Stimulus events' , CH.sevent , CF.sevent , ...
                                      X( 2 ) , Y( 2 ) , W( 2 ) , 'sevent' ;
   'MET signal events' , CH.mevent , CF.mevent , ...
                                      X( 3 ) , Y( 3 ) , W( 3 ) , 'mevent' ;
      'Default values' , CH.def    , CF.def , ...
                                      X( 4 ) , Y( 3 ) , W( 3 ) , 'def'  } ;
  
  % Table tool tips
  TT = { [ 'Assign each task stimulus (Task) a stimulus definition\n' , ...
           '(Def''n) i.e. give each label a physical manifestation.\n', ...
           'This is a link; each one gets a unique name. There is\n' , ...
           'no limit to the number of times a task stimulus can be\n' , ...
           'linked, or to which stimulus definition it links to.' ] ;
         [ 'Make a stimulus link change its physical properties\n' , ...
           'during a trial with a named stimulus event. Do so by\n' , ...
           'attaching the event to a state of the task logic,\n' , ...
           'and saying which variable parameter of the linked\n' , ...
           'stimulus definition must change. Give a default value\n' , ...
           'to change to.' ] ;
         [ 'Produce a reward or change reward type during a trial\n' , ...
           'using a MET signal event. Do so by attaching either a\n' , ...
           'mreward or mrdtype to a state of the task logic, and\n' , ...
           'give the reward duration (ms) or type (1,2,3,...) as\n' , ...
           'the MET signal Value (referred to internally as cargo,\n', ...
           'hence use of the term in task variable VarPar).' ] ;
         [ 'Set the default value for the timeout duration of any\n' , ...
           'task logic state. Or set it for any variable parameter\n' , ...
           'in the stimulus definition of any stimulus link.' ] } ;
  
	% Make tables
  for  i = 1 : size ( C , 1 )
    
    % Field name of table
    fn = C{ i , end } ;
    
    % Make table
    t.( fn ) = mktable ( h , tag , 0 , C{ i , 1 : end - 1 } , H , fn ) ;
    
    % Table tool-tip
    t.( fn ).tab.TooltipString = sprintf ( TT { i } ) ;
    
    % Which columns to edit directly?
    t.( fn ).tab.ColumnEditable = CE.( fn ) ;
    
    % Add callbacks
    t.( fn ).add.Callback = { @tabadd_cb , fn } ;
    t.( fn ).min.Callback = { @tabmin_cb , fn } ;
    
  end
  
  
  %   Make remaining controls   %
  
  % Redefine y
  t.link.tit.Units = h.Units ;
  y = sum ( t.link.tit.Position ( [ 2 , 4 ] ) )  +  SPC ;
  
  % Control constants: Define styles , strings , callback , jump , field
  %   names
  C = { 'text' ,     'Tasks'   ,         '' , 1   , 'tsktxt' ;
  'pushbutton' ,         '+'  ,@tskblkbtn_cb, 0   , 'tskadd' ;
  'pushbutton' ,         '-'  ,@tskblkbtn_cb, 0   , 'tskmin' ;
     'listbox' ,          ''   , @tsklst_cb , 0   , 'tsklst' ;
        'text' ,     'Name '   ,         '' , 0.5 , 'namtxt' ;
        'edit' ,          ''   , @namedt_cb , 0.5 , 'namedt' ;
        'text' ,     'Logic'   ,         '' , 0.5 , 'logtxt' ;
   'popupmenu' , { '<empty>' } , @logpop_cb , 0.5 , 'logpop' } ;
 
  % Define control links. That is , which controls' behaviour depends on
  % the state of some other? The handle will be kept in .UserData.uilink
  % L gives two field names. The one we assign to, then the one we link.
  L = { 'tskadd' , { 'tsklst' , 'logpop' , 'tskmin' }   ;
        'tskmin' , { 'tskadd' , 'tsklst' } ;
        'namedt' , { 'tskadd' , 'tsklst' } } ;
      
	% Tool tips for each control
  TT = repmat ( { '' } , size ( C , 1 ) , 1 ) ;
  i = ~ strcmp ( C ( : , 1 ) , 'text' ) ;
  TT ( i ) = { { 'Add new block' , 'Done new block' } ; % tskadd
               { 'Remove block' , 'Abort new block' } ; % tskmin
               'Select task to view/remove' ; %tsklst
               'Edit task name' ; % namedt
               'Choose task logic'} ; % logpop
	
	% Generate controls
  for i = 1 : size ( C , 1 )
    
     % Get parameters
    c = [ C( i , : ) , TT( i ) ] ;
    [ sty , str , call , jmp , fn , tt ] = c { : } ;
    
    % Generate
    t.( fn ) = uicontrol ( h , 'Style' , sty , ...
      'String' , str , 'BackgroundColor' , 'k' , ...
      'ForegroundColor' , 'w' , 'Tag' , tag , 'Units' , h.Units , ...
      'Callback' , call ) ;
    
    % uicontrols only struct
    u.( fn ) = t.( fn ) ;
    
    % Tooltip
    if  iscell ( tt )
      u.( fn ).UserData.alt_tooltip = tt { 2 } ;
      tt = tt { 1 } ;
    end
    u.( fn ).TooltipString = tt ;
    
    % Set location
    t.( fn ).Position ( 1 ) = x ;
    t.( fn ).Position ( 2 ) = y  +  jmp * t.( fn ).Position ( 4 ) ;
    
    % Widen text controls to show whole string , and left justify
    if  strcmp ( sty , 'text' )
      
      t.( fn ).Position( 3 ) = 1.1  *  t.( fn ).Extent( 3 ) ;
      t.( fn ).HorizontalAlignment = 'left' ;
      
    % Square pushbuttons
    elseif  strcmp ( sty , 'pushbutton' )
      
      t.( fn ).Position ( 3 ) = t.( fn ).Position ( 4 ) ;
      
    end
    
  end % Generate
  
  % Link controls
  uilink ( L , u )
  
  % Bold Task string
  t.tsktxt.FontWeight = 'bold' ;
  t.tsktxt.Position ( 3 ) = 1.1  *  t.tsktxt.Position ( 3 ) ;
  
  % Left justify name edit
  t.namedt.HorizontalAlignment = 'left' ;
  
  % Align task string, buttons, and list to the left
  t.tskmin.Position( 1 ) = sum ( t.tskmin.Position ( [ 1 , 3 ] ) ) ;
  
  tx = sum ( [ t.tsktxt.Position( [ 1 , 3 ] ) ;
               t.tskmin.Position( [ 1 , 3 ] ) ] , 2 ) ;
	t.tsklst.Position( 1 ) = max ( tx ) ;
  t.tsklst.Position( 4 ) = 2  *  t.tsklst.Position( 4 ) ;
  
  % Determine empty space to distribute , first find total width of
  % controls plus spaces
  W = [ t.tsklst , t.namtxt , t.namedt , t.logtxt , t.logpop ] ;
  W = cell2mat ( { W.Position }' ) ;
  W = sum ( W ( : , 3 ) )  +  t.tsklst.Position( 1 )  -  x  +  2 * SPC;
  
  % Then subtract from total width and divide by number of controls that
  % will be widened
  W = ( wid  -  W )  /  3 ;
  
  % Widen controls
  t.tsklst.Position ( 3 ) = t.tsklst.Position ( 3 )  +  W ;
  t.namedt.Position ( 3 ) = t.namedt.Position ( 3 )  +  W ;
  t.logpop.Position ( 3 ) = t.logpop.Position ( 3 )  +  W ;
  
  % Align logic text and menu to the right
  tx = wid  -  t.logpop.Position ( 3 ) ;
  t.logpop.Position( 1 ) = tx ;
  
  tx = t.logpop.Position( 1 )  -  t.logtxt.Position( 3 ) ;
  t.logtxt.Position( 1 ) = tx ;
  
  % Find central position for name controls
  tx = [ sum( t.tsklst.Position ( [ 1 , 3 ] ) ) , t.logtxt.Position( 1 ) ] ;
  tx = [ SPC , -SPC ] + tx ;
  
  c = diff ( tx )  -  t.namtxt.Position( 3 )  -  t.namedt.Position( 3 ) ;
  tx = tx( 1 )  +  c / 2 ;
  
  t.namtxt.Position( 1 ) = tx ;
  t.namedt.Position( 1 ) = sum ( t.namtxt.Position ( [ 1 , 3 ] ) ) ;
  
  % Top of the plot
  top = sum ( t.tsktxt.Position ( [ 2 , 4 ] ) ) ;
  
  % Initialise task logic popup menu UserData.value
  t.logpop.UserData.value = 1 ;
  
  % Add task add button to table button uilink in UserData
  for  F = { 'link' , 'sevent' , 'mevent' , 'def' }  ,  f = F { 1 } ;
    
    t.( f ).add.UserData.uilink = t.tsklst ;
    t.( f ).min.UserData.uilink = t.tskadd ;
    
  end
  
  
end % uitask


function  w = tabwid ( win , c1 , c2 )
  
  n1 = numel ( c1 ) ;
  n2 = numel ( c2 ) ;
  
  w = n1 / ( n1 + n2 )  *  win ;
  
end % tabwid


function [ t , top ] = ...
  mktable ( h , tag , bld , tit , c , cfmt , x , y , wid , hi , udtag )
  
  % Bold the title
  weight = 'normal' ;
  if bld  ,  weight = 'bold' ;  end
  
  % Make title and pushbuttons
  t.tit = uicontrol ( h , 'Style' , 'text' , 'String' , tit , ...
    'HorizontalAlignment' , 'left' , 'FontWeight' , weight ) ;
  t.add = uicontrol ( h , 'Style' , 'pushbutton' , 'String' , '+' ) ;
  t.min = uicontrol ( h , 'Style' , 'pushbutton' , 'String' , '-' ) ;
  
  % Common properties
  u = struct2cell ( t ) ;
  ud = struct ( 'tag' , udtag ) ;
  set ( [ u{ : } ] , 'BackgroundColor' , 'k' , 'ForegroundColor' , 'w' ,...
    'Tag' , tag , 'Units' , h.Units , 'UserData' , ud )
  
  % Button tooltips
  TT = { 'add' , 'Add new row' , 'Done new row' ;
         'min' , 'Remove row' , 'Abort new row' } ;
	for  i = 1 : size ( TT , 1 )
    
    fn = TT { i , 1 } ;
    t.( fn ).TooltipString = TT { i , 2 } ;
    t.( fn ).UserData.alt_tooltip = TT { i , 3 } ;
    
  end
  
  % Square buttons
  t.add.Position ( 3 ) = t.add.Position ( 4 ) ;
  t.min.Position ( 3 ) = t.min.Position ( 4 ) ;
  
  % Align controls to top
  top = y  +  hi ;
  p = top  -  t.tit.Position ( 4 ) ;
  t.tit.Position ( 2 ) = p ;
  
  p = top  -  t.add.Position ( 4 ) ;
  t.add.Position ( 2 ) = p ;
  t.min.Position ( 2 ) = p ;
  
  % Align controls to left or right
  t.tit.Position ( 1 ) = x ;
  
  p = x  +  wid  -  t.min.Position ( 3 ) ;
  t.min.Position ( 1 ) = p ;
  t.add.Position ( 1 ) = p  -  t.add.Position ( 3 ) ;
  
  % Determine height of table
  hi = t.tit.Position ( 2 )  -  y ;
  
  % Resize text to reveal whole string
  t.tit.Position( 3 ) = 1.1  *  t.tit.Extent( 3 ) ;
  
  % Make table's context menu
  u = uicontextmenu ( h ) ;
  
  % Make table
  t.tab = uitable ( h , 'ColumnName' , c , 'ColumnFormat' , cfmt , ...
    'RowName' , '' , 'Units' , h.Units , ...
    'Position' , [ x , y , wid , hi ] , 'Tag' , tag , ...
    'ForegroundColor' , 'w' , 'UIContextMenu' , u , ...
    'BackgroundColor' , [ 0.35 , 0.35 , 0.35 ; 0.2 , 0.2 , 0.2 ] , ...
    'ColumnEditable' , true , 'CellSelectionCallback' , @tabsel_cb , ...
    'CellEditCallback' , @tabedit_cb ) ;
  
  % Reduce columns until extent matches width
  fitcols ( t.tab )
  
  % Table UserData , store selected element index , initialise to null.
  % Also link the add button
  t.tab.UserData.uilink = t.add ;
  t.tab.UserData.selected = [ 0 , 0 ] ;
  t.tab.UserData.keepsel = false ; 
  t.tab.UserData.tag = udtag ;
  
end % mktable


function  fitcols ( t )
  
  % Switch units for column fitting
  t.Units = 'pixels' ;
  
  % Number of columns
  if  ~ isempty ( t.ColumnName )
    nc = numel ( t.ColumnName ) ;
  else
    nc = size ( t.Data , 2 ) ;
  end
  
  % Fit columns
  cw = t.Position( 3 )  /  nc ;
  cw = repmat ( { cw } , 1 , nc ) ;
  
  t.ColumnWidth = cw ;
  
  % Find difference between width and extent , divided amongst columns
  cw = ( t.Position ( 3 )  -  t.Extent ( 3 ) )  /  nc ;
  
  % Adjust columns to match extent and position
  t.ColumnWidth = num2cell ( cell2mat ( t.ColumnWidth )  +  cw ) ;
  
  % Shave off column widths until extent matches position
  i = 0 ;
  while  t.Position( 3 )  <  t.Extent( 3 )
    
    i = i + 1 ;
    if  nc  <  i  ,  i = 1 ;  end
    
    t.ColumnWidth{ i } = t.ColumnWidth{ i }  -  1 ;
    
  end
  
end % fitcols


function  [ b , top ] = uiblock ( h , spc , y , w )
  
  % Tag all controls
  tag = 'block' ;
  
  % Define styles , strings , callbacks , vertical , jump , width
  %   multiplier , and field names 
  C = { ...
      'text' ,     'Block'   ,         '' , spc + y , +1 , 1   , 'blktxt' ; 
'pushbutton' ,         '+'  ,@tskblkbtn_cb, spc + y ,  0 , 1   , 'blkadd' ; 
'pushbutton' ,         '-'  ,@tskblkbtn_cb, spc + y ,  0 , 1   , 'blkmin' ; 
   'listbox' ,          ''   , @blklst_cb ,       y ,  0 , 1.6 , 'blklst' ;
      'edit' ,          ''   , @namedt_cb ,       y , -1 , 1   , 'bnmedt' ;
      'text' ,      'Name'   ,         '' ,       y , -1 , 1   , 'bnmtxt' ;
      'text' ,   'Repeats'   ,         '' , spc + y , +1 , 1   , 'reptxt' ;
      'text' ,  'Attempts'   ,         '' , spc + y ,  0 , 1   , 'atmtxt' ;
      'edit' ,       '123'   ,@blkrepatm_cb,spc + y , +1 , 1   , 'repedt' ;
      'edit' ,       '123'   ,@blkrepatm_cb,spc + y ,  0 , 1   , 'atmedt' ;
      'text' ,  'Task var'   ,         '' , spc + y , +1 , 1   , 'vartxt' ;
'pushbutton' ,         '+'  ,@blkvarbtn_cb, spc + y , +1 , 1   , 'varadd' ;
'pushbutton' ,         '-'  ,@blkvarbtn_cb, spc + y , +1 , 1   , 'varmin' ;
'pushbutton' ,   'Add all'  ,  @addall_cb ,       y , +1 , 1   , 'addall' ;
 'popupmenu' , { '<empty>' } ,         '' , spc + y ,  0 , 1.5 , 'varpop' ;
   'listbox' ,          ''   ,         '' ,       y ,  0 , 1.6 , 'varlst'};
 
  % Define control links. That is , which controls' behaviour depends on
  % the state of some other? The handle will be kept in .UserData.uilink
  % L gives two field names. The one we assign to, then the one we link.
  L = { 'blkadd' , { 'blklst' , 'varpop' , 'blkmin' } ;
        'blkmin' , { 'blkadd' , 'blklst' } ;
        'bnmedt' , { 'blkadd' , 'blklst' } ;
        'repedt' , { 'blkadd' , 'blklst' } ;
        'atmedt' , { 'blkadd' , 'blklst' } } ;
      
	% Tool tips for each control
  TT = repmat ( { '' } , size ( C , 1 ) , 1 ) ;
  i = ~ strcmp ( C ( : , 1 ) , 'text' ) ;
  TT ( i ) = { { 'Add new block' , 'Done new block' } ; % blkadd
               { 'Remove block' , 'Abort new block' } ; % blkmin
               'Select block to view/remove' ; %blklst 
               'Edit block name' ; % bnmedt
               'Num. times to repeat block' ; % repedt
sprintf( 'Num. times to reshuffle\nbroken/aborted trials' ) ; % atmedt
               'Add task variable to block' ; % varadd
               'Remove task variable from block'  ; % varmin
               'Add all task variables to list' ; % addall
               'Select task var to add' ; % varpop
sprintf( 'View block''s vars\nSelect to remove' ) } ; % varlst
  
  % Generate controls
  for  i = 1 : size ( C , 1 )
    
    % Get parameters
    c = [ C( i , : ) , TT( i ) ] ;
    [ sty , str , call , ver , jmp , wid , fn , tt ] = c { : } ;
    
    % Generate
    b.( fn ) = uicontrol ( h , 'Style' , sty , ...
      'String' , str , 'BackgroundColor' , 'k' , ...
      'ForegroundColor' , 'w' , 'Tag' , tag , 'Units' , h.Units , ...
      'Callback' , call ) ;
    
    % Tooltip
    if  iscell ( tt )
      b.( fn ).UserData.alt_tooltip = tt { 2 } ;
      tt = tt { 1 } ;
    end
    b.( fn ).TooltipString = tt ;
    
    % Default horizontal position
    b.( fn ).Position( 1 ) = spc ;
    
    % Set vertical position
    b.( fn ).Position( 2 ) = ver  +  jmp * b.( fn ).Position( 4 ) ;
    
    % Apply width multiplier
    b.( fn ).Position( 3 ) = wid  *  b.( fn ).Position( 3 ) ;
    
    % Adjust text controls according to string
    if  any ( strcmp ( sty , { 'text' , 'edit' } ) )
      
      b.( fn ).Position( 3 ) = 1.1 * b.( fn ).Extent( 3 ) ;
      
    % Square pushbuttons
    elseif  strcmp ( sty , 'pushbutton' )
      
      b.( fn ).Position ( 3 ) = b.( fn ).Position ( 4 ) ;
      
    end
    
  end % generate
  
  % Link controls
  uilink ( L , b )
  
  % Left justify block , block name , and var text. And name edit box
  c = [ b.blktxt , b.bnmtxt , b.vartxt , b.bnmedt ] ;
  set ( c , 'HorizontalAlignment' , 'left' )
  
  % Right justify rep and atm text and edits
  c = [ b.reptxt , b.atmtxt , b.repedt , b.atmedt ] ;
  set ( c , 'HorizontalAlignment' , 'right' )
  
  % Get top position of group
  top = sum ( b.blktxt.Position ( [ 2 , 4 ] ) ) ;
  
  % Align Block block buttons and block list
  x = sum ( b.blkadd.Position ( [ 1 , 3 ] ) ) ;
  b.blkmin.Position( 1 ) = x ;
  
  x = sum ( [ b.blkmin.Position( [ 1 , 3 ] ) ,       0 ;
              b.blktxt.Position( [ 1 , 3 ] ) , spc / 2 ] , 2 ) ;
  b.blklst.Position( 1 ) = max ( x ) ;
  
  % Align var list , menu , buttons and text
  x = spc  +  w  -  b.varlst.Position( 3 ) ;
  b.varlst.Position( 1 ) = x ;
  
  x = x  -  spc / 2 ;
  b.varmin.Position( 1 ) = x  -  b.varmin.Position( 3 ) ;
  
  x = x - b.varmin.Position( 3 ) ;
  b.varadd.Position( 1 ) = x  -  b.varadd.Position( 3 ) ;
  
  x = x - b.varadd.Position( 3 ) ;
  b.vartxt.Position( 1 ) = x  -  b.vartxt.Position( 3 ) ;
  
  x = [ b.vartxt.Position( 1 ) , sum( b.varmin.Position ( [ 1 , 3 ] ) ) ] ;
  dx = diff ( x ) ;
  wid = max ( [ dx , b.varpop.Position( 3 ) ] ) ;
  x = x( 1 )  -  wid  +  dx ;
  
  b.varpop.Position( [ 1 , 3 ] ) = [ x , wid ] ;
  
  % Find empty space to distribute between lists and menu minus spaces
  W = [ sum( b.blklst.Position( [ 1 , 3 ] ) ) - b.blktxt.Position( 1 ) ;
        sum( b.varlst.Position( [ 1 , 3 ] ) ) - b.varpop.Position( 1 ) ;
        b.atmtxt.Position( 3 ) ; b.atmedt.Position( 3 ) ] ;
	W = sum ( W )  +  2 * spc ;
  W = ( w  -  W )  /  3 ;
  
  % Apply extra width to lists and menu
  b.blklst.Position( 3 ) = b.blklst.Position( 3 ) + W ;
  b.varlst.Position( 3 ) = b.varlst.Position( 3 ) + W ;
  b.varpop.Position( 3 ) = b.varpop.Position( 3 ) + W ;
  
  % Adjust var control positions
  c = [ b.varadd , b.varmin , b.varpop , b.varlst ] ;
  jmp = [ 1 , 1 , 2 , 1 ] ;
  
  for  i = 1 : numel ( c )
    c( i ).Position( 1 ) = c( i ).Position( 1 )  -  jmp( i ) * W ;
  end
  
  b.vartxt.Position( 1 ) = b.varpop.Position( 1 ) ;
  
  % Widen the Add All button to match length of string
  b.addall.Position( 3 ) = 1.1 * b.addall.Extent( 3 ) ;
  
  % Now align the top of that button with the bottom of the pop-down menu
  b.addall.Position( 2 ) = b.varpop.Position( 2 )  -  ...
    b.addall.Position( 4 )  -  spc / 2 ;
  
  % And align the right side of that button with the pop-down menu
  b.addall.Position( 1 ) = sum (  b.varpop.Position( [ 1 , 3 ] )  )  -  ...
    b.addall.Position( 3 );
  
  % Place rep and atm edits left justified in between other groups
  x = [ sum( b.blklst.Position( [ 1 , 3 ] ) ) , b.varpop.Position( 1 ) ] ;
  x = [ spc , -spc ]  +  x ;
  
  p = b.atmtxt.Position ( 3 )  +  b.atmedt.Position ( 3 ) ;
  p = ( diff ( x ) - p )  /  2 ;
  x = x( 1 )  +  p ;
  
  b.atmtxt.Position( 1 ) = x ;
  b.atmedt.Position( 1 ) = x  +  b.atmtxt.Position( 3 ) ;
  b.repedt.Position( 1 ) = b.atmedt.Position( 1 ) ;
  
  x = b.repedt.Position( 1 )  -  b.reptxt.Position( 3 ) ;
  b.reptxt.Position( 1 ) = x ;
  
  % Set height of list boxes
  p = top  -  y ;
  b.blklst.Position ( 4 ) = p ;
  b.varlst.Position ( 4 ) = p ;
  
  % Set alignment of block name controls
  b.bnmedt.Position ( [ 1 , 3 ] ) = b.blklst.Position ( [ 1 , 3 ] ) ;
  
  x = b.bnmedt.Position ( 1 )  -  b.bnmtxt.Position ( 3 ) ;
  b.bnmtxt.Position ( 1 ) = x ;
  
  % Empty strings in edits
  c = findobj ( h , 'tag' , tag , 'style' , 'edit' ) ;
  set ( c , 'string' , '' )
  
  % Bold block text
  b.blktxt.FontWeight = 'bold' ;
  b.blktxt.Position( 3 ) = 1.1 * b.blktxt.Extent( 3 ) ;
  
  
end % uiblock


function  [ e , top ] = uievar ( h , x , y , wid )
  
  % Tool tip
  TT = sprintf( [ 'origin  x , y\norigin  x_left , y_top , x_right ,' , ...
    ' y_bottom\norigin  x_left , y_top , x_right , y_bottom , ' , ...
    'grid_number\n\ndisparity  d\ndisparity  d_near , d_far\ndisparity',...
    '  d_near , d_far , step_number\n\nreward  baseline , slope' ] ) ;
  
  % Environment variables
  EVNAME = { 'Origin' , 'Disparity' , 'Reward' } ;
  NUMCOL = [ 5 , 3 , 2 ] ;
  MAXCOL = max ( NUMCOL ) ;
  COLFMT = repmat ( { 'numeric' } , 1 , MAXCOL ) ;
  
  % Make table
  e.tab = uitable ( h , 'ColumnName' , '' , 'RowName' , EVNAME , ...
    'Units' , h.Units , 'ForegroundColor' , 'w' , ...
    'BackgroundColor' , [ 0.35 , 0.35 , 0.35 ; 0.2 , 0.2 , 0.2 ] , ...
    'Data' , cell ( numel ( EVNAME ) , MAXCOL ) , 'TooltipString' , TT ,...
    'ColumnEditable' , true , 'CellEditCallback' , @evar_cb , ...
    'ColumnFormat' , COLFMT ) ;
  
  % Set unused elements
  for  i = 1 : numel ( NUMCOL )
    
    n = NUMCOL ( i ) ;
    e.tab.Data ( i , n + 1 : end ) = repmat( { '---' } , 1 , MAXCOL - n ) ;
    
  end
  
  % Position the table
  e.tab.Position ( 1 : 3 ) = [ x , y , wid ] ;
  
  % Reduce columns until extent matches width
  fitcols ( e.tab )
  
  % Match vertical extent
  e.tab.Position ( 4 ) = e.tab.Extent ( 4 ) ;
  
  % Redefine y to make label
  e.tab.Units = h.Units ;
  y = sum ( e.tab.Position ( [ 2 , 4 ] ) ) ;
  
  % Label
  e.txt = uicontrol ( h , 'Style' , 'text' , 'String' , ...
    'Environment variables' , 'BackgroundColor' , 'k' , ...
    'ForegroundColor' , 'w' , 'FontWeight' , 'bold' , 'Units' , h.Units ) ;
  
  % Position title
  e.txt.Position ( 1 : 2 ) = [ x , y ] ;
  
  % Top of control group
  top = sum ( e.txt.Position ( [ 2 , 4 ] ) ) ;
  
  % Match width string
  e.txt.Position( 3 ) = 1.1  *  e.txt.Extent( 3 ) ;
  
end % uievar


function  uilink ( L , S )
% 
% Expects L to be two column cell of field names in struct S. Col 1 must be
% a single string. Col 2 can be a string or cell array of strings. Struct S
% contains a uicontrol in each field.
% 
  
  % Convert control struct to array for linking
  H = struct2array ( S ) ;
  F =   fieldnames ( S ) ;
  
  % Link controls
  for  i = 1 : size ( L , 1 )
    
    % Get field names
    f = L ( i , : ) ;
    [ receive , linked ] = f { : } ;
    
    % Find indeces of linked controls
    [ ~ , j ] = ismember ( linked , F ) ;
    
    % Programming error!
    if  all ( ~j )
      meterror (  'metsessdlg: Failed to link uicontrols , review code'  )
    end
    
    % Store linked handles
    S.( receive ).UserData.uilink = H ( j ) ;
    
  end % link
  
end % findlinked

