function uk = acmp_p(sm, K, M, P, p)
% -------------------------------------------------------------------------
% Communications and Signal Processing Group
% Department of Electrical and Electronic Engineering
% Imperial College London, 2011
%
% Date        : 23/02/2011
% Supervisor  : Dr Pier Luigi Dragotti
% Author      : Jose Antonio Uriguen
%
% File        : acmp_p.m
% -------------------------------------------------------------------------

H = fliplr(toeplitz(sm(M+1:1:P+1), sm(M+1:-1:1)));

[U,aaa,aaa] = svd(H,0);

U = U(:,1:K);
Z = pinv(U(1:end-p,:)) *U(p+1:end,:);

uk = (eig(Z)).^(1/p);
end