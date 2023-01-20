
/*  metxclose.c
  
  met ( 'close' )
  met ( 'close' , keep )
  
  Attempts to close any sytem resources used by met. This includes the
  broadcast and request pipe file descriptors, mapped POSIX shared memory,
  event file descriptors, and any open log file. An optional scalar numeric
  value can be provided in keep which, if non-zero, keeps the file
  descriptors open ; only the POSIX shared memory is unmapped, and the log
  file is closed. The field values of RTCONS are reset as resources are
  closed. Memory is freed, pointers are made NULL, and file descriptors are
  made FDINIT. Before closing the request pipe, an mquit signal is sent
  with cargo set to the run-time constant RTCONS.quit.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHD1  "met:close: "
#define  ERRHDR  MCSTR ":" ERRHD1

#define  NLHS  0
#define  NRHS_MIN  0
#define  NRHS_MAX  1

/* Number of event file descriptor vectors */
#define  NEFDV  2


/*--- fdclose function  ---*/

static void  fdclose ( int  fd , char *  e , struct met_t *  RTC )
{
  
  while  ( close ( fd )  ==  -1 )
  
    /* Error other than UNIX signal interruption */
    if  ( errno  !=  EINTR )
    {
      RTC->quit = ME_SYSER ;
      perror ( "met:close:close" ) ;
      mexWarnMsgIdAndTxt ( "MET:close:fd" , ERRHDR "%s" , RTC->cd , e ) ;
    }
  
} /* fdclose */


/*--- metxclose function definition ---*/

void  metxclose ( struct met_t *  RTCONS ,
                  int  nlhs ,       mxArray *  plhs[] ,
                  int  nrhs , const mxArray *  prhs[] )
{
  
  
  /*-- Check input arguments --*/
  
  /* met hasn't been opened */
  if  ( RTCONS->init  ==  MET_UNINIT )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:close:init" , ERRHD1
      "met not open , must first open" ) ;
  }
  
  /* Number of outputs */
  if  ( nlhs  !=  NLHS )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:close:nlhs" , ERRHDR
      "no output arg" , RTCONS->cd ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs  <  NRHS_MIN  ||  NRHS_MAX  <  nrhs )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:close:nrhs" , ERRHDR
      "takes %d to %d input args , %d given" ,
      RTCONS->cd , NRHS_MIN , NRHS_MAX , nrhs ) ;
  }
  
  /* Optional input keep */
  if  (  nrhs  ==  NRHS_MAX  &&
       ( mxGetNumberOfElements ( prhs[ 0 ] )  !=  1  ||
         !mxIsDouble ( prhs[ 0 ] ) )  )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:close:keep" , ERRHDR
      "keep must be scalar double" , RTCONS->cd ) ;
  }
  
  
  /*-- Variables --*/
  
  /* Generic counters */
  int  i , j ;
  
  /* arg keep */
  double  keep = 0 ;
  
  /* pointer array to event file descriptors */
  int *  efd[ NEFDV ] = { RTCONS->refd , RTCONS->wefd } ;
  
  /* mquit MET signal and pointer , time measurement , bytes to write, and
    return value */
  struct metsignal  s = { RTCONS->cd , MSIQUIT , RTCONS->quit , 0 } ;
  char *  sp = (char *)  &s ;
  struct timeval  tv ;
  size_t  w = sizeof ( s ) ;
  ssize_t  r ;
  
  
  /*-- Get value of keep --*/
  
  if  ( nrhs  ==  NRHS_MAX )
    keep = mxGetScalar ( prhs[ 0 ] ) ;
  
  
  /*-- Unmap POSIX shared memory --*/
  
  /* Loop each shm object */
  for  ( i = 0 ; i  <  SHMARG ; ++i )
    
    /* Attempt to unmap */
    if  ( RTCONS->shmmap[ i ]  !=  NULL  &&
          munmap ( RTCONS->shmmap[ i ] , RTCONS->shmsiz[ i ] )  ==  -1 )
    {
      RTCONS->quit = ME_SYSER ;
      perror ( "met:close:munmap" ) ;
      mexWarnMsgIdAndTxt ( "MET:close:shm" , ERRHDR
        "error unmapping POSIX shared memory" , RTCONS->cd ) ;
    }
    else
    {
      RTCONS->shmmap[ i ] = NULL ;
      RTCONS->shmsiz[ i ] = 0 ;
    }
  
  
  /*-- Close log file --*/
  
  if  ( RTCONS->logfile  !=  NULL  &&
        fclose ( RTCONS->logfile )  ==  EOF )
  {
    RTCONS->quit = ME_SYSER ;
    perror ( "met:close:fclose" ) ;
    mexWarnMsgIdAndTxt ( "MET:close:log" , ERRHDR
      "error closing log file" , RTCONS->cd ) ;
  }
  else
    RTCONS->logfile = NULL ;
  
  
  /*-- Lower init flag --*/
  
  RTCONS->init  =  MET_UNINIT ;
  
  
  /*-- Keep open file descriptors --*/
  
  if  ( keep )  return ;
  
  
  /*-- Close event file descriptors --*/
  
  /* Loop readers' and writer's efd's ... */
  for  ( i = 0 ; i  <  NEFDV ; ++i )
  
    /* ... and then shared memory objects */
    for  ( j = 0 ; j  <  SHMARG ; ++j )
    {
      /* Not assigned , continue to next fd */
      if  ( efd[ i ][ j ]  ==  FDINIT )  continue ;
      
      /* Attempt close */
      fdclose ( efd[ i ][ j ] , "error closing event fd" , RTCONS ) ;
      
      /* Success , reset efd value */
      efd[ i ][ j ] = FDINIT ;
    }
  
  /* Writer's efd's for other MET controllers */
  for  ( i = 0 ; i  <  SHMARG ; ++i )
  {
    /* MET controller didn't write, so list wasn't initialised */
    if  (  RTCONS->shmflg[ i ]  !=  MSMG_WRITE  &&
           RTCONS->shmflg[ i ]  !=  MSMG_BOTH  )
      continue ;
    
    /* Check each efd in list */
    for  ( j = 0 ; j  <  RTCONS->wefdn[ i ] ; ++j )
    {
      /* Uninitialised efd. Or MET controller was reader and writer ; its
         writer's efd was closed above using efd. */
      if  (  RTCONS->wefdv[ i ][ j ]  ==  FDINIT  ||
           ( RTCONS->shmflg[ i ]  ==  MSMG_BOTH  &&
             RTCONS->cd - 1  ==  j )  )
        continue ;
      
      /* Close event fd */
      fdclose ( RTCONS->wefdv[ i ][ j ] ,
        "error closing writer's event fd" , RTCONS ) ;
      
      /* Reset efd and flag to initialisation value */
      RTCONS->wefdv[ i ][ j ] = FDINIT ;
      RTCONS->wflgv[ i ][ j ] = FDSINIT ;
      
    } /* efd's */
  } /* shm's */
  
  /* Free writer's event fd list memory */
  for  ( i = 0 ; i  <  SHMARG ; ++i )
  {
    if  ( RTCONS->wefdv[ i ]  !=  NULL )
      { free ( RTCONS->wefdv[ i ] ) ;  RTCONS->wefdv[ i ] = NULL ; }
    if  ( RTCONS->wflgv[ i ]  !=  NULL )
      { free ( RTCONS->wflgv[ i ] ) ;  RTCONS->wflgv[ i ] = NULL ; }
  }
  
  
  /*-- Free fd arrays , for select() --*/
  
  free ( RTCONS->fd   ) ;
  free ( RTCONS->fdio ) ;
  free ( RTCONS->fdsi ) ;
  
  
  /*-- Attempt to send mquit signal --*/
  
  /* Time measurement */
  if  ( gettimeofday ( &tv , NULL )  ==  -1 )
  {
    RTCONS->quit = ME_SYSER ;
    perror ( "met:close:gettimeofday" ) ;
    mexWarnMsgIdAndTxt ( "MET:close:tv" , ERRHDR
      "error getting time measurement" , RTCONS->cd ) ;
  }
  
  else
    s.time = tv.tv_sec  +  tv.tv_usec / USPERS ;
  
  /* Send signal */
  while  ( w  &&  ( r = write ( RTCONS->p[ REQSTW ] , sp , w ) ) )
  {
    /* System error */
    if  ( r  ==  -1 )
    {
      
      /* UNIX signal interruption , try again */
      if  ( errno  ==  EINTR )  continue ;
      
      /* Something else */
      RTCONS->quit = ME_SYSER ;
      perror ( "met:close:write" ) ;
      mexWarnMsgIdAndTxt ( "MET:close:tv" , ERRHDR
        "error sending mquit" , RTCONS->cd ) ;
      break ;
    }
    
    /* Update */
     w -= r ;
    sp += r ;
    
  } /* Send mquit */
  
  
  /*-- Close pipe file descriptors --*/
  
  for  ( i = 0 ; i  <  METPIP ; ++i )
  {
    /* Attempt close */
    fdclose ( RTCONS->p[ i ] , "error closing pipe fd" , RTCONS ) ;
    
    /* Set pipe fd and status flags to initialisation value */
     RTCONS->p[ i ] = FDINIT ;
    RTCONS->pf[ i ] = FDSINIT ;
  }
  
  
} /* metxclose */

