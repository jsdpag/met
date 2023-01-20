
function  d = metdload ( MC , MCC , sdir , tid , v , cnam , fieldcopy )
% 
% d = metdload ( MC , MCC , sdir , tid , v , cnam , fieldcopy )
% 
% Matlab Electrophysiology Toolbox. Helper function can be used by a MET
% controller function to load a descriptor of some kind, specified in
% string v i.e. variable name. This can be 'sd' or 'td' to request the
% current session or trial descriptor. Further requires the MET constants
% MC, MET controller constants MCC, the current session directory string
% sdir, the current trial identifier string tid, and the name string cnam
% of the calling controller. fieldcopy is an optional scalar logical input.
% If true then the old descriptor is retrieved from file then copied to an
% empty descriptor, field by field ; if false, then the loaded descriptor
% is returned directly (default). The former behaviour helps with backwards
% compatability.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Check input %%%
  
  % fieldcopy not given , use default
  if  nargin  <  7  ,  fieldcopy = false ;  end
  
  % At this point, we will assume that MC and MCC are correct
  
  % Check that sdir names an existing directory
  if  ~ isvector ( sdir )  ||  ~ ischar ( sdir )  ||  ...
      ~ exist ( sdir , 'dir' )
    
    error ( 'MET:metdload:sdir' , [ 'metdload: sdir does not name ' , ...
      'an existing directory' ] )
  
  % tid is a string
  elseif  ~ isvector ( tid )  ||  ~ ischar ( tid )
    
    error ( 'MET:metdload:tid' , 'metdload: tid is not a string' )
    
  % v is a string namind 'sd' or 'td'
  elseif  ~ isvector ( v )  ||  ~ ischar ( v )  ||  ...
      ~ any ( strcmp( v , MCC.DAT.VNAM ) )  ||  strcmp ( v , 'bd' )
    
    error ( 'MET:metdload:v' , 'metdload: v must be ''sd'' or ''td''' )
    
  % cnam is a string
  elseif  ~ isvector ( cnam )  ||  ~ ischar ( cnam )
    
    error ( 'MET:metdload:cnam' , 'metdload: cnam is not a string' )
    
  % fieldcopy is scalar logical
  elseif  ~ isscalar ( fieldcopy )  ||  ~ islogical ( fieldcopy )
      
    error ( 'MET:metdload:fieldcopy' , ...
      'metdload: fieldcopy is not scalar logical' )
    
  end % check input
  
  % Convert tid to number
  i = str2double ( tid ) ;
  
  % Must be integer of 1 or more, not NaN or Inf
  if  isnan ( i )  ||  isinf ( i )  ||  i < 1  ||  mod ( i , 1 )
    
    error (  'MET:metdload:tid'  ,  [ 'metdload: tid must be an ' , ...
      'integer of 1 or more' ]  )
    
  end % check tid number
  
  
  %%% Load descriptor %%%
  
  % Get file name based on the type of descriptor
  switch  v
    
    % Session descriptor file name
    case  'sd'  ,  f = fullfile (  sdir  ,  MCC.SDFNAM  ) ;
  
    % Trial descriptor file name
    case  'td'  ,  f = fullfile (  sdir  ,  MC.SESS.TRIAL  ,  tid  ,  ...
        sprintf ( MCC.TDNAMS , tid )  ) ;
      
  end
  
  % Check that file exists
  if  ~ exist ( f , 'file' )
    
    error (  [ 'MET:' , cnam , ':metdload' ]  ,  [ cnam , ...
      'metdload: could not find %s' ]  ,  f  )
    
  end
  
  % Check that descriptor is in the named file
  w = whos ( v , '-file' , f ) ;
  
  if  isempty ( w )
    
    error (  [ 'MET:' , cnam , ':metdload' ]  ,  [ cnam , ...
      'metdload: descriptor ''%s'' not found in %s' ]  ,  v  ,  f  )
    
  end
  
  % Read descriptor
  r = load (  f  ,  v  ) ;
  
  % Check that descriptor was loaded
  if  ~ isfield (  r  ,  v  )

    error (  [ 'MET:' , cnam , ':metdload' ]  ,  [ cnam , ...
      'metdload: failed to load descriptor ''%s'' from %s' ]  ,  v  ,  f  )

  end % sd exists
  
  % Field-by-field copy of old descriptor
  if  fieldcopy
    
    % Get empty copy of descriptor
    d = MCC.DAT.(  upper( v )  ) ;
    
    % Get fields in old descriptor
    F = fieldnames(  r.( v )  )' ;
    
    % Copy each field
    for  F = F  ,  f = F { 1 } ;  d.( f ) = r.( v ).( f ) ;  end
    
  else
    
    % Return descriptor directly
    d = r.( v ) ;
    
  end
  
  
end % metdload

