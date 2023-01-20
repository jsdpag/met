
/*  metchkargv.c
  
  void  metchkargv ( const int  argc , char **  argv ,
                     unsigned char *  shmnr ,
                     unsigned char **  rflg )
  
  Deals with the business of making sure that all input arguments
  to metserver are valid. The first three inputs must be integers
  between 0 and MAXCHLD, meaning there must be that many
  child controllers reading from shared memory. There must be
  at least one child controller, and there must be a pair of input
  arguments for each one. Each pair must consist of first Matlab
  command line options -nojvm, -nodesktop, or -nosplash and then
  a child controller function name followed by zero or more
  valid controller options.
  
  Requires argc and argv from main (). The following unsigned 
  char pointer shmnr must be an array with SHMARG many elements.
  It is used to return the number of readers for each type of
  shared memory in this order:
  
    shmnr[ 0 ] <- argv[ 1 ] - stimulus variable parameters
    shmnr[ 1 ] <- argv[ 2 ] - eye position
    shmnr[ 2 ] <- argv[ 3 ] - Neural signal processor output
  
  Sets the reader flag rflg to 1 whenever a child process reads
  from a given shared memory i.e. for the ith shared memory and
  jth child process, rflg[ i ][ j ] will be set to 1 if child j
  reads shared memory i.
  
  Terminates process with error if input argument is invalid.
  Does not set meterr.
  
  NOTE: The program does not check whether the child controller
    function m-files exist. This will be determined when each
    child controller executed Matlab and discoveres that the
    program is not on the path.
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


/*--- Include block ---*/

#include  <ctype.h>

#include  "met.h"
#include  "metsrv.h"


/*--- Define block ---*/

// Maximum length of any option string, plus null byte
#define  MAXSTR  18

// Maximum number of option strings in a set
#define  MAXSET  11


/*--- Option sets ---*/

//  *op - option strings
// n*op - number of option strings
// s*op - number of options to skip

/* Matlab options 'm' */
char *  mop[] = { "-nojvm" , "-nodesktop" , "-nosplash" ,
  "-desktop" , "-noFigureWindows" , "-nodisplay" , "-debug" ,
  "-singleCompThread" , "-nouserjavapath" , "-softwareopengl" ,
  "-nosoftwareopengl" } ;
char   nmop   = 11 ;
char   smop   =  0 ;

/* Controller options 'c' - The reader-writer options must be
 arranged in the first 6 elements of the array for reader
 and writer counting to work, later. */
char *  cop[] = { "-rstim" , "-reye" , "-rnsp" ,
                  "-wstim" , "-weye" , "-wnsp" ,
                  "-cbmex" , "-ivxudp" , "-ptbdaq" } ;
char   ncop   = 9 ;
char   scop   = 1 ;


/*--- nexopt function definition ---*/

/* nexopt is used to return the next option from a given option
 string into a buffer. It reads to the next space or null byte.
 It skips spaces to find the next option. It returns the value of
 a pointer starting at the next non-space character. Check for
 this to be null byte. A null byte is placed at the head of
 the buffer if c points to a null byte when the function is
 called */
 
char *  nexopt ( char *  c , char *  b )
{
  
  /* Copy string to buffer */
  
  // Counter
  int  i ;
  
  // Copy
  for  ( i = 0 ; *c != ' ' && *c != '\0' && i < MAXSTR-1 ; ++i )
    *(b++) = *(c++) ;
  
  // Add null byte to end of buffered string
  *b = '\0' ;
  
  
  /* Skip spaces, and return position of next option */
  
  while  ( *c == ' ' )
    ++c ;
  
  return  c ;
  
  
} // nexopt


/*--- metchkargv function definition ---*/

void  metchkargv ( const int  argc , char **  argv ,
                   unsigned char *  shmnr ,
                   unsigned char **  rflg )
{
  
  
  /* Variable definition */
  
  // Input argument pointer
  char *  c ;
  
  // String buffer for reading each option
  char  b[ MAXSTR ] ;
  
  // Pointers option sets, { Matlab , Controller }
  void *   opt[] = {  &mop ,  &cop } ;
  void *  nopt[] = { &nmop , &ncop } ;
  void *  sopt[] = { &smop , &scop } ;
  
  // Controller option set index
  const char  ictrlo = 1 ;
  
  // Option set variables
  char  ** v , nv , sv ;
  
  // Flags for detecting option repetition in one argument string
  char  rf[ MAXSET ] ;
  
  // Ordered set of argv indeces for shared mem reader counts
  unsigned char  ri[] = { STMARG , EYEARG , NSPARG } ;
  
  // Reader & writer counters, shared mem.
  char  rw[ 2 * SHMARG ] ;
  
  // Loop counters
  int  i , j , k ;
  
  // Initialise reader-writer counter to zero
  for  ( i = 0 ; i < 2 * SHMARG ; ++i )
    rw[ i ] = 0 ;
  
  
  /* Determine number of shared memory readers */
  
  // Loop shm readers
  for  ( i = 0 ; i < SHMARG ; ++i )
  {
    
    // Convert argument to int
    shmnr[ i ] = atoi ( argv[ ri[ i ] ] ) ;
    
    // And check value
    if  ( MAXCHLD  <  shmnr[ i ] )
      FEX ( "metserver: too many shm readers" )
    
  } // shm readers
  
  
  /* Check that options are all valid */
  
  // Loop input arguments
  for  ( i = SHMARG + 1 ; i < argc ; /*no action*/ )
  {
    
    // Loop Matlab and MET controller option sets
    for  ( j = 0 ; j < 2 ; ++i , ++j )
    {
      
      // Next input argument option string
      c = argv[ i ] ;
      
      // Input argument is empty
      if  ( *c == '\0' )
        
        // This is not allowed for controller options
        if  ( j == ictrlo )
          FEX ( "metserver: empty controller option agrument" )
        
        // But it is allowed for Matlab options, to next argv
        else
          continue ;
      
      // Valid option strings
       v = (char **)  opt[ j ] ;
      
      // Number of option strings
      nv = *( (char *) nopt[ j ] ) ;
      
      // Number of options to skip
      sv = *( (char *) sopt[ j ] ) ;
      
      // Lower repetition flags
      for  ( k = 0 ; k < nv ; ++k )
        rf[ k ] = 0 ;
      
      // Read each option
      while  ( *c  !=  '\0' )
      {
        
        // Read
        c = nexopt ( c , b ) ;
        
        // Skip sv options
        if  ( sv )
        {
          // Count one more skipped
          --sv ;
          continue ;
        }
        
        // Match against valid options
        for  ( k = 0 ; k < nv ; ++k )
          
          // If there is a match ...
          if  ( !strcmp ( b , v[ k ] ) )
          {
            
            // Check repetition flag
            if  ( rf[ k ] )
            {
              
              // Already used for this controller
              if  ( j == ictrlo )
                FEX ( "metserver: controller option repeated" )
              
              else
                FEX ( "metserver: Matlab option repeated" )
              
            }
              
            // Not used for this controller yet, raise flag
            else
              rf[ k ] = 1 ;
            
            // Count shared memory reader/writer options
            if  ( j == ictrlo  &&  k < 2 * SHMARG )
            {
              rw[ k ]++ ;
              
              // Set reader flag
              if  ( k  <  SHMARG )
                rflg[ k ][ ( i - SHMARG ) / 2 - 1 ] = 1 ;
            }
            
            // Done searching
            break ;
            
          } // match
          
          // Check for unrecognised option
          if  ( k == nv )
          {
            
            if  ( j == ictrlo )
              FEX ( "metserver: unrecognised controller option" )
              
            else
              FEX ( "metserver: unrecognised Matlab option" )
              
          } // unrecognised option
        
      } // options
      
    } // option sets
  
  } // input args
  
  
  /* Check that number of readers and reader options match */
  
  for  ( i = 0 ; i < SHMARG ; ++i )
    
    if  ( shmnr[ i ] != rw[ i ] )
      FEX ( "metserver: shm reader flag number not same as count" )
    
    // Reader, but no writer
    else if  ( rw[ i ]  &&  !rw[ i + SHMARG ] )
      FEX ( "metserver: shm reader but no writer" )
      
  
  
  /* Check that number of writers is correct */
  
  for  ( /*no action*/ ; i < 2 * SHMARG ; ++i )
    
    if  ( MAXWSM < rw[ i ] )
      FEX ( "metserver: too many shm writer flags of same type" )
    
    // Writer, but no reader
    else if  ( rw[ i ]  &&  !rw[ i - SHMARG ] )
      FEX ( "metserver: shm writer but no reader" )
  
  
} // metchkargv


