*Create dataset with all solar day-ahead bids with owner and unit info 
*Note: this code was written building on Fabra & Reguant (2014) (cf. references) code as published
*here: https://www.aeaweb.org/articles?id=10.1257/aer.104.9.2872
clear matrix
set type double
set more off
program drop _all
mat drop _all


*Monthly data
forvalues y = 2017(1)2020 {
forvalues m = 1(1)12 {

clear
gen year=0
cd "$dirpath/Day-Ahead/Monthly"
save solar_pbids_`y'_`m'.dta, replace

forvalues d = 1(1)31 {
local file =  `y'*10000 + `m'*100 + `d'
local ordner = `y'*100 + `m'
cd "$dirpath/Day-Ahead/Rawdata/curva_pbc_uof_`ordner'"
*check if this day exists
capture confirm file `"curva_pbc_uof_`file'.1"'
di `file'
qui if _rc == 0 {
*Hourly bids
    *import Omel bidding data
	clear
	insheet using curva_pbc_uof_`file'.1, delimiter(";")
	* drop first 2 lines 
	drop if _n < 3	

	*rename and destring variables
	gen hour = real(v1)
	replace v2 = rtrim(v2)
	gen year = real(substr(v2,7,4))
	gen month = real(substr(v2,4,2))
	gen day = real(substr(v2,1,2))
	rename v3 country
	rename v4 unit
	gen type = "S" if v5 == "V"
	replace type = "D" if v5 == "C"	
	replace v6 = subinstr(v6,".","",1)
	replace v6 = subinstr(v6,",",".",1)
	replace v7 = subinstr(v7,",",".",1)
	gen mwh = real(v6)
	gen pbid = real(v7)
	gen accepted = 1 if v8 == "C" | v8 == "P"
	replace accepted = 0 if v8 == "O"
	drop v* 
	sort unit
	
	*account for summer/winter time change
	drop if hour > 24
	summ hour	
	if (r(max) ==  23) {
		expand 2 if hour == 23, generate(new)
		replace hour = 24 if new == 1
		drop new
	}


*Add ownership information by merging bidding data with data on unit ownership
*account for multiple ownerships by expanding data
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

*only supply bids of solar power sold in MIBEL and ES
drop if country=="PT"
drop if plant_type!="Solar PV" & plant_type!="Solar" & plant_type!="Thermal Solar"
drop if type!="S"	
	
*create equilibrium price
	sort hour country 
	by hour country: egen mgprice = max(pbid) if accepted == 1 & type == "S"
	replace mgprice = 0 if mgprice == .
	by hour country: egen mg_price = max(mgprice)
	drop mgprice
	
*clean repeated observations, take accepted bid (bid was sold/bought)
	gsort unit owner hour pbid -accepted mwh
	duplicates drop unit owner hour pbid mwh, force
	*Generate variable rejected that indicates if a supply bid of a certain unit 
	*in one hour is not accepted although its price is lower than EQ price 
	*(and the other way around for S)
	gen rejected_temp = 0
	replace rejected_temp = 1 if pbid < mg_price & type == "S" & accepted == 0
	replace rejected_temp = 1 if pbid > mg_price & type == "D" & accepted == 0
	sort unit hour pbid 
	by unit: egen rejected = max(rejected_temp)
	replace rejected = 0 if accepted == 1
	drop rejected_temp

keep year month day hour unit owner pbid mwh mg_price accepted rejected
order year month day hour unit owner pbid mwh mg_price accepted rejected
	
	compress
	cd "$dirpath/Day-Ahead/Monthly"
    append using solar_pbids_`y'_`m'.dta 
	save solar_pbids_`y'_`m'.dta, replace
	
	sleep 10000
}
}
}
}

*Merge monthly bids
cd "$dirpath/Final"
save solar_pbids.dta, replace

forvalues y = 2017(1)2020 {
forvalues m = 1(1)12 {
clear
cd "$dirpath/Day-Ahead/Monthly"
use solar_pbids_`y'_`m'.dta

drop if missing("name")
 
cd "$dirpath/Final"
append using solar_pbids.dta, force
save solar_pbids.dta, replace
sleep 10000
}
}
