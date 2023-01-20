
% 
% This class provides a data structure for the rds_Cumming99 MET PTB
% stimulus. As a sub-class of the handle class, it maintains the same
% location in memory when it is modified within a function. In other words,
% there is no copy-on-write behaviour.
% 
% Written by Jackson Smith - October 2017 - DPAG , University of Oxford
% 

classdef  rds_Cumming99_handle  <  handle
  
  % List all properties accessed in rds_Cumming99
  properties
    
    vp
    const
    fcxy
    frdsxy
    RDSn
    g
    frames
    flick
    dotmin
    dotmax
    crad
    swid
    rdsrad
    crad2
    rdsrad2
    drad2
    dotwid
    dbase
    hbase
    dsig
    hsig
    hsnorm
    hsny
    prng
    pmin
    dnrng
    dnmin
    dnhsh
    adot
    dot_type
    ards
    acen
    asur
    theta
    alens
    acfill
    phi
    aseg
    gamma
    abshift
    acrec
    Ncfillmax
    Nrds
    Nsur
    Ncen
    Nsig
    Nnoise
    Ncfill
    Nseg
    Ncrec
    Ntotal
    Ngtotal
    Nbshift
    Ncsur
    Ncseg
    Ncsig
    Ncnoise
    Nuncorb_surr
    Nuncorb_fill
    Nuncorb_segs
    Nuncorn
    Ntotalmax
    Ngtotalmax
    s
    c
    ib
    is
    in
    timer
    xy
    v
    vrp
    gi
    girp
    ndisp
    hitregion
    
  end % properties
  
end % rds_Cumming99_handle

