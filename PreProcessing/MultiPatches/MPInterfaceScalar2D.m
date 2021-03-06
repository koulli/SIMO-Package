% MP_INTERFACE_2D: create a global numbering of basis functions in two-dimensional multipatch geometries.
%
%   [glob_num, glob_ndof] = mp_interface_2d (interfaces, sp);
%
% INPUT:
%
%  interfaces: structure with the information of the interfaces between patches (see mp_geo_read_file)
%  sp:         object representing the space of discrete functions (see sp_bspline_2d)
%
% OUTPUT:
%
%  glob_num:  global numbering of the discrete basis functions
%  glob_ndof: total number of degrees of freedom
%
% Copyright (C) 2011 Rafael Vazquez
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.

%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.

function [GNum, GNDof] = MPInterfaceScalar2D(Interfaces, Mesh)

  if (~isempty (Interfaces))
    GNum = cell (numel (Mesh), 1);
    patch_intrfc = cell (numel (Mesh), 1);
    ttform   = cell (numel (Mesh), numel (Interfaces));
    ppnum    = cell (numel (Interfaces), 1);
    for iPtc = 1:numel(Mesh)
      GNum{iPtc} = zeros (Mesh{iPtc}.NDof, 1);
      patch_intrfc{iPtc} = union (find([Interfaces.Patch1] == iPtc), ...
                                  find([Interfaces.Patch2] == iPtc));
    end

    for intrfc = 1:numel(Interfaces)
      iPtc1  = Interfaces(intrfc).Patch1;
      iPtc2  = Interfaces(intrfc).Patch2;
      iSide1 = Interfaces(intrfc).Side1;
      iSide2 = Interfaces(intrfc).Side2;
      ttform{iPtc1, intrfc} = Mesh{iPtc1}.Boundary(iSide1).Dofs;
      if (Interfaces(intrfc).Ornt == 1)
        ttform{iPtc2, intrfc} = Mesh{iPtc2}.Boundary(iSide2).Dofs;
      else
        ttform{iPtc2, intrfc} = fliplr (Mesh{iPtc2}.Boundary(iSide2).Dofs);
      end
      ppnum{intrfc} = zeros (1, Mesh{iPtc1}.Boundary(iSide1).NDof);
    end

    GNDof = 0;
% We start with the Dofs that do not belong to any interface
    for iPtc = 1:numel (Mesh)
      nonIntrfcDofs = setdiff(1:Mesh{iPtc}.NDof, [ttform{iPtc,:}]);
      GNum{iPtc}(nonIntrfcDofs) = GNDof + (1:numel(nonIntrfcDofs));
      GNDof = GNDof + numel (nonIntrfcDofs);
    end

% Then we set the interfaces
    for intrfc = 1:numel(Interfaces)
      iPtc     = Interfaces(intrfc).Patch1;
      new_dofs = find (GNum{iPtc}(ttform{iPtc, intrfc}) == 0);
      new_dofs_number = GNDof + (1:numel (new_dofs));
      GNum{iPtc}(ttform{iPtc, intrfc}(new_dofs)) = new_dofs_number;
      ppnum{intrfc}(new_dofs) = new_dofs_number;

      [GNum, ppnum] = set_same_interface (iPtc, intrfc, ttform, new_dofs,...
				   Interfaces, GNum, ppnum, patch_intrfc);
      [GNum, ppnum] = set_same_patch (iPtc, intrfc, ttform, new_dofs, ...
                                   Interfaces, GNum, ppnum, patch_intrfc);
      GNDof = GNDof + numel (new_dofs);

    end

  else
    GNDof = 0;
    GNum = cell (numel (Mesh), 1);
    for iPtc = 1:numel(Mesh)
      GNum{iPtc} = GNDof + (1:Mesh{iPtc}.NDof);
      GNDof = GNDof + Mesh{iPtc}.NDof;
    end
  end    

end

function [glob_num, ppnum] = set_same_patch (iPtc, intrfc, ttform, new_dofs, ...
                                 interfaces, glob_num, ppnum, patch_intrfc);

  intrfc_dofs = ttform{iPtc, intrfc}(new_dofs);
  for ii = setdiff (patch_intrfc{iPtc}, intrfc)
    [common_dofs, pos1, pos2] = intersect (ttform{iPtc, ii}, intrfc_dofs);
    not_set = find (ppnum{ii}(pos1) == 0);
    if (~isempty (not_set))
      ppnum{ii}(pos1(not_set)) = ppnum{intrfc}(new_dofs(pos2(not_set)));
      [glob_num, ppnum] = set_same_interface (iPtc, ii, ttform, ...
                   pos1(not_set), interfaces, glob_num, ppnum, patch_intrfc);
    end
  end
end

function [glob_num, ppnum] = set_same_interface (iPtc, intrfc, ttform, ...
                         new_dofs, interfaces, glob_num, ppnum, patch_intrfc)
  intrfc_dofs = ttform{iPtc, intrfc}(new_dofs);
  iPtc2 = setdiff ([interfaces(intrfc).Patch1 interfaces(intrfc).Patch2], iPtc);
  glob_num{iPtc2}(ttform{iPtc2, intrfc}(new_dofs)) = ...
                            glob_num{iPtc}(intrfc_dofs);
  [glob_num, ppnum] = set_same_patch (iPtc2, intrfc, ttform, new_dofs, ...
			     interfaces, glob_num, ppnum, patch_intrfc);

end
