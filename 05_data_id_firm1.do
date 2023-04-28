*Create dataset with intraday bids of one particular firm per month
clear
clear matrix
set type double
set more off
program drop _all
mat drop _all

forvalues p =1(1)6 {
forvalues y = 2017(1)2020 {
forvalues m = 1(1)12 {
clear
gen year = 0
cd "$dirpath/Intraday/Monthly/Sessions"
save firm1_id_`y'_`m'_`p'.dta, replace
forvalues d = 1(1)31 {
local file =  `y'*1000000 + `m'*10000 + `d'*100  + `p'
local ordner = `y'*100 + `m'
cd "$dirpath/Intraday/Rawdata/curva_pibc_uof_`ordner'"

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
	replace type = "D" if v5 == "C"	
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
**Add ownership information
*merge bidding data with data on unit ownership 
sort unit hour
merge m:1 unit using unitdata1.dta
drop if _merge==2
drop _merge

*****Only certain firms in Spain
drop if strpos(owner,"INIPEL")!=1
drop if country_id_`p'=="PT"

*check if empty
capture assert _N == 0
qui if _rc!=0 {
****Unit-wise supply and demand offered
	gsort hour unit pbid_id_`p' mwh_id_`p' -type_id_`p' 
	gen supply_unit_id_`p' = mwh_id_`p' if type_id_`p' == "S" 
	replace supply_unit_id_`p' = 0 if supply_unit_id_`p' == .
	by hour unit: replace supply_unit_id_`p' = sum(supply_unit_id_`p')
	by hour unit: egen supply_unit_id_`p'_max=max(supply_unit_id_`p')
	
	gsort hour unit -pbid_id_`p' mwh_id_`p' type_id_`p' 
	gen demand_unit_id_`p' = mwh_id_`p' if type_id_`p' == "D" 
	replace demand_unit_id_`p' = 0 if demand_unit_id_`p' == .
	by hour unit: replace demand_unit_id_`p' = sum(demand_unit_id_`p')
	by hour unit: egen demand_unit_id_`p'_max=max(demand_unit_id_`p')
	
****Unit-wise supply and demand offered and accepted
	gsort hour unit pbid_id_`p' mwh_id_`p' -type_id_`p'
	by hour unit: egen q_total_supply_unit_id_a_`p'=total(mwh_id_`p') /// 
	if type_id_`p'=="S"&accepted_id_`p'==1
	bysort hour unit: egen q_total_supply_unit_id_`p'=max(q_total_supply_unit_id_a_`p')
	gen supply_unit_id_a_`p' = mwh_id_`p' if type_id_`p' == "S"&accepted_id_`p'==1
	replace supply_unit_id_`p' = 0 if supply_unit_id_a_`p' == .
	by hour unit: replace supply_unit_id_a_`p' = sum(supply_unit_id_`p')
	gsort hour unit -pbid_id_`p' mwh_id_`p' type_id_`p'
	by hour unit: egen q_total_demand_unit_id_a_`p'=total(mwh_id_`p') /// 
	if type_id_`p'=="D"&	accepted_id_`p'==1
	gen demand_unit_id_a_`p' = mwh_id_`p' if type_id_`p' == "D" &accepted_id_`p'==1
	replace demand_unit_id_a_`p' = 0 if demand_unit_id_a_`p' == .
	by hour unit: replace demand_unit_id_a_`p' = sum(demand_unit_id_a_`p')
	bysort hour unit: egen q_total_demand_unit_id_`p'=max(q_total_demand_unit_id_a_`p')
	*gen net_supply_unit_id_a_`p' = supply_unit_id_a_`p' - demand_unit_id_a_`p'

	bysort hour unit: egen pbid_id_`p'_S=max(pbid_id_`p') if type_id_`p'=="S"
	bysort hour unit: egen pbid_id_`p'_D=max(pbid_id_`p') if type_id_`p'=="D"
	bysort hour unit: egen pbid_id_`p'_S_max=max(pbid_id_`p'_S) 
	bysort hour unit: egen pbid_id_`p'_D_max=max(pbid_id_`p'_D)
	drop pbid_id_`p'_S pbid_id_`p'_D
	bysort hour unit: egen pbid_id_`p'_a_max_S=max(pbid_id_`p') ///
	if type_id_`p'=="S"&accepted_id_`p'==1
	bysort hour unit: egen pbid_id_`p'_a_max_D=max(pbid_id_`p') /// 
	if type_id_`p'=="D"&accepted_id_`p'==1
	drop if type_id_`p'=="D"
capture assert _N == 0
qui if _rc!=0 {
	gsort hour unit -pbid_id_`p'
capture assert _N == 0
qui if _rc!=0 {
	duplicates drop hour unit, force

	keep country_id_`p' year month day hour unit pbid_id_`p'_* ///
	q_total_supply_unit_id_`p' q_total_demand_unit_id_`p' supply_unit_id_`p'_max ///
	demand_unit_id_`p'_max 

	compress
cd "$dirpath/Intraday/Monthly/Sessions"
append using firm1_id_`y'_`m'_`p'.dta 

cd "$dirpath/Intraday/Monthly/Sessions"
save firm1_id_`y'_`m'_`p'.dta, replace
}
}
}
}
}	
}
}
}
}


***deal with empty datasets
forvalues y = 2017(1)2020 {
forvalues m = 1(1)12 {
forvalues p =1(1)6 {
clear
cd "$dirpath/Intraday/Monthly/Sessions"
use firm1_id_`y'_`m'_`p'.dta
if _N==0 {
	set obs 1
	replace year=`y'
	gen month=`m'
	gen day=1
	gen hour=12
    gen unit="A"
	gen country_id_`p'=.
	gen mg_price_id_`p'=.
	gen mg_quantity_id_`p'=.
	gen supply_unit_id_`p'_max=.
	gen demand_unit_id_`p'_max=. 
	gen q_total_supply_unit_id_`p'=.
	gen q_total_demand_unit_id_`p'=.
	gen pbid_id_`p'_S_max=.
	gen pbid_id_`p'_D_max=.
	gen pbid_id_`p'_a_max_S=. 
	gen pbid_id_`p'_a_max_D=.
	save firm1_id_`y'_`m'_`p'.dta, replace
}
save firm1_id_`y'_`m'_`p'.dta, replace
}
}	
}



**merge monthly sessions 
forvalues y = 2017(1)2020 {
forvalues m = 1(1)12 {

clear
gen year=0
cd "$dirpath/Intraday/Monthly"
save firm1_id_`y'_`m'.dta, replace
clear
cd "$dirpath/Intraday/Monthly/Sessions"
use firm1_id_`y'_`m'_1.dta 
qui forvalues p = 2(1)6 {
merge m:m month day hour unit using firm1_id_`y'_`m'_`p'.dta 
drop _merge
}
duplicates drop year month day hour unit, force
cd "$dirpath/Intraday/Monthly"
save firm1_id_`y'_`m'.dta, replace
}
}
