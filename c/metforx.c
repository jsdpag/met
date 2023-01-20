
/*  metforx.c
  
  int  metforx ( const unsigned char  n ,
                 pid_t *  cpg ,
                 pid_t *  c ,
                 const int *  br , const int *  qw ,
                 const unsigned char *  shmnr ,
                 int *  refd , int **  wefd ,
                 const int  argc , char **  argv )
  
  Fork-exec n child processes.
  
  The parent process records the process ID of each child in c,
  then returns the number of child processes that were successfully
  forked ; this is even returned on error, so that any forked
  child processes can be waited on. In addition, a new process
  group is made. Its members are the child processes, and the
  process group ID is returned in cpg. Newly forked processes are
  placed in the new group before calling exec, thus any processes
  forked from the initial group will begin as members. As Matlab
  seems to depend on being in a foreground process group, both
  the parent and child process group leader attempt to place the
  new group into the foreground.
  
  On error, meterr is set to ME_INTRN if n or any element of shmnr
  exceeds MAXCHLD ; if any element in br, qw, refd, or wefd is
  uninitialised ; if *cpg is not 0 i.e. zero ; if any element of c
  is initialised ; if argc is not twice the value of n. meterr
  becomes ME_SYSER for any error during a system call.
  
    2016-07-27 v00.00.26 - refd and wefd can remain FDINIT
    following meteventfd if there are no readers on the shm i.e.
    refd[ i ] or wefd[ i ] == FDINIT if shmnr[ i ] is 0.
    
    2016-08-08 v00.01.15 - wefd now points to an array of arrays.
    First dim spans shared memory objects , second dim spans child
    controllers. Thus wefd[ i ][ j ] refers to writer's event fd
    for child controller with descriptor j+1 that reads the ith
    shared memory.
  
  Each child process is assigned a specific pair of pipe file
  descriptors. Thus the ith child will be associated with broadcast
  pipe reading fd br[ i - 1 ] and request pipe writing fd
  qw[ i - 1 ], for i ranging 1 to n. The ith child's MET controller
  descriptor also becomes i. To keep the pipes open across exec,
  the child first lowers the close-on-exec flag, but only on it's
  assigned pair of pipes.
  
  The number of POSIX shared memory readers will be provided in
  shmnr, along with synchronising event file descriptors for
  readers in refd and writers in wefd. There will be SHMARG
  elements in each of these arrays that are ordered according to
  the type of shared memory as follows:
  
    Symbolic index , Numeric index , Type
          STMARG-1 ,             0 , stimulus variable parameters
          EYEARG-1 ,             1 , eye position
          NSPARG-1 ,             2 , Neural signal processor output
  
  For example: shmnr[1], refd[1], and wefd[1][] provide the number
  of readers, readers' efd, and writer's efds for the eye position
  shared memory.
  
  Because the number of shared memory readers is provided in shmnr,
  the corresponding command-line argument strings can be skipped in
  argc and argv. Thus, argc will be 4 less and argv have 4 fewer
  elements than what is handed to metserver, discounting also the
  name of the executed command. That is, the argv given to metforx
  will only be Matlab and MET controller option strings. Option
  strings will come in pairs, so that the ith child process will
  use argv[2*(i-1)] Matlab options and argv[2*(i-1)+1]
  metcontroller options ; correspondingly, argc must be twice n.
  
  Child processes will determine whether they read or write each
  shared memory according to their MET controller options, and they
  will lower the close-on-exec flag for any event file descriptors
  that they need.
  
  Before calling exec, each child process will duplicate the
  standard output file descriptor, then open /dev/null for writing
  in association with the standard output file descriptor i.e.
  STDOUT_FILENO.
  
  At last, the child process executes Matlab with its given Matlab
  options, and option -r. The latter is followed by a line of
  Matlab code where metcontroller is run, and provided with all
  necessary file descriptors, MET controller function name, and
  MET controller options.
  
  If a child process encounters any error prior to executing
  Matlab then it will attempt to send an mquit MET signal to the
  MET server controller before closing its request pipe writing
  file descriptor and returning failure on exit.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  <alloca.h>
#include  <string.h>

#include  "met.h"
#include  "metsrv.h"


/*--- Define block ---*/

// Error message header
#define  ERMHDR  "metserver:metforx:"


/*--- Macros ---*/

/* For accessing elements from linear arrays fd and coe */

// refd
#define  FDR( i )  i
#define  FDW( i , j )  SHMARG + i * nc + j

// Error handling char buffer overrun when making line of matlab
#define  EBUFOSTR \
  "MET child controller %d matlab code buffer overrun\n"
#define  EBUFOVER  { \
                     fprintf ( stderr , ERMHDR "snprintf: " \
                     EBUFOSTR , cd ) ; \
                     return ; \
                   }


/*--- sbnd function definition ---*/

/* Find option string boundaries. Scans string with p for the
  the first non-space character. From there, scans string with
  q until a space or null byte is found. Returns number of bytes
  between pointers. */
static size_t  sbnd ( char **  p , char **  q )
{
  
  // Find head of string
  while  ( *(*p)  ==  ' ' )  ++(*p) ;
  
  // Find tail of string
  *q = *p ;
  while  ( *(*q)  !=  ' '  &&  *(*q)  !=  '\0' )  ++(*q) ;
    
  // Number of characters
  return  (*q) - (*p) ;
  
} // sbnd


/*--- metcp function definition ---*/

/*
  Executed by each child process. Returns on error. Otherwise,
  calls exec ... and reincarnates as Matlab.
  
  Inputs are:
  
  cd - MET controller descriptor of this specific child process.
  nc - Total number of child controllers.
  br , qw - The broadcast pipe reading and request pipe writing
    file descriptors for this specific child process.
  shmnr - List of readers for each type of POSIX shared memory.
  refd , wefd - Lists the readers' and writer's event fd's for
    synchronising each type of shared memory. wefd can be treated
    as 2D array with dim 1 spanning shm and dim 2 spanning child
    controllers.
  matopt - The Matlab command line options, for this specific
    child process.
  metopt - The MET controller options, for this specific child
    process.
*/
static void  metcp ( metsource_t  cd ,
                     const unsigned char  nc ,
                     int  br , int  qw ,
                     const unsigned char *  shmnr ,
                     int *  refd , int **  wefd ,
                     char *  matopt , char *  metopt )
{
  
  
  /*-- CONSTANTS --*/
  
  /* Controller options */
  
  // Shared memory writer
  const char *  WSHMOP[ SHMARG ] = 
    { "-wstim" , "-weye" , "-wnsp" } ;
  
  // Shared memory reader
  const char *  RSHMOP[ SHMARG ] =
    { "-rstim" , "-reye" , "-rnsp"  } ;
  
  
  /*-- Variables --*/
  
  // Generic counters, and file descriptor/bit flag buffer
  int  i , j , f ;
  
  // Duplicate standard output file descriptor
  int  stodup ;
  
  // Number of characters in MET controller option
  size_t  n ;
  
  /* Number of command line arguments for Matlab. At least 3,
    including command string, -r, and line of Matlab. */
  int  argc = 3 ;
  
  // Char pointers for crawling along option strings, char buffer
  char  * p , * q ;
  
  /* Shared memory character flag 'c' closed , 'r' reading ,
    'w' writing , 'b' both reading and writing */
  char  shmflg[ SHMARG ] ;
  for  ( i = 0 ; i < SHMARG ; ++i )
    shmflg[ i ] = MSMG_CLOSED ;
  
  /* The maximum number of file descriptors to keep on exec. This
    will be number of readers' efds (SHMARG), number of writer's
    efds (SHMARG * nc), and pipe fds (2). */
  int  maxkfd = SHMARG * (nc + 1)  +  2 ;
  
  /* File descriptor array , enough for pipe fd's and event fd's.
    fd[ i ] refers to readers' efd for 0 <= i < SHMARG. For
    writer's efd, it's fd[ SHMARG + i * nc + j ] for same i,
    and 0 <= j < nc ; writer's efd on shared mem i, and child
    j. fd[ SHMARG * (nc + 1)  +  i ] accesses pipe fds for
    0 <= i < 2. Use macros FDR and FDW to compute indeces for
    refd and wefd. */
  int  fd[ maxkfd ] ;
  
  /* Close-on-exec flags. Non-zero for fd's who keep raised
    close-on-exec flag. coe[ i ] refers to file descriptor
    fd[ i ]. Last two elements refer to broadcast and request
    pipes, hence they are set to zero */
  unsigned char  coe[ maxkfd ] ;
  
  
  /*-- Initialise fd and fdf --*/
  
  // fd - readers' and writer's event file descriptors
  for  ( i = 0 ; i < SHMARG ; ++i )
  {
     fd[ FDR( i ) ] = refd[ i ] ;
     
     for  ( j = 0 ; j  <  nc ; ++j )
       fd[ FDW( i , j ) ] = wefd[ i ][ j ] ;
  }
  
  // Broadcast and request pipes
  i = SHMARG * (nc + 1) ;
  fd[ i++ ] = br ;
  fd[ i   ] = qw ;
  
  // Close-on-exec flags, initialise leave open on event fd's ...
  for  ( i = 0 ; i < maxkfd - 2 ; ++i )
    coe[ i ] = 1 ;
  
  // ... but lower them on broadcast and request pipes.
  for  ( ; i < maxkfd ; ++i )
    coe[ i ] = 0 ;
  
  
  /*-- Report which MET child controller is starting --*/
  
  printf ( "  MET ctrl %d (pid %lld , pg %lld) >> %s\n" , cd ,
    (long long int) getpid() , (long long int) getpgid ( 0 ) ,
    metopt ) ;
  
  
  /*-- Count Matlab command line options --*/
  
  // Point to head of Matlab option string
  p = matopt ;
  
  // If there are bytes left in option string
  while  ( *p  !=  '\0' )
  {
    
    // Find head and tail of next option
    if  ( 0 < sbnd ( &p , &q ) )
      
      // Non-empty option, count one more
      ++argc ;
    
    // Advance head pointer
    p = q ;
    
  } // count Matlab options
  
  
  /*-- MET controller options --*/
  
  /* Two goals. Determine which efd's to keep. But also find
    the reading/writing action on each shared mem. */
  
  // Point to head of MET controller option string
  p = metopt ;
  
  // If there are bytes left in the option string
  while  ( *p  !=  '\0' )
  {
    
    // Find head and tail of next option, get number of characters
    n = sbnd ( &p , &q ) ;
    
    // Check reader and writer options
    for  ( i = 0 ; i < SHMARG ; ++i )
    {
      // Read shared memory
      if  ( !strncmp ( RSHMOP[ i ] , p , n ) )
      {
        if  ( shmflg[ i ] == MSMG_CLOSED )
          shmflg[ i ] = MSMG_READ ;
        else
          shmflg[ i ] = MSMG_BOTH ;
        
        // Lower close-on-exec flag for controller's writer's efd
        coe[ FDW( i , cd - 1 ) ] = 0 ;
      }
      
      // Write shared memory
      else if  ( !strncmp ( WSHMOP[ i ] , p , n ) )
      {
        if  ( shmflg[ i ] == MSMG_CLOSED )
          shmflg[ i ] = MSMG_WRITE ;
        else
          shmflg[ i ] = MSMG_BOTH ;
        
        // Lower close-on-exec flag for all writer's efds
        for  ( j = 0 ; j  <  nc ; ++j )
          
          // Don't try to lower flags on non-existent fd
          coe[ FDW( i , j ) ]  =  fd[ FDW( i , j ) ] == FDINIT ;
      }
      
      // Controller function or non-shared memory option
      else
        continue ;
      
      // Lower close-on-exec flags for readers' event fd
      coe[ FDR( i ) ] = 0 ;
      
      // No need to continue search
      break ;
      
    } // options
    
    // Advance head pointer
    p = q ;
    
  } // identify 
  
  
  /*-- Unset event fd's that close-on-exec --*/
  
  for  ( i = 0 ; i < SHMARG ; ++i )
  {
    // Readers' efd
    if  ( coe[ FDR( i ) ] )
      refd[ i ] = FDINIT ;
    
    // Writer's efd
    for  ( j = 0 ; j  <  nc ; ++j )
      if  ( coe[ FDW( i , j ) ] )
        wefd[ i ][ j ] = FDINIT ;
  }
  
  
  /*-- Lower close-on-exec flags --*/
  
  for  ( i = 0 ; i < maxkfd ; ++i )
  {
    
    // Leave raised flag
    if  ( coe[ i ] )  continue ;
    
    // Get current file descriptor flags
    if  ( ( f = fcntl ( fd[ i ] , F_GETFD , 0 ) ) == -1 )
    {
      perror ( ERMHDR "fcntl" ) ;
      return ;
    }
    
    // Lower close-on-exec bit
    f &= ~FD_CLOEXEC ;
    
    // Set new file descriptor flags
    if  ( fcntl ( fd[ i ] , F_SETFD , f ) == -1 )
    {
      perror ( ERMHDR "fcntl" ) ;
      return ;
    }
    
  } // lower flag
  
  
  /*-- Duplicate standard output file descriptor --*/
  
  if  ( ( stodup = dup ( STDOUT_FILENO ) )  ==  -1 )
  {
    perror ( ERMHDR "dup" ) ;
    return ;
  }
  
  
  /*-- Build exec arg vector --*/
  
  // Define argument vector for exec, +1 for NULL pointer
  char *  argv[ argc + 1 ] ;
  
  // Command string
  argv[ 0 ] = MATCOM ;
  
  // NULL pointer
  argv[ argc ] = NULL ;
  
  // Add Matlab option strings
  p = matopt ;
  for  ( i = 1 ; *p  !=  '\0' ; ++i )
  {
    // Find head and tail of next option, get number of characters
    n = sbnd ( &p , &q ) ;
    
    // Allocate memory
    argv[ i ] = alloca ( sizeof ( char ) * (n + 1) ) ;
    
    // Copy string
    memcpy ( argv[ i ] , p , n ) ;
    
    // Null byte
    argv[ i ][ n ] = '\0' ;
    
    // Advance to next option
    p = q ;
  }
  
  // Code execute option
  argv[ i++ ] = MATEXE ;
  
  // Make an empty buffer for the line of Matlab code
  argv[ i ] = alloca ( _POSIX_ARG_MAX ) ;
  
  /* Write line of Matlab code for -r input arg up to the last
    pipe file descriptor. This is the head of the line. */
  if  (  _POSIX_ARG_MAX  <=
       ( n = snprintf ( argv[ i ] , _POSIX_ARG_MAX ,
         MATSTR_HEAD , cd , stodup , br , qw ) )  )
    EBUFOVER
  
  // Add line for each shared memory
  for  ( j = 0 ; j  <  SHMARG ; ++j )
  {
    // Always need the shared memory open flag character
    if  ( _POSIX_ARG_MAX  <=  ( n += snprintf ( argv[ i ] + n ,
          _POSIX_ARG_MAX - n , " , '%c'" , shmflg[ j ] ) ) )
      EBUFOVER
    
    // Shared memory stays closed , so go to next shm
    if ( shmflg[ j ]  ==  MSMG_CLOSED )  continue ;
    
    // Shared mem written in by child controller , add no. readers
    if  ( shmflg[ j ]  !=  MSMG_READ  &&
          _POSIX_ARG_MAX  <=  ( n += snprintf ( argv[ i ] + n ,
          _POSIX_ARG_MAX - n , " , %d" , shmnr[ j ] ) ) )
      EBUFOVER
    
    // Always need readers' efd
    if  ( _POSIX_ARG_MAX  <=  ( n += snprintf ( argv[ i ] + n ,
          _POSIX_ARG_MAX - n , " , %d" , refd[ j ] ) ) )
      EBUFOVER
    
    // Logical value , is child controller a reader only?
    unsigned char  ro  =  shmflg[ j ] == MSMG_READ  ;
    
    /* Add all writer's efd's if child controller writes to shm.
      But only give one writer's efd specific to controller if
      it only reads the shm. */
    for  (  f  =  ( ro ? cd - 1 :  0 )  ;
            f  <  ( ro ? cd     : nc )  ;
            ++f )
      
      if  ( _POSIX_ARG_MAX  <=  ( n += snprintf ( argv[ i ] + n ,
          _POSIX_ARG_MAX - n , " , %d" , wefd[ j ][ f ] ) ) )
        
        EBUFOVER
    
  } // shm
  
  // Error check buffer overrun
  if  ( _POSIX_ARG_MAX  <=  n )  EBUFOVER
  
  // Add MET option strings to metcontroller argument list
  for  ( p = metopt ; *p  !=  '\0' ; p = q )
  {
    
    /* Find head and tail of next option. If option is empty then
      look for next one. */
    if  ( !sbnd ( &p , &q ) )  continue ;
    
    // Remember tail character
    char  tc = *q ;
    
    // Replace with a null byte to frame a string
    *q = '\0' ;
    
    // Add MET option argument
    if  ( _POSIX_ARG_MAX  <=  ( n += snprintf ( argv[ i ] + n ,
          _POSIX_ARG_MAX - n , " , '%s'" , p ) ) )
      EBUFOVER
      
    // Restore tail char
    *q = tc ;
    
  } // MET options
  
  // Write tail of the line of matlab
  if  ( _POSIX_ARG_MAX  <=  ( n += snprintf ( argv[ i ] + n ,
        _POSIX_ARG_MAX - n , MATSTR_TAIL ) ) )
    
    EBUFOVER
  
  
  /*-- Redirect standard output to /dev/null --*/
  
  // Open null device for writing
  while  ( ( f = open ( DEVNULL , O_WRONLY ) )  ==  -1 )
    
    // Signal interruption, try again
    if  ( errno == EINTR )  continue ;
    
    // A real problem
    else
    {
      perror ( ERMHDR "open" ) ;
      return ;
    }
  
  // Duplicate into standard output file descriptor
  while  ( dup2 ( f , STDOUT_FILENO )  ==  -1 )
    
    // Signal interruption
    if  ( errno == EINTR )  continue ;
    
    // Problem
    else
    {
      perror ( ERMHDR "dup2" ) ;
      return ;
    }
  
  // Close temporary file descriptor
  while  ( ( close ( f ) )  ==  -1 )
    
    // Signal interruption, try again
    if  ( errno == EINTR )  continue ;
    
    // A real problem
    else
    {
      perror ( ERMHDR "close" ) ;
      return ;
    }
  
  
  /*-- Reincarnate as Matlab --*/
  
  if  ( execvp ( MATCOM , argv )  ==  -1 )
    
    perror ( ERMHDR "execvp" ) ;
  
  
} // metcp


/*--- metforx function definition ---*/

int  metforx ( const unsigned char  n ,
               pid_t *  cpg ,
               pid_t *  c ,
               const int *  br , const int *  qw ,
               const unsigned char *  shmnr ,
               int *  refd , int **  wefd ,
               const int  argc , char **  argv )
{
  
  
  /*-- Variables --*/
  
  // Counter
  int  i ;
  
  
  /*-- Check input --*/
  
  if  ( MAXCHLD < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , ERMHDR
      " n exceeds MAXCHLD %d\n" , MAXCHLD ) ;
  }
  
  else if  ( argc  !=  2 * n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , ERMHDR
      " argc is not 2 * n i.e. %d\n" , 2 * n ) ;
  }
  
  else if  ( *cpg )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , ERMHDR " cpg points to non-zero value\n" ) ;
  }
  
  // Check arrays
  else
  {
    for  ( i = 0  ;  meterr == ME_NONE  &&  i < n  ;  ++i )
    {
      // On error we will not reach a continue statement ...
      if  ( br[ i ] == FDINIT )
        fprintf ( stderr , ERMHDR
          " br[ %d ] is uninitialised\n" , i ) ;
        
      else if  ( qw[ i ] == FDINIT )
        fprintf ( stderr , ERMHDR
          " qw[ %d ] is uninitialised\n" , i ) ;
      
      else if  ( c[ i ] != MCINIT )
        fprintf ( stderr , ERMHDR
          " c[ %d ] is not MCINIT i.e. %d\n" , i , MCINIT ) ;
        
      else if  ( i < SHMARG )
      {
        if  ( MAXCHLD < shmnr[ i ] )
          fprintf ( stderr , ERMHDR
            " shmnr[ %d ] exceeds MAXCHLD i.e. %d\n" , 
            i , MAXCHLD ) ;
        else
          continue ;
      }
      else
        continue ;
      
      // ... and get here.
      meterr = ME_INTRN ;
    }
  }
  
  // Error, return 0 because no child processes forked, yet.
  if  ( meterr != ME_NONE )
    return  0 ;
  
  
  /*-- Fork child processes --*/
  
  // Report action
  printf ( "Starting %d MET child controllers:\n" , n ) ;
  
  for  ( i = 0  ;  meterr == ME_NONE  &&  i < n  ;  ++i )
  {
    
    // Get child pid
    c[ i ] = fork () ;
    
    // Error
    if  ( c[ i ] == -1 )
    {
      meterr = ME_SYSER ;
      perror ( ERMHDR "fork" ) ;
      break ;
    }
    
    
    /* Child process */
    
    else if  ( !c[ i ] )
    {
      /* Places itself into new process group, or creates it if
        *cpg is zero */
      if  ( setpgid ( 0 , *cpg )  ==  -1 )
        // Error
        perror ( "metforx:child process:setpgid" ) ;
      
      // Process group leader puts group in foreground
      else if  ( !( *cpg )  &&
                 tcsetpgrp ( STDIN_FILENO , getpgrp( ) ) == -1 )
        perror ( "metforx:child process:tcsetpgrp" ) ;
      
      else
        // Setup for and call exec
        metcp ( i + 1 , n , br[ i ] , qw [ i ] , shmnr , refd ,
                wefd , argv[ 2 * i ] , argv[ 2 * i + 1 ] ) ;
      
      /* If we got here then something went terribly wrong. Start
        by tring to send an mquit MET signal. */
      struct metsignal  s = { i + 1 , MSIQUIT , meterr , 0 } ;
      if
      ( write ( qw[ i ] , &s , sizeof (struct metsignal) ) == -1 )
        perror ( "metforx:child process:write" ) ;
      
      /* Although this should happen automatically, try to close
        the request pipe file descriptor as a last-ditch attempt
        to inform the MET server controller that there is a
        problem */
      if  ( close ( qw[ i ] ) == -1 )
        perror ( "metforx:child process:close" ) ;
      
      // Exit with failure code
      exit ( EXIT_FAILURE ) ;
      
    } // child
    
    
    /* Parent process */
    
    // Make first child process a process group leader
    if  ( !( *cpg ) )
    {
      char  eflg = 1 ;
      
      // Make new process group
      if  ( setpgid ( c[ i ] , c[ i ] )  ==  -1 )
        perror ( ERMHDR "setpgid" ) ;
      
      // Put new process group in foreground
      else if  ( tcsetpgrp ( STDIN_FILENO , c[ i ] )  ==  -1 )
        perror ( ERMHDR "tcsetpgrp" ) ;
      
      // Remember child process group id, lower error flag
      else  {  *cpg = c[ i ] ;  --eflg ; }
      
      // Error during system call
      if  ( eflg )  meterr = ME_SYSER ;
    }
    
    // Assign child process to new process group
    else if  ( setpgid ( c[ i ] , *cpg )  ==  -1 )
    {
      meterr = ME_SYSER ;
      perror ( ERMHDR "setpgid" ) ;
    }
    
  } // forking
  
  
  /*-- Return value --*/
  
  return  i ;
  
  
} // metforx


