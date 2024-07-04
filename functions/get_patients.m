function patients = get_patients(records)
%GET_PATIENTS Summary of this function goes here
%   Detailed explanation goes here
patients = strings;
for i = 1:numel(records)
    ch_ks = split(records(i), '-');
    patients(i) = ch_ks(1);
end
patients = unique(patients);
end

