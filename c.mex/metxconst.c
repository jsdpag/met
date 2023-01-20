
/*  metxconst.c
  
  MC = met ( 'const' , nort )
  
  Returns a Matlab struct containing MET constants, with fields:
    
    MC.CD - scalar double - Controller descriptor.
    MC.AWMSIG - scalar double - Maximum number of MET signals that can be
      atomically read or written from a pipe.
    
    Cell arrays , 2 columns with names in column 1 and numbers in column 2.
    Each row acts as a record binding name to number.
    MC.SIG - MET signal names and identifiers.
    MC.OUT - Trial outcome names and codes.
    MC.ERR - MET error names and codes.
    MC.SHM - The POSIX shared memory objects (col 1) and associated I/O
      actions (col 2) that this controller may perform. Actions are encoded
      by a single character, either 'r' for read access or 'w' for write
      access.
    
    Structs of valid cargo codes:
    MC.MREADY - Has fields TRIGGER and REPLY.
    MC.MWAIT - Has fields INIT, FINISH, and ABORT.
    MC.MCALIBRATE - Has fields NONE.
    
    Structs of MET file and directory names:
    MC.PROG - Program directory, stimulus and task logic template sub-dirs.
    MC.ROOT - Root run-time directory trial and session indicator files.
    MC.SESS - Session directory files and sub-dirs
    MC.TRIAL - Trial directory parameter files.
  
  If optional input argument nort is non-zero then no run-time constants
  are returned , their fields will contain empty matrices i.e. [].
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "metx.h"


/*--- Define block ---*/

#define  ERRHDR  MCSTR ":met:open: "

#define  NLHS_MAX  1
#define  NRHS_MAX  1

/* Number of fields in MC */
#define  FIELDS  13

/* Number of cell arrays */
#define  NCELLS  4

/* Cell array starting field index */
#define  ICELLS  2

/* Number of columns per cell array */
#define  NCCOL  2

/* Run-time constant SHM */
#define  RTCSHM  5

/* Number of MET signal sub-structs */
#define  NSUBSIG  3

/* Number of MET file sub-structs */
#define  NSUBFNM  4

/* Total number of sub-structs */
#define  NSUBS  NSUBSIG + NSUBFNM

/* MET signal sub-structs starting field index */
#define  ISUBSIG  ICELLS + NCELLS


/*--- MC field names ---*/

const char *  MCFNAM[ FIELDS ] = { "CD" , "AWMSIG" , "SIG" , "OUT" ,
  "ERR" , "SHM" , "MREADY" , "MWAIT" , "MCALIBRATE" , "PROG" , "ROOT" ,
  "SESS" , "TRIAL" } ;


/*--- Cell constants ---*/

/* MET signal names and identifiers */
const char *  MSIGN[] = { MSNNULL , MSNREADY , MSNSTART , MSNSTOP ,
  MSNWAIT , MSNQUIT , MSNSTATE , MSNTARGET , MSNREWARD , MSNRDTYPE ,
  MSNCALIBRATE } ;
const int    MSIGID[] = { MSINULL , MSIREADY , MSISTART , MSISTOP ,
  MSIWAIT , MSIQUIT , MSISTATE , MSITARGET , MSIREWARD , MSIRDTYPE ,
  MSICALIBRATE } ;

/* Trial outcome names and codes */
const char *  OUTNAM[] =
  { "correct" , "failed" , "ignored" , "broken" , "aborted" } ;
const int     OUTVAL[] =
  { MO_CORRECT , MO_FAILED , MO_IGNORED , MO_BROKEN , MO_ABORTED } ;

/* Error names and codes */
const char *  ERRNAM[] = { "NONE" , "PBSRC" , "PBSIG" , "PBCRG" , "PBTIM" ,
  "SYSER" , "BRKBP" , "BRKRP" , "CLGBP" , "CLGRP" , "CHLD" , "INTR" ,
  "INTRN" , "TMOUT" , "MATLB" } ;
const int     ERRVAL[] = { ME_NONE , ME_PBSRC , ME_PBSIG ,
  ME_PBCRG , ME_PBTIM , ME_SYSER , ME_BRKBP , ME_BRKRP , ME_CLGBP ,
  ME_CLGRP , ME_CHLD , ME_INTR , ME_INTRN , ME_TMOUT , ME_MATLB } ;

/* met shared memory name constant is defined within the scope of
  metxconst. Somewhere , possibly in the undocumented boggy moors of
  Matlab, exists a definition called SHMNAM. By defining within the scope
  of metxconst, we override the other definition. */

/* Number of elements per array , the last element contains SHM ,
  set later */
unsigned char  CELNUM[ NCELLS ] = { MAXMSI + 1 , 5 , ME_MAXER + 1 , 0 } ;

/* Arrays of name and value arrays , last element SHM , to be set later */
const void *  CELNAM[ NCELLS ] = { MSIGN  , OUTNAM , ERRNAM , NULL } ;
const int  *  CELVAL[ NCELLS ] = { MSIGID , OUTVAL , ERRVAL , NULL } ;


/*--- Sub-struct constants ---*/

/* MC.MREADY field names and values */
const char *  MREADY[] = { "TRIGGER" , "REPLY" } ;
const metcargo_t  CREADY[] = { MREADY_TRIGGER , MREADY_REPLY } ;

/* MC.MWAIT field names and values */
const char *  MWAIT[] = { "INIT" , "FINISH" , "ABORT" } ;
const metcargo_t  CWAIT[] = { MWAIT_INIT , MWAIT_FINISH , MWAIT_ABORT } ;

/* MC.MCALIBRATE field names and values */
const char *  MCALIBRATE[] = { "NONE" } ;
const metcargo_t  CCALIBRATE[] = { MCALIBRATE_NONE } ;

/* MC.PROG field names and strings */
const char *  PROGNAM[] = { "STIM" , "TLOG" } ;
const char *  PROGVAL[] = { MPRG_STIM , MPRG_TLOG } ;

/* MC.ROOT field names and strings */
const char *  ROOTNAM[] = { "ROOT" , "SESS" , "TRIAL" } ;
const char *  ROOTVAL[] = { MDIR_ROOT , MDIR_SESS , MDIR_TRIAL } ;

/* MC.SESS field names and strings */
const char *  SESSNAM[] = { "FIN" , "FTR" , "HDR" , "LOGS" , "REC" ,
  "SCHED" , "STIM" , "SUM" , "TLOG" , "TRIAL" } ;
const char *  SESSVAL[] = { MSESS_FIN , MSESS_FTR , MSESS_HDR ,
  MSESS_LOGS , MSESS_REC , MSESS_SCHED , MSESS_STIM , MSESS_SUM ,
  MSESS_TLOG , MSESS_TRIAL } ;

/* MC.TRIAL field names and strings */
const char *  TRIALNAM[] = { "PAR" , "PTX" } ;
const char *  TRIALVAL[] = { MTRLD_PAR , MTRLD_PTX } ;

/* Number of fields in sub-structs */
const unsigned char  MFIELDS[ NSUBS ] = { 2 , 3 , 1 , 2 , 3 , 10 , 2 } ;

/* Arrays of sub-struct field names, cargos, file names */
const void *  MNAMES[ NSUBS ] = { MREADY , MWAIT , MCALIBRATE , PROGNAM ,
  ROOTNAM , SESSNAM , TRIALNAM } ;
const metcargo_t *  CARGO[ NSUBSIG ] = { CREADY , CWAIT , CCALIBRATE } ;
const void *  MFNAM[ NSUBFNM ]  = { PROGVAL , ROOTVAL , SESSVAL ,
  TRIALVAL } ;


/*--- metxconst function definition ---*/

void  metxconst ( struct met_t *  RTCONS ,
                  int  nlhs ,       mxArray *  plhs[] ,
                  int  nrhs , const mxArray *  prhs[] )
{
  
  /*-- CONSTANTS --*/
  
  /* met shared memory names */
  char *  SHMNAM[ SHMARG ] = { SNAM_STIM , SNAM_EYE , SNAM_NSP } ;
  
  
  /*-- Check input arguments --*/
  
  /* Number of outputs */
  if  ( nlhs  >  NLHS_MAX )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:const:nlhs" , ERRHDR
      "gives %d output args , %d requested" , RTCONS->cd , NLHS_MAX ,
       nlhs ) ;
  }
    
  /* Number of inputs */
  if  ( nrhs  >  NRHS_MAX )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:const:nrhs" , ERRHDR
      "takes max %d input arg , %d given" ,
      RTCONS->cd , NRHS_MAX , nrhs ) ;
  }
  
  /* Check optional input */
  if  (  nrhs  &&
       ( !mxIsScalar ( prhs[ 0 ] )  ||  !mxIsDouble ( prhs[ 0 ] ) )  )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:const:nort" , ERRHDR
      "input arg nort must be scalar double" , RTCONS->cd ) ;
  }
  
  
  /*-- Variables --*/
  
  /* Generic counter */
  unsigned char  i , j ;
  
  /* MET file name buffer , length , and empty buffer space */
  char  fnb[ PATH_MAX ] , * fnp ;
  size_t  fnl , eb ;
  
  /* Array pointers */
  const char  ** names , ** mfnam ;
  
  /* Matlab array pointer */
  mxArray  * M , * N ;
  
  /* No run-time const flag , mxGetScalar safe since prhs was checked */
  double  nort = 0 ;
  if  ( nrhs )  nort = mxGetScalar ( prhs[ 0 ] ) ;
  
  
  /*-- Create struct --*/
  
  plhs[ 0 ] = mxCreateStructMatrix ( 1 , 1 , FIELDS , MCFNAM ) ;
  
  if  ( plhs[ 0 ]  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
      "not enough heap memory to make MC" , RTCONS->cd ) ;
  }
  
  
  /*-- Controller descriptor , run-time constant --*/
  
  /* Return [] if no run-time constants */
  if  ( nort )
    M = mxCreateDoubleMatrix ( 0 , 0 , mxREAL ) ;
  else
    M = mxCreateDoubleScalar ( (double) RTCONS->cd ) ;
  
  if  ( M  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
      "not enough heap memory to make MC.CD" , RTCONS->cd ) ;
  }
  
  mxSetFieldByNumber ( plhs[ 0 ] , 0 , 0 , M ) ;
  
  
  /*-- Atomic read / write size , run-time constant --*/
  
  /* Determine atomic read / write size in bytes , if not yet found */
  if  (  !nort  &&  RTCONS->awmsig  ==  AWMSIG_INIT )
  {
    /* Take the minimum of either the pipe atomic write size or the system
      page size */
    
    /* PIPE_BUF and page size variables */
    long  ppb[ 2 ] , pgs ;

    /* Get PIPE_BUF */
    errno = 0 ;
    ppb[ BCASTR ] = fpathconf( RTCONS->p[ BCASTR ] , _PC_PIPE_BUF ) ;
    ppb[ REQSTW ] = fpathconf( RTCONS->p[ REQSTW ] , _PC_PIPE_BUF ) ;

    if  ( ( ppb[ BCASTR ] == -1  ||  ppb[ REQSTW ] == -1 )  &&  errno )
    {
      RTCONS->quit = ME_SYSER ;
      perror ( "metserver:metatomic:fpathconf" ) ;
      mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
        "error accessing PIPE_BUF" , RTCONS->cd ) ;
    }
    else if  ( ppb[ BCASTR ]  !=  ppb[ REQSTW ] )
    {
      RTCONS->quit = ME_INTRN ;
      mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
        "broadcast read and request write pipes have different PIPE_BUF" ,
        RTCONS->cd ) ;
    }
    
    /* Get page size */
    errno = 0 ;
    pgs = sysconf( _SC_PAGESIZE ) ;

    if  ( pgs == -1  &&  errno )
    {
      RTCONS->quit = ME_SYSER ;
      perror ( "metserver:metatomic:sysconf" ) ;
      mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
        "error accessing page size" , RTCONS->cd ) ;
    }

    /* Return the smaller value */
    RTCONS->awmsig  =  ppb[ 0 ] <= pgs ? ppb[ 0 ] : pgs ;
    
    /* Convert to number of MET signals */
    RTCONS->awmsig  /=  sizeof ( struct metsignal ) ;
    
  } /* determine atomic size */
  
  if  ( nort )
    M = mxCreateDoubleMatrix ( 0 , 0 , mxREAL ) ;
  else
    M = mxCreateDoubleScalar ( (double) RTCONS->awmsig ) ;
  
  if  ( M  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
      "not enough heap memory to make %s" , RTCONS->cd , MCFNAM[ 1 ] ) ;
  }
  
  mxSetFieldByNumber ( plhs[ 0 ] , 0 , 1 , M ) ;
  
  
  /*-- Shared memory I/O permissions , run-time constants --*/
  
  /* We only know at run-time what these are, so we can only add the final
    entries to CELNUM and CELVAL, here. Start by counting the number of
    shared mem actions that this controller has permission to do. */
  if  ( !nort )
    
    for  ( i = j = 0 ; i  <  SHMARG ; ++i )

      /* The number of actions to count depends on the shm open flag */
      switch  ( RTCONS->shmflg[ i ] )
      {
        case  MSMG_BOTH:   j  +=  2 ;  break ;
        case  MSMG_READ:
        case  MSMG_WRITE:  ++j ;
      } /* shm open flag */
      
  /* no run-time constants */
  else  j = 0 ;
  
  /* Add row count to CELNUM */
  CELNUM[ NCELLS - 1 ] = j ;
  
  /* Declare shared memory name and value arrays */
  char * CSMNAM[ j ] ;
  int    CSMVAL[ j ] ;
  
  /* Add them fo CELNAM and CELVAL */
  CELNAM[ NCELLS - 1 ] = CSMNAM ;
  CELVAL[ NCELLS - 1 ] = CSMVAL ;
  
  /* Populate shm name and value arrays , depending again on open flags */
  for  ( i = j = 0 ; i < SHMARG  &&  j < CELNUM[ NCELLS - 1 ] ; ++i )
    switch  ( RTCONS->shmflg[ i ] )
    {
      case  MSMG_BOTH:
      case  MSMG_READ:   CSMNAM[ j   ] = SHMNAM[ i ] ;
                         CSMVAL[ j++ ] = MSMG_READ ;
                         if  ( RTCONS->shmflg[ i ] == MSMG_READ )  break ;
                         
      case  MSMG_WRITE:  CSMNAM[ j   ] = SHMNAM[ i ] ;
                         CSMVAL[ j++ ] = MSMG_WRITE ;
                         
    } /* populate CELNAM & CELVAL */
  
  
  /*-- Cell arrays --*/
  
  for  ( i = 0 ; i  <  NCELLS ; ++i )
  {
    
    /* Create cell array */
    M = mxCreateCellMatrix ( CELNUM[ i ] , NCCOL ) ;
    
    if  ( M == NULL )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
        "not enough heap memory to make MC.%s" , RTCONS->cd ,
        MCFNAM[ i + ICELLS ] ) ;
    }
    
    
    /* Value names */
    names = (const char **)  CELNAM[ i ] ;
    
    /* Add name and value records */
    for  ( j = 0 ; j  <  CELNUM[ i ] ; ++j )
    {
      /* Char matrix */
      N = mxCreateString ( names[ j ] ) ;
      
      if  ( N  ==  NULL )
      {
        RTCONS->quit = ME_MATLB ;
        mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
          "not enough heap memory to make MC.%s.%s" , RTCONS->cd ,
          MCFNAM[ i + ICELLS ] , names[ j ] ) ;
      }
      
      mxSetCell ( M , j , N ) ;
      
      /* Double matrix */
      if  ( i  <  NCELLS - 1 )
        N = mxCreateDoubleScalar ( (double) CELVAL[ i ][ j ] ) ;
      
      /* Char */
      else
      {
        char  c[ 2 ] = { CELVAL[ i ][ j ] , '\0' } ;
        N = mxCreateString ( c ) ;
      }
      
      if  ( N  ==  NULL )
      {
        RTCONS->quit = ME_MATLB ;
        mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
          "not enough heap memory to make MC.%s.%s" , RTCONS->cd ,
          MCFNAM[ i + ICELLS ] , names[ j ] ) ;
      }
      
      mxSetCell ( M , CELNUM[ i ] + j , N ) ;
    }
    
    /* Set to MC field */
    mxSetFieldByNumber ( plhs[ 0 ] , 0 , i + ICELLS , M ) ;
  }
  
  
  /*-- Get MET program directory --*/
  
  /* Use Matlab function which to obtain full path of metcontroller.m
    First, convert "metcontroller" to a Matlab char array. */
  if  ( ( N = mxCreateString ( METCON ) )  ==  NULL )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
      "not enough heap memory to call which " METCON , RTCONS->cd ) ;
  }
  
  if  ( mexCallMATLAB ( 1 , &M , 1 , &N , "which" ) )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
      "unable to execute >> which " METCON , RTCONS->cd ) ;
  }
  
  /* Matrix to char array */
  if  ( mxGetString ( M , fnb, PATH_MAX ) )
  {
    RTCONS->quit = ME_MATLB ;
    mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
      "error converting program dir from Matlab matrix to char" ,
      RTCONS->cd ) ;
  }
  
  /* Free Matlab arrays */
  mxDestroyArray ( M ) ;
  mxDestroyArray ( N ) ;
  
  /* Length of full path */
  fnl = strlen ( fnb ) ;
  
  /* Find end root MET program directory , one past '/' */
  if  ( ( fnp = strstr ( fnb , MPRG_MAT "/" METCON ".m" ) )  ==  NULL )
  {
    RTCONS->quit = ME_INTRN ;
    mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
      "failed to locate '" MPRG_MAT "/" METCON ".m' in %s" ,
      RTCONS->cd , fnb ) ;
  }
  
  /* Length of path minus substring */
  fnl = fnl  -  strlen ( fnp ) ;
  
  
  /*-- Sub structs: MREADY , MWAIT , MCALIBRATE , PROG , ROOT , SESS ,
    TRIAL --*/
  
  /* Sub struct loop */
  for  ( i = 0 ; i  <  NSUBS ; ++i )
  {
    
    /* Cast arrays of field names and values */
    names = (const char **)  MNAMES[ i ] ;
    
    /* Cast array of MET file names, if looping through them */
    if  ( NSUBSIG  <=  i )
      mfnam = (const char **)  MFNAM[ i - NSUBSIG ] ;
    
    /* Create sub struct */
    M = mxCreateStructMatrix ( 1 , 1 , MFIELDS[ i ] , names ) ;
    
    if  ( M  ==  NULL )
    {
      RTCONS->quit = ME_MATLB ;
      mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
        "not enough heap memory to make MC.%s" , RTCONS->cd ,
        MCFNAM[ i + ISUBSIG ] ) ;
    }
    
    /* Assign to MC field */
    mxSetFieldByNumber ( plhs[ 0 ] , 0 , i + ISUBSIG , M ) ;
    
    /* Sub struct fields */
    for  ( j = 0 ; j  <  MFIELDS[ i ] ; ++j )
    {
      
      /* MET signal field */
      if  ( i  <  NSUBSIG )
        
        N = mxCreateDoubleScalar ( (double) CARGO[ i ][ j ] ) ;
      
      /* MET program sub-directories */
      else if  ( i == NSUBSIG )
      {
        /* Find space remaining in buffer */
        eb = PATH_MAX - fnl ;
        
        /* Then append sub-dir name */
        if  ( eb  <=  snprintf ( fnp , eb , "%s" , mfnam[ j ] ) )
        {
          RTCONS->quit = ME_INTRN ;
          mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
            "MET program file name > PATH_MAX i.e. %llu" , RTCONS->cd ,
            PATH_MAX ) ;
        }
        
        /* Create string Matlab array */
        N = mxCreateString ( fnb ) ;
        
      }
      
      /* Other MET file names */
      else
        
        N = mxCreateString ( mfnam[ j ] ) ;
      
      /* Failed to create Matlab array */
      if  ( N  ==  NULL )
      {
        RTCONS->quit = ME_MATLB ;
        mexErrMsgIdAndTxt ( "MET:const:MC" , ERRHDR
          "not enough heap memory to make MC.%s.%s" , RTCONS->cd ,
          MCFNAM[ i + ISUBSIG ] , names[ j ] ) ;
      }
      
      /* Place Matlab array into struct field */
      mxSetFieldByNumber ( M , 0 , j , N ) ;
      
    } /* fields */
    
  } /* sub structs */
  
  
} /* metxconst */

