
/*  metsrv.h
  
  Constants, include statements, definitions that are specific
  to metserver and supporting functions.
  
  NOTE: Because POSIX shared memory is used, metserver must
  be compiled like this
  
    gcc  *.c  -o metserver  -lrt
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include Block ---*/

#include  <limits.h>
#include  <stdlib.h>
#include  <termios.h>

#include  <sys/epoll.h>


/*--- Declare external global variables ---*/

/* UNIX signal handling flags */

// SIGCHLD
extern char  FLGCHLD ;

// SIGINT
extern char  FLGINT  ;

// SIGALRM
extern char  FLGALRM ;

/* MET error code */

extern unsigned char  meterr ;


/*--- Function declarations ---*/

int  findcd ( const unsigned char , const int * , const int ) ;


/*--- Define Block ---*/


/* metserver input argument constants */

// The number of consecutive args required for each controller
#define  NCTRLA  2


/* MET child controller constants */

// pid_t array initialiser
#define  MCINIT  -1

// Matlab [the program] shell command string
#define  MATCOM  "ptb3-matlab"

// Matlab execute option
#define  MATEXE  "-r"

/* Matlab [the language] execution string. Remember that
  metcontroller's inputs are controller descriptor, duplicate
  standard output, broadcast read and request write pipe file
  descriptors, and three groups of arguments with number of
  readers, readers' event fd, and writer's event fd's, for each
  type of shared memory. */
#define  MATSTR_HEAD  "try , metcontroller ( %d , %d , %d , %d"
#define  MATSTR_TAIL  " ) ;  catch E , " \
  "met ( 'print' , "\
   "sprintf ( '\\n%%s\\n%%s' , E.identifier , getReport( E ) ) ,"\
       " 'e' )" \
  " , end , exit ;"

// Null device. A black hole where Matlab preamble disappears.
#define  DEVNULL  "/dev/null"


/* meteventfd semaphore semantics flags , for input sem */

// Make event fd with semaphore semantics
#define     EFDSEM  1

// Make event fd with normal semantics i.e. non-semaphore
#define  EFDNONSEM  0


/* metepoll epoll fd event flags */

#define  EPEVFL  EPOLLIN | EPOLLPRI | EPOLLERR | EPOLLHUP


/* epoll_wait timeouts , in milliseconds */

// MET initialisation wait for mready, timeout in milliseconds
#define  MIWAIT  60000

/* MET server, waiting for MET signal requests. Poll UNIX signal
  status every 250 ms i.e. at a rate of 4Hz if no other event
  is detected first. */
#define  MSERVT  250


/* wait() alarm timeout */

// In seconds
#define  TWAIT1  20
#define  TWAITK   1


/* Error reporting/exit macros */

#define  FEB( s )  { fprintf ( stderr , s "\n" ) ;  break ; }
#define  EXF       exit ( EXIT_FAILURE ) ;
#define  PEX( s )  { perror ( s "\n" ) ; EXF }
#define  FEX( s )  { fprintf ( stderr , s "\n" ) ;  EXF }


/* MET error handling macros */

// Save the first MET error that is encountered and reset meterr
#define  RESET_METERR  if ( e == ME_NONE && meterr != ME_NONE ) \
                         e = meterr ; \
                       meterr = 0 ;

// Check specific UNIX signal handler flags
#define  CHKSIGFLG( S )  if ( meterr == ME_NONE && ( S ) ) \
                         { \
                           if ( FLGINT ) \
                             meterr = ME_INTR ; \
                           else if ( FLGCHLD ) \
                             meterr = ME_CHLD ; \
                         }


/*--- Function prototypes ---*/

 size_t metatomic ( int ) ;
    int metbroadcast ( const unsigned char, const int *,
                       void *, const size_t ) ;
   void metchkargv ( const int, char **, unsigned char *,
                     unsigned char ** ) ;
    int metclose ( const int, int * ) ;
    int metepoll ( const unsigned char, const int * ) ;
    int metforx ( const unsigned char, pid_t *, pid_t *,
                  const int *, const int *, const unsigned char *,
                  int *, int **, const int, char ** ) ;
    int metiwait ( const unsigned char, const int, const int * ) ;
    int metpipe ( const int, int *, int * ) ;
    int metsigsrv ( const unsigned char, const int *, const int *,
                    const int, const size_t ) ;
   void metunisig ( void ) ;
    int metwait ( const unsigned char, const unsigned char,
                  pid_t *, const unsigned int ) ;

ssize_t metgetreq ( const int, int *, const struct epoll_event *,
                    void *, size_t, const int *, const unsigned char ) ;
int  metshm ( const unsigned char  ,
              const unsigned char *,
                     const char  **,
                     const size_t *,
                              int * ) ;
    int metsmunln ( const unsigned char, const unsigned char *,
                    const char ** ) ;

    int  meteventfd ( const unsigned char, const unsigned char *,
                      const unsigned char, int * ) ;


