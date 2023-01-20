
function  metdaqeye ( MC )
% 
% metdaqeye ( MC )
% 
% Matlab Electrophysiology Toolbox child controller function. An analogue
% copy of the eye positions will be collected using a USB-1208fs DAQ
% device. Communication is mediated via PsychToolbox Daq functions. Eye
% samples are streamed from a peripheral eye-tracker as voltages that are
% converted into degrees of visual field from the centre of the screen,
% where up and right are in positive directions. Buffers eye positions
% until it is able to write to the eye position POSIX shared memory ; this
% is a circular buffer that stores up to 5 seconds of binoccular eye
% positions. Expects low voltages to code eye positions near the the
% left/top of the screen and high voltages to code positions near the
% right/bottom of the screen. Mouse positions during a button press are
% also buffered and written to 'eye' shm if the metscrnpar.csv touch
% parameter is non-zero ; if no DAQ device is connected but touch is
% non-zero then the controller will write only mouse positions.
% 
% It is possible to obtain eye positions and pupil diameters digitally,
% over a network. The analogue inputs to the USB-DAQ are ignored, in this
% case. See notes regarding the metdaqeye.csv parameter file for details.
% 
% The format of data written to shared memory is a simple N by 5 double
% matrix. Each row is a single sample of the binoccular eye position. The
% columns contain, in this order: time stamp , left horizontal , left
% vertical , right horizontal , right vertical. The time stamp is a
% PTB-style measurement in seconds taken by the local system upon arrival
% of each sample ; it is the best available estimate but will contain
% scheduling jitter. Eye positions are written to shared memory in degrees
% of visual field from the centre of the screen, where up and right are
% positive and left and down are negative. Mouse positions are written with
% a similar format, including only the first three columns: time,
% horizontal, vertical.
% 
% Valid eye positions must not exceed velocity and accelleration thresholds
% of 30 deg/s and 8000 deg/s^2. See Rayner et al. 2007. Vision Research,
% 47(21), 2714–2726.
% 
% NOTE: Depends on customised DaqAInScan.m that checks for device serial
% number, and discards no data if options.nodiscard is true.
% 
% NOTE: USB-1208fs pins 1 , 2 , 4 , 5 , 7 , 8 , 10 , 11 seem to correspond
% to Daq toolbox 'channels' 8 , 9 , 10 , 11 , 12 , 13 , 14 , 15. Thus, if
% eye positions go to pins 1 , 4 , 7 , and 10 then read from channels 8 ,
% 10 , 12 , and 14.
% 
% NOTE: Constant VOLRNG is a two-element row vector with the minimum and
% maximum voltage that will be output from the eye-tracker. Set to -5 to +5
% Volts.
% 
% NOTE: Writes to 'eye' shared memory, so this must be specified in the
% .cmet file.
% 
% NOTE: Reads the USB-DAQ device product name and serial number from
% metdaqeye.csv, a MET .csv file. File also specifies whether there is a
% digital network source of eye data ; if there is, then host and server IP
% addresses and ports must be provided. Must have column headers
% param,value and list parameters DAQPRD, DAQSNO, EYESRC, HOSTIP, HOSTPT,
% SERVIP, SERVPT, XYSWAP. EYESRC is a string saying what the source of eye
% positions is ; if is it usbdaq then the USB-DAQ device is used to collect
% analogue copies of the eye positions ; if it is any other valid string
% then the USB-DAQ device is not used, and all eye data is collected
% digitally ; valid strings for digital streaming are smiivx (SMI iViewX,
% uses MET utility ivxudp). HOSTIP and SERVIP must be valid IPv4 addresses,
% and are taken as strings. HOSTPT and SERVPT must be valid port numbers,
% taken as numeric values. Here, HOST refers to the local system running
% MET, and SERVer refers to the remote eye-tracking system. XYSWAP is a
% binary flag that, when non-zero says to take the left eye to be the right
% eye and vice-versa ; this might be necessary if the eye tracker
% mis-labels the two eyes, as SMI's iViewX does ; note again that this
% option may be necessary for digital streaming but not analogue input,
% depending on how things were wired up.
%   
%   Example:
% 
%   param,value
%   DAQPRD,USB-1208FS
%   DAQSNO,01AC196D
%   EYESRC,usbdaq
%   HOSTIP,123.456.7.8
%   HOSTPT,4567
%   SERVIP,123.456.7.9
%   SERVPT,5476
%   XYSWAP,1
%
% Written by Jackson Smith - December 2016 - DPAG, University of Oxford
% 
  
  
  %%% Environment check %%%
  
  % Make sure that the controller can write to 'eye' shared memory
  if  ~ any (  strcmp ( MC.SHM( : , 1 ) , 'eye' )  &  ...
             [ MC.SHM{ : , 2 } ]' == 'w'  )
    
    error ( 'MET:metdaqeye:daq' , ...
      [ 'metdaqeye: No write access to ''eye'' shared memory\n' , ...
        '  Make sure that this is set in the .cmet file' ] )
    
  end
  
  
  %%% metdaqeye constants %%%
  
  % MET controller constants
  MCC = metctrlconst ( MC ) ;
  
  % DAQ product and serial number , digital networking parameters
  peye = readdaqpar ;
  
  % Screen parameters
  pscr = metscrnpar ;
  
  % Screen identifier
  if  pscr.screenid  ==  -1
    SCRIND = max ( Screen(  'Screens'  ) ) ;
  else
    SCRIND = pscr.screenid ;
  end
  
  % Stimulus screen pixel dimensions. Assumes that maximum screen index is
  % stumulus screen.
  [ SCRWID , SCRHEI ] = Screen ( 'WindowSize' , SCRIND ) ;
  
  % Pixels per degree of visual field
  PIXDEG = metpixperdeg (  pscr.width  ,  SCRWID  ,  pscr.subdist  ) ;
  
  % Convert screen width and height units from pixels to visual degrees.
  % Remember to change sign of y-axis positions so that down is negative
  % and up is positive.
  SCRWID = + SCRWID  /  PIXDEG ;
  SCRHEI = - SCRHEI  /  PIXDEG ;
  
  % Voltage range [ min , max ] that maps to the left/top and right/bottom
  % of the screen
  VOLRNG = [ -5 , +5 ] ;
  
  % Difference of minimum and maximum voltage
  VOLDIF = diff ( VOLRNG ) ;
  
  % Binoccular eye position sampling rate in Hz i.e. samples / second
  EYESHZ = MCC.SHM.EYE.SHZ ;
  
  % Duration of one eye position sample, in seconds
  EYEDUR = 1 / EYESHZ ;
  
  % Duration of one touchscreen/mouse sample, in seconds
  MUSDUR = 1 / MCC.SHM.EYE.MOUSEPOLL ;
  
  % Duration, in seconds, of circular buffer.
  BUFDUR = 5 ;
  
  % Maximum frequency of writes to eye shared memory , in hertz
  FEYESW = 250 ;
  
  % Minimum duration between writes to eye shared memory
  DEYESW = 1  /  FEYESW ;
  
  % Map columns of DaqAInScan output argument 'data' to eyes , this is also
  % used to get digital stream data so be careful if you need to change
  % this
  DAQMAP = struct ( 'XLEFT'  , 1 , 'YLEFT'  , 2 , ...
                    'XRIGHT' , 3 , 'YRIGHT' , 4 ) ;
	
	% Touchscreen/mouse flag , raised if mouse positions can drive the task
  FMOUSE = pscr.touch ;
  if  FMOUSE
    met (  'print' ,  'metdaqeye: touchscreen/mouse positions enabled' ,...
      'L'  )
  end
	
	
	%  Input options struct for PsychToolbox DaqAInScan  %

  % Single ended input channel , values 8 to 15 , corresponding to pins 1,
  % 4, 7, and 10 on USB-1208fs.
  options.channel = [ 8 , 10 , 12 , 14 ] ;

  % Gain multiplier code , for +/-5 volts
  options.range = 2  *  ones ( size ( options.channel ) ) ;

  % Sampling rate in samples/channel/s
  options.f = EYESHZ ;

  % Immediate transfer mode on 1 or off 0.
  options.immediate = 1 ;

  % Number of data points to collect , no limit
  options.count = Inf ;

  % Release time , must be updated on every call to DaqAInScanContinue
  options.ReleaseTime = 0 ;

  % Maximum processing time per invocation. One and a quarter eye samples
  % long. Should make sure that at least one sample is returned with each
  % call to DaqAInScan.
  options.secs =  1  /  MCC.SHM.EYE.EYEPOL ;

  % Tells us what it's doing
  options.print = 0 ;

  % Home-made option. Don't discard any data!
  options.nodiscard = 1 ;
  
  
  %%% Networking %%%
  
  % Defaults
  DAQFLG = 'd' ;
  feyenet = cell ( 1 , 3 ) ;
  
  % See whether eye data is being obtained over a network. Note here that
  % DAQFLG will be 'a' for analogue and 'd' for digital. If it becomes zero
  % then an error has occurred. feyenet will be a three-element function
  % handle cell-array vector, with order { opening function , reading
  % function , closing function }. The reading function has the form
  % [ tim , teye , gaze , diam ] = feyenet{ 2 }( ) returning local
  % timestamp taken just after collecting eye data, eye time stamps from
  % remote system, gaze positions and pupil diameters with column order:
  % [ x-left, y-left, x-right, y-right ] ; gaze positions must be
  % normalised to values between 0 and 1, where coordinate (0,0) is the
  % top-left corner of the stimulus screen.
  switch  peye.EYESRC
    
    % No networking , gather analogue copy of eye positions
    case  'usbdaq'
      
      str = sprintf (  [ 'metdaqeye: reading analogue gaze ' , ...
        'position from USB-DAQ %s with serial no %s' ]  ,  ...
        peye.DAQPRD  ,  peye.DAQSNO  ) ;
      
      DAQFLG = 'a' ;
      
    % Networking , SMI iViewX UDP stream provides positions and diameters
    case  'smiivx'
      
      str = sprintf (  [ 'metdaqeye: reading digital gaze ' , ...
        'position and pupil diameter from SMI iViewX\n  host-ip %s,' , ...
        'host-port %d, iViewX-ip %s, iViewX-port %d' ]  ,  ...
        peye.HOSTIP , peye.HOSTPT , peye.SERVIP , peye.SERVPT  ) ;
      
      feyenet = {  @( ) ivxudp( 'o' , peye.HOSTIP , peye.HOSTPT , ...
                                      peye.SERVIP , peye.SERVPT )  ;
                   @( ) ivxudp( 'r' )  ;
                   @( ) ivxudp( 'c' )  } ;
      
    % Unrecognised option
    otherwise
      
      error (  'MET:metdaqeye:net'  ,  [ 'metdaqeye: ' , ...
        '.csv parameter EYESRC value unrecognised: %s\n' , ...
        '  Recognised strings are:\n  usbdaq (analogue mode)\n' , ...
        '  smiivx (SensoMotoric Instruments, iViewX)' ] ,  ...
        peye.EYESRC  )
        
  end % networking
  
  % Tell user what we're using
  met (  'print'  ,  str  ,  'L'  )
  
  
  %%% Search for DAQ device %%%
  
  % List of all devices
  DAQ = PsychHID ( 'devices' ) ;
  
  % Find devices with the same product name and serial number
  DAQ = find (  strcmp ( peye.DAQPRD , { DAQ.product      } )  &  ...
                strcmp ( peye.DAQSNO , { DAQ.serialNumber } )  ) ;
  
  % Find the Daq device index in this set
  DAQ = intersect ( DAQ , DaqDeviceIndex ) ;
  
  % Problem , analogue mode and can't find the DAQ device
  if  DAQFLG  ==  'a'  &&  isempty ( DAQ )
    
    % Touchscreen/mouse input is not available
    if  ~ FMOUSE
    
      error (  'MET:metdaqeye:input'  ,  [ 'metdaqeye: ' , ...
        'Unable to find USB-DAQ %s with serial no %s in analogue ' , ...
        'mode , and touchscreen/mouse is not enabled' ]  ,  ...
        peye.DAQPRD  ,  peye.DAQSNO  )
    
    end % no touch/mouse
    
    % Touch/mouse is available. No problem! Lower the DAQ flag altogether.
    DAQFLG = false ;
    
    % Tell user
    met (  'print'  ,  sprintf ( [ 'metdaqeye: can''t find USB-DAQ ' , ...
      '%s with serial no %s in analogue mode , using touchscreen/' , ...
      'mouse' ] , peye.DAQPRD  ,  peye.DAQSNO )  ,  'E'  )
    
  end % no DAQ
  
  
  %%% Preparation %%%
  
  % Pack controller's constants
  C = struct ( 'DAQ' , DAQ , 'SCRWID' , SCRWID , 'SCRHEI' , SCRHEI , ...
    'VOLRNG' , VOLRNG , 'VOLDIF' , VOLDIF , 'EYESHZ' , EYESHZ , ...
    'EYEDUR' , EYEDUR , 'MUSDUR' , MUSDUR , 'BUFDUR' , BUFDUR , ...
    'DAQMAP' , DAQMAP , 'OPTIONS', options, 'PIXDEG' , PIXDEG , ...
    'FMOUSE' , FMOUSE , 'DAQFLG' , DAQFLG , 'XYSWAP' , peye.XYSWAP , ...
    'FEYESW' , FEYESW , 'DEYESW' , DEYESW , 'HMIROR' , pscr.hmirror , ...
    'VMIROR' , pscr.vmirror ) ;
  
  % Remove unnecessary variables
  clearvars  -except  MC C feyenet
  
  % Start eye data collection
  switch  C.DAQFLG
    
    % Analogue gaze positions
    case  'a'  ,  DaqAInScanBegin ( C.DAQ , C.OPTIONS ) ;
      
    % Digital network streaming
    case  'd'
      
      % Catch any error if this fails to establish communication
      try
        
        feyenet{ 1 }( ) ;
        
      catch  E
        
        % Something went wrong and touchscreen/mouse input is not enabled
        if  ~ C.FMOUSE
          
          error (  'MET:metdaqeye:net'  ,  [ 'metdaqeye: ' , ...
            'Digital networking , eye-tracker connection failure , ' ,...
            'touchscreen/mouse is not enabled.\n  Error: %s' ]  ,  ...
            E.message  )
          
        % Touch/mouse is enabled ...
        else
          
          % ... so disable eye streaming altogether
          C.DAQFLG = false ;
          
          % Tell user
          met (  'print'  ,  sprintf ( [ 'metdaqeye: can''t connect ' , ...
            'to eye-tracker for digital streaming , using ' , ...
            'touchscreen/mouse\n  Error msg: %s' ] , E.message )  ,  'E'  )
          
        end % streaming error
        
      end % open communication with remote eye tracker
      
  end % start data collection
  
  
  %%% Run controller %%%
  
  % Error message , empty means no error
  E = [] ;
  
  % We need to catch errors to guarantee we turn off the daq device
  try
    
    metdaqeye_run ( MC , C , feyenet{ 2 } )
    
  catch  E
  end
  
  % Attempt to stop data collection
  switch  C.DAQFLG
    case  'a'  ,  DaqAInScanEnd ( C.DAQ , C.OPTIONS ) ;
    case  'd'  ,  feyenet{ 3 }( ) ;
  end
  
  % Rethrow any errors
  if  ~ isempty ( E )  ,  rethrow ( E )  ,  end
  
  
end % metdaqeye


%%% Controller function %%%

function  metdaqeye_run ( MC , C , feyenet )
  
  
  %%% Constants %%%
  
  % Set of MET signal ID's , fields name each signal and contain id value
  MSID = MC.SIG' ;
  MSID = struct ( MSID { : } ) ;
  
  % Receive MET signals in blocking mode
  WAIT_FOR_MSIG = 1 ;
  
  % Mapping from DaqAInScan output , horizontal and vertical column indeces
  if  C.XYSWAP
    
    % Take left as right and vice versa
    XI = [ C.DAQMAP.XRIGHT , C.DAQMAP.XLEFT ] ;
    YI = [ C.DAQMAP.YRIGHT , C.DAQMAP.YLEFT ] ;
    
  else
    
    % Map left to left , right to right
    XI = [ C.DAQMAP.XLEFT , C.DAQMAP.XRIGHT ] ;
    YI = [ C.DAQMAP.YLEFT , C.DAQMAP.YRIGHT ] ;
    
  end % DaqAInScan output mapping horizontal and vertical
  
  
  % Mapping from DaqAInScan output , column indices ordering left to right
  % eye positions and horizontal to vertical
  if  C.XYSWAP
    
    % Take left as right and vice versa
    DASMAP = [ C.DAQMAP.XRIGHT ;
               C.DAQMAP.YRIGHT ;
               C.DAQMAP.XLEFT  ;
               C.DAQMAP.YLEFT  ] ;
    
  else
    
    % Map left to left , right to right
    DASMAP = [ C.DAQMAP.XLEFT  ;
               C.DAQMAP.YLEFT  ;
               C.DAQMAP.XRIGHT ;
               C.DAQMAP.YRIGHT ] ;
  
  end % DaqAInScan output mapping
           
	% Met controller constants , pull out standard column indeces for shared
	% eye positions
  MCC = metctrlconst ;
  
  NCOL = MCC.SHM.EYE.NCOL ;
  TIME = MCC.SHM.EYE.COLIND.TIME ;
  EYEMAP = [ MCC.SHM.EYE.COLIND.XLEFT  , MCC.SHM.EYE.COLIND.YLEFT , ...
             MCC.SHM.EYE.COLIND.XRIGHT , MCC.SHM.EYE.COLIND.YRIGHT ] ;
           
	% Eye data buffering loop. This is a for loop that will provide each set
	% of data in turn. These include field names, data names, and data
	% availability flags needed to perform the buffering for each data type.
  % Column order { gaze positions , pupil diameters } , each sub-cell has
  % column order { num. samples field , next row index field , buffer
  % name , data type , availability flag }.
  BUFFOR = {  { 'n_eye' , 'i_eye' , 'eye' , 'gaze' , C.DAQFLG        }, ...
              { 'n_pup' , 'i_pup' , 'pup' , 'diam' , C.DAQFLG == 'd' }  } ;
           
	clear  MCC
  
  
  %%% Allocate buffer %%%
  
  % eye: gaze positions , pup: pupil diameter , mouse: touchscrn/mouse pos
  
  % Number of samples in buffer
  b.n_eye   = 0 ;
  b.n_pup   = 0 ;
  b.n_mouse = 0 ;
  
  % Index of the next available row in the buffer , starts from 0 and
  % ranges up to b.size - 1  i.e. C-style indexing as opposed to
  % Matlab-style indexing which starts at 1
  b.i_eye   = 0 ;
  b.i_pup   = 0 ;
  b.i_mouse = 0 ;
  
  % Eye position buffer , a double matrix with columns: [ time , left x ,
  % left y , right x , right y ]. Kept empty if data not available.
  b.eye   = [] ;
  b.pup   = [] ;
  b.mouse = [] ;
  
  % Total number of samples , at least one
  b.size = max ( [  1  ,  ceil( C.BUFDUR  *  C.EYESHZ )  ] ) ;
  
  %   Allocate buffer space for data channels that are enabled   %
  
    % Eye position buffer
    if  C.DAQFLG  ,  b.eye = zeros ( b.size , NCOL ) ;  end

    % Pupil diameter buffer
    if  C.DAQFLG  ==  'd'  ,  b.pup = zeros ( b.size , NCOL ) ;  end

    % Mouse position buffer
    if  C.FMOUSE  ,  b.mouse = zeros ( b.size , 3 ) ;  end
    
  % The last time that the mouse was polled , in seconds
	b.mtime = 0 ;
  
  % The last time that buffered data was written out to eye shared memory
  b.wtime = 0 ;
  
  % New data flag , low when new data is ready. Initialised high, hence
  % there is no new data ... yet!
  datflg = true ;
  
  
  %%% Complete MET initialisation %%%
  
  % Send mready signal , non-blocking
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Report
  met (  'print'  ,  sprintf ( ...
    'MET controller %d initialised: metdaqeye' ,...
    MC.CD )  ,  'L'  )
  
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
      
      % Send mready reply , then
      met ( 'send' , MSID.mready , MC.MREADY.REPLY , [] ) ;
      
    end
    
    
    %-- Sample eye positions --%
    
    if  C.DAQFLG
    
      % Determine how to get eye data
      switch  C.DAQFLG
        
        % Sample analogue gaze positions
        case  'a'
      
          % DaqAInScan will read until this time in the future
          C.OPTIONS.ReleaseTime( 1 ) = GetSecs  +  C.OPTIONS.secs ;

          % Read eye positions
          [ ~ , D.gaze ] = DaqAInScanContinue ( C.DAQ , C.OPTIONS , true );

          % Take a time measurement immediately following eye position read
          tim = GetSecs  *  ~ isempty (  D.gaze  ) ;
          
          % Was data returned?
          if  tim %#ok
            
            % Clip voltage values to minimum and maximum.
            D.gaze( D.gaze < C.VOLRNG( 1 ) ) = C.VOLRNG( 1 ) ;
            D.gaze( D.gaze > C.VOLRNG( 2 ) ) = C.VOLRNG( 2 ) ;

            % In-house DaqAInScan might return NaN place holders. Clip
            % these too.
            D.gaze( isnan( D.gaze ) ) = C.VOLRNG( 2 ) ;

            % Normalise volts, mapping -5 to -0.5 and +5 to 0.5
            D.gaze = ( D.gaze - C.VOLRNG( 1 ) )  /  C.VOLDIF  -  0.5 ;

            % Number of new data points
            N.gaze = size ( D.gaze , 1 ) ;

            % Compute sample times
            teye = C.EYEDUR  *  ( 1 - N.gaze : 0 )  +  tim ;
            
          end % data returned
          
        % Digital eye data
        case  'd'
          
          % Read eye samples
          [ tim , teye , D.gaze , D.diam ] = feyenet ( ) ;
          
          % Was data returned?
          if  tim
            
            % Normalise gaze position values to [ -0.5 , 0.5 ]
            D.gaze = D.gaze  -  0.5 ;

            % Convert time stamps to local system time. This is the naive
            % way. Assume that the last time stamp was taken not so long
            % before the local time measurement. So subtract the last time
            % stamp from all other time stamps, then add the local time.
            teye = teye  -  teye ( end )  +  tim ;

            % Number of new data points
            N.gaze = size ( D.gaze , 1 ) ;
            N.diam = size ( D.diam , 1 ) ;
            
          end % data returned
          
      end % get eye data
      
      % New data is available
      if  tim
        
        % Lower data flag to signal new data
        datflg = false ;
        
        
        %-- Unit conversion --%

        % Change unit of gaze positions to degrees of visual field
        D.gaze( : , XI ) = C.SCRWID  *  D.gaze( : , XI ) ;
        D.gaze( : , YI ) = C.SCRHEI  *  D.gaze( : , YI ) ;
        
        
        %-- Buffering --%

        % Buffer gaze positions , then pupil diameter if it is available
        for  I = BUFFOR
        
          % Assign meaningful names to data set. nfn - number of samples
          % field name , ifn - index field name , bfn - buffer field name ,
          % dty - data type , flg - availability flag (up i.e. non-zero
          % means true)
          [ nfn , ifn , bfn , dty , flg ] = I{ 1 }{ : } ;
          
          % Data is not available , continue to next data type
          if  ~ flg  ,  continue  ,  end
          
          % Index vector of new samples , convert from C-style indexing to
          % Matlab-style indexing
          i = mod ( b.( ifn ) : b.( ifn ) + N.( dty ) - 1 , b.size )  +  1;

          % Remember the new value of b.( ifn ). Recall that b.( ifn ) is
          % the first index to start placing new data from the next read.
          b.( ifn ) = mod ( b.( ifn ) + N.( dty ) , b.size ) ;

          % Number of samples in buffer
          b.( nfn ) = min ( [  b.size  ,  b.( nfn ) + N.( dty )  ] ) ;

          % Compute sample times
          b.( bfn )( i , TIME ) = teye ;

          % Store samples
          b.( bfn )( i , EYEMAP ) = D.( dty ) ( : , DASMAP ) ;
          
        end % buffer data
        
      % No new eye data was available
      else
        
        % Wait for the duration of one analogue eye poll , or until a MET
        % signal arrives
        tim = WaitSecs ( C.OPTIONS.secs ) ;
        
        % Jump back to the head of the loop to check MET signals , unless
        % it is time to get touch/mouse positions
        if  ~ ( C.FMOUSE  &&  tim - b.mtime  >  C.MUSDUR )
          
          continue ;
          
        end % conditional loop continue
        
      end % new eye data
    
    end % eye pos
    
    
    %-- Sample mouse position --%
    
    if  C.FMOUSE
      
      % Measure time
      tim = GetSecs ;
      
      % The mouse was polled too recently
      if  tim - b.mtime  <  C.MUSDUR
        
        % If there is no eye tracking data then wait for approximately the
        % remainder of the time until the mouse may be polled again
        if  ~ C.DAQFLG
          
          % Time remaining until next poll , must not be less than zero
          tim = max ( [  0  ,  b.mtime  +  C.MUSDUR  -  tim  ] ) ;
          
          % Wait until poll deadline , or until MET signals arrive
          tim = WaitSecs ( tim ) ;
          
        end % wait for poll deadline
        
      % Enough time has passed , poll the mouse
      else
        
        % Read current mouse position
        [ x_mouse , y_mouse , buttons_mouse ] = GetMouse ;

        % Take time measurement
        b.mtime = GetSecs ;

        % New data is available
        if  any ( buttons_mouse )

          % Lower data flag to signal new data
          datflg = false ;

          % Unit conversion , pixels to degrees
          x_mouse = x_mouse  /  C.PIXDEG ;
          y_mouse = y_mouse  /  C.PIXDEG ;

          % Swap coordinate systems PTB --> MET , remember that SCRHEI is
          % negative for ease of processing eye positions
          x_mouse = x_mouse  -  C.SCRWID / 2 ;
          y_mouse = - C.SCRHEI / 2  -  y_mouse ;
          
          % PTB window horizontally mirrored , reflect mouse x position
          if  C.HMIROR  ,  x_mouse = - x_mouse ;  end
          
          % PTB window horizontally mirrored , reflect mouse x position
          if  C.VMIROR  ,  y_mouse = - y_mouse ;  end


          %-- Buffering --%

          % Index vector of new samples , convert from C-style indexing to
          % Matlab-style indexing
          i = b.i_mouse  +  1 ;

          % Remember the new value of b.i_mouse. Recall that b.i_mouse is
          % the first index to start placing new data from the next read.
          b.i_mouse = mod ( b.i_mouse + 1 , b.size ) ;

          % Number of samples in buffer
          b.n_mouse = min ( [  b.size  ,  b.n_mouse + 1  ] ) ;

          % Add samble
          b.mouse( i , : ) = [ b.mtime , x_mouse , y_mouse ] ;

        end % new mouse data
        
      end % check time since last mouse poll
      
    end % mouse position
    
    
    %-- Respond to state of new data --%
    
    % No new data or minimum duration between writes not yet met , iterate
    % event loop and try again
    if  datflg  ||  tim < b.wtime + C.DEYESW 
      continue
    end
    
    
    %-- Shared memory --%
    
    % Check whether any shared memory is ready for reading or writing.
    % Note that timeout argument is zero so that select will return as soon
    % as possible ; the man page for system call select() suggests this
    % as a way to poll file descriptors for availability, such as those
    % that MET uses to monitor the shared memory.
    [ ~ , ~ , shm ] = met ( 'select' , 0 ) ;
    
    % No shared memory is ready
    if  isempty ( shm )  ,  continue  ,  end
    
    % Which shared memory is writable?
    w = [ shm{ : , 2 } ]  ==  'w' ;
    
    % No shared memory is writable , or eye position shared memory is not
    % writable
    if  ~ any ( w )  ||  ...
        ~ any ( strcmp ( shm( w , 1 ) , 'eye' ) )
      
      continue
      
    end
    
    % Default indeces
    i = [] ;  j = [] ;  k = [] ;
    
    % Prepare an index vector that chronologically orders the buffered eye
    % position data.
    if  C.DAQFLG
      
      % Notice that if the buffer is not full, then the starting index must
      % be 1 (hence i = 0) ; otherwise, the circular buffer is full and the
      % next available position is also the oldest sample (hence i =
      % b.i_eye).
      if  b.n_eye  <  b.size
        i = 0 ;
      else
        i = b.i_eye ;
      end
      
      % Convert to Matlab-style index.
      i = mod (  i : i + b.n_eye - 1  ,  b.size  )  +  1 ;
      
    end % eye buf chrono. index vector
    
    % Build a similar chronological index for pupil diameter
    if  C.DAQFLG  ==  'd'
      if  b.n_pup  <  b.size  ,  j = 0 ;  else  j = b.i_pup ;  end
      j = mod (  j : j + b.n_pup - 1  ,  b.size  )  +  1 ;
    end
    
    % Build a similar chronological index for mouse positions
    if  C.FMOUSE
      if  b.n_mouse  <  b.size  ,  k = 0 ;  else  k = b.i_mouse ;  end
      k = mod (  k : k + b.n_mouse - 1  ,  b.size  )  +  1 ;
    end
    
    % Write eye and mouse positions to shared memory
    if  met (  'write' ,  'eye' ,  ...
          b.eye( i , : ) ,  b.pup( j , : ) ,  b.mouse( k , : )  )
        
      % Get the most accurate write time , jitter notwithstanding
      b.wtime = GetSecs ;
      
      % Data was successfully written , reset the buffers ...
      if  C.DAQFLG
        b.n_eye = 0 ;
        b.i_eye = 0 ;
      end
      
      if  C.DAQFLG  ==  'd'
        b.n_pup = 0 ;
        b.i_pup = 0 ;
      end
      
      if  C.FMOUSE
        b.n_mouse = 0 ;
        b.i_mouse = 0 ;
      end
      
      % ... and data flag
      datflg = true ;
      
    end % write to 'eye' shm
    
    
  end % event loop
  
end % metdaqeye_run


%%% Subroutines %%%

% Read in MET .csv file with the specific DAQ model name and serial number
function  p = readdaqpar
  
  % Location of metdaqeye.csv , first get containing directory then add
  % file name
  f = fileparts ( which ( 'metdaqeye' ) ) ;
  f = fullfile ( f , 'metdaqeye.csv' ) ;
  
  % Make sure that the file exists
  if  ~ exist ( f , 'file' )
    
    error ( 'MET:metdaqeye:csv' , 'metdaqeye: Can''t find %s' , f )
    
  end
  
  % Parameter name set
  PARNAM = { 'DAQPRD' , 'DAQSNO' , 'EYESRC' , 'HOSTIP' , 'HOSTPT' , ...
    'SERVIP' , 'SERVPT' , 'XYSWAP' } ;
  
  % Numeric parameters
  NUMPAR = { 'HOSTPT' , 'SERVPT' , 'XYSWAP' } ;
  
  % Read in parameters
  p = metreadcsv ( f , PARNAM , NUMPAR ) ;
  
  % Must be strings
  for  PARNAM = { 'DAQPRD' , 'DAQSNO' , 'EYESRC' , 'HOSTIP' , 'SERVIP' } ;
  
    fn = PARNAM { 1 } ;
    
    if  ~ isvector ( p.( fn ) )  ||  ~ ischar ( p.( fn ) )
      error ( 'MET:metdaqeye:csv' , 'metdaqeye: %s must be string' , fn )
    end
    
  end % string params
  
  % Must be non-negative integers
  for  PARNAM = { 'HOSTPT' , 'SERVPT' , 'XYSWAP' }
    
    fn = PARNAM { 1 } ;
    
    if  ~ isscalar ( p.( fn ) )  ||  ~ isnumeric ( p.( fn ) )  ||  ...
      mod ( p.( fn ) , 1 )  ||  ~ isreal ( p.( fn ) )  ||  p.( fn ) < 0
    
      error ( 'MET:metdaqeye:csv' , ...
        'metdaqeye: %s must be a non-negative interger' , fn )
      
    end
    
  end % integer params
  
  % Must be a binary flag
  for  PARNAM = { 'XYSWAP' }
    
    fn = PARNAM { 1 } ;
    
    if  p.( fn ) ~= 0  &&  p.( fn ) ~= 1
    
      error ( 'MET:metdaqeye:csv' , ...
        'metdaqeye: %s must have a binary value of either 0 or 1' , fn )
      
    end
    
  end % integer params
  
end % readdaqpar

