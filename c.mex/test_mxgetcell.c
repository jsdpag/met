
/* Does mxGetCell return NULL if element has empty array because the 
 cell was generated using a call to cell ( ) */

#include  "mex.h"
#include  "matrix.h"


void  mexFunction ( int  nlhs ,       mxArray *  plhs[] ,
                    int  nrhs , const mxArray *  prhs[] )
{
  
  /* Number of input arguments */
  if  ( nrhs  !=  1 )
    mexErrMsgTxt ( "needs 1 input arg" ) ;
  
  /* Type of input arg */
  if  ( !mxIsCell ( prhs[ 0 ] ) )
    mexErrMsgTxt ( "needs cell array" ) ;
  
  /* Convenience pointer to cell , and element */
  const mxArray * el , * C = prhs[ 0 ] ;
  
  /* Get number of elements */
  size_t  i , n = mxGetNumberOfElements ( C ) ;
  
  /* Try to access elements and print result */
  for  ( i = 0 ; i < n ; ++i )
  {
    el = mxGetCell ( C , i ) ;
    mexPrintf ( "Element %d , %p\n" , i , el ) ;
  }
  
}
