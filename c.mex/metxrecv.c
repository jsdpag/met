
/*  metxrecv.c
  
  [ n , src , sig , crg , tim ] = met ( 'recv' , blk )
  
  Receives MET signals from the MET server controller. The number of
  signals received is returned in n, with a value of 0 up to the MET signal
  atomic read/write limit. For the ith received signal, the source
  controller, signal identifier, cargo, and time are returned in src( i ),
  sig( i ), crg( i ), and tim( i ). By default, all reads are non-blocking.
  A non-blocking read when no MET signals are available will return n with
  a value of zero, and all other output arguments will be empty i.e. [].
  blk is an optional argument ; if non-zero then a blocking read is
  performed , non-blocking if zero.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:send: "

#define  NLHS_MAX  5
#define  NRHS_MAX  1

/* Array index of each output argument , starting from src */
#define  PLHS_SRC  0
#define  PLHS_SIG  1
#define  PLHS_CRG  2
#define  PLHS_TIM  3

/* prhs index of blk */
#define  PRHS_BLK  0


/*--- metxrecv function definition ---*/

void  metxrecv ( struct met_t *  RTCONS ,
                 int  nlhs ,       mxArray *  plhs[] ,
                 int  nrhs , const mxArray *  prhs[] )
{
  
  /*-- Check input arguments --*/
  
  /* Number of outputs */
  if  ( nlhs  >  NLHS_MAX )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:recv:nlhs" , ERRHDR
      "max %d output args , %d requested" ,
      RTCONS->cd , NLHS_MAX , nlhs ) ;
  }
    
  /* Number of inputs */
  if  ( NRHS_MAX  <  nrhs )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:recv:nrhs" , ERRHDR
     "takes max %d input arg , %d given" , RTCONS->cd , NRHS_MAX , nrhs ) ;
  }
  
  /* Input arg blk is scalar double */
  if  (  nrhs  ==  NRHS_MAX  &&
       ( mxGetNumberOfElements ( prhs[ PRHS_BLK ] ) != 1  ||
         !mxIsDouble ( prhs[ PRHS_BLK ] ) )  )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:recv:nrhs" , ERRHDR
      "blk must be a scalar double" , RTCONS->cd ) ;
  }
  
  
  /*-- Variables --*/
  
  /* Generic counter */
  size_t  i ;
  
  /* MET signal receive buffer , and byte pointer to buffer head */
  struct metsignal  s[ RTCONS->awmsig ] ;
  char *  pb = ( char * )  s ;
  
  /* Number of bytes in buffer, number of bytes / signals read , and bytes
    of fractional read */
  size_t  b = sizeof ( s ) , n = 0 , f = 0 ;
  
  /* Return value from read */
  ssize_t  r ;
  
  /* Vector of output argument double arrays */
  double *  argov[ NLHS_MAX - 1 ] ;
  
  
  /*-- Perform blocking read --*/
  
  if  ( nrhs  ==  NRHS_MAX  &&  mxGetScalar ( prhs[ PRHS_BLK ] ) )
    
    metxsetfl ( RTCONS , 1 ,
                RTCONS->p + BCASTR , RTCONS->pf + BCASTR , 'b' ,
                "error switching to blocking read on broadcast pipe" ) ;
  
  
  /*-- Read MET signals --*/
  
  /* If there is space in the buffer and read returns non-zero */
  while ( b  &&  ( r = read ( RTCONS->p[ BCASTR ] , pb , b ) ) )
  {
    
    /* Error check */
    if  ( r  ==  -1 )
    {
      /* UNIX signal interruption , try again */
      if  ( errno  ==  EINTR )  continue ;
      
      /* No data in pipe on a non-blocking read */
      else if  ( errno == EAGAIN   ||  errno == EWOULDBLOCK )
      {
        /* Does this come after a fractional read i.e. was less than a full
          MET signal written and read? */
        if  ( f )
        {
          RTCONS->quit = ME_PBSIG ;
          mexErrMsgIdAndTxt ( "MET:recv:frac" , ERRHDR
            "fractional read from broadcast pipe" , RTCONS->cd ) ;
        }
        
      } /* no data on non-blocking read */
      
      /* Any other error */
      else
      {
        RTCONS->quit = ME_SYSER ;
        perror ( "met:metxrecv:read" ) ;
        mexErrMsgIdAndTxt ( "MET:recv:read" , ERRHDR
          "error reading broadcast pipe" , RTCONS->cd ) ;
      }
      
    } /* error */
    
    /* Bytes read */
    else
    {
      
      /* Adjust counters */
       n += r ;
      pb += r ;
       b -= r ;
      
      /* Check if a fraction of a MET signal was read */
      f  =  n  %  sizeof ( struct metsignal )  ;
      
    } /* bytes */
    
    
    /* Read loop quit condition. 0 or more whole MET signals read. */
    if  ( !f )  break ;
    
    
  } /* read loop */
  
  
  /*-- Restore non-blocking reads --*/
  
  if  ( !( RTCONS->pf[ BCASTR ]  &  O_NONBLOCK ) )
    
    metxsetfl ( RTCONS , 1 ,
                RTCONS->p + BCASTR , RTCONS->pf + BCASTR , 'n' ,
               "error switching to non-blocking read on broadcast pipe" ) ;
  
  
  /*-- Output arguments --*/
  
  /* Number of signals read */
  n  /=  sizeof ( struct metsignal ) ;
  
  if  ( ( plhs[ 0 ] = mxCreateDoubleScalar ( (double)  n ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:recv:n" , ERRHDR
      "non enough heap memory for output arg n" , RTCONS->cd ) ;
  }
  
  /* Maximum index of array argov that is accessed. Subtract 1 to go from
    output arg count to array index. Subtract another 1 to centre the
    starting index value of 0 on output arg src. */
  r = nlhs  -  2 ;
  
  /* No output arg other than n requested , so return */
  if  ( r  <  0 )  return ;
  
  /* Number of columns i.e. is n non-zero? Yes, 1 col. No, 0 col. */
  f = 0  <  n ;
  
  /* Alocate output vectors */
  for  ( i = 1 ; i  <  nlhs ; ++i )
    
    /* Make Matlab array */
    if  ( ( plhs[ i ] = mxCreateDoubleMatrix ( n , f , mxREAL ) ) == NULL )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:recv:outargs" , ERRHDR
        "not enough heap memory for output arg %d" , RTCONS->cd , i + 1 ) ;
    }
    
    /* Access array's real value data */
    else if  (  n  &&
              ( argov[ i - 1 ] =  mxGetPr ( plhs[ i ] ) )  ==  NULL  )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:recv:outargs" , ERRHDR
        "no real value component to output arg %d" , RTCONS->cd , i + 1 ) ;
    }
  
  /* Load each received MET signal */
  for  ( i = 0 ; i  <  n ; ++i )
    
    switch  ( r )
    {
      /* Time */
      case  PLHS_TIM:  argov[ PLHS_TIM ][ i ] = ( double )  s[ i ].time   ;
      
      /* Cargo */
      case  PLHS_CRG:  argov[ PLHS_CRG ][ i ] = ( double )  s[ i ].cargo  ;
      
      /* Signal identifier */
      case  PLHS_SIG:  argov[ PLHS_SIG ][ i ] = ( double )  s[ i ].signal ;
      
      /* Source controller descriptor */
      case  PLHS_SRC:  argov[ PLHS_SRC ][ i ] = ( double )  s[ i ].source ;
    }
  
  
} /* metxrecv */

