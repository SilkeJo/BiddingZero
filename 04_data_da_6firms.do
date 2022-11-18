*Create dataset with day-ahead bids of 6 particular firms with pbids > 0
clear
clear matrix
set type double
set more off
program drop _all
mat drop _all
global dirpath="C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\Data"

*Monthly data
forvalues y = 2017(1)2020 {
forvalues m = 1(1)12 {

clear
gen year=0
cd "$dirpath/Day-Ahead/Monthly"
save 6firms_`y'_`m'.dta, replace

forvalues d = 1(1)31 {
local file =  `y'*10000 + `m'*100 + `d'
local ordner = `y'*100 + `m'
cd "$dirpath/Day-Ahead/Rawdata/curva_pbc_uof_`ordner'"
*check if this day exists
capture confirm file `"curva_pbc_uof_`file'.1"'
di `file'

***Info on hourly unit-wise bids
qui if _rc == 0 {
**Hourly bids
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
	
*only solar bids of 6 firms in MIBEL and ES
drop if strpos(owner,"SHELL")== 0 & strpos(owner,"INIPEL")== 0 & /// 
strpos(owner,"GESTER")== 0 & strpos(owner,"GOIEN")== 0 & /// 
strpos(owner,"ALPIQ")== 0 & strpos(owner,"DLR")== 0

drop if plant_type!="Solar PV" & plant_type!="Solar" & plant_type!="Thermal Solar"
	
*Equilibrium price (maximum accepted bid)
	sort hour country 
	by hour country: egen mgprice = max(pbid) if accepted == 1 & type == "S"
	replace mgprice = 0 if mgprice == .
	by hour country: egen mg_price = max(mgprice)
	drop mgprice
	
*Clean repeated observations, take accepted bid (bid was sold/bought)
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
		
*Unit-wise supply and demand offered
	sort hour unit pbid mwh 
	by hour unit: egen q_total_supply_unit=total(mwh) if type=="S"
	gen supply_unit = mwh if type == "S" 
	replace supply_unit = 0 if supply_unit == .
	by hour unit: replace supply_unit = sum(supply_unit)
	
	gsort hour unit -pbid mwh
	by hour unit: egen q_total_demand_unit=total(mwh) if type=="D"
	gen demand_unit = mwh if type == "D" 
	replace demand_unit= 0 if demand_unit == .
	by hour unit: replace demand_unit = sum(demand_unit)
	gen net_supply_unit= supply_unit - demand_unit
	
*Unit-wise supply and demand offered and accepted
	sort hour unit pbid mwh 
	by hour unit: egen q_total_supply_unit_a=total(mwh) if type=="S"&accepted==1
	
	*gsort hour unit -pbid 
	*by hour unit: egen q_total_demand_unit_a=total(mwh) if type=="D"&accepted==1
	*gen net_supply_unit_a = supply_unit_a - demand_unit_a
	
*only maximum price bid and maximum accepted price bid 
*Clean missing data for quantity sold
bysort year month day hour unit: egen max=max(q_total_supply_unit_a)
replace q_total_supply_unit_a=max if missing(q_total_supply_unit_a)
replace q_total_supply_unit_a=0 if missing(q_total_supply_unit_a)
drop max

**generate maxmimum price bids and supplied quantity
bysort year month day hour unit: egen pbid_max=max(pbid) 
bysort year month day hour unit: egen supply_unit_max=max(supply_unit) 
bysort year month day hour unit: egen pbid_max_acc=max(pbid) if accepted==1
bysort year month day hour unit: egen pbid_max_a=max(pbid_max_acc) 
drop pbid_max_acc

*keep only one row per unit and hour with relevant variables 
gsort year month day hour unit -pbid
duplicates drop year month day hour unit, force
drop if missing(year) 
keep year month day hour unit owner name plant_type pbid_max pbid_max_a q_total_supply_unit_a supply_unit_max

keep year month day hour unit owner name plant_type pbid_max pbid_max_a /// 
  q_total_supply_unit_a supply_unit_max 
	
	compress
	cd "$dirpath/Day-Ahead/Monthly"
    append using 6firms_`y'_`m'.dta
	save 6firms_`y'_`m'.dta, replace
	
	sleep 10000
}
}
}
}

*Merge monthly bids
clear
gen year=0
cd "$dirpath/Final"
save 6firms.dta, replace

forvalues y = 2017(1)2020 {
forvalues m = 1(1)12 {
clear
cd "$dirpath/Day-Ahead/Monthly"
use 6firms_`y'_`m'.dta

drop if missing("name")

*add market prices
cd "$dirpath/Market-Data/Prepared"
merge m:1 year month day hour using prices.dta
drop if _merge==2
keep year month day hour unit owner name plant_type pbid_max pbid_max_a /// 
  q_total_supply_unit_a supply_unit_max mg_price_da2 mg_price_id2_1
 
cd "$dirpath/Final"
append using 6firms.dta, force
save 6firms.dta, replace
sleep 10000
}
}



