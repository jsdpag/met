
/*  metxshmblk.c
  
  signed char  metxshmblk ( const mxArray *  shm , char *  bm )
  
  Returns the array index of the POSIX shared memory named in shm. The
  blocking mode is returned in bm as either '+' to indicate blocking, and
  '-' to indicate non-blocking. On error, returns -1.
  
  Array index - POSIX shared memory name
            0 - 'stim'
            1 - 'eye'
            2 - 'nsp'
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:shm: "

#define  BUFLEN  6


/*--- metxshmblk function definition ---*/

signed char  metxshmblk ( const mxArray *  shm , char *  bm )
{
  
  
  /*-- Constants --*/
  
  char *  SHMNAM[ SHMARG ] = { SNAM_STIM , SNAM_EYE , SNAM_NSP } ;
  
  
  /*-- Variables --*/
  
  /* Input string buffer and pointer */
  char  buf[ BUFLEN ] , * p ;
  
  /* Return value */
  signed char  r ;
  
  
  /*-- Get shared memory name --*/
  
  if  ( mxGetString ( shm , buf , BUFLEN ) )
    
    return  -1 ;
  
  
  /*-- Determine blocking mode and head of shared mem name --*/
  
  /* Set p to first char past possible '-' or '+' prefix character */
  p = buf + 1 ;

  /* Determine blocking mode */
  if  ( buf[ 0 ]  ==  SCHBLOCK )

    /* Blocking char */
    *bm = SCHBLOCK ;

  else
  {
    /* Non-blocking char */
    *bm = SCHNOBLK ;
    
    /* Non-blocking , but no prefix char */
    if  ( buf[ 0 ]  !=  SCHNOBLK )
      --p ;
  }
  
  
  /*-- Find shared memory index and blocking mode --*/
  
  for  ( r = 0 ; r  <  SHMARG ; ++r )
    
    /* Check shared mem name */
    if  ( !strcmp ( SHMNAM[ r ] , p ) )
      
      /* Name found! Return index and blocking mode */
      return  r ;
  
  
  /*-- ERROR: input unrecognised --*/
  
  return  -1 ;
  
  
} /* metxshmblk */

