
% 
% [ ... ] = ivxudp ( ivxfun , ... )
% 
% Matlab Electrophysiology Toolbox utility function. This allows a MET
% controller function to stream eye positions from a remote system that
% runs the SensoMotoric Instrumentation GmbH (SMI) eye-tracking program
% iViewX. Different sub-functions are executed, depending on the value of
% the first argument, ivxfun, which must be a single character.
% 
% This requires that the local system running MET and the SMI system are
% connected to the same network ; for example, both systems may have their
% ethernet cards plugged into the same networking switch. iViewX is
% required to be set up for binocular eye tracking, while manual Direct
% Analog Gain and Offset calibration must be enabled. The left and right
% gaze positions must be used to generate the analogue voltage output from
% the SMI system, and out of range behaviour must be clipped ; when this is
% the case, the Data Range in iViewX is automatically set as 4095 to 12287,
% and this fact will be assumed, here. The local MET system and the SMI
% system must have compatible IP addresses that are used in the iViewX
% Ethernet configuration for UDP communication. Beware that monocular
% eye samples will be discarded, only binocular eye samples will be used.
% 
% The above will be true when using the Hi-Speed Primate camera with iViewX
% version 2.8 build 43.
% 
% Sub-functions:
% 
%     s = ivxudp ( 'o' , hipa , hprt , iipa , iprt ) -- Make and bind a
%       socket. The user must provide the IP address and port for the host
%       (upon which Matlab is running) and SMI (upon which iViewX is
%       running) computers. hipa and iprt must be strings containing IP
%       addresses. hprt and iprt must be scalar doubles indicating ports.
%       For input arguments, 'h' means host and 'i' means iViewX. 'open'
%       will send a test ping command ; if no reply is given before a
%       timeout, then the socket is immediately closed. A data format
%       string is then sent to iViewX, telling it what information to
%       stream. Finally, data streaming from iViewX is started. Returns
%       scalar double s, which is the value of the socket file descriptor ;
%       for use with multiplexing functions, like select( ).
% 
%     ivxudp ( 'c' ) -- Stops iViewX from streaming data, and close the
%       socket.
% 
%     [ tret , tim , gaze , diam ] = ivxudp ( 'r' ) -- Read new
%       eye samples from the socket buffer. This is a non-blocking read.
%       So when no new data is available, then all output arguments will be
%       empty double arrays i.e. they will all be []. The exception is
%       tret (see below). If data is available then each of the output
%       arguments will be a double array containing the following:
% 
%       tret - scalar - gettimeofday( ) time measurement in seconds.
%         This is taken immediately after reading from the socket, and will
%         be directly comparable to local time measurements returned by
%         Psych Toolbox functions, like GetSecs( ). If no new data was
%         available then tret returns zero.
% 
%       All following outputs will have 1 <= N rows, where the ith row in
%       each output argument refers to the same data sample.
% 
%       tim - N x 1 - Contains the time stamp of each eye sample. These
%         measurements are NOT from the local system running MET. They are
%         from the SMI computer. In seconds.
% 
%       gaze - N x 4 - Contains gaze positions. Column indexing
%         is [ x-left , y-left , x-right , y-right ]. That is, horizontal
%         coordinates are in columns 1 and 3, vertical in 2 and 4 ; left
%         eye coordinates are in columns 1 and 2, right in 3 and 4. All
%         gaze positions are normalised to a value between 0 and 1, where
%         0 corresponds to the minimum voltage and 1 the maximum voltage
%         that iViewX is configured to produce when generating analogue
%         copies of the gaze position.
% 
%       diam - N x 4 - Contains the pupil diameter. Column indexing is the
%         same as for gaze. Hence, the diameter is measured separately in
%         both the x- and y-axis, for each eye. In pixels of the eye
%         tracking video image.
% 
% 
% Written by Jackson Smith - DPAG , University of Oxford
