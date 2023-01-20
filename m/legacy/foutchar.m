
function OUTCHAR = foutchar
% 
% OUTCHAR = foutchar
% 
% Returns struct array with a field for each possible outcome, and the
% expected character code.
% 
% Written by Jackson Smith - Nov 2015 - DPAG, University of Oxford
% 
  
  OUTCHAR.CORRECT = 'c' ;
  OUTCHAR.FAILED = 'f' ;
  OUTCHAR.IGNORED = 'i' ;
  OUTCHAR.BROKEN = 'b' ;
  OUTCHAR.ABORT = 'a' ;
  
end % foutchar
