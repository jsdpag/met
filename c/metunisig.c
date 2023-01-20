
/*  metunisig.c
  
  Sets up UNIX signal handling for the server controller process.
  This needs to block SIGPIPE. SIGCHLD, SIGALRM, and SIGINT need
  to respond by raising special flags that are defined in
  metserver.c and declared in metsrv.h. SIGHUP and SIGQUIT will
  use SIGINT's handler. All flags shall never be lowered once
  raised ; the exception is for SIGALRM, its flag can be reset.
  All signals are registered with no sigaction flags, so that
  system calls do not automatically restart. Instead, system calls
  will typically return -1 with errno EINTR.
  
  Process exits on error. Does not set meterr.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- Internal signal handling function ---*/

static void  sig_action ( int  s , siginfo_t *  si , void *  c )
{
  
  // Respond to signal
  switch  ( s )
  {
    
    // Alarm flag
    case  SIGALRM:
      FLGALRM = 1 ;
      break ;
    
    // Child terminated
    case  SIGCHLD:
      FLGCHLD = 1 ;
      fprintf ( stderr , "SIGCHLD from %lld\n" ,
        (long long int) si->si_pid ) ;
      break ;
    
    /* Top down interruption: User Ctrl-c, Ctrl-\, terminal
     closure, or logout */
    case   SIGHUP:
    case  SIGQUIT:
    case   SIGINT:
      FLGINT = 1 ;
      break ;
    
  } // signals
  
} // sig_action


/*--- Internal signal regsiter function ---*/

static void  sigreg ( int  n , int *  s , struct sigaction * sa )
{
  
  // Counter
  int  i ;
  
  // Register each signal
  for  ( i = 0 ; i < n ; ++i )
  
    if  ( sigaction ( s[ i ] , sa , NULL ) == -1 )
      
      PEX ( "metserver:metunisig:sigaction" )
  
} // sigreg


/*--- External function ---*/

void  metunisig ( void )
{
  
  
  /*--- Variables ---*/
  
  // Catchable signals
  int  ncat = 5 ;
  int  scat[] = { SIGALRM , SIGCHLD , SIGHUP , SIGQUIT , SIGINT } ;
  
  // Blocked signals
  int  nblk = 4 ;
  int  sblk[] = { SIGPIPE , SIGTSTP , SIGTTIN , SIGTTOU } ;
  
  // sigaction structure
  struct sigaction  sa ;
  
  
  /*--- Initialise sigaction structure ---*/
  
  // Block all signals during handling
  if  ( sigfillset ( &( sa.sa_mask ) ) == -1 )
    PEX ( "metserver:metunisig:sigfillset" )
  
  
  /*--- Catchable signals ---*/
  
  // Don't restart system calls, but return -1 and errno EINTR.
  // Use sa_sigaction, not sa_handler
  sa.sa_flags = SA_SIGINFO ;
  
  // Signal handler
  sa.sa_sigaction = sig_action ;
  
  // Register
  sigreg ( ncat , scat , &sa ) ;
  
  
  /*--- Blocked signals ---*/
  
  // Don't restart system calls, but return -1 and errno EINTR.
  // Use sa_handler, not sa_sigaction
  sa.sa_flags = 0 ;
  
  // Signal handler
  sa.sa_handler = SIG_IGN ;
  
  // Register
  sigreg ( nblk , sblk , &sa ) ;
  
  
} // metunisig


