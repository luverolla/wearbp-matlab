function S = take_sigs(file)
%TAKE_SIGS Loads signals from a .mat file for supplying to a parfor loop.
%   This function is necessary since the builtin LOAD cannot be used
%   inside Matlab's parallelized for loops.
%
%   All the variables contained in the .mat files are returned as members
%   of a Matlab structure
S = matfile(file);
end