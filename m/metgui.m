
function  metgui ( MCin )
% 
% metgui ( MC )
% 
% MET controller function that provides a graphical user interface for
% controlling and monitoring the experiment. Supports MET GUI Central,
% which provides the interfacing callbacks that open and close MET
% sessions. metgui also generates blocks of trials and provides mready
% triggers, thus it generates trial descriptors and trial directories.
% 
% It buffers MET signals and all available shared memory from trial
% initialisation to its end. MET signals, stimulus link hit regions, eye
% positions/pupil diameters and touchscreen/mouse positions are all written
% to the current trial directory in files called metsigs_<i>.mat,
% hitregion_<i>.mat, and eyepos_<i>.mat, where <i> is replaced by the
% current trial identifier. Note that in eyepos_*.mat files,
% positions/diameters are stored as 16-bit signed integers in hundredths of
% a degree of visual field (positions) or hundredths of a pixel
% (diameters). ASCII text versions of all data data files are stored along
% side them in files with the same name, replacing .txt for .mat.
%
% The exception is trial-buffered 'nsp' shared memory. Since the controller
% that receives NSP event times may continue to receive data beyond the
% broadcast of the trial stop signal, it is responsible for saving its own
% trial-buffered data. metcbmex does so, and produces files called
% nspevents_<i>.mat and nspevents_<i>.txt.
%
% Some special MET GUIs are always loaded, because they are essential for
% running the task. These include MET GUI Central, MET Remote, and MET
% Session Info (provides block control). Any other MET GUI must be listed
% in met/m/mgui/metgui.csv in a comma-separated table with two columns and
% a row for each GUI. The column headings must be metguifun,realtime and
% each record names a MET GUI function in mgui to use, along with a scalar
% value that, if non-zero, tells metgui to update the named GUI every time
% that there are new events. If a record's realtime value is zero then the
% named GUI is only updated at the end of each trial. metguifun must
% contain function names without a .m file-type.
% 
% For example, metgui1 will only be updated after each trial is finished.
% But metgui2 will appear to be updated in real time.
% 
%    metguifun,realtime
%      metgui1,0
%      metgui2,1
% 
% Special MET GUIs will have access to a global variable that metgui
% declares, called metguisig. This is a struct used to buffer MET signals
% that metgui must request. It has fields .n, .sig, and .crg containing the
% number of buffered signals, signal identifiers, and signal cargos.
% .sig( i ) and .crg( i ) are used to request a MET signal with that
% identifier and cargo combination. Use metguiqsig to queue signals. One
% last field is AWMSIG, the number of MET signals in an atomic write to the
% request pipe ; buffer resizing will add this many spaces when it is full.
% 
% There is a second parameters file, met/m/metgui.csv. This optionally
% enables metgui.m to generate output from a serial port (Dsub-9) so as to
% synchronise the start and stop of trials with a peripheral system ; for
% instance, this could be used to start and stop file recording. metgui
% uses PsychToolbox IOPort to manage its serial port behaviour. The start
% signal is sent when the mready trigger MET signal is received, but before
% mstart is broadcast, while the stop signal is sent as soon as mstop is
% received. This must be a MET-formatted .csv file (see metreadcsv) with
% the following parameters, all of which are strings. 'enable' can be
% either 'on', allowing metgui to generate serial start/stop signals, or
% 'off', disabling serial output. 'port' is the Linux file system's name
% for the serial port. 'baud' is any valid baud rate, such as 115200.
% 'parity' can be 'None', 'Even', or 'Odd'. 'databits' is the number of
% data bits per packet and sets to '5', '6', '7', or '8'. 'stopbits' is the
% number of stop bits per packet and is '1' or '2'. 'flowcontrol' cat be
% 'None', 'Hardware' (RTS/CTS lines), 'Software' (XON/ XOFF). 'pollrate' is
% the rate in Hz that the serial port is polled while waiting between
% serial signals (when startwait and stopwait timers in use); can't be less
% than 2Hz. 'starthex' is the hex value that is output when a new trial is
% about to start. 'stophex' is the hex value that is output just after a
% trial ends. 'startwait' is the duration in seconds that metgui will pause
% after sending the start signal, giving the peripheral system time to
% begin recording before any critical events occur. 'stopwait' is the
% duration in seconds for metgui to have waited after sending the stop
% signal before another trial can begin, again giving the peripheral system
% time to catch up.
% 
% An example met/m/metgui.csv file could be as follows. This would enable a
% USB to RS232 adapter to send signals to a peripheral data recording
% system:
% 
%   param,value
%   enable,on
%   port,/dev/ttyUSB0
%   baud,115200
%   parity,None
%   databits,8
%   stopbits,1
%   flowcontrol,Hardware
%   pollrate,10
%   starthex,01
%   stophex,02
%   startwait,0.5
%   stopwait,0.25
% 
% NOTE: Attempts to leave GUIs where they were last placed.
% 
% Written by Jackson Smith - Sept 2016 - DPAG , University of Oxford
% 
  
  
  %%% Global constants %%%
  
  global  MC  MCC
  
  % MET constants
   MC = MCin ;
  
  % MET constroller constants , for shared memory transfer
  MCC = metctrlconst ( MC ) ;
  
  
  %%% Constants %%%
  
  % MET signal identifiers. Each field holds the numerical code of the
  % named signal.
  MSID = MCC.MSID ;
  
  % The names of shared memory that the controller can read
  SHMNAM = {} ;
  if  ~ isempty (  MC.SHM  )
    SHMNAM = MC.SHM( [ MC.SHM{ : , 2 } ]  ==  'r'  ,  1  )' ;
  end
  
  % Default buffer approximate duration , in seconds
  BUFDUR = 11 ;
  
  % MET GUI table , name and required column headings for the GUI and
  % Serial parameter files
  MGLIST = 'metgui.csv' ;
  MGLCOL = { 'metguifun' , 'realtime' } ;
  MGLSER = { 'enable' , 'port' , 'baud' , 'parity' , 'databits' , ...
    'stopbits' , 'flowcontrol' , 'pollrate' , 'starthex' , 'stophex' , ...
      'startwait' , 'stopwait' } ;
  MGLSERNUM = { 'pollrate' , 'startwait' , 'stopwait' } ;
  
  % Special MET GUIs, always loaded by metgui and not allowed in metgui.csv
  MGSPEC = { 'metguicentral' , 'metsessinfo' , 'metremote' } ;
  
  % Name of MET GUI position file. metgui saves the position of all open
  % MET GUIs ( figure property 'Position' ) into this file before closing.
  % If it exists, then it is opened and positions are applied to MET GUIs
  % as they are loaded, if a position is available. Otherwise, the MET GUI
  % gets its default position.
  MGFPOS = 'metgui_figpos.mat' ;
  
  % Poll timeout , in seconds. If no MET IPC received in this time then
  % stop checking to allow GUI callbacks a chance to run. 50 Hz polling
  % rate when no trial is running , or 5 Hz during a trial.
  POLDUR_NOTRIAL = 1 / 50 ;
  POLDUR_RUNNING = 1 /  5 ;
  
  % NSP finalisation timer. We will wait this long for the last NSP reads
  % of a trial to arrive before giving up and moving on, in seconds.
  NSPTIM = 0.5 ;
  
  % Time formatting string
  TIMFMT = [ '  ' , MCC.FMT.TIME , ': ' ] ;
  
  % Formatting string for trial data files
  TDFNAM.METSIG = 'metsigs_%d.mat' ;
  TDFNAM.HITREG = [ MCC.SDEF.ptb.hitregion.fieldname , '_%d.mat' ] ;
  TDFNAM.EYEPOS = 'eyepos_%d.mat' ;
  
  % Name of the trial log file relative to the current session directory
  LOGNAM = fullfile (  MC.SESS.LOGS  ,  'master_log.txt'  ) ;
  
  % Name of metgui's recovery file
  MGRECF = fullfile (  MC.SESS.REC  ,  'metgui_rec.mat'  ) ;
  
  % MET outcome code for ignored and aborted trials
  IGNORED = MC.OUT{  strcmp ( MC.OUT( : , 1 ) , 'ignored' )  ,  2  } ;
  ABORTED = MC.OUT{  strcmp ( MC.OUT( : , 1 ) , 'aborted' )  ,  2  } ;
  
  % MET signalling protocol states: wait for mready trigger , trial
  % initialisation and waiting for mstart , and trial running until mstop
  WAIT_FOR_MREADY = 0 ;
  TRIAL_INIT = 1 ;
  TRIAL_RUN = 2 ;
  
  
  %%% Alocate buffers %%%
  
  % The current buffer , always contains the most recent information about
  % MET signals and shared memory
  cbuf = MCC.DAT.cbuf ;
  
  % Trial buffer , collects all MET signals and shared memory data during a
  % trial. Chiefly , this is to allow MET GUIs to make any kind of
  % calculation about behavioural or neural responses over the whole trial.
  F = [  { 'msig' }  ,  SHMNAM  ] ;
  F = [ F ; cell( size ( F ) ) ] ;
  tbuf = struct ( F { : } ) ;
  
  % Trial MET signal buffer stores one signal per row in .b , while the
  % number of filled rows is given in .n and the index of the most recent
  % signal is in .i. Column indeces are given in src, sig, crg, and tim to
  % show where in .b the controller identifiers, signal identifiers,
  % cargos, and time stamps are kept.
  i = MC.AWMSIG ;
  F = { 'i' , 'n' , 'b'             , 'src' , 'sig' , 'crg' , 'tim' ;
         0  ,  i  ,  zeros( i , 4 ) ,   1   ,   2   ,   3   ,   4   } ;
  tbuf.msig = struct ( F { : } ) ;
  
  % Trial stim buffer. .b will be initialised each trial as a cell array
  % column vector that holds a sequence of reads from 'stim' shm. Each
  % element will hold a cell array row vector with as many elements as the
  % current trial descriptor's stimlink sub-struct. .n is the total number
  % of elements in .b, while .i is the index of .b holding the last read
  % from 'stim' or 0 if no reads have happened yet in the trial. .t is a
  % vector containing the time that each hit region was shown. .final field
  % is a concatenation of all 'stim' reads from initialisation to end of
  % the trial ; it is a struct with fields .time and .hitregion, where
  % .time is a vector of time values that arrived with each read, and
  % .hitregion is an r by s cell array for r reads and s stimulus links
  % such that .hitregion{ i , j } is the list of hit regions for the jth
  % link provided in the ith read.
  % 
  % For all trial buffers , .hz is the approximate rate of data production
  % of the shared memory , and f is a list of buffer fields.
  if  any ( strcmp (  'stim'  ,  SHMNAM  ) )
    
    % The nested cell arrays are so that a scalar struct is produced with
    % .b that contains a cell array.
    F = {  'i' , 'n' , 'b' , 'hz'                      , 'f' , 'final'  ;
            0  , [ ] , [ ] , Screen( 'FrameRate' , 1 ) , [ ] ,    [ ]   } ;
    tbuf.stim   = struct (  F { : }  ) ;
    tbuf.stim.n =   ceil (  BUFDUR  *  tbuf.stim.hz  ) ;
    tbuf.stim.b =   cell (  tbuf.stim.n  ,  1  ) ;
    tbuf.stim.t =  zeros (  tbuf.stim.n  ,  1  ) ;
    tbuf.stim.f = { 'b' , 't' } ;
    
  end
  
  % Trial eye buffer. Same fields as stim buffer, only that .b is a double
  % matrix with columns for time and binoccular eye positions and a row to
  % buffer each eye sample read from 'eye' shm. .d is the same, but it
  % buffers pupil diameter, if they are provided. .m is similar to .b
  % except that it holds any mouse positions that are transferred through
  % 'eye' shm, and it has columns for time and a single position. .i
  % becomes the maximum position reached in either .b, .d, or .m, while
  % .i_b, .i_d, and .i_m contain the actual positions reached,
  % respectively.
  if  any ( strcmp (  'eye'  ,  SHMNAM  ) )
    
    % Make struct buffer
    F = { 'i' , 'i_b' , 'i_d' , 'i_m' , 'n' , 'b' , 'd' , 'm' , ...
                                                 'hz'            , 'f'  ;
           0  ,   0    ,  0   ,   0   , [ ] , [ ] , [ ] , [ ] , ...
                                                 MCC.SHM.EYE.SHZ , [ ]  } ;
    tbuf.eye   = struct (  F { : }  ) ;
    tbuf.eye.n =   ceil (  BUFDUR  *  tbuf.eye.hz  ) ;
    tbuf.eye.b =  zeros (  tbuf.eye.n  ,  MCC.SHM.EYE.NCOL  ) ;
    tbuf.eye.d =  zeros (  tbuf.eye.n  ,  MCC.SHM.EYE.NCOL  ) ;
    tbuf.eye.m =  zeros (  tbuf.eye.n  ,  3  ) ;
    tbuf.eye.f = { 'b' , 'd' , 'm' } ;
    
  end
  
  % Trial nsp buffer. .b is a cell array vector containing each 'nsp' read
  % in sequence. .n is the number of elements in .b , and .i is the index
  % in .b of the most recent read. .label is re-set by the first read of
  % each trial to contain channel label strings. .final is used to collapse
  % the contents of .b down into a cell array where each element contains a
  % double vector with all time stamps received over the trial. A couple of
  % buffer-specific flags aid finalisation: .mstop is true if digin MET
  % signal mstop has been observed, .msi is the index of the last read that
  % was checked for a digin mstop value, and .mst is the time when we first
  % started looking for mstop.
  if  any ( strcmp (  'nsp'  ,  SHMNAM  ) )
    
    % Make struct buffer
    F = {'i', 'n', 'b', 'hz', 'f', 'label', 'final', 'mstop', 'msi', 'mst';
          0 , [ ], [ ], [  ], [ ],    [ ] ,    [ ] , [     ], [   ], [  ]};
    tbuf.nsp = struct (  F { : }  ) ;
    tbuf.nsp.hz = MCC.SHM.NSP.SHZ ;
    tbuf.nsp.n  = ceil (  BUFDUR  *  tbuf.nsp.hz  ) ;
    tbuf.nsp.b = cell (  tbuf.nsp.n  ,  1  ) ;
    tbuf.nsp.f = { 'b' } ;
    
  end
  
  % Global MET signal request buffer
  global  metguisig
  metguisig.n = 0 ;
  metguisig.sig = zeros ( MC.AWMSIG , 1 ) ;
  metguisig.crg = zeros ( MC.AWMSIG , 1 ) ;
  metguisig.AWMSIG = MC.AWMSIG ;
  
  % Trial outcome buffer , current index .i , buffer .b , .b will be
  % resized at need i.e. if any task variable depends on outcome for more
  % than numel ( .b ) trials in the past. .n is the total number of
  % elements in the buffer , filled or not. Note that current index is
  % where the result of the last trial that ran to completion is kept.
  outc.i = 0 ;
  outc.n = 5e3 ;
  outc.b = zeros ( outc.n , 1 ) ;
  
  % Block buffer , stores the block_id of all kept blocks i.e. those blocks
  % of trials deemed successful enough for later analysis
  blk.i = 0 ;
  blk.n = 500 ;
  blk.b = zeros ( blk.n , 1 ) ;
  
  
  %%% Load GUIs %%%
  
  % Hop into mgui
  cd ( MCC.GUIDIR )
  
  % Check environment and return MET gui list and figure positions
  [ lgui , rtgui , figpos , serial ] = chkenv ( MGSPEC , MGLIST , ...
    MGLCOL , MGFPOS , MGLSER , MGLSERNUM ) ;
  
  % Append special MET GUIs , but not metguicentral which needs special
  % initialisation
  MGSPEC = setdiff ( MGSPEC , 'metguicentral' ) ;
  lgui = [  cellfun( @( f ) str2func( f ) , MGSPEC , ...
    'UniformOutput' , false )  ,  lgui  ] ;
  
  % Remember the names of each MET GUI function , excluding metguicentral
  ngui = cellfun (  @func2str  ,  lgui  ,  'UniformOutput' , false  ) ;
  
  % metsessinfo is not realtime but metremote is
  rtgui = [  strcmp( MGSPEC , 'metremote' )  ,  rtgui  ] ;
  
  % Allocate space for component gui figure handles and gui descriptors.
  mgui.N = numel ( lgui ) ;
  mgui.H = gobjects ( mgui.N , 1 ) ;
  mgui.update = cell ( mgui.N , 1 ) ;
  mgui.reset = cell ( mgui.N , 1 ) ;
  mgui.recover = cell ( mgui.N , 1 ) ;
  mgui.close = cell ( mgui.N , 1 ) ;
  mgui.rtguiind = find (  rtgui  ) ;
  mgui.notrtgui = find ( ~rtgui  ) ;
  mgui.hasrtgui = any ( rtgui ) ;
  mgui.drawnow = false ;
  
  % Load MET guis
  for  i = 1 : numel ( lgui )
    
    % Report progress
    met (  'print'  ,  sprintf ( '  Loading MET GUI %d of %d: %s' , ...
      i , numel( lgui ) + 1 , func2str( lgui{ i } ) )  ,  ...
      'e'  )
    
    % Create MET GUI
    [ mgui.H( i ) , ...
      mgui.update{ i } , ...
      mgui.reset{ i } , ...
      mgui.recover{ i } , ...
      mgui.close{ i } ]  =  lgui{ i }( ) ;
    
    % Last position of MET GUI was saved
    if  isfield (  figpos  ,  ngui { i }  )
      
      % Load old position into MET GUI
      mgui.H( i ).Position = figpos.(  ngui { i }  ) ;
      
    end % restore positions
    
  end % load guis
  
  % Point to MET Remote figure and its start , stop , and abort buttons
  mr.h = mgui.H(  strcmp( MGSPEC , 'metremote' )  ) ;
  mr.start = mr.h.UserData.gd.start ;
  mr.stop  = mr.h.UserData.gd.stop  ;
  mr.abort = mr.h.UserData.gd.abort ;
  
  % Disable start button until a session is loaded
  mr.start.Enable = 'off' ;
  
  % MET Session Info, its mgui index
  msi.i = find (  strcmp (  MGSPEC  ,  'metsessinfo'  )  ) ;
  msi.h = mgui.H( msi.i ) ;
  
  % Find all blocked GUI controls , those that are not enabled when a trial
  % is running
  i = arrayfun(  @( h )  isstruct( h.UserData )  &&  ...
    isfield( h.UserData , 'blockcntl' )  ,  mgui.H  ) ;
  
  % Point metremote to all blocked controls
  mr.h.UserData.blockcntl = arrayfun (  ...
    @( h )  { h.UserData.blockcntl }  ,  mgui.H( i )  ) ;
  mr.h.UserData.blockcntl = [  mr.h.UserData.blockcntl{ : }  ] ;
  
  % Report loading final MET GUI
  met (  'print'  ,  sprintf ( ...
    '  Loading MET GUI %d of %d: metguicentral' , ...
    [ 1 , 1 ] * ( numel( lgui ) + 1 ) )  ,  'e'  )
  
  % Open MET GUI Central , pass handle to start button in MET Remote
  mgc = metguicentral ( mgui.H , mr.start ) ;
  
  % Last position of MET GUI Central was saved
  if  isfield (  figpos  ,  'metguicentral'  )

    % Load old position into MET GUI Central
    mgc.Position = figpos.metguicentral ;

  end % restore positions
  
  % Make sure that all MET GUIs are grabbable
  metcheckgui ( [ mgc ; mgui.H ] ) ;
  
  % Make other MET guis visible , but they won't appear or respond to the
  % user until drawnow is executed
  set ( mgui.H , 'Visible' , 'on' )
  
  
  %%% Initialisation %%%
  
  %-- Variables --%
  
  % Update gui flag , set when new IPC is ready
  fguiup = false ;
  
  % MET signalling protocol state
  msigprot = WAIT_FOR_MREADY ;
  
  % mstart time
  mst = 0 ;
  
  % Set empty session , block , and trial descriptors
  sd = MCC.DAT.SD ;
  bd = MCC.DAT.BD ;
  td = MCC.DAT.TD ;
  
  % Current polling duration
  poldur = POLDUR_NOTRIAL ;
  
  % Last drawnow time
  dntime = -Inf ;
  
  
  %-- Other actions --%
  
  % Shuffle the random number generator's seed
  rng ( 'shuffle' )
  
  % Done initialisation , send mready to alert MET server
  met ( 'send' , MSID.mready , MC.MREADY.REPLY , GetSecs ) ;
  
  % Report
  met (  'print'  ,  sprintf ( 'MET controller %d initialised: metgui' ,...
    MC.CD )  ,  'L'  )
  
  % Flush standard output
  met ( 'flush' )
  
  
  %%% Event loop %%%
  
  while  true
    
    
    %-- MET inter-process communication --%
    
    % Wait for new input , get MET select time for limiting drawnow
    % execution rate
    [ mstime , cbuf.new_msig , cbuf.shm ] = met ( 'select' , poldur ) ;
    
    % MET signals available
    if  cbuf.new_msig
      
      % Non-blocking read
      [ cbuf.msig.n , ...
        cbuf.msig.src , ...
        cbuf.msig.sig , ...
        cbuf.msig.crg , ...
        cbuf.msig.tim ] = met ( 'recv' ) ;
      
      % If any signal is mquit then break the event loop immediately
      if  any ( MSID.mquit  ==  cbuf.msig.sig )  ,  break  ,  end
      
      % Signal gui update real-time MET GUIs
      fguiup( 1 ) = mgui.hasrtgui ;
      
      % MET signalling protocol state is trial initialisation or running
      if  msigprot  ~=  WAIT_FOR_MREADY
        
        % Resize MET signal trial buffer at need
        if  tbuf.msig.n  <  tbuf.msig.i + cbuf.msig.n
          tbuf.msig.n = 2  *  tbuf.msig.n ;
          tbuf.msig.b = [ tbuf.msig.b  ;  zeros( size ( tbuf.msig.b ) ) ] ;
        end
      
        % Update MET signal trial buffer
        i = tbuf.msig.i + 1 : tbuf.msig.i + cbuf.msig.n ;
        tbuf.msig.b( i , tbuf.msig.src ) = cbuf.msig.src ;
        tbuf.msig.b( i , tbuf.msig.sig ) = cbuf.msig.sig ;
        tbuf.msig.b( i , tbuf.msig.crg ) = cbuf.msig.crg ;
        tbuf.msig.b( i , tbuf.msig.tim ) = cbuf.msig.tim ;
        tbuf.msig.i = i ( end ) ;
        
      end % fill trial buffer
      
    end % msig
    
    % MET shared memory available for reading
    if  ~isempty ( cbuf.shm )  &&  any ( [ cbuf.shm{ : , 2 } ]  ==  'r' )
      
      % Read each available shared memory. MET signalling protocol is in
      % wait for mready state , no trial then buffering.
      tbuf = readshm ( BUFDUR , ...
        cbuf , tbuf , msigprot == WAIT_FOR_MREADY , td ) ;

       % Signal gui update real-time MET GUIs
      fguiup( 1 ) = mgui.hasrtgui ;
      
    end % shm
    
    
    %-- MET signal handling --%
    
    % There are new MET signals
    if  cbuf.new_msig
    
      % Locate those signals that are handled
      i = find (  cbuf.msig.sig  ~=  MSID.mnull  &  ...
                  cbuf.msig.sig  ~=  MSID.mcalibrate  ) ;
                
      % Guarantee a row vector
      i = reshape (  i  ,  1  ,  numel ( i )  ) ;

      % Loop handled signals 
      for  i  =  i
        
        % Point to cargo and time
        crg = cbuf.msig.crg( i ) ;
        tim = cbuf.msig.tim( i ) ;
        
        % Respond to signal
        switch  cbuf.msig.sig( i )

          % mready trigger , means we prepare a new trial
          case  MSID.mready

            if  crg  ==  MC.MREADY.TRIGGER
              
              % Slow the MET GUI polling rate , and queue mready reply
              poldur = POLDUR_RUNNING ;
              metguiqsig ( MSID.mready , MC.MREADY.REPLY ) ;
              
              % Serial port signals are enabled
              if  serial.enable
                
                % We have a minimum period of waiting for each serial
                % output signal , the last one was stop so check that first
                for  F = { 'stopwait' , 'startwait' }  ,  f = F{ 1 } ;
                
                  % We must wait for a while since the last write signal
                  % was sent. See how much longer we need to wait for.
                  serial.wait = serial.lastwrite + serial.( f ) - GetSecs ;

                  % Timer still running
                  while  0  <  serial.wait
                    
                    % Check for new data in shared memory
                    [ ~ , ~ , cbuf.shm ] = met ( 'select' , 0 ) ;

                    % Clear and buffer incoming shared memory so that we
                    % don't create a block while waiting
                    tbuf = readshm ( BUFDUR , cbuf , tbuf , ...
                      msigprot == WAIT_FOR_MREADY , td ) ;

                    % Wait for one period of the serial polling rate , then
                    % update the amount of time left to wait for
                    serial.wait = serial.lastwrite + serial.( f ) - ...
                      WaitSecs( serial.pollwait ) ;

                  end % wait since last stop signal
                  
                  % This was the wait following the start signal , so no
                  % need to send another start signal. Break loop now.
                  if  strcmp ( f , 'startwait' )  ,  break  ,  end

                  % Send the serial start signal
                  [ ~ , serial.lastwrite , serial.emsg ] = ...
                    IOPort ( 'Write' , serial.h , serial.starthex ) ;

                  % Problem writing out
                  if  ~ isempty ( serial.emsg )

                    error ( 'MET:metgui:ioportwrite' , [ 'metgui: ' , ...
                      'error writing to serial port\nIOPort error: %s' ] ,...
                        serial.emsg )

                  end
                
                end % serial output signal types
                
              end % serial port sigs
              
            end % mready trigger

          % Stop or abort button hit
          case  MSID.mwait

            % If we are still in the trial initialisation state of the MET
            % signalling protocol then revert back to waiting for mready.
            % No further action is required if a trial is running. Remember
            % to reset the polling duration.
            if  msigprot == TRIAL_INIT
              
              msigprot = WAIT_FOR_MREADY ;
              poldur = POLDUR_NOTRIAL ;
              
              % Serial port output enabled
              if  serial.enable

                % Send the serial stop signal
                [ ~ , serial.lastwrite , serial.emsg ] = ...
                  IOPort ( 'Write' , serial.h , serial.stophex ) ;

                % Problem writing out
                if  ~ isempty ( serial.emsg )

                  error ( 'MET:metgui:ioportwrite' , [ 'metgui: ' , ...
                    'error writing to serial port\nIOPort error: %s' ] ,...
                      serial.emsg )

                end
                
              end % serial signals
              
            end

          % Trial starts
          case  MSID.mstart

            % Turn immediately to the trial running state of MET sig
            % protocol
            msigprot = TRIAL_RUN ;
            
            % Remember time
            mst( 1 ) = tim ;
            
            % Report
            met (  'print'  ,  ...
              [ '  ' , datestr( now , 13 ) , ': start' ]  ,  'L'  )
            
          % Report change of task logic state
          case  MSID.mstate
            
            met (  'print'  ,  ...
              sprintf ( [ TIMFMT , '%s' ] , tim - mst ,...
              sd.logic.( td.logic ).nstate{ crg } )  ,  ...
              'L'  )
            
          % Report subject selected new target
          case  MSID.mtarget
            
            met (  'print'  ,  ...
              sprintf ( [ TIMFMT , '%s selected' ] , tim - mst ,...
              sd.logic.( td.logic ).nstim{ crg } )  ,  ...
              'L'  )
            
          % Report new reward type
          case  MSID.mrdtype
            
           met ( 'print' , sprintf ( [ TIMFMT , 'reward type %d' ] , ...
             tim - mst , crg ) , 'L' )
            
          % Report reward started
          case  MSID.mreward
            
            met (  'print'  ,  sprintf ( [ TIMFMT , '%dms reward' ] , ...
              tim - mst , crg )  ,  'L'  )

          % mstop
          case  MSID.mstop

            % Back to wait for mready state of MET sig protocol
            msigprot = WAIT_FOR_MREADY ;
            
            % Reset polling duration
            poldur = POLDUR_NOTRIAL ;
            
            % Report outcome to user
            met ( 'print' , sprintf ( [ TIMFMT , '%s' ] , ...
             tim - mst , MC.OUT { crg , 1 } ) , 'L' )

            % Advance buffer position unless the trial was ignored.
            if  crg ~= IGNORED
              
              outc.i = outc.i  +  1 ;

              % Resize outcome buffer , at need
              if  outc.n  <  outc.i
                outc.b = [  outc.b  ;  zeros( outc.n , 1 )  ] ;
                outc.n = 2  *  outc.n ;
              end
            
              % Store outcome in buffer
              outc.b( outc.i ) = crg ;
              
            end % outcome buffer
            
            % Finalise stim trial buffer
            if  isfield ( tbuf , 'stim' )
              tbuf.stim.final.time = tbuf.stim.t( 1 : tbuf.stim.i ) ;
              tbuf.stim.final.stimlink = { td.stimlink.name } ;
              tbuf.stim.final.( MCC.SDEF.ptb.hitregion.fieldname ) = ...
                [ tbuf.stim.b{ 1 : tbuf.stim.i } ]' ;
            end

            % Finalise nsp trial buffer
            if  isfield ( tbuf , 'nsp' )
              
              % Try to catch any lagging data. Start by resetting
              % finalisation fields.
              tbuf.nsp.msi = 0 ;
              tbuf.nsp = nspmstop ( tbuf.nsp ) ;
              tbuf.nsp.mst = GetSecs ;
              
              % Wait for digin mstop if not found and timer not expired ...
              while  ~ tbuf.nsp.mstop  &&  GetSecs - tbuf.nsp.mst < NSPTIM
                
                % Wait for duration of one trialdata sample
                WaitSecs (  1  /  MCC.SHM.NSP.SHZ  ) ;
                
                % Wait for new shared data ... blissfully unaware of
                % problems until next iteration of the event loop
                [ ~ , ~ , cbuf.shm ] = met ( 'select' , poldur ) ;
                
                % Attempt to read, and buffer, shared memory
                tbuf = readshm ( BUFDUR , cbuf , tbuf , false , td ) ;
                
                % Now check if digin mstop delivered yet
                tbuf.nsp = nspmstop ( tbuf.nsp ) ;
                
              end % wait for digin 
              
              % At last, finalise NSP buffer
              tbuf.nsp.final = nspfin ( tbuf.nsp ) ;
              
            end % finalise nsp

            % Save MET signal data
            savetdat (  TDFNAM  ,  sd  ,  td  ,  tbuf  )

            % Save recovery data
            saverec (  fnrec ,  sd  ,  bd  ,  outc.b( 1 : outc.i ) , ...
              blk.b( 1 : blk.i )  ) ;
            
            % Update non-realtime MET GUIs
            for  j = mgui.notrtgui

              % Input arguments are the figure handle ; the session ,
              % block , and trial descriptors ; and the two buffers ,
              % current and trial. Determine whether or not we need to
              % execute drawnow.
              mgui.drawnow = mgui.update{ j } (  mgui.H( j )  ,  ...
                sd  ,  bd  ,  td  ,  cbuf  ,  tbuf  )  ||  mgui.drawnow ;
              
              % And save any recovery data
              mgui.recover{ j } (  mgui.H( j )  ,  { 'save' , mgrec } )

            end
            
            % Flush met printed messages to log file
            met ( 'flush' , 'l' )
            
            % Serial port output enabled
            if  serial.enable
              
              % Wait for a short time so as to increase chances of
              % recording equipment to register the stop signal
              WaitSecs (  0.02  ) ;
              
              % Send the serial stop signal
              [ ~ , serial.lastwrite , serial.emsg ] = ...
                IOPort ( 'Write' , serial.h , serial.stophex ) ;

              % Problem writing out
              if  ~ isempty ( serial.emsg )

                error ( 'MET:metgui:ioportwrite' , [ 'metgui: ' , ...
                  'error writing to serial port\nIOPort error: %s' ] ,...
                    serial.emsg )

              end

            end % serial signals

        end % handling

      end % Handled signals
      
      % Flush standard output stream
      met ( 'flush' , 'o' )
    
    end % MET signals
    
    
    %-- Update real-time MET GUIs --%
    
    % If any new IPC available
    if  fguiup
      
      % Lower flag
      fguiup( 1 ) = 0 ;
      
      % Update real-time guis with latest MET IPC
      for  i = mgui.rtguiind
        
        % Input arguments are the figure handle ; the session , block , and
        % trial descriptors ; and the two buffers , current and trial.
        % Determine whether we need to execute drawnow.
        mgui.drawnow = mgui.update{ i } (  mgui.H( i )  ,  ...
          sd  ,  bd  ,  td  ,  cbuf  ,  tbuf  )  ||  mgui.drawnow ;

      end
      
    end  %  update guis
    
    
    %-- Update plots --%
    
    % At least the GUI polling duration has passed since last call to
    % drawnow , or MET GUIs have been updated. If a trial is running, then
    % only execute drawnow if a MET GUI requests it following an update.
    if  mgui.drawnow  ||  poldur <= mstime - dntime
%         ( msigprot == WAIT_FOR_MREADY  &&  poldur <= mstime - dntime )
      
      % Draw the changes
      drawnow
      
      % Estimate the return time
      dntime = GetSecs ;
      
      % Lower flag
      mgui.drawnow = false ;
      
    end % MET GUI changes
    
    
    %-- Handle MET GUI events --%
    
    % MET GUI Central will not allow the user to access menu options if
    % metremote's play button is currently down
    if  ~ mr.start.Value
    
      % MET GUI Central reports that user wants to quit
      if  mgc.UserData.mquit

        % Send mquit signal with 'none' error , time measurement taken by
        % met
        met (  'send'  ,  MSID.mquit  ,  MC.ERR{ 1 , 2 }  ,  []  ) ;

        % Jump straight back to monitoring MET IPC
        continue

      % New MET session opened
      elseif  mgc.UserData.guiflg

        % Lower flag
        mgc.UserData.guiflg = false ;

        % Point to current session descriptor
        sd = mgc.UserData.sd ;
        
        % Reset the outcome and block buffers
        outc.b( : ) = 0 ;
        outc.i = 0 ;
         blk.i = 0 ;

        % Name of controller's recovery file in this session
        fnrec = fullfile (  sd.session_dir  ,  MGRECF  ) ;
        
        % MET GUI recovery directory
        [ ~ , mgrec ] = fileparts ( MCC.GUIDIR ) ;
        mgrec = fullfile (  sd.session_dir  ,  MC.SESS.REC  ,  mgrec  ) ;
        
        % Open log file
        met (  'logcls'  )
        met (  'logopn'  ,  fullfile ( sd.session_dir , LOGNAM )  )

        % Check if this session is being re-opened before it was
        % finalised ; say , because of a crash.
        if  exist (  fnrec  ,  'file'  )

          % Get recovery data and initialise the session descriptor
          [ sd , bd , outc , blk ] = recover ( fnrec , sd , outc , blk ) ;
          
          % Recover non-realtime MET GUIs
          for  i = mgui.notrtgui
            mgui.recover{ i } (  mgui.H( i )  ,  { 'load' , mgrec }  )
          end % non-realtime MET GUIs
          
        else

          % This is a brand new session , so create a fresh block of trials
          [ bd , sd ] = metblock ( [] , sd ) ;
          
          % And make sure that the MET GUI recovery directory exists
          mkmgrec ( mgrec )
          
        end

        % Update master copy of session descriptor
        mgc.UserData.sd = sd ;
        
        % Refresh all MET GUIs with new session and block descriptors
        for  i = 1 : mgui.N
          mgui.reset{ i } (  mgui.H( i )  ,  { 'sd' , sd }  )
          mgui.reset{ i } (  mgui.H( i )  ,  { 'bd' , bd }  )
        end
        
      % Reset MET GUIs as if they were freshly loaded
      elseif  ~ isempty ( mgc.UserData.reset )
        
        % Loop each listed MET GUI
        for  i = 1 : numel ( mgc.UserData.reset )
          
          % Find gui index
          j = mgui.H  ==  mgc.UserData.reset( i ) ;
          
          % Execute reset
          mgui.reset{ j } (  mgui.H( j )  ,  { 'reset' , [] }  )
          
        end % reset mguis
        
        % Clear reset list
        mgc.UserData.reset( : ) = [] ;

      end % new session
      
      % MET Session Info block controls activated and MET Remote's play
      % button is enabled.
      if  msi.h.UserData.guiflg  ~=  'd'
        
        % Change block if .guiflg is 'b' for block or 'a' for all (block
        % and environmental variables)
        if  any ( msi.h.UserData.guiflg  ==  'ab' )
          
          % Current block aborted , adjust block buffer to overwrite
          % current block id
          if  msi.h.UserData.abortblk  ,  blk.i = blk.i - 1 ;  end

          % Kill the remainder of the current trial deck. This will force
          % creation of a whole new block, while taking outcome history
          % into account.
          bd.deck = [] ;

          % If the last trial was ignored then cheat and say that it was
          % actually aborted , otherwise a new trial i.e. block of trials
          % will not be generated
          if  outc.b( outc.i )  ==  IGNORED
            outc.b( outc.i ) = ABORTED ;
          end
        
        end % change block
        
        % Change environment variables
        if  any ( msi.h.UserData.guiflg  ==  'ae' )
          
          % Get new values
          sd.evar = msi.h.UserData.evar ;
          
          % Update master copy of session descriptor
          mgc.UserData.sd = sd ;
          
        end % change environment variables
        
        % Lower gui flag
        msi.h.UserData.guiflg = 'd' ;
        
      end % block and environmental variable controls
    
    
    %-- New trial --%

    % Only start the trial if the play button is down, the stop buttons
    % are up, the MET signalling protocol is in the wait-for-mready state,
    % and the MET GUI signal buffer is empty.
    elseif  msigprot == WAIT_FOR_MREADY   &&  ~ mr.stop.Value   &&  ...
        ~ mr.abort.Value  &&  ~ metguisig.n

      % Trial initialisation signalling protocol state
      msigprot = TRIAL_INIT ;

      % Queue mready trigger signal
      metguiqsig ( MSID.mready , MC.MREADY.TRIGGER ) ;

      % Reset MET signal trial buffer
      tbuf.msig.i = 0 ;

      % Reset shm trial buffers
      for  i = 1 : numel (  SHMNAM  )  ,  F = SHMNAM { i } ;
        tbuf.( F ) = resetb (  tbuf.( F )  ) ;
      end

      % Generate a new trial if the previous one was not ignored , or if
      % this is the first trial of the session
      if  ~ outc.i  ||  outc.b( outc.i )  ~=  IGNORED

        % Update block descriptor
        [ bd , sd ] = metblock ( bd , sd , outc.b ( 1 : outc.i ) ) ;

        % Make new trial descriptor and directory
        [ td , sd ] = metnewtrial (  sd  ,  bd  ,  true  ) ;

        % Update master copy of session descriptor
        mgc.UserData.sd = sd ;
        
        % Refresh all MET GUIs with new block and trial descriptors
        for  i = 1 : mgui.N
          mgui.reset{ i } (  mgui.H( i )  ,  { 'bd' , bd }  )
          mgui.reset{ i } (  mgui.H( i )  ,  { 'td' , td }  )
        end

        % Update block buffer if buffer empty or current block id has
        % changed from the last one in the buffer
        blk = updateblk ( blk , bd ) ;

      end % generate trial

      % Print information for running trial
      met (  'print'  ,  trialstr ( bd , td )  ,  'E'  )
      
    end % metremote play button
    
    
    %-- Send MET signals --%
    
    % Starting index of MET signal depends on whether there are mwait
    % signals and what the MET signalling protocol state is currently
    if  msigprot ~= TRIAL_INIT
      
      % Trial is not initialising , send all signals
      i = 1 ;
      
    % Trial is initialising
    else
      
      % Are there mwait signals?
      i = 1 : metguisig.n ;
      j = metguisig.sig ( i )  ==  MSID.mwait ;
      
      % Yes , then place them at the head of the buffer. Put all remaining
      % signals in the tail, and index the start of the tail with non-mwait
      % signals.
      if  any ( j )
        
        % Re-organise the buffer
        metguisig.sig( i ) = [  metguisig.sig(  j )  ;
                                metguisig.sig( ~j )  ] ;
        metguisig.crg( i ) = [  metguisig.crg(  j )  ;
                                metguisig.crg( ~j )  ] ;
        
        % Starting index
        i = sum ( j ) + 1 ;
        
      else
        
        % Send all signals
        i = 1 ;
        
      end
      
    end % starting index
    
    % Loop until all signals sent
    while  i  <=  metguisig.n
      
      % Index vector spanning all remaining signals in buffer
      j = i : i + min( [ metguisig.n , metguisig.AWMSIG ] ) - 1 ;
      
      % Send signals , return the number that were sent
      n = met ( 'send' , metguisig.sig( j ) , metguisig.crg( j ) , [] ) ;
      
      % Update number remaining , and starting index
      i = i + n ;
      metguisig.n = metguisig.n - n ;
      
    end % send loop
    
    
  end % event loop
  
  
  %%% Shut down %%%
  
  % Close component guis
  for  i = 1 : mgui.N
    
    % But first save its figure Position , for use next time
    figpos.( ngui{ i } ) = mgui.H( i ).Position ;
    
    % Now close the figure
    mgui.close{ i }( mgui.H( i ) )
    
  end % close MET GUIs
  
  % Remember MET GUI Central's figure Position
  figpos.metguicentral = mgc.Position ;
  
  % Close MET GUI Central
  delete ( mgc )
  
  % Save MET GUI figure Position data file
  save (  MGFPOS  ,  'figpos'  )
  
  % Serial port was opened , so close it
  if  serial.enable  ,  IOPort (  'CloseAll'  )  ,  end
  
  
end % metgui


%%% SUB-ROUTINES %%%

function  [ lgui , rtgui , figpos , serial ] = ...
  chkenv ( MGSPEC , MGLIST , MGLCOL , MGFPOS , MGLSER , MGLSERNUM )
  
  
  % Look for MET GUI table
  if  ~ exist ( MGLIST , 'file' )

    % Can't find file
    error ( 'MET:metgui:noguitable' , 'metgui: no MET GUI table %s' , ...
      fullfile ( pwd , MGLIST ) )

  end
    
  
  % Read table
  t = readtable (  MGLIST  ) ;
  
  % No MET GUIs were listed
  if  isempty ( t )
    
    lgui = {} ;
    rtgui = [] ;
    return
  
  % Make sure that all column headings are there
  elseif  numel( MGLCOL )  ~=  numel( t.Properties.VariableNames )  ||  ...
      ~ all ( strcmp(  MGLCOL  ,  t.Properties.VariableNames  ) )
    
    error (  'MET:metgui:guitablecol'  ,  ...
      'metgui: %s must have columns %s'  ,  ...
      MGLIST  ,  strjoin ( MGLCOL , ' , ' )  )
    
  % Make sure that metguifun contains only strings
  elseif  ~ all (  cellfun(  @( c ) isvector( c ) && ischar( c )  ,  ...
      t.metguifun  ) )
    
    error (  'MET:metgui:metguifun'  ,  ...
      'metgui: %s column metguifun must contain only strings'  ,  MGLIST  )
    
  % And that realtime is numeric or logical
  elseif  ~ isnumeric ( t.realtime )
    
    error (  'MET:metgui:realtime'  ,  ...
      'metgui: %s column realtime must be numeric'  ,  MGLIST  )
    
  end
  
  % Quietly ignore special MET GUIs
  i = ~ ismember ( t.metguifun , MGSPEC ) ;
  t.metguifun = t.metguifun ( i ) ;
  t.realtime = t.realtime ( i ) ;
  
  % Return function handles for each named MET GUI
  for  i = 1 : numel ( t.metguifun )
    
    % Make sure that named gui function is in mgui
    if  ~ exist ( [ t.metguifun{ i } , '.m' ] , 'file' )
      
      error ( [ 'MET:metgui:' , MGLIST ] , ...
         ['metgui: can''t find ' , t.metguifun{ i } , '.m' ] )
      
    end
    
    t.metguifun{ i } = str2func ( t.metguifun{ i } ) ;
    
  end
  
  % Map table columns to output arguments
  lgui = reshape ( t.metguifun , 1 , numel ( t.metguifun ) ) ;
  rtgui = reshape ( t.realtime , size ( lgui ) ) ;
  
  % Look for figure position file. Contains position of all MET GUIs the
  % last time that MET was closed.
  if  exist (  MGFPOS  ,  'file'  )
    
    % Get figure positions
    load (  MGFPOS  ,  'figpos'  )
    
  else
    
    % File not created yet so return a struct with no fields
    figpos = struct ;
    
  end % MET GUI figure positions
  
  % Now we check for serial port output parameters , first build the file
  % name
  fnam = fileparts ( which(  'metgui'  ) ) ;
  fnam = fullfile (  fnam  ,  MGLIST  ) ;
  
  % Check that file exists
  if  ~ exist ( fnam , 'file' )

    % Can't find file
    error ( 'MET:metgui:noserialcsv' , ...
      'metgui: no serial port parameter file %s' , fnam )

  end
  
  % Read in parameters
  p = metreadcsv (  fnam  ,  MGLSER  ,  MGLSERNUM  ) ;
  
  % Start building metgui serial struct , overrides Matlab serial object
  % name. If not enabled then we don't need any other parameters, so quit.
  switch  p.enable
    case  'on'  ,  serial.enable = true ;
    case  'off' ,  serial.enable = false ;  return ;
    otherwise
      error ( 'MET:metgui:serialenable' , ...
        'metgui: serial %s enable must be ''on'' or ''off''' , MGLIST )
  end
  
  % The poll rate must be a sensible value ... nothing below 2Hz is allowed
  if  ~ isscalar( p.pollrate )  ||  p.pollrate < 2  ||  ...
        ~ isreal( p.pollrate )  ||  ~ isfinite( p.pollrate )
    
    error ( 'MET:metgui:serialpollrate' , ['metgui: invalid poll ' , ...
        'rate in serial %s' ] , MGLIST )
    
  end
  
  % Polling rate is sensible , lets find the waiting time between polls
  serial.pollwait = 1  /  p.pollrate ;
  
  % Start and stop wait times
  for  F = { 'startwait' , 'stopwait' }  ,  f = F{ 1 } ;
    
    % Must be real, 0 or positive, scalar, and finite
    if  ~ isscalar( p.( f ) )  ||  p.( f ) < 0  ||  ...
        ~ isreal( p.( f ) )  ||  ~ isfinite( p.( f ) )
      
      error ( [ 'MET:metgui:serial' , f ] , ['metgui: invalid wait ' , ...
        'time for %s in serial %s' ] , f , MGLIST )
      
    end
    
    % Store wait time
    serial.( f ) = p.( f ) ;
    
  end % start/stop waits
  
  % Convert hex strings to uint8 values
  for  F = { 'starthex' , 'stophex' }  ,  f = F{ 1 } ;
    
    % Attempt conversion
    try
      
      serial.( f ) = hex2dec (  p.( f )  ) ;
      
    catch  E
      
      error ( [ 'MET:metgui:serial' , f ] , ['metgui: invalid hex ' , ...
        'string for %s in serial %s\nhex2dec error: %s' ] , ...
          f , MGLIST , E.message )
      
    end
    
    % Check that value is within range of uint8
    if  serial.( f )  <=  0  ||  intmax (  'uint8'  )  <  serial.( f )
      
      % Too small or too big
      error ( [ 'MET:metgui:serial' , f , 'uint8' ] , [ 'metgui: ' , ...
        'serial %s param %s value out of range for uint8' ] , MGLIST , f )
      
    end
    
    % Convert to uint8
    serial.( f ) = uint8 (  serial.( f )  ) ;
    
  end % hex str to uint8
  
  % Build a serial port parameter string for IOPort
  str = sprintf ( [ 'BaudRate=%s Parity=%s DataBits=%s StopBits=%s ' , ...
    'FlowControl=%s' ] , p.baud , p.parity , p.databits , p.stopbits , ...
      p.flowcontrol ) ;
  
  % Attempt to open the serial port
  [ serial.h , serial.emsg ] = IOPort ( 'OpenSerialPort' , p.port , str ) ;
  
  % There was an error while attempting to open the port
  if  serial.h  <  0
    
    error ( 'MET:metgui:openserialport' , [ 'metgui: error opening ' , ...
      'serial port , see IOPort error\n  %s' ] , serial.emsg )
    
  end
  
  % First check on whether enough time has passed since last trial was
  % stopped should cancel out the waiting period go immediately to sending
  % the first start signal
  serial.lastwrite = - serial.stopwait ;
  
end % chkenv


% Reads available shared memory and updates the trial buffer
function  tbuf = readshm ( BUFDUR , cbuf , tbuf , no_trial_buff , td )
  
  % Read each available shared memory
  for  i = 1 : size ( cbuf.shm , 1 )
        
    % Is shm ready to read? Otherwise skip to next shm.
    if  cbuf.shm{ i , 2 }  ~=  'r'  ,  continue  ,  end

    % SHM name / fieldname
    F = cbuf.shm{ i , 1 } ;

    % Read in fresh data
    cbuf.( F ) = met ( 'read' , F ) ;

    % No trial buffering allowed
    if  no_trial_buff  ,  continue  ,  end

    % Copy from current buffer to trial buffer
    tbuf.( F ) = cpcurb ( BUFDUR , F , cbuf.( F ) , tbuf.( F ) , td ) ;

  end % read shm
  
end % readshm


% Copies from current shared memory buffer into trial buffer
function  tbuf = cpcurb (  BUFDUR  ,  F  ,  cbuf  ,  tbuf  ,  td  )
  
  
  %-- Global Constants --%
  
  % MET controller constants
  global  MCC
  
  
  %-- Number of elements required --%
  
  % Determine number of samples to add to buffer. If possible, get the
  % index for the buffer position that will store new data.
  switch  F
    
    case  { 'stim' , 'nsp' }
      
      N = 1 ;
      i = tbuf.i + 1 ;
      
    % Eye shared memory is trickier. There are two possible position
    % buffers streaming through with different numbers of samples.
    case  'eye'
      
      % Get the number of samples for each kind of position
      N_eye = [ 0 , 0 , 0 ] ;
      N_eye( MCC.SHM.EYE.EYEIND ) = size( cbuf{ MCC.SHM.EYE.EYEIND } , 1 );
      N_eye( MCC.SHM.EYE.IPUPIL ) = size( cbuf{ MCC.SHM.EYE.IPUPIL } , 1 );
      N_eye( MCC.SHM.EYE.IMOUSE ) = size( cbuf{ MCC.SHM.EYE.IMOUSE } , 1 );
         
      % Find the maximum number of new positions , for resize check
      N = max (  N_eye  ) ;
      
  end
  
  % Resize buffer at need
  while  tbuf.n  <  tbuf.i + N
    tbuf = resizeb (  BUFDUR  ,  tbuf  ) ;
  end
  
  
  %-- Copy data --%

  % Different approaches by shm type
  switch  F
    
    case  'stim'
      
      % Time measure
      tbuf.t( i ) = cbuf { MCC.SHM.STIM.TIME } ;
      
      % Logical index vector
      liv = cbuf { MCC.SHM.STIM.LINDEX } ;
      
      % Make a cell array of appropriate size
      tbuf.b{ i } = cell (  numel (  liv  )  ,  1  ) ;
      
      % Map new hit regions to corresponding positions , remember that
      % we're dealing with cell arrays and not doubles
      tbuf.b{ i }( liv ) = cbuf (  MCC.SHM.STIM.HITREG : end  ) ;
      
    case   'eye'
      
      % New eye positions available
      if  N_eye( MCC.SHM.EYE.EYEIND )
        
        % Find eye position buffer places
        i = tbuf.i_b + 1 : tbuf.i_b + N_eye( MCC.SHM.EYE.EYEIND ) ;

        % Transfer eye positions directly
        tbuf.b( i , : ) = cbuf { MCC.SHM.EYE.EYEIND } ;

        % Set the last index holding new eye position data
        tbuf.i_b = i( end ) ;
      
      end % eye pos
      
      % New pupil diameters available
      if  N_eye( MCC.SHM.EYE.IPUPIL )
        
        % Find pupil diameter buffer places
        i = tbuf.i_d + 1 : tbuf.i_d + N_eye( MCC.SHM.EYE.IPUPIL ) ;

        % Transfer eye positions directly
        tbuf.d( i , : ) = cbuf { MCC.SHM.EYE.IPUPIL } ;

        % Set the last index holding new eye position data
        tbuf.i_d = i( end ) ;
        
      end % pupil diam
      
      % New touchscreen/mouse positions available
      if  N_eye( MCC.SHM.EYE.IMOUSE )
        
        % Do the same for mouse positions
        i = tbuf.i_m + 1 : tbuf.i_m + N_eye( MCC.SHM.EYE.IMOUSE ) ;
        tbuf.m( i , : ) = cbuf { MCC.SHM.EYE.IMOUSE } ;
        tbuf.i_m = i( end ) ;
      
      end % touch/mouse pos
      
      % Find maximum index position in either
      i = max ( [  tbuf.i_b ,  tbuf.i_d ,  tbuf.i_m  ] ) ;
      
    case   'nsp'
      
      % Get the trial-id for this nsp data
      tid = cbuf{ MCC.SHM.NSP.TIDIND } ;
      
      % Only add new sample to the buffer if it comes from the current
      % trial i.e. not lagging data from the last trial. NOTE! tbuf.i is
      % not changed if there is mismatch.
      if  tid  ~=  td.trial_id  ,  return  ,  end

      % Get new time stamps
      tbuf.b{ i } = cbuf{ MCC.SHM.NSP.DATIND }.data ;

      % If this is the first read then update the labels
      if  ~ tbuf.i
        tbuf.label = cbuf{ MCC.SHM.NSP.DATIND }.label ;
      end
      
  end % update trial buffer
  
  % Set .i to the last element that was filled
  tbuf.i = i ( end ) ;
  
end % cpcurb


% Resize the buffer , add a chunk for approximately another BUFDUR seconds
% of storage
function  buf = resizeb (  BUFDUR  ,  buf  )
  
  % Determine how many more elements to add
  N = ceil ( BUFDUR  *  buf.hz ) ;
  
  % Loop buffer fields
  for  F = buf.f  ,  f = F { 1 } ;
    
    % Number of columns
    c = size (  buf.( f )  ,  2  ) ;
    
    % Resize function according to type
    if  iscell (  buf.( f )  )
      h = @cell ;
    else
      h = @zeros ;
    end
    
    % Resize buffer
    buf.( f ) = [  buf.( f )  ;  h( N , c )  ] ;
    
  end % buffer fields
  
  % Update number of elements
  buf.n = buf.n  +  N ;
  
end % resizeb


% Check for trial.nsp buffer for digin copy of MET signal mstop
function  nsp = nspmstop ( nsp )
  

  %%% Global MET controller constants %%%
  
  global  MCC
  
  % mstop MET signal identifier
  msid = MCC.MSID.mstop ;
  
  % digin value column
  DIGVAL = MCC.SHM.NSP.DINVAL - 1 ;
  
  
  %%% Prepare indices %%%
  
  % Locate digital channel
  dig = strcmp ( nsp.label , MCC.SHM.NSP.DINLAB ) ;
  
  if  ~ any ( dig )
    met ( 'print' , 'metgui:nspmstop: no nsp digin channel found' , 'E' )
    return
  end
  
  
  %%% Check each new read for mstop %%%
  
  % First past the last read checked for mstop to the last read in buffer
  for  i = nsp.msi + 1 : nsp.i
    
    % Point to digital input values
    vdig = nsp.b{ i }{ dig , DIGVAL } ;
    
    % No digital input events , go to next read
    if  isempty (  vdig  )  ,  continue  ,  end
    
    % Locate signal identifiers in digital input , as opposed to cargos
    j = vdig  <=  MCC.SHM.NSP.SIGMAX ;
    
    % Look for digin mstop signal
    if  any ( vdig( j )  ==  msid )
      
      % We found it! Update mstop flag and quit search
      nsp.mstop = true ;
      return
      
    end % digin mstop
    
  end % check reads
  
  % digin mstop not found
  nsp.mstop = false ;
  
  % Last read that we checked
  nsp.msi = nsp.i ;
  
  
end % nspmstop


% Collapse trial buffer nsp data down into a 2D cell array where each
% element contains a double vector will all data from that channel / unit
function  f = nspfin ( nsp )
  
  % Index of last read from nsp
  i = nsp.i ;
  
  % Nothing read from nsp shm
  if  ~ i  ,  return  ,  end
  
  % Size of one read
  s = size (  nsp.b { 1 }  ) ;
  
  % Concatenate reads together
  f = cellfun ( @coll , nsp.b { 1 : i } , 'UniformOutput' , false ) ;
  
  % Reshape concatentation from vector to 2D matrix
  f = reshape (  f  ,  s  ) ;
  
end % nspfin


% Function for cellfun argument in nspfin , collapse input arguments
% together
function  c = coll ( varargin )
  
  c = [ varargin{ : } ] ;
  
end % coll


function  savetdat (  TDFNAM  ,  sd  ,  td  ,  tbuf  )
  

  %%% Global Constants %%%
  
  % MET constants & controller constants
  global  MC  MCC
  
  % MET signal identifiers
  MSID = MCC.MSID ;
  
  
  %%% Binary files %%%
  
  
  %-- MET signals --%
  
  % Trial identifer as string
  tid = num2str (  sd.trial_id  ) ;
  
  % Generate file name with full path
  f_msig = sprintf (  TDFNAM.METSIG  ,  sd.trial_id  ) ;
  f_msig = fullfile ( sd.session_dir , MC.SESS.TRIAL , tid , f_msig ) ;
  
  % Name data in separate variables
  msig = tbuf.msig ;
  i = 1 : msig.i ;
  src = msig.b ( i , msig.src ) ;
  sig = msig.b ( i , msig.sig ) ;
  crg = msig.b ( i , msig.crg ) ;
  tim = msig.b ( i , msig.tim ) ;
  
  % Save to file
  save (  f_msig  ,  'src'  ,  'sig'  ,  'crg'  ,  'tim'  )
  
  
  %-- Hit regions --%
  
  if  isfield ( tbuf , 'stim' )
    
    % File name with full path
    f_stim  = sprintf (  TDFNAM.HITREG  ,  sd.trial_id  ) ;
    f_stim  = fullfile ( sd.session_dir , MC.SESS.TRIAL , tid , f_stim ) ;
    
    % Point to finalised buffer
    stim = tbuf.stim.final ;
    
    % Save data
    save ( f_stim , '-struct' , 'stim' )
    
  end % hitregion
  
  
  %-- Eye positions --%
  
  if  isfield ( tbuf , 'eye' )
    
    % Shared memory column indecex
    I = MCC.SHM.EYE.COLIND ;
    
    % Eye position column index
    EI = [ I.XLEFT , I.YLEFT , I.XRIGHT , I.YRIGHT ] ;
    
    % Mouse position column index
    MI = [ I.XLEFT , I.YLEFT ] ;
    
    % File name wth full path
    f_eye  = sprintf (  TDFNAM.EYEPOS  ,  sd.trial_id  ) ;
    f_eye  = fullfile ( sd.session_dir , MC.SESS.TRIAL , tid , f_eye  ) ;
    
    % Eye trial buffer
    tb = tbuf.eye ;
    
    % Make output variable for eye positions ...
    eye.time = tb.b(  1 : tb.i_b  ,  I.TIME  ) ;
    eye.position = tb.b(  1 : tb.i_b  ,  EI  ) ;
    
    % ... pupil diameters ...
    pupil.time = tb.d(  1 : tb.i_d  ,  I.TIME  ) ;
    pupil.diameter = tb.d(  1 : tb.i_d  ,  EI  ) ;
    
    % ... and mouse positions
    mouse.time = tb.m(  1 : tb.i_m  ,  I.TIME  ) ;
    mouse.position = tb.m(  1 : tb.i_m  ,  MI  ) ;
    
    % Convert .position type from double to int16. Remember, positions are
    % changed to hundredths of degrees of visual field. Diameters are
    % already in an acceptable range.
      eye.position = int16 (  100  *    eye.position  ) ;
    pupil.diameter = int16 (          pupil.diameter  ) ;
    mouse.position = int16 (  100  *  mouse.position  ) ;
    
    % Save data
    save (  f_eye  ,  'eye'  ,  'pupil'  ,  'mouse'  )
    
  end % eye positions
  
  
  %%% ASCII version %%%
  
  
  %-- MET signals --%
  
  % Trial's task logic
  l = sd.logic.( td.logic ) ;
  
  % Keep a copy of signal vector
  s = sig ;
  
  % Convert to cell arrays
  src = num2cell ( src ) ;
  sig = num2cell ( sig ) ;
  crg = num2cell ( crg ) ;
  tim = num2cell ( tim ) ;
  
  % String cell array
  S = cell ( size(  sig  ) ) ;
  
  % Signals other than mstate, mtarget, and mstop
  i = s ~= MSID.mstate  &  s ~= MSID.mstop  &  s ~= MSID.mtarget ;
  
  S( i ) = cellfun (  @( src , sig , crg , tim )  ...
    sprintf ( [ '%d,' , MCC.FMT.TIME , ',%s,%d' ] , ...
      src , tim , MC.SIG{ sig + 1 , 1 } , crg )  ,  ...
    src( i )  ,  sig( i )  ,  crg( i )  ,  tim( i )  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % mstate
  i = s  ==  MSID.mstate ;
  
  S( i ) = cellfun (  @( src , sig , crg , tim )  ...
    sprintf ( [ '%d,' , MCC.FMT.TIME , ',%s,%s' ] , ...
      src , tim , MC.SIG{ sig + 1 , 1 } , l.nstate{ crg } )  ,  ...
    src( i )  ,  sig( i )  ,  crg( i )  ,  tim( i )  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % mtarget
  i = s  ==  MSID.mtarget ;
  
  S( i ) = cellfun (  @( src , sig , crg , tim )  ...
    sprintf ( [ '%d,' , MCC.FMT.TIME , ',%s,%s' ] , ...
      src , tim , MC.SIG{ sig + 1 , 1 } , l.nstim{ crg } )  ,  ...
    src( i )  ,  sig( i )  ,  crg( i )  ,  tim( i )  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % mstop
  i = s  ==  MSID.mstop ;
  
  S( i ) = cellfun (  @( src , sig , crg , tim )  ...
    sprintf ( [ '%d,' , MCC.FMT.TIME , ',%s,%s' ] , ...
      src , tim , MC.SIG{ sig + 1 , 1 } , MC.OUT{ crg , 1 } )  ,  ...
    src( i )  ,  sig( i )  ,  crg( i )  ,  tim( i )  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % Concatenate into a single string
  S = strjoin (  S  ,  '\n'  ) ;
  
  % File name
  f_msig = strrep ( f_msig , '.mat' , '.txt' ) ;
  
  % Save file
  metsavtxt ( f_msig , S , 'w' , 'metgui' )
  
  
  %-- Hit regions --%
  
  if  isfield ( tbuf , 'stim' )
    
    % File name
    f_stim = strrep ( f_stim , '.mat' , '.txt' ) ;
    
    % Time stamps for each hit region list. Transpose this and the
    % remaining data so that we work along rows first i.e. reads from
    % 'stim' that arrived at the same time. This way, strings will be
    % provided in chronological order.
    TS = num2cell ( ...
      repmat (  stim.time  ,  1  ,  size ( stim.hitregion , 2 )  )  )' ;
    
    % Stimulus link name for each hit region list
    SL = repmat (  stim.stimlink  ,  size( stim.hitregion , 1 )  ,  1  )' ;
    
    % Non-empty hit region lists
    stim.hitregion = stim.hitregion' ;
    i = ~ cellfun (  @isempty  ,  stim.hitregion  ) ;
    
    % Convert hit regions to string
    S = cellfun (  @stim2str  ,  ...
      stim.hitregion( i )  ,  TS( i )  ,  SL( i )  ,  ...
      'UniformOutput'  ,  false  ) ;
    
    % Save file
    metsavtxt ( f_stim , [ S{ : } ] , 'w' , 'metgui' )
    
  end % hitregion
  
  
  %-- Eye positions --%
  
  if  ~ isfield ( tbuf , 'eye' )  ,  return  ,  end
  
  % Format strings for eye and mouse positions
  S = sprintf ( '\n' ) ;
  eyefmt = [  MCC.FMT.TIME  ,  repmat( ',%0.2f' , 1 , 4 )  ,  S  ] ;
  moufmt = [  MCC.FMT.TIME  ,  repmat( ',%0.2f' , 1 , 2 )  ,  S  ] ;
  
  % Position strings
  if  tb.i_b
    eyestr = sprintf( eyefmt , tb.b ( 1 : tb.i_b , [ I.TIME , EI ] )' ) ;
  else
    eyestr = '' ;
  end
  
  if  tb.i_d
    pupstr = sprintf( eyefmt , tb.d ( 1 : tb.i_d , [ I.TIME , EI ] )' ) ;
  else
    pupstr = '' ;
  end
  
  if  tb.i_m
    moustr = sprintf( moufmt , tb.m ( 1 : tb.i_m , [ I.TIME , MI ] )' ) ;
  else
    moustr = '' ;
  end
  
  % Build output string
  S = [  sprintf(   'eye_position: \n' )  ,  eyestr  ,  ...
         sprintf( 'pupil_diameter: \n' )  ,  pupstr  ,  ...
         sprintf( 'mouse_position: \n' )  ,  moustr  ] ;
  
  % File name
  f_eye = strrep ( f_eye , '.mat' , '.txt' ) ;
  
	% Save file
  metsavtxt ( f_eye , S , 'w' , 'metgui' )
  
end % savetdat


% Build a line for hit region output string
function  s = stim2str ( h , t , s )
  
  % MET controller constants
  global  MCC
  
  % Time stamp and stimulus link string
  timstmstr = sprintf (  [ MCC.FMT.TIME , ',%s: \n' ]  ,  t  ,  s  ) ;
  
  % Hit region format string , either 5 or 6 column
  hitfmt = [  '  %0.2f'  ,  ...
              repmat(  ',%0.2f'  ,  1  ,  size( h , 2 ) - 1  )  ,  ...
              sprintf( '\n' )  ] ;
  
  % Hit region string
  s = [  timstmstr  ,  sprintf( hitfmt , h' )  ] ;
  
end % stim2str


% Save controller's recovery data
function  saverec (  fnrec  ,  sd  ,  bd  ,  outc  ,  blk  )
  
  % Current trial_id
  trial_id = sd.trial_id ;
  
  % Current environment variables
  evar = sd.evar ;
  
  % Store recovery data
  save ( fnrec , 'bd' , 'outc' , 'blk' , 'trial_id' , 'evar' )
  
end % saverec


% Loads recovery data from a session directory that was re-opened but never
% finalised
function  [ sd , bd , outc , blk ] = recover ( fnrec , sd , outc , blk )
  
  % Global MET constants
  global  MC MCC
  
  % Load recovery data
  r = load (  fnrec  ) ;
  
  % Fetch block descriptor
  bd = r.bd ;
  
  % Assign trial and block identifiers , and reset environment variables
  sd.trial_id =  r.trial_id ;
  sd.block_id = bd.block_id ;
  sd.evar = r.evar ;
  
  % Number of buffered trial outcomes
  i = numel (  r.outc  ) ;
  outc.i = i ;
  
  % Outcome buffer is too small
  if  outc.n  <  i
    
    % Replace buffer with the loaded one
    outc.n = i ;
    outc.b = r.outc ;
    
  else
    
    % Fill existing buffer
    outc.b( 1 : i ) = r.outc ;
    
  end
  
  % Number of buffered block ids
  i = numel ( r.blk ) ;
  blk.i = i ;
  
  % Block buffer is too small
  if  blk.n  <  i
    
    % Replace buffer with loaded one
    blk.n = i ;
    blk.b = r.blk ;
    
  else
    
    % Fill existing buffer
    blk.b( 1 : i ) = r.blk ;
    
  end
  
  % Look to see if another trial was started before the system went down
  tdir = fullfile (  sd.session_dir  ,  MC.SESS.TRIAL  ,  ...
    num2str( sd.trial_id  +  1 )  ) ;
  
  % Not done , return
  if  ~ exist (  tdir  ,  'dir'  )  ,  return  ,  end
  
  % Crash message file name
  tdir = fullfile (  tdir  ,  MCC.CRASHF  ) ;
  
  % Write crash message to trial directory
  metsavtxt ( tdir , sprintf( MCC.CRASHS , sd.trial_id ) , 'w' , 'metgui' )
  
  % Increment trial identifier to skip crashed trial
  sd.trial_id = sd.trial_id  +  1 ;
  
end % recover


% metgui needs to create a MET GUI recovery directory when a new session is
% opened
function  mkmgrec ( mgrec )
  
  % Something else has already made this directory
  if  exist ( mgrec , 'dir' )  ,  return  ,  end
  
  % Try to make new directory
  [ s , m ] = mkdir ( mgrec ) ;
  
  if  ~ s
    
    error ( 'MET:metgui:mkmgrec' , ...
      'metgui: failed to create %s\n  Got error: %s' , mgrec , m )
    
  end
  
end % mkmgrec


% Reset buffer , buf is buffer struct , sets .i to 0 and clears contents of
% .b if it is a cell array , .final is cleared if it exists
function  buf = resetb (  buf  )
  
  % Buffer is supported by cell array
  if  iscell (  buf.b  )
    
    % Clear it
    buf.b( 1 : buf.i ) = cell ( buf.i , 1 ) ;
    
  end
  
  % Field names
  F = fieldnames ( buf ) ;
  
  % Find index fields
  i = ~ cellfun (  @isempty  ,  regexp ( F , '^i(_[bdm])*$' , 'once' )  ) ;
  
  % Set index fields to zero
  for  F = F ( i )'
    buf.( F{ 1 } ) = 0 ;
  end
  
  % Has field .final
  if  isfield (  buf  ,  'final'  )
    
    % Clear it too
    buf.final = [] ;
    
  end
  
end % resbuf


% Decide whether or not to buffer the current block id , and return updated
% block buffer
function  blk = updateblk ( blk , bd )
  
  % Buffer not empty and current block id is the last one to have been
  % buffered , no action required
  if  blk.i  &&  blk.b( blk.i ) == bd.block_id  ,  return  ,  end
          
  % Resize buffer at need
  if  blk.i  ==  blk.n
    blk.b = [  blk.b  ;  zeros( blk.n )  ] ;
    blk.n = 2 * blk.n ;
  end

  % Buffer block id
  blk.i = blk.i + 1 ;
  blk.b( blk.i ) = bd.block_id ;
  
end  %  updateblk


% Generates a brief report about the properties of a newly generated trial.
function  s = trialstr ( bd , td )
  
  % Trial's origin and reward coefficients to cell arrays
  O = num2cell ( td.origin ) ;
  R = num2cell ( td.reward ) ;
  
  % Trial information , task variables formed later
  S = cell ( 1 , 2 ) ;
  
  S{ 1 } = sprintf (  [ '\n\n  Trial ID: %d , Block ID: %d (%s)' , ...
    ', Task: %s (%s)' , ...
    '\n  Origin: ( x %0.2f , y %0.2f , d %0.2f ) , ' , ...
    'Reward coef: %d + %0.2fxr\n  Task variables:' ]  ,  ...
    td.trial_id , td.block_id , td.block_name , td.task , td.logic , ...
    O { : } , R { : } ) ;
  
  % Find which task variables are changed for this task
  i = ~ isnan ( bd.deck(  1  ,  :  ) ) ;
  
  % Variable names and values
  V = [  bd.varnam( i )  ;  num2cell( bd.deck(  1  ,  i  ) )  ] ;
  V( 2 , : ) = cellfun (  @( v )  num2str ( v )  ,  V ( 2 , : )  ,  ...
    'UniformOutput'  ,  false  ) ;
  
  % Build task variable string
  S{ 2 } = sprintf( '\n    %s = %s' , V { : } ) ;
  
  % Return trial string
  s = [ S{ : } ] ;
  
end % trialstr

