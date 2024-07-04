import os
from joblib import Parallel, delayed
import scipy.io as scio
import vitaldb

N_JOBS = 8

if not os.path.exists('./data'):
    os.mkdir('./data')

cases = vitaldb.find_cases(['ART', 'PLETH'])

def process_case(i):
    case_path = f'./data/{cases[i]}.mat'
    if os.path.exists(case_path):
        return
    
    print(f'Processing case {cases[i]} ({i}/{len(cases)})', flush=True)
    case_data = vitaldb.load_case(cases[i], ['ART', 'PLETH'], 1/500)
    scio.savemat(case_path, {'abp_raw': case_data[:,0], 'ppg_raw': case_data[:,1]}, do_compression=True)

Parallel(n_jobs=N_JOBS)(delayed(process_case)(i) for i in range(len(cases)))