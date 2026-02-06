function f = P6_FF(relr,Re)
% Code from mathworks: https://nl.mathworks.com/matlabcentral/answers/110994-labelling-three-axes-of-moody-plot

% 'moody_estimation' finds friction factor by solving the Colebrook equation (Moody Chart)
% Inputs: e/D, Re.
% Output: f.

if (Re < 0)
error('OB:Deterministic:NegativeReynoldsNumber', 'Reynolds number = %f, but cannot be negative', Re);
elseif (Re < 2000)
f = 64/Re; return % Laminar flow
end
 
if (relr > 0.05)
warning('epsilon/diameter ratio = %f is not on Moody chart',relr);
end

if Re<4000, warning('Re = %f in transition range',Re); end

% Use fzero to find f from Colebrook equation.
% coleFun is an anonymous function object to evaluate F(f,e/d,Re)
% fzero returns the value of f such that F(f,e/d/Re) = 0 (approximately)
% fi = initial guess from Haaland equation, see White, equation 6.64a
% Iterations of fzero are terminated when f is known to whithin +/- dfTol
coleFun = @(f,ed,Re) 1.0/sqrt(f) + 2.0*log10( ed/3.7 + 2.51/( Re*sqrt(f)));
fi = 1/(1.8*log10(6.9/Re + (relr/3.7)^1.11))^2;
f = fzero_2(coleFun,fi,[],relr,Re);

% Error check:
if f<0
   error('OB:Deterministic:NegativeFrictionFactor', 'Friction factor = %f, but cannot be negative', f);
end
