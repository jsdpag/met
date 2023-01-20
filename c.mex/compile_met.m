
% 
% compile_met.m
% 
% Compiles met.c by running mex met.c [metx_func1  metx_func2  ...] with
% all supporting MET MEX functions listed AFTER met.c
% 
% Written by Jackson Smith - DPAG , University of Oxford
% 

% Well, R2015b can't manage wildcards, unlike R2015a or R2016a. So we have
% to use this workaround
metx = dir ( 'metx*.c' ) ;
mex ( '-lrt' , 'met.c' , metx.name )

movefile  met.mexa64  ../m/

clear metx