clear all
set more off
set gr off

local infolder  "raw"
local outfolder "build/descriptive"

clear
use `infolder'/qob1.dta

gen yob1=1900+yob+(qob-1)/4

* Mean years of education by YOB and QOB
preserve
  gcollapse (mean) educ qob, by(yob1)
  twoway  connected educ yob1 ///
    , mlabel(qob) ytitle("Years of Completed Education")  ///
    xtitle("Year of birth") graphregion(color(white))     ///
    ylabel(, angle(horizontal))
  graph export "`outfolder'/education_by_yob_qob.eps", replace
  graph export "`outfolder'/education_by_yob_qob.png", replace
restore

* Mean years of education by QOB
preserve
  gcollapse (mean) educ, by(qob)
  twoway ///
    (bar educ qob, barw(.6) base(12.65)) ///
    (scatter educ qob, msym(none) mlab(educ) mlabpos(12) mlabcolor(black) mlabsize(vsmall))       ///
    , graphregion(color(white)) ytitle("Years of Completed Education") xtitle("Quarter of Birth") ///
    ylabel(, angle(hor)) legend(off)
  graph export "`outfolder'/education_by_qob.eps", replace
  graph export "`outfolder'/education_by_qob.png", replace
restore

* Mean years of education by QOB, only those with <12 years of education
preserve
  gcollapse  (mean) educ if educ<12, by(qob)
  twoway ///
    (bar educ qob, barw(.6) base(8.55)) ///
    (scatter educ qob, msym(none) mlab( educ) mlabpos(12) mlabcolor(black) mlabsize(vsmall))      ///
    , graphregion(color(white)) ytitle("Years of Completed Education") xtitle("Quarter of Birth") ///
    ylabel(, angle(hor)) legend(off)
  graph export "`outfolder'/education_by_qob_lessthan12.eps", replace
  graph export "`outfolder'/education_by_qob_lessthan12.png", replace
restore

* Mean years of education by QOB, only those with more than 12+ years of education
preserve
  collapse (mean) educ if educ>=12, by(qob)
  twoway  (bar educ qob, barw(.6) base(13.97)) ///
    (scatter educ qob, msym(none) mlab(educ) mlabpos(12) mlabcolor(black) mlabsize(vsmall)), ///
    graphregion(color(white)) ytitle("Years of Completed Education") xtitle("Quarter of Birth") ///
    ylabel(, angle(hor)) legend(off)
  graph export "`outfolder'/education_by_qob_12plus.eps", replace
  graph export "`outfolder'/education_by_qob_12plus.png", replace
restore

clear
