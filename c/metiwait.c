
/*  metiwait.c
  
  int  metiwait ( const unsigned char  n , const int  epfd ,
                  const int *  qr )
  
  MET initialisation wait, waits for n mready signals with cargo
  2. Only one signal from each MET child controller is allowed,
  hence only one signal may be transmitted by each request pipe.
  qr is the array of n request pipes, provided in the same order
  as MET child controller descriptors i.e. for ith element of qr,
  the corresponding controller descriptor is i + 1. The event poll
  file descriptor fd must be initialised to indicate when any
  request pipe in qr is ready to read from.
  
  n must not exceed MAXCHLD or be zero, and neither epfd nor any
  element of qr may be set to FDINIT.
  
  Returns the number of mready signals that were received. Returns
  -1 on error and sets meterr to ME_INTRN if any input value is
  out of range. meterr is set to ME_BRKRP if the write end of any
  request pipe is closed. If the event poll times out while waiting
  then meterr is set to ME_TMOUT. If any child controller produces
  more than one mready signal or requests any other signal then
  meterr is ME_PBSIG. If any signal cargo is not 2 i.e. an mready
  reply then meterr is ME_PBCRG. If a signal claims a different
  controller descriptor source from the controller of origin then
  meterr is ME_PBSRC. For any other system call error, meterr is
  set to ME_SYSER.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- metiwait function definition ---*/

int  metiwait ( const unsigned char  n , const int  epfd ,
                const int *  qr )
{
  
  
  /*-- Variables, known at compile time --*/
  
  /* Generic counter , mready counter , num epoll events ,
    events checked */
  int  i , c = 0 , ne , nec ;
  
  // Number of signals read
  ssize_t  s ;
  
  
  /*-- Check input --*/
  
  // n is too big
  if  ( !n  ||  MAXCHLD < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metiwait: "
      "n %d out of range 1 to %d\n" ,
      n , MAXCHLD ) ;
  }
  
  // epoll file descriptor is uninitialised
  if  ( epfd  ==  FDINIT )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr , "metserver:metiwait: "
      "epfd not assigned i.e. it is FDINIT %d\n" ,
      FDINIT ) ;
  }
  
  // Input arrays
  for  ( i = 0  ;  meterr == ME_NONE  &&  i < n  ;  ++i )
    
    // Check whether request pipe fd's not initialised
    if  ( qr[ i ] == FDINIT )
    {
      fprintf ( stderr , "metserver:metiwait: "
        "file descriptor %d not assigned i.e. it is FDINIT %d\n" ,
        i , FDINIT ) ;
      meterr = ME_INTRN ;
    }
  
  // Quit on error
  if  ( meterr != ME_NONE )
    return  -1 ;
  
  
  /*-- Variables, known at run time --*/
  
  // MET signal buffer
  struct metsignal  buf[ n ] ;
  
  // epoll_event structure array, enough to detect all signals
  struct epoll_event  e[ n ] ;
  
  /* mready received checklist. Initialised to 0 for not received.
    Set to fd of source request pipe when received. If i is the
    value of the mready signal's source, then the i - 1 element
    is set. */
  char  chk[ n ] ;
  for  ( i = 0 ; i < n ; ++i )
    chk[ i ] = 0 ;
  
  
  /*-- Wait for mready signals --*/
  
  while  ( meterr == ME_NONE  &&  c < n )
  {
    
    // Block on signal request pipes
    ne = epoll_wait ( epfd , e , n , MIWAIT ) ;
    
    // Timeout, ne is zero
    if  ( !ne )
    {
      meterr = ME_TMOUT ;
      fprintf ( stderr ,
        "metserver:metiwait: initial %d mready time out\n" , c ) ;
      break ;
    }
    
    // Error check
    else if  ( ne == -1 )
    {
      // Signal interruption, try again 
      if  ( errno == EINTR )
      {
        // UNIX signal flag check
        CHKSIGFLG ( FLGCHLD || FLGINT )
        continue ;
      }
      
      // Other system error
      meterr = ME_SYSER ;
      perror ( "metserver:metiwait:epoll_wait" ) ;
      break ;
    }
    
    // Check for broken IPC
    for  ( i = 0 ; i < ne ; ++i )
      if  ( e[ i ].events  &  EPOLLHUP )
      {
        meterr = ME_BRKRP ;
        fprintf ( stderr , "metserver:metiwait: "
          "broken request pipe\n" ) ;
        return  -1 ;
      }
    
    // Read signals
    s = metgetreq ( ne , &nec , e , buf , n , qr , n ) ;
    
    // Error check
    if  ( s == -1 )
      break ;
    
    // Buffer full but not all fd's read, too many signals
    else if  ( s == n  &&  nec < ne )
    {
      meterr = ME_PBSIG ;
      fprintf ( stderr , "metserver:metiwait: "
        "more than %ld signals produced on %d request pipes\n" ,
        (long) s , n ) ;
      break ;
    }
    
    // Check each signal
    while  ( s-- )
    {
      // Must be mready
      if  ( buf[ s ].signal  !=  MSIREADY )
      {
        meterr = ME_PBSIG ;
        fprintf ( stderr , "metserver:metiwait: "
          "MET controller %d signal id %d not mready %d\n" ,
          buf[ s ].source , buf[ s ].signal , MSIREADY ) ;
        break ;
      }
      
      // mready cargo must be reply, not trigger
      else if  ( buf[ s ].cargo  !=  MREADY_REPLY )
      {
        meterr = ME_PBCRG ;
        fprintf ( stderr , "metserver:metiwait: "
          "MET controller %d cargo %d not reply %d\n" ,
          buf[ s ].source , buf[ s ].cargo , MREADY_REPLY ) ;
        break ;
      }
      
      // Controller descriptor to pipe array index
      i = buf[ s ].source - 1 ;
      
      // Check if MET controller mready received yet
      if  ( chk[ i ] )
      {
        // It has been, this is a duplicate
        meterr = ME_PBSIG ;
        fprintf ( stderr , "metserver:metiwait: "
          "MET controller %d duplicate mready\n" ,
          buf[ s ].source ) ;
        break ;
      }
      
      // Valid mready signal
      else
      {
        // Remember which MET controller sent it
        chk[ i ] = 1 ;
        
        // And count one more
        ++c ;
      }
      
    } // check signals
    
    // Check UNIX signal flags
    CHKSIGFLG( FLGCHLD || FLGINT )
    
  } // mready wait loop
  
  
  /*-- Return value --*/
  
  return  meterr == ME_NONE  ?  c  :  -1  ;
  
  
} // metiwait


