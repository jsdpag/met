
/*  metpipe.c
  
  int  metpipe ( const int  n , int *  r , int *  w )
  
  Requests n pipes from the kernel. The reading and writing file
  descriptors for the ith pipe are returned in r[ i - 1 ] and
  w[ i - 1 ].
  
  n may not exceed MAXCHLD. All values of r and w must be FDINIT
  when metpipe is called.
  
  Returns the number of pipes made. Returns -1 on error and sets
  meterr to ME_SYSER for system call errors. Or ME_INTRN if any of
  the elements in the file descriptor arrays have been assigned a
  value other than FDINIT, the initialisation value ; or if n is
  bigger than SHMARG.
  
  Note: Uses Linux-specific pipe2 system call
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- Define block ---*/

// Read end of pipe
#define  PIPER  0

// Write end of pipe
#define  PIPEW  1


/*--- metpipe function definition ---*/

int  metpipe ( const int  n , int *  r , int *  w )
{
  
  
  /*-- Variables --*/
  
  // counter
  int  i ;
  
  // file descriptor buffer
  int  fd[ 2 ] ;
  
  // non-blocking and close-on-exec flags
  int  flags = O_NONBLOCK  |  O_CLOEXEC ;
  
  
  /*-- Check input --*/
  
  // n is too big
  if  ( MAXCHLD < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metpipe: n > MAXCHLD i.e %d\n" ,
      MAXCHLD ) ;
  }
  
  // Input arrays
  for  ( i = 0  ;  meterr == ME_NONE  &&  i < n  ;  ++i )
    
    // Check that fd's not already assigned
    if  ( r[ i ] != FDINIT  ||  w[ i ] != FDINIT )
    {
      fprintf ( stderr , "metserver:metpipe: reading or writing"
        " file descriptor %d already assigned\n" , i ) ;
      meterr = ME_INTRN ;
    }
  
  // Quit on error
  if  ( meterr != ME_NONE )
    return  -1 ;
  
  
  /*-- Make pipes --*/
  
  for  ( i = 0 ; i < n ; ++i )
  {
    
    // Check UNIX signal flags
    CHKSIGFLG ( FLGCHLD || FLGINT )
    if  ( meterr != ME_NONE )
      return  -1 ;
    
    // Request pipe from kernel
    if  ( pipe2 ( fd , flags )  ==  -1 )
    {
      // System error
      perror ( "metserver:metpipe:pipe2" ) ;
      meterr = ME_SYSER ;
      return  -1 ;
    }
    
    // Assign reading file descriptor
    r[ i ] = fd[ PIPER ] ;
    
    // Assign writing file descriptor
    w[ i ] = fd[ PIPEW ] ;
    
  } // pipes
  
  
  /*-- Success , return number of pipes --*/
  
  return  i ;
  
  
} // metpipe


