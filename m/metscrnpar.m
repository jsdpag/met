
function  p = metscrnpar
% 
% p = metscrnpar
% 
% Matlab electrophysiology toolbox function. Reads screen dimensions from
% met/m/metscrnpar.csv and returns them in a struct with fields .width,
% .height, and .subdist that contain the width and height of the screen,
% and the distance of the subject's eyes to the screen. Each field contains
% a scalar double, in millimetres. Next is .touch, a flag with value 0, 1,
% or 2 ; if non-zero then the monitor is a touchscreen (mouse input used
% instead of eye positions) ; the mouse cursor is hidden in the PTB window
% unless .touch is 2. Then returns two logical values of 0 for false and 1
% for true in fields .hmirror and .vmirror that say whether or not the
% monitor is mirrored in the horizontal or vertical direction. Horizontal
% mirroring turns left into right, and vertical mirroring turns the top
% into bottom. Field .screenid is the screen ID to use, as returned by
% Screen ( 'Screens' ) ; if -1 then max( Screen(  'Screens'  ) ) is used.
% Field .stereo contains the stereo mode number that is provided to Screen
% 'OpenWindow' , refer to Screen OpenWindow? for a list of allowable values
% e.g. setting .stereo to 6 opens PsychToolbox in red-left/green-right
% anaglyph mode. Fields .rbak, .gbak, and .bbak are the red, green, and
% blue colour lookup table values for the default background, normalised
% from 0 to 1. Field .priority is a binary flag that, when non-zero,
% signals to the MET controller that opens a Psych Toolbox window that it
% may raise its process priority to the maximum level. Fields .newHeadId,
% .newCrtcId, and .rank are values for screen to head mapping ; if -1 is
% provided then the argument is not given to Screen ( 'Preference' ,
% 'ScreenToHead' , ... ), while no screen to head mapping is done if all
% values are -1. The next five parameters describe a square that signals
% each new frame to a photodiode placed at the upper-left hand corner of
% the screen. sqwid is the width of that square in millimetres ; set to 0
% for no square. sqred, sqgrn, and sqblu are the normalised ( 0 to 1 )
% colour lookup table ( clut ) values for each colour channel that specify,
% all together, the base colour of the square. The photodiode square is
% only drawn during a trial, and then it will alternate between the raw
% colour ( sqred , sqgrn , sqblu ) and a weighted colour
% ( sqwrd , sqwgn , sqwbl ) .* ( sqred , sqgrn , sqblu ). A second square
% can be placed in the upper-right hand corner of the screen using
% parameters mskwid and mskclu. The job of this square is to mask the
% background colour; this is needed for instance when a second photodiode
% monitors the upper-right hand corner of the screen for an increase in
% luminance to time stamp a stimulus event. mskwid is the width and height
% of the square, in pixels; this can be zero or more but not negative.
% mskclu is the greyscale colour lookup value, normalised from 0 (black) to
% 1 (white). defseed can be 0 or 1; when non-zero it instructs MET to reset
% Matlab's stimulus random number generator to the default seed at the
% start of each trial, as might be done in control experiments that require
% the identical set of random dots on every trial. If defseed is 0 then the
% random number generator is shuffled and a separate set of numbers is
% sampled on each trial for e.g. different random dots.
%
% NOTE: Requires a MET comma-separated file (CSV) called metscrnpar.csv
%   located in the same met/m directory as metscrnpar.m. This will list all
%   the required parameters returned in p, with the same parameter names
%   and value sets. Being a MET .csv file, the first line must be column
%   headers param,value.
% 
%   Example - 304 by 228 mm screen (no touch surface) with subject 600 mm
%     away , no PsychToolbox mirroring enables , use max screen id for
%     PsychToolbox window , open PsychToolbox window in red/green anaglyph
%     mode , mid-grey background , no screen-to-head mapping
%   
%     param,value
%     width,304
%     height,228
%     subdist,600
%     touch,0
%     hmirror,0
%     vmirror,0
%     screenid,-1
%     stereo,6
%     rbak,0.5
%     gbak,0.5
%     bbak,0.5
%     priority,1
%     newHeadId,-1
%     newCrtcId,-1
%     rank,-1
%     sqwid,28
%     sqred,1
%     sqgrn,1
%     sqblu,1
%     sqwrd,0.75
%     sqwgn,0.75
%     sqwbl,0.75
%     mskwid,150
%     mskclu,0
%     defseed,0
% 
% Written by Jackson Smith - Dec 2016 - DPAG , University of Oxford
% 
  
  
  %%% Constants %%%
  
  % Location of metscrnpar.csv , first get containing directory then add
  % file name
  f = fileparts ( which ( 'metscrnpar' ) ) ;
  f = fullfile ( f , 'metscrnpar.csv' ) ;
  
  % Make sure that the file exists
  if  ~ exist ( f , 'file' )
    
    error ( 'MET:metscrnpar:csv' , 'metscrnpar: Can''t find %s' , f )
    
  end
  
  % Parameter name set
  PARNAM = { 'width' , 'height' , 'subdist' , 'touch' , ...
    'hmirror' , 'vmirror' , 'screenid' , 'stereo' , 'rbak' , 'gbak' , ...
    'bbak' , 'priority' , 'newHeadId' , 'newCrtcId' , 'rank' , 'sqwid' ,...
    'sqred' , 'sqgrn' , 'sqblu' , 'sqwrd' , 'sqwgn' , 'sqwbl' , ...
    'mskwid' , 'mskclu' , 'defseed' } ;
  
  % Anonymous function handles that check numerical range and return 1 if
  % value is out of range. width, height, and subdist must all be greater
  % than zero. touch must be 0 or 1. screen id -1 up to max screen id. *bak
  % must be 0 to 1. Screen-to-head parameters must be -1 or more.
  VALRNG.width = @( v )  v  <=  0 ;
  VALRNG.height = VALRNG.width ;
  VALRNG.subdist = VALRNG.width ;
  VALRNG.touch = @( v )  v ~= 0  &&  v ~= 1  &&  v ~= 2 ;
  VALRNG.hmirror = @( v )  v ~= 0  &&  v ~= 1 ;
  VALRNG.vmirror = VALRNG.hmirror ;
  VALRNG.screenid = @( v )  v < -1  ||  ...
                            max( Screen( 'Screens' ) ) < v  ||  ...
                            mod( v , 1 ) ;
	VALRNG.stereo = @( v )  v < 0  ||  11 < v  ||  mod ( v , 1 ) ;
  VALRNG.rbak = @( v )  v < 0  ||  1 < v ;
  VALRNG.gbak = VALRNG.rbak ;
  VALRNG.bbak = VALRNG.rbak ;
  VALRNG.priority = VALRNG.hmirror ;
  VALRNG.newHeadId = @( v )  v < -1  ||  mod( v , 1 ) ;
  VALRNG.newCrtcId = VALRNG.newHeadId ;
  VALRNG.rank = VALRNG.newHeadId ;
  VALRNG.sqwid = @( v )  v  <  0 ;
  VALRNG.sqred = VALRNG.rbak ;
  VALRNG.sqgrn = VALRNG.rbak ;
  VALRNG.sqblu = VALRNG.rbak ;
  VALRNG.sqwrd = VALRNG.rbak ;
  VALRNG.sqwgn = VALRNG.rbak ;
  VALRNG.sqwbl = VALRNG.rbak ;
  VALRNG.mskwid = VALRNG.sqwid ;
  VALRNG.mskclu = VALRNG.rbak ;
  VALRNG.defseed = VALRNG.hmirror ;
  
  % Error string telling the user what numerical range the column must have
  ESTRMV.width = 'more than zero' ;
  ESTRMV.height = ESTRMV.width ;
  ESTRMV.subdist = ESTRMV.width ;
  ESTRMV.touch = 'equal to zero, one, or two' ;
  ESTRMV.hmirror = 'equal to zero or one' ;
  ESTRMV.vmirror = ESTRMV.hmirror ;
  ESTRMV.screenid = '-1 or a value from Screen ( ''Screens'' )' ;
  ESTRMV.stereo = 'an integer from 0 to 11' ;
  ESTRMV.rbak = 'between 0 and 1' ;
  ESTRMV.gbak = ESTRMV.rbak ;
  ESTRMV.bbak = ESTRMV.rbak ;
  ESTRMV.priority = ESTRMV.hmirror ;
  ESTRMV.newHeadId = 'an integer of -1 or more' ;
  ESTRMV.newCrtcId = ESTRMV.newHeadId ;
  ESTRMV.rank = ESTRMV.newHeadId ;
  ESTRMV.sqwid = 'equal to zero or more' ;
  ESTRMV.sqred = ESTRMV.rbak ;
  ESTRMV.sqgrn = ESTRMV.rbak ;
  ESTRMV.sqblu = ESTRMV.rbak ;
  ESTRMV.sqwrd = ESTRMV.rbak ;
  ESTRMV.sqwgn = ESTRMV.rbak ;
  ESTRMV.sqwbl = ESTRMV.rbak ;
  ESTRMV.mskwid = ESTRMV.sqwid ;
  ESTRMV.mskclu = ESTRMV.rbak ;
  ESTRMV.defseed = ESTRMV.hmirror ;
  
  
  %%% Read file %%%
  
  p = metreadcsv (  f  ,  PARNAM  ) ;
  
  % Make sure that there are no strings
  if  any ( cellfun(  @ischar  ,  struct2cell( p )  ) )
    
    error (  'MET:metscrnpar:csv'  ,  ...
      'metscrnpar.csv may not contain string'  )
    
  end % string returned
  
  % Check parameter values
  for  N = PARNAM , n = N{ 1 } ;
    
    if  VALRNG.( n ) ( p.( n ) )
      
      error ( 'MET:metscrnpar:csv' , [ 'metscrnpar: ' , ...
        'Parameter ''' , n , ''' must be ' , ESTRMV.( n ) ] )
      
    end
    
  end % column values
  
  
  %%% Special checks %%%
  
  % Photodiode square cannot be bigger than minimum dimension of the screen
  if  min ( [  p.width  ,  p.height  ] )  <  p.sqwid
    
    error (  'MET:metscrnpar:csv'  ,  ...
      'metscrnpar: sqwid cannot be larger than minimum screen dimension'  )
    
  end
  
  
end % metscrnpar

