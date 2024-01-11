#!/bin/bash

# 디렉토리 정의
run_dir="/home/kangmg/compchem/multiwfn/sobEDA/sobeda_run"

cd $run_dir

# 실행 파일 복사
cp source/make_path.py scr/tmp.py
cp source/EDA_run.sh scr/tmp.sh
chmod 770 scr/tmp.sh
cp fragment.txt scr/fragment.txt
cp template.gjf scr/template.gjf

cd $run_dir/scr

# make_path.py로 path list파일인 path.txt 생성
echo 'Your reaction coordinate is :'
python3 tmp.py
echo ''

# gaussian template.gjf head로부터 option 추출
read -r option < template.gjf
IFS=' ' read -ra array <<< $option
unset array[0]
unset array[${#array[@]}]
unset array[${#array[@]}]
calc_option=${array[@]}
read -r nFrags < fragment.txt

for ((i = 0; i < nFrags; i++)); do
    current_line=$((3 + i * 2))
    line_content=$(sed -n "${current_line}p" fragment.txt)
    echo -n "| $line_content " >> tmp
done
echo -n "|" >> tmp
read -r frag_info < tmp
rm -f tmp


# EDA_SUMMARY.log 파일 생성부분 
rm -f EDA_SUMMARY.log

echo "Original sobEDA        : http://sobereva.com/soft/sobEDA_tutorial.zip" >> EDA_SUMMARY.log
echo "Modified this version  : https://github.com/kangmg/modified_sobEDA" >> EDA_SUMMARY.log
echo "--------------------------------------------------------------------" >> EDA_SUMMARY.log
echo "" >> EDA_SUMMARY.log
echo "          	   EDA scan result summary ( SobEDA )" >> EDA_SUMMARY.log
echo "" >> EDA_SUMMARY.log
echo "" >> EDA_SUMMARY.log
echo " *  Calculation option  *   $calc_option " >> EDA_SUMMARY.log
echo " *       nFrages        *   $nFrags " >> EDA_SUMMARY.log
echo " *      Frag info.      *   $frag_info " >> EDA_SUMMARY.log
echo " *        Date          *   $(date)" >> EDA_SUMMARY.log
echo "" >> EDA_SUMMARY.log
echo "--------------------------------------------------------------------" >> EDA_SUMMARY.log
echo "xyz_index   E_Tot       E_Els       E_Pauli     E_Orb        E_Ccorr" >> EDA_SUMMARY.log
echo "--------------------------------------------------------------------" >> EDA_SUMMARY.log


# EDA_result.log 파일 생성부분
rm -f EDA_result.log

echo "Original sobEDA        : http://sobereva.com/soft/sobEDA_tutorial.zip" >> EDA_result.log
echo "Modified this version  : https://github.com/kangmg/modified_sobEDA" >> EDA_result.log
echo "--------------------------------------------------------------------" >> EDA_result.log
echo "" >> EDA_result.log
echo "                     EDA scan result ( SobEDA )" >> EDA_result.log
echo "" >> EDA_result.log
echo "" >> EDA_result.log
echo " *  Calculation option  *   $calc_option " >> EDA_result.log
echo " *       nFrages        *   $nFrags " >> EDA_result.log
echo " *      Frag info.      *   $frag_info " >> EDA_result.log
echo " *        Date          *   $(date)" >> EDA_result.log
echo "" >> EDA_SUMMARY.log
echo "--------------------------------------------------------------------" >> EDA_result.log
echo "" >> EDA_result.log
echo "" >> EDA_result.log







# path.txt 파일에서 파일 리스트 읽어오기
path=$(cat path.txt)

# 파일 리스트를 공백을 기준으로 배열로 변환
IFS=' ' read -r -a files <<< "$path"

total_cpu_time=0
# 각 파일에 대해 확장자를 추가하여 EDA_run.sh 실행
for file in "${files[@]}"; do
    cp $run_dir/coordinates/${file}.xyz ${file}.xyz
    sleep 0.3
    # EDA_run.sh 실행
    echo "Running: EDA_run.sh ${file}.xyz > ${file}.log"
    start_time=$(date +%s.%N)
    ./tmp.sh "${file}.xyz" > "${file}.log"
    end_time=$(date +%s.%N)
    sleep 0.3
    rm ${file}.xyz
    cpu_time=$(echo "$end_time - $start_time" | bc)
    total_cpu_time=$(echo "$total_cpu_time + $cpu_time" | bc)
    echo "CPU Time : $cpu_time seconds" >> EDA_result.log
    echo "#----------------------------------------------------------------------------#" >> EDA_result.log
    echo "" >> EDA_result.log
done

# path.txt 파일 삭제
rm -f path.txt
# tmp 실행 파일 삭제
rm -f fragment.txt tmp.sh template.gjf tmp.py

# 파일 이동
mv EDA_SUMMARY.log ..
mv EDA_result.log ..

echo ''
echo "Total CPU Time : $total_cpu_time seconds"
echo "NORMAL TERMINATION at $(date)"
