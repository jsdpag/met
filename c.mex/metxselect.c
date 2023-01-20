
/*  metxselect.c
  
  [ tim , msig , shm ] = met ( 'select' , tout )
  
  Waits for any MET inter-process communication resources to be ready for
  reading/writing. Times out after at least tout seconds ; if not provided,
  or if empty i.e. [] then the function waits indefinitely. If MET signals
  are ready to be received with 'recv' then msig is 1 , otherwise it is 0.
  If N actions on POSIX shared memory are possible then cell array shm is
  returned with N rows and 2 columns ; if no actions are possible, then shm
  is an empty cell array i.e. {}. Each row of shm will contain the name of
  the shared memory in column 1 and the action that can be performed on it
  in column 2, given as a single char that is either 'r' for reading or 'w'
  for writing. A time PsychToolbox-style time stamp is returned in tim, in
  seconds, which is taken immediately prior to returning.
  
  For versions 00.XX.XX and 01.XX.XX of MET, valid names in shm col 1 are:
  
    'stim' - Stimulus variable parameter shared memory.
     'eye' - Eye position shared memory.
     'nsp' - Neural signal processor shared memory.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  <math.h>
#include  <sys/select.h>

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:select: "

#define  NLHS_MAX  3
#define  NRHS_MAX  1

#define  PRHS_TOUT 0

#define  PLHS_TIM  0
#define  PLHS_MSIG 1
#define  PLHS_SHM  2

#define  SHMNUMCOL  2
#define  SHMACTCOL  2


/*--- metxwrite function definition ---*/

void  metxselect ( struct met_t *  RTCONS ,
                   int  nlhs ,       mxArray *  plhs[] ,
                   int  nrhs , const mxArray *  prhs[] )
{
  
  /*--- CONSTANTS ---*/

  /* Shared memory names */
  const char *  SHMNAM[ SHMARG ] = { SNAM_STIM , SNAM_EYE , SNAM_NSP } ;
  
  
  /*-- Compile time variables , for input checking --*/
  
  /* Number of elements in input arg tout */
  size_t  ntout = 0 ;
  
  /* Pointer to tout's data */
  double *  tout = NULL ;
  
  /* Matlab array pointer */
  mxArray *  M = NULL ;
  
  
  /*-- Check input arguments --*/
  
  /* Number of outputs */
  if  ( nlhs  >  NLHS_MAX )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:select:nlhs" , ERRHDR
      "max %d output args , %d requested" ,
      RTCONS->cd , NLHS_MAX , nlhs ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs > NRHS_MAX )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:select:nrhs" , ERRHDR
      "max %d input args , %d given" , RTCONS->cd , NRHS_MAX , nrhs ) ;
  }
  
  /* Check size and type of input arg tout */
  if  ( PRHS_TOUT + 1 <= nrhs )
  {
    
    /* Scalar double */
    if  (  !mxIsDouble ( prhs[ PRHS_TOUT ] )  ||
          ( ntout = mxGetNumberOfElements ( prhs[ PRHS_TOUT ] ) )  >  1  )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:select:tout" , ERRHDR
        "input arg tout must be scalar double or empty i.e. []" ,
        RTCONS->cd ) ;
    }
    /* Has real-value data , not just imaginary */
    else if  ( ntout  && ( tout = mxGetPr ( prhs[ PRHS_TOUT ] ) ) == NULL )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:select:tout" , ERRHDR
        "input arg tout has no real value component" , RTCONS->cd ) ;
    }
    /* Value is 0 or more */
    else if  ( ntout  &&  *tout  <  0 )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:select:tout" , ERRHDR
        "input arg tout must be >= 0" , RTCONS->cd ) ;
    }
    
  } /* check tout */
  
  
  /*-- Run time variables --*/
  
  /* Generic counters */
  int  i ;
  
  /* Number of fd's ready for ee-yi-ee-yi-oh */
  int  n ;
  
  /* File descriptor set */
  fd_set  fset ;
  
  /* Timer specification and time measurement , timeval pointer */
  struct timeval  t , * tvp = NULL ;
  
  /* Timeout deadline and time measurement , in seconds */ 
  double  toutd = 0 , tmeas ;
  
  /* Timout fractional and integral */
  double  toutf , touti ;
  
  
  /*-- Timeout prep --*/
  
  if  ( ntout )
  {
    /* Take time measurement */
    if  ( gettimeofday ( &t , NULL )  ==  -1 )
    {
      RTCONS->quit = ME_SYSER ;
      mexErrMsgIdAndTxt ( "MET:select:gettimeofday" , ERRHDR
        "error measuring time" , RTCONS->cd ) ;
    }
    
    /* Determine timout deadline */
    toutd = t.tv_sec  +  t.tv_usec / USPERS  +  *tout ;
    
    /* Convert seconds to timeval */
    toutf = modf ( *tout , &touti ) ;
    t.tv_sec  = ( time_t )  touti ;
    t.tv_usec = ( suseconds_t )  ( toutf * USPERS ) ;
    
    /* Point to timout */
    tvp = &t ;
  }
  
  
  /*-- Multiplexing --*/
  
  /* Return here after UNIX signal interruption */
  reset:
  
  /* Load fd's into set */
  FD_ZERO( &fset ) ;
  
  for  ( i = 0 ; i  <  RTCONS->nfd ; ++i )
    
    FD_SET( RTCONS->fd[ i ] , &fset ) ;
  
  /* Wait for fds , or timeout */
  n = select ( RTCONS->maxfd + 1 , &fset , NULL , NULL , tvp ) ;
  
  /* Error handling */
  if  ( n  ==  -1 )
  {
    /* Not UNIX signal interruption */
    if  ( errno  !=  EINTR )
    {
      RTCONS->quit = ME_SYSER ;
      perror ( "met:metxselect:select" ) ;
      mexErrMsgIdAndTxt ( "MET:select:select" , ERRHDR
        "error during select" , RTCONS->cd ) ;
    }
    
    /* Call select() again immediately if there is no timeout */
    if  ( !ntout )  goto  reset ;
    
    /* Measure current time */
    if  ( gettimeofday ( &t , NULL )  ==  -1 )
    {
      RTCONS->quit = ME_SYSER ;
      mexErrMsgIdAndTxt ( "MET:select:gettimeofday" , ERRHDR
        "error measuring time" , RTCONS->cd ) ;
    }

    /* Convert to seconds */
    tmeas = t.tv_sec  +  t.tv_usec / USPERS  ;

    /* Time until deadline */
    tmeas = toutd - tmeas ;

    /* Call select() again if deadline not reached , revise timeout */
    if  ( 0  <  tmeas )
    {
      toutf = modf ( tmeas , &touti ) ;
      t.tv_sec  = ( time_t )  touti ;
      t.tv_usec = ( suseconds_t )  ( toutf * USPERS ) ;
      goto  reset ;
    }

    /* Otherwise the deadline has been reached or surpassed , so report
      no fd's ready */
    n = 0 ;
      
  } /* errors */
  
  
  /*-- Make output arrays --*/
  
  /* msig */
  if  ( PLHS_MSIG + 1  <=  nlhs )
  {
    /* Index of broadcast pipe file descriptor */
    i = RTCONS->nfd - 1 ;
    
    /* Pipe fd was returned by select , hence signals ready */
    i =  n  &&  FD_ISSET( RTCONS->fd[ i ] , &fset )  ?  1  :  0  ;
    
    /* Make Matlab array */
    if  (  ( M = mxCreateDoubleScalar ( (double)  i ) )  ==  NULL  )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:select:mxCreateDoubleScalar" , ERRHDR
        "not enough heap space to make output arg msig" , RTCONS->cd ) ;
    }
    
    /* Assign to output */
    plhs[ PLHS_MSIG ] = M ;
    
  }
  
  /* shm */
  if  ( PLHS_SHM + 1  <=  nlhs )
  {
    
    /* Row counter */
    int  j ;
    
    /* Number of rows and columns , initialise nr to number of fd's */
    mwSize  nr = n , nc ;
    
    /* shm action string buffer , ends in null byte , don't touch this */
    char  c[ 2 ] = { ' ' , '\0' } ;
    
    /* Number of columns is 2 if shared mem is ready. How we determine this
      depends on whether the pipe fd was returned i.e. the value left over
      in i from making msig. If signals ready, then reduce the fd count by
      1, to get the number of shared mem actions. */
    if  ( i )  --nr ;
    
    /* Number of columns is > 0 if there are shm actions , and 0 if not */
    nc  =  nr  ?  SHMNUMCOL  :  0  ;
    
    /* Create cell array shm */
    if  (  ( M = mxCreateCellMatrix ( nr , nc ) )  ==  NULL  )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:select:mxCreateCellMatrix" , ERRHDR
        "not enough heap space to make output arg shm" , RTCONS->cd ) ;
    }
    
    /* Assign to output */
    plhs[ PLHS_SHM ] = M ;
    
    /* Empty cell , skip to time measurement */
    if  ( !nr )  goto  tmeasure ;
    
    /* Check each event fd to see if it was returned by select() , while
      there are still unassigned rows in shm */
    for  ( i = j = 0 ; i < RTCONS->nfd - 1  &&  j < nr ; ++i )
    {
      /* fd was not returned , so check next one */
      if  ( !FD_ISSET( RTCONS->fd[ i ] , &fset ) )  continue ;
      
      /* This fd is ready , make shared memory name into Matlab string */
      if  ( ( M = mxCreateString (SHMNAM[ RTCONS->fdsi[i] ]) )  ==  NULL )
      {
        RTCONS->quit = ME_MATLB ;
        mexErrMsgIdAndTxt ( "MET:select:mxCreateString" , ERRHDR
          "not enough heap space to make output arg shm" , RTCONS->cd ) ;
      }
      
      /* Add to shm in first column */
      mxSetCell ( plhs[ PLHS_SHM ] , j , M ) ;
      
      /* Get input/output action on shared mem */
      c[ 0 ] = RTCONS->fdio[ i ] ;
      
      /* Turn into Matlab string */
      if  ( ( M = mxCreateString ( c ) )  ==  NULL )
      {
        RTCONS->quit = ME_MATLB ;
        mexErrMsgIdAndTxt ( "MET:select:mxCreateString" , ERRHDR
          "not enough heap space to make output arg shm" , RTCONS->cd ) ;
      }
      
      /* Add to shm in action column , then advance row counter */
      nc = nr  *  ( SHMACTCOL - 1 ) ;
      mxSetCell ( plhs[ PLHS_SHM ] , nc  +  j++ , M ) ;
      
    } /* check efd's */
    
  } /* out arg shm */
  
  /* Empty cell , jumps here */
  tmeasure:
  
  
  /*-- Return time measurement --*/
  
  /* Measure current time */
  if  ( gettimeofday ( &t , NULL )  ==  -1 )
  {
    RTCONS->quit = ME_SYSER ;
    mexErrMsgIdAndTxt ( "MET:select:gettimeofday" , ERRHDR
      "error measuring time" , RTCONS->cd ) ;
  }
  
  /* Convert to seconds */
  tmeas = t.tv_sec  +  t.tv_usec / USPERS  ;
  
  /* Convert to Matlab array */
  if  ( ( M = mxCreateDoubleScalar ( tmeas ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:select:mxCreateDoubleScalar" , ERRHDR
      "not enough heap space to make output arg tim" , RTCONS->cd ) ;
  }
  
  /* Assign to output */
  plhs[ PLHS_TIM ] = M ;
  
  
} /* metxselect */

