
function  metrtspks ( MC )
% 
% metrtspks ( MC )
% 
% Matlab Electrophysiology Toolbox controller function. Uses
% metrealtimeplot and MET GUI definition metspkplot to generate a real-time
% display of recent spike events alongside trial events.
% 
% NOTE: Requires read access to 'nsp' shared memory. Make sure that this is
% provided in the .cmet file.
% 
% Written by Jackson Smith - March 2017 - DPAG , University of Oxford
% 
  
  
  %%% Constants %%%
  
  % MET GUI definition
  MGUI = 'metspkplot.m' ;
  
  
  %%% Look for shared memory %%%
  
  % Shared memory with read access
  i = [ MC.SHM{ : , 2 } ]  ==  'r' ;
  
  % Too many or too few , needs to be exact. Or read access granted to the
  % wrong shared memory.
  if  ~ any ( strcmp(  'nsp'  ,  MC.SHM( i , 1 )  ) )
    
    error (  'MET:metrtspks:rnsp'  ,  [ 'metrtspks: requires ' , ...
      'shm reading access to ''nsp''\n  Check .cmet file' ]  )
    
  end % check shared memory access
  
  
  %%% Real-time plot %%%
  
  % Clear unnecessary variables
  clearvars  -except  MC MGUI
  
  % Run plot
  metrealtimeplot ( MC , MGUI , 'metrtspks' )
  
  
end % metrtspks

