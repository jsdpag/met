
function  c = metcell ( varargin )
% 
% metcell ( N ) is an N-by-N cell array of empty matrices.
% metcell ( M , N ) or metcell ( [ M , N ] ) is an M-by-N cell array of
%   empty matrices.
% metcell ( M , N , P , ... ) or metcell( [ M , N , P , ... ]) is an
%   M-by-N-by-P-by-... cell array of empty matrices.
% metcell ( SIZE ( A ) ) is a cell array the same size as A containing all
%   empty matrices.
% 
% As you can see, this works exactly the same way as a call to cell ( ).
% Indeed, it uses just that. However, it actually guarantees that each
% element of the cell will contain an empty matrix. cell ( ) uses some kind
% of trickery to make it seem like it's full of empties. But since that's
% wasteful of memory, it apparently keeps track of which elements have been
% assigned to, and probalby maintains NULL pointers elsewhere. This makes
% it impossible to know in a mex program whether a cell hasn't been assigne
% to, or whether Matlab has run out of heap space, because a NULL is
% returned in either case.
% 
% So, by using this function that ambiguity can be resolved. A valid
% pointer to an array is always returned because each element of the new
% cell array has been assigned to.
% 
% Written by Jackson Smith - Oct 2016 - DPAG , University of Oxford
%
  
  % Generate cell array
  c = cell ( varargin { : } ) ;
  
  % Explicitly assign empties
  c( : ) = { [] } ;
  
end % metcell
