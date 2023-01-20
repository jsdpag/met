% 
% qintersec ( a , b ) - Quick and greedy intersection. Returns the first
% value in a that exists in b. 0 is returned when a and b do not
% intersect. Both inputs must be type double Matlab matrices.
% 
% NOTE: Relies on the blockdef verification to guarantee that a and b are
% both sorted ascending. That is, qintersec will assume sorted data, and
% will almost certainly fail if that is not the case.
% 
% See qintersec.c for code.
% 
% Written by Jackson Smith - Nov 2015 - DPAG, University of Oxford
%