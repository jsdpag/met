
function  [ lnkind , hitregion , logic , ptblnk ] = ...
  metptblink ( sd , tid , shm )
% 
% [ lnkind , hitregion , logic , ptblnk ] = metptblink ( sd , tid ,  shm )
% [ lnkind , hitregion , logic , ptblnk ] = metptblink ( sd ,  td ,  ... )
% [ lnkind , hitregion , logic , ptblnk ] = metptblink ( sd , ... , cbuf )
% qflag = metptblink ( sd , tid , shm )
% 
% Matlab Electrophysiology Toolbox. This helper function should be run by
% any controller that needs the set of MET ptb-type stimulus definition hit
% regions that are provided during the trial initialisation phase, between
% receiving an mready trigger and an mstart MET signal.
% 
% There are two ways to call the function. In both forms, the current
% session descriptor sd must be the first argument. In the first form,  the
% trial identifier string tid (see metsdpath) must be the second argument,
% and the third must be shm, the cell array listing the currently
% accessible shared memory that is returned by met 'select'. In the second
% form, the current trial descriptor is provided rather than the trial
% identifier string, and instead of a 'select' shared memory list, the
% latest current buffer is provided (must have .stim field).
% 
% lnkind provides a mapping from task stimulus number to the set of linked
% stimuli. It is a cell array with an element for each task stimulus such
% that for stimulus i, lnkind{ i } returns the set of indeces for linked
% stimuli ; an empty array is returned if the task stimulus is not linked
% to any ptb-type MET stimulus definition. hitregion is a cell array with
% one element per stimulus link, where hitregion{ i } returns the hit
% region matrix for stimulus link i. logic is a pointer to the sub-struct
% in sd.logic corresponding to the task logic used by the current trial.
% ptblnk is a logical array such that ptblnk( i ) is true if the ith
% stimulus link is of type 'ptb'.
% 
% NOTE: that met 'select' and met 'read' are used in the first form of the
% function to read access the 'stim' shared memory, and will wait
% indefinitely for the initial hit regions to arrive. 'eye' and 'nsp' shm
% will be cleared during this wait. However, if an mquit or mwait signal is
% received then the function will return a single argument, qflag, that is
% a scalar double equal to that signal's identifier ; all remaining
% arguments will be returned as empty matrices i.e. []. The original shm
% given as an input argument may well be out of date when metptblink
% returns ; it is wise to run met ( 'select' ) at that point.
% 
% NOTE: Looks for global copies of MET constants MC and MET controller
% constants MCC. Creates them if not found.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  
  %%% Global constants %%%
  
  % MET constants and MET controller constants
  global  MC  MCC
  
  % If these haven't been set yet then set them. Note , only compile-time
  % MET constants asked for if not already declared.
  if  isempty (  MC )  ,   MC = met ( 'const' , 1 ) ;  end
  if  isempty ( MCC )  ,  MCC = metctrlconst    ;  end
  
  % MET quit and wait signal identifiers
  MQUIT = MCC.MSID.mquit ;
  MWAIT = MCC.MSID.mwait ;
  
  
  %%% Local constants %%%
  
  % Timer duration when waiting for hit regions to come over shared mem
  TIMOUT = 10 ;
  
  
  %%% Check input %%%
  
  % Session descriptor field set , checking only the basic form , not the
  % nested structs
  if  chkfrm ( sd , MCC.DAT.SD )
    
    error (  'MET:metptblink:stim'  ,  [ 'metptblink: invalid ' , ...
      'session descriptor sd , see metctrlconst' ]  )
    
  end % session descriptor
  
  % Trial descriptor given
  if  isstruct ( tid )
    
    % Check trial descriptor's form against the prototype
    if  chkfrm ( tid , MCC.DAT.TD )
      error (  'MET:metptblink:stim'  ,  [ 'metptblink: invalid ' , ...
        'trial descriptor tid , see metctrlconst' ]  )
    end
    
  % Trial identifier string given
  elseif  ~ isvector ( tid )  ||  ~ ischar ( tid )  ||  tidcheck ( tid )
    
    error (  'MET:metptblink:stim'  ,  [ 'metptblink: invalid trial ' , ...
      'identifier string tid , should be an integer of 1 or more' ]  )
    
  end % trial descriptor
    
  % Current buffer given.
  if  isstruct ( shm )
    
    % This must have correct field names including .stim, which must
    % contain at least the first two elements of 'stim' shared memory: the
    % time and logical index vector.
    if  chkfrm( shm , MCC.DAT.cbuf )  ||  ~ isfield( shm , 'stim' )  || ...
        numel( shm.stim )  <  MCC.SHM.STIM.LINDEX
      
      error (  'MET:metptblink:stim'  ,  [ 'metptblink: invalid ' , ...
        'current buffer passed in shm, see metctrlconst' ]  )
      
    end
    
  % met 'select' list of available shared memory was given
  elseif  ~ isempty ( shm )  &&  ~ (  iscell( shm )  &&  ...
    all( cellfun( @( c ) isvector( c ) && ischar( c ) , shm( : ) ) )  &&...
      size( shm , 2 )  ==  2  )
    
    error (  'MET:metptblink:stim'  ,  [ 'metptblink: invalid ' , ...
      'shared memory list shm , should be empty or a 2 column cell ' , ...
      'array of strings' ]  )
    
  end % shared mem list or current buffer
  
  
  %%% Get current trial descriptor %%%
  
  % If tid is a struct then we already have it
  if  isstruct ( tid )
    
    % Standard name
    td = tid ;
    
  % Trial identifier string given , load descriptor
  else
    
    % Name of the file with the new trial descriptor
    f = sprintf (  MCC.TDNAMS  ,  tid  ) ;
    f = fullfile (  sd.session_dir  ,  MC.SESS.TRIAL  ,  tid  ,  f  ) ;

    % Load the trial descriptor
    load (  f  ,  'td'  )

    % Make sure that variable was loaded
    if  ~ exist ( 'td' , 'var' )

      error (  'MET:metptblink:stim'  ,  [ 'metptblink: could not ' , ...
        'load trial descriptor ''td'' from %s' ]  ,  f  )

    end
  
  end % Get trial descriptor
  
  % Number of stimulus links
  nlinks = numel ( td.stimlink ) ;
  
  
  %%% Find ptb-type stimuli %%%
  
  % Determine which stimulus links are type 'ptb' stimuli
  ptblnk = strcmp (  'ptb'  ,  { td.stimlink.type }'  ) ;
  
  
  %%% Task stimulus to stimulus link mapping %%%
  
  % Make link to stim index mapping. If L is an index between 1 and the
  % number of links then stimind( L ) returns the task stimulus that is
  % linked.
  stmind = [  td.stimlink.istim  ] ;
  
  % Task stimulus index vector , converted to a cell array
  C = num2cell (  1 : sd.logic.( td.logic ).N.stim  ) ;
  
  % Make a task stimulus to link mapping. If i is an index from 1 to the
  % number of task stimuli, then lnkind{ i } returns a linear index vector
  % of link indeces. NOTE: lnkind{ i } is empty for any task stimulus
  % that isn't linked to a ptb-type MET stimulus definition.
  lnkind = cellfun (  @( c )  find ( stmind  ==  c )  ,  C  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % If lnkind{ 1 } is not empty then there has been a MET protocol
  % violation
  if  ~ isempty (  lnkind { 1 }  )
    
    error (  'MET:metptblink:protocol'  ,  [ 'metptblink: stimulus' , ...
      'link in session %s trial %s links to the ''none'' task ' , ...
      'stimulus in breach of the MET specification , ''%s''' ]  ,  ...
      sd.session_dir  ,  tid  ,  ...
      strjoin( {  td.stimlink( lnkind{ 1 } ).name  } , ''' , ''' )  )
    
  end % MET violation
  
  
  %%% Read trial initialisation hit regions %%%
  
  % Current buffer given , no need to read the shared memory
  if  isstruct ( shm )
    
    % Map current data from 'stim' shm to standard name
    C = shm.stim ;
    
  % met 'select' shared memory list given , read the shared memory
  else
    
    % Take a time measurement to prime the timer
    t1 = GetSecs ;
    
    % Wait for hit regions to be written to shared memory
    while  isempty ( shm )  ||  ...
             ~ any(  strcmp( shm( : , 1 ) , 'stim' )  &  ...
               [ shm{ : , 2 } ]' == 'r'  )

      % Wait for shared memory access , timout after a while
      [ t2 , msig , shm ] = met ( 'select'  ,  TIMOUT  ) ;
      
      % MET signals received
      if  msig  ,  [ ~ , ~ , msig ] = met ( 'recv' ) ;  end

      % mquit or mwait signal received , set SID as contents of lnkind
      if  any ( msig  ==  MQUIT )  ,  lnkind = MQUIT ;
      elseif  any ( msig  ==  MWAIT )  ,  lnkind = MWAIT ;
      end
      
      % mquit or mwait received , terminate function
      if  ~ iscell (  lnkind  )
        hitregion = [] ;  logic = [] ;  ptblnk = [] ;
        return
      end
        
      % Timeout
      if  TIMOUT  <  t2 - t1

        % Fire a warning message
        met (  'print'  ,  [ 'metptblink: timeout waiting for ' , ...
          'hit regions while initialising trial , wait again' , ...
          tid ]  ,  'e'  )
        
        % Reset the timer
        t1 = t2 ;

      end % timeout
      
      % Check if eye or nsp shared memory ready to read
      if  ~ isempty ( shm )
        
        % Loop shm names
        for  f = { 'eye' , 'nsp' }

          % Check readability
          if  any (  strcmp( shm( : , 1 ) , f{ 1 } )  &  ...
                  [ shm{ : , 2 } ]' == 'r'  )

            % Clear shared memory , non-blocking
            met (  'read'  ,  f{ 1 }  ) ;

          end % eye shared mem
        end % shm names
      end % clear eye & nsp shm

    end % wait for stim shm

    % Read from 'stim' shared memory
    C = met ( 'read' , 'stim' ) ;
  
  end % read shared memory
  
  
  %%% Verify ptb hit regions %%%
  
  % 'stim' shared memory constants
  S = MCC.SHM.STIM ;
  
  % Number of hit region lists returned
  n = numel ( C )  -  S.HITREG  +  1 ;
  
  % At this point there should be something to read. If there isn't then
  % that's a major problem.
  if  isempty ( C )
    
    error (  'MET:metptblink:stim'  ,  [ 'metptblink: met select ' , ...
      'reported stim shm ready for reading but nothing was read' ]  )
    
  % There must be a full compliment of hit regions returned , one for each
  % ptb-type stimulus link
  elseif  n  ~=  sum (  ptblnk  )
    
    error (  'MET:metptblink:stim'  ,  [ 'metptblink: initialising ' , ...
      'trial ' , tid , ' but stim shm returned %d hit regions when ' , ...
      '%d stimulus links were of type ''ptb''' ]  ,  n  ,  sum( ptblnk )  )
    
  % Logical index vector not returned , or it is not as long as the list of
  % stimulus links
  elseif  ~ islogical( C{ S.LINDEX } )  ||  ...
      ~ isvector( C{ S.LINDEX } )  ||  numel( C{ S.LINDEX } )  ~=  nlinks
    
    error (  'MET:metptblink:stim'  ,  [ 'metptblink: initialising' , ...
      'trial ' , tid , ' but stim shm failed to return a logical ' , ...
      'vector as long as the list of trial stimulus links' ]  )
    
  % Logical index vector must be true for each ptb-style stimulus link
  elseif  any ( C{ S.LINDEX }( : )  ~=  ptblnk ( : ) )
    
    error (  'MET:metptblink:stim'  ,  [ 'metptblink: initialising' , ...
      'trial ' , tid , ' but stim shm failed to return a hit ' , ...
      'region for each ptb-style stimulus link' ]  )
    
  end % error check
  
  
  %%% Final output arguments %%%
  
  % Return hit regions
  hitregion = cell (  1  ,  nlinks  ) ;
  hitregion( ptblnk ) = C (  S.HITREG  :  end  ) ;
  
  % The current task logic
  logic = sd.logic.( td.logic ) ;
  
  
end % metptblink


%%% Subroutines %%%

% Check basic form of session or trial descriptor , returns true if form is
% not valid. d is descriptor struct , s is a struct to compare against
function  i = chkfrm ( d , s )
  
  % Get field names
  F = {  fieldnames( d )  ,  fieldnames( s )  } ;
  
  % Check form. Must be scalar struct with the correct field name set.
  i = ~ isscalar ( d )  ||  ~ isstruct ( d )  ||  ...
      numel( F{ 1 } ) ~= numel( F{ 2 } )  ||  ...
      any( ~ismember( F{ 1 }  ,  F{ 2 } ) ) ;
  
end % chkfrm


% Makes sure that trial identifier string tid converts to a real integer
% greater than 0. Returns true if tid is not a valid identifier.
function  i = tidcheck ( tid )
  
  % Convert
  t = str2double ( tid ) ;
  
  % Check number
  i = isnan ( t )  ||  isinf ( t )  ||  mod ( t , 1 )  ||  t < 1 ;
  
end % tidcheck

