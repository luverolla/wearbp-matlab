function res_fid = next_fiducial(start_pt, end_pt, fid_src)
%NEXT_FIDUCIAL Summary of this function goes here
%   Detailed explanation goes here
res_fid = [];
for i=1:numel(fid_src)
    if fid_src(i) > start_pt && fid_src(i) < end_pt
        res_fid = fid_src(i);
        break;
    end
end
end

