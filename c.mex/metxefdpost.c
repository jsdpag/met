
/*  metxefdpost.c
  
  int  metxefdpost ( struct met_t *  RTC ,
                     const unsigned char  n , const int *  efd , 
                     uint64_t  v )
  
  Attempts to post the value v to n event file descriptors listed in efd.
  Run-time constants are handed in RTC for error handling.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:metxefdread: "

#define  SUCCESS  0
#define  FAILURE  1


/*--- metxefdpost function definition ---*/

int  metxefdpost ( struct met_t *  RTC ,
                   const unsigned char  n , const int *  efd , 
                   uint64_t  v )
{
  
  /*-- Variables --*/
  
  /* Counter */
  unsigned char  i ;
  
  /* Byte pointer */
  char *  p ;
  
  /* Number of bytes */
  size_t  b ;
  
  /* write() return value */
  ssize_t  r ;
  
  
  /*-- Write loop --*/
  
  /* Event file descriptors */
  for  ( i = 0 ; i  <  n ; ++i )
  {
    
    /* Skip uninitialised efd */
    if  ( efd[ i ]  ==  FDINIT )  continue ;
    
    /* Initialise pointer and byte number */
    p = ( char * )  &v ;  b = sizeof ( v ) ;
    
    
    /* Post to efd */
    while  (  b  &&  ( r = write ( efd[ i ] , p , b ) )  )
    {
      /* Error check */
      if  ( r  ==  -1 )
      {
        /* UNIX signal interruption , try again */
        if  ( errno  ==  EINTR )  continue ;

        /* Another error , print system error message */
        perror ( "met:metxefdpost:write" ) ;

        /* MET error handling */
        if  ( errno  ==  EAGAIN  ||  errno  ==  EWOULDBLOCK )
        {
          RTC->quit = ME_INTRN ;
          fprintf ( stderr , ERRHDR "event fd counter overrun" ,
            RTC->cd ) ;
        }
        else if  ( errno  ==  EINVAL )
        {
          RTC->quit = ME_INTRN ;
          fprintf ( stderr , ERRHDR
           "attempted posting 0xffffffffffffffff to event fd" , RTC->cd ) ;
        }
        else
        {
          RTC->quit = ME_SYSER ;
          fprintf ( stderr , ERRHDR
            "error writing to event fd" , RTC->cd ) ;
        }
        
        /* Return failure code */
        return  FAILURE ;

      } /* error */

      /* Update counters */
      b -= r ;
      p += r ;
      
    } /* post */
    
  } /* efd's */
  
  
  /*-- Return success code --*/
  
  return  SUCCESS ;
  
  
} /* metxefdpost */

