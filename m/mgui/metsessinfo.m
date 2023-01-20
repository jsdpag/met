
function  [ h , update , reset , recover , close ] = metsessinfo
% 
% [ h , update , reset , recover , close ] = metsessinfo
% 
% Creates a MET Session Info GUI. This displays information about the
% subject, the current session, trial, and block. It also provides block
% controls. These enable the user to skip to the next block in one of two
% ways. By hitting 'Next' a signal to metgui is made to mark the current
% block down in the block buffer for later analysis. 'Abort' means that the
% current block is not to be used for analysis.
% 
% The figure's UserData will be a scalar struct. Field .guiflg will be a
% single character, being 'd' for down, 'b' for block change request,
% 'e' for environment variable change request, and 'a' for block and
% environment variable changes. Field .abortblk will be non-zero if the
% current block was aborted by the user, meaning that it was not successful
% enough for later analysis. Field .evar will be a copy of the same field
% from a session descriptor, and can be assigned directly to .evar of the
% current session descriptor. Field blockcntl will contain a graphics
% object vector of the block controls.
% 
% Saves a recovery file called metsessinfo_rec.mat in the session's
% recovery/mgui directory that metgui creates.
% 
% Written by Jackson Smith - Sept 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  % MET constants and MET controller constants
  global  MC  MCC
  
  % If these haven't been set yet then set them
  if  isempty ( MC  )  ,   MC  = met ( 'const' , 1 ) ;  end
  if  isempty ( MCC )  ,   MCC = metctrlconst        ;  end
  
  
  %%% Constants %%%
  
  % Title bar
  TITBAR = 'MET Session Information' ;
  
  % Border margins , in pixels
  BMARG = 10 ;
  
  % Control margin , in pixels
  CMARG = 5 ;
  
  % uicontrol colours
  UICOLS = {  'BackgroundColor' , 'ForegroundColor'  ;  'k' , 'w'  } ;
  
  % uitable colours
  TABCOL = {               'BackgroundColor' , 'ForegroundColor'  ;
    [ 0.35 , 0.35 , 0.35 ; 0.2 , 0.2 , 0.2 ] , 'w'  } ;
  
  % Block lock colours
  BLOCOFF = [ 0.4 , 0 , 0 ] ;
  BLOCON  = [ 1.0 , 0 , 0 ] ;
  
  % Number of trials buffered by outcome plot
  NTRIALS = 250 ;
  
  % Animated line colours
  ANICOL.correct = [ 1 , 1 , 1 ]  *  0.8 ;
  ANICOL.failed  = [ 1 , 0 , 0 ]  *  0.8 ;
  ANICOL.ignored = [ 0.5 , 0.5 , 1 ]  *  0.8 ;
  ANICOL.broken  = [ 1 , 1 , 0 ]  *  0.8 ;
  ANICOL.aborted = [ 1 , 0.8 , 1 ] * 0.8 ;
  
  % Order of table properties
  TPROPS = { 'RowName' , 'ColumnName' , 'Data' , 'ColumnEditable' } ;
  
  % Axes properties
  APROPS = { 'Color' , 'none' , 'Box' , 'on' , 'XColor' , 'w' , ...
    'YColor' , 'w' , 'LineWidth' , 1 , 'YDir' , 'reverse' , ...
    'TickDir' , 'out' , 'XGrid' , 'on' , 'GridColor' , 'w' , ...
    'Units' , 'pixels' , 'YLim' , [ 0.5 , 5.5 ] , 'YTick' , 1 : 5 , ...
    'YTickLabel' , { 'corr' , 'fail' , 'ign' , 'brk' , 'abr' } , ...
    'YTickLabelRotation' , 40 , 'XTickLabel' , [] } ;
  
  % Table values
  EVAR = { { 'Origin' , 'Disp' , 'Reward' } , [] , cell( 3 , 5 ) } ;
  EVAR{ 3 }( 1 , 1 : 2 ) = num2cell ( MCC.DAT.SD.evar.origin ) ;
  EVAR{ 3 }{ 2 , 1     } = MCC.DAT.SD.evar.disp ;
  EVAR{ 3 }( 3 , 1 : 2 ) = num2cell ( MCC.DAT.SD.evar.reward ) ;
  EVAR{ 3 }( [ 9 , 11 , 12 , 14 , 15 ] ) = { '---' } ;
  
  % Environment variable column format
  COLFMT = repmat ( { 'numeric' } , 1 , 5 ) ;
  
  % UserData for reward buttons , remembers what the MET signal identifier
  % is for mrdtype and mreward
  REWBTN.mrdtype = MCC.MSID.mrdtype ;
  REWBTN.mreward = MCC.MSID.mreward ;
  
  % Origin text string
  ORISTR = 'Origin ( Hor , Ver , Disp ):' ;
  
  % Control properties:
  %  function , Name value pairs , Tag , Callback , new row , spaces
  % New row can be integers 1 , 2 , ... to say how much space should be
  % placed between this row and the last row. spaces is number of control
  % margins to insert before placing the left side of the new control
  CPROPS = ...
    { 'uicontrol' , { 'text' , 'Type:' }            , 'reward' , 1 , 2 ;
      'uicontrol' , { 'popupmenu' , { '1' , '2' } } , 'reward' , 0 , 0 ;
      'uicontrol' , { 'text' , 'Size (ms):' }       , 'reward' , 0 , 7 ;
      'uicontrol' , { 'edit' , '0' }                , 'reward' , 0 , 0 ;
      'uicontrol' , { 'pushbutton' , 'Set type' }   , 'reward' , 0 , 7 ;
      'uicontrol' , { 'pushbutton' , 'Reward' }     , 'reward' , 0 , 1 ;
      'uicontrol' , { 'text' , 'Manual rewards' }   , 'reward' , 1 , 0 ;
      'uitable'   , [ EVAR , true , { 1 } ]             , 'evar' , 2 , 0 ;
      'uicontrol' , { 'text' , 'Environment variables'} , 'evar' , 1 , 0 ;
      'uicontrol' , { 'togglebutton' , '' }       , 'uiblock' , 2 , 2 ;
      'uicontrol' , { 'pushbutton' , 'Next' }     , 'uiblock' , 0 , 3 ;
      'uicontrol' , { 'pushbutton' , 'Abort' }    , 'uiblock' , 0 , 1 ;
      'uicontrol' , { 'text' , 'Block controls' } , 'uiblock' , 1 , 0 ;
      'uitable'   , [ EVAR , false , { 2 } ]      , 'var' , 2 , 0 ;
      'uicontrol' , { 'text' , 'Task variables' } , 'var' , 1 , 0 ;
      'uicontrol' , { 'text' , 'Ignored:' } , 'outcome' , 2 , 7 ;
      'uicontrol' , { 'text' , '0' }        , 'ignored' , 0 , 0 ;
      'uicontrol' , { 'text' , 'Broken:' }  , 'outcome' , 0 , 2 ;
      'uicontrol' , { 'text' , '0' }        , 'broken'  , 0 , 0 ;
      'uicontrol' , { 'text' , 'Aborted:' } , 'outcome' , 0 , 2 ;
      'uicontrol' , { 'text' , '0' }        , 'aborted' , 0 , 0 ;
      'uicontrol' , { 'text' , 'Correct:' } , 'outcome' , 1 , 7 ;
      'uicontrol' , { 'text' , '0' }        , 'correct' , 0 , 0 ;
      'uicontrol' , { 'text' , 'Failed:' }  , 'outcome' , 0 , 2 ;
      'uicontrol' , { 'text' , '0' }        , 'failed'  , 0 , 0 ;
      'uicontrol' , { 'text' , '% correct:'}, 'outcome' , 0 , 2 ;
      'uicontrol' , { 'text' , '0' }        , '%corr'   , 0 , 0 ;
      'axes'      , APROPS                  , 'outcome' , 2 , 0 ;
      'uicontrol' , { 'text' , 'Outcomes' } , 'outcome' , 1 , 0 ;
      'uicontrol' , { 'text' , ORISTR }           , 'session' , 2 , 0 ;
      'uicontrol' , { 'text' , '<none>' }         , 'origin'  , 0 , 0 ;
      'uicontrol' , { 'text' , 'Task:' }          , 'session' , 1 , 0 ;
      'uicontrol' , { 'text' , '<none>' }         , 'task'    , 0 , 2 ;
      'uicontrol' , { 'text' , 'Block:' }         , 'session' , 1 , 0 ;
      'uicontrol' , { 'text' , '<none>' }         , 'block'   , 0 , 0 ;
      'uicontrol' , { 'text' , 'Trial:' }         , 'session' , 0 ,15 ;
      'uicontrol' , { 'text' , '0' }              , 'trial'   , 0 , 0 ;
      'uicontrol' , { 'text' , 'Tags:' }          , 'session' , 2 , 0 ;
      'uicontrol' , { 'text' , '<none>' }         , 'tags'    , 0 , 2 ;
      'uicontrol' , { 'text' , 'Subject:' }       , 'session' , 1 , 0 ;
      'uicontrol' , { 'text' , '<none>' }         , 'subject' , 0 , 0 ;
      'uicontrol' , { 'text' , 'Exp. ID:' }       , 'session' , 0 ,15 ;
      'uicontrol' , { 'text' , '0' }              , 'expid'   , 0 , 0 ;
      'uicontrol' , { 'text' , 'Sess. ID:' }      , 'session' , 0 , 2 ;
      'uicontrol' , { 'text' , '0' }              , 'sessid'  , 0 , 0 } ;
    
    
  %-- Callbacks --%
  
  % Specified control receives specified callback , order is
  % { callback string , callback handle , Name , Value , ... }
  CALBAK = { ...
  'Callback' , @blkloc_cb   , 'Tag', 'uiblock' , 'Style'  , 'togglebutton';
  'Callback' , @blkbutton_cb, 'Tag', 'uiblock' , 'String' , 'Next'        ;
  'Callback' , @blkbutton_cb, 'Tag', 'uiblock' , 'String' , 'Abort'       ;
  'Callback' , @rdsize_cb   , 'Tag', 'reward'  , 'Style'  , 'edit'        ;
  'Callback' , @rdbutton_cb , 'Tag' , 'reward' , 'String' , 'Set type'    ;
  'Callback' , @rdbutton_cb , 'Tag' , 'reward' , 'String' , 'Reward'      ;
  'CellEditCallback' , @evar_cb , 'Type' , 'uitable' , 'Tag' , 'evar'   } ;
  
  
  %-- Alignment --%
  
  % Horizontally align pairs of uicontrols with these properties , fifth
  % column says whether to right-justify
  HALIGN = { 'String' ,   'Correct:' , 'String' , 'Ignored:' , 1 ;
             'String' ,    'Failed:' , 'String' ,  'Broken:' , 1 ;
             'String' , '% correct:' , 'String' , 'Aborted:' , 1 ;
                'Tag' ,    'correct' ,    'Tag' ,  'ignored' , 0 ;
                'Tag' ,     'failed' ,    'Tag' ,   'broken' , 0 ;
                'Tag' ,      '%corr' ,    'Tag' ,  'aborted' , 0 ;
             'String' ,   'Subject:' , 'String' ,    'Tags:' , 1 ;
             'String' ,   'Subject:' , 'String' ,    'Task:' , 1 ;
             'String' ,   'Subject:' , 'String' ,   'Block:' , 1 ;
             'String' ,   'Exp. ID:' , 'String' ,   'Trial:' , 1 ;
                'Tag' ,    'subject' ,    'Tag' ,     'tags' , 0 ;
                'Tag' ,    'subject' ,    'Tag' ,    'block' , 0 ;
                'Tag' ,    'subject' ,    'Tag' ,     'task' , 0 ;
                'Tag' ,      'expid' ,    'Tag' ,    'trial' , 0 } ;
              
	% Stretch width of specified controls out to touch the second specified
	% control. If second control is not specified then xmax, the maximum
	% position of a control on the figure, will be used.
  STRTCH = { 'Tag' , 'subject' , 'String' , 'Exp. ID:' ;
             'Tag' , 'tags'    , ''       , ''         ;
             'Tag' , 'block'   , 'String' , 'Trial:'   ;
             'Tag' , 'task'    , ''       , ''         ;
             'Tag' , 'origin'  , ''       , ''         } ;
  
  
  %-- Tool tips --%
  
  % Block controls
  TTBLOC = 'Lock/unlock block controls' ;
  TTBNEX = sprintf (  'Accept current block\nand proceed to next'  ) ;
  TTBABT = sprintf (  'Reject current block\nand proceed to next'  ) ;
  
  % Environment variables
  TTEVAR = sprintf (  ...
    [ 'origin  x , y\n'  ,  ...
      'origin  x_left , y_top , x_right , y_bottom\n'  ,  ...
      'origin  x_left , y_top , x_right , y_bottom , grid_number\n\n'  ,...
      'disparity  d\n'  ,  ...
      'disparity  d_near , d_far\n'  ,  ...
      'disparity  d_near , d_far , step_number\n\n'  ,  ...
      'reward  baseline , slope' ]  ) ;
    
  % Manual rewards
  TTRTYP = 'Select reward type' ;
  TTRSIZ = sprintf ( 'The pump runs for\nthis duration' ) ;
  TTRSET = sprintf (  ...
    [ 'Set reward type but give no reward.\n'  ,  ...
      'Note that a MET signal event could reset\n'  ,  ...
      'the reward type if it sends mrdtype.' ]  ) ;
  TTRREW = sprintf ( 'Set reward type and\ngive reward' ) ;
  
  % Associate strings with control properties
  TT = { TTBLOC , 'uiblock' , 'String' , ''          ;
         TTBNEX , 'uiblock' , 'String' , 'Next'      ;
         TTBABT , 'uiblock' , 'String' , 'Abort'     ;
         TTEVAR ,    'evar' , 'Type'   , 'uitable'   ;
         TTRTYP ,  'reward' , 'Style'  , 'popupmenu' ;
         TTRSIZ ,  'reward' , 'Style'  , 'edit'      ;
         TTRSET ,  'reward' , 'String' , 'Set type'  ;
         TTRREW ,  'reward' , 'String' , 'Reward'    } ;
  
  
  %%% Generate figure %%%
  
  % Initialise UserData send MET signals via metgui
  s = struct (  'guiflg'  ,  'd'  ,  'abortblk'  ,  0  ,  ...
    'evar' , MCC.DAT.SD.evar , 'blockcntl'  ,  gobjects ( 0 )  ,  ...
    'mstop'  ,  []  ) ;
  s.mstop = MC.SIG{  strcmp(  MC.SIG( : , 1 )  ,  'mstop'  )  ,  2  } ;
  
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Visible' , 'off' , 'DockControls' , 'off' , 'UserData' , s ) ;
  
  
  %%% Generate user controls %%%
  
  % Initial horizontal and vertical position in the figure
  x = BMARG ;  y = BMARG - CMARG ;
  
  % Maximum horizontal position encountered
  xmax = x ;
  
  % Initialise c so that it runs on the first iteration , will be
  % overwritten
  c.Type = '' ;
  c.Position = zeros ( 4 , 1 ) ;
  
  for  i = 1 : size ( CPROPS , 1 )
    
    % Get record for this control
    [ fnam , prop , tag , nl , ns ] = CPROPS { i , : } ;
    
    % Choose a generator function and assemble name/value pairs
    switch  fnam
      
      case  'uicontrol'
        f = @uicontrol ;
        prop = [  { 'Style' , 'String' }  ;  prop  ] ; %#ok
        prop = [  prop  ,  UICOLS  ] ; %#ok
                            
      case  'uitable'
        f = @uitable ;
        yexmul = prop { end } ; % y-axis extent multiplier
        prop = [  TPROPS  ;  prop( 1 : end - 1 )  ] ;
        prop = [  prop  ,  TABCOL  ] ; %#ok
        
      case  'axes'
        f = @axes ;
        
    end
    
    % Set x and y positions
    if  nl
      
      % New line , rise by a multiple of control margin spaces , plus the
      % height of the last control
      y = y  +  nl * CMARG ;
      switch  c.Type
        case  'axes'
          y = y  +  c.Position ( 4 )  +  c.TightInset ( 2 ) ;
        otherwise
          y = y  +  c.Position ( 4 ) ;
      end
      
      % Reset x position
      x = BMARG ;
      
    end
    
    % Put spaces in front of control
    if   ns  ,  x = ceil (  x  +  ns * CMARG  ) ;  end
    
    % Generate control
    c = f (  'Parent'  ,  h  ,  'Tag'  ,  tag  ,  prop { : }  ) ;
    c.Position( 1 : 2 ) = [ x , y ] ;
    
    % Automatic reshaping
    switch  c.Type
      
      case  'uicontrol'
        
        % Match text width to number of characters if it is a label.
        % Dynamic texts will have '0' or 'none' as a string.
        if  strcmp ( c.Style , 'text' )  &&  ...
            ~ any ( strcmp(  c.String  ,  { '0' , '<none>' }  ) )

          % Set units to characters , match width , restore to pixels
          c.Units = 'characters' ;
          c.Position( 3 ) = numel ( c.String ) + 1 ;
          c.Units = 'pixels' ;
          
          % Left justified
          c.HorizontalAlignment = 'left' ;

        end
    
      case  'uitable'
      
        % Match size to extent of the data
        c.Position( 3 : 4 ) = [ 1 , yexmul ]  .*  c.Extent( 3 : 4 ) ;
        
        % Store extent for axes reshaping
        tabext = c.Position( 3 : 4 ) ;
        
      case  'axes'
        
        % Match width and height to most recent table
        c.Position( 3 : 4 ) = tabext ;
        
        % Then make sure that left and bottom labels show
        c.Position( 1 : 2 ) = c.Position( 1 : 2 ) + c.TightInset( 1 : 2 ) ;
        c.Position( 3 : 4 ) = c.Position( 3 : 4 ) - c.TightInset( 1 : 2 ) ;
        
    end % reshaping
    
    % Advance horizontal position to right-hand side of new control
    x = x  +  c.Position ( 3 ) ;
    
    % Find new horizontal position
    if  xmax  <  x  ,  xmax = x ;  end
    
  end % ui controls
  
  % Reshape figure
  x = xmax  +  BMARG ;
  y = y  +  BMARG  +  c.Position ( 4 ) ;
  h.Position( 3 : 4 ) = [ x , y ] ;
  h.Position( 2 ) = y ;
  
  
  %%% Assign Callbacks %%%
  
  for  i = 1 : size ( CALBAK , 1 )
    
    % Find object
    c = findobj (  h.Children  ,  CALBAK { i , 3 : end }  ) ;
    
    % Set callback
    set ( c , CALBAK { i , 1 : 2 } )
    
  end % callbacks
  
  
  %%% Align controls %%%
  
  % We can reduce 'Subject:' text down to match number of characters, the
  % buffer is not needed for this character combination
  c = findobj (  h.Children  ,  'String'  ,  'Subject:'  ) ;
  c.Units = 'characters' ;
  c.Position( 3 ) = numel (  c.String  ) ;
  c.Units = 'pixels' ;
  
  % Right-justify 'Sess. ID:' text
  c = findobj (  h.Children  ,  'String'  ,  'Sess. ID:'  ) ;
  c.HorizontalAlignment = 'right' ;
  
  % Match horizontal alignment for a subset of uicontrol pairs. Align
  % right-hand edges to the furthest edge.
  for  i = 1 : size ( HALIGN , 1 )
    
    % Find pair of controls
    c = findobj ( h.Children , ...
      'Type' , 'uicontrol' , HALIGN { i , 1 : 2 } ) ;
    d = findobj ( h.Children , ...
      'Type' , 'uicontrol' , HALIGN { i , 3 : 4 } ) ;
    
    % Get maximum right-hand position
    mr = max( sum (  [ c.Position( [ 1 , 3 ] ) ;
                       d.Position( [ 1 , 3 ] ) ]  ,  2  ) ) ;
    
    % Match widths
    if  c.Position ( 3 )  <  d.Position ( 3 )
      c.Position( 3 ) = d.Position ( 3 ) ;
    else
      d.Position( 3 ) = c.Position ( 3 ) ;
    end
    
    % Align one to the other
    c.Position( 1 ) = mr  -  c.Position ( 3 ) ;
    d.Position( 1 ) = mr  -  d.Position ( 3 ) ;
    
    % Right justify if instructed to
    if  HALIGN { i , 5 }
      c.HorizontalAlignment = 'right' ;
      d.HorizontalAlignment = 'right' ;
    end
    
  end % match horizontal alignment
  
  % Stretch out width of specified controls. Either to the left edge of
  % another control. Or to xmax.
  for  i = 1 : size ( STRTCH , 1 )
    
    % Find first control
    c = findobj ( h.Children , ...
      'Type' , 'uicontrol' , STRTCH { i , 1 : 2 } ) ;
    
    % Find value to stretch to
    if  isempty (  STRTCH { i , 3 }  )
      
      % No other control given
      x = xmax ;
      
    else
      
      % Find other control and get left-hand position
      d = findobj ( h.Children , ...
      'Type' , 'uicontrol' , STRTCH { i , 3 : 4 } ) ;
      x = d.Position ( 1 ) ;
      
    end
    
    % Stretch control and left-justify
    c.Position( 3 ) = x  -  c.Position ( 1 ) ;
    c.HorizontalAlignment = 'left' ;
    
  end % stretch
  
  
  %%% Tool tips %%%
  
  % Loop controls
  for  i = 1 : size ( TT , 1 )
    
    % Find control
    c = findobj (  h.Children  ,  'Tag'  ,  TT { i , 2 : end }  ) ;
    
    % Set tool tip string
    c.TooltipString = TT { i , 1 } ;
    
  end % tool tips
  
  
  %%% Final touches %%%
  
  % Reset children's Units to normalised , so that the user can resize the
  % figure
  set ( h.Children , 'Units' , 'normalized' )
  
  % Find and store block and evar controls in user data. These handles will
  % be passed to MET Remote, which will enable/disable them as the task
  % starts and stops.
  c = findobj ( h.Children , 'Tag' , 'uiblock' , '-or' , 'Tag' , 'evar' ) ;
  c = findobj ( c , '-not' , 'Style' , 'text' ) ;
  h.UserData.blockcntl = reshape (  c  ,  1  ,  numel( c )  ) ;
  
  % Set block lock colours , turn lock on
  c = findobj( c , 'Style' , 'togglebutton' ,'Tag' , 'uiblock' ) ;
  c.UserData = struct ( 'on' , BLOCON , 'off' , BLOCOFF ) ;
  c.BackgroundColor = c.UserData.on ;
  c.Value = 1 ;
  
  % Give block lock handle to block buttons
  d = findobj( h.Children , 'Style' , 'pushbutton' ,'Tag' , 'uiblock' ) ;
  set ( d , 'UserData' , c )
  
  % Empty task variable table
  c = findobj( h.Children , 'Type' , 'uitable' ,'Tag' , 'var' ) ;
  c.Data = [] ;
  c.RowName = [] ;
  
  % Make sure that manual reward size is set to default
  c = findobj ( h.Children , 'Tag' , 'reward' , 'Style' , 'edit' ) ;
  c.String = num2str ( MCC.DAT.SD.evar.reward ( 1 ) ) ;
  
  % Make animated lines for outcome plot
  c = findobj( h.Children , 'Type' , 'axes' ) ;
  c.UserData.ntrials = NTRIALS ;
  
  for  i = 1 : size ( MC.OUT , 1 )
    
    % Outcome string
    s = MC.OUT { i , 1 } ;
    
    % Make line for that outcome
    c.UserData.( s ) = animatedline (  'Parent'  ,  c  ,  ...
      'MaximumNumPoints'  ,  NTRIALS  ,  'LineStyle'  ,  'none'  ,  ...
      'Marker'  ,  '.'  ,  'MarkerEdgeColor'  ,  ANICOL.( s )  ,  ...
      'MarkerFaceColor'  ,  'none'  ) ;
    
  end % animated lines
  
  % Current trial number i.e. x-axis value
  c.UserData.trial = 0 ;
  
  % Make trial outcome controls' UserData into counters
  c = findobj ( h.Children , 'Tag' , 'correct' , '-or' , ...
    'Tag' , 'failed' , '-or' , 'Tag' , 'ignored' , '-or' , ...
    'Tag' , 'broken' , '-or' , 'Tag' , 'aborted' ) ;
  set ( c , 'UserData' , 0 )
  
  % Set format for env var table
  c = findobj( h.Children , 'Type' , 'uitable' ,'Tag' , 'evar' ) ;
  c.ColumnFormat = COLFMT ;
  
  % Give reward buttons the MET signal identifiers of mrdtype and mreward
  c = findobj( h.Children , 'Tag' , 'reward' ,'Style' , 'pushbutton' ) ;
  set ( c , 'UserData' , REWBTN )
  
  
  %%% Return function handles %%%
  
  update = @fupdate ;
   reset = @freset ;
 recover = @frecover ;
   close = @fclose ;
  
  
end % metsessinfo


%%% Callbacks %%%

% Set colour according to whether button is down
function  blkloc_cb ( h , ~ )
  
  if  h.Value
    h.BackgroundColor = h.UserData.on  ;
  else
    h.BackgroundColor = h.UserData.off ;
  end
  
end % blkloc_cb


% Report block change request to metgui if lock is off
function  blkbutton_cb ( h , ~ )
  
  % Block control lock is on
  if  h.UserData.Value  ,  return  ,  end
  
  % Raise MET Session Info's GUI flag , to alert metgui
  switch  h.Parent.UserData.guiflg
    
    % Flag is down , raise to block change
    case  'd'
      h.Parent.UserData.guiflg = 'b' ;
      
    % Evar change already raised , raise to all
    case  'e'
      h.Parent.UserData.guiflg = 'a' ;
      
  end % GUI flag
  
  % Report what to do with the current block
  h.Parent.UserData.abortblk = strcmp(  h.String  ,  'Abort'  ) ;
  
  % Now disable block controls. MET Remote will enable them when the new
  % block has stopped running.
  c = findobj ( h.Parent.Children , 'Tag' , 'uiblock' , ...
    '-not' , 'Style' , 'text' ) ;
  set ( c , 'Enable' , 'off' )
  
  % Turn on block lock
  h.UserData.Value = 1 ;
  h.UserData.Callback ( h.UserData , [] )
  
end % blkbutton_cb


% Report environment variable change to metgui
function  evar_cb ( h , d )
  
  % Row and column
  r = d.Indices ( 1 ) ;
  c = d.Indices ( 2 ) ;
  
  % Previous Data , New Data , Edit data
  PD = d.PreviousData ;
  ND = d.NewData ;
  ED = d.EditData ;
  
  % Row name , set to empty if we have blanked and then report evar change
  rnam = h.RowName{ r } ;
  
  % Do not allow dashed cells to change
  if  ischar ( PD )  &&  strcmp ( PD , '---' )
    
    h.Data{ r , c } = d.PreviousData ;
    return
    
  % Empty input string or spaces will cause space to be assigned in valid
  % columns
  elseif  isempty ( ED )  ||  ~ isempty ( regexp ( ED , '^ *$' , 'once' ) )
    
    % May not blank these cells
    if  ( r == 1  &&  c < 3 )  ||  ( r == 2  &&  c == 1 )  ||  ...
          r == 3
        
      h.Data{ r , c } = d.PreviousData ;
      return
      
    end
    
    h.Data{ r , c } = [] ;
    
    % Also empty any non-dashed cell to the right
    i = ~ strcmp ( h.Data( r , c + 1 : end ) , '---' ) ;
    i = find ( i ) ;
    h.Data( r , c + i ) = { [] } ;
    
    % Empty row name to skip correctness checks
    rnam = '' ;
  
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
  e = false ;
  
  switch  rnam
    
    case  'Origin'
      
      % Editing x0 when x1 is full , or editing x1
      if      (  c == 1  &&  ~ isempty ( h.Data{ r , 3 } )  )  ||  c == 3
        
        % Right extent of origin less than or equal to the left
      	e = h.Data{ r , 3 }  <=  h.Data{ r , 1 } ;
        
      % Editing y0 when y1 is full , or editing y1
      elseif  (  c == 2  &&  ~ isempty ( h.Data{ r , 4 } )  )  ||  c == 4
        
        % Bottom extent of origin above or equal to the top
        e = h.Data{ r , 2 }  <=  h.Data{ r , 4 } ;
        
      % Editing gridding value
      elseif  c == 5  &&  ( mod ( d.NewData , 1 )  ||  d.NewData <= 0 )
        
        % Grid number must be positive integer
        e = true ;
        
      end
      
    case  'Disp'
      
      if      1 < c  &&  h.Data{ r , 2 } < h.Data{ r , 1 }
        
        % Far disparity is closer than near
        e = true ;
        
      elseif  c == 3  &&  ( mod ( d.NewData , 1 )  ||  d.NewData <= 0 )
        
        % Space number must be positive integer
        e = true ;
        
      end
      
    case  'Reward'
      
      if  c == 1  &&  d.NewData < 0
        
        % Negative baseline reward
        e = true ;
        
      elseif  c == 1  &&  d.NewData <= 0
        
        % Non-positive reward slope
        e = true ;
        
      end
      
  end % rows
  
  % Error detected , revert to previous value
  if  e
    h.Data{ r , c } = d.PreviousData ;
    return
  end
  
  % Otherwise , raise MET Session Info's GUI flag , to alert metgui
  switch  h.Parent.UserData.guiflg
    
    % Flag is down , raise to evar change
    case  'd'
      h.Parent.UserData.guiflg = 'e' ;
      
    % Block change already raised , raise to all
    case  'b'
      h.Parent.UserData.guiflg = 'a' ;
      
  end % GUI flag
  
  % Find valid column indeces for origin
  if  isempty ( h.Data{ 1 , 4 } )
    o = 2 ;
  else
    o = 5 ;
  end
  
  % Find valid column indeces for disparity
  if  isempty ( h.Data{ 1 , 3 } )
    d = 1 ;
  else
    d = 3 ;
  end
  
  % Update MET Session Info's evar struct
  evar = h.Parent.UserData.evar ;
  evar.origin = [ h.Data{ 1 , 1 : o } ] ;
  evar.disp   = [ h.Data{ 2 , 1 : d } ] ;
  evar.reward = [ h.Data{ 3 , 1 : 2 } ] ;
  h.Parent.UserData.evar = evar ;
  
end % evar_cb


% Set reward size
function  rdsize_cb ( h , ~ )
  
  % Convert input to number
  n = str2double ( h.String ) ;
    
  % Check form
  if      isnan ( n )  ||  n  <  1
    
    % Illegal number , set to 1
    n = 1 ;
    
  elseif  intmax ( 'uint16' )  <  n
    
    % Number too big , set to maximum ... assuming that MET signal cargo is
    % an unsigned 16 bit integer. Anyway, this will allow over 65 seconds
    % of reward to be delivered.
    n = intmax ( 'uint16' ) ;
    
  elseif  mod ( n , 1 )
    
    % Round up to remove fraction
    n = ceil ( n ) ;
    
  else
    
    % No problems
    return
    
  end
  
  % Set valid number
  h.String = num2str (  n  ) ;
  
end % rdsize_cb


% Queue a MET signal in the metgui buffer to change reward type or to
% deliver a reward
function  rdbutton_cb ( h , ~ )
  
  % Find reward input controls
  c = findobj ( h.Parent.Children , 'Tag' , 'reward' , ...
    '-not' , 'Style' , 'text' , '-not' , 'Style' , 'pushbutton' ) ;
  
  % Get reward size
  d = findobj ( c , 'Style' , 'popupmenu' ) ;
  t = str2double (  d.String { d.Value }  ) ;
  
  % Conditionally prepare input for metguiqsig
  if  strcmp ( h.String , 'Reward' )
    
    % Get reward size
    d = findobj ( c , 'Style' , 'edit' ) ;
    r = str2double ( d.String ) ;
    
    % Reward type and size
    sig = [ h.UserData.mrdtype , h.UserData.mreward ] ;
    crg = [ t , r ] ;
    
  else
    
    % Reward type
    sig = h.UserData.mrdtype ;
    crg = t ;
    
  end
  
  % Queue reward signals in metgui's buffer
  metguiqsig ( sig , crg )
  
end % rdbutton_cb


%%% metgui API %%%

function  drawnew = fupdate ( h , ~ , ~ , ~ , cbuf , ~ )
%
% drawnew = update ( h , sd , bd , td , cbuf , tbuf )
% 
% Only thing to update will be outcome controls
%
  
  
  %%% Global Constants %%%
  
  % MET compile-time constants
  global  MC
  
  
  %%% Get outcome value and name %%%
  
  % Initialise no changes
  drawnew = false ;
  
  % No MET signals , nothing to do
  if  ~ cbuf.new_msig  ,  return  ,  end
  
  % Find mstop 
  i = find (  cbuf.msig.sig  ==  h.UserData.mstop  ,  1  ,  'last'  ) ;
  
  % No mstop received , nothing to do
  if  isempty ( i )  ,  return  ,  end
  
  % Get outcome value
  outv = cbuf.msig.crg ( i ) ;
  
  % And map that to a name
  outn = MC.OUT { outv , 1 } ;
  
  
  %%% Update plot %%%
  
  % Find outcome plot
  c = findobj (  h.Children  ,  'Type'  ,  'axes'  ) ;
  
  % Increment trial counter
  c.UserData.trial = c.UserData.trial  +  1 ;
  
  % Add a point to the appropriate line
  addpoints ( c.UserData.( outn ) , c.UserData.trial , outv ) ;
  
  % And adjust x-axis limit
  c.XLim = [ 1 - c.UserData.ntrials , 0 ]  +  c.UserData.trial ;
  
  
  %%% Update text controcorrectl %%%
  
  % Find control
  c = findobj ( h.Children , 'Tag' , outn ) ;
  
  % Increment trial counter
  c.UserData = c.UserData  +  1 ;
  
  % Convert to string
  c.String = num2str ( c.UserData ) ;
  
  % If this is correct or failed then get the complimentary control
  switch  outn
    
    case  'correct'
      d = findobj ( h.Children , 'Tag' , 'failed'  ) ;
      nc = c.UserData ;
      nf = d.UserData ;
      
    case   'failed'
      d = findobj ( h.Children , 'Tag' , 'correct' ) ;
      nc = d.UserData ;
      nf = c.UserData ;
      
    otherwise
      d = [] ;
      
  end
  
  % Compute percent correct
  if  ~ isempty ( d )
    
    pc = nc  /  ( nc  +  nf )  *  100 ;
    
    % Find control and assign new string
    d = findobj ( h.Children , 'Tag' , '%corr' ) ;
    d.String = sprintf ( '%0.1f' , pc ) ;
    
  end
  
  % Report that MET GUI has changed appearance
  drawnew = true ;
  
end % update


function  freset ( h , v )
%
%  Expects v to be a 2 element cell , first element is string 'sd' , 'bd' ,
%  or 'td' saying what kind of descriptor , second element is descriptor
%
  
  
  %%% Global Constants %%%
  
  % MET constants and MET controller constants
  global  MC MCC
  
  
  %%% Handle descriptor %%%
  
  switch  v { 1 }
    
    case  'sd'
      
      % Find subject , experiment id , session id , and tag controls , and
      % environment variable table
      sub = findobj ( h.Children , 'Tag' , 'subject' ) ;
      eid = findobj ( h.Children , 'Tag' , 'expid'   ) ;
      sid = findobj ( h.Children , 'Tag' , 'sessid'  ) ;
      tag = findobj ( h.Children , 'Tag' , 'tags'    ) ;
     evar = findobj ( h.Children , 'Tag' , 'evar' , 'Type' , 'uitable' ) ;
      
      % Session descriptor
      sd = v { 2 } ;
      
      % Subject
      sub.String = sprintf (  MCC.FMT.SUBJECT  ,  ...
        sd.subject_id  ,  sd.subject_name  ) ;
      
      % Experiment id
      eid.String = sprintf ( '%d' , sd.experiment_id ) ;
      
      % Session id
      sid.String = sprintf ( '%d' , sd.session_id ) ;
      
      % Tags
      if  isempty (  sd.tags  )
        tag.String = '' ;
      else
        tag.String = strjoin (  sd.tags  ,  ' , '  ) ;
      end
      
      % Environment variables
      i = 0 ;
      for  F = { 'origin' , 'disp' , 'reward' }  ,  i = i + 1 ;
        n = numel (  sd.evar.( F{ 1 } )  ) ;
        evar.Data( i , 1 : n ) = num2cell (  sd.evar.( F{ 1 } )  ) ;
      end
      
      
    case  'bd'
      
      % Find block text and task var table
      blk = findobj ( h.Children , 'Tag' , 'block' ) ;
      var = findobj ( h.Children , 'Tag' , 'var' , 'Type' , 'uitable' ) ;
      
      % Block descriptor
      bd = v { 2 } ;
      
      % Block id and name
      blk.String = sprintf ( '%d (%s)' , bd.block_id , bd.name ) ;
      
      % Task var names to column headings
      var.ColumnName = bd.varnam ;
      
      % Table contents set to current trial deck
      var.Data = bd.deck ;
      
    case  'td'
      
      % Find trial id, task, and origin texts
      tid = findobj ( h.Children , 'Tag' , 'trial'  ) ;
      tsk = findobj ( h.Children , 'Tag' , 'task'   ) ;
      org = findobj ( h.Children , 'Tag' , 'origin' ) ;
      
      % Trial descriptor
      td = v { 2 } ;
      
      % Trial id
      tid.String = sprintf ( '%d' , td.trial_id ) ;
      
      % Task name and logic
      tsk.String = sprintf ( '%s (%s)' , td.task , td.logic ) ;
      
      % Origin
      O = num2cell ( td.origin ) ;
      org.String = sprintf ( '(%0.2f,%0.2f,%0.2f)' , O { : } ) ;
      
    case  'reset'
      
      % Find outcome axes
      aout = findobj ( h.Children , 'Type' , 'axes' ) ;
      
      % Set number of trials in plot and reset x-axis limits
      aout.UserData.trial = 0 ;
      aout.XLim = [ 1 - aout.UserData.ntrials , 0 ] ;
      
      % Loop outcomes
      for  i = 1 : size ( MC.OUT , 1 )

        % Outcome string
        s = MC.OUT { i , 1 } ;
        
        % Find text trial counter
        txtc = findobj ( h.Children , 'Style' , 'text' , 'Tag' , s ) ;
        
        % Set counter and re-build string
        txtc.UserData = 0 ;  txtc.String = '0' ;
        
        % Remove animated line data points
        clearpoints (  aout.UserData.( s )  )

      end % animated lines
      
      % Percent correct
      txtc = findobj ( h.Children , 'Style' , 'text' , 'Tag' , '%corr' ) ;
      txtc.String = sprintf ( '%0.1f' , 0 ) ;
      
  end
  
  
end % mgreset


function  frecover ( h , d )
% 
% recover ( h , sdir ) saves recovery data in the current session
% directory at the end of each trial.
% 
  
  
  %%% Global constants %%%
  
  global  MC
  
  
  %%% Handle recovery data %%%
  
  % Recovery file name
  f = fullfile (  d { 2 }  ,  'metsessinfo_rec.mat'  ) ;
  
  % Find outcome axes and texts
  aout = findobj ( h.Children , 'Type' , 'axes' ) ;
  
  % Animated line points
  C = cell ( 2 , 1 ) ;
  
  
  % Choose what function to perform
  switch  d { 1 }
  
    % Update recovery data in the given location. We need to save animated
    % line data points and trial counters. Build recovery struct rec.
    case  'save'
      
      % Get current trial at right-hand edge of axes
      rec.aout.trial = aout.UserData.trial ;
      
      % Loop outcomes
      for  i = 1 : size ( MC.OUT , 1 )

        % Outcome string
        s = MC.OUT { i , 1 } ;
        
        % Find text trial counter
        txtc = findobj ( h.Children , 'Style' , 'text' , 'Tag' , s ) ;
        
        % Get counter
        rec.( s ) = txtc.UserData ;
        
        % Get animated line x-axis data points , y-axis positions are fixed
        [  C{ : }  ]  =  getpoints (  aout.UserData.( s )  ) ;
        rec.aout.( s ) = C { 1 } ;

      end % animated lines
      
      % Save recovery data
      save ( f , 'rec' )
      
      
    % Get recovery data and place it back into GUI controls
    case  'load'
      
      % Recovery struct
      load ( f , 'rec' )
      
      % Set number of trials in plot and reset x-axis limits
      aout.UserData.trial = rec.aout.trial ; %#ok
      aout.XLim = [ 1 - aout.UserData.ntrials , 0 ] + aout.UserData.trial ;
      
      % Loop outcomes
      for  i = 1 : size ( MC.OUT , 1 )

        % Outcome string
        s = MC.OUT { i , 1 } ;
        
        % Find text trial counter
        txtc = findobj ( h.Children , 'Style' , 'text' , 'Tag' , s ) ;
        
        % Set counter and re-build string
        txtc.UserData = rec.( s ) ;
        txtc.String = sprintf (  '%d'  ,  txtc.UserData  ) ;
        
        % Get x-axis points , y-axis points are fixed
        C{ 1 } = rec.aout.( s ) ;
        C{ 2 } = i  *  ones ( size(  C { 1 }  ) ) ;
        
        % Set animated line data points
        clearpoints (  aout.UserData.( s )  )
          addpoints (  aout.UserData.( s )  ,  C { : }  )

      end % animated lines
      
      % Percent correct
      txtc = findobj ( h.Children , 'Style' , 'text' , 'Tag' , '%corr' ) ;
      
      if  rec.correct  ||  rec.failed
        pc = rec.correct  /  ( rec.correct + rec.failed )  *  100 ;
      else
        pc = 0 ;
      end
      
      txtc.String = sprintf ( '%0.1f' , pc ) ;
  
  end % choose functionality
  
end % mrrecover


function  fclose ( h )
  
  % Delete the figure , bypass close request callback
  delete ( h )
  
end % mgclose

