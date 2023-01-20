
function  metdaqout ( MC )
% 
% metdaqout ( MC )
% 
% Matlab Electrophysiology Toolbox child controller function. Searches for
% a specific USB Digital Acquisition device. Then generates digital output
% corresponding to every MET signal received. Also switches up to two
% reward pumps on and off.
% 
% Specifically, it looks for a Measurement Computing USB-1208fs and
% configures its digital I/O ports for output. There are two ports, each
% with 8 pins. Altogether, they can define an unsigned 16-bit integer. Bare
% wire to DSUB ribbon cable connects the digital ports of the DAQ device
% with the Neursl Signal Processor digital input port.
% 
% MET signals arrive with two codes, a signal ID and a cargo. The signal ID
% specifies the event and is transmitted from port 0. The cargo gives
% context to a signal, and it is transmitted from port 1, rounded down to
% intmax uint8 if it is greater. Signal transmission occurs in these steps.
% 
%   1 - Turn on signal ID bits in port 0
%   2 - Wait for at least 33 microseconds
%   3 - Turn on cargo bits in port 1
%   4 - Wait for at least 33 microseconds
%   5 - Turn off all bits in both ports
% 
% 33 microseconds is approximately the duration of each sample that the NSP
% takes in its digital input port i.e. it samples at a rate of 30 KHz. In
% practice, this will be a lower limit.
% 
% To set up NSP, configure the digital input port to read 16 bits on the
% rising edge of any bit. The result will be an unsigned 16-bit integer.
% For integer i, if i <= 255 [ intmax uint8 ] then the value is a MET
% signal ID [ see met ( 'const' , 1 ) output for codes ]. If 255 < i, then
% bit-shift i eight bits to the right [ bitshift ( i , -8 ) ] to get the
% cargo value. Signal ID's and cargo values should always occur one after
% the other.
% 
% The USB-1208fs also has two analogue output ports that are each used to
% trigger a reward pump. mrdtype and mreward MET signal pairs are expected,
% in that order, to define each reward. The cargo of mrdtype must be 1
% or 2 ; less than 1 is ignored and greater than 2 is rounded down to 2.
% This indicates which reward pump to drive, pump 1 or 2. The cargo of
% mreward is the number of milliseconds to add to the operation of the pump
% specified by mrdtype. If another reward is defined on a pump that is
% running, then the new reward duration is added to the existing reward
% duration.
% 
% NOTE: Reads the USB-DAQ device product name and serial number from
% metdaqeye.csv, a MET .csv file. Must have column headers param,value and
% list parameters DAQPRD and DAQSNO. Example:
% 
%   param,value
%   DAQPRD,USB-1208FS
%   DAQSNO,01AC1989
% 
% Written by Jackson Smith - Oct 2016 - DPAG , University of Oxford
% 
  
  
  %%% metdaqout constants %%%
  
  % MET controller constants
  MCC = metctrlconst ( MC ) ;
  
  % DAQ product and serial number
  [ DAQPRD , DAQSNO ] = readdaqpar ;
  
  % Neural signal processor sample duration , in seconds
  NSPDUR = 1 / MCC.SHM.NSP.RAWSHZ ;
  
  % Maximum unsigned 8-bit integer, to clip large cargo
  MAXCRG = double ( intmax ( 'uint8' ) ) ;
  
  % Assign each DAQ port to a different kind of data. Port 1 for MET signal
  % ID's, and port 2 for cargos.
  PRTSID = 0 ;
  PRTCRG = 1 ;
  
  % Maximum number of pumps
  PUMPNO = 2 ;
  
  
  %%% Search for DAQ device %%%
  
  % List of all devices
  DAQ = PsychHID ( 'devices' ) ;
  
  % Find devices with the same product name and serial number
  DAQ = find (  strcmp ( DAQPRD , { DAQ.product      } )  &  ...
                strcmp ( DAQSNO , { DAQ.serialNumber } )  ) ;
  
  % Find the Daq device index in this set
  DAQ = intersect ( DAQ , DaqDeviceIndex ) ;
  
  if  isempty ( DAQ )
    
    error ( 'MET:metdaqout:daq' , ...
      'metdaqout: Unable to find USB-DAQ %s with serial no %s' , ...
      DAQPRD , DAQSNO )
    
  end
  
  
  %%% Preparation %%%
  
  % Pack constants
  C = struct ( 'DAQ' , DAQ , 'NSPDUR' , NSPDUR , 'MAXCRG' , MAXCRG , ...
    'PRTSID' , PRTSID , 'PRTCRG' , PRTCRG , 'PUMPNO' , PUMPNO ) ;
  
  % DAQ digital port set to output
  DaqDConfigPort ( DAQ , C.PRTSID , 0 ) ;
  DaqDConfigPort ( DAQ , C.PRTCRG , 0 ) ;
  
  % Make sure that all digital pins are off
  DaqDOut ( C.DAQ , C.PRTSID , 0 ) ;
  DaqDOut ( C.DAQ , C.PRTCRG , 0 ) ;
  
  % Remove unecessary variables
  clearvars  -except  MC C
  
  
  %%% Run controller %%%
  
  % Error message , empty means no error
  E = [] ;
  
  % We need to catch errors to guarantee we turn off the daq device
  try
    
    metdaqout_run ( MC , C )
    
  catch  E
  end
  
  % Guarantee that DAQ digital pins are all off
  DaqDOut ( C.DAQ , C.PRTSID , 0 ) ;
  DaqDOut ( C.DAQ , C.PRTCRG , 0 ) ;
  
  % And that pumps have stopped
  DaqAOut ( C.DAQ , 0 , 0 ) ;
  DaqAOut ( C.DAQ , 1 , 0 ) ;
  
  % Rethrow any errors
  if  ~ isempty ( E )  ,  rethrow ( E )  ,  end
  
  
end % metdaqout


%%% Controller function %%%

function  metdaqout_run ( MC , C )
  
  
  %%% Constants %%%
  
  % Set of MET signal ID's , fields name each signal and contain id value
  MSID = MC.SIG' ;
  MSID = struct ( MSID { : } ) ;
  
  % Receive MET signals in blocking mode
  WAIT_FOR_MSIG = 1 ;
  
  % Reports that switch all signal id and cargo digital pins off.
  SIDOFF = uint8 ( [ 0 , C.PRTSID , 0 ] ) ;
  CRGOFF = uint8 ( [ 0 , C.PRTCRG , 0 ] ) ;
  
  
  %%% MET signal variables %%%
  
  % Signal identifier port HID report. First two entries stay constants.
  % The third is set for each MET signal.
  sidrpt = uint8 ( [ 0 , C.PRTSID , 0 ] ) ;
  
  % Same for cargo
  crgrpt = uint8 ( [ 0 , C.PRTCRG , 0 ] ) ;
  
  
  %%% Reward variables %%%
  
  % Currently selected pump , defaults to pump 1. The next mreward cargo is
  % added to this pump's stop deadline.
  pump = 1 ;
  
  % Pump stop deadline , a time in the future after which the pump will
  % turn off. Zero if not currently running.
  pstop = zeros ( C.PUMPNO , 1 ) ;
  
  % The latest time measurement taken
  tim = Inf ;
  
  
  %%% Complete MET initialisation %%%
  
  % Send mready signal , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Report
  met (  'print'  ,  sprintf ( ...
    'MET controller %d initialised: metdaqout' , MC.CD )  ,  'L'  )
  
  % Flush any outstanding messages to terminal
  met ( 'flush' )
  
  % Wait for synchronising ready signal
  [ ~ , ~ , sig ] = met ( 'recv' , WAIT_FOR_MSIG ) ;
  
  % Return if any mquit signal received
  if  any ( sig  ==  MSID.mquit )  ,  return  ,  end
  
  
  %%% Event loop %%%
  
  while  true
    
    
    % Wait for next event %
    
    % This might be the arrival of MET signals , or it may be a pump
    % stopping deadline.
    
    % If any pump is running
    p = 0  <  pstop ;
    
    if  any ( p )
      
      % Then get the duration until the nearest stopping deadline. We know
      % that all tim < pstop ( p ) because tim was measured to check those
      % deadlines in the previous iteration of the event loop.
      tout = min (  pstop ( p )  -  tim   ) ;
      
    else
      
      % Otherwise no pump is running , so wait indefinitely
      tout = [] ;
      
    end
    
    % Wait for event
    met ( 'select' , tout ) ;
    
    
    % MET signals %
    
    % Look for new MET signals with a non-blocking read
    [ n , ~ , sig , crg ] = met ( 'recv' ) ;
    
    % Remove any mnull signals
    mns =  sig == MSID.mnull ;
    n = n  -  sum ( mns ) ;
    mns = ~ mns ;
    sig = sig ( mns ) ;  crg = crg ( mns ) ;
    
    % There are MET signals to process
    if  n

      % Return if any mquit received
      if  any ( sig  ==  MSID.mquit )  ,  return  ,  end

      % Find mready signals
       mrs =  sig == MSID.mready  ;
      nmrs = sum ( mrs ) ;

      % Has mready trigger been received?
      if  any ( crg ( mrs )  ==  MC.MREADY.TRIGGER )

        % Send mready reply , then
        met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;

      end

      % Filter out mready signals
      if  nmrs

        n =  n - nmrs  ;

        mrs = ~ mrs ;
        sig = sig ( mrs ) ;
        crg = crg ( mrs ) ;

      end % filter mready

      % Find mreward signals and make a copy of the cargo before rounding
      p = sig  ==  MSID.mreward ;
      mrwcrg = crg ( p ) ;

      % Round cargos down to highest allowable value
      crg ( C.MAXCRG  <  crg ) = C.MAXCRG ;
      
      % Write each signal to the NSP via DAQ
      for  i = 1 : n

        % Transmit MET signal ID
        sidrpt( 3 ) = sig ( i ) ;
        e = PsychHID ( 'SetReport' , C.DAQ , 2 , 4 , sidrpt ) ;
        
        % Error returned
        if  e.n
          fprintf ( 'metDaqDOut error 0x%s. %s: %s\n' , hexstr ( e.n ) ,...
            e.name , e.description ) ;
        end % error

        % Allow NSP collection of signal id ... although USB HID latency
        % makes this step redundant
        WaitSecs ( C.NSPDUR ) ;

        % Transmit MET signal cargo
        crgrpt( 3 ) = crg ( i ) ;
        e = PsychHID ( 'SetReport' , C.DAQ , 2 , 4 , crgrpt ) ;
        
        % Error returned
        if  e.n
          fprintf ( 'metDaqDOut error 0x%s. %s: %s\n' , hexstr ( e.n ) ,...
            e.name , e.description ) ;
        end % error

        % Allow NSP collection of cargo
        WaitSecs ( C.NSPDUR ) ;

        % Turn off signal id pins
        e = PsychHID ( 'SetReport' , C.DAQ , 2 , 4 , SIDOFF ) ;
        
        % Error returned
        if  e.n
          fprintf ( 'metDaqDOut error 0x%s. %s: %s\n' , hexstr ( e.n ) ,...
            e.name , e.description ) ;
        end % error
        
        % Turn off cargo id pins
        e = PsychHID ( 'SetReport' , C.DAQ , 2 , 4 , CRGOFF ) ;
        
        % Error returned
        if  e.n
          fprintf ( 'metDaqDOut error 0x%s. %s: %s\n' , hexstr ( e.n ) ,...
            e.name , e.description ) ;
        end % error

      end % write digital triggers

      % Restore mreward cargos
      crg( p ) = mrwcrg ;
      
      % Find and keep only mrdtype and mreward
      p = p  |  sig == MSID.mrdtype ;
      sig = sig ( p ) ;
      crg = crg ( p ) ;
      
      % Process reward signals in order
      for  i = 1 : numel ( sig )
        
        % Switch selected pump then go to next signal
        if  sig ( i ) == MSID.mrdtype  &&  crg ( i )
          pump = min ( [ crg( i ) , C.PUMPNO ] ) ;
          continue ;
        end
        
        % Here, we know that signal i is mreward with a ms duration cargo
        
        % Pump is not currently running
        if  ~ pstop ( pump )
          
          % Start the pump and record the time that it started , set this
          % as the initial stopping deadline
          DaqAOut ( C.DAQ , pump - 1 , 1 ) ;
          pstop( pump ) = GetSecs ;
          
        end
        
        % Push back stopping deadline for selected pump , convert cargo
        % from milliseconds to seconds
        pstop( pump ) = pstop ( pump )  +  crg ( i ) / 1e3 ;
        
      end % reward signals
      
    end % MET signals
    
    
    % Stop pumps %
    
    % Take a time measurement if at least one pump is running
    if  any ( pstop )  ,  tim = GetSecs ;  end
    
    % Check each pump
    for  i = 1 : C.PUMPNO
      
      % Pump not running or deadline not reached , go to next pump
      if  ~ pstop ( i )  ||  tim < pstop ( i )
        continue
      end
      
      % Shut off the pump
      DaqAOut ( C.DAQ , i - 1 , 0 ) ;
      pstop( i ) = 0 ;
      
    end % pumps
    

  end % event loop
  
end % metdaqout_run


%%% Subroutines %%%

% Read in MET .csv file with the specific DAQ model name and serial number
function  [ DAQPRD , DAQSNO ] = readdaqpar
  
  % Location of metdaqout.csv , first get containing directory then add
  % file name
  f = fileparts ( which ( 'metdaqout' ) ) ;
  f = fullfile ( f , 'metdaqout.csv' ) ;
  
  % Make sure that the file exists
  if  ~ exist ( f , 'file' )
    
    error ( 'MET:metdaqout:csv' , 'metdaqout: Can''t find %s' , f )
    
  end
  
  % Parameter name set
  PARNAM = { 'DAQPRD' , 'DAQSNO' } ;
  
  % Read in parameters
  p = metreadcsv ( f , PARNAM ) ;
  
  % Must have returned strings
  if  ~ isvector ( p.DAQPRD )  ||  ~ ischar ( p.DAQPRD )
    error ( 'MET:metdaqout:csv' , 'metdaqout: DAQPRD must be string' )
  elseif  ~ isvector ( p.DAQSNO )  ||  ~ ischar ( p.DAQSNO )
    error ( 'MET:metdaqout:csv' , 'metdaqout: DAQSNO must be string' )
  end
  
  % Map to outputs
  DAQPRD = p.DAQPRD ;
  DAQSNO = p.DAQSNO ;
  
end % readdaqpar

