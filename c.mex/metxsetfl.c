
/*  metxsetfl.c
  
  void  metxsetfl ( struct met_t *  RTC , unsigned char  n ,
                    int *  fd , int *  fl , char  m ,
                    char *  e )
  
  Used to set the non-blocking bit of n flags fl for n file descriptors fd.
  The blocking mode is given in m as a single char, 'b' for blocking and
  'n' for non-blocking. The error message in e is printed if fcntl returns
  an error. The run-time constants must be provided in RTC for error
  handling.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:metxsetfl: "


/*--- metxsetfl function definition ---*/

void  metxsetfl ( struct met_t *  RTC , unsigned char  n ,
                  int *  fd , int *  fl , char  m ,
                  char *  e )
{
  
  
  /*-- Check input --*/
  
  if  ( m  !=  'b'  &&  m  !=  'n' )
  {
    RTC->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:metxsetfl:mode" , ERRHDR
      "'%c' is not a valid mode char for arg m" , RTC->cd , m ) ;
  }
  
  
  /*-- Variables --*/
  
  /* Counter */
  unsigned char  i ;
  
  
  /*-- Set flags --*/
  
  for  ( i = 0 ; i  <  n ; ++i )
  {
    
    /* Skip uninitialised file descriptors */
    if  ( fd[ i ]  ==  FDINIT )  continue ;
    
    /* Blocking mode flag */
    switch  ( m )
    {
      /* Set flag to blocking */
      case  'b':  fl[ i ]  &=  ~O_NONBLOCK  ;
                  break ;

      /* Set flag to non-blocking */
      case  'n':  fl[ i ]  |=   O_NONBLOCK  ;
    }
    
    /* Apply flag to file descriptor */
    if  ( fcntl ( fd[ i ] , F_SETFL , fl[ i ] )  ==  -1 )
    {
      RTC->quit = ME_SYSER ;
      perror ( "met:metxsetfl:fcntl" ) ;
      mexErrMsgIdAndTxt ( "MET:metxsetfl:fcntl" , ERRHDR "%s" ,
        RTC->cd , e ) ;
    }
    
  } /* n fd's */
  
  
} /* metxsetfl */

