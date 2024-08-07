function [] = var2hfile(filename, vars, names)
%VAR2HFILE Save Matlab arrays and matrices inside a .h file
%   This function can save scalars and monodimentional arrays.
%   Matrices are reshaped as monodimentional arrays so that they can be
%   easily passed as parameter to the matrix-related function in the 
%   ARM CMSIS DSP library.

fid = fopen(filename,'w');
for i=1:numel(vars)
    cur = vars{i};
    shape = size(cur);
    % tensor (n > 2)
    if numel(shape) > 2
        error("Saving multidimentional vectors (n > 2) is not yet supported");
    % matrix (n = 2)
    else
        % scalar
        if shape(1) == 1 && shape(2) == 1
            fprintf(fid, "static float %s = %.8f;\n", names{i}, single(vars{i}));
        else
            cur = reshape(cur.',1,[]);
            str = sprintf('%.8f,' , cur);
            str = str(1:end-1);% strip final comma
            fprintf(fid,'static float %s[%d] = {%s};\n', names{i}, numel(cur), str);
        end       
    end
end
fclose(fid);
end

