function stim_par = rndparams( block , SVRULE )
  
  % Initialise output
  stim_par = block.stim_par ;
  
  N = numel( stim_par ) ;
  
  % Sort the sampling rules according to dependency. Independent variables
  % are queued first, then progressively dependent variables.
  % Q{i,1} number of variable parameters in ith stimulus. Q{i,2} sampling
  % rules.
  Q = cell( N , 2 ) ;
  
  % Load queue, unsorted
  for i = 1 : N
    
    % Make vector indexing stimulus i, for each rule
    n = numel( block.stim_var{ i } ) ;
    Q{ i , 1 } = i * ones( n , 1 ) ;
    
    % Sampling rules
    Q{ i , 2 } = block.stim_var{ i } ;
    
  end
  
  % Tranform into an index vector and struct vector.
  S = cell2mat( Q(:,1) ) ;
  Q = cell2mat( Q(:,2) ) ;
  
  % Initialise sort set to look for independent variable parameters.
  I = [ Q.rule ] == SVRULE.IND ;
  
  % Loop through dependency tree.
  while ~isempty( I )
    
    % Sample the sub set of ready parameters.
    for i = find( I )
      
      % Reference stimulus index
      rstm = Q(i).ref_stim ;
      
      % Reference stimulus parameter.
      rpar = Q(i).ref_par ;
      
      % Find the set of values we can sample from.
      val = Q(i).values ;
      
      % Remove reference value
      if Q(i).rule == SVRULE.NREF
        j = val ~= stim_par{ rstm }.( rpar ) ;
        
      % Keep only the reference value
      elseif Q(i).rule == SVRULE.REF
        j = val == stim_par{ rstm }.( rpar ) ;
        
      else
        j = true( size( val ) ) ;
        
      end % keep valid values
      
      val = val( j ) ;
       
      % Sample value
      j = ceil( numel(val) * rand ) ;
      stim_par{ S(i) }.( Q(i).param ) = val( j ) ;
      
    end % sampling
    
    % Find parameters dependent on current set I that we just sampled for.
    J = false( size( I ) ) ;
    
    for i = 1 : numel( Q )
      
      if I( i ) , continue , end
      
      J(i) = any( ...
        Q(i).ref_stim == S(I) & strcmp( Q(i).ref_par , { Q(I).param }' )...
        ) ;
      
    end
    
    % Handle the new set
    J = J( ~I ) ;
    S = S( ~I ) ;
    Q = Q( ~I ) ;
    
    I = J ;
    
  end % dependency tree
  
end % rndparams