
/*  metx.h
  
  Matlab Electrophysiology Toolbox (MET) interface function header file.
  The interface function met and its supporting MET functions will use this
  to standardise constants and types.
  
  Written by Jackson Smith - DPAG , University of Oxford
  
*/


/*--- Include block ---*/

#include  "met.h"
#include  "mex.h"
#include  "matrix.h"


/*--- Define block ---*/

/* MET pipe count and array indeces in struct met_t .p field */
#define  METPIP  2
#define  BCASTR  0
#define  REQSTW  1

/* met initialisation flag values. Uninitialised (0) and initialised (1) */
#define  MET_UNINIT  0
#define  MET_INIT    1

/* met fd status flag initialisation value */
#define  FDSINIT  -1

/* awmsig initial value */
#define  AWMSIG_INIT  0

/* MET controller printing format string */
#define  MCSTR  "MET ctrl %d"

/* POSIX shared memory prefix character blocking modes */
#define  SCHBLOCK  '+'
#define  SCHNOBLK  '-'

/* Initialise .nfd field in struct met_t , number of monitored pipes */
#define  NFD_INIT  1
#define  MFD_INIT  0
#define  FDIO_PIPE  '\0'
#define  FDSI_PIPE  -1


/*   Reading and writing POSIX shared memory   */

/* size_t header , number of values , and named indeces. Latter are number
  of bytes stored past the size_t header , and the number of Matlab arrays
  stored therein. */
#define  SMST_NUM    2
#define  SMST_BYTES  0
#define  SMST_NMXAR  1


/*--- Macros ---*/

/* Check that mxArray is a string. For input arg check, so 0 is success. */
#define  CHK_IS_STR( i )  mxIsEmpty ( prhs[ i ] )  || \
                          !mxIsChar ( prhs[ i ] )  || \
                          mxGetNumberOfDimensions ( prhs[ i ] )  >  2  || \
                          mxGetM ( prhs[ i ] )  >  1

/* struct met_t initialiser. It is very important that the memory map
  pointers are initialised to NULL, because this is checked for when
  closing resources. */
#define  STRUCTMET_INIT  { \
                           MET_UNINIT , \
                           MET_UNINIT , \
                           ME_NONE , \
                           0 , \
                           AWMSIG_INIT , \
                           { FDINIT  , FDINIT  } , \
                           { FDSINIT , FDSINIT } , \
                           { NULL , NULL , NULL } , \
                           { 0 , 0 , 0 } , \
                           { 0 , 0 , 0 } , \
                           { 0 , 0 , 0 } , \
                           { FDINIT , FDINIT , FDINIT } , \
                           { FDINIT , FDINIT , FDINIT } , \
                           { 0 , 0 , 0 } , \
                           { NULL , NULL , NULL } , \
                           { FDSINIT , FDSINIT , FDSINIT } , \
                           { FDSINIT , FDSINIT , FDSINIT } , \
                           { NULL , NULL , NULL } , \
                           { 0 , 0 , 0 } , \
                           NFD_INIT , \
                           MFD_INIT , \
                           NULL , \
                           NULL , \
                           NULL , \
                           NULL , \
                           NULL \
                         }


/*--- Type definitions ---*/

/* met function structure. This is used to store run-time constants between
  calls to met(), as well as providing a compact way of passing those
  constants to met's supporting MET functions. Has fields:
  
  init - Flags whether met has been initialised or not.
  stdout_res - Standard out fd restored. Can only be set once, in metxopen.
  quit - Cargo of the mquit MET signal that is produced when met is closed.
  cd - Controller descriptor of this MET controller.
  awmsig - Maximum number of MET signals in atomic read or write from pipe.
  p - MET pipe file descriptors.
  pf - Pipe fd status flags e.g. O_NONBLOCK.
  shmmap - Pointers to memory-mapped POSIX shared memory.
  shmsiz - The number of bytes in each memory mapping.
  shmflg - MET opening flags for POSIX shared memory.
  shmnr - The number of readers for each shared memory.
  refd - Readers' event file descriptor for each shared memory.
  wefd - Writer's event file descriptor for each shared memory.
  wefdn - The number of event fd's in each array of wefdv.
  wefdv - Writer's efd vectors , for each shm/reader combination.
  rflg - Readers' event fd status flags e.g. O_NONBLOCK.
  wflg - Writer's event fd status flags e.g. O_NONBLOCK.
  wflgv - Writer's efd status flag vectors , for efds in wefdv.
  rcount - Cumulative sum of values read from event fd's since last write.
  nfd - Numer of file descriptors watched in synchronous I/O multiplexing.
  maxfd - Maximum value of all fd's kept in fd.
  fd - Array of fd's watched in synchronous I/O multiplexing. The last
    element is always the broadcast pipe. All earlier elements are event
    fd's for shared memory.
  fdio - Input/output action associated with element of fd. MSMG_READ 'r'
    for reading from shared memory , MSMG_WRITE 'w' for writing to shm.
    Null byte '\0' for last element i.e. broadcast pipe.
  fdsi - Shared memory index of element in fd. -1 for last , pipe element.
  HOME - Pointer from getenv() pointing to user's home directory string.
  logfile - Writing stream into the MET controller's current log file.
  
*/
struct met_t
  {
    unsigned char  init ;
    unsigned char  stdout_res ;
    unsigned char  quit ;
    metsource_t  cd ;
    size_t  awmsig ;
    int  p[ METPIP ] ;
    int  pf[ METPIP ] ;
    void *  shmmap[ SHMARG ] ;
    size_t  shmsiz[ SHMARG ] ;
    char  shmflg[ SHMARG ] ;
    unsigned char  shmnr[ SHMARG ] ;
    int  refd[ SHMARG ] ;
    int  wefd[ SHMARG ] ;
    unsigned char  wefdn[ SHMARG ] ;
    int *  wefdv[ SHMARG ] ;
    int  rflg[ SHMARG ] ;
    int  wflg[ SHMARG ] ;
    int *  wflgv[ SHMARG ] ;
    uint64_t  rcount[ SHMARG ] ;
    int  nfd ;
    int  maxfd ;
    int *  fd ;
    char *  fdio ;
    int *  fdsi ;
    char *  HOME ;
    FILE *  logfile ;
  } ;


/*--- Function prototypes ---*/

/* met supporting functions */
void metxsend  ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxwrite ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxrecv  ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxread  ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxselect( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxprint ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxflush ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxlogopn( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxlogcls( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxopen  ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxclose ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;
void metxconst ( struct met_t *, int, mxArray **, int, const mxArray ** ) ;

/* Hidden functions */
   uint64_t metxefdread ( struct met_t *, int ) ;
        int metxefdpost ( struct met_t *, const unsigned char, const int *,
              uint64_t ) ;
       void metxsetfl   ( struct met_t *, unsigned char, int *, int *,
              char, char * ) ;
signed char metxshmblk ( const mxArray *, char * ) ;

