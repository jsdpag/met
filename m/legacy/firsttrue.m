% 
% firsttrue( x ) - Returns the numeric index of the first non-zero
% element. 0 is returned when all elements contain zero or x is an empty
% matrix. x must be a logical matrix.
% 
% Why use this instead of 'find'? Because find returns an empty matrix
% when no index is found, instead of 0. This is a disaster when trying to
% assign the output of find to a pre-allocated matrix.
% 
% See firsttrue.c for code.
% 
% Written by Jackson Smith - Oct 2015 - DPAG, University of Oxford
%