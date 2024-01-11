import glob

xyz_files = glob.glob('/home/kangmg/compchem/multiwfn/sobEDA/sobeda_run/coordinates/*.xyz')
xyz_data ={}

for i, xyz_file in enumerate(xyz_files):
    file_name = xyz_file.split('/')[-1]
    xyz_files[i] = file_name.split('.')[0]

xyz_files = [int(idx) for idx in xyz_files]
xyz_files.sort()
xyz_files = [str(st) for st in xyz_files]

print(xyz_files)

with open('path.txt', 'w') as file:
    file.write(' '.join(xyz_files))
