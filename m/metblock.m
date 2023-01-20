
function  [ bd , sd ] = metblock ( bd , sd , outcome )
% 
% [ bd , sd ] = metblock ( bd , sd , outcome )
% 
% Matlab Electrophysiology Toolbox block manager. Used to track each block
% of trials from generation to depletion and replacement. bd is a block
% descriptor, which carries all information about the current block. If
% this is an empty matrix i.e. [] then a new block descriptor is created
% and no further checks are done. Alternatively, if bd is a block
% descriptor with an empty deck, then a fresh descriptor is made and
% outcome-dependent variables are set appropriately.
% 
% The type of a new block is determined by the current session descriptor
% sd. The next block definition listed in sd.block is used to create a new
% block descriptor, starting again at the top of the list when all
% definitions have been run. The session descriptor's block information is
% updated as well.
% 
% If bd is not empty, then it must be a block descriptor for the current
% block of trials. outcome is a vector that buffers the trial outcome code
% for all trials that have been presented, where outcome ( end ) is the
% result of the last trial ; outcome codes must be those defined by the MET
% constants function met ( 'const' ).
% 
% How the block descriptor is updated will depend on the outcome of the
% previous trial. Correct and failed trials will cause the head of the
% block's trial deck to be discarded. If a trial is broken or aborted then
% the head of the deck is randomly reshuffled to a new position in the deck
% unless its maximum number of attempts has been reached, in which case it
% is discarded. Ignored trials do not affect the deck. If a block
% descriptor's deck is emptied upon discarding its head, then a new block
% descriptor is automatically created using the next listed block
% definition.
% 
% NOTE: The form of block and session descriptors is set by the
%   initialisers defined in metctrlconst, the MET controller constants
%   function.
% 
% NOTE: Looks for global constants MC and MCC naming the MET constants and
%   MET controller constants. If not found, then they are initialised ; the
%   MET constants with compile-time constants only.
% 
% NOTE: If there are any task variables that depend on trial outcome then
%   they are initialised to the value following 0 consecutive trials of
%   that type. The next trial in the deck is updated upon reaching the
%   head, but will be reset to the default value if reshuffled.
% 
% Written by Jackson Smith - Dec 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  % MET constants , MET controller constants
  global  MC  MCC
  
  % If these haven't been set yet then set them. Note , only compile-time
  % MET constants asked for if not already declared.
  if  isempty (  MC )  ,   MC = met ( 'const' , 1 ) ;  end
  if  isempty ( MCC )  ,  MCC = metctrlconst    ;  end
  
  
  %%% Constants %%%
  
  % Burnout , the maximum number of times we may resample a distribution
  % when trying to generate dependent variables' values
  BRNOUT = 1e3 ;
  
  % MET trial outcome code constants
  MOUT = MC.OUT' ;  MOUT = struct (  MOUT { : }  ) ;
  
  
  %%% Generate a new block descriptor %%%
  
  % Empty input argument signals that a new block descriptor is needed
  if  isempty ( bd )
    
    % Generate the new block descriptor and update the session descriptor
    [ bd , sd ] = newblock ( sd , BRNOUT ) ;
    
    % Return updated descriptors
    return
    
  end % new block descriptor
  
  
  %%% Udpate current descriptor %%%
  
  % Last trial's outcome code , set to a default value that will not equate
  % to any known outcome if no outcome is given
  if  isempty (  outcome  )
    outc = 0 ;
  else
    outc = outcome ( end ) ;
  end
  
  % Maximum number of attempts per trial
  amax = sd.block.( bd.name ).attempts ;
  
  % Index for each outcome-dependent task variable ...
  OUTVAR = find (  strcmp(  { bd.var.depend }  ,  'outcome'  )   ) ;
  
  % Ignored trial requires no action , terminate function
  if  outc  ==  MOUT.ignored  ,  return  ,  end
  
  % If broken or aborted then increment number of attempts
  if  any (  outc  ==  [ MOUT.broken , MOUT.aborted ]  )
    
    bd.attempts( 1 ) = bd.attempts( 1 )  +  1 ;
    
  end
  
  % Deck is empty , make a new block descriptor
  if  isempty ( bd.deck )
    
    [ bd , sd ] = newblock ( sd , BRNOUT ) ;
    
  % Otherwise, look for reasons to discard head of the deck. Trial was
  % correct, failed, or had maximum number of attempts.
  elseif  any (  outc  ==  [ MOUT.correct , MOUT.failed ]  )  ||  ...
      bd.attempts( 1 )  ==  amax
    
    % Discard head of deck
    bd.task = bd.task ( 2 : end ) ;
    bd.deck = bd.deck ( 2 : end , : ) ;
    bd.attempts = bd.attempts ( 2 : end ) ;
    
    % However, the deck might now be empty. Make a new block descriptor at
    % need.
    if  isempty ( bd.deck )
      [ bd , sd ] = newblock ( sd , BRNOUT ) ;
    end
    
  % The last possibility is that we need a reshuffle
  else
    
    % Reset any outcome-dependent variable values to default
    for  i  =  OUTVAR
      
      % If NaN then not used in current task , go to next variable
      if  isnan (  bd.deck( 1 , i )  )  ,  continue  ,  end
      
      % Reset
      bd.deck( 1 , i ) = bd.var( i ).value( 1 ) ;
      
    end % outcome-dependent var
    
    % Randomly select a trial to swap with , must get a value from 2 to
    % number of trials in deck
    i = ceil (  rand  *  ( size( bd.deck , 1 ) - 1 )  )  +  1 ;
    
    % Swap
    bd.task( [ 1 , i ] ) = bd.task ( [ i , 1 ] ) ;
    bd.deck( [ 1 , i ] , : ) = bd.deck ( [ i , 1 ] , : ) ;
    bd.attempts( [ 1 , i ] ) = bd.attempts ( [ i , 1 ] ) ;
    
  end
  
  % No outcome given
  if  isempty (  outcome  )  ,  return  ,  end
  
  % Find out how many trials have had the last outcome in a unbroken row ,
  % up to now.
  outn = numel ( outcome )  -  find ( outc  ~=  outcome , 1 , 'last' ) ;
  
  % Empty matrix? Then all outc == outcome.
  if  isempty ( outn )  ,  outn = numel ( outcome ) ;  end
  
  % Add one to get corresponding index of value set
  outn = outn  +  1 ;
  
  % Set the value for each variable that's dependent on this outcome
  for  i  =  OUTVAR
    
    % Variable is dependent on another outcome , skip
    if  MOUT.( bd.var( i ).dist )  ~=  outc  ,  continue  ,  end
    
    % Lookup value
    bd.deck( 1 , i ) = bd.var( i ).value(  min(  [ outn , end ]  )  ) ;
    
  end % outcome-dependent var
  
end % metblock


%%% Subroutines %%%

% Creates a new block descriptor based on the current state of the given
% session descriptor , and updates the session descriptor.
function  [ bd , sd ] = newblock ( sd , BRNOUT )
  

  %-- Global MET controller constants --%
  
  global  MCC
  
  
  %-- Preparation --%
  
  % Copy block descriptor initialiser
  bd = MCC.DAT.BD ;
  
  % Check the current block id
  if  isempty (  sd.block_id  )
    
    % If empty then set to 1
    bd.block_id = 1 ;
    
  else
    
    % Otherwise increment by 1
    bd.block_id = sd.block_id  +  1 ;
    
  end
  
  % Update the current session descriptor's block_id
  sd.block_id = bd.block_id ;
  
  % Get the list of block definition names
  C = fieldnames ( sd.block ) ;
  
  % Determine the index of the next block definition to use
  i = mod (  bd.block_id - 1  ,  numel ( C )  )  +  1 ;
  
  % Get that block definition
  bd.name = C { i } ;
  bdef = sd.block.(  bd.name  ) ;
  
  % Get set of task variable names
  bd.varnam = bdef.var ;
  
  % Get the subset of session variable definitions used in this block
  C = fieldnames ( sd.var ) ;
  C = setdiff ( C , bdef.var ) ;
  var = rmfield (  sd.var  ,  C  ) ;
  var = orderfields ( var , bd.varnam ) ;
  
  % Combine into a single struct array , variable definitions all have the
  % same fields
  var = struct2cell ( var ) ;
  var = [ var{ : } ] ;
  bd.var = var ;
  
  % Locate independent variables
  I = strcmp (  { var.depend }  ,  'none'  ) ;
  
  % Locate scheduled variables
  S = strcmp (  { var.dist }  ,  'sched' ) ;
  
  % Locate variables dependent on trial outcome
  O = strcmp (  { var.depend }  ,  'outcome'  ) ;
  
  % Get the number of scheduled values for each variable
  n = zeros ( size ( var ) ) ;
  for  i  =  find ( S )  ,  n( i ) = numel ( var( i ).value ) ;  end
  
  % Get unique task names , and backward mapping to each session variable
  [ T , ~ , TM ] = unique (  { var.task }  ) ;
  TM = reshape (  TM  ,  1  ,  numel ( TM )  ) ;
  
  % Number of tasks in use
  tn = numel ( T ) ;
  
  % Initialise builder cell arrays , each element will contain one deck of
  % trials for each task in use
  deck = cell ( tn , 1 ) ;
  
  % Also prepare a task cell vector
  task = cell ( 1 , tn ) ;
  
  
  %-- Build new deck of trials --%
  
  % Build a deck for each task in use
  for  d = 1 : tn
    
    % Find variables that use this task
    t = TM  ==  d ;
    
    % Of these , find independent scheduled variable indeces
    v = find ( t  &  I  &  S ) ;
    
    % Take their product , this is 1 if there are no scheduled variables.
    % Multiply by number of block repetitions and it becomes the total
    % number of trials in this sub-deck.
    N = prod (  n ( v )  ) ;
    
    % Allocate sub-deck
    deck{ d } = nan (  N  ,  numel ( var )  ) ;
    
    % And also a temporary index array , for values of scheduled
    % independent task variables.
    J = zeros ( size(  deck{ d }  ) ) ;
    
    % Copy in scheduled values , we need every possible combination. Start
    % by looping each scheduled variable and initialising repetition
    % counters. The counters are for making indexing variables that place
    % copies of each scheduled value in unique combination with all others
    R = [ N , 1 ] ;
    
    for  i  =  v
      
      % Adjust number of vertical reps
      R( 1 ) = R ( 1 )  /  n ( i ) ;
      
      % Generate index variable
      j = repmat ( 1 : n ( i ) , R ) ;
      
      % Copy values
      deck{ d }( : , i ) = var( i ).value( j( : ) ) ;
      
      % Store indeces
      J( : , i ) = j ( : ) ;
      
      % Adjust number of horizontal reps
      R( 2 ) = R ( 2 )  *  n ( i ) ;
      
    end % sched vars
    
    % Repeat by number of block repetitions and it becomes the total
    % number of trials in this sub-deck.
    deck{ d } = repmat (  deck{ d }  ,  bdef.reps  ,  1  ) ;
    N = size ( deck{ d } , 1 ) ;
    
    % Also repeat index array
    J = repmat (  J  ,  bdef.reps  ,  1  ) ;
    
    % Allocate task cell array vector of strings
    task{ d } = repmat (  T ( d )  ,  1  ,  N  ) ;
    
    % Find sampled independent variables
    v = find ( t  &  I  &  ~ S ) ;
    
    % Now generate random values for them
    for  i  =  v
      
      % Get sampling function handle
      fh = MCC.DIST.IND.( var( i ).dist ) ;
      
      % And get distribution arguments in a cell array
      C = num2cell ( var( i ).value ) ;
      
      % Sample distribution
      deck{ d }( : , i ) = fh (  N  ,  C { : }  ) ;
      
    end % sampled ind var
    
    % Find variables that are dependent on other variables
    v = find ( t  &  ~ I  &  ~ O ) ;
    
    % And fill them according to the value of the other variable
    for  i  =  v
      
      % Find the independent variable's index
      j = strcmp (  var( i ).depend  ,  bdef.var  ) ;
      
      % Scheduled dependent variable
      if  strcmp ( var( i ).dist , 'sched' )
        
        % Get the location of each scheduled value of the independent
        % variable
%        [ ~ , k ] = ismember (  deck{ d }( : , j )  ,  var( j ).value  ) ;
        
        % ismember can't handle repeated values , hence the index array J
        
        % Map dependent scheduled values to the same trials
        deck{ d }( : , i ) = var( i ).value(  J ( : , j )  ) ;
        
        % Done , go to next variable
        continue
        
      end % sched
      
      % The same value is used
      if  strcmp ( var( i ).dist , 'same' )
        
        % Then we simply copy values over from the independent variable
        deck{ d }( : , i ) = deck{ d }( : , j ) ;
        
        % And carry on to the next variable
        continue
        
      end % same
      
      % Otherwise a different value is required how we handle the situation
      % depends on whether the independent variable is scheduled or not
      if  S ( j )
        
        % Convert independent variable's values to a cell array
        C = num2cell (  deck{ d }( : , j )  ) ;
        
        % Form a function handle for cellfun
        fh = @( c )  sdiff ( c , var( j ).value ) ;
        
        % Independent variable is scheduled , remove its value from the
        % total set of scheduled values and randomly return one value from
        % the remaining set
        deck{ d }( : , i ) = cellfun (  fh  ,  C  ) ;
        
      else
        
        % Burnout counter
        bout = 0 ;
        
        % Similarity vector , the ith value of k is true if the dependent
        % and independent variables' values are equal
        k = true ( N , 1 ) ;
        
        % Get sampling function handle
        fh = MCC.DIST.IND.( var( j ).dist ) ;

        % And get distribution arguments in a cell array
        C = num2cell ( var( j ).value ) ;
        
        % Independent variable is sampled from a distribution , resample
        % from the same distribution until a set of different values is
        % found
        while  bout < BRNOUT  &&  any ( k )
          
          % Resample value that are still equal
          deck{ d }( k , i ) = fh (  sum ( k )  ,  C { : }  ) ;
          
          % Look for equal values
          k( k ) = deck{ d }( k , i )  ==  deck{ d }( k , j ) ;
          
          % Count attempts
          bout = bout  +  1 ;
          
        end % resampling
        
        % Burnout error
        if  bout  ==  BRNOUT
          
          error ( 'MET:metblock:burnout' , [ 'metblock: Attempted %d ' ,...
            'times to sample different values for dependent var %s' ] , ...
            BRNOUT , bdef.var { i } )
          
        end
        
      end % scheduled
      
    end % dependent variables
    
    % Variables dependent on outcome
    v = find (  t  &  ~ I  &  O  ) ;
    
    % Set them to default value assuming that zero trials of the indicated
    % type have occurred
    for  i  =  v  ,  deck{ d }( : , i ) = var( i ).value( 1 ) ;  end
    
  end % tasks
  
  % Concatenate block into one matrix
  deck = cell2mat ( deck ) ;
  task = [  task{ : }  ]' ;
  
  % Number of trials in deck
  N = size ( deck , 1 ) ;
  
  % And randomly permute trial records
  i = randperm ( N ) ;
  deck = deck ( i , : ) ;
  task = task ( i ) ;
  
  
  %-- Finish setting new block descriptor --%
  
  % Deck of trials
  bd.deck = deck ;
  
  % Trial tasks
  bd.task = task ;
  
  % Initialise number of attempts to zero
  bd.attempts = zeros (  size ( bd.task )  ) ;
  
  
end % newblock


% cellfun function , removes value x from set S then randomly selects y
% from the remainder for return
function  y = sdiff ( x , S )
  
  % Remove x from S
  S = S ( x  ~=  S ) ;
  
  % Randomly sample one value from the remainder
  i = ceil (  rand  *  numel ( S )  ) ;
  
  % Return sampled value
  y = S ( i ) ;
  
end % sdiff

