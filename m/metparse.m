
function  varargout = metparse ( PATH , varargin )
% 
% [ logic , vpar , task , var , block , evar ] = metparse ( SDPATH )
% [ ... ] = metparse ( SDPATH , rfdef )
% logic = metparse ( TLPATH , 'l' )
%  vpar = metparse ( VPPATH , 'p' )
%  vpar = metparse ( VPPATH , 'p' , rfdef )
% 
% Matlab Electrophysiology Toolbox parser. Reads in the schedule.txt and
% all task logic .txt files from the current session directory , specified
% in SDPATH. Parsed task logic is returned in logic, while first-level
% declarations of the schedule.txt file are returned in the remaining
% arguments. An optional second argument passes in a receptive/response
% field definition struct vector. This is passed to the MET stimulus
% definition functions so that the default value of variable parameters can
% be changed to match the RF preferences. If rfdef is left out then
% standard default variable parameter values are used.
% 
% Alternatively, the second input argument may be a single character. If
% given as such, then metparse looks directly in the directory provided by
% PATH and only returns one output argument. If the second input is 'l'
% then the named directory is taken to contain task logic files, which are
% all parsed and returned ; but when it is is 'p' then the named directory
% is taken to contain only stimulus definition functions , and only their
% variable parameters are returned. When the second argument is 'p' then an
% optional third argument may contain RF definitions.
% 
% logic will contain a struct with a field named after each task logic
% listed in /tasklogic of the current session directory. Each will contain
% a struct with fields that describe the states and task stimuli of the
% task logic:
% 
%   .calibration - string - Names the type of calibration that is performed
%     during this task.
%   
%   .N.state , .N.stim - scalar double , integer value 1 or more - The
%     number of task states and stimuli in this task logic.
%   
%   .nstate - N.state element cell vector of strings - The name of each
%     state. The index of each name in the list is the index for the named
%     state in all following fields. For example, if .nstate{ i } returns
%     'state1' then all values pertaining to state1 will be accessed in the
%     following fields with index i.
%   
%   .istate - scalar struct with N.state fields - Field names are the same
%     as in .nstate and are listed in the same order. Each field contains a
%     scalar double of the index required to find that field name in
%     .nstate.
%   
%   .nstim , .istim - The same as .nstate and .istate, except that they
%     describe the task stimuli, instead.
%   
%   .stim - scalar struct - Lists which task stimuli are present for each
%     state. Each field names a state and contains a list of task stimulus
%     indeces of stimuli that the state presents.
%   
%   .T - N.state element double vector - The timeout duration of each
%     state, in seconds. .T{ i } is the timeout for the state with name
%     .nstate{ i }.
%   
%   .E - N.state x N.stim x 2 double matrix - State transitions according
%     to which task stimulus is selected and whether or not the state has
%     timed out. When task stimulus j is selected in the ith state, then
%     the task will transition to state .E( i , j , 1 ) if the ith state
%     has been running for less than .T( i ) seconds, otherwise it will
%     transition to state .E( i , j , 2 ) if the ith state has timed out.
%   
%   .file - Name of the task logic file
%   
%   .dir - Directory containing that file
% 
% vpar is a struct with a field named after each stimulus definition. Each
% field contains a cell array where each row is a record pertaining to a
% single variable parameter of the stimulus. The column order is the name
% of the variable parameter (string) , the numerical domain (char 'i' or
% 'f' for integer or float) , the parameter's default value (scalar
% double), the minimum value (scalar double) and maximum value (scalar
% double).
% 
% Schedule file components each have their output argument.
% 
%   task will be a struct with a field named after each task declaration in
%   schedule.txt that contains a sub-struct describing each instance of the
%   task using fields:
%   
%     .logic - string - Names the task logic that this instance of the task
%       will use. This will be a fieldname of output argument logic ; hence
%       it will be the name given in a .txt file of the /tasklogic session
%       sub-directory.
%     
%     .link - A struct describing each task stimulus to stimulus definition
%       link in this task. If a task has L links then .link will have L
%       fields, and the ith field will be named after the ith link. Each
%       field holds a sub-struct with fields .stim and .def that each
%       contain a string naming the task stimulus and stimulus definition
%       to be linked. .stim will be a string from the .nstim field of the
%       logic named in .logic, and .def will name a function from the /stim
%       session sub-directory.
%     
%     .def - A D element struct vector giving the default values for state
%       timeouts and stimulus definition variable parameters used in this
%       instance of the task logic. This will have fields .type, .name,
%       .vpar, and .value. The double scalar in .value will be used for the
%       variable parameter named by string .vpar that belongs to the
%       component named by string .type with the name provided in (none
%       other than) .name. Valid types are 'stim' and 'state' for a
%       stimulus link or task logic state. For 'stim' the .vpar string must
%       be a variable parameter returned by the stimulus definition
%       function ; while for 'state' the value of .vpar must be 'timeout',
%       to set the state's timeout duration.
%     
%     .sevent - A struct describing which variable parameter of which
%       stimulus link will change upon transitioning to a given state of
%       the task logic i.e. it describes stimulus events. For S stimulus
%       events, .sevent will have S fields named after each stimulus event
%       declared in the schedule.txt file. Each field will be a struct with
%       fields .state, .link, and .vpar containing strings that specify
%       which state of the task logic named in .logic initiates the
%       parameter .vpar to change in the stimulus definition of the given
%       stimulus link, which is also described in .link above. The default
%       value that .vpar becomes is given in .value.
%     
%     .mevent - A struct describing which MET signal is broadcast when a
%       given task logic state is transitioned to i.e. a MET signal event.
%       For M events, .mevent will have M fields, each named after a MET
%       signal event declared for this task in the schedule.txt file. Each
%       field will hold a struct with fields .state, .msignal, and .cargo
%       giving the task logic state and MET signal name strings, and a
%       scalar double default cargo for the broadcast MET signal.
%     
%   var will have a field named after each task variable declaration in
%   schedule.txt that holds a sub-struct describing the task variable with
%   fields:
%     
%     .task - string - Names a task instance described in output argument
%       task. This is the task instance that the variable affects.
%     
%     .type - string - Names type of the task varible. In other words, this
%       declares what kind of component in the named task will vary from
%       trial to trial. Type can be 'state' , 'link' , 'sevent' , or
%       'mevent' to specify a task logic state, stimulus link, stimulus
%       event, or MET signal event.
%     
%     .name - string - Name of the task component that varies. This will be
%       the same as a field name in one of the structs described above.
%     
%     .vpar - string - Names which of the component's variable parameters
%       will be affected by this task variable. The values depend on the
%       specified type of variable, which are as follows:
%       
%           Type , Valid strings
%        'state' , 'timeout'
%         'link' , any variable parameter of the stimulus definition
%       'sevent' , 'value'
%       'mevent' , 'cargo'
%     
%     .depend - string - States whether this task variable is independent,
%       or if it is dependent on another task variable. If independent then
%       this will contain 'none'. Otherwise, it will give a field name from
%       var naming the dependent variable ; variables can not depend on
%       themselves. Alternatively, a dependent variable can use the string
%       'outcome' to vary with the outcome of past trials.
%     
%     .dist - string - Names the kind of distribution that the variable
%       will sample from. Independent variables can have string 'sched' ,
%       'unic' , 'unid' , 'bin' , 'norm' , 'pois' , 'exp' , or 'geo'.
%       Dependent variables can have string 'same' , or 'diff' if dependent
%       on another task varialbe, or 'correct' , 'failed' , 'ignored' ,
%       'broken' , or 'abort' if dependent on past outcomes.
%     
%     .value - empty , double scalar , or double vector - The set of
%       parameters required for each type of distribution.
%   
%   block will have a field named after each block declaration in
%   schedule.txt that holds a sub-struct describing each block of trials
%   with the following fields:
%     
%     .reps - scalar double , integer value 1 or more - The number of
%       repetitions of the block in each presentation. For example, a block
%       defining 5 different types of trials can be repeated 10 times to
%       produce 50 trials in total.
%     
%     .attempts - scalar double , integer value 1 or more - The number of
%       times that each trial will be presented in the current presentation
%       of the block. A trial is presented again if it is broken or
%       aborted ; then it is reshuffled back into the deck of remaining
%       trials.
%     
%     .var - cell array of strings - Each string names a task variable from
%       var that varies between trials in this block. There must be at
%       least one independent variable for each affected task instance.
%       Independent variables are sampled for each trial. The number of
%       trials in one repetition of a block depends on the number of
%       scheduled items or the stated number of repetitions.
%     
%   evar will have a struct that describes MET environmental variables with
%   the following fields:
%   
%     .origin - double vector of 2 , 4 , or 5 elements - Describes the
%       origin on screen for PsychToolbox i.e. 'ptb' type stimulus
%       definitions. Values 1 to 4 are given in degrees of visual field
%       from the centre of the screen, where up and right are positive, and
%       down and left are negative. In the 2 element form, a coordinate is
%       given that is always used. In the 4 element form, a rectangle is
%       defined as:
%
%         .origin( [ RectLeft , RectTop , RectRight , RectBottom ] )
%
%       giving two pairs of coordinates for the top-left corner and the
%       bottom-right corner ; an origin is sampled uniformly from anywhere
%       in this rectangle, for each trial. The 5 element form adds one more
%       value to the end of the 4 element form, giving a grid value ; the
%       rectangle is divided into that many sub-rectangles in the
%       horizontal and vertical directions, then all points at a corner of
%       any sub-rect is sampled to provide an origin on each trial.
%     
%     .disp - double with 1 , 2 , or 3 elements - Gives the disparity of
%       the origin in degrees of visual field. 0 is the screen surface.
%       Negative values are in front, and positive values behind the
%       screen. With 1 element, a single disparity is always used. The 2
%       element form gives a lower and upper range, with the disparity
%       sampled from anywhere in between. The final form appends a grid
%       value on the 2 element form, dividing the range into that many
%       segments such that either end of each segment is a disparity that
%       is sampled from.
%     
%     .reward - scalar struct - Describes how the cargo of each mreward
%       signal should be changed before a reward is given. That is, how
%       much more or less of a reward should be given than originally
%       intended. This struct has fields .baseline and .slope so that the
%       final reward is .baseline + .slope * cargo.
% 
% 
% Written by Jackson Smith - DPAG , University of Oxford
% 
  
  
  %%% MET controller constants %%%
  
  % RF definition constants are required to check input
  MCC = metctrlconst ;
  RFDEF = MCC.DAT.RFDEF ;
  
  
  %%% First run input check %%%
  
  % Default value for opt allows full parsing of session dir
  opt = 'f' ;
  
  % Default RF definition is empty. This signals that standard default
  % variable parameter values should be returned by the stimulus definition
  % functions.
  rfdef = MCC.DAT.SD.rfdef ;
  
  % PATH must be a string
  if  ~ischar ( PATH )  ||  ~isvector ( PATH )
    
    error ( 'MET:metparse:input' , 'metparse: input arg 1 not a string' )
    
  % optional inputs provided
  elseif  1 < nargin
    
    % Determine type. Character given.
    if  ischar (  varargin { 1 }  )
      
      % This is either 'l' or 'p'. Guarantee lower case. There might be a
      % RF definition struct that follows.
      opt = lower (  varargin { 1 }  ) ;
      
      % Check for too many inputs
      if  3  <  nargin
        
        error ( 'MET:metparse:input' , [ 'metparse: max 3 input args ' ,...
          'when second input is a char' ] )
        
      % opt must be 1 character: either 'l' or 'p'
      elseif  ~ isscalar ( opt )  ||  ~ any ( opt == 'lp' )

        error ( 'MET:metparse:input' , [ 'metparse: when input ' , ...
          'arg 2 is a char then it must be ''l'' or ''p''' ] )
        
      % RF definition provided for input 'p'
      elseif  nargin  ==  3
        
        % Input 'l' given , so max 2 input args
        if  opt  ==  'l'
          
          error ( 'MET:metparse:input' , [ 'metparse: max 2 input ' , ...
            'args when second input is ''l''' ] )
          
        end
        
        rfdef = varargin { 2 } ;
        
        % It must be a struct
        if  ~ isstruct ( rfdef )
          
          error ( 'MET:metparse:input' , [ 'metparse: input arg 3 ' , ...
            'must be a struct when arg 2 is a char' ] )
          
        end
        
      end % too many inputs
     
    % Second input is a RF definition struct
    elseif  isstruct (  varargin { 1 }  )
      
      % RF definition struct is given
      rfdef = varargin { 1 } ;
      
      % No more input arguments are allowed
      if  2  <  nargin
        
        error ( 'MET:metparse:input' , [ 'metparse: max 2 input args ' ,...
          'when second input is rfdef' ] )
        
      end % too many inputs
      
    % Unrecognised second input argument
    else
      
      error ( 'MET:metparse:input' , [ 'metparse: input arg 2 has ' , ...
          'invalid type' ] )
      
    end % Check type of input argument 2
    
  end % First pass input checking
  
  % Check rfdef
  if  ~ all ( strcmp(  RFDEF( : , 1 )  ,  fieldnames( rfdef )  ) )
    
    error ( 'MET:metparse:input' , [ 'metparse: rfdef has wrong set' , ...
          'of fields' ] )
        
  % rfdef can be empty ...
  elseif  ~ isempty (  rfdef  )
    
    % ... or a vector
    if  ~ isvector (  rfdef  )
    
      error ( 'MET:metparse:input' , [ 'metparse: rfdef must be ' , ...
        'empty , or a vector' ] )
        
    end
    
    % Non-empty , so check that all values are in range
    for  i = 1 : size ( RFDEF , 1 )
      
      % Field name
      f = RFDEF { i , 1 } ;
      
      % RF values
      j = [ rfdef.( f ) ] ;
      
      % Check range
      if  any ( j < RFDEF{ i , 3 }  |  RFDEF{ i , 4 } < j )
        
        error ( 'MET:metparse:input' , [ 'metparse: rfdef %s value ' , ...
          'is out of range' ] , f )
        
      end
      
    end % check values
    
  end % check rfdef
  
  
  %%% CONSTANTS %%%
  
  % Matlab Electrophysiology Toolbox compile time constants
  MC = met ( 'const' , 1 ) ;
  
  % schedule.txt file path
  SCHED = fullfile ( PATH , MC.SESS.SCHED ) ;
  
  % Task logic directory , session dir location , logic only location
  TLOG = fullfile ( PATH , MC.SESS.TLOG ) ;
  if  opt == 'l'  ,  TLOG = PATH ;  end
  
  % Stimulus definition sub-dir , sess dir location , stim only location
  STIM = fullfile ( PATH , MC.SESS.STIM ) ;
  if  opt == 'p'  ,  STIM = PATH ;  end
  
  % Task logic files
  TLOGF = fullfile ( TLOG , '*.txt' ) ;
  
  % Stimulus definition functions
  STIMF = fullfile ( STIM , '*.m' ) ;
  
  % Comment character
  COMCHR = '%' ;
  
  % Newline character
  NLCHAR = '\n' ;
  
  % Valid name , form as regular expression
  VALNAM = '^[a-zA-Z]+\w*$' ;
  
  
  %%% Check environment %%%
  
  % Search terms , reduce to PATH only if opt given
  FSRCH = { {  PATH , 'dir'  } , {  TLOG , 'dir'  } , ...
            {  STIM , 'dir'  } , { SCHED , 'file' } } ;
  if  any ( opt  ==  'lp' )  ,  FSRCH = FSRCH ( 1 ) ;  end
  
  % Look for session files / dirs
  for  F = FSRCH , f = F{ 1 } ;
    
    if  ~exist ( f{ 1 } , f{ 2 } )
      
      error ( 'MET:metparse:sessdir' , ...
        'metparse: Can''t find %s %s' , f{ 2 } , f{ 1 } )
      
    end
    
  end % session files
  
  % Look for task logic and stimulus definitions
  FSRCH = cell ( 1 , sum ( opt  ~=  'lp' ) ) ;
  
  if  opt  ~=  'p'
    tlogf = dir ( TLOGF ) ;
    FSRCH{ 1 } = { tlogf , 'task logic files' , TLOG } ;
  end
  
  if  opt  ~=  'l'
    stimf = dir ( STIMF ) ;
    FSRCH{ end } = { stimf , 'stimulus definition functions' , STIM } ;
  end
  
  for  F = FSRCH , f = F{ 1 } ;
    
    if  isempty ( f{ 1 } )
      error ( 'MET:metparse:sessdir' , 'metparse: no %s in %s' , ...
        f{ 2 } , f{ 3 } )
    end
    
  end % task logic and stim def func
  
  
  %%% Parse task logic files %%%
  
  % Not vpar only
  if  opt ~=  'p'
  
    logic = struct ;

    % Task logic file loop
    for  i = 1 : numel ( tlogf )

      % Task logic file name
      f = fullfile ( TLOG , tlogf( i ).name ) ;

      % Parse tokens , with line numbers
      [ t , l ] = readtokens ( f , COMCHR , NLCHAR ) ;

      % Separate sections of file
      [ n , s ] = tsklogic ( t , l , f , MC , VALNAM ) ;

      % Check that logic name is unique
      if  isfield ( logic , n )
        error ( 'MET:metparse:sessdir' , ...
          'metparse: task logic %s name %s already used' , f , n )
      end

      % Add to output
      logic.( n ) = s ;
      
      % Record file and directory names
      logic.( n ).file = tlogf( i ).name ;
      logic.( n ).dir  = TLOG ;

    end % task logic
    
  end % parse task logic
  
  % Task logic only , pack output and quit
  if  opt  ==  'l'
    varargout = { logic } ;
    return
  end
  
  
  %%% Stimulus definition variable parameters %%%
  
  % At this point , opt must be 'p' or 'f' and either way we need vpar
  
  % Store current dir , and jump into ./stim
  d = pwd ;
  cd ( STIM )
  
  % Get parameter set from each stim definition
  for  i = 1 : numel ( stimf )
    
    % Path to function
    fn = fullfile ( STIM , stimf( i ).name ) ;
    
    % Function name and handle
    [ ~ , n ] = fileparts ( stimf( i ).name ) ;
    h = str2func ( n ) ;
    
    % Parameters
    try
      
      % Hand rfdef to stim def function so that default variable parameter
      % values are matched to RF preferences
      if  nargin ( h )
        
        [ ~ , vpar.( n ) ] = h ( rfdef ) ;
        
      else
        
        % This is likely an older copy of the stimulus definition as it
        % cannot receive RF definitions.
        [ ~ , vpar.( n ) ] = h ( ) ;
        
        % Warn the user about this
        met (  'print'  ,  sprintf( [ 'metparse: ' , ...
          'obsolete version of stimulus definition accepts no input ' , ...
          'argument %s' ] , fn )  ,  'E'  )
        
      end
      
    catch
      
      error ( 'MET:metparse:stimdef' , ...
        'metparse: error retrieving %s variable pars' , fn )
      
    end
    
    checkvpar ( fn , VALNAM , vpar.( n ) )
    
  end % stim definitions
  
  % Restore current dir
  cd ( d )
  
  % Variable parameters only , pack output and quit
  if  opt  ==  'p'
    varargout = { vpar } ;
    return
  end
  
  
  %%% Parse schedule.txt file %%%
  
  % Parse tokens , with line numbers
  [ t , l ] = readtokens ( SCHED , COMCHR , NLCHAR ) ;
  
  % Separate sections
  [ task , var , block , evar ] = schedule ( t , l , logic , vpar , ...
    SCHED , VALNAM , MC ) ;
  
  
  %%% Look for any unused definitions %%%
  
  % First, build a list of task logic and stimulus definitions that were
  % used in schedule.txt
  tnames = fieldnames ( task ) ;
  schlog = cell ( size ( tnames ) ) ;
  schdef = cell ( 1 , numel ( tnames ) ) ;
  
  % Gather task logic and linked stim defs from each task instance
  for  i = 1 : numel ( tnames ) , t = tnames { i } ;
    
    % Task logic
    schlog { i } = task.( t ).logic ;
    
    % Link names
    l = task.( t ).link ;
    lnames = fieldnames ( l ) ;
    
    % Linked definitions
    schdef { i } = cell ( 1 ,  numel ( lnames ) ) ;
    
    for  j = 1 : numel ( lnames ) , ln = lnames { j } ;
      
      schdef { i } { j } = l.( ln ).def ;
      
    end % links
    
  end % tasks
  
  % Collapse both lists into their unique values
  schlog = unique ( schlog ) ;
  schdef = unique ( [ schdef{ : } ] ) ;
  
  % Is any task logic unused ?
  tlname = fieldnames ( logic ) ;
  i = ~ ismember ( tlname , schlog ) ;
  
  if  any ( i )
    
    error ( 'MET:metparse:stimdef' , [ 'metparse: %s , ' , ...
      'unused task logic: %s' ] , ...
      SCHED , strjoin ( tlname ( i ) , ' , ' ) )
    
  end
  
  % Is any stimulus definition unused?
  sdname = fieldnames ( vpar ) ;
  i = ~ ismember ( sdname , schdef ) ;
  
  if  any ( i )
    
    error ( 'MET:metparse:stimdef' , [ 'metparse: %s , ' , ...
      'unused stimulus definition: %s' ] , ...
      SCHED , strjoin ( sdname ( i ) , ' , ' ) )
    
  end
  
  
  %%% Pack output in varargout %%%
  
  varargout = { logic , vpar , task , var , block , evar } ;
  
  
end % metparse


%%% SUB-ROUTINES %%%

function  checkvpar ( fn , VALNAM , vpar )
  
  % Variable parameter constants. Number of columns in cell array. Then
  % column indeces of parameter name , domain , default value , lower , and
  % upper bounds on range.
  VPARCS.NC = 5 ;
  VPARCS.NAME = 1 ;  VPARCS.DOMAIN = 2 ;  VPARCS.DEFAULT = 3 ;
  VPARCS.LOWER = 4 ;  VPARCS.UPPER = 5 ;
  VPARCS.CHRCOL = [ VPARCS.NAME , VPARCS.DOMAIN ] ;
  VPARCS.DBLCOL = [ VPARCS.DEFAULT ,VPARCS.LOWER , VPARCS.UPPER ] ;
  VPARCS.DOMCHR = [ 'i' , 'f' ] ;
  
  % For convenience , pull these out into column cell arrays
  vpchr = vpar( : , VPARCS.CHRCOL ) ;  vpchr = vpchr( : ) ;
  vpdom = vpar( : , VPARCS.DOMAIN ) ;  vpdom = vpdom( : ) ;
  vpdbl = vpar( : , VPARCS.DBLCOL ) ;  vpdbl = vpdbl( : ) ;

  % Check that variable parameter terms have correct format
  if  isempty ( vpar )  ||  ~ iscell ( vpar )  ||  ...
      size ( vpar , 2 )  ~=  VPARCS.NC

    error ( 'MET:metparse:stimdef' , [ 'metparse: %s must return ' , ...
      'cell array in output arg vpar with %d columns' ] , ...
      fn , VPARCS.NC )

  elseif  any ( ...
      cellfun ( @( c )  ~ischar ( c ) | ~isvector ( c ) , vpchr ) )

    error ( 'MET:metparse:stimdef' , ...
      'metparse: %s , vpar , name and domain must be strings' , fn )

  elseif  any ( ...
      cellfun ( @( c )  1 < numel( c ) || ~any( c == VPARCS.DOMCHR ) ,...
                vpdom ) )

    error ( 'MET:metparse:stimdef' , ...
      'metparse: %s , vpar , domain must be one of ''%s''' , ...
      fn , strjoin ( num2cell ( VPARCS.DOMCHR ) , ''' , ''' ) )

  elseif  any ( cellfun ( ...
      @( c )  ~isa( c , 'double' ) || ~isscalar( c ) || isnan( c ) , ...
      vpdbl ) )

    error ( 'MET:metparse:stimdef' , [ 'metparse: %s , vpar , ' , ...
      'all numbers must be scalar doubles , no NaN' ] , fn )

  end

  % Check form of parameter names , no repeats
  checkform (  vpar( : , VPARCS.NAME ) , NaN ( size ( vpar , 1 ) , 1 ) ,...
               3 , 'vpar name' , fn , VALNAM  )

  % Turn doubles to a single matrix and check relations
  d = cell2mat ( vpar( : , VPARCS.DBLCOL ) ) ;

  if  any ( d( : , 3 )  <  d( : , 2 ) )

    error ( 'MET:metparse:stimdef' , ...
      'metparse: %s , vpar , upper bound less than lower' , fn )

%   elseif  any ( all ( isinf ( d( : , 2 : 3 ) ) , 2 )  &  ...
%       ~( d( : , 2 ) < 0  &  0 < d( : , 3 ) ) )
% 
%     error ( 'MET:metparse:stimdef' , [ 'metparse: %s , vpar , ' , ...
%       'range bounds both Inf on same side of zero' ] , fn )

  end
  
  i = isinf ( d( : , 1 ) ) ;
  
  if  any ( i )
    
    if  any ( d( i , 1 ) < 0  &  ...
        ( ~isinf ( d( i , 2 ) )  |  0 < d( i , 2 ) ) )

      error ( 'MET:metparse:stimdef' , [ 'metparse: %s , vpar , ' , ...
        '-Inf default vpar but lower bound is +Inf' ] , fn )

    elseif  any ( d( i , 1 ) > 0  &  ...
        ( ~isinf ( d( i , 3 ) )  |  0 > d( i , 3 ) ) )

      error ( 'MET:metparse:stimdef' , [ 'metparse: %s , vpar , ' , ...
        '+Inf default vpar but upper bound is -Inf' ] , fn )

    end
    
  elseif  any ( ~i )  &&  ...
      any (  d( ~i , 1 ) < d( ~i , 2 )  |  d( ~i , 3 ) < d( ~i , 1 )  )

    error ( 'MET:metparse:stimdef' , [ 'metparse: %s , vpar , ' , ...
      'default value is out of range' ] , fn )

  end
  
end % checkvpar


function  [ task , var , block , evar ] = ...
  schedule ( t , l , logic , vpar , fn , VALNAM , MC )
  
  
  %%% KONSTANTS %%%
  
  % Keywords for sections of schedule.txt
  K.W = { 'task' , 'var' , 'block' , 'evar' } ;
  K.TASK = 1 ;  K.VAR = 2 ;  K.BLOCK = 3 ;  K.EVAR = 4 ;
  
  % var declaration type keywords
  K.TYPE = { 'state' , 'stim' , 'sevent' , 'mevent' } ;
  K.STATE = 1 ;  K.STIM = 2 ;  K.SEVENT = 3 ;  K.MEVENT = 4 ;
  
  % Variable parameters
  K.VPAR.state  = { 'timeout' , 'f' , 0 , Inf } ;
  K.VPAR.sevent = { 'value' } ;
  K.VPAR.mevent = { 'cargo' , 'i' , 0 , intmax( 'uint16' ) } ;
  
  % Variable parameter index , for vpar output of stim def function
  K.VPI = [ 1 , 2 , 4 , 5 ] ;
  
  % Minimum number of tokens in a task variable declaration
  K.VARMIN = 7 ;
  
  % Minimum number of tokens in block declaration
  K.BLKMIN = 4 ;
  
  % Independent
  K.INDEP = 'none' ;
  
  % Dependent on outcome
  K.OUTC = 'outcome' ;
  
  % Distribution types , Independent , outcome dependent , var dependent
  K.DIND = { 'sched' , ...
    'unid' , 'unic' , 'bin' , 'norm' , 'pois' , 'exp' , 'geo' } ;
  K.DOUT = { 'correct' , 'failed' , 'ignored' , 'broken' , 'abort' } ;
  K.DDEP_SCHED   = { 'sched' } ;
  K.DDEP_NOSCHED = { 'same' , 'diff' } ;
  
  % Broadly class the domain of distributions, if possible, as integer or
  % real numbers. Scheduled distributions ( shed and outcomes ) must be
  % checked against the given distribution terms
  K.DDOM.INTS = { 'unid' ,  'bin' , 'pois' , 'geo' } ;
  K.DDOM.REAL = { 'unic' , 'norm' ,  'exp' } ;
  K.DDOM.SCHD = [ { 'sched' } , K.DOUT ] ;
  
  % Number of distribution terms , only for parametric , as scheduled is a
  % special case
  K.NTRM = { 'unid' , 'unic' , 'bin' , 'norm' , 'pois' , 'exp' , 'geo' ;
                 2  ,     2  ,    2  ,     2  ,     1  ,    1  ,    2  } ;
  K.NTRM = struct ( K.NTRM{ : } ) ;
  
  
  %%% Pralloc output structs %%%
  
   task = struct ;
    var = struct ;
  block = struct ;
  
  
  %%% Group tokens by keyword %%%
  
  [ tg , lg ] = grpsplit ( K.W , t , l , fn ) ;
  
  
  %%% Parse each task declaration %%%
  
  % Are there any?
  if  isempty ( tg{ K.TASK } )
    
    error ( 'MET:metparse:schedule' , ...
      'metparse: file %s , no %s declaration' , fn , K.W{ K.TASK } )
    
  end
  
  % Declarations
  for  i = 1 : numel ( tg{ K.TASK } )
    
    % Declaration , and line numbers
     d = tg{ K.TASK }{ i } ;
    ln = lg{ K.TASK }{ i } ;
    
    % Do we have at least a task and task-logic name?
    if  numel ( d )  <  2
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'incomplete task declaration' ] , fn )
      
    end
    
    % Do task name and task logic name have proper form?
    checkform ( d( 1 ) , ln( 1 ) , 1 , 'task name'       , fn , VALNAM )
    checkform ( d( 2 ) , ln( 2 ) , 1 , 'task logic name' , fn , VALNAM )
    
    % Repeated task name?
    if  isfield ( task , d{ 1 } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , task %s already declared' ] , fn , ln( 1 ) , d{ 1 } )
      
    end
    
    % Task logic recognised?
    if  ~isfield ( logic , d{ 2 } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , task logic %s not found' ] , fn , ln( 2 ) , d{ 2 } )
      
    end
    
    % Parse declaration
    task.( d{ 1 } ) = tasdec ( d{ 1 : 2 } , ...
      d( 3 : end ) , ln ( 3 : end ) , ...
      logic.( d{ 2 } ) , vpar , fn , VALNAM , MC ) ;
    
  end % task declarations
  
  
  %%% Task variable declarations %%%
  
  % Are there any?
  if  isempty ( tg{ K.VAR } )
    
    error ( 'MET:metparse:schedule' , ...
      'metparse: file %s , no %s declaration' , fn , K.W{ K.VAR } )
    
  end
  
  % Check minimum number of terms
  i = cellfun ( @( t )  numel ( t )  <  K.VARMIN , tg{ K.VAR } ) ;
  i = find ( i , 1 , 'first' ) ;
  
  if  i
    
    error ( 'MET:metparse:schedule' , ...
      'metparse: file %s , %s declaration under %d terms' , ...
      fn , K.W{ K.VAR } , K.VARMIN )
    
  end
  
  % Declarations
  for  i = 1 : numel ( tg{ K.VAR } )
    
    % Declaration , and line numbers
     d = tg{ K.VAR }{ i } ;
    ln = lg{ K.VAR }{ i } ;
    
    % Check form
    checkform ( d( 1 : K.VARMIN ) , ln( 1 : K.VARMIN ) , ...
      1 , 'var' , fn , VALNAM )
    
    % Repeated variable name?
    if  isfield ( var , d{ 1 } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s already declared' ] , fn , ln( 1 ) , d{ 1 } )
      
    end 
    
    % Valid task?
    if  ~isfield ( task , d{ 2 } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , task %s not declared' ] , ...
        fn , ln( 2 ) , d{ 1 } , d{ 2 } )
      
    end
    
    % Valid type keyword?
    if  ~any ( strcmp ( d{ 3 } , K.TYPE ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , type %s unrecognised' ] , ...
        fn , ln( 3 ) , d{ 1 } , d{ 3 } )
      
    end
    
    % Get list of valid component names , by type of var
    switch  d{ 3 }
      
      case  K.TYPE{ K.STATE }
        n = logic.( task.( d{ 2 } ).logic ).nstate ;
        
      case  K.TYPE{ K.STIM }
        n = fieldnames ( task.( d{ 2 } ).link ) ;
        
      case  K.TYPE{ K.SEVENT }
        n = fieldnames ( task.( d{ 2 } ).sevent ) ;
        
      case  K.TYPE{ K.MEVENT }
        n = fieldnames ( task.( d{ 2 } ).mevent ) ;
        
    end % component list
    
    if  isstruct ( n )  ,  n = fieldnames ( n ) ;  end
    
    % Is a valid component named?
    if  ~any ( strcmp ( d{ 4 } , n ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , no %s %s declaration in schedule.txt' ] , ...
        fn , ln( 4 ) , d{ 1 } , d{ 3 } , d{ 4 } )
      
    end
    
    % Get variable parameter list , by type
    switch  d{ 3 }
      
      case  K.TYPE{ K.STIM }
        
        n = task.( d{ 2 } ).link.( d{ 4 } ).def ;
        vp = vpar.( n )( : , K.VPI ) ;
        n = vp( : , 1 ) ;
        
      case  K.TYPE{ K.SEVENT }
        
        % Link name and var par
         n = task.( d{ 2 } ).sevent.( d{ 4 } ).link ;
        vp = task.( d{ 2 } ).sevent.( d{ 4 } ).vpar ;
        
        % Map to link definition and vpar record
         n = task.( d{ 2 } ).link.( n ).def ;
         j = strcmp ( vp , vpar.( n )( : , 1 ) ) ;
        vp = vpar.( n )( j , K.VPI ) ;
        
        % Variable par of sevent
        n = K.VPAR.sevent ;
        
      otherwise
        
        vp = K.VPAR.( d{ 3 } ) ;
        n = vp( : , 1 ) ;
      
    end % vpar list
    
    % Check variable parameter
    j = find ( strcmp ( d{ 5 } , n( : , 1 ) ) ) ;
    
    if  ~isscalar ( j ) ;
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , %s %s , no vpar %s' ] , ...
        fn , ln( 5 ) , d{ 1 } , d{ 3 : 5 } )
      
    end
    
    % Check dependency
    if  isempty ( fieldnames ( var ) )  &&  ~strcmp ( d{ 6 } , K.INDEP )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , first task var must be independent' ] , ...
        fn , ln( 1 ) , d{ 1 } )
      
    elseif  ...
      ~any ( strcmp ( d{ 6 } , [ K.INDEP ; K.OUTC ; fieldnames( var ) ] ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , dependency %s unrecognised' ] , ...
        fn , ln( 6 ) , d{ 1 } , d{ 6 } )
      
    elseif  ~any ( strcmp ( d{ 6 } , { K.INDEP ; K.OUTC } ) )
      
      if  ~ strcmp ( var.( d{ 6 } ).depend , K.INDEP )
        
        error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
          'line %d , var %s , dependency on dependent variable %s' ] , ...
          fn , ln( 6 ) , d{ 1 } , d{ 6 } )
        
      elseif  ~ strcmp ( d{ 2 } , var.( d{ 6 } ).task )
        
        error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
          'line %d , var %s for task %s , dependency on variable %s ' , ...
          'for task %s' ] , ...
          fn , ln( 6 ) , d{ 1 } , d{ 2 } , d{ 6 } , var.( d{ 6 } ).task )
        
      end
      
    end
    
    % Distribution names list
    switch  d{ 6 }
      case  K.INDEP  ,  n = K.DIND ;
      case  K.OUTC   ,  n = K.DOUT ;
      otherwise      ,  n = [ K.DDEP_SCHED , K.DDEP_NOSCHED ] ;
    end
    
    % Check distribution type
    if  ~ any ( strcmp ( d{ 7 } , n ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , depends on %s , ' , ...
        'unrecognised distribution %s' ] , ...
        fn , ln( 7 ) , d{ 1 } , d{ 6 } , d{ 7 } )
      
    end
    
    % Convert distribution terms
    v = [] ;
    
    if  K.VARMIN  <  numel ( d )
      
      v = str2double ( d( K.VARMIN + 1 : end ) ) ;
      
    end
    
    % Any invalid numbers?
    n = find ( isnan ( v )  |  ~isreal ( v ) , 1 , 'first' )  +  K.VARMIN ;
    
    if  n
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , distribution term %s not a valid number' ] ,...
        fn , ln( n ) , d{ 1 } , d{ n } )
      
    end
    
    % Check terms against distribution and variable parameter
    checkdist ( K , fn , d{ 1 } , ln( 1 ) , ...
      vp( j , : ) , d{ 7 } , v , d{ 6 } , var )
    
    % Pack data
    n = { 'task' , 'type' , 'name' , 'vpar' , 'depend' , 'dist' , 'value' ;
          d{ 2 : 7 } , v } ;
    
    var.( d{ 1 } ) = struct ( n{ : } ) ;
    
    
  end % var declarations
  
  
  %%% Block declarations %%%
  
  % Are there any?
  if  isempty ( tg{ K.BLOCK } )
    
    error ( 'MET:metparse:schedule' , ...
      'metparse: file %s , no %s declaration' , fn , K.W{ K.BLOCK } )
    
  end
  
  % Check minimum number of terms
  i = cellfun ( @( t )  numel ( t )  <  K.BLKMIN , tg{ K.BLOCK } ) ;
  i = find ( i , 1 , 'first' ) ;
  
  if  i
    
    error ( 'MET:metparse:schedule' , ...
      'metparse: file %s , %s declaration under %d terms' , ...
      fn , K.W{ K.BLOCK } , K.BLKMIN )
    
  end
  
  % Declarations
  for  i = 1 : numel ( tg{ K.BLOCK } )
    
    % Declaration , and line numbers
     d = tg{ K.BLOCK }{ i } ;
    ln = lg{ K.BLOCK }{ i } ;
    
    % Check form of block name , and task variable names with no repeats
    checkform ( d( 1 ) , ln( 1 ) , 1 , 'block name' , fn , VALNAM )
    checkform ( d( K.BLKMIN : end ) , ln( K.BLKMIN : end ) , 3 , ...
      'block var' , fn , VALNAM )
    
    % Repeated block name?
    if  isfield ( block , d{ 1 } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , block %s already declared' ] , fn , ln( 1 ) , d{ 1 } )
      
    end 
    
    % Valid task variables?
    j = ~isfield ( var , d( K.BLKMIN : end ) ) ;
    j = find ( j , 1 , 'first' )  +  K.BLKMIN  -  1 ;
    
    if  j
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , block %s , task var %s not declared' ] , ...
        fn , ln( j ) , d{ 1 } , d{ j } )
      
    end
    
    % Get number of repeats and attempts
    v = str2double ( d( 2 : 3 ) ) ;
    j = find ( isnan ( v )  |  isinf ( v ) , 1 , 'first' )  +  1 ;
    
    if  isempty ( j )
      j = find ( v < 1  |  mod ( v , 1 ) , 1 , 'first' )  +  1 ;
    end
    
    if  ~isempty ( j )  ||  any ( v < 1  |  mod ( v , 1 ) )
      
      % Either invalid number string , or not a natural number over 0
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , block %s , value %s is not a valid number' ] , ...
        fn , ln( j ) , d{ 1 } , d{ j } )
      
    end
    
    % Make sure that there is at least one independent variable for each
    % task involved , and that all dependent variables follow either a
    % listed independent variable from the same task or the outcome.
    checktskvar ( K , fn , d{ 1 } , ln( 1 ) , d( K.BLKMIN : end ) , var )
    
    % Pack data
    n = { 'reps' , 'attempts' , 'var'  ;
          v( 1 ) ,     v( 2 ) , { d( K.BLKMIN : end ) } } ;
    
    block.( d{ 1 } ) = struct ( n{ : } ) ;
    
  end % block declarations
  
  
  %%% Check for unused task or var %%%
  
  % All block structs
  B = struct2cell ( block ) ;
  B = [ B{ : } ] ;
  
  % Names of vars used in blocks , and the tasks they name
  vbloc = { B( : ).var } ;
  tbloc = cell ( 1 , numel ( B ) ) ;
  
  % var field names and sub-structs
  varfn =  fieldnames ( var ) ;
  varst = struct2cell ( var ) ;
  
  % Loop blocks to gather task names
  for  i = 1 : numel ( B )
    
    % var sub-structs of vars named in this block
    j = ismember ( varfn , B( i ).var ) ;
    j = [ varst{ j } ] ;
    
    % Named tasks
    tbloc { i } = { j.task } ;
    
  end
  
  % Collapse to unique values
  vbloc = unique ( [ vbloc{ : } ] ) ;
  tbloc = unique ( [ tbloc{ : } ] ) ;
  
  % Get names of all tasks, vars, and blocks
  tname = fieldnames ( task ) ;
  vname = fieldnames (  var ) ;
  
  % Check for missing tasks or vars
  i = ~ ismember ( tname , tbloc ) ;
  j = ~ ismember ( vname , vbloc ) ;
  
  if  any ( i )
    
    error ( 'MET:metparse:schedule' , ...
      'metparse: file %s , unused task: %s' , ...
      fn , strjoin ( tname ( i ) , ' , ' ) )
    
  elseif  any ( j )
    
    error ( 'MET:metparse:schedule' , ...
      'metparse: file %s , unused var: %s' , ...
      fn , strjoin ( vname ( j ) , ' , ' ) )
    
  end
  
  
  %%% Parse evar declaration %%%
  
  % Are there too many?
  if  1  <  numel ( tg{ K.EVAR } )
    
    error ( 'MET:metparse:schedule' , ...
      'metparse: file %s , one %s declaration allowed' , ...
      fn , K.W{ K.EVAR } )
    
  end
  
  evar = evardec ( tg{ K.EVAR }{ 1 } , lg{ K.EVAR }{ 1 } , fn ) ;
  
  
end % schedsep


function  evar = evardec ( t , l , fn )
  
  
  %%% Constants %%%
  
  % Keywords
  K.W = { 'origin' , 'disp' , 'reward' } ;
  K.ORIGIN = 1 ;  K.DISP = 2 ;  K.REWARD = 3 ;
  
  % Number of tokens for each declaration type
  NUMVAL.ORIGIN = [ 2 , 4 , 5 ] ;
  NUMVAL.DISP = 1 : 3 ;
  NUMVAL.REWARD = 2 ;
  
  % K and NUMVAL fieldnames , for checking looped token groups
  FNAMES = fieldnames ( NUMVAL ) ;
  
  % Default values , { field name , value }
  DEFVAL.ORIGIN = [ 0 , 0 ] ;
  DEFVAL.DISP   = 0 ;
  DEFVAL.REWARD = [ 0 , 1 ] ;
  
  % Origin sampling box coordinate indeces
  x0 = 1 ;  y0 = 2 ;  x1 = 3 ;  y1 = 4 ;
  
  
  %%% Find token groups %%%
  
  if  isempty ( t )
    
    tg = cell ( size ( FNAMES ) ) ;
    lg = cell ( size ( FNAMES ) ) ;
    
  else
    
    [ tg , lg ] = grpsplit ( K.W , t , l , fn ) ;
    
  end
  
  
  %%% Loop declaration types %%%
  
  for  i = 1 : numel ( tg )
    
    % Get declaration-type fieldname for constants
    f = FNAMES { i } ;
    
    % There can only be one of each type
    if  1 < numel ( tg{ i } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , evar statement , more than one %s declaration' ] , ...
        fn , lg{ i }{ 2 }( 1 ) , K.W{ i } )
      
    end
    
    % No such declaration , set default and jump to next type
    if  isempty ( tg{ i } )
      tg{ i } = DEFVAL.( f ) ;
      continue
    end
    
    % Bring nested layer forward
    tg{ i } = tg{ i }{ 1 } ;
    lg{ i } = lg{ i }{ 1 } ;
    
    % Invalid number of values given
    nval = numel ( tg{ i } ) ;
    
    if  all ( nval ~= NUMVAL.( f ) )
      
      if  isempty ( lg{ i } )  ,  lg{ i } = NaN ;  end
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , evar , %s declaration , wrong number of values' ] , ...
        fn , lg{ i }( 1 ) , lower ( f ) )
      
    end
    
    % Correct number of values , convert to numeric form
    tg{ i } = str2double ( tg{ i } ) ;
    
    % Check type
    j = isnan ( tg{ i } )  |  ~isreal ( tg{ i } )  |  isinf ( tg{ i } ) ;
    j = find ( j , 1 , 'first' ) ;
    
    if  j
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , evar , %s declaration , value %d invalid number' ] , ...
        fn , lg{ i }( j ) , lower ( f ) , j )
      
    end
    
    % Type-specific case checking
    v = tg{ i } ;
    
    switch  i
      
      case  1  %  origin
        
        if      2  ==  nval
          
          % Nothing to check
          
        elseif  4  <=  nval  &&  ...
            any (  v( [ x1 , y0 ] )  <=  v( [ x0 , y1 ] )  )
          
          % Upper bounds are less than lower bounds
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , evar , %s declaration , ' ...
            'upper bound less than lower bound' ] , ...
            fn , lg{ i }( 1 ) , lower ( f ) )
          
        elseif  5  ==  nval  &&  v( 5 )  <=  0
          
          % Gridding value is 0 or negative
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , evar , %s declaration , ' ...
            'zero or negative gridding value' ] , ...
            fn , lg{ i }( 1 ) , lower ( f ) )
          
        end
        
      case  2  %  disp
        
        if  1  ==  nval
          
          % Nothing to check
          
        elseif  2  <=  nval  &&  v( 2 )  <=  v( 1 )
          
          % Upper bound less than lower
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , evar , %s declaration , ' ...
            'upper bound less than lower bound' ] , ...
            fn , lg{ i }( 1 ) , lower ( f ) )
          
        elseif  3  ==  nval  &&  v( 3 )  <=  0
          
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , evar , %s declaration , ' ...
            'zero or negative gridding value' ] , ...
            fn , lg{ i }( 1 ) , lower ( f ) )
          
        end
        
      case  3  %  reward
        
        if      v ( 1 )  <   0
          
          % Baseline is negative
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , evar , %s declaration , ' ...
            'negative baseline reward' ] , ...
            fn , lg{ i }( 1 ) , lower ( f ) )
          
        elseif  v ( 2 )  <=  0
          
          % Slope is zero or less
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , evar , %s declaration , ' ...
            'zero or negative slope' ] , ...
            fn , lg{ i }( 2 ) , lower ( f ) )
          
        end
      
    end % declaration type
    
  end % declaration types
  
  
  %%% Pack data %%%
  
  i = { K.W{ : } ; tg{ : } } ;
  
  evar = struct ( i { : } ) ;
  
  
end % evardec


function  checktskvar ( K , fn , bname , bline , vname , var )
	
	% Get a struct array for listed task variables
  v = repmat ( var.( vname { 1 } ) , size ( vname ) ) ;
  
	for  i = 1 : numel ( vname )
    v( i ) = var.( vname { i } ) ;
  end
  
  % Task names and locations in v
  [ tname , ~ , ti ] = unique ( { v.task } ) ;
  
  % Independent variables
  iv = strcmp ( K.INDEP , { v.depend }' ) ;
  
  % Check that there is at least one independent variable for each task
  % involved
  i = unique ( { v( iv ).task } ) ;
  i = find ( ~strcmp ( i , tname ) , 1 , 'first' ) ;
  
  if  i
    
    error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
      'line %d , block %s , no independent vars for task %s' ] , ...
      fn , bline , bname , tname{ i } )
    
  end
  
  % Check that all dependent variables reference a listed independent
  % variable from the same task
  for  i = 1 : numel ( tname )
    
    % Find variables from this task
    j = ti == i ;
    
    % Find independent variable names for this task , include outcome
    ivn = [ vname( j  &  iv ) , { K.OUTC } ] ;
    
    % Dependent variables in this task
    d = find ( j  &  ~iv ) ;
    
    % Get dependency for each dependent variable
    dep = { v( d ).depend } ;
    
    % Is every dependency in the ind. var list?
    j = ~ ismember ( dep , ivn ) ;
    j = find ( j , 1 , 'first' ) ;
    
    if  j
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
      'line %d , block %s , dependend var %s''s independent var %s ' , ...
      'not listed in block declaration' ] , ...
      fn , bline , bname , vname{ d ( j ) } , dep{ j } )
      
    end
    
  end % tasks
  
end % checktskvar


function  checkdist ( K , fn , vname , vline , vpar , ...
  dname , dterm , ddep , var )
  
  % Give variable parameter terms meaningful names
  vp = { 'name' , 'domain' , 'min' , 'max' ; vpar{ : } } ;
  vp = struct ( vp{ : } ) ;
  
  % Is this an independent variable?
  indep = strcmp ( ddep , K.INDEP ) ;
  
  % Raise flag to show that distribution is mapped to independent var
  mapflg = 0 ;
  
  % This is a dependent variable
  if  ~indep
    
    % Its distribution is same or diff
    if  any ( strcmp ( dname , K.DDEP_NOSCHED ) )
      
      % Map to the independent variable's distribution and terms , for
      % domain checking , after which point the function can return , since
      % the independent variable will have been checked
      dname = var.( ddep ).dist  ;
      dterm = var.( ddep ).value ;
      
      % Map flag
      mapflg = 1 ;
    
    % Distribution is sched , then the independent variable must also have
    % distribution sched
    elseif  strcmp ( dname , K.DDEP_SCHED )  &&  ...
        ~strcmp ( var.( ddep ).dist , K.DDEP_SCHED )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , has distribution %s but depends on ' , ...
        'var %s with distribution %s' ] , ...
        fn , vline , vname , dname , ddep , var.( ddep ).dist )
      
    end
    
  end % dependent var mapping to independent var
  
  % Check whether distribution name is in the set of continuous parametric
  % or scheduled
  i.schd = strcmp ( dname , K.DDOM.SCHD ) ;
  
  % Domain checking , integer variable parameters can not have continuous
  % distributions
  if  vp.domain == 'i'
    
    % Parametric continuous distributions
    if  any ( strcmp ( dname , K.DDOM.REAL ) )

      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , vpar %s with integer domain can''t use ' , ...
        'continuous parametric distribution %s' ] , ...
        fn , vline , vname , vp.name , dname )
    
    % Scheduled distribution terms
    elseif  any ( i.schd )  &&  any ( mod ( dterm , 1 ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , vpar %s with integer domain can''t use ' , ...
        'continuous terms in scheduled distribution %s' ] , ...
        fn , vline , vname , vp.name , dname )
      
    end
    
  end % int vpar domain
  
  % Number of distribution terms , depends on whether parametric or
  % scheduled
  if  mapflg
    
    % Distribution is mapped , so no need to check
    
  elseif  any ( i.schd )
    
    % Scheduled , in no case can dterm be an empty list
    if  ~numel ( dterm )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , var %s , distribution %s , no terms given' ] , ...
        fn , vline , vname , dname )
      
    % Dependent variable , depends on another task variable , not outcome.
    % Must have the same number of terms as the independent variable
    elseif  ~indep  &&  strcmp ( dname , K.DDEP_SCHED )  &&  ...
      numel ( var.( ddep ).value )  ~=  numel ( dterm )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , dependent var %s , distribution %s , different ' , ...
        'number of terms from independent var' ] , ...
        fn , vline , vname , dname )
      
    end
    
  % Parametric
  elseif  K.NTRM.( dname )  ~=  numel ( dterm )

    error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
      'line %d , var %s , distribution %s requires %d term(s)' ] , ...
      fn , vline , vname , dname , K.NTRM.( dname ) )

  end % number of terms
  
  % Check validity of parametric terms , take the opportunity to define the
  % range of distribution values
  if  ~any ( i.schd )
    
    % Handle each distribution
    switch  dname
      
      % Uniform distributions
      case  { 'unid' , 'unic' }
        
        % First term must be less than second
        if  dterm ( 2 ) <= dterm ( 1 )
          
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , var %s , %s a b , b <= a' ] , ...
            fn , vline , vname , dname )
          
        % Discrete distribution must not get continuous terms
        elseif  dname ( end ) == 'd'  &&  any ( mod ( dterm , 1 ) )
          
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , var %s , %s must have integer terms' ] , ...
            fn , vline , vname , dname )
          
        end
        
        mm = dterm ;
        
      % Binomial
      case  'bin'
        
        % n term must be natural number or zero
        if  mod ( dterm ( 1 ) , 1 )  ||  dterm ( 1 ) < 0
          
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , var %s , %s n p , n must be natural number ' , ...
            'or zero' ] , ...
            fn , vline , vname , dname )
          
        % p term must be a probability value
        elseif  dterm ( 2 ) < 0  ||  1 < dterm ( 2 )
          
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , var %s , %s n p , p must have range 0 to 1' ] , ...
            fn , vline , vname , dname )
          
        end
        
        mm = [ 0 , dterm( 1 ) ] ;
        
      % Normal i.e. Gaussian
      case  'norm'
        
        % Positive standard deviation
        if  dterm ( 2 )  <=  0
          
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , var %s , %s m s , s must be positive' ] , ...
            fn , vline , vname , dname )
          
        end
        
        mm = [ -Inf , Inf ] ;
        
      % Poisson and exponential
      case  { 'pois' , 'exp' }
        
        % Positive mean
        if  dterm  <=  0
          
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , var %s , %s m , m must be positive' ] , ...
            fn , vline , vname , dname )
          
        end
        
        mm = [ 0 , Inf ] ;
        
      % Geometric
      case  'geo'
        
        % Support term must be 0 or 1
        if  all ( dterm ( 1 )  ~=  [ 0 , 1 ] )
          
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , var %s , %s s p , s must be 0 or 1' ] , ...
            fn , vline , vname , dname )
          
        % Probability
        elseif  dterm ( 2 ) < 0  ||  1 < dterm ( 2 )
          
          error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , var %s , %s s p , p must have range 0 to 1' ] , ...
            fn , vline , vname , dname )
          
        end
        
        mm = [ dterm( 1 ) , Inf ] ;
      
    end % dist handling
    
  % Default mm , so that check is guaranteed to return false
  else
    
    mm = [ Inf , -Inf ] ;
    
  end % parametric dist check
  
  % Range checking , make sure that distribution will produce values within
  % range of the variable parameter. Two sets of () brackets check the two
  % cases. Scheduled distribution contains one or more values out of range.
  % Or, parametric distribution support exceeds range.
  if  ( any ( i.schd )  &&  ...
        any ( dterm < vp.min  |  vp.max < dterm ) )  ||  ...
      ( mm ( 1 ) < vp.min  ||  vp.max < mm ( 2 ) )
    
    error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
            'line %d , var %s , %s support exceeds range of vpar %s' ] ,...
            fn , vline , vname , dname , vp.name )
    
  end
  
end % checkdist


function  task = ...
  tasdec ( tnam , tlnam , tok , lin , logic , vpar , fn , VALNAM , MC )
  
  
  %%% CONSTANTS %%%
  
  % Task declaration keywords
  K.W = { 'link' , 'sevent' , 'mevent' , 'def' } ;
  K.LINK = 1 ;  K.SEVENT = 2 ;  K.MEVENT = 3 ;  K.DEF = 4 ;
  
  % MET signal names
  METSIG = MC.SIG ( : , 1 ) ;
  
  % Min and Max MET signal cargo values , up to at least v01.00.00
  MMCARG = [ 0 , intmax( 'uint16' ) ] ;
  
  % def statement type keywords
  K.TYPE = { 'stim' , 'state' } ;
  K.STIM = 1 ;  K.STATE = 2 ;
  
  
  %%% Output struct %%%
  
  task = { 'logic' , 'link' , 'def' , 'sevent' , 'mevent' ;
              tlnam ,     [] ,    [] ,       [] ,       [] } ;
  task = struct ( task{ : } ) ;
  
  
  %%% Group tokens %%%
  
  [ tg , lg ] = grpsplit ( K.W , tok , lin , fn ) ;
  
  % Got at least one link statement
  if  isempty ( tg{ K.LINK } )
    
    error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
      'task %s declaration , no link statements' ] , fn , tnam )
    
  end
  
  
  %%% Parse link statements %%%
  
  for  i = 1 : numel ( tg{ K.LINK } )
    
    % Tokens and line numbers
    t = tg{ K.LINK }{ i } ;
    l = lg{ K.LINK }{ i } ;
    
    % Check min and max number of terms
    n = numel ( t ) ;
    
    if  n < 2  ||  3 < n
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , link statement needs 2 or 3 terms' ] , fn , l( 1 ) )
      
    end
    
    % Correct form , no repeat check
    checkform ( t , l , 1 , 'link term' , fn , VALNAM )
    
    % Check that link name is unique
    if  isfield ( task.link , t{ 1 } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , link %s already defined' ] , fn , l( 1 ) , t{ 1 } )
      
    end
    
    % Check task stim
    if  ~any ( strcmp ( t{ end - 1 } , logic.nstim ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , link %s , task stim %s unrecognised' ] , ...
        fn , l( end - 1 ) , t{ 1 } , t{ end - 1 } )
      
    end
    
    % Check stim def
    if  ~isfield ( vpar , t{ end } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , link %s , stim def %s not in ./stim' ] , ...
        fn , l( end ) , t{ 1 } , t{ end } )
      
    end
    
    % Pack link statement
    task.link.( t{ 1 } ) = struct ( 'stim' , t{ end - 1 } , ...
                                     'def' , t{ end     } ) ;
    
  end % link statements
  
  
  %%% Parse sevent statements %%%
  
  for  i = 1 : numel ( tg{ K.SEVENT } )
    
    % Tokens and line numbers
    t = tg{ K.SEVENT }{ i } ;
    l = lg{ K.SEVENT }{ i } ;
    
    % Check min and max number of terms
    n = numel ( t ) ;
    
    if  n < 4  ||  5 < n
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , sevent statement needs 4 or 5 terms' ] , fn , l( 1 ) )
      
    end
    
    % A name was provided
    ni = n  ==  5 ;
    
    % Check form of string terms
    j = 1 : 3 + ni ;
    checkform ( t( j ) , l( j ) , 1 , 'sevent term' , fn , VALNAM )
    
    % sevent name already used
    if  isfield ( task.sevent , t{ 1 } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , sevent %s already defined' ] , fn , l( 1 ) , t{ 1 } )
      
    end
    
    % Check that task logic state exists
    if  ~any ( strcmp ( t{ ni + 1 } , logic.nstate ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , sevent %s , task logic %s has no state %s' ] , ...
        fn , l( ni + 1 ) , t{ 1 } , tlnam , t{ ni + 1 } )
      
    end
    
    % Check that link is defined
    if  ~isfield ( task.link , t{ ni + 2 } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , sevent %s , no link %s' ] , ...
        fn , l( ni + 2 ) , t{ 1 } , t{ ni + 2 } )
      
    end
    
    % Check variable parameter name
    n = task.link.( t{ ni + 2 } ).def ;
    j = strcmp ( t{ ni + 3 } , vpar.( n )( : , 1 ) ) ;
    
    if  ~any ( j )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , sevent %s , stim def %s has no vpar %s' ] , ...
        fn , l( ni + 3 ) , t{ 1 } , n , t{ ni + 3 } )
      
    end
    
    n = vpar.( n )( j , : ) ;
    
    % Default value
    v = str2double ( t{ ni + 4 } ) ;
    
    vparcheck ( n , v , ...
      fn , l( ni + 4 ) , 'sevent' , t{ 1 } , t{ ni + 4 } )
    
    % Pack sevent
    task.sevent.( t{ 1 } ) = struct ( 'state' , t{ ni + 1 } , ...
      'link' , t{ ni + 2 } , 'vpar' , t{ ni + 3 } , 'value' , v ) ;
    
  end % sevent statements
  
  
  %%% Parse mevent statements %%%
  
  for  i = 1 : numel ( tg{ K.MEVENT } )
    
    % Tokens and line numbers
    t = tg{ K.MEVENT }{ i } ;
    l = lg{ K.MEVENT }{ i } ;
    
    % Check min and max number of terms
    n = numel ( t ) ;
    
    if  n < 3  ||  4 < n
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , mevent statement needs 3 or 4 terms' ] , fn , l( 1 ) )
      
    end
    
    % A name was provided
    ni = n  ==  4 ;
    
    % Check form of string terms
    j = 1 : 2 + ni ;
    checkform ( t( j ) , l( j ) , 1 , 'mevent term' , fn , VALNAM )
    
    % mevent name already used
    if  isfield ( task.mevent , t{ 1 } )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , mevent %s already defined' ] , fn , l( 1 ) , t{ 1 } )
      
    end
    
    % Check that task logic state exists
    if  ~any ( strcmp ( t{ ni + 1 } , logic.nstate ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , mevent %s , task logic %s has no state %s' ] , ...
        fn , l( ni + 1 ) , t{ 1 } , tlnam , t{ ni + 1 } )
      
    end
    
    % Check MET signal name
    if  ~any ( strcmp ( t{ ni + 2 } , METSIG ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , mevent %s , no MET signal %s' ] , ...
        fn , l( ni + 2 ) , t{ 1 } , t{ ni + 2 } )
      
    end
    
    % Default value
    v = str2double ( t{ ni + 3 } ) ;
    
    if  isnan ( v )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , mevent %s , cargo not valid number %s' ] , ...
        fn , l( ni + 3 ) , t{ 1 } , t{ ni + 3 } )
      
    end
    
    % Invalid cargo
    if  v < MMCARG( 1 )  ||  MMCARG( 2 ) < v  ||  mod ( v , 1 )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , mevent %s , invalid cargo %s' ] , ...
        fn , l( ni + 3 ) , t{ 1 } , t{ ni + 3 } )
      
    end
    
    % Pack sevent
    task.mevent.( t{ 1 } ) = struct ( 'state' , t{ ni + 1 } , ...
      'msignal' , t{ ni + 2 } , 'cargo' , v ) ;
    
  end % mevent statements
  
  
  %%% Parse def statements %%%
  
  n = numel ( tg{ K.DEF } ) ;
  
  % Pre-allocate .def if there are any def statements
  if  n
    
    v = cell ( 2 , 4 ) ;
    v( 1 , : ) = { 'type' , 'name' , 'vpar' , 'value' } ;
    
    task.def = repmat (  struct ( v{ : } )  ,  n  ,  1  ) ;
    
  end % pralloc
  
  % def statements
  for  i = 1 : n
    
    % Tokens and line numbers
    t = tg{ K.DEF }{ i } ;
    l = lg{ K.DEF }{ i } ;
    
    % Check min and max number of terms
    n = numel ( t ) ;
    
    if  n  ~=  4
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , def statement needs 4 terms' ] , fn , l( 1 ) )
      
    end
    
    % Check form of string terms
    j = 1 : 3 ;
    checkform ( t( j ) , l( j ) , 1 , 'def term' , fn , VALNAM )
    
    % Is type a recognised keyword?
    if  ~any ( strcmp ( t{ 1 } , K.TYPE ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , def statement , unrecognised type %s' ] , ...
        fn , l( 1 ) , t{ 1 } )
      
    end
    
    % Type is 'stim'
    ni = strcmp ( t{ 1 } , K.TYPE{ K.STIM } ) ;
    
    if  ni
      
      % link names
      n = fieldnames ( task.link ) ;
      
    % Type is 'state'
    else
      
      % State names
      n = logic.nstate ;
      
    end
    
    % Check that name exists
    if  ~any ( strcmp ( t{ 2 } , n ) )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , def statement , type %s , unrecognised name %s' ] , ...
        fn , l( 1 ) , t{ 1 } , t{ 2 } )
      
    end
    
    % Variable parameter list
    if  ni
      
      n = task.link.( t{ 2 } ).def ;
      n = vpar.( n ) ;
      
    else
      
      n = { 'timeout' } ;
      
    end
    
    % Check that variable parameter exists
    j = strcmp ( t{ 3 } , n( : , 1 ) ) ;
    
    if  ~any ( j )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , def statement , type %s , unrecognised vpar %s' ] , ...
        fn , l( 1 ) , t{ 1 } , t{ 3 } )
      
    end
    
    % Default value
    v = str2double ( t{ 4 } ) ;
    
    if  isnan ( v )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , def statement , type %s , not a number %s' ] , ...
        fn , l( 1 ) , t{ 1 } , t{ 4 } )
      
    end
    
    % Check default value ranges
    if  ni
      
      % 'stim' type
      vparcheck ( n( j , : ) , v , fn , l( 1 ) , 'def' , t{ 1 } , t{ 4 } )
      
    % 'state' type , check timeout values
    elseif  v < 0  ||  ~isreal ( v )  ||  isinf ( v )
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , def statement , type %s , invalid timeout %s' ] , ...
        fn , l( 1 ) , t{ 1 } , t{ 4 } )
      
    elseif  any ( strcmp ( t{ 3 } , MC.OUT( : , 1 ) ) )  &&  v
      
      error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
        'line %d , def statement , type %s , ' , ...
        'non-zero timeout for end state' ] , ...
        fn , l( 1 ) , t{ 1 } , t{ 4 } )
      
    end
    
    % Pack data
    task.def( i ).type  = t{ 1 } ;
    task.def( i ).name  = t{ 2 } ;
    task.def( i ).vpar  = t{ 3 } ;
    task.def( i ).value = v ;
    
  end % def statements
  
  
end % tasdec


function  vparcheck ( vp , v , fn , l , kw , kws , vs )
  
  if  any ( isnan ( v )  |  ~isreal ( v ) )

    error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
      'line %d , %s %s , not valid number %s' ] , ...
      fn , l , kw , kws , vs )

  end

  % Value is the right type
  if  vp{ 2 }  ==  'i'  &&  any ( mod ( v , 1 ) )

    error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
      'line %d , %s %s , %s not integer' ] , ...
      fn , l , kw , kws , vs )

  end

  % Value in range
  if  any ( v < vp{ 4 }  |  vp{ 5 } < v )

    error ( 'MET:metparse:schedule' , [ 'metparse: file %s , ' , ...
      'line %d , %s %s , %s out of range' ] , ...
      fn , l , kw , kws , vs )

  end
  
end % vparcheck


function  [ n , s ] = tsklogic ( t , l , fn , MC , VALNAM )
  
  
  %%% Constants %%%
  
  % Keywords that separate different sections of a task logic file
  KEYWRD = { 'name' , 'calibration' , 'stim' , 'state' , 'edge' } ;
  
  % Keyword indeces , for symbolic reference
  KNAME = 1 ;  KCAL = 2 ;  KSTIM = 3 ;  KSTAT = 4 ;  KEDGE = 5 ;
  
  % Mandatory sections
  MSECTS = [ 0 , 0 , 1 , 1 , 1 ] ;
  
  % Output struct fields
  OSFNAM = { 'calibration' , 'N' , 'nstate' , 'istate' , 'nstim' , ...
    'istim' , 'stim' , 'T' , 'E' } ;
  OSFNAM = [ OSFNAM ; cell( size ( OSFNAM ) ) ] ;
  
  % Mandatory task stimulus
  MTSTIM = 'none' ;
  
  % Mandatory first state
  MSTART = 'start' ;
  
  % Mandatory end states must be last in the state definition list
  MESTAT = MC.OUT( 1 : 4 , 1 ) ;
  
  % State parse key word
  SPKWRD = 'all' ;
  
  % Minimum number of tokens required to define a state transition. Name of
  % target state, timeout flag, and task stimulus.
  STRMIN = 3 ;
  
  % Number of timeout phases
  NTOPHZ = 2 ;
  
  % Running phase
  IRUNPH = 1 ;
  
  % Timed out
  ITMOUT = 2 ;
  
  % Default transitions on timeout , start to ignored , rest to broken
  DTS2TO = 'ignored' ;
  DTA2BK =  'broken' ;
  
  % Edge keywords and the phase of a state they affect. R-unning ,
  % T-imeout, and B-oth running and timeout.
  EDGEKW = { 'R' , 'T' , 'B' } ;
  EDGEPH = {  IRUNPH  ,  ITMOUT  ,  [ IRUNPH , ITMOUT ]  } ;
  
  
  %%% Output structure %%%
  
  s = struct ( OSFNAM{ : } ) ;
  s.N = struct ( 'state' , [] , 'stim' , [] ) ;
  
  
  %%% Parse task logic %%%
  
  % Separate out groups of tokens denoting sections of file
  [ tg , lg ] = grpsplit ( KEYWRD , t , l , fn ) ;
  
  % Check each section
  for  i = 1 : numel ( KEYWRD )
    
    j = numel ( tg{ i } ) ;
    
    % No section of this kind
    if  ~j
      
      % But it was mandatory
      if  MSECTS( i )
        error ( 'MET:metparse:tsklogic' , ...
          'metparse: file %s missing section %s' , fn , KEYWRD{ i } )
      end
      
    % Too many
    elseif  1  <  j
      
      error ( 'MET:metparse:tsklogic' , ...
        'metparse: file %s , line %d , more than one %s section' , ...
        fn , lg{ i }{ 2 }( 1 ) , KEYWRD{ i } )
      
    else

      % Collapse to a single cell array layer
      tg{ i } = tg{ i }{ 1 } ;
      lg{ i } = lg{ i }{ 1 } ;

    end
    
  end % sections
  
  
  %%% Get task name  %%%
  
  % Was a name provided?
  if  isempty ( tg{ KNAME } )
    
    % No , use file name , no suffix
    [ ~ , n ] = fileparts ( fn ) ;
    tg{ KNAME } = { n } ;
    lg{ KNAME } = NaN ;
    
  end
  
  % Yes , validate and return
  n = scalartoken ( tg{ KNAME } , lg{ KNAME } , ...
    fn , KEYWRD{ KNAME } , VALNAM ) ;
  
  
  %%% Get calibration mode %%%
  
  % Was this provided?
  if  isempty ( tg{ KCAL } )
    
    % No , return empty
    s.calibration = '' ;
    
  else
    
    % Yes , validate and return
    s.calibration = scalartoken ( tg{ KCAL } , lg{ KCAL } , ...
      fn , KEYWRD{ KCAL } , VALNAM ) ;
    
  end
  
  
  %%% Get list of task stimuli %%%
  
  % Check and retrieve single list of states
  s.nstim = tg{ KSTIM } ;
  
  % Proper form and no repeats
  checkform( s.nstim , lg{ KSTIM } , 3 , KEYWRD{ KSTIM } , fn , VALNAM )
  
  % No reserved words
  i = ismember ( s.nstim , [ SPKWRD , EDGEKW ] ) ;
  i = find ( i , 1 , 'first' ) ;
  
  if  i
    
    error ( 'MET:metparse:tsklogic' , ...
      'metparse: file %s , line %d , %s is a reserved word' , ...
      fn , lg{ KSTIM }( i ) , s.nstim{ i } )
    
  end
  
  % Check for 'none' , it should be at top
  i = find ( strcmp ( s.nstim , MTSTIM ) , 1 ) ;
  
  if  isempty ( i )
    
    % None not listed , add it
    s.nstim = [ MTSTIM  ,  s.nstim ] ;
    
  elseif  1  <  i
    
    error ( 'MET:metparse:tsklogic' , ...
      'metparse: file %s , line %d , %s must be first task stimulus' , ...
      fn , lg{ KSTIM }( i ) , MTSTIM )
    
  end
  
  % Number of task stimuli
  s.N.stim = numel ( s.nstim ) ;
  
  % Make task stimulus index map
  i = [ s.nstim  ;  num2cell( 1 : numel ( s.nstim ) ) ] ;
  s.istim = struct ( i{ : } ) ;
  
  
  %%% Get list of task states %%%
  
  % Check and retrieve single list of states
  lstat = tg{ KSTAT } ;
  
  % Determine which tokens name task stimuli or keywords , is-task-stim and
  % task-stim-index
  [ its , tsi ] = ismember ( lstat , [ s.nstim , SPKWRD ] ) ;
  
  % Find state name and timeout index pairs
  i = find ( ~its ) ;
  isn = i ( 1 : 2 : end ) ;
  
  % Check state name form , no repeats allowed
  checkform ( lstat( isn ) , lg{ KSTAT }( isn ) , 3 , KEYWRD{ KSTAT } , ...
    fn , VALNAM )
  
  % Check for start state
  if  ~strcmp ( MSTART , lstat{ isn( 1 ) } )
    error ( 'MET:metparse:tsklogic' , ...
      'metparse: file %s , line %d , first state %s not %s' , ...
      fn , lg{ KSTAT }( isn( 1 ) ) , lstat{ isn( 1 ) } , MSTART )
  end
  
  % Name of each state , and number of states
  s.nstate = lstat( isn ) ;
  s.N.state = numel ( s.nstate ) ;
  
  % Indexes for each state name
  i = [ s.nstate  ;  num2cell( 1 : numel ( s.nstate ) ) ] ;
  s.istate = struct ( i{ : } ) ;
  
  % Timeout durations
  s.T = str2double ( lstat( isn + 1 ) ) ;
  
  % Check a number given for all timeouts
  i = find (  isnan ( s.T )  |  isinf ( s.T )  |  ~isreal ( s.T ) , ...
    1 , 'first' ) ;
  
  if  i
    j = isn( i ) + 1 ;
    error ( 'MET:metparse:tsklogic' , ...
      'metparse: file %s , line %d , not a valid timout value %s' , ...
      fn , lg{ KSTAT }( j ) , lstat{ j } )
  end
  
  % Check no timeout less than zero
  i = find ( s.T  <  0 , 1 , 'first' ) ;
  if  i
    j = isn( i ) + 1 ;
    error ( 'MET:metparse:tsklogic' , ...
      'metparse: file %s , line %d , timout %s < 0' , ...
      fn , lg{ KSTAT }( j ) , lstat{ j } )
  end
  
  % Find the end index of each state definition token group
  esd = [ isn( 2 : end ) - 1  ,  numel( lstat ) ] ;
  
  % Build task stimulus lists per state
  for  i = 1 : s.N.state
    
    % State name
    sn = s.nstate{ i } ;
    
    % Grab task stim indeces , and keep only non-zeros
    j = tsi ( isn( i ) : esd( i ) ) ;
    s.stim.( sn ) = j( its( isn( i ) : esd( i ) ) ) ;
    
    % Look for 'all' keyword , this was the last value during member search
    j = find ( s.stim.( sn )  ==  s.N.stim + 1 ) ;
    if  j
      
      % 'all' found but other stim names also listed
      if  1  <  numel ( s.stim.( sn ) )
        j = isn ( i )  +  sum ( ~its( isn( i ) : esd( i ) ) ) ;
        error ( 'MET:metparse:tsklogic' , ...
          [ 'metparse: file %s , line %d , %s state definition , ' , ...
                                   '%s given but other stim listed' ] , ...
          fn , lg{ KSTAT }( j ) , sn , SPKWRD )
      end
      
      % Add all task stim indeces
      s.stim.( sn ) = 1 : s.N.stim ;
    
    % Empty list
    elseif  isempty ( s.stim.( sn ) )
      
      error ( 'MET:metparse:tsklogic' , ...
        [ 'metparse: file %s , line %d , ' , ...
                               '%s state definition , no stim list' ] , ...
        fn , lg{ KSTAT }( isn( i ) ) , sn )
      
    % Repeats in the list
    elseif  numel ( unique ( s.stim.( sn ) ) )  <  numel ( s.stim.( sn ) )
      
      error ( 'MET:metparse:tsklogic' , ...
        [ 'metparse: file %s , line %d , ' , ...
                        '%s state definition , repeated stim names' ] , ...
        fn , lg{ KSTAT }( isn( i ) ) , sn )
      
    % Check for stim 'none'
    elseif  ~any ( s.stim.( sn )  ==  s.istim.( MTSTIM ) )
      
      % Not there , add to head
      s.stim.( sn ) = [ s.istim.( MTSTIM )  ,  s.stim.( sn ) ] ;
      
    end
    
  end % stim lists
  
  % Look for end states , index with end-state , end-state-index
  [ ies , esi ] = ismember ( s.nstate , MESTAT ) ;
  
  % Linear index
  ies = find ( ies ) ;
  esi = esi ( ies ) ;
  
  % Number of stimuli in list , should be just 1 i.e. 'none'
  i = cellfun ( @( i )  numel ( s.stim.( s.nstate{ i } ) ) , ...
    num2cell ( ies ) ) ;
  
  j = ies ( find ( 1  <  i , 1 , 'first' ) ) ;
  if  j
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , ' , ...
                               'end state %s can only show stim %s' ] , ...
      fn , lg{ KSTAT }( isn( j ) ) , s.nstate{ j } , MTSTIM )
  end
  
  % Timeout must be zero
  j = ies ( find ( s.T( ies ) ~= 0 , 1 , 'first' ) ) ;
  if  j
    error ( 'MET:metparse:tsklogic' , ...
      'metparse: file %s , line %d , end state %s timeout must be 0' , ...
      fn , lg{ KSTAT }( isn( j ) ) , s.nstate{ j } )
  end
  
  % Are end states the last in the list
  j = ( -numel ( ies ) + 1 : 0 ) + numel ( s.nstate )  ~=  ies ;
  
  % And are end states in order?
  j = j  |  [ false , diff( esi )  <  1 ] ;
  
  % Test these cases
  j = find ( j , 1 , 'first' ) ;
  if  j
    i = ies ( j ) ;
    esi = tiedrank ( esi ) ;
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , ' , ...
                    'end state %s must be %d to last defined state' ] , ...
      fn , lg{ KSTAT }( isn( i ) ) , s.nstate{ i } , ...
      numel ( esi ) - esi ( j ) )
  end
  
  % Missing end states
  if  numel ( ies )  <  numel ( MESTAT )
    
    % State name index up to but not including first end state
    if  ies
      
      i = 1 : ies( 1 ) - 1 ;
      
    else
      
      % No end states defined , so go to end of state list
      i = 1 : s.N.state ;
      
    end
    
    % Append end state names
    s.nstate = [ s.nstate( i )  ,  MESTAT' ] ;
    s.N.state = numel ( s.nstate ) ;
    
    % And timeouts
    s.T = [ s.T( i ) , zeros( 1 , numel ( MESTAT ) ) ] ;
    
    % Remove old end state indeces and task stimuli
    s.istate = rmfield ( s.istate , MESTAT( esi ) ) ;
      s.stim = rmfield (   s.stim , MESTAT( esi ) ) ;
    
    % Add end state indeces and task stimuli
    i = s.N.state  -  numel ( MESTAT ) ;
    
    for  j = 1 : numel ( MESTAT )
      
      s.istate.( MESTAT{ j } ) = i + j ;
        s.stim.( MESTAT{ j } ) = s.istim.( MTSTIM ) ;
      
    end
    
  end % missing states
  
  
  %%% Get state transitions %%%
  
  % Initialise an edge matrix
  s.E = zeros ( s.N.state , s.N.stim , NTOPHZ ) ;
  
  % Add default timout actions , start state to ignored , rest to broken
  i = false ( s.N.state , 1 ) ;
  i( s.istate.( MSTART ) ) = 1 ;
  s.E(  i , : , ITMOUT ) = s.istate.( DTS2TO ) ;
  s.E( ~i , : , ITMOUT ) = s.istate.( DTA2BK ) ;
  
  % Get edge token and line-number groups
  edge = tg{ KEDGE } ;
  elng = lg{ KEDGE } ;
  
  % Locate state names , stim names (and 'all' keyword) , and timeout flags
  [ stat , istat ] = ismember ( edge , s.nstate ) ;
  [ stim , istim ] = ismember ( edge , [ s.nstim , SPKWRD ] ) ;
  [ tofl , itofl ] = ismember ( edge ,   EDGEKW ) ;
  
  % Any unrecognised tokens?
  i = find ( ~( stat | stim | tofl ) , 1 , 'first' ) ;
  
  if  i
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , ' , ...
                              'state transitions , unrecognised %s' ] , ...
      fn , elng( i ) , edge{ i } )
  end
  
  % Is first token a state name?
  if  ~stat ( 1 )
    
    error ( 'MET:metparse:tsklogic' , ...
      'metparse: file %s , line %d , state name expected after %s' , ...
      fn , elng( 1 ) , KEYWRD{ KEDGE } )
    
  end
  
  % Is last or penultimate token a state name?
  i = find ( stat ( end - 1 : end ) , 1 , 'first' ) ;
  
  if  i
    
    error ( 'MET:metparse:tsklogic' , ...
      'metparse: file %s , line %d , hanging transition statement' , ...
      fn , elng( end - 2 + i ) )
    
  end
  
  % Find the current state , the one we transition from. This must be
  % followed by a transition statement that starts with another state name.
  cstat = [ stat( 1 : end - 1 )  &  stat( 2 : end )  ,  false ] ;
  
  % No current states given
  if  ~any ( cstat )
    
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , ' , ...
                 'no state name identified as being current state' ] , ...
      fn , elng( 1 ) )
    
  end
  
  % Start and end index of tokens for each set of state transitions
  icstat = repmat ( find ( cstat ) , 2 , 1 ) ;
  icstat ( 2 , 1 : end - 1 ) = icstat ( 2 , 2 : end ) - 1 ;
  icstat ( end ) = numel ( stat ) ;
  
  % There must be enough tokens separating every named current state to
  % define a transition
  i = diff ( icstat )  <  STRMIN ;
  i = icstat ( 1 , i ) ;
  
  if  i
    
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , ' , ...
        'part transition defined on current state %s' ] , ...
      fn , elng( i( 1 ) ) , edge{ i( 1 ) } )
    
  end
  
  % Any end states?
  i = ismember ( s.nstate( istat ( cstat ) ) , MESTAT ) ;
  i = icstat ( 1 , i ) ;
  
  if  i
    
    error ( 'MET:metparse:tsklogic' , ...
      'metparse: file %s , line %d , no transitions on end state %s' , ...
      fn , elng( i( 1 ) ) , edge{ i( 1 ) } )
    
  end
  
  % Now find target states , the ones we transition to. These must not be
  % followed by another state name.
  tstat = [ stat( 1 : end - 1 )  &  ~stat( 2 : end )  ,  false ] ;

% Technically not possible because of hanging trans. statement check, above
%
%   if  ~any ( tstat )
%     
%     error ( 'MET:metparse:tsklogic' , ...
%       [ 'metparse: file %s , line %d , ' , ...
%         'no transition statements identified' ] , fn , elng( 1 ) )
%     
%   end
  
  % Start and end index of tokens for each transition
  itstat = repmat ( find ( tstat ) , 2 , 1 ) ;
  i = itstat( 2 , 2 : end )  -  1 ;
  itstat( 2 , : ) = [ i  -  cstat( i )  ,  numel( stat ) ] ;
  
  % There must be enough tokens separating every named target state to
  % define a transition
  i = diff ( itstat )  <  STRMIN - 1 ;
  i = itstat ( 1 , i ) ;
  
  if  i
    
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , ' , ...
        'incomplete transition targeting state %s' ] , ...
      fn , elng( i( 1 ) ) , edge{ i( 1 ) } )
    
  end
  
  % Does every state transition have a timeout phase i.e. running,
  % timed-out, or both?
  i = find ( tstat ( 1 : end - 1 )  &  ~tofl ( 2 : end ) , 1 , 'first' ) ;
  
  if  i
    
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , ' , ...
        'no timeout flag after target state %s' ] , ...
      fn , elng( i ) , edge{ i } )
    
  end
  
  % Does every state transition have at least one stimulus or keyword?
  i = find ( tstat ( 1 : end - 2 )  &  ~stim ( 3 : end ) , 1 , 'first' ) ;
  
  if  i
    
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , target state %s , ' , ...
        'stim name or ''all'' expected after timeout flag' ] , ...
      fn , elng( i ) , edge{ i } )
    
  end
  
  % Find start of each stimulus list
  sstim = itstat ( 1 , : ) + 2 ;
  
  % Is every token from start of stim list to end of transition statement a
  % stim name or keyword?
  C = { num2cell( sstim ) , num2cell( itstat( 2 , : ) ) } ;
  i = cellfun ( @( a , b )  ~all ( stim ( a : b ) ) , C{ : } ) ;
  i = itstat ( 1 , i ) ;
  
  if  i
    
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , target state %s , ' , ...
        'unrecognised stim name' ] , ...
      fn , elng( i( 1 ) ) , edge{ i( 1 ) } )
    
  end
  
  % Is 'all' keyword the only token in stim list?
  i = cellfun ( ...
    @( a , b )  1 <= b - a  &&  any ( s.N.stim  <  istim( a : b ) ) , ...
    C{ : } ) ;
  i = itstat ( 1 , i ) ;
  
  if  i
    
    error ( 'MET:metparse:tsklogic' , ...
      [ 'metparse: file %s , line %d , target state %s , ' , ...
        'stim list can have ''%s'' or stim names' ] , ...
      fn , elng( i( 1 ) ) , edge{ i( 1 ) } , SPKWRD )
    
  end
  
  % Locate transition statements belonging to each current state
  I = cellfun ( ...
    @( a , b )  a < itstat( 1 , : )  &  itstat( 1 , : ) <= b , ...
    num2cell ( icstat( 1 , : ) ) , num2cell ( icstat ( 2 , : ) ) , ...
    'UniformOutput' , false ) ;
  
  % Loop current state , handle each of their transitions
  for  i = 1 : size ( icstat , 2 )
    
    % Current state's index
    c = istat ( icstat ( 1 , i ) ) ;
    
    % Target state indeces
    j = itstat ( 1 , I{ i } ) ;
    t = istat ( j ) ;
    
    % Timeout flag indeces
    to = itofl ( j + 1 ) ;
     
    % Stim lists , heads and tails
    sl = [ sstim( I{ i } )  ;  itstat( 2 , I{ i } ) ] ;
    
    % Loop transition statements
    for  j = 1 : numel ( t )
      
      % Timeout phase indeces
      toi = EDGEPH{ to ( j ) } ;
      
      % Stimulus indeces
      sti = istim ( sl ( 1 , j )  :  sl ( 2 , j ) ) ;
      
      % 'all' keyword
      if  sti  ==  s.N.stim + 1
        
        sti = 1 : s.N.stim ;
        
      end
      
      % Apply transition to edge matrix
      s.E ( c , sti , toi ) = t( j ) ;
      
    end % transitions
    
  end % source states
  
  
end % tsklogic


function  checkform ( tg , lg , flg , type , fn , VALNAM )
% 
% flg: 1 - form check only , 2 - repeat check only , 3 - check both
% 
  
  % Check for proper form
  if  flg  ~=  2
    
    i = cellfun ( @isempty , regexp ( tg , VALNAM ) ) ;

    if  any ( i )

      i = find ( i ) ;

      error ( 'MET:metparse:checkform' , ...
        'metparse: file %s , line %d , invalid %s %s' , ...
          fn , lg( i( 1 ) ) , type , tg{ i( 1 ) } )

    end
  
  end % form
  
  
  % Check for repeats
  if  flg ~= 1  &&  numel ( unique ( tg ) ) ~= numel ( tg )

    error ( 'MET:metparse:checkform' , [ 'metparse: file %s , ' , ...
      'line %d , repeats found in %s list' ] , ...
        fn , lg( 1 ) , type )

  end % repeats
  
  
end % checkform


function  s = scalartoken ( tg , lg , fn , KEYWRD , VALNAM )
% 
% A single token is expected i.e. a scalar token. Check that there is just
% one , and that it has good form. Then return it.
% 
  
  if  1  <  numel ( tg )
    
    % Too many given
    error ( 'MET:metparse:scalartoken' , ...
      'metparse: file %s , line %d , too many %s statements' , ...
        fn , lg( 2 ) , tg{ 2 } )
    
  elseif  isempty ( regexp ( tg{ 1 } , VALNAM , 'once' ) )
    
    % Invalid format
    error ( 'MET:metparse:scalartoken' , ...
      'metparse: file %s , line %d , invalid %s %s' , ...
        fn , lg( 1 ) , KEYWRD , tg{ 1 } )
    
  end
    
  % Return scalar token
  s = tg{ 1 } ;
  
end % scalartoken


function  [ tg , lg ] = grpsplit ( g , t , l , fn )
% 
% Group-split. Keywords are provided in cell array g. These are used to
% group together and split appart contiguous sets of tokens. The rule is
% that a set starts at the first token following a keyword and carries on
% until the first token prior to the next keyword, or the end. Grouped
% tokens are returned in tg, which has an element for each value of g ;
% this is another cell array, in turn, and each element contains a grouped
% set of tokens. Line numbers are packed accordingly in lg. If a keyword is
% never encountered, then it's corresponding elements in tg and lg will be
% empty. File name fn for error messages.
% 
  
  % Allocate output
  tg = cell ( size ( g ) ) ;
  lg = cell ( size ( g ) ) ;
  
  % Locate keywords , collapse to linear index vectors
  [ ti , gi ] = ismember ( t , g ) ;
  ti = find ( ti ) ;
  gi =   gi ( ti ) ;
  
  if  ~any ( ti )
    
    error ( 'MET:metparse:grpsplit' , ...
      'metparse: file %s , line %d , no recognised statement' , ...
      fn , l( 1 ) )
      
  end
  
  % Start and end of each group of tokens , excluding keywords
  s = ti + 1 ;
  e = [ ti( 2 : end ) - 1  ,  numel( t ) ] ;
  
  % Gather groups of tokens , grouped by keyword
  C = cell ( 4 , 1 ) ;
  C( 3 : 4 ) = {  'UniformOutput'  ,  false  } ;
  
  for  i = 1 : numel ( g )
    
    % Locate groups
    j =  gi == i  ;
    
    % No keywords of this kind
    if  ~any ( j )  ,  continue  ,  end
    
    % Start and end indeces of grouped tokens
    C( 1 : 2 ) = { num2cell( s( j ) ) , num2cell( e( j ) ) } ;
    
    % Gather token groups , and pack into cell array
    tg{ i } = cellfun ( @( a , b )  t( a : b ) , C{ : } ) ;
    lg{ i } = cellfun ( @( a , b )  l( a : b ) , C{ : } ) ;
    
  end % keywords
  
end % grpsplit


function  [ t , l ] = readtokens ( file , comchr , nlchar )
% 
% Reads in the specified file and returns cell t with an element for each
% token , containing the token string. The line number of each token is
% given in l at the same indexed position.
% 
  
  % Load file as one string
  t = fileread ( file ) ;
  
  if  isempty ( t )
    error ( 'MET:metparse:readtokens' , 'metparse: empty file %s' , fn )
  end
  
  % Make sure that there is a newline character at the end of the file
  nlval = sprintf ( nlchar ) ;
  
  if  t ( end )  ~=  nlval
    t ( end + 1 )  =  nlval ;
  end
  
  % Remove comments
  t = regexprep ( t , [ comchr , '.*?' , nlchar ] , nlchar ) ;
  
  % Split lines appart
  t = regexp ( t , [ '.*?' , nlchar ] , 'match' ) ;
  
  % Remove newline characters
  t = regexprep ( t , [ ' *' , nlchar ] , '' ) ;
  
  % Line numbers
  l = num2cell ( 1 : numel ( t ) ) ;
  
  % Remove empty lines
  i = ~cellfun ( @isempty , t ) ;
  l = l( i ) ;
  t = t( i ) ;
  
  % Grab tokens
  t = regexp ( t , '\S*' , 'match' ) ;
  
  % Repeat line numbers
  for  i = 1 : numel ( t )
    
    l{ i } = repmat ( l{ i } , 1 , numel ( t{ i } ) ) ;
    
  end
  
  % Concatenate sub-cells into one cell array
  l = [ l{ : } ] ;
  t = [ t{ : } ] ;
  
end % readtokens

