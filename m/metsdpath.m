
function  varargout = metsdpath ( varargin )
% 
% sdpath = metsdpath
% sdpath = metsdpath ( check )
% [ sdpath , tid ] = metsdpath ( ... )
% metsdpath ( sdpath )
% metsdpath ( sdpath , fincheck )
% 
% Reads in the path of the current MET session directory. Also verifies the
% directory's existance, along with requisite sub-directories and files.
% Without input arguments, the path is returned but nothing is verified. If
% one scalar numerical or logical input argument is provided then the path
% is returned and the session directory is verified if the input , check ,
% is non-zero. If a path string naming a session directory , sdpath , is
% provided then no output argument is generated, but the session directory
% is verified. An optional second output argument string contains the
% current trial identifier.
% 
% A session directory passes verification if it exists and if it contains
% sub-directories logs/, recovery/, stim/, tasklogic/, and trials/ ; it
% must also contain a schedule.txt file, while having at least one .txt and
% one .m file in tasklogic/ and stim/, respectively. The session directory
% will not pass verification if it contains a .finalise flag file, unless
% the optional fincheck input argument is false (default true). An error is
% thrown when a directory fails to pass verification.
% 
% Written by Jackson Smith - DPAG , University of Oxford
% 
  
  
  %%% Check input %%%
  
  % Too many inputs
  if  2  <  nargin
    
    error ( 'MET:metsdpath:input' , 'metsdpath: too many input args' )
    
  end
  
  % Default input argument (double), directory verification flag, and
  % .finalise check flag
  arg = [] ;
  verify = false ;
  fincheck = true ;
  
  % Input arg provided
  if  nargin
    
    % Get value
    arg = varargin{ 1 } ;
    
    % Char input argument
    if  ischar ( arg )
      
      % Not a string
      if  ~isvector ( arg )  ||  1 < size ( arg , 1 )
        error ( 'MET:metsdpath:input' , ...
          'metsdpath: char input arg is not a string' )
      end
      
      % Set session directory path value
      sdpath = arg ;
      
      % Verify session directory
      verify = true ;
      
      % Look for fincheck flag
      if  nargin == 2
        
        % Get flag value
        fincheck = varargin{ 2 } ;
        
        % Verify that this is scalar numeric or logical
        if  ~ isscalar ( fincheck )  ||  ...
            ~ ( isnumeric ( fincheck )  ||  islogical ( fincheck ) )
          
          error ( 'MET:metsdpath:input' , ...
          'metsdpath: fincheck must be scalar numeric or logical' )
        
        end
        
      end % fincheck flag
      
    % Input arg is numerical or logical
    elseif  isnumeric ( arg )  ||  islogical ( arg )
      
      % Not a scalar
      if  ~isscalar ( arg )
        error ( 'MET:metsdpath:input' , ...
          'metsdpath: numerical/logical input is not scalar' )
      end
      
      % Verify session directory
      verify = 0  ~=  arg ;
      
    % All other cases
    else
      
      error ( 'MET:metsdpath:input' , ...
    'metsdpath: input arg is neither string nor numerical/logical scalar' )
      
    end
    
  end % input arg
  
  % Too many outputs
  if  ( ischar ( arg )  &&  nargout )  ||  2  <  nargout
    
    error ( 'MET:metsdpath:output' , ...
      'metsdpath: too many output arguments requested' )
    
  end
  
  
  %%% MET COMPILE-TIME CONSTANTS %%%
  
  MC = met ( 'const' , 1 ) ;
  
  
  %%% Read session directory path %%%
  
  if  ~nargin  ||  ~ischar ( arg )
    
    % Check that MET root directory exists
    if  ~exist ( MC.ROOT.ROOT , 'dir' )

      error ( 'MET:metsdpath:root' , 'metsdpath: No MET root directory' )
      
    end
    
    % File names to files containing session directory path and current
    % trial identifier
    FNAME = {  fullfile( MC.ROOT.ROOT , MC.ROOT.SESS  ) ;
               fullfile( MC.ROOT.ROOT , MC.ROOT.TRIAL )  } ;
             
    % Allocate variable output list
    NARGOUT = max (  [ 1 , nargout ]  ) ;
    varargout = cell (  1  ,  NARGOUT  ) ;
    
    % Load one file for each output
    for  i = 1 : NARGOUT

      % Session directory path file exists
      if  ~exist ( FNAME{ i } , 'file' )

        error ( 'MET:metsdpath:root' , ...
          'metsdpath: Can''t find MET root file %s' , FNAME{ i } )

      end

      % Open file for reading
      fid = fopen ( FNAME{ i } ) ;

      if  ( fid  ==  -1 )

        error ( 'MET:metsdpath:root' , ...
          'metsdpath: cannot open %s' , FNAME{ i } )

      end

      % Current session directory path
      str = fgetl ( fid ) ;
      
      if  isscalar ( str )  &&  str == -1
        
        error ( 'MET:metsdpath:root' , ...
          'metsdpath: Failed to read from %s' , FNAME{ i } )
        
      end

      % Close session file
      if  (  fclose ( fid )  )

        error ( 'MET:metsdpath:root' , ...
          'metsdpath: cannot close %s' , FNAME{ i } )

      end

      % Return path
      varargout{ i } = str ;
      
    end % output args
    
    % Set session directory path name
    sdpath = varargout { 1 } ;
    
  end % read dir path
  
  
  %%% No verification %%%
  
  if  ~verify  ,  return  ,  end
  
  
  %%% Verify session directory %%%
  
  
  %-- Verification constants --%
  
  % Sub-directory names , loop MC.SESS field names
  SDNAME = { 'LOGS' , 'REC' , 'STIM' ,  'TLOG' , 'TRIAL' } ;
  
  % Sub-directory must have at least one file matching search string. Empty
  % means don't look
  SDFILE = {     '' ,    '' ,  '*.m' , '*.txt' ,     '' } ;
  
  % Regular files that must exist , MC.SESS field names
  RFNAME = { 'SCHED' } ;
  
  
  %-- Verification --%
  
  % Session directory
  if  ~exist ( sdpath , 'dir' )
    
    error ( 'MET:metsdpath:sessdir' , ...
      'metsdpath: current session directory does not exist %s' , sdpath )
    
  end
  
  % Check for regular files
  for  i = 1 : numel ( RFNAME )
    
    fname = fullfile ( sdpath , MC.SESS.( RFNAME{ i } ) ) ;
    
    if  ~exist ( fname , 'file' )
      
      error ( 'MET:metsdpath:sessdir' , ...
        'metsdpath: current session file does not exist %s' , fname )
      
    end
    
  end
  
  % Check for required sub-directories
  for  i = 1 : numel ( SDNAME )
    
    % Directory path
    fname = fullfile ( sdpath , MC.SESS.( SDNAME{ i } ) ) ;
    
    % Does it exist?
    if  ~exist ( fname , 'dir' )
      
      error ( 'MET:metsdpath:sessdir' , ...
        'metsdpath: current session sub-directory does not exist %s' , ...
        fname )
      
    end
    
    % Does it have at least one file of the right type?
    if  ~isempty ( SDFILE{ i } )
      
      fname = fullfile ( fname , SDFILE{ i } ) ;
      
      if  isempty ( dir ( fname ) )
        
        error ( 'MET:metsdpath:sessdir' , ...
        'metsdpath: No files found of type %s' , fname )
        
      end
      
    end % file check
    
  end % sub-dirs
  
  % Does .finalise exist?
  fname = fullfile ( sdpath , MC.SESS.FIN ) ;
  
  if  fincheck  &&  exist ( fname , 'file' )
    
    error ( 'MET:metsdpath:finalise' , ...
      'metsdpath: this session was finalised and may not be opened' )
    
  end
  
  
end % metsdpath

