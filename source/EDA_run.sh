# Performing sobEDA/sobEDAw energy decomposition based on Multiwfn (>=2023-Jun-23) and Gaussian (>=G16 A.03)
# Written by Tian Lu (sobereva@sina.com), last update: 2023-Jun-24
#!/bin/bash

#시스템 변수 받기
input_xyz_file="$1"
#확장자 제거
input_xyz=${input_xyz_file%.*}

#Command of running Gaussian
gau="g16"
#Command of running Multiwfn
mwfn="Multiwfn"

iCP=0 #=1: Using complex basis functions for fragment calculations; =0: Using own basis functions of fragment
sobEDAw=0 #=1: Also show sobEDAw terms using parm_c/a/r defined below ; =0: Do not show
irun=1 #=1: Run Gaussian calculations; =0: Only deal with existing files without actual calculations
idetail=0 #=1: Show detailed energy variation between stages, need additional cost for individually calculating frozen state; =0: Do not show

#Set fitted parameters for calculating sobEDAw terms. Just uncomment those to be actually used
# B3LYP-D3(BJ)/6-31+G(d,p) with iCP=1
#parm_c=0.575;parm_a=0.071;parm_r=2.571
# B3LYP-D3(BJ)/6-311+G(2d,p) with iCP=1:
#parm_c=0.550;parm_a=0.037;parm_r=2.750
# BHandHLYP-D3(BJ)/6-31+G(d,p) with iCP=1:
#parm_c=0.634;parm_a=-0.065;parm_r=0.702
# BHandHLYP-D3(BJ)/6-311+G(2d,p) with iCP=1:
#parm_c=0.595;parm_a=-0.284;parm_r=0.582
# BLYP-D3(BJ)/6-31+G(d,p) with iCP=1:
#parm_c=0.338;parm_a=-0.033;parm_r=2.783
#See Tables 1 and 2 of original paper of sobEDA for parameters of more calculation levels



##### Calculate isolated fragments #####
dos2unix -q fragment.txt
read nfrag < fragment.txt
echo "Number of fragments: $nfrag"
iopsh=0 #Assumed to be closed-shell

for ((i=1;i<=$nfrag;i=i+1))
do
awk 'NR==var' var=$((2*i)) fragment.txt > tmp
read chg multi < tmp
multiarr[$i]=$multi
if (( $multi != 1 )); then
  iopsh=1
fi
if (( $multi < 0 )); then #Remove negative sign
  multi=${multi#-}
fi
awk 'NR==var' var=$((2*i+1)) fragment.txt > tmp
read atom < tmp
echo
echo "Charge and spin multiplicity of fragment $i: $chg $multi"
echo "Indices of atoms in fragment $i: $atom"
rm -f tmp

echo "Generating Gaussian input file of fragment $i via Multiwfn (${input_xyz}_fragment$i.gjf)"
if (( $iCP == 0 )); then
  $mwfn $input_xyz_file << EOF > /dev/null
gi
custom
$chg $multi
$atom
${input_xyz}_fragment.gjf
q
EOF
else
  $mwfn $input_xyz_file << EOF > /dev/null
gi
Bq
$chg $multi
$atom
${input_xyz}_fragment.gjf
q
EOF
fi
echo "%chk=${input_xyz}_fragment$i.chk" > tmp.txt
cat tmp.txt ${input_xyz}_fragment.gjf > ${input_xyz}_fragment$i.gjf
rm -f tmp.txt ${input_xyz}_fragment.gjf

if (( $irun == 1 )); then
  echo "Running: $gau < ${input_xyz}_fragment$i.gjf &> ${input_xyz}_fragment$i.out"
  $gau < ${input_xyz}_fragment$i.gjf &> ${input_xyz}_fragment$i.out
  if test $? -eq 0
  then

  	echo "Finished successfully!"
  else
  	echo "Error encountered, please check corresponding output file! Now script exits"
    exit 1
  fi
  echo "Running: formchk ${input_xyz}_fragment$i.chk ${input_xyz}_fragment$i.fch"
  formchk ${input_xyz}_fragment$i.chk ${input_xyz}_fragment$i.fch > /dev/null
  rm -f ${input_xyz}_fragment$i.chk
fi

E_tot[$i]=`grep "SCF Done" ${input_xyz}_fragment$i.out | awk -F = '{print $2}'| awk '{print $1}'`
E_T[$i]=`grep "ET=" ${input_xyz}_fragment$i.out | awk -F = '{print $2}' | awk '{print $1}'`
E_x[$i]=`grep "ENTVJ=" ${input_xyz}_fragment$i.out | awk -F = '{print $3}' | awk '{print $1}'`
E_c[$i]=`grep "ENTVJ=" ${input_xyz}_fragment$i.out | awk -F = '{print $4}' | awk '{print $1}'`
E_xc[$i]=`echo ${E_x[$i]}+${E_c[$i]} | bc -l`
if grep -Fq "Dispersion energy" ${input_xyz}_fragment$i.out
then
  E_disp[$i]=`grep "Dispersion energy" ${input_xyz}_fragment$i.out | awk -F = '{print $2}'| awk '{print $1}'`
else
  E_disp[$i]=0
fi
E_els[$i]=`echo "${E_tot[$i]}-(${E_xc[$i]})-(${E_disp[$i]})-(${E_T[$i]})" | bc -l`

echo "Energy components of fragment $i:"
echo "E_tot = ${E_tot[$i]} Hartree"
echo "E_T = ${E_T[$i]} Hartree"
echo "E_els = ${E_els[$i]} Hartree"
echo "E_x = ${E_x[$i]} Hartree"
echo "E_c = ${E_c[$i]} Hartree"
#echo "E_xc = ${E_xc[$i]} Hartree"
echo "E_disp = ${E_disp[$i]} Hartree"

done

if (( $iopsh == 1 )); then
  echo
  echo "Note: Calculation of whole system will be conducted in unrestricted way"
fi



##### Calculate promolecular state #####
echo
echo "Generating fch file of promolecular state via Multiwfn (${input_xyz}_promol.fch)"
if (( $iCP == 0 )); then
  nfragtmp=$nfrag
else
  nfragtmp=-$nfrag #Negative value indicates that identical bases were used for all fragment calculations 
fi
echo 100 >> tmp
echo 19 >> tmp
echo 3 >> tmp
echo $nfragtmp >> tmp
for ((i=2;i<=$nfrag;i=i+1))
do
  echo ${input_xyz}_fragment$i.fch >> tmp
done
if (( $iopsh == 1 )); then
  for ((j=1;j<=$nfrag;j=j+1))
  do
    form=`awk 'NR==2' ${input_xyz}_fragment$j.fch | cut -c 11`
    if [ "$form" == "U" ]; then #Unrestricted fragment, Multiwfn asks if flipping spin
      if (( ${multiarr[$j]} > 0 )); then
        echo n >> tmp
      else
        echo y >> tmp
      fi
    fi
  done
fi
echo 0 >> tmp
echo q >> tmp
$mwfn ${input_xyz}_fragment1.fch < tmp > /dev/null
mv combine.fch ${input_xyz}_promol.fch
rm -f tmp
echo "Running: unfchk ${input_xyz}_promol.fch ${input_xyz}_promol.chk"
unfchk ${input_xyz}_promol.fch ${input_xyz}_promol.chk > /dev/null

echo "Generating Gaussian input file of promolecular state via Multiwfn (${input_xyz}_promol.gjf)"
$mwfn ${input_xyz}_promol.fch << EOF > /dev/null
gi
${input_xyz}_promol.gjf
n
q
EOF

sed -i "1s/^/%oldchk=${input_xyz}_promol.chk\n/" ${input_xyz}_promol.gjf
sed -i "s/nosymm/nosymm scf=maxcyc=-1 guess=read iop(4\/6=222)/g" ${input_xyz}_promol.gjf

if (( $irun == 1 )); then
  echo "Running: $gau < ${input_xyz}_promol.gjf &> ${input_xyz}_promol.out"
  $gau < ${input_xyz}_promol.gjf &> ${input_xyz}_promol.out
  if test $? -eq 0
  then
  	echo "Finished successfully!"
  else
  	echo "Error encountered, please check corresponding output file! Now script exits"
    exit 1
  fi
fi

E_tot_promol=`grep "SCF Done" ${input_xyz}_promol.out | awk -F = '{print $2}'| awk '{print $1}'`
E_T_promol=`grep "ET=" ${input_xyz}_promol.out | awk -F = '{print $2}' | awk '{print $1}'`
E_x_promol=`grep "ENTVJ=" ${input_xyz}_promol.out | awk -F = '{print $3}' | awk '{print $1}'`
E_c_promol=`grep "ENTVJ=" ${input_xyz}_promol.out | awk -F = '{print $4}' | awk '{print $1}'`
E_xc_promol=`echo $E_x_promol+$E_c_promol | bc -l`
if grep -Fq "Dispersion energy" ${input_xyz}_promol.out
then
  E_disp_promol=`grep "Dispersion energy" ${input_xyz}_promol.out | awk -F = '{print $2}'| awk '{print $1}'`
else
  E_disp_promol=0
fi
E_els_promol=`echo "$E_tot_promol-($E_xc_promol)-($E_disp_promol)-($E_T_promol)" | bc -l`

echo "Energy components of promolecular state:"
echo "E_tot = $E_tot_promol Hartree"
echo "E_T = $E_T_promol Hartree"
echo "E_els = $E_els_promol Hartree"
echo "E_x = $E_x_promol Hartree"
echo "E_c = $E_c_promol Hartree"
#echo "E_xc = $E_xc_promol Hartree"
echo "E_disp = $E_disp_promol Hartree"



##### Calculate frozen state (orthogonalized promolecular wavefunction) #####
if (( $idetail == 1 )); then
  echo
  echo "Generating Gaussian input file of frozen state (${input_xyz}_frozen.gjf)"
  cp ${input_xyz}_promol.gjf ${input_xyz}_frozen.gjf
  sed -i "s/ iop(4\/6=222)//g" ${input_xyz}_frozen.gjf
  
  if (( $irun == 1 )); then
    echo "Running: $gau < ${input_xyz}_frozen.gjf &> ${input_xyz}_frozen.out"      ############################
    $gau < ${input_xyz}_frozen.gjf &> ${input_xyz}_frozen.out
    if test $? -eq 0
    then
    	echo "Finished successfully!"
    else
    	echo "Error encountered, please check corresponding output file! Now script exits"
      exit 1
    fi
  fi
  
  E_tot_frz=`grep "SCF Done" ${input_xyz}_frozen.out | awk -F = '{print $2}'| awk '{print $1}'`
  E_T_frz=`grep "ET=" ${input_xyz}_frozen.out | awk -F = '{print $2}' | awk '{print $1}'`
  E_x_frz=`grep "ENTVJ=" ${input_xyz}_frozen.out | awk -F = '{print $3}' | awk '{print $1}'`
  E_c_frz=`grep "ENTVJ=" ${input_xyz}_frozen.out | awk -F = '{print $4}' | awk '{print $1}'`
  E_xc_frz=`echo $E_x_frz+$E_c_frz | bc -l`
  if grep -Fq "Dispersion energy" ${input_xyz}_frozen.out
  then
    E_disp_frz=`grep "Dispersion energy" ${input_xyz}_frozen.out | awk -F = '{print $2}'| awk '{print $1}'`
  else
    E_disp_frz=0
  fi
  E_els_frz=`echo "$E_tot_frz-($E_xc_frz)-($E_disp_frz)-($E_T_frz)" | bc -l`
  
  echo "Energy components of frozen state:"
  echo "E_tot = $E_tot_frz Hartree"
  echo "E_T = $E_T_frz Hartree"
  echo "E_els = $E_els_frz Hartree"
  echo "E_x = $E_x_frz Hartree"
  echo "E_c = $E_c_frz Hartree"
  #echo "E_xc = $E_xc_frz Hartree"
  echo "E_disp = $E_disp_frz Hartree"
fi


##### Calculate final state with frozen state as guess #####
echo
echo "Generating Gaussian input file of final state (${input_xyz}_final.gjf)"
cp ${input_xyz}_promol.gjf ${input_xyz}_final.gjf
sed -i "1s/^/%chk=${input_xyz}_final.chk\n/" ${input_xyz}_final.gjf
sed -i "s/ scf=maxcyc=-1//g" ${input_xyz}_final.gjf
sed -i "s/ iop(4\/6=222)//g" ${input_xyz}_final.gjf

if (( $irun == 1 )); then
  echo "Running: $gau < final.gjf &> final.out"
  $gau < ${input_xyz}_final.gjf &> ${input_xyz}_final.out
  if test $? -eq 0
  then
  	echo "Finished successfully!"
  else
  	echo "Error encountered, please check corresponding output file! Now script exits"
    exit 1
  fi
fi

E_tot_final=`grep "SCF Done" ${input_xyz}_final.out | awk -F = '{print $2}'| awk '{print $1}'`
E_T_final=`grep "ET=" ${input_xyz}_final.out | awk -F = '{print $2}' | awk '{print $1}'`
E_x_final=`grep "ENTVJ=" ${input_xyz}_final.out | awk -F = '{print $3}' | awk '{print $1}'`
E_c_final=`grep "ENTVJ=" ${input_xyz}_final.out | awk -F = '{print $4}' | awk '{print $1}'`
E_xc_final=`echo "$E_x_final+$E_c_final" | bc -l`
if grep -Fq "Dispersion energy" ${input_xyz}_final.out
then
  E_disp_final=`grep "Dispersion energy" ${input_xyz}_final.out | awk -F = '{print $2}'| awk '{print $1}'`
else
  E_disp_final=0
fi
E_els_final=`echo "$E_tot_final-($E_xc_final)-($E_disp_final)-($E_T_final)" | bc -l`
if (( $idetail == 0 )); then #Get energy at first cycle (frozen state energy)
  E_tot_frz=`grep " E=" ${input_xyz}_final.out | head -1 | awk '{print $2}'`
fi

echo "Energy components of final state:"
echo "E_tot = $E_tot_final Hartree"
echo "E_T = $E_T_final Hartree"
echo "E_els = $E_els_final Hartree"
echo "E_x = $E_x_final Hartree"
echo "E_c = $E_c_final Hartree"
#echo "E_xc = $E_xc_final Hartree"
echo "E_disp = $E_disp_final Hartree"
echo "Frozen state energy: $E_tot_frz Hartree"



##### Show detailed energy variations #####
if (( $idetail == 1 )); then
  echo
  echo "Details of energy variations:"
  echo "                     Total      kin       els      exch      corr       disp"
  
  dE_tot=$E_tot_promol
  dE_els=$E_els_promol
  dE_T=$E_T_promol
  dE_x=$E_x_promol
  dE_c=$E_c_promol
  dE_disp=$E_disp_promol
  for ((i=1;i<=$nfrag;i=i+1))
  do
    dE_tot=`echo "$dE_tot-(${E_tot[$i]})" | bc -l`
    dE_T=`echo "$dE_T-(${E_T[$i]})" | bc -l`
    dE_els=`echo "$dE_els-(${E_els[$i]})" | bc -l`
    dE_x=`echo "$dE_x-(${E_x[$i]})" | bc -l`
    dE_c=`echo "$dE_c-(${E_c[$i]})" | bc -l`
    dE_disp=`echo "$dE_disp-(${E_disp[$i]})" | bc -l`
  done
  echo | awk '{printf ("%s %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %s\n","isolate->promol:",v1*627.51,vT*627.51,v2*627.51,v3*627.51,v4*627.51,v5*627.51,"kcal/mol")}' v1=$dE_tot v2=$dE_els v3=$dE_x v4=$dE_c v5=$dE_disp vT=$dE_T
  
  dE_tot=`echo "$E_tot_frz-($E_tot_promol)" | bc -l`
  dE_T=`echo "$E_T_frz-($E_T_promol)" | bc -l`
  dE_els=`echo "$E_els_frz-($E_els_promol)" | bc -l`
  dE_x=`echo "$E_x_frz-($E_x_promol)" | bc -l`
  dE_c=`echo "$E_c_frz-($E_c_promol)" | bc -l`
  dE_disp=`echo "$E_disp_frz-($E_disp_promol)" | bc -l`
  echo | awk '{printf ("%s %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %s\n","promol ->frozen:",v1*627.51,vT*627.51,v2*627.51,v3*627.51,v4*627.51,v5*627.51,"kcal/mol")}' v1=$dE_tot v2=$dE_els v3=$dE_x v4=$dE_c v5=$dE_disp vT=$dE_T
  
  dE_tot=`echo "$E_tot_final-($E_tot_frz)" | bc -l`
  dE_T=`echo "$E_T_final-($E_T_frz)" | bc -l`
  dE_els=`echo "$E_els_final-($E_els_frz)" | bc -l`
  dE_x=`echo "$E_x_final-($E_x_frz)" | bc -l`
  dE_c=`echo "$E_c_final-($E_c_frz)" | bc -l`
  dE_disp=`echo "$E_disp_final-($E_disp_frz)" | bc -l`
  echo | awk '{printf ("%s %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %s\n","frozen ->final: ",v1*627.51,vT*627.51,v2*627.51,v3*627.51,v4*627.51,v5*627.51,"kcal/mol")}' v1=$dE_tot v2=$dE_els v3=$dE_x v4=$dE_c v5=$dE_disp vT=$dE_T
  
  dE_tot=$E_tot_final
  dE_T=$E_T_final
  dE_els=$E_els_final
  dE_x=$E_x_final
  dE_c=$E_c_final
  dE_disp=$E_disp_final
  for ((i=1;i<=$nfrag;i=i+1))
  do
    dE_tot=`echo "$dE_tot-(${E_tot[$i]})" | bc -l`
    dE_T=`echo "$dE_T-(${E_T[$i]})" | bc -l`
    dE_els=`echo "$dE_els-(${E_els[$i]})" | bc -l`
    dE_x=`echo "$dE_x-(${E_x[$i]})" | bc -l`
    dE_c=`echo "$dE_c-(${E_c[$i]})" | bc -l`
    dE_disp=`echo "$dE_disp-(${E_disp[$i]})" | bc -l`
  done
  echo | awk '{printf ("%s %9.2f %9.2f %9.2f %9.2f %9.2f %9.2f %s\n"," Whole process: ",v1*627.51,vT*627.51,v2*627.51,v3*627.51,v4*627.51,v5*627.51,"kcal/mol")}' v1=$dE_tot v2=$dE_els v3=$dE_x v4=$dE_c v5=$dE_disp vT=$dE_T
fi



##### Show summary of interaction #####
dE_tot=$E_tot_final
dE_els=$E_els_promol
dE_x=$E_x_promol
dE_c=$E_c_promol
dE_disp=$E_disp_final
for ((i=1;i<=$nfrag;i=i+1))
do
  dE_tot=`echo "$dE_tot-(${E_tot[$i]})" | bc -l`
  dE_els=`echo "$dE_els-(${E_els[$i]})" | bc -l`
  dE_x=`echo "$dE_x-(${E_x[$i]})" | bc -l`
  dE_c=`echo "$dE_c-(${E_c[$i]})" | bc -l`
  dE_disp=`echo "$dE_disp-(${E_disp[$i]})" | bc -l`
done
dE_orb=`echo "$E_tot_final-($E_tot_frz)" | bc -l`
dE_rep=`echo "$E_tot_frz-($E_tot_promol)" | bc -l`

echo
echo "*************************"
echo "***** Final results *****"
echo "*************************"
echo
echo | awk '{printf ("%s %9.2f %s\n","Total interaction energy:",v*627.51,"kcal/mol")}' v=$dE_tot
echo
echo "Physical components of interaction energy derived by sobEDA:"
echo | awk '{printf ("%s %9.2f %s\n","Electrostatic (E_els):",v*627.51,"kcal/mol")}' v=$dE_els
echo | awk '{printf ("%s %9.2f %s\n","Exchange (E_x):",v*627.51,"kcal/mol")}' v=$dE_x
echo | awk '{printf ("%s %9.2f %s\n","Pauli repulsion (E_rep):",v*627.51,"kcal/mol")}' v=$dE_rep
echo | awk '{printf ("%s %9.2f %s\n","Exchange-repulsion (E_xrep = E_x + E_rep):",(v1+v2)*627.51,"kcal/mol")}' v1=$dE_x v2=$dE_rep
echo | awk '{printf ("%s %9.2f %s\n","Orbital (E_orb):",v*627.51,"kcal/mol")}' v=$dE_orb
echo | awk '{printf ("%s %9.2f %s\n","DFT correlation (E_DFTc):",v*627.51,"kcal/mol")}' v=$dE_c
echo | awk '{printf ("%s %9.2f %s\n","Dispersion correction (E_dc):",v*627.51,"kcal/mol")}' v=$dE_disp
echo | awk '{printf ("%s %9.2f %s\n","Coulomb correlation (E_c = E_DFTc + E_dc):",(v1+v2)*627.51,"kcal/mol")}' v1=$dE_c v2=$dE_disp


#새로운 EDA_result.log 파일 생성 및 내용 추가
file_content=$(tail -n +3 "${input_xyz_file}")
echo "" >> EDA_result.log
echo "COORDINATE NAME : ${input_xyz}.xyz" >> EDA_result.log 
echo '#----------------------------------GEOMETRY----------------------------------#' >> EDA_result.log
echo "$file_content" >> EDA_result.log
echo '#---------------------------------EDA RESULT---------------------------------#' >> EDA_result.log
echo | awk '{printf ("%s %9.2f %s\n","Total interaction energy:",v*627.51,"kcal/mol")}' v=$dE_tot >> EDA_result.log
echo | awk '{printf ("%s %9.2f %s\n","Electrostatic (E_els):",v*627.51,"kcal/mol")}' v=$dE_els >> EDA_result.log
echo | awk '{printf ("%s %9.2f %s\n","Exchange (E_x):",v*627.51,"kcal/mol")}' v=$dE_x >> EDA_result.log
echo | awk '{printf ("%s %9.2f %s\n","Pauli repulsion (E_rep):",v*627.51,"kcal/mol")}' v=$dE_rep >> EDA_result.log
echo | awk '{printf ("%s %9.2f %s\n","Exchange-repulsion (E_xrep = E_x + E_rep):",(v1+v2)*627.51,"kcal/mol")}' v1=$dE_x v2=$dE_rep >> EDA_result.log
echo | awk '{printf ("%s %9.2f %s\n","Orbital (E_orb):",v*627.51,"kcal/mol")}' v=$dE_orb >> EDA_result.log
echo | awk '{printf ("%s %9.2f %s\n","DFT correlation (E_DFTc):",v*627.51,"kcal/mol")}' v=$dE_c >> EDA_result.log
echo | awk '{printf ("%s %9.2f %s\n","Dispersion correction (E_dc):",v*627.51,"kcal/mol")}' v=$dE_disp >> EDA_result.log
echo | awk '{printf ("%s %9.2f %s\n","Coulomb correlation (E_c = E_DFTc + E_dc):",(v1+v2)*627.51,"kcal/mol")}' v1=$dE_c v2=$dE_disp >> EDA_result.log
echo '#----------------------------------------------------------------------------#' >> EDA_result.log


#새로운 EDA_SUMMARY.log 파일 생성 및 내용 추가
E_tot_v=$(echo | awk '{printf ("%9.2f",v*627.51)}' v=$dE_tot) # total
E_els_v=$(echo | awk '{printf ("%9.2f",v*627.51)}' v=$dE_els) # electrostatic
E_x_v=$(echo | awk '{printf ("%9.2f",v*627.51)}' v=$dE_x) # exchange
E_rep_v=$(echo | awk '{printf ("%9.2f",v*627.51)}' v=$dE_rep) # repulsion
E_xrep_v=$(echo | awk '{printf ("%9.2f",(v1+v2)*627.51)}' v1=$dE_x v2=$dE_rep) # exchange repulsion or Pauli
E_orb_v=$(echo | awk '{printf ("%9.2f",v*627.51)}' v=$dE_orb) # Orbital
E_DFTcorr_v=$(echo | awk '{printf ("%9.2f",v*627.51)}' v=$dE_c)  #DFT correlation
E_dc_v=$(echo | awk '{printf ("%9.2f",v*627.51)}' v=$dE_disp) # dispersion correction
E_Ccorr_v=$(echo | awk '{printf ("%9.2f",(v1+v2)*627.51)}' v1=$dE_c v2=$dE_disp) # coulomb correlation = E_DFTcorr + E_dc
echo "  ${input_xyz}      ${E_tot_v}   ${E_els_v}   ${E_xrep_v}   ${E_orb_v}   ${E_Ccorr_v}" >> EDA_SUMMARY.log


#scr 디렉토리 생성
#if [ ! -d "scr" ]; then
#    mkdir -p "scr"
#fi

# 생성파일을 scr 디렉토리로 이동함
#mv ${input_xyz}_* scr

##### Show scaled sobEDA terms for weak interaction #####
if (( $sobEDAw == 1 )); then
  echo
  echo "Variant of sobEDA for weak interaction (sobEDAw):"
  expterm=`echo "-($parm_r)*($dE_disp/$dE_els-($parm_a))" | bc -l`
  scale=`echo "$expterm $parm_c" | awk '{print exp($1)*(1-$2)+$2;}'`
  if [[ $(echo "$scale > 1" | bc) -eq 1 ]] ; then
    echo | awk '{printf ("%s%6.2f%s\n","Warning: Current w (",v,") is larger than 1.0, scale it to 1.0")}' v=$scale
    scale=1
  fi
  dE_scldisp=`echo "$scale*$dE_c+$dE_disp" | bc -l`
  dE_sclc=`echo "(1.0-$scale)*$dE_c" | bc -l`
  echo | awk '{printf ("%s %7.2f%s\n","Note:",v*100,"% DFT correlation is combined with dispersion correction to yield a SAPT-like dispersion term")}' v=$scale
  echo | awk '{printf ("%s %9.2f %s\n","Electrostatic (E_els):",v*627.51,"kcal/mol")}' v=$dE_els
  echo | awk '{printf ("%s %9.2f %s\n","Exchange-repulsion (including scaled DFT correlation):",(v1+v2+v3)*627.51,"kcal/mol")}' v1=$dE_x v2=$dE_rep v3=$dE_sclc
  echo | awk '{printf ("%s %9.2f %s\n","Orbital (E_orb):",v*627.51,"kcal/mol")}' v=$dE_orb
  echo | awk '{printf ("%s %9.2f %s\n","Dispersion (E_disp):",v*627.51,"kcal/mol")}' v=$dE_scldisp
fi

echo
echo "Please do not forget to cite original paper of Multiwfn program and sobEDA method in your work!"
