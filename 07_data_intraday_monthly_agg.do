*Create aggregated intraday market data
clear
clear matrix
set type double
set more off
program drop _all
mat drop _all
global dirpath="C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\Data"

forvalues p =1(1)6 {
forvalues y = 2020(1)2020 {

forvalues m = 11(1)11 {
clear
gen year = 0
cd "$dirpath/Intraday/Aggregated/Sessions"
save prepared_id_`y'_`m'_`p'.dta, replace
forvalues d = 1(1)31 {
local file =  `y'*1000000 + `m'*10000 + `d'*100  + `p'
local ordner = `y'*100 + `m'
cd "$dirpath/Intraday/Rawdata/curva_pibc_uof_`ordner'"
*check if this day exists 
capture confirm file `"curva_pibc_uof_`file'.1"'
di `file'
qui if _rc == 0 {
*import Omie bidding data
	clear
	insheet using curva_pibc_uof_`file'.1, delimiter(";")
*drop first 2 lines & missing data
	drop if _n < 3
capture assert _N == 0
qui if _rc > 0 {
	gen hour = real(v1)
	replace v2 = rtrim(v2)
	gen year = real(substr(v2,7,4))
	gen month = real(substr(v2,4,2))
	gen day = real(substr(v2,1,2))
	rename v3 country_id
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
*continue if not empty
	capture assert _N == 0
	qui if _rc > 0 {
		summ hour	
	if (r(max) ==  23) {
		expand 2 if hour == 23, generate(new)
		replace hour = 24 if new == 1
		drop new
	}

*Equilibrium price (maximum accepted bid)
	sort hour country_id
	by hour country_id: egen mgprice = max(pbid_id_`p') if accepted_id_`p' == 1 & 	 type_id_`p'== "S"
	replace mgprice = 0 if mgprice == .
	by hour country_id: egen mg_price_id_`p' = max(mgprice)
	drop mgprice
	
*Clean repeated observations, take accepted bid (bid was sold/bought)
	gsort unit hour pbid_id_`p' mwh_id_`p' -accepted_id_`p' 
	duplicates drop unit hour pbid_id_`p' mwh_id_`p', force
	*Generate variable "rejected" that indicates if any bid of a certain unit 
	*in one hour is not accepted although bid is below/above EQ price (for S/D)
	gen rejected_temp = 0
	replace rejected_temp = 1 if pbid_id_`p' < mg_price_id_`p' /// 
	& type_id_`p' == "S" & accepted_id_`p' == 0
	replace rejected_temp = 1 if pbid_id_`p' > mg_price_id_`p' /// 
	& type_id_`p' == "D" & accepted_id_`p' == 0
	sort unit hour pbid_id_`p'
	by unit: egen rejected_id_`p' = max(rejected_temp)
	replace rejected_id_`p' = 0 if accepted_id_`p' == 1
	drop rejected_temp
	

*aggregate supply and demand accepted
gsort hour pbid_id_`p' mwh_id_`p' -type_id_`p'
by hour: gen supply_a_id_`p' = sum(mwh_id_`p') if  accepted_id_`p' == 1 & type_id_`p'=="S"
by hour: replace supply_a_id_`p' = supply_a_id_`p'[_n-1] if supply_a_id_`p' == .
*gsort hour -pbid_id_`p' -mwh_id_`p' type_id_`p'
*by hour: gen demand_a_id_`p' = sum(mwh_id_`p') if accepted_id_`p' == 1  & type_id_`p'=="D"
*by hour: replace demand_a_id_`p' = demand_a_id_`p'[_n-1] if demand_a_id_`p' == .

*graph twoway (line pbid_id supply_id) (line pbid_id demand_id) if hour==12
*equilibrium quantity
	sort hour country_id pbid_id_`p'
	by hour country_id: gen mgq_id = supply_a_id_`p' if pbid_id_`p'==mg_price_id_`p' 
	replace mgq_id = 0 if mgq_id==.
	by hour country_id: egen mg_quantity_id_`p' = max(mgq_id)
	drop mgq*
	
duplicates drop hour, force

drop if year!=`y'

keep country_id year month day hour mg_price_id_`p' mg_quantity_id_`p' 

	cd "$dirpath/Intraday/Aggregated/Sessions"
	append using prepared_id_`y'_`m'_`p'.dta 
	save prepared_id_`y'_`m'_`p'.dta, replace
}
}
}	
}
}
}
}


**merge monthly sessions 
forvalues y = 2017(1)2020 {
forvalues m = 1(1)12 {

clear
gen year=0
cd "$dirpath/Intraday/Aggregated"
save prepared_id_`y'_`m'.dta, replace

cd "$dirpath/Intraday/Aggregated/Sessions"
use prepared_id_`y'_`m'_1.dta 
qui forvalues p = 2(1)6 {
merge m:m year month day hour country_id using prepared_id_`y'_`m'_`p'.dta 
drop _merge
}

*put MI and ES quantities in one row if double row per hour
forvalues x=1(1)6 {
	bysort year month day hour: egen temp=max(mg_price_id_`x')
	bysort year month day hour: egen temp2=max(mg_quantity_id_`x')
	bysort year month day hour: replace mg_price_id_`x'=temp
	bysort year month day hour: replace mg_quantity_id_`x'=temp2
	drop temp*
}
duplicates drop year month day hour, force


cd "$dirpath/Intraday/Aggregated"
save prepared_id_`y'_`m'.dta, replace
}
}


