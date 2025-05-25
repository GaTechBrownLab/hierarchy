// Standard script initialization
version 18          // Stata version used to create/execute this script
set more off        // disable pause of output display every full screen
clear all           // ensure clean slate
capture log close   // close any pending logs
set seed 123456789  // consistent random number generation

// Standard visualization settings
set scheme s1color  // graphics color scheme (theme)
local font = "Arial"
graph set window fontface "`font'"
quietly include "Stata Scripts/00colors.do"

colorpalette crest, n(3) nograph
local lasi_color = r(p1)
local rhli_color = r(p2)
local lasb_color = r(p3)

display "`lasb_color'"

// Data from combined experiments
import delimited "Data/Combined lasI.csv", clear

// Keep C12-only and C4-only observations
keep if (float(c4) == float(0)) | (float(c12) == float(0))

// Consider only time points with peak expression
egen mean_rlu_od = mean(rlu_od), by(time phase)
egen max_mean_rlu_od = max(mean_rlu_od), by(phase)
keep if mean_rlu_od == max_mean_rlu_od

// There are three obvious outliers
replace phase = "outlier" if (float(c4) > float(0.2)) & (rlu_od < 2225)

// Estimate basal expression to calibrate observations
// Notes
//   - a0 is just RLU/OD when both signals are zero
//   - Could just take the mean, but for consistency use the same approach
//   - Use the logarithm of all parameters to enforce a constraint > 0
//   - Use float() to avoid computer precision errors

nl (rlu_od = exp({lna0})) ///
	if float(c4) == float(0) & float(c12) == float(0) & phase == "initial", ///
	nolog
	
// Convert from logarithm
nlcom (a0: exp(_b[/lna0]))
local a0_initial = r(table)["b", "a0"]

// Store in table
generate double a0 = r(table)["b", "a0"]
label variable a0 "Basal expression (RLU/OD)"

// Repeat the estimate for followup observations
nl (rlu_od = exp({lna0})) ///
	if float(c4) == float(0) & float(c12) == float(0) & phase == "followup"
nlcom (a0: exp(_b[/lna0]))
local a0_followup = r(table)["b", "a0"]

// Calculate a scaling factor and calibrate the followup data
local followup_scale = `a0_initial' / `a0_followup'
replace rlu_od = rlu_od * `followup_scale' if phase == "followup"

// Use basal expression as starting prediction
generate predicted = a0
label variable predicted "Predicted expression (RLU/OD)"

// Keep track of prediction errors
generate double residuals = rlu_od - `a0_initial'

// Initial guesses
local lna1 = ln(61616)
local lnK1 = ln(0.237)
local lna2 = ln(8997)
local lnK2 = ln(1.044)

// Now predict non-basal expression level (e.g. residuals)
nl (residuals = exp({lna1}) * c12 / (exp({lnK1}) + c12)) ///
	if (float(c4) == float(0)) & (float(c12) != float(0)) & phase == "initial", ///
    initial(lna1 `lna1' lnK1 `lnK1') ///
	nolog

// Convert from logarithms
nlcom (a1: exp(_b[/lna1])) (K1: exp(_b[/lnK1]))

// Store in table
generate double a1 = r(table)["b", "a1"]
generate double K1 = r(table)["b", "K1"]
label variable a1 "Maximum expression level increase from C12 (RLU/OD)"
label variable K1 "Half concentration for C12 (μM)"

tempvar tmp_pred
predictnl `tmp_pred' = (a1 * c12 / (c12 + K1))
replace predicted = predicted + `tmp_pred'
replace residuals = rlu_od - predicted
drop `tmp_pred'

nl (residuals = exp({lna2}) * c4 / (exp({lnK2}) + c4)) ///
	if (float(c12) == float(0)) & (float(c4) != float(0)) & phase == "initial", ///
    initial(lna2 `lna2' lnK2 `lnK2') ///
	nolog

// Convert from logarithms
nlcom (a2: exp(_b[/lna2])) (K2: exp(_b[/lnK2]))

// Store in table
generate double a2 = r(table)["b", "a2"]
generate double K2 = r(table)["b", "K2"]
label variable a2 "Maximum expression level increase from C4 (RLU/OD)"
label variable K2 "Half concentration for C4 (μM)"

predictnl `tmp_pred' = (a2 * c4 / (c4 + K2))
replace predicted = predicted + `tmp_pred'
replace residuals = rlu_od - predicted
drop `tmp_pred'

// Calculate correlation coefficients for followup data vs. initial predictions
tempvar res_sq diff_sq
generate double `res_sq' = residuals ^ 2 if phase == "followup"
summarize rlu_od if phase == "followup", meanonly
generate double `diff_sq' = (rlu_od - r(mean)) ^ 2 if phase == "followup"
summarize `res_sq' if phase == "followup"
local ssr = r(sum)
summarize `diff_sq' if phase == "followup"
local ssd = r(sum)
generate double R2 = 1 - (`ssr' / `ssd')
label variable R2 "R² for followup data"
drop `res_sq' `diff_sq'

// Convert to fold-change
replace predicted = predicted / a0
replace rlu_od = rlu_od / a0


tempvar tmp_data tmp_initial tmp_followup tmp_outlier
generate `tmp_data' = float(c4) == float(0)
generate `tmp_initial' = (float(c4 == float(0)) & (phase == "initial"))
generate `tmp_followup' = (float(c4 == float(0)) & (phase == "followup"))

sort c12
twoway ///
    (line predicted c12 if `tmp_data', lpattern(dash) lwidth(thick) lcolor("`lasi_color'")) ///
	(scatter rlu_od c12 if `tmp_initial', msize(large) mcolor("`lasi_color'")) ///
	(scatter rlu_od c12 if `tmp_followup', msize(large) mcolor("`lasb_color'")) ///
    , ///
		xlabel(, labsize(10pt)) ///
        xtitle("[3–oxo–C{sub:12}–HSL] (μM)", size(10pt)) ///
        ylabel(, nogrid labsize(10pt)) ///
        ytitle("N-fold Change in RLU/OD", size(10pt)) ///
        title("{it:lasI} Expression", size(13pt) position(12) ring(1)) ///
        note("[C{sub:4}–HSL]: 0 μM", ///
            size(8pt) position(11) ring(0)) ///
        legend( ///
			label(1 "Model Prediction") ///
			label(2 "Full Range") ///
			label(3 "Low Concentrations") ///
			cols(1) ring(0) position(5) ///
		) ///
        nodraw name(lasi_c12, replace)

drop `tmp_data' `tmp_initial' `tmp_followup'

generate `tmp_data' = float(c12) == float(0)
generate `tmp_initial' = (float(c12 == float(0)) & (phase == "initial"))
generate `tmp_followup' = (float(c12 == float(0)) & (phase == "followup"))
generate `tmp_outlier' = (float(c12 == float(0)) & (phase == "outlier"))

sort c4
twoway ///
    (line predicted c4 if `tmp_data', lpattern(dash) lwidth(thick) lcolor("`lasi_color'")) ///
	(scatter rlu_od c4 if `tmp_initial', msize(large) mcolor("`lasi_color'")) ///
	(scatter rlu_od c4 if `tmp_followup', msize(large) mcolor("`lasb_color'")) ///
	(scatter rlu_od c4 if `tmp_outlier', msize(large) mcolor("`lasb_color'%33")) ///
    , ///
		xlabel(, labsize(10pt)) ///
        xtitle("[C{sub:4}–HSL] (μM)", size(10pt)) ///
        ylabel(, nogrid labsize(10pt)) ///
        ytitle("N-fold Change in RLU/OD", size(10pt)) ///
        title("{it:lasI} Expression", size(13pt) position(12) ring(1)) ///
        note("[3–oxo–C{sub:12}–HSL]: 0 μM", ///
            size(8pt) position(11) ring(0)) ///
			legend( ///
			label(1 "Model Prediction") ///
			label(2 "Full Range") ///
			label(3 "Low Concentrations") ///
			order(1 2 3) ///
			cols(1) ring(0) position(5) ///
		) ///
        nodraw name(lasi_c4, replace)

drop `tmp_data' `tmp_initial' `tmp_followup' `tmp_outlier'

graph combine lasi_c12 lasi_c4, ///
	ysize(2.344) ///
	name(combined_lasi, replace)

graph export "Prefigures/combined_lasi.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(combined_lasi) replace
