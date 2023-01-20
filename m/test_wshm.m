
function  test_wshm ( MC )
  
  S = MC.SIG' ;
  S = struct ( S{ : } ) ;
  
  s = { S.mready , MC.MREADY.REPLY , GetSecs , 0 } ;
  
  % Signal ready to MET server
  met ( 'send' , s{ : } ) ;
  [ ~ , ~ , s ] = met ( 'recv' , 1 ) ;
  
  if  any ( s  ==  S.mquit )  ,  return  ,  end
  
  % Event loop
  i = 1 ;
  
  while  true ;
    
    [ ~ , msig , shm ] = met ( 'select' ) ;
    
    % Quit
    if  msig
      
      [ ~ , ~ , s ] = met ( 'recv' ) ;
      if  any ( s  ==  S.mquit ) , return , end
      
    end
    
    switch  MC.CD
      
      % Controller 1 will write to shm
      case  1 , i = cntl1 ( shm , i ) ;
                if  ~ i  ,  met ( 'send' , S.mquit , 0 , [] )  ;  end

      % Controller 2 will read shm
      case  2 , i = cntl2 ( shm , i ) ;
      
    end

  end % event loop
  
end % test_wshm


function  i = cntl1 ( shm , i )
  
  % Prepare data to write
  switch  i
    
    case  1
      
      D.label = { 'one' , 'two' , 'three' } ;
      D.nsp2ptb_time_coef = struct ( 'a' , 1 , 'b' , 2 ) ;
      D.data  = { 1 , 2 , 3 } ;
      D.n = 1 ;
      D.w = 0 ;
      
    case  2
      
      D.label = { 'four' , 'five' , 'six' } ;
      D.nsp2ptb_time_coef = struct ( 'c' , 3 , 'd' , 4 ) ;
      D.data  = { [] , [] , [] } ;
      D.n = 2 ;
      D.w = 0 ;
      
    otherwise
      
      if  i >= 3  &&  ~ isempty ( shm ) , i = 0 ; end
      return
      
  end
  
  wflg = 0 ;
  
  for  s = 1 : size ( shm , 1 )
    
    if  shm { s , 2 }  ~=  'w'  ,  continue  ,  end
    
    met ( 'print' , [ 'Writing to ' , shm{ s , 1 } ] , 'e' ) ;
    D

    met ( 'write' , shm { s , 1 } , D ) ;
    
    wflg = 1 ;
    
  end
  
  i = i + wflg ;
  
end % cntl1


function  i = cntl2 ( shm , i )
  
  rflg = 0 ;
  
  % Read each shm
  for  s = 1 : size ( shm , 1 )
    
    if  shm { s , 2 }  ~=  'r'  ,  continue  ,  end
    
    met ( 'print' , [ 'Reading from ' , shm{ s , 1 } ] , 'e' ) ;
    
    C = met ( 'read' , shm { s , 1 } ) ;
    
    for  c = 1 : numel ( C )
      
      met ( 'print' , sprintf ( 'C{ %d }' , c ) , 'e' )
      C{ c }
      
    end
    
    rflg = 1 ;
    
  end
  
  i = i + rflg ;
  
end % cntl2

