
function new = metwaitfortrial ( MC , cnam , tout )
% 
% new = metwaitfortrial ( MC , cnam , tout )
% 
% Matlab Electrophysiology Toolbox. Helper function can be used by a MET
% controller function to wait for the next trial. It will ignore all MET
% signals except for the next mready trigger or mquit signal, returning
% true or false in each case. Requires MET constants MC and string cnam
% giving the name of the calling controller function. tout is an optional
% argument. It gives a timeout in seconds, as a positive scalar real
% double. If no mstart or mquit signal is received before the timout has
% passed then drawnow is executed and the timer starts again. If tout is
% zero then drawnow is never executed, this is default.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Check input %%%
  
  % MC is a scalar struct
  if  ~ isscalar ( MC )  ||  ~ isstruct ( MC )
    
    error (  'MET:metwaitfortrial:MC'  ,  ...
    'metwaitfortrial: MC must be a scalar struct'  )
    
  % cnam not a string
  elseif  ~ isvector ( cnam )  ||  ~ ischar ( cnam )
    
    error (  'MET:metwaitfortrial:cnam'  ,  ...
    'metwaitfortrial: cnam must be a string'  )
    
  % tout is not provided
  elseif  nargin  <  3
    
    % Default to zero
    tout = 0 ;
    
  % tout is provided but is not a scalar real double
  elseif  ~ isscalar ( tout )  ||  ~ isa ( tout , 'double' )  ||  ...
      ~ isreal ( tout )  ||  tout  <  0
    
    error (  'MET:metwaitfortrial:tout'  ,  ...
    'metwaitfortrial: tout must be a positive scalar real double'  )
    
  end
  
  
  %%% Constants %%%
  
  % MET signal identifiers for mready ...
  i = strcmp ( MC.SIG( : , 1 ) , 'mready' ) ;
  MREADY = MC.SIG{ i , 2 } ;
  
  % ... and mquit
  i = strcmp ( MC.SIG( : , 1 ) , 'mquit' ) ;
  MQUIT = MC.SIG{ i , 2 } ;
  
  % Value tells met 'revv' not to block on incoming MET signals
  DONT_WAIT_FOR_MSIG = 0 ;
  
  % Value tells met 'recv' to block on incoming MET signals
  WAIT_FOR_MSIG = 1 ;
  
  
  %%% Wait for signals %%%
  
  % Initialise sig and crg to empty
  sig = [] ;  crg = [] ;
  
  % Values for the new-MET-signal flag and blocking-mode flag
  if  tout
    
    % Timeout given , never block on met 'recv' when checking MET signals
    blkflg = DONT_WAIT_FOR_MSIG ;
    
    % Take initial time measurement, to compare against met 'select' return
    % time
    timold = GetSecs ;
    
  else
    
    % No timeout , always execute met 'recv' and block on MET signals
    msig = true ;
    blkflg = WAIT_FOR_MSIG ;
    
  end
  
  % Number of signals received , use this to detect failures
  n = 1 ;
  
  % Event loop
  while  n
    
    % Timeout given , wait for new MET signals and run timer
    if  tout  ,  [ tim , msig ] = met (  'select'  ,  tout  ) ;  end
    
    % Read new MET signals
    if  msig  ,  [ n , ~ , sig , crg ] = met ( 'recv' , blkflg ) ;  end
    
    % mquit received
    if  any ( sig  ==  MQUIT )
      
      % Break the trial loop
      new = false ;
      return
      
    end % mquit
    
    % Look for mready
    i =  sig  ==  MREADY ;
    
    % mready trigger received
    if  any ( crg ( i )  ==  MC.MREADY.TRIGGER )
      
      % Run drawnow one last time if a timeout given
      if  tout  ,  drawnow  ,  end
      
      % Run new trial
      new = true ;
      return
      
    end % mready trigger
    
    % Timer ran out
    if  tout  &&  tout  <=  tim - timold
      
      % Update figures
      drawnow
      
      % Save new time measurement
      timold = tim ;
      
    end % timer
    
    % Empty sig and crg if they have contents
    if  ~ isempty ( sig )  ,  sig = [] ;  crg = [] ;  end
    
  end % event loop
  
  
  % We should never get here , if we did then something has gone terribly
  % wrong
  error (  [ 'MET:' , cnam , ':metwaitfortrial' ]  ,  [ cnam , ...
    ':metwaitfortrial: met ''recv'' failed to block on broadcast pipe' ]  )
  
  
end % metwaitfortrial

