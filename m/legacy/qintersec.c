
/*  qintersec.c
    
    qintersec ( a , b ) - Quick and greedy intersection. Returns the first
    value in a that exists in b. 0 is returned when a and b do not
    intersect. Both inputs must be type double Matlab matrices.
    
    NOTE: Relies on the blockdef verification to guarantee that a and b are
    both sorted ascending. That is, qintersec will assume sorted data, and
    will almost certainly fail if that is not the case.
    
    This is a MEX file for MATLAB.
    
    Written by Jackson Smith - Nov 2015 - DPAG, University of Oxford
    
*/


/* Include block */
#include  "mex.h"
#include  "matrix.h"


/* Define block */
#define  ARGA  0
#define  ARGB  1


/*   MAIN FUNCTION   */
void  mexFunction ( int nlhs , mxArray * plhs[] ,
                    int nrhs , const mxArray * prhs[] )
{
  
  
  /*   Variables   */
  
  /* Argument data pointers
  */
  double  r = 0 , * pa , * pb ;
  
  /* Number of elements in input matrices, and for loop counters
  */
  size_t  na , nb ;
  
  
  /*   Check input   */
  
  /* Number of input arguments
  */
  if ( nrhs != 2 )
    mexErrMsgIdAndTxt( "qintersec:input:nrhs" , "Two arguments required") ;
  
  /* All inputs must be Matlab double matrices
  */
  if ( !mxIsDouble( prhs[ ARGA ] ) || !mxIsDouble( prhs[ ARGB ] ) )
    mexErrMsgIdAndTxt( "qintersec:input:rhs" ,
                       "Double matrices required") ;
  
  
  /*   Quick and greedy intersection   */
  
  /* Find the number of elements in each input argument
  */
  na = mxGetNumberOfElements( prhs[ ARGA ] ) ;
  nb = mxGetNumberOfElements( prhs[ ARGB ] ) ;
  
  /* Access pointers to double float data
  */
  pa = mxGetPr( prhs[ ARGA ] ) ;
  pb = mxGetPr( prhs[ ARGB ] ) ;
  
  /* Scan along input arguments for the first value found in both
  */
  while ( na && nb )
  {
    
    /* We found it! Set r and quit loop.
    */
    if ( *pa == *pb )
    {
      r = *pa ;
      break ;
    }
    
    /* Now we rely on the assumption of sorted data. If this
       element of a is less than this element of b, then advance a by one.
    */
    else if ( *pa < *pb )
    {
      pa++ ; na-- ;
    }
    
    /* Otherwise, the current element of b is less than a, so advance that.
    */
    else
    {
      pb++ ; nb-- ;
    }
    
  } /* scan */
  
  
  /*   Return value   */
  
  plhs[ 0 ] = mxCreateDoubleScalar( r ) ;
  
  
} /* qintersec */

