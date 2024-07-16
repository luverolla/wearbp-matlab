function res_fid = next_fiducial(start_pt, end_pt, fid_src)
%NEXT_FIDUCIAL Get the first fiducial that falls between a given range.
%   Searches, for each fiducial f in fid_src, the first point that 
%   respects the condition: start_pt < f < end_pt
res_fid = [];
for i=1:numel(fid_src)
    if fid_src(i) > start_pt && fid_src(i) < end_pt
        res_fid = fid_src(i);
        break;
    end
end
end

