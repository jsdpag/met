
function  meterror (  varargin  )
%
% meterror (  format string  ,  arg1  ,  arg2  ,  ...  )
% 
% Matlab Electrophysiology Toolbox helper function. This is specifically to
% help MET GUIs to bring down the calling MET controller when there is an
% unresolvable problem. Use this instead of Matlab's error( ) function,
% which will print an error message with stack trace and then terminate the
% callback function. Instead, meterror( ) prints a message and stack trace,
% then exits Matlab. metserver will then detect an unexpected MET child
% process termination and begin the shutdown process. It takes all the same
% input arguments as fprintf( ) or sprintf( ) to format an error message.
% 
% Written by Jackson Smith - Sept 2017 - DPAG , University of Oxford
%
  
  % An error message has been requested
  E = [] ;
  
  if  ~ isempty (  varargin  )
    
    % Try-catch printing the error , or else the function will abort before
    % we reach the exit call
    try
      
      met (  'print'  ,  sprintf (  varargin{ : }  )  ,  'E'  )
      
    catch  E
    end
    
  end % Error message
  
  % Generic error message
  if  isempty (  varargin  )  ||  ~ isempty (  E  )
    met (  'print'  ,  'Error encountered'  ,  'E'  )
  end
  
  % Print stack trace
  dbstack
  
  % Bring 'er down
  exit
  
end % meterror