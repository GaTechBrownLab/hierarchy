// Standard script initialization
version 18          // Stata version used to create/execute this script
set more off        // disable pause of output display every full screen
clear all           // ensure clean slate
capture log close   // close any pending logs
set seed 123456789  // consistent random number generation

// Standard visualization settings
set scheme s1color  // graphics color scheme (theme)
//local font = "Lucida Sans OT"
local font = "Arial"
graph set window fontface "`font'"
quietly include "Stata Scripts/00colors.do"

capture program drop plot_fold_change
program define plot_fold_change
	args gene signal color ytitle panel
	local gene_name = substr("`gene'", 1, 3) + upper(substr("`gene'", 4, 1))
	tempvar use_data fold_change mean_fold_change
	if "`signal'" == "c4" {
		quietly generate `use_data' = float(c12) == float(0) & in_window
		local signal_text = "C{sub:4}–HSL"
		local null_signal = "3–oxo–C{sub:12}–HSL"
	}
	else {
		quietly generate `use_data' = float(c4) == float(0) & in_window
		local signal_text = "3–oxo–C{sub:12}–HSL"
		local null_signal = "C{sub:4}–HSL"
	}

	summarize rlu_od if `use_data', meanonly
	quietly {
		generate `fold_change' = rlu_od / r(min) if `use_data'
		by c4 c12, sort: egen `mean_fold_change' = mean(`fold_change')
	}

	twoway ///
		lowess `mean_fold_change' `signal' if `use_data' & unique_treatment, ///
			sort ///
			lpattern(dash) lcolor("`color'") ///
		|| ///
		scatter `fold_change' `signal' if `use_data', ///
			mcolor("`color'") msize(vlarge) ///
		xlabel(, labsize(18pt)) ///
		xtitle("[`signal_text'] (μM)", size(18pt)) ///
		ylabel(, nogrid labsize(18pt)) ///
		ytitle(`ytitle', size(18pt)) ///
		title("{it:`gene_name'} Expression", size(21pt) position(12) ring(1)) ///
        subtitle(`panel', size(21pt) position(11) ring(1)) ///
		note("[`null_signal']: 0 μM", ///
			size(15pt) position(5) ring(0)) ///
		legend(off) ///
		nodraw name(`gene'_`signal', replace)

	drop `use_data' `fold_change' `mean_fold_change'

end


colorpalette crest, n(3) nograph
local lasi_color = r(p1)
local rhli_color = r(p2)
local lasb_color = r(p3)

frame create lasi
frame lasi {
	use "Data/LasI.dta" 
	plot_fold_change lasi c4 "`lasi_color'" "N-fold change in RLU/OD" "A"
	plot_fold_change lasi c12 "`lasi_color'" "N-fold change in RLU/OD" "A"
}

frame create rhli
frame rhli {
	use "Data/RhlI.dta"
	plot_fold_change rhli c4 "`rhli_color'" "" "B"
	plot_fold_change rhli c12 "`rhli_color'" "" "B"
}

graph combine lasi_c4 rhli_c4, ///
	cols(2) xsize(8.25in) ysize(3.75in) ///
	name(single_c4, replace)

graph export "Prefigures/single_c4.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(single_c4) replace

graph combine lasi_c12 rhli_c12, ///
	cols(2) xsize(8.25in) ysize(3.75in) ///
	name(single_c12, replace)

graph export "Prefigures/single_c12.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(single_c12) replace

