
/*  metshm.c
  
  int  metshm ( const unsigned char     n ,
                const unsigned char *  nr ,
                       const char  **  fn ,
                       const size_t *  fs ,
                                int *  fd )
  
  Requests n POSIX shared memory objects from the kernel. All
  other arguments must point to arrays with n elements. The
  number of MET controllers that read the ith shared memory is
  nr[ i - 1 ] ; if this is 0 i.e. no readers then the shared
  memory is not requested. The file name of the ith shared memory
  is given in fn[ i - 1 ], while each associated file descriptor
  is returned in fd[ i - 1 ]. fs[ i - 1 ] is the number of bytes
  allocated to the ith shared memory.
  
  n cannot be less than 0 or exceed SHMARG. No element of nr can
  exceed MAXCHLD. No element in fs can exceed SSIZE_MAX. No
  file descriptor value can have been assigned to fd.
  
  Because POSIX shared memory is linked to a name on the file 
  system, fn[ i -1 ] must specify a valid file name. In Linux
  (from kernel 2.4), POSIX shared memory has its own dedicated
  file system that is typically mounted to /dev/shm. Therefore,
  shared memory file names must all have the form /<name> i.e.
  /eye.met
  
  Returns the number of POSIX shared memory objects that were
  successfully made and set a size ; this could be fewer than
  the number of linked shared memories if there was an error
  setting size. Returns -1 on error and sets meterr to ME_SYSER
  for errors returned by system calls. Or ME_INTRN is returned
  either if any element of the file descriptor array is not
  initialised to FDINIT, or if any input argument exceeds
  allowable limits.
  
  NOTE: Must compile gcc with the correct order and flags.
    
    gcc  *.c  -o metserver  -lrt
  
  Written by Jackson Smith - DPAG - University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- metshm function definition ---*/

int  metshm ( const unsigned char     n ,
              const unsigned char *  nr ,
                     const char  **  fn ,
                     const size_t *  fs ,
                              int *  fd )
{
  
  
  /*-- Variables --*/
  
  // Counters
  int  i , c ;
  
  // Opening flags
  int  oflag = O_RDWR | O_CREAT | O_EXCL ;
  
  
  /*-- Check input --*/
  
  // n is too big
  if  ( SHMARG < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metshm: n > SHMARG i.e %d\n" ,
      SHMARG ) ;
  }
  
  // Check input arrays
  for  ( i = 0  ;  meterr == ME_NONE  &&  i < n  ;  ++i )
  {
    
    // Number of readers is too big
    if  ( MAXCHLD < nr[ i ] )
      
      fprintf ( stderr , "metserver:metshm: "
        "nr[ %d ] > MAXCHLD i.e %d\n" , i , MAXCHLD ) ;
    
    // Shared memory size is too big
    else if  ( SSIZE_MAX < fs[ i ] )
      
      fprintf ( stderr , "metserver:metshm: "
        "fs[ %d ] > SSIZE_MAX i.e %lld\n" ,
         i , (long long) SSIZE_MAX ) ;
    
    // File descriptor may have been assigned
    else if  ( FDINIT != fd[ i ] )
      
      fprintf ( stderr , "metserver:metshm: "
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
  
  
  /*-- Make POSIX shared memory --*/
  
  for  ( i = c = 0 ; i < n ; ++i )
  {
    
    // Check UNIX signal flags
    CHKSIGFLG ( FLGCHLD || FLGINT )
    if  ( meterr )
      return  -1 ;
    
    // Skip if there are no readers
    if  ( !nr[ i ] )
      continue ;
    
    // Link shared memory on the file system
    fd[ i ] = shm_open ( fn[ i ] , oflag , S_IRWXU ) ;
    
    if ( fd[ i ] == -1 )
    {
      perror ( "metserver:metshm:shm_open" ) ;
      meterr = ME_SYSER ;
      return  -1 ;
    }
    
    // Set size of shared memory
    if ( ftruncate ( fd[ i ] , fs[ i ] ) == -1 )
    {
      perror ( "metserver:metshm:ftruncate" ) ;
      meterr = ME_SYSER ;
      return  -1 ;
    }
    
    // Count one more POSIX shared memory successfully made
    ++c ;
    
    
  } // shared memory objects
  
  
  /*-- Success, return number of shared memory objects --*/
  
  return  c ;
  
  
} // metshm


