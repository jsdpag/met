
function  type = metstimdeftype ( MC , MCC , sd )
% 
% type = metstimdeftype ( MC , MCC , sd )
% 
% Matlab Electrophysiology Toolbox. This helper function can be run by a
% MET controller that needs to know the type of all MET stimulus
% definitions being used in the current session. Using MET constants MC and
% the current session descriptor sd, type is returned as a scalar struct
% where each field is named after a stimulus definition and contains its
% type string.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  % There must be three inputs
  if  nargin  ~=  3
    error (  'MET:mettarget:nargs'  ,  [ 'mettarget: three input ' , ...
      'arguments required' ]  )
  end
  
  % Present working directory
  wd = pwd ;
  
  % Stimulus definition directory for current session
  d = fullfile(  sd.session_dir  ,  MC.SESS.STIM  ) ;
  
  % Change into the current session's stimulus definition directory. This
  % way, we force Matlab to run those m-files first, before any other with
  % the same name.
  cd ( d )
  
  % The set of function names are the same as the field names from the set
  % of variable parameter declarations in sd.var
  F = fieldnames (  sd.vpar  ) ;
  
  % Get the MET stimulus type of each definition
  for  i = 1 : numel ( F )
    
    % Function name
    f = F { i } ;
    
    % Get handle to stimulus definition
    h = str2func (  f  ) ;
    
    % Return type string and store in field named after stim def
    type.( f ) = h ( sd.rfdef ) ;
    
    % Must return a string
    if  ~ isvector ( type.( f ) )  ||  ~ ischar ( type.( f ) )
      
      error (  'MET:mettarget:stimdef'  ,  [ 'mettarget: stimulus ' , ...
      'definition fails to return type string , %s' ]  ,  ...
      fullfile ( d , [ f , '.m' ] )  )
      
    % Must be a recognised type of MET stimulus definition
    elseif  ~ any ( strcmp(  MCC.SDEF.types  ,  type.( f )  ) )
      
      error (  'MET:mettarget:stimdef'  ,  [ 'mettarget: stimulus ' , ...
      'definition returns invalid type string ''%s'' , %s' ]  ,  ...
      type.( f )  ,  fullfile ( d , [ f , '.m' ] )  )
      
    end % stim type error
    
  end % stim type
  
  % Restore original working directory
  cd ( wd )
  
end % metstimdeftype

