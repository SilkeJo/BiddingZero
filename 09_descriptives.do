clear
set more off
global dirpath="C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\Do-Files_new\for submission\Data"

****Figures and Tables
**solar_pbids.dta cannot be uploaded because it is too large
*clear
*cd "$dirpath/Final"
*use solar_pbids.dta

*Figure 2: Histogram of all solar price bids
*set scheme s1mono
*hist pbid, xtitle("Price bids (€/MWh)", size(medium)) ytitle("Density (%)", size(medium)) percent graphregion(fcolor(white)) lcolor(nsvy) fcolor(ebblue) xsize(4) width(5) lwidth(0.1) xlabel(,labsize(small)) ylabel(,labsize(small)) ysc(titlegap(*3)) xsc(titlegap(*3))
*cd "$dirpath/Final/Graphs"
*graph export "02_Histogram_PriceBids_Solar.png", replace
*graph close

*Figure 3: price bids of preselected firms
clear
cd "$dirpath/Final"
use 6firms.dta
*drop 6th firms because of large gap of observations 
replace owner="Firm #1" if strpos(owner,"INIPEL")
replace owner="Firm #2" if strpos(owner,"DLR")
replace owner="Firm #3" if strpos(owner,"GOIENER")
replace owner="Firm #4" if strpos(owner,"GESTER")
replace owner="Firm #5" if strpos(owner,"SHELL") 
replace owner="others" if owner!="Firm #1" & owner!="Firm #2" & owner!="Firm #3" & ///
owner!="Firm #4" & owner!="Firm #5" 
drop if owner=="others" 
set scheme s1mono
twoway scatter pbid_max pbid_max_a, by(owner) msize(small) mcolor(navy) ///
graphregion(color(white)) ///
|| scatter mg_price_id2_1 pbid_max_a, by(owner) msize(tiny) mcolor(eltblue) ///
ytitle(€/MWh, size(medsmall)) xtitle(Maximum accepted day-ahead market price bid /// 
(€/MWh), size(medsmall)) graphregion(color(white)) ///
legend(label (1 "Maximum day-ahead market price bid (€/MWh)") /// 
label(2 "Intraday market price session 1 (€/MWh)") rows(2)) ///
 ysc(titlegap(*4)) xsc(titlegap(*4))
cd "$dirpath/Final/Graphs"
graph export "03_Price_Bids_5firms.png", replace
graph close


*Figure 4: weekly market data
clear 
cd "$dirpath/Final"
use allmarketdata.dta, replace
drop if year>2020
collapse (mean) mg_price_da2 mg_price_id2* mg_quant* ///
(sum) coal gas biomass oil hydro pumpedhydro nuclear /// 
other other_re solar waste wind gen load_ACT, by(week)

rename coal Coal
gen Gas = Coal + gas
gen Oil = Gas + oil
gen Nuclear = Oil + nuclear
gen Biomass = Nuclear + biomass
gen Other = Biomass + other
gen Other_RE = Other + other_re
gen Hydro = Other_RE + hydro
gen Waste = Hydro + waste
gen Solar = Waste + solar
gen Wind = Solar + wind
foreach var in Coal Gas Oil Nuclear Biomass Hydro Waste Solar Wind Other Other_RE {
	replace `var'=`var'/1000
}
set scheme s1mono
twoway bar Coal week, bcolor(black) || ///
rbar Coal Gas week, bcolor(sienna) || ///
rbar Gas Oil week, bcolor(brown) || ///
rbar Oil Nuclear week, bcolor(gray) || /// 
rbar Nuclear Biomass week, bcolor(midgreen) || ///
rbar Biomass Other week, bcolor(teal) || /// 
rbar Other Other_RE week, bcolor(dkgreen) || /// 
rbar Other_RE Hydro week, bcolor(navy) || /// 
rbar Hydro Waste week, bcolor(olive_teal) || /// 
rbar Waste Solar week, bcolor(yellow) || /// 
rbar Solar Wind week, bcolor(ltblue) || /// 
line mg_price_da week, yaxis(2) lcolor(red) lpattern(dash dot) || /// 
line mg_price_id2_1 week, yaxis(2) lcolor(orange) lpattern(dash dot) ///
legend(rows(3) size(small) symxsize(*0.3) label(1 "Coal") label(2 "Gas") ///
label(3 "Oil") label(4 "Nuclear") label(5 "Biomass") /// 
label(6 "Other") label(7 "Other_RE") ///
label(8 "Hydro") label(9 "Waste") ///
label(10 "Solar") label(11 "Wind") ///
label(12 "Mean DA Price") label(13 "Mean ID Price")) ///
ytitle("Total weekly generation (GWh)", size(small)) ///
ylabel(,labsize(small)) ysc(titlegap(4) r(0 10000)) ///
ytitle("Average weekly price (€/MWh)", size(small) axis(2)) ///
ylabel(,labsize(small) axis(2)) ysc(titlegap(2) axis(2)) ///
xtitle("Week", size(small)) tlabel(2017w1(26)2020w52,labsize(small) format(%tw)) 
cd "$dirpath/Final/Graphs"
graph export 04_WeeklyMarketData.png, replace
graph close

*Figure 5: intraday market data
clear 
cd "$dirpath/Final"
use allmarketdata.dta

gen weekd=dow( mdy( month, day, year) )
gen weekend = 1 if weekd == 6 | weekd == 0
replace weekend = 0 if weekend == .
gen weekdays = 0
replace weekdays = 1 if weekend == 1

egen q_total_mg_id=rowtotal(mg_quantity_id*)
egen mg_price_id_max=rowmax(mg_price_id2*)

drop mg_price_id_max
egen mg_price_id_max=rmax(mg_price_id2*)
gen diff_p_id_da=mg_price_id_max-mg_price_da

gen weekend2="Weekday" 
replace weekend2="Weekend" if weekend==1

collapse (mean) diff_p_id_da mg_quant*, by(hour weekend2)

 gen mg_quantity_id2=mg_quantity_id_1+mg_quantity_id_2
 gen mg_quantity_id3=mg_quantity_id2+mg_quantity_id_3
 gen mg_quantity_id4=mg_quantity_id3+mg_quantity_id_4
 gen mg_quantity_id5=mg_quantity_id4+mg_quantity_id_5
 gen mg_quantity_id6=mg_quantity_id5+mg_quantity_id_6

set scheme s1mono
graph twoway || bar mg_quantity_id_1 hour, by(weekend2, note("")) barw(0.5) color(eltblue) ///
|| rbar mg_quantity_id_1 mg_quantity_id2 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(ebblue) ///
|| rbar mg_quantity_id2 mg_quantity_id3 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(navy) ///
|| rbar mg_quantity_id3 mg_quantity_id4 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(sienna) ///
|| rbar mg_quantity_id4 mg_quantity_id5 hour, by(weekend2, note("")) barw(0.5) barw(0.5)  color(orange) ///
|| rbar mg_quantity_id5 mg_quantity_id6 hour, by(weekend2, note("")) barw(0.5) barw(0.5) color(orange_red) ///
|| line diff_p_id_da hour, yaxis(2) lcolor(black) lwidth(medthick) ytitle("Average Price Difference (€/MWh)", /// 
size(small) axis(2)) ylabel(,labsize(small) axis(2)) ///
 ysc(titlegap(3) axis(2)) /// 
ytitle("Average Volume (MWh)", axis(1) size(small)) ///
ytitle("Average Price Difference (€/MWh)", axis(2) size(small)) ///
ylabel(,labsize(small)) ysc(titlegap(3) axis(1) r(0 6000)) /// 
legend(rows(2) size(small) symxsize(*0.12) label(1 "Intraday Session 1") /// 
label(2 "Intraday Session 2") label(3 "Intraday Session 3") /// 
label(4 "Intraday Session 4") label(5 "Intraday Session 5") /// 
label(6 "Intraday Session 6") label(7 "Price Difference ID / DA")) ///
xtitle("Hour", size(small)) xlabel(1(1)24,labsize(vsmall)) 
cd "$dirpath/Final/Graphs"
graph export 05_HourlyMarketData.png, replace
graph close

*Tables 1 and 2
clear
cd "$dirpath/Final"
use regressions.dta

sum diff_p_id_da q_total_mg_id load_ACT solar_share wind_share hydro_share gas_share coal_share oil_share other_share co2price gasprice solar_fc_error wind_fc_error load_fc_error $dummies
drop if pbid_max==0
sum pbid_max load_ACT solar_share wind_share hydro_share gas_share coal_share oil_share other_share co2price gasprice solar_fc_error wind_fc_error load_fc_error $dummies

*Figure 6 and 7
bysort year month day hour owner: egen q_total_supply_unit_a_all=total(q_total_supply_unit_a)
bysort year month day hour owner: egen q_total_supply_unit_id_all=total(q_total_supply_unit_id) 
set scheme s1mono
scatter q_total_supply_unit_id_all q_total_supply_unit_a_all if pbid_max_a>0, msize(tiny)  ///
xtitle("Energy sold day ahead (MWh)", size(medium)) mcolor(navy) ytitle("Energy sold intraday (MWh)", size(medium)) graphregion(fcolor(white)) xlabel(,labsize(small)) ylabel(,labsize(small)) ysc(titlegap(*4)) xsc(titlegap(*4))
cd "$dirpath/Final/Graphs"
graph export "06_ID_quantities.png", replace
graph close
egen pbid_id_min=rmin(pbid_id_1_S_max pbid_id_2_S_max pbid_id_3_S_max pbid_id_4_S_max pbid_id_5_S_max pbid_id_6_S_max)
scatter pbid_max pbid_id_min, msize(tiny) ///
xtitle("Max Price Bid Day-Ahead(€/MWh)", size(medium)) mcolor(navy) ytitle("Min accepted price bid Intraday 1-6 (€/MWh)", size(medium)) graphregion(fcolor(white)) xlabel(,labsize(small)) ylabel(,labsize(small)) ysc(titlegap(*4)) xsc(titlegap(*4))
cd "$dirpath/Final/Graphs"
graph export "07_ID_pricebids.png", replace
graph close


