#!/bin/bash

run_dir='/home/kangmg/compchem/multiwfn/sobEDA/sobeda_run'
echo ""
echo "1 : Perform a single-point sobEDA calculation using your xyz file."
echo "2 : Run a serial sobEDA calculation using xyz files in the coordinates folder. (coordinates/*xyz)"
echo "3 : Excute the trajectory decomposer, breaking down your trajectory file into individual xyz files."
echo "4 : Generate a plot from your sobEDA result file. (EDA_SUMMARY.log)"
echo ""
read -p "Which oepraction would you like to perform? " choice
echo ""
cd $run_dir
case $choice in
  1)
    read -p "Your xyz file ? : " xyz_file
    cp source/EDA_run.sh scr/tmp.sh
    cp $xyz_file scr/tmp.xyz
    cp fragment.txt scr/fragment.txt
    cp template.gjf scr/template.gjf
    cd scr
    echo " sobEDA is running . . . "
    ./tmp.sh tmp.xyz > sobEDA.log
    mv sobEDA.log ..
    rm tmp.sh tmp.xyz template.gjf fragment.txt EDA_SUMMARY.log
    mv EDA_result.log ..
    ;;
  2)
    source/scan.sh
    ;;
  3)
    read -p " Your trajectory file ? : " traj_file
    read -p " chunck size ? : " chunck
    python3 source/decomposer.py $traj_file $chunck
    ;;
  4)
    python3 source/plot.py
    ;;
  *)
    echo "Invalid choice. Please enter a number between 1 and 4."
    ;;
esac
