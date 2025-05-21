********************************
***** 2017-2021 quarterly ******
********************************

global path "D:\РЭШ\Research\PostThesis"
global datafile "$path\data\var\bankdata_201709-202109_q_var_result.dta"
global datafile_save "$path\data\var\bankdata_201709-202109_q_var_result+.dta"

global path_tex "$path\reg_res\summary_stats"
global path_graph "$path\graphs\dynamics"

**===============**
*** PASSTHROUGH ***
*== vars for vars (winsirized) data ==*
//global endname "_vars_proc_add"
use "$datafile", clear

gen Capital_ratio = Net_worth / Total_assets
gen Liquidity_ratio = Cash / Total_assets
gen Core_deposits = Deposits / Liabilities
gen Credit_cond = II_Loans / Loans * 100
gen Deposit_cond = IE_Deposits / Deposits * 100
gen Deposit_spread = ruo - Deposit_cond

gen m_L_key_rate = m_L * key_rate
gen m_D_key_rate = m_D * key_rate

gen m_L_iq_key_rate = m_L_iq * key_rate
gen m_D_iq_key_rate = m_D_iq * key_rate

gen m_L_noreg_key_rate = m_L_noreg * key_rate
gen m_D_noreg_key_rate = m_D_noreg * key_rate


gen Core_deposits_wins = Deposits_wins / Liabilities
gen Credit_cond_wins = II_Loans_wins / Loans_wins *100
gen Deposit_cond_wins = IE_Deposits_wins / Deposits_wins * 100
gen Deposit_spread_wins = ruo - Deposit_cond_wins
gen m_L_wins_key_rate = m_L_wins * key_rate
gen m_D_wins_key_rate = m_D_wins * key_rate

summarize m_D m_L m_D_iq m_L_iq m_D_noreg m_L_noreg m_D_wins m_L_wins, detail

local vars_out m_D m_L m_D_iq m_L_iq m_D_noreg m_L_noreg m_D_wins m_L_wins
foreach var in `vars_out' { 
	egen upq_`var' = pctile(`var'), p(75) // by(dq)
	egen loq_`var' = pctile(`var'), p(25) // by(dq)
	egen iqr_`var' = iqr(`var') // , by(dq)
	gen upper_`var' = upq_`var' + 1.5 * iqr_`var'
	gen lower_`var' = loq_`var' - 1.5 * iqr_`var'
	gen oliq_`var'=((`var'<lower_`var')|(`var'>upper_`var'))
	replace oliq_`var'=. if `var'==.
	drop upq_`var' loq_`var' iqr_`var' upper_`var' lower_`var'
	label var oliq_`var' "IQR outlier for `var'"
}
foreach var in `vars_out' { 
	egen upper_`var' = pctile(`var'), p(99.5) // by(dq)
	egen lower_`var' = pctile(`var'), p(0.5) // by(dq)
	gen olq_`var'=((`var'<lower_`var')|(`var'>upper_`var'))
	replace olq_`var'=. if `var'==.
	drop upper_`var' lower_`var'
	label var olq_`var' "Quantile outlier for `var'"
}

gen lnL = ln(Loans)
gen lnL_wins = ln(Loans_wins)
gen lnD = ln(Deposits)
gen lnD_wins = ln(Deposits_wins)

save "$datafile_save", replace

*******************************
**** STATISTICS ***************
*******************************
use "$datafile_save", clear
drop if m_L==. & m_D==.

*** Full Dataset ***	
local vars Credit_cond Deposit_cond Credit_cond_wins Deposit_cond_wins ///
	lnD lnL lnL_wins lnD_wins ///
	m_D m_L m_D_iq m_L_iq m_D_noreg m_L_noreg m_D_wins m_L_wins ///
	key_rate Capital_ratio Liquidity_ratio Core_deposits CPI GDP_growth

estpost summarize `vars', detail
matrix stats = (e(count)', e(mean)', e(sd)', e(min)', e(p50)', e(max)')
matrix colnames stats = Obs Mean SD Min Median Max
matlist stats
//matrix rownames stats = `vars'
estout matrix(stats) using "$path_tex/summary_stats_full.tex", replace style(tex)
estout matrix(stats) using "$path_tex/summary_stats_full.csv", replace delimiter(";")

*** Markup quantile outliers removed ***
* Note different dataset for each markup type

** All except winsorized markups
foreach mu in m_L m_L_iq m_L_noreg {
	local vars Credit_cond ///
		lnL ///
		`mu' ///
		key_rate Capital_ratio Liquidity_ratio Core_deposits CPI GDP_growth
		
	estpost summarize `vars' if olq_`mu'==0, detail
	matrix stats = (e(count)', e(mean)', e(sd)', e(min)', e(p50)', e(max)')
	matrix colnames stats = Obs Mean SD Min Median Max
	matlist stats
	//matrix rownames stats = `vars'
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_Q.tex", replace style(tex)
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_Q.csv", replace delimiter(";")
	
	estpost summarize `vars' if oliq_`mu'==0, detail
	matrix stats = (e(count)', e(mean)', e(sd)', e(min)', e(p50)', e(max)')
	matrix colnames stats = Obs Mean SD Min Median Max
	matlist stats
	//matrix rownames stats = `vars'
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_IQR.tex", replace style(tex)
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_IQR.csv", replace delimiter(";")
}

foreach mu in m_D m_D_iq m_D_noreg {
	local vars Deposit_cond ///
		lnD ///
		`mu' ///
		key_rate Capital_ratio Liquidity_ratio Core_deposits CPI GDP_growth
		
	estpost summarize `vars' if olq_`mu'==0, detail
	matrix stats = (e(count)', e(mean)', e(sd)', e(min)', e(p50)', e(max)')
	matrix colnames stats = Obs Mean SD Min Median Max
	matlist stats
	//matrix rownames stats = `vars'
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_Q.tex", replace style(tex)
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_Q.csv", replace delimiter(";")
	
	estpost summarize `vars' if oliq_`mu'==0, detail
	matrix stats = (e(count)', e(mean)', e(sd)', e(min)', e(p50)', e(max)')
	matrix colnames stats = Obs Mean SD Min Median Max
	matlist stats
	//matrix rownames stats = `vars'
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_IQR.tex", replace style(tex)
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_IQR.csv", replace delimiter(";")
}

* Winsorized markups
foreach mu in m_L_wins {
	local vars Credit_cond_wins ///
		lnL_wins ///
		`mu' ///
		key_rate Capital_ratio Liquidity_ratio Core_deposits CPI GDP_growth
	
	estpost summarize `vars' if olq_`mu'==0, detail
	matrix stats = (e(count)', e(mean)', e(sd)', e(min)', e(p50)', e(max)')
	matrix colnames stats = Obs Mean SD Min Median Max
	matlist stats
	//matrix rownames stats = `vars'
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_Q.tex", replace style(tex)
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_Q.csv", replace delimiter(";")
	
	estpost summarize `vars' if oliq_`mu'==0, detail
	matrix stats = (e(count)', e(mean)', e(sd)', e(min)', e(p50)', e(max)')
	matrix colnames stats = Obs Mean SD Min Median Max
	matlist stats
	//matrix rownames stats = `vars'
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_IQR.tex", replace style(tex)
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_IQR.csv", replace delimiter(";")
}

foreach mu in m_D_wins {
	local vars Deposit_cond_wins ///
		lnD_wins ///
		`mu' ///
		key_rate Capital_ratio Liquidity_ratio Core_deposits CPI GDP_growth
	
	estpost summarize `vars' if olq_`mu'==0, detail
	matrix stats = (e(count)', e(mean)', e(sd)', e(min)', e(p50)', e(max)')
	matrix colnames stats = Obs Mean SD Min Median Max
	matlist stats
	//matrix rownames stats = `vars'
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_Q.tex", replace style(tex)
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_Q.csv", replace delimiter(";")
	
	estpost summarize `vars' if oliq_`mu'==0, detail
	matrix stats = (e(count)', e(mean)', e(sd)', e(min)', e(p50)', e(max)')
	matrix colnames stats = Obs Mean SD Min Median Max
	matlist stats
	//matrix rownames stats = `vars'
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_IQR.tex", replace style(tex)
	estout matrix(stats) using "$path_tex/summary_stats_`mu'_IQR.csv", replace delimiter(";")
}

**************************************************
**** GRAPHS OF THE DYNAMICS **********************
**************************************************
local vars Credit_cond Deposit_cond Credit_cond_wins Deposit_cond_wins ///
	lnD lnL lnL_wins lnD_wins ///
	m_D m_L m_D_iq m_L_iq m_D_noreg m_L_noreg m_D_wins m_L_wins ///
	key_rate Capital_ratio Liquidity_ratio Core_deposits CPI GDP_growth

* Levels
foreach t in mean median {
	use "$datafile_save", clear
	drop if m_L==. & m_D==.
	
	collapse (`t') `vars', by(dq)
	
	foreach w in "" "_wins" {
		twoway connected key_rate Credit_cond`w' Deposit_cond`w' dq
		graph export "$path_graph\Conds`w'_`t'.png", replace
		
		twoway connected lnL`w' lnD`w' dq
		graph export "$path_graph\Volumes`w'_`t'.png", replace
	}
	
}

* First Differences
foreach t in mean median {
	use "$datafile_save", clear
	drop if m_L==. & m_D==.
	
	sort regnum dq
	local Dvars ""
	foreach v in `vars' {
		by regnum: gen `v'_l = `v'[_n-1] if t==t[_n-1]+1 // lag
		gen D_`v' = `v' - `v'_l
		drop `v'_l
		local Dvars "`Dvars' D_`v'"
	}
	
	
	collapse (`t') `Dvars', by(dq)
	
	foreach w in "" "_wins" {
		twoway connected D_key_rate D_Credit_cond`w' D_Deposit_cond`w' dq
		graph export "$path_graph\Conds`w'_diff_`t'.png", replace
		
		twoway connected D_lnL`w' D_lnD`w' dq
		graph export "$path_graph\Volumes`w'_diff_`t'.png", replace
	}
}

gen lnTA = ln(Total_assets)
scatter m_L_wins m_D_wins if oliq_m_L_wins==0 & oliq_m_D_wins==0
scatter m_L_wins lnTA if oliq_m_L_wins==0
scatter m_D_wins lnTA if oliq_m_D_wins==0
scatter m_L m_D if oliq_m_L==0 & oliq_m_D==0
