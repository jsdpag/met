
function  [ C , F ] = metgetfields ( S , fname )
% 
% C = metgetfields ( S , fname )
% [ C , F ] = metgetfields ( S , fname )
% 
% Returns a cell array where each element contains the contents of
% sub-field fname from structs nested in struct S. F contains the field
% names of S.
%
% Thus all fields of S must be structs with the same set of field names.
%
% If S is empty or any sub-struct lacks the name field then { [] } is
% returned in C, and [] is returned in F ;
% 
% The mapping of input to output is C{ i } = S.( F{ i } ).( fname )
% 
% Written by Jackson Smith - Sept 2016 - DPAG , University of Oxford
% 
  
  % Empty input
  if  isempty ( S )
    C = { [] } ;
    F = [ ] ;
    return
  end
  
  % Input check
  if  ~ isstruct ( S )
    error ( 'MET:metgetfields:input' , 'metgetfields: S must be a struct' )
  elseif  ~ ischar ( fname )  ||  ~ isvector ( fname )
    error ( 'MET:metgetfields:input' , ...
      'metgetfields: fname must be a string' )
  end
  
  % Optional output
  if  1 < nargout
    
    % Return field names of top-level struct
    F = fieldnames ( S )' ;
    
  end
  
  % Turn sub-structs into one struct array
  S = struct2cell ( S ) ;
  S = [ S{ : } ] ;
  
  % Assign output
  try
    
    C = { S.( fname ) } ;
    
  catch
    
    % Couldn't read requested field , return empty
    C = { [] } ;
    F = [ ] ;
    
  end
  
end % metgetfields

