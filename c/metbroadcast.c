
/*  metbroadcast.c
  
  int  metbroadcast ( const unsigned char  n ,
                      const int *  fd ,
                      void *  buf ,
                      const size_t  ns )
  
  Broadcast the ns MET signals stored in buffer buf to n
  MET child controllers through the set of n broadcast pipes 
  with file descriptors in array fd. An attempt will be made
  to write to each pipe, even if there was an error while writing
  to an other.
  
  n must not exceed METCHLD, and no pipe file descriptor can be
  FDINIT.
  
  Returns the number of broadcast pipes that were successfully
  written to. Returns -1 on error and sets meterr to ME_INTRN if
  n or fd breach the limits stated above. Otherwise meterr is set
  to ME_BRKBP if any broadcast pipe is broken, or ME_CLGBP if the
  pipe is non-blocking but would have to block to transfer the
  MET signals i.e. the pipe is clogged.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- metbroadcast function definition ---*/

int  metbroadcast ( const unsigned char  n ,
                    const int *  fd ,
                    void *  buf ,
                    const size_t  ns )
{
  
  
  /*-- Variables --*/
  
  // Pipe counter
  unsigned char  i = 0 ;
  
  // Pointer to buffer
  char *  p = buf ;
  
  // Number of bytes in buffer
  const size_t  NBUF = sizeof ( struct metsignal )  *  ns ;
  
  // Number of bytes to write
  size_t  nw = NBUF ;
  
  // Return value from write
  ssize_t  r ;
  
  
  /*-- Check input --*/
  
  // n is too big
  if  ( MAXCHLD < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr ,
      "metbroadcast: n > MAXCHLD i.e. %d\n" ,
      MAXCHLD ) ;
    return  -1 ;
  }
  
  
  /*-- Broadcast --*/
  
  while  ( i < n )
  {
    
    // Write to broadcast pipe
    r = write ( fd[ i ] , p , nw ) ;
    
    // Error checking
    if  ( r == -1 )
    {
      
      // Signal interruption, try again
      if  ( errno == EINTR )
      {
        // UNIX signal flag check, then continue writing
        CHKSIGFLG ( FLGCHLD || FLGINT )
        continue ;
      }
      
      // Clogged pipe
      else if  ( errno == EAGAIN  ||  errno == EWOULDBLOCK )
      {
        meterr = ME_CLGBP ;
        fprintf ( stderr ,
          "metbroadcast: broadcast pipe %d clogged\n" , i ) ;
      }
      
      // Broken pipe
      else if  ( errno == EPIPE )
      {
        meterr = ME_BRKBP ;
        fprintf ( stderr ,
          "metbroadcast: broadcast pipe %d broken\n" , i ) ;
      }
      
      // Invalid file descriptor set to FDINIT
      else if  ( errno == EBADF  &&  fd[ i ] == FDINIT )
      {
        meterr = ME_INTRN ;
        fprintf ( stderr ,
          "metbroadcast: broadcast pipe %d unitialised\n" , i ) ;
      }
      
      // Other system error
      else
      {
        meterr = ME_SYSER ;
        perror ( "metbroadcast:write" ) ;
      }
      
      /* If we got here then an error occurred that requires
        skipping this pipe. By setting r to nw, nw -= r will
        give nw a value of zero, triggering variable reset and
        pipe counter increment. */
      r = nw ;
      
    } // error check
    
    // Update number of bytes to write, and buffer position
    nw -= r ;
     p += r ;
    
    // All bytes written to this pipe (or error, skip pipe).
    if  ( !nw )
    {
      // Reset writing variables
      nw = NBUF ;
      p = buf ;
      
      // Go to next pipe
      ++i ;
    }
    
  } // broadcast pipes
  
  
  /*-- Return value --*/
  
  return  meterr == ME_NONE  ?  i  :  -1 ;
  
  
} // metbroadcast


