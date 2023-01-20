
function  metguiqsig ( sig , crg )
% 
% metguiqsig ( sig , crg )
% 
% Matlab Electrophysiology Toolbox metgui queue MET signals in request
% buffer. metgui maintains a global buffer called metguisig. Special MET
% GUIs will have access to it and can make signal requests by writing to
% it. metguisig is a struct with fields .n, .sig, and .crg containing the
% number of buffered signals, signal identifiers, and signal cargos.
% .sig( i ) and .crg( i ) are used to request the ith MET signal. One last
% field is AWMSIG, the number of MET signals in an atomic write to the
% request pipe ; buffer resizing will add this many spaces when it is full.
% Double vectors sig and crg must contain valid MET signal identifiers and
% cargos to be buffered in metguisig.
% 
% It is expected that metgui will have already initialised global variable
% metguisig. If not, the function silently returns.
% 
% Written by Jackson Smith - Jan 2017 - DPAG , University of Oxford
% 
  
  
  %%% Global variable %%%
  
  % metgui's MET signal request buffer
  global  metguisig
  
  % It has not been initialised by metgui , silently return
  if  isempty ( metguisig )
    clearvars  -global  metguisig
    return
  end
  
  
  %%% Basic input check %%%
  
  % Compare size of input arguments
  nsig = numel ( sig ) ;
  
  if  nsig  ~=  numel ( crg )
    error ( 'MET:metguiqsig:imbalance' , [ 'metguiqsig: ' , ...
      'Different number of signal identifiers and cargos given' ] )
  end
  
  
  %%% Buffer requested MET signal %%%
  
  % Current number of positions in buffer
  n = numel ( metguisig.sig ) ;
  
  % Resize at need
  if  n  <  metguisig.n + nsig
    
    % Determine number of blocks to add to buffer , round up
    n = ( nsig + metguisig.n - n )  /  metguisig.AWMSIG ;
    n = ceil ( n ) ;
    
    % Add space
    metguisig.sig = [  metguisig.sig  ;
                       zeros( n * metguisig.AWMSIG , 1 )  ] ;
    metguisig.crg = [  metguisig.crg  ;
                       zeros( n * metguisig.AWMSIG , 1 )  ] ;
    
  end % resize
  
  % Store new signals
  i = metguisig.n + 1 : metguisig.n + nsig ;
  metguisig.n = i ( end ) ;
  metguisig.sig( i ) = sig ;
  metguisig.crg( i ) = crg ;
  
  
end % metguiqsig

