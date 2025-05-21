**********************************
*** Thesis: Banks Market Power ***
**********************************

/*
Here I estimate markups.
*/

******************
*** Parameters ***
******************
clear all
global path "D:\РЭШ\Research\PostThesis"

* no Winsorization
global datafile "$path\data\var\bankdata_201709-202109_q_var_real_ruo.dta"
global datafile_save "$path\data\var\bankdata_201709-202109_q_var_real_ruo_markups.dta"

* Winsorized (in Python)
global datafile_wins "$path\data\var\bankdata_201709-202109_q_var_real_ruo_wins.dta"
global datafile_wins_save "$path\data\var\bankdata_201709-202109_q_var_real_ruo_wins_markups.dta"

* Winsorized (in Stata)
global datafile_winsStata "$path\data\var\bankdata_201709-202109_q_var_real_ruo_winsStata.dta"
global datafile_winsStata_save "$path\data\var\bankdata_201709-202109_q_var_real_ruo_winsStata_markups.dta"

* Merged results
global datafile_save_final "$path\data\var\bankdata_201709-202109_q_var_result"

* Dependent variables for regressions
global xvar lnL lnD lnQ lnL2 lnD2 lnQ2 lnL_lnD lnL_lnQ lnD_lnQ

********************************
***** 2017-2021 quarterly ******
********************************
* Ending for tex file with tables (regression results)
global endname "_markups_wins"


*** FULL DATASET REGRESSIONS ***
/* Regressions on no Winsorization data */
use "$datafile", clear

* Generate variables for regressions
gen lnNIE = ln(NIE)
gen lnNII = ln(NII)
gen lnL = ln(Loans)
gen lnD = ln(Deposits)
gen lnQ = ln(Securities)

label var lnL "ln(Loans)"
label var lnD "ln(Deposits)"
label var lnQ "ln(Securities)"

gen lnL2 = lnL * lnL
gen lnD2 = lnD * lnD
gen lnQ2 = lnQ * lnQ

gen lnL_lnD = lnL * lnD
gen lnL_lnQ = lnL * lnQ
gen lnD_lnQ = lnD * lnQ

gen lnL_t = lnL * t
gen lnD_t = lnD * t
gen lnQ_t = lnQ * t

gen t2 = t * t


** Marginal expenses from translog function, on full dataset **
xtset regnum dq //quarterly
xtdescribe

reghdfe lnNIE $xvar, absorb(dq regnum) vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) replace ///
	ctitle(2017q4-2021q3, Full, lnNIE) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNIE_L = NIE / Loans * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNIE_D = NIE / Deposits * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

reghdfe lnNII $xvar, absorb(dq regnum) vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
	ctitle(2017q4-2021q3, Full, lnNII) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNII_L = NII / Loans * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNII_D = NII / Deposits * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

gen MNetNIE_L = MNIE_L - MNII_L
gen MNetNIE_D = MNIE_D - MNII_D


label var MNIE_L "Marginal non-interest expenses on Loans"
label var MNIE_D "Marginal non-interest expenses on Deposits"

label var MNII_L "Marginal non-interest income on Loans"
label var MNII_D "Marginal non-interest income on Deposits"

label var MNetNIE_L "Marginal net non-interest expenses on Loans"
label var MNetNIE_D "Marginal net non-interest expenses on Deposits"

* There was an idea to add time trend in the function. Check that time variable is rather irrelevant in the specification. On top of that we use time fixed effects that captures simultaneous movements.
reghdfe lnNIE $xvar t t2 lnL_t lnD_t lnQ_t, absorb(dq regnum) vce(robust)
test t t2 lnL_t lnD_t lnQ_t // Prob > F = 0.8983 (with this probability we could receive regression coefficients if the real coefficients are zero)

reghdfe lnNII $xvar t t2 lnL_t lnD_t lnQ_t, absorb(dq regnum) vce(robust)
test t t2 lnL_t lnD_t lnQ_t // Prob > F = 0.4267

* Even without time fixed effects, the test can't reject zero hypothesis at all for NIE (but can for NII!)
reghdfe lnNIE $xvar t t2 lnL_t lnD_t lnQ_t, absorb(regnum) vce(robust)
test t t2 lnL_t lnD_t lnQ_t // Prob > F = 0.7923

reghdfe lnNII $xvar t t2 lnL_t lnD_t lnQ_t, absorb(regnum) vce(robust)
test t t2 lnL_t lnD_t lnQ_t // Prob > F = 0.0234


** Markups **
gen m_L = PoL / (ruo_q + MNetNIE_L) - 1
gen m_D = ruo_q / (CoF + MNetNIE_D) - 1
gen m_L_CoF = PoL / (CoF + MNetNIE_L) - 1

label var m_L "Credit markup, with RUONIA"
label var m_D "Deposit markup, with RUONIA"
label var m_L_CoF "Credit markup, with Cost of Deposits"

save "$datafile_save", replace



*** IQR REGRESSIONS ***
** Flag outliers (IQR) **
use "$datafile_save", clear
local vars_out lnNIE lnNII lnL lnQ lnD
foreach var in `vars_out' { 
	egen upq_`var' = pctile(`var'), p(75) // by(dq)
	egen loq_`var' = pctile(`var'), p(25) // by(dq)
	egen iqr_`var' = iqr(`var') // , by(dq)
	gen upper_`var' = upq_`var' + 1.5 * iqr_`var'
	gen lower_`var' = loq_`var' - 1.5 * iqr_`var'
	gen oliq_`var'=((`var'<lower_`var')|(`var'>upper_`var'))
	drop upq_`var' loq_`var' iqr_`var' upper_`var' lower_`var'
}

gen oliq = 0
replace oliq = 1 if oliq_lnL==1 | oliq_lnD==1 | oliq_lnQ==1 | oliq_lnNIE==1 | oliq_lnNII==1 
label var oliq "Dummy: outlier by IQR"

** Marginal expenses from translog function, on full dataset **
reghdfe lnNIE $xvar if oliq==0, absorb(dq regnum) vce(robust)
//outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
//	ctitle(2017q4-2021q3, IQR, lnNIE) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNIE_L_iq = NIE / Loans * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ) if oliq==0
gen MNIE_D_iq = NIE / Deposits * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ) if oliq==0

reghdfe lnNII $xvar if oliq==0, absorb(dq regnum) vce(robust)
//outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
//	ctitle(2017q4-2021q3, IQR, lnNII) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNII_L_iq = NII / Loans * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ) if oliq==0
gen MNII_D_iq = NII / Deposits * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ) if oliq==0

gen MNetNIE_L_iq = MNIE_L_iq - MNII_L_iq
gen MNetNIE_D_iq = MNIE_D_iq - MNII_D_iq

** Markups **
gen m_L_iq = PoL / (ruo_q + MNetNIE_L_iq) - 1
gen m_D_iq = ruo_q / (CoF + MNetNIE_D_iq) - 1
gen m_L_CoF_iq = PoL / (CoF + MNetNIE_L_iq) - 1

label var MNIE_L_iq "Marginal non-interest expenses on Loans, IQR outliers deleted"
label var MNIE_D_iq "Marginal non-interest expenses on Deposits, IQR outliers deleted"

label var MNII_L_iq "Marginal non-interest income on Loans, IQR outliers deleted"
label var MNII_D_iq "Marginal non-interest income on Deposits, IQR outliers deleted"

label var MNetNIE_L_iq "Marginal net non-interest expenses on Loans, IQR outliers deleted"
label var MNetNIE_D_iq "Marginal net non-interest expenses on Deposits, IQR outliers deleted"

label var m_L_iq "Credit markup, with RUONIA, IQR outliers deleted"
label var m_D_iq "Deposit markup, with RUONIA, IQR outliers deleted"
label var m_L_CoF_iq "Credit markup, with Cost of Deposits, IQR outliers deleted"

//order m_L m_L_oliq m_D m_D_oliq
//summarize m_L m_L_oliq m_D m_D_oliq, detail
//save "$path\var\bankdata_201709-202109_q_var_result_oliq.dta", replace
//drop lnNIE lnNII lnL lnD lnQ lnL2 lnD2 lnQ2 lnL_lnD lnL_lnQ lnD_lnQ lnL_t lnD_t lnQ_t

save "$datafile_save", replace



*** NO REGRESSION MARKUPS ***
** Markups calculated with no regression estimation **
gen m_L_noreg = PoL / ruo_q - 1
gen m_D_noreg = ruo_q / CoF - 1
gen m_L_CoF_noreg = PoL / CoF - 1

label var m_L_noreg "Credit markup, with RUONIA, no regression"
label var m_D_noreg "Deposit markup, with RUONIA, no regression"
label var m_L_CoF_noreg "Credit markup, with Cost of Deposists, no regression"

save "$datafile_save", replace



*** WINSORISED (Python) DATASET REGRESSIONS ***
use "$datafile_wins", clear

* Generate variables for regressions
gen lnNIE = ln(NIE_wins)
gen lnNII = ln(NII_wins)
gen lnL = ln(Loans_wins)
gen lnD = ln(Deposits_wins)
gen lnQ = ln(Securities_wins)

label var lnNIE "ln(NIE_wins)"
label var lnNII "ln(NII_wins)"
label var lnL "ln(Loans_wins)"
label var lnD "ln(Deposits_wins)"
label var lnQ "ln(Securities_wins)"

gen lnL2 = lnL * lnL
gen lnD2 = lnD * lnD
gen lnQ2 = lnQ * lnQ

gen lnL_lnD = lnL * lnD
gen lnL_lnQ = lnL * lnQ
gen lnD_lnQ = lnD * lnQ

gen lnL_t = lnL * t
gen lnD_t = lnD * t
gen lnQ_t = lnQ * t


** Marginal expenses **
reghdfe lnNIE $xvar, absorb(dq regnum) // vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
	ctitle(2017q4-2021q3, Wins, lnNIE) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNIE_L_wins = NIE_wins / Loans_wins * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNIE_D_wins = NIE_wins / Deposits_wins * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

reghdfe lnNII $xvar, absorb(dq regnum) vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
	ctitle(2017q4-2021q3, Wins, lnNII) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNII_L_wins = NII_wins / Loans_wins * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNII_D_wins = NII_wins / Deposits_wins * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

gen MNetNIE_L_wins = MNIE_L_wins - MNII_L_wins
gen MNetNIE_D_wins = MNIE_D_wins - MNII_D_wins

** Markups **
gen m_L_wins = PoL_wins / (ruo_q + MNetNIE_L_wins) - 1
gen m_D_wins = ruo_q / (CoF_wins + MNetNIE_D_wins) - 1
gen m_L_CoF_wins = PoL_wins / (CoF_wins + MNetNIE_L_wins) - 1

label var MNIE_L_wins "Marginal non-interest expenses on Loans, Winsorised"
label var MNIE_D_wins "Marginal non-interest expenses on Deposits, Winsorised"

label var MNII_L_wins "Marginal non-interest income on Loans, Winsorised"
label var MNII_D_wins "Marginal non-interest income on Deposits, Winsorised"

label var MNetNIE_L_wins "Marginal net non-interest expenses on Loans, Winsorised"
label var MNetNIE_D_wins "Marginal net non-interest expenses on Deposits, Winsorised"

label var m_L_wins "Credit markup, with RUONIA, Winsorised"
label var m_D_wins "Deposit markup, with RUONIA, Winsorised"
label var m_L_CoF_wins "Credit markup, with Cost of Deposits, Winsorised"

drop MNIE_L_wins MNIE_D_wins MNII_L_wins MNII_D_wins MNetNIE_L_wins MNetNIE_D_wins


********************************
*** TREND (ROBUSTNESS CHECK) ***
********************************
global tvar lnL_t lnD_t lnQ_t

** Marginal expenses **
reghdfe lnNIE $xvar $tvar, absorb(dq regnum) // vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
	ctitle(2017q4-2021q3, Wins, lnNIE) addtext("Time FE", "Yes", "Bank FE", "Yes")
test $tvar
/*
 ( 1)  lnL_t = 0
 ( 2)  lnD_t = 0
 ( 3)  lnQ_t = 0

       F(  3,   542) =    0.22
            Prob > F =    0.8839
*/

gen MNIE_L_wins = NIE_wins / Loans_wins * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNIE_D_wins = NIE_wins / Deposits_wins * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

reghdfe lnNII $xvar $tvar, absorb(dq regnum) vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
	ctitle(2017q4-2021q3, Wins, lnNII) addtext("Time FE", "Yes", "Bank FE", "Yes")
test $tvar
/*
 ( 1)  lnL_t = 0
 ( 2)  lnD_t = 0
 ( 3)  lnQ_t = 0

       F(  3,   548) =    1.12
            Prob > F =    0.3387
*/

gen MNII_L_wins = NII_wins / Loans_wins * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNII_D_wins = NII_wins / Deposits_wins * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

gen MNetNIE_L_wins = MNIE_L_wins - MNII_L_wins
gen MNetNIE_D_wins = MNIE_D_wins - MNII_D_wins

** Markups **
gen m_L_wins_trend = PoL_wins / (ruo_q + MNetNIE_L_wins) - 1
gen m_D_wins_trend = ruo_q / (CoF_wins + MNetNIE_D_wins) - 1
//gen m_L_CoF_wins_trend = PoL_wins / (CoF_wins + MNetNIE_L_wins) - 1

label var m_L_wins_trend "Credit markup, with RUONIA, Winsorised, time trend"
label var m_D_wins_trend "Deposit markup, with RUONIA, Winsorised, time trend"
//label var m_L_CoF_wins_break "Credit markup, with Cost of Deposits, Winsorised, COVID break"

drop MNIE_L_wins MNIE_D_wins MNII_L_wins MNII_D_wins MNetNIE_L_wins MNetNIE_D_wins

**************************************
*** COVID BREAK (ROBUSTNESS CHECK) ***
**************************************
gen D2020 = 0
replace D2020 = 1 if quarter > "2020q1"

global xvar_break c.D2020#c.lnL c.D2020#c.lnD c.D2020#c.lnQ c.D2020#c.lnL2 c.D2020#c.lnD2 c.D2020#c.lnQ2 c.D2020#c.lnL_lnD c.D2020#c.lnL_lnQ c.D2020#c.lnD_lnQ

reghdfe lnNIE $xvar $xvar_break, absorb(dq regnum) // vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
	ctitle(2017q4-2021q3, Wins, lnNIE) addtext("Time FE", "Yes", "Bank FE", "Yes")
test $xvar_break
	
gen MNIE_L_wins = NIE_wins / Loans_wins * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ  ///
	+ _b[c.D2020#c.lnL]*D2020 + 2*_b[c.D2020#c.lnL2]*D2020 * lnL + _b[c.D2020#c.lnL_lnD]*D2020 * lnD + _b[c.D2020#c.lnL_lnQ]*D2020 * lnQ)
gen MNIE_D_wins = NIE_wins / Deposits_wins * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ ///
	+ _b[c.D2020#c.lnD]*D2020 + 2*_b[c.D2020#c.lnD2]*D2020 * lnD + _b[c.D2020#c.lnL_lnD]*D2020 * lnL + _b[c.D2020#c.lnD_lnQ]*D2020 * lnQ)

reghdfe lnNII $xvar $xvar_break, absorb(dq regnum) // vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
	ctitle(2017q4-2021q3, Wins, lnNII) addtext("Time FE", "Yes", "Bank FE", "Yes")
test $xvar_break
	
gen MNII_L_wins = NII_wins / Loans_wins * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ ///
	+ _b[c.D2020#c.lnL]*D2020 + 2*_b[c.D2020#c.lnL2]*D2020 * lnL + _b[c.D2020#c.lnL_lnD]*D2020 * lnD + _b[c.D2020#c.lnL_lnQ]*D2020 * lnQ)
gen MNII_D_wins = NII_wins / Deposits_wins * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ ///
	+ _b[c.D2020#c.lnD]*D2020 + 2*_b[c.D2020#c.lnD2]*D2020 * lnD + _b[c.D2020#c.lnL_lnD]*D2020 * lnL + _b[c.D2020#c.lnD_lnQ]*D2020 * lnQ)

gen MNetNIE_L_wins = MNIE_L_wins - MNII_L_wins
gen MNetNIE_D_wins = MNIE_D_wins - MNII_D_wins

** Markups **
gen m_L_wins_break = PoL_wins / (ruo_q + MNetNIE_L_wins) - 1
gen m_D_wins_break = ruo_q / (CoF_wins + MNetNIE_D_wins) - 1
//gen m_L_CoF_wins_break = PoL_wins / (CoF_wins + MNetNIE_L_wins) - 1

label var m_L_wins_break "Credit markup, with RUONIA, Winsorised, COVID break"
label var m_D_wins_break "Deposit markup, with RUONIA, Winsorised, COVID break"
//label var m_L_CoF_wins_break "Credit markup, with Cost of Deposits, Winsorised, COVID break"

drop MNIE_L_wins MNIE_D_wins MNII_L_wins MNII_D_wins MNetNIE_L_wins MNetNIE_D_wins
drop lnNIE lnNII lnL lnD lnQ lnL2 lnD2 lnQ2 lnL_lnD lnL_lnQ lnD_lnQ lnL_t lnD_t lnQ_t

save "$datafile_wins_save", replace



*** WINSORISED (Stata) DATASET REGRESSIONS ***
use "$datafile_winsStata", clear

* Generate variables for regressions
gen lnNIE = ln(NIE_winsSt)
gen lnNII = ln(NII_winsSt)
gen lnL = ln(Loans_winsSt)
gen lnD = ln(Deposits_winsSt)
gen lnQ = ln(Securities_winsSt)

label var lnNIE "ln(NIE_wins)"
label var lnNII "ln(NII_wins)"
label var lnL "ln(Loans_wins)"
label var lnD "ln(Deposits_wins)"
label var lnQ "ln(Securities_wins)"

gen lnL2 = lnL * lnL
gen lnD2 = lnD * lnD
gen lnQ2 = lnQ * lnQ

gen lnL_lnD = lnL * lnD
gen lnL_lnQ = lnL * lnQ
gen lnD_lnQ = lnD * lnQ

gen lnL_t = lnL * t
gen lnD_t = lnD * t
gen lnQ_t = lnQ * t


** Marginal expenses **
reghdfe lnNIE $xvar, absorb(dq regnum) vce(robust)
//outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
//	ctitle(2017q4-2021q3, WinsSt, lnNIE) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNIE_L_winsSt = NIE_winsSt / Loans_winsSt * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNIE_D_winsSt = NIE_winsSt / Deposits_winsSt * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

reghdfe lnNII $xvar, absorb(dq regnum) vce(robust)
//outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
//	ctitle(2017q4-2021q3, WinsSt, lnNII) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNII_L_winsSt = NII_winsSt / Loans_winsSt * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNII_D_winsSt = NII_winsSt / Deposits_winsSt * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

gen MNetNIE_L_winsSt = MNIE_L_winsSt - MNII_L_winsSt
gen MNetNIE_D_winsSt = MNIE_D_winsSt - MNII_D_winsSt

** Markups **
gen m_L_winsSt = PoL_winsSt / (ruo_q + MNetNIE_L_winsSt) - 1
gen m_D_winsSt = ruo_q / (CoF_wins + MNetNIE_D_winsSt) - 1
gen m_L_CoF_winsSt = PoL_winsSt / (CoF_winsSt + MNetNIE_L_winsSt) - 1

label var MNIE_L_winsSt "Marginal non-interest expenses on Loans, Winsorised in Stata"
label var MNIE_D_winsSt "Marginal non-interest expenses on Deposits, Winsorised in Stata"

label var MNII_L_winsSt "Marginal non-interest income on Loans, Winsorised in Stata"
label var MNII_D_winsSt "Marginal non-interest income on Deposits, Winsorised in Stata"

label var MNetNIE_L_winsSt "Marginal net non-interest expenses on Loans, Winsorised in Stata"
label var MNetNIE_D_winsSt "Marginal net non-interest expenses on Deposits, Winsorised in Stata"

label var m_L_winsSt "Credit markup, with RUONIA, Winsorised in Stata"
label var m_D_winsSt "Deposit markup, with RUONIA, Winsorised in Stata"
label var m_L_CoF_winsSt "Credit markup, with Cost of Deposits, Winsorised in Stata"

drop lnNIE lnNII lnL lnD lnQ lnL2 lnD2 lnQ2 lnL_lnD lnL_lnQ lnD_lnQ lnL_t lnD_t lnQ_t
save "$datafile_winsStata_save", replace


*** MERGE AND CREATE THE FINAL RESULT DATASET ***
use "$datafile_save", clear
merge 1:1 regnum dq using "$datafile_wins_save", nogenerate ///
	keepusing(NIE_wins NII_wins Loans_wins Deposits_wins ///
	II_Loans_wins IE_Deposits_wins Securities_wins ///
	m_L_wins m_D_wins m_L_CoF_wins m_L_wins_trend m_D_wins_trend m_L_wins_break m_D_wins_break)
merge 1:1 regnum dq using "$datafile_winsStata_save", nogenerate ///
	keepusing(NIE_winsSt NII_winsSt Loans_winsSt Deposits_winsSt ///
	II_Loans_winsSt IE_Deposits_winsSt Securities_winsSt ///
	m_L_winsSt m_D_winsSt m_L_CoF_winsSt)

drop ln* t2 MNIE_* MNII_* MNetNIE_*
sort regnum dq	
	
save "$datafile_save_final.dta", replace


*** HHI ***
use "$datafile_save_final.dta", clear
sort dq regnum
by dq: egen Total_Sales = total(Sales)
gen S = Sales / Total_Sales
by dq: egen HHI = total(S*S)
drop Total_Sales S
label var HHI "Herfindahl-Hirschman index"

/*
gen lnSales = ln(Sales)
local vars_out lnSales
foreach var in `vars_out' { 
	egen upq_`var' = pctile(`var'), p(75) // by(dq)
	egen loq_`var' = pctile(`var'), p(25) // by(dq)
	egen iqr_`var' = iqr(`var') // , by(dq)
	gen upper_`var' = upq_`var' + 1.5 * iqr_`var'
	gen lower_`var' = loq_`var' - 1.5 * iqr_`var'
	gen oliq_`var'=((`var'<lower_`var')|(`var'>upper_`var'))
	drop upq_`var' loq_`var' iqr_`var' upper_`var' lower_`var'
}
by dq: egen Total_Sales_iq = total(Sales) if oliq_lnSales==0
gen S = Sales / Total_Sales_iq if oliq_lnSales==0
by dq: egen HHI_iq =  total(S*S) if oliq_lnSales==0
*/

/*
by dq: egen Total_Sales_iq = total(Sales) if oliq==0
gen S_iq = Sales / Total_Sales_iq if oliq==0
by dq: egen HHI_iq = total(S_iq*S_iq) if oliq==0
drop Total_Sales_iq S_iq
label var HHI_iq "Herfindahl-Hirschman index, IQR outliers deleted"
*/

sort regnum dq	
save "$datafile_save_final.dta", replace




*** PREPARE VARIABLES FOR FURTHER REGRESSIONS ***
use "$datafile_save_final.dta", clear

** Variables **
gen lnL = ln(Loans)
gen lnD = ln(Deposits)
gen Capital_ratio = Net_worth / Total_assets
gen Liquidity_ratio = Cash / Total_assets
gen Core_deposits = Deposits / Liabilities
gen Credit_cond = II_Loans / Loans * 100
gen Deposit_cond = IE_Deposits / Deposits * 100
//gen Deposit_spread = ruo - Deposit_cond

label var lnL "ln(Loans)"
label var lnD "ln(Deposits)"
label var Capital_ratio "Net worth to Total assets, control for bank ability to provide loans"
label var Liquidity_ratio "Cash to Total assets, control for bank ability to provide loans"
label var Core_deposits "Deposits to Total Liabilities, control for bank abilities to provide loans"
label var Credit_cond "Interest income on Loans to Total Loans in %, proxy for Loan interest rates"
label var Deposit_cond "Interest expenses on Deposits to Total Deposits in %, proxy for Deposit interest rates"


gen lnL_wins = ln(Loans_wins)
gen lnD_wins = ln(Deposits_wins)
gen Core_deposits_wins = Deposits_wins / Liabilities
gen Credit_cond_wins = II_Loans_wins / Loans_wins *100
gen Deposit_cond_wins = IE_Deposits_wins / Deposits_wins * 100
//gen Deposit_spread_wins = ruo - Deposit_cond_wins

label var lnL_wins "ln(Loans), on Winsorized data"
label var lnD_wins "ln(Deposits), on Winsorized data"
label var Core_deposits_wins "Deposits to Total Liabilities, on Winsorized data"
label var Credit_cond_wins "Interest income on Loans to Total Loans in %, on Winsorized data"
label var Deposit_cond_wins "Interest expenses on Deposits to Total Deposits in %, on Winsorized data"


gen lnL_winsSt = ln(Loans_winsSt)
gen lnD_winsSt = ln(Deposits_winsSt)
gen Core_deposits_winsSt = Deposits_winsSt / Liabilities
gen Credit_cond_winsSt = II_Loans_winsSt / Loans_winsSt *100
gen Deposit_cond_winsSt = IE_Deposits_winsSt / Deposits_winsSt * 100
//gen Deposit_spread_winsSt = ruo - Deposit_cond_winsSt

label var lnL_winsSt "ln(Loans), on Stata Winsorized data"
label var lnD_winsSt "ln(Deposits), on Winsorized data"
label var Core_deposits_winsSt "Deposits to Total Liabilities, on Stata Winsorized data"
label var Credit_cond_winsSt "Interest income on Loans to Total Loans in %, on Stata Winsorized data"
label var Deposit_cond_winsSt "Interest expenses on Deposits to Total Deposits in %, on Stata Winsorized data"


** Flag outliers **
local vars_out m_D m_L m_D_noreg m_L_noreg m_D_wins m_L_wins m_D_winsSt m_L_winsSt ///
	m_L_CoF m_L_CoF_wins m_L_CoF_winsSt m_L_CoF_noreg m_D_iq m_L_iq ///
	m_L_wins_trend m_D_wins_trend m_L_wins_break m_D_wins_break

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

sort regnum dq	
	
//save "$datafile_save_final.dta", replace
//export delimited "$datafile_save_final.csv", replace

//save "$datafile_save_final", replace
//export excel "$path\data\var\bankdata_201709-202109_q_var_result.xlsx", firstrow(var) replace
//export delimited "$path\data\var\bankdata_201709-202109_q_var_result.csv", replace

save "$datafile_save_final.dta", replace
export delimited "$datafile_save_final.csv", replace
export excel "$datafie_save_final.xlsx", replace



/*

***************************
**** ROBUSTNESS CHECK *****
*** 2017-2019 quarterly ***
***************************
clear all
global path "D:\РЭШ\Research\PostThesis"

* no Winsorization
global datafile "$path\data\var\bankdata_201709-202109_q_var_real_ruo.dta"
global datafile_save "$path\data\var\bankdata_201709-201912_q_var_real_ruo_markups.dta"

* Winsorized (in Python)
global datafile_wins "$path\data\var\bankdata_201709-202109_q_var_real_ruo_wins.dta"
global datafile_wins_save "$path\data\var\bankdata_201709-201912_q_var_real_ruo_wins_markups.dta"

* Winsorized (in Stata)
global datafile_winsStata "$path\data\var\bankdata_201709-202109_q_var_real_ruo_winsStata.dta"
global datafile_winsStata_save "$path\data\var\bankdata_201709-201912_q_var_real_ruo_winsStata_markups.dta"

* Merged results
global datafile_save_final "$path\data\var\bankdata_201709-201912_q_var_result.dta"

* Dependent variables for regressions
global xvar lnL lnD lnQ lnL2 lnD2 lnQ2 lnL_lnD lnL_lnQ lnD_lnQ


* Ending for tex file with tables (regression results)
global endname "_markups_wins"

*** WINSORISED (Python) DATASET REGRESSIONS ***
use "$datafile_wins", clear
keep if quarter <= "2019q4"

* Generate variables for regressions
gen lnNIE = ln(NIE_wins)
gen lnNII = ln(NII_wins)
gen lnL = ln(Loans_wins)
gen lnD = ln(Deposits_wins)
gen lnQ = ln(Securities_wins)

label var lnNIE "ln(NIE_wins)"
label var lnNII "ln(NII_wins)"
label var lnL "ln(Loans_wins)"
label var lnD "ln(Deposits_wins)"
label var lnQ "ln(Securities_wins)"

gen lnL2 = lnL * lnL
gen lnD2 = lnD * lnD
gen lnQ2 = lnQ * lnQ

gen lnL_lnD = lnL * lnD
gen lnL_lnQ = lnL * lnQ
gen lnD_lnQ = lnD * lnQ

gen lnL_t = lnL * t
gen lnD_t = lnD * t
gen lnQ_t = lnQ * t


** Marginal expenses **
reghdfe lnNIE $xvar, absorb(dq regnum) // vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
	ctitle(2017q4-2019q4, Wins, lnNIE) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNIE_L_wins = NIE_wins / Loans_wins * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNIE_D_wins = NIE_wins / Deposits_wins * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

reghdfe lnNII $xvar, absorb(dq regnum) vce(robust)
outreg2 using "$path/reg_res/reg$endname.tex", tex(pretty) ///
	ctitle(2017q4-2019q4, Wins, lnNII) addtext("Time FE", "Yes", "Bank FE", "Yes")

gen MNII_L_wins = NII_wins / Loans_wins * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD + _b[lnL_lnQ] * lnQ)
gen MNII_D_wins = NII_wins / Deposits_wins * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL + _b[lnD_lnQ] * lnQ)

gen MNetNIE_L_wins = MNIE_L_wins - MNII_L_wins
gen MNetNIE_D_wins = MNIE_D_wins - MNII_D_wins

** Markups **
gen m_L_wins = PoL_wins / (ruo_q + MNetNIE_L_wins) - 1
gen m_D_wins = ruo_q / (CoF_wins + MNetNIE_D_wins) - 1
gen m_L_CoF_wins = PoL_wins / (CoF_wins + MNetNIE_L_wins) - 1

label var MNIE_L_wins "Marginal non-interest expenses on Loans, Winsorised"
label var MNIE_D_wins "Marginal non-interest expenses on Deposits, Winsorised"

label var MNII_L_wins "Marginal non-interest income on Loans, Winsorised"
label var MNII_D_wins "Marginal non-interest income on Deposits, Winsorised"

label var MNetNIE_L_wins "Marginal net non-interest expenses on Loans, Winsorised"
label var MNetNIE_D_wins "Marginal net non-interest expenses on Deposits, Winsorised"

label var m_L_wins "Credit markup, with RUONIA, Winsorised"
label var m_D_wins "Deposit markup, with RUONIA, Winsorised"
label var m_L_CoF_wins "Credit markup, with Cost of Deposits, Winsorised"

drop lnNIE lnNII lnL lnD lnQ lnL2 lnD2 lnQ2 lnL_lnD lnL_lnQ lnD_lnQ lnL_t lnD_t lnQ_t

*/

















/*
gen m_L_key_rate = m_L * key_rate
gen m_D_key_rate = m_D * key_rate

gen m_L_iq_key_rate = m_L_iq * key_rate
gen m_D_iq_key_rate = m_D_iq * key_rate

gen m_L_noreg_key_rate = m_L_noreg * key_rate
gen m_D_noreg_key_rate = m_D_noreg * key_rate

gen m_L_wins_key_rate = m_L_wins * key_rate
gen m_D_wins_key_rate = m_D_wins * key_rate
*/


/*
*** Delete outliers and exclude securities ***
use "$path\var\bankdata_201709-202109_q_var_result.dta", clear
local vars_out lnNIE lnNII lnL lnD
foreach var in `vars_out' { 
	egen upq_`var' = pctile(`var'), p(75) // by(dq)
	egen loq_`var' = pctile(`var'), p(25) // by(dq)
	egen iqr_`var' = iqr(`var') // , by(dq)
	gen upper_`var' = upq_`var' + 1.5 * iqr_`var'
	gen lower_`var' = loq_`var' - 1.5 * iqr_`var'
	gen oliq_`var'=((`var'<lower_`var')|(`var'>upper_`var'))
	drop upq_`var' loq_`var' iqr_`var' upper_`var' lower_`var'
}
foreach var in `vars_out' {
	keep if oliq_`var' == 0
}

global xvar lnL lnD lnL2 lnD2 lnL_lnD

reghdfe lnNIE $xvar, absorb(dq regnum) vce(robust)

gen MNIE_L_oliq = NIE / Loans * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD)
gen MNIE_D_oliq = NIE / Deposits * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL)

reghdfe lnNII $xvar, absorb(dq regnum) vce(robust)

gen MNII_L_oliq = NII / Loans * (_b[lnL] + 2*_b[lnL2] * lnL +  _b[lnL_lnD] * lnD)
gen MNII_D_oliq = NII / Deposits * (_b[lnD] + 2*_b[lnD2] * lnD + _b[lnL_lnD] * lnL)

gen MNetNIE_L_oliq = MNIE_L_oliq - MNII_L_oliq
gen MNetNIE_D_oliq = MNIE_D_oliq - MNII_D_oliq


label var MNIE_L_oliq "Marginal non-interest expenses on Loans, IQR outliers deleted"
label var MNIE_D_oliq "Marginal non-interest expenses on Deposits, IQR outliers deleted"

label var MNII_L_oliq "Marginal non-interest income on Loans, IQR outliers deleted"
label var MNII_D_oliq "Marginal non-interest income on Deposits, IQR outliers deleted"

label var MNetNIE_L_oliq "Marginal net non-interest expenses on Loans, IQR outliers deleted"
label var MNetNIE_D_oliq "Marginal net non-interest expenses on Deposits, IQR outliers deleted"

gen m_L_oliq = PoL / (ruo_q + MNetNIE_L_oliq)
gen m_D_oliq = ruo_q / (CoF + MNetNIE_D_oliq)

order m_L m_L_oliq m_D m_D_oliq

summarize m_L m_L_oliq m_D m_D_oliq, detail
*/

/*
*** Standardisation ***
use "$path\var\bankdata_201709-202109_q_var_result.dta", clear
// x' = (x-mean(x))/std(x)
foreach v in lnNIE lnNII lnL lnD lnQ lnL2 lnD2 lnQ2 lnL_lnD lnL_lnQ lnD_lnQ {
	summarize `v'
	gen `v'_mean = r(mean) 
	gen `v'_sd = r(sd)
	gen `v'_s = (`v' - r(mean)) / r(sd)
}

global xvar_s lnL_s lnD_s lnQ_s lnL2_s lnD2_s lnQ2_s lnL_lnD_s lnL_lnQ_s lnD_lnQ_s

reghdfe lnNIE_s $xvar_s , absorb(dq regnum) vce(robust)

gen MNIE_L_s = NIE / Loans * (_b[lnL_s] / lnL_sd + 2*_b[lnL2_s] / lnL2_sd * lnL +  _b[lnL_lnD_s] / lnL_lnD_sd * lnD + _b[lnL_lnQ_s] / lnL_lnQ_sd * lnQ) * lnNIE_sd
gen MNIE_D_s = NIE / Deposits * (_b[lnD_s] / lnD_sd + 2*_b[lnD2_s] / lnD2_sd * lnD + _b[lnL_lnD_s] / lnL_lnD_sd * lnL + _b[lnD_lnQ_s] / lnD_lnQ_sd * lnQ) * lnNIE_sd

reghdfe lnNII_s $xvar_s, absorb(dq regnum) vce(robust)
gen MNII_L_s = NII / Loans * (_b[lnL_s] / lnL_sd + 2*_b[lnL2_s] / lnL2_sd * lnL +  _b[lnL_lnD_s] / lnL_lnD_sd * lnD + _b[lnL_lnQ_s] / lnL_lnQ_sd * lnQ) * lnNII_sd
gen MNII_D_s = NII / Deposits * (_b[lnD_s] / lnD_sd + 2*_b[lnD2_s] / lnD2_sd * lnD + _b[lnL_lnD_s] / lnL_lnD_sd * lnL + _b[lnD_lnQ_s] / lnD_lnQ_sd * lnQ) * lnNII_sd

gen MNetNIE_L_s = MNIE_L - MNII_L
gen MNetNIE_D_s = MNIE_D - MNII_D

gen m_L_s = PoL / (ruo_q + MNetNIE_L)
gen m_D_s = ruo_q / (CoF + MNetNIE_D)

order m_L m_L_s m_D m_D_s
*/

