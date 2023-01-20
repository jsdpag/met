
%% Make drawing environment

% Constants

  % MET screen parameters
  p = metscrnpar ;
  
  % Screen resolution
  sres.x = 1600 ;
  sres.y = 1200 ;
  
  % Pixels per degree
  p.pixperdeg = metpixperdeg ( p.width , sres.x , p.subdist ) ;
  
  % Pixels to degrees
  sres.x = sres.x  /  p.pixperdeg ;
  sres.y = sres.y  /  p.pixperdeg ;
  
  % iViewX things
  ivx.fs = 500 ; % sampling rate
  ivx.hip = '192.168.1.3' ;
  ivx.hpt = 5555 ;
  ivx.iip = '192.168.1.2' ;
  ivx.ipt = 4444 ;
  
  % Approximate samples needed for x seconds of trace
  nsamp = ceil ( 0.2  *  ivx.fs ) ;
  
% Make axes for plotting gaze
ag = axes (  'xlim'  ,  [ -0.5 , 0.5 ] * sres.x  , ...
            'ylim'  ,  [ -0.5 , 0.5 ] * sres.y  ) ;
hold on , grid on
title ( 'gaze position' )

% Make animated line objects for drawing eye traces
lg = gobjects ( 2 , 1 ) ;

for  i = 1 : numel ( lg )
  lg( i ) = animatedline ( 'MaximumNumPoints' , nsamp , 'Marker' , '.' , ...
    'MarkerEdgeColor' , ag.ColorOrder( i , : ) , 'LineStyle' , 'none' ) ;
end

% Make axes for plotting gaze
figure
ad = axes (  'xlim'  ,  [ 0 , 1600]  ,  'ylim'  ,  [ 0 , 1600 ]  ) ;
hold on , grid on
title ( 'pupil diameter' )

% Make animated line objects for drawing eye traces
ld = gobjects ( 2 , 1 ) ;

for  i = 1 : numel ( ld )
  ld( i ) = animatedline ( 'MaximumNumPoints' , nsamp , 'Marker' , '.' , ...
    'MarkerEdgeColor' , ad.ColorOrder( i , : ) , 'LineStyle' , 'none' ) ;
end


%% Open ivxudp

ivxudp ( 'o' , ivx.hip , ivx.hpt , ivx.iip , ivx.ipt ) ;


%% Stream eye positions

% Clear points from animated lines
for  i = 1 : numel( lg )
  clearpoints ( lg( i ) )
end

% Allocate buffers
nsamp = ceil ( 10  *  ivx.fs ) ;
b = 0 ;
G = zeros ( nsamp , 4 ) ;
D = zeros ( nsamp , 4 ) ;

KbReleaseWait ;

while  ~ KbCheck  &&  b < nsamp
  
  % Read eye positions
  [ tret , ~ , gaze , diam ] = ivxudp ( 'r' ) ;
  
  % No data
  if  ~ tret
    WaitSecs ( 1 / ivx.fs ) ;
    continue
  end
  
  % Scale data to pixel resolution. X and Y coordinates
  gaze = gaze  -  0.5 ;
  gaze( : , [ 1 , 3 ] ) = + gaze( : , [ 1 , 3 ] )  *  sres.x ;
  gaze( : , [ 2 , 4 ] ) = - gaze( : , [ 2 , 4 ] )  *  sres.y ;
  
  % Loop eyes
  for  i = 1 : numel( lg )
    
    % X and Y indeces
    x = 2 * ( i - 1 ) + 1 ;
    y = 2 * i ;
    
    % Add points to gaze line
    addpoints ( lg( i ) , gaze( : , x ) , gaze( : , y ) )
    
    % And diameter line
    addpoints ( ld( i ) , diam( : , x ) , diam( : , y ) )
    
  end
  
  % Buffer data , first find index positions
  i = b + 1 : min( [ b + size( gaze , 1 ) , nsamp ] ) ;
  b = i( end ) ;
  G( i , : ) = gaze ;
  D( i , : ) = diam ;
  
  % Update plot
  drawnow
  
end


%% Close ivxudp

ivxudp ( 'c' )

