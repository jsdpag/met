
function  [ type , vpar , init , stim , close , chksum ] = null ( ~ )
% 
% [ type , vpar , init , close , stim , chksum ] = null ( rfdef )
% 
% Matlab Electrophysiology Toolbox (MET) PsychToolbox stimulus definition.
% 
% MET null stimulus definition. If linked to a task stimulus then nothing
% will happen when that stimulus is presented i.e. no visual, electrical,
% optogenetic, etc. stimulus is generated. This might be useful in training
% if only correct targets should be shown, or in a fixation task when no
% distractor stimulus is required.
% 
% Written by Jackson Smith - Feb 2017 - DPAG , University of Oxford
% 
  
  % This is a MET PsychToolbox visual stimulus
  type = 'null' ;
  
  % Variable parameter set
  vpar = { 'null' , 'f' , 0 , -Inf , +Inf } ;
            
  % Function handles
	 init = @finit ;
   stim = @fstim ;
  close = @fclose ;
 chksum = @fchksum ;
  
end % dot


%%% Stimulus definition handles %%%

% Trial initialisation function , use a bogus hitregion
function  S = finit ( ~ , tconst , ~ )
  c6 = tconst.MCC.SDEF.ptb.hitregion.sixcol ;
  S.hitregion = zeros ( 1 , 6 ) ;
  S.hitregion( [ c6.xcoord , c6.ycoord ] ) = -Inf ;
  S.hitregion( [ c6.radius , c6.disp , c6.dtoler ] ) = 0 ;
  S.hitregion( c6.ignore ) = 0 ;
end

% Stimulation function
function  S = fstim ( S , ~ , ~ )  ,  end

% Trial closing function
function  S = fclose ( S , ~ )  ,  end

% Check-sum function
function  c = fchksum ( ~ )  ,  c = 0 ;  end

