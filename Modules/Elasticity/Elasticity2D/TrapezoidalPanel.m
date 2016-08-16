% Trapezoidal panel 
close all
clear
clc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%------------------------PRE-PROCESSING------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% control points
tic

CtrlPts = zeros(4, 2, 2);

CtrlPts(1 : 3, 1, 1) = [0; 0; 0];
CtrlPts(1 : 3, 2, 1) = [2; 0.5; 0];

CtrlPts(1 : 3, 1, 2) = [0; 1; 0];
CtrlPts(1 : 3, 2, 2) = [2; 1; 0];

CtrlPts(4, :, :) = 1;

KntVect{1} = [0 0 1 1];
KntVect{2} = [0 0 1 1];

% degree of basis function
p=2;q=2;
% repeated knot value inside knot vector
kx=1;ky=1;
% number of elements in each direction
nelx=10; nely=10;
% create NURBS surface in CAD 
Surf = CreateNURBS(KntVect, CtrlPts);
% h,p,k-refinements
Surf = KRefine(Surf, [nelx, nely], [p, q], [p-kx, q-ky]);

figure
hold on
axis equal
daspect([1, 1, 1])
PlotGeo(Surf);
PlotKnts(Surf);
PlotCtrlPts(Surf);
PlotCtrlNet(Surf);

% --------------------------------------------------------------
Mesh = Mesh2D(Surf, 'VectorField');

% Assemble siffnesss matrix
disp([num2str(toc),'  Assembling the system'])
% material properties
E = 30e6;
nu = 0.3;

KVals = calcLocalStiffnessMatrices2D(Mesh, Surf, E, nu, 'PlaneStress');
[Rows, Cols, Vals] = convertToTripletStorage(Mesh, KVals);

% Convert triplet data to sparse matrix
K = sparse(Rows, Cols, Vals);
clear Rows Cols Vals

f = zeros(Mesh.NDof, 1);
% Impose natural boundary conditions
disp([num2str(toc),'  Imposing natural boundary conditions'])

Ty = @(x, y) -100;
[Fy1, DofsFy1] = applyNewmannBdryVals(Surf, Mesh, Ty, 4, 'FY');

f(DofsFy1) = f(DofsFy1) + Fy1;

% Impose essential boundary conditions
disp([num2str(toc),'  Imposing essential boundary conditions'])
h = @(x, y) 0;

[UX, DofsX] = projDrchltBdryVals(Surf, Mesh, h, 1, 'UX');
[UY, DofsY] = projDrchltBdryVals(Surf, Mesh, h, 1, 'UY');

BdryIdcs = [DofsY; DofsX];
BdryVals = [UY; UX];

FreeIdcs = setdiff(1 : Mesh.NDof, BdryIdcs);

d = zeros(Mesh.NDof, 1);
d(BdryIdcs) = BdryVals;

f(FreeIdcs) = f(FreeIdcs) - K(FreeIdcs, BdryIdcs) * BdryVals; 

% Solve the system
disp([num2str(toc),'  Solving the system'])
d(FreeIdcs) = K(FreeIdcs, FreeIdcs) \ f(FreeIdcs);

%------------------------------------------------------------------------
% strain energy
%------------------------------------------------------------------------
StrainEnergy = 0.5*f'*d;
disp(['StrainEnergy = ', num2str(StrainEnergy, 20)]);
% -----------------------------------------------------------------------
% IGA solution
[C, F] = NURBSEval(Surf, {linspace(0, 1, 50), 1.0}, d);

x = C(1, :)';
y = C(2, :)';

figure
hold on
title('Vertical displacement at the upper line')
plot(x, F(2, :)', 'b*');
% -----------------------------------------------------------------------

% Export solution to vtk format
disp([num2str(toc),'  Exporting result to *.vtk format'])
ParaPts = {linspace(0, 1, 201), linspace(0, 1, 201)};
    
SPToVTKStress(Surf, d, ParaPts, E, nu, 'PlaneStress',...
    'TrapezoidalPanelStress')
filename = 'TrapezoidalPanelDispl';
fieldname = 'Displ';
SPToVTK(Surf, d, ParaPts, filename, fieldname)

