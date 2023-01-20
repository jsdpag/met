function  [ type , varpar , init , stim , close , chksum ] = cylinder_dotinangle ( ~ )
% 

%% parameters 

% width - width of cylinder in visual degrees. Default is 2. 

% height - height of cylinder in visual degrees Default is 4.

% speed - speed of dots in degree/sec. Default 7 

% disparity - disparity in visual angle. Negative disparity is clockwise,
%   positive disparity is anticlockwise rotation of cylinder. Default is 3

% centre_x -  xcoordinate of stimulus centre in visual degrees. Default 0. 

% centre_y - ycoordinate of stimulus centre in visual degrees. Defaul 0 

% dotsize - radius of a single dot in visual degrees 

% density - dot density in dots per visual degree. Default 4

%avglife - average lifetime of a dot. Drawn from a geometric function 

% contrast - Michelson contrast of light and dark dots on a midgrey (0.5)
%   background


%   dot_type - The value provided to Screen DrawDots. Says how to render
%     dots. 0 draws square dots. 1, 2, and 3 draw circular dots with
%     different levels of anti-aliasing ; 1 favours performance [speed?], 2
%     is the highest available quality supported by the hardware, and 3 is
%     a [PTB?] builtin implementation which is automatically used if
%     options 1 or 2 are not supported by the hardware. 4 , which is
%     optimised for rendering square dots of different sizes is not
%     available as all dots will have the same size. Default 2.

  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;

varpar = {           'width' , 'f', 6     , 0     ,+Inf;
                    'height' , 'f', 8     , 0     ,+Inf;
                     'speed' , 'f', 3     , 0     ,+Inf;
                 'disparity' , 'f', 0.2   , -Inf  ,+Inf;
                  'centre_x' , 'f', 0     ,-Inf   ,+Inf; 
                  'centre_y' , 'f', 0     ,-Inf   ,+Inf; 
                   'dotsize' , 'f', 0.1   , 0     ,+Inf;
                   'density' , 'f', 15    ,-Inf   ,+Inf;
                   'avglife' , 'f', 45e-3 , 0.0   ,+Inf; 
                  'contrast' , 'f', 1     , 0     , 1  ;
                  'dot_type' , 'i', 2     , 0     , 3  };

% Function handles
	 init = @finit ;
   stim = @fstim ;
  close = @fclose ;
 chksum = @fchksum ;
 
end % cylinder_dotinangle

%% init function

% Trial initialisation function
function  S = finit ( vpar , tconst , ~ )
%check:
% Disparity requested but PsychToolbox is in a monocular mode
if  vpar.disparity  &&  ~ tconst.stereo
    
    error (  'MET:cylinder:badparam'  ,  [ 'cylinder: ' , ...
        'disparity non-zero but PsychToolbox opened monocular window' ]  )
end

% Keep a copy of variable parameters in their original units
S.vp = vpar;

% keeping copy of disparity and Speed that are not getting altered
S.disparity = S.vp.disparity;
S.speed = S.vp.speed;


% centre of cylinder in pixels and ptb coordinates
% first the coordinate of the centre of the stimulus gets added to the
% centre of the trial origin (centre + tconst.origin), in  a next step this is transformed into
% pixels (* tconst.pixperdeg) and then transformed in a PTB coordinate system (+/- tconst.wincent).
S.centre_x = (S.vp.centre_x + tconst.origin(1)) * tconst.pixperdeg + tconst.wincentx;
S.centre_y = tconst.wincenty - ((S.vp.centre_y + tconst.origin(2)) * tconst.pixperdeg);


S.centre = [S.centre_x, S.centre_y];


% width and height of aperture in pixels
  S.width = tconst.pixperdeg * S.vp.width;
  S.height = tconst.pixperdeg * S.vp.height;
  
  %disparity in pixels 
   S.disparity = S.vp.disparity * tconst.pixperdeg/2;
   
 
   % dot size in pixels 
   
   S.dotdiameter = S.vp.dotsize * tconst.pixperdeg * 2;
   
   
  
% dots per aperture = dots/deg^2, round up so that we always get at least
  % one dot if density is non-zero

  
  %S.dotarea = S.vp.dotsize*2 * tconst.pixperdeg;
  %S.aperturearea = S.height * S.width;
  %S.density = S.vp.density * tconst.pixperdeg;
  S.Nd = ceil(S.vp.width  * S.vp.height * S.vp.density);

  
% translate speed from visual degree to aperture_width/frame 

% Speed in radians per second. deg/sec * pix/deg = pix/sec * 1/pix =
% 1/sec * rad = rad/sec
S.speed = ((S.vp.speed  *  tconst.pixperdeg  )/  S.width)  *  pi * tconst.flipint;
  
%%-- dot buffers --%%

% buffer for x coordinates for dot positions in rad
S.x_rad = zeros(1,S.Nd);


% dot coordinates in pixel 
S.xy_pix = zeros(2, S.Nd);



% initialise x coordinates in rad and normalise it two 2pi 

S.x_rad = rand(1,S.Nd) .* (2*pi);


% initialise y coordinates in pixel 

S.xy_pix(2,:) = (rand(1,S.Nd) - 0.5) .* S.height;



% buffer for disparity displacement for each dot 
   
   S.disppix = zeros(1.,S.Nd);


%%-- lifetime --%%

% % buffer
% S.lifetime = zeros(S.Nd, 1);
% 
% % Probability of survival. Used to sample a geometric distribution for
% % signal dot lifetimes.
% S.prob_survival = 1  /  ( S.vp.avglife / tconst.flipint )  ;
% 
% % Initialise signal dot lifetimes from a geometric distribution , add 1
% % so that the first signal dots are guaranteed to get at least 2 frames
% 
% for i = 1:S.Nd
%     S.lifetime( i ) = ...
%         ceil( log( rand( size( i ) ) )  /  log( 1 - S.prob_survival ) )  +  1 ;
% end



%%-- contrast --%%

% Michelson Contrast - we assume a midgrey background (0.5)

% S.cl is contrast of light dots, S.cd is contrast of dark dots
S.cl = 0.5*(S.vp.contrast+1);
S.cd = 0.5*(1-S.vp.contrast);


S.colcontrast = [S.cl,S.cd;S.cl,S.cd;S.cl,S.cd];

S.bcon = zeros(1,S.Nd);

%make even dots dark and odd ones light
S.bcon(1:2:end) = 1;
S.bcon(2:2:end) = 2;

%Draw dots command: S.colconstrast(:,S.bcon);

%%-- hitregion  --% 

S.hitregion = [S.vp.centre_x + tconst.origin(1), S.vp.centre_y + ...
    tconst.origin(2),S.vp.width, S.vp.height, 0, 0, 0.5, 1];

% rotation ???? do I need to rotate here and then undo rotation in stim function
% because otherwise dont know when to undo rotation for new frame 


end % initialisation function 


%% stim function 
% Stimulation function
function  [ S , h ] = fstim ( S , tconst , tvar )

h = false;

  % Don't update variable parameters or dots if we're drawing to the
  % right-eye frame buffer because it has already been done for the
  % left-eye frame buffer
  if  tvar.eyebuf  <  1
    
    %-- Handle dead dots --%
    
%       Dot index vector
%     sd = 1 : S.Nd ;
%     
%     
%     Find dead signal dot indeces
%     dead = find (  ~ S.lifetime ( sd )  ) ;
%     
%     Skip if no dead dots
%     if  dead
%         
%         S.xy_rad(1,dead) = rand(1,numel(dead)).* (2.*pi) ;
%         S.xy_pix(2,dead) = rand(1,numel(dead)).* S.height;
%         
%     end
    
    %reduce lifetime
    
    % Count down one frame from  dot lifetimes
%     S.lifetime( sd ) = S.lifetime( sd )  -  1 ;
       
       
      %%-- update x positions of dots according to speed --%%
      
      %update x rad coordinates with speed - keep positions between 0 and
      %2pi - this is better for processing and memory. We dont need to
      %scale the speed because we move around a circle. The scaling and
      %therefore changes in velocity happen automatically when we use cos
      %to get the x positons back in pixels further down. 
      
      S.x_rad = mod(S.x_rad + S.speed, (2*pi));
      
      
      %%-- calculate disparity displacement --% 
      
      % get disparity placement according to dot position and in pixels
      S.disppix = S.disparity .* sin(S.x_rad);
      
      %translate x coord from dots in pixels 
      
      S.xy_pix(1,:) = (S.width/2) .* cos(S.x_rad);
      
      % save new dot positions 
      
      S.xy = S.xy_pix;
      
      %apply disparity for left eye 
      
      S.xy_pix(1,:) = S.xy(1,:) - S.disppix;
      
  else
      
     %apply disparity for right eye 

S.xy_pix(1,:) = S.xy(1,:) + S.disppix;
   
  end %if tvar.eyebuf < 1  



% Set appropriate alpha blending for correct anti-aliasing of dots
  Screen (  'BlendFunction'  ,  tconst.winptr  ,  ...
    'GL_SRC_ALPHA'  ,  'GL_ONE_MINUS_SRC_ALPHA'  ) ;
  

  % Submit drawing instructions to PTB

Screen('DrawDots' , tconst.winptr , S.xy_pix, S.dotdiameter, S.colcontrast(:,S.bcon),... 
S.centre, S.vp.dot_type);

  
end %stimulation function 

%% Trial closing function 
function  S = fclose ( ~ , ~ )
  
  S = [] ;
  
end % close



%% check-sum function 
function  c = fchksum ( S )
  
  c = sum( sort( double(  S.xy_pix( : )  ) ) ) ;
  
end % chksum



