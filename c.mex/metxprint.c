
/*  metxprint.c
  
  met ( 'print' , str , out )
  
  Prints string str to standard output if out is 'o' or standard error if
  out is 'e'. Written to standard output by default if out is omitted. If
  out is 'l' i.e. lower-case letter L then the string is written to only
  the current log file. If out is 'L' i.e. upper-case letter L then the
  string is written to both standard output and the current log file ; but
  if out is 'E' then the string is written to standard error and the log
  file. For options 'L' and 'E', if there is no open log file then
  the message is only printed to the terminal, as if 'o' or 'e' had been
  given ; for 'l', nothing happens. A newline is appended to the end of
  str.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:print: "

#define  NLHS  0
#define  NRHS_MIN  1
#define  NRHS_MAX  2


/*--- metxprint function definition ---*/

void  metxprint ( struct met_t *  RTCONS ,
                  int  nlhs ,       mxArray *  plhs[] ,
                  int  nrhs , const mxArray *  prhs[] )
{
  
  
  /*-- Check input arguments --*/
  
  /* Number of outputs */
  if  ( nlhs  !=  NLHS )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:print:nlhs" , ERRHDR
      "no output arg" , RTCONS->cd ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs  <  NRHS_MIN  ||  NRHS_MAX  <  nrhs )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:print:nrhs" , ERRHDR
      "takes %d to %d input args , %d given" ,
      RTCONS->cd , NRHS_MIN , NRHS_MAX , nrhs ) ;
  }
    
  /* Check that str is a string */
  if  ( CHK_IS_STR( 0 ) )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:print:str" , ERRHDR
      "str is not a horizontal string" , RTCONS->cd ) ;
  }
  
  /* Check that out is a single character */
  if  (  nrhs == 2   &&  (  !mxIsChar ( prhs[ 1 ] )  ||
         mxGetNumberOfElements ( prhs[ 1 ] ) != 1  )  )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:print:out" , ERRHDR
      "out is not a single character" , RTCONS->cd ) ;
  }
  
  
  /*-- Variables --*/
  
  /* Number of characters */
  size_t  nc  =  mxGetNumberOfElements ( prhs[ 0 ] ) + 1 ;
  
  /* mxChar pointer , for getting value of argument 'out' */
  mxChar *  mcp ;
  
  /* char buffers for input arguments */
  char  str[ nc ] , out = 'o' ;
  
  /* Terminal output stream and logfile output stream */
  FILE  * tstrm = NULL , * lfstrm = NULL ;
  
  
  /*-- Determine output stream --*/
  
  /* Get char from argument 'out' */
  if  ( nrhs  ==  2 )
  {
    /* Get pointer */
    if  ( ( mcp = mxGetChars ( prhs[ 1 ] ) )  ==  NULL )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:print:out" , ERRHDR 
      "arg 'out' is not char array" , RTCONS->cd ) ;
    }
    
    /* Convert to char */
    out = (char) (*mcp) ;
  }
  
  /* Choose output stream */
  switch  ( out )
  {
    case  'L':  lfstrm = RTCONS->logfile ;
    case  'o':  tstrm = stdout ;
                break ;
    
    case  'E':  lfstrm = RTCONS->logfile ;
    case  'e':  tstrm = stderr ;
                break ;
                
    case  'l':  lfstrm = RTCONS->logfile ;
                break ;
      
    default:  RTCONS->quit = ME_INTRN ;
              mexErrMsgIdAndTxt ( "MET:print:out" , ERRHDR
      "arg 'out' must be 'o' or 'e' , got '%c'" , RTCONS->cd , out ) ;
  }
  
  
  /*-- Convert argument 'str' to C-style string --*/
  
  if  ( mxGetString ( prhs[ 0 ] , str , nc ) )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:print:convert" , ERRHDR 
      "failed to convert str to string" , RTCONS->cd ) ;
  }
  
  
  /*-- Print to standard terminal stream --*/
  
  if  ( tstrm != NULL  &&  fprintf ( tstrm , "%s\n" , str ) < 0 )
  {
    RTCONS->quit = ME_SYSER ;
    mexErrMsgIdAndTxt ( "MET:print:fprintf" , ERRHDR
      "error printing to terminal" , RTCONS->cd ) ;
  }
  
  
  /*-- Print to log file --*/
  
  if  ( lfstrm != NULL  &&  fprintf ( lfstrm , "%s\n" , str ) < 0 )
  {
    RTCONS->quit = ME_SYSER ;
    mexErrMsgIdAndTxt ( "MET:print:fprintf" , ERRHDR
      "logfile printing error" , RTCONS->cd ) ;
  }
  
  
} /* metxprint */

