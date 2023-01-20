
function  e = metDaqDOut ( daq , port , data )
% 
% e = metDaqDOut ( daq , port , data )
% 
% Matlab Electrophysiology Toolbox. This is a streamlined version of
% DaqDOut from PsychToolbox. The idea is to minimise the output latency.
% daq is a device index assumed to refer to a USB-1208fs. It is necessary
% to check this before metDaqDOut is used. port has a value of 0 or 1 to
% refer to port A or B on the device. data is a scalar 8-bit value that
% determines what combination of pins in the given port will be on ; thus
% if data is 0 then all pins are off and if data is 255 then all pins are
% on. The PsychHID error output is returned in err. An error message is
% printed if an error is returned, but the program is not terminated.
% 
% Written by Jackson Smith - April 2017 - DPAG , University of Oxford
% 
  
  % Pack information about which port to use and what pins to set into an
  % HID report
  r = uint8 ( [ 0 , port , data ] ) ;
  
  % Tell device to change digital output state. Default report ID for
  % 1x08FS devices is 4.
  e = PsychHID ( 'SetReport' , daq , 2 , 4 , r ) ;
  
  % Error returned
  if  e.n
    
    fprintf ( 'metDaqDOut error 0x%s. %s: %s\n' , hexstr ( e.n ) , ...
      e.name , e.description ) ;
    
  end % error
  
end % metDaqDOut

