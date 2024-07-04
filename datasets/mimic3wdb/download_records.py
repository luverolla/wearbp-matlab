import scipy.io
from joblib import Parallel, delayed
import wfdb
import os

def proc_pat(i, num_pats):
    if not os.path.exists(f"counts/{i+1}.txt"):
        return
    with open(f"counts/{i+1}.txt", "r") as f:
        records = f.readlines()

        for j in range(len(records)):
            pat_dir = records[j].split(";")[0]
            rec_name = records[j].split(";")[1].strip()

            if os.path.exists(f"./dataset/{rec_name}.mat"):
                print(f"Record {rec_name} already exists, skipping", flush=True)
                continue

            try:
                #print(f"Starting record {rec_name} ({j + 1}/{len(records)})")
                sig, fields = wfdb.rdsamp(rec_name, pn_dir=f'mimic3wdb-matched/1.0/{pat_dir}', channel_names=["ABP", "PLETH"])
                sig = sig.T

                scipy.io.savemat(f"./dataset/{rec_name}.mat", {"abp_raw": sig[0,:], "ppg_raw": sig[1,:]}, do_compression=True)

                print(f"Patient {i+1}/{num_pats} Record {j + 1}/{len(records)}", flush=True)
            except:
                pass


num_pats = len(os.listdir("counts"))
Parallel(n_jobs=8)(delayed(proc_pat)(i, num_pats) for i in range(num_pats))