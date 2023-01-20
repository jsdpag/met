
/*  metgetreq.c
  
  ssize_t  metgetreq ( const int  n ,
                       int  * m ,
                       const struct epoll_event *  e , 
                       void *  buf ,
                       size_t  ns ,
                       const int *  qr ,
                       const unsigned char  np )
  
  Reads at most ns MET signals into buffer buf from the request
  pipe file descriptors listed in e. The first n elements of e will
  be checked sequentially for fd's that are ready for reading (i.e.
  e[ i ].events bitwise-AND with EPOLLIN), and only those will be
  read from into buf. qr is a set of np request pipe file
  descriptors such that the ith pipe is associated with MET
  controller descriptor i + 1 ; this is used to check the source
  field of each signal against the pipe that delivered it.
  Aborts on error.
  
  n and np must not exceed MAXCHLD, and n <= np. No element of qr
  may be -1.
  
  Returns the number of signals that were received, and places the
  number of file descriptors that were checked into the int
  pointed at by m.
  
  Returns -1 on error and sets meterr to ME_INTRN if n exceeds
  MAXCHLD. meterr is set to ME_PBSIG if a given request pipe only
  delivers a fraction of a MET signal ; this is defined as the
  case where a pipe is read and a fraction of a signal is
  returned, followed by another read from the same pipe that fails
  with error EAGAIN i.e. the read would block for lack of data.
  If the source member of a signal claims a controller descriptor
  that is not associated with the request pipe that delivered the
  signal then meterr is set to ME_PBSRC ; meterr is ME_PCSRC if
  it is ever the MET server controller descriptor or greater than
  the maximum controller descriptor i.e. np. On the other hand, if
  a MET signal identifier is greater than the maximum then meterr
  is set to ME_PBSIG. If the write end of a request pipe is closed
  then meterr is set to ME_BRKRP. meterr is set to ME_SYSER for
  any error during a system call. On error, *m is not guaranteed
  to receive any particular value.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "metsrv.h"


/*--- metgetreq function definition ---*/

ssize_t  metgetreq ( const int  n ,
                     int  * m ,
                     const struct epoll_event *  e , 
                     void *  buf ,
                     size_t  ns ,
                     const int *  qr ,
                     const unsigned char  np )
{
  
  
  /*-- Constants --*/
  
  // Signal names
  const char *  MSIGNM[] = { MSNNULL , MSNREADY , MSNSTART ,
    MSNSTOP , MSNWAIT , MSNQUIT , MSNSTATE , MSNTARGET ,
    MSNREWARD , MSNRDTYPE , MSNCALIBRATE } ;
  
  // Minimum and maximum allowable cargo values
  const metcargo_t  CRGMIN[ MAXMSI + 1 ] =
    { MIN_MNULL , MIN_MREADY , MIN_MSTART , MIN_MSTOP ,
      MIN_MWAIT , MIN_MQUIT , MIN_MSTATE , MIN_MTARGET ,
      MIN_MREWARD , MIN_MRDTYPE , MIN_MCALIBRATE } ;

  const metcargo_t  CRGMAX[ MAXMSI + 1 ] =
    { MAX_MNULL , MAX_MREADY , MAX_MSTART , MAX_MSTOP ,
      MAX_MWAIT , MAX_MQUIT , MAX_MSTATE , MAX_MTARGET ,
      MAX_MREWARD , MAX_MRDTYPE , MAX_MCALIBRATE } ;
  
  
  /*-- Variables --*/
  
  // char buffer pointer
  char *  p = buf ;
  
  // MET signal buffer pointer
  struct metsignal *  s = buf ;
  
  // MET signal source controller descriptor
  metsource_t  cd ;
  
  // MET signal identifier
  metsignal_t  sid ;
  
  // MET signal cargo
  metcargo_t  crg ;
  
  // MET signal time
  mettime_t  tim ;
  
  // Number of bytes of space in buffer
  size_t  nb = ns * sizeof ( struct metsignal ) ;
  
  // Number of bytes of a signal received in a fractional read
  size_t  frac = 0 ;
  
  /* Return value from read, number of signals from latest read,
    and number of signals read in total. */
  ssize_t  r , nr , nrt = 0 ;
  
  
  /*-- Check input --*/
  
  // n is too big
  if  ( MAXCHLD < n  ||  MAXCHLD < np  ||  np < n )
  {
    meterr = ME_INTRN ;
    fprintf ( stderr ,
      "metgetreq: n or np > MAXCHLD i.e. %d or np < n\n" ,
      MAXCHLD ) ;
    return  -1 ;
  }
  
  
  /*-- Receive MET signal requests --*/
  
  // Check each req pipe if space in buffer and no error
  for  ( *m = 0 ;
         meterr == ME_NONE  &&  nb  &&  *m < n ;
         ++( *m ) )
  {
    // Can't read from file descriptor, go to next
    if  ( !( e[ *m ].events  &  EPOLLIN ) )
      continue ;
    
    // Read loop, if space in buf and no EOF (i.e. 0) returned
    while  ( nb  &&  ( r = read ( e[ *m ].data.fd , p , nb ) ) )
    {
      
      // Error checking
      if  ( r == -1 )
      {
        // Signal interruption, try again
        if  ( errno == EINTR )
        {
          // UNIX signal flag check
          CHKSIGFLG ( FLGCHLD || FLGINT )
          if  ( meterr == ME_NONE )  continue ;
        }
        
        // No data in pipe on a non-blocking read
        else if  ( errno == EAGAIN   ||
                   errno == EWOULDBLOCK )
        {
          // Fractional read error, breach of MET sig protocol
          if  ( frac )
          {
            meterr = ME_PBSIG ;
            fprintf ( stderr ,
              "metgetreq: fractional read from request pipe %d\n" ,
              e[ *m ].data.fd ) ;
          }
        }
        
        // Unrecognised system error
        else
        {
          meterr = ME_SYSER ;
          perror ( "metgetreq:read" ) ;
        }
        
      } // error checking
      
      // Otherwise, data was read
      else
      {
        
        
        // Count signals from latest read
        nr = ( r + frac )  /  sizeof ( struct metsignal ) ;
        
        // Count total signals read
        nrt += nr ;
        
        
        // Check source and identifier of each signal
        while  ( nr-- )
        {
          /* Get MET signal's controller descriptor i.e. source,
            signal identifier, cargo, and time. Advance pointer
            after getting time. */
           cd = s->source ;
          sid = s->signal ;
          crg = s->cargo ;
          tim = ( s++ )->time ;
          
          // Not allowed to be MET server controller
          if  ( cd == MCD_SERVER )
            fprintf ( stderr ,
              "metgetreq: MET controller %d "
              "illegal source MCD_SERVER i.e. %d\n" ,
              findcd ( np , qr , e[ *m ].data.fd ) ,
              MCD_SERVER ) ;
              
          // Source too big
          else if  ( np < cd )
            fprintf ( stderr ,
              "metgetreq: MET controller %d "
              "msig source %d too big i.e. > %d\n" ,
              findcd ( np , qr , e[ *m ].data.fd ) ,
              cd , np ) ;
          
          // Check that signal source is same as MET controller
          else if  ( qr[ cd - 1 ]  !=  e[ *m ].data.fd )
          {
            // Is this because pipe fd is still FDINIT?
            if  ( qr[ cd - 1 ] == FDINIT )
            {
              meterr = ME_INTRN ;
              fprintf ( stderr ,
                "metgetreq: qr[ %d ] is uninitialised\n" ,
                cd - 1 ) ;
            }
            // Signal source is wrong
            else
              fprintf ( stderr ,
                "metgetreq: MET controller %d "
                "incorrect msig source %d\n" ,
                findcd ( np , qr , e[ *m ].data.fd ) , cd ) ;
          }
              
          // Signal identifier too big
          else if  ( MAXMSI < sid )
          {
            meterr = ME_PBSIG ;
            fprintf ( stderr , "metgetreq: MET controller %d "
              "msig identifier %d > MAXMSI i.e. %d\n" ,
              cd , sid , MAXMSI ) ;
          }
          
          // Cargo out of range
          else if  ( crg < CRGMIN[ sid ]  ||  crg > CRGMAX[ sid ] )
          {
            meterr = ME_PBCRG ;
            fprintf ( stderr , "metgetreq: MET controller %d " 
              "msig %s cargo %d out of range %d to %d\n" ,
              cd , MSIGNM[ sid ] , crg ,
              CRGMIN[ sid ] , CRGMAX[ sid ] ) ;
          }
          
          // Time out of range
          else if  ( tim < MIN_MSTIME  ||  tim > MAX_MSTIME )
          {
            meterr = ME_PBTIM ;
            fprintf ( stderr , "metgetreq: MET controller %d "
              "msig %s time " MST2STR " out of range " MST2STR
              " to " MST2STR "\n" ,
              cd , MSIGNM[ sid ] , tim ,
              MIN_MSTIME , MAX_MSTIME ) ;
          }
          
          // No error
          else
            continue ;
            
          // Error detected, set meterr
          meterr =  meterr == ME_NONE  ?  ME_PBSRC  :  meterr ;
          break ;
          
        } // check signal source
        
        
        // Advance pointer
        p += r ;
        
        // Account for filled space in buffer
        nb -= r ;
        
        // Check for fractional read, number bytes read
        frac = ( r + frac )  %  sizeof ( struct metsignal ) ;
        
        
      } // data read
      
      
      // Break read loop if whole signals were read, or on error
      if  ( !frac  ||  meterr != ME_NONE )
        break ;
      
      
    } // read loop
    
    
    // Broken request pipe
    if  ( r == READ_EOF )
    {
      meterr = ME_BRKRP ;
      fprintf ( stderr , "metgetreq: request pipe %d broken\n" ,
        e[ *m ].data.fd ) ;
    }
    
    
  } // file descriptors
  
  
  /*-- Return value --*/
  
  return  meterr == ME_NONE  ?  nrt  :  -1 ;
  
  
} // metgetreq


