
/*  metsigsrv.c
  
  int  metsigsrv ( const unsigned char  c ,
                   const int *  bw , const int *  qr ,
                   const int  epfd , const size_t  awmsig )
  
  Performs MET signal server function for c MET child controllers.
  c request pipe reading file descriptors in qr are monitored by
  the epoll with file descriptor epfd. MET signals from all request
  pipes are buffered and broadcast to all child controllers ; up to
  awmsig MET signals will be buffered before a forced broadcast.
  Tracks the wait for mready state prior to each trial and
  generates an mstart signal when all MET child controllers are
  ready to start a new trial.
  
  c may not exceed MAXCHLD, and no file descriptor may be
  uninitialised. awmsig may not be 0.
  
  Returns 0 when an mquit signal with cargo 0 is requested.
  Otherwise returns -1 and sets meterr. If mquit with non-zero
  cargo is requested then meterr is set to that cargo. If an
  illegal signal is requested then ME_PBSIG is set, but if an
  illegal cargo is requested then ME_PBCRG is set. meterr sets to
  ME_PBSRC if a MET signal's source is not the request pipe
  index - 1. ME_PBTIM is returned if a MET signal's time value is
  less than zero. If any broadcast pipe would block on write then
  ME_CLGBP is set, and if the other end of the broadcast or 
  request pipe is closed then ME_BRKBP or ME_BRKRP is set. Any
  SIGCHLD sets ME_CHLD, while SIGINT, SIGHUP, and SIGQUIT set
  ME_INTR. Any other error from a system call sets ME_SYSER.
  If the input arguments are out of range then ME_INTRN is set.
  meterr is set to ME_SYSER if epoll_wait reports that n events
  occurred when only m < n have data for reading and the other
  n - m have no associated errors ; ME_SYSER is also set if an
  unrecognised epoll event is given. ME_INTRN if a broadcast
  fails to write to all broadcast pipes.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- Define block ---*/

/* MET signalling protocol defines several MET signalling states
  that a MET controller can be in at any one time. This provides
  the context for detecting illegal signals and cargos. Note
  that the MET server controller cannot tell the difference
  between the 'stop' and 'wait for mready' states. The following
  are integer codes for each state. */

#define  MSP_WMRSTP  0  // Wait for mready and stop states
#define  MSP_TINITL  1  // Trial initialisation state
#define  MSP_MSTART  2  // Wait for mstart state
#define  MSP_RUN     3  // Run state

#define  MSP_STATES  4  // Number of states

// Error message header
#define  ERMHDR  "metserver:metsigsrv:"

// bufmstart char buffer size
#define  BMSSIZ  256

// MET trial index file's name
#define  MTIXFN  MDIR_HOME_ROOT "/" MDIR_TRIAL


/*--- Macro ---*/

/* If mready has illegal cargo for the current MET signalling
  protocol state, then execute the following. The continue
  statement immediately jumps to next iteration of the MET signal
  checking loop, which breaks because meterr is not ME_NONE */
#define  CRGILL  { \
                   meterr = ME_PBCRG ; \
                   fprintf ( stderr , ERMHDR \
                     " illegal cargo %d ," , crg ) ; \
                   continue ; \
                 }

// Failed to resolve a MET signal
#define  FTRSIG  { \
                   meterr = ME_INTRN ; \
                   fprintf ( stderr , \
                     ERMHDR " failed to resolve" ) ; \
                 }


/*-- CONSTANTS --*/

/* epoll_event structure .events member bit flags */

// epoll event reports error on file descriptor
const uint32_t  EP_ERR  =  EPOLLRDHUP  |  EPOLLERR  |  EPOLLHUP ;

// epoll event reports data available for reading
const uint32_t  EP_DAT  =  EPOLLIN  |  EPOLLPRI ;


// Signalling protocol state names
const char *  PSTATN[] = { "wait-for-mready / stop" ,
  "trial-init." , "wait-for-mstart" , "run" } ;

/*
  Illegal signal lookup table.
  
  Indeces in the first dimension of table is the same as the MET
  signalling protocol state code defined above. The second
  dimension index is same as MET signal identifier. For p and s,
  MSIGIL[ p ][ s ] is 1 if MET signal with identifier s is illegal
  during MET signalling protocol state p, and 0 if it is not.
  
  First dim: 0 - wait mready/stop , 1 - trial init ,
    2 - wait mstart , 3 - run
  
  Second dim: 0 - mnull , 1 - mready , 2 - mstart , 3 - mstop ,
    4 - mwait , 5 - mquit , 6 - mstate , 7 - mtarget ,
    8 - mreward , 9 - mrdtype , 10 - mcalibrate
*/
const unsigned char  MSIGIL[ MSP_STATES ][ MAXMSI + 1 ] =
  {// 0   1   2   3   4   5   6   7   8   9  10
    { 0 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 } , // mready-stop
    { 0 , 0 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 } , // trial init
    { 0 , 1 , 1 , 1 , 0 , 0 , 1 , 1 , 0 , 0 , 0 } , // mstart
    { 0 , 1 , 1 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 }   // run
  } ;

/* Tabulates which signals do NOT trigger MET signalling protocol
  state transitions, for each state (dim 1) and signal (dim 2).
  Hence Met Signal NO TRansition. */
const unsigned char  MSNOTR[ MSP_STATES ][ MAXMSI + 1 ] =
  {// 0   1   2   3   4   5   6   7   8   9  10
    { 1 , 0 , 1 , 1 , 1 , 0 , 1 , 1 , 1 , 1 , 1 } , // mready-stop
    { 1 , 0 , 1 , 1 , 0 , 0 , 1 , 1 , 1 , 1 , 1 } , // trial init
    { 1 , 1 , 0 , 1 , 0 , 0 , 1 , 1 , 1 , 1 , 1 } , // mstart
    { 1 , 1 , 1 , 0 , 0 , 0 , 1 , 1 , 1 , 1 , 1 }   // run 
  } ;

// Signal names
const char *  MSIGNM[] = { MSNNULL , MSNREADY , MSNSTART ,
  MSNSTOP , MSNWAIT , MSNQUIT , MSNSTATE , MSNTARGET ,
  MSNREWARD , MSNRDTYPE , MSNCALIBRATE } ;


/*--- Global variables ---*/

// ~/.met/trials must be constructed by consulting getevn HOME
char  mtfile[ PATH_MAX ] ;


/*--- bufmstart function definition ---*/

/* Reads the current trial index from ~/.met/trial, measures
  the current time, and adds an mstart signal to the MET signal
  pointed to by s. Returns -1 on error or 0 on success. */
static int  bufmstart ( struct metsignal *  s )
{
  
  
  /*-- Variables --*/
  
  // Trial index file pointer
  FILE *  f ;
  
  // Read file contents into char buffer
  char  c[ BMSSIZ ] ;
  
  // Numeric conversion of trial index from string
  unsigned long long int  t ;
  
  // Time measurement
  struct timeval  tv ;
  
  
  /*-- Open trial index file --*/
  
  if  ( ( f = fopen ( mtfile , "r" ) ) == NULL )
  {
    meterr = ME_SYSER ;
    perror ( ERMHDR "fopen" ) ;
    return  -1 ;
  }
  
  
  /*-- Read in trial index --*/
  
  if  ( ( fgets ( c , BMSSIZ , f ) )  ==  NULL )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , ERMHDR "fgets: failed to read %s" ,
      mtfile ) ;
    return  -1 ;
  }
  
  
  /*-- Close trial index file --*/
  
  if  ( fclose ( f )  ==  EOF )
  {
    meterr = ME_SYSER ;
    perror ( ERMHDR "fclose" ) ;
    return  -1 ;
  }
  
  
  /*-- Convert string to numeric value --*/
  
  errno = 0 ;
  t = strtoull( c , NULL , 10 ) ;
  
  if  ( errno )
  {
    meterr = ME_SYSER ;
    perror ( ERMHDR "strtoull" ) ;
    return  -1 ;
  }
  
  
  /*-- Time stamp mstart signal --*/
  
  if  ( gettimeofday ( &tv, NULL )  ==  -1 )
  {
    meterr = ME_SYSER ;
    perror ( ERMHDR "gettimeofday" ) ;
    return  -1 ;
  }
  
  
  /*-- Add mstart to buffer --*/
  
  s->source = MCD_SERVER ;
  s->signal = MSISTART ;
  s->cargo = t ;
  s->time = tv.tv_sec  +  tv.tv_usec / USPERS ;
  
  
  /*-- Return success --*/
  
  return  0 ;
  
  
} // bufmstart


/*--- metsigsrv function definition ---*/

int  metsigsrv ( const unsigned char  c ,
                 const int *  bw , const int *  qr ,
                 const int  epfd , const size_t  awmsig )
{
  
  
  /*-- Buffering and broadcasting variables --*/
  
  // Number of epoll events , and request pipe counter
  int  n , m ;
  
  // Number of buffered signals , and signal index in buffer
  size_t  s = 0 , i ;
  
  // Return value from metgetreq
  ssize_t  sr ;
  
  // Current signal identifier , cargo , and time.
  metsignal_t  sig ;
   metcargo_t  crg ;
  
  // MET signal buffer
  struct metsignal  buf[ awmsig ] ;
  
  /* epoll_event structure array, enough to detect all signals.
    And also an epoll_event structure pointer, for checking
    events. */
  struct epoll_event  e[ c ] , * ep ;
  
  
  /*-- MET signal checking variables --*/
  
  // Current MET signalling protocol state, init wait-for-mready
  unsigned char  ps = MSP_WMRSTP ;
  
  // mready counter and MET controller checklist
  int  rc ;
  unsigned char  chk[ c ] ;
  
  // User's home directory
  char *  hd = getenv ( "HOME" ) ;
  
  
  /*-- Check input --*/
  
  // No home directory environment variable
  if  ( hd  ==  NULL )
  {
    meterr = ME_SYSER ;
    fprintf ( stderr , ERMHDR
      " can't get user's home directory path name\n" ) ;
  }
  
  // Failed to build ~/.met/trials file name
  else if  ( PATH_MAX  <=
             snprintf ( mtfile , PATH_MAX , MTIXFN , hd ) )
  {
    meterr = ME_SYSER ;
    fprintf ( stderr , ERMHDR
      " failed to build MET trials file name\n" ) ;
  }
  
  // c is too big
  else if  ( MAXCHLD  <  c )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , ERMHDR " c > MAXCHLD i.e. %d\n", MAXCHLD ) ;
  }
  
  // epfd uninitialised
  else if  ( epfd  ==  FDINIT )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , ERMHDR " epfd uninitialised\n" ) ;
  }
  
  // awmsig is zero
  else if  ( awmsig  <=  0 )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , ERMHDR " awmsig is 0\n" ) ;
  }
  
  // Pipe file descriptor uninitialised
  for  ( m = 0  ;  m < c  ; ++m )
    
    if  ( bw[ m ]  ==  FDINIT  ||  qr[ m ]  ==  FDINIT )
    {
      meterr = ME_INTRN ;
      fprintf ( stderr , ERMHDR
        " uninitialised broadcast or request pipe\n" ) ;
    }
  
  // Error
  if  ( meterr !=  ME_NONE )
    return  -1 ;
  
  
  /*-- MET signal server --*/
  
  // Reading-writing loop , breaks on error
  while  ( meterr == ME_NONE )
  {
    
    // Reset epoll event structure pointer
    ep = e ;
    
    
    /* Block on events */
    
    if  ( ( n = epoll_wait( epfd , e , c , MSERVT ) )  ==  -1 )
      
      // System level error other than signal interruption
      if  ( errno  !=  EINTR )
      {
        meterr = ME_SYSER ;
        perror ( ERMHDR "epoll_wait" ) ;
      }
      // EINTR, so no epoll events are ready yet
      else  n = 0 ;
    
    
    /* Check UNIX signal flags */
    
    CHKSIGFLG ( FLGCHLD || FLGINT )
    
    
    /* Check epoll events */
    
    // epoll events
    for  ( i = m = 0 ; meterr == ME_NONE  &&  i < n ; ++i )
      
      // Error on request pipe file descriptor
      if  ( e[ i ].events  &  EP_ERR )
      {
        meterr = ME_BRKRP ;
        fprintf ( stderr , ERMHDR
          " error on MET controller %d request pipe\n" ,
          findcd ( c , qr , e[ i ].data.fd ) ) ;
      }
      
      // Data ready, count one more
      else if  ( e[ i ].events  &  EP_DAT )
        ++m ;
      
      // Unrecognised event
      else
      {
        meterr = ME_SYSER ;
        fprintf ( stderr , ERMHDR " unrecognised "
          "event on MET controller %d request pipe\n" ,
          findcd ( c , qr , e[ i ].data.fd ) ) ;
      }
    
    // Make sure that as much data is ready as was reported
    if  ( meterr == ME_NONE  &&  m < n )
    {
      meterr = ME_SYSER ;
      fprintf ( stderr , ERMHDR
        " %d request pipe events reported but %d have data\n" ,
        n , m ) ;
    }
    
    
    /* Read and broadcast MET signals */
    
    while  ( meterr == ME_NONE  &&  n )
    {
      
      /* Buffer requested MET signals. 1 less than awmsig
        guarantees space for mstart, if required. */
      sr =
        metgetreq ( n , &m , ep , buf , awmsig - s - 1 , qr , c ) ;
      
      if  ( sr  ==  -1 )  
      {
        fprintf ( stderr , ERMHDR " metgetreq error\n" ) ;
        break ;
      }
      
      /* Adjust number of buffered signals, pipes to read,
        and epoll event pointer position. */
       s += sr ;
       n -=  m ;
      ep +=  m ;
      
      // Pipes to read and space in buffer, read again
      if  ( n  &&  s < awmsig - 1 )  continue ;
      
      // Check signals
      for  ( i = 0  ;  meterr == ME_NONE  &&  i < s  ;  ++i )
      {
        
        // Grab MET signal identifier and cargo
        sig = buf[ i ].signal ;
        crg = buf[ i ].cargo ;
        
        // Illegal signal in this MET signalling protocol state
        if  ( MSIGIL[ ps ][ sig ] )
        {
          meterr = ME_PBSIG ;
          fprintf ( stderr , ERMHDR " illegal" ) ;
        }
        
        /* If this signal is NOT associated with a MET
          signalling protocol state transition then check the next
          signal */
        else if  ( MSNOTR[ ps ][ sig ] )
          continue ;
        
        /* Now handle MET signalling protocol state transitions */
        
        // mquit
        else if  ( sig  ==  MSIQUIT )
        {
          // MET child controller quit with error , set meterr
          if  ( crg  !=  ME_NONE )  meterr = crg ;
          
          // Break nested loops
          goto  mquit_break ;
        }
        
        // run state
        else if  ( ps  ==  MSP_RUN )
        {
          // mstop signal or mwait with abort cargo
          if  (  sig == MSISTOP  ||
               ( sig == MSIWAIT  &&  crg == MWAIT_ABORT ) )
            
            // Back to wait-for-mready / stop state
            ps = MSP_WMRSTP ;
        }
        
        // trial init or wait-for-mstart state, and mwait signal
        else if  ( sig == MSIWAIT  &&
                   ( ps == MSP_TINITL  ||  ps == MSP_MSTART ) )
          
          // Back to wait-for-mready / stop
          ps = MSP_WMRSTP ;
        
        // mready signal
        else if  ( sig  ==  MSIREADY )
        {
          
          // Currently in wait-for-mready state
          if  ( ps  ==  MSP_WMRSTP )
          {
            
            // Check illegal cargo , next loop if found
            if  ( crg  !=  MREADY_TRIGGER )
              CRGILL
            
            // Transition to trial-init state
            ps = MSP_TINITL ;
            
            // Initialise mready counters
            rc = 0 ;
            for  ( m = 0 ; m < c ; ++m )  chk[ m ] = 0 ;
            
          } // wait-for-mready
          
          // Currently trial-init
          else if  ( ps  ==  MSP_TINITL )
          {
            
            // Check for illegal cargo , next loop if found
            if  ( crg  !=  MREADY_REPLY )
              CRGILL
            
            // Convert controller descriptor to index
            m = buf[ i ].source - 1 ;
            
            // Has MET child controller duplicated mready?
            if  ( chk[ m ] )
            {
              meterr = ME_PBSIG ;
              fprintf ( stderr , ERMHDR " duplicate" ) ;
              continue ;
            }
            
            // Mark down mready for this MET controller
            chk[ m ] = 1 ;
            
            /* Count another mready signal. Advance to the
              next buffered MET signal if there are still mready
              signals to wait for. */
            if  ( ++rc  <  c )  continue ;
            
            // All mready received, to wait-for-mstart state
            ps = MSP_MSTART ;
            
            // Add mstart signal to the end of the buffer
            if  ( bufmstart ( buf + s )  ==  -1 )  continue ;
            
          } // trial-init
          
          // Something went terribly wrong
          else  FTRSIG
          
        } // mready
                
        // Something went terribly wrong
        else  FTRSIG
      
      } // check signals
      
      
      // Signal check detected an error, complete message
      if  ( meterr  !=  ME_NONE )
      {
        /* i increments on each iteration of MET signal check loop,
          including before the loop breaks on error */
        --i ;
        fprintf ( stderr ,
          " signal %d %s from controller %d in %s state\n" ,
          sig , MSIGNM[ sig ] , buf[ i ].source , PSTATN[ ps ] ) ;
        break ;
      }
      
      // Broadcast MET signals
      m = metbroadcast ( c , bw , buf , s + (ps == MSP_MSTART) ) ;
      
      if  ( m  ==  -1 )
        
        fprintf ( stderr , ERMHDR " metbroadcast error" ) ;
        
      else if  ( m  <  c )
      {
        meterr = ME_INTRN ;
        fprintf ( stderr , ERMHDR
          " only %d broadcast pipes of %d were written to\n" ,
          m , c ) ;
      }
      
      else
      {
        // No broadcasting error. Empty the MET signal buffer.
        s = 0 ;
        
        // Currently in wait-for-mstart state
        if  ( ps  ==  MSP_MSTART )
          
          // mstart was just broadcast, transition to run state
          ps = MSP_RUN ;
      }
      
    } // read-broadcast
    
    
  } // read-write
  
  // mquit encountered, jumps here
  mquit_break:
  
  
  /*-- Return value --*/
  
  return  meterr == ME_NONE  ?  0  :  -1  ;
  
  
} // metsigsrv


