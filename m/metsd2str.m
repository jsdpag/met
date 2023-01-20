
function  s = metsd2str ( sd )
% 
% s = metsd2str ( sd )
%
% Written by Jackson Smith - 2016 - DPAG , University of Oxford
% 
  
  %%% Global Constants %%%
  
  global  MCC
  
  % If these haven't been set yet then set them. Note , only compile-time
  % MET constants asked for if not already declared.
  if  isempty ( MCC )  ,  MCC = metctrlconst    ;  end
  
  
  %%% Check input %%%
  
  % Must provide a valid session descriptor for sd
  if  isempty ( sd )  ||  ~ isstruct ( sd )  ||  ...
      numel( fieldnames( sd ) ) ~= numel( fieldnames( MCC.DAT.SD ) )  ||...
      ~all ( strcmp ( fieldnames( sd ) , fieldnames( MCC.DAT.SD ) ) )
    
    error ( 'MET:metsd2str:input' , ...
      'metsd2str: no valid session descriptor given' )
    
  end
  
  
  %%% Constants %%%
  
  % Comment character
  C = MCC.REX.COMMENT ;
  
  % Newline char
  NL = sprintf ( '\n' ) ;
  
  % Fields to access i.e. sections to write
  F = { 'evar' , 'task' , 'var' , 'block' } ;
  
  % Lines per declaration
  LPD = [ 1 , 1 , 1 , 2 ] ;
  
  % Sub-sections to write in task declarations
  FTSK = { 'link' , 'def' , 'sevent' , 'mevent' } ;
  
  
  %%% Count number of strings to write %%%
  
  % Initialise with main header comments
  N = 4 ;
  
  for  i = 1 : numel ( F ) , f = F{ i } ;
    
    % Name of all items of this kind
    fn = fieldnames ( sd.( f ) ) ;
    
    % Count lines
    N = N + numel ( fn ) * LPD( i ) ;
    
    % Continue unless a task declaration
    if  ~ strcmp ( f , 'task' )  ,  continue  ,  end
    
    % Count sub-declarations of task , for each task
    for  j = 1 : numel ( fn ) , ft = fn{ j } ;
      
      for  k = 1 : numel ( FTSK ) , fs = FTSK{ k } ;
        
        % There are no declarations of this type , go to next
        if  isempty (  sd.( f ).( ft ).( fs )  )  ,  continue  ,  end
        
        % def is a struct array , count number of elements rather than
        % fields
        switch  fs
          case  'def' , d = sd.( f ).( ft ).( fs ) ;
          otherwise   , d = fieldnames ( sd.( f ).( ft ).( fs ) ) ;
        end

        % Count
        N = N  +  numel ( d ) ;
      
      end % task sub-declarations
      
    end % tasks
    
  end % main declarations
  
  
  %%% Gather strings %%%
  
  % Set aside a cell array to gather strings
  si = 1 ;
  s = cell ( 1 , N ) ;
  
  % Write env vars comment
  s{ si } = sprintf ( '\n\n%c Environment variables\nevar\n\n' , C ) ;
  
  % Loop env vars
  fn = fieldnames ( sd.evar ) ;
  for  i = 1 : numel ( fn ) , f = fn{ i } ;
    
    % Convert numbers to strings
    n = num2cell ( sd.evar.( f ) ) ;
    n = cellfun ( @( c ) num2str( c ) , n , 'UniformOutput' , false ) ;
    
    % Connect to evar name
    si = si + 1 ;
    s{ si } = [ '  ' , f , '  ' , strjoin( n , '  ' ) , NL ] ;
    
  end % env var
  
  % Write task declarations
  si = si + 1 ;
  s{ si } = sprintf ( '\n\n%c Task declarations' , C ) ;
  
  % Loop tasks
  fn = fieldnames ( sd.task ) ;
  
  for  i = 1 : numel ( fn ) , f = fn{ i } ;
    
    % Task name and logic
    si = si + 1 ;
    s{ si } = ...
      [ NL , 'task' , '  ' , f , '  ' , sd.task.( f ).logic , NL ] ;
    
    % Loop sub-sections of task declaration
    for  j = 1 : numel ( FTSK ) , fs = FTSK{ j } ;
      
      % Current component struct
      c = sd.task.( f ).( fs ) ;
      
      % But there is no such section in this task declaration , go to next
      if  isempty ( c )  ,  continue  ,  end
      
      % Get ordered set of values 
      switch  fs
        
        case  'link'
          
          nam = fieldnames ( c ) ;
          stm = metgetfields ( c , 'stim' )' ;
          def = metgetfields ( c , 'def'  )' ;
          
          V = [ nam , stm , def ] ;
          
        case  'def'
          
          typ = { c.type }' ; nam = { c.name }' ;
          vpn = { c.vpar }' ; val = { c.value }' ;
          
          val =  cellfun ( @( c ) num2str( c ) , ...
            val , 'UniformOutput' , false ) ;
          
          V = [ typ , nam , vpn , val ] ;
          
        case  'sevent'
          
          nam = fieldnames ( c ) ;
          sta = metgetfields ( c , 'state' )' ;
          lnk = metgetfields ( c , 'link' )' ;
          vpn = metgetfields ( c , 'vpar' )' ;
          val = metgetfields ( c , 'value' )' ;
          
          val =  cellfun ( @( c ) num2str( c ) , ...
            val , 'UniformOutput' , false ) ;
          
          V = [ nam , sta , lnk , vpn , val ] ;
          
        case  'mevent'
          
          nam = fieldnames ( c ) ;
          sta = metgetfields ( c , 'state' )' ;
          sig = metgetfields ( c , 'msignal' )' ;
          crg = metgetfields ( c , 'cargo' )' ;
          
          crg =  cellfun ( @( c ) num2str( c ) , ...
            crg , 'UniformOutput' , false ) ;
          
          V = [ nam , sta , sig , crg ] ;
          
      end
      
      % Write lines
      for  k = 1 : size ( V , 1 )
        
        si = si + 1 ;
        s{ si } = ...
          [ '  ' , strjoin( [ { fs } , V( k , : ) ] , '  ' ) , NL ] ;
        
        if  k == 1 , s{ si } = [ NL , s{ si } ] ; end
        
      end % lines
      
    end % sub-sections
    
    % Pop on a final newline
    s{ si } = [ s{ si } , NL ] ;
    
  end % tasks
  
  
  % Task variables
  si = si + 1 ;
  s{ si } = sprintf ( '\n%c Task variables\n' , C ) ;
  
  % Get name and parameters
  nam = fieldnames ( sd.var ) ;
  tsk = metgetfields ( sd.var , 'task' )' ;
  typ = metgetfields ( sd.var , 'type' )' ;
  obj = metgetfields ( sd.var , 'name' )' ;
  vpn = metgetfields ( sd.var , 'vpar' )' ;
  dep = metgetfields ( sd.var , 'depend' )' ;
  dis = metgetfields ( sd.var , 'dist' )' ;
  val = metgetfields ( sd.var , 'value' )' ;

  V = [ nam , tsk , typ , obj , vpn , dep , dis , val ] ;
  
  % Loop task vars
  for  i = 1 : size ( V , 1 )
    
    % Numbers to strings
    val =  cellfun ( @( c ) num2str( c ) , ...
      num2cell ( V { i , end } ) , 'UniformOutput' , false ) ;
    
    val = strjoin ( val ) ;
    
    si = si + 1 ;
    s{ si } = ...
      strjoin ( [ { 'var' } , V( i , 1 : end - 1 ) , { val } ] , '  ' ) ;
    s{ si } = [ s{ si } , NL ] ;
    
  end % task vars
  
  
  % Block declarations
  si = si + 1 ;
  s{ si } = sprintf ( '\n\n%c Block declarations\n' , C ) ;
  
  % Loop blocks
  fn = fieldnames ( sd.block ) ;
  
  for  i = 1 : numel ( fn ) , f = fn { i } ;
    
    % Block component struct
    c = sd.block.( f ) ;
    
    % Block header
    si = si + 1 ;
    s{ si } = sprintf ( 'block  %s  %d  %d\n' , f , c.reps , c.attempts ) ;
    
    % Variable list
    si = si + 1 ;
    s{ si } = [ sprintf( '  %s' , c.var { : } ) , NL , NL ] ;
    
  end % blocks
  
  
  %%% Glue strings together %%%
  
  s = [ s{ : } ] ;
  
  
end % metsd2str

