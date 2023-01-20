
/*
  
  chpa ( x )
  s = chpa ( x )
  
  Matlab Electrophysiology Toolbox mex utility function. Check pointer/
  address. Returns char array s containing a string version of the memory
  address where the real-number data for array x is stored. If no return
  argument is requested, then the address is printed to Matlab's command
  terminal.
  
  This can be a handy tool to check things such as the copy-on-write
  behaviour of Matlab.
  
  Written by Jackson Smith - Octobre 2017 - DPAG , University of Oxford
  
*/


/* Include block */
#include  "mex.h"
#include  "matrix.h"


/* Define block */
#define  NCHARS  16


/*-- chpa --*/

void  mexFunction ( int  nlhs ,       mxArray  * plhs[ ] , 
                    int  nrhs , const mxArray  * prhs[ ] )
{
  
  
  /*- Input checking -*/
  
  /* There must be one input argument */
  if  ( nrhs  !=  1 )
    
    mexErrMsgIdAndTxt ( "MET:chpa:nrhs" ,
      "chpa:there must be one input argument" ) ;
  
  /* There can be no more than one output argument */
  if  ( nlhs  >  1 )
    
    mexErrMsgIdAndTxt ( "MET:chpa:nlhs" ,
      "chpa:there can be at most one output argument" ) ;
  
  
  /*- Get memory address -*/
  
  /* void pointer stores address of input array's data */
  void *  p = mxGetData ( prhs[ 0 ] ) ;
  
  
  /*- Convert address to string -*/
  
  /* char buffer */
  char  c[ NCHARS ] ;
  
  /* Conversion */
  if  ( snprintf( c , NCHARS , "%p" , p )  >=  NCHARS )
    
    /* Output truncated */
    mexErrMsgIdAndTxt (  "MET:chpa:snprintf"  ,
      "chpa:string buffer overflow, more than %d chars to store %p"  ,
      NCHARS  ,  p  ) ;
  
  
  /*- Output -*/
  
  /* No return argument requested */
  if  ( !nlhs )
  
    /* Print directly to Matlab's command terminal */
    mexPrintf ( "%s\n" , c ) ;
  
  else
    
    /* Convert string into a Matlab char array */
    plhs[ 0 ] = mxCreateString ( c ) ;
  
  
} /* chpa */

