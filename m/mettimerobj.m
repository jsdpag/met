
function  t = mettimerobj ( EID , ESTR )
%
% t = mettimerobj ( EID , ESTR )
% 
% Matlab Electrophysiology Toolbox timer object. Generates a Matlab timer
% object and sets it to periodically check the broadcast pipe and shared
% memory for new input to read ; the check is non-blocking. An error is
% thrown with error ID EID and message ESTR if mquit is received by the
% timer.
% 
% The purpose of this is to make sure that mquit signals are caught in a
% timely manner. And that any controller writing to shared memory is not
% blocked from doing so because one reader is busy. For example, if the
% controller is handling user input then it will clear MET IPC in the
% background.
% 
% Use the start, stop, and wait functions to control and synchronise timer
% behaviour.
%
% Written by Jackson Smith - Dec 2016 - DPAG , University of Oxford
%
  
  
  %%% Constants %%%
  
  % MET constants
  MC = met ( 'const' , 1 ) ;
  i = strcmp ( MC.SIG( : , 1 ) , 'mquit' ) ;
  MQUIT = MC.SIG{ i , 2 } ;
  
  % Timer delay , in seconds. Executes every 20ms i.e. at 50Hz
  PERIOD = 1 / 50 ;
  
  % Message identifier regular expression
  MIDREX = '^[a-zA-Z]{1}\w*(:\w+)*$' ;
  
  % Check EID input error message
  EIDERR = 'mettimerobj: EID not a valid message identifier' ;
  
  
  %%% Check input %%%
  
  % Two input arguments
  if  nargin ~= 2
    error ( 'MET:mettimerobj:nargin' , 'mettimerobj: 2 input args needed' )
  end
  
  % Both are strings , only ESTR can be empty
  if  ~isvector ( EID )  ||  ~ischar ( EID )
      error ( 'MET:mettimerobj:EID' , EIDERR )
      
  elseif  ~ ( isvector( ESTR ) || isempty( ESTR ) )  ||  ~ ischar ( ESTR )
      error ( 'MET:mettimerobj:ESTR' , ...
        'mettimerobj: ESTR must be a string' )
      
  end
  
  % Error message identifier has correct form
  if  isempty (  regexp ( EID , MIDREX , 'once' )  )
    
    error ( 'MET:mettimerobj:EID' , EIDERR )
       
  end
  
  
  %%% Make timer %%%
  
  t = timer ;
  
  % Set properties
  t.Name       = 'MET timer object' ;
  t.StartFcn   = { @timer_cb , MQUIT , EID , ESTR } ;
  t.StartDelay = PERIOD ;
  t.TimerFcn   = { @timer_cb , MQUIT , EID , ESTR } ;
  t.Period     = PERIOD ;
  t.ExecutionMode = 'fixedSpacing' ;
  
  
end % mettimerobj


%%% Callbacks %%%

function  timer_cb ( ~ , ~ , MQUIT , EID , ESTR )
  
  % Poll broadcast pipe and shared memory
  [ ~ , msig , shm ] = met ( 'select' , 0 ) ;
   
  % MET signals available
  if  msig
    
    [ ~ , ~ , sig ] = met ( 'recv' ) ;

    % mquit received
    if  any ( sig  ==  MQUIT )

      % Throw an error
      error ( EID , ESTR )

    end
  
  end % MET signals
  
  % No shared memory available or none ready to read from , end callback
  if  isempty ( shm )  ||  all ( [ shm{ : , 2 } ]  ~=  'r' )
    return
  end
  
  % Clear any shared memory that can be read
  for  i = 1 : size ( shm , 1 )
    
    % Can't read this memory , go to next
    if  shm { i , 2 }  ~=  'r'  ,  continue  ,  end
    
    % Read shared memory
    met ( 'read' , shm { i , 1 } ) ;
    
  end % clear shm
  
end % timer_cb

