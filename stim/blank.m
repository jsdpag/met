
function  [ type , vpar , init , stim , close , chksum ] = blank ( rfdef  )
% 
% [ type , vpar , init , close , stim , chksum ] = blank ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Draws nothing on screen, but does provide hit regions. That is, it
% provides invisible hit regions. Can be used to mask choice targets.
% 
% Variable parameters
%
%   x_coord - Horizontal (x-axis) coordinate to the centre of the hit
%     region. In degrees of visual field from the trial origin. Left is
%     negative, right is positive. Default 0.
%   
%   y_coord - Vertical (x-axis) coordinate to the centre of the hit region.
%     In degrees of visual field from the trial origin. Down is negative,
%     up is positive. Default 0.
% 
%   fradius - Formation radius, in degrees of visual field. The hit region
%     will be placed on the edge of a circle with this radius that is
%     centred on x_coord and y_coord. This allows the hit region to orbit
%     around the given point. Default 0.
%   
%   fangle - Formation angle, in degrees. The angle between the line
%     running from the centre of the circle to the hit region and a line
%     parallel to the x-axis that also passes through the centre of the
%     circle. Default 0.
% 
%   fflip - Formation flip. The location of the hit region on the formation
%     circle can be flipped an additional 180 degrees from fangle. This is
%     done for values less than zero. For values of zero or more, fangle is
%     used. This is mainly intended to be used in conjunction with positive
%     and negative coherences in a random-dot stimulus , allowing the
%     single hit region to serve as a choice target.
%   
%   htype - Use either a circular or square hit region. 0 for circular, and
%     1 for square. Default 1.
%   
%   hwidth - Width of the square hit region if type is 1, or diameter of
%     the circular hit region if type is 0. In degrees of visual field.
%     Default 1.5.
%   
%   hrotation - Rotation of the hit region. Only used if type is 1 i.e.
%     square hit region. In degrees. Default 0.
%
%   hdisp - Disparity of the hit region relative to the trial origin, in
%     degrees of visual field. Default 0. 
%   
%   hdisptol - Hit region disparity tolerance. Convergence may differ from
%     dot's disparity by up to this much for the subject to select the
%     stimulus. In degrees of visual field. Default 0.5.
% 
% NOTE: Dynamic changes to the type during a trial will be ignored.
% 
% 
% Written by Jackson Smith - April 2017 - DPAG , University of Oxford
% 
  
  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set
  vpar = {  'x_coord'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
            'y_coord'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
            'fradius'  ,  'f'  ,  4.5   ,     0  ,  +Inf  ;
             'fangle'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
              'fflip'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
              'htype'  ,  'i'  ,  1.0   ,     0  ,     1  ;
             'hwidth'  ,  'f'  ,  4.0   ,     0  ,  +Inf  ;
          'hrotation'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
              'hdisp'  ,  'f'  ,  0.0   ,  -Inf  ,  +Inf  ;
           'hdisptol'  ,  'f'  ,  0.5   ,     0  ,  +Inf  } ;
            
  % Function handles
	 init = @finit ;
   stim = @fstim ;
  close = @fclose ;
 chksum = @fchksum ;
 
 
%%% RF definition %%%
% No receptive/response field 

if numel(rfdef) > 1
  
%   % Get x location
%   i = strcmp (  varpar( : , 1 )  ,  'centre_x'  ) ;
%   varpar{ i , 3 } = rfdef(1).xcoord ;
  
  % Get y location
  i = strcmp (  vpar( : , 1 )  ,  'y_coord'  ) ;
  vpar{ i , 3 } = rfdef(end).ycoord ;
  
  % Get width
  i = strcmp (  vpar( : , 1 )  ,  'fradius'  ) ;
  vpar{ i , 3 } = abs( rfdef(end).xcoord ) ;
  
  % Get rotation direction
  i = strcmp (  vpar( : , 1 )  ,  'fangle'  ) ;
  vpar{ i , 3 } = rfdef(end).orientation ;
  
% elseif numel(rfdef) == 1
%     
%   rf_wid = rfdef(1).width ;  
%   % Get x location
%   i = strcmp (  vpar( : , 1 )  ,  'fradius'  ) ;
%   vpar{ i , 3 } = abs( rfdef(1).xcoord ) ;
%   
%   % Get y location
%   i = strcmp (  vpar( : , 1 )  ,  'y_coord'  ) ;
%   rf_y = rfdef(1).ycoord;
%   
%   if rf_y > 0 
%       vpar{ i , 3 } = rfdef(1).ycoord - rf_wid/2;
%   else
%       vpar{ i , 3 } = rfdef(1).ycoord + rf_wid/2;
%   end
%   
%   % Get rotation direction
%   i = strcmp (  vpar( : , 1 )  ,  'fangle'  ) ;
%   vpar{ i , 3 } = rfdef(1).orientation ;

else
    
  return
  
end
  
end % dot


%%% Stimulus definition handles %%%

% Trial initialisation function
function  S = finit ( vpar , tconst , ~ )
  
  
  % Initialise stimulus descriptor with a copy of variable parameters
  S.vp = vpar ;
  
  % Add 180 degrees if fflip is negative
  flip = 180  *  ( S.vp.fflip  <  0 ) ;
  
  % Translation of the dot onto the edge of the formation circle.
  S.trans = [  S.vp.fradius  *  cosd( S.vp.fangle + flip )  ;
               S.vp.fradius  *  sind( S.vp.fangle + flip )  ] ;
             
  % Find centre of hit region in MET coordinates and degrees of visual
  % field
  x = S.vp.x_coord  +  tconst.origin ( 1 )  +  S.trans ( 1 ) ;
  y = S.vp.y_coord  +  tconst.origin ( 2 )  +  S.trans ( 2 ) ;
 
  % Use a square hit region
  if   S.vp.htype
    
    % Hit region is a 7-column square definition
    c8 = tconst.MCC.SDEF.ptb.hitregion.eightcol ;
    S.hitregion = zeros ( 1 , 8 ) ;
    
    % Centre of hit region
    S.hitregion( c8.xcoord ) = x ;
    S.hitregion( c8.ycoord ) = y ;
    
    % Width and height
    S.hitregion( c8.width  ) = vpar.hwidth ;
    S.hitregion( c8.height ) = vpar.hwidth ;
    
    % Square rotation
    S.hitregion( c8.rotation ) = vpar.hrotation ;
    
    % Disparity values
    S.hitregion( c8.disp   ) = vpar.hdisp  +  tconst.origin ( 3 ) ;
    S.hitregion( c8.dtoler ) = vpar.hdisptol ;
    
    % Ignore stimulus? 1 means no.
    S.hitregion( c8.ignore ) = 1 ;
    
  % Use a circular hit region
  else
    
    % Hit region is a 5-column circle definition
    c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
    S.hitregion = zeros ( 1 , 5 ) ;

    % Centre of hit region
    S.hitregion( c6.xcoord ) = x ;
    S.hitregion( c6.ycoord ) = y ;
    
    % Radius if half the hwidth value i.e. half the diameter
    S.hitregion( c6.radius ) = vpar.hwidth  /  2 ;
    
    % Disparity values
    S.hitregion( c6.disp   ) = vpar.hdisp  +  tconst.origin ( 3 ) ;
    S.hitregion( c6.dtoler ) = vpar.hdisptol ;
    
    % Ignore stimulus? 1 means no.
    S.hitregion( c6.ignore ) = 1 ;
    
  end % hit regions
  
  
end % init


% Stimulation function
function  [ S , h ] = fstim ( S , tconst , tvar )
  
  
  %%% Variable parameter changes %%%
  
  % Hit region update not expected by default
  h = false ;
  
  % Any variable parameters changed? If stereo mode is enabled, then only
  % run this once for the left-eye buffer , which is drawn to first.
  if  ~ isempty ( tvar.varpar )  &&  tvar.eyebuf < 1
    
    
    %-- Variables --%
    
    % Point to variable parameters
    vp = tvar.varpar ;
    
    % Make a struct that tracks which parameters were changed , d for delta
    F = fieldnames( S.vp )' ;
    F = [  F  ;  num2cell(  false( size( F ) )  )  ] ;
    d = struct (  F { : }  ) ;
    
    % Remove htype from any change request
    i = ~ strcmp (  'htype'  ,  vp( : , 1 )  ) ;
    vp = vp ( i , : ) ;
    
    
    %-- New values --%
    
    for  i = 1 : size ( vp , 1 )
      
      % Save
      S.vp.( vp{ i , 1 } ) = vp{ i , 2 } ;
      
      % Mark as changed
      d.( vp{ i , 1 } ) = true ;
      
    end % new values
    
    
    %-- Handle changes --%
    
    % Set formation circle flag
    fcircle = any ( [ d.fradius , d.fangle , d.fflip ] ) ;
    
    % Set location change flag
    locflg = any ( [ d.x_coord , d.y_coord , fcircle ] ) ;
    
    % Set misc i.e. width or disparity flag
    miscflg = any ( [ d.hwidth , d.hdisp , d.hdisptol ] ) ;
    
    % Formation circle radius, angle, or fflip
    if  fcircle
      
      % Add 180 degrees if fflip is negative
      flip = 180  *  ( S.vp.fflip  <  0 ) ;

      % Translation of the dot onto the edge of the formation circle.
      S.trans = [  S.vp.fradius  *  cosd( S.vp.fangle + flip )  ;
                   S.vp.fradius  *  sind( S.vp.fangle + flip )  ] ;
      
    end % formation circle change
    
    % Formation circle or location change
    if  locflg
      
      % Calculate new location
      x = S.vp.x_coord  +  tconst.origin ( 1 )  +  S.trans ( 1 ) ;
      y = S.vp.y_coord  +  tconst.origin ( 2 )  +  S.trans ( 2 ) ;
      
    end
    
    % Assume hit region change
    h = true ;
    
    % Square hit region was changed
    if  S.vp.htype  &&  any ( [ locflg , miscflg , d.hrotation ] )      
      
      % Hit region is a 8-column square definition
      c8 = tconst.MCC.SDEF.ptb.hitregion.eightcol ;

      % Centre of hit region
      if  locflg
        S.hitregion( c8.xcoord ) = x ;
        S.hitregion( c8.ycoord ) = y ;
      end

      % Width and height
      if  d.hwidth
        S.hitregion( c8.width  ) = S.vp.hwidth ;
        S.hitregion( c8.height ) = S.vp.hwidth ;
      end

      % Square rotation
      if  d.hrotation
        S.hitregion( c8.rotation ) = S.vp.hrotation ;
      end

      % Disparity values
      if  d.hdisp  ||  d.hdisptol
        S.hitregion( c8.disp   ) = S.vp.hdisp  +  tconst.origin ( 3 ) ;
        S.hitregion( c8.dtoler ) = S.vp.hdisptol ;
      end
      
    % Circular hit region was changed
    elseif  locflg  ||  miscflg
      
      % Hit region is a 5-column circle definition
      c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;

      % Centre of hit region
      if  locflg
        S.hitregion( c6.xcoord ) = x ;
        S.hitregion( c6.ycoord ) = y ;
      end

      % Radius if half the hwidth value i.e. half the diameter
      if  d.hwidth
        S.hitregion( c6.radius ) = S.vp.hwidth  /  2 ;
      end

      % Disparity values
      if  d.hdisp  ||  d.hdisptol
        S.hitregion( c6.disp   ) = S.vp.hdisp  +  tconst.origin ( 3 ) ;
        S.hitregion( c6.dtoler ) = S.vp.hdisptol ;
      end
      
    % No hit region change
    else
      
      h = false ;
      
    end % update hit regions
    
    
  end % var par changes
  
  
end % stim


% Trial closing function
function  S = fclose ( ~ , ~ )
  
  S = [] ;
  
end % close


% Check-sum function
function  c = fchksum ( ~ )
  
  c = 0 ;
  
end % chksum

