import os


pwd = os.path.dirname(os.path.abspath(__file__))

def path_set(replaced_line, line_num, file_path):
    with open(file_path, 'r') as f:
        lines = f.readlines()
    lines[line_num-1] = replaced_line + '\n' # line start with 1
    with open(file_path, 'w') as file:
        file.writelines(lines)



# scan.sh
scan_sh_path = pwd+"/source/scan.sh"
scan_sh_num = 4
scan_sh_line = f'run_dir="{pwd}"'
path_set(scan_sh_line, scan_sh_num, scan_sh_path)

# plot.py - 1
plot_py_path1 = pwd+"/source/plot.py"
plot_py_num1 = 71
plot_py_line1 = f"    xyz_files = glob.glob('{pwd}/coordinates/*.xyz')"
path_set(plot_py_line1, plot_py_num1, plot_py_path1)

# plot.py - 2
plot_py_path2 = pwd+"/source/plot.py"
plot_py_num2 = 114
plot_py_line2 = f"xyz_files = glob.glob('{pwd}/coordinates/*.xyz')"
path_set(plot_py_line2, plot_py_num2, plot_py_path2)

# make_path.py
plot_py_path = pwd+"/source/make_path.py"
plot_py_num = 3
plot_py_line = f"xyz_files = glob.glob('{pwd}/coordinates/*.xyz')"
path_set(plot_py_line, plot_py_num, plot_py_path)

# decomposer.py
decomposer_py_path = pwd+"/source/decomposer.py"
decomposer_py_num = 33
decomposer_py_line = f"output_folder = '{pwd}/coordinates'"
path_set(decomposer_py_line, decomposer_py_num, decomposer_py_path)

# easyEDA.sh
easyEDA_sh_path = pwd+"/easyEDA.sh"
easyEDA_sh_num = 3
easyEDA_sh_line = f'run_dir="{pwd}"'
path_set(easyEDA_sh_line, easyEDA_sh_num, easyEDA_sh_path)
