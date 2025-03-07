% 
% BDP BrainSuite Diffusion Pipeline
% 
% Copyright (C) 2023 The Regents of the University of California and
% the University of Southern California
% 
% Created by Chitresh Bhushan, Divya Varadarajan, Justin P. Haldar, Anand A. Joshi,
%            David W. Shattuck, and Richard M. Leahy
% 
% This program is free software; you can redistribute it and/or
% modify it under the terms of the GNU General Public License
% as published by the Free Software Foundation; version 2.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,
% USA.
% 


function [interp_mat, target_mat_size] = interpolation_matrix_2D(orig_mat_size, scale_factor)
% Generates the voxel indices interpolation matrix which can be used to
% directly generate the interpolated image ordered by voxel indices.
%
% It may work with arbitrary scale_factor, but results with power of two
% should be perfect according to bi-linear interpolation. 
%

if isequal(scale_factor, [1 1])
   target_mat_size = orig_mat_size;
   interp_mat = speye(prod(orig_mat_size), prod(orig_mat_size));
   return
end

xy_step = 1./scale_factor;
[xg, yg] = ndgrid(1:xy_step(1):orig_mat_size(1), 1:xy_step(2):orig_mat_size(2));

target_mat_size = size(xg);
xg_ceil = ceil(xg);
yg_ceil = ceil(yg);
xg_floor = floor(xg);
yg_floor = floor(yg);

% integer mask 
xg_int_mask = (xg_ceil==xg_floor);
yg_int_mask = (yg_ceil==yg_floor);

% correct the ceil for integers
xg_ceil(xg_int_mask) = xg_ceil(xg_int_mask)+1;
yg_ceil(yg_int_mask) = yg_ceil(yg_int_mask)+1;

% find weights
fl_fl_weight = (xg_ceil - xg)  .*  (yg_ceil - yg);
fl_cl_weight = (xg_ceil - xg)  .*  (yg - yg_floor);
cl_fl_weight = (xg - xg_floor) .*  (yg_ceil - yg);
cl_cl_weight = (xg - xg_floor) .*  (yg - yg_floor);

% dummy; weights are zero 
yg_ceil(yg_ceil>orig_mat_size(2)) = 1;
xg_ceil(xg_ceil>orig_mat_size(1)) = 1;

% voxel indices
fl_fl_orig_vox_ind = sub2ind(orig_mat_size, xg_floor, yg_floor);
fl_cl_orig_vox_ind = sub2ind(orig_mat_size, xg_floor, yg_ceil);
cl_fl_orig_vox_ind = sub2ind(orig_mat_size, xg_ceil, yg_floor);
cl_cl_orig_vox_ind = sub2ind(orig_mat_size, xg_ceil, yg_ceil);
target_vox_ind = floor(sub2ind(target_mat_size, xg*scale_factor(1)-(scale_factor(1)-1),  yg*scale_factor(2)-(scale_factor(2)-1)));


% create sparse interpolation matrix 

interp_mat = sparse([target_vox_ind(:);     target_vox_ind(:);     target_vox_ind(:);     target_vox_ind(:)], ...
                    [fl_fl_orig_vox_ind(:); fl_cl_orig_vox_ind(:); cl_fl_orig_vox_ind(:); cl_cl_orig_vox_ind(:)], ...
                    [fl_fl_weight(:);       fl_cl_weight(:);       cl_fl_weight(:);       cl_cl_weight(:)], ...
                    prod(target_mat_size), prod(orig_mat_size));


end
