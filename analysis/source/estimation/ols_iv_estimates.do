clear all
set more off
set gr off

local infolder  "raw"
local outfolder "build/estimation"

clear
use `infolder'/qob1

label var earnwkl "Log Weekly Earnings"
label var educ    "Years of Education"

qui tab qob, gen(qob)
forvalues y=1(1)4 {
  label var qob`y' "Born in Q`y'"
}
gen qob234 = qob1==0

* Replicate Table III, Panel B in Angrist & Kruger (QJE 1991)
foreach var in earnwkl educ {

  qui sum    `var' if qob1==1
  local mean_`var'_qob1     = r(mean)
  local  obs_`var'_qob1     = r(N)

  qui sum    `var' if qob234==1
  local mean_`var'_qob234   = r(mean)
  local  obs_`var'_qob234   = r(N)

  qui reg    `var' qob234
  local diff_`var'          = e(b)[1,1]
  local diff_`var'_se       = sqrt(e(V)[1,1])
  local diff_`var'_obs      = e(N)
}

cap file close f
file open   f using "`outfolder'/mean_earnings_schooling.txt", write replace
file write  f "<tab:mean_earnings_schooling>" _n
file write  f  (`mean_earnwkl_qob1') _tab (`mean_earnwkl_qob234')  _tab  (`diff_earnwkl')     _n
file write  f  (`diff_earnwkl_se')   _n
file write  f  (`mean_educ_qob1')    _tab (`mean_educ_qob234')     _tab  (`diff_educ')        _n
file write  f  (`diff_educ_se')      _n
file write  f  (`obs_earnwkl_qob1')  _tab (`obs_earnwkl_qob234')   _tab  (`diff_earnwkl_obs') _n
file close  f


qui reg earnwkl educ
local ols_coef    = e(b)[1,1]
local ols_se      = sqrt(e(V)[1,1])

qui ivregress 2sls earnwkl (educ=qob1)
local wald_coef   = e(b)[1,1]
local wald_se     = sqrt(e(V)[1,1])

qui reg educ qob1
local first_coef  = e(b)[1,1]
local first_se    = sqrt(e(V)[1,1])
qui test qob1
local wald_Fval   = r(F)

* Replicate Table V, Column (2) in Angrist & Kruger (QJE 1991)
qui ivregress 2sls earnwkl i.yob (educ=i.yob#i.qob)
local 2sls_coef   = e(b)[1,1]
local 2sls_se     = sqrt(e(V)[1,1])
qui estat first
local 2sls_Fval   = r(mineig)
qui estat overid
local overid_chi2 = r(sargan)
local overid_dof  = r(df)
local overid_pval = r(p_sargan)

cap file close f
file open   f using "`outfolder'/ols_iv_estimates.txt", write replace
file write  f "<tab:ols_iv_estimates>" _n
file write  f (`ols_coef')    _tab (`wald_coef')  _tab (`2sls_coef')  _n
file write  f (`ols_se')      _tab (`wald_se')    _tab (`2sls_se')    _n
file write  f (`first_coef')  _n
file write  f (`first_se')    _n
file write  f (`wald_Fval')   _tab (`2sls_Fval')  _n
file write  f (`overid_chi2') _n
file write  f (`overid_dof')  _n
file write  f (`overid_pval')
file close  f

clear
