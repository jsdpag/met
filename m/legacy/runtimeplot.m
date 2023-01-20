
function  h = runtimeplot ( h , tally , t , td , ~ ) % ptbwin )
% 
% Run time plot shows performance throughout session.
% 
% h = runtimeplot - Returns a struct that contains a set of handles to
%   graphics objects. Opens a figure with all run time plots.
% 
% runtimeplot ( h , tally , t , td ) - Updates the figures. h, handle
%   returned by h = runtimeplot. tally, struct with the count of trials per
%   outcome. t, the number of trials completed. outc, character code for
%   the outcome of the latest trial.
% 
% Written by Jackson Smith - Nov 2015 - DPAG, University of Oxford
% 
  
  
  %%% Constants %%%
  
  % Number of points in animated lines
  NPOINT = 500 ;
  
  % Outcome character codes
  OUTCHAR = foutchar ;
  
  
  % Wrapper function. Decide what to do based on number of input and output
  % arguments
  
  % Make new run-time plots and return handles
  if  isempty ( h )
    
    h = newrtplot( NPOINT , OUTCHAR , [] ) ;
    
  % Update an existing plot
  elseif nargin == 5
    
    h = drawplot ( h , tally , t , td , [] , NPOINT , OUTCHAR ) ;
    
  else
    
    error ( 'runtimeplot:arguments:wrong number' )
    
  end
  
end % runtimeplot


%%% Subroutines %%%

% function  h = drawplot ( h , tally , t , td , ptbwin , NPOINT , OUTCHAR )
function  h = drawplot ( h , tally , t , td , ~ , NPOINT , OUTCHAR )
  
  
  %%% Summary line of text %%%
  
  % Percent correct
  c = OUTCHAR.CORRECT ;
  f = OUTCHAR.FAILED ;
  pc = tally.( c ) / ( tally.( c ) + tally.( f ) ) * 100 ;
  
  % outcome codes
  c = fieldnames ( tally ) ;
  
  % Join each set
  s = cell( 1 , numel( c ) + 2 ) ;
  for i = 1 : numel ( c )
    s{ i + 1 } = [ c{ i } , ': ' , num2str( tally.( c{i} ) ) ] ;
  end
  
  % Add some data
  s{ 1 } = [ 'N: ' , num2str(t) ] ;
  s{ end } = [ '% corr: ' , num2str( round(pc) ) ] ;
	
	% Join into a whole string
  s = strjoin ( s , ', ' ) ;
  
  % Report
  h.outc.Title.String = { s ; '' } ;
  
  
  %%% Update char buffer %%%
  
  % Determine char buffer index
  cb = mod( ( -1 : -1 : -NPOINT ) + t , NPOINT ) + 1 ;
  
  % Latest outcome
  h.dat.obuf( cb(1) ) = td.outcome ;
  
  
  %%% Time series %%%
  
  % If less than the buffer is full
  if t < NPOINT
    ksum = sum( h.dat.kernel( 1 : cb( 1 ) ) ) / 100 ;
  else
    ksum = 1 ;
  end
  
  % Add data point to each animated line, according to outcome
  i = 0 ;
  c = [ 0 , 0 ] ;
  for F = fieldnames ( OUTCHAR )' , f = OUTCHAR.( F{1} ) ;
    
    % Raster plot, choose y data
    i = i + 1 ;
    
    if f == td.outcome
      y = i ;
    else
      y = nan ;
    end
    
    addpoints ( h.dat.outc.( f ) , t , y )
    
    % Percentage plot
    p = h.dat.kernel * ( h.dat.obuf( cb ) == f ) / ksum ;
    
    if f == OUTCHAR.CORRECT
      c( 1 ) = p ;
    elseif f == OUTCHAR.FAILED
      c( 2 ) = p ;
    end
    
  end % outcomes
  
  % Percent correct
  addpoints ( h.dat.pcor , t , c( 1 ) / sum( c ) * 100 )
  
  % Update x-axis limit
  h.tlim( : ) = [ 1 - NPOINT , 0 ] + t ;
  
  for F = { 'outc' , 'pcor' } , f = F{1} ;
    h.( f ).XLim( : ) = h.tlim ;
  end
  
  % Kernel line
  h.dat.klin.XData( : ) = h.tlim( 2 ) : -1 : h.tlim( 1 ) ;
  
  
  %%% Bar chart %%%
  
  h.dat.nbar.YData( : ) = cell2mat( struct2cell( tally ) )' ;
  
  
  %%% Eye plots %%%
%   
%   % Get eye data
%   x = td.indev_buf.x ;
%   y = td.indev_buf.y ;
%   
%   % Turn invalid data to NaN
%   x( x <= 0 | ptbwin.size_px( 1 ) < x ) = NaN ;
%   y( y <= 0 | ptbwin.size_px( 2 ) < y ) = NaN ;
%   
%   % Target hit boxes
%   hb = cell2mat ( td.hitbox ) ;
%   
%   % PTB rect corner indeces
%   ih = [ RectLeft , RectRight ] ;
%   iv = [ RectTop , RectBottom ] ;
%   
%   % Convert to visual angle
%   x =  ( x - ptbwin.size_px( 1 ) / 2 )  /  ptbwin.pixperdeg ;
%   y = -( y - ptbwin.size_px( 2 ) / 2 )  /  ptbwin.pixperdeg ;
%   hb( ih , : ) =  ( hb( ih , : ) - ptbwin.size_px( 1 ) / 2 )  /  ...
%     ptbwin.pixperdeg ;
%   hb( iv , : ) = -( hb( iv , : ) - ptbwin.size_px( 2 ) / 2 )  /  ...
%     ptbwin.pixperdeg ;
%   
%   % Time , zeroed on start of trial
%   t = td.indev_buf.time  -  td.stim_trial( 1 ) ;
%   
%   % Event time stamps
%   ets = td.event_stim( : )'  -  td.stim_trial( 1 ) ;
%   
%   % New rect corner indeces for patch drawing
%   ih = [ RectLeft , RectLeft , RectRight , RectRight ] ;
%   iv = [ RectTop , RectBottom , RectBottom , RectTop ] ;
%   
%   % Delete old lines and shapes , reset the colour order
%   delete ( [ h.scrn.Children( : ) ;
%              h.veye.Children( : ) ;
%              h.heye.Children( : ) ] )
%   set ( [ h.scrn , h.veye , h.heye ] , 'ColorOrderIndex' , 1 )
%   
%   % Don't continue if aborted trial
%   if  td.outcome  ==  OUTCHAR.ABORT  ,  return  ,  end
%   
%   % 2D position plot
%   patch ( hb( ih , : ) , hb( iv , : ) , 'r' , 'edgecolor' , 'r' , ...
%     'facealpha' , 0.15 , 'parent' , h.scrn )
%   plot ( h.scrn , x , y , '.' )
%   
%   % Position over time
%   plot ( h.veye , t , x , '.' )
%   plot ( h.heye , t , y , '.' )
%   
%   if  isempty ( t )
%     
%     mm = [ min( ets ) , max( ets ) ] ;
%     
%   else
%     
%     mm = [ min( [ ets(   1 ) , t(   1 ) ] ) , ...
%            max( [ ets( end ) , t( end ) ] ) ] ;
%     
%   end
%   
%   h.veye.XLim = mm ;
%   h.heye.XLim = mm ;
%   
%   % Events over time
%   iv = h.veye.YLim ;
%   plot ( h.veye , [ ets ; ets ] , iv , 'color' , [ 0.8 , 0 , 0 ] )
%   plot ( h.heye , [ ets ; ets ] , h.heye.YLim , 'color' , [ 0.8 , 0 , 0 ] )
%   
%   for  i = 1 : numel ( ets )
%     
%     if  mod ( i , 2 )
%       j = iv( 2 ) ;
%       a = 'bottom' ;
%     else
%       j = iv( 1 ) ;
%       a = 'top' ;
%     end
%     
%     td.events{ i } = strrep ( td.events{ i } , '_' , '\_' ) ;
%     
%     text ( ets( i ) , j , td.events{ i } , 'fontsize' , 10 , ...
%       'horizontalalignment' , 'center' , 'verticalalignment' , a , ...
%       'Color' , 'w' , 'parent' , h.veye )
%     
%   end
  
  
  %%% Refresh plots %%%
  
  drawnow
  
  
end % drawplot


function  h = newrtplot ( NPOINT , OUTCHAR , ~ ) % ptbwin )
  
  
  %%% CONSTANTS %%%
  
  NP = 6 ;
  
  
  %%% Prepare figure panel %%%
  
  % Get screen size, base figure size on that.
  p = get( groot , 'Screensize' ) .* [ 1 , 1 , 1/4 , 1 ] ;
  p( 1 ) = 10 ;
  p( 2 ) = 2 * p( 1 ) ;
  p( 3 ) = round ( p( 3 ) ) ;
  p( 4 ) = p( 4 ) - p( 2 ) ;
  
  % Apple OSX, control room rig
  if ismac
    
    % Hack fix on parkergroup macmini
    p( 1 ) = p( 1 ) + sum ( get(groot,'screensize') .* [ 0 , 0 , 1 , 0] ) ;
    
  end
  
  % Figure properties
  p = { 'Color' , 'k' ;
        'DockControls' , 'off' ;
        'MenuBar' , 'none' ; 
        'Name' , 'Performance' ;
        'NumberTitle' , 'off' ;
        'ToolBar' , 'none' ;
        'Position' , p }' ;
  
  % Make the figure
	h.fig = figure ( p{:} ) ;
  h.fig.Position( 2 ) = 0 ;
  
  % Common axes properties
  p = { 'Color' , 'none' ;
        'Box' , 'on' ;
        'LineWidth' , 1 ;
        'XColor' , 'w' ;
        'YColor' , 'w' ;
        'TickLength' , [ 0.02 , 0.025 ] ;
        'TickDir' , 'out' ;
        'XGrid' , 'on' ;
        'YGrid' , 'on' ;
        'GridColor' , 'w' }' ;
  
  % Outcome tick labels
  tick = lower (  fieldnames ( OUTCHAR )  ) ;
  nt = numel ( tick ) ;
  
  % Percentage tick labels
  perc = 0 : 25 : 100 ;
  plab = num2cell ( perc ) ;
  plab{ 2 } = [] ; plab{ 4 } = [] ;
	
  %-- Create axes --%
  
  h.tlim = [ 1 - NPOINT , 0 ] ;
  
  % Outcome raster time series
	h.outc = subplot( NP , 1 , 1 , p{:}  , ...
    'ytick' , 1 : nt , 'yticklabel' , tick , 'ylim' , [ 0 , nt ] + 0.5 ,...
    'ydir' , 'reverse' , 'YTickLabelRotation' , 45 , ...
    'xlim' , h.tlim ) ;
  
  % Percentage correct, over time
  h.pcor = subplot( NP , 2 , 3 , p{:} , 'ylim' , [ 0 , 100 ], ...
    'ytick' , perc , 'yticklabel' , plab , 'xlim' , h.tlim ) ;
  
  % Absolute count of each outcome
  h.nbar = subplot( NP , 2 , 4 , p{:} , 'xticklabel' , tick , ...
    'xtick' , 1 : nt , 'xlim' , [ 0.25 , nt + 0.75 ] , ...
    'XTickLabelRotation' , 45 , 'Layer' , 'top' ) ;
  h.nbar.XGrid = 'off' ;
  
  % 2D diagram of response positions on monitor
%   h.scrn = subplot( 3 , 1 , 2 , p{:} , 'Layer' , 'top' , 'Units' , ...
%     'centimeters' ) ;
%   h.scrn.Position( 3 ) = h.scrn.Position( 4 ) * ptbwin.size_px( 1 ) / ...
%                                                 ptbwin.size_px( 2 ) ;
% 	h.scrn.Units = 'normalized' ;
%   h.scrn.Position( 1 ) = 0.5  -  h.scrn.Position( 3 ) / 2 ;
%   axis ( h.scrn , ...
%     [ [ -1 , 1 ] * ptbwin.size_px( 1 ) , ...
%       [ -1 , 1 ] * ptbwin.size_px( 2 ) ] / 2 / ptbwin.pixperdeg )
%   hold ( h.scrn , 'on' )
%   
%   % Horizontal and vertical eye traces
%   h.veye = subplot( NP , 1 , 5 , p{:} , 'YLim' , h.scrn.XLim , ...
%     'xticklabel' , [] ) ;
%   h.heye = subplot( NP , 1 , 6 , p{:} , 'YLim' , h.scrn.YLim ) ;
%   hold ( h.veye , 'on' )
%   hold ( h.heye , 'on' )
  
  % Set labels
  h.outc.Title.Color = 'w' ;
  h.outc.Title.FontWeight = 'normal' ;
  h.pcor.XLabel.String = 'trial number' ;
  h.pcor.YLabel.String = '% correct' ;
  h.nbar.YLabel.String = 'count' ;
%   h.scrn.XLabel.String = 'Azimuth (deg)' ;
%   h.scrn.YLabel.String = 'Elevation (deg)' ;
%   h.veye.YLabel.String = 'Azimuth (deg)' ;
%   h.heye.YLabel.String = 'Elevation (deg)' ;
%   h.heye.XLabel.String = 'Time (sec)' ;

  % Legacy version , shorten figure , first get normalised vertical
  % position of bottom row of figures
  mop = min ( [ h.pcor.OuterPosition( 2 ) , h.nbar.OuterPosition( 2 ) ] ) ;
  
  % Then subtract that from axes positions
  h.nbar.Position( 2 ) = h.nbar.Position( 2 )  -  mop ;
  h.pcor.Position( 2 ) = h.pcor.Position( 2 )  -  mop ;
  h.outc.Position( 2 ) = h.outc.Position( 2 )  -  mop ;
  
  % Flip units to pixels to that axes keep shape while figure is adjusted
  set ( [ h.nbar , h.pcor , h.outc ] , 'Units' , 'pixels' )
  
  % And reduce the height of the figure
  h.fig.Position( 4 ) = h.fig.Position( 4 )  -  mop * h.fig.Position( 4 ) ;
  h.fig.Units = 'normalized' ;
  h.fig.Position( 1 : 2 ) = 0.5  -  h.fig.Position( 3 : 4 ) / 2 ;
  
  
  %-- Other data --%
  
  % Percentage over time requires a memory of what happened, and a
  % weighting function
  
  % Outcome char buffer
  h.dat.obuf = char( zeros( NPOINT , 1 ) ) ;
  
  % Weighting function
  h.dat.kernel = exp ( -( 5 / NPOINT ) * ( 1 : NPOINT ) ) ;
  h.dat.kernel = h.dat.kernel / sum( h.dat.kernel ) * 100 ;
  
  
  %-- Animated lines and Bar chart --%
  
  % Common properties for animated lines
  p = { 'MaximumNumPoints' , NPOINT ;
        'LineWidth' , 1.5 }' ;
  
  % Define colours for each outcome
  c = OUTCHAR.CORRECT ; f = OUTCHAR.FAILED ; i = OUTCHAR.IGNORED;
  b = OUTCHAR.BROKEN ; a = OUTCHAR.ABORT ;
  
	col.( c ) = [1 1 1] * 0.8 ;
  col.( f ) = [1 0 0] * 0.8 ;
  col.( i ) = [0.5 0.5 1] * 0.8 ;
  col.( b ) = [1 1 0] * 0.8 ;
  col.( a ) = [1 0.8 1]*0.8 ;
  
  % Create a line for each outcome in the raster and percentage time plots
  for F = fieldnames ( OUTCHAR )' , f = OUTCHAR.( F{1} ) ;
    
    h.dat.outc.( f ) = animatedline( p{ : } , 'linestyle' , 'none' , ...
      'marker' , '.' , 'markeredgecolor' , col.( f ) , ...
      'markerfacecolor' , 'none' , 'parent' , h.outc );
    
  end
  
  % percent correct over time
  h.dat.pcor = animatedline( p{ : } , 'color' , col.c , ...
    'parent' , h.pcor ) ;
  
  % Weighting kernel line
  h.dat.klin = line( h.tlim(2):-1:h.tlim(1) , ...
    h.dat.kernel / h.dat.kernel(1) * 100 , ...
    'linewidth' , 1 , 'color' , [1 1 1] * 0.4 , 'parent' , h.pcor ) ;
  
  % absolute count of outcomes, bar chart
  hold ( h.nbar , 'on' )
  h.dat.nbar = bar( 1 : nt , zeros( 1 , nt ) , ...
    'FaceColor', [1 1 1] * 0.4 , ...
    'EdgeColor' , col.c , 'LineWidth' , 1.5 , 'parent' , h.nbar ) ;
  hold ( h.nbar , 'off' )
  
  
end % newrtplot

