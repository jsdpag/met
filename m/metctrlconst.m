
function  MCC = metctrlconst ( MC )
% 
% MCC = metctrlconst ( MC )
% 
% Returns a struct of MET controller constants for standardising activity
% between different controllers. Accepts one optional input argument, MC,
% which is the calling MET controller's MET constant struct and contains
% run-time constants in addition to compile-time constants. If this is not
% provided, or an empty array is given, then compile-time constants are
% looked for.
% 
% Written by Jackson Smith - Sept 2016 - DPAG , University of Oxford
% 
  
  
  %%% MET constants %%%
  
  % Absolute path to home directory , want this and not ~
  ABSHOME = ls ( '-d' , '~' ) ;
  ABSHOME = regexprep ( ABSHOME , '\n' , '' ) ;
  
  % Function internal constant , flags whether met( ) function is visible.
  % Flag will be low if the operating system is not UNIX ... read 'linux'
  HASMET = ~ isempty ( which(  'met'  ) )  &&  isunix  &&  ~ ismac  &&  ...
    ~ ispc ; 
  
  % MET run-time constants given , and met( ) function is visible
  if  0 < nargin  &&  ~ isempty ( MC )  &&  HASMET
    
    % Check correctness of the input
    if  ~ isscalar ( MC )  ||  ~ isstruct ( MC )
      
      error ( 'MET:metctrlconst:MC' , ...
        'metctrlconst: MC must be a scalar struct' )
      
    % Must have all the same fields as the struct returned by met
    elseif  any (  ~ ismember(  fieldnames(  MC  )  ,  ...
                                fieldnames(  met( 'const' , 1 )  )  )  )
     
      error (  'MET:metctrlconst:MC'  ,  [ 'metctrlconst: ' , ...
        'MC has wrong field names , see ''const'' in help met' ]  )
      
    end % check MC
    
  % Can't find met( ) function , as may be the case in special
  % circumstances , such as developing MET stimulus definitions in a
  % non-MET environment
  elseif  ~ HASMET
    
    MC = [] ;
    
  % Load compile-time constants
  else
    
    MC = met ( 'const' , 1 ) ;
    
  end
  
  % MET signal identifiers
  if  ~ isempty ( MC )
    
    MCC.MSID = MC.SIG' ;
    MCC.MSID = struct (  MCC.MSID { : }  ) ;
    
  end % MET sids
  
  
  %%% Directories & Files %%%
  
  % Default subject directory
  MCC.DEFSUB = fullfile ( ABSHOME , 'subject' ) ;
  
  % Session descriptor file name , to be written into the session directory
  MCC.SDFNAM = 'sessdesc.mat' ;
  
  % Can't find met
  if  isempty ( MC )
    
    MCC.MRCNTL = [] ;
    MCC.VERNAM = [] ;
    MCC.STMRES = [] ;
    MCC.CLASSDIR = [] ;
    
  else
    
    % MET root file where MET controller function name and shm attributes
    % are written
    MCC.MRCNTL = fullfile ( MC.ROOT.ROOT , 'cntlattrib' ) ;
    
    % Return absolute path, up to at least MET 00.03.91 MC.ROOT.ROOT was
    % '~/.met' , in future this might become the absolute path
    if  MCC.MRCNTL( 1 )  ==  '~'
      MCC.MRCNTL = [ ABSHOME , MCC.MRCNTL( 2 : end ) ] ;
    end

    % MET program directory version file name
    MCC.VERNAM = fullfile ( fileparts(  MC.PROG.STIM  ) , 'version.txt' ) ;
    
    % MET stimulus definition resource directory
    MCC.STMRES = fullfile (  MC.PROG.STIM  ,  'resources'  ) ;
    
    % MET stimulus class directory
    MCC.CLASSDIR = fullfile (  MC.PROG.STIM  ,  'met.stim.class'  ) ;
    
  end
  
  % MET .csv file column headers
  MCC.CSVHDR = { 'param' , 'value' } ;
  
  % MET GUI directory
  MGNDIR = 'mgui' ;
  MCC.GUIDIR = fullfile (  fileparts( which(  'metgui'  ) )  ,  MGNDIR  ) ;
  
  % Raise error if the met/m directory is visible but the mgui dir is not
  if  HASMET  &&  ~ exist (  MCC.GUIDIR  ,  'dir'  )
    
    error (  'MET:metctrlconst:guidir'  ,  [ 'metctrlconst: ' , ...
      'failed to locate MET GUI definition directory , %s' ]  ,  ...
      MCC.GUIDIR  )
    
  elseif  ~ HASMET
    
    % No valid directory
    MCC.GUIDIR = [] ;
    
  end
  
  % System crash recovery message file. Added to trial directory of the
  % trial that experienced a crash.
  MCC.CRASHF = 'system_crash.txt' ;
  
  
  %%% Regular Expressions %%%
  
  % Subject directory
  MCC.REX.SUBJECT = '(?<subject_id>\w+)\.(?<subject_name>\w+)' ;
  
  % Date string  YYYYMMDD
  MCC.REX.DATESTR = '(?<date>\d{8})' ;
  
  % Session directory , must append subject ID to head of string
  MCC.REX.SESSDIR = ...
    '\.(?<experiment_id>\d+)\.(?<session_id>\d+)(?<tags>(\.\w+)*)' ;
  
  % Single tag
  MCC.REX.TAG = '\w+' ;
  
  % Valid name in task logic and schedule
  MCC.REX.VALNAM = '^[a-zA-Z]+\w*$' ;
  
  % Comment character for MET text files
  MCC.REX.COMMENT = '%' ;
  
  % Any real number
  MCC.REX.REALNUM = '\d+(\.\d+)?' ;
  
  % MET Session dialogue task variable value list expansion format
  MCC.REX.EXPANSION = sprintf (  '^[+-]?%s:[+]?[1-9]+\\d*:[+]?%s$'  ,  ...
    MCC.REX.REALNUM  ,  MCC.REX.REALNUM  ) ;
  
  % MET session dialogue task variable value list format
  MCC.REX.LIST = sprintf (  '^[+-]?%s(,[+-]?%s)*$'  ,  ...
    MCC.REX.REALNUM  ,  MCC.REX.REALNUM  ) ;
  
  
  %%% Format strings %%%
  
  % <Subject ID>.<Subject name>
  MCC.FMT.SUBJECT = '%s.%s' ;
  
  % Date - intended for use with sprintf or fprintf where the second
  % argument is a 3 element vector of numbers with order
  % [ year , month , day ]
  % e.g. d = [ 2016 , 09 , 28 ] ; sprintf ( '%02d' , d )
  MCC.FMT.DATESTR = '%02d' ;
  
  % Session directory
  % <Subject ID>.<Experiment ID>.<Session ID><tag string>
  MCC.FMT.SESSDIR = '%s.%d.%d%s' ;
  
  % Tag string , like date string , use a cell vector of strings as the
  % second argument to sprintf
  % e.g. t = { 'tag1' , 'tag2' } ; sprintf ( '.%s' , t { : } )
  MCC.FMT.TAGSTR = '.%s' ;
  
  % Time string , for time measurements from PTB or MET
  MCC.FMT.TIME = '%0.6f' ;
  
  % Trial descriptor file name , accepting either a string ( S ) or a
  % decimal integer ( D )
  MCC.TDNAMS = 'param_%s.mat' ;
  MCC.TDNAMD = 'param_%d.mat' ;
  
  % Message written to the system crash text file.
  MCC.CRASHS = [  ...
    'MET appears to have crashed during trial %d\n' , ...
    'This trial ID has been skipped.\n' , ...
    'The same parameters have been used in the next trial.\n'  ] ;
  
  
  %%% Blackrock Microsystems Inc NSP format strings %%%
  
  % Volume i.e. the data drive. Drive c: is a separate drive where the
  % operating system and program files live ... don't use that. In the
  % olden days, drives a: and b: were for floppy disks, but d: is, in this
  % case, a hard drive.
  MCC.NSP.VOLUME = 'd:' ;
  
  % Microflop file separator character
  MCC.NSP.SEPCHR = '\' ;
  
  % Replacement character for periods i.e. full-stops that might otherwise
  % confuse poor old Microflop. For instance, session directory
  % M000.Test.123.4.tag1.tag2 will be renamed M000_Test_123_4_tag1_tag2 on
  % the Blackrock's Host PC.
  MCC.NSP.REPCHR = '_' ;
  
  % The master subject directory , automatically connected to the data
  % drive
  [ ~ , MCC.NSP.DEFSUB ] = fileparts (  MCC.DEFSUB  ) ;
  MCC.NSP.DEFSUB = strjoin (  { MCC.NSP.VOLUME , MCC.NSP.DEFSUB }  ,  ...
    MCC.NSP.SEPCHR  ) ;
  
  % The file name prefix that comes before the trial id
  MCC.NSP.FPREFX = 'trial_' ;
  
  
  %%% File name search strings %%%
  
  MCC.SCH.SUBJECT = '*.*/' ;
  MCC.SCH.DATESTR = '*/' ;
  MCC.SCH.SESSDIR = '*.*.*/' ;
  
  
  %%% Data structures %%%
  
  % Standard variable names for session, block, and trial descriptors
  MCC.DAT.VNAM = { 'sd' , 'bd' , 'td' } ;
  
  % Receptive/response field definition field names, defaults, and ranges.
  % Column order { field name , default , min value , max value }.
  % x- and y-axis coordinates, Michelson contrast, RF diameter, preferred
  % orientation e.g. of a bar, preferred speed, preferred disparity.
  MCC.DAT.RFDEF = {       'xcoord' ,   0 ,  -Inf ,  +Inf ;
                          'ycoord' ,   0 ,  -Inf ,  +Inf ;
                        'contrast' ,   1 ,     0 ,     1 ;
                           'width' ,   1 ,     0 ,  +Inf ;
                     'orientation' ,  90 ,  -Inf ,  +Inf ;
                           'speed' ,   0 ,     0 ,  +Inf ;
                       'disparity' ,   0 ,  -Inf ,  +Inf  } ;
  
  % Session descriptor - Contains all information about the current
  % session. subject_id - Subject ID such as M123. subject_name - Subject
  % name such as MrMonkey. date - Date string, YYYYMMDD, that the session
  % was run. experiment_id - The experiment identifier, a unique integer
  % assigned to each experiment, where an experiment consists of a group of
  % sessions. session_id - Session identifier, unique to each session
  % within an experiment. tags - set of strings that describe the session.
  % session_dir - Full path to the session directory of the current
  % session. trial_id - Trial identifier, changes for each new trial.
  % block_id - block identifier, changes for each new block. rfdef -
  % Session constants that define the properties of a set of
  % receptive/response fields that are passed to MET stimulus definition
  % functions in order to automatically adjust default stimulus values.
  % logic - the set of task logics used in the session, format as returned
  % by metparse. task - the set of tasks used in the session, as returned
  % by metparse. type - the type string for each MET stimulus definition
  % used by the session. vpar - set set of variable parameter declarations
  % for each MET stimulus definition used by the session. var - the set of
  % task variables used in the session, as returned by metparse. block -
  % the set of all types of trial blocks used in the session, as returned
  % by metparse. evar - the environment variable values, as returned by
  % metparse.
  MCC.DAT.SD = desc (  { 'subject_id' , 'subject_name' , 'date' , ...
    'experiment_id' , 'session_id' , 'tags' , 'session_dir' , ...
    'trial_id' , 'block_id' , 'rfdef' , 'logic' , 'task' , 'type' , ...
    'vpar' , 'var' , 'block' , 'evar' }  ) ;
  
    % Initialise an empty rfdef struct vector
    MCC.DAT.SD.rfdef = desc (  MCC.DAT.RFDEF( : , 1 )'  ) ;
    MCC.DAT.SD.rfdef( 1 ) = [] ;
  
    % Default environment variables
    MCC.DAT.SD.evar.origin = [ 0 , 0 ] ;
    MCC.DAT.SD.evar.disp   = 0 ;
    MCC.DAT.SD.evar.reward = [ 200 , 1 ] ;
    
    % .tags field must be an empty cell array
    MCC.DAT.SD.tags = {} ;
  
  % Block descriptor
  MCC.DAT.BD = desc (  { 'block_id' , 'name' , 'task' , 'var' , ...
    'varnam' , 'deck' , 'attempts' }  ) ;
  
  % Trial descriptor
  MCC.DAT.TD = desc (  { 'trial_id' , 'task' , 'logic' , 'block_name' , ...
    'block_id' , 'origin' , 'reward' , 'var' , 'state' , 'stimlink' , ...
    'sevent' , 'mevent' , 'calibration' }  ) ;
    
    % State timeout changes
    MCC.DAT.TD.state = desc (  { 'istate' , 'nstate' , 'timeout' }  ) ;
    
    % Stimulus links
    MCC.DAT.TD.stimlink = desc (  { 'istim' , 'nstim' , 'name' , ...
      'stimdef' , 'type' , 'vpar' }  ) ;
    
    % Stimulus events
    MCC.DAT.TD.sevent = desc (  { 'name' , 'istate' , 'nstate' , ...
      'nstimlink' , 'istimlink' , 'vpar' , 'value' }  ) ;
    
    % MET signal events
    MCC.DAT.TD.mevent = desc (  { 'name' , 'istate' , 'nstate' , ...
      'msig' , 'msigname' , 'cargo' }  ) ;
  
  % The maximum value of a signal ID recorded by NSP digital input
  MCC.DAT.MAXSIG = double ( intmax ( 'uint8' ) ) ;
  
  % The maximum value of a MET signal's cargo
  MCC.DAT.MAXCRG = intmax ( 'uint16' ) ;
  
  % Current-buffer for latest MET signals and shared memory , start by
  % building a list of the names of shared memory that the controller can
  % read ...
  SHMNAM = {} ;
  if  ~ isempty ( MC )  &&  ~ isempty (  MC.SHM  )
    SHMNAM = MC.SHM( [ MC.SHM{ : , 2 } ]  ==  'r'  ,  1  )' ;
  end
  
  % ... then define the struct ...
  MCC.DAT.cbuf = desc( [  { 'new_msig' , 'msig' , 'shm' }  ,  SHMNAM  ] ) ;
  
  % ... and nested MET signals struct.
  MCC.DAT.cbuf.msig =  desc(  { 'n' , 'src' , 'sig' , 'crg' , 'tim' }  ) ;
  
  % Field .shm must be a two-column cell array
  MCC.DAT.cbuf.shm = cell ( 0 , 2 ) ;
  
  
  %%% Shared memory %%%
  
  % Shared memory names
  MCC.SHM.NAMES = { 'stim' , 'eye' , 'nsp' } ;
  
  
  %-- stim --%
  
  % Constants contain the ordinal position of objects in the set that are
  % written to stim shm. Only hit-region matrices will be written , not
  % variable parameters.
  
  % The expected presentation time of the next frame
  MCC.SHM.STIM.TIME = 1 ;
  
  % A logical index corresponding to stimulus links listed in the trial
  % descriptor's stimlink field that have had updated vpar structs written
  % to stim shm. Make it a column vector.
  MCC.SHM.STIM.LINDEX = 2 ;
  
  % The first hit-region matrix , the rest follow in sequence
  MCC.SHM.STIM.HITREG = 3 ;
  
  % Number of columns allowable , either 6 or 8
  MCC.SHM.STIM.NCOL = [ 6 , 8 ] ;
  
  % Rectangular hit-region , column indeces
  MCC.SHM.STIM.RECT8 = { 'XCOORD' , 1 ;
                         'YCOORD' , 2 ;
                          'WIDTH' , 3 ;
                         'HEIGHT' , 4 ;
                       'ROTATION' , 5 ;
                      'DISPARITY' , 6 ;
                      'TOLERANCE' , 7 ;
                         'IGNORE' , 8 }' ;
	MCC.SHM.STIM.RECT8 = struct (  MCC.SHM.STIM.RECT8 { : }  ) ;
  
  % Circular hit-region , column indeces
  MCC.SHM.STIM.CIRC6 = { 'XCOORD' , 1 ;
                         'YCOORD' , 2 ;
                         'RADIUS' , 3 ;
                      'DISPARITY' , 4 ;
                      'TOLERANCE' , 5 ;
                         'IGNORE' , 6 }' ;
	MCC.SHM.STIM.CIRC6 = struct (  MCC.SHM.STIM.CIRC6 { : }  ) ;
  
  
  %-- eye --%
  
  % Shared memory index , the order that each array is written to 'eye'
  % shared memory, or read from. Eye positions are first, pupil diameters
  % are second, mouse positions are third. By convention, mouse positions
  % are treated as left eye positions.
  MCC.SHM.EYE.EYEIND = 1 ;
  MCC.SHM.EYE.IPUPIL = 2 ;
  MCC.SHM.EYE.IMOUSE = 3 ;
  
  % Shared memory eye formatting info , number of columns , symbolic
  % mapping of name to column index , eye positions sampling rate in 
  % Hertz , eye position polling rate i.e. max frequency of calls to
  % DaqAInScan , and touchscreen/mouse polling rate
  MCC.SHM.EYE.NCOL = 5 ;
  MCC.SHM.EYE.COLIND = {  'TIME' , 1 ;
                         'XLEFT' , 2 ;
                         'YLEFT' , 3 ;
                        'XRIGHT' , 4 ; 
                        'YRIGHT' , 5 }' ;
  MCC.SHM.EYE.COLIND = struct ( MCC.SHM.EYE.COLIND { : } ) ;
  MCC.SHM.EYE.SHZ = 500 ;
  MCC.SHM.EYE.EYEPOL = MCC.SHM.EYE.SHZ  /  1.25 ;
  MCC.SHM.EYE.MOUSEPOLL = 40 ;
  
  
  %-- nsp --%
  
  % Reads from cbmex shall be packaged into such a data structure as .STRUC
  % for both saving to a regular file and writing to shared memory. label
  % is a cell array vector of strings that label each row of the data
  % field, itself a cell array. nsp2ptb_time_coef holds the slope and
  % intercept used to convert time stamps from the neural signal processor
  % into local system time values. n and w are context dependent by MET
  % controller ; for instance , the controller that reads from cbmex()
  % might count the number of reads in .n and the number of shm writes to
  % .w. By convention, .data will contain a n x m cell array of n different
  % recording channels with up to m separately identified units. The type
  % of vector in each cell is context dependent. NOTE: 'nsp' shared memory
  % will convey two arrays ; the first will be a copy of the struct, and
  % the second will be the trial identifier associated with the read
  MCC.SHM.NSP.STRUC = desc (  { 'label' , 'nsp2ptb_time_coef' , 'data' ,...
    'n' , 'w' }  ) ;
  MCC.SHM.NSP.STRUC.nsp2ptb_time_coef = desc( { 'intercept' , 'slope' } ) ;
  
  % The allowable cbmex ( 'trialdata' ) sampling rate
  MCC.SHM.NSP.SHZ = 50 ;
  
  % Neural signal processor raw data sampling rate
  MCC.SHM.NSP.RAWSHZ = 30000 ;
  
  % NSP spike channel label prefix , regular expression. Recognises labels
  % such as chan123, elec123, elec1-123.
  MCC.SHM.NSP.SPKLAB = '^(chan|elec(\d+-)?)\d+$' ;
  
  % NSP digital input channel label
  MCC.SHM.NSP.DINLAB = 'digin' ;

  % The maximum value of a signal identifier in NSP digital input. Anything
  % above this is a cargo.
  MCC.SHM.NSP.SIGMAX = intmax ( 'uint8' ) ;
  
  % The number of bits to shift down when converting cargo value
  MCC.SHM.NSP.BSHIFT = -8 ;
  
  % NSP digital input NSP time stamp column index , as returned by cbmex
  % 'trialdata'
  MCC.SHM.NSP.DINTIM = 2 ;
  
  % NSP unsigned int 16 value of digital input , column index
  MCC.SHM.NSP.DINVAL = 3 ;
  
  % 'nsp' shared memory indeces for the data structure and for the
  % associated trial identifier
  MCC.SHM.NSP.DATIND = 1 ;
  MCC.SHM.NSP.TIDIND = 2 ;
  
  % Maximum number of front end channels on NSP
  MCC.SHM.NSP.MAXCHN = 128 ;
  
  % Maximum unit index, starting from 0
  MCC.SHM.NSP.MAXUNI = 5 ;
  
  % Duration to wait after file opened before any other action, to allow
  % for file to start registering data, in seconds
  MCC.SHM.NSP.FOPDUR = 0.4 ;
  
  
  %%% schedule.txt %%%
  
  % sched and outcome not included here , they're a special case
  
  % Set of independent task variable distributions. These are anonymous
  % function handles. They all have the form h( n , a1 , ... ) to generate
  % a column vector of N sampled numbers using input arguments a1 and so
  % forth.
  MCC.DIST.IND.unic = @( N , u0 , u1 )  ( u1 - u0 ) * rand( N , 1 ) + u0 ;
  MCC.DIST.IND.unid = @( N , u0 , u1 )  ...
    round (  MCC.DIST.IND.unic ( N , u0 , u1 )  ) ;
  MCC.DIST.IND.bin  = @( N , n , p )  binornd ( n , p , N , 1 ) ;
  MCC.DIST.IND.norm = @( N , m , s )  s * randn ( N , 1 ) + m ;
  MCC.DIST.IND.pois = @( N , m )  poissrnd ( m , N , 1 ) ;
  MCC.DIST.IND.exp  = @( N , m )    exprnd ( m , N , 1 ) ;
  MCC.DIST.IND.geo  = @( N , s , p )  geornd( p , N , 1 ) + s ;
  
  % Domain of independent parametric distributions and each input argument,
  % and range of each input arg.
  %
  % { cdc1c2... , [ min_a1 , max_a1 ] , [ min_a2 , max_a2 ] , ... }
  MCC.DIST.DOMAIN.unic = { 'fff' , [ -Inf , Inf ] , [ -Inf , Inf ] } ;
  MCC.DIST.DOMAIN.unid = { 'iii' , [ -Inf , Inf ] , [ -Inf , Inf ] } ;
  MCC.DIST.DOMAIN.bin  = { 'iif' , [ 0 , Inf ] , [ 0 , 1 ] } ;
  MCC.DIST.DOMAIN.norm = { 'fff' , [ -Inf , Inf ] , [ realmin , Inf ] } ;
  MCC.DIST.DOMAIN.pois = { 'if'  , [ realmin , Inf ] } ;
  MCC.DIST.DOMAIN.exp  = { 'ff'  , [ realmin , Inf ] } ;
  MCC.DIST.DOMAIN.geo  = { 'iif' , [ 0 , 1 ] , [ 0 , 1 ] } ;
  
  % Dependent task variable distributions
  MCC.DIST.DEP = { 'same' , 'diff' } ;
  
  % Variable parameters for sevent, mevent, and state. There is a
  % one-to-one mapping, here. Stimulus links take more work.
  MCC.VPMAP.state  = 'timeout' ;
  MCC.VPMAP.sevent =   'value' ;
  MCC.VPMAP.mevent =   'cargo' ;
  
  
  %%% Stimulus definitions %%%
  
  % Here we provide prototypes for input arguments to the stimulus
  % trial initialiser and stimulation functions. Sub-fields are named after
  % each recognised type of stimulus: ptb
  % All MET stimulus definitions require a session initialiser that has the
  % form:
  % 
  %   [ type , varpar , init , stim , close , chksum ] = stim_def_name
  % 
  % Where type is a string being one of the listed recognised types, varpar
  % is a cell array where each row defines a variable parameter of the
  % stimulus, and the remaining output arguments are function handles. The
  % name of the function is the name of the stimulus definition e.g. rdk.m
  % might be the session initialiser defining a random-dot kinetogram. init
  % is the trial initialiser function, stim is the stimulation function
  % used during a trial, close is used after each trial to release any
  % special resources, and chksum produces a checksum value from the
  % stimulus descriptor.
  
  % The code for when the user is not currently selecting any task
  % stimulus , i.e. none. NOTE: this refers to task stimuli from task logic
  % as opposed to stimulus definitions
  MCC.SDEF.none = 1 ;
  
  % Recognised MET stimulus definition types
  MCC.SDEF.types = { 'null' , 'ptb' } ;
  
  % ptb is a PsychToolbox visual stimulus.
  
  % Trial initialiser functions must have the form:
  % 
  %   S = init ( trial_const )
  % 
  % Where S is a new stimulus descriptor.
  % Input argument to trial initialiser is a struct passing in the
  % following values. MCC is the MET controller constants struct, winptr
  % the window pointer, winrec the window rectangle in pixels with format
  % [ left , top , right , bottom ],  winheight and winwidth are the height
  % and width of the PTB window in pixels, wincentx and wincenty are the x
  % and y coordinate of the centre of the PTB window in pixels, the screen
  % flipint[erval] in seconds, pixels per degree, the background value
  % normalised from 0 to 1 with [ red , green , blue ], stereo is the PTB
  % stereomode of the open window with 0 being monoscopic and non-zero
  % being a stereoscopic arrangement, origin is a three element vector
  % giving a point of origin that all MET ptb stimuli will be drawn
  % relative to with values [ x-coordinate , y-coordinate , disparity ]
  % given in degrees of visual field where up and right are positive - down
  % and left are negative - relative to centre of screen.
  MCC.SDEF.ptb.init = desc (  { 'MCC' , 'winptr' , 'winrec' , ...
    'winheight' , 'winwidth' , 'wincentx' , 'wincenty' , 'flipint' , ...
    'pixperdeg' , 'backgnd' , 'stereo' , 'origin'  }  ) ;
  
  % Stimulation functions must have the form:
  % 
  %   [ Snew , h ] = stim ( S , trial_const , trial_var )
  % 
  % Where S is the trial's stimulus descriptor. Any changes to the stimulus
  % are returned in stimulus descriptor Snew, which will be passed in as S
  % on the next iteration of the animation loop. The second input argument
  % is the same scalar struct that passes to init. The third input is also
  % a scalar struct that passes run-time values. eyebuf is the target
  % buffer ID if the PTB window is in stereo mode or -1 if monoccular - it
  % is 0 for the left eye and 1 for the right eye and always comes in that
  % order for each frame, frame is the number of frames presented following
  % the next call to  Screen ( 'Flip' , winptr ) - the frame that we are
  % now drawing to, ftime is the expected stimulus onset time of the next
  % call to Screen 'Flip' in seconds since the last mstart signal, skip is
  % non-zero if the last frame is thought to have been skipped, varpar is a
  % cell array that says which variable parameters must change before
  % drawing occurs and to what value - it is an N row by two column array
  % where each row describes a different variable parameter and the column
  % order is { string variable name , scalar double value } - is an empty
  % array if no parameter change is required.
  % 
  MCC.SDEF.ptb.stim = desc (  { 'eyebuf' , 'frame' , 'ftime' , 'skip' , ...
    'varpar' }  ) ;
  
  % ptb stimulus descriptors must all have a field called .hitregion. It
  % may be a 6 or 8 column double array with N rows. In the 6 column form,
  % a set of N circular hit regions are defined and the column order is
  % [ x-coordinate , y-coordinate , radius , disparity , disp_tolerance ,
  % ignore ]. In the 8 column form, a set of N rectangles are defined and
  % the column order is [ x-coordinate , y-coordinate , width , height ,
  % counter-clockwise rotation , disparity , disp_tolerance , ignore ]. All
  % values are in degrees of visual angle (or degrees, for rotation).
  % Coordinates on screen are given relative to the centre of the screen
  % where up and right are in the positive direction, down and left are in
  % the negative direction. Disparity tolerance is how different the
  % convergence can be from the given disparity. If the eyes enter any of
  % the N hit regions then the stimulus is considered to have been
  % selected. A stimulus is ignored when checking eye/mouse positions if
  % the ignore column is zero ; a stimulus is only checked if this column
  % is non-zero. The constants here give the column index for each kind of
  % value, for 6 or 8 column forms.
  MCC.SDEF.ptb.hitregion.fieldname = 'hitregion' ;
  MCC.SDEF.ptb.hitregion.ncols = [ 6 , 8 ] ;
  MCC.SDEF.ptb.hitregion.sixcol = struct ( 'xcoord' , 1 , ...
    'ycoord' , 2 , 'radius' , 3 , 'disp' , 4 , 'dtoler' , 5 , ...
    'ignore' , 6 ) ;
  MCC.SDEF.ptb.hitregion.eightcol  = struct ( 'xcoord' , 1 , ...
    'ycoord' , 2 , 'width' , 3 , 'height' , 4 , 'rotation' , 5 , ...
    'disp' , 6 , 'dtoler' , 7 , 'ignore' , 8 ) ;
    
  
  %%% Finishing touches %%%
  
  % Make MET ptb stimulus function input structs point to MCC
  MCC.SDEF.ptb.init.MCC = MCC ;
  
  
end % metctrlconst


%%% Sub-routines %%%

% Generic descriptor initialiser , makes struct from list of field names
function  d = desc ( F )
  
  % Pack field names in a cell array with empty matrices
  c = [ F ; cell( size( F ) ) ] ;
  
  % Return struct
  d = struct ( c{ : } ) ;
  
end % desc


