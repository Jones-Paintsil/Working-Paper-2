 
clear all
set more off
capture log close
cd "J:\Data\DHS\Guinea\Guinea"


*Household Population
use   GNPR71FL.DTA ,clear
renames hv103 hc1 hc27 \ defacto child_age child_sex
*Calculate Height for age: hc70
des hc70
replace hc70=. if hc70>600
sum hc70
replace hc70=hc70/100
sum hc70

*Calculate the weight/height
des hc72   // check new who
replace hc72=. if hc72>600
replace hc72=hc72/100
sum hc72
gen waste_severe=(hc72<-3) if hc72!=. & defacto==1
gen waste=(hc72<-2) if hc72!=. & defacto==1
tab1 waste* [fw=hv005]
 
*Calculate the weight/age
des hc71
replace hc71=. if hc71>600
replace hc71=hc71/100
gen under_wght_severe=(hc71<-3) if hc71!=. & defacto==1
gen under_wght=(hc71<-2) if hc71!=. & defacto==1
tab1 under_wght* [fw=hv005]

*Merge with Household Data=HR
merge m:1 hhid using  GNHR71FL.DTA
save  pr_temp, replace

*Working the Child file
use GNKR71FL.DTA, clear
*size at birth
recode m18 (8=.) (5=1 "Very Small") ///
(4=2 Small) (1/3=3 "Average or Larger"), ///
gen(size_at_birth) 
fre size_at_birth

*child is twin
des b0
clonevar child_twin=b0

*merging kr
des v001 v002 b16
duplicates list v001 v002 b16
drop if b16==0 | b16==.
drop v481    
save child_temp.dta, replace

*Merge the Household file with the Child file
use pr_temp, clear
duplicates list hv001 hv002 hvidx
renames hv001 hv002 hvidx \ v001 v002 b16
drop _m
merge 1:1 v001 v002 b16 using "child_temp.dta"
*keep if _m==3
drop _m

/*rename hv003 to make it mergable with women file
I am not using v003 because v003 is in the children file*/

rename b16 wv003
save pr_kr, replace

*Working out the Women file
use "GNIR71FL.DTA", clear

*Mothers Bmi
des,s
des v437 v438
sum v437 v438
replace v437=. if v437>9000

replace v438=. if v438>=9000

replace v437=v437/10

replace v438=v438/10

replace v438=(v438/100)^2

gen bmi_1c=v437/v438 
des v213 v222
replace bmi_1c=. if v213==1 | v222<3
su bmi_1c

recode bmi_1c (min/18.499999=1 "Thin(BMI<18.5)") ///
(18.5/24.99999=2 "Normal(BMI 18.5-24.9)") ///
(25/max=3 "Overweight/Obese (BMI>=25)") ///
if bmi_1c!=., gen(bmi_c)
tab bmi_c [fw=v005]

*birth spacing
des bord_01 b11_01
gen birth_interval=1 if bord_01==1
replace birth_interval=b11_01 if birth_interval==. & b11_01!=.
fre birth_interval
/*replace birth_interval=. if ha65!=.*/
*
recode birth_interval (1=1 "First Birth") (2/24=2 "<24") ///
(24/47=3 "24-47") (48/max=4 "48+"), gen(birth_interval_1)

*Birth interval using preceding birth interval only
recode b11_01 (9/24=1 "<24") ///
(25/47=2 "25-47") (48/max=3 "48+"), gen(pre_birth_space)

recode b11_01 (9/24=1 "<24") (25/36=2 "25-36") ///
(37/48=3 "37-48") (49/60=4 "49-60") (61/72=5 "61-72") ///
(73/max=6 "73+"), gen(pre_birth_space1)
*merging
duplicates list v001 v002 v003
rename b16_01 wv003
drop if wv003==0 | wv003==.
merge 1:1 v001 v002 wv003 using pr_kr
duplicates list v001 v002 wv003
keep if _m==3
drop _m

save "J:\Data\DHS_MSG\Merge_countries\Guinea",replace
