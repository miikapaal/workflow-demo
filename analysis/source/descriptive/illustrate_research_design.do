*------------------------------------------------------------------------------*
/*-----------------------------------------------------------------------------*
Miika Päällysaho
miika.paallysaho@ne.su.se
2021-02-04

Econometrics 2
Assignment 2: Instrumental Variables
Suggested Solutions

This do-file contains the Stata code for answering the questions included in
the "Empirical Exercises" part of Assignment 2.

Note: Uses Stata v. 16.0

*-----------------------------------------------------------------------------*/
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
*--------------------------- (1) Preparations ---------------------------------*
*------------------------------------------------------------------------------*
clear all                         // Remove anything old stored
set more off, permanently         // Tell Stata not to pause
set gr   off                      // Tell Stata not to display plots
version                           // Check the version of the command interpreter

// Install necessary packages:
// (Note: Run "which XXX" to check a given package/command is already installed.)
ssc install estout, replace       // estout: Used here to create regression tables.
ssc install binscatter, replace   // binscatter: User-written command for creating scatterplots and event-study graphs
*ssc install outreg, replace      // outreg (not used here): Another package to create regression tables.
*ssc install ivreg2, replace      // ivreg2 (not used here): User-written alternative to Stata's official ivregress

// Directory shortcuts:
global main_dir "~/Dropbox/TA/EC7411-TA/2-IV"                 // Shortcut for the main directory
global data_dir "$main_dir/Data"                              // Shortcut for the data directory
global res_dir  "$main_dir/Results"                           // Shortcut for the results directory

// Tip: Using "cap" (shorthand for "capture") before a command
//    doesn't cause Stata to stop running a do-file despite errors.
// While this is at times very useful, use it with caution, since it may mask informative error messages.
cap log close // Close a log-file (if there's one open).
log using "$res_dir/Assignment2.log", replace

*------------------------------------------------------------------------------*
*--------------------------- (2) Empirical Exercises --------------------------*
*------------------------------------------------------------------------------*
use "$data_dir/qob1.dta", clear           // Load the dataset.
desc                                      // Check which variables are included
label var earnwkl "Log Weekly Earnings"   // For convenience, relabel a couple of variables
label var educ    "Years of Education"

*------------------------------------------------------------------------------*
*-------- Q1: Visualizing the Research Design
gen yob1=1900+yob+(qob-1)/4               // Create a year*qob variable taking values 1930, 1930.25, 1930.5, etc.

// Method #1: Using the user-written "binscatter" command:
// Unfortunately, "binscatter" does not seem to allow adding the "qob"-labels to the graph...
// See: https://www.stata.com/meeting/boston14/abstracts/materials/boston14_stepner.pdf
binscatter educ yob1, line(connect) yscale(range(12.2,13.2)) discrete ///
    graphregion(color(white)) ytitle("Years of Completed Education")  ///
    xtitle("Year of birth")

// Method #2: Collapse the data at yob*qob level using the yob1-variable created above,
// and plot the group means against the yob1 variable:
preserve
  collapse (mean) educ qob, by(yob1)
  twoway connected educ yob1, ///
          mlabel(qob) ytitle("Years of Completed Education") ///
          xtitle("Year of birth") graphregion(color(white))  ///
          ylabel(, angle(horizontal))
  graph export "$res_dir/Figure1.pdf", replace
restore

// Additional results that can be used to show the impact of quater of birth (not asked for):
// (1) Mean years of completed education by quarter of birth:
preserve
  collapse (mean) educ, by(qob)
  twoway  (bar educ qob, barw(.6) base(12.65)) ///
          (scatter educ qob, msym(none) mlab(educ) mlabpos(12) mlabcolor(black) mlabsize(vsmall)), ///
    graphregion(color(white)) ytitle("Years of Completed Education") xtitle("Quarter of Birth") ///
    legend(off) title("Mean years of completed education by quarter of birth")
restore

// (2) Mean years of completed education by quarter of birth:
// Only those with less than 12 years of education
preserve
  collapse  (mean) educ if educ<12, by(qob)
  twoway  (bar educ qob, barw(.6) base(8.55)) ///
          (scatter educ qob, msym(none) mlab( educ) mlabpos(12) mlabcolor(black) mlabsize(vsmall)), ///
    graphregion(color(white)) ytitle("Years of Completed Education") xtitle("Quarter of Birth") ///
    legend(off) title("Mean years of completed education by quarter of birth") ///
    subtitle("Individuals with less than 12 years of education")
restore

// (3) Mean years of completed education by quarter of birth:
// Only those with more than 12 years of education
preserve
  collapse (mean) educ if educ>=12, by(qob)
  twoway  (bar educ qob, barw(.6) base(13.97)) ///
    (scatter educ qob, msym(none) mlab(educ) mlabpos(12) mlabcolor(black) mlabsize(vsmall)), ///
    graphregion(color(white)) ytitle("Years of Completed Education") xtitle("Quarter of Birth") ///
    legend(off) title("Mean years of completed education by quarter of birth") ///
    subtitle("Individuals with more than 12 years of education")
restore

*------------------------------------------------------------------------------*
*-------- Q2: Wald Estimator
*-------- Q3: Assessing the First Stage.
// Let's at this point create dummies for each quarter of birth.
tab qob, gen(qob)                 // Generate a dummy for each value of qob (named qob1-qob4)
forvalues y=1(1)4 {
  label var qob`y' "Born in Q`y'" // Label the dummies
}

// Replicating all the results in Panel B of Table III in Angrist & Krueger (1991)
eststo clear      // Clear any stored estimates in memory.

// Start with the first two rows:
* Mean education and log weekly wage if born in Q1.
eststo: quietly estpost summarize earnwkl educ if qob1==1
* Mean education and log weekly wage if born in Q2-Q4.
eststo: quietly estpost summarize earnwkl educ if qob1==0
* Use a t-test to test for differences in means
eststo: quietly estpost ttest earnwkl educ, by(qob1) unequal
* Note: I could also have obtained the same differences by regressing "educ" and "earnwkl" on "qob1".

// Tabulate the results:
esttab  using "$res_dir/Table1.tex", label collabels(none) replace ///
        cells("mean(pattern(1 1 0) fmt(5)) b(pattern(0 0 1) fmt(5))" ". se(pattern(0 0 1) par fmt(5))") ///
        title(Mean Earnings and Schooling for 1980 Census -- Men Born 1930--1939\label{Table1}) ///
        mtitles("\makecell{Born in\\1st quarter\\of year}" ///
                "\makecell{Born in\\2nd, 3rd or 4th\\quarter of year}" ///
                "\makecell{Difference\\(std. error)\\(2)-(1)}")

// Finally, create the last two rows of Column (3):
// Let's also run the first-stage regression and save the F-value from
// the hypothesis test on the significance of the instrument "qob1":
eststo clear
eststo: reg earnwkl educ                    // OLS estimates
eststo: ivregress 2sls earnwkl (educ=qob1)  // Wald estimates
estat first                                 // Check the first-stage (I'll use this method later)
eststo: reg educ qob1                       // First-stage regression
quietly test qob1                           // Perform the hypothesis test
estadd scalar Fval = r(F)                   // Extract the F-value

*------------------------------------------------------------------------------*
*-------- Q4: 2SLS Estimates.
// Confirm that you can replicate the 2SLS estimate in Column (2) of Table V
// (note that the instruments are described in the footnote to the table).
*-------- Q5: Multiple Instruments?
// Are the instrument used in the analysis of Table V, Column (2) relevant?

// Tip: Writing i.var1#i.var2 creates dummies for each possible combination
//    of values taken by var1 and var2. I'll use this to add yob*qob dummies.
eststo: ivregress 2sls earnwkl i.yob (educ=i.yob#i.qob)
estat first
estadd scalar Fval   = r(mineig)            // Add the first-stage F-value to the table:
estat overid                                // Run the overidentification test
estadd scalar chi2_s = r(sargan)            // Add the chi2-statistic from the test
estadd scalar dof    = r(df)                // Add the dof of the test statistic
estadd scalar pval   = r(p_sargan)          // Add the p-value of the overidentification test

// Note: We could have also run the 2SLS model as follows:
gen qyob=qob+yob*100                        // Create a qob*yob variable.
ivregress 2sls earnwkl i.yob (educ=i.qyob)

// Finally, let's tabulate the OLS, Wald, Wald 1st-stage and 2SLS results:
// Here, we include and first-stage F-value as well as
// the dof and chi2 statistics from the overidentification test.
esttab using "$res_dir/Table2.tex", ///
  keep(educ qob1) se label replace mtitle("OLS" "Wald" "Wald: First Stage" "2SLS") ///
  title(OLS, Wald, Wald First Stage, and 2SLS Estimates for 1980 Census -- Men Born 1930--1939\label{Table2}) ///
  stats(Fval chi2_s dof pval, labels("1st-Stage \$ F \$-value" "\$ \chi^2 \$-value" "dof" "\$ p \$-value"))

*------------------------------------------------------------------------------*
*-------- Q6 => See the suggested solutions and slides!

*------------------------------------------------------------------------------*
*-------- Q7: Interpreting the IV Estimates.
// Do you think the estimated effects in the questions above should be interpreted as LATE, ATE or ATT?
// Small illustration of identifying compliers, always-takers and never-takers.
gen qob234 = !qob1          // Dummy for being born in Q2, Q3, or Q4.
gen hs_deg = educ>=12       // Outcome variable: Graduating HS (at least 12 years of schooling)
reg hs_deg qob234, robust   // First-stage coefficient on the instrument = Share of compliers.
tab hs_deg
tab qob234
tab hs_deg qob234, cell

*------------------------------------------------------------------------------*
*------------------------------------------------------------------------------*
cap log close
clear all
