# easyEDA - modified version of sobEDA

## 1. 설명

<a href="https://pubs.acs.org/doi/10.1021/acs.jpca.3c04374">sobEDA</a> 코드 내부에 coordinate scan을 수행할 수 있는 기능이 포함되어있지만, IRC 좌표 등에 대해서 적용하긴 어려워보여서 코드 일부를 수정했습니다. IRC 또는 NEB 등으로부터 계산된 reaction coordinates 좌표에 대해서 sobEDA 계산을 수행하고 plot할 수 있는 코드도 포함했습니다.  


## 2. 설치 방법

1. 설치는 git clone을 이용하시거나 release에서 zip 파일을 다운받은 후 압축을 풀어주세요.

2. 설치 후 경로 설정을 위해 다음 파이썬 파일을 실행해주세요.
```
python3 first_install.py
```

## 3. 사용 방법

### a. 기능

easyEDA.sh 파일을 실행한 후 다음 4가지 기능 중 원하는 기능을 선택하여 실행할 수 있습니다.
```
 1 : Perform a single-point sobEDA calculation using your xyz file.
 
 2 : Run a serial sobEDA calculation using xyz files in the coordinates folder. (coordinates/*xyz)
 
 3 : Excute the trajectory decomposer, breaking down your trajectory file into individual xyz files.
 
 4 : Generate a plot from your sobEDA result file. (EDA_SUMMARY.log)
```

### b. 실행 과정

가지고 있는 reaction coordinates trajectory 파일로부터 EDA에 대한 plot을 얻고자 한다면 다음 순서에 따라 수행해주세요.

1. 우선 가지고 있는 reaction coordinate 파일을 각각 단일 좌표에 대한 xyz 파일로 분해해야 합니다.
`./easyEDA.sh`을 입력하여 실행한 후 `3`을 입력하면 trajectory 파일과 chunk_size를 인풋으로 받습니다. 가령 파일 내에 포함된 `butadiene.xyz` 파일에 대해서 실행하고 싶으면 chunk_size는 `13`이 됩니다. `head(1)+title(1)+coordinates(10)+공백(1)`

2. `template.gjf`와 `fragment.txt` 파일에 대해서 파일명을 유지한채 내용을 적절히 수정해야합니다. `fragment.txt` 파일은 EDA 계산을 수행할 때 n개의 fragment에 대한 spin multiplicity, charge, atom index를 포함합니다. `template.gjf`는 계산에 대한 theory와 basis 정보를 담고 있습니다. 자세한 내용은 공식 메뉴얼을 참고해주세요.

3. 첫번째 단계에서 생성된 `coordinates/*.xyz` 파일에 대해서 EDA 계산을 수행하기 위해선 `./easyEDA.sh`을 실행한 후 `2`를 입력해주세요. 분자의 크기나 좌표 수에 따라서 시간이 오래 소유될 수 있습니다.

4. `scr/*` 폴더에 `*.log` 파일은 각각의 좌표에 대한 sobEDA 계산 결과를 담고 있습니다. 이 결과들은 `EDA_result.log`와 `EDA_SUMMARY.log`에 요약되어있습니다. 필요에 따라 `scr/*` 파일은 삭제하셔도 됩니다.

5. 결과를 plot 하기 위해선 `./easyEDA.sh`을 실행한 후 `4`를 입력하시면 됩니다. x_axis의 타입은 IRC, distacne, angle, dihedral angle로 4가지 축 종류를 제공합니다. title, x_label, y_label은 사용자로 부터 입력받습니다. 그래프 스타일을 수정하려면, `source/plot.py`에서 figure(1) 부분을 수정하시면 됩니다. path vs. x_axis에 대한 plot은 사용자가 설정한 x_axis가 적당한지 보여줍니다. 일반적으로 monotonic function이 아니면 좋지 못한 x_axis입니다.

## 4. 필요한 프로그램
sobEDA는 다음 두 프로그램에 의존성이 있습니다.
* Multiwfn (>=2023-Jun-23)
* Gaussian16 (>=G16 A.03)

## 5. 참고

[1] sobEDA code

Original sobEDA : http://sobereva.com/685

Download link   : http://sobereva.com/soft/sobEDA_tutorial.zip
