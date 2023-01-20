
/*  met.h
  
  Matlab Electrophysiology Toolbox (MET) header file. Everything
  that's needed to standardise constants and types across all
  MET functions.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Feature Test Macro ---*/

/* From the GNU libc manual ...
   
   If you define this macro, everything is included:
   ISO C89, ISO C99, POSIX.1, POSIX.2, BSD, SVID, X/Open,
   LFS, and GNU extensions. In the cases where POSIX.1
   conflicts with BSD, the POSIX definitions take precedence.

   Specifically, it tells gcc that pipe2 is valid.
*/
#define _GNU_SOURCE


/*--- Include Block ---*/

#include  <errno.h>
#include  <fcntl.h>
#include  <float.h>
#include  <signal.h>
#include  <stdio.h>
#include  <stdint.h>
#include  <string.h>
#include  <unistd.h>

#include  <sys/eventfd.h>
#include  <sys/mman.h>
#include  <sys/stat.h>
#include  <sys/time.h>
#include  <sys/types.h>
#include  <sys/wait.h>


/*--- Define Block ---*/

/*   System call constants   */

/* read() end-of-file value */
#define  READ_EOF  0


/*   MET controller constants   */

/* Maximum number of child controllers, 16 - 1 for MET server */
#define  MAXCHLD  15

/* Maximum number of writers per shared memory object */
#define  MAXWSM  1

/* MET server controller descriptor */
#define  MCD_SERVER  0

/* metcontroller.m function name */
#define  METCON  "metcontroller"


/*   MET error codes   */

#define  ME_NONE   0 /* no error */
#define  ME_PBSRC  1 /* MET signal source protocol breach */
#define  ME_PBSIG  2 /* MET signal protocol breach */
#define  ME_PBCRG  3 /* MET signal cargo protocol breach */
#define  ME_PBTIM  4 /* MET signal time protocol breach */
#define  ME_SYSER  5 /* System error other than EINTR or EAGAIN */
#define  ME_BRKBP  6 /* Broken broadcast pipe */
#define  ME_BRKRP  7 /* Broken request pipe */
#define  ME_CLGBP  8 /* Clogged broadcast pipe */
#define  ME_CLGRP  9 /* Clogged request pipe */
#define  ME_CHLD  10 /* Child controller unexpected termination */
#define  ME_INTR  11 /* User interrupt , <ctrl>-c at terminal */
#define  ME_INTRN 12 /* MET internal error */
#define  ME_TMOUT 13 /* Timeout while waiting */
#define  ME_MATLB 14 /* Matlab error */

#define  ME_MAXER 14 /* Maximum value of MET error code */


/*   MET files   */

/* File descriptor initialiser value */
#define  FDINIT  -1

/* Program directories */
#define  MPRG_MAT   "m"
#define  MPRG_STIM  "stim"
#define  MPRG_TLOG  "tasklogic"

/* Runtime root directory */
#define  MDIR_ROOT  "~/.met"
#define  MDIR_SESS  "session"
#define  MDIR_TRIAL "trial"

/* c functions don't know a ~ from a tadger */
#define  MDIR_HOME_ROOT  "%s/.met"

/* Session directory */
#define  MSESS_FIN    ".finalise"
#define  MSESS_FTR    "footer.mat"
#define  MSESS_HDR    "header.mat"
#define  MSESS_LOGS   "logs"
#define  MSESS_REC    "recovery"
#define  MSESS_SCHED  "schedule.txt"
#define  MSESS_STIM   "stim"
#define  MSESS_SUM    "summary.txt"
#define  MSESS_TLOG   "tasklogic"
#define  MSESS_TRIAL  "trials"

/* Trial directory */
#define  MTRLD_PAR  "param.mat"
#define  MTRLD_PTX  "param.txt"


/* Shared memory */

/* The number of arguments about shared memory readers */
#define  SHMARG  3

/* Index of number of stimulus shared memory readers */
#define  STMARG  1

/* Index of number of eye shared memory readers */
#define  EYEARG  2

/* Index of number of NSP shared memory readers */
#define  NSPARG  3

/* POSIX shared memory naming strings */
#define  SNAM_STIM  "stim"
#define  SNAM_EYE   "eye"
#define  SNAM_NSP   "nsp"

/* File names */
#define  MSHM_MNTP  "/dev/shm/" /* Linux shm mount point */
#define  MSHM_STIM  "/stim.met" /* stimulus var. params */
#define  MSHM_EYE   "/eye.met"  /* eye positions, fixations */
#define  MSHM_NSP   "/nsp.met"  /* Neural Signal Processor */

/* Shared memory sizes, in bytes */
#define  MSMS_STIM    65536  /* 2 to power of 16 ie 64 Kbytes */
#define  MSMS_EYE   2097152  /* 2 to power of 21 ie  2 MBytes */
#define  MSMS_NSP   2097152  /* 2 to power of 21 ie  2 MBytes */

/* Header format values */
#define  MSHF_STRMD  0  /* Stream of double values */

/* Opening flags , characters */
#define  MSMG_CLOSED  'c'
#define  MSMG_READ    'r'
#define  MSMG_WRITE   'w'
#define  MSMG_BOTH    'b'

#define  MSMG_NUM      4

/* Synchronisation - Value posted by shm reader or writer to
  its event fd */

#define  REFD_POST  1
#define  WEFD_POST  1


/*   Trial outcome codes   */

#define  MO_CORRECT  1
#define  MO_FAILED   2
#define  MO_IGNORED  3
#define  MO_BROKEN   4
#define  MO_ABORTED  5


/*   MET signals   */

/* Names */
#define  MSNNULL       "mnull"
#define  MSNREADY      "mready"
#define  MSNSTART      "mstart"
#define  MSNSTOP       "mstop"
#define  MSNWAIT       "mwait"
#define  MSNQUIT       "mquit"
#define  MSNSTATE      "mstate"
#define  MSNTARGET     "mtarget"
#define  MSNREWARD     "mreward"
#define  MSNRDTYPE     "mrdtype"
#define  MSNCALIBRATE  "mcalibrate"

/* Identifiers */
#define  MSINULL        0
#define  MSIREADY       1
#define  MSISTART       2
#define  MSISTOP        3
#define  MSIWAIT        4
#define  MSIQUIT        5
#define  MSISTATE       6
#define  MSITARGET      7
#define  MSIREWARD      8
#define  MSIRDTYPE      9
#define  MSICALIBRATE  10

/* Maximum signal identifier */
#define  MAXMSI        10

/* Maximum possible cargo value */
#define  MAXCRG  UINT16_MAX

/* mready cargo */
#define  MREADY_TRIGGER  1
#define  MREADY_REPLY    2

/* mwait cargo */
#define  MWAIT_INIT    1
#define  MWAIT_FINISH  1
#define  MWAIT_ABORT   2

/* mcalibrate cargo */
#define  MCALIBRATE_NONE  0

/* Maximum cargo value */
#define  MCARGO_MAX  UINT16_MAX

/* Minimum and maximum cargo values per MET signal */
#define  MIN_MNULL       0
#define  MIN_MREADY      1
#define  MIN_MSTART      1
#define  MIN_MSTOP       1
#define  MIN_MWAIT       1
#define  MIN_MQUIT       0
#define  MIN_MSTATE      1
#define  MIN_MTARGET     1
#define  MIN_MREWARD     0
#define  MIN_MRDTYPE     1
#define  MIN_MCALIBRATE  0

#define  MAX_MNULL       MCARGO_MAX
#define  MAX_MREADY      2
#define  MAX_MSTART      MCARGO_MAX
#define  MAX_MSTOP       5
#define  MAX_MWAIT       2
#define  MAX_MQUIT       ME_MAXER
#define  MAX_MSTATE      MCARGO_MAX
#define  MAX_MTARGET     MCARGO_MAX
#define  MAX_MREWARD     MCARGO_MAX
#define  MAX_MRDTYPE     MCARGO_MAX
#define  MAX_MCALIBRATE  MCARGO_MAX

/* Minimum and maximum MET signal time values */
#define  MIN_MSTIME  0.0
#define  MAX_MSTIME  DBL_MAX
#define  MST2STR  "%0.6f"


/*   Time conversion   */

/* Microseconds per seconds */
#define  USPERS  1000000.0


/*--- Data structures ---*/

/*   MET type definitions   */

/* MET signal identifier */
typedef   uint8_t  metsignal_t ;

/* MET signal source controller */
typedef   uint8_t  metsource_t ;

/* MET signal cargo */
typedef  uint16_t   metcargo_t ;

/* MET signal time stamp */
typedef    double    mettime_t ;

/* MET shared memory header format byte */
typedef  uint8_t  metshmfmt_t ;


/*   MET signal structure   */

struct metsignal
  { 
    metsource_t  source ;
    metsignal_t  signal ;
     metcargo_t   cargo ;
      mettime_t    time ;
  } ;


