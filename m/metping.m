
function  metping ( MC , call )
% 
% metping ( MC , call )
% 
% Matlab Electrophysiology Toolbox child controller function. This is
% intended to be run using wrapper functions metping1 and metping2. It is
% the common code for generating diagnostic information that estimates the
% latency of MET signal transmission from one child MET controller to
% another. If call is non-zero, then this is taken to be the calling
% function that generates diagnostic MET signals. But if call is zero then
% this will be the responding function that replies to each diagnostic
% signal.
% 
% So as not to interfere with other controllers, the calling ping
% function will generate a series of mnull MET signals. Each signal will
% have a cargo that is 1 plus the value of the cargo from the last signal,
% starting with 1 in the very first signal on each trial. The responding
% function will generate one mnull signal for each that is received,
% carrying the same cargo. If call is non-zero then the function will
% buffer the time and cargo of each mnull MET signal in two groups,
% those sent by the calling function and those sent by the responding
% function. The time is measured from each trial's mstart signal, in
% microseconds. Buffered signals are saved in the current trial directory
% as metping_<i>.mat files, where <i> is replaced by the trial identifier.
% 
% Saved files contain a truncated copy of the mnull buffer, consisting of
% two variables, crg and tim for the cargo and time values.  Each is a
% N by 2 array. N is at least 0 and at most MCC.DAT.MAXCRG, depending on
% the length of the trial. Column 1 is for the calling function, and column
% 2 is for the responding function. N is the largest number of signals
% buffered locally or from the responding controller, zero padding is used
% when signals are unavailable. crg and tim are unsigned integers, 16 and
% 32-bit respectively.
% 
% Written by Jackson Smith - April 2017 - DPAG , University of Oxford
% 
  
  
  %%% Constants %%%
  
  % MET controller constants
  MCC = metctrlconst ( MC ) ;
  
  % MET signal identifer map
  MSID = MCC.MSID ;
  
  % Controller name string , for metwaitfortrial
  NAMSTR = sprintf (  'metping_call%d'  ,  call  ) ;
  
  % Signal for 'send' and 'recv' to block 
  WAIT_FOR_SIG = 1 ;
  
  % The blocking flag used by recv in the event loop depends on whether
  % this is the calling or responding function. The responder blocks, the
  % caller uses non-blocking
  if  call
    BLKFLG = 0 ;
  else
    BLKFLG = WAIT_FOR_SIG ;
  end
  
  % MET signal generation rate
  MSIGHZ = 100 ;
  
  % Minimum duration between mnull signals , in seconds
  MSDURS = 1  /  MSIGHZ ;
  
  % Numeric type of cargo
  CRGTYP = 'uint16' ;
  
  % Regular expression of saved file , put string version of trial
  % identifer in %s
  REXSAV = 'metping_%s.mat' ;
  
  % Constants that are discarded by responding function
  DISCOC = { 'MSIGHZ' , 'MSDURS' , 'CRGTYP' , 'REXSAV' } ;
  
  
  %%% Initialise controller %%%
  
  % The calling function requires MET signal buffers
  if  call
    
    % Build as a struct. crg mnull cargo values, tim are MET signal times,
    % and n are the number of mnull signals buffered from each metping
    % controller
    b.crg = zeros (  MCC.DAT.MAXCRG  ,  2  ,  CRGTYP  ) ;
    b.tim = zeros (  MCC.DAT.MAXCRG  ,  2  ) ;
    b.n = [ 0 , 0 ] ;
    
  else
  
    % Responding function doesn't need certain constants
    clear (  DISCOC { : }  )
  
  end % signal buffers
  
  % Clear discarded constants list
  clear  DISCOC
  
  
  %%% Complete MET initialisation %%%
  
  % Send mready signal , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Report
  met (  'print'  ,  sprintf ( [ 'MET controller %d initialised: ' , ...
    NAMSTR ] , MC.CD )  ,  'e'  )
  
  % Wait for mwait signal that finalises initialisation phase
  n = 0 ;
  sig = [] ;
  while  ~ n  ||  all ( sig  ~=  MSID.mwait )
    
    % Block on the next MET signal(s)
    [ n , ~ , sig ] = met ( 'recv' , WAIT_FOR_SIG ) ;

    % Return if any mquit signal received
    if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
  
  end % initialising mwait
  
  
  %%% Trial loop %%%
  
  % Wait for the next trial
  while  metwaitfortrial ( MC , NAMSTR )
    
    
    %%% Initialise trial %%%
    
    % Calling function requires initialisation that responding function
    % does not
    if  call
    
      
      %-- Get trial parameters --%
    
      % Read current session directory name and trial identifier
      [ sdir , tid ] = metsdpath ;

      % Current trial directory
      tdir = fullfile ( sdir , MC.SESS.TRIAL , tid ) ;

      % Navigate to trial directory
      cd ( tdir )
      
      
      %-- Reset the mnull buffer and counter --%
      
      % Zero mnull signals buffered from either metping controller
      b.n( : ) = 0 ;
      
      % Cargo counter reset to zero
      crgval = 0 ;
      

    end % trial dir
    
    
    %-- Synchronise start of trial with MET --%
    
    % Empty the signal identifier logical index vector , i will be used as
    % such hereafter
    i = false ( 0 ) ;
    
    % Send mready reply to MET server controller , blocking write
    met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] , WAIT_FOR_SIG ) ;
    
    % Wait for start of trial MET signal mstart
    while  ~ any ( i )
      
      % Block on the broadcast pipe
      [ ~ , ~ , sig , ~ , tim ] = met (  'recv'  ,  WAIT_FOR_SIG  ) ;
      
      % Immediately terminate the function if a quit signal received
      if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
      
      % Look for start signal
      i = sig  ==  MSID.mstart ;
      
    end % mstart
    
    % If this is the calling ping function then get start time as reference
    % time for timing mnull signals. Set this as the new time measurement
    % so that we give a full timout to met select. Get mstart time for
    % buffered signal times. Difference between reftim and newtim is
    % tdelta.
    if  call
      mstart = tim ( i ) ;
      reftim = mstart ;
      tdelta = 0 ;
    end
    
    
    %%% Event loop %%%
    
    % Run until mstop is received
    while  true
      
      
      %-- Generate mnull signals --%
      
      % Calling ping function
      if  call
        
        % Determine time remaining until the next mnull signal is generated
        tout = max ( [  0  ,  MSDURS  -  tdelta  ] ) ;
        
        % Wait for the next MET signal or mnull timeout
        newtim = met ( 'select' , tout ) ;
        
        % Find duration from reference to new time measurements
        tdelta = newtim  -  reftim ;
        
        % Time to send a new mnull signal , and no cargo overflow
        if  MSDURS  <=  tdelta  &&  crgval  <  MCC.DAT.MAXCRG
          
          % Increase cargo value
          crgval = crgval  +  1 ;
          
          % Send new mnull signal , met send takes time measurement for MET
          % signal , non-blocking by default
          if  ~ met ( 'send' , MSID.mnull , crgval , [] )
            
            error (  'MET:metping_call:send'  ,  ...
            'metping - caller: failed to send mnull MET signal'  )
            
          end
          
          % Update reference time
          reftim = newtim ;
          
        end % new mnull
      
      end % Calling ping
      
      
      %-- Read incoming MET signals --%
      
      [ n , src , sig , crg , tim ] = met ( 'recv' , BLKFLG ) ;

      % No new MET signals
      if  ~ n
        
        % No other action possible , interate event loop
        continue
      
      % mquit kills the controller
      elseif  any ( sig  ==  MSID.mquit )

        return

      % mstop kills the event loop
      elseif  any ( sig  ==  MSID.mstop )

        break

      end % stop or quit
      
      
      %-- Handle mnull signals --%
      
      % Look for mnull signals
      mnull = sig  ==  MSID.mnull ;
      
      % Find MET signals from this MET controller
      cntl = src  ==  MC.CD ;
      
      % Calling function
      if  call
        
        % Buffer mnull signals for the calling function ( j == 1 ) and the
        % responding function ( j == 2 )
        for  j = 1 : 2
          
          % Buffer is full , check next buffer or break loop
          if  b.n ( j )  ==  MCC.DAT.MAXCRG  ,  continue  ,  end
          
          % Locate mnull signals from ...
          switch  j
            
            % Local calling function
            case  1  ,  i = mnull  &    cntl ;
              
            % Responding function
            case  2  ,  i = mnull  &  ~ cntl ;
              
          end % locate mnull
          
          % Count them
          n = sum ( i ) ;
          
          % No mnull signals from specified controller
          if  ~ n
            
            continue
            
          % We will overflow the buffer
          elseif  MCC.DAT.MAXCRG  <  b.n ( j ) + n
          
            % Take only what we can store
            n = MCC.DAT.MAXCRG  -  b.n ( j ) ;
            
            % Find elements of i that are true , return linear index
            k = find ( i ) ;
            
            % Switch off logical indeces of mnull signals that will be
            % discarded
            i (  k( n + 1 : end )  ) = 0 ;
            
          end % discard overflow
          
          % Index vector for buffer spots that will be filled
          k = b.n ( j ) + 1 : b.n( j ) + n ;
          
          % Buffer the MET signal cargos and times
          b.crg( k , j ) = crg ( i ) ;
          b.tim( k , j ) = tim ( i )  -  mstart ;
          
          % Update number of filled buffer elements
          b.n( j ) = b.n ( j )  +  n ;
          
        end % buffer loop
        
      % Responding function
      else
        
        % Find all mnull from another MET controller
        i = mnull  &  ~ cntl ;
        
        % No such mnull signals , wait for new MET signals
        if  ~ any (  i  )  ,  continue  ,  end
        
        % Prepare signals and cargos
        crg = crg ( i ) ;
        sig = MSID.mnull  *  ones ( size(  crg  ) ) ;
        
        % Send a responding mnull for each one , using the same cargo , let
        % met send take the time measurement for all signals
        if  ~ met ( 'send' , sig , crg , [] )
            
          error (  'MET:metping_resp:send'  ,  ...
          'metping - responder: failed to send mnull MET signal'  )

        end
        
      end % handle mnull signals
      
    end % event loop
    
    
    %-- Save buffered mnull signals --%
    
    % Only the calling function does this
    if  call  ,  savedat ( REXSAV , tdir , tid , b )  ,  end
    
    
  end % trial loop
  
  
end % metping


%%% Subroutines %%%

% Save buffered mnull signals
function  savedat ( REXSAV , tdir , tid , b )
  
  % Data file name
  f = fullfile (  tdir  ,  sprintf( REXSAV , tid )  ) ;
  
  % Maximum number of buffered signals
  n = max (  b.n  ) ;
  
  % Truncate buffers. crg is already uint16. Convert times to microseconds
  % and then to uint32
  crg = b.crg ( 1 : n , : ) ;
  tim = uint32 ( 1e6  *  b.tim ( 1 : n , : ) ) ;
  
  % Find buffer with fewer than n buffered signals , if it exists
  i = b.n  <  n ;
  
  % Make index vector of spots that need zero padding
  j = b.n( i ) + 1 : n ;
  
  % Zero pad missing signals
  crg ( j , i ) = 0 ; %#ok
  tim ( j , i ) = 0 ; %#ok
  
  % Save data
  save ( f , 'crg' , 'tim' )
  
end % savedat

