
function  metrteyes ( MC )
% 
% metrteyes ( MC )
% 
% Matlab Electrophysiology Toolbox controller function. Uses
% metrealtimeplot and MET GUI definition meteyeplot to generate a real-time
% display of the current eye positions relative to the hit regions of
% visual stimuli on screen.
% 
% NOTE: Requires read access to 'stim' and 'eye' shared memory. Make sure
% that this is provided in the .cmet file. However, if metscrnpar.csv
% parameter touch is 1 rather than 0, then eye shared memory need not be
% available, as mouse positions will be available.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Constants %%%
  
  % MET GUI definition
  MGUI = 'meteyeplot.m' ;
  
  % MET screen parameters
  p = metscrnpar ;
  
  % Required shared memory , open for reading
  SHMMEM = { 'stim' ; 'eye' } ;
  
  
  %%% Look for shared memory %%%
  
  % Shared memory with read access
  i = [ MC.SHM{ : , 2 } ]'  ==  'r' ;
  
  % Too many or too few , needs to be exact. Or read access granted to the
  % wrong shared memory.
  if  sum ( i )  ~=  numel ( SHMMEM )  ||  ...
      ~ all ( ismember(  SHMMEM  ,  MC.SHM( i , 1 )  ) )
    
    error (  'MET:metrteyes:numshm'  ,  [ 'metrteyes: requires ' , ...
      'shm reading access to only: %s\n  Check touch property in ' , ...
      'metscrnpar.csv' ]  ,  strjoin ( SHMMEM , ' , ' )  )
    
  end % check shared memory access
  
  
  %%% Real-time plot %%%
  
  % Clear unnecessary variables
  clearvars  -except  MC MGUI
  
  % Run plot
  metrealtimeplot ( MC , MGUI , 'metrteyes' )
  
  
end % metrteyes

