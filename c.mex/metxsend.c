
/*  metxsend.c
  
  n = met ( 'send' , sig , crg , tim , blk )
  
  Sends MET signal requests to the MET server controller. Up to the atomic
  write limit of signals can be sent, while the ith signal has MET signal
  identifier sig( i ), cargo crg( i ), and time tim( i ). All signals have
  a source value of the calling controller's controller descriptor. Returns
  the number of MET signals that were sent. sig, crg, and tim must be
  Matlab type double matrices. blk is optional ; if non-zero then a
  blocking write is performed on the request pipe. Otherwise, a
  non-blocking write is performed. If tim is an empty double i.e. [] then
  'send' takes a time measurement and supplies this to all requested
  signals.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:send: "

#define  NLHS_MAX  1
#define  NRHS_MIN  3
#define  NRHS_MAX  4

#define  PRHS_SIG  0
#define  PRHS_CRG  1
#define  PRHS_TIM  2
#define  PRHS_BLK  3


/*--- Macros ---*/

/* Current signal identifier */
#define  CSI( i )  s[ i ].signal


/*--- Constants ---*/

/* Signal names */
  const char *  MSIGNM[] = { MSNNULL , MSNREADY , MSNSTART ,
    MSNSTOP , MSNWAIT , MSNQUIT , MSNSTATE , MSNTARGET ,
    MSNREWARD , MSNRDTYPE , MSNCALIBRATE } ;

/* Minimum and maximum allowable cargo values */
const metcargo_t  CRGMIN[ MAXMSI + 1 ] =
  { MIN_MNULL , MIN_MREADY , MIN_MSTART , MIN_MSTOP ,
    MIN_MWAIT , MIN_MQUIT , MIN_MSTATE , MIN_MTARGET ,
    MIN_MREWARD , MIN_MRDTYPE , MIN_MCALIBRATE } ;

const metcargo_t  CRGMAX[ MAXMSI + 1 ] =
  { MAX_MNULL , MAX_MREADY , MAX_MSTART , MAX_MSTOP ,
    MAX_MWAIT , MAX_MQUIT , MAX_MSTATE , MAX_MTARGET ,
    MAX_MREWARD , MAX_MRDTYPE , MAX_MCALIBRATE } ;


/*--- metxsend function definition ---*/

void  metxsend ( struct met_t *  RTCONS ,
                 int  nlhs ,       mxArray *  plhs[] ,
                 int  nrhs , const mxArray *  prhs[] )
{
  
  /*-- Compile time variables --*/
  
  /* Generic counter */
  size_t  i ;
  
  /* Number of requested signals , and number sent.
    Use also to check number of elements in the input arguments. */
  size_t  q , n ;
  
  /* Time measurement flag , default low, and time measurement */
  unsigned char  tf = 0 ;
  mettime_t  tm ;
  
  /* MET signal buffer byte pointer */
  char *  p ;
  
  /* double pointers */
  double  * sig , * crg , * tim ;
  
  /* Write return value */
  ssize_t  r ;
  
  
  /*-- Check input arguments --*/
  
  /* Number of outputs */
  if  ( nlhs  >  NLHS_MAX )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:send:nlhs" , ERRHDR
      "max %d output args , %d requested" ,
      RTCONS->cd , NLHS_MAX , nlhs ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs < NRHS_MIN  ||  NRHS_MAX < nrhs )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:send:nrhs" , ERRHDR
      "takes %d to %d input args , %d given" , RTCONS->cd , NRHS_MIN ,
      NRHS_MAX , nrhs ) ;
  }
  
  /* All inputs type Matlab double */
  for  ( i = 0 ; i  <  nrhs ; ++i )
    
    if  ( !mxIsDouble ( prhs[ i ] ) )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:send:nrhs" , ERRHDR
        "arg %d is not double array" , RTCONS->cd , i + 1 ) ;
    }
  
  
  /*   sig, crg, and tim args all have same number of elements   */
  
  /* Seed comparison by getting numel of first arg */
  q = mxGetNumberOfElements ( prhs[ 0 ] ) ;
  
  /* Chain compare remainder of args */
  for  ( i = 1 ; i  <  NRHS_MAX - 1 ; ++i , q = n )
  {
    /* numel of next arg */
    n = mxGetNumberOfElements ( prhs[ i ] ) ;
    
    /* Do args i-1 and i have same numel? */
    if  ( q  !=  n )
    {
      /* No , is tim empty? */
      if  ( i  ==  PRHS_TIM  &&  n  ==  0 )
      {
        /* Yes, then raise measurement flag, set n to q, and carry on */
        tf = 1 ;
        n = q ;
        continue ;
      }
      
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:send:prhs" , ERRHDR
        "unequal number of %d and %d elements in args %d and %d" ,
        RTCONS->cd , q  , n , i , i + 1 ) ;
    }
  }
  
  /* Blocking argument is scalar double */
  if  ( nrhs  ==  NRHS_MAX  &&
        mxGetNumberOfElements ( prhs[ PRHS_BLK ] )  !=  1 )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:send:prhs" , ERRHDR
      "blk must be scalar double" , RTCONS->cd ) ;
  }
  
  
  /*-- Empty input --*/
  
  /* No signal requests. sig, crg, and tim are all empty i.e. [] */
  if  ( !q )
    
    /* Return zero i.e. n = 0 */
    if  ( ( plhs[ 0 ] = mxCreateDoubleScalar ( 0 ) )  ==  NULL )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:send:plhs" , ERRHDR
        "not enough free heap space for output arg" , RTCONS->cd ) ;
    }
    else
      /* mcCreateDoubleScalar successful */
      return ;
  
  
  /*-- Time measurement requested --*/
  
  if  ( tf )
  {
    /* Measure time */
    struct timeval  tv ;
    
    if  ( gettimeofday ( &tv , NULL )  ==  -1 )
    {
      RTCONS->quit = ME_SYSER ;
      mexErrMsgIdAndTxt ( "MET:send:gettimeofday" , ERRHDR
        "error measuring time" , RTCONS->cd ) ;
    }
    
    /* Convert to MET i.e. PsychToolbox-style value */
    tm = tv.tv_sec  +  tv.tv_usec / USPERS ;
  }
  
  
  /*-- MET signal buffer --*/
  
  /* Number of requested signals is minimum of number provided vs atomic */
  q =  RTCONS->awmsig  <  q  ?  RTCONS->awmsig  :  q  ;
  
  /* Make buffer */
  struct metsignal  s[ q ] ;
  
  /* Get pointers to input values */
  sig = mxGetPr ( prhs[ PRHS_SIG ] ) ;
  crg = mxGetPr ( prhs[ PRHS_CRG ] ) ;
  tim = mxGetPr ( prhs[ PRHS_TIM ] ) ;
  
  /* Check that real value data exists for all input args. Careful with
    tim, if time-measure flag is up then NULL is allowed. */
  if  ( sig  ==  NULL  ||  crg  ==  NULL  ||  ( !tf  &&  tim  ==  NULL ) )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:send:prhs" , ERRHDR
      "an input arg has no real value data" , RTCONS->cd ) ;
  }
  
  /* Load buffer */
  for  ( i = 0 ; i  <  q ; ++i )
  {
    /* Current controller's descriptor */
    s[ i ].source = RTCONS->cd ;
    
    /* MET signal identifier */
    s[ i ].signal = ( metsignal_t )  sig[ i ] ;
    
    /* Cargo */
    s[ i ].cargo = ( metcargo_t )  crg[ i ] ;
    
    /* Time , return new measurement unless values provided in tim */
    s[ i ].time  =  tf  ?  tm  :  ( mettime_t )  tim[ i ]  ;
    
    /* Check signal identifier */
    if  ( sig[ i ] < 0  ||  MAXMSI < sig[ i ] )
    {
      RTCONS->quit = ME_PBSIG ;
      mexErrMsgIdAndTxt ( "MET:send:sigid" , ERRHDR
        "signal %llu identifier %0.0f out of range 0 to %d" ,
        RTCONS->cd , (unsigned long long) i , sig[ i ] , MAXMSI ) ;
    }
    /* Check cargo */
    else if ( crg[ i ] < CRGMIN[ CSI( i ) ]  ||
              crg[ i ] > CRGMAX[ CSI( i ) ] )
    {
      RTCONS->quit = ME_PBCRG ;
      mexErrMsgIdAndTxt ( "MET:send:sigcrg" , ERRHDR
        "signal %llu %s cargo %d out of range %d to %d" ,
        RTCONS->cd , (unsigned long long) i , MSIGNM[ CSI( i ) ] ,
        s[ i ].cargo , CRGMIN[ CSI( i ) ] , CRGMAX[ CSI( i ) ] ) ;
    }
    /* Check time */
    else if  ( s[ i ].time < MIN_MSTIME  ||  MAX_MSTIME < s[ i ].time )
    {
      RTCONS->quit = ME_PBTIM ;
      mexErrMsgIdAndTxt ( "MET:send:sigtime" , ERRHDR
        "signal %llu %s time " MST2STR " out of range " MST2STR " to "
        MST2STR , RTCONS->cd , (unsigned long long) i ,
        MSIGNM[ CSI( i ) ] , s[ i ].time , MIN_MSTIME , MAX_MSTIME ) ;
    }
    
  } /* load buf */
  
  
  /*-- Perform blocking write --*/
  
  if  ( nrhs  ==  NRHS_MAX  &&  mxGetScalar ( prhs[ PRHS_BLK ] ) )
    
    metxsetfl ( RTCONS , 1 ,
                RTCONS->p + REQSTW , RTCONS->pf + REQSTW , 'b' ,
                "error switching to blocking write on request pipe" ) ;
  
  
  /*-- Write MET signals to request pipe --*/
  
  /* Initialise number of bytes sent */
  n = 0 ;
  
  /* Convert from number of signals to number of bytes requested */
  q = q  *  sizeof ( struct metsignal ) ;
  
  /* Point to head of buffer */
  p = (char *)  s ;
  
  /* Write loop */
  while  ( q  &&  ( r = write ( RTCONS->p[ REQSTW ] , p , q ) ) )
  {
    
    /* Error checking */
    if  ( r  ==  -1 )
    {
      /* Unix signal interruption , try again */
      if  ( errno  ==  EINTR )  continue ;
      
      /* Clogged pipe , only matters in non-blocking writes */
      else if  ( ( errno == EAGAIN  ||  errno == EWOULDBLOCK )  &&
                 !( RTCONS->pf[ REQSTW ]  &  O_NONBLOCK ) )
      {
        RTCONS->quit = ME_CLGRP ;
        mexErrMsgIdAndTxt ( "MET:send:clogged" , ERRHDR
          "clogged request pipe" , RTCONS->cd ) ;
      }
      
      /* Broken pipe */
      else if  ( errno  ==  EPIPE )
      {
        RTCONS->quit = ME_BRKRP ;
        mexErrMsgIdAndTxt ( "MET:send:broken" , ERRHDR
          "broken request pipe" , RTCONS->cd ) ;
      }
      
      /* Other */
      else
      {
        RTCONS->quit = ME_SYSER ;
        perror ( "met:metxsend:write" ) ;
        mexErrMsgIdAndTxt ( "MET:send:write" , ERRHDR
          "error while writing to request pipe" , RTCONS->cd ) ;
      }
    } /* error */
    
    /* Update counters and pointer */
    p += r ;
    n += r ;
    q -= r ;
    
  } /* write loop */
  
  
  /*-- Restore non-blocking writes --*/
  
  if  ( !( RTCONS->pf[ REQSTW ]  &  O_NONBLOCK ) )
    
    metxsetfl ( RTCONS , 1 ,
                RTCONS->p + REQSTW , RTCONS->pf + REQSTW , 'n' ,
                "error switching to non-blocking write on request pipe" ) ;
  
  
  /*-- Return number of MET signals requested --*/
  
  /* Convert from bytes to signals */
  n  /=  sizeof ( struct metsignal ) ;
  
  /* Convert to Matlab array */
  if  ( ( plhs[ 0 ] = mxCreateDoubleScalar ( (double)  n ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:send:plhs" , ERRHDR
      "not enough free heap space for output arg" , RTCONS->cd ) ;
  }
  
  
} /* metxsend */

