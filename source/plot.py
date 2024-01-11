import glob
import numpy as np
import math
import matplotlib.pyplot as plt

def load_coordinates(name):
    file_name= name+'.xyz'
    file_path = f"coordinates/{file_name}"
    with open(file_path, 'r') as file:
        content = file.read()
    return content.strip()

def head_remover(xyz_lines):
    if len(xyz_lines[0].split()) == 1:
        xyz_lines = xyz_lines[2:]
    elif len(xyz_lines[0].split()) == 4:
        xyz_lines = xyz_lines
    else:
        print("Check your xyz file format!")
    return xyz_lines

def distance(atom1, atom2):

    x1, y1, z1 = np.array(atom1)
    x2, y2, z2 = np.array(atom2)
    distance = math.sqrt((x2 - x1)**2 + (y2 - y1)**2 + (z2 - z1)**2)
    return distance

def angle(atom1, atom2, atom3): 

    vector1 = np.array(atom1) - np.array(atom2)
    vector3 = np.array(atom3) - np.array(atom2)

    dot_product = np.dot(vector1, vector3)
    magnitude1 = np.linalg.norm(vector1)
    magnitude3 = np.linalg.norm(vector3)

    angle_radians = np.arccos(dot_product / (magnitude1 * magnitude3))
    angle_degrees = np.degrees(angle_radians)

    return angle_degrees

def dihedral_angle(atom1, atom2, atom3, atom4):
    
    b2 = np.array(atom3) - np.array(atom2)
    b1 = np.array(atom2) - np.array(atom1)
    b3 = np.array(atom4) - np.array(atom3)

    v1 = np.cross(b1, b2)
    v2 = np.cross(b2, b3)

    angle = np.arctan2(np.linalg.norm(np.cross(v1, v2)), np.dot(v1, v2))
    angle_degrees = np.degrees(angle)

    if angle_degrees < 0:
        angle_degrees += 360.0

    return angle_degrees

def get_list_in_coordinates(coordinates):
    list_in_coordinates = []
    for coordinate in coordinates:
        coordinate_split = [float(str) for str in coordinate.split()[1:]]
        
        list_in_coordinates.append(coordinate_split)
    return list_in_coordinates

def x_axis(type, index_list):

    # path 정의
    xyz_files = glob.glob('/home/kangmg/compchem/multiwfn/sobEDA/sobeda_run/coordinates/*.xyz')
    for i, xyz_file in enumerate(xyz_files):
        file_name = xyz_file.split('/')[-1]
        xyz_files[i] = file_name.split('.')[0]
    path = [int(idx) for idx in xyz_files]
    path.sort()
    path_str = [str(i) for i in path]

    path_coordinates = {}
    for irc in path_str:
        path_coordinates[irc] = load_coordinates(irc)

    xaxis =[]
    if type == 'distance':
        for irc in path_str:
            coordinates = path_coordinates[irc].split('\n')
            coordinates = head_remover(coordinates)
            list_in_coordinates = get_list_in_coordinates(coordinates)
            input_coordi = [list_in_coordinates[i] for i in index_list]
            xaxis.append(distance(*input_coordi))
    elif type == 'angle':
        for irc in path_str:
            coordinates = path_coordinates[irc].split('\n')
            coordinates = head_remover(coordinates)
            list_in_coordinates = get_list_in_coordinates(coordinates)
            input_coordi = [list_in_coordinates[i] for i in index_list]
            xaxis.append(angle(*input_coordi))
    elif type == 'dihedral angle':
        for irc in path_str:
            coordinates = path_coordinates[irc].split('\n')
            coordinates = head_remover(coordinates)
            list_in_coordinates = get_list_in_coordinates(coordinates)
            input_coordi = [list_in_coordinates[i] for i in index_list]
            xaxis.append(dihedral_angle(*input_coordi))
    elif type == 'IRC':
        xaxis=path_str

    return xaxis

def rel(lst, n):
    return [x - lst[n] for x in lst]

# path 정의
xyz_files = glob.glob('/home/kangmg/compchem/multiwfn/sobEDA/sobeda_run/coordinates/*.xyz')
for i, xyz_file in enumerate(xyz_files):
    file_name = xyz_file.split('/')[-1]
    xyz_files[i] = file_name.split('.')[0]
path = [int(idx) for idx in xyz_files]
path.sort()
path_str = [str(st) for st in path]

# load_EDA_result
data = np.genfromtxt('EDA_SUMMARY.log', skip_header=16)


# image
angle_image="""
    ex) input = 1 2 3

            [1]
       [2]< )   angle(deg)
            [3]

"""

distance_image="""
    ex) input = 1 2
    
     [1] --- [2]
          distnace(angs)

"""

dihedral_image="""
    ex) input = 1 2 3 4
    
               [1]
              /                 [1]
      [3]--[2]      =    [2,3]< )   angle(deg)
     /                          [4]
  [4]

"""

#define x axis
while True:
    print("Possible x-axis types : ")
    print(' \n distance \n angle \n dihedral angle \n IRC \n ')
    type = input("Your x-axis type? : ")
    if type == 'distance':
        print("")
        print(distance_image)
        print("")
        two_atoms = input(" Two atoms. a b : ")
        xaxis_parameter = [int(x) for x in two_atoms.split()]
        your_x_axis = x_axis(type, xaxis_parameter)
        print(f" Distance btw. {xaxis_parameter} : \n ")
        print(your_x_axis)
        print("")
        min_value = min(your_x_axis)
        max_value = max(your_x_axis)
        print(f" Max value : {max_value}")
        print(f" Min value : {min_value}")
        break
    elif type == 'angle':
        print("")
        print(angle_image)
        print("")
        three_atoms = input(" Three atoms. a b c : ")
        xaxis_parameter = [int(x) for x in three_atoms.split()]
        your_x_axis = x_axis(type, xaxis_parameter)
        print(f" Angle btw. {xaxis_parameter} : \n ")
        print(your_x_axis)
        print("")
        max_value = max(your_x_axis)
        min_value = min(your_x_axis)
        print(f" Max value : {max_value}")
        print(f" Min value : {min_value}")
        break
    elif type == 'dihedral angle':
        print("")
        print(dihedral_image)
        print("")
        four_atoms = input(" Four atoms. a b c d : ")
        xaxis_parameter = [int(x) for x in four_atoms.split()]
        your_x_axis = x_axis(type, xaxis_parameter)
        print(f" Dihedral angle btw. {xaxis_parameter} : \n ")
        print(x_axis)
        print("")
        max_value = max(your_x_axis)
        min_value = min(your_x_axis)
        print(f" Max value : {max_value}")
        print(f" Min value : {min_value}")
        break
    elif type == 'IRC':
        xaxis_parameter =[0]
        your_x_axis = x_axis(type, xaxis_parameter)
        break
    else:
        print(" Error: Invalid input")


# EDA summary 파일로부터 데이터 추출
#your_x_axis=x_axis(axis_type, xaxis_parameter)
total = data[:,1]
electrostatic = data[:,2]
pauli = data[:,3]
orbital = data[:,4]
coulomb_correlation = data[:,5]

# total interaction energy에서 min value를 찾고 그 coordinate index를 rel_index에 저장
min_value = float('inf')
rel_idx = -1
for i, num in enumerate(total):
    if num < min_value:
        min_value = num
        rel_idx = i

# min value를 기준으로 relative value로 만들어줌
total_r = rel(total,rel_idx)
electrostatic_r = rel(electrostatic,rel_idx)
pauli_r = rel(pauli,rel_idx)
orbital_r = rel(orbital,rel_idx)
coulomb_correlation_r = rel(coulomb_correlation,rel_idx)


#plot 부분

plt.figure(1)

plt.plot(your_x_axis,electrostatic_r,label='electrostatic',color='red',linestyle='-.',marker='s')
plt.plot(your_x_axis,pauli_r,label='pauli',color='blue',linestyle='-',marker='*')
plt.plot(your_x_axis,orbital_r,label='orbital',color='cyan',linestyle='dotted',marker='D')
plt.plot(your_x_axis,coulomb_correlation_r,label='coulomb correlation',color='magenta',linestyle='dashdot',marker='+')
plt.plot(your_x_axis,total_r,label='total interaction',color='black',linestyle='dashed',marker='x')

print("")
plt.title(input(" Title : "))
plt.xlabel(input(" x-label : "))
plt.ylabel(input(" y-label : "))

while True:
    if type == 'IRC':
        break
    elif type != 'IRC':
        print("")
        print(" x-axis range? Format 'x1 < x < x2' ")
        print("")
        range_str = input(" Format x1 x2 : ")
        range = [float(x) for x in range_str.split()]
        isinstance(range, list)
        plt.xlim(range)
        break
    else:
        print(" What is wrong? ")

plt.legend(loc=2)



plt.figure(2)

plt.title("path vs. x-axis")
plt.xlabel("path")
plt.ylabel(f"your x-axis : {type}")
plt.plot(path_str, your_x_axis,color='black',linestyle='dashed',marker='o')

plt.show()