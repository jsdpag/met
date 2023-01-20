
/*  met.c
  
  [ ... ] = met ( metfun , ... )
  
  Matlab Electrophysiology Toolbox interface function. This allows a
  program written in Matlab to send or receive MET signals, and to read or
  write to POSIX shared memory.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

/* Minimum number of input arguments required */
#define  MINARGS  1


/*--- met supporting function declarations ---

void metxsend  ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxwrite ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxrecv  ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxread  ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxselect( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxprint ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxflush ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxlogopn( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxlogcls( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxopen  ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxclose ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxconst ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
TESTING */


/*--- Supporting function constants ---*/

/* Number of functions i.e. function count */
#define  FCOUNT  12

/* Function names & number of characters in each (excluding null byte) */
const  char *  FNAMES[ FCOUNT ] = { "send" , "write" , "recv" , "read" ,
  "select" , "print" , "flush" , "logopn" , "logcls" , "open" , "close" ,
  "const" } ;
const  unsigned char  FNOCHR[ FCOUNT ] =
  { 4 , 5 , 4 , 4 , 6 , 5 , 5 , 6 , 6 , 4 , 5 , 5 } ;

/* Function pointers */
void ( * METFUN[ FCOUNT ] )
  ( struct met_t  * , int , mxArray  ** , int , const mxArray  ** )  =
  { metxsend , metxwrite , metxrecv , metxread , metxselect , metxprint ,
    metxflush , metxlogopn , metxlogcls , metxopen , metxclose ,
    metxconst } ;


/*--- met function definition ---*/

void  mexFunction ( int  nlhs ,       mxArray *  plhs[] ,
                    int  nrhs , const mxArray *  prhs[] )
{
  
  
  /*-- Run time constants --*/
  
  static struct met_t  RTCONS = STRUCTMET_INIT ;
  
  
  /*-- Check input --*/
  
  /* Number of input arguments */
  if  ( nrhs  <  MINARGS )
  {
    RTCONS.quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:nargin" , MCSTR
      ":met: %d rhs args given , less than %d " ,
      RTCONS.cd , nrhs , MINARGS ) ;
  }
  
  /* First argument is a string */
  else if  ( CHK_IS_STR( 0 ) )
  {
    RTCONS.quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:nargin" , MCSTR
      ":met: arg 1 must be a non-empty, horizontal string" ,
      RTCONS.cd , MINARGS ) ;
  }
  
  
  /*-- Variables --*/
  
  /* Function index */
  unsigned char  i ;
  
  /* MET function name length and buffer */
  size_t  mfl  =  mxGetNumberOfElements ( prhs[ 0 ] ) + 1 ;
  char  metfun[ mfl ] ;
  
  
  /*-- Identify MET function --*/
  
  /* Convert to C-style string */
  if  ( mxGetString ( prhs[ 0 ] , metfun , mfl ) )
  {
    RTCONS.quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:metfun:convert" , MCSTR
      ":met: failed to convert arg 1 to string" , RTCONS.cd ) ;
  }
  
  /* Check each MET function name */
  for  ( i = 0  ;  i < FCOUNT  ;  ++i )
    if ( !strncmp ( metfun , FNAMES[ i ] , FNOCHR[ i ] ) )
      break ;
  
  /* Function not found */
  if  ( i  ==  FCOUNT )
  {
    RTCONS.quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:metfun:identify" , MCSTR
      ":met: unrecognised function %s" , RTCONS.cd , metfun ) ;
  }
  
  
  /*-- Execute MET function --*/
  
  /* Does not pass met function name in prhs[ 0 ] */
  ( *METFUN[ i ] ) ( &RTCONS , nlhs , plhs , nrhs - 1 , prhs + 1 ) ;
  
  
} /* met */

