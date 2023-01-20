
/*  meteventfd.c
  
  int  meteventfd ( const unsigned char      n ,
                    const unsigned char *    r ,
                    const unsigned char    sem ,
                                    int *   fd )
  
  Requests n event file descriptors from the kernel. A file
  descriptor is only requested when the request flag in r is
  non-zero ; thus, each element in r indicates whether each event
  fd should be obtained. New event file descriptors are returned
  in fd. Event fd's are always initialised to close-on-exec and 
  to be non-blocking.
  
  The event fd's will follow semaphore semantics if sem is non-
  zero. If semaphore semantics are enabled, then the event fd
  is initialised to a value of zero. Otherwise, it is initialised
  to the value of the request flag.
  
  n must be no more than SHMARG or MAXCHLD, whichever is larger.
  No element of r may exceed MAXCHLD, as explained next.
  
  This function is intended to return synchronising event fd's for
  use with the POSIX shared memory. Hence, the number of readers
  for each POSIX shared memory object is an appropriate input for
  r ; this is also why it makes sense to skip creating an event fd
  when r[ i ] is 0, because there is no corresponding shared mem
  to synchronise between processes. It is also why r initialises
  the event fd for non-semaphore semantics, because the readers'
  event fd's are being made, and they must be initialised to the
  number of readers for each shared memory. Alternatively,
  semaphore semantics are required for the writer's event fd's,
  which must initialise to 0 until the writer has posted a value.
  
  NOTE: 08/08/2016 update on MET requires a unique writer's efd
  for every reader on every shared memory object. This function
  is useful for obtaining them, but n can no longer be constrained
  to SHMARG, alone.
  
  The number of event fd's that were successfully requested is
  returned. Returns -1 on error and sets meterr to ME_INTRN if
  n exceeds SHMARG, or if any element of the file descriptor array
  fd has already been assigned i.e. it is not FDINIT. meterr is
  set to ME_SYSER for errors that occur during system calls.
  
  NOTE: Event file descriptors are Linux-specific.
  
  Written by Jackson Smith - DPAG - University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- meteventfd function definition ---*/

int  meteventfd ( const unsigned char      n ,
                  const unsigned char *    r ,
                  const unsigned char    sem ,
                                  int *   fd )
{
  
  
  /*-- Variables --*/
  
  // Counters
  int  i , c ;
  
  // Behaviour flags
  int  flags = EFD_CLOEXEC  |  EFD_NONBLOCK ;
  
  // Conditionally add semaphore semantics
  flags = sem  ?  flags | EFD_SEMAPHORE  :  flags ;
  
  
  /*-- Check input --*/
  
  // n is too big
  if  ( ( SHMARG < MAXCHLD ? MAXCHLD : SHMARG )  <  n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:meteventfd: "
      "n > SHMARG i.e %d or MAXCHLD i.e. %d\n" ,
      SHMARG , MAXCHLD ) ;
  }
  
  // Check input arrays
  for  ( i = 0  ;  meterr == ME_NONE  &&  i < n  ;  ++i )
  {
    
    // Request flag value is too big
    if  ( MAXCHLD < r[ i ] )
      
      fprintf ( stderr , "metserver:meteventfd: "
        "r[ %d ] > MAXCHLD i.e %d\n" , i , MAXCHLD ) ;
    
    // File descriptor may have been assigned    
    else if  ( FDINIT != fd[ i ] )
      
      fprintf ( stderr , "metserver:meteventfd: "
        "fd[ %d ] is not FDINIT i.e %d\n" , i , FDINIT ) ;
    
    // No errors detected
    else
      continue ;
    
    // Error detected
    meterr = ME_INTRN ;
    
  } // check input arrays
  
  // Quit on error
  if  ( meterr != ME_NONE )
    return  -1 ;
  
  
  /*-- Make event file descriptors --*/
  
  for  ( i = c = 0 ; i < n ; ++i )
  {
    
    // Check UNIX signal flags
    CHKSIGFLG ( FLGCHLD || FLGINT )
    if  ( meterr )
      return  -1 ;
    
    // Skip if not requesting event fd.
    if  ( !r[ i ] )
      continue ;
    
    // Obtain new event fd
    fd[ i ] = eventfd ( sem ? 0 : r[ i ] , flags ) ;
    
    // System error
    if  ( fd[ i ] == -1 )
    {
      perror ( "metserver:meteventfd:eventfd" ) ;
      meterr = ME_SYSER ;
      return  -1 ;
    }
    
    // Count one more event file descriptor successfully made
    ++c ;
      
  } // event fd's
  
  
  /*-- Success, return number of new event fd's --*/
  
  return  c ;
  
  
} // meteventfd


