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


# EDA_SUMMARY.log 파일 생성부분 

rm -f EDA_SUMMARY.log

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

# 기존 파일 삭제
rm -f EDA_result.log


# path.txt 파일에서 파일 리스트 읽어오기
path=$(cat path.txt)

# 파일 리스트를 공백을 기준으로 배열로 변환
IFS=' ' read -r -a files <<< "$path"


# 각 파일에 대해 확장자를 추가하여 EDA_run.sh 실행
for file in "${files[@]}"; do
    cp $run_dir/coordinates/${file}.xyz ${file}.xyz
    sleep 1
    # EDA_run.sh 실행
    echo "Running: EDA_run.sh ${file}.xyz > ${file}.log"
    ./tmp.sh "${file}.xyz" > "${file}.log"
    sleep 1
    rm ${file}.xyz
done

# path.txt 파일 삭제
rm -f path.txt
# tmp 실행 파일 삭제
rm -f fragment.txt tmp.sh template.gjf tmp.py

# 파일 이동
mv EDA_SUMMARY.log ..
mv EDA_result.log ..

echo ''
echo "NORMAL TERMINATION at $(date)"
