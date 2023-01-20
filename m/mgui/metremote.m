
function  [ h , update , reset , recover , close ] = metremote
% 
% [ h , update , reset , recover , close ] = metremote
% 
% Creates a MET remote control GUI. This allows the user to start, stop,
% and abort the session. A stop lock is automatically set when the session
% is started ; it must be disarmed before the session can be stopped or
% aborted. Enables/Disables MET Session Info's block controls ; the calling
% program must set MET remote's UserData.blockcntl field to contain a
% graphics object vector of those controls. Uses metguiqsig to queue MET
% signals in metgui's signal request buffer.
% 
% Written by Jackson Smith - Sept 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  % MET compile-time constants
  global  MC
  
  % If these haven't been set yet then set them
  if  isempty ( MC )  ,   MC = met ( 'const' , 1 ) ;  end
  
  
  %%% Constants %%%
  
  % MET signals
  MSIG = MC.SIG' ;
  MSIG = struct ( MSIG { : } ) ;
  
  % metremote directory
  GUIDIR = fileparts ( which ( 'metremote' ) ) ;
  
  % Title bar
  TITBAR = 'MET Remote' ;
  
  % Lock button baseline colour
  LCOLOFF = [ 0.4 , 0 , 0 ] ;
  LCOLON  = [ 1.0 , 0 , 0 ] ;
  
  % Button names
  BNAMES = { 'start' , 'lock' , 'stop' , 'abort' } ;
  
  % Button images
  BIMAGE = { 'start.png' , LCOLOFF , 'stop.png' , 'abort.png' } ;
  
  % Tooltips
  BTTIPS = { 'Run task' , 'Stop lock' , 'End trial & stop' , 'Abort now' };
  
  % Button styles
  BSTYLE = ...
    { 'togglebutton' , 'togglebutton' , 'togglebutton' , 'togglebutton' } ;
  
  % Button MET signal and cargo request , zero place holders signal to
  % metgui not to queue button signal
  METSIG = { [] , [] , MSIG.mwait , MSIG.mwait } ;
  METCRG = { [] , [] , MC.MWAIT.FINISH , MC.MWAIT.ABORT } ;
  
  % Starting state: Enable
  ENABLE = { 'on' , 'off' , 'off' , 'off' } ;
  
  % Button width , in centimetres
  BONWID = 1 ;
  
  % Border width , in centimetres
  BRDWID = 0.25 ;
  
  % Number of controls
  N = numel ( BNAMES ) ;
  
  % Width Height of figure
  FIGWH = [ N * ( BRDWID + BONWID ) + BRDWID  ,  2 * BRDWID + BONWID ] ;
  
  
  %%% Generate figure %%%
  
  % Initialise UserData send MET signals via metgui
  s = struct ( 'blockcntl' , gobjects ( 0 ) , 'drawnew_flg' , false ) ;
  
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Units' , 'centimeters' , 'Visible' , 'off' , 'UserData' , s , ...
    'Resize' , 'off' , 'DockControls' , 'off' ) ;
  
  % Set width and height
  h.Position ( 3 : 4 ) = FIGWH ;
  
  
  %%% Generate buttons %%%
  
  % Loop all
  for  i = 1 : N
    
    % Name
    n = BNAMES { i } ;
    
    % X position
    xpos = i * BRDWID  +  ( i - 1 ) * BONWID ;
    
    % UserData struct
    if  ~isempty (  METSIG{ i } )
      us = struct ( 'sig' , METSIG{ i } , 'crg' , METCRG{ i } ) ;
    else
      us = [] ;
    end
    
    % Create
    gd.( n ) = uicontrol ( 'Parent' , h , 'Style' , BSTYLE{ i } , ...
      'Units' , 'centimeters' , ...
      'Position' , [ xpos , BRDWID , BONWID , BONWID ] , ...
      'UserData' , us , 'BackgroundColor' , 'none' , ...
      'Enable' , ENABLE{ i } , 'TooltipString' , BTTIPS{ i } ) ;
    
    % Set image or colour
    if  ischar ( BIMAGE { i } )
      
      % Open button image
      I = imread ( fullfile ( GUIDIR , BIMAGE { i } ) ) ;
      
      % Resize image
      gd.( n ).Units = 'pixels' ;
      I = imresize ( I , gd.( n ).Position ( 3 : 4 ) ) ;
      
      % Set image to button
      gd.( n ).CData = I ;
      
    else
      
      gd.( n ).BackgroundColor = BIMAGE { i } ;
      
    end
    
  end % buttons
  
  
  %%% Set lock button %%%
  
  % Resize lock button
  gd.lock.Position( 1 : 2 ) = gd.lock.Position( 1 : 2 )  +  0.25 * BONWID ;
  gd.lock.Position( 3 : 4 ) = gd.lock.Position( 3 : 4 )  /  2 ;
  
  % Add colour values to user data
  gd.lock.UserData.coloff = LCOLOFF ;
  gd.lock.UserData.colon  = LCOLON  ;
  
  
  %%% Assign button behaviours %%%
  
  gd.start.Callback = { @start , gd.lock } ;
   gd.lock.Callback = { @lock , gd.stop , gd.abort } ;
   gd.stop.Callback = { @stop , gd.lock , [] } ;
  gd.abort.Callback = { @stop , gd.lock , gd.stop } ;
  
  
  %%% Store GUI descriptor %%%
  
  h.UserData.gd = gd ;
  
  
  %%% Return function handles %%%
  
  update = @( h , sd , bd , td , cbuf , tbuf ) ...
    mrupdate ( h , sd , bd , td , cbuf , tbuf , ...
               MSIG.mstop , MSIG.mwait , MC.MWAIT.ABORT , 0 , ENABLE ) ;
   reset = @( h , v )  mrreset ( h , v , 0 , ENABLE ) ;
 recover = @( h , sdir )  mrrecover ( h , sdir ) ;
   close = @mrclose ;
  
  
end % metremote


%%% Button callbacks %%%

function  start ( h , ~ , lock )
  
  % Disable start button and block controls
  h.Enable = 'off' ;
  set ( h.Parent.UserData.blockcntl , 'Enable' , 'off' )
  
  % Activate lock button
  lock.Enable = 'on' ;
  lock.Value = 1 ;
  lock.BackgroundColor = lock.UserData.colon ;
  
  % Raise drawnew flag, requesting drawnow to be executed
%   h.Parent.UserData.drawnew_flg = true ;
  
end % start button


function  lock ( h , ~ , stop , abort )
  
  % Get assigned values
  if  h.Value
    
    % Prevent use of stop and abort buttons
    e = 'off' ;
    
    % Light button           
    c = h.UserData.colon ;
    
  else
    
    % Allow use of stop and abort buttons
    e = 'on' ;
    
    % Dim button
    c = h.UserData.coloff ;
    
  end
  
  % Assign values
   stop.Enable = e ;
  abort.Enable = e ;
  h.BackgroundColor = c ;
  
  % Raise drawnew flag, requesting drawnow to be executed
%   h.Parent.UserData.drawnew_flg = true ;
  
end % lock button


function  stop ( h , ~ , lock , stpbtn )
  
  % Disable lock
  lock.Enable = 'off' ;
  
  % Disable stop button , if given
  if  ~isempty ( stpbtn )
    stpbtn.Enable = 'off' ;
  end
  
  % Disable self
  h.Enable = 'off' ;
  
  % Signal for metgui to send MET signal
  metguiqsig ( h.UserData.sig , h.UserData.crg )
  
  % Raise drawnew flag, requesting drawnow to be executed
%   h.Parent.UserData.drawnew_flg = true ;
  
end % stop and abort buttons


%%% metgui API %%%

function  drawnew = mrupdate ( h , ~ , ~ , ~ , cbuf , ~ , ...
                     mstop , mwait , cabort , v , E )
% 
% drawnew = update ( h , sd , bd , td , cbuf , tbuf )
% 
% mstop , mwait , cabort - Hidden internal arguments for passing MET signal
% values.
% 
% h - MET Remote figure handle , sd - MET session descriptor ,
% bd - block descriptor , td - trial descriptor , cbuf - current buffer ,
% tbuf - trial buffer
% 
% Returns scalar logical saying whether GUI appearance has changed,
% requiring drawnow to be executed.
% 
  
  % Initialise drawnew depending on state of flag
  drawnew = false ;
%   drawnew = h.UserData.drawnew_flg ;
%   
%   % Lower flag if it is raised
%   if  h.UserData.drawnew_flg
%     h.UserData.drawnew_flg = false ;
%   end
  
  % Return if no signals
  if  ~ cbuf.new_msig  ,  return  ,  end
  
  % Fetch GUI descriptor
  gd = h.UserData.gd ;
  
  % Reset MET Remote in one of the following cases: Abort button down and
  % mwait signal with cargo abort ; abort button up , stop button down ,
  % and mstop signal.
  if  ( gd.abort.Value  &&  ...
        any ( cbuf.msig.sig == mwait  &  cbuf.msig.crg == cabort ) ) ||...
      (~gd.abort.Value  &&  gd.stop.Value  &&  ...
        any ( cbuf.msig.sig == mstop ) )
    
    mrreset ( h , [] , v , E ) ;
    
    % Report change of appearance
    drawnew = true ;
    
  end
  
end % update


function  mrreset ( h , v , bval , E )
%
% In further developing MET GUI interface, reset ( h , v ) has come to
% accept a 2-element cell array in v to update session, block, or trial
% descriptors. This is now done for all MET GUIs, but is not relevant here.
% Therefore, if v is a cell array then quit immediately.
  
  if  iscell ( v ) , return , end

  % Object class string
  cstr = 'matlab.ui.control.UIControl' ;
  
  % Fetch GUI descriptor
  gd = h.UserData.gd ;
  
  % Get set of buttons as cell array
  u = struct2cell ( gd ) ;
  
  % Keep only the buttons
  i = cellfun ( @( c )  isa ( c , cstr ) , u ) ;
  u = u( i ) ;
  u = [ u{ : } ] ;
  
  % Reset each uicontrol with given Value and Enable
  for  i = 1 : numel ( u )
    
    u( i ).Value = bval ;
    u( i ).Enable = E{ i } ;
    
  end
  
  % Re-enable block controls
  set ( h.UserData.blockcntl , 'Enable' , 'on' )
  
end % mgreset


function  mrrecover ( ~ , ~ )
% 
% recover ( h , sdir ) normally saves recovery data in the current session
% directory at the end of each trial. But there is no recovery action for
% MET Remote , so this is an empty function.
% 
  
end % mrrecover


function  mrclose ( h )
  
  % Delete the figure , bypass close request callback
  delete ( h )
  
end % mgclose

