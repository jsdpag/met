function [ type , varpar , init , stim , close , chksum ] = rdk_Shadlen ( ~ )

% random dot motion stimulus based on Shadlen papers. Dots get replotted
% every third frame. They can either be replotted as noise or as signal
% dots, which depends on the coherence. The coherence is the probability o
% of a given dot being replaced as signal dot. 
%
%%-- parameters --%%
%
%centre_x - x coordinate of stimulus aperture with random dots default = 0
%centre_Y - y coordinate of stimuls aperture default = 0 
%dotsize - radius of a single dot in degree of visual angle - default 0.05
%ap_radius - radius of stimulus aperture in degrees. default = 2.5 
%coherence - probability that dots are signal dots moving either to the
%right (+) or to the left (-) in fractions (depends on direction - see below). 
%Default is 0.5
%direction - defines whether positive coherence is defined as rightward
%direction or leftward direction - currently direction is 1 meaning that 
%positive coherences mean rightward direction 
%speed - speed of moving dots in degrees per second - default 7
%density  - density of dots in dots/squared degrees per second default 16.7
%contrast - Michelson contrast of light and dark dots on a midgrey (0.5)
%   background
%dot_type - The value provided to Screen DrawDots. Says how to render
%     dots. 0 draws square dots. 1, 2, and 3 draw circular dots with
%     different levels of anti-aliasing ; 1 favours performance [speed?], 2
%     is the highest available quality supported by the hardware, and 3 is
%     a [PTB?] builtin implementation which is automatically used if
%     options 1 or 2 are not supported by the hardware. 4 , which is
%     optimised for rendering square dots of different sizes is not
%     available as all dots will have the same size. Default 2.


 % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;


varpar = {   'centre_x' , 'f' , 0.0 ,-Inf , +Inf ; 
            'centre_y'  , 'f' , 0.0 ,-Inf , +Inf ;
            'dotsize'   , 'f' , 0.05 ,-Inf , +Inf ;
            'ap_radius' , 'f' , 2.5 ,-Inf , +Inf ;
            'coherence' , 'f' , 0.5 ,-1.0 , 1.0  ;
            'direction' , 'f' , 1   ,-1   , 1    ; 
            'speed'     , 'f' , 5   , 0   , +Inf ;
            'density'   , 'f' , 16.7 , 0.0 , +Inf ;
            'contrast'  , 'f' , 1   , 0   , 1    ;
            'dot_type'  , 'i' , 2   , 0   , 3 };


 % Function handles
	 init = @finit ;
   stim = @fstim ;
  close = @fclose ;
 chksum = @fchksum ;

end % rdk_Shadlen 


%% init function 
% Trial initialisation function
function  S = finit ( vpar , tconst , ~ )



%%% Build stimulus descriptor %%% 

% Keep a copy of variable parameters in their original units 

S.vp = vpar; 

% centre of aperture in pixels and ptb coordinates
% first the coordinate of the centre of the stimulus gets added to the
% centre of the trial origin (centre + tconst.origin), in  a next step this is transformed into
% pixels (* tconst.pixperdeg) and then transformed in a PTB coordinate system (+/- tconst.wincent).
S.centre_x = (S.vp.centre_x + tconst.origin(1)) * tconst.pixperdeg + tconst.wincentx;
S.centre_y = tconst.wincenty - ((S.vp.centre_y + tconst.origin(2)) * tconst.pixperdeg);


S.centre = [S.centre_x, S.centre_y];


% dots per frame = dots/deg^2, round up so that we always get at least
% one dot if density is non-zero 
S.Nd = ceil(pi * (S.vp.ap_radius^2) * S.vp.density * tconst.flipint);

% dotsize and diameter in pixels 
S.dotsize = tconst.pixperdeg * S.vp.dotsize;
S.dotdiameter = S.dotsize * 2;

%ap_radius in pixels 
S.ap_radius = tconst.pixperdeg * S.vp.ap_radius;

% Pixels travelled by a signal dot between each frame * 2 because I have 2
% sets of dots
S.step = 2  *  tconst.pixperdeg  *  S.vp.speed  *  tconst.flipint ;


% save coherence and direction twice 

S.coherence = S.vp.coherence;
S.direction = S.vp.direction;
% Coherence is negative. Therefore, add 180 degrees to the direction
% parameter, then make coherence positive.
if  S.coherence  <  0
    S.direction = - S.direction ;
    S.coherence = - S.coherence ;
end

%%% Dot Buffers %%% 

% Matrix with 2 sets of dots 2 * S.ND * 2. First row is is x coordinate,
% second is y coordinate, S.Nd number of columns indicates numbers of dots 
% and 3rd dimension indicates the set of dots. 


S.xy = zeros(2,S.Nd,2);

%random dot locations for all 2 sets of dots 
for i = 1:2
S.xy(:,:,i) = xypos(S.Nd, S.ap_radius);
end


% buffer for coherence probability - coherence is used as probability. If a
% randomly assigned number between 0 and 1 

S.coh = zeros(1,S.Nd);


% set index for first set of dots - increased with every frame 

S.dset = 0;

%%% Contrast %%%

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

%%-- hitregion  --%%

S.hitregion = [S.vp.centre_x + tconst.origin(1), S.vp.centre_y + ...
    tconst.origin(2),S.vp.ap_radius, 0, 0, 1];


end % init function



%% stim function

function [ S , h ] = fstim ( S , tconst , tvar )

 % Hit region update not expected by default
  h = false ;
  
  
  % Don't update variable parameters or dots if we're drawing to the
  % right-eye frame buffer because it has already been done for the
  % left-eye frame buffer
  if  tvar.eyebuf  <  1
      
          %update set of dots 
      
     S.dset = S.dset+1; 
     
     if S.dset == 3
    
          S.dset = 1;
      end
      
      %move dots - but first determine whether dots move in coherence
      %direction or randomly 
      
      S.coh = rand(1,S.Nd);
      
      %index vectors to noise and signal dots
      index_signal = find (S.coh <= S.coherence);
      index_noise = S.coh > S.coherence;
      
      %move noise dots
      
      S.xy(:,index_noise,S.dset) = xypos(sum(index_noise), S.ap_radius);
      
      %move signal dots
      
      S.xy(1,index_signal,S.dset) = S.xy(1,index_signal,S.dset) + S.step * S.direction ;
    
      % check whether dot crossed apperture, if dot crossed aperture -
      % re-plot at random location on opposite side of moving direction 
      %outside the aperture then move dot with a random distance back into 
      %the aperture 
      
      % calculate distance to aperture centre
      distance_x_centre = sqrt(S.xy(1,index_signal,S.dset).^2 + S.xy(2,index_signal,S.dset).^2 );
      
      % get signal dots that have a distance greater than the radius
      % meaning that they are outside the aperture 
      idx_dist = index_signal(distance_x_centre >= S.ap_radius);

      if sum(idx_dist) > 0      
      
        %replex y and x coordinates of the dots to a place on the opposite
        %site of the aperture 
        S.xy(2,idx_dist,S.dset) = 2 .* S.ap_radius .* rand(size(idx_dist)) - S.ap_radius;
        S.xy(1,idx_dist,S.dset) = sqrt((S.ap_radius^2) - (S.xy(2,idx_dist,S.dset).^2) );
        
        %move signal dots back into aperture 
        S.xy(1,idx_dist,S.dset) = S.xy(1,idx_dist,S.dset) - rand(size(idx_dist)) .* S.step;
        
      end
      
      % needs to be mirrored if coherence is positive 
      if S.direction > 0
          S.xy(1,idx_dist,S.dset) = - S.xy(1,idx_dist,S.dset);
      end
 
      
     
      
      
  end %tvar.eyebuf if 
  
  
  
 % Set appropriate alpha blending for correct anti-aliasing of dots
  Screen (  'BlendFunction'  ,  tconst.winptr  ,  ...
    'GL_SRC_ALPHA'  ,  'GL_ONE_MINUS_SRC_ALPHA'  ) ;
  
  
% Submit drawing instructions to PTB

Screen('DrawDots' , tconst.winptr , S.xy(:,:,S.dset), S.dotdiameter, S.colcontrast(:,S.bcon),... 
S.centre, S.vp.dot_type);


end %stim function 

%% Trial closing function 
function  S = fclose ( ~ , ~ )
  
  S = [] ;
  
end % close


%% check-sum function 
function  c = fchksum ( S )
  
  c = sum( sort( double(  S.xy( : )  ) ) ) ;
  
end % chksum

%% additional functions
%xypos function - find randomised x and y coordinates for dots, needs
%number of dots and radius of aperture in pixels 

function [XY] = xypos(n, r)

%find angles 

theta = 2*pi*rand(1,n);

% find radius 

radius = r * sqrt(rand(1,n));

%radius = r * rand(1,n);

%back to cartesian coordinate system 
XY = [radius.*cos(theta); radius.*sin(theta)];

end %xypos
