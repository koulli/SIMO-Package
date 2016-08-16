%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot the B-spline curve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close all
clear
clc

% control points
% CtrlPts = zeros(2, 7);
% CtrlPts(1 : 2, 1) = [0; 0];
% CtrlPts(1 : 2, 2) = [0; 1];
% CtrlPts(1 : 2, 3) = [1; 1];
% CtrlPts(1 : 2, 4) = [2.5; -0.5];
% CtrlPts(1 : 2, 5) = [4; 2];
% CtrlPts(1 : 2, 6) = [5; 2.5];
% CtrlPts(1 : 2, 7) = [6; 1];

%CtrlPts = zeros(2, 4);
CtrlPts(1 : 2, 1) = [0; 0];
CtrlPts(1 : 2, 2) = [1/4; 1/2];
CtrlPts(1 : 2, 3) = [3/4; 3/4];
CtrlPts(1 : 2, 4) = [1; 0];

% knot vector
%KntVect = [0 0 0 0 1 2 3 4 4 4 4];
KntVect = [0 0 0 1/2 1 1 1];
KntVect = KntVect ./ max(KntVect);

NCtrlPts = size(CtrlPts, 2); % number of control points
p = numel(KntVect) - NCtrlPts - 1; % order of basis functions
ParaPts = linspace(0, 1, 101); % paramatric points

Idx = FindSpan(NCtrlPts, p, ParaPts, KntVect);
N0 = BasisFuns(Idx, ParaPts, p, KntVect);

C = zeros(2, numel(ParaPts));
for i = 1 : p + 1
    C = C + bsxfun(@times, N0(:, i)', CtrlPts(:, Idx - p + i - 1));
end

figure
hold on
daspect([1 1 1])
axis equal
axis off
% Plot curve
plot(C(1, :), C(2, :));
% Plot control polygon
plot(CtrlPts(1, :), CtrlPts(2, :), 'k--');
% Plot control points
plot(CtrlPts(1, :), CtrlPts(2, :),...
    'r.','MarkerSize',15);
