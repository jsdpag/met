
/*  metpclose.c
  
  int  metclose ( const int  n , int *  f )
  
  Attempts to close each file descriptor in array f, which has n
  elements.
  
  n must not exceed MAXCHLD.
  
  On success, 0 is returned. On error other than EINTR, -1 is
  returned and meterr is set to ME_SYSER.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- metclose function definition ---*/

int  metclose ( const int  n , int *  f )
{
  
  
  /*-- Variables --*/
  
  // Counter variable
  int  i = 0 ;
  
  
  /*-- Check input --*/
  
  // n is too big
  if  ( MAXCHLD < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metclose: n > MAXCHLD i.e %d\n" ,
      MAXCHLD ) ;
  }
  
  
  /*-- Close file descriptors --*/
  
  // If any descriptors remain open
  while  ( i < n )
  {
    
    // Then check for an unassigned file descriptor
    if  ( f[ i ] == FDINIT ) ;
      
      // No action except to jump down to ++i
    
    // Otherwise, attempt to close the descriptor
    else if  ( close ( f[ i ] ) == -1 )
    {
      
      // Error detected other than EINTR. Freak out!
      if  ( errno  !=  EINTR )
      {
        perror ( "metserver:metclose:close" ) ;
        meterr = ME_SYSER ;
        // Don't quit here, in case there are other fd's to close
      }
      
      // Just EINTR, so try again
      else
      {
        // UNIX signal flag check
        CHKSIGFLG ( FLGCHLD || FLGINT )
        continue ;
      }
      
    } // error
    
    // No EINTR error on close, go to next open file descriptor
    ++i ;
    
  } // file descriptors
  
  
  /*-- Return outcome --*/
  
  // 0 - Success, -1 - failure
  return  meterr == ME_NONE ? 0 : -1 ;
  
  
} // metclose


