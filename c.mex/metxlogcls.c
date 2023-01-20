
/*  metxlogcls.c
  
  met ( 'logcls' )
  
  Closes the currently open log file. Silently returns if there is no open
  log file.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:print: "

#define  NLHS  0
#define  NRHS  0


/*--- metxlogcls function definition ---*/

void  metxlogcls ( struct met_t *  RTCONS ,
              int  nlhs ,       mxArray *  plhs[] ,
              int  nrhs , const mxArray *  prhs[] )
{
  
  
  /*-- Check input arguments --*/
  
  /* No open file */
  if  ( RTCONS->logfile  ==  NULL )
    return ;
  
  /* Number of outputs */
  if  ( nlhs  !=  NLHS )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:logcls:nlhs" , ERRHDR
      "no output arg" , RTCONS->cd ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs  !=  NRHS )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:logcls:nrhs" , ERRHDR
      "requires %d input arg , %d given" , RTCONS->cd , NRHS , nrhs ) ;
  }
  
  
  /*-- Close open log file --*/
  
  if  ( RTCONS->logfile  !=  NULL  &&
        fclose ( RTCONS->logfile )  ==  EOF )
  {
    RTCONS->quit = ME_SYSER ;
    perror ( "met:logcls:fclose" ) ;
    mexErrMsgIdAndTxt ( "MET:logcls:fclose" , ERRHDR
      "error closing existing log file" , RTCONS->cd ) ;
  }
  
  /* File is closed , signal this by resetting logfile to NULL */
  RTCONS->logfile = NULL ;
  
  
} /* metxlogcls */

