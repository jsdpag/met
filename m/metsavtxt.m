
function  metsavtxt ( f , s , p , func )
% 
% metsavtxt ( f , s , p , func )
% 
% Matlab Electrophysiology Toolbox save text file. Writes string s to file
% f using write permissions p. p may be any one of the character set aAwW
% ( see fopen for meanings , p should be 'w' in typical use ). func is the
% name of the calling function, which is used in error messages.
% 
% Written by Jackson Smith - Jan 2017 - DPAG , University of Oxford
% 
  
  
  %%% Check input %%%
  
  E = '' ;
  
  if  ~ isvector ( func )  ||  ~ ischar ( func )
    
    EID = 'MET:metsavtxt:func' ;
    E   = 'metsavtxt: input arg func must be a string' ;
    
  elseif  ~ isvector ( f )  ||  ~ ischar ( f )
    
    EID = sprintf ( 'MET:%s:f' , func ) ;
    E   = sprintf ( '%s: input arg f must be a string' , func ) ;
    
  elseif  ~ isvector ( s )  ||  ~ ischar ( s )
    
    EID = sprintf ( 'MET:%s:s' , func ) ;
    E   = sprintf ( '%s: input arg s must be a string' , func ) ;
    
  elseif  ~ isscalar ( p )  ||  ~ ischar ( p )  ||  all ( p ~= 'waWA' )
    
    EID = sprintf ( 'MET:%s:p' , func ) ;
    E   = sprintf ( '%s: input arg p must be one of chars wWaA' , func ) ;
    
  end
  
  % Error detected
  if  ~ isempty ( E )  ,  error ( EID , E ) , end
  
  
  %%% Write file %%%
  
  % Open file , discard old contents if it exists
  [ fid , M ] = fopen (  f  ,  p  ) ;

  if  fid  ==  -1
    EID = sprintf ( 'MET:%s:fopen' , func ) ;
    error ( EID , '%s: fopen , %s' , func , M )
  end

  % Write new contents to file
  if  ~ fprintf ( fid , '%s\n' , s )
    
    EID = sprintf ( 'MET:%s:fprintf' , func ) ;
    error ( EID , '%s: fprintf failed to write to %s' , func ,  f )
    
  end

  % Close file
  if  fclose ( fid )  ==  -1
    
    M = ferror ( fid ) ;
    EID = sprintf ( 'MET:%s:fclose' , func ) ;
    error ( EID , '%s: fclose , %s' , func , M )
    
  end
  
  
end % metsavtxt

