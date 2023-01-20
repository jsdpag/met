
function  ...
  [ x , y , buttons , wheelDelta , focus , valuators , valinfo ] = ...
  metgetmouse ( mouseIndex , windowPtrOrScreenNumber )
% 
% [ x , y , buttons , wheelDelta , focus , valuators , valinfo ] =
%                  metgetmouse ( [mouseIndex] , [windowPtrOrScreenNumber] )
% 
% Matlab Electrophysiology Toolbox helper function. PsychToolbox's
% GetMouseWheel is presently unsupported on Linux. However, an unreleased
% version is, and forms the basis for this MET function. See help
% GetMouseWheel for more information. Both inputs are optional, or empty
% matrices can be given.
% 
% Written by Jackson Smith - March 2016 - DPAG , University of Oxford
% 
  
% History:
% 05/31/08  mk  Initial implementation [of GetMouseWheel].
% 05/14/12  mk  Tweaks for more mice.
% 02/21/17  mk  Support Linux by wrapping around GetMouse() valuator
%   functionality. 
% 15/03/17  js  Adapted for MET , keeps only Linux-related code

  % Cache the detected index of the first "real" wheel mouse to allow for
  % lower execution times:
  persistent  oldWheelAbsolute ;
  persistent  wheelMouseIndex ;

  if  isempty ( oldWheelAbsolute )
    oldWheelAbsolute = nan ( max( GetMouseIndices ) + 1 , 1 ) ;
  end
  
  if nargin < 2 , windowPtrOrScreenNumber = [] ; end

  if isempty(wheelMouseIndex) && ((nargin < 1) || isempty(mouseIndex))
    
      % Find first mouse with a mouse wheel:
      mousedices = GetMouseIndices('slavePointer');
      
      numMice = length(mousedices);
      if numMice == 0
          error ( [ 'GetMouseWheel could not find any mice connected ' ,...
            'to your computer' ] ) ;
      end

      for i=mousedices
          [~,~,~,~,~,valinfo] = GetMouse([], i);
          for j=1:length(valinfo)
              if strcmp(valinfo(j).label, 'Rel Vert Wheel')
                  wheelMouseIndex = i;
                  break;
              end
          end
          if ~isempty(wheelMouseIndex)
              break;
          end
      end

      if isempty(wheelMouseIndex)
          error( [ 'GetMouseWheel could not find any mice with ' , ...
            'mouse wheels connected to your computer' ] ) ;
      end
  end

  % Override mouse index provided?
  if nargin < 1 || isempty(mouseIndex)
      % Nope: Assign default detected wheel-mouse index:
      mouseIndex = wheelMouseIndex;
  end

  [ x , y , buttons , focus , valuators , valinfo ] = ...
    GetMouse (  windowPtrOrScreenNumber  ,  mouseIndex  ) ;
  
  for j=1:length(valinfo)
      if strcmp(valinfo(j).label, 'Rel Vert Wheel')
          wheelAbsolute = valuators(j);
          if isnan(oldWheelAbsolute(mouseIndex+1))
              wheelDelta = 0;
          else
              wheelDelta = wheelAbsolute - oldWheelAbsolute(mouseIndex+1);
          end
          oldWheelAbsolute(mouseIndex+1) = wheelAbsolute;
          return;
      end
  end
  error('Given mouse does not have a wheel.');

  
end % metgetmouse

