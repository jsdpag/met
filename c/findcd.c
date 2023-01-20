
/*  findcd.c
  
  Returns controller descriptor of MET controller with request
  pipe fd. This is the index + 1 of the element in qr that
  contains fd.  Returns -1 if not found. qr has np elements
  
  Written by Jackson Smith - DPAG, University of Oxford
  
*/


int  findcd ( const unsigned char  np , const int *  qr ,
              const int  fd )
{
  
  // Return value
  int  r = 0 ;
  
  // Scan qr for fd
  while  ( r < np  &&  qr[ r ] != fd )  ++r ;
  
  // Index
  return  r < np ? r + 1 : -1 ;
  
} // findcd


