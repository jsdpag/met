
function  p = metreadcsv ( fname , parnam , par2num )
% 
% p = metreadcsv ( fname , parnam , par2num )
% 
% Reads a MET-formatted .csv file with path fname. MET .csv files are used
% to list a set of parameters, providing both their name and value. The
% names must be strings that form a valid struct field name, and the values
% must be scalar real numbers or strings. Optional input parnam can be a
% cell array of strings defining the set of parameter names that must be
% present ; to ignore, pass []. The first line of the file must contain the
% column headers param,value. Note that when values are mixed numbers and
% strings, then all values may be returned as strings. The optional input
% par2num contains a cell array of parameter names that will be converted
% to doubles if they are strings.
% 
% The use of .csv parameter files is to provide the user a quick way to
% change MET controller behaviour, rather than editing constants in
% the m-files. Examples include providing screen information in
% metscrnpar.csv or specifying which USB-DAQ device to use in
% metdaqout.csv.
% 
% .csv file format providing n parameters:
% 
%   param,value
%   <par name 1>,<val 1>
%   ...
%   <par name i>,<val i>
%   ...
%   <par name n>,<val n>
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Constants %%%
  
  % MET controller constants , contains MET .csv column headers.
  MCC = metctrlconst ;
  
  % Check if string
  chkstr = @( c )  isvector ( c )  &&  ischar ( c ) ;
  
  % Check values
  chkval = @( c )  ( isscalar( c ) && isreal( c ) && isfinite( c ) ) || ...
    ( isvector( c ) && ischar( c ) ) ;
  
  
  %%% Check input %%%
  
  % fname must be a string
  if  ~ chkstr ( fname )
    
    error ( 'MET:metreadcsv:fname' , 'metreadcsv: fname must be a string' )
    
  % File-type suffix is not .csv
  elseif  isempty ( regexp( fname , '\.csv$' , 'once' ) )
    
    error ( 'MET:metreadcsv:fname' , [ 'metreadcsv: ' , ...
      'fname does not end in .csv , %s' ] , fname )
    
  % File does not exist
  elseif  ~ exist ( fname , 'file' )
    
    error ( 'MET:metreadcsv:fname' , [ 'metreadcsv: ' , ...
      'Can''t find %s' ] , fname )
    
  end % fname check
  
  % Optional parnam not provided
  if  nargin  <  2
    
    parnam = [] ;
    
  % Empty given , skip other tests
  elseif  isempty ( parnam )
    
  % Must be cell array
  elseif  ~ iscell ( parnam )
    
    error ( 'MET:metreadcsv:parnam' , ...
      'metreadcsv: parnam must be a cell array' )
    
  % Must contain strings
  elseif  any ( ~ cellfun ( chkstr , parnam ) )
    
    error ( 'MET:metreadcsv:parnam' , ...
      'metreadcsv: parnam must contain only strings' )
    
  end % par2num check
  
  % Optional par2num not provided
  if  nargin  <  3
    
    par2num = [] ;
    
  % Must be cell array
  elseif  ~ iscell ( par2num )
    
    error ( 'MET:metreadcsv:par2num' , ...
      'metreadcsv: par2num must be a cell array' )
    
  % Must contain strings
  elseif  any ( ~ cellfun ( chkstr , par2num ) )
    
    error ( 'MET:metreadcsv:par2num' , ...
      'metreadcsv: par2num must contain only strings' )
    
  % Must be a subset of the specified parameters
  elseif  ~ isempty ( parnam )  &&  any ( ~ ismember ( par2num , parnam ) )
    
    error ( 'MET:metreadcsv:par2num' , ...
      'metreadcsv: par2num must be a subset of parnam' )
    
  end % par2num check
  
  
  %%% Get parameters and check for correctness %%%
  
  % First, read comma-separated table
  T = readtable ( fname ) ;
  
  % At least one parameter listed in table
  if  isempty ( T )
    
    error (  'MET:metreadcsv:empty'  ,  [ 'metreadcsv: ' , ...
      'File %s lists no parameters' ]  ,  ...
      fname  )
    
  % Check column headers
  elseif  numel ( MCC.CSVHDR )  ~=  size ( T , 2 )  ||  ...
      ~ all ( strcmp ( MCC.CSVHDR , T.Properties.VariableNames ) )
    
    error (  'MET:metreadcsv:colhdr'  ,  [ 'metreadcsv: ' , ...
      'File %s must have column headers: %s' ]  ,  ...
      fname  ,  strjoin ( MCC.CSVHDR , ',' )  )
    
  end % entries and headers
  
  % Make sure that .param and .value are cell arrays
  if  ~ iscell ( T.param )  ,  T.param = num2cell ( T.param ) ;  end
  if  ~ iscell ( T.value )  ,  T.value = num2cell ( T.value ) ;  end
  
  % Check that param column has only strings
  i = find ( ~ cellfun(  chkstr  ,  T.param  ) )  +  1 ;
  
  if  i
    
    error (  'MET:metreadcsv:badpar'  ,  [ 'metreadcsv: ' , ...
      'File %s has invalid parameter names at lines:%s' ]  ,  ...
      fname  ,  sprintf ( ' %d' , i )  )
    
  end % param strings
    
  % Check that all parameter names are valid
  i = find ( cellfun(  @isempty  ,  ...
    regexp( T.param , MCC.REX.VALNAM , 'once' )  ) ) ;
  
  if  i
    
    error (  'MET:metreadcsv:badpar'  ,  [ 'metreadcsv: ' , ...
      'File %s has invalid parameter names: %s' ]  ,  ...
      fname  ,  strjoin ( T.param( i ) , ' , ' )  )
    
  end % param names
  
  % Check that all specified parameters are present
  if  ~ isempty ( parnam )
    
    i = find (  ~ ismember ( parnam , T.param )  ) ;

    if  i

      error (  'MET:metreadcsv:badpar'  ,  [ 'metreadcsv: ' , ...
        'File %s is missing parameters names: %s' ]  ,  ...
        fname  ,  strjoin ( parnam( i ) , ' , ' )  )

    end
    
  end % specified params
  
  % Convert certain parameters to doubles, if requested
  if  ~ isempty ( par2num )
    
    % Find parameters
    i = find (  ismember ( T.param , par2num )  ) ;
    
    % And convert any value that is char
    T.value( i ) = cellfun (  @s2dchk  ,  T.value( i )  ,  ...
      'UniformOutput'  ,  false  ) ;
    
  end % string 2 double
  
  % Check that all values are valid numbers or strings
  i = find ( ~ cellfun ( chkval , T.value ) )  +  1 ;
  
  if  i
    
    error (  'MET:metreadcsv:parnam'  ,  [ 'metreadcsv: ' , ...
      'File %s has invalid values at lines:%s\n  ' , ...
      'Values must be scalar real numbers or strings' ]  ,  ...
      fname  ,  sprintf ( ' %d' , i )  )
    
  end % values
  
  
  %%% Prepare output %%%
  
  % Combine parameter names and values into one cell array
  C = [  T.param  ,  T.value  ]' ;
  
  % Return struct with a field named after each parameter and containing
  % its value
  p = struct (  C { : }  ) ;
  
  
end % metreadcsv


%%% Sub-routines %%%

% Turns string to double , unless value is numeric in which case a double
% is returned
function  v = s2dchk ( s )
  
  if  ischar ( s )
    
    v = str2double (  s  ) ;
    
  elseif  isnumeric ( s )
    
    if  ~ isa (  s  ,  'double'  )
      v = double (  s  ) ;
    else
      v = s ;
    end
    
  else
    
    error (  'MET:metreadcsv:s2dchk' , ...
      'metreadcsv: failed to read numeric values'  )
    
  end
  
end % s2dchk

