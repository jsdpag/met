
function  go ( ptbwin )
% 
% go ( ptbwin )
% 
% Used to run taskcontroller.m
% 
% Provides a GUI dialogue to help the user select a session directory where
% taskcontroller will operate. Also provides a layer of error catching, and
% resets the current directory to that where 'go' was first executed.
% 
% Input
% 
% DEBUG - scalar logical, optional - True if taskcontroller should be run
%   in debugging mode. False is default if argument not provided.
% 
% Version 1 - Directory selection dialogue. Try-catch taskcontroller.
%   Resets current directory. Allow copying of old session directory to
%   new.
% 
%   v1.1 - Checks for indev.m in the session directory. Initialises the
%     input-device descriptor and passes it to taskcontroller. When
%     taskcontroller returns, for any reason, then the descriptor is
%     closed.
%   
%   v1.2 - Makes sure that taskcontrol and mat.smi.com functions are on the
%     path.
% 
%   v1.3 - Asks user if stereo task , passes "stereo" argument to
%     taskcontroller.
%   
%   v1.4 - Retrofitted to run using MET. NOTE that an error with identifier
%     'MET:GO:SHUTDOWN' is thrown when the user wants to quit on purpose.
% 
% To do - Check format of session directory name
% 
% Written by Jackson Smith - Dec 2015 - DPAG, University of Oxford
% 
  
  
  %%% Pre-initialisation %%%
  
  % Try to force Matlab to recognise new versions of files
  rehash
  
  
  %%% Global constants %%%
  
  % MET controller constants , includes information about default subject
  % directory and 'eye' shared memory format
  global  MC  MCC
  
  
  %%% CONSTANTS %%%
  
  % MET root directory session name file
  METSESS  = fullfile ( MC.ROOT.ROOT , MC.ROOT.SESS  ) ;
  
  % Default directory to show the user in GUI dialogue
  SESSROOT = MCC.DEFSUB ;
  
  % make sure it exist
  if ~exist ( SESSROOT , 'file' )
    error ( 'taskcontroller:init:can''t find directory %s' , SESSROOT )
  end
  
  % Error dialogue timeout, in seconds
  ERRTOUT = 10 ;
  
  % Get current directory and save the path for later use.
  STARTDIR = pwd ;
  
  
  %%% Prompt user for sesson directory %%%
  
  % Ask whether to copy or open existing session directory
  cop = questdlg ( 'Copy or open existing session directory?' , ...
    'taskcontroller' , 'Copy' , 'Open' , 'Shutdown' , 'Copy' ) ;
  
  % Quit if no valid answer given
  if isempty ( cop ) || strcmp ( cop , 'Shutdown' )
    error ( 'MET:GO:SHUTDOWN' , '' )
  end
  
  % Have user specify directory to copy or open
  SESSDIR = uigetdir ( SESSROOT , 'Please choose session directory' ) ;
  
  % No valid directory was returned
  if checkdir ( SESSDIR , 'No valid directory provided.' , ERRTOUT )
    return
  end
  
  % If copying a directory
  if strcmp ( cop , 'Copy' )
    
    % The old directory
    OLDDIR = SESSDIR ;
    
    % Ask the user to edit the old session directory name
    SESSDIR = regexprep ( OLDDIR , '.*/' , '' ) ;
    SESSDIR = inputdlg ( { 'Name of the copy' } , 'taskcontroller' , ...
      1 , { SESSDIR } ) ;
    SESSDIR = SESSDIR { 1 } ;
    
    % Ask for the location of the new directory , start from where copied
    % directory is
    COPYDIR = uigetdir ( fileparts ( OLDDIR ) , 'Place copy here ...' ) ;
    SESSDIR = fullfile ( COPYDIR , SESSDIR ) ;
    
    % No valid directory was returned
    if checkdir ( COPYDIR , 'No valid directory provided.' , ERRTOUT )
      return
    end
    
    % Make sure we're not overwriting original dir
    if strcmp( OLDDIR , SESSDIR )
      
      % Error in copying
      checkdir ( 0 , 'Cannot overwrite original directory' , ERRTOUT ) ;
      return
      
    end
    
    % Make new session directory
    if ~mkdir( SESSDIR )
      
      % Error in copying
      checkdir ( 0 , 'Unable to make directory' , ERRTOUT ) ;
      return
      
    end
    
    % Copy m-files from the old session directory
    OLDDIR = fullfile ( OLDDIR , '*.m' ) ;
    
    if ~copyfile( OLDDIR , SESSDIR )
      
      % Error in copying
      checkdir ( 0 , 'Unable to copy m-files' , ERRTOUT ) ;
      return
      
    end
    
  % If opening existing
  elseif strcmp ( cop , 'Open' )
    
    % Check whether the session was finalised
    if sfin ( SESSDIR )
      
      h = msgbox ( 'Cannot Open finalised session.' ) ;
      uiwait ( h )
      return
      
    end % finalised
    
  else
    
    error ( 'Unidentified return value from questdlg: %s' , cop )
    
  end
  
  
  %%% Safely run taskcontroller %%%
  
  % Update session name in MET root file
  fileID = fopen ( METSESS , 'w' ) ;
  fprintf ( fileID , '%s\n' , SESSDIR ) ;
  fclose ( fileID ) ;
  
  % Run taskcontroller with the given session directory and debug setting
  try
    
    taskcontroller ( SESSDIR , ptbwin )
    
  catch  E
    
    % Reset current directory
    cd ( STARTDIR )
    
    % Inform the user
    h = errordlg ( 'An error occurred while running taskcontroller.m' ) ;
    uiwait( h , ERRTOUT )
    
    % Pass the error on
    rethrow ( E )
    
  end % run taskcontroller
  
  
end % go


%%% SUBROUTINES %%%

function f = sfin ( SESSDIR )
  
  % File attributes
  [ ~ , a ] = fileattrib ( SESSDIR ) ;
  
  % Name of finalisation flag
  n = fullfile ( SESSDIR , '.finalised' ) ;
  
  % Check write permission and finalisation flag
  if  a.UserWrite  &&  isempty ( dir ( n ) )
    
    % User has write permission and there is no flag
    % Not finalised
    f = false ;
    
  else
    
    % Finalised
    f = true ;
    
  end
  
end % sfin


function c = checkdir ( D , MSG , ERRTOUT )
  
  % Default return is false, don't quit
  c = false ;
  
  % Output from uigetdir
  if ~D
    
    % Inform user
    h = errordlg ( MSG ) ;
    
    % Wait for confirmation
    uiwait( h , ERRTOUT )
    
    % Quit on return
    c = true ;
    
  end
  
end % checkdir

