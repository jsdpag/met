
/*  metatomic.c
  
  size_t  metatomic ( int  fd )
  
  Returns the PIPE_BUF value of the pipe file descriptor fd, or
  the system's page size, whichever is smaller.
  
  On error, returns 0 and sets meterr to ME_SYSER.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- metatomic function definition ---*/

size_t  metatomic ( int  fd )
{
  
  
  /*-- Variables --*/
  
  // PIPE_BUF and page size
  long  ppb , pgs ;
  
  
  /*-- Get PIPE_BUF --*/
  
  // fpathconf returns -1 and changes errno, on error.
  errno = 0 ;
  ppb = fpathconf( fd , _PC_PIPE_BUF ) ;
  
  if  ( ppb == -1  &&  errno )
  {
    meterr = ME_SYSER ;
    perror ( "metserver:metatomic:fpathconf" ) ;
    return  0 ;
  }
  
  
  /*-- Get page size --*/
  
  // Again, look for errno change and -1 return value, on error.
  errno = 0 ;
  pgs = sysconf( _SC_PAGESIZE ) ;
  
  if  ( pgs == -1  &&  errno )
  {
    meterr = ME_SYSER ;
    perror ( "metserver:metatomic:sysconf" ) ;
    return  0 ;
  }
  
  
  /*-- Return the smaller value --*/
  
  return  (size_t)  ppb <= pgs ? ppb : pgs ;
  
  
} // metatomic


