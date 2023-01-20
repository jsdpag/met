
function  [ notmade , msg ] = metmkdir ( dname , tlogic , stimdef , sched )
% 
% [ notmade , msg ] = metmkdir ( dname , tlogic , stimdef , sched )
% 
% Matlab Electrophysiology Toolbox, make directory. Makes a new session
% directory with name dname. dname must contain at least the parent and new
% directories' names e.g. parent/session_dir.
% 
% Sub-directories tasklogic/ and stim/ are populated with .txt and .m
% files, respectively, according to the task logic and stimulus definition
% files listed in tlogic and stimdef ; only the file names need to be
% given, without a path , while the file suffix is optional. tlogic and
% stimdef can each either be a single string or a cell array of strings.
% 
% String sched is written to the new session directory's schedule.txt file.
% 
% Returns 0 on success and nonzero on failure. Will not overwrite existing
% directories. tasklogic/ and stim/ will recursively have write permissions
% removed from all users.
% 
% On error, returns 1 if session directory exists , 2 if parent directory
% of new session directory does not have write permissions or these
% couldn't be accessed , 3 parent directory not specified in path provided
% in dname, 4 for any other error. msg is empty on success, but contains a
% error message string on error.
% 
% Written by Jackson Smith - Oct 2016 - DPAG , University of Oxford
% 
	
  
  %%% Constants  %%%
  
  % Compile time constants
  MC = met ( 'const' , 1 ) ;
  
  % Location , master copies of task logic and stimulus definitions
  TLDIR = MC.PROG.TLOG ;
  SDDIR = MC.PROG.STIM ;
  
  % File type suffix cellfun function
  FTS = @( c , rex )  isempty (  regexp ( c , rex , 'once' )  ) ;
  
  % Return error values , 1 - session directory exists , 2 - no parent dir
  % write permissions , 3 - no parent directory given
  EVEXIST = 1 ;
  EVWPERM = 2 ;
  EVNOPAR = 3 ;
  EVOTHER = 4 ;
  
  
  %%% Check input %%%
  
  % Default output , success
  notmade = 0 ;
  
  % dname must be a string
  if  nargin  ~=  4
    
    error ( 'MET:metmkdir:input' , 'metmkdir: four input args required' )
    
  elseif  ~ ( ischar ( dname )  &&  isvector ( dname ) )
    
    error ( 'MET:metmkdir:input' , 'metmkdir: dname must be a string' )
    
  % tlogic must be a string or cell array of strings
  elseif  ~ ( ischar ( tlogic )  &&  isvector ( tlogic ) )  &&  ...
      ~ iscelstr ( tlogic )
    
    error ( 'MET:metmkdir:input' , ...
      'metmkdir: tlogic must be a string or cell array of strings' )
    
  % stimdef must be a string or cell array of strings
  elseif  ~ ( ischar ( stimdef )  &&  isvector ( stimdef ) )  &&  ...
      ~ iscelstr ( stimdef )
    
    error ( 'MET:metmkdir:input' , ...
      'metmkdir: stimdef must be a string or cell array of strings' )
    
  % sched must be a string
  elseif  ~ isvector ( sched )  ||  ~ ischar ( sched )
    
    error ( 'MET:metmkdir:input' , 'metmkdir: sched must be a string' )
    
  end
  
  % Parent directory of new session directory , and its permissions
  C = { fileparts( dname ) , [] , [] } ;
  
  % Does parent directory exist at all? That is, is there such a date
  % directory?
  if  ~ exist (  C { 1 }  ,  'dir'  )
    
    % No! So we should try to make one.
    [ i , msg ] = mkdir (  C { 1 }  ) ;
    
    if  ~ i
      notmade = EVOTHER ;
      msg = [  'Can''t make parent date directory , '  ,  msg  ] ;
      return
    end
    
  end % make date dir
  
  if  ~ isempty ( C { 1 } )
    [ C{ 2 : 3 } ] = fileattrib( C { 1 } ) ;
  end
  
  % Check that new session directory does not exist
  if  exist ( dname , 'dir' )
    
    notmade = EVEXIST ;
    msg = [ 'Cannot overwrite existing ' , dname ] ;
    
  % Check write permissions for parent directory
  elseif  isempty ( C { 1 } )
    
    notmade = EVNOPAR ;
    msg = 'No parent directory specified in dname' ;
    
  elseif  ~ ( C{ 2 }  &&  C{ 3 }.UserWrite )
    
    notmade = EVWPERM ;
    msg = [ 'No write permission for ' , C{ 1 } ] ;
    
  end % Write permissions
  
  % Error detected
  if  notmade  ,  return  ,  end
  
  % If tlogic or stimdef not cell arrays of strings then make them so
  if  ~ iscell ( tlogic  )  ,   tlogic = {  tlogic } ;  end
  if  ~ iscell ( stimdef )  ,  stimdef = { stimdef } ;  end
  
  % Add file type suffixes if not given
  i = cellfun ( @( c )  FTS ( c , '.+\.txt$' ) , tlogic  ) ;
  tlogic  ( i )  =  cellfun ( @( c )  [ c , '.txt' ] ,  tlogic ( i ) , ...
    'UniformOutput' , false ) ;
  
  i = cellfun ( @( c )  FTS ( c , '.+\.m$'   ) , stimdef ) ;
  stimdef ( i )  =  cellfun ( @( c )  [ c , '.m'   ] , stimdef ( i ) , ...
    'UniformOutput' , false ) ;
  
  % Check that full path not provided , and master copy of file exists ,
  % loop file sets
  C = { {  tlogic , 'task logic'          , TLDIR } , ...
        { stimdef , 'stimulus definition' , SDDIR } } ;
  
  for  C = C , c = C { 1 } ;
    
    % File type and MET program directory location
    [ t , md ] = c{ 2 : 3 } ;
    
    % Loop files in set
    for  i = 1 : numel ( c { 1 } )
      
      % File name
      f = c{ 1 }{ i } ;
      
      % If parent directory is not empty, then it was given as part of path
      if  ~ isempty ( fileparts ( f ) )

        error ( 'MET:metmkdir:input' , [ 'metmkdir: ' , ...
          t , ' , full path provided , ' , f ] )
        
      % Master copy not recognised
      elseif  ~ exist ( fullfile ( md , f ) , 'file' )
        
        notmade = EVOTHER ;
        msg = [ 'No ' , t , ' called ' , f , ' was found in ' , md ] ;
        return
        
      end % checks
      
    end % files
  end % no path
  
  
  %%% Make directories %%%
  
  % Session directory and sub-directory names
  C = { '' , MC.SESS.LOGS , MC.SESS.REC , MC.SESS.STIM , MC.SESS.TLOG , ...
    MC.SESS.TRIAL } ;
  C = fullfile ( dname , C ) ;
  
  % Make directories
  for  c = C
    
    [ i , msg ] = mkdir ( c { 1 } ) ;

    % Failed to make directory , quit
    if  ~ i
      notmade = EVOTHER ;
      return
    end
  
  end % make directories
  
  
  %%% Copy task logics and stimulus definitions %%%
  
  % Loop task logic and stim def , each sub-cell is ordered source
  % directory, list of files, destination directory
  for  C = { { SDDIR , stimdef , C{ 4 } } ;
             { TLDIR , tlogic  , C{ 5 } } }' ;
    
    % Give meaningful names to looped values
    [ source , files , dest ] = C { 1 } { : } ;
    
    % Full path to source files
    files = fullfile ( source , files ) ;
    
    % Copy files
    for  F = files( : )' , f = F { 1 } ;
      
      [ i , msg ] = copyfile ( f , dest ) ;

      % Failed to copy , quit
      if  ~ i
        notmade = EVOTHER ;
        return
      end
      
    end % copy files
    
  end % task logic & stim def
  
  
  %%% Write schedule.txt %%%
  
  % Full name of file
  F = fullfile (  dname  ,  MC.SESS.SCHED  ) ;
  
  % Write
  metsavtxt ( F , sched , 'w' , 'metmkdir' )
  
  
end % metmkdir


%%% Subroutines %%%

% Is a cell array of strings
function  i = iscelstr ( c )
  
  % Plan for failure
  i = false ;
  
  % Check if it is a cell array and if all elements are strings
  if  isempty ( c )  ||  ~ iscell ( c )  ||  ...
      ~ all (  cellfun ( @( c )  ischar( c )  &&  isvector( c ) , c )  )
    return
  end
  
  % But to our surprise , it is
  i( 1 ) = 1 ;
  
end % iscelstr

