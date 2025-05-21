**********************************
*** Thesis: Banks Market Power ***
**********************************

/*
Previously: using Python, I have extracted banks consolidated reports (quarterly) from 2017q3 to 2021q9, deaccumulated and corrected the data for CPI, and saved to Excel, added RUONIA and Key Rate. So, Excel file contains the data required for further analysis in real (corrected for inflation) values.

Additionally I use dataset Winsorized in Python (the two Winsorizations are slightly different because Stata and Python define quantile values differently).

Here I add description and winsorize, subsequently saving to dta files.

The actions are:
1. Prepare dta files with CPI and GDP growth data.
2. Use data prepared in Python, add CPI and GDP growth data, and label. Save
3. Winsorize and label. Save
4. Use data prepared and winsorized in Python, add CPI and GDP growth data, and label. Save

*/

clear all
global path "D:\РЭШ\Research\PostThesis\data"
//global exceldata "$path\var\bankdata_201709-202109_q_var_real_ruo.xlsx"


*** EXTERNAL DATA (CPI and GDP growth) ***
/* Prepare data on CPI and GDP growth in percentage. */
* CPI yearly (geom mean of Q to last year Q fromm Rosstat and yearly data from FRED)
import excel "$path\external_data\CPI_yearly+FRED.xlsx", clear firstrow
replace CPI = CPI - 100
drop obs
rename CPI CPI_year
label var CPI_year "CPI geom mean of Q to last year Q, from Rosstat"
label var CPI_FRED "CPI yearly, from FRED"
save "$path\external_data\cpi_yearly.dta", replace

* CPI quarterly (Q to last year Q from Rosstat)
import excel "$path\external_data\original\CPI_quarterly.xlsx", sheet(Q2Q) clear firstrow
keep quarter QtolastyearQ
rename QtolastyearQ CPI
replace CPI = CPI - 100
label var CPI "CPI Q to last year Q, from Rosstat"
save "$path\external_data\cpi_quarterly.dta", replace

* GDP growth yearly data
import excel "$path\external_data\GDP_growth.xlsx", clear firstrow
keep year GDPgrowth
rename GDPgrowth GDP_growth
replace GDP_growth = (GDP_growth - 1)*100
label var GDP_growth "GDP growth yearly, from FRED"
save "$path\external_data\gdp_growth.dta", replace


*** QUARTERLY DATA (FULL) ***
* import from excel quarterly data (no Winsorisation)
import excel "$path\var\bankdata_201709-202109_q_var_real_ruo.xlsx", firstrow clear
drop A Unnamed* flag

rename dt_year year
rename dt_month month

merge n:1 year using "$path\external_data\cpi_yearly.dta", nogenerate
merge n:1 quarter using "$path\external_data\cpi_quarterly.dta", nogenerate
gen ruo_q = (1+ruo/100)^(1/4) - 1 // quarterly interest rate
label var ruo_q "RUONIA, quarterly return"
merge n:1 year using "$path\external_data\gdp_growth.dta", nogenerate
drop if regnum == .

* coment the data
label var regnum "Registration number of the bank"
label var year "Year"
label var month "Month number"
label var quarter "Quarter"
label var Name "Bank full name"
label var Total_assets "Total assets"
label var Net_worth "Net worth"
label var Net_income "Net income"
label var Loans "Loans"
label var Admin_expenses "Administrative expenses"
label var Rel_Admin_expenses "Administrative expenses relative to Total assets"
label var Securities "Securities Holdings"
label var Cash "Cash and equivalents, including deposit on bank accounts and central banks"
label var Liabilities "Total liabilities"
label var NIE "Non-interest expenses, includes commisions and administrative expenses"
label var NII "Non-interest income, includes commisions, dividents, and other operational income"
label var II_Loans "Interest income on loans"
label var IE_Deposits "Interest expenses on deposits"
label var Leverage "Ratio Net worth to Total assets"
label var Deposits "Deposits"
label var Pure_deposits "Deposits from people and non-credit organizations"
label var Sales "All interest and commission income"
label var Safe_funds "Deposits in other banks"
label var Safe_funds_income "Interest income from deposits in other banks"
label var Safe_rev "Safe revenues: ratio Safe funds income to Safe funds"
label var PoL "Price of loans: ratio Interest income on loans to Loans"
label var CoF "Cost of funds: ratio Interest expenses on deposits to Deposits"
label var ruo "RUONIA, quarterly geometric mean"
label var key_rate "Key interest rate, quarterly geometric mean"
//label var CPI_year "CPI by Rosstat, yearly"
//label var CPI_FRED "CPI by FRED, yearly"
//label var GDP_growth "GDP growth by FRED, yearly"

* quarter variable in date-time format
gen dt = mdy(month, 1, year)
gen dq = qofd(dt)
format dq %tq
label var dq "Quarter"
drop dt

* time variable in numeric format
egen min_t = min(dq)
gen t = dq - min_t + 1
label var t "Time period"
drop min_t

order regnum dq t
sort regnum dq

save "$path\var\bankdata_201709-202109_q_var_real_ruo.dta", replace



*** QUARTERLY DATA (WINSORISED in Python) ***
* import from excel quarterly data (Winsorised)
import excel "$path\var\bankdata_201709-202109_q_var_real_ruo_wins.xlsx", firstrow clear
drop A Unnamed* flag

rename dt_year year
rename dt_month month

merge n:1 year using "$path\external_data\cpi_yearly.dta", nogenerate
merge n:1 quarter using "$path\external_data\cpi_quarterly.dta", nogenerate
gen ruo_q = (1+ruo/100)^(1/4) - 1 // quarterly interest rate
label var ruo_q "RUONIA, quarterly return"
merge n:1 year using "$path\external_data\gdp_growth.dta", nogenerate
drop if regnum == .

* coment the data
label var regnum "Registration number of the bank"
label var year "Year"
label var month "Month number"
label var quarter "Quarter"
label var Name "Bank full name"
label var Total_assets "Total assets"
label var Net_worth "Net worth"
label var Net_income "Net income"
label var Loans "Loans (winsorised)"
label var Admin_expenses "Administrative expenses"
label var Rel_Admin_expenses "Administrative expenses relative to Total assets"
label var Securities "Securities Holdings (winsorised)"
label var Cash "Cash and equivalents, including deposit on bank accounts and central banks"
label var Liabilities "Total liabilities"
label var NIE "Non-interest expenses (winsorised), includes commisions and administrative expenses"
label var NII "Non-interest income (winsorised), includes commisions, dividents, and other operational income"
label var II_Loans "Interest income on loans (winsorised)"
label var IE_Deposits "Interest expenses on deposits (winsorised)"
label var Leverage "Ratio Net worth to Total assets"
label var Deposits "Deposits (winsorised)"
label var Pure_deposits "Deposits from people and non-credit organizations"
label var Sales "All interest and commission income (winsorised)"
label var Safe_funds "Deposits in other banks"
label var Safe_funds_income "Interest income from deposits in other banks"
label var Safe_rev "Safe revenues: ratio Safe funds income to Safe funds"
label var PoL "Price of loans: ratio Interest income on loans to Loans"
label var CoF "Cost of funds: ratio Interest expenses on deposits to Deposits"
label var ruo "RUONIA, quarterly geometric mean"
label var key_rate "Key interest rate, quarterly geometric mean"
//label var CPI_year "CPI by Rosstat, yearly"
//label var CPI_FRED "CPI by FRED, yearly"
//label var GDP_growth "GDP growth by FRED, yearly"

foreach v in "NIE" "NII" "Loans" "Deposits" "Securities" "II_Loans" "IE_Deposits" "PoL" "CoF" {
	rename `v' `v'_wins
}

* quarter variable in date-time format
gen dt = mdy(month, 1, year)
gen dq = qofd(dt)
format dq %tq
label var dq "Quarter"
drop dt

* time variable in numeric format
egen min_t = min(dq)
gen t = dq - min_t + 1
label var t "Time period"
drop min_t

order regnum dq t
sort regnum dq

save "$path\var\bankdata_201709-202109_q_var_real_ruo_wins.dta", replace



*** QUARTERLY DATA (WINSORISED in STATA) ***
* Winsorize
use "$path\var\bankdata_201709-202109_q_var_real_ruo.dta", clear

foreach v in "NIE" "NII" "Loans" "Deposits" "Securities" "II_Loans" "IE_Deposits" {
	gen `v'TA = `v' / Total_assets
	//hist `v'
	//graph export "$path\var\hist_`v'.png", replace
	//hist `v'TA
	//graph export "$path\var\hist_`v'TA.png", replace
	egen upq_`v'TA = pctile(`v'TA), p(99)
	egen loq_`v'TA = pctile(`v'TA), p(1)
	gen `v'_winsSt = `v'
	replace `v'_winsSt = upq_`v'TA * Total_assets if `v'TA > upq_`v'TA
	replace `v'_winsSt = loq_`v'TA * Total_assets if `v'TA < loq_`v'TA
	drop `v'TA upq_`v'TA loq_`v'TA
}

gen PoL_winsSt = II_Loans_winsSt / Loans_winsSt
gen CoF_winsSt = IE_Deposits_winsSt / Deposits_winsSt

label var NIE_winsSt "Non-interest expenses, Winsorized in Stata"
label var NII_winsSt "Non-interest income, Winsorized in Stata"
label var Loans_winsSt "Loans, Winsorized in Stata"
label var Deposits_winsSt "Deposits, Winsorized in Stata"
label var Securities_winsSt "Securities, Winsorized in Stata"
label var II_Loans_winsSt "Interest income on Loans, Winsorized in Stata"
label var IE_Deposits_winsSt "Interest expenses on Deposits, Winsorized in Stata"

save "$path\var\bankdata_201709-202109_q_var_real_ruo_winsStata.dta", replace





/*
*** YEARLY DATA ***
* import from excel quarterly data
import excel "$path\var\bankdata_2017-2020_y_var_real_ruo.xlsx", firstrow clear
drop A Unnamed*

* coment the data
label var regnum "Registration number of the bank"
label var dt_year "Year"
label var dt_month "Month number"
label var quarter "Quarter"
label var Name "Bank full name"
label var Total_assets "Total assets"
label var Net_worth "Net worth"
label var Net_income "Net income"
label var Loans "Loans"
label var Admin_expenses "Administrative expenses"
label var Rel_Admin_expenses "Administrative expenses relative to Total assets"
label var Securities "Securities Holdings"
label var Cash "Cash and equivalents, including deposit on bank accounts and central banks"
label var Liabilities "Total liabilities"
label var NIE "Non-interest expenses, includes commisions and administrative expenses"
label var NII "Non-interest income, includes commisions, dividents, and other operational income"
label var II_Loans "Interest income on loans"
label var IE_Deposits "Interest expenses on deposits"
label var Leverage "Ratio Net worth to Total assets"
label var Deposits "Deposits"
label var Pure_deposits "Deposits from people and non-credit organizations"
label var Sales "All interest and commission income"
label var Safe_funds "Deposits in other banks"
label var Safe_funds_income "Interest income from deposits in other banks"
label var Safe_rev "Safe revenues: ratio Safe funds income to Safe funds"
label var PoL "Price of loans: ratio Interest income on loans to Loans"
label var CoF "Cost of funds: ratio Interest expenses on deposits to Deposits"
label var ruo "RUONIA, yearly geometric mean"
label var key_rate "Key interest rate, yearly geometric mean"

* time variable in numeric format
egen min_t = min(dt_year)
gen t = dt_year - min_t + 1
label var t "Time period"
drop min_t

save "$path\var\bankdata_2017-2020_y_var_real_ruo.dta", replace
*/
