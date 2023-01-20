
/*  metxflush
  
  met ( 'flush' )
  met ( 'flush' , s )
  
  Forces the standard output stream to write its contents to standard
  output i.e. the terminal window. This allows a series of met 'print'
  commands to be run with either the 'l' or 'L' option without writing to
  standard output each time. Instead, print commands are buffered in the
  standard output stream until the flush command is called, resulting in a
  single write to standard output. This can result in improved performance.
  The stream for any open log file is also flushed. Standard output and the
  logfile streams are both flushed by default. Optional input argument s is
  a single character saying which stream to flush. If it is 'b' then both
  streams are flushed, if 'o' then only standard output is flushed, of if
  'l' (lower-case L) then only the log-file stream is flushed.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:flush: "

#define  NLHS  0
#define  NRHS_MAX  1

#define  BOTH  'b'
#define  SOUT  'o'
#define  SLOG  'l'


/*--- metxflush function definition ---*/

void  metxflush ( struct met_t *  RTCONS ,
                  int  nlhs ,       mxArray *  plhs[] ,
                  int  nrhs , const mxArray *  prhs[] )
{
  
  
  /*-- Variable --*/
  
  /* Flags which streams to flush , both by default */
  char  c = BOTH ;
  
  
  /*-- Check input arguments --*/
  
  /* Number of outputs */
  if  ( nlhs  !=  NLHS )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:flush:nlhs" , ERRHDR
      "no output arg" , RTCONS->cd ) ;
  }
    
  /* Number of inputs */
  if  ( NRHS_MAX  <  nrhs )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:flush:nrhs" , ERRHDR
      "takes %d input args , %d given" ,
      RTCONS->cd , NRHS_MAX , nrhs ) ;
  }
  
  /* Optional input argument s */
  if  ( nrhs  ==  1 )
  {
    
    /* Is a character array */
    if  ( !mxIsChar( prhs[ 0 ] ) )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:flush:s" , ERRHDR
        "s must be a character array" , RTCONS->cd  ) ;
    }  
      
    /* Has a single character */
    else if  ( mxGetNumberOfElements( prhs[ 0 ] )  !=  1 )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:flush:s" , ERRHDR
        "s must hold a single character" , RTCONS->cd  ) ;
    }
   
    /* Get pointer to character */
    mxChar  * p = mxGetChars ( prhs[ 0 ] ) ;
    
    /* Cast to char */
    c = ( char ) p[ 0 ] ;
    
  }
  
  
  /*-- Flush standard output stream --*/
  
  if  (  ( c == BOTH  ||  c == SOUT )  &&  fflush( stdout )  ==  EOF  )
  {
    RTCONS->quit = ME_SYSER ;
    perror ( "met:metxflush:fflush" ) ;
    mexErrMsgIdAndTxt ( "MET:flush:fflush" , ERRHDR
      "error while flushing standard output stream" , RTCONS->cd ) ;
  }
  
  
  /*-- Flush log file stream --*/
  
  /* Point to log file stream */
  FILE  * lfstrm = RTCONS->logfile ;
  
  /* Flush stream */
  if  (  ( c == BOTH  ||  c == SLOG )  &&
          lfstrm != NULL  &&  fflush ( lfstrm ) == EOF  )
  {
    RTCONS->quit = ME_SYSER ;
    perror ( "met:metxflush:fflush" ) ;
    mexErrMsgIdAndTxt ( "MET:flush:fflush" , ERRHDR
      "error while flushing log file stream" , RTCONS->cd ) ;
  }
  
  
} /* metxflush */

