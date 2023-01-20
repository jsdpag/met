
function  test ( MC )
  
  S = MC.SIG' ;
  S = struct ( S{ : } ) ;
  
  met ( 'print' , 'test: done initialising' , 'e' )
  
  met ( 'send' , S.mready , MC.MREADY.REPLY , [] )
  met ( 'recv' )
  
  met ( 'print' , 'test: making figure' , 'e' )
  h = figure
  
  t = 0 : 0.01 : 5 ;
  y = sin ( pi * t ) ;
  
  met ( 'print' , 'test: plotting sinusoids' , 'e' )
  l = plot ( t , y )
  
  met ( 'print' , 'test: executing drawnow' , 'e' )
  drawnow
  
  met ( 'print' , 'test: hit key to end' , 'e' )
  while  ~ KbWait
    WaitSecs ( 0.1 )
  end
  
  met ( 'print' , 'test: done' , 'e' )
  met ( 'send' , S.mquit , 0 , [] )
  
  return
  
  s = { S.mready , MC.MREADY.REPLY , GetSecs , 0 } ;
  
  MCC = metctrlconst ;
  
  % Write placeholder .met/trial so that MET doesn't crash
  % dlmwrite ( '~/.met/trial' , 1 , '' )
  
  % Do we have write access to shared memory?
  i = [ MC.SHM{ : , 2 } ]  ==  'w' ;
  EYESHM = any (  strcmp(  MC.SHM( i , 1 )  ,  'eye'  )  ) ;
  STIMSHM = any (  strcmp(  MC.SHM( i , 1 )  ,  'stim'  )  ) ;
  NSPSHM = any (  strcmp(  MC.SHM( i , 1 )  ,  'nsp'  )  ) ;
  
  % Initialise nsp shared memory structure for writing
  if  NSPSHM
    nsps = MCC.SHM.NSP.STRUC ;
    nsps.label = cellfun (  @( c )  sprintf ( 'chan%d' , c )  ,  ...
      num2cell ( 1 : 10 )  ,  'UniformOutput'  ,  false  )' ;
    nsps.label{ end + 1 } = 'digin' ;
    nsps.data = metcell ( 11 , 6 ) ;
    nsps.n = 0 ;  nsps.w = 0 ;
  end
  
  % Open PTB window , disable text clipping
  w = Screen ( 'openwindow' , 1 , 0 ) ;
  [ wpx , hpx ] = Screen ( 'windowsize' , w ) ;
  fi = Screen ( 'GetFlipInterval' , w ) ;
  hfi = fi / 2 ;
  
  global ptb_drawformattedtext_disableClipping
  ptb_drawformattedtext_disableClipping = 1 ;
  
  % Text height , vertical step, arg vector for DrawFormattedText.
  th = 10 ;
  tstep = 0 ;
  DFTARG = { w , 'Stopped' , 'center' , 'center' , [ 255 , 255 , 255 ] ,...
    [] , [] , [] , [] , [] , [ 0 , hpx / 2 , wpx , hpx / 2 + th ] } ;
  DrawFormattedText ( DFTARG { : } ) ;
  
  % Stop timer
  t = 0 ;
  
  % Signal ready to MET server
  met ( 'send' , s{ : } ) ;
  [ ~ , ~ , s ] = met ( 'recv' , 1 ) ;
  
  if  any ( s  ==  S.mquit )  ,  return  ,  end
  
  % Sync to screen
  vbl = Screen ( 'Flip' , w ) ;
  
  % Draw loop
  while  true

    % Non-blocking read
    [ n , ~ , s , c ] = met ( 'recv' ) ;
    
    % New signals
    if  n
      
      % Break condition
      if  any ( s  ==  S.mquit )  ,  break  ,  end
      
      % Check each signal
      for  i = 1 : n
        
        % Handle signal
        switch  s( i )
        
          case  S.mready
            
            % mready trigger , send reply
            if  c( i ) == MC.MREADY.TRIGGER
              
              % New onscreen message
              DFTARG{ 2 } = 'About to start' ;
              
              % Load up session directory name and trial identifier
              [ sdpath , tid ] = metsdpath ;
              td = load (  fullfile( sdpath , MC.SESS.TRIAL , tid , ...
                [ 'param_' , tid , '.mat' ] )  ) ;
              td = td.td ;
              
              % Prepare and send the first 'hit-region'
              if  STIMSHM
                stim = num2cell (  0 : numel (  td.stimlink  )  ) ;
                stim{ 1 } = true ( size (  td.stimlink  ) ) ;
                met ( 'write' , 'stim' , GetSecs , stim { : } ) ;
              end
              
              % Reset nsp shm struct
              if  NSPSHM  ,  nsps.n = 0 ;  nsps.w = 0 ;  end
              
              % Reply mready
              met ( 'send' , S.mready , MC.MREADY.REPLY , [] ) ;
              
            end
            
          case  S.mstart
            
            DFTARG{ 2 } = 'Running' ;
            tstep = 4 ;
            t = ceil (  exprnd ( 2.5 , 10 , 1 )  ) ;
            
          case  S.mwait
            
            % Wait to stop
            if  c( i )  ==  MC.MWAIT.FINISH
              DFTARG{ 2 } = 'Stopping' ;
            elseif  c( i )  ==  MC.MWAIT.ABORT
              t = -1 ; % True in if statement , guaranteed timeout
            end
            
          case  S.mrdtype
            
            met (  'print'  ,  ...
              sprintf ( 'Switching to reward type %d' , c( i ) )  ,  'e'  )
            
          case  S.mreward
            
            met (  'print'  ,  ...
              sprintf ( 'Delivering %d ms reward' , c( i ) )  ,  'e'  )
        
        end % handling
        
      end % signals
      
    end % new signals
    
    % Handle stop timer
    if  t
      
      % Subtract another frame interval
      t = t - fi ;
      
      % Timeout , stop trial and request reward , guarantee timer zero
      if  t  <=  0
        
        met ( 'send' , [ S.mrdtype , S.mreward ] , [ 1 , 2345 ] , [] ) ;
        met ( 'send' , S.mstop , MC.OUT{ 1 , 2 } , [] ) ;
        DFTARG{ 2 } = 'Stopped' ;
        tstep = 0 ;
        t = 0 ;
        
      end
      
    end % timer
    
    % Move text
    if  tstep
      
      DFTARG{ end }( [ 2 , 4 ] ) = DFTARG{ end }( [ 2 , 4 ] ) + tstep ;
      
      % Wrap around
      if  hpx  <  DFTARG{ end }( 4 )
        DFTARG{ end }( [ 2 , 4 ] ) = [ 0 , th ] ;
      end
      
      % Trial must be running if tstep non-zero , write new stim value
      stim( 2 : end ) = cellfun (  @( c )  c + 1  ,  stim ( 2 : end )  ,...
        'UniformOutput' , false ) ;
      met ( 'write' , 'stim' , GetSecs , stim { : } ) ;
      
    end % move text
    
    % Draw text
    DrawFormattedText ( DFTARG { : } ) ;
    Screen ( 'DrawingFinished' , w ) ;
    
    % MET shared memory
    if EYESHM
      eye = 2 * pi * vbl * [ 0.06 , 0.06 , 0.07 , 0.07 ] ; % angular freq
      eye( [ 1 , 3 ] ) = sin ( eye( [ 1 , 3 ] ) )  .*  [ 0.4 , 0.2 ] ;
      eye( [ 2 , 4 ] ) = cos ( eye( [ 2 , 4 ] ) )  .*  [ 0.4 , 0.2 ] ;
      eye = eye  .*  [ wpx , hpx , wpx , hpx ] ; % change unit to pixels
      eye = eye  +  [ wpx , hpx , wpx , hpx ] / 2 ; % centre on screen
      met (  'write'  ,  'eye'  ,  [ vbl , eye ]  ) ; % write to shm
    end
    
    if  NSPSHM
      nsps.data{ 1 } = mod (  nsps.n  ,  2  ) ;
      if  nsps.data{ 1 }  ,  nsps.data{ 1 } = vbl ;
      else  nsps.data{ 1 } = [] ;
      end
      nsps.w = nsps.w - 1 ;
      nsps.n = nsps.n + 1 ;
      if  nsps.data{ 1 }
        met (  'write'  ,  'nsp'  ,  nsps  ) ;
      end
    end
    
    % Flip screen
    vbl = Screen ( 'Flip' , w , vbl + hfi ) ;

  end
  
  % Close PTB
  sca
  
end % test

