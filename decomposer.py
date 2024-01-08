import sys
import os

if len(sys.argv) != 3:
    print("Usage: python decomposer.py xyz_traj.xyz chunk_num")
    sys.exit(1)

input = sys.argv[1]


def split_and_save(lines_per_chunk,input_file):
    with open(input_file,'r') as file:
        lines = file.readlines()

    total_lines = len(lines)
    num_chunks = round(total_lines / lines_per_chunk)

    output_folder = 'coordinates'

    for i in range(num_chunks):
        start_idx = i * lines_per_chunk
        end_idx = (i + 1) * lines_per_chunk
#        chunk = lines[start_idx+2:end_idx]  ### +2 atom num이랑 title 제거
        chunk = lines[start_idx:end_idx]  ### +2 atom num이랑 title 출력
        output_path = os.path.join(output_folder, f"{i + 1}.xyz")

        with open(output_path, 'w') as output_file:
            output_file.writelines(chunk)
        print(f'{i +1}.xyz file created in {output_folder}')


chunk_int = int(sys.argv[2])

split_and_save(chunk_int, input)
