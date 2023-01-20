
function  metlegeye ( MC )
% 
% metlegeye ( MC )
% 
% Matlab Electrophysiology Toolbox legacy eye position plot. Works together
% with metlegctl to retrofit old go.m and taskcontroller.m control code for
% use with MET. Requires meteyeplot from metgui's set of user interfaces,
% found in met/m/mgui. This shows a real time display of the eye position
% on the screen, as well as the outline of hit boxes for any stimulus that
% is currently being shown.
% 
% Written by Jackson Smith - Dec 2016 - DPAG , University of Oxford
% 
  
  
  %%% Constants %%%
  
  % Location of mgui directory with plotting user interface
  PLTDIR = fileparts (  which ( 'metlegeye' )  ) ;
  PLTDIR = fullfile ( PLTDIR , 'legacy' ) ;
  
  % Required MET shared memory , must have read access
  METSHM = { 'stim' , 'eye' } ;
  
  % Shared memory error message
  SHMERR = [ 'metlegeye: Needs read access to shm: ''' , ...
    strjoin( METSHM , ''' , ''' ) , ''' , check .cmet file' ] ;
  
  
  %%% Environment check %%%
  
  % Look for meteyeplot
  if  ~ exist ( fullfile ( PLTDIR , 'meteyeplot_legacy.m' ) , 'file' )
    error ( 'MET:metlegeye:meteyeplot_legacy' , ...
      'metlegeye: Can''t find meteyeplot_legacy.m' )
  end
  
  % No access to any shm
  if  isempty ( MC.SHM )
    error ( 'MET:metlegeye:shm' , SHMERR )
  end
  
  % Verify read access on required shm
  for  i = 1 : numel ( METSHM )
    
    j = strcmp ( MC.SHM ( : , 1 ) , METSHM { i } ) ;
    
    if  all ( [ MC.SHM{ j , 2 } ]  ~=  'r' )
      error ( 'MET:metlegeye:shm' , SHMERR )
    end
    
  end % shm read access
  
  
  %%% Prepare eye plot %%%
  
  % Go to mgui directory
  cd ( PLTDIR )
  
  % Create an eye plot
  [ h , update , ~ , ~ , fclose ] = meteyeplot_legacy ;
  
  % Show eye plot
  h.Visible = 'on' ;
  
  % Clear memory
  clearvars -except  MC  h  update  fclose
  
  
  %%% Run controller %%%
  
  % Error message , empty means no error
  E = [] ;
  
  try
    
    metlegeye_run ( MC , h , update )
    
  catch  E
  end
  
  % Mandatory cleanup
  fclose ( h )
  
  % Rethrow error
  if  ~ isempty ( E )  ,  rethrow ( E ) ;  end
  
  
end % metlegeye


%%% Subroutines %%%

function  metlegeye_run ( MC , h , update )
  
  
  %%% Constants %%%
  
  % MET signal identifiers
  MSID = MC.SIG' ;  MSID = struct ( MSID { : } ) ;
  
  % Receive MET signals in blocking mode
  WAIT_FOR_MSIG = 1 ;
  
  % Wait indefinitely for next event
  WAIT_INDEF = [] ;
  
  % Index for each hit box vertex
  HBL = RectLeft   ;
  HBR = RectRight  ;
  HBT = RectTop    ;
  HBB = RectBottom ;
  
  % Plot's constants
  C = h.UserData ;
  
  
  %%% Event buffer %%%
  
  % Make a metgui-style current buffer that stores the latest MET signals
  % and shared memory
  F = { 'new_msig' , 'msig' , 'shm' , 'stim' , 'eye' , 'nsp' } ;
  F = [ F ; cell( size ( F ) ) ] ;
  cbuf = struct ( F { : } ) ;
  
  % Current buffer MET signals
  F = { 'n' , 'src' , 'sig' , 'crg' , 'tim' } ;
  F = [ F ; cell( size ( F ) ) ] ;
  cbuf.msig = struct ( F { : } ) ;
  
  % Empty graphics handle vector , so that the first call to delete will
  % not crash
  r = gobjects ( 0 ) ;
  
  
  %%% Complete MET initialisation %%%
  
  % Send mready signal , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Wait for synchronising ready signal
  [ ~ , ~ , sig ] = met ( 'recv' , WAIT_FOR_MSIG ) ;
  
  % Return if any mquit signal received
  if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
  
  
  %%% Event loop %%%
  
  while  true
    
    % Wait for next event
    [ ~ , cbuf.new_msig , cbuf.shm ] = met ( 'select' , WAIT_INDEF ) ;
    
    
    %-- New MET signals --%
    
    if  cbuf.new_msig
      
      % Get them
      [ cbuf.msig.n   , ...
        cbuf.msig.src , ...
        cbuf.msig.sig , ...
        cbuf.msig.crg , ...
        cbuf.msig.tim ] = met ( 'recv' ) ;
      
      % Check for mquit , terminate controller if received
      if  any ( cbuf.msig.sig  ==  MSID.mquit )  ,  return  ,  end
      
      % Look for mready triggers and send a reply
      mready = cbuf.msig.sig  ==  MSID.mready ;
      
      if any (  cbuf.msig.crg ( mready )  ==  MC.MREADY.TRIGGER  )
        met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
      end
      
      % Respond to mstop by erasing hit box rectangles
      if  any ( cbuf.msig.sig  ==  MSID.mstop )  ,  delete ( r )  ,  end
      
    end % new msig
    
    
    %-- Newly readable shared memory --%
    
    % Check each one
    for  i = 1 : size ( cbuf.shm , 1 )
      
      % Not readable , go to next
      if  cbuf.shm { i , 2 }  ~=  'r'  ,  continue  ,  end
      
      % Read shm
      F = cbuf.shm { i , 1 } ;
      cbuf.( F ) = met ( 'read' , F ) ;
      
      % If this is 'stim' then update the hit box rectangles in the screen
      % plot.
      if  ~ strcmp ( F , 'stim' )  ,  continue  ,  end
      
      % Delete any existing rectangles
      delete ( r )
      
      % Point to hit box matrix
      hb = cell2mat ( cbuf.stim{ 1 } ) ;
      
      % Mirror in the vertical direction
      hb( [ HBT , HBB ] , : ) = C.SCRPIX.HEIGHT - hb( [ HBT , HBB ] , : ) ;
      
      % Convert from pixels to degrees of visual field from centre of
      % screen
      hb( [ HBL , HBR ] , : ) = ...
        hb( [ HBL , HBR ] , : )  /  C.PXPDEG.WIDTH   -  C.SCHDEG.WIDTH  ;
      hb( [ HBT , HBB ] , : ) = ...
        hb( [ HBT , HBB ] , : )  /  C.PXPDEG.HEIGHT  -  C.SCHDEG.HEIGHT ;
      
      % Rectangle graphics handles
      r = gobjects ( 1 , size ( hb , 2 ) ) ;
      
      % For each hit box
      for  j = 1 : size ( hb , 2 )
        
        % Determine rectangle's position vector
        P = [ hb( [ HBL , HBB ] , j )' , ...
          hb( HBR , j ) - hb( HBL , j ) , ...
          hb( HBT , j ) - hb( HBB , j ) ] ;
        
        % Make rectangles
        r( j ) = rectangle ( 'Parent' , C.A.SCR , ...
          'Position' , P , 'FaceColor' , 'none' , ...
          'EdgeColor' , 'w' , 'LineWidth' , 1 ) ;
        
      end % rectangles
      
    end % shm
    
    
    %-- Update eye plot --%
    
    % If new signals or eye positions were received
    if  cbuf.new_msig  ||  any ( [ cbuf.shm{ : , 2 } ]  ==  'r' )
      
      update ( h , [] , [] , [] , cbuf , [] )
      
    end
    
    % Draw changes
    drawnow
    
  end % event loop
  
  
end % metlegeye_run

