
/*  metxopen.c
  
  met ( 'open' , cd , stdofd , pfd , shmflg , shmnr , refd , wefd , wefdv )
  
  Opens and initialises met. The standard output file descriptor is
  restored. POSIX shared memory is opened and mapped. A pointer for the
  HOME environment variable is obtained. The controller's descriptor and
  pipe file descriptors are stored. Returns a Matlab struct of MET
  constants, including MET signals, MET files, and MET error codes.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHD1  "met:open: "
#define  ERRHD2  MCSTR ":" ERRHD1

#define  NLHS_MAX  1
#define  NRHS      8

#define  ARG_CD      0
#define  ARG_STDOFD  1
#define  ARG_PFD     2
#define  ARG_SHMFLG  3
#define  ARG_SHMNR   4
#define  ARG_REFD    5
#define  ARG_WEFD    6
#define  ARG_WEFDV   7


/*--- Constants ---*/

/* Input argument names */
const char *  ARGNAM[] = { "cd" , "stdofd" , "pfd" , "shmflg" , "shmnr" ,
  "refd" , "wefd" , "wefdv" } ;

/* Type per input argument */
const mxClassID  ARGTYP[] = { mxDOUBLE_CLASS , mxDOUBLE_CLASS ,
  mxDOUBLE_CLASS , mxCHAR_CLASS , mxDOUBLE_CLASS , mxDOUBLE_CLASS ,
  mxDOUBLE_CLASS , mxCELL_CLASS } ;

/* Elements per input argument */
const unsigned char  ARGSIZ[] = 
  { 1 , 1 , 2 , SHMARG , SHMARG , SHMARG , SHMARG , SHMARG } ;

/* POSIX shared memory open flags */
const char  SHMFLG[ MSMG_NUM ] =
  { MSMG_CLOSED , MSMG_READ , MSMG_WRITE , MSMG_BOTH } ;

/* POSIX shared memory file names */
const char *  SHMNAM[] = { MSHM_STIM , MSHM_EYE , MSHM_NSP } ;

/* Blocked UNIX signals */
const int  nblk   = 1 ;
const int  sblk[] = { SIGPIPE } ;


/*--- fdcheck function definition ---*/

static void  fdcheck ( int  n , int *  fd , int *  flg ,
                       struct met_t *  RTC )
{
  
  
  /*-- Variables --*/
  
  /* Counter */
  int  i ;
  
  
  /*-- Check fd flags --*/
  
  /* Loop file descriptors */
  for  ( i = 0 ; i  <  n ; ++i )
    
    /* This function is called after fd storage , when FDINIT is a valid
      value for event fd's. Skip to next fd, if found. */
    if  ( fd[ i ]  ==  FDINIT )  continue ;
    
    /* Access file status flags , which includes O_NONBLOCK */
    else if  ( ( flg[ i ] = fcntl ( fd[ i ] , F_GETFL , 0 ) )  ==  -1 )
    {
      RTC->quit = ME_SYSER ;
      perror ( "met:open:fcntl" ) ;
      mexErrMsgIdAndTxt ( "MET:open:fdcheck" , ERRHD2
        "failed to get fd status flags" , RTC->cd ) ;
    }
    
    /* Got flags, but fd is in blocking mode */
    else if  ( !( flg[ i ]  &  O_NONBLOCK ) )
    {
      /* Raise the nonblocking flag ... */
      flg[ i ]  |=  O_NONBLOCK  ;
      
      /* ... and set it on the fd */
      if  ( fcntl ( fd[ i ] , F_SETFL , flg[ i ] )  ==  -1 )
      {
        RTC->quit = ME_SYSER ;
        perror ( "met:open:fcntl" ) ;
        mexErrMsgIdAndTxt ( "MET:open:fdcheck" , ERRHD2
          "failed to set fd status flags" , RTC->cd ) ;
      }
    }
  
  
}  /* fdcheck */


/*--- metxopen function definition ---*/

void  metxopen ( struct met_t *  RTCONS ,
                 int  nlhs ,       mxArray *  plhs[] ,
                 int  nrhs , const mxArray *  prhs[] )
{
  
  
  /*-- Variables --*/
  
  /* Generic counters , f acts as O_ flags for shm */
  int  i , j , f ;
  
  /* Matlab matrix pointer and number of elements */
  mxArray *  M ;
  unsigned char *  n = RTCONS->wefdn ;
  
  /* POSIX shared memory file descriptor, mmap prot flag, and file stats */
  int  fd , p ;
  struct stat  s ;
  
  /* Double pointer */
  double  * stdofd , * pfd , * shmnr , * refd , * wefd ;
  
  /* Char pointer and buffer */
  mxChar *  mxc ;
    char      c ;
  
  /* sigaction structure */
  struct sigaction  sa ;
  
  
  /*-- Check input arguments --*/
  
  /* Initialisation flag must be low */
  if  ( RTCONS->init  ==  MET_INIT )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:open:init" , ERRHD1
      "already opened , must first close" ) ;
  }
  
  /* Number of outputs */
  if  ( nlhs  >  NLHS_MAX )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:open:nlhs" , ERRHD1
      "gives max %d output args , %d requested" , NLHS_MAX , nlhs ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs  !=  NRHS )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:open:nrhs" , ERRHD1
      "takes %d input args , %d given" , NRHS , nrhs ) ;
  }
  
  /* Check input argument type and number of elements */
  for  ( i = 0 ; i  <  nrhs  ; ++i )
    
    if  ( ARGTYP[ i ]  !=  mxGetClassID ( prhs[ i ] ) )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:open:prhs" , ERRHD1 "arg %s wrong type" ,
        ARGNAM[ i ] ) ;
    }
    
    else if  ( ARGSIZ[ i ]  !=  mxGetNumberOfElements ( prhs[ i ] ) )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:open:prhs" , ERRHD1
        "arg %s numel not %d" , ARGNAM[ i ] , ARGSIZ[ i ] ) ;
    }
  
  /* Check shared memory flags
  */
  
  /* Get pointer to Matlab char */
  if  ( ( mxc = mxGetChars ( prhs[ ARG_SHMFLG ] ) )  ==  NULL )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:open:prhs" , ERRHD1
        "arg %s is not mxChar" , ARGNAM[ ARG_SHMFLG ] ) ;
  }
  
  /* Check each Matlab char ... */
  RTCONS->nfd = NFD_INIT ;
  
  for  ( i = 0 ; i  <  ARGSIZ[ ARG_SHMFLG ] ; ++i )
  {
    
    /* ... against each valid value. */
    c = ( char )  mxc[ i ] ;
    for  (  j = 0  ;  j < MSMG_NUM  &&  SHMFLG[ j ] != c  ;  ++j  )  ;
    
    /* No valid value given */
    if  ( j  ==  MSMG_NUM )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:open:prhs" , ERRHD1
        "arg %s invalid flag '%c'" , ARGNAM[ ARG_SHMFLG ] , c ) ;
    }
    
    /* Otherwise it's valid, so keep it */
    RTCONS->shmflg[ i ] = c ;
    
    /* And count number of monitored file descriptors */
    switch  ( c )
    {
      case  MSMG_BOTH:   RTCONS->nfd  +=  2 ;  break ;
      case  MSMG_READ:
      case  MSMG_WRITE:  ++( RTCONS->nfd ) ;
    }
    
  } /* shm open flag check */
  
  
  /*-- Block UNIX signals --*/
  
  /* Block all signals during handling */
  if  ( sigfillset ( &( sa.sa_mask ) ) == -1 )
  {
    RTCONS->quit = ME_SYSER ;
    mexErrMsgIdAndTxt ( "MET:open:unisig" , ERRHD1
      "failed to block UNIX signals" ) ;
  }
  
  /* Don't restart system calls, but return -1 and errno EINTR.
    Use sa_handler, not sa_sigaction */
  sa.sa_flags = 0 ;
  
  /* Signal handler , ignore i.e. block */
  sa.sa_handler = SIG_IGN ;
  
  /* Register each UNIX signal */
  for  ( i = 0 ; i  <  nblk ; ++i )
  
    if  ( sigaction ( sblk[ i ] , &sa , NULL ) == -1 )
    {
      RTCONS->quit = ME_SYSER ;
      mexErrMsgIdAndTxt ( "MET:open:unisig" , ERRHD1
      "failed to block UNIX signals" ) ;
    }
  
  
  /*-- Store constants --*/
  
  /* Raise initialisation flag */
  RTCONS->init = MET_INIT ;
  
  /* Controller descriptor */
  RTCONS->cd = ( metsource_t )  mxGetScalar ( prhs[ ARG_CD ] ) ;
  
  /* Pipe file descriptors */
  if  ( ( pfd = mxGetPr ( prhs[ ARG_PFD ] ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:open:pfd" , ERRHD2 "pfd no real component" ,
      RTCONS->cd ) ;
  }
  
  /* Broadcast pipe reading file descriptor */
  RTCONS->p[ BCASTR ] = ( int )  pfd[ BCASTR ] ;
  
  /* Request pipe writing file descriptor */
  RTCONS->p[ REQSTW ] = ( int )  pfd[ REQSTW ] ;
  
  /* Number of readers */
  if  ( ( shmnr = mxGetPr ( prhs[ ARG_SHMNR ] ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:open:shmnr" , ERRHD2
      "shmnr no real component" , RTCONS->cd ) ;
  }
  
  /* Readers' event file descriptors */
  if  ( ( refd = mxGetPr ( prhs[ ARG_REFD ] ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:open:refd" , ERRHD2 "refd no real component" ,
      RTCONS->cd ) ;
  }
  
  /* Writer's event file descriptors , for this MET controller */
  if  ( ( wefd = mxGetPr ( prhs[ ARG_WEFD ] ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:open:wefd" , ERRHD2 "wefd no real component" ,
      RTCONS->cd ) ;
  }
  
  /* Allocate arrays for monitoring fd's with select() */
  RTCONS->fd    =  (  int * )  malloc ( RTCONS->nfd  *  sizeof( int  ) ) ;
  RTCONS->fdio  =  ( char * )  malloc ( RTCONS->nfd  *  sizeof( char ) ) ;
  RTCONS->fdsi  =  (  int * )  malloc ( RTCONS->nfd  *  sizeof( int  ) ) ;
  
  if  ( RTCONS->fd   == NULL  ||  RTCONS->fdio == NULL  ||
        RTCONS->fdsi == NULL )
  {
    RTCONS->quit = ME_SYSER ;
    mexErrMsgIdAndTxt ( "MET:open:fd_arrays" , ERRHD2
      "failed to allocate memory" , RTCONS->cd ) ;
  }
  
  /* fd array index , advanced as monitored shm event fd's found, next */
  j = 0 ; 
  
  /* POSIX shared memory flags , number of readers , readers' and writer's
    event file descriptors */
  for  ( i = 0 ; i  <  SHMARG ; ++i )
  {
    /* Gather event fd's */
    RTCONS->shmnr[ i ]  = ( unsigned char )  shmnr[ i ] ;
    RTCONS->refd[ i ]   = ( int )  refd[ i ] ;
    RTCONS->wefd[ i ]   = ( int )  wefd[ i ] ;
    
    /* Monitored fd's with select() */
    switch  ( RTCONS->shmflg[ i ] )
    {
      /* Reads and writes in shared mem i */
      case  MSMG_BOTH:
        
      /* Readers must wait for posts to wefd */
      case  MSMG_READ:  RTCONS->fd[ j ] = RTCONS->wefd[ i ] ;
                        RTCONS->fdio[ j ] = MSMG_READ ;
                        RTCONS->fdsi[ j++ ] = i ;
                        
                        /* If reader and writer then don't break */
                        if  ( RTCONS->shmflg[ i ]  ==  MSMG_READ )  break ;
                        
      /* Writers must wait for posts to refd */
      case  MSMG_WRITE: RTCONS->fd[ j ] = RTCONS->refd[ i ] ;
                        RTCONS->fdio[ j ] = MSMG_WRITE ;
                        RTCONS->fdsi[ j++ ] = i ;
    }
    
  } /* shared mem */
  
  /* Error check number of monitored shm event fd's */
  if  ( RTCONS->nfd  <=  j )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:open:fd_arrays" , ERRHD2
      "max %d shm efd's expected , but %d gathered" , RTCONS->cd , 
      RTCONS->nfd , j + 1 ) ;
  }
  
  /* Monitor broadcast pipe with select() */
  RTCONS->fd[ j ] = RTCONS->p[ BCASTR ] ;
  RTCONS->fdio[ j ] = FDIO_PIPE ;
  RTCONS->fdsi[ j ] = FDSI_PIPE ;
  
  /* Find maximum monitored file descriptor */
  RTCONS->maxfd = MFD_INIT ;
  
  for  ( i = 0 ; i  <  RTCONS->nfd ; ++i )
    if  ( RTCONS->maxfd  <  RTCONS->fd[ i ] )
      RTCONS->maxfd =  RTCONS->fd[ i ] ;
  
  /* Check that max fd is within limit */
  if  ( FD_SETSIZE  <  RTCONS->maxfd )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:open:FD_SETSIZE" , ERRHD2
      "max fd %d found , larger than limit FD_SETSIZE i.e. %d" ,
      RTCONS->cd , RTCONS->maxfd , FD_SETSIZE ) ;
  }
  
  /* Writer's event fd lists , each shm and reader combination */
  for  ( i = 0 ; i  <  SHMARG ; ++i )
  {
    /* Skip if MET controller is not a writer */
    if  (  RTCONS->shmflg[ i ]  !=  MSMG_WRITE  &&
           RTCONS->shmflg[ i ]  !=  MSMG_BOTH  )
      continue ;
    
    /* Get pointer to Matlab array in this element of the cell wefdv */
    if  ( ( M = mxGetCell ( prhs[ ARG_WEFDV ] , i ) )  ==  NULL )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:open:wefdv" , ERRHD2
        "wefdv{ %d } no real component" , RTCONS->cd , i ) ;
    }
    /* Check whether array is empty , while storing number of elements */
    else if  ( !( n[ i ] = mxGetNumberOfElements ( M ) ) )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:open:wefdv" , ERRHD2
        "wefdv{ %d } is empty" , RTCONS->cd , i ) ;
    }
    /* Check that MET controller's descriptor doesn't exceed numel ( M ) */
    else if  ( n[ i ]  <  RTCONS->cd )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:open:wefdv" , ERRHD2
        "wefdv{ %d } has %llu elements , less than cd %d" ,
        RTCONS->cd , i , (unsigned long long) n[ i ] , RTCONS->cd ) ;
    }
    /* Get pointer to double values */
    else if  ( ( wefd = mxGetPr ( M ) )  ==  NULL )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:open:wefdv" , ERRHD2
        "wefdv{ %d } no real component" , RTCONS->cd , i ) ;
    }
    /* And check that a reader/writer has the same writer's efd in wefd and
      wefdv */
    else if  ( RTCONS->shmflg[ i ]  ==  MSMG_BOTH  &&
               RTCONS->wefd[ i ]  !=  wefd[ RTCONS->cd - 1 ] )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:open:wefdv" , ERRHD2
        "reader/writer wefdv{ %d }( %d ) %d not same as wefd( %d ) %d" ,
        RTCONS->cd , i+1 , RTCONS->cd , ( int )  wefd[ RTCONS->cd - 1 ] ,
        i+1 , RTCONS->wefd[ i ] ) ;
    }
    
    /* Count number of initialised event fd's */
    for  ( j = f = 0 ; j  <  n[ i ] ; ++j )
      f  +=  FDINIT != wefd[ j ]  ;
    
    /* Match this against number of readers */
    if  ( RTCONS->shmnr[ i ]  !=  f )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:open:wefdv" , ERRHD2
        "shm %d has %d readers but %d event fd's in wefdv" ,
        RTCONS->cd , i , RTCONS->shmnr[ i ] , f ) ;
    }
    
    /* Get memory for the list of efd's and their state flags */
    RTCONS->wefdv[ i ] = malloc ( n[ i ]  *  sizeof ( int ) ) ;
    RTCONS->wflgv[ i ] = malloc ( n[ i ]  *  sizeof ( int ) ) ;
    
    if  ( RTCONS->wefdv[ i ]  ==  NULL  ||  RTCONS->wflgv[ i ]  ==  NULL )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:open:wefdv" , ERRHD2
        "shm %d failed to allocate memory for event fd list" ,
        RTCONS->cd , i ) ;
    }
    
    /* Copy the list of event fd's and initialise flags */
    for  ( j = 0 ; j  <  n[ i ] ; ++j )
    {
      RTCONS->wefdv[ i ][ j ] = ( int )  wefd[ j ] ;
      RTCONS->wflgv[ i ][ j ] = FDSINIT ;
    }
    
  } /* wefdv */
  
  /* Check that number of writer's efds are same for each shared memory.
    Find index of first shm that controller writes in. */
  for  ( i = 0 ; i  <  SHMARG  &&
         RTCONS->shmflg[ i ] != MSMG_WRITE  &&
         RTCONS->shmflg[ i ] != MSMG_BOTH ;
         ++i )  ;
  
  /* Then check against remaining shared mems */
  for  ( j = i + 1 ; j  <  SHMARG ; ++j )
    
    /* Not a writer */
    if  ( RTCONS->shmflg[ j ]  !=  MSMG_WRITE  &&
          RTCONS->shmflg[ j ]  !=  MSMG_BOTH )
      continue ;
    
    /* Writer's efd list size is different */
    else if  ( n[ i ]  !=  n[ j ] )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:open:wefdv" , ERRHD2
        "shms %d and %d have %llu and %llu element writer's efd lists" ,
        RTCONS->cd , i , j ,
        (unsigned long long) n[ i ] , (unsigned long long) n[ j ] ) ;
    }
  
  /* HOME environment variable */
  if  ( ( RTCONS->HOME = getenv ( "HOME" ) )  ==  NULL )
  {
    RTCONS->quit = ME_SYSER ;
    mexErrMsgIdAndTxt ( "MET:open:HOME" , ERRHD2
      "could not find HOME environment var" , RTCONS->cd ) ;
  }
  
  
  /*-- Restore standard output file descriptor --*/
  
  if  ( RTCONS->stdout_res  ==  MET_UNINIT )
  {
    /* Get duplicate file descriptor */
    if  ( ( stdofd = mxGetPr ( prhs[ ARG_STDOFD ] ) )  ==  NULL )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:open:stdofd" , ERRHD2
        "stdofd no real component" , RTCONS->cd ) ;
    }
    
    int  dupfd = ( int )  *stdofd ;
    
    /* Duplicate back into standard out file number */
    while  ( dup2 ( dupfd , STDOUT_FILENO )  ==  -1 )
      
      /* Error other than UNIX signal interruption */
      if  ( errno  !=  EINTR )
      {
        RTCONS->quit = ME_SYSER ;
        perror ( "met:open:dup2" ) ;
        mexErrMsgIdAndTxt ( "MET:open:stdofd" , ERRHD2
          "system error duplicating fd" , RTCONS->cd ) ;
      }
    
    /* Close duplicate file descriptor */
    while  ( close ( dupfd )  ==  -1 )
      
      /* Error other than UNIX signal interruption */
      if  ( errno  !=  EINTR )
      {
        RTCONS->quit = ME_SYSER ;
        perror ( "met:open:close" ) ;
        mexErrMsgIdAndTxt ( "MET:open:stdofd" , ERRHD2
          "system error closing duplicate fd" , RTCONS->cd ) ;
      }
    
    /* Permanently raise flag */
    RTCONS->stdout_res = MET_INIT ;
    
  } /* duplicate standard out */
  
  
  /*-- Check & store file descriptor status flags --*/
  
  /* Pipes */
  fdcheck ( METPIP , RTCONS->p    , RTCONS->pf   , RTCONS ) ;
  
  /* Readers' event file descriptors */
  fdcheck ( SHMARG , RTCONS->refd , RTCONS->rflg , RTCONS ) ;
  
  /* Writer's event file descriptors */
  fdcheck ( SHMARG , RTCONS->wefd , RTCONS->wflg , RTCONS ) ;
  
  for  ( i = 0 ; i  <  SHMARG ; ++i )
    fdcheck ( n[ i ] , RTCONS->wefdv[ i ] , RTCONS->wflgv[ i ] , RTCONS ) ;
  
  
  /*-- Memory map POSIX shared memory --*/
	
  /* Loop shared memory file names */
	for  ( i = 0 ; i  <  SHMARG ; ++i )
  {
    
    /* Determine system opening flag from MET shm opening flag */
    switch  ( RTCONS->shmflg[ i ] )
    {
      /* Stays closed , to next shm */
      case MSMG_CLOSED:  continue ;
      
      /* Reading only */
      case   MSMG_READ:  f = O_RDONLY ;
                         p = PROT_READ ;
                         break ;
      
      /* Writing only */
      case  MSMG_WRITE:  f = O_RDWR ;
                         p = PROT_WRITE ;
                         break ;
      
      /* Reading and writing */
      case   MSMG_BOTH:  f = O_RDWR ;
                         p = PROT_READ  |  PROT_WRITE ;
                         break ;
    }
    
    /* Open POSIX shared memory */
    if  ( ( fd = shm_open ( SHMNAM[ i ] , f , 0 ) )  ==  -1 )
    {
      RTCONS->quit = ME_SYSER ;
      perror ( "met:open:shm_open" ) ;
      mexErrMsgIdAndTxt ( "MET:open:shm" , ERRHD2
        "error opening POSIX shared memory %s" ,
        RTCONS->cd , SHMNAM[ i ] ) ;
    }
    
    /* Determine size of shared memory by accessing file stats */
    if  ( fstat ( fd , &s )  ==  -1 )
    {
      RTCONS->quit = ME_SYSER ;
      perror ( "met:open:fstat" ) ;
      mexErrMsgIdAndTxt ( "MET:open:shm" , ERRHD2
        "error getting stats on POSIX shared memory %s" ,
        RTCONS->cd , SHMNAM[ i ] ) ;
    }
    
    RTCONS->shmsiz[ i ] = s.st_size ;
    
    /* Map shared memory */
    RTCONS->shmmap[ i ] =
                      mmap ( NULL , s.st_size , p , MAP_SHARED , fd , 0 ) ;
    
    if  ( RTCONS->shmmap[ i ]  ==  MAP_FAILED )
    {
      RTCONS->quit = ME_SYSER ;
      RTCONS->shmmap[ i ] = NULL ;
      perror ( "met:open:mmap" ) ;
      mexErrMsgIdAndTxt ( "MET:open:shm" , ERRHD2
        "error mapping POSIX shared memory %s" ,
        RTCONS->cd , SHMNAM[ i ] ) ;
    }
    
    /* Close shared memory */
    while  ( close ( fd )  ==  -1 )
      
      /* System error other than UNIX signal interruption */
      if  ( errno  !=  EINTR )
      {
        RTCONS->quit = ME_SYSER ;
        perror ( "met:open:close" ) ;
        mexErrMsgIdAndTxt ( "MET:open:shm" , ERRHD2
          "error closing POSIX shared memory %s" ,
          RTCONS->cd , SHMNAM[ i ] ) ;
      }
    
  } /* shm */
  
  
  /*-- Return MET constants --*/
  
  metxconst ( RTCONS , nlhs , plhs , 0 , NULL ) ;
  
  
} /* metxopen */

