
function  [ h , update , reset , recover , close ] = metraster
% 
% [ h , update , reset , recover , close ] = metraster
% 
% Displays run-time raster plot of incoming cbmex trialdata. Expects that
% new data in the .nsp current buffer will be the same as written out by
% metcbmex.
% 
% Written by Jackson Smith - Oct 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  % MET compile-time constants
  global  MC  MCC
  
  % If these haven't been set yet then set them
  if  isempty ( MC  )  ,   MC  = met ( 'const' , 1 ) ;  end
  if  isempty ( MCC )  ,   MCC = metctrlconst        ;  end
  
  
  %%% Figure constants %%%
  
  % Make a convenient signal ID lookup table
  MSID = MC.SIG' ;
  MSID = struct ( MSID { : } ) ;
  
  % Title of figure
  TITBAR = 'MET Raster' ;
  
  % X label
  XLABEL = 'Time (sec)' ;
  
  % Size in cm
  FIGSIZ = [ 14 , 7 ] ;
  
  
  %%% Internal data %%%
  
  % Figure needs to keep a time zero. If ever encountered in NSP data, then
  % it is set to that.
  s.time_0 = 0 ;
  s.a = [] ;
  s.MSID = MSID ;
  
  
  %%% Generate figure %%%
  
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Units' , 'centimeters' , 'Visible' , 'off' , 'UserData' , s , ...
    'DockControls' , 'off' ) ;
  
  % Set width and height
  h.Position ( 3 : 4 ) = FIGSIZ ;
  
  % Generate an axes
  h.UserData.a = axes ( 'Parent' , h , 'Color' , 'none' , ...
    'TickDir' , 'out' , 'LineWidth' , 1 , 'XColor' , 'w' , ...
    'YColor' , 'w' , 'YTick' , [] , ...
    'Position' , [ 0.05 , 0.175 , 0.9 , 0.75 ] , 'YDir' , 'reverse' ) ;
  
  % Label
  xlabel ( h.UserData.a , XLABEL )
  
  
  %%% Return function handles %%%
  
  update = @( h , ~ , ~ , ~ , cbuf , ~ )  updatef ( h , cbuf ) ;
   reset = @( h , ~ )  resetf ( h ) ;
 recover = @( ~ , ~ )  recoverf ;
   close = @closef ;
  
  
end % metraster


%%% Figure functions %%%

function  drawnew = updatef ( h , cbuf )
  

  % Global constants
  global  MC  MCC
  
  % User Data
  u = h.UserData ;
  
  % Initialise no change
  drawnew = false ;
  
  % New signals?
  if  cbuf.new_msig
    
    % Point to them
    msig = cbuf.msig ;
    
    % Got mready trigger signal
    if  any ( msig.sig == u.MSID.mready  &  msig.crg == MC.MREADY.TRIGGER )
      
      % Clear figure
      cla ( u.a )
      
      % Report change
      drawnew = false ;
      
    end
    
  end % MET signals via MET server
  
  
  % No new write to shared memory
  if  isempty ( cbuf.shm )  ,  return  ,  end
  
  % Shared memory names and actions
  snm =   cbuf.shm( : , 1 ) ;
  sac = [ cbuf.shm{ : , 2 } ]' ;
  
  % New nsp data?
  if  ~ any ( strcmp ( snm , 'nsp' )  &  sac == 'r' )  ,  return  ,  end
  
  % Report change
  drawnew = false ;
  
  % Point to nsp data
  nsp = cbuf.nsp{ 1 } ;
  
  % First, look for signal events
  din = strcmp ( nsp.label , 'digin' ) ;
  
  % Get signal id's and times as recorded by NSP , IDs will be in the
  % lower-order bits
    i = nsp.data { din , 2 }  <=  MCC.DAT.MAXSIG ;
  sig = nsp.data { din , 2 } ( i ) ;
  tim = nsp.data { din , 1 } ( i ) ;
  
  % Any mstart events? Use this for time zero
  i =  find ( sig == u.MSID.mstart , 1 , 'last' )  ;
  if  i
    u.time_0 = tim ( i ) ;
    h.UserData = u ;
  end
  
  % Zero signal times
  tim = tim - u.time_0 ;
  
  % Prepare to gather spike time stamps , find spike front-end channels ,
  % and make data gathering cell array
  I = ~ cellfun( @( c )  isempty ( c ) , strfind( nsp.label , 'chan' ) ) ;
  NCHAN = sum ( I ) ;
  C = cell ( NCHAN , 2 ) ;
  
  % Loop channels and concatenate time stamps
  for  i = 1 : size ( nsp.data , 1 )
    
    % Not spike channel , next
    if  ~ I ( i )  ,  continue  ,  end
    
    % Gather together all spikes
    C { i , 1 } = cell2mat ( nsp.data ( i , : )' ) ;
    
    % Then assign channel number to each spike
    C { i , 2 } = ones ( size ( C { i , 1 } ) )  *  i ;
    
  end % gather all spikes
  
  % Pack all spikes into one array
  C = cell2mat ( C ) ;
  
  % If there is data
  if  ~ isempty ( C )
  
    % Zero spike times
    C ( : , 1 ) = C ( : , 1 ) - u.time_0 ;

    % And plot them
    line ( C ( : , 1 ) , C ( : , 2 ) , 'Parent' , u.a , ...
      'Linestyle' , 'none' , 'Marker' , '.' , 'MarkerEdgeColor' , 'w' , ...
      'MarkerSize' , 3 )
  
  end % plot spikes
  
  % Y lim
  Y = [ -1 , NCHAN + 1 ] ;
  ylim ( u.a , Y )
  
  % Overlay signal
  for  i = 1 : numel ( sig )
    
    % Line
    line ( tim ( [ i , i ] ) , Y , 'Parent' , u.a , ...
    'Color' , [ 0.8 , 0 , 0 ] )
    
    % Signal name
    n = MC.SIG { sig( i ) + 1 , 1 } ;
    
    % Text
    text ( tim ( i ) , Y ( 1 ) , n , 'Parent' , u.a , ...
      'Color' , [ 0.8 , 0 , 0 ] , 'HorizontalAlignment' , 'center' , ...
      'VerticalAlignment' , 'bottom' )
    
  end % signals
  
  
end % updatef


function  resetf ( h )
  
  % Clear figure
  cla ( h.UserData.a )
  
end % resetf


function  recoverf
  
  % No action
  
end % recoverf


function  closef ( h )
  
  % Delete the figure , bypass close request callback
  delete ( h )
  
end % closef

