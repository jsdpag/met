
function trial_d = loadtrials( trialdir , subset )
% 
% trial_d = loadtrials( trialdir , subset )
% 
% Load trial data files, originating from trialcontroller.m. Each output
% file will be a .mat binary file with file name trialj.mat where j becomes
% the trial number. Every file will contain the trial-descriptor variable
% 'trial_d'. Some subset of trials will be loaded and all descriptors sewn
% together into one struct array.
% 
% Input
% 
% trialdir - string - Directory containing binary .mat output files.
% 
% subset - optional argument - loads all trials by default or if [] given.
%   - numerical vector - A list of trial numbers. Only trials in the
%     list are loaded into memory.
%   - logical vector - The ith trial is loaded if subset(i) is true.
% 
% Written by Jackson Smith - Oct 2015 - DPAG, University of Oxford
% 
  
  
  %%% CONSTANTS %%%
  
  FNAM = 'trial*.mat' ;
  VARNAM = 'trial_d' ; 
  TFIELD = 'trial' ;
  
  
  %%% Check input %%%
  
  % Optional argument. [] indicates none given.
  if nargin < 2 , subset = [] ; end
  
  d = checkin ( trialdir , subset , FNAM , VARNAM ) ;
  
  
  %%% Load trials %%%
  
  % Get first one into memory for struct format
  load( fullfile( trialdir , d(1).name ) , VARNAM )
  
  % Make sure that there is at least the .trial field
  if isempty( fieldnames( trial_d ) ) || ...
      ~any( strcmp( fieldnames( trial_d ) , TFIELD ) ) %#ok
    error( 'loadtrials:%s:struct lacks field %s' , VARNAM , TFIELD )
  end
  
  % Resize buffer enough to load all data
  trial_d = repmat( trial_d , numel( d ) , 1 ) ;
  
  % Load all trials
  for i = 1 : numel( d )
    
    fnam = fullfile( trialdir , d( i ).name ) ;
    tdin = load( fnam , VARNAM ) ;
    
    trial_d( i ) = tdin.( VARNAM ) ;
    
  end % load trials
  
  % Sort by trial number
  [ ~ , i ] = sort( [ trial_d.( TFIELD ) ] ) ;
  trial_d = trial_d( i ) ;
  
  
  %%% Cut down to specified subset %%%
  
  % No subsets, return all trials
  if isempty( subset ) , return , end
  
  % Determine which elements of struct array to keep
  if isnumeric( subset )
    [ ~ , i ] = intersect( [ trial_d.( TFIELD ) ] , subset ) ;
  else
    i = find( subset ) ;
  end
  
  % Slice it down
  trial_d = trial_d( i ) ;
  
  
end % loadtrials


%%% Subroutines %%%

function d = checkin ( trialdir , subset , FNAM , VARNAM )
  
  % Check validity of directory name
  if isempty(trialdir) || ~ischar(trialdir) || ~exist( trialdir , 'dir' )
    
    error( 'loadtrials:trialdir:not a valid directory' )
    
  end
  
  % Search directory for files
  d = dir( fullfile( trialdir , FNAM ) ) ;
  
  if isempty( d )
    
    error( 'loadtrials:trialdir:no files with form %s' , FNAM )
    
  end
  
  % Check first file for trial_d variable. Don't look at all of them, that
  % could take for ever.
  w = whos( '-file' , fullfile( trialdir , d(1).name ) ) ;
  
  if ~strcmp( { w.name } , VARNAM )
    
    error( 'loadtrials:trialdir:files lack variable ''%s''' , VARNAM ) ;
    
  end
  
  % No subset argument given
  if isempty( subset ) , return , end
  
  % Check validity of given subset values.
  if ~isvector( subset ) || ...
      ( ~isnumeric( subset ) && ~islogical( subset ) )
    
    error( 'loadtrials:subset:must be numerical or logical vector' )
    
  elseif isnumeric( subset ) && ( numel( d ) < numel( subset ) || ...
      any( subset <= 0 ) || any( mod( subset , 1 ) ) )
    
    error( 'loadtrial:subset:numerical index out of range' )
    
  elseif islogical( subset ) && ( numel( d ) ~= numel( subset ) || ...
      ~any( subset ) )
    
    error( 'loadtrial:subset:logical index out of range' )
    
  end
  
end % checkin

