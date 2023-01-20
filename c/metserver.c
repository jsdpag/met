
/*  metserver.c
  
  metserver  RST  REYE  RNSP  MSTR  CSTR  [ MSTR  CSTR ... ]
  
  NOTE: Because POSIX shared memory is used, metserver must
  be compiled like this
  
    gcc  *.c  -o metserver  -lrt
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- Define external global variables ---*/

// UNIX signal flags, lowered. Only signal handlers can raise them.
char  FLGCHLD = 0 ;
char  FLGINT  = 0 ;
char  FLGALRM = 0 ; // Exception - this can be reset.

// MET error code, and temporary storage
unsigned char  meterr = ME_NONE , e = ME_NONE ;


/*--- MAIN FUNCTION ---*/

int  main ( int  argc , char **  argv )
{
  
  
  /*--- Report running ---*/
  
  printf ( "metserver running (pid %lld , pg %lld)\n" ,
    (long long int) getpid () , (long long int) getpgid ( 0 ) ) ;
  
  
  /*--- Compile-time variables ---*/
  
  /*- General variable definitions -*/
  
  // Generic counter , 
  int  i , j ;
  
  // Terminal attributes
  struct termios  tattr ;
  
  /* Number of child controllers requested , number of child
    processes waited for */
  unsigned char  n , w ;
  n = w = 0 ;
  
  /* Child process group, initialised to 0 so that when it is
    passed to setpgid for the first forked process, then the
    pid of that process will become the new pgid. The new pgid
    then becomes the pgid for all remaining forked processes. */
  pid_t  cpg = 0 ;
  
  // One MET signal
  struct metsignal  s = { MCD_SERVER , MSIWAIT , MWAIT_INIT , 0 } ;
  
  // One timeval structure
  struct timeval  tv ;
  
  /* The maximum size of an atomic write to pipes on this system,
    in number of MET signals */
  size_t  awmsig = 0 ;
  
  // epoll object file descriptor
  int  epfd = FDINIT ;
  
  
  /*- POSIX shared memory variable definition -*/
  
  // Number of shared memory readers
  unsigned char  shmnr[ SHMARG ] ;
  
  // Shared memory file descriptors
  int  shmfd[ SHMARG ] ;
  
  // Shared memory file names
  const char *  shmfn[ SHMARG ] = { MSHM_STIM , MSHM_EYE , MSHM_NSP } ;
  
  // Shared memory size in bytes
  size_t  shmfs[ SHMARG ] = { MSMS_STIM , MSMS_EYE , MSMS_NSP } ;
  
  // Event file descriptors. refd, the readers post to it.
  int  refd[ SHMARG ] ;
  
  // initialise shm file descriptors
  for  ( i = 0 ; i < SHMARG ; ++i )
    shmfd[ i ] = refd[ i ] = FDINIT ;
  
  
  /*--- Number of child controllers ---*/
  
  // Check for the minimum allowable number of inputs
  if  ( argc - 1 < SHMARG + NCTRLA )
    FEX ( "metserver: too few input arguments" )
  
  // Check that each controller has enough input arguments
  if  ( ( argc - 1 - SHMARG )  %  NCTRLA )
    FEX ( "metserver: unbalanced number of "
      "child controller input arguments" )
  
  // Check number of child controllers
  n = ( argc - 1 - SHMARG ) / NCTRLA ;
  
  if  ( MAXCHLD  <  n )
    FEX ( "metserver: too many child controllers" )
  
  // Report
  printf ( "Use %d MET child controllers\n" , n ) ;
  
  
  /*--- Run-time variable definitions ---*/
  
  /* Define array for read and write ends of the broadcast and
   request pipes. One element per child controller. 'b' for
   broadcast, 'q' for request, 'r' for read, and 'w' for write. */
  
  int  br[ n ] , bw[ n ] , qr[ n ] , qw[ n ] ;
  
  // Child process id's
  pid_t  c[ n ] ;
  
  /* Event file descriptors. wefd, the writer posts to it. Make
    one for each reader of each shared memory. As for pipe fd
    arrays, the index on the second dimension of wefd and rflg
    will refer to a resource devoted to the controller with
    descriptor of +1 the index. */
  int  * wefd[ SHMARG ] , wefd_array[ SHMARG * n ] ;
  
  // Reader flag, init 0. 1 for child controller that reads shm.
  unsigned char  * rflg[ SHMARG ] , rflg_array[ SHMARG * n ] ;
  
  /* 2D arrays built from 1D. Okay, they're arrays of pointers to
    positions within a contiguous 1D array. But the notation is
    now the same as for 2D array, see initialisation just below. */
  for  ( i = 0 ; i  <  SHMARG ; ++i )
  {
    wefd[ i ] = wefd_array  +  i * n ;
    rflg[ i ] = rflg_array  +  i * n ;
  }
  
  // Initialise arrays
  for  ( i = 0 ; i < n ; ++i )
  {
    // Pipes and child pid
    br[ i ] = FDINIT ;
    bw[ i ] = FDINIT ;
    qr[ i ] = FDINIT ;
    qw[ i ] = FDINIT ;
     c[ i ] = MCINIT ;
    
    // Loop shared memory objects
    for  ( j = 0 ; j  <  SHMARG ; ++j )
    {
      wefd[ j ][ i ] = FDINIT ;
      rflg[ j ][ i ] = 0 ;
    }
  }
  
  
  /*--- Check input ---*/
  
  /* Returns number of shared memory readers. */
  metchkargv ( argc , argv , shmnr , rflg ) ;
  
  
  /*--- UNIX signals: register handlers or ignore ---*/
  
  metunisig () ;
  
  
  /*--- Save current terminal attributes ---*/
  
  if  ( tcgetattr ( STDIN_FILENO , &tattr )  ==  -1 )
    PEX ( "metserver:tcgetattr" )
  
  
  /*--- meterr is still 0, because metchkargv and metunisig exit
    process on error. From now on, meterr can be set. Check for
    previous error codes before requesting any resources or
    running MET server. ---*/
  
  
  /*--- Request unnamed IPC , pipes ---*/
  
  /* Make pipes, initialise non-blocking and close-on-exec */
  
  // UNIX signal flag check
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  // Broadcast pipes
  if  ( e == ME_NONE )
    metpipe ( n , br , bw ) ;
    
  // Request pipes
  if  ( e == ME_NONE )
    metpipe ( n , qr , qw ) ;
    
  /* Get the size of an atomic write to the pipe, or the page 
    size, whichever is smaller */
  if  ( e == ME_NONE )
  {
    awmsig = metatomic ( br[ 0 ] ) / sizeof ( struct metsignal ) ;
    printf ( "atomic write size "
             "%ld MET signals (%ld bytes / MET sig)\n" ,
      (long) awmsig , sizeof ( struct metsignal ) ) ;
  }
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error creating unnamed IPC (pipes)\n" ) ;
  
  
  /*--- Request named IPC , POSIX shared memory ---*/
  
  // UNIX signal flag check and reset meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  // POSIX shared memory
  if  ( e == ME_NONE )
    metshm ( SHMARG , shmnr , shmfn , shmfs , shmfd ) ;
  
  // Close shared memory file descriptors
  metclose ( SHMARG , shmfd ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error creating named IPC (shm)\n" ) ;
  
  
  /*--- Request synchronising IPC , event file descriptors ---*/
  
  // UNIX signal flag check and reset meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  // Readers' event fd's
  if  ( e == ME_NONE )
    meteventfd ( SHMARG , shmnr , EFDNONSEM , refd ) ;
  
  // Writer's event fd's
  for  ( i = 0 ;
         e == ME_NONE  &&  meterr == ME_NONE  &&  i < SHMARG ;
         ++i )
    
    meteventfd ( n , rflg[ i ] , EFDSEM , wefd[ i ] ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error creating event fd's\n" ) ;
  
  
  /*--- Request epoll & register unnamed IPC ---*/
  
  // UNIX signal flag check and reset meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  // epoll & register request pipe reading fd's
  if  ( e == ME_NONE )
    epfd = metepoll ( n , qr ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error creating epoll\n" ) ;
  
  
  /*--- Fork-exec MET child controllers ---*/
  
  // UNIX signal flag check and remember previous meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  // Create MET child controllers
  if  ( e == ME_NONE )
    n = metforx ( n , &cpg , c , br , qw , shmnr , refd , wefd ,
                  argc - SHMARG - 1 , argv + SHMARG + 1 ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error creating MET child controllers\n" ) ;
  
  
  /*--- Close other unused (by metserver) file descriptors ---*/
  
  // UNIX signal flag check and remember previous meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  /* Try closing */
  
  // Broadcast pipe, read
  metclose ( n , br ) ;
  
  // Request pipe, write
  metclose ( n , qw ) ;
  
  // Readers' event file descriptors
  metclose ( SHMARG , refd ) ;
  
  // Writer's event file descriptors , close set-by-set
  for  ( i = 0 ; meterr == ME_NONE  &&  i < SHMARG ; ++i )
    metclose ( n , wefd[ i ] ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error closing unused IPC\n" ) ;
  
  
  /*--- Wait for ready signal ---*/
  
  // UNIX signal flag check and remember previous meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  // Wait
  if  ( e == ME_NONE )
    metiwait ( n , epfd , qr ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error waiting for initial mready\n" ) ;
  
  
  /*--- Unlink named IPC , POSIX shared memory ---*/
  
  // UNIX signal flag check and remember previous meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  // Unlink
  metsmunln ( SHMARG , shmnr , shmfn ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error unlinking shared memory\n" ) ;
  
  
  /*--- Broadcast wait signal ---*/
  
  // UNIX signal flag check and remember previous meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  // Broadcast mwait
  if  ( e == ME_NONE )
  {
    // Get time
    if  ( gettimeofday ( &tv , NULL ) == -1 )
    {
      // Error getting time
      meterr = ME_SYSER ;
      perror ( "metserver:gettimeofday" ) ;
    }
    else
    {
      // Convert timeval to seconds and broadcast
      s.time = tv.tv_sec  +  tv.tv_usec / USPERS ;
      metbroadcast ( n , bw , &s , 1 ) ;
    }
  }
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error broadcasting initial mwait\n" ) ;
  
  
  /*--- Start MET signal server ---*/
  
  // UNIX signal flag check and remember previous meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  // MET signal server
  if  ( e == ME_NONE )
    metsigsrv ( n , bw , qr , epfd , awmsig ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: MET signal server error\n" ) ;
  
  
  /*--- Broadcast quit signal ---*/
  
  // UNIX signal flag check and remember previous meterr
  CHKSIGFLG ( FLGCHLD || FLGINT )
  RESET_METERR
  
  /* Broadcast quit */
  
  // Set signal and cargo
  s.signal = MSIQUIT , s.cargo = e ;
  
  // Get time
  if  ( gettimeofday ( &tv , NULL ) == -1 )
  {
    // Error getting time
    meterr = ME_SYSER ;
    perror ( "metserver:gettimeofday" ) ;
  }
  
  // Convert timeval to seconds
  else
    s.time = tv.tv_sec  +  tv.tv_usec / USPERS ;
  
  // Broadcast
  metbroadcast ( n , bw , &s , 1 ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error broadcasting mquit\n" ) ;
  
  
  /*--- First wait for child processes ---*/
  
  // UNIX SIGINT flag check and remember previous meterr
  CHKSIGFLG ( FLGINT )
  RESET_METERR
  
  // wait
  if  (  0  <  ( i = metwait ( n , n , c , TWAIT1 ) )  )
    w += i ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error 1st wait for child process\n" ) ;
  
  
  /*--- Close remaining unnamed IPC , pipes ---*/
  
  /* The idea here is that any MET child controllers that missed
    the mquit signal might detect a broken pipe and exit
    gracefully */
  
  // UNIX SIGINT flag check and remember previous meterr
  CHKSIGFLG ( FLGINT )
  RESET_METERR
  
  // Broadcast pipe, write
  metclose ( n , bw ) ;
  
  // Request pipe, read
  metclose ( n , qr ) ;
  
  // epoll no longer required to monitor request pipes
  metclose ( 1 , &epfd ) ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: "
        "error closing remaining unnamed IPC (pipes)\n" ) ;
  
  
  /*--- Second wait for child processes ---*/
  
  // UNIX SIGINT flag check and remember previous meterr
  CHKSIGFLG ( FLGINT )
  RESET_METERR
  
  // Wait for child processes that caught broken broadcast pipe
  if  ( w < n )
    if  (  0  <  ( i = metwait ( n - w , n , c , TWAIT1 ) )  )
      w += i ;
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error close-pipe wait for child process\n" ) ;
  
  
  /*--- Kill wait , the last resort ---*/
  
  // UNIX SIGINT flag check and remember previous meterr
  CHKSIGFLG ( FLGINT )
  RESET_METERR
  
  // Un-waited child processes , or error while waiting
  if  ( w < n )
  {
    // Kill child process group
    if  ( killpg ( cpg , SIGKILL )  ==  -1 )
      perror ( "metserver:killpg" ) ;
    
    // Wait for them
    if  (  0  <  ( i = metwait ( n - w , n , c , TWAITK ) )  )
      w += i ;
    
    // Error
    if  ( w < n )
    {
      meterr = ME_INTRN ;
      fprintf ( stderr , "metserver: "
        "wait failed on %d MET child controllers\n" , n - w ) ;
    }
  }
  
  // Report errors
  if  ( meterr != ME_NONE )
      fprintf ( stderr ,
        "metserver: error kill wait for child process\n" ) ;
  
  
  /*--- Restore original terminal attributes ---*/
  
  if  ( tcsetattr ( STDIN_FILENO , TCSADRAIN , &tattr )  ==  -1 )
  {
    perror ( "metserver:tcsetattr" ) ;
    if  ( e == ME_NONE )
      e = ME_SYSER ;
  }
  
  
  /*--- Error detected ---*/
  
  // MET error caught
  switch  ( e )
  {
    case   ME_NONE:  break ;
    case  ME_PBSRC:  FEB ( "metserver: "
                           "MET signal source protocol breach" )
    case  ME_PBSIG:  FEB ( "metserver: "
                           "MET signalling protocol breach" )
    case  ME_PBCRG:  FEB ( "metserver: "
                           "MET signal cargo protocol breach" )
    case  ME_PBTIM:  FEB ( "metserver: "
                           "MET signal time protocol breach" )
    case  ME_SYSER:  FEB ( "metserver: system error" )
    case  ME_BRKBP:  FEB ( "metserver: broken broadcast pipe" )
    case  ME_BRKRP:  FEB ( "metserver: broken request pipe" )
    case  ME_CLGBP:  FEB ( "metserver: clogged broadcast pipe" )
    case  ME_CLGRP:  FEB ( "metserver: clogged request pipe" )
    case   ME_CHLD:  FEB ( "metserver: "
                           "unexpected child controller "
                           "termination" )
    case   ME_INTR:  FEB ( "metserver: "
                           "SIGINT, SIGHUP, or SIGQUIT" )
    case  ME_INTRN:  FEB ( "metserver: MET internal error" )
    case  ME_TMOUT:  FEB ( "metserver: timeout while waiting" )
    case  ME_MATLB:  FEB ( "metserver: Matlab error detected" )
           default:  FEB ( "metserver: unrecognised error" )
  } // errors
  
  
  /*-- Exit process --*/
  
  if  ( e == ME_NONE )
  {
    fprintf ( stdout , "metserver: successful shutdown\n" ) ;
    exit ( EXIT_SUCCESS ) ;
  }
  else
    exit ( EXIT_FAILURE ) ;
  
  
} // metserver


