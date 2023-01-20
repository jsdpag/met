
function  ppd = metpixperdeg ( mm , px , sub )
% 
% ppd = metpixperdeg ( mm , px , sub )
% 
% Matlab electrophysiology toolbox. Convenience function to calculate the
% pixels per degree of visual angle. mm is the length of the screen along a
% given dimension in millimetres, while px is the length along the same
% dimension in pixels. sub is the distance in millimetres from the
% subject's eyes to the nearest point on the screen i.e. the distance along
% a line that is perpendicular to the screen and passes through the eye.
% 
% mm and px must be numeric matrices that have the same number of elements,
% such that mm( i ) and px( i ) refer to the ith dimension of the screen.
% sub must always be a scalar numeric value. All numbers must be rational
% and greater than zero.
% 
% Returns column vector ppd that has the same number of elements as mm and
% px, where ppd( i ) is the number of pixels per degree along the ith
% dimension.
% 
% Written by Jackson Smith - Dec 2016 - DPAG , University of Oxford
% 
  
  
  %%% Error checking %%%
  
  % Check millimetre dimension measurements
  if  isempty ( mm )  ||  ~ isnumeric ( mm )  ||  ~ isreal ( mm )  ||  ...
      any (  ~ isfinite ( mm )  |  mm <= 0  )

    error ( 'MET:metpixperdeg:input' , ...
      [ 'metpixperdeg: Input arg mm must have finite real values ' , ...
        'greater than 0' ] )
      
  % Check pixel dimension measurements
  elseif  isempty ( px )  ||  ~ isnumeric ( px )  ||  ...
      ~ isreal ( px )  ||  any (  ~ isfinite ( px )  |  px <= 0  )

    error ( 'MET:metpixperdeg:input' , ...
      [ 'metpixperdeg: Input arg px must have finite real values ' , ...
        'greater than 0' ] )
      
  % Check subject distance
  elseif  numel ( sub ) ~= 1  ||  ~ isnumeric ( sub )  ||  ...
      ~ isreal ( sub )  ||  ~ isfinite ( sub )  ||  sub <= 0

    error ( 'MET:metpixperdeg:input' , ...
      [ 'metpixperdeg: Input arg sub must be a scalar, finite ' , ...
        'real value greater than 0' ] )

  % Check that mm and px have the same number of values
  elseif  numel ( mm )  ~=  numel ( px )
    
    error ( 'MET:metpixperdeg:input' , ...
        'metpixperdeg: mm and px must have the same number of elements' )
    
  end
  
  
  %%% Compute pixels per degree %%%
  
  % Compute millimetres of screen per degree of visual angle
  mm_deg = sub  *  tand ( 1 ) ;
  
  % Then compute pixels per millimetre of screen
  pix_mm = px( : )  ./  mm( : ) ;
  
  % And finally, pixels per degree
  ppd = mm_deg  *  pix_mm ;
  
  
end % metpixperdeg

