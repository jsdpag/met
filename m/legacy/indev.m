
function  [ indevd , iddclose ] = indev
% 
% [ indevd , iddclose ] = indev
% 
% Initialises and returns an input-device descriptor. A function handle is
% given for closing the descriptor. This function must be called before the
% taskcontroller is executed, as the descriptor is required as input.
% 
% An analogue copy of the eye positions will be collected using a
% USB-1208fs DAQ device with serial number 01AC196D. Communication is
% mediated via PsychToolbox Daq functions. Eye samples are streamed from
% iViewX as voltages ranging -/+ 5 volts. Valid eye samples are those that
% do not exceed either a velocity or acceleration threshold. The positions
% returned by .check are the average of all valid positions obtained since
% the last call to .check.
% 
% indevd - scalar struct - The input-device descriptor. This allows us to
%   query what the subject is doing in a manner that is independent of the
%   specific input device ; be it mouse, touchscreen, or eye tracker. This
%   is provided as an argument to taskcontroller so that any device
%   specific resources can be released by the calling function in case of
%   an error. The struct must have at least the following fields
%   
%   .type - string - Human readable tag, such as 'mouse' or 'eye tracker'
%   .check - function handle - [ x , y , newxy , idd ] =
%                                                check ( idd , ptbwin ) -
%     Checks the input device for any new subject response. If there is a
%     new response then newxy logical 1, otherwise it is logical 0. When
%     there is a new response, x and y will each be scalar doubles
%     providing a coordinate relative to the screen, in pixels [ origin at
%     ( 0 , 0 ) ]. Requires the input-device descriptor as input ; returns
%     it as final output argument. Only uses samples with valid data from
%     both eyes ; returns the averaged position of both eyes since last
%     check.
%   .init - function handle - idd = init ( idd, ptbwin ) - Prepares the
%     input device for a new trial. Takes and returns the input device
%     descriptor. e.g. indevd = indevd.init ( indevd )
%   .close - function handle - idd = close ( idd , ptbwin ) - Does any
%     clean-up that the input device needs at the end of a trial. Takes and
%     returns the input-device descriptor.
%   .indev_buf - struct - Buffered eye positions. Fields .time, .x, and .y
%     contain the vector of PTB-style time measurements, the x and y
%     coordinates with left and right eye data in the 1st and 2nd column.
%     Has additional field 'N' giving the number of buffere samples. New
%     samples are buffered starting from row index N + 1. Thus, a simple
%     way to read and wipe buffered data on the fly is to set N = 0 after
%     using the buffered data. Also keeps field 'valid' , a vector that is
%     that is 1 if an eye sample does not exceed the velocity or
%     acceleration threshold.
%   .tswitch - scalar double , integer > 0 - Number of new samples in a row
%     that must land on a new target before the current target is
%     considered to switch to the new one.
%   
%
%   ptbwin is the PTB window descriptor in taskcontroller.
% 
% iddclose - function handle - Takes the input-device descriptor and
%   releases any associated resources.
% 
% 
% NOTE: Depends on customised DaqAInScan that checks for device serial
% number, and discards no data if options.nodiscard is true.
% 
% 
% Valid eye positions must not exceed velocity and accelleration thresholds
% of 30 deg/s and 8000 deg/s^2. See Rayner et al. 2007. Vision Research,
% 47(21), 2714–2726.
% 
% Written by Jackson Smith - Jan 2016 - DPAG, University of Oxford
% 
  
  
  %%% Constants %%%
  
  % Type of input device
  INDTYP = 'analogue eye positions' ;
  
  % Serial number of the USB-1208fs to read from
  DAQSNO = '01AC196D' ;
  
  % Product description of DAQ
  DAQPRD = 'USB-1208FS' ;
  
  % Voltage range [ min , max ] that maps to the left/top and right/bottom
  % of the screen
  VOLRNG = [ -5 , +5 ] ;
  
  % iViewX out-of-range behaviour , set to clip i.e. max voltage. Samples
  % with this value in the x- or y-axis or more are considered invalid
  IVXORB = VOLRNG ( 2 ) ;
  
  % Velocity and acceleration thresholds , in degrees per second and
  % degrees per second-squared. Eye positions that exceed these thresholds
  % are not reported by .check
  VELTHR = 30 ;
  ACCTHR = 8000 ;
  
  % iViewX binoccular sampling rate in Hz i.e. samples / second
  EYESHZ = 500 ;
  
  % iViewX duration of each sample , time difference
  EYETMD = 1 / EYESHZ ;
  
  % Target switch duration , approximate number of seconds that eyes must
  % remain on target. Make this a multiple of eye sample durations.
  TSWITCH = 2 / EYESHZ ;
  
  % Initial buffer size , in seconds. Buffer duration.
  BUFDUR = 10 ;
  
  % Map columns of DaqAInScan output argument 'data' to eyes
  DAQMAP = struct ( 'XLEFT'  , 1 , 'YLEFT'  , 2 , ...
                    'XRIGHT' , 3 , 'YRIGHT' , 4 ) ;
  
  
  %  Input options struct for PsychToolbox DaqAInScan  %

  % Single ended input channel , values 8 to 15 , corresponding to pins 1,
  % 4, 7, and 10 on USB-1208fs.
  options.channel = [ 8 , 10 , 12 , 14 ] ;

  % Gain multiplier code , for +/-5 volts
  options.range = 2  *  ones ( size ( options.channel ) ) ;

  % Sampling rate in samples/channel/s
  options.f = 500 ;

  % Immediate transfer mode on 1 or off 0.
  options.immediate = 1 ;

  % Number of data points to collect , no limit
  options.count = Inf ;

  % Release time , must be updated on every call to DaqAInScanContinue
  options.ReleaseTime = 0 ;

  % Maximum processing time per invocation. Make it 2.5 milliseconds ,
  % about one quarter an inter-flip interval at 85Hz screen refresh rate.
  options.secs = 2.5e-3 ;

  % Tells us what it's doing
  options.print = 0 ;

  % Home-made option. Don't discard any data!
  options.nodiscard = 1 ;
  
  
  %%% Input device descriptor %%%
  
  % Find DAQ device with the correct serial number and product description
  d = PsychHID ( 'devices' ) ;
  d = strcmp ( DAQSNO , { d.serialNumber } )  &  ...
      strcmp ( DAQPRD , { d.product      } ) ;
  d = intersect ( DaqDeviceIndex , find ( d ) ) ;
  
  % Can't find DAQ!
  if  isempty ( d )
    error ( 'Can''t find DAQ %s with serial no. %s' , DAQPRD , DAQSNO )
  end
  
  % Descriptor constants , DTREC1 is delta-time reciprocal to power of 1.
  C.EYESHZ = EYESHZ ;
  C.EYETMD = EYETMD ;
  C.DTREC1 = EYESHZ ;
  C.VOLRNG = VOLRNG ;
  C.IVXORB = IVXORB ;
  C.TSWITCH = TSWITCH ;
  C.VELTHR = VELTHR ;
  C.ACCTHR = ACCTHR ;
  C.BUFDUR = BUFDUR ;
  C.DAQ = d ;
  C.OPTIONS = options ;
  C.DAQMAP = DAQMAP ;
  
  % Run-time constants
  RC.IVXORB = [] ;
  RC.VELTHR = [] ;
  RC.ACCTHR = [] ;
  RC.OPTIONS = [] ;
  
  
  % Allocate buffer.
  b = [  { 'N' , 'time' , 'x' , 'y' , 'valid' }  ;  cell( 1 , 5 )  ] ;
  b = struct ( b { : } ) ;
  
  
  % Pack fields in a cell array. Field 'C' holds constants declared above.
  % 'RC' holds 'run-time' constants determined by the .init function based
  % on the PTB window descriptor's values ; for example, the velocity and
  % acceleration thresholds must be converted from degrees to pixels.
  % tswitch must be an integer value to get past taskcontroller checkin.
  C = { 'type' , INDTYP ;
        'check' , @checkf ;
        'init' , @initf ;
        'close' , @closef ;
        'indev_buf' , b ;
        'tswitch' , 1 ;
         'C' ,  C ;
        'RC' , RC }' ;
	
	% Make descriptor
  indevd = struct ( C { : } ) ;
  
  
  %%% Input device descriptor close function %%%
  
  % Empty function as no special action required
  iddclose = @iddclosef ;
  
  
end % indev


%%% Sub-routines %%%

function  iddclosef ( d )
  
  % Make sure that data collection stopped
  try
    
    closef ( d , [] ) ;
  
  catch E
    
    warning ( getReport ( E ) ) ;
  
  end
  
end % iddclosef

function  d = initf ( d , ptbwin )
  
  
  %%% Run-time constants %%%
  
  % iViewX out-of-range behaviour , sample is not valid if it exceeds this
  % threshold , in pixels. Column order is x-axis , y-axis.
  d.RC.IVXORB = ( d.C.IVXORB - d.C.VOLRNG( 1 ) )  /  diff ( d.C.VOLRNG ) ;
  d.RC.IVXORB = d.RC.IVXORB  .*  ptbwin.size_px  -  1 ;
  
  % Convert thresholds from degrees to pixels
  d.RC.VELTHR = d.C.VELTHR  *  ptbwin.pixperdeg ;
  d.RC.ACCTHR = d.C.ACCTHR  *  ptbwin.pixperdeg ;
  
  % DaqAInScan options
  d.RC.OPTIONS = d.C.OPTIONS ;
  
  % T switch to number of frames i.e. number of samples from .check
  d.tswitch = ceil ( d.C.TSWITCH  /  ptbwin.flipinterval ) ;
  
  
  %%% Allocate/Reset buffer %%%
  
  % Not allocated yet
  if  isempty ( d.indev_buf.N )
    
    % Default number of samples
    d.indev_buf.N = ceil ( d.C.BUFDUR  *  d.C.EYESHZ ) ;
    
    % Allocate memory
    d.indev_buf.time = zeros ( d.indev_buf.N , 1 ) ;
    d.indev_buf.x = zeros ( d.indev_buf.N , 2 ) ;
    d.indev_buf.y = zeros ( d.indev_buf.N , 2 ) ;
    d.indev_buf.valid = false ( d.indev_buf.N , 1 ) ;
  
  % Has been allocated , reset first two samples
  else
    
    d.indev_buf.x( 1 : 2 , : ) = 0 ;
    d.indev_buf.y( 1 : 2 , : ) = 0 ;
    d.indev_buf.valid( 1 : 2 ) = 0 ;
    
  end
  
  % Either way , we initialise N
  d.indev_buf.N = 2 ;
  
  
  %%% Start data collection %%%
  
  DaqAInScanBegin ( d.C.DAQ , d.RC.OPTIONS ) ;
  
  
end % initf


function  d = closef ( d , ~ )
  
  % Stop data collection
  DaqAInScanEnd ( d.C.DAQ , d.C.OPTIONS ) ;
  
  % And trim buffer
  i = 3 : d.indev_buf.N ;
  d.indev_buf.N = d.indev_buf.N - 2 ;
  d.indev_buf.time = d.indev_buf.time ( i ) ;
  d.indev_buf.x = d.indev_buf.x ( i , : ) ;
  d.indev_buf.y = d.indev_buf.y ( i , : ) ;
  
  % Signal empty buffer
  d.indev_buf.N = [] ;
  
end % closef


function  [ x , y , newxy , d ] = checkf ( d , ptbwin )
  
  
  %%% Constants %%%
  
  xi = [ d.C.DAQMAP.XLEFT , d.C.DAQMAP.XRIGHT ] ;
  yi = [ d.C.DAQMAP.YLEFT , d.C.DAQMAP.YRIGHT ] ;
  
  
  %%% Initialise output %%%
  
  x = 0 ; y = 0 ; newxy = false ;
  
  
  %%% Read in new data %%%
  
  % First , set when DaqAInScan will read to
  d.RC.OPTIONS.ReleaseTime( 1 ) = GetSecs  +  d.RC.OPTIONS.secs ;
  
  % Read data
  [ ~ , dat ] = DaqAInScanContinue ( d.C.DAQ , d.RC.OPTIONS , true ) ;
  
  % Number of data points read
  R = size ( dat , 1 ) ;
  
  % No new data
  if  isempty ( dat )  ,  return  ,  end
  
  % Clip voltage values to minimum and maximum.
  dat( dat < d.C.VOLRNG( 1 ) ) = d.C.VOLRNG( 1 ) ;
  dat( dat > d.C.VOLRNG( 2 ) ) = d.C.VOLRNG( 2 ) ;
  
  % In-house DaqAInScan might return NaN place holders. Clip these too.
  dat( isnan( dat ) ) = d.C.VOLRNG( 2 ) ;
  
  % Normalise volts, mapping -5 to 0 and +5 to 1.
  dat = ( dat - d.C.VOLRNG( 1 ) )  /  diff ( d.C.VOLRNG ) ;
  
  % Change units to pixels
  dat( : , xi ) = ptbwin.size_px( 1 )  *  dat( : , xi ) ;
  dat( : , yi ) = ptbwin.size_px( 2 )  *  dat( : , yi ) ;
  
  
  %%% Update buffer %%%
  
  % Double buffer size if too small
  if  numel ( d.indev_buf.time )  <  d.indev_buf.N  +  R
    
    % Resize each buffer component
    for  F = { 'time' , 'x' , 'y' , 'valid' } , f = F { 1 } ;
      
      % Select allocator based on array's type
      if  islogical ( d.indev_buf.( f ) )
        alocf = @false ;
      else
        alocf = @zeros ;
      end
      
      % Extend buffer
      d.indev_buf.( f ) = [  d.indev_buf.( f ) ;
                             alocf( size ( d.indev_buf.( f ) ) )  ] ;
      
    end % buffer components
    
  end % resize buffers
  
  % Buffer indeces where new data will go
  i = d.indev_buf.N + 1 : d.indev_buf.N + R ;
  
  % Add new data
  d.indev_buf.N = i ( end ) ;
  d.indev_buf.time( i ) = d.C.EYETMD  *  ( 1 - R : 0 )  +  GetSecs ;
  d.indev_buf.x( i , : ) = dat ( : , xi ) ;
  d.indev_buf.y( i , : ) = dat ( : , yi ) ;
  
  % Buffer indeces of position samples for velocity computation
  j = i( 1 ) - 2 : i( end ) ;
  
  % Compute the marginal velocity of new samples
  vx = diff ( d.indev_buf.x( j , : ) )  *  d.C.DTREC1 ;
  vy = diff ( d.indev_buf.y( j , : ) )  *  d.C.DTREC1 ;
  
  % Compute marginal acceleration of new samples
  ax = diff ( vx )  *  d.C.DTREC1 ;
  ay = diff ( vy )  *  d.C.DTREC1 ;
  
  % Velocity
  j = 2 : size ( vx , 1 ) ;
  v = sqrt ( vx( j , : ) .^ 2  +  vy( j , : ) .^ 2 ) ;
  
  % Acceleration
  a = sqrt ( ax .^ 2  +  ay .^ 2 ) ;
  
  % Samples are valid if both eyes are below velocity and acceleration
  % thresholds. Also, no out-of-range behaviour from iViewX i.e. not
  % clipped to max voltage.
  d.indev_buf.valid( i ) = all ( v < d.RC.VELTHR  &  a < d.RC.ACCTHR  & ...
    ( dat ( : , xi ) < d.RC.IVXORB( 1 )  |  ...
      dat ( : , yi ) < d.RC.IVXORB( 2 ) ) , 2 ) ;
  
  
  %%% Compute targeted location on screen %%%
  
  % Are there any valid samples?
  i = d.indev_buf.valid( i ) ;
  newxy( 1 ) = any ( i ) ;
  
  % No valid samples
  if  ~newxy  ,  return  ,  end
  
  % Number of valid samples
  j = size ( xi , 2 )  *  sum ( i ) ;
  
  % Valid samples, compute average position
  x( 1 ) = mean ( reshape ( dat ( i , xi ) , j , 1 ) ) ;
  y( 1 ) = mean ( reshape ( dat ( i , yi ) , j , 1 ) ) ;
  
  
end % closef

