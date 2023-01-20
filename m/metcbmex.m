
function  metcbmex ( MC_in )
%
% metcbmex ( MC )
% 
% Matlab Electrophysiology Toolbox's Blackrock Microsystems system
% controller. Uses cbmex function to coordinate the activity of the Neural
% Signal Processor and Host PC with the rest of the experiment. A new data
% file is created for each trial. Header and footer comments are streamed,
% giving the trial parameters, outcome, and event times. Additionally,
% measurements are taken to synchronise the NSP clock versus the local
% system clock. Lastly, incoming data from the NSP is buffered and shared
% with any MET controller that reads the "nsp" POSIX shared memory. Shared
% data has time stamps converted to double vectors ; the values are NSP
% event times in seconds, rather than number of NSP samples. All buffered
% NSP events are written to the current trial directory in files with form
% nspevents_<i> where <i> is replaced with the trial identifier, both
% binary .mat and ASCII .txt versions are saved ; saved copies of the data
% are left in their original uint32 format and values are in number of NSP
% samples.
% 
% Comment strings are broken up into 127 character pieces and streamed in
% sequence. Fully appended, the string will have a separate line for each
% record. Each record will start with some name followed by a colon, and
% then a comma-separated list of values that terminate with a newline
% character e.g. name:v1,v2,v3,...,vN\n. The header records are contained
% between a pair of lines, 'header:start\n' and 'header:end\n'. The same is
% done for footer records.
% 
% NOTE! cbmex trialconfig is run in 'absolute' mode. That means the time
% stamps are in numbers of samples since the NSP was turned on , or since
% the latest file began recording in Host PC > Central > File Storage.
% 
% Written by Jackson Smith - March 2017 - DPAG , University of Oxford
%
  
  
  %%% Check environment %%%
  
  % This controller requires write access to 'nsp' shared memory
  i = [ MC_in.SHM{ : , 2 } ]  ==  'w' ;
  
  if  isempty ( i )  ||  ~ any ( strcmp(  MC_in.SHM( i , 1 )  ,  'nsp'  ) )
    
    error (  'MET:metcbmex:wnsp'  ,  [ 'metcbmex: write permission ' , ...
      'for ''nsp'' shared memory is required , check .cmet file' ]  )
    
  end
  
  
  %%% Global variable %%%
  
  % MET constants and MET controller constants
  global  MC  MCC
  MC = MC_in ;
  MCC = metctrlconst ( MC ) ;
  
  % Use this to remember the last time that cbmex trialdata was called.
  % Compare it against the newest time measurement and make sure that at
  % least CTDDUR seconds have passed before calling again. Initialise to
  % negative infinity so that the first call to cbmex trialdata will
  % succeed.
  global  ctdtim
  ctdtim = -Inf ;
  
  % This is for making sure that every mcalibrate signal has a unique cargo
  % during the initialisation phase of each trial.
  global  mcalcrg ;
  mcalcrg = 0 ;
  
  
  %%% Constants %%%
  
  % Footer flag. If raised then MET signals are converted to ASCII and
  % transferred to NSP as comments. If low, then only the outcome of the
  % trial is sent.
  FTRFLG = false ;
  
  % MET signal identifier name-to-value map
  MSID = MCC.MSID ;
  
  % Blocking mode in met recv
  WAIT_FOR_MSIG = 1 ;
  
  % NSP sampling rate, in Hertz
  NSPSHZ = MCC.SHM.NSP.RAWSHZ ;
  
  % cbmex trialdata sampling rate , in Hertz
  CTDSHZ = MCC.SHM.NSP.SHZ ;
  
  % cbmex trialdata sampling duration , in seconds
  CTDDUR = 1 / CTDSHZ ;
  
  % Time to wait after opening a new file for recording, allows data to
  % start being registered by Cerebus
  FOPDUR = MCC.SHM.NSP.FOPDUR ;
  
  % Number of trialdata reads to initialise buffer , about 15 seconds worth
  NREADS = ceil ( 15 / CTDDUR ) ;
  
  % Maximum number of characters in a comment , drop to 92 since that seems
  % to be all firmware/Central v6.04 can manage.
  MAXCHR = 92 ; % 127 ;
  
  % Maximum number of comments per trial
  MAXCOM = 256 ;
  
  % NSP digital input channel label
  DINLAB = MCC.SHM.NSP.DINLAB ;
  
  % NSP digital input NSP time stamp column index
  DINTIM = MCC.SHM.NSP.DINTIM ;
  
  % NSP unsigned int 16 value of digital input , column index
  DINVAL = MCC.SHM.NSP.DINVAL ;
  
  % The maximum value of a signal ID recorded by NSP digital input
  MAXSIG = MCC.DAT.MAXSIG ;
  
  % The number of bits to shift down when converting cargo value
  BSHIFT = MCC.SHM.NSP.BSHIFT ;
  
  % Number of calibrating signals to produce when initialising the trial ,
  % have previously used MAXSIG
  NUMCAL = 30 ;
  
  % Duration between calibrating signals , in seconds. Have previously
  % tried 2 / MCC.SHM.NSP.RAWSHZ, but then cbmex fails to capture all
  % events. Have tried C * CTDDUR with C values of 1 , 0.5 , and 0.25, and
  % all have worked. Currently using a single millisecond delay.
  CALDUR = 1e-3 ;
  
  % Calibration point number threshold. Must get at least this many to
  % carry on to trial. Have previously used MAXSIG.
  CALTHR = NUMCAL ;
  
  % Calibration point timer duration. If this much time passes, in seconds,
  % from the beginning of calibration then issue an error message that
  % suggests checking the digin settings in Central>Hardware Config.
  CTIMER = 1.0 ;
  
  % Calibration flag , initialised high for very first calibration. After
  % that, it is lowered for the rest of the duration of metcbmex's
  % execution. It's job is to flip the number of calibration points
  % generated each trial , and the threshold required to move on
  CALFLG.FLAG = true ;
  CALFLG.NEW_NUMCAL = 5 ;
  CALFLG.NEW_CALTHR = 3 ;
  
  % Formatting string for PTB timestamps , use for regression coefficients
  % as well. Accurate to the nearest microsecond.
  TIMFMT = MCC.FMT.TIME ;
  
  % Form of saved data file name
  DATFMT = 'nspevents_%s' ;
  
  % Pack constants
  C = struct ( 'MSID' , MSID , 'WAIT_FOR_MSIG' , WAIT_FOR_MSIG , ...
    'NSPSHZ' , NSPSHZ , 'CTDSHZ' , CTDSHZ , 'CTDDUR' , CTDDUR , ...
    'FOPDUR' , FOPDUR , 'NREADS' , NREADS , 'MAXCHR' , MAXCHR , ...
    'MAXCOM' , MAXCOM , 'DINLAB' , DINLAB , 'DINTIM' , DINTIM , ...
    'DINVAL' , DINVAL , 'NUMCAL' , NUMCAL , 'CALDUR' , CALDUR , ...
    'MAXSIG' , MAXSIG , 'CALTHR' , CALTHR , 'CTIMER' , CTIMER , ...
    'CALFLG' , CALFLG , 'BSHIFT' , BSHIFT , 'TIMFMT' , TIMFMT , ...
    'DATFMT' , DATFMT , 'FTRFLG' , FTRFLG ) ;
  
  % Clean up workspace
  clearvars  -except  ctdtim  mcalcrg  MC  MCC  C
  
  
  %%% Buffering %%%
  
  % Setup a buffer struct that stores NSP sample number and local PTB
  % timestamp pairs. The number of samples is in 'n', NSP sample numbers
  % are in .nsp, and local PTB time stamps are in .ptb. Hence, nsp ( i )
  % and ptb ( i ) refer to the same MET signal, for 1 <= i <= n. Also keeps
  % the latest set of the least-squares robust linear regression
  % coefficients in 'coef' to convert NSP sample number to local PTB time
  % stamp ; this is two-element row vector with [ y-intercept , slope ].
  tbuf.n = 0 ;
  tbuf.nsp = zeros ( 2 * C.CALTHR , 1 ) ;
  tbuf.ptb = zeros ( 2 * C.CALTHR , 1 ) ;
  tbuf.coef = [ 0 , 0 ] ;
  tbuf.timer = 0 ;
  
  % One could consider this a sort of buffer. The current session
  % descriptor is initialised here.
  sd = MCC.DAT.SD ;
  
  
  %%% MET initialisation %%%
  
  % Block warnings from robustfit saying "Iteration limit reached"
  warning (  'off'  ,  'stats:statrobustfit:IterationLimit'  )
  
  % Current session directory on the Host PC
  hpcsdr = '' ;
  
  % Trial name , if empty then no file is recording , otherwise file is
  % open on HostPC , check for this before terminating
  hpcnam = '' ;
  
  % mready trigger flag. Raised if mready trigger observed while executing
  % the trial function. This could happen if the next trial has been
  % prepared before this controller has finished delivering the final
  % trialdata read from cbmex, which is deliberately the next read
  % following reception of mstop.
  mrtflg = false ;
  
  % Try to guarantee that File Storage is running in Central on the Cerebus
  % HostPC.
  cbmex (  'fileconfig'  ,  'd:\test\open_file_storage'  ,  ...
    'cbmex: making sure File Storage is open , DON''T CLOSE IT!'  ,  0  )
  
  % Send mready signal , non-blocking
  met ( 'send' , C.MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Report
  met (  'print'  ,  ...
    sprintf ( 'MET controller %d initialised: metcbmex' , MC.CD )  ,  ...
    'L'  )
  
  % Flush standard output stream
  met ( 'flush' )
  
  % Wait for mwait signal that finalises initialisation phase
  n = 0 ;
  sig = [] ;
  while  ~ n  ||  all ( sig  ~=  C.MSID.mwait )
    
    % Block on the next MET signal(s)
    [ n , ~ , sig ] = met ( 'recv' , 1 ) ;

    % Return if any mquit signal received
    if  any ( sig  ==  C.MSID.mquit )  ,  return  ,  end
  
  end % initialising mwait
  
  clear  sig
  
  
  %%% Trial loop %%%
  
  % Wait for an mready trigger - a new trial is starting
  while  mrtflg  ||  metwaitfortrial ( MC , 'metcbmex' )
    
    
    %-- Get new trial parameters --%
    
    % Load current session directory path and trial identifier
    [ sdir , tid ] = metsdpath ;
    
    % This is a new session
    if  ~ strcmp (  sd.session_dir  ,  sdir  )
      
      % Load new session descriptor
      sd = metdload ( MC , MCC , sdir , tid , 'sd' , 'metcbmex' ) ;
      
      % Convert session directory name to HostPC format
      [ ~ , sdir ] = fileparts ( sdir ) ;
      sdir = regexprep ( sdir , '\.' , MCC.NSP.REPCHR ) ;
      
      % Update the HostPC session directory
      hpcsdr = strjoin (  { MCC.NSP.DEFSUB , ...
        [ sd.subject_id , MCC.NSP.REPCHR , sd.subject_name ] , sd.date ,...
        sdir }  ,  MCC.NSP.SEPCHR  ) ;
      
    end % new session
    
    % Base-name for new trial's Blackrock Microsystems data files
    hpcnam = strjoin (  {  hpcsdr  ,  [ MCC.NSP.FPREFX , tid ]  }  ,  ...
      MCC.NSP.SEPCHR  ) ;
    
    % cbmex 'fileconfig' comment string
    fcfcom = sprintf (  'subj_id %s,exp_id %d,sess_id %d,trial_id %s'  ,...
      sd.subject_id  ,  sd.experiment_id  ,  sd.session_id  ,  tid  ) ;
    
    
    %--- Start NSP cbmex buffering ---%
    
    % Start recording a new data file for this trial , make sure that
    % enough time passes before and after the call to cbmex to avoid packet
    % drops and data misalignment.
    WaitSecs ( C.CTDDUR ) ;
    cbmex ( 'fileconfig' , hpcnam , fcfcom , 1 )
    
    % Wait for file to start registering data
    WaitSecs ( C.FOPDUR )
    
    % Start cbmex buffer
    cbmex ( 'trialconfig' , 1 , 'absolute' , 'nocontinuous' )
    
    
    %--- Make new time calibrating measurements ---%
    
    % Reset buffer
    tbuf.n = 0 ;
    
    % Number of calibrating samples taken
    N = 0 ;
    
    % Reset mcalibrate cargo
    mcalcrg = 0 ;
    
    % Measure the time , now i.e. start calibration timer
    tbuf.timer = GetSecs ;
    
    % Get at least three , otherwise we can't compute a linear regression
    while  N  <  C.CALTHR
      
      % Get NSP and local PTB time samples
      WaitSecs ( C.CTDDUR ) ;
      [ n , nsptime , ptbtime , tdinfo , mquit , mwait ] = calib ( C ) ;
      
      % mquit signal received , time to end trial or program
      if  mquit  ||  mwait  ,  break
        
      % Check the calibration timer
      elseif  C.CTIMER  <  GetSecs - tbuf.timer
        
        % Timeout , print error message ...
        met (  'print'  ,  sprintf ( ...
          [ 'metcbmex: timout waiting for digin calibration points\n' , ...
            '  Check Central>Hardware Configuration on Cerebus\n' , ...
            '  HostPC. Digital input channel digin should be set to\n' ,...
            '  Function: 16-bit on rising edge.' ] )  ,  'E'  )
        
        % ... and break event loop
        mquit = true ;
        
        % Break calibration loop
        break
        
      % Otherwise , repeat calibration if no samples were obtained
      elseif  ~ n  ,  continue
      end
      
      % Add points to buffer
      tbuf = fillbuf ( tbuf , nsptime , ptbtime ) ;
      N = N + n ;
      
      % We got calibration points , so reset the timer
      tbuf.timer = GetSecs ;
      
    end % calibration samples
    
    % Quit signal received
    if  mquit
      
      % Terminate event/trial loop and shut down controller
      break
    
    % User clicked stop before trial started
    elseif  mwait
      
      % Make sure to stop data file recording on the HostPC , and data
      % buffering
      WaitSecs ( C.CTDDUR ) ;
      cbmex ( 'fileconfig' , hpcnam , 'manual stop' , 0 )
      WaitSecs ( C.CTDDUR ) ;
      cbmex ( 'trialconfig' , 0 )
      hpcnam = '' ;
      
      % Wait for new trial
      continue
      
    end % mquit or mwait
    
    % Compute latest coefficients , these will be used during the trial to
    % convert NSP timestamps to local PTB time
    i = 1 : tbuf.n ;
    tbuf.coef( : ) = robustfit ( tbuf.nsp ( i ) , tbuf.ptb ( i ) ) ;
    
    
    %--- Send header comments ---%
    
    % Make comment header string and reset comment 'colour'
    comstr = makehdr ( C , sd , tid , tbuf ) ;
    
    % Split header string into cbmex comments
    str2com ( C , comstr ) ;
    
    
    %--- Run trial ---%
    
    % Final preparations and send mready reply. Then buffer incoming NSP
    % data, as well as local MET signals. Write out incoming NSP data to
    % shared memory when possible
    [ trialdata , metsignals , mrtflg , mquit ] = ...
      trial ( C , tbuf.coef , tdinfo , str2double( tid ) ) ;
    
    % mquit signal received , time to end program
    if  mquit  ,  break  ,  end
    
    
    %--- Close trial ---%
    
    % Make footer comment string with outcome and all signals received
    % since, but including, mstart
    comstr = makeftr ( C , metsignals ) ;
    
    % Stream as comments
    str2com ( C , comstr ) ; %, comcol ) ;
    
    % Close HostPC file
    WaitSecs ( C.CTDDUR ) ;
    cbmex ( 'fileconfig' , hpcnam , '' , 0 )
    hpcnam = '' ;
    
    % And stop buffering data
    WaitSecs ( C.CTDDUR ) ;
    cbmex ( 'trialconfig' , 0 )
    
    % Save calibration times obtained for this trial
    i = tbuf.n - N + 1  :  tbuf.n ;
    trialdata.clock_calib_times.nsp = tbuf.nsp ( i ) ;
    trialdata.clock_calib_times.ptb = tbuf.ptb ( i ) ;
    
    % Write out buffered NSP data to trial directory on local system
    savedat ( C , sd , tid , trialdata )
    
  end % trial loop
  
  
  % Need to close open file recording on HostPC
  if  ~ isempty ( hpcnam )
    WaitSecs ( C.CTDDUR ) ;
    cbmex ( 'fileconfig' , hpcnam , 'MET emergency shutdown' , 0 )
    WaitSecs ( C.CTDDUR ) ;
    cbmex ( 'trialconfig' , 0 )
  end
  
  
end % metcbmex


%%% Subroutines %%%


% Used to get a few time stamps from the NSP and local system, to calibrate
% the clocks to each other. n, number of samples. nsp and ptb, vectors of
% samples where nsp ( i ) and ptb ( i ) refer to the same MET signal. tdat
% is a struct that describes the output of cbmex 'trialdata' ; has fields
% 'label' a cell column vector of strings with channel names, 'rows' with
% the number of rows, and 'cols' with the number of columns minus one
% (omits the one column of label strings). Final field of tdat is 'din',
% a 2 element vector with the [ row , column ] of digital input uint16
% values. This will be skipped when times are converted from NSP to local
% PTB.
function  [ n , nsp , ptb , tdat , mquit , mwait ] = calib ( C )
  
  
  %--- Initialisation ---%
  
  % Global constants and variable
  global  MC  mcalcrg
  
  % Default return values
  n = 0 ; nsp = [] ; ptb = [] ; tdat = [] ; mquit = false ; mwait = false ;
  
  % MET calibration signal id
  mcal = C.MSID.mcalibrate ;
  
  
  %--- Generate calibrating MET signals ---%
  
  for  i = 1 : C.NUMCAL
    
    % Unique cargo
    mcalcrg = mcalcrg + 1 ;
    
    % Note , each mcalibrate signal has a unique cargo to match it against
    % the return from cbmex trialdata. Also, met 'send' is called with []
    % for the time-stamp argument, meaning that it will measure the time
    % just prior to sendint the MET signal.
    met ( 'send' , mcal , mcalcrg , [] ) ;
    
    % Wait between calibrating signals
    WaitSecs ( C.CALDUR ) ;
    
  end % MET signals out
  
  % Get NSP data
  WaitSecs ( C.CTDDUR ) ;
  d = cbmex ( 'trialdata' , 1 ) ;
  
  
  %--- Retreive self-generated MET signals ---%
  
  % Prepare MET signal buffers
  NSIG = 0 ;
  CRG = zeros ( C.NUMCAL , 1 ) ; 
  TIM = zeros ( C.NUMCAL , 1 ) ;
  
  % Now gather all mcalibrate signals from MET server
  while  NSIG  <  C.NUMCAL
    
    % Wait for new MET signals
    [ nsig , src , sig , crg , tim ] = met ( 'recv' , C.WAIT_FOR_MSIG ) ;

    % Any mquit signal received?
    mquit( 1 ) = any (  sig == C.MSID.mquit  ) ;
    
    % Any mwait signal received
    mwait( 1 ) = any ( sig == C.MSID.mwait ) ;
    
    % Need to return in either case
    if  mquit  ||  mwait ,  return  ,  end
    
    % Look for mcalibrate signals from this controller
    i =  MC.CD == src  &  sig == mcal ;
    
    % Number found
    nsig ( 1 ) = sum ( i ) ;
    
    % Buffer them
    j = NSIG + ( 1 : nsig ) ;
    CRG ( j ) = crg ( i ) ;
    TIM ( j ) = tim ( i ) ;
    
    % And count them
    NSIG ( 1 ) = NSIG  +  nsig ;
  
  end % gather all
  
  
  %--- Match MET signals ---%
  
  % Digital input channel index
  din = find (  strcmp( C.DINLAB , d ( : , 1 ) )  ) ;
  
  % There is no recognisable digital input from NSP
  if  isempty (  din  )
    error ( 'MET:metcbmex:digin' , ...
      'metcbmex: no %s channel returned by cbmex ''trialdata''' , ...
      C.DINLAB )
  end
  
  % Extract the signal ID and cargo from the NSP measurements
  [ sig , crg ] = extractmsig ( C , d { din , C.DINVAL } ) ;
  
  % Times, only the first of each pair, this comes with signal id
  nsp = d{ din , C.DINTIM }( 1 : 2 : 2 * floor ( end / 2 ) ) ;
  
  % Keep only mcalibrate signals
  i =  sig == mcal  ;
  crg = crg ( i ) ;
  nsp = nsp ( i ) ;
  
  % Map cargo values from NSP source to local source
  [ i , j ] = ismember ( crg , CRG ) ;
  j = j ( i ) ;
  
  % No signals mapped , we will have to try again
  if  ~ any ( i )  ,  return  ,  end
  
  % Return NSP and local time stamps from matched MET signals
  nsp = nsp ( i ) ;
  ptb = TIM ( j ) ;
  
  % The number of calibrating samples obtained
  n = numel ( nsp ) ;
  
  
  %--- trialdata return value descriptor ---%
  
  % Build tdat struct. Notice that cols and din ( 2 ) are less 1 , this is
  % from removing label column.
  tdat.label = d ( : , 1 ) ;
  tdat.rows  = size ( d , 1 ) ;
  tdat.cols  = size ( d , 2 )  -  1 ;
  tdat.din   = [ din , C.DINVAL - 1 ] ;
  
  
end % calib


% Extracts the MET signal ID and cargo from a series of NSP digital input
% values. Make sure that I is given directly from trialdata output. That
% way we know that samples are in chronological order.
function  [ sig , crg ] = extractmsig ( C , I )
  
  % Default value , returned on error
  sig = [] ; crg = [] ;
  
  % Find number of complete signal ID / cargo pairs
  n = 2  *  floor ( numel ( I ) / 2 ) ;
  
  % No pairs , return empties
  if  ~ n  ,  return  ,  end  %#ok
  
  % Signal ID's , the first of each pair
  sig = I ( 1 : 2 : n ) ;
  
  % Cargo values , the second of each pair
  crg = I ( 2 : 2 : n ) ;
  
  % All signal IDs must be in the low bank of bits , and all cargo must be
  % in the high bank of bits. If not then theres a signal ID / cargo
  % mismatch
  if  any ( C.MAXSIG < sig  |  crg <= C.MAXSIG )  ,  return  ,  end
  
  % Cast signal ID to double
  sig = double ( sig ) ;
  
  % Drop cargo down to lower 8 bits. Remember , cargos are pushed out from
  % port 2 of the USB-1208fs , the upper 8 bits of the 16-bit integer.
  crg = bitshift ( crg , C.BSHIFT ) ;
  
  % And cast to double
  crg = double ( crg ) ;
  
end % extractmsig


% Buffer new time samples. If the buffer is full then resize it to double
% the current length.
function  tbuf = fillbuf ( tbuf , nsp , ptb )
  
  % Length of buffer
  nbuf = numel ( tbuf.nsp ) ;
  
  % Number of new points
  new = numel ( nsp ) ;
  
  % Number of values in total once added
  ntotal = tbuf.n + new ;
  
  % Need to resize the buffer
  if  nbuf  <  ntotal
    tbuf = rsbuf ( tbuf , new , nbuf ) ;
  end % resize
  
  % Assign new values
  i = tbuf.n + 1 : ntotal ;
  tbuf.nsp ( i ) = nsp ;
  tbuf.ptb ( i ) = ptb ;
  
  % Count new values
  tbuf.n( 1 ) = ntotal ;
  
end % fillbuf


% Resize buffer. Buffer struct will have .n field with number of filled
% elements. All other fields contain a column vector buffer. Needs number
% of new data points to add, and default number of elements to extend by.
function  b = rsbuf ( b , newd , dadd )
  
  % Get field names without field 'n'
  FNAM = setdiff ( fieldnames ( b )' , { 'n' , 'coef' , 'timer' } ) ;
  
  % Number of elements to extend by
  nex = max ( [ newd , dadd ] ) ;
  
  % Resize each buffer vector
  for  F = FNAM , f = F { 1 } ;
    
    b.( f ) = [ b.( f ) ; zeros( nex , 1 ) ] ;
    
  end % resize
  
end % rsbuf


% Make comment header string
function  header = makehdr ( C , sd , tid , tbuf )
  
  % Global MET constants
  global  MC  MCC

  % Name of trial parameter file [ remove ...ASCII trial... ]
  f = fullfile (  sd.session_dir  ,  MC.SESS.TRIAL  ,  tid  ,  ...
    sprintf ( MCC.TDNAMS , tid )  ) ;
  
  % Replace .mat suffix with .txt
%   f = regexprep ( f , '.mat$' , '.txt' ) ;

  % Load trial descriptor
  load (  f  ,  'td'  )
  
  % Nothing available by default
  t = '' ;
  
  % Create task variable value list  % Load trial parameters
  % if  exist ( f , 'file' )
  if  exist ( 'td' , 'var' )  &&  ~ isempty ( td.var )
    
    % Read trial's parameter string
%     t = fileread ( f ) ;
    
    % And get rid of spaces
%     t = regexprep (  t  ,  ' *'  ,  ''  ) ;

    % Get task variable names
    f = fieldnames ( td.var ) ;

    % No fields?!?! This should never happen
    if  isempty (  f  )
      
      error ( 'MET:metcbmex:td' , ...
      'metcbmex: trial descriptor has empty task var list on trial %s' ,...
      tid )
      
    else
      
      % Create string for each task variable
      t = cellfun (  ...
        @( c )  sprintf( '%s:%s\n' , c , num2str( td.var.( c ) ) )  ,...
          f  ,  'UniformOutput'  ,  false  ) ;
        
      % Concatenate into a single string
      t = [  t{ : }  ] ;
        
    end % check fields
    
  end % create task variable list
  
  % Coefficient format string
  fmt = [ C.TIMFMT , '\n' ] ;
  
  % NSP to PTB time regression intercept and slope
  i = tbuf.coef( 1 ) ;
  s = tbuf.coef( 2 ) ;
  
  header = [ ...
           sprintf( 'header:start\n' ) , ...
                     'trial:' , sprintf( '%s\n' , tid ) , ...
    'nsp2ptb_time_intercept:' , sprintf( fmt , i ) , ...
        'nsp2ptb_time_slope:' , sprintf( fmt , s ) , ...
           t  ,  ...
           sprintf( 'header:end\n' )  ] ;
  
end % makehdr


% Break up header string into comment-sized chunks and stream them to NSP
% function  comcol = str2com ( C , comstr , comcol )
function  str2com ( C , comstr )
  
  % Number of characters in a comment
  nc = C.MAXCHR ;
  
  % Characters in header
  nh = numel ( comstr ) ;
  
  % Number of times nh divides into chunks of nc chars , rounded up. That
  % is, this is the number of comments to send.
  ncom = ceil ( nh / nc ) ;
  
  % Stream comments
  for  i = 1 : ncom
    
%     % Out of comments
%     if  C.MAXCOM  <=  comcol
%       met ( 'print' , [ 'MET:metcbmex:comment\n' , ...
%         'metcbmex: comment number overflow' ] , 'E' )
%       return
%     end
    
    % Indeces for first and last characters in this comment
    first = ( i - 1 ) * nc  +  1 ;
    last  = min ( [ i * nc , nh ] ) ;
    
    % Send , careful to wait before sending.
    WaitSecs ( C.CTDDUR ) ;
    cbmex ( 'comment' , 255 , 0 , comstr ( first : last ) )
%     comcol = comcol + 1 ;
    
  end % stream
  
end % hdr2com


% Final sync up with MET server , buffer NSP data while writing new stuff
% to shared mem
function  [ td , msig , mrtflg , mquit ] = ...
  trial ( C , coef , tdinfo , tid )
  
  
  %--- Global MET constants ---%
  
  global  MC  MCC
  
  
  %--- Global variable ---%
  
  % Last time that cbmex trialdata was read
  global  ctdtim
  
  
  %--- Initialisation ---%
  
  % Default return value , no MET trial-ready trigger quit signal received
  % , if these are raised then the controller must proceed to the next
  % trial or terminate as soon as possible
  mrtflg = false ;
  mquit = false ;
  
  % mstop flag , raise to the count of next trialdata read when this MET
  % signal is seen. Actions are to ignore any new signals , while the next
  % read from cbmex trialdata and write to shared mem will break the event
  % loop.
  mstop = 0 ;
  
  % Shared memory write flag. Raised when writing is allowed. This is
  % necessary because we may be allowed to write before any new data from
  % cbmex trialdata has been read. We must remember that we can write to
  % shm while we wait for new data.
  wflag = false ;
  
  % cbmex 'trialdata' return buffer. Store the list of channel labels.
  td.label = tdinfo.label ;
  
  % NSP sample number to local PTB time stamp regression coefficients , for
  % saving to file
  td.nsp2ptb_time_coef.intercept = coef ( 1 ) ;
  td.nsp2ptb_time_coef.slope     = coef ( 2 ) ;
  
  % And set asside a data gathering cell array with the correct dimensions.
  % Layers accept successive reads from cbmex
  td.data = cell ( tdinfo.rows , tdinfo.cols , C.NREADS ) ;
  
  % Total number of reads buffered
  td.n = 0 ;
  
  % Number of reads written
  td.w = 0 ;
  
  % MET signal buffer , keep signal IDs , cargos , and times
  msig.n = 0 ;
  msig.sid = zeros ( MC.AWMSIG , 1 ) ;
  msig.crg = zeros ( MC.AWMSIG , 1 ) ;
  msig.tim = zeros ( MC.AWMSIG , 1 ) ;
  
  % Do one last call to cbmex , clears out the ol'buffer better than a
  % splash o' Speyside
  WaitSecs ( C.CTDDUR ) ;
  cbmex ( 'trialdata' , 1 ) ;

  % This is the best estimate of when the last call to cbmex was done.
  % Wait at least another C.CTDDUR after this before calling again
  ctdtim = GetSecs ;
  
  
  %--- Buffer data ---%
  
  % Send mready signal , non-blocking
  met ( 'send' , C.MSID.mready , MC.MREADY.REPLY , [] ) ;
  
  % Event loop
  while  true
    
    
    %- Wait for next event -%
    
    % Compute duration to wait until the next trialdata read can be made
    tdwait = C.CTDDUR  -  ( GetSecs - ctdtim ) ;
    tdwait = max ( [ tdwait , 0 ] ) ;
    
    % Wait for new event , measure select return time
    [ seltim , newsig , shm ] = met ( 'select' , tdwait ) ;
    
    
    %- MET signals -%
    
    % There are new MET signals to read , and the trial not yet stopped
    if  newsig  &&  ~ mstop
      
      % Perform a non-blocking read , get signal id 
      [ nsig , ~ , sid , crg , tim ] = met ( 'recv' ) ;
      
      % mquit signal received
      mquit( 1 ) = any ( sid == C.MSID.mquit ) ;
      if  mquit  ,  return  ,  end
      
      % mready trigger received
      mrtflg( 1 ) = any (  crg( sid  ==  C.MSID.mready )  ==  ...
        MC.MREADY.TRIGGER  )  ||  mrtflg ;
      
      % Total amount of buffer space used after new data added
      stot = msig.n  +  nsig ;
      
      % Resize buffer at need
      if  numel ( msig.sid )  <  stot
        msig = rsbuf ( msig , nsig , MC.AWMSIG ) ;
      end
      
      % Add to buffer
      msi = msig.n + 1 : stot ;
      msig.n = stot ;
      
      msig.sid ( msi ) = sid ;
      msig.crg ( msi ) = crg ;
      msig.tim ( msi ) = tim ;
      
      % mstop received , raise flag
      if  any ( sid == C.MSID.mstop )  ,  mstop( 1 ) = td.n + 2 ;  end
      
    end % msig
    
    
    %- Read cbmex 'traldata' -%
    
    % Can we read from cbmex trialdata yet?
    if  C.CTDDUR  <=  seltim - ctdtim ;
      
      % Buffer is out of space , resize
      if  td.n  ==  size ( td.data , 3 )
        
        td.data = cat ( 3 , td.data , ...
          cell ( tdinfo.rows , tdinfo.cols , C.NREADS ) ) ;
        
      end % resize buffer
      
      % Read new 'trialdata' cell array
      d = cbmex ( 'trialdata' , 1 ) ;
      
      % Closest estimate we have of the time 'trialdata' was last read
      ctdtim = GetSecs ;
      
      % Buffer data , without labels ( column 1 of d )
      td.n = td.n + 1 ;
      td.data ( : , : , td.n )  =  d ( : , 2 : end ) ;
      
    end % trialdata read
    
    
    %- Shared memory write permission -%
    
    % Can we write to shared memory?
    if  ~ isempty ( shm )
      
      % Action possible on nsp shared memory?
      insp = strcmp ( 'nsp' , shm ( : , 1 ) ) ;
      
      % Raise flag if nsp can be written to , or keep raised if already up
      wflag( 1 ) = wflag  ||  ...
        any(  'w'  ==  cell2mat( shm ( insp , 2 ) )  ) ;
      
    end % write flag
    
    
    %- Write to shared memory -%
    
    % Do we need to write to shared memory? That is, do we have permission
    % to write, and have we written out less than we've received?
    if  wflag  &&  td.w < td.n
      
      % Index of layer(s) to combine for writing
      icom = td.w + 1 : td.n ;
      
      % Collapse reads into a single-layered cell array. Casts data to
      % double, and converts NSP sample number to local PTB time stamp.
      wshm = tdcollapse ( td , icom , MCC.SHM.NSP.RAWSHZ , tdinfo ) ;

      % Write to shared memory
      if  met ( 'write' , 'nsp' , wshm , tid )

        % Count layers written
        td.w = td.w  +  numel ( icom ) ;

        % Lower write flag
        wflag( 1 ) = false ;
        
        % Break event loop if trial is over , at least we buffered up to
        % the end of the trial
        if  mstop  &&  mstop <= td.w  ,  break ;  end
        
      end % successful write
      
    end % write shm
    
    
  end % event loop
  
  
  %--- Trial stopped ---%
  
  % close NSP buffer and pause before allowing another call to cbmex
  WaitSecs ( C.CTDDUR ) ;
  cbmex ( 'trialconfig' , 0 )
  
  % Collapse trialdata buffer to one layered cell array
  icom = 1 : td.n ;
  td = tdcollapse ( td , icom , 0 , tdinfo ) ;
  
  % Pare down to used space in MET signal buffer , and delete mready
  % signals
  i =  msig.sid  ~=  C.MSID.mready  &  ...
    ( 1 : numel ( msig.sid ) )'  <=  msig.n ;
  
  msig.n   = sum ( i ) ;
  msig.sid = msig.sid ( i ) ;
  msig.crg = msig.crg ( i ) ;
  msig.tim = msig.tim ( i ) ;
  
  
end % trial


% Folds data down to a single layer , concatenates all vectors with the
% same row and column together. icom is the linear index vector saying
% which layers to combine. rawshz is the NSP's raw data sampling rate ,
% and tdinfo is the trialdata info struct. If rawshz is non-zero
% then the NSP event time stamp unit is changed from number of samples to
% seconds ; no conversion is done on digital input values. If met crashes
% while executing 'write' then this may be because td.data has elements
% that point to nothing, not even an empty matrix ; the solution, then, is
% to explicitly assign an empty matrix to each empty cell of the cell array
% by i = cellfun ( @isempty , td.data ) ; td.data( i ) = { [] } ; All data
% returned in each cell of td.data is converted to type double.
function  td = tdcollapse ( td , icom , rawshz , tdinfo )
  
  % NSP to PTB time conversion flag , if raised then DO NOT convert times.
  
  % We want to convert time stamp units if rawshz is non-zero
  if  rawshz
    
    % Flags are all low
    tflg = false ( tdinfo.rows , tdinfo.cols ) ;
    
    % The only place we raise the flag for is the digital input's value.
    tflg( tdinfo.din( 1 ) , tdinfo.din( 2 ) ) = 1 ;
    
  else % rawshz is zero ...
    
    % ... so raise all flags
    tflg = true ( tdinfo.rows , tdinfo.cols ) ;
    
  end % no time-conversion flag
  
  % Guarantee that all data is a double row vector. Otherwise, cbmex
  % returns inconsistent numerical types depending on whether the channel
  % had data. Where there is data, it is a column vector. But the shorthand
  % for concatenating the contents of a cell array is [ C{ : } ] , which
  % requires row vectors.
  td.data = cellfun(  @( c )  double( c')  ,  td.data( : , : , icom )  ,...
    'UniformOutput'  ,  false  ) ;
  
  % Collapse data into a single-layered cell array
  td.data = cellfun (  @( C , tflg )  ccoll ( C , tflg , rawshz )  ,  ...
    num2cell ( td.data , 3 )  ,  num2cell ( tflg )  ,  ...
    'UniformOutput'  ,  false  ) ;
  
end % tdcollapse


% Cell-collapse function , for folding multiple reads in the trial data
% buffer for one channel/unit into a single vector
function  v = ccoll ( C , tflg , rawshz )
  
  % Concatenate all data into one vector
  v = [  C{ : }  ] ;
  
  % Do not convert time stamps from NSP sample number to seconds if the
  % flag is raised , or if vector is empty
  if  tflg  ||  isempty ( v )  ,  return  ,  end
  
  % Samples to seconds
  v = v  /  rawshz ;
  
end % ccoll


% Converts buffered signals to lines of text. Each line has the format
% <signal name>:<signal ID>,<cargo>,<local PTB time>
function  comstr = makeftr ( C , msig )

  % Global MET constants
  global  MC
  
  % MET signal formatting string
  fmt = [ '%s:%d,%d,' , C.TIMFMT , '\n' ] ;
  
  % The number of strings to make depends on whether or not we send an
  % ASCII copy of all MET signals. If flag is low then we will only send
  % the outcome.
  if  C.FTRFLG
    N = msig.n + 3 ;
  else
    N = 3 ;
  end
  
  % Data gathering cell array
  S = cell ( 1 , N ) ;
  
  % Footer start and end strings
  S {  1  } = sprintf ( 'footer:start\n' ) ;
  S { end } = sprintf ( 'footer:end\n'   ) ;
  
  % mstop signal cargo
  i = msig.sid  ==  C.MSID.mstop ;
  i = msig.crg ( i ) ;
  
  % Trial outcome string
  S{ 2 } = sprintf ( 'outcome:%s\n' , MC.OUT { i , 1 } ) ;
  
  % If footer flag is up then make ASCII copy of all MET signals
  if  C.FTRFLG
  
    % Make strings
    for  i = 1 : msig.n

      % Signal name
      sname = MC.SIG { msig.sid ( i ) + 1 } ;

      % Line of text describing this signal
      S { i + 2 } = sprintf ( fmt , ...
        sname , msig.sid( i ) , msig.crg( i ) , msig.tim( i ) ) ;

    end
  
  end % MET sig to ASCII
  
  % Combine strings into one , with the footer start and end
  comstr = [ S{ : } ] ;
  
end % makeftr


% Save trial data to local system trial directory
function  savedat ( C , sd , tid , trialdata )
  
  
  %%% Global MET constants %%%
  
  global  MC  MCC
  
  
  %%% Save data file %%%
  
  %-- File name --%
  
  % Data file base name , replace %s with trial identifier string , no file
  % type suffix
  DATFMT = sprintf (  C.DATFMT  ,  tid  ) ;
  
  % Full path to data file , no suffix
  f = fullfile (  sd.session_dir  ,  MC.SESS.TRIAL  ,  tid  ,  DATFMT  ) ;
  
  
  %-- Binary data --%
  
  % Find all positions in the .data field that contain data
  i = ~ cellfun (  @isempty  ,  trialdata.data  ) ;
  
  % Initialise a storage cell array. When initialised like this , Matlab
  % seems to return an array of NULL pointers , to save on memory. We would
  % like to do this when saving to disk, but had to place actual empty
  % arrays in each cell before writing to 'nsp' shared memory.
  data = cell ( size(  trialdata.data  ) ) ;
  
  % We required double matrices inside each cell of .data to write it to
  % 'nsp' shared memory. But for storage on disk, we will convert all
  % values back to unsigned 32-bit integers.
  data( i ) = cellfun (  @uint32  ,  trialdata.data( i )  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % Attach storage copy of data to the struct
  trialdata.data = data ;
  
  % Save binary copy of the event times
  save (  [ f , '.mat' ]  ,  '-struct'  ,  'trialdata'  )
  
  
  %-- ASCII data --%
  
  % Channel labels
  L = repmat (  trialdata.label  ,  1  ,  size ( trialdata.data , 2 )  ) ;
  
  % Column numbers
  n = repmat (  1 : size ( trialdata.data , 2 )  ,  ...
    size ( trialdata.data , 1 )  ,  1  ) ;
  
  % Convert .data into strings. The transposition is deliberate, so that
  % Matlab will work along rows first.
  trialdata.data = cellfun (  ...
    @( d , l , n )  dat2str( d , l , n , '%d' )  ,  ...
    trialdata.data  ,  L  ,  num2cell ( n )  ,  ...
    'UniformOutput'  ,  false  )' ;
  
  % Get rid of empties. Again, watch the transposition.
  trialdata.data = trialdata.data( i' ) ;
  
  % Buffer for remaining strings
  S = cell (  5  ,  1  ) ;
  
  % Clock-to-clock calibration samples
  S{ 1 } = dat2str (  trialdata.clock_calib_times.nsp  ,  ...
    'clock_calib_times'  ,  'nsp'  ,          '%d'  ) ;
  S{ 2 } = dat2str (  trialdata.clock_calib_times.ptb  ,  ...
    'clock_calib_times'  ,  'ptb'  ,  MCC.FMT.TIME  ) ;
  
  % Time-conversion coefficients
  S{ 3 } = dat2str (  trialdata.nsp2ptb_time_coef.intercept  ,  ...
    'nsp2ptb_time_coef'  ,  'intercept'  ,  MCC.FMT.TIME  ) ;
  S{ 4 } = dat2str (  trialdata.nsp2ptb_time_coef.slope      ,  ...
    'nsp2ptb_time_coef'  ,  'slope'      ,  MCC.FMT.TIME  ) ;
  
  % Buffer read/write counts
  S{ 5 } = sprintf (  'reads_buffered: %d\nshm_writes: %d'  ,  ...
    trialdata.n  ,  trialdata.w  ) ;
  
  % Collapse all into a single string
  S = strjoin (  [ S ; trialdata.data ]  ,  '\n'  ) ;
  
  % Write ASCII file
  metsavtxt (  [ f , '.txt' ]  ,  S  ,  'w'  ,  'metcbmex'  )
  
    
end % savedat


% Convert an entry from trialdata.data into a string , ignore empties
function  s = dat2str ( d , l , n , df )
  
  % No data
  if  isempty ( d )
    s = '' ;
    return
  end
  
  % Alter format string depending on the type of n
  if  ischar ( n )
    
    fmt = [ '%s_%s: ' , df ] ;
    
  else
    
    fmt = [ '%s_%d: ' , df ] ;
  
  end
  
  % Header
  h = sprintf (  fmt  ,  l  ,  n  ,  d( 1 )  ) ;
  
  % Remainder of the list
  if  numel ( d )  ==  1
    r = '' ;
  else
    r = sprintf (  ',%d'  ,  d( 2 : end )  ) ;
  end
  
  % Return full string
  s = [ h , r ] ;
  
end % dat2str

