function setrefractiveindex(doms, n)
% SETREFRACTIVEINDEX - sets n for a list of domains
%
%  setrefractiveindex(doms, n) sets refractive index of a list of domains
%
% Copyright (C) 2008, 2009, Timo Betcke, Alex Barnett

for d=doms
  d.refr_ind = n;
end
