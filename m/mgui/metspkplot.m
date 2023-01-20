
function  [ h , update , reset , recover , close ] = metspkplot
% 
% [ h , update , reset , recover , close ] = metspkplot
% 
% Displays a real-time plot of recent spike and trial events in a scrolling
% raster plot.
% 
% Written by Jackson Smith - March 2017 - DPAG , University of Oxford
% 
  
  
  %%% Global Constants %%%
  
  % MET constants and MET controller constants
  global  MC  MCC
  
  % If these haven't been set yet then set them
  if  isempty ( MC  )  ,   MC  = met ( 'const' , 1 ) ;  end
  if  isempty ( MCC )  ,   MCC = metctrlconst        ;  end
  
  
  %%% Constants %%%
  
  % Title
  TITBAR = 'MET spike times' ;
  
  % Figure width ratio
  FIGWID = 1.5 ;
  
  % Axes height ratio
  AXEHEI = 0.95 ;
  
  % MET signal identifiers
  C.MSID = MCC.MSID ;
  
  % NSP spike channel label prefix , regular expression
  C.SPKLAB = MCC.SHM.NSP.SPKLAB ;
  
  % Unit colours. Unclassified , unit 1 , u 2 , u 3 , u 4 , u 5.
  C.UNICOL = {  'w'  ,  [ 1 , 0 , 0.7 ]  ,  'c'  ,  'y'  ,  ...
    [ 0.7 , 0 , 1 ]  ,  'g'  } ;
  
  % Trial event line colour
  C.TEVCOL = [ 0.8 , 0.8 , 0.8 ] ;
  
  % Number of seconds to plot
  C.TIMDUR = 6 ;
  
  % Estimate of maximum firing rates in multiunit and single unit channels.
  C.MURATE = 500 ;
  C.SURATE = 300 ;
  
  
  %%% GUI variables %%%
  
  % Trial initialisation flag , raise when mready trigger received and
  % lower when next 'nsp' shm arrives or if mstop received
  C.tinflg = false ;
  
  % Number of spike channels
  C.nchan = 0 ;
  
  % Unit channel map
  C.chnmap = {} ;
  
  % Row index of cbmex 'trialdata' output that contains NSP digital input
  C.digin = 0 ;
  
  % Trial event buffer. In case we ever see an mstart, mstate, or mstop
  % signal in NSP digital input that was recorded before its cargo
  C.sigbuf = [] ;
  
  % Trial start time stamp , in NSP time , to estimate when trial stop time
  % is. And also remember the PTB start time
  C.strnsp = -1 ;
  C.strptb = -1 ;
  
  % Trial stop event flag , lower when stop event is plotted
  C.stpflg = true ;
  
  % Position of last event label 0 - low , 1 - high
  C.labpos = true ;
  
  
  %%% Create figure %%%
  
  h = figure ( 'Name' , TITBAR , 'NumberTitle' , 'off' , ...
    'MenuBar' , 'none' , 'ToolBar' , 'none' , 'Color' , 'k' , ...
    'Units' , 'pixels' , 'Visible' , 'off' , 'DockControls' , 'off' ) ;
  
  % Adjust width
  h.Position( 3 ) = FIGWID  *  h.Position( 3 ) ;
  
  
  %%% Create axes %%%
  
  C.A = axes ( 'Parent' , h , 'Color' , 'none' , 'TickDir' , 'out' , ...
    'LineWidth' , 1 , 'XColor' , 'w' , 'YColor' , 'w' , 'Box' , 'on' , ...
    'XGrid' , 'off' , 'YGrid' , 'on' , 'GridColor' , [1 1 1] * 0.85 , ...
    'FontSize' , 8 ) ;
  
  % Adjust height to allow space for event labels
  C.A.Position( 4 ) = AXEHEI  *  C.A.Position( 4 ) ;
  
  
  %%% Final settings %%%
  
  % Animated lines for unclassified spikes, and classified units 1 to 5
  C.anilin = cellfun (  @( c )  animatedline ( 'Parent' , C.A , ...
    'LineStyle' , 'none' , 'Marker' , '.' , 'MarkerSize' , 4 , ...
    'MarkerEdgeColor' , c )  ,  C.UNICOL  ,  'UniformOutput'  ,  false  ) ;
  
  % Compress into a line vector
  C.anilin = [  C.anilin{ : }  ] ;
  
  % Line object constant parameters
  C.LINCON = { 'Parent'  ,  C.A  ,  'Color'  ,  C.TEVCOL  ,  ...
    'LineWidth'  ,  1 } ;
  
  % Text object constant parameters
  C.TXTCON = { 'Parent'  ,  C.A  , 'Visible'  ,  'off'  ,  ...
    'Color'  ,  C.TEVCOL  ,  'FontSize'  ,  10  ,  ...
    'HorizontalAlignment'  ,  'center'  ,  'VerticalAlignment'  ,  ...
    'bottom' } ;
  
  % Store constants for later use
  h.UserData = C ; 
  
  
  %%% Return function handles %%%
  
  update = @( h , sd , ~ , td , cbuf , ~ )  updatef( h , sd , td , cbuf ) ;
   reset = @resetf ;
 recover = @( ~ , ~ )  recoverf ;
   close = @closef ;
  
  
end % metspkplot


%%% MET GUI functions %%%

function  resetf ( ~ , ~ )
  
  % No action required
  
end % resetf


function  recoverf
  
  % No action required
  
end % recoverf


function  closef ( h )
  
  % Delete the figure , bypass close request callback
  delete ( h )
  
end % closef


function  drawnew = updatef ( h , sd , td , cbuf )


  %%% Global constants %%%
  
  global  MC  MCC
  
  
  %%% Figure constants %%%
  
  % All constants
  C = h.UserData ;
  
  % MET signal identifier map
  MSID = h.UserData.MSID ;
  
  
  %%% Initialisation %%%
  
  % We assume no changes to the plot i.e. do not request a drawnow
  drawnew = false ;
  
  
  %%% MET signalling %%%
  
  % New signals
  if  cbuf.new_msig
    
    % Trial initialisation detected
    i = cbuf.msig.sig  ==  MSID.mready ;
    
    if  any ( cbuf.msig.crg( i )  ==  MC.MREADY.TRIGGER )
      
      % Raise flags
      h.UserData.tinflg = true ;
      h.UserData.stpflg = true ;
      
      % NULL NSP trial-start time
      h.UserData.strnsp = -1 ;
      
      % Then clear the plot of event lines/labels ...
      delete( findobj( C.A , 'type' , 'line' , '-or' , 'type' , 'text' ) )
      
      % ... and spike events
      for  j = 1 : numel (  C.anilin  )
        clearpoints ( C.anilin( j ) )
      end % animated lines
      
      % Reset the time-axis
      C.A.XLim = [ 0 , C.TIMDUR ] ;
      
      % Do NOT request call to drawnow so that last trial's data stays on
      % screen until the next read from 'nsp' shared memory comes in.
      
    end % trial initialisation
    
    % Trial start
    i = cbuf.msig.sig  ==  MSID.mstart ;
    
    if  any ( i )
      
      % Check for multiple
      if  1  <  sum ( i )
        
        % Warn user
        met (  'print'  ,  ...
          'metspkplot: multiple mstart received , using most recent'  , ...
          'E'  )
        
        % Find last signal
        i = find (  i  ,  1  ,  'last'  ) ;
        
      end % multiple
      
      % Get trial start time
      h.UserData.strptb = cbuf.msig.tim( i ) ;

    end % trial start
    
    % Trial stopped , lower initialisation flag
    i = cbuf.msig.sig  ==  MSID.mstop ;
    
    if  any ( i )
      
      % Check for multiple
      if  1  <  sum ( i )
        
        % Warn user
        met (  'print'  ,  ...
          'metspkplot: multiple mstop received , using most recent'  , ...
          'E'  )
        
        % Find last signal
        i = find (  i  ,  1  ,  'last'  ) ;
        
      end % multiple
      
      % Lower trial initialisation flag if it was up
      h.UserData.tinflg = false ;
      
      % And plot the outcome of the trial with the approximate timing. This
      % is because the final package of 'nsp' data will be ignored, as it
      % comes with an obsolete trial identifier
      if  h.UserData.stpflg  &&  h.UserData.strnsp  ~=  -1
        
        % Time of event is PTB-stop min PTB-start plus NSP-start
        tim = cbuf.msig.tim( i ) - h.UserData.strptb + h.UserData.strnsp ;
        
        % Outcome line and text
        EVTXT = text (  tim  ,  C.A.YLim( 2 )  ,  ...
          MC.OUT{ cbuf.msig.crg( i ) , 1 }  ,  C.TXTCON { : }  ) ;
        line (  [ tim ; tim ]  ,  C.A.YLim'  ,  C.LINCON { : }  )
        
        % Raise label if last one was low
        if  ~ h.UserData.labpos
          EVTXT.Position( 2 ) = EVTXT.Position( 2 )  +  EVTXT.Extent( 4 ) ;
        end
        
        % Show label
        EVTXT.Visible = 'on' ;
        
        % Flip label flag
        h.UserData.labpos = ~ h.UserData.labpos ;
        
        % Lower stop flag
        h.UserData.stpflg = false ;
        
        % Request drawnow
        drawnew = true ;
        
      end % outcome line
      
    end % mstop MET signal
    
  end % MET signals
  
  
  %%% nsp shared memory %%%
  
  % There is no new 'nsp' shared memory , nothing else to do so return
  if  isempty ( cbuf.shm )  ,  return  ,  end
  
  % Find readable shared memory
  i = [ cbuf.shm{ : , 2 } ]  ==  'r' ;

  % If we can't read 'nsp' shared memory then there is nothing else to do
  if  ~ any (  strcmp(  cbuf.shm( i , 1 )  ,  'nsp'  )  )
    return
  end
  
  % Point to trial identifier
  tid = cbuf.nsp { MCC.SHM.NSP.TIDIND } ;
  
  % This 'nsp' shm read did not come from this trial, ignore it
  if  tid  ~=  td.trial_id  ,  return  ,  end
  
  % Point to new data
  nsp = cbuf.nsp { MCC.SHM.NSP.DATIND } ;
  
  
  %-- Trial initialisation --%
  
  % Check that channel labels are correct
  if  h.UserData.tinflg

    % Lower initialisation flag
    h.UserData.tinflg = false ;

    % Find front-end spike channels
    chan = regexp (  nsp.label  ,  C.SPKLAB  ,  'once'  ) ;

    % Guarantee that chan is a cell array
    if  ~ iscell ( chan )  ,  chan = { '' } ;  end

    % Extract channel label strings and reverse order
    i = ~ cellfun (  @isempty  ,  chan  ) ;
    str = nsp.label ( i ) ;
    str = str ( end : -1 : 1 ) ;

    % Compare these to existing channel labels , update the axes if they
    % are different
    if  numel ( str )  ~=  numel ( C.A.YTickLabel )  ||  ...
        ~ all (  strcmp ( str , C.A.YTickLabel )  )

      % We need drawnow to be called
      drawnew = true ;

      % Reset graphics object bundle and time vectors
      delete( findobj( C.A , 'type' , 'line' , '-or' , 'type' , 'text' ) )

      % The number of channels
      h.UserData.nchan = numel ( str ) ;

      % NSP digital input row vector
      h.UserData.digin = ...
        find ( strcmp(  nsp.label  ,  MCC.SHM.NSP.DINLAB  ) ) ;

      % Channel index vector mapping
      j = h.UserData.nchan : -1 : 1 ;
      h.UserData.chnmap = num2cell (  j'  ) ;
      
      % Keep only every fifth channel label , first find those that are not
      % one of every fifth ...
      i = 0  ~=  mod (  j  ,  5  ) ;
      
      % ... then make the label an empty string
      str( i ) = { '' } ;

      % Set y-axis limit
      C.A.YLim = [ 0.5 , h.UserData.nchan + 0.5 ] ;

      % Set y-axis tick positions ...
      C.A.YTick = [  h.UserData.chnmap{ end : -1 : 1 }  ] ;

      % ... and labels
      C.A.YTickLabel = str ;

      % Adjust maximum number of points per animated line. Start with
      % multiunit line and round up to next power of 2.
      n = log2 ( h.UserData.nchan  *  C.MURATE  *  C.TIMDUR ) ;
      C.anilin( 1 ).MaximumNumPoints = 2  ^  ceil ( n ) ;

      % And do the same for single unit lines
      n = log2 ( h.UserData.nchan  *  C.SURATE  *  C.TIMDUR ) ;
      set (  C.anilin ( 2 : end )  ,  ...
        'MaximumNumPoints'  ,  2 ^ ceil( n )  )

    end % update axes
    
    % Empty signal buffer
    h.UserData.sigbuf = [] ;

  end % trial init
  
  
  %-- Trial events --%
  
  % Initialise tmax
  tmax = -Inf ;
  
  % New NSP digital input available
  if  ~ isempty (  nsp.data{ h.UserData.digin , MCC.SHM.NSP.DINTIM - 1 }  )

    % Point to digital input values and NSP times
    v = nsp.data { h.UserData.digin , MCC.SHM.NSP.DINVAL - 1 } ;
    t = nsp.data { h.UserData.digin , MCC.SHM.NSP.DINTIM - 1 } ;
    
    % First look for any lost cargo i.e. Captain Hook Cargo. This is only
    % valid if a hanging signal was seen in the last NSP SHM read.
    if  ~ isempty ( h.UserData.sigbuf )
      
      % Lost cargo detected
      if  v( 1 ) > MCC.SHM.NSP.SIGMAX
      
        % Add the missing signal identifier and sample time in front of the
        % lost cargo
        t = [  h.UserData.sigbuf( 1 )  ,  t  ] ;
        v = [  h.UserData.sigbuf( 2 )  ,  v  ] ;
        
      end % lost cargo
      
      % Empty signal buffer in either case , because any new lost cargo is
      % unlikely to match the hanging signal of the previous read
      h.UserData.sigbuf = [] ;
      
    end % hanging signal previously buffered
    
    % Second, look for hanging signal identifiers with no cargo in the
    % current NSP SHM read
    if  v( end )  <=  MCC.SHM.NSP.SIGMAX
      
      % Store the signal identifier and NSP sample time
      h.UserData.sigbuf = [  v( end )  ,  t( end )  ] ;
      
      % Get rid of the hanging signal from v and t
      v( end ) = [] ;  t( end ) = [] ;
      
    end % hanging signals
    
    % Locate signal IDs and cargo values in the digin integer codes
    isig = v  <=  MCC.SHM.NSP.SIGMAX ;
    icrg = v  >   MCC.SHM.NSP.SIGMAX ;
    
    % Find valid sigals, where a signal ID was followed by a cargo
    j = find ( isig( 1 : end - 1 )  &  icrg( 2 : end ) ) ;
    
    % Extract signal ID values and times in register with cargos
    tim = t ( j     ) ;
    sig = v ( j     ) ;
    crg = v ( j + 1 ) ;
    
    % Apply bit-shift to cargo to get its actual data. Drop down to the
    % lower 8 bits. Remember , cargos are pushed out from port 2 of the
    % USB-1208fs , the upper 8 bits of the 16-bit integer.
    crg = bitshift ( crg , MCC.SHM.NSP.BSHIFT ) ;
    
    % Look for any signal identifiers that were followed by another signal
    % ID instead of a cargo
    j = find ( isig( 1 : end - 1 )  &  isig( 2 : end ) ) ;
    
    if  ~ isempty (  j  )
      
      % We found some signals with no cargos. These are not at the end of
      % the NSP SHM read, so there is no real hope of the cargo being the
      % first value of the upcoming read. We will add the signal ID and NSP
      % sample time but with an illegal cargo value (less than zero) that
      % we can check for later.
      tim = [  tim  ,  t( j )  ] ;
      sig = [  sig  ,  v( j )  ] ;
      crg = [  crg  ,  - ones(  1  ,  numel( j )  )  ] ;
      
      % Sort back into chronological order
      [ tim , j ] = sort (  tim  ) ;
      sig = sig ( j ) ;  crg = crg ( j ) ;
      
    end % cargoless signals
    
    % Filter out un-monitored signals , keep those concerning trial events
    i = sig == MSID.mstart  |  sig == MSID.mstate  |  sig == MSID.mstop  ;
    
    % New trial events detected
    if  any ( i )
    
      % MET signal identifiers , cargos , and times
      sig = sig( i ) ;
      crg = crg( i ) ;
      tim = tim( i ) ;
      
      % Ask for drawnow
      drawnew = true ;
      
      % Maximum event time
      tmax = max ( tim ) ;

      % Event strings , initialise with empty strings
      str = cell ( size(  sig  ) ) ;
      str( : ) = { '' } ;

      % mstart event
      i = sig  ==  MSID.mstart ;
      
      % Grab NSP start time
      if  any ( i )
        
        % Yar! But there be many.
        if  1  <  sum (  i  )
          
          % Tell user
          met (  'print'  ,  [ 'metspkplot: too many mstart sigs ' , ...
            'from NSP , using most recent' ]  ,  'E'  )
          
          % Take most recent mstart , only
          j = find (  i  ,  1  ,  'last'  ) ;
          
          % And remove all other entries
          i = i( 1 : j - 1 ) ;
          sig( i ) = [] ;
          crg( i ) = [] ;
          tim( i ) = [] ;
          str( i ) = [] ;
          
          % Generalise variable name and recompute index of event
          i = sig  ==  MSID.mstart ;
          
        end % too many mstarts
        
        % Add mstart event string
        str( i ) = {  sprintf( 'trial %d' , td.trial_id )  } ;
        
        % Get nsp mstart time
        h.UserData.strnsp = tim( i ) ;
        
      end % nsp mstart time
      
      % mstate events with valid cargos
      j = find ( sig  ==  MSID.mstate ) ;
      
      if  ~ isempty ( j )
        
        % Locate valid cargos , remember that we initialised missing cargos
        % with -1. Also guarantee that cargo's give a valid state index.
        i = -1 < crg( j )  &  crg( j ) <= sd.logic.( td.logic ).N.state ;
        
        % Get state names for event labels
        str( j( i ) ) = sd.logic.( td.logic ).nstate(  crg( j( i ) )  ) ;
        
        % Now locate missing cargos
        i = ~ i ;
        
        % And use a generic event-type label
        str( j( i ) ) = { '<state>' } ;
        
      end % mstate events

      % mstop event
      i = sig  ==  MSID.mstop ;
      
      % Only add trial stop event if the stop flag is still raised.
      % Otherwise, delete the entry.
      if  any ( i )  &&  h.UserData.stpflg
        
        % Shiver me timbers! Thar's too much, says I.
        if  1  <  sum (  i  )
          
          % Tell user
          met (  'print'  ,  [ 'metspkplot: too many mstop sigs ' , ...
            'from NSP , using most recent' ]  ,  'E'  )
          
          % Take most recent mstart , only
          j = find (  i  ,  1  ,  'last'  ) ;
          
          % And remove all other entries
          i = i( 1 : j - 1 ) ;
          sig( i ) = [] ;
          crg( i ) = [] ;
          tim( i ) = [] ;
          str( i ) = [] ;
          
          % Generalise variable name and recompute index of event
          i = sig  ==  MSID.mstop ;
          
        end % too many
        
        % Event string when we have valid cargo ...
        if  -1 < crg( i )  &&  crg( i ) <= size( MC.OUT , 1 )
          
          str( i ) = MC.OUT ( crg( i ) , 1 ) ;
          
        % ... and when we don't
        else
          
          str{ i } = '<end trial>' ;
          
        end % mstop string
        
        % Lower stop flag
        h.UserData.stpflg = false ;
        
      % Dammit, Jim, this is no time to be making event strings!
      else
        
        sig( i ) = [] ; %#ok
        crg( i ) = [] ; %#ok
        tim( i ) = [] ;
        str( i ) = [] ;
        
      end % mstop event
      
      % Only add lines/labels if any remain to be added
      if  ~ isempty (  tim  )

        % Make event lines
        line (  [ tim ; tim ]  ,  C.A.YLim'  ,  C.LINCON { : }  )

        % Make event line labels
        y = C.A.YLim( 2 )  *  ones( size(  tim  ) ) ;
        EVTXT = text (  tim  ,  y  ,  str  ,  C.TXTCON { : }  )' ;

        % High position
        y = EVTXT( 1 ).Position( 2 )  +  EVTXT( 1 ).Extent( 4 ) ;

        % Raise even labels if position flag is high
        if  h.UserData.labpos
              j = 2 : 2 : numel( EVTXT ) ;

        % Otherwise, raise odd labels
        else  j = 1 : 2 : numel( EVTXT ) ;
        end

        % Get set of raised positions
        for  j = j  ,  EVTXT( j ).Position( 2 ) = y ;  end

        % Make all new text objects visible
        set (  EVTXT  ,  'Visible'  ,  'on'  )

        % Flip flag value if there are an odd number of labels
        if  mod (  numel ( EVTXT )  ,  2  )

          h.UserData.labpos = ~ h.UserData.labpos ;

        end
        
      end % non-empty event times & strings
    
    end % new trial events

  end % new NSP digital input
  
  
  %-- Spike events --%
  
  % Keep only front end channels
  nsp.data( h.UserData.nchan + 1 : end , : ) = [] ;

  % Find data/unit combinations with new events
  i = ~ cellfun (  @isempty  ,  nsp.data  ) ;
  
  % New spike events available
  if  any ( i( : ) )

    % Request drawnow
    drawnew = true ;
    
    % Maximum spike time
    spkmax = max ( [ nsp.data{ i } ] ) ;
    
    % Update maximum time
    if  tmax  <  spkmax  ,  tmax = spkmax ;  end

    % Handle events for each classification of spike: unclassified, & 1 : 5
    for  j = 1 : numel (  C.anilin  )

      % No spike events for this classification
      if  ~ any (  i ( : , j )  )  ,  continue  ,  end

      % Make y-axis positions based on which channel the spikes came from
      chan = cellfun(  @( d , c )  repmat ( c , size( d ) )  , ...
        nsp.data( i( : , j ) , j )  ,  h.UserData.chnmap( i( : , j ) ) ,...
        'UniformOutput'  ,  false  ) ;

      % Add spikes to animated line that represents this unit
      % classification
      addpoints (  C.anilin( j )  ,  ...
        [  nsp.data{ i( : , j ) , j }  ]  ,  [  chan{ : }  ]  )

    end % animated lines
  
  end % new spike events
  
  
  %-- Time axis limits --%
  
  % Maximum event time exceeds upper limit of time axis
  if  C.A.XLim ( 2 )  <  tmax
    
    % Re-centre time axis on new time limit
    C.A.XLim = [  - C.TIMDUR / 3  ,  2 / 3 * C.TIMDUR  ]  +  tmax ;
    
  end % time lim
  
  
end % updatef

