
function  [ type , varpar , init , stim , close , chksum ] = ...
                                                       singrating ( rfdef )
% 
% [ type , varpar , init , stim , close , chksum ] = singrating ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% Draws a sinusoidal grating viewed through a circular aperture. Many sine
% gratings can be drawn in a circular formation.
% 
% 
% Variable parameters:
%
%   
%   %-- formation circle --%
%   
%   The formation circle is used only to position sine gratings relative to
%   each other ; it is not drawn. The centre of each grating is placed at a
%   unique point on the circumfrance of the formation circle such that
%   every pair of neighbouring gratings is separated by the same angle as
%   every other pair. Thus, four gratings on the formation circle's
%   circumfrance will have pi/2 radians (90 degrees) between each pair.
%   Typically, the centre of the formation circle is provided and then
%   grating centres are rotated around that. Alternatively, one grating
%   centre can be pinned to a point while the rest of the formation circle
%   is spun around it.
%   
%   fnumsg - The number of sine gratings to draw.  Default 4.
%   
%   fxcoord - Horizontal i.e. x-axis coordinate of the centre of the
%     formation circle. In degrees of visual field from the trial origin.
%     Left is negative, right is positive. Default 0.
%   
%   fycoord - Vertical i.e. y-axis coordinate of the centre of the
%     formation circle. In degrees of visual field from the trial origin.
%     Down is negative, up is positive. Default 0.
%   
%   fradius - Radius of the formation circle, in degrees of visual field.
%     Default 4.5.
%   
%   frotation - Counter-clockwise rotation of the formation circle, in
%     degrees. That is, the rotation of gratings around the centre of the
%     formation circle. When set to zero, the first grating is placed
%     immediately to the right of the formation circle centre ; at 90
%     degrees, the first grating is directly above. Default 0.
%   
%   ffirst - Index of the first drawn RDS. This allows fewer RDSs to be
%     drawn than indicated by fnumsg, while retaining the same formation
%     as with fnumsg patches. For instance, if fnumsg is 4 but ffirst is
%     2 while frotation is 0, then 3 patches are drawn with angles of pi/2,
%     pi, and 3*pi/2 separating each neighbouring pair. Default 1.
%   
%   flast - Index of the final drawn patch. Must be equal to or greater
%     than ffirst, and equal to or less than fnumsg. Default 4.
%   
%   fyoke - Grating position index (see fposition), integer ranging from 0
%     to N. If zero, then the centre of the formation circle is placed at
%     the point marked by fxcoord and fycoord. If non-zero, then all
%     gratings are translated so that the yoked grating position is centred
%     at ( fxcoord , fycoord ). But  the relative position of all gratings
%     remains the same as if fyoke were zero. In other words, each grating
%     is placed around the centre of the formation circle according to its
%     radius and rotation ; then all gratings are translated so that the
%     specified grating has its centre on ( fxcoord , fycoord ). May be
%     less than ffirst or greater than flast. Default 0.
%   
%   fposition - The first grating position sits on the edge of the
%     formation circle at frotation degrees of counter-clockwise rotation
%     around the circle's centre. The second to N positions are hence a
%     further 360 / N degrees, each step. fposition says at which point the
%     first grating will be placed, followed counter-clockwise around the
%     circumfrance by the second to Nth grating. In other words, the ith
%     grating will be placed at frotation + 360 / N * ( i + fposition - 2 )
%     degrees around the edge of the formation circle. Thus fposition must
%     be an integer of 1 to N. Default 1.
% 
% 
%   %-- sinusoidal grating --%
%   
%   The following values are applied to all sinusoidal gratings around the
%   formation circle.
%
%   monovis - A flag stating which monocular images are visible. A non-zero
%     value causes the grating to be visible in either the left (1) or
%     right (2) eye, only. A value of zero allows both monocular images to
%     be seen. Default 0.
%   
%   width - Diameter of the grating, in degrees of visual field. Default 4.
%   
%   orientation - The sinusoid varies along one axis ; the orthogonal axis
%     has a constant greyscale value for any given position on the axis of
%     sinusoidal variation. It is the angle of the second, orthogonal axis
%     that is given by this parameter, in degrees of counter-clockwise
%     rotation. For a value of zero, the lines of the grating will be
%     horizontal, at 45 degrees the lines will run between the bottom-left
%     and top-right of the aperture, and at 90 degrees the lines will be
%     vertical. Default 0.
%   
%   delta_orient - An additional value that is added to 'orientation' prior
%     to its use on the grating, in degrees. For instance, if orientation
%     is 90 degrees and delta_orient is 2.5 degrees, then the sinusoidal
%     gratings will all be at orientation + delta_orient = 90 + 2.5 = 92.5
%     degrees. This can be used in combination with a MET stimulus event to
%     cause relative changes in orientation during a trial. Default 0.
%   
%   phase - The offset of the sinusoid along its axis of variation, in
%     degrees. This is defined so that for an orientation of zero, a phase
%     of zero will cause the sinusoid to reach a value of zero in the
%     middle of the aperture, and start rising in an upwards direction
%     while its value lowers in a downwards direction. Default 0.
%   
%   rate - The number of cycles per second that traverse the grating. One
%     way to think of this is from the perspective of a single pixel inside
%     the grating. If the greyscale of that pixel is plotted over time,
%     then rate is the number of full sinusoidal cycles that occur per
%     second. This is implemented by adding a speed to the grating (see
%     below). Default 0.
%   
%   speed - The degrees of visual field travelled per second by a fixed
%     point on the sinusoid. The speed and orientation + 90 provide the
%     polar coordinates of the direction vector that the sinusoid travels
%     in. Speed is applied by increasing the phase at an appropriate rate ;
%     if both speed and phase are non-zero, then phase gives only the
%     starting phase on the first frame. Default 0. [NO LONGER AVAILABLE,
%     BUT WE KEEP THIS HERE TO REMIND YOU HOW WE THINK OF SPEED]
%   
%   freq - The frequency of the sinusoid in cycles per degree of visual
%     field. Default 1.
%   
%   contrast - The Michelson contrast of the sinusoid. Default 1.
%   
%   disparity - Baseline horizontal disparity value in degrees of visual
%     field, where negative is convergent, positive is divergent, and zero
%     is in the plane of fixation. The left and right monocular images are
%     both shifted in opposite directions by half this amount to create a
%     full disparity. Default 0.
%   
%   delta_disp - Some additional amount of disparity added to the baseline
%     value, in degrees of visual field. This is to enable MET stimulus
%     events to change singrating disparity relative to an existing
%     disparity. Default 0.
% 
%
%   %-- Hit region --%
%   
%   hminrad - Minimum radius of the hit region around each grating, in
%     degrees of visual field. Defautl 0.8.
%   
%   hdisptol - Hit region disparity tolerance. Convergence may differ from
%     dot patch disparity by up to this much for the subject to select the
%     stimulus. In degrees of visual field. Default 0.5.
%
%   hitcheck - A flag saying whether or not to compare the hit regions of
%     this stimulus against eye or touchscreen/mouse positions. A non-zero
%     value enables checking. A value of zero disables checking. May be 0
%     or 1. Default 1.
% 
% 
% When rfdef is non-empty, then default variable parameters will be set to
% match the preferences of RF number 1 i.e. rfdef( 1 ). The formation
% circle radius will be adjusted to run through the RF location, while the
% formation circle rotation will be adjusted to place the first grating
% onto the RF. The width, orientation, and speed of all gratings will be
% matched to the preferences of that RF.
% 
% NOTE: Being a deterministic stimulus, the checksum always returns zero.
% 
% NOTE: Stimulus events that ask for a change to fnumsg, ffirst, flast, or
%   width will be silently ignored. 
% 
% 
% Written by Jackson Smith - August 2017 - DPAG , University of Oxford
% 
  
  % This is a MET PsychToolbox visual stimulus
  type = 'ptb' ;
  
  % Variable parameter set
  varpar = {  'fnumsg' , 'i' ,   4    ,  1   , +Inf ;
             'fxcoord' , 'f' ,   0.00 , -Inf , +Inf ;
             'fycoord' , 'f' ,   0.00 , -Inf , +Inf ;
             'fradius' , 'f' ,   4.50 ,  0.0 , +Inf ;
           'frotation' , 'f' ,   0.00 , -Inf , +Inf ;
              'ffirst' , 'i' ,   1    ,  1   , +Inf ;
               'flast' , 'i' ,   4    ,  1   , +Inf ;
               'fyoke' , 'i' ,   0    ,  0   , +Inf ;
           'fposition' , 'i' ,   1    ,  1   , +Inf ;
             'monovis' , 'i' ,   0    ,  0   ,  2   ;
               'width' , 'f' ,   4.00 ,  0.0 , +Inf ;
         'orientation' , 'f' ,   0.00 , -Inf , +Inf ;
        'delta_orient' , 'f' ,   0.00 , -Inf , +Inf ;
               'phase' , 'f' ,   0.00 , -Inf , +Inf ;
                'rate' , 'f' ,   0.00 ,  0.0 , +Inf ;
                'freq' , 'f' ,   1.00 ,  0.0 , +Inf ;
            'contrast' , 'f' ,   1.00 ,  0.0 ,  1.0 ;
           'disparity' , 'f' ,   0.00 , -Inf , +Inf ;
          'delta_disp' , 'f' ,   0.00 , -Inf , +Inf ;
             'hminrad' , 'f' ,   0.80 ,  0.0 , +Inf ;
            'hdisptol' , 'f' ,    0.5 ,  0.0 , +Inf ;
            'hitcheck' , 'i' ,   1    ,  0   ,  1   } ;
  
  % Function handles
	 init = @finit ;
   stim = @fstim ;
  close = @fclose ;
 chksum = @fchksum ;
 
 
  %%% RF definition %%%

  % No receptive/response field defined , return stim def
  if  isempty ( rfdef )  ,  return  ,  end

  % Get centre of RF
  x = rfdef( 1 ).xcoord ;
  y = rfdef( 1 ).ycoord ;

  % Set formation circle radius
  i = strcmp (  varpar( : , 1 )  ,  'fradius'  ) ;
  varpar{ i , 3 } = sqrt ( x ^ 2  +  y ^ 2 ) ;

  % Formation circle rotation
  i = strcmp (  varpar( : , 1 )  ,  'frotation'  ) ;
  varpar{ i , 3 } = atand ( y / x ) ;
  
    % Correct the output of atand so that the returned angle points towards
    % coordinate ( x , y )
    if  x < 0
      
      % Special case , 180 degrees
      if  y == 0
        
        varpar{ i , 3 } = 180 ;
        
      % General case
      else
        
        varpar{ i , 3 } = varpar{ i , 3 }  +  sign ( y ) * 180 ;
        
      end
      
    end % correct atand output
    
  % Match RF contrast, width, and orientation preferences
  for  P = { 'contrast' , 'width' , 'orientation' , 'disparity' }
    
    p = P { 1 } ;
    i = strcmp (  varpar( : , 1 )  ,  p  ) ;
    varpar{ i , 3 } = rfdef( 1 ).( p ) ;
    
  end % match rf pref
  
  % To match speed preference, we must convert from degrees per second to
  % cycles per second
  i = strcmp (  varpar( : , 1 )  ,  'rate'  ) ;
  j = strcmp (  varpar( : , 1 )  ,  'freq'  ) ;
  varpar{ i , 3 } = rfdef( 1 ).speed  *  varpar{ j , 3 } ;
  
end % singrating


%%% Stimulus definition handles %%%

% Trial initialisation function
function  S = finit ( vpar , tconst , Sold )
  
  
  %%% Check parameters %%%
    
  % Neither ffirst , flast , fyoke, nor fposition may exceed maximum number
  % of gratings
  if  any( vpar.fnumsg  <  ...
      [ vpar.ffirst , vpar.flast , vpar.fyoke , vpar.fposition ] )
    
    error (  'MET:singrating:badparam'  ,  [ 'singrating: ' , ...
      'Neither ffirst (%d) , flast (%d) , fyoke (%d) , nor ' , ...
      'fposition (%d) may exceed fnumsg (%d)' ]  ,  ...
      vpar.ffirst  ,  vpar.flast  ,  vpar.fyoke  ,  vpar.fposition  ,  ...
      vpar.fnumsg  )
    
  % ffirst must be less than or equal to flast
  elseif  vpar.flast  <  vpar.ffirst
    
    error (  'MET:singrating:badparam'  ,  [ 'singrating: ' , ...
      'ffirst (%d) must not exceed flast (%d)' ]  ,  vpar.ffirst  ,  ...
      vpar.flast  )
    
  end % varpar check
  
  
  %%% Build stimulus descriptor %%%
  
  % Keep a copy of variable parameters in their original units
  S.vp = vpar ;
  
  % List stimulus constant parameters i.e. these ignore stimulus events
  S.const = { 'fnumsg' , 'ffirst' , 'flast' , 'width' } ;
  
  % Compute the width of the texture support, in pixels. Make this the
  % minimum number of pixels required. Degrees  *  pixels / degree. Round
  % up to nearest pixel.
  S.Spix = ceil ( S.vp.width  *  tconst.pixperdeg ) ;
  
  
  %-- Procedural texture --%
  
  % If this is the first trial of the session then we will need to
  % initialise a new procedural texture. Or, an old texture was carried
  % forward but has a different support
  if  isempty (  Sold  )  ||  Sold.Spix  ~=  S.Spix
    
    % There is an old texture to release
    if  ~ isempty (  Sold  )  ,  Screen (  'Close'  ,  Sold.t  ) ;  end
    
    % Create sine grating procedural texture and return texture id. Note
    % that the support of the texture in pixels is S.Spix pixels wide.
    S.t = CreateProceduralSineGrating (  tconst.winptr ,  S.Spix ,  ...
      S.Spix ,  [] ,  S.Spix / 2 ,  0.5  ) ;
    
  else
    
    % Procedural texture already created , get the texture id returned by
    % fclose at the end of the last trial
    S.t = Sold.t ;
    
  end % procedural texture
  
  
  %-- Formation circle --%
  
  % Formation circle coordinates, on the PTB axes
  S.fcxy = fcentre ( tconst , S ) ;
  
  % The location of each grating centre relative to the formation circle
  % coordinate
  S.fsgxy = fsgcentre ( tconst , S ) ;
  
  % The number of presented gratings , which may differ from the number of
  % grating positions
  S.SGn = S.vp.flast  -  S.vp.ffirst  +  1 ;
  
  
  %-- DrawTextures input arguments --%
  
  % We need one column for each grating that is drawn
  
  % Convert the width from degrees to pixels because we use this a lot
  S.width = tconst.pixperdeg  *  S.vp.width ;
  
  % We also need to know the number of screen pixels per texture support
  % pixels
  S.scrpersup_pix = S.width  /  S.Spix ;
  
  % Frequency is a bit complex. The unit of frequency is in cycles per
  % pixel of the texture's support! How do we convert to this from cycles
  % per degree on screen? cycles/degree  *  degrees/screen_pix  *
  % screen_pix/support_pix.
  S.freq = S.vp.freq  /  tconst.pixperdeg  *  S.scrpersup_pix ;
  
  % Phase offset required for sinusoid to start in middle of aperture at
  % phase zero. Because start of sinusoid is from the edge of the support
  % ( I guess ), so if the radius of aperture touches the edge of the
  % support then the sinusoid starts at the edge of the aperture.
  S.phoff = S.width  /  2  /  S.scrpersup_pix  *  S.freq  *  360 ;
  
  % Destination rectangles
  S.drect = drect ( S ) ;
  
  % Angles. The problem is that DrawTextures interprets the Angle input
  % argument such that a value of 0 produces a vertical grating, while
  % increasing values spin the grating in a clockwise direction. Therefore,
  % we need to subtract the desired orienation and then subtract a further
  % 90 degrees to get the counter-clockwise orientation we want, where zero
  % creates a horizontal grating. Note that unary minus has higher
  % precedence than multiplication.
  S.angle = - ( S.vp.orientation  +  S.vp.delta_orient  +  90 )  *  ...
    ones ( 1 , S.SGn ) ;
  
  % Auxiliary parameters provide the phase, frequency, and contrast in rows
  % 1, 2, and 3. Row 4 contains zeros, because help
  % CreateProceduralSineGrating says so.
  S.auxpar = zeros (  4  ,  S.SGn  ) ;
  
  % Phase. Again, DrawTextures interprets this in the opposite way to what
  % we're after. Increasing the phase causes the sine to go backwards.
  % Therefore, we must subtract the desired phase from 180. Why 180?
  % Because help CPSG says so.
  S.auxpar( 1 , : ) = - ( S.phoff  +  S.vp.phase ) ;
  
  % Sine frequency in cycles per pixel of the texture's support
  S.auxpar( 2 , : ) = S.freq ;
  
  % Sine grating contrast
  S.auxpar( 3 , : ) = S.vp.contrast ;
  
  
  %-- Speed coefficient --%
  
  % Since tvar.ftime gives the expected onset time of the next frame in
  % seconds since the start of the trial, we can compute a coefficient that
  % will convert this time into a phase shift that is added to the current
  % phase. This will produce a moving grating. Remeber to subtract this,
  % see above for reason.
  
  % What phase shift is required per second to get the desired speed?
  % Again, this is a bit complex because we want to convert from cycles per
  % second to degrees on screen per second to degrees of phase, where one
  % cycle is in pixels of texture support.
  % screen_cycles/sec  *  degrees/screen_cycle  =  degrees/sec
  % degrees/sec  *  screen_pix/degree  =  screen_pix/sec
  % screen_pix/sec  *  support_pix/screen_pix = support_pix/sec
  % support_pix/sec  *  support_cycles/support_pix = support_cycles/sec
  % support_cycles/sec  *  360 degrees/support_cycle = degrees/sec
  S.speed = S.vp.rate  /  S.vp.freq  *  tconst.pixperdeg  /  ...
    S.scrpersup_pix  *  S.freq  *  360 ;
  
  % In case speed switches between zero and non-zero values during a trial,
  % it is necessary to continuously update a time-zero reference point to
  % avoid sudden jumps in sinusoid position. A value of zero tells fstim
  % that time-zero should be set to the expected onset time of the next
  % frame.
  S.tzero = 0 ;
  
  
  %-- Disparity --%
  
  % Sum to find full disparity , and convert to pixels
  S.disp = ( S.vp.disparity + S.vp.delta_disp )  *  tconst.pixperdeg ;
  
  
  %-- Hit regions --%
  
  % We will use the 5-column form defining a set of circular regions
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  S.hitregion = zeros ( S.SGn , 6 ) ;
  
  % Initialise hit region radius and disparity
  S.hitregion( : , c6.radius ) = max ( [ S.vp.hminrad , S.vp.width / 2 ] );
  S.hitregion( : , c6.disp   ) = tconst.origin( 3 ) ;
  S.hitregion( : , c6.dtoler ) = S.vp.hdisptol ;
  
  % Initialise hit region positions
  S.hitregion( : , [ c6.xcoord , c6.ycoord ] ) = hitregpos ( tconst , S ) ;
  
  % Set whether or not to ignore the stimulus
  S.hitregion( : , c6.ignore ) = S.vp.hitcheck ;
  
  
end % finit


% Stimulation function
function  [ S , h ] = fstim ( S , tconst , tvar )
  
  
  %%% Update the stimulus values %%%
  
  % Hit region update not expected by default
  h = false ;
  
  % Only update variable parameters or dot positions if this is the
  % left-eye frame buffer i.e. only do this once per stereo image
  if  tvar.eyebuf  <  1
    
    
    %-- Variable parameter changes --%

    % Any variable parameters changed?
    if  ~ isempty ( tvar.varpar )
      
      
      %   Get/make lists   %
      
      % Point to the list of variable parameter changes
      vp = tvar.varpar ;

      % Make a struct that tracks which parameters were changed , d for
      % delta i.e. change. There is one field for every variable parameter,
      % and has the same name.
      F = fieldnames( S.vp )' ;
      F = [  F  ;  num2cell(  false( size( F ) )  )  ] ;
      d = struct (  F { : }  ) ;
      
      
      %   New values   %
    
      for  i = 1 : size ( vp , 1 )

        % Ignored variable parameter change , skip to next
        if  any ( strcmp(  vp{ i , 1 }  ,  S.const  ) )
          continue
        end
        
        % Save in stimulus descriptor's copy of variable parameters
        S.vp.( vp{ i , 1 } ) = vp{ i , 2 } ;

        % Mark as changed
        d.( vp{ i , 1 } ) = true ;

      end % new values
      
      
      %   Update stimulus descriptor   %
      
      % Formation circle flag is low
      fcirc = false ;
      
      % Formation circle coordinate change of any kind
      if  any ( [  d.fxcoord ,  d.fycoord ,  d.fradius ,  d.frotation , ...
          d.fyoke ,  d.fposition  ] )
        
        % Update formation circle centre
        S.fcxy = fcentre ( tconst , S ) ;
        
        % Get new grating positions
        S.fsgxy = fsgcentre ( tconst , S ) ;
        
        % Raise formation circle change flag
        fcirc = true ;
        
        % Raise hitregion flag
        h = true ;
        
      end % formation circle change
      
      % New destination rectangles required
      if  fcirc  ,  S.drect = drect ( S ) ;  end
      
      % Update frequency if either frequency or width changed
      if  d.freq
        
        % Frequency value in cycles per support pixel
        S.freq = S.vp.freq  /  tconst.pixperdeg  *  S.scrpersup_pix ;
        
        % Apply to auxiliary parameters
        S.auxpar( 2 , : ) = S.freq ;
        
      end % freq change
      
      % Update phase offset value
      if  d.freq
        S.phoff = S.width  /  2  /  S.scrpersup_pix  *  S.freq  *  360 ;
      end
      
      % Orientation change
      if  d.orientation  ||  d.delta_orient
        S.angle( : ) = - ( S.vp.orientation  +  S.vp.delta_orient  +  90 );
      end
  
      % Sine frequency or phase offset change
      if  d.phase  ||  d.freq
        S.auxpar( 1 , : ) = - ( S.phoff  +  S.vp.phase ) ;
      end
      
      % Sine grating contrast change
      if  d.contrast  ,  S.auxpar( 3 , : ) = S.vp.contrast ;  end
      
      % A speed or freq parameter change require the speed coefficient to
      % be updated
      if  d.rate  ||  d.freq
        
        % Old speed coefficient
        old_speed = S.speed ;
        
        % New speed coefficient
        S.speed = S.vp.rate  /  S.vp.freq  *  tconst.pixperdeg  /  ...
          S.scrpersup_pix  *  S.freq  *  360 ;
        
        % Did we change from no speed to non-zero speed? If yes, then we
        % need to reset the speed timer to the upcoming frame, so that we
        % measure no time change.
        if  old_speed == 0  &&  0 < S.speed  ,  S.tzero = 0 ;  end
        
      end % speed change
      
      % If phase changed, speed and timer are non-zero then we need to
      % reset the timer so that the requested phase is actually used on the
      % next frame
      if  d.phase  &&  S.tzero < tvar.ftime  ,  S.tzero = 0 ;  end
      
      % Disparity change
      if  d.disparity  ||  d.delta_disp
        
        % Sum to find full disparity , and convert to pixels
        S.disp = ( S.vp.disparity + S.vp.delta_disp )  *  tconst.pixperdeg;
        
      end % disparity change
      
      % Hit region changed
      if  h  ||  d.hitcheck  ||  d.hminrad  ||  d.hdisptol
        
        % Get hit region index constants
        c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
        
        % Change position of hit regions
        if  fcirc

          S.hitregion( : , [ c6.xcoord , c6.ycoord ] ) = ...
            hitregpos ( tconst , S ) ;

        end
        
        % Change radius of hit regions
        if  d.hminrad
          
          S.hitregion( : , c6.radius ) = ...
            max ( [  S.vp.hminrad  ,  S.vp.width / 2  ] ) ;
          
        end
        
        % Hit region ignore flag has changed status , set to new value and
        % raise hit region flag
        if  d.hitcheck
          S.hitregion( : , c6.ignore ) = S.vp.hitcheck ;
          h = true ;
        end
      
        % Hit region disparity tolerance changed , raise hit region flag if
        % not already done
        if  d.hdisptol
          S.hitregion( : , c6.dtoler ) = S.vp.hdisptol ;
          h = true ;
        end
      
      end % hit region change
      
    end % variable parameter changes
    
    
    %-- Apply speed --%
    
    % Is the sinusoid moving?
    if  S.speed
      
      % Reset time-zero?
      if  ~ S.tzero  ,  S.tzero = tvar.ftime ;  end
      
      % Compute phase change according to the time elapsed
      dphase = S.speed * ( tvar.ftime  -  S.tzero ) ;
      
      % Find modulus of new phase , to keep numerical range in check
      phase = mod (  S.vp.phase  +  dphase  ,  360  ) ;
      
      % Assign phase to sinusoids
      S.auxpar( 1 , : ) = - ( S.phoff  +  phase ) ;
      
    end % apply speed
    
    
  end % left-eye frame buffer
  
  
  %%% Draw image %%%
  
  % monovis flag does not allow this monocular image to be seen.
  if  S.vp.monovis  &&  -1 < tvar.eyebuf  &&  ...
        S.vp.monovis ~= tvar.eyebuf + 1
    return
  end
  
  % Get pointer to grating rects
  R = S.drect ;
  
  % Apply horizontal disparity, if any, and if applicable
  if  S.disp
    
    % Apply disparity according to which monocular image it is
    switch  tvar.eyebuf
    
      % Left monocular
      case  0  ,  R( [ 1 , 3 ] , : ) = R( [ 1 , 3 ] , : )  -  S.disp / 2 ;
        
      % Right monocular
      case  1  ,  R( [ 1 , 3 ] , : ) = R( [ 1 , 3 ] , : )  +  S.disp / 2 ;
    
    end % eye buffer
    
  end % disparity
  
  % Use the correct blending function
  Screen ( 'BlendFunction' , tconst.winptr , 'GL_ONE' , 'GL_ONE' ) ;
  
  % Draw to frame buffer
  Screen (  'DrawTextures' ,  tconst.winptr ,  S.t ,  [] ,  R ,  ...
    S.angle ,  [] ,  [] ,  [] ,  [] ,  [] ,  S.auxpar  ) ;
  
  
end % fstim


% Trial closing function
function  Sold = fclose ( S , type )
  
  % What kind of stimulus closure?
  switch  type
    
    % Trial closure , carry forward texture id to next trial
    case  't'
      
      Sold.Spix = S.Spix ;
      Sold.t    = S.t    ;
      
    % Session closure
    case  's'
      
      % Free procedural texture resources
      Screen (  'Close'  ,  S.t  ) ;
      
      % Return empty descriptor
      Sold = [] ;
    
  end % close stim
  
end % close


% Check-sum function
function  c = fchksum ( ~ )
  
  c = 0 ;
  
end % chksum


%%% Sub-routines %%%

% Absolute screen location of the formation circle centre.
function  c = fcentre ( tconst , S )
  
  % Centre of formation circle from the centre of the screen , in degrees
  c = [ S.vp.fxcoord , S.vp.fycoord ]  +  tconst.origin( 1 : 2 ) ;
  
  % Convert unit from degrees to pixels and add the pixel coordinates of
  % the centre of the screen
  c = tconst.pixperdeg * c  +  [ tconst.wincentx , tconst.wincenty ] ;
  
  % Rmember to convert y-axis coordinate to PTB coordinate system where
  % down is up
  c( 2 ) = tconst.winheight  -  c( 2 ) ;
  
end % fcentre


% Pixel coordinates of each grating centre on screen. Columns are indexed
% by grating, so that xy( : , i ) is the centre of the ith grating. This is
% different from grating positions, which are fixed around the formation
% circle, but can be assigned to different gratings.
function  xy = fsgcentre ( tconst , S )
  
  % Number of grating positions
  N = S.vp.fnumsg ;
  
  % Formation circle radius , in pixels
  radpix = S.vp.fradius  *  tconst.pixperdeg ;
  
  % Angle of each grating position , counter-clockwise around the formation
  % circle.
  a = 360 / N  *  ( 0 : N - 1 )  +  S.vp.frotation ;
  
  % Change grating positions from polar to Cartesian coordinates , in
  % pixels from the centre of the formation circle. The reflection accounts
  % for the PTB coordinate system.
  xy = [  + radpix  *  cosd( a )  ;  - radpix  *  sind( a )  ] ;
  
  % Translate grating positions so that the yoked position is centred in
  % the middle of the formation circle
  if  S.vp.fyoke
    
    % Patch index
    y = S.vp.fyoke ;
    
    % Translate positions
    xy( 1 , : ) = xy ( 1 , : )  -  xy ( 1 , y ) ;
    xy( 2 , : ) = xy ( 2 , : )  -  xy ( 2 , y ) ;
    
  end % formation yoke
  
  % Re-order grating positions so that first, second, ... Nth grating are
  % placed starting at fposition. Start by making an index vector that will
  % re-order the grating positions
  i = mod (  ( 0 : N - 1 ) + S.vp.fposition - 1  ,  N  )  +  1 ;
  
  % Re-order grating to grating-position mapping
  xy = xy ( : , i ) ;
  
  % Add centre-of-screen coordinate to get absolute position of grating
  % centres, in pixels
  xy( 1 , : ) = xy( 1 , : )  +  S.fcxy( 1 ) ;
  xy( 2 , : ) = xy( 2 , : )  +  S.fcxy( 2 ) ;
  
end % fsgcentre


% Create an array of destination rectangles in pixel coordinates , one per
% grating indexed by column
function  r = drect ( S )
  
  % Base rectangle centred on origin but with the correct width , in pixels
  r = S.width  *  [ -0.5 ; -0.5 ; 0.5 ; 0.5 ] ;
  
  % Replicate base rectangle for each grating
  r = repmat (  r  ,  1  ,  S.SGn  ) ;
  
  % Translate into position around the formation circle
  r = r  +  S.fsgxy( [ 1 , 2 , 1 , 2 ] , S.vp.ffirst : S.vp.flast ) ;
  
end % drect


% Calculate the position of each hit region, in degrees from the trial
% origin
function  p = hitregpos ( tconst , S )
  
  % Indices of presented gratings
  i = S.vp.ffirst : S.vp.flast ;
  
  % Get x-y coordinates relative to formation circle's centre , in pixels
  p = S.fsgxy ( : , i )' ;
  
  % Flip from PTB-style coordinate system to standard Cartesian
  p( : , 2 ) = tconst.winheight  -  p( : , 2 ) ;
  
  % Subtract centre of screen coordinate
  p( : , 1 ) = p( : , 1 )  -  tconst.wincentx ;
  p( : , 2 ) = p( : , 2 )  -  tconst.wincenty ;
  
  % Convert unit to degrees
  p = p  ./  tconst.pixperdeg ;
  
end % hitregpos

