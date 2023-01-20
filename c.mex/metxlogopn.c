
/*  metxlogopn.c
  
  met ( 'logopn' , n )
  
  Creates a new log file with name taken from string n. All subsequent
  calls to met 'print' with out option 'l', 'L', or 'E' will write to this
  file. If a log file is already open when logopn is called then it will be
  closed before the new one is opened. If file n already exists, then it is
  appended to.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:logopn: "

#define  NLHS  0
#define  NRHS  1

#define  FOMODE  "a"


/*--- metxlogopn function definition ---*/

void  metxlogopn ( struct met_t *  RTCONS ,
                   int  nlhs ,       mxArray *  plhs[] ,
                   int  nrhs , const mxArray *  prhs[] )
{
  
  /*-- Compile time variable --*/
  
  size_t  nc ;
  
  
  /*-- Check input arguments --*/
  
  /* Number of outputs */
  if  ( nlhs  !=  NLHS )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:print:nlhs" , ERRHDR
      "no output arg" , RTCONS->cd ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs  !=  NRHS )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:print:nrhs" , ERRHDR
      "requires %d input arg , %d given" , RTCONS->cd , NRHS , nrhs ) ;
  }
  
  /* Check that we've got a string no longer than PATH_MAX */
  nc = mxGetNumberOfElements ( prhs[ 0 ] ) ;
  
  if  (  CHK_IS_STR( 0 )  ||  PATH_MAX  <  nc  )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:print:n" , ERRHDR
      "arg n must be string no longer than %llu" , RTCONS->cd , PATH_MAX );
  }
    
  
  /*-- Convert Matlab array n to char array --*/
  
  /* char buffer */
  char  c[ nc + 1 ] ;
  
  /* prhs[ 0 ] has been checked to be mxChar type, and c is guaranteed to
    be long enough , so no error checking */
  mxGetString ( prhs[ 0 ] , c , nc + 1 ) ;
  
  
  /*-- Close open log file --*/
  
  if  ( RTCONS->logfile  !=  NULL  &&
        fclose ( RTCONS->logfile )  ==  EOF )
  {
    RTCONS->quit = ME_SYSER ;
    perror ( "met:logopn:fclose" ) ;
    mexErrMsgIdAndTxt ( "MET:print:fclose" , ERRHDR
      "error closing existing log file" , RTCONS->cd ) ;
  }
  
  /* File is closed , signal this by resetting logfile to NULL */
  RTCONS->logfile = NULL ;
  
  
  /*-- Open new log file --*/
  
  if  ( ( RTCONS->logfile = fopen ( c , FOMODE ) )  ==  NULL )
  {
    RTCONS->quit = ME_SYSER ;
    perror ( "met:logopn:fopen" ) ;
    mexErrMsgIdAndTxt ( "MET:print:fopen" , ERRHDR
      "error opening log file %s" , RTCONS->cd , c ) ;
  }
  
  
} /* metxlogopn */

