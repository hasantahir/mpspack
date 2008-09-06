function [A Sker Dker_noang] = T(k, s, t, o);
% T - deriv of double layer potential discr matrix for density on a segment
%
%  T = T(k, s) where s is a segment returns the matrix discretization of
%   the deriv-of-DLP integral operator with density on the segment,
%      u(x) = int_s partial_n(x) partial_n(y) Phi(x,y) tau(y) ds(y)
%   where Phi is the fundamental solution
%      Phi(x,y) = (i/4) H_0^{(1)}(k|x-y|)    for k>0
%                 (1/2pi) log(1/|x-y|)       for k=0
%   for x each of the points on the self-same segment s. No jump relations
%   are included. For self-interaction, no special quadrature is yet implemented
%
%  T = T(k, s, t) where t is a pointset (any object with fields t.x)
%   uses s as the source segment as above, but target points in t.
%   It is assumed t is not s.
%
%  T = T(k, s, [], opts) or T = T(k, s, t, opts) does the above two choices
%   but with options struct opts including the following:
%    opts.Sker = quad-unweighted kernel matrix of fund-sols (i/4)H_0
%    opts.Dker_noang = quad-unweighted kernel matrix of fund-sols derivs
%                      without the cosphi factors (prevents recomputation
%                      of H1's), ie (ik/4)H_1
%   Passing any of the above options stops it from being calculated internally.
%   When k=0, the above options have no effect.
%
%  [T Sker Dker_noang] = T(...) also returns quad-unweighted
%   kernel values matrices Sker, Dker_noang, when k>0 (empty for Laplace)
%
%  barnett 8/4/08, Tested by routine: testbasis.m, case 9 (non-self case only)
if isempty(k) | isnan(k), error('T: k must be a number'); end
if nargin<4, o = []; end
if nargin<3, t = []; end
if ~isfield(o, 'quad'), o.quad='m'; end; % default self periodic quadr
if ~isfield(o, 'ord'), o.ord=10; end;    % default quadr order
self = isempty(t);               % self-interact: potentially sing kernel
N = numel(s.x);                  % # src pts
if self, t = s; end              % use source as target pts (handle copy)
M = numel(t.x);                  % # target pts
sp = s.speed/2/pi; % note: 2pi converts to speed wrt s in [0,2pi] @ src pt
% compute all geometric parts of matrix...
d = repmat(t.x, [1 N]) - repmat(s.x.', [M 1]); % C-# displacements mat
r = abs(d);                                    % dist matrix R^{MxN}
if self, r(diagind(r)) = 999; end % dummy nonzero diag values
ny = repmat(s.nx.', [M 1]);      % identical rows given by src normals
csry = conj(ny).*d;              % (cos phi + i sin phi).r
nx = repmat(t.nx, [1 N]);        % identical cols given by target normals
csrx = conj(nx).*d;              % (cos th + i sin th).r
clear nx ny d
if k==0                          % Laplace; don't reuse since v. fast anyway
  A = -real(csry.*csrx)./(r.^2.^2)/(2*pi); % (-1/2pi)cos(phi-th)/r^2
  Sker = []; Dker_noang = [];
else
  cc = real(csry).*real(csrx) ./ (r.*r);      % cos phi cos th
  cdor = real(csry.*csrx) ./ (r.*r.*r);   % cos(phi-th) / r
  if ~isfield(o, 'Sker')
    o.Sker = utils.fundsol(r, k);           % Phi
  end
  if ~isfield(o, 'Dker_noang')
    [A o.Dker_noang] = utils.fundsol_deriv(r, -cdor, k); % compute n-deriv Phi
  else
    [A o.Dker_noang] = utils.fundsol_deriv(r, -cdor, k, o.Dker_noang);
  end
  % put all this together to compute the kernel value matrix...
  A = A + k^2 * cc .* o.Sker;
  Sker = o.Sker; Dker_noang = o.Dker_noang; % pass out some calcs for later use
end

if self % ........... source curve = target curve; can be singular kernel
  
  if s.qtype=='p' & o.quad=='k' % Kapur-Rokhlin (ignores diagonal value)
    A(diagind(A)) = 0;
    [s w] = quadr.kapurtrap(N+1, o.ord);  % Zydrunas-supplied K-R weights
    w = 2*pi * w;                 % change interval from [0,1) to [0,2pi)
    A = circulant(w(1:end-1)) .* A .* repmat(sp.', [M 1]); % speed
  
  else       % ------ self-interacts, but no special quadr, just use seg's
    % Use the crude approximation of kappa for diag, usual s.w off-diag...
    A = A .* repmat(s.w, [M 1]);  % use segment usual quadrature weights
    fprintf('warning: using T crude self-quadr, will be awful (no diag)!\n')
    A(diagind(A)) = 0;
  end
  
else % ............................ distant target curve, so smooth kernel
  
  A = A .* repmat(s.w, [M 1]);       % use segment quadrature weights
end