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


function [lambdas, eigenVectors,M_0, residualImage] = dtiLogLinearW(bImages, bMatrices);
% Justin Haldar (jhaldar@usc.edu)

M = size(bImages,2);
N = size(bImages,3);
P = size(bImages,4);
B = size(bImages,1);

%% Configure linear equations

diffusionWeightedImages = zeros(B,M,N,P);

bMatrix = zeros(B,7);

for bIndex = 1:B
    diffusionWeightedImages(bIndex,:,:,:) = log(abs(squeeze(bImages(bIndex,:,:,:))));
    bMatrix(bIndex,:) = -[bMatrices(1,1,bIndex) bMatrices(2,2,bIndex) bMatrices(3,3,bIndex) 2*bMatrices(2,1,bIndex) 2*bMatrices(3,1,bIndex) 2*bMatrices(3,2,bIndex) -1];
end

%% Permute diffusion tensors and calculate various meta-parameters
lambdas = zeros(3,M,N,P);
eigenVectors = zeros(3,3,M,N,P);
if nargout>3
    residualImage = zeros(M,N,P);
end
M_0 = zeros(M,N,P);
for mIndex = 1:M
    for nIndex = 1:N
        for pIndex = 1:P
            ind= not(isinf(diffusionWeightedImages(:,mIndex,nIndex,pIndex)));
            [Q,R] = qr(diag(abs(bImages(ind,mIndex,nIndex,pIndex)))*bMatrix(ind,:),0);
            dValues = R\Q' *(diag(abs(bImages(ind,mIndex,nIndex,pIndex)))*diffusionWeightedImages(ind,mIndex,nIndex,pIndex));
            if not(isnan(sum(dValues)))
                [v,d] = eig([dValues(1),dValues(4),dValues(5);dValues(4),dValues(2),dValues(6);dValues(5),dValues(6),dValues(3)]);
                lambdas(:,mIndex,nIndex,pIndex) = flipud(sort(diag(d)));
                [temp,index1] = sort(diag(d));
                eigenVectors(:,:,mIndex,nIndex,pIndex) = v(:,flipud(index1));
                if nargout>3
                    residualImage(mIndex,nIndex,pIndex) = norm(bMatrix*dValues(:) - diffusionWeightedImages(:,mIndex,nIndex,pIndex));
                end
                M_0(mIndex,nIndex,pIndex) = exp(dValues(7));
            end
        end
    end
end
return;;
