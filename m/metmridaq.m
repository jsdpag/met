
function  metmridaq ( MC )
% 
% metmridaq ( MC )
% 
% Matlab Electrophysiology Toolbox child controller function. This is meant
% to help synchronise MET/PTB time stamps with BOLD-fMRI data collection
% during offline analysis. It records the TTL voltage output from the MRI
% system that signals the onset and duration of each volume of data
% recorded in the fMRI sequence ( e.g. the Siemens Magnetom Trio 3T ). The
% voltage output is expected to switch between a high and low state with
% each volume, and remain in that state until the next volume starts. On
% the first trial only of a session, metmridaq will delay the start of the
% trial until the first volume switch is detected. Hence, it is recommended
% that a new MRI file is saved for each session in MET. For example:
% 
%   MET session , MRI file
%     M123.12.1 , ep2d-1    Session 1 of experiment 12 for subject M123
%     M123.12.2 , ep2d-2    Session 2
%           ... , ...
% 
% The MRI TTL voltage trace is saved in the session's trial directory as an
% ASCII text file with file name metmridaq.txt. Data is streamed into this
% file. Each line has a unique sample with format: <time stamp>,<voltage>.
% Where the time stamp is in seconds and the voltage is in Volts. Time
% stamps are MET/PTB times that are the best estimated time of each voltage
% sample. An example line of metmridaq.txt is: 1531500817.571831,5.03.
% Samples are listed in chronological order, as they are received. One can
% easily load metmridaq.txt into a 2D matlab double floating point array
% via:
% 
%   >> X = importdata (  'metmridaq.txt'  ,  ','  ) ;
% 
% metmridaq requires parameter file met/m/metmridaq.csv. This is a MET .csv
% file ( see metreadcsv ). Required parameters are as follows. DAQPRD must
% be the product string of the DAQ device in use. DAQSNO must be the serial
% number string for the specific device that will be devoted to measuring
% the MRI TTL voltage trace. VOLTHR is a threshold in volts that will be
% used to distinguish the high from low state when synchronising the first
% trial ; this is how the first volume will be identified. VOLSHZ is the
% desired sampling rate of the MRI voltage trace, in Hertz.
% 
%   Example:
% 
%   param,value
%   DAQPRD,USB-1208FS
%   DAQSNO,01CEC036
%   VOLTHR,1.0
%   VOLSHZ,200
% 
% NOTE: Assumes that MRI TTL is attached to USB-1208FS single-ended
% analogue input channel 0 at pin 1 with analogue ground at pin 3. This
% corresponds to channel 8 in the DaqAInScan options.channel field.
% 
% Written by Jackson Smith - July 2018 - DPAG , University of Oxford
% 
  
  
  %%% metmridaq CONSTANTS %%%
  
  % Get copy of controller constants
  MCC = metctrlconst (  MC  ) ;
  
  % Voltage sample format string , without newline
  VOLFMT = [  MCC.FMT.TIME  ,  ',%0.2f'  ] ;
  
  % Output file format string , append to the session directory path
  VOLNAM = fullfile (  MC.SESS.TRIAL  ,  'metmridaq.txt'  ) ;
  
  % Read parameter file
  p = readpar ;
  
  
  %%% Find DAQ device %%%
  
  % Find all DAQ devices
  DAQ = DaqDeviceIndex ;
  
  % List of all connected HID devices
  hid = PsychHID (  'Devices'  ) ;
  
  % Look for any that match the given product and serial number
  i = strcmp (  p.DAQPRD  ,  { hid( DAQ ).product      }  )  &  ...
      strcmp (  p.DAQSNO  ,  { hid( DAQ ).serialNumber }  ) ;
    
  % Can't find device
  if  ~ any (  i  )
    
    error (  'MET:metmridaq:nodaq'  ,  ...
      'metmridaq: can''t find %s with serial no. %s'  ,  p.DAQPRD  ,  ...
        p.DAQSNO  )
    
  end % no daq device
  
  % Get specified device
  DAQ = DAQ( i ) ;
  
  
	%%% Input options struct for PsychToolbox DaqAInScan %%%

  % First single ended analogue input channel , corresponding to pin 1 on
  % USB-1208fs
  options.channel = 8 ;

  % Gain multiplier code , for +/-5 volts
  options.range = 2  *  ones ( size ( options.channel ) ) ;

  % Sampling rate in samples/channel/s
  options.f = p.VOLSHZ ;

  % Immediate transfer mode on 1 or off 0.
  options.immediate = 1 ;

  % Number of data points to collect , no limit
  options.count = Inf ;

  % Release time , must be updated on every call to DaqAInScanContinue
  options.ReleaseTime = 0 ;

  % Maximum processing time per invocation. Heuristically setting this to
  % 10 times the duration of one sample.
  options.secs =  10  /  options.f ;

  % Tells us what it's doing
  options.print = 0 ;

  % Home-made option. Don't discard any data!
  options.nodiscard = 1 ;
  
  
  %%% Preparation %%%
  
  % Pack controller's constants
  C = struct ( 'DAQ' , DAQ , 'VOLTHR' , p.VOLTHR , 'VOLFMT' , VOLFMT , ...
    'VOLNAM' , VOLNAM , 'OPTIONS' , options ) ;
  
  % Remove unnecessary variables
  clearvars  -except  MC C
  
  % Start data collection
  DaqAInScanBegin ( C.DAQ , C.OPTIONS ) ;
  
  
  %%% Run controller %%%
  
  % Error message , empty means no error
  E = [] ;
  
  % We need to catch errors to guarantee we turn off the daq device
  try
    
    metmridaq_run (  MC  ,  C  )
    
  catch  E
  end
  
  % Attempt to stop data collection
  try  DaqAInScanEnd ( C.DAQ , C.OPTIONS ) ;
  catch
  end
  
  % Make sure to flush final output to file
  try  met (  'flush'  ,  'l'  )
  catch
  end
  
  % Close output file
  try  met (  'logcls'  )
  catch
  end
  
  % Rethrow any errors
  if  ~ isempty ( E )  ,  rethrow ( E )  ,  end
  
  
end % metmridaq


%%% Controller function %%%

function  metmridaq_run (  MC  ,  C  )
  
  
  %%% Constants %%%
  
  % Set of MET signal ID's , fields name each signal and contain id value
  MSID = MC.SIG' ;
  MSID = struct ( MSID { : } ) ;
  
  % Receive MET signals in blocking mode
  WAIT_FOR_MSIG = 1 ;
  
  % Voltage format string with newline
  VOLFMTNL = [ C.VOLFMT , '\n' ] ;
  
  
  %%% Flag initialisation %%%
  
  % Initialise empty session directory string
  sdir = '' ;
  
  % sflg is raised after the first fMRI volume on the first trial is
  % detected. This is done once per session.
  sflg = true ;
  
  % tflg is set to match the first observed state of the MRI TTL voltage in
  % order to recognise when the voltage has changed i.e. when to raise
  % sflg. If empty then the MRI TTL state has not yet been observed for
  % this session.
  tflg = false( 0 ) ;
  
  
  %%% Complete MET initialisation %%%
  
  % Send mready signal , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Report
  met (  'print'  ,  sprintf ( ...
    'MET controller %d initialised: metmridaq' ,...
      MC.CD )  ,  'o'  )
  
  % Flush any outstanding messages to terminal
  met ( 'flush' )
  
  % Wait for synchronising ready signal
  [ ~ , ~ , sig ] = met ( 'recv' , WAIT_FOR_MSIG ) ;
  
  % Return if any mquit signal received
  if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
  
  
  %%% Event loop %%%
  
  while  true
    
    
    %-- MET signals --%
    
    % Check for new MET signals
    [ ~ , ~ , sig , crg ] = met ( 'recv' ) ;
    
    % Return if any mquit received
    if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
    
    % Find mready signals
    mrs =  sig == MSID.mready  ;
    
    % Has mready trigger been received?
    if  any ( crg ( mrs )  ==  MC.MREADY.TRIGGER )
      
      % Read current session directory name
      scur = metsdpath ;
      
      % Session directory has changed - NEW session
      if  ~ strcmp (  sdir  ,  scur  )
        
        % Flush and close current output file
        met (  'flush'  ,  'l'  )
        met (  'logcls'  )
        
        % Open new output file
        met (  'logopn'  ,  fullfile(  scur  ,  C.VOLNAM  )  )
        
        % Remember current session directory
        sdir = scur ;
        
        % Lower session flag
        sflg( 1 ) = false ;
        
        % Empty TTL flag
        tflg = false( 0 ) ;
        
      end % new session
      
      % Send mready reply if the first trial was synced to fMRI volume
      if  sflg
        
        met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
        
      end
      
    end % mready trigger received
    
    
    %-- Sample MRI voltage trace --%
    
    % DaqAInScan will read until this time in the future
    C.OPTIONS.ReleaseTime( 1 ) = GetSecs  +  C.OPTIONS.secs ;
    
    % Read voltages
    [ ~ , v ] = DaqAInScanContinue ( C.DAQ , C.OPTIONS , true ) ;
    
    % Time measurement
    t = GetSecs ;
    
    % Nothing sampled , carry on to next event
    if  isempty (  v  )
      
      continue
      
    % Session flag is low , sync first trial to first fMRI volume
    elseif  ~ sflg
      
      % Threshold voltages to determine high or low state of MRI TTL
      ttl = C.VOLTHR  <=  v ;
      
      % MRI TTL state not yet set , set it now
      if  isempty (  tflg  )  ,  tflg = ttl( 1 ) ;  end
      
      % The latest voltage value is in a different state from the one that
      % was first observed
      if  tflg  ~=  ttl( end )
        
        % Send mready reply
        met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
        
        % Raise session flag
        sflg( 1 ) = true ;
        
      end % new volume detected
      
    end % sync trial 1
    
    
    %-- Output string --%
    
    % Create time stamp vector
    tv = t  +  ( 1 - numel( v ) : 0 )' / C.OPTIONS.f ;
    
    % Convert time stamps and voltages into string records
    s = [  ...
      sprintf( VOLFMTNL , [ tv( 1 : end - 1 ) , v( 1 : end - 1 ) ]' )  ,...
      sprintf( C.VOLFMT , tv( end ) , v( end ) )  ] ;
    
    % Send to log file stream i.e. the session's voltage output file
    met (  'print'  ,  s  ,  'l'  )
    
    
  end % event loop
  
  
end % metmridaq_run


%%% Subroutines %%%

% Read in MET .csv file with the specific DAQ model name and serial number
function  p = readpar
  
  % Location of metmridaq.csv , first get containing directory then add
  % file name
  f = fileparts ( which ( 'metmridaq' ) ) ;
  f = fullfile ( f , 'metmridaq.csv' ) ;
  
  % Make sure that the file exists
  if  ~ exist ( f , 'file' )
    
    error ( 'MET:metmridaq:csv' , 'metmridaq: Can''t find %s' , f )
    
  end
  
  % Parameter name set
  PARNAM = { 'DAQPRD' , 'DAQSNO' , 'VOLTHR' , 'VOLSHZ' } ;
  
  % Numeric parameters
  NUMPAR = { 'VOLTHR' , 'VOLSHZ' } ;
  
  % Read in parameters
  p = metreadcsv ( f , PARNAM , NUMPAR ) ;
  
  % Must be strings
  for  PARNAM = { 'DAQPRD' , 'DAQSNO' } ;
  
    fn = PARNAM { 1 } ;
    
    if  ~ isvector ( p.( fn ) )  ||  ~ ischar ( p.( fn ) )
      error ( 'MET:metmridaq:csv' , 'metmridaq: %s must be string' , fn )
    end
    
  end % string params
  
  % Must be scalar, real and finite numbers
  for  PARNAM = { 'VOLTHR' , 'VOLSHZ' }
    
    fn = PARNAM { 1 } ;
    
    if  ~ isscalar ( p.( fn ) )  ||  ~ isnumeric ( p.( fn ) )  ||  ...
      ~ isreal ( p.( fn ) )  ||  ~ isfinite ( p.( fn ) )
    
      error ( 'MET:metmridaq:csv' , ...
        'metmridaq: %s must be scalar, real, finite number' , fn )
      
    end
    
  end % integer params
  
  % Must be greater than zero
  if  0  >=  p.VOLSHZ
    
    error ( 'MET:metmridaq:csv' , ...
        'metmridaq: VOLSHZ must be greater than zero' )
      
  end
  
end % readpar

