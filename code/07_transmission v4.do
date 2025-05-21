********************************
***** 2017-2021 quarterly ******
********************************

global path "D:\РЭШ\Research\PostThesis"
global datafile "$path\data\var\bankdata_201709-202109_q_var_result.dta"
global path_tex "$path\reg_res\main"


use "$datafile", clear
drop if m_L_wins==. & m_D_wins==. & m_L_CoF_wins==.

global xcontrols Capital_ratio Liquidity_ratio Core_deposits CPI GDP_growth
global xcontrols_wins Capital_ratio Liquidity_ratio Core_deposits_wins CPI GDP_growth
global xcontrols_winsSt Capital_ratio Liquidity_ratio Core_deposits_winsSt CPI GDP_growth

global xcontrols_tFE Capital_ratio Liquidity_ratio Core_deposits
global xcontrols_tFE_wins Capital_ratio Liquidity_ratio Core_deposits_wins
global xcontrols_tFE_winsSt Capital_ratio Liquidity_ratio Core_deposits_winsSt

foreach v in key_rate Credit_cond Credit_cond_wins Credit_cond_winsSt Deposit_cond Deposit_cond_wins Deposit_cond_winsSt lnL lnL_wins lnL_winsSt lnD lnD_wins lnD_winsSt {
	by regnum: gen `v'_l = `v'[_n-1] if t==t[_n-1]+1 // lag
	gen D_`v' = `v' - `v'_l
	drop `v'_l
}

sort regnum dq
foreach v in key_rate D_key_rate {
	by regnum: gen `v'_lag1 = `v'[_n-1] if t==t[_n-1]+1 // 1st lag
	by regnum: gen `v'_lag2 = `v'[_n-2] if t==t[_n-2]+2 // 2nd lag
	by regnum: gen `v'_lag3 = `v'[_n-3] if t==t[_n-3]+3 // 3rd lag
	by regnum: gen `v'_lead1 = `v'[_n+1] if t==t[_n+1]-1 // 1st lead
	by regnum: gen `v'_lead2 = `v'[_n+2] if t==t[_n+2]-2 // 2nd lead
	by regnum: gen `v'_lead3 = `v'[_n+3] if t==t[_n+3]-3 // 3rd lead
}

foreach v in m_L m_D m_L_CoF m_L_wins m_D_wins m_L_CoF_wins m_L_wins_break m_D_wins_break{
	foreach kr in key_rate key_rate_lag1 key_rate_lag2 key_rate_lag3 key_rate_lead1 key_rate_lead2 key_rate_lead3 {
		gen `v'_`kr' = `v' * `kr'
	}
}


foreach v in m_L m_D m_L_CoF m_L_wins m_D_wins m_L_CoF_wins m_L_wins_break m_D_wins_break {
	foreach kr in D_key_rate D_key_rate_lag1 D_key_rate_lag2 D_key_rate_lag3 D_key_rate_lead1 D_key_rate_lead2 D_key_rate_lead3 {
		gen `v'_`kr' = `v' * `kr'
	}
}
export delimited "$path\data\var\bankdata_201709-202109_q_var_result_transmission.csv", replace


** CREDIT MARKUPS **
* Markups outliers removed by interquantile range (IQR)
foreach mu in m_L m_L_wins m_L_wins_break {	
	foreach dv in Credit_cond lnL { // Dependent variable
		if "`dv'" == "Credit_cond" {
			local dv_title "Credit cond" // Dependent variable -- for the title
		}
		else if "`dv'" == "lnL" {
			local dv_title "ln Loans"
		}
		
		if inlist("`mu'", "m_L","m_L_CoF") {
			local title "Init"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		else if inlist("`mu'", "m_L_iq","m_L_CoF_iq") {
			local title "IQR"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		else if inlist("`mu'", "m_L_wins","m_L_CoF_wins") {
			local title "Wins"
			local dv_reg `dv'_wins
			local xctrls_reg $xcontrols_wins
			local xctrls_reg_tFE $xcontrols_tFE_wins
		}
		else if inlist("`mu'", "m_L_wins_break") {
			local title "Break"
			local dv_reg `dv'_wins
			local xctrls_reg $xcontrols_wins
			local xctrls_reg_tFE $xcontrols_tFE_wins
		}
		else if inlist("`mu'", "m_L_winsSt","m_L_CoF_winsSt") {
			local title "WinsSt"
			local dv_reg `dv'_winsSt
			local xctrls_reg $xcontrols_winsSt
			local xctrls_reg_tFE $xcontrols_tFE_winsSt
		}
		else if inlist("`mu'", "m_L_noreg","m_L_CoF_noreg") {
			local title "No Reg"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		
		*** ONLY BANK FE ***
		** LEVELS **
		local tex "reg_iqr_L_Credit_`mu'.tex"
		
		reghdfe `dv_reg' key_rate_lag2 key_rate_lag1 key_rate key_rate_lead1 key_rate_lead2 ///
			`mu' `mu'_key_rate_lag2 `mu'_key_rate_lag1 `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe `dv_reg' key_rate key_rate_lead1 key_rate_lead2 ///
			`mu' `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe `dv_reg' key_rate `mu' `mu'_key_rate `xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
			
		** FIRST DIFFERENCES **
		local tex "reg_iqr_D_Credit_`mu'.tex"
		
		reghdfe D_`dv_reg' D_key_rate_lag2 D_key_rate_lag1 D_key_rate D_key_rate_lead1 D_key_rate_lead2 ///
			`mu' `mu'_D_key_rate_lag2 `mu'_D_key_rate_lag1 `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe D_`dv_reg' D_key_rate D_key_rate_lead1 D_key_rate_lead2 ///
			`mu' `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe D_`dv_reg' D_key_rate `mu' `mu'_D_key_rate `xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
			
			
			
		*** BANK AND TIME FE ***
		** LEVELS **
		local tex "reg_iqr_L_Credit_`mu'.tFE.tex"
		
		reghdfe `dv_reg' ///
			`mu' `mu'_key_rate_lag2 `mu'_key_rate_lag1 `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe `dv_reg' ///
			`mu' `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe `dv_reg' `mu' `mu'_key_rate `xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
			
		** FIRST DIFFERENCES **
		local tex "reg_iqr_D_Credit_`mu'.tFE.tex"
		
		reghdfe D_`dv_reg' ///
			`mu' `mu'_D_key_rate_lag2 `mu'_D_key_rate_lag1 `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe D_`dv_reg' ///
			`mu' `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe D_`dv_reg' `mu' `mu'_D_key_rate `xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
	}
}



** DEPOSIT MARKUPS **

	
* Markups outliers removed by interquantile range (IQR)
foreach mu in m_D m_D_wins m_D_wins_break {
	foreach dv in Deposit_cond lnD { // Dependent variable
		if "`dv'" == "Deposit_cond" {
			local dv_title "Deposit cond" // Dependent variable name -- for the title
		}
		else if "`dv'" == "lnD" {
			local dv_title "ln Deposits"
		}	
		
		if inlist("`mu'", "m_D","m_L_CoF") {
			local title "Init"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		else if inlist("`mu'", "m_D_iq","m_L_CoF_iq") {
			local title "IQR"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		else if inlist("`mu'", "m_D_wins","m_L_CoF_wins") {
			local title "Wins"
			local dv_reg `dv'_wins
			local xctrls_reg $xcontrols_wins
			local xctrls_reg_tFE $xcontrols_tFE_wins
		}
		else if inlist("`mu'", "m_D_wins_break") {
			local title "Break"
			local dv_reg `dv'_wins
			local xctrls_reg $xcontrols_wins
			local xctrls_reg_tFE $xcontrols_tFE_wins
		}
		else if inlist("`mu'", "m_D_winsSt","m_L_CoF_winsSt") {
			local title "WinsSt"
			local dv_reg `dv'_winsSt
			local xctrls_reg $xcontrols_winsSt
			local xctrls_reg_tFE $xcontrols_tFE_winsSt
		}
		else if inlist("`mu'", "m_D_noreg","m_L_CoF_noreg") {
			local title "No Reg"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}

		
		*** ONLY BANK FIXED EFFECTS ***
		** LEVELS **
		local tex "reg_iqr_L_Deposit_`mu'.tex"
		
		reghdfe `dv_reg' key_rate_lag2 key_rate_lag1 key_rate key_rate_lead1 key_rate_lead2 ///
			`mu' `mu'_key_rate_lag2 `mu'_key_rate_lag1 `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe `dv_reg' key_rate key_rate_lead1 key_rate_lead2 ///
			`mu' `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe `dv_reg' key_rate `mu' `mu'_key_rate `xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		
		** FIRST DIFFERENCES **
		local tex "reg_iqr_D_Deposit_`mu'.tex"
		
		reghdfe D_`dv_reg' D_key_rate_lag2 D_key_rate_lag1 D_key_rate D_key_rate_lead1 D_key_rate_lead2 ///
			`mu' `mu'_D_key_rate_lag2 `mu'_D_key_rate_lag1 `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe D_`dv_reg' D_key_rate D_key_rate_lead1 D_key_rate_lead2 ///
			`mu' `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe D_`dv_reg' D_key_rate `mu' `mu'_D_key_rate `xctrls_reg' if oliq_`mu'==0, absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes", "Markup outliers", "IQR")
			
		
		*** BANK AND TIME FIXED EFFECTS ***
		** LEVELS **
		local tex "reg_iqr_L_Deposit_`mu'.tFE.tex"
		
		reghdfe `dv_reg' ///
			`mu' `mu'_key_rate_lag2 `mu'_key_rate_lag1 `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe `dv_reg' ///
			`mu' `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe `dv_reg' `mu' `mu'_key_rate `xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		
		** FIRST DIFFERENCES **
		local tex "reg_iqr_D_Deposit_`mu'.tFE.tex"
		
		reghdfe D_`dv_reg' ///
			`mu' `mu'_D_key_rate_lag2 `mu'_D_key_rate_lag1 `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe D_`dv_reg' ///
			`mu' `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
		
		reghdfe D_`dv_reg' `mu' `mu'_D_key_rate `xctrls_reg_tFE' if oliq_`mu'==0, absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes", "Markup outliers", "IQR")
	}
}






****************************************************************
********** ROBUSTNESS CHECK: FULL DATASET **********************
****************************************************************

** CREDIT MARKUPS **
* Full dataset
foreach mu in m_L m_L_wins {	
	foreach dv in Credit_cond lnL { // Dependent variable
		if "`dv'" == "Credit_cond" {
			local dv_title "Credit cond" // Dependent variable -- for the title
		}
		else if "`dv'" == "lnL" {
			local dv_title "ln Loans"
		}
		
		if inlist("`mu'", "m_L","m_L_CoF") {
			local title "Init"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		else if inlist("`mu'", "m_L_iq","m_L_CoF_iq") {
			local title "IQR"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		else if inlist("`mu'", "m_L_wins","m_L_CoF_wins") {
			local title "Wins"
			local dv_reg `dv'_wins
			local xctrls_reg $xcontrols_wins
			local xctrls_reg_tFE $xcontrols_tFE_wins
		}
		else if inlist("`mu'", "m_L_winsSt","m_L_CoF_winsSt") {
			local title "WinsSt"
			local dv_reg `dv'_winsSt
			local xctrls_reg $xcontrols_winsSt
			local xctrls_reg_tFE $xcontrols_tFE_winsSt
		}
		else if inlist("`mu'", "m_L_noreg","m_L_CoF_noreg") {
			local title "No Reg"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		
		*** ONLY BANK FE ***
		** LEVELS **
		local tex "reg_full_L_Credit_`mu'.tex"
		
		reghdfe `dv_reg' key_rate_lag2 key_rate_lag1 key_rate key_rate_lead1 key_rate_lead2 ///
			`mu' `mu'_key_rate_lag2 `mu'_key_rate_lag1 `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
		
		reghdfe `dv_reg' key_rate key_rate_lead1 key_rate_lead2 ///
			`mu' `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
		
		reghdfe `dv_reg' key_rate `mu' `mu'_key_rate `xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
			
		** FIRST DIFFERENCES **
		local tex "reg_full_D_Credit_`mu'.tex"
		
		reghdfe D_`dv_reg' D_key_rate_lag2 D_key_rate_lag1 D_key_rate D_key_rate_lead1 D_key_rate_lead2 ///
			`mu' `mu'_D_key_rate_lag2 `mu'_D_key_rate_lag1 `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
		
		reghdfe D_`dv_reg' D_key_rate D_key_rate_lead1 D_key_rate_lead2 ///
			`mu' `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
		
		reghdfe D_`dv_reg' D_key_rate `mu' `mu'_D_key_rate `xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
			
			
			
		*** BANK AND TIME FE ***
		** LEVELS **
		local tex "reg_full_L_Credit_`mu'.tFE.tex"
		
		reghdfe `dv_reg' ///
			`mu' `mu'_key_rate_lag2 `mu'_key_rate_lag1 `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
		
		reghdfe `dv_reg' ///
			`mu' `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
		
		reghdfe `dv_reg' `mu' `mu'_key_rate `xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
			
		** FIRST DIFFERENCES **
		local tex "reg_full_D_Credit_`mu'.tFE.tex"
		
		reghdfe D_`dv_reg' ///
			`mu' `mu'_D_key_rate_lag2 `mu'_D_key_rate_lag1 `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
		
		reghdfe D_`dv_reg' ///
			`mu' `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
		
		reghdfe D_`dv_reg' `mu' `mu'_D_key_rate `xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
	}
}



** DEPOSIT MARKUPS **
* Full dataset
foreach mu in m_D_wins {
	foreach dv in Deposit_cond lnD { // Dependent variable
		if "`dv'" == "Deposit_cond" {
			local dv_title "Deposit cond" // Dependent variable name -- for the title
		}
		else if "`dv'" == "lnD" {
			local dv_title "ln Deposits"
		}	
		
		if inlist("`mu'", "m_D","m_L_CoF") {
			local title "Init"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		else if inlist("`mu'", "m_D_iq","m_L_CoF_iq") {
			local title "IQR"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}
		else if inlist("`mu'", "m_D_wins","m_L_CoF_wins") {
			local title "Wins"
			local dv_reg `dv'_wins
			local xctrls_reg $xcontrols_wins
			local xctrls_reg_tFE $xcontrols_tFE_wins
		}
		else if inlist("`mu'", "m_D_winsSt","m_L_CoF_winsSt") {
			local title "Wins"
			local dv_reg `dv'_winsSt
			local xctrls_reg $xcontrols_winsSt
			local xctrls_reg_tFE $xcontrols_tFE_winsSt
		}
		else if inlist("`mu'", "m_D_noreg","m_L_CoF_noreg") {
			local title "No Reg"
			local dv_reg `dv'
			local xctrls_reg $xcontrols
			local xctrls_reg_tFE $xcontrols_tFE
		}

		
		*** ONLY BANK FIXED EFFECTS ***
		** LEVELS **
		local tex "reg_full_L_Deposit_`mu'.tex"
		
		reghdfe `dv_reg' key_rate_lag2 key_rate_lag1 key_rate key_rate_lead1 key_rate_lead2 ///
			`mu' `mu'_key_rate_lag2 `mu'_key_rate_lag1 `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
		
		reghdfe `dv_reg' key_rate key_rate_lead1 key_rate_lead2 ///
			`mu' `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
		
		reghdfe `dv_reg' key_rate `mu' `mu'_key_rate `xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
		
		
		** FIRST DIFFERENCES **
		local tex "reg_full_D_Deposit_`mu'.tex"
		
		reghdfe D_`dv_reg' D_key_rate_lag2 D_key_rate_lag1 D_key_rate D_key_rate_lead1 D_key_rate_lead2 ///
			`mu' `mu'_D_key_rate_lag2 `mu'_D_key_rate_lag1 `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
		
		reghdfe D_`dv_reg' D_key_rate D_key_rate_lead1 D_key_rate_lead2 ///
			`mu' `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
		
		reghdfe D_`dv_reg' D_key_rate `mu' `mu'_D_key_rate `xctrls_reg', absorb(regnum) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "No", "Bank FE", "Yes")
			
		
		*** BANK AND TIME FIXED EFFECTS ***
		** LEVELS **
		local tex "reg_full_L_Deposit_`mu'.tFE.tex"
		
		reghdfe `dv_reg' ///
			`mu' `mu'_key_rate_lag2 `mu'_key_rate_lag1 `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
		
		reghdfe `dv_reg' ///
			`mu' `mu'_key_rate `mu'_key_rate_lead1 `mu'_key_rate_lead2 ///
			`xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
		
		reghdfe `dv_reg' `mu' `mu'_key_rate `xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
		
		
		** FIRST DIFFERENCES **
		local tex "reg_full_D_Deposit_`mu'.tFE.tex"
		
		reghdfe D_`dv_reg' ///
			`mu' `mu'_D_key_rate_lag2 `mu'_D_key_rate_lag1 `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
		
		reghdfe D_`dv_reg' ///
			`mu' `mu'_D_key_rate `mu'_D_key_rate_lead1 `mu'_D_key_rate_lead2 ///
			`xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
		
		reghdfe D_`dv_reg' `mu' `mu'_D_key_rate `xctrls_reg_tFE', absorb(regnum dq) vce(robust)
		outreg2 using "$path_tex/`tex'", tex(pretty) append ///
			ctitle(2017q4-2021q3, `title', `dv_title') ///
			addtext("Time FE", "Yes", "Bank FE", "Yes")
	}
}
