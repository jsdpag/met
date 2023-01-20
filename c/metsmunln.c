
/*  metsmunln.c
  
  int  metsmunln ( const unsigned char      n ,
                   const unsigned char *   nr ,
                   const          char **  fn )
  
  Attempts to unlinks n POSIX shared memory objects from the file
  system. The file name of each shared memory is given in fn, while
  the corresponding number of readers is given in nr.
  
  n must not be greater than SHMARG, while no value in nr may
  exceed MAXCHLD.
  
  nr is provided to error check against the file system. If
  0 < nr[ i ] and the POSIX shared memory with name fn[ i ] is 
  found on the file system, then an attempt is made to unlink it.
  If 0 < nr[ i ] but fn[ i ] is not found, then meterr is set to
  ME_INTRN. Alternatively, if fn[ i ] is on the file system but
  nr[ i ] is 0, then an attempt is made to unlink the file, and
  meterr is set to ME_INTRN.
  
  Function returns the number of POSIX shared memory objects that
  were successfully unlinked. Returns -1 on error. If the only
  errors occurr during sytem calls then meterr is set to ME_SYSER.
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- metsmunln function definition ---*/

int  metsmunln ( const unsigned char      n ,
                 const unsigned char *   nr ,
                 const          char **  fn )
{
  
  
  /* Variables */
  
  // Counters
  int  i , c ;
  
  // File path buffer
  char  fp[ PATH_MAX + 1 ] ;
  
  // stat structure
  struct stat  s ;
  
  // stat() return value, for file checking
  int  sr ;
  
  
  /*-- Check input --*/
  
  // n is too big
  if  ( SHMARG < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metsmunln: n > SHMARG i.e %d\n" ,
      SHMARG ) ;
  }
  
  // Check input arrays
  for  ( i = 0  ;  meterr == ME_NONE  &&  i < n  ;  ++i )
  {
    
    // Number of readers is too big
    if  ( MAXCHLD < nr[ i ] )
    {  
      fprintf ( stderr , "metserver:metsmunln: "
        "nr[ %d ] > MAXCHLD i.e %d\n" , i , MAXCHLD ) ;
      meterr = ME_INTRN ;
    }
    
  } // check input arrays
  
  // Quit on error
  if  ( meterr != ME_NONE )
    return  -1 ;
  
  
  /*--- Unlink POSIX shared memory ---*/
  
  for  ( i = c = 0 ; i < n ; ++i )
  {
    
    
    /* shared mem file name at mount point */
    
    // Initialise buffer
    fp[ 0 ] = '\0' ;
    
    // Fill buffer
    snprintf ( fp , PATH_MAX + 1 , MSHM_MNTP "%s" , fn[ i ] ) ;
    
    
    /* Check existence of shared mem file */
    
    sr = stat ( fp , &s ) ;
    
    
    // File does not exist, sr is -1 rather than 0
    if  ( sr )
      
      // System error other than non-existent file or dir
      if  ( errno != ENOENT )
      {
        meterr = ME_SYSER ;
        fprintf ( stderr , "metserver:metsmunln:stat" ) ;
        continue ;
      }
    
    
    /* Compare number of readers to file existence */
    
    // Readers counted, but file not there
    if  ( nr[ i ]  &&  sr )
    {
      meterr = ME_INTRN ;
      fprintf ( stderr , "metserver:metsmunln: "
        "shm %d has %d readers but %s non-existent\n" ,
        i + 1 , nr[ i ] , fp ) ;
      continue ;
    }
    
    // File exists without any readers
    else if  ( !nr[ i ]  &&  !sr )
    {
      meterr = ME_INTRN ;
      fprintf ( stderr , "metserver:metsmunln: "
        "shm %d %s exists but no readers\n" ,
        i + 1 , fn[ i ] ) ;
    }
    
    // No readers and file does not exist
    else if  ( !nr[ i ]  &&  sr )
      continue ;
    
    
    /* Unlink shared mem */
    
    if ( shm_unlink ( fn[ i ] ) == -1 )
    {
      meterr = ME_SYSER ;
      perror ( "metserver:metsmunln:shm_unlink" ) ;
      continue ;
    }
    
    // Count successful removal
    ++c ;
    
    
  } // shared mem
  
  
  /*--- Return outcome ---*/
  
  return  meterr == ME_NONE ? c : -1 ;
  
  
} // metsmunln


