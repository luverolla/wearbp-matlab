function cntab = valcounts(target, varname)
%VALCOUNT Summary of this function goes here
%   Detailed explanation goes here
vals = unique(target.(varname));
cntab = table(numel(vals),1);

for i=1:numel(vals)
    cntab{vals(i),1} = height(target(target.(varname) == vals(i)));
end
end

