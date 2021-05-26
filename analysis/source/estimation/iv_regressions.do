clear all
set more off
set gr off

clear
use input/qob1

label var earnwkl "Log Weekly Earnings"
label var educ    "Years of Education"

tab qob, gen(qob)
forvalues y=1(1)4 {
  label var qob`y' "Born in Q`y'"
}

* Table III, Panel B
eststo clear
eststo: quietly estpost summarize earnwkl educ if qob1==1
eststo: quietly estpost summarize earnwkl educ if qob1==0
eststo: quietly estpost ttest earnwkl educ, by(qob1) unequal

esttab  using "$res_dir/Table1.tex", label collabels(none) replace ///
        cells("mean(pattern(1 1 0) fmt(5)) b(pattern(0 0 1) fmt(5))" ". se(pattern(0 0 1) par fmt(5))") ///
        title(Mean Earnings and Schooling for 1980 Census -- Men Born 1930--1939\label{Table1}) ///
        mtitles("\makecell{Born in\\1st quarter\\of year}" ///
                "\makecell{Born in\\2nd, 3rd or 4th\\quarter of year}" ///
                "\makecell{Difference\\(std. error)\\(2)-(1)}")

eststo clear
eststo: reg earnwkl educ
eststo: ivregress 2sls earnwkl (educ=qob1)
estat first
eststo: reg educ qob1
quietly test qob1
estadd scalar Fval = r(F)

* Table V, Column (2)
eststo: ivregress 2sls earnwkl i.yob (educ=i.yob#i.qob)
estat   first
estadd  scalar Fval   = r(mineig)
estat   overid
estadd  scalar chi2_s = r(sargan)
estadd  scalar dof    = r(df)
estadd  scalar pval   = r(p_sargan)

esttab using "$res_dir/Table2.tex", ///
  keep(educ qob1) se label replace mtitle("OLS" "Wald" "Wald: First Stage" "2SLS") ///
  title(OLS, Wald, Wald First Stage, and 2SLS Estimates for 1980 Census -- Men Born 1930--1939\label{Table2}) ///
  stats(Fval chi2_s dof pval, labels("1st-Stage \$ F \$-value" "\$ \chi^2 \$-value" "dof" "\$ p \$-value"))

clear
