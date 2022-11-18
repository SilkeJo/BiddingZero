*Unit Data
clear all
global dirpath="C:\Users\JOHANNS\EnBW AG\C-UE C-UM - Dokumente\Team\Silke\Stata\Spain\Data"

**additional info
cd "$dirpath\Units"
clear
import excel unitlocation.xlsx
rename A unit
rename C municname
rename E provname
rename D regionname
gen size2=real(B)
drop if _n==1
drop B
duplicates drop unit, force
**correct 
replace regionname="Castilla-La Mancha" if regionname=="Castilla La Mancha"
replace regionname="Castilla y León" if regionname=="Castilla-León"
save unitlocation.dta, replace

***OMIE Data (less information)
clear
import excel units_OMIE.xls
rename A unit
rename B name
rename C owner
generate ownership = real(D)
drop D
rename E plant_type
rename F state
rename G country
drop if unit=="CODIGO"
save units_omie.dta, replace

***REE Data (more information)
clear
import excel units_REE.xlsx
rename A unit
rename B code_EIF
rename C name
rename D mw2
rename E plant_type
rename F vin_SM
rename G vin_UP
drop if unit=="vinculacion_UP"
sort unit
duplicates tag unit, gen(dup)
gen mw = real(mw)
drop mw2 dup
drop if unit=="CÃ³digo de UF"
save units_ree.dta, replace

***Add OMIE Units and join info when possible
append using units_omie.dta
gsort unit -mw
duplicates tag unit, gen(dup)
by unit, sort: gen nvals = _n == 1
by unit: replace owner=owner[_n+1] if dup==1&nvals==1&ownership==.
by unit: replace state=state[_n+1] if dup==1&nvals==1&ownership==.
by unit: replace ownership=ownership[_n+1] if dup==1&nvals==1&ownership==.
by unit: replace country=country[_n+1] if dup==1&nvals==1&ownership==.
duplicates drop unit owner, force
drop dup nvals
save unitdata.dta, replace
*half is REE data, half is OMIE data

***Rename plant_type and extract information from plant names or owners
replace plant_type="Renewable" if strpos(name, "RENOVABLE")
replace plant_type="Thermal Solar" if plant_type=="Solar tÃ©rmica"
replace plant_type="Thermal Solar" if strpos(name,"SOLNOVA")
replace plant_type="Solar PV" if strpos(name, "FOTO")
replace plant_type="Solar PV" if strpos(name, "FV")
replace plant_type="Solar PV" if strpos(name, "PV")
replace plant_type="Solar PV" if plant_type=="Solar fotovoltaica"
replace plant_type="Solar" if strpos(name, "SOLAR")
replace plant_type="Thermal Solar" if strpos(name, "TERMOSOLAR")
replace plant_type="Wind Onshore" if plant_type=="EÃ³lica terrestre"
replace plant_type="Wind Onshore" if strpos(name,"EOLICO")
replace plant_type="Wind Onshore" if strpos(name,"EÓLICO")
replace plant_type="Wind Onshore" if strpos(name,"EÓLICA")
replace plant_type="Wind Onshore" if strpos(name,"EOLICA")
replace plant_type="Wind Onshore" if strpos(name,"WIND")
replace plant_type="Wind Onshore" if strpos(name,"EOL.")
replace plant_type="Wind Onshore" if strpos(owner, "WIND TO MARKET")
replace plant_type="Solar" if strpos(owner, "SOLAR")

*rename plant_types from Spanish to English 
replace plant_type="Cogeneration Gas" if plant_type=="Gas Natural CogeneraciÃ³n"
replace plant_type="Oil/Coal Derivates" if /// 
plant_type=="Derivados del petrÃ³leo Ã³ carbÃ³n"
replace plant_type="Oil/Coal Derivates" if /// 
strpos(name,"DERIV PETROLEO")
replace plant_type="Hydro" if plant_type=="HidrÃ¡ulica UGH"
replace plant_type="Hydro" if plant_type=="HidrÃ¡ulica no UGH"
replace plant_type="Hydro" if strpos(name, "HIDRÁULICA")
replace plant_type="Hydro" if strpos(name, "HIDRAULICA")
replace plant_type="Hydro" if strpos(name, "HIDRA")
replace plant_type="Hydro" if strpos(name, "UGH")
replace plant_type="Thermal" if strpos(name, "TÉRMICA")
replace plant_type="Thermal" if strpos(name, "TERMICA")
replace plant_type="Coal" if plant_type=="Hulla antracita"
replace plant_type="Coal" if plant_type=="Hulla sub-bituminosa"
replace plant_type="CCGT" if plant_type=="Ciclo Combinado"
replace plant_type="CHP" if strpos(name,"COGENERACION")
replace plant_type="Hydro" if plant_type=="TurbinaciÃ³n bombeo"
replace plant_type="Hydro Consumption" if plant_type=="Consumo bombeo"
replace plant_type="Biomass" if plant_type=="Biomasa"
replace plant_type="Biogas" if strpos(name, "BIOMASA")
replace plant_type="Biogas" if plant_type=="BiogÃ¡s"
replace plant_type="Biogas" if plant_type=="BiogÃ¡s"
replace plant_type="Biogas" if strpos(name, "BIOGAS")
replace plant_type="Residual Energy" if plant_type=="EnergÃ­a residual"
replace plant_type="Residual Energy" if strpos(name, "RESIDUOS")
replace plant_type="Residual Energy" if plant_type=="EnergÃ­a residual"
replace plant_type="Oceanic and geothermal" if plant_type=="Oceano y geotÃ©rmica"
replace plant_type="Waste" if plant_type=="Residuos varios"
replace plant_type="Waste" if plant_type=="Residuos domÃ©sticos y similares"
replace plant_type="Oil" if plant_type=="Fuel"
replace plant_type="Mining Subproducts" if plant_type=="Subproductos minerÃ­a"
replace plant_type="Imports France" if plant_type=="ImportaciÃ³n Francia"
replace plant_type="Imports Andorra" if plant_type=="ImportaciÃ³n Andorra"
replace plant_type="Imports Morocco" if plant_type=="ImportaciÃ³n Marruecos"
replace plant_type="Balearic Link" if plant_type=="Enlace Baleares"
replace plant_type="Export" if plant_type=="CONTRATO INTERNACIONAL"
replace plant_type="Marketer" if plant_type=="Comercializadores mercado libre"
replace plant_type="Marketer" if plant_type=="COMERCIALIZADOR"
replace plant_type="Direct Consumption" if plant_type=="Consumos directos en mercado"
replace plant_type="Direct Consumption" if plant_type=="CONSUMIDOR DIRECTO"
replace plant_type="Consumption Auxiliary Services" if plant_type=="Consumo de Servicios Auxiliares"
replace plant_type="Balearic Link" if plant_type=="Enlace Baleares"
replace plant_type="Marketer Services of Last Resort" if plant_type=="Comercializadores Ãºltimo recurso"
replace plant_type="Marketer Services of Last Resort" if plant_type=="COMERCIALIZADOR ULTIMO RECURSO"
replace plant_type="Forwarded units" if plant_type=="GENERICA"
replace plant_type="Self-Consumer" if plant_type=="AUTOPRODUCTORES"

*owner is replaced by UP because it represents the aggregation of physical units by technology and BRP
*replace owner = vin_UP if missing(owner)
*egen firm_code = group(owner) if plant_type=="Solar PV" | plant_type=="Solar" | plant_type=="Wind Onshore" | *plant_type=="Thermal Solar" 

*sort owner firm_code 
*bysort owner: replace firm_code=firm_code[_n-1] if missing(firm_code)
*owner is replaced by vin_SM (sujeto del mercado) if missing
replace owner = vin_SM if missing(owner)

*manual correction if owner is written in two different versions
replace owner="BIEFFE MEDITAL" if owner=="TEC 94 - BIEFFE MEDITAL"
replace owner="ENERGIAS VILLA DEL CAMPO" if owner=="ENERGIAS DE LA VILLA DE CAMPO COMERCIALIZADORA SLU"
replace owner="ELECTRA ALTO MIÑO COMPRA (ESP)" if strpos(owner,"ELECTRA ALTO")
replace owner="ELECTRICA DEL EBRO" if owner=="ENERGIA ELECTRICA DEL EBRO COM."
replace owner="ELECTRA ADURIZ SA" if owner=="ELECTRA ADURIZ  SA"
replace owner="ETER ENERGIA" if owner=="ETERE"
replace owner="ESTABANELL Y PAHISA MERCATOR" if owner=="ESTEBANELL Y PAHISA ENERGIA"
replace owner="MONTEFIBRE HISPANIA" if owner=="MONTEFIBRE HISPANIA (GENFIBRE)"
replace owner="HIDROELÉCTRICA DE SILLEDA, S.L." if owner=="HIDROELECTRICA DE SILLEDA COMERCIALIZADORA, S.L."
replace owner="SNIACE S.A" if owner=="SNIACE ,S.A." | owner=="SNIACE ENERGIA"
replace owner="LUZBOA-COMERCIALIZAÇAO DE ENERGIA LDA" if owner=="LUZBOA - COMERCIALIZAÇÃO DE ENERGIA LDA"
replace owner="TALARN ENERGIA ELECTRICA S.L.U" if owner=="TALARN DISTRIBUCIO MUNICIPAL ELECTRICA"
replace owner="SOCIE MUNICIPAL DE DISTRIBUCIO ELECTRICA DE TIRVIA" /// 
if owner=="SOCIETAT MUNICIPAL DE COMERCIALITZACIO ELECTRICA DE TIRVIA, S.L."
replace owner="GESTINER INGENIEROS, S.L." if owner=="GESTINER INGENIEROS, SL"
replace owner="ENDESA" if strpos(owner,"ENDESA")
replace owner="UNION FENOSA" if strpos(owner,"UNION FENOSA")
replace owner="IBERDROLA" if strpos(owner,"IBERDROLA")
replace owner="RESPIRA ENERGIA" if strpos(owner, "RESPIRA ENERGIA")
replace owner="AUDAX" if strpos(owner, "AUDAX")
replace owner="WIND TO MARKET" if strpos(owner, "WIND TO MARKET")
replace owner="SHELL" if strpos(owner, "SHELL")


save unitdata.dta, replace

**account for mututal ownership by creating four different lists to be merged with curvas
sort unit
duplicates drop unit, force
save unitdata1, replace
clear
use unitdata.dta
merge m:1 unit owner using unitdata1.dta
drop if _merge!=1
duplicates drop unit, force
drop _merge
save unitdata2.dta, replace
clear
use unitdata.dta
merge m:1 unit owner using unitdata1.dta
drop if _merge!=1
drop _merge
merge m:1 unit owner using unitdata2.dta
drop if _merge!=1
drop _merge
duplicates drop unit, force
save unitdata3.dta, replace
clear
use unitdata.dta
merge m:1 unit owner using unitdata1.dta
drop if _merge!=1
drop _merge
merge m:1 unit owner using unitdata2.dta
drop if _merge!=1
drop _merge
merge m:1 unit owner using unitdata3.dta
drop if _merge!=1
drop _merge
duplicates drop unit, force
rename owner owner4
rename ownership ownership4
*rename firm_code firm_code4
save unitdata4.dta, replace
clear
use unitdata2.dta
rename owner owner2
rename ownership ownership2
*rename firm_code firm_code2
save unitdata2.dta, replace
clear
use unitdata3.dta
rename owner owner3
rename ownership ownership3
*rename firm_code firm_code3
save unitdata3, replace







