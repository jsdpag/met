
function  i = mets2i ( s , r , c , nochk )
% 
% i = mets2i ( s , r , c , nochk )
% 
% Matlab Electrophysiology Toolbox helper function. Returns a column vector
% i of linear indeces for a 2D array of size s = [ num rows , num cols ]. r
% and c are both vectors providing row and column indeces ; these are
% expanded into all corresponding linear indeces, as when a 2D array is
% directly indexed e.g. A( r , c ). This is unlike sub2ind, which requires
% a row and column index for each linear index. Input checking can be
% turned off with optional input nochk. If nochk is non-zero then checking
% is skipped ; default is zero.
% 
% Written by Jackson Smith - June 2017 - DPAG , University of Oxford
% 
  
  
  %%% Check input %%%
  
  % Is nochk provided?
  if  nargin  <  4
    
    % Default , perform check
    nochk = false ;
    
  end % nochk
  
  % Skip input arg check?
  if  ~ nochk
    
    % No , loop inputs
    for  A = { { s , 's' } , { r , 'r' } , { c , 'c' } } , a = A{ 1 } ;
      
      % Is input a real numeric vector of integers greater than zero ,
      % without NaN or Inf ?
      if  ~ isvector ( a{ 1 } )  ||  ~ isnumeric ( a{ 1 } )  ||  ...
            ~ isreal ( a{ 1 } )  ||  any (  a{ 1 } <= 0  |  ...
                isnan( a{ 1 } )  |  isinf( a{ 1 } )  )  ||  ...
                  any ( mod(  a{ 1 }  ,  1  ) )
        
        error (  'MET:mets2i:badarg'  ,  [ 'mets2i: %s must be a ' , ...
          'real numeric vector of integers greater than zero , ' , ...
          'without NaN or Inf' ]  ,  a{ 2 }  )
        
      end % Check input
      
      % Special checks
      switch  a{ 2 }
        
        % Size input argument must have two elements , only
        case  's'
          
          if  numel ( s )  ~=  2
            error (  'MET:mets2i:badarg'  ,  ...
              'mets2i: s must have 2 elements'  )
          else
            continue
          end
        
        % Check that index vectors do not exceed the number of rows ...
        case  'r'
          
          if  all ( r  <=  s( 1 ) )  ,  continue  ,  end
          
        % ... or columns
        case  'c'
          
          if  all ( c  <=  s( 2 ) )  ,  continue  ,  end
          
      end % row/column check
      
      % If we got here then the number of row or columns is exceeded in one
      % of the index vectors
      error (  'MET:mets2i:badarg'  ,  ...
        'mets2i: %s exceeds size given in s'  ,  a{ 2 }  )
      
    end % loop inputs
    
    
  end % skip check
  
  
  %%% Convert subscript to linear index %%%
  
  i = repmat (  r( : )  ,  1  , numel ( c )  )  +  ...
      repmat (  s( 1 )  *  ( c( : )' - 1 )  ,  numel ( r )  ,  1  )  ;
  
%   i = reshape (  repmat(  r( : )  ,  1  , numel ( c )  )  +  ...
%     repmat(  s( 1 )  *  ( c( : )' - 1 )  ,  numel ( r )  ,  1  )  ,  ...
%       s( 1 ) * s( 2 )  ,  1  ) ;
  
  
end % mets2i

