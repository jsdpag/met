
/*  firsttrue.c
    
    firsttrue( x ) - Returns the numeric index of the first non-zero
    element. 0 is returned when all elements contain zero or x is an empty
    matrix. x must be a logical matrix.
    
    Why use this instead of 'find'? Because find returns an empty matrix
    when no index is found, instead of 0. This is a disaster when trying to
    assign the output of find to a pre-allocated matrix.
    
    This is a MEX file for MATLAB.
    
    Written by Jackson Smith - Oct 2015 - DPAG, University of Oxford
    
 */


/* Include block */
#include  "mex.h"
#include  "matrix.h"


/*   MAIN FUNCTION   */
void  mexFunction ( int nlhs , mxArray * plhs[] ,
                    int nrhs , const mxArray * prhs[] )
{
  
  
  /*   Variables   */
  
  /*  retval - The return value of firsttrue( x ). Defaults to 0, no index
        found.
  */
  size_t  numel , retval = 0 ;
  
  /*  pml - Pointer to mxLogical
  */
  mxLogical  * pml ;
  
  
  /*   Check input   */
  
  /* Check for errors */
  if (  nrhs != 1  ||  !mxIsLogical( prhs[ 0 ] )  )
    mexErrMsgIdAndTxt( "firsttrue:input:nrhs" ,
                       "One logical matrix required") ;
  
  /* Check input for cases where we should just return 0 immediately */
  else if (  !( numel = mxGetNumberOfElements( prhs[ 0 ] ) )  )
    goto  returnval ;
  
  
  /*   Find first non-zero index   */
  
  /*  First, get pointer to data
  */
  pml = mxGetLogicals( prhs[ 0 ] ) ;
  if ( pml == NULL )
    mexErrMsgIdAndTxt( "firsttrue:input:data" ,
                       "Failed to retrieve mxLogical pointer") ;
  
  /* Check all elements
  */
  while (  retval < numel  &&  !pml[ retval ]  )
    retval++ ;
  
  /*  Adjust from C to Matlab indexing, and check whether we encountered
      any nonzero value. If not, we must reset retval to zero.
  */
  if ( numel < ++retval )
    retval = 0 ;
  
  
  /*   Return index   */
  
  returnval:
  
  plhs[ 0 ] = mxCreateDoubleScalar( (double) retval ) ;
  
  
} /* firsttrue */

