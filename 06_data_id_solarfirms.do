*****Intraday market bids of all firms owning solar power
clear
clear matrix
set type double
set more off
program drop _all
mat drop _all

forvalues p =1(1)6 {
forvalues y = 2020(1)2020 {
forvalues m = 1(1)12 {
	
clear
gen year = 0
cd "$dirpath/Intraday/Monthly/Sessions"
save solar_id_`y'_`m'_`p'.dta, replace

forvalues d = 1(1)31 {
local file =  `y'*1000000 + `m'*10000 + `d'*100  + `p'
local ordner = `y'*100 + `m'
cd "C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\Data/Intraday/Rawdata/curva_pibc_uof_`ordner'"

*check if this day exists
capture confirm file `"curva_pibc_uof_`file'.1"'
di `file'
qui if _rc == 0 {
*Hourly bids
   *import Omie bidding data
	clear
	insheet using curva_pibc_uof_`file'.1, delimiter(";")
	* drop first 2 lines & missing data
	drop if _n < 3

*if not empty, continue
capture list v1
qui if _rc == 0  {
	gen hour = real(v1)
	replace v2 = rtrim(v2)
	gen year = real(substr(v2,7,4))
	gen month = real(substr(v2,4,2))
	gen day = real(substr(v2,1,2))
	rename v3 country_id_`p'
	rename v4 unit
	gen type_id_`p' = "S" if v5 == "V"
	replace type_id_`p' = "D" if v5 == "C"	
	replace v6 = subinstr(v6,".","",1)
	replace v6 = subinstr(v6,",",".",1)
	replace v7 = subinstr(v7,",",".",1)
	gen mwh_id_`p' = real(v6)
	gen pbid_id_`p' = real(v7)
	gen accepted_id_`p' = 1 if v8 == "C" | v8 == "P"
	replace accepted_id_`p' = 0 if v8 == "O"
	drop v* 
	sort unit
	
*account for summer/winter time change: 
*add observation if one hour less, drop if one hour more
	drop if hour > 24
	summ hour	
	if (r(max) ==  23) {
		expand 2 if hour == 23, generate(new)
		replace hour = 24 if new == 1
		drop new
	}
	
cd "$dirpath/Units"	
sort unit hour
merge m:1 unit using unitdata1.dta
drop if _merge==2
drop _merge
	expand 2 if unit=="ACE1" | unit=="ACE2" | unit=="ALABEF" | unit=="ALL1"| unit =="ALZ1"| /// 
	unit=="ALZ2" | unit=="ASC2" | unit=="GAR1" | unit=="BIEMTEC" | unit=="CENER1" | ///
	unit=="ECRERE1" | unit=="GARRAF" | unit=="HGULLA" | unit=="SMULLES" | unit=="SNTEC" | ///
	| unit =="TECSMUR" | unit=="TECYCAL" | unit=="TRL1" | unit =="VAN2",gen(exp1)
	merge m:1 unit using unitdata2.dta
	drop if _merge==2
	replace owner=owner2 if exp1==1 
	replace ownership=ownership2 if exp1==1
	*replace firm_code=firm_code2 if exp1==1
	drop _merge owner2 ownership2 
	*firm_code2
	expand 2 if unit=="ALABEF" & exp1==0 | unit=="ALZ1" & exp1==0 | unit =="ALZ2" & exp1==0 ///
	| unit=="ASC2" & exp1==0 | unit=="BIEMTEC" & exp1==0 | unit =="GARRAF" & exp1==0 ///
	| unit=="HGULLA" & exp1==0 | unit =="SMULLES" & exp1==0 ///
	| unit=="SMULLES" & exp1==0 | unit=="SNTEC" & exp1==0 | unit =="TECSMUR" & exp1==0 ///
	| unit=="TECYCAL" & exp1==0 | unit=="TRL1" & exp1==0 | unit =="VAN2" & exp1==0, gen(exp2)
	merge m:1 unit using unitdata3.dta
	drop if _merge==2
	replace owner=owner3 if exp2==1 
	replace ownership=ownership3 if exp2==1
	expand 2 if unit=="ALZ1" & exp1==0 & exp2==0 | unit=="ALZ2" & exp1==0 & exp2==0 | unit=="TRL1" & exp1==0 & exp2==0, gen(exp3)
	drop _merge owner3 ownership3 
	merge m:1 unit using unitdata4.dta
	drop if _merge==2
	replace owner=owner4 if exp3==1 
	replace ownership=ownership4 if exp3==1
	drop exp* _merge owner4 ownership4 
	replace owner="SHELL" if strpos(owner,"SHELL")==1
*only supply bids of firms owning solar power sold in MIBEL and ES
drop if country_id_`p'=="PT"
drop if solar!=1 
drop if year!=`y'
drop if month!=`m'

*check if empty
*capture assert _N == 0
*qui if _rc!=0 {
*duplicates drop year month day hour owner, force
compress
cd "$dirpath/Intraday/Monthly/Sessions"
append using solar_id_`y'_`m'_`p'.dta
save solar_id_`y'_`m'_`p'.dta, replace
}
}
}
}
}	
}



*aggregate unit data in monthly session data by owner
forvalues y = 2020(1)2020 {
forvalues m = 1(1)12 {
forvalues p = 1(1)6 {
cd "$dirpath/Intraday/Monthly/Sessions"
use solar_id_`y'_`m'_`p'.dta 
sort year month day hour owner 
by year month day hour owner: egen supply_id_`p'=total(mwh) if type_id_`p'=="S"
by year month day hour owner: egen supply_id_a_`p'=total(mwh) if type_id_`p'=="S"&accepted_id_`p'==1
by year month day hour owner: egen supply_id_a_`p'_sol=total(mwh) if type_id_`p'=="S" & ///
 strpos(plant_type,"Solar")==1&accepted_id_`p'==1
by year month day hour owner: egen demand_id_`p'=total(mwh) if type_id_`p'=="D"
by year month day hour owner: egen demand_id_a_`p'=total(mwh) if type_id_`p'=="D"&accepted_id_`p'==1
by year month day hour owner: egen demand_id_a_`p'_sol=total(mwh) if type_id_`p'=="D"& ///
accepted_id_`p'==1 & strpos(plant_type,"Solar")==1&accepted_id_`p'==1

by year month day hour owner: egen q_total_demand_id_`p'=max(demand_id_`p') 
by year month day hour owner: egen q_total_bought_id_`p'=max(demand_id_a_`p') 
by year month day hour owner: egen q_total_offered_id_`p'=max(supply_id_`p') 
by year month day hour owner: egen q_total_sold_id_`p'=max(supply_id_a_`p') 
by year month day hour owner: egen q_total_sold_id_`p'_sol=max(supply_id_a_`p'_sol) 
by year month day hour owner: egen q_total_bought_id_`p'_sol=max(demand_id_a_`p'_sol) 

duplicates drop year month day hour owner, force
keep unit hour year month day owner solar wind q_total_demand_id_`p' q_total_bought_id_`p' q_total_offered_id_`p' q_total_sold_id_`p'
cd "$dirpath/Intraday/Monthly/Sessions/clean"
save solar_id_`y'_`m'_`p'.dta, replace
}
}
}

*merge monthly sessions 
forvalues y = 2020(1)2020 {
forvalues m = 1(1)12 {
clear
gen year=0
cd "$dirpath/Intraday/Monthly"
save solar_id_`y'_`m'.dta, replace
clear
cd "$dirpath/Intraday/Monthly/Sessions/clean"
use solar_id_`y'_`m'_1.dta 
qui forvalues p = 2(1)6 {
merge 1:1 year month day hour owner using solar_id_`y'_`m'_`p'.dta 
drop _merge
}
*duplicates drop year month day hour owner, force
cd "$dirpath/Intraday/Monthly"
save solar_id_`y'_`m'.dta, replace
}
}


*Merge monthly intraday market datasets 
cd "$dirpath/Final"
clear
gen year=0
save solar_id.dta, replace
forvalues y = 2020(1)2020 {
forvalues m = 1(1)12 {
clear
cd "$dirpath/Intraday/Monthly"
use solar_id_`y'_`m'.dta
cd "$dirpath/Final"
append using solar_id.dta
save solar_id.dta, replace
}
}
