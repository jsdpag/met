
function  metcontroller ( cd , stodup , br , qw , varargin )
% 
% metcontroller ( cd , stodup , br , qw , varargin )
% 
% Each Matlab-based Matlab Electrophysiology Toolbox (MET) child controller
% runs metcontroller to initialise itself and run the controller function.
% It will catch errors that originate in the controller function, and
% ensure that the child controller exits.
% 
% All inputs are provided as command line strings, most need to be
% converted into numerical values.
% 
% cd - Controller descriptor unique to each MET child controller.
% stodup - Duplicate file descriptor of standard output, before
%   STDOUT_FILENO was mapped to the null device /dev/null. This was done to
%   ignore Matlab's preamble. The duplicate is used to restore standard
%   output to its rightful file descriptor.
% br , qw - Broadcast reading and request writing pipe file descriptors,
%   for receiving and sending MET signals.
%
% The remainder of arguments can vary in number, hence they are passed
% through varargin.
%
% POSIX shared memory arguments come next, in groups. The arguments within
% a group refer to one specific POSIX shared memory. The format of each
% group depends on the access rights that this MET child controller will
% have, which is given by the first argument in each group. This is a
% single character flag with a value of 'c' closed, 'r' read, 'w' write, or
% 'b' read and write. No arguments follow 'c'. The readers' event fd and
% this MET controller's writer efd follow 'r'. 'w' and 'b' are both
% followed by the number of readers, the readers' efd, and then the list of
% writer's efds, one per reader. Shared memory argument groups are expected
% to come in this order by type: variable stimulus parameters (stim), eye
% position (eye), and Neural Signal Processor output (nsp).
% 
% The first argument after shared memory arguments must name the MET
% controller function that metcontroller will execute. Following that are
% any MET controller options. While these may include shared memory
% options, they may also request special resources. This includes iViewX
% (SMI) UDP communication (-ivxudp), Psych Toolbox digital output on a
% Measurement Computing USB-1208fs digital acquisition device (-ptbdaq),
% and NSP communication via the cbmex interface (-cbmex). [ The use of
% these flags will be deprecated ]
% 
% Special resources are obtained directly using matlab commands. But
% initialising and using the MET signal pipes or shared memory requires the
% met command interface. This returns a struct of MET constants.
% 
% Following initialisation, the MET controller function named by mctrlf is
% executed, and handed the struct of MET constants.
% 
% After the controller function returns, metcontroller will attempt to
% close any special resources, pipes, and shared memory, and exit.
% 
% If any error is caught, then an attempt is made to send a mquit MET
% signal on the request pipe, before proceeding with the usual shutdown.
% 
% 
% Written by Jackson Smith - DPAG , University of Oxford
% 
% 
  
  
  %%% Handle Mathworks bug report 914291 %%%
  
  % See link: https://uk.mathworks.com/matlabcentral/answers/
  %  114915-why-does-matlab-cause-my-cpu-to-spike-even-when-matlab-is-
  %  idle-in-matlab-8-0-r2012b
  % 
  % Matlab is known to have sudden spikes in cpu consumption. An excerpt
  % from Mathworks's answer is "Beginning in MATLAB R2012b, the Help
  % Browser uses a different renderer called the JxBrowser ... this may be
  % an issue with the JxBrowser, try disabling [it]"
  % 
  % Disable JxBrowser
%   com.mathworks.mlwidgets.html.HtmlComponentFactory.setDefaultType( ...
%     'HTMLRENDERER' ) ;
  
  
  %%% CONSTANTS %%%
  
  % Number of POSIX shared memory objects
  SHMARG = 3 ;
  
  % Shared mem open flag characters
  MSMG_CLOSED = 'c' ;
  MSMG_READ   = 'r' ;
  MSMG_WRITE  = 'w' ;
  MSMG_BOTH   = 'b' ;
  MSMG_ALL = [ MSMG_CLOSED , MSMG_READ , MSMG_WRITE , MSMG_BOTH ] ;
  
  % Shared mem arg group indeces relative to open flag
  MSM_FLG = 1 ;
  
    % For use by readers, and only readers, of shared memory
    MSMR_REFD = 2 ;
    MSMR_WEFD = 3 ;
    
    % For use by writers, or readers and writers.
    MSMW_NUMR = 2 ;
    MSMW_REFD = 3 ;
    MSMW_WEFDV = 4 ;
  
  % Initialisation value of file descriptors
  FDINIT = -1 ;
  
  % MET controller options for special resources
  METRSC = { '-cbmex' , '-ivxudp' , '-ptbdaq' } ;
  
  
  %%% Check first descriptors %%%
  
  for  ARGV = { { cd , 'cd' } ;
                { stodup , 'stodup' } ;
                { br , 'br' } ;
                { qw , 'qw' } }' , A = ARGV{ 1 } ;
    
    if  ~isscalar ( A{ 1 } )  ||  ~isnumeric ( A{ 1 } )  ||  ...
        A{ 1 }  <  0  ||  mod ( A{ 1 } , 1 )
      
      fex ( sprintf ( [ 'metcontroller: arg %s is not scalar integer ' ...
        'of 0 or more' ] , A{ 2 } ) )
      
    end
    
  end % check first descriptors
  
  % Find char inputs
  c = find ( cellfun ( @ischar , varargin ) ) ;
  
  % Group broadcast and request pipe file descriptors
  pfd = [ br , qw ] ;
  
  
  %%% Find controller function  %%%
  
  % By definition, this will be the first argument following the shared
  % memory reading/writing flag and event fd groups. Make sure that there
  % is a single function name.
  
  f = c( cellfun ( @exist , varargin( c ) )  ==  2 ) ;
  
  if  ~isscalar ( f )
    fex ( spritnf ( ...
      'metcontroller:cd %d: could not find valid MET function name' , ...
      cd ) )
  end
  
  % MET controller function handle
  mcfh = str2func ( varargin{ f } ) ;
  
  
  %%% Isolate shared memory arguments and MET options %%%
  
  % Shared memory flags and event file descriptors , locate numeric args
  shmarg = varargin( 1 : f - 1 ) ;
  i = cellfun ( @isnumeric , shmarg ) ;
  nargs = cell2mat ( shmarg( i ) ) ;
  
  % Locate character args
  c = cellfun( @ischar , shmarg ) ;
  
  % MET options
  metopt = varargin( f + 1 : end ) ;
  
  % Error checking - numer of args
  if  numel ( shmarg )  <  SHMARG  ||  sum ( c )  ~=  SHMARG
    
    fex ( spritnf ( ...
      'metcontroller:cd %d: needs %d shared mem argument groups' , ...
      cd , SHMARG ) )
    
  % Not scalars
  elseif  any ( ~cellfun ( @isscalar , shmarg ) )
    
    fex ( spritnf ( ...
      'metcontroller:cd %d: non-scalar shared mem arguments' , cd ) )
    
  % Not char or numeric
  elseif  ~all ( c  |  i )
    
    fex ( spritnf ( ...
      'metcontroller:cd %d: shared mem argument not char or numeric' , ...
      cd ) )
    
  % Numeric arent integers of FDINIT or more
  elseif  numel ( nargs )  &&  any ( mod( nargs , 1 )  |  nargs < FDINIT )
    
    fex ( spritnf ( ...
      'metcontroller:cd %d: shared mem bad file descriptor' , cd ) )
    
  end % err check
  
  
  %%% Group shared memory args by shared memory object %%%
  
  % Linear indeces
  c = find ( c ) ;
  
  % Number of elements in each group
  c = [ c( 2 : end ) , numel( shmarg ) + 1 ]  -  c ;
  
  % Linear index vectors , one per shared mem arg group
  c = mat2cell ( 1 : numel ( shmarg ) , 1 , c ) ;
  
  % Group shared mem args
  shmarg = cellfun ( @( i ) shmarg( i ) , c , 'UniformOutput' , false ) ;
  
  
  %%% Prep POSIX shared memory args for met 'open' %%%
  
  % Opening flags
  shmflg = cellfun ( @( C ) C{ MSM_FLG } , shmarg ) ;
  
  % Compare flags against valid values
  c = unique ( shmflg ) ;
  
  if  numel ( c )  ~=  numel ( intersect ( c , MSMG_ALL ) )
    
    fex ( spritnf ( ...
      'metcontroller:cd %d: unrecognised shared mem flag' , cd ) )
    
  end
  
  % Number of readers
  shmnr = zeros ( size ( shmarg ) ) ;
  
  % Readers' event file descriptors
   refd = FDINIT  *  ones ( size ( shmarg ) ) ;
  
  % Writer's event file descriptors , specific to this controller
   wefd = FDINIT  *  ones ( size ( shmarg ) ) ;
  
  % Writer's event file descriptors vector , if controller writes to shm
  wefdv =  cell ( size ( shmarg ) ) ;
  
  % Shared mem arg groups
  for  i = 1 : numel ( shmarg ) , A = shmarg{ i } ;
      
    % Shared mem not opened , go to next
    if  shmflg( i ) == MSMG_CLOSED , continue  , end
    
    % Pattern of argument group depends on whether controller reads,
    % writes, or both in shared mem.
    if  any ( shmflg( i )  ==  [ MSMG_WRITE , MSMG_BOTH ] )
    
      % MET controller writes , or reads and writes
      
      % Number of readers on this shared memory
      shmnr( i ) = A{ MSMW_NUMR } ;
      
      % Readers' event file descriptor , for this shm
      refd( i ) = A{ MSMW_REFD } ;
      
      % There is a writer's event fd group , one fd value per child
      % controller
      wefdv{ i } = cell2mat ( A( MSMW_WEFDV : end ) ) ;
      
      % This controller's own writer's event fd
      wefd( i ) = wefdv{ i }( cd ) ;
    
    elseif  shmflg( i )  ==  MSMG_READ
      
      % MET child controller is reader on this shared mem
      
      % Readers' event fd
      refd( i ) = A{ MSMR_REFD } ;
      
      % Writer's event fd , for this specific MET controller
      wefd( i ) = A{ MSMR_WEFD } ;
      
    else
      
      fex ( spritnf ( ...
      'metcontroller:cd %d: unrecognised shared mem flag' , cd ) )
      
    end
    
  end % shm groups
  
  % Error check contents of wefdv , if controller writes to shared mem
  i = shmflg  ==  MSMG_WRITE  |  shmflg  ==  MSMG_BOTH ;
  if  any ( i )
    
    % Number of elements in non-empty cell's elements.
    n = cellfun ( @numel , wefdv( i ) ) ;
    
    % Same numbers of elements in each writer's event fd list. Form list of
    % lengths. If they are the same then the unique function will return a
    % scalar value.
    if  ~isscalar ( unique ( n ) )
      
      fex ( sprintf ( [ 'metcontroller:cd %d: ' ... 
        'shared mem writer''s efd list length varies' ] , cd ) )
      
    end
    
    % Count the number of initialised writer's event fd's. This should be
    % identical to the number of readers passed in as an argument.
    n = cellfun ( @( C )  sum ( C  ~=  FDINIT ) , wefdv( i ) ) ;
    
    if  any ( shmnr( i )  ~=  n )
      
      fex ( sprintf ( [ 'metcontroller:cd %d: ' ... 
        'shared mem writer''s efd and reader counts disagree' ] , cd ) )
      
    end
    
  end % error check wefdv
  
  
  %%% Determine which special resources are requested %%%
  
  % Resource tracker, a struct with fields named after each MET controller
  % option (without '-'). Each field is 1 if that resource has been
  % requested, and 0 otherwise.
  metrsc = [ strrep( METRSC , '-' , '' ) ; cell( 1 , numel( METRSC ) ) ] ;
  
  for  i = 1 : numel ( METRSC )
    metrsc{ 2 , i } = false ;
  end
  
  metrsc = struct ( metrsc{ : } ) ;
  
  % Check input arguments
  ARGV = strrep ( intersect ( METRSC , metopt ) , '-' , '' ) ;
  
  % Set corresponding flags to 1
  for  i = 1 : numel ( ARGV )
    metrsc.( ARGV{ i } )( 1 ) = 1 ;
  end
  
  
  %%% Low-level PsychToolbox %%%
  
  % Remove some of the initial diagnostic verbosity from PsychToolbox
  PsychTweak (  'ScreenVerbosity'  ,  2  ) ;
  
  
  %%% Open met %%%
  
  % met
  try
    
    clearvars  -except  ...
      cd stodup pfd  shmflg shmnr refd wefd wefdv  metrsc mcfh
    MC = met ( 'open' , ...
               cd , stodup , pfd , ...
               shmflg , shmnr , refd , wefd , wefdv ) ;
    
  catch  E
    
    % Report error
    met ( 'print' , sprintf ( 'metcontroller:cd %d:%s' , ...
      cd , fullReport ( E ) ) , 'e' )
    
    % Attempt to close any open met resources
    met ( 'close' ) ;
    
    % Exit Matlab
    exit
    
  end % open met
  
  % Remove unnecessary variables
  clearvars  cd  stodup  pfd  shmflg  shmnr  refd  wefd  wefdv
  
  
  %%% Register cleanup object %%%
  
  % This variable will be cleared when metcontroller terminates, thus
  % triggering an attempt to close met, release special resources, and
  % terminate Matlab.
  
  cleanupObj = onCleanup ( @() close_resources ( metrsc ) ) ;
  
  
  %%% Inform user that MET controller has started %%%
  
  met (  'print'  ,  sprintf ( 'Initialising MET controller %d: %s' , ...
    MC.CD , func2str ( mcfh ) )  ,  'e'  )
  
  
  %%% Open special resources %%%
  
  try
    
    open_resources ( metrsc )
    
  catch  E
    
    % Report error
    met ( 'print' , fullReport ( E ) , 'e' ) ;
    
    % Attempt to close any open resources, and exit matlab
    delete ( cleanupObj )
    
  end % open special
  
  
  %%% Write controller attributes %%%
  
  try
    
    cntlattrib ( MC , metrsc , mcfh )
    
  catch  E
    
    % Report error
    met ( 'print' , fullReport ( E ) , 'e' ) ;
    
    % Attempt to close any open resources, and exit matlab
    delete ( cleanupObj )
    
  end % open special
  
  
  %%% Run MET controller function %%%
  
  try
    
    mcfh ( MC )
    
  catch  E
    
    % Report error
    met ( 'print' , fullReport ( E ) , 'E' ) ;
    
  end
  
  
  %%% Attempt to close any open resources, and exit matlab %%%
  
  delete ( cleanupObj )
  
  % We should never get this far , but just in case we tell user ...
  met (  'print'  ,  sprintf ( 'Emergency exit MET controller %d: %s' , ...
    MC.CD , func2str ( mcfh ) )  ,  'e'  )

  % ... and make one last-ditch attempt to shut down
  exit
  
  
end % metcontroller


%%% Subroutines %%%

function  fex ( s )
% 
% fex ( s )
% 
% Print error message to standard error then exit process.
% 
  
  met ( 'print' , s , 'e' )
  
  exit
  
end % fex


function  open_resources ( metrsc )
% 
% open_resources ( metrsc )
% 
% Attempts to open all special resources that have been requested.
% 
  
  % Get resource names
  SRF = fieldnames ( metrsc )' ;
  
  % Loop special resources
  for  F = SRF , f = F{ 1 } ;
    
    % Not requested, so don't try to open it
    if  ~metrsc.( f ) , continue , end
      
    % Resource-specific action
    switch  f

      case   'cbmex' , cbmex ( 'open'  ) ;
                         met ( 'flush' )

      case  'ivxudp' % No action , silently ignore this

      case  'ptbdaq' % No action , silently ignore this

      otherwise
        error ( '' )

    end
    
  end % special resources
  
  
end % open_resources


function  close_resources ( metrsc )
% 
% close_resources ( metrsc )
% 
% This function attempts to close all opened resources, both met and
% special. Calls exit to terminate Matlab, and process.
% 
  
  
  %%% Attempt to close met %%%
  
  try
    
    met ( 'close' )
    
  catch  E
    
    % Report error
    met ( 'print' , fullReport ( E ) , 'E' ) ;
    
  end
  
  
  %%% Attempt to clear PTB %%%
  
  try
    
    sca
    
  catch  E
    
    % Report error
    met ( 'print' , fullReport ( E ) , 'E' ) ;
    
  end
  
  % Same again for IOPort resources
  try
    
    IOPort (  'CloseAll'  )
    
  catch  E
    
    % Report error
    met ( 'print' , fullReport ( E ) , 'E' ) ;
    
  end
  
  
  %%% Attempt to close any special resources %%%
  
  % Get resource names
  SRF = fieldnames ( metrsc )' ;
  
  % Loop special resources
  for  F = SRF , f = F{ 1 } ;
    
    % Not requested, so don't try to close it
    if  ~metrsc.( f ) , continue , end
    
    % Close resource
    try
      
      % Resource-specific action
      switch  f
        
        case   'cbmex' , cbmex ( 'close' ) ;
          
        case  'ivxudp'
          
        case  'ptbdaq'
          
        otherwise
          error ( '' )
        
      end
      
    catch  E
      
      % Report error
      met ( 'print' , fullReport ( E ) , 'E' ) ;
      
    end
    
  end % special resources
  
  
  %%% Attempt to destroy any extant Matlab objects %%%
  
  % Try removing timers , note that only visible timers will be removed
  try
    delete (  timerfind  )
  catch
  end
  
  % Remove any figures that remain open
  try
    delete (  findobj (  'type'  ,  'figure'  )  )
  catch
  end
  
  
  %%% Exit Matlab %%%
  
  exit
  
  
end % close_resources


function  s = fullReport ( E )
% 
% s = fullReport ( E )
% 
% Turns MException E into string s, containing the message id in the first
% line, and the error report in following lines.
% 
  
  s = sprintf ( '\n%s\n%s' , E.identifier , getReport( E ) ) ;
  
end % fullReport


% Attempt to write controller function name, shm access, and special
% resources to a line of ~/.met/cntlattrib
function  cntlattrib ( MC , metrsc , mcfh )
  
  % Get resource names
  SRF = fieldnames ( metrsc )' ;
  
  % Get shared memory access rights
  SHM = MC.SHM ;
  
  % Number of items
  C = struct2cell (  metrsc  ) ;
  N = sum ( [ C{ : } ] )  +  size ( SHM , 1 )  +  1 ;
  
  % Cell array for gathering sub strings
  C = cell ( 1 , N ) ;
  
  % Get string of controller function name , with controller descriptor
  i = 1 ;
  C{ i } = sprintf (  '%d %s'  ,  MC.CD  ,  func2str( mcfh )  ) ;
  
  % Add shared memory access
  for  j = 1 : size ( SHM , 1 )  ,  i = i + 1 ;
    
    C{ i } = [  '-'  ,  SHM{ j , [ 2 , 1 ] }  ] ;
    
  end
  
  % Add special resources
  for  j = 1 : numel ( SRF )  ,  i = i + 1 ;
    
    % Not requested, so don't add it
    if  ~ metrsc.( SRF{ j } )  ,  continue  ,  end
    
    C{ i } = [ '-' , SRF{ j } ] ;
    
  end
  
  % Build output string
  S = sprintf (  '%s'  ,  strjoin ( C )  ) ;
  
  % MET controller constants , get name of root file to open
  MCC = metctrlconst ;
  f = MCC.MRCNTL ;
  
  % System command string
  S = sprintf (  'echo ''%s'' >> %s'  ,  S  ,  f  ) ;
  
  % Write file
  [ i , E ] = system (  S  ) ;
  
  if  i
    
    error ( 'MET:metcontroller:cntlattrib' , ...
      'metcontroller: failed to execute  %s\n  Got error: %s' , S , E )
    
  end
  
  
end % cntlattrib

