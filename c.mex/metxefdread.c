
/*  metxefdread.c
  
  uint64_t  metxefdread ( metsource_t  cd , int  efd )
  
  Reads one full uint64_t from the event file descriptor pointed at by efd.
  cd is the controller descriptor of the calling MET controller. Returns
  the value read from efd, or 0 if a non-blocking read was attempted on a
  zero-valued efd.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:metxefdread: "


/*--- metxefdread function definition ---*/

uint64_t  metxefdread ( struct met_t *  RTCONS , int  efd )
{
  
  /*-- Variables --*/
  
  /* read() return value */
  ssize_t  r ;
  
  /* Number of bytes to read from event fd */
  size_t  n = sizeof ( uint64_t ) ;
  
  /* Event fd read buffer */
  uint64_t  b = 0 ;
  
  /* Byte pointer */
  char *  p = ( char * )  &b ;
  
  
  /*-- Read loop --*/
  
  while  (  n  &&  ( r = read ( efd , p , n ) ) )
  {
    
    /* Error check */
    if  ( r  ==  -1 )
    {
      /* UNIX signal interruption , try again */
      if  ( errno  ==  EINTR )  continue ;
      
      /* No value for reading and non-blocking event fd */
      else if  ( errno  ==  EAGAIN  ||  errno  ==  EWOULDBLOCK )
      {
        /* Read a fraction of uint64_t before non-blocking read. errno is
          only EGAIN if efd contains 0 at time of read. If efd has 0 before
          any bytes read, then n is sizeof ( uint64_t ) at this point.
          Otherwise, less than sizeof ( uint64_t ) bytes read and efd has
          0 ; this is a fractional read. */
        if  ( n  <  sizeof ( uint64_t ) )
        {
          RTCONS->quit = ME_INTRN ;
          perror ( "met:metxefdread:read efd" ) ;
          mexErrMsgIdAndTxt ( "MET:metxefdread:read efd" , ERRHDR
            "fractional read from event fd" , RTCONS->cd ) ;
        }
        
        /* No error , break read loop */
        break ;
      }
      
      /* Some other system error */
      RTCONS->quit = ME_SYSER ;
      perror ( "met:metxefdread:read efd" ) ;
      mexErrMsgIdAndTxt ( "MET:metxefdread:read efd" , ERRHDR
        "error reading event fd %d" , RTCONS->cd , efd ) ;
      
    } /* error */
    
    /* Update counters */
    n -= r ;
    p += r ;
    
  }  /* read loop */
  
  
  /*-- Return value --*/
  
  return  b ;
  
  
} /* metxefdread */

