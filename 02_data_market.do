*****Overall market data
clear all

****Generation forecast 
clear
gen year=0
cd "$dirpath/Market-Data/Prepared"
save regen_forecast.dta, replace

forvalues y=2017(1)2020 {
clear
cd "$dirpath/Market-Data"
import excel ForecastsWindSolar`y'.xlsx
drop if A==""
gen A2=substr(A,1,2)
gen hour=real(A2)+1
gen date=A if missing(B)
*manually correct time change in March
replace date="." if date=="02:00 - 03:00"
gen day2=substr(date,1,2)
gen day=real(day2)
gen month2=substr(date,4,2)
gen month=real(month2)
replace day=day[_n-1] if day==.
replace month=month[_n-1] if month==.
replace day=1 if day==.
replace month=1 if month==.
gen year=`y'
drop if missing(B)
gen solar_fc_DA=real(B)
gen solar_fc_ID=real(C)
gen solar_fc_C=real(D)
gen wind_fc_DA=real(H)
gen wind_fc_ID=real(I)
gen wind_fc_C=real(J)

local time DA ID C
local tech solar wind

foreach x of local time {
	foreach y of local tech {
	label var `y'_fc_`x' "MW"
	}
}
*manually correct time change in March
duplicates drop year month day hour, force
if year==2017 {
expand 2 if day==26&month==3&hour==2, gen(exp)
}
if year==2018 {
expand 2 if day==25&month==3&hour==2, gen(exp2)
}
if year==2019 {
expand 2 if day==31&month==3&hour==2, gen(exp)
}
if year==2020 {
expand 2 if day==29&month==3&hour==2, gen(exp)
}
replace hour=3 if exp==1
drop day2 month2 A A2 B C D E F G H I J date exp
sort year month day hour
cd "$dirpath/Market-Data/Prepared"
append using regen_forecast.dta
save regen_forecast.dta, replace
}

****Actual generation 
clear
gen year=0
cd "C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\Review\Data\Market-Data\Prepared"
save actual_gen.dta, replace

forvalues y=2017(1)2022 {
clear
cd "$dirpath/Market-Data"
import excel Generation`y'.xlsx
drop if A==""
gen A2=substr(A,1,2)
gen hour=real(A2)+1
gen date=A if missing(B)
*manually correct time change in March
replace date="." if date=="02:00 - 03:00"
gen day2=substr(date,1,2)
gen day=real(day2)
gen month2=substr(date,4,2)
gen month=real(month2)
replace day=day[_n-1] if day==.
replace month=month[_n-1] if month==.
replace day=1 if day==.
replace month=1 if month==.
drop if missing(B)
gen year=`y'
	
gen biomass=real(B)
gen lignite=real(C)
gen coal_gas=real(D)
gen gas=real(E)
gen hardcoal=real(F)
gen oil=real(G)
gen peat=real(I)
gen pumpedhydro=real(L)
gen geothermal=real(J)
gen runofriver=real(M)
gen reservoir=real(N)
gen marine=real(O)
gen nuclear=real(P)
gen other=real(Q)
gen other_re=real(R)
gen solar=real(S)
gen waste=real(T)
gen wind=real(V)
egen thermal_gen=rowtotal(biomass lignite coal gas hardcoal oil peat nuclear)
egen other_gen=rowtotal(geothermal runofriver reservoir marine other_re other waste)
egen re_gen=rowtotal(solar wind)
egen gen=rowtotal(thermal_gen other_gen re_gen)

label var thermal_gen "biomass lignite coal gas hardcoal oil peat nuclear MW"
label var other_gen "geothermal runofriver reservoir marine other_re other waste MW"
label var re_gen "solar wind MW"
label var gen "total gen MW"

duplicates drop year month day hour, force
if year==2017 {
expand 2 if day==26&month==3&hour==2, gen(exp)
}
if year==2018 {
expand 2 if day==25&month==3&hour==2, gen(exp2)
}
if year==2019 {
expand 2 if day==31&month==3&hour==2, gen(exp)
}
if year==2020 {
expand 2 if day==29&month==3&hour==2, gen(exp)
}
if year==2021 {
expand 2 if day==28&month==3&hour==2, gen(exp)
}
if year==2022 {
expand 2 if day==27&month==3&hour==2, gen(exp)
}
replace hour=3 if exp==1
drop day2 month2 A A2 B-V date exp*
sort year month day hour
cd "C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\Review\Data\Market-Data\Prepared"
append using actual_gen.dta
drop if missing(hour)
*handling missing data 
foreach genvar in biomass lignite coal gas hardcoal oil peat nuclear pumpedhydro geothermal runofriver reservoir marine other_re other waste solar wind {
 replace `genvar'=`genvar'[_n-1] if `genvar'==.
}
}
save actual_gen.dta, replace

****Load 
clear
gen year=0
cd "$dirpath/Market-Data/Prepared"
save load.dta, replace

forvalues y=2017(1)2022 {
clear
cd "$dirpath/Market-Data"
import excel Load`y'.xlsx
drop if A==""
gen A2=substr(A,1,2)
gen hour=real(A2)+1
gen date=A if missing(B)
*manually correct time change in march
replace date="." if date=="02:00 - 03:00"
gen day2=substr(date,1,2)
gen day=real(day2)
gen month2=substr(date,4,2)
gen month=real(month2)
replace day=day[_n-1] if day==.
replace month=month[_n-1] if month==.
replace day=1 if day==.
replace month=1 if month==.
drop if missing(B)
gen year=`y'
gen load_fc_DA=real(B)
gen load_ACT=real(C)

label var load_fc_DA "Day-Ahead Load Forecast (MW)"
label var load_ACT "Actual Load (MW)"

duplicates drop year month day hour, force
if year==2017 {
expand 2 if day==26&month==3&hour==2, gen(exp)
}
if year==2018 {
expand 2 if day==25&month==3&hour==2, gen(exp2)
}
if year==2019 {
expand 2 if day==31&month==3&hour==2, gen(exp)
}
if year==2020 {
expand 2 if day==29&month==3&hour==2, gen(exp)
}
if year==2021 {
expand 2 if day==28&month==3&hour==2, gen(exp)
}
if year==2022 {
expand 2 if day==27&month==3&hour==2, gen(exp)
}
replace hour=3 if exp==1
drop day2 month2 A A2 B C date exp*
sort year month day hour
cd "$dirpath/Market-Data/Prepared"
append using load.dta
save load.dta, replace
}
*handling missing data 
sort year month day hour 
replace load_ACT=load_ACT[_n-1] if load_ACT==.
duplicates drop year month day hour, force
save load.dta, replace


****Prices 
*EUA Spot Prices 
clear
cd "$dirpath/Market-Data"
import excel EUA_update.xlsx
gen date=date(A,"MDY")
gen year=year(date)
gen month=month(date)
gen day=day(date)
gen co2price=real(B)
replace co2price=co2price[_n-1] if missing(co2price)
drop A B date
drop if year<2016
cd "$dirpath/Market-Data/Prepared"
drop C-JJ
save co2prices.dta, replace

*Gas prices 
clear
gen year=0
cd "$dirpath/Market-Data/Prepared"
save gasprices.dta, replace

forvalues y=2017(1)2022 {
clear
cd "$dirpath/Market-Data"
import excel MIBGAS_Data_`y'.xlsx
gen date=date(A,"MDY")
gen year=year(date)
gen month=month(date)
gen day=day(date)
gen gasprice=real(C)
keep year month day gasprice 
drop if missing(year)
cd "$dirpath/Market-Data/Prepared"
append using gasprices.dta
save gasprices.dta, replace
}

*Day-Ahead Market Prices
clear
gen year=0
cd "$dirpath/Market-Data/Prepared"
save prices_da.dta, replace

forvalues y=2017(1)2022{
forvalues m=1(1)12{
forvalues d = 1(1)31 {
local file =  `y'*10000 + `m'*100 + `d'
cd "$dirpath/Market-Data/Rawdata/marginalpdbc_`y'"
*check if this day exists
capture confirm file `"marginalpdbc_`file'.1"'
di `file'
qui if _rc == 0 {
	clear
	insheet using marginalpdbc_`file'.1, delimiter(";")
	drop if _n < 2
	rename v4 hour 
	rename v3 day 
	rename v2 month 	
	gen year = real(v1)
	rename v5 mg_price_da
	rename v6 mg_price_da2
	drop v* 
	cd "$dirpath/Market-Data/Prepared"
	append using prices_da.dta
	save prices_da.dta, replace
}
}
}
}
drop if missing(hour)
gen diff=mg_price_da-mg_price_da2
sum diff, det
drop diff
save prices_da.dta, replace

*Intraday Market Prices (6 Sessions)
clear
gen year=0
cd "$dirpath/Market-Data/Prepared"
forvalues p=1(1)6{
save prices_id_`p'.dta, replace
}
forvalues p=1(1)6{
forvalues y=2017(1)2020{
forvalues m=1(1)12{
forvalues d = 1(1)31 {
local file =  `y'*1000000 + `m'*10000 + `d'*100+`p'
cd "$dirpath/Market-Data/Rawdata/marginalpibc_`y'"
*check if this data for this day exists
capture confirm file `"marginalpibc_`file'.1"'
di `file'
qui if _rc == 0 {
	clear
	insheet using marginalpibc_`file'.1, delimiter(";")
	capture confirm var v4
	qui if _rc==0 {
	drop if _n < 2
	rename v4 hour 
	rename v3 day 
	rename v2 month 	
	gen year = real(v1)
	rename v5 mg_price_id1_`p'
	rename v6 mg_price_id2_`p'
	drop v* 
	cd "$dirpath/Market-Data/Prepared"
	drop if missing(hour)
	append using prices_id_`p'.dta
	save prices_id_`p'.dta, replace
}
}
}
}
}
}

forvalues p=1(1)6{
	cd "$dirpath/Market-Data/Prepared"
	clear 
	use prices_id_`p'.dta
	duplicates drop year month day hour, force
	save prices_id_`p'.dta, replace 
}

clear 
use prices_id_1.dta
forvalues p=2(1)6{
	merge 1:1 year month day hour using prices_id_`p'.dta
	drop _merge
}
save prices_id.dta,replace

****Merge monthly equilibrium market data
cd "$dirpath/Market-Data/Prepared"
clear
gen year=0
save eq_data.dta, replace
forvalues y = 2017(1)2022 {
forvalues m = 1(1)12 {
clear
cd "$dirpath/Day-Ahead/Prepared"
use prepared_`y'_`m'.dta
keep country year month day hour mg_price mg_quantity 
duplicates drop year month day hour country, force 
rename country country_id
cd "$dirpath/Intraday/Aggregated"
merge 1:1 year month day hour country_id using prepared_id_`y'_`m'.dta
gsort year month day hour -mg_price
forvalues p = 1(1)6{
	by year month day hour: replace mg_price_id_`p'=mg_price_id_`p'[_n+1] if missing(mg_price_id_`p')
		by year month day hour: replace mg_quantity_id_`p'=mg_quantity_id_`p'[_n+1] if missing(mg_quantity_id_`p')
}
drop if _merge==2
drop _merge
drop if missing(year) 
cd "$dirpath/Market-Data/Prepared"
append using eq_data.dta, force
save eq_data.dta, replace
}
}

*Merge DA and ID Prices
clear
cd "$dirpath/Market-Data/Prepared"
gen year=0
save prices.dta, replace
cd "$dirpath/Market-Data/Prepared"
use prices_da.dta
duplicates drop year month day hour, force
merge 1:1 year month day hour using prices_id.dta
drop _merge
save prices.dta, replace

*Account for time change
expand 2 if day==26&month==3&hour==2&year==2017, gen(exp)
expand 2 if day==25&month==3&hour==2&year==2018, gen(exp2)
expand 2 if day==31&month==3&hour==2&year==2019, gen(exp3)
expand 2 if day==29&month==3&hour==2&year==2020, gen(exp4)
if year==2021 {
expand 2 if day==28&month==3&hour==2, gen(exp5)
}
if year==2022 {
expand 2 if day==27&month==3&hour==2, gen(exp6)
}
replace hour=3 if exp==1 | exp2==1 | exp3==1 | exp4==1 |exp5==1 | exp6==1
duplicates tag year month day hour, gen(dup)

drop if exp==1&dup==1
drop if exp2==1&dup==1
drop if exp3==1&dup==1
drop if exp4==1&dup==1
drop if exp5==1&dup==1
drop if exp6==1&dup==1

drop exp* dup
save marketprices.dta, replace

*Merge with commodity prices
merge m:1 year month day using co2prices.dta
drop if _merge==2
drop _merge
merge m:1 year month day using gasprices.dta
drop if _merge==2
drop _merge

*Merge with equilibrium data
cd "$dirpath/Market-Data/Prepared"
merge 1:1 year month day hour using eq_data.dta
drop if _merge<3
drop _merge
cd "$dirpath/Market-Data/Prepared"
gen diff=mg_price-mg_price_da
drop if diff>90 | diff<-30
drop mg_price diff
egen mg_price_id_max=rmax(mg_price_id2*)
egen mg_price_id_max2=rmax(mg_price_id_*)
gen diff=mg_price_id_max-mg_price_id_max2
drop if diff<-20
drop diff mg_price_id1* mg_price_id_*
save prices.dta, replace

**Merge all 
clear
cd "$dirpath/Market-Data/Prepared"
use actual_gen.dta 

merge 1:1 year month day hour using load.dta 
drop if _merge==2
drop _merge
merge 1:1 year month day hour using regen_forecast.dta 
drop if _merge==2
drop _merge
merge 1:1 year month day hour using eq_data.dta 
drop if _merge==2
drop _merge
merge 1:1 year month day hour using prices.dta 
drop if _merge==2
drop _merge
gen coal=hardcoal+lignite+coal_gas
gen hydro=runofriver+reservoir
replace gen=gen-pumpedhydro

**Control yearly sums and shares
*collapse (mean) mg_price_da mg_price_id1* ///
*(sum) coal gas biomass oil hydro pumpedhydro nuclear /// 
*other other_re solar waste wind gen load_ACT, by(year)

*foreach var in coal gas oil nuclear biomass hydro waste solar wind other other_re {	
*	gen share_`var'=`var'/gen
*}

**Time variables
gen date=mdy(month, day, year)
format date %td

gen week=wofd(date)
format week %tw

gen Month=mofd(date)
format month %tm

cd "$dirpath/Final"
save allmarketdata.dta, replace







