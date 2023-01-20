
/*  metwait.c
  
  int  metwait ( const unsigned char  w , const unsigned char  n ,
                 pid_t *  c , const unsigned int  t )
  
  Waits for w child processes with process id's listed in the n
  element array c. As each child process is waited on, the
  corresponding value in c will be set back to MCINIT. The wait
  times out after t seconds ; if t is zero then the wait is
  indefinite.
  
  w and n must not exceed MAXCHLD. w must not exceed n.
  c must contain w values that are not MCINIT.
  
  Returns the number of child processes that were waited
  on. If the function times out after waiting on m, then m is
  returned, but meterr is set to ME_TMOUT. If c does not contain
  the pid of a waited child process then that waiting is still
  counted in the return value, but meterr is set to ME_INTRN and
  further waiting is aborted. Similartly, if a system error is
  detected, then the number of waitings so far is returned, but
  meterr is set to ME_SYSER. Returns -1 and sets meterr to
  ME_INTRN if any input value is out of  range.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- metwait function definition ---*/

int  metwait ( const unsigned char  w , const unsigned char  n ,
               pid_t *  c , const unsigned int  t )
{
  
  
  /*-- Variables --*/
  
  // Counters
  int  i , j ;
  
  // wait() return value
  pid_t  r ;
  
  
  /*-- Check input --*/
  
  // w is out of range
  if  ( MAXCHLD < w )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metwait: "
      "w %d exceeds MAXCHLD %d\n" ,
      w , MAXCHLD ) ;
  }
  
  // n is out of range
  else if  ( MAXCHLD < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metwait: "
      "n %d exceeds MAXCHLD %d\n" ,
      n , MAXCHLD ) ;
  }
  
  // w exceeds n
  else if  ( n < w )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metwait: "
      "w %d exceeds n %d\n" ,
      w , n ) ;
  }
  
  // Quit on error
  if  ( meterr != ME_NONE )
    return  -1 ;
  
  // Count pid_t values that are not MCINIT
  for  ( i = j = 0 ; i < n ; ++i )
    j +=  c[ i ] != MCINIT  ;
  
  // Not enough process id's
  if  ( j != w )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metwait: "
      "%d pid's required, c has %d\n" ,
      w , j ) ;
    return  -1 ;
  }
  
  
  /*-- Wait on child processes --*/
  
  // Set timeout alarm
  alarm ( t ) ;
  
  // Wait loop
  for  ( j = 0  ;  meterr == ME_NONE  &&  j < w  ; )
  {
    
    // Next child process
    r = wait ( NULL ) ;
    
    // Error check
    if  ( r == -1 )
    {
      
      // Signal interruption
      if  ( errno == EINTR )
      {
        
        // Alarm sounded
        if  ( FLGALRM )
        {
          // Reset alarm flag but stop waiting
          FLGALRM = 0 ;
          meterr = ME_TMOUT ;
          break ;
        }
        
        // Some other signal, check UNIX signal flags
        CHKSIGFLG ( FLGINT )
        
        // Restart alarm
        alarm ( t ) ;
        
      }
      
      // System error
      else
      {
        meterr = ME_SYSER ;
        perror ( "metserver:metwait:wait" ) ;
      }
      
      // Breaks on error, waits again on interruption
      continue ;
            
    } // error
    
    // Count another wait on child process
    ++j ;
    
    // Cross out child process pid from list
    for  ( i = 0 ; i < n ; ++i )
      if  ( r == c[ i ] )
      {  
        c[ i ] = MCINIT ;  
        break ;
      }
    
    // Check whether pid was found
    if  ( i == n )
    {
      meterr = ME_INTRN ;
      fprintf ( stderr , "c does not contain %ld\n" , (long) r ) ;
    }
    
  } // child processes
  
  // Cancel any set alarm
  alarm ( 0 ) ;
  
  
  /*-- Return value --*/
  
  return  j ;
  
  
} // metwait


