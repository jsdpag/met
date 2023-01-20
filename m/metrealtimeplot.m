
function  metrealtimeplot ( MC_in , mgui , metcntlnam )
% 
% metrealtimeplot ( MC , mgui , metcntlnam )
% 
% Matlab Electrophysiology Toolbox real-time plotting. Shared memory
% presents a reader-writer problem. Will readers read fast enough to
% consume data as quickly as it's written? In MET, one slow reader will
% block all the rest from reading new data, because the writer cannot write
% new data until every reader has read the old data. Therefore, the metgui
% MET controller function could stall performance if it tried to support
% real-time plotting. This is because it must buffer reads from all shared
% memory in order to support non-realtime plots that are updated at the end
% of each trial. Therefore, if metgui was busy updating and presenting one
% or more real-time plots then it may not be ready to receive new data from
% shared memory when it is first ready.
% 
% metrealtimeplot is used to support a single real-time MET GUI to both
% minimise the load on the metgui controller, and to risk slowing the read
% rate on a single channel of shared memory instead of them all. It cannot
% be named directly in a .cmet file. Rather, a wrapper function must be
% used that checks if the required shared memory is available, and then
% passes in the name of the MET GUI definition mgui (string with .m suffix,
% just the file name , not the path). It will not maintain a
% trial-buffer, as does metgui. It will only provide the latest
% current-buffer, whenever it is available. The name of the calling wrapper
% function is provided in metcntlnam, for reporting.
% 
% This is to be used for such things as the real-time eye-position plot, or
% a real-time spike-raster that is aligned to trial events.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Global constants %%%
  
  global  MC  MCC
  
  % MET constants
  MC = MC_in ;
  
  % MET controller constants
  MCC = metctrlconst ( MC ) ;
  
  
  %%% Constants %%%
  
  % MET signal identifier name-to-value map
  MSID = MCC.MSID ;
  
  % Amount of time that must pass between calls to drawnow , in seconds.
  % At most a 60Hz frequency of execution. Better than 20Hz of native
  % drawnow limitrate.
  DRAWWAIT = 1  /  60 ;
  
  
  %%% Check input %%%
  
  % Check that directory exists
  if  ~ isvector ( mgui )  ||  ~ ischar ( mgui )  ||  ...
      isempty ( regexp(  mgui  ,  '\.m$'  ,  'once'  ) )
    
    error (  'MET:metrealtimeplot:mgui'  ,  [ 'metrealtimeplot: ' , ...
      'mgui must be a string ending in .m' ]  )
    
  elseif  ~ exist (  fullfile ( MCC.GUIDIR , mgui )  ,  'file'  )
    
    error (  'MET:metrealtimeplot:mgui'  ,  [ 'metrealtimeplot: ' , ...
      'file not found , %s' ]  ,  fullfile ( MCC.GUIDIR , mgui )  )
    
  % metcntlnam must be a string
  elseif  ~ isvector ( metcntlnam )  ||  ~ ischar ( metcntlnam )
    
    error (  'MET:metrealtimeplot:mgui'  ,  [ 'metrealtimeplot: ' , ...
      'metcntlnam must be a string' ]  )
    
  end
  
  
  %%% Initialisation %%%
  
  % Go to containing directory
  cd ( MCC.GUIDIR )
  
  % MET GUI figure position file name
  fnpos = [  mgui( 1 : end - 2 )  ,  '_figpos.mat'  ] ;
  
  % Get function handle
  f = str2func ( strrep(  mgui  ,  '.m'  ,  ''  ) ) ;
  
  % Report progress
  met (  'print'  ,  sprintf ( '%s loading real-time MET GUI: %s' , ...
    metcntlnam , mgui )  ,  'e'  )
  
  % Load MET GUI definition
  [ g.h , g.update , g.reset , g.recover , g.close ] = f( ) ;
  
  % Is there a figure position file?
  if  exist (  fnpos  ,  'file'  )
    
    % Yes , reload last used position
    load (  fnpos  ,  'figpos'  )
    
    % And apply to the MET GUI
    g.h.Position = figpos ; %#ok
    
  end % reload fig pos
  
  % Make sure that MET GUI is grabbable
  metcheckgui ( g.h ) ;
  
  % Prevent the figure from ever being closed , there is no way to bring it
  % back
  g.h.CloseRequestFcn = [] ;
  
  % And add a field saying whether the last update has been drawn yet
  g.drawnew = false ;
  
  % Current buffer , initialise number of returned signals to zero
  cbuf = MCC.DAT.cbuf ;
  cbuf.new_msig = 0 ;
  cbuf.msig.n = 0 ;
  
  % Session and trial descriptors
  sd = MCC.DAT.SD ;
  td = MCC.DAT.TD ;
  
  % drawnow timer variable , set this to the latest time measurement to
  % restart the timer
  tim_start = GetSecs ;
  
  % Clear unnecessary variables
  clearvars  mgui  f
  
  % Make MET GUI appear
  g.h.Visible = 'on' ;
  drawnow
  
  
  %%% Complete MET initialisation %%%
  
  % Send mready signal , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Report
  met (  'print'  ,  sprintf ( 'MET controller %d initialised: %s' , ...
    MC.CD , metcntlnam )  ,  'L'  )
  
  % Flush any outstanding messages to terminal
  met ( 'flush' )
  
  % Pause until MET server controller signals end of MET initialisation
  while  ~ cbuf.msig.n  ||  all ( cbuf.msig.sig  ~=  MSID.mwait )
    
    % Block on the next MET signal(s)
    [ cbuf.msig.n , ~ , cbuf.msig.sig ] = met ( 'recv' , 1 ) ;

    % Return if any mquit signal received
    if  any ( cbuf.msig.sig  ==  MSID.mquit )  ,  return  ,  end
  
  end % initialising mwait
  
  
  %%% Real-time plotting %%%
  
  % Event loop
  while  true
    
    % Timeout if next drawnow deadline is hit
    tim_dur = max ( [  DRAWWAIT  +  tim_start  -  GetSecs  ,  0  ] ) ;
    
    % Wait for next event , blocking. Note, a time measurement is taken
    % immediately before returning from met 'select'. Timeout 
    [ tim , cbuf.new_msig , cbuf.shm ] = met ( 'select' , tim_dur ) ;
    
    
    %-- Real time plot --%
    
    % Check timer , has minimum duration passed since last call to drawnow?
    if  DRAWWAIT  <=  tim - tim_start
      
      % Changes made to MET GUI
      if  g.drawnew
        
        % Do not draw the same change twice
        g.drawnew = false ;
        
        % Show changes to MET GUI
        drawnow
        
      end % draw changes
      
      % Measure current time to restart the timer
      tim_start = GetSecs ;
      
    end % check timer
    
    
    %-- Handle new signals --%
    
    if  cbuf.new_msig
      
      % Read new signals , non-blocking
      [ cbuf.msig.n   , ...
        cbuf.msig.src , ...
        cbuf.msig.sig , ...
        cbuf.msig.crg , ...
        cbuf.msig.tim ] = met ( 'recv' ) ;
      
      % Break event loop if mquit received
      if  any (  cbuf.msig.sig  ==  MSID.mquit  )  ,  break  ,  end
      
      % Look for mready trigger , a new trial is starting
      mrtrig = cbuf.msig.sig  ==  MSID.mready ;
      
      if  any ( cbuf.msig.crg( mrtrig )  ==  MC.MREADY.TRIGGER )
        
        % Read current session directory name and trial identifier
        [ sdir , tid ] = metsdpath ;
        
        % Session directory has changed
        if  ~ strcmp (  sd.session_dir  ,  sdir  )
          
          % Load new session descriptor
          sd = metdload ( MC , MCC , sdir , tid , 'sd' , ...
            'metrealtimeplot' ) ;
          
          % Tell real-time MET GUI that session has changed
          g.reset (  g.h  ,  { 'sd' , sd }  )
          
        end % new sess dir
        
        % Load trial descriptor
        td = metdload ( MC , MCC , sdir , tid , 'td' , ...
            'metrealtimeplot' ) ;
        
        % Tell real-time MET GUI that trial has changed
        g.reset (  g.h  ,  { 'td' , td }  )
        
        % Report that MET controller is ready for new trial
        met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
        
      end % new trial starting
      
    end % new signals
    
    
    %-- Read shared memory --%
    
    % New data is available
    if  ~ isempty ( cbuf.shm )
      
      % Load each available shared memory
      for  i = 1 : size ( cbuf.shm , 1 )
        
        % No read access , to next shm
        if  cbuf.shm{ i , 2 }  ~=  'r'  ,  continue  ,  end
        
        % Read new data from shared memory
        cbuf.( cbuf.shm{ i , 1 } ) = met ( 'read' , cbuf.shm{ i , 1 } ) ;
        
      end % shared mem
      
    end % new shared memory data
    
    
    %-- Update MET GUI --%
    
    % Neither block descriptor nor trial buffer provided (args 3 and 6)
    g.drawnew = ...
      g.update (  g.h  ,  sd  ,  []  ,  td  ,  cbuf  ,  []  )  ||  ...
      g.drawnew ;
    
    
  end % event loop
  
  
  %%% Clean up %%%
  
  % Save the MET GUI's figure position for next time
  figpos = g.h.Position ; %#ok
  save (  fnpos  ,  'figpos'  )
  
  % Have MET GUI release any special resources and destroy itself
  g.close ( g.h ) ;
  
  % It doesn't hurt to run this too , just in case
  delete ( g.h )
  
  
end % metrealtimeplot

