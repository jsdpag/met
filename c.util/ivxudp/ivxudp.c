
/*  ivxudp.c
  
  [ ... ] = ivxudp ( ivxfun , ... )
  
  Matlab Electrophysiology Toolbox utility function. This allows a MET
  controller function to stream eye positions from a remote system that
  runs the SensoMotoric Instrumentation GmbH (SMI) eye-tracking program
  iViewX. Different sub-functions are executed, depending on the value of
  the first argument, ivxfun, which must be a single character.
  
  This requires that the local system running MET and the SMI system are
  connected to the same network ; for example, both systems may have their
  ethernet cards plugged into the same networking switch. iViewX is
  required to be set up for binocular eye tracking, while manual Direct
  Analog Gain and Offset calibration must be enabled. The left and right
  gaze positions must be used to generate the analogue voltage output from
  the SMI system, and out of range behaviour must be clipped ; when this is
  the case, the Data Range in iViewX is automatically set as 4095 to 12287,
  and this fact will be assumed, here. The local MET system and the SMI
  system must have compatible IP addresses that are used in the iViewX
  Ethernet configuration for UDP communication. Beware that monocular
  eye samples will be discarded, only binocular eye samples will be used.
  
  The above will be true when using the Hi-Speed Primate camera with iViewX
  version 2.8 build 43.
  
  Sub-functions:
  
      s = ivxudp ( 'o' , hipa , hprt , iipa , iprt ) -- Make and bind a
        socket. The user must provide the IP address and port for the host
        (upon which Matlab is running) and SMI (upon which iViewX is
        running) computers. hipa and iprt must be strings containing IP
        addresses. hprt and iprt must be scalar doubles indicating ports.
        For input arguments, 'h' means host and 'i' means iViewX. 'open'
        will send a test ping command ; if no reply is given before a
        timeout, then the socket is immediately closed. A data format
        string is then sent to iViewX, telling it what information to
        stream. Finally, data streaming from iViewX is started. Returns
        scalar double s, which is the value of the socket file descriptor ;
        for use with multiplexing functions, like select( ).

      ivxudp ( 'c' ) -- Stops iViewX from streaming data, and close the
        socket.
  
      [ tret , tim , gaze , diam ] = ivxudp ( 'r' ) -- Read new
        eye samples from the socket buffer. This is a non-blocking read.
        So when no new data is available, then all output arguments will be
        empty double arrays i.e. they will all be []. The exception is
        tret (see below). If data is available then each of the output
        arguments will be a double array containing the following:
        
        tret - scalar - gettimeofday( ) time measurement in seconds.
          This is taken immediately after reading from the socket, and will
          be directly comparable to local time measurements returned by
          Psych Toolbox functions, like GetSecs( ). If no new data was
          available then tret returns zero.
        
        All following outputs will have 1 <= N rows, where the ith row in
        each output argument refers to the same data sample.
  
        tim - N x 1 - Contains the time stamp of each eye sample. These
          measurements are NOT from the local system running MET. They are
          from the SMI computer. In seconds.
        
        gaze - N x 4 - Contains gaze positions. Column indexing
          is [ x-left , y-left , x-right , y-right ]. That is, horizontal
          coordinates are in columns 1 and 3, vertical in 2 and 4 ; left
          eye coordinates are in columns 1 and 2, right in 3 and 4. All
          gaze positions are normalised to a value between 0 and 1, where
          0 corresponds to the minimum voltage and 1 the maximum voltage
          that iViewX is configured to produce when generating analogue
          copies of the gaze position.
        
        diam - N x 4 - Contains the pupil diameter. Column indexing is the
          same as for gaze. Hence, the diameter is measured separately in
          both the x- and y-axis, for each eye. In pixels of the eye
          tracking video image.
  
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

/* Matlab */
#include  "mex.h"
#include  "matrix.h"

/* Sockets */
#include  <arpa/inet.h>
#include  <netinet/in.h>
#include  <sys/types.h>
#include  <sys/socket.h>

/* General */
#include  <errno.h>
#include  <stdio.h>
#include  <stdlib.h>
#include  <string.h>
#include  <strings.h>
#include  <unistd.h>
#include  <sys/time.h>


/*--- Define block ---*/

/* System error and exit */
#define  PEX( s )  { perror ( s ) ; exit ( EXIT_FAILURE ) ; }


/* ivxfun values */

  /* Open socket and start data streaming */
  #define  IVXFUN_OPEN  'o'

  /* Close socket and stop data streaming */
  #define  IVXFUN_CLOSE  'c'

  /* Close socket and stop data streaming */
  #define  IVXFUN_READ  'r'


/* Number of input and output args */

  /* Open function number of right-hand side input arguments */
  #define  NRHS_OPEN  5

  /* Maximum number of output arguments from read function */
  #define  NLHS_READ  4


/*   Buffers   */

  /* Socket receive buffer size -- 2 ^ 19 bytes */
  #define  RECBUF  524288

  /* Return buffer threshold in bytes. This is the minimum size of a TCP/IP
     datagram. The user-space receive buffer must have at least this much
     space left before executing another read on the socket */
  #define  BUFTHR  576 

  /* Function name buffer size in bytes */
  #define  FNAMEB  6
  
  /* Socket receive buffer pause to flush, in microseconds */
  #define  BFUSEC  25000


/* IP addressing */

  /* Maximum reserved port */
  #define  MAXPRT  1023

  /* Ping test socket timeout */
  #define   TOSEC  1
  #define  TOUSEC  0


/*   Parsing constants   */

  /* iViewX command terminator */
  #define  IVXTRM  '\n'

  /* iViewX alternate command terminator */
  #define  IVXTR2  '\r'

  /* iViewX command separator */
  #define  IVXSEP  ' '

  /* iViewX eye type for binocular data streaming */
  #define  IVXBIN  'b'

  /* The number of numeric values to be returned per sample form iViewX */
  #define  NUMVAL  9

  /* microseconds per second */
  #define  USPERS  1000000.0

  /* Gaze position minimum and maximum values , and range */
  #define  GAZMIN  4095.0
  #define  GAZMAX  12287.0
  #define  GAZRNG  8192.0

  /* Output argument index , from ivxparse */
  #define  AOUT_TIM   0
  #define  AOUT_GAZE  1
  #define  AOUT_DIAM  2

  /* ivxparse return values */
    
    /* Eye samples received and parsed */
    #define  IVXPARSE_GOT_SAMPLES  0

    /* No eye samples received */
    #define  IVXPARSE_NO_SAMPLES   1


/*--- Global static variables ---*/

/* Socket file descriptor. If this is 0 then we know that no socket is
   open */
static int  s = 0 ;

/* iViewX IP address and port, for sending messages */
static struct sockaddr_in  ivxadd ;

/* User-space receive buffer pointer */
static char *  recbuf ;

/* current number of bytes and datagrams in user-space receive buffer */
static size_t  rbi = 0 ;
static size_t  rbd = 0 ;


/*--- Global constant variables ---*/

/* iViewX command strings. In memory so that we can measure length. */

  /* Ping */
  const char  IVXPNG[] = "ET_PNG\n" ;

  /* Streamed data format: eye type character, microsecond time stamp, x-
     axis gaze positions, y-axis gaze positions, x-axis pupil diameters, y-
     axis pupil diameters */
  const char  IVXFRM[] = "ET_FRM \"%ET %TU %SX %SY %DX %DY\"\n" ;

  /* Start data streaming */
  const char  IVXSTR[] = "ET_STR\n" ;

  /* One sample of eye data from iViewX */
  const char  IVXSPL[] = "ET_SPL" ;

  /* Stops data streaming */
  const char  IVXEST[] = "ET_EST\n" ;

  /* Stop fixation detection */
  const char  IVXEFX[] = "ET_EFX\n" ;

  /* Stops calibration */
  const char  IVXBRK[] = "ET_BRK\n" ;

/* ivxparse output constants */
  
  /* The number of columns per output argument */
  const unsigned char  NUMCOL[] = { 1 , 4 , 4 } ;
  
  /* The ET_SPL to column mapping for left and right eye values */
  const unsigned char  COLMAP[] = { 0 , 2 , 1 , 3 } ;


/*--- Function definitions ---*/

     int  notstr ( const mxArray * ) ;
uint16_t  getport ( const mxArray * ) ;
    void  ivxsock ( const mxArray ** ) ;
    void  xclose ( void ) ;
 ssize_t  xsendto ( int , const void * , size_t , int , 
                                    const struct sockaddr * , socklen_t ) ;
 ssize_t  xrecvfrom ( int , void * , size_t , int ) ;
  double  sread ( void ) ;
    char  ivxparse ( int , mxArray ** ) ;


/*** ivxudp function definition ***/

void  mexFunction ( int  nlhs ,       mxArray *  plhs[] ,
                    int  nrhs , const mxArray *  prhs[] )
{
  
  
  /*-- Variables --*/
  
  /* Function character and null byte */
  char  c[ 2 ] ;
  
  
  /*-- Check input --*/
  
  /* There must be at least one input argument that is a single Matlab
     char */
  if  ( nrhs  <  1 )
  
    mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
      "ivxudp arg ivxfun required"  ) ;
  
  else if  (  !mxIsChar ( prhs[ 0 ] )  )
    
    mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
      "ivxudp arg ivxfun must be type char"  ) ;
  
  else if  (  !mxIsScalar ( prhs[ 0 ] )  )
    
    mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
      "ivxudp arg ivxfun must be a single char"  ) ;
  
  
  /*-- Get function char --*/
  
  if  (  mxGetString ( prhs[ 0 ] , c , 2 )  )
    
    mexErrMsgIdAndTxt (  "MET:ivxudp:funchar"  ,
      "ivxudp error reading arg ivxfun"  ) ;
  
  /* Additional error checking if function char is not 'o' i.e. open */
  else if  ( c[ 0 ]  !=  IVXFUN_OPEN )
  {
    
    /* Only ivxfun allowed , no other input args */
    if  (  nrhs != 1 )
      
      mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
        "ivxudp too many input args for function '%c'"  ,  c[ 0 ]  ) ;
    
    /* Socket must be open */
    else if  (  !s  )
      
      mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
        "ivxudp must be open before using function '%c'"  ,  c[ 0 ]  ) ;
    
  } /* extra error checking */
  
  
  /*-- Run sub-function --*/
  
  /* Choose sub-function according to the value of ivxfun */
  switch (  c[ 0 ]  )
  {
    
    
    /* Read in the latest eye samples */
    case  IVXFUN_READ:
      
      /* Check number of output arguments */
      if  ( NLHS_READ  <  nlhs )
        
        mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
          "ivxudp read provides at most %d output arguments"  ,
            NLHS_READ  ) ;
      
      /* Read data from socket's buffer and place into ivxudp's buffer.
         Returns time measurement. */
      double  tret = sread (  ) ;
      
      /* Parse data into double values , returns non-zero if NO samples
         were found i.e. tret must be zero */
      if  (  ivxparse ( nlhs - 1 , plhs + 1 )  )
        tret = 0 ;
      
      /* Return scalar double time value */
      plhs[ 0 ] = mxCreateDoubleScalar ( tret ) ;
      
      /* Finished reading */
      break ;
      
      
    /* Open socket and start data streaming */
    case  IVXFUN_OPEN:
      
      /* Check correct number of input arguments ... */
      if  ( nrhs  !=  NRHS_OPEN )
        
        mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
          "ivxudp open requires %d input arguments in total"  ,
            NRHS_OPEN  ) ;
      
      /* ... and output arguments */
      else if  ( 1  <  nlhs )
        
        mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
          "ivxudp open returns at most 1 output argument"  ) ;
      
      /* No socket can be open yet */
      else if  ( s )
        
        mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
          "ivxudp is already open"  ) ;
        
      
      /* Open and test socket */
      ivxsock ( prhs + 1 ) ;

      /* Return socket file descriptor */
      plhs[ 0 ]  =  mxCreateDoubleScalar (  (double) s  ) ;

      /* Report */
      mexPrintf (  "ivxudp: opened UDP socket %d, allocated buffer\n"  ,
        s  ) ;
      
      /* Finished opening */
      break ;
      
      
    /* Close socket and stop data streaming */
    case  IVXFUN_CLOSE:
      
      xclose () ;
      break ;
      
      
    /* Unrecognised function */
    default:
      
      mexErrMsgIdAndTxt (  "MET:ivxudp:ivxfun"  ,
        "ivxudp arg ivxfun unrecognised function char '%c'"  ,  c[ 0 ]  ) ;
    
      
  } /* choose sub-function */
    
  
} /* ivxudp */


/*---Subroutines---*/

/* Parse iViewX commands , returns 0 if eye samples parsed , returns non-
   zero value if NO eye samples found */
char  ivxparse ( int  nlhs , mxArray *  plhs[] )
{
  
  
  /*-- Check input --*/
  
  /* No output arguments requested at all, empty user-space receive buffer
     and return assuming no samples (it doesn't matter anyway) */
  if  ( nlhs  <=  -1 )
  {
    rbi = rbd = 0 ;
    return  IVXPARSE_NO_SAMPLES ;
  }
  
  
  /*-- Variables --*/
  
  /* char pointers - ci for scanning receive buffer (initialised at head of
     receive buffer) , cj another scanning pointer (initialised to first
     byte past end of rec buffer) , p an array of pointers that locate the
     first byte of the first numeric value from each sample */
  char  * ci = recbuf  ,  * cj = recbuf + rbi ,  * p[ rbd ] ;
  
  /* Counters - i, j & k generic counters , N is the number of binocular
     eye samples (initialised to zero) , icol[ c ] the starting index for
     column c in a N x 4 array , aout and oset are output argument index
     and d index offset */
  size_t  i , N = 0 , icol[ 4 ] ;
  unsigned char  j , k , aout , oset ;
  
  /* double pointer array , each element points to memory allocated for
     output arguments */
  double *  dp[ NLHS_READ - 1 ] ;
  
  /* double value parsing buffer , has enough space to read in one full
     sample */
  double  d[ NUMVAL ] ;
  
  
  /*-- Pre-allocate empty double arrays --*/
  
  /* Start with empties , in case there are no new eye samples */
  for  ( i = 0  ;  i < nlhs  ;  i++ )
    
    plhs[ i ] = mxCreateDoubleMatrix ( 0 , 0 , mxREAL ) ;
  
  /* Alas! There are no new eye samples. Return now. */
  if  ( !rbi )
    return  IVXPARSE_NO_SAMPLES ;
  
  
  /*-- Locate and count new eye samples --*/
  
  /* Scan entire receive buffer for samples */
  while  ( ci  <  cj )
  {
    
    /* We have NOT yet placed ci upon the first byte of an iViewX sample
       command string , so advance pointer by one more character */
    if  ( ci[ 0 ] != IVXSPL[ 0 ]  ||
          ci[ 1 ] != IVXSPL[ 1 ]  ||
          ci[ 2 ] != IVXSPL[ 2 ]  ||
          ci[ 3 ] != IVXSPL[ 3 ]  ||
          ci[ 4 ] != IVXSPL[ 4 ]  ||
          ci[ 5 ] != IVXSPL[ 5 ]  )
    {
      ci++ ;
      continue ;
    }
    
    /* Jump to first byte past the command string */
    ci += FNAMEB ;
    
    /* Skip separator characters */
    while  ( *ci  ==  IVXSEP )
      ci++ ;
    
    /* Invalid case check. This byte should be the eye type for binocular,
       not any other character. In either case, step forward one byte. */
    if  ( *( ci++ )  !=  IVXBIN )
    {
      mexPrintf (  "ivxudp: invalid %s command , not binocular"  ,
        IVXSPL  ) ;
      continue ;
    }
    
    /* Skip separator characters */
    while  ( *ci  ==  IVXSEP )
      ci++ ;
    
    /* If we have encountered the end of a datagram then the data sample
       format is invalid. Say so, and keep checking the buffer. */
    if  ( *ci == IVXTRM  ||  *ci == IVXTR2 )
    {
      mexPrintf (  "ivxudp: invalid %s command , terminates before "
        "any data provided" ,  IVXSPL  ) ;
      ci++ ;
      continue ;
    }
    
    /* Store pointer location in the buffer AND increment the sample
       counter */
    p[ N++ ] = ci ;
    
    /* Look for the end of the datagram */
    while  ( *ci != IVXTRM  &&  *ci != IVXTR2 )
      ci++ ;
    
  } /* scan receive buffer */
  
  /* Empty user-space receive buffer */
  rbi = rbd = 0 ;
  
  /* No new eye samples , return now */
  if  ( !N )
    return  IVXPARSE_NO_SAMPLES ;
  
  /* Otherwise, no eye-data output arguments requested */
  if  ( nlhs  <=  0 )
    return  IVXPARSE_GOT_SAMPLES ;
  
  /* Find index values */
  for  ( i = 0  ;  i < 4  ;  i++ )
    icol[ i ] = N  *  i ;
  
  
  /*-- Allocate memory for new samples --*/
  
  /* Allocate for each requested output argument */
  for  ( i = 0  ;  i < nlhs  ;  i++ )
    
    dp[ i ] = mxMalloc (  N * NUMCOL[ i ] * sizeof( double )  ) ;
  
  
  /*-- Parse strings to doubles --*/
  
  /* Parse each eye sample */
  for  ( i = 0  ;  i < N  ;  i++ )
  {
    
    /* Place pointer at start of sample's first value */
    ci = p[ i ] ;
    
    /* Parse each individual numeric value */
    for  ( j = 0  ;  j < NUMVAL  ;  j++ )
    {
      d[ j ] = strtod (  ci  ,  &cj  ) ;  /* parse */
      ci = cj ;                           /* next number */
    }
    
    /* Convert gaze positions to normalised values */
    for  ( j = 1  ;  j < 5  ;  j++ )
    {
      /* Clip to minimum ... */
      if  ( d[ j ]  <  GAZMIN )
        
        d[ j ] = GAZMIN ;
        
      /* ... and maximum values */
      else if  ( d[ j ]  >  GAZMAX )
        
        d[ j ] = GAZMAX ;
        
      /* Normalised value */
      d[ j ] = ( d[ j ]  -  GAZMIN )  /  GAZRNG ;
    }
    
    /* We are guaranteed to return time values at this point , so convert
       to seconds from microseconds */
    dp[ AOUT_TIM ][ i ] = d[ 0 ]  /  USPERS ;
    
    /* Store gaze and diameter values */
    for  ( j = 0  ;  j < nlhs - 1  ;  j++ )
    {
      
      /* Determine output argument index and d's index offset */
      if  ( j )
        {  aout = AOUT_DIAM ;  oset = 5 ;  }
      
      else
        {  aout = AOUT_GAZE ;  oset = 1 ;  }
      
      /* Map newly parsed data into allocated memory */
      for  ( k = 0  ;  k < 4  ;  k++ )
      
        dp[ aout ][ icol[ k ] + i ] = d[ COLMAP[ k ] + oset ] ;
      
    } /* store gaze and diam */
    
  } /* samples */
  
  
  /*-- Return parsed output in Matlab matrices --*/
  
  for  ( i = 0  ;  i < nlhs  ;  ++i )
  {
    
    /* Set data and dimensions */
    mxSetData (  plhs[ i ]  ,  dp[ i ]      ) ;
    mxSetM    (  plhs[ i ]  ,  N            ) ;
    mxSetN    (  plhs[ i ]  ,  NUMCOL[ i ]  ) ;
    
  } /* pack output */
  
  /* Beware that we didn't need to free memory pointed to by dp because
     it is attached to an output array that Matlab will now keep track of
   */
  
  
  /*-- Return function output --*/
  
  /* We wouldn't get this far if there were no samples */
  return  IVXPARSE_GOT_SAMPLES ;
  
  
} /* ivxparse */


/* Read streamed eye data from iViewX out of socket and return local time
   as measured immediately after reading */
double  sread ( void )
{
  
  
  /*--Variables--*/
  
  /* Bytes received */
  ssize_t  br = 0 ;
  
  /* Receive buffer pointer variable */
  char *  pv = recbuf ;
  
  /* Space remaining in receive buffer */
  size_t  rem = RECBUF - rbi ;
  
  /* Read time measurement */
  struct timeval  t ;
  
  
  /*--Read eye data from socket--*/

  /* Non-zero value must return from recvfrom, and user-space receive
     buffer must still have enough space.
   */
  while (  ( br = xrecvfrom ( s , pv , rem , MSG_DONTWAIT ) )  &&
             BUFTHR <= rem  )
  {
    
    /* Error detected */
    if  (  br == -1  )
    {
      
      /* Non-blocking read, no data available */
      if  (  errno == EAGAIN  ||  errno == EWOULDBLOCK  )
        break ;
      
      /* This shouldn't happen */
      else
        mexErrMsgIdAndTxt (  "MET:ivxudp:sread"  ,
          "ivxudp 'read', Unexpected error"  ) ;
      
    } /* error */
    
    /* Update buffer position and remaining space */
    pv += br ;
    rem -= br ;
    
    /* Count datagram */
    ++rbd ;
    
  } /* read loop */
  
  
  /*--Read time measurement--*/
  
  if  ( gettimeofday ( &t , NULL ) == -1 )
    mexErrMsgIdAndTxt ( "MET:ivxudp:sread" ,
            "ivxudp: gettimeofday errno %d" , errno ) ;
  
  
  /*--Number of bytes in buffer--*/
  
  rbi  =  RECBUF - rem  ;
  
  
  /*-- Return time in seconds --*/
  
  return   (double) t.tv_sec  +  (double) t.tv_usec / USPERS ;
  
  
} /* sread */


/* Open socket and test that it can reach iViewX */
void  ivxsock ( const mxArray *  m[] )
{
  
  
  /*--Variables--*/
  
  /* Address string lengths, and generic number of bytes */
  size_t  hsn , isn , nb ;
  
  /* Port numbers */
  uint16_t  hprt , iprt ;
  
  /* Host address */
  struct  sockaddr_in  a ;
  
  /* Socket receive buffer size */
  int  rbs = RECBUF ;
  
  /* Socket receive timeout duration, default with size, and temporary */
  struct timeval def ;
  int  sdef = sizeof ( def ) ;
  
  struct timeval  rto = { TOSEC , TOUSEC } ;
  
  /* Ping message bytes received */
  ssize_t  br = 0 ;
  
  
  /*--Obtain address strings--*/
  
  /* Check strings */
  if  ( notstr ( m[ 0 ] ) )
    mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' , hipa must be a string" ) ;
    
  if  ( notstr ( m[ 2 ] ) )
    mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' , iipa must be a string" ) ;
  
  /* Number of characters , add 1 for null byte */
  hsn = mxGetNumberOfElements( m[ 0 ] ) + 1 ;
  isn = mxGetNumberOfElements( m[ 2 ] ) + 1 ;
  
  /* String buffers */
  char  hipa[ hsn ] , iipa[ isn ] ;
  
  /* Convert to char */
  mxGetString ( m[ 0 ] , hipa , hsn ) ;
  mxGetString ( m[ 2 ] , iipa , isn ) ;
  
  
  /*--Obtain port numbers--*/
  
  /* Convert to integers */
  hprt = getport ( m[ 1 ] ) ;
  iprt = getport ( m[ 3 ] ) ;
  
  /* Check values */
  if  ( !hprt )
    mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' , hprt must be a double over 1023" ) ;
    
  if  ( !iprt )
    mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' , iprt must be a double over 1023" ) ;
  
  
  /*--Set addresses--*/
  
  /* Host */
  memset ( (char *) &a , 0 , sizeof ( a ) ) ;
  a.sin_family = AF_INET ;
  a.sin_port = htons ( hprt ) ;
  a.sin_addr.s_addr = inet_addr ( hipa ) ;
  
  /* iViewX */
  memset ( (char *) &ivxadd , 0 , sizeof ( ivxadd ) ) ;
  ivxadd.sin_family = AF_INET ;
  ivxadd.sin_port = htons ( iprt ) ;
  ivxadd.sin_addr.s_addr = inet_addr ( iipa ) ;
  
  
  /*--Allocate receive buffer--*/
  
  if  (  ( recbuf = malloc ( RECBUF ) )  ==  NULL  )
    PEX ( "malloc" )
  
  /* No data in buffer */
  rbi = rbd = 0 ;
  
  
  /*--Make UDP socket--*/
  
  if  (  ( s = socket ( AF_INET , SOCK_DGRAM , 0 ) )  ==  -1  )
    PEX ( "MET:ivxudp:socket" )
  
  /* Set receive buffer size */
  if  (
  setsockopt ( s , SOL_SOCKET , SO_RCVBUF , &rbs , sizeof ( rbs ) )  ==  -1
       )
    PEX ( "MET:ivxudp:setsockopt" )
  
  /* Get default receive timeout */
  if  ( getsockopt ( s , SOL_SOCKET , SO_RCVTIMEO , &def , &sdef ) == -1 )
    PEX ( "MET:ivxudp:getsockopt" )
    
  /* Set receive timeout */
  if  (
setsockopt ( s , SOL_SOCKET , SO_RCVTIMEO , &rto , sizeof ( rto ) )  ==  -1
       )
    PEX ( "MET:ivxudp:setsockopt" )
  
  
  /*--Bind socket to host address--*/
  
  if  ( bind ( s , (struct sockaddr *) &a , sizeof ( a ) ) == -1 )
  {
    
    /* Handle binding errors. Close socket, first.
     */
    int  e = errno ;
    xclose () ;
    errno = e ;
    
    if  ( errno == EACCES )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' hipa & hprt , "
              "address is protected or search permission denied") ;
      
    else if  ( errno == EADDRINUSE )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' hipa & hprt , this address is in use" ) ;
    
    else if  ( errno == EADDRNOTAVAIL )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' hipa & hprt , "
              "nonexistent interface or address not local" ) ;
    
    else if  ( errno == EFAULT )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' hipa & hprt , "
              "points outside user's accessible address space" ) ;
    
    else if  ( errno == ELOOP )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' hipa & hprt , "
              "too many symbolic links were encountered" ) ;
    
    else if  ( errno == ENAMETOOLONG )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' hipa & hprt , address too long" ) ;
    
    else if  ( errno == ENOENT )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' hipa & hprt , file does not exist" ) ;
    
    else if  ( errno == ENOTDIR )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' hipa & hprt , part of prefix not directory" );
    
    else
      PEX ( "MET:ivxudp:bind" )
      
  } /* bind socket -- error handling */
  
  
  /*--Send a single ping command to iViewX--*/
  
  /* First, stop any data streaming or calibration */
  nb = strlen ( IVXEST ) ;
  xsendto ( s , IVXEST , nb , 0 , 
    ( struct sockaddr * ) &ivxadd , sizeof ( ivxadd ) ) ;
  
  nb = strlen ( IVXEFX ) ;
  xsendto ( s , IVXEFX , nb , 0 , 
    ( struct sockaddr * ) &ivxadd , sizeof ( ivxadd ) ) ;
  
  nb = strlen ( IVXBRK ) ;
  xsendto ( s , IVXBRK , nb , 0 , 
    ( struct sockaddr * ) &ivxadd , sizeof ( ivxadd ) ) ;
  
  /* Give a moment for straggling messages to arrive */
  while  (  usleep ( BFUSEC ) == -1  &&  errno == EINTR  ) ;
  
  /* Try to flush the receive buffer */
  while  (  br  ==  xrecvfrom ( s , recbuf , RECBUF , MSG_DONTWAIT )  )
    if  (  br == -1  && ( errno == EAGAIN  ||  errno == EWOULDBLOCK )  )
      break ;
  
  /* Send ping message */
  nb = strlen ( IVXPNG ) ;
  xsendto ( s , IVXPNG , nb , 0 , 
    ( struct sockaddr * ) &ivxadd , sizeof ( ivxadd ) ) ;
  
  
  /*--Wait for ping reply--*/
  
  /* Receive from socket
   */
  br  ==  xrecvfrom ( s , recbuf , RECBUF - 1 , 0 ) ;

  /* Check for timeout error */
  if  (  br == -1  && ( errno == EAGAIN  ||  errno == EWOULDBLOCK )  )
  {
    xclose () ;
    mexErrMsgIdAndTxt ( "MET:ivxudp:openping" ,
           "ivxudp 'open' , timeout waiting for ping reply" ) ;
  }

  /* Set null byte */
  recbuf[ br ] = '\0' ;
  
  /* Look for reply. If we got something else then report it and quit
   */
  if  ( strncasecmp ( recbuf , IVXPNG , br ) )
  {
    xclose () ;
    mexErrMsgIdAndTxt ( "MET:ivxudp:openping" ,
           "ivxudp 'open' , reply other than ping:\n%s" ) ;
  }
  
  
  /*--Reset default receive timeout--*/
  
  if  (
setsockopt ( s , SOL_SOCKET , SO_RCVTIMEO , &def , sizeof ( def ) )  ==  -1
       )
    PEX ( "MET:ivxudp:setsockopt" )
    
    
	/*-- Start data streaming --*/
  
  /* Send format command */
  nb = strlen ( IVXFRM ) ;
  xsendto ( s , IVXFRM , nb , 0 , 
    ( struct sockaddr * ) &ivxadd , sizeof ( ivxadd ) ) ;

  /* Send start command */
  nb = strlen ( IVXSTR ) ;
  xsendto ( s , IVXSTR , nb , 0 , 
    ( struct sockaddr * ) &ivxadd , sizeof ( ivxadd ) ) ;
  
  
} /* ivxsock */


/* getport returns 0 if matrix m is not a valid port number. Otherwise,
   converts it to an integer */
uint16_t  getport ( const mxArray * m )
{
  
  
  /*--Input value--*/
  
  double  d ;
  
  
  /*--Check input--*/
  
  /* Check type double, scalar matrix, no imaginary component */
  if  (  !mxIsDouble( m )  ||  !mxIsScalar( m )  ||  mxIsComplex( m )  )
    return  0 ;
  
  /* Get double value */
  d = mxGetScalar ( m ) ;
  
  /* Make sure that double is not NaN, Inf, or in reserved range */
  if  (  mxIsNaN ( d )  ||  mxIsInf ( d )  ||  d  <=  MAXPRT  )
    return  0 ;
  
  
  /*--Return integer--*/
  
  return  ( uint16_t ) d ;
  
  
} /* getport */


/* checkstr returns 1 if matrix m is not a Matlab char vector.
   0 if it is */
int  notstr ( const mxArray * m )
{
  
  /* If not a string i.e. char column or row vector */
  if  (                           mxIsEmpty ( m )  ||
                                  !mxIsChar ( m )  ||  
               2 != mxGetNumberOfDimensions ( m )  ||  
        (  1 < mxGetM ( m )  &&  1 < mxGetN ( m )  )
      )
    return  1 ;
  
  /* m is a string */
	return  0 ;
  
} /* notstr */


/* Receive messages from socket irrespective of signal interruptions */
ssize_t  xrecvfrom ( int  sockfd , void *  buf , size_t  len , int  flags )
{
  
  /* Copy iViewX address */
  struct sockaddr_in  a  =  ivxadd ;
  
  /* Length of iViewX address structure */
  socklen_t  l  =  sizeof ( a ) ;
  
  /* Return value */
  ssize_t  r = 0 ;
  
  /* errno buffer */
  int  e ;
  
  /* Receive loop */
  while ( (r = recvfrom ( sockfd , buf , len , flags ,
                                     (struct sockaddr *) &a , &l )) == -1 )
  {
    
    /* Signal interruption before transfer, try again */
    if  ( errno == EINTR )
      continue ;
    
    /* Timeout or no data available on a non-blocking read, quit */
    else if  (  errno == EAGAIN  ||
                errno == EWOULDBLOCK  ||
                errno == EINPROGRESS )
      break ;
    
    
    /* Handle receiving errors. Close socket, first.
     */
    e = errno ;
    xclose () ;
    errno = e ;
    PEX ( "MET:ivxudp:recv" )
    
  }
  
  /* Done */
  return  r ;
  
} /* xrecvfrom */


/* Send message through socket irrespective of signal interruptions */
ssize_t  xsendto ( int sockfd , const void * buf , size_t len , int flags ,
                    const struct sockaddr * dest_addr , socklen_t addrlen )
{
  
  /* Return value */
  ssize_t  r ;
  
  /* errno buffer */
  int  e ;
  
  /* Send loop */
  while  (
 ( r = sendto( sockfd , buf , len , flags , dest_addr , addrlen ) )  ==  -1
         )
  {
    
    /* Signal interruption before transfer, try again */
    if  ( errno == EINTR )
      continue ;
    
    /* Handle sending errors. Close socket, first.
     */
    e = errno ;
    xclose () ;
    errno = e ;
    
    if  ( errno == EACCES )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' iipa & iprt , "
         "attempt send to net‐work/broadcast address as though unicast" ) ;
      
    else if  ( errno == ECONNRESET )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' iipa & iprt , connection reset by peer" ) ;
    
    else if  ( errno == EFAULT )
      mexErrMsgIdAndTxt ( "MET:ivxudp:openargs" ,
              "ivxudp 'open' iipa & iprt , invalid user space address" ) ;
    
    else
      PEX ( "MET:ivxudp:sendto" )
    
  }
  
  /* Done */
  return  r ;
  
} /* xsendto */


/* Closes socket irrespective of signal interruptions */
void  xclose ( void )
{
  
  /* Send stop command */
  size_t  nb = strlen ( IVXEST ) ;
  xsendto ( s , IVXEST , nb , 0 , 
    ( struct sockaddr * ) &ivxadd , sizeof ( ivxadd ) ) ;
  
  /* Free receive buffer */
  free ( recbuf ) ;
  rbi = rbd = 0 ;
  
  /* Close socket */
  while ( close ( s ) == -1 )
  {
    
    if  ( errno == EINTR )
      continue ;
    
    else
      PEX ( "MET:ivxudp:close" )
      
  }
  
  /* Report */
  mexPrintf ( "ivxudp: closed UDP socket %d, freed buffer\n" , s ) ;
  
  /* Remember to set socket file descriptor to zero, indicating closed */
  s = 0 ;
  
  
} /* xclose */

