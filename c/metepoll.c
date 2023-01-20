
/*  metepoll.c
  
  int  metepoll ( const unsigned char  n , const int *  fd )
  
  Requests the kernel for an epoll object, then registers the set
  of n file descriptors in fd for monitoring. The epoll object is
  initialised to close-on-exec.
  
  N may not exceed MAXCHLD. No value in fd may be less than zero.
  
  Returns a file descriptor for the newly obtained and initialised
  epoll object. Returns -1 on error and sets meterr to ME_INTRN if
  any input value is out of range, or ME_SYSER if an error occurred
  during a system call.
  
  NOTE: epoll is Linux specific
  
  Written by Jackson Smith - DPAG - University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- metepoll function definition ---*/

int  metepoll ( const unsigned char  n , const int *  fd )
{
  
  
  /* Variables */
  
  // epoll file descriptor
  int  epfd = FDINIT ;
  
  // counter
  int  i ;
  
  // epoll event structure
  struct epoll_event  e ;
  e.events = EPEVFL ;
  
  
  /*-- Check input --*/
  
  // n is too big
  if  ( MAXCHLD < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metepoll: n > MAXCHLD i.e %d\n" ,
      MAXCHLD ) ;
  }
  
  // Input arrays
  for  ( i = 0  ;  meterr == ME_NONE  &&  i < n  ;  ++i )
    
    // Check that fd's not already assigned
    if  ( fd[ i ] == FDINIT )
    {
      fprintf ( stderr , "metserver:metepoll: "
        "file descriptor %d not assigned i.e. it is FDINIT %d\n" ,
        i , FDINIT ) ;
      meterr = ME_INTRN ;
    }
  
  // Quit on error
  if  ( meterr != ME_NONE )
    return  -1 ;
  
  
  /*-- Make epoll --*/
  
  if  ( ( epfd = epoll_create1 ( EPOLL_CLOEXEC ) ) == -1 )
  {
    perror ( "metserver:metepoll:epoll_create1" ) ;
    meterr = ME_SYSER ;
    return  -1 ;
  }
  
  
  /*-- Register file descriptors --*/
  
  for  ( i = 0 ; i < n ; ++i )
  {
    
    // Check UNIX signal flags
    CHKSIGFLG ( FLGCHLD || FLGINT )
    if  ( meterr )
      return  -1 ;
    
    // Specify file descriptor
    e.data.fd = fd[ i ] ;
    
    // Register it
    if ( epoll_ctl ( epfd , EPOLL_CTL_ADD , fd[ i ] , &e ) == -1 )
    {
      perror ( "metserver:metepoll:epoll_ctl" ) ;
      meterr = ME_SYSER ;
      return  -1 ;
    }
      
  } // register fd
  
  
  /*-- Return initialised epoll file descriptor --*/
  
  return  epfd ;
  
  
} // metepoll


