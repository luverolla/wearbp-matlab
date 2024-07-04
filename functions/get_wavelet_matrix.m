function [mra] = get_wavelet_matrix(sig, level, wname)
%GET_WAVELET_MATRIX Get projection of signal on wavelet slices as a matrix
%   Perform wavelet decomposition, on a signal of length L, on N levels
%   and get the projection in the form of a N*L matrix, calling wrcoef
%   to get the projection for each band slice. The matrix is ordered so
%   that the first row contains the detail coefficients of the highest
%   band slice, and the last row contains the approximation coefficients
[c,l] = wavedec(sig, level, wname);
mra = zeros(level+1,numel(sig));
for k=1:level
    mra(k,:) = wrcoef("d",c,l,wname,k);
end
mra(end,:) = wrcoef("a",c,l,wname,level);
end

