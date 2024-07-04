from joblib import Parallel, delayed
import wfdb
import os

des_len = 5*60
fs = 125

pat_dirs = wfdb.get_record_list('mimic3wdb-matched')
n_patients = len(pat_dirs)

def count_unit(i):
    if os.path.exists(f"counts/{i+1}.txt"):
        return
    rec_paths = wfdb.get_record_list('mimic3wdb-matched/1.0/' + pat_dirs[i])
    rec_paths = [r for r in rec_paths if r.startswith('p') and not r.endswith('n')]
    own_records = []

    for j, _ in enumerate(rec_paths):

        if os.path.exists(f"./dataset/{rec_paths[j]}.mat"):
            continue

        try:
            header = wfdb.rdheader(rec_paths[j], rd_segments=True, pn_dir='mimic3wdb-matched/1.0/' + pat_dirs[i] + '/')
            
            if header.sig_len >= des_len * fs and "ABP" in header.sig_name and "PLETH" in header.sig_name:
                own_records.append(rec_paths[j])
        except:
            pass
    
    if len(own_records) > 0:
        with open(f"counts/{i+1}.txt", "w") as f:
            for j in range(len(own_records)):
                f.write(f"{pat_dirs[i]};{rec_paths[j]}\n")

    if i % 1 == 0:
        print(f"Patient {i + 1}/{n_patients}")

Parallel(n_jobs=8)(delayed(count_unit)(i) for i in range(len(pat_dirs)))