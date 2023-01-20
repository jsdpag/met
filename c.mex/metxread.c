
/*  metxread.c
  
  C = met ( 'read' , shm )
  
  Reads Matlab arrays from the POSIX shared memory named by shm into cell
  array C. If the shared memory contains N arrays, then C will have N
  elements each contain one array, in the order that they were written.
  Returns an empty cell array if nothing was read.
  
  The shm string may be prefixed by one optional character, either '+' or
  '-', to indicate the blocking mode. If '+' is prefixed then 'read'
  blocks on the shared memory until data has been written. If '-' is
  prefixed then the function immediately returns {} if there is no new
  data ; this is the default action when no character is prefixed.
  
  A blocking read fails as an error if the calling controller is also a
  writer to the shared memory.
  
  For versions 00.XX.XX and 01.XX.XX of MET, valid strings for shm are:
  
    'stim' - Stimulus variable parameter shared memory.
     'eye' - Eye position shared memory.
     'nsp' - Neural signal processor shared memory.
    
    e.g. blocking write to eye shm done by passing '+eye' and non-blocking
    writes done by passing '-eye' or simply 'eye'.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:read: "

#define  NLHS_MAX  1
#define  NRHS      1

#define  PRHS_SHM  0


/*--- Macros ---*/

/* For use by rshm */
#define  CHKNUL( M )  if  ( M  ==  NULL ) \
                      { \
                        RTC->quit = ME_MATLB ; \
                        mexErrMsgIdAndTxt ( "MET:read:rshm" , ERRHDR \
                          "not enough heap space to read " \
                          "from shared mem %d" , RTC->cd , si ) ; \
                      }


/*-- Global variables --*/
  
/* Shared memory index and blocking mode */
signed char  si ;


/*--- rshm function definition ---*/

/* Reads the next Matlab array data into a new mxArray pointed to by M ,
  starting at address shm. Returns the number of bytes read. */

size_t  rshm ( struct met_t *  RTC , void *  shm , mxArray **  M )
{
  
  /*-- Variables --*/
  
  /* Return value */
  size_t  ret = 0 ;
  
  /* Generic counter and number of things */
  size_t  i , n ;
  
  /* Array header pointers: array type , complexity flag , num dims */
  mxClassID *  cid = shm ;
       char *  cfl = (   char * )  ( cid + 1 ) ;
     mwSize *  dim = ( mwSize * )  ( cfl + 1 ) ;
  
  /* Count bytes read */
  ret += sizeof( *cid ) + sizeof( *cfl ) + ( *dim + 1 ) * sizeof( *dim ) ;
  
  /* Advance shared mem pointer */
  shm = dim  +  1  +  *dim ;
  
  
  /*-- Read data --*/
  
  /* Read format is type specific , so is Matlab array creation */
  if  ( *cid  ==  mxSTRUCT_CLASS )
  {
    /*** This is a struct array ***/
    
    /* Struct specific variables. Number of fields , field name pointer ,
       field name array , another counter and size of things , and another
       pointer to Matlab array. */
    int *  f = shm ;
    const char **   fp = NULL ;
    char  * fn[ *f ] ;
    size_t  j , m ;
    mxArray *  N ;
    
    
    /*   Field names   */
    
    /* Read number of fields */
    ret += sizeof ( *f ) ;
    
    /* Get field names if they exist */
    if  ( *f )
    {
      /* Dynamic 'fieldnames' argument for mxCreateStructArray. Stays NULL
        if no fields. Points to name array if fields exist. */
      fp = ( const char ** )  fn ;
      
      /* Find start of first field name */
      fn[ 0 ] = shm = f + 1 ;
      
      /* Point remaining field names into array fn */
      for  ( i = 1 ; i  <  *f ; ++i )
        
        /* The next string starts at the end of the last one , plus 1 for
          null byte */
        fn[ i ] = fn[ i - 1 ]  +  strlen ( fn[ i - 1 ] )  +  1 ;
      
      /* Find the first byte past the last field name (+ null byte). This
        also advances the memory pointer. */
      shm = fn[ i - 1 ]  +  strlen ( fn[ i - 1 ] )  +  1 ;
      
      /* Bytes of field names read */
      ret += ( char * )  shm  -  fn[ 0 ] ;
      
    }  /* get field names */
    
    
    /*   Create struct array   */
    
    *M = mxCreateStructArray ( *dim , dim + 1 , *f , fp ) ;
    CHKNUL( *M )
    
    /* Number of elements in output array */
    n = mxGetNumberOfElements ( *M ) ;
    
    
    /*   Read Matlab arrays into new struct array  */
    
    /* Step through elements */
    for  ( i = 0 ; i  <  n ; ++i )
      
      /* At each element , step through all fields */
      for  ( j = 0 ; j  <  *f ; ++j )
      {
        /* Read next array */
        m = rshm ( RTC , shm , &N ) ;
        
        /* Place into struct array */
        mxSetFieldByNumber ( *M , i , j , N ) ;
        
        /* Count bytes read , and advance memory pointer */
        ret += m ;
        shm = ( char * )  shm  +  m ;
        
      } /* read mat arrays into struct */
    
  }
  else if  ( *cid  ==  mxCELL_CLASS )
  {
    /*** Cell array ***/
    
    /* Variables - Another size of things , and Matlab array pointer */
    size_t  m ;
    mxArray *  N ;
    
    
    /*   Create cell array   */
    *M = mxCreateCellArray ( *dim , dim + 1 ) ;
    CHKNUL( *M )
    
    /* Number of elements in output array */
    n = mxGetNumberOfElements ( *M ) ;
    
    
    /* Step through cell array elements */
    for  ( i = 0 ; i  <  n ; ++i )
    {
      /* Read next array */
      m = rshm ( RTC , shm , &N ) ;
      
      /* Place into new cell array */
      mxSetCell( *M , i , N ) ;
      
      /* Count bytes read and advance memory pointer */
      ret += m ;
      shm = ( char * )  shm  +  m ;
      
    } /* read mat arrays into cell */
    
  }
  else
  {
    /*** Numeric, char, and logical arrays ***/
    
    /* A finer point. Since mxCreateNumericArray is used with non-zero
      dimensions (when data exists), the resulting Matlab array already has
      memory allocated for its real and imaginary values. Thus, no call to
      mxMalloc is required. Instead, memcpy is used to flash values
      straight from shared memory into the newly made array. */
    
    
    /*   Variables   */
    
    /* Data access function pointer array, and data pointer */
    void *  (*f[ 2 ]) ( const mxArray * ) = { mxGetData , mxGetImagData } ;
    void *  d ;
    
    /* Determine complexity flag value */
    mxComplexity  cflarg = *cfl  ?  mxCOMPLEX  :  mxREAL  ;
    
    
    /*   Create matrix   */
    
    *M = mxCreateNumericArray ( *dim , dim + 1 , *cid , cflarg ) ;
    CHKNUL( *M )
    
    /* Number of elements in array , if empty then hop to escape point */
    if  (  !( n = mxGetNumberOfElements ( *M ) )  )
      goto finished ;
    
    /* Number of bytes in a block of data */
    n = n  *  mxGetElementSize ( *M ) ;
    
    if  ( !n )
    {
      RTC->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:read:rshm" , ERRHDR
        "shared mem %d , failed to access number of bytes" ,
        RTC->cd , si ) ;
    }
    
    
    /*   Read blocks of data into matrix   */
    
    /* Step through real then complex valued data */
    for  ( i = 0 ; i  <  1 + *cfl ; ++i )
    {
      
      /* Get data pointer */
      if  ( ( d = f[ i ] ( *M ) )  ==  NULL )
      {
        RTC->quit = ME_MATLB ;
        mexErrMsgIdAndTxt ( "MET:read:rshm" , ERRHDR
          "shared mem %d , failed to access %s values" , RTC->cd , si ,
          i ? "imaginary" : "real" ) ;
      }
      
      /* Copy data - destination is array , source is shared mem */
      memcpy( d , shm , n ) ;
      
      /* Count bytes read , advance memory pointer */
      ret += n ;
      shm = ( char * )  shm  +  n ;
      
    } /* data blocks */
    
  } /* Read data from shared memory */
  
  /* Escape point from reading */
  finished:
  
  
  /*-- Return number of bytes written --*/
  
  return  ret ;
  
  
} /* rshm */


/*--- metxread function definition ---*/

void  metxread ( struct met_t *  RTCONS ,
                 int  nlhs ,       mxArray *  plhs[] ,
                 int  nrhs , const mxArray *  prhs[] )
{
  
  /*-- Check input arguments --*/
  
  /* Number of outputs */
  if  ( nlhs  >  NLHS_MAX )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:read:nlhs" , ERRHDR
      "max %d output args , %d requested" ,
      RTCONS->cd , NLHS_MAX , nlhs ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs  !=  NRHS )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:read:nrhs" , ERRHDR
      "%d input arg required , %d given" , RTCONS->cd , NRHS , nrhs ) ;
  }
  
  /* Arg shm must be string */
  if  (  CHK_IS_STR( PRHS_SHM )  )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:read:nrhs" , ERRHDR
      "args must be non-empty string" , RTCONS->cd ) ;
  }
  
  
  /*-- Variables --*/
  
  /* Shared memory blocking mode */
  char  bm ;
  
  /* Double pointer to Return array's data */
  double *  d ;
  
  /* Event fd read/write buffer */
  uint64_t  efdval ;
  
  /* Byte-resolution pointer for mapped POSIX shared memory */
  char *  shm ;
  
  /* Reads shared mem header , being two consecutive size_t values ,
    < # of bytes >,< # of Matlab arrays > */
  size_t  * hdr ;
  
  /* mxArray counter */
  size_t  i ;
  
  /* mxArray return value from rshm */
  mxArray *  M ;
  
  
  /*-- Get POSIX shared memory name and blocking mode --*/
  
  if  ( ( si = metxshmblk ( prhs[ PRHS_SHM ] , &bm ) )  ==  -1 )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:read:shm" , ERRHDR
      "arg shm unrecognised" , RTCONS->cd ) ;
  }
  
  
  /*-- Error check --*/
  
  /* No read access on this shared memory */
  if  (  RTCONS->shmflg[ si ]  !=  MSMG_READ  &&
         RTCONS->shmflg[ si ]  !=  MSMG_BOTH   )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:read:shm" , ERRHDR
      "no read access to shared mem %d" , RTCONS->cd , si + 1 ) ;
  }
  
  /* Reading and writing to same shared memory , but blocking requested */
  else if  ( RTCONS->shmflg[ si ]  ==  MSMG_BOTH  &&  bm  ==  SCHBLOCK )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:read:shm" , ERRHDR
      "writes shared mem %d , blocking read not allowed" , RTCONS->cd ,
      si + 1 ) ;
  }
  
  
  /*-- Perform blocking read , so change event fd blocking mode --*/
  
  if  ( bm  ==  SCHBLOCK )
    
    /* This controller's specific writer's event fd set to blocking , so
      that controller can wait for writer */
    metxsetfl ( RTCONS , 1 ,
                RTCONS->wefd + si , RTCONS->wflg + si , 'b' ,
             "shm read error switch to blocking on writer's event fd\n" ) ;
  
  
  /*-- Check if writer has written new shm contents --*/
  
  efdval = metxefdread ( RTCONS , RTCONS->wefd[ si ] ) ;
  
  /* No new data ready in shm */
  if  ( efdval  <  WEFD_POST )
  {
    /* Make empty cell array */
    if  ( ( plhs[ 0 ] = mxCreateCellMatrix ( 0 , 0 ) )  ==  NULL )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:read:plhs" , ERRHDR
        "not enough heap space to make output arg C" , RTCONS->cd ) ;
    }
    
    /* Return {} */
    return ;
  }
  
  /* Error check reader count */
  else if  ( WEFD_POST  <  efdval )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:read:readrefd" , ERRHDR
      "writer's event fd returned %llu , larger than WEFD_POST %d" ,
      RTCONS->cd , (unsigned long long) efdval , WEFD_POST ) ;
  }
  
  
  /*-- Read from POSIX shared memory --*/
  
  /* Point to the first size_t value of the header */
  hdr = RTCONS->shmmap[ si ] ;
  
  /* Set byte pointer shm to first byte past the size_t header */
  shm = ( char * )  RTCONS->shmmap[ si ]  +  SMST_NUM * sizeof ( *hdr ) ;
  
  /* Make output arg C , one element per mxArray stored in shared mem */
  if  ( ( plhs[ 0 ] = mxCreateCellMatrix ( hdr[ SMST_NMXAR ] , 1 ) )  ==
          NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:read:plhs" , ERRHDR
      "not enough heap space to make output arg C" , RTCONS->cd ) ;
  }
  
  /* Read shared mem into output arg C */
  for  ( i = 0 ; i  <  hdr[ SMST_NMXAR ] ; ++ i )
  {
    /* Get next Matlab array and advance shared mem pointer */
    shm += rshm ( RTCONS , shm , &M ) ;
    
    /* Set this array into the output cell array */
    mxSetCell ( plhs[ 0 ] , i , M ) ;
    
  } /* read shm */
  
  /* Check that all the bytes were read */
  if  ( shm - ( char * )  hdr  !=  hdr[ SMST_BYTES ] )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:read:wrong_bytes" , ERRHDR
      "wrong number of bytes read from shm %d" , RTCONS->cd , si ) ;
  }
  
  
  /*-- Post to readers' event file descriptor --*/
  
  if  ( metxefdpost ( RTCONS , 1 ,  RTCONS->refd + si , REFD_POST ) )
    
    mexErrMsgIdAndTxt ( "MET:read:post" , ERRHDR
      "failed to post to readers' event fd" , RTCONS->cd ) ;
  
  
  /*-- Restore non-blocking reads --*/
  
  if  ( !( RTCONS->wflg[ si ]  &  O_NONBLOCK ) )
    
    /* Set this controller's writer's efd to non-blocking */
    metxsetfl ( RTCONS , 1 ,
                RTCONS->wefd + si , RTCONS->wflg + si , 'n' ,
           "shm read error switch to non-blocking on writer's event fd" ) ;
  
  
}  /* metxread */

