**********************************
*** Thesis: Banks Market Power ***
**********************************

/*
Here I plot graphs for the estimated markups.
*/

clear all
global path "D:\РЭШ\Research\PostThesis"
global datafile "$path\data\var\bankdata_201709-202109_q_var_result.dta"
global path_graph "$path\graphs"

********************************
***** 2017-2021 quarterly ******
********************************
use "$datafile", clear
drop if m_L==. & m_D==.

gen lnTA = ln(Total_assets)
label var lnTA "ln(Total Assets)"

*** SCATTER PLOTS ***
global path_scatter "$path_graph\scatterSt"
*** Markups between markups ***
//keep if oliq_lnL==0 & oliq_lnD==0 & oliq_lnQ==0 & oliq_lnNIE==0 & oliq_lnNII==0
correlate m_L m_L_wins m_L_winsSt m_L_noreg m_L_iq
correlate m_D m_D_wins m_D_winsSt m_D_noreg m_D_iq

* With m_L_wins: all other m_L and same type m_D
local base_v m_L_wins
foreach v in m_D_wins m_L m_L_winsSt m_L_noreg m_L_CoF m_L_CoF_noreg m_L_CoF_wins m_L_iq {
	scatter `v' `base_v'
	graph export "$path_scatter\Scatter.`base_v'-`v'.png", as(png) replace
	scatter `v' `base_v' if oliq_`v'==0 & oliq_`base_v'==0
	graph export "$path_scatter\Scatter.`base_v'-`v'.oliq.png", as(png) replace
}

* With m_D_wins: all other m_D and same type m_L
local base_v m_D_wins
foreach v in m_L_wins m_D m_D_noreg m_D_winsSt m_L_CoF_wins m_D_iq {
	scatter `v' `base_v'
	graph export "$path_scatter\Scatter.`base_v'-`v'.png", as(png) replace
	scatter `v' `base_v' if oliq_`v'==0 & oliq_`base_v'==0
	graph export "$path_scatter\Scatter.`base_v'-`v'.oliq.png", as(png) replace
}

*** Markups and banks size ***
* Total assets
gen m_avg_wins = (m_L_wins + m_D_wins)/2

local base_v lnTA
foreach v in m_L_wins m_D_wins m_avg_wins {
	scatter `v' `base_v'
	graph export "$path_scatter\Scatter.`base_v'-`v'.png", as(png) replace
	scatter `v' `base_v' if oliq_`v'==0
	graph export "$path_scatter\Scatter.`base_v'-`v'.oliq.png", as(png) replace
}

* Loans (and credit markups)
local base_v lnL
local v m_L_wins
scatter `v' `base_v'
graph export "$path_scatter\Scatter.`base_v'-`v'.png", as(png) replace
scatter `v' `base_v' if oliq_`v'==0
graph export "$path_scatter\Scatter.`base_v'-`v'.oliq.png", as(png) replace

* Deposits (and deposit markups)
local base_v lnL
local v m_L_wins
scatter `v' `base_v'
graph export "$path_scatter\Scatter.`base_v'-`v'.png", as(png) replace
scatter `v' `base_v' if oliq_`v'==0
graph export "$path_scatter\Scatter.`base_v'-`v'.oliq.png", as(png) replace


*** TRENDS ***
global path_trends "$path_graph\trendsSt"
** Full dataset **
* Simple average
use "$datafile", clear
drop if m_L==. & m_D==.
gen m_avg_wins = (m_L_wins + m_D_wins)/2
collapse (mean) m_L_wins m_D_wins m_avg_wins HHI, by(dq)
twoway connected HHI dq, title("HHI", size(medium))
graph export "$path_trends\Trend.HHI.png", as(png) replace
twoway connected m_L_wins m_D_wins m_avg_wins dq, title("Trends. Simple average", size(medium)) 

* Weighted average (by Total Assets)
use "$datafile", clear
drop if m_L==. & m_D==.
gen m_avg_wins = (m_L_wins + m_D_wins)/2
collapse (mean) m_L_wins m_D_wins m_avg_wins HHI [w=Total_assets], by(dq)
twoway connected m_L_wins m_D_wins m_avg_wins dq, title("Trends. Weighted average", size(medium)) 

* Median
use "$datafile", clear
drop if m_L==. & m_D==.
gen m_avg_wins = (m_L_wins + m_D_wins)/2
collapse (median) m_L_wins m_D_wins m_avg_wins HHI, by(dq)
twoway connected m_L_wins m_D_wins m_avg_wins dq, title("Trends. Median", size(medium)) 


** IQR dataset **
* Simple average
use "$datafile", clear
collapse (mean) m_L_wins if oliq_m_L_wins==0, by(dq)
twoway connected m_L_wins dq, title("Trends. Credit markups. Simple average", size(medium)) 

use "$datafile", clear
collapse (mean) m_D_wins if oliq_m_D_wins==0, by(dq)
twoway connected m_D_wins dq, title("Trends. Deposit markups. Simple average", size(medium)) 

use "$datafile", clear
gen m_avg_wins = (m_L_wins + m_D_wins)/2
collapse (mean) m_avg_wins if oliq_m_D_wins==0 & oliq_m_L==0, by(dq)
twoway connected m_avg_wins dq, title("Trends. Avg markups. Simple average", size(medium)) 


* Weighted average (by Total Assets)
use "$datafile", clear
collapse (mean) m_L_wins [w=Total_assets] if oliq_m_L_wins==0, by(dq)
twoway connected m_L_wins dq, title("Trends. Credit markups. Weighted average", size(medium)) 

use "$datafile", clear
collapse (mean) m_D_wins [w=Total_assets] if oliq_m_D_wins==0, by(dq)
twoway connected m_D_wins dq, title("Trends. Deposit markups. Weighted average", size(medium)) 

use "$datafile", clear
gen m_avg_wins = (m_L_wins + m_D_wins)/2
collapse (mean) m_avg_wins [w=Total_assets] if oliq_m_D_wins==0 & oliq_m_L==0, by(dq)
twoway connected m_avg_wins dq, title("Trends. Avg markups. Weighted average", size(medium)) 


* Median
use "$datafile", clear
collapse (median) m_L_wins if oliq_m_L_wins==0, by(dq)
twoway connected m_L_wins dq, title("Trends. Credit markups. Median", size(medium)) 

use "$datafile", clear
collapse (median) m_D_wins if oliq_m_D_wins==0, by(dq)
twoway connected m_D_wins dq, title("Trends. Deposit markups. Median", size(medium)) 

use "$datafile", clear
gen m_avg_wins = (m_L_wins + m_D_wins)/2
collapse (median) m_avg_wins if oliq_m_D_wins==0 & oliq_m_L==0, by(dq)
twoway connected m_avg_wins dq, title("Trends. Avg markups. Median", size(medium)) 



*** Dynamics for a few banks ***
use "$datafile", clear
twoway connected m_L_wins m_D_wins dq if regnum == 1481 //,  yline(1) // 1000 1326 1481
twoway connected m_L_wins m_D_wins dq if regnum == 1000 //,  yline(1) // 1000 1326 1481
twoway connected m_L_wins m_D_wins dq if regnum == 1326 //,  yline(1) // 1000 1326 1481


/*
sktest lnQ

graph twoway (lfit m_L m_D) (scatter m_L m_D) if outl_m_L == 0 & outl_m_D == 0

graph twoway (lfit m_L m_D) (scatter m_L m_D) if outl_MNetNIE_L == 0 & outl_MNetNIE_D == 0


sktest MNetNIE_L if outl_MNetNIE_L == 0 // not normal
sktest MNetNIE_D if outl_MNetNIE_D == 0 // rather not normal
sktest MNIE_L if outl_MNIE_L == 0 // rather not normal
sktest MNII_L if outl_MNII_L == 0 // maybe normal
sktest MNIE_D if outl_MNIE_D == 0 // not normal
sktest MNII_D if outl_MNII_D == 0 // not normal

sktest MNIE_L MNII_L MNIE_D MNII_D MNetNIE_L MNetNIE_D m_L m_D

hist m_L if outl_m_L == 0

count
count if oliq_MNIE_L == 1 | oliq_MNII_L == 1
count if oliq_MNetNIE_L == 1
count if oliq_m_L == 1
count if olq_m_L == 1

count if outl_MNIE_D == 1 | outl_MNII_D == 1
count if outl_MNetNIE_D == 1
*/
