
/*  metxwrite.c
  
  i = met ( 'write' , shm , ... )
  
  Writes a set of Matlab arrays to the POSIX shared memory named by shm.
  All arguments provided after shm are written as a separate array. Returns
  1 if all data is successfully written, or 0 if nothing was written ;
  throws an error, otherwise.
  
  The shm string may be prefixed by one optional character, either '+' or
  '-', to indicate the blocking mode. If '+' is prefixed then 'write'
  blocks on the shared memory until the data can be written. If '-' is
  prefixed then the function immediately returns 0 if data can not be
  written ; this is the default action when no character is prefixed.
  
  Data can be written only when all N readers of the named shared memory
  have posted 1 to the corresponding readers' event fd i.e. when all
  readers have read the current contents of the named shared memory. A
  blocking write fails as an error if the calling controller is also a
  reader of the shared memory.
  
  Only struct, cell, char, logical, and numeric arrays may be written. Take
  heed , nested arrays in a struct or cell must be one of these types. Full
  matrices only, no sparse.
  
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

#define  ERRHDR  MCSTR ":met:write: "

#define  NLHS_MAX  1
#define  NRHS_MIN  2
#define  NRHS_PAR  1

#define  PRHS_SHM  0
#define  PRHS_ARG1 1

#define  WRSUCC  1
#define  WRFAIL  0

#define  NFORBID  3

#define  MAXMXCLASS  mxFUNCTION_CLASS


/*--- Macros ---*/

/* Check size of (w)rite versus amount of (f)ree space , for use by wshm */
#define  SPCCHK( w , f )  if  ( f  <  w ) \
                          { \
                            RTC->quit = ME_INTRN ; \
                            mexErrMsgIdAndTxt ( "MET:write:wshm" , ERRHDR \
                              "shared mem %d overrun" , RTC->cd , si ) ; \
                          }


/*--- Global constants ---*/

/* Size, in bytes, of each type of POSIX shared memory */
const size_t  SHMSIZ[ SHMARG ] = { MSMS_STIM , MSMS_EYE , MSMS_NSP } ;

/* Forbidden mxClassID values , if any such mxArray is passed as an
  argument then an error is thrown */
const mxClassID  FORBIDDEN[ NFORBID ] =
  { mxUNKNOWN_CLASS , mxVOID_CLASS , mxFUNCTION_CLASS } ;


/*--- Global variables ---*/

/* Shared memory index */
signed char  si ;


/*-- wshm function definition --*/

/* Writes Matlab array M to shared memory from address shm. s bytes of free
  space remain in shared mem at function invocation. Returns the number of
  bytes occupied by M. */

size_t  wshm ( struct met_t *  RTC ,
               void *  shm , size_t  s ,
               const mxArray *  M )
{
  
  /*-- Check that input array is not sparse --*/
  
  if  ( mxIsSparse ( M ) )
  {
    RTC->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:write:wshm" , ERRHDR
      "shared mem %d , cannot write sparse array" , RTC->cd , si ) ;
  }
  
  
  /*-- Variables --*/
  
  /* Return value */
  size_t  ret = 0 ;
  
  /* Generic counter and number of things */
  size_t  i , n ;
  
  /* Array header pointers: array type , complexity flag , num dims */
  mxClassID *  cid = shm ;
       char *  cfl = (   char * )  ( cid + 1 ) ;
     mwSize *  dim = ( mwSize * )  ( cfl + 1 ) ;
  
  
  /*-- Write header --*/
  
  /* Format is:
    
       < mxClassID >,< char >,< mwSize >,< mwSize 1 >, ... < mwSize D >
    
    where D is the value in the first mwSize.
    
    The meaning of each value is:
    
      < array type >,< complex value flag >,< number of dimensions >,
        < size of dim 1 >, ... < size of dim D >
    
    where D is number of dimensions */
  
  /* Compute the number of bytes taken by array type and number of dims */
  n = sizeof ( *cid )  +  sizeof ( *cfl )  +  sizeof ( *dim ) ;
  SPCCHK( n , s )
  
  /* Write type , complexity flag , and num dims */
  *cid = mxGetClassID ( M ) ;
  *cfl = mxIsComplex ( M ) ;
  *dim = mxGetNumberOfDimensions ( M ) ;
  
  /* Reduce free space , count bytes written , advance memory pointer */
  s -= n ;
  ret += n ;
  shm = dim + 1 ;
  
  /* Check type of array */
  if  ( MAXMXCLASS  <  *cid )  goto  forbiddencid ;
  
  for  ( i = 0 ; i  <  NFORBID ; ++i )
    if  ( *cid  ==  FORBIDDEN[ i ] )
    {
      forbiddencid:
      
      RTC->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:write:wshm" , ERRHDR
        "shared mem %d , cannot write array of type: %s" ,
        RTC->cd , si , mxGetClassName ( M ) ) ;
    }
  
  /* Number of bytes in dimensions array , dereference preceeds multiply */
  n = *dim  *  sizeof ( *dim ) ;
  SPCCHK( n , s )
  
  /* Write dimensions array */
  memcpy ( shm , mxGetDimensions ( M ) , n ) ;
  
  s -= n ;
  ret += n ;
  shm = dim  +  1  +  *dim ;  /* ndim addr + ndims + num dim values */
  
  
  /*-- Write data --*/
  
  /* Number of elements in input array */
  n = mxGetNumberOfElements ( M ) ;
  
  /* How we write the data depends on the type of data */
  if  ( *cid  ==  mxSTRUCT_CLASS )
  {
    /* This is a struct array. The format is:
      
      < int >,< char string 1 >, ... < char string F >,< mxArray 1 , 1 >,
        < mxArray 1 , 2 > , ... < mxArray 1 , F >,< mxArray 2 , 1 >, ...
        < mxArray N , F >
      
      where N is the number of elements in the struct , and F is the number
      of fields. F is the value of the first int. In words, the format is:
      
      < number of fields >,< field name 1 >, ... < field name F >,
        < array in element 1 , field 1 > , < array in el 1 , field 2 >,
        ... < array in el 1 , field F >,< array in el 2 , field 1 >, ...
        < array in el N , field F >
      
      Field names are null terminated, i.e. with '\0'. Field contents are
      written out in this order:
      
        for  i = 1 : number of elements
          for  j = 1 : numer of fields
            write array at element i and field j
    */
    
    
    /*   Struct specific variables   */
    
    /* Number of fields , field name pointer , another counter and size of
      things , and another pointer to Matlab array */
    int *  f = shm ;
    const char *  fn ;
    size_t  j , m ;
    const mxArray *  N ;
    
    
    /*   Write field names   */
    
    /* Check that there is room to write number of fields ... */
    m = sizeof ( *f ) ;
    SPCCHK( m , s )
    
    /* ... and write it */
    *f = mxGetNumberOfFields ( M ) ;
    
    s -= m ;
    ret += m ;
    shm = f + 1 ;
    
    /* Structs without fieldnames are possible , return if no fields */
    if  ( !(*f) )  goto  finished ;
    
    /* Loop field names */
    for  ( i = 0 ; i  <  *f ; ++i )
    {
      /* Get next field name */
      fn = mxGetFieldNameByNumber ( M , i ) ;
      
      /* Length of string , including terminating null byte */
      m = strlen ( fn )  +  1 ;
      SPCCHK( m , s )
      
      /* Write string */
      memcpy ( shm , fn , m ) ;
      
      /* Adjust counters */
      s -= m ;
      ret += m ;
      shm = ( char * )  shm  +  m ;
      
    } /* field names */
    
    
    /*   Write values   */
    
    /* Step through all elements */
    for  ( i = 0 ; i  <  n ; ++i )
      
      /* At each element , step through all fields */
      for  ( j = 0 ; j  <  *f ; ++j )
      {
        /* Get the array at this element and field */
        if  ( ( N = mxGetFieldByNumber ( M , i , j ) )  ==  NULL )
        {
          RTC->quit = ME_MATLB ;
          mexErrMsgIdAndTxt ( "MET:write:wshm" , ERRHDR
            "cannot access struct array value , shared mem %d " ,
            RTC->cd , si ) ;
        }
        
        /* Write array to shared memory , and get its size */
        m = wshm ( RTC , shm , s , N ) ;
        
        /* Count bytes written and space used , advance memory pointer */
        ret += m ;
        s -= m ;
        shm = ( char * )  shm  +  m ;
        
      } /* write arrays */
    
    
  }
  else if  ( *cid  ==  mxCELL_CLASS )
  {
    /*** This is a cell array ***/
    
    /* The format is straight forward. Step through linear indeces from 0
      to n - 1 and write value of each cell array element in sequence. */
    
    /* Variables - Another size of things , and Matlab array pointer */
    size_t  m ;
    mxArray *  N ;
    
    /* Step through cell array elements */
    for  ( i = 0 ; i  <  n ; ++i )
    {
      /* Get next element */
      if  ( ( N = mxGetCell ( M , i ) )  ==  NULL )
      {
        RTC->quit = ME_MATLB ;
        mexErrMsgIdAndTxt ( "MET:write:wshm" , ERRHDR
          "cannot access cell array value , shared mem %d " ,
          RTC->cd , si ) ;
      }
      
      /* Write array to shared memory , and get its size */
      m = wshm ( RTC , shm , s , N ) ;
      
      /* Count bytes written and space used , advance memory pointer */
      ret += m ;
      s -= m ;
      shm = ( char * )  shm  +  m ;
      
    } /* cell array */
    
  }
  else
  {
    /*** Numeric, char, and logical arrays ***/
    
    /* Format is < real value bytes >,< complex value bytes > */
    
    
    /*   Variables   */
    
    /* Data access function pointer array, and data pointer */
    void *  (*f[ 2 ]) ( const mxArray * ) = { mxGetData , mxGetImagData } ;
    void *  d ;
    
    /* This is an empty array , nothing to write , hop to escape point */
    if  ( !n )  goto finished ;
    
    /* Convert number of elements to number of bytes in a data block */
    else if  ( !( n = n  *  mxGetElementSize ( M ) ) )
    {
      RTC->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:write:wshm" , ERRHDR
        "cannot access element size, shared mem %d " , RTC->cd , si ) ;
    }
    
    
    /*   Write blocks of data   */
    
    /* Step through real then complex valued data */
    for  ( i = 0 ; i  <  1 + *cfl ; ++i )
    {
      
      /* Get data pointer */
      if  ( ( d = f[ i ] ( M ) )  ==  NULL )
      {
        RTC->quit = ME_MATLB ;
        mexErrMsgIdAndTxt ( "MET:write:wshm" , ERRHDR
          "shared mem %d , failed to access %s values" , RTC->cd , si ,
          i ? "imaginary" : "real" ) ;
      }
      
      /* Copy data - destination is shared mem , source is array */
      SPCCHK( n , s )
      memcpy( shm , d , n ) ;
      
      /* Count bytes written and space used , advance memory pointer */
      ret += n ;
      s -= n ;
      shm = ( char * )  shm  +  n ;
      
    } /* data blocks */
    
  } /* write to shared memory */
  
  /* Escape point from writing */
  finished:
  
  
  /*-- Return number of bytes written --*/
  
  return  ret ;
  
  
} /* wshm */


/*--- metxwrite function definition ---*/

void  metxwrite ( struct met_t *  RTCONS ,
                  int  nlhs ,       mxArray *  plhs[] ,
                  int  nrhs , const mxArray *  prhs[] )
{
  
  
  /*-- Check input arguments --*/
  
  /* Number of outputs */
  if  ( nlhs  >  NLHS_MAX )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:write:nlhs" , ERRHDR
      "max %d output args , %d requested" ,
      RTCONS->cd , NLHS_MAX , nlhs ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs < NRHS_MIN )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:write:nrhs" , ERRHDR
      "min %d input args , %d given" , RTCONS->cd , NRHS_MIN , nrhs ) ;
  }
  
  /* Arg shm must be string */
  if  (  CHK_IS_STR( PRHS_SHM )  )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:write:shm" , ERRHDR
      "arg shm must be non-empty string" , RTCONS->cd ) ;
  }
  
  
  /*-- Variables --*/
  
  /* Shared memory blocking mode */
  char  bm ;
  
  /* Double pointer of return array's data */
  double *  dpret ;
  
  /* Event fd read buffer */
  uint64_t  efdval ;
  
  /* Byte-resolution pointer for mapped POSIX shared memory */
  char *  shm ;
  
  /* Bytes remaining in shared memory */
  size_t  s ;
  
  /* Writes shared mem header , being two consecutive size_t values ,
    < # of bytes >,< # of Matlab arrays > */
  size_t  * hdr ;
  
  /* Return value from writer function wshm */
  size_t  ret ;
  
  /* mxArray counter */
  size_t  i ;
  
  
  /*-- Get POSIX shared memory index and blocking mode --*/
  
  if  ( ( si = metxshmblk ( prhs[ PRHS_SHM ] , &bm ) )  ==  -1 )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:write:shm" , ERRHDR
      "arg shm unrecognised" , RTCONS->cd ) ;
  }
  
  
  /*-- Error check --*/
  
  /* No write access on this shared memory */
  if  (  RTCONS->shmflg[ si ]  !=  MSMG_WRITE  &&
         RTCONS->shmflg[ si ]  !=  MSMG_BOTH   )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:write:shm" , ERRHDR
      "no write access to shared mem %d" , RTCONS->cd , si + 1 ) ;
  }
  
  /* Reading and writing to same shared memory , but blocking requested */
  else if  ( RTCONS->shmflg[ si ]  ==  MSMG_BOTH  &&  bm  ==  SCHBLOCK )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:write:shm" , ERRHDR
      "reads shared mem %d , blocking write not allowed" , RTCONS->cd ,
      si + 1 ) ;
  }
  
  
  /*-- Initialise output argument --*/
  
  if  ( ( plhs[ 0 ] = mxCreateDoubleScalar ( WRFAIL ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:write:plhs" , ERRHDR
      "not enough heap memory to make output arg i" , RTCONS->cd ) ;
  }
  
  
  /*-- Perform blocking write , so change event fd blocking mode --*/
  
  if  ( bm  ==  SCHBLOCK )
    
    /* Set readers' efd to blocking , so writer can wait for readers */
    metxsetfl ( RTCONS , 1 ,
                RTCONS->refd + si , RTCONS->rflg + si , 'b' ,
              "shm write error switch to blocking on readers' event fd" ) ;
  
  
  /*-- Check that all readers have read current shm contents --*/
  
  /* Reading loop. Necessary for blocking reads & UNIX sig interruption. */
  while  (  RTCONS->rcount[ si ]  <  RTCONS->shmnr[ si ]  &&
           ( efdval = metxefdread ( RTCONS , RTCONS->refd[ si ] ) )  )
    
    /* Count more readers. */
    RTCONS->rcount[ si ]  +=  efdval ;
  
  /* Not enough readers reported ready, yet. Return 0 */
  if  ( RTCONS->rcount[ si ]  <  RTCONS->shmnr[ si ] )  return ;
  
  /* Error check reader count */
  else if  ( RTCONS->shmnr[ si ]  <  RTCONS->rcount[ si ] )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:write:readrefd" , ERRHDR
      "%d readers for shm %d but %llu report ready" ,
      RTCONS->cd , RTCONS->shmnr[ si ] , si ,
      (unsigned long long) RTCONS->rcount[ si ] ) ;
  }
  
  
  /*-- Write to POSIX shared memory --*/
  
  /* Point to the first size_t value of the header */
  hdr = RTCONS->shmmap[ si ] ;
  
  /* Initialise header , zero number of bytes , number of Matlab arrays */
  hdr[ SMST_NMXAR ] = nrhs - NRHS_PAR ;
  
  /* Set byte pointer shm to first byte past the size_t header */
  shm = ( char * )  RTCONS->shmmap[ si ]  +  SMST_NUM * sizeof ( ret ) ;
  
  /* Bytes remaining in shared memory */
  s = SHMSIZ[ si ]  -  SMST_NUM * sizeof ( ret ) ;
  
  /* Write each input argument past 'shm' to shared memory */
  for  ( i = PRHS_ARG1 ; i  <  nrhs ; ++i )
  {
    /* Place next Matlab array */
    ret = wshm ( RTCONS , shm , s , prhs[ i ] ) ;
    
    /* Reduce free bytes , advance pointer */
    s -= ret ;
    shm += ret ;
    
  } /* write shm */
  
  /* Number of bytes written to shared mem */
  hdr[ SMST_BYTES ] = SHMSIZ[ si ]  -  s ;
  
  
  /*-- Post to all writer's efd --*/
  
  if  (  metxefdpost ( RTCONS , RTCONS->wefdn[ si ] ,
                       RTCONS->wefdv[ si ] , WEFD_POST )  )
    
    mexErrMsgIdAndTxt ( "MET:write:post" , ERRHDR
      "failed to post to writer's event fd" , RTCONS->cd ) ;
  
  
  /*-- Reset reader counter for next call to metxwrite --*/
  
  RTCONS->rcount[ si ] = 0 ;
  
  
  /*-- Restore non-blocking writes --*/
  
  if  ( !( RTCONS->rflg[ si ]  &  O_NONBLOCK ) )
  
    /* Set readers' efd to non-blocking */
    metxsetfl ( RTCONS , 1 ,
                RTCONS->refd + si , RTCONS->rflg + si , 'n' ,
          "shm write error switch to non-blocking on readers' event fd" ) ;
  
  
  /*-- Return success value --*/
  
  /* Get pointer to return array's data */
  if  ( ( dpret = mxGetPr ( plhs[ 0 ] ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:write:plhs" , ERRHDR
      "no real value data in output arg i" , RTCONS->cd ) ;
  }
  
  /* Update value */
  *dpret = WRSUCC ;
  
  
}  /* metxwrite */

