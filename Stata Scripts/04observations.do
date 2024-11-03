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

capture program drop plot_fold_change_line
program define plot_fold_change_line
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
			mcolor("`color'") msize(medsmall) ///
		xlabel(, labsize(15pt)) ///
		xtitle("[`signal_text'] (μM)", size(15pt)) ///
		ylabel(, nogrid labsize(15pt)) ///
		ytitle(`ytitle', size(15pt)) ///
		title("{it:`gene_name'} Expression", size(15pt) position(12) ring(1)) ///
        subtitle(`panel', size(18pt) position(11) ring(1)) ///
		note("[`null_signal']: 0 μM", ///
			size(12pt) position(5) ring(0)) ///
		legend(off) ///
		fysize(36) ///
		nodraw name(`gene'_`signal', replace)

	drop `use_data' `fold_change' `mean_fold_change'

end

capture program drop plot_fold_change_heatmap
program define plot_fold_change_heatmap
	args gene panel

    preserve

	local gene_name = substr("`gene'", 1, 3) + upper(substr("`gene'", 4, 1))
	
	summarize rlu_od if in_window, meanonly
	quietly {
		generate fold_change = rlu_od / r(min) if in_window
		by c12 c4, sort: egen mean_fold_change = mean(fold_change)
	}
    
    // Convert the data into a matrix to avoid axis scaling in the plot.
    quietly {
        keep if in_window & unique_treatment
        keep c4 c12 mean_fold_change
        sort c4

        levelsof c12, local(c12_levels)
        forvalues i = `r(r)'(-1)1 {
            local c12_levels_reversed = "`c12_levels_reversed' " + ///
                word("`c12_levels'", `i')
        }
        levelsof c4, local(c4_levels)
    
        replace c4 = c4 * 100
        rename mean_fold_change mfc
        reshape wide mfc, i(c12) j(c4)
        gsort -c12
        mkmat mfc*, matrix(MFC)
        matrix rownames MFC = `c12_levels_reversed'
        matrix colnames MFC = `c4_levels'
    }

	heatplot MFC, ///
		levels(25) ///
		keylabels(minmax, format(%4.0f) region(lwidth(0)) ///
            subtitle("Mean" "fold" "change", size(12pt) justification(left))) ///
		colors(flare, reverse) ///
		plotregion(style(none) margin(zero)) ///
		title("{it:`gene_name'} Expression", size(15pt) position(12) ring(1)) ///
        subtitle(`panel', size(18pt) position(11) ring(1)) ///
		xtitle("[C{sub:4}–HSL] (μM)", size(15pt)) ///
		xlabel(, format(%4.1f) labsize(11pt) noticks nogrid) ///
		xscale(noline) ///
		ytitle("[3–oxo–C{sub:12}–HSL] (μM)", size(15pt)) ///
		ylabel(, format(%4.1f) labsize(11pt) noticks nogrid) ///
		yscale(noline) ///
		fysize(30) ///
		nodraw name(`gene', replace)

    matrix drop MFC
    restore
end

colorpalette crest, n(3) nograph
local lasi_color = r(p1)
local rhli_color = r(p2)
local lasb_color = r(p3)

frame create lasi1
frame lasi1 {
	use "Data/LasI.dta" 
	plot_fold_change_line lasi c12 "`lasi_color'" "N-fold change in RLU/OD" "{bf:A}"
	plot_fold_change_line lasi c4 "`lasi_color'" "" "{bf:C}"
}

frame create rhli1
frame rhli1 {
	use "Data/RhlI.dta"
	plot_fold_change_line rhli c12 "`rhli_color'" "N-fold change in RLU/OD" "{bf:B}"
	plot_fold_change_line rhli c4 "`rhli_color'" "" "{bf:D}"
}

frame create lasi2
frame lasi2 {
	use "Data/LasI.dta"
	plot_fold_change_heatmap lasi "{bf:E}"
}

frame create rhli2
frame rhli2 {
	use "Data/RhlI.dta"
	plot_fold_change_heatmap rhli "{bf:F}"
}

graph combine lasi_c12 lasi_c4 lasi rhli_c12 rhli_c4 rhli, ///
	cols(3) xsize(8.25in) ysize(5.5in) ///
	name(observations, replace)

gr_edit .plotregion1.graph3.legend.plotregion1.label[1].style.editstyle size(11-pt) editcopy
gr_edit .plotregion1.graph3.legend.plotregion1.label[27].style.editstyle size(11-pt) editcopy
gr_edit .plotregion1.graph6.legend.plotregion1.label[1].style.editstyle size(11-pt) editcopy
gr_edit .plotregion1.graph6.legend.plotregion1.label[27].style.editstyle size(11-pt) editcopy
gr_edit .plotregion1.graph3.xaxis1.title.yoffset = -4
gr_edit .plotregion1.graph6.xaxis1.title.yoffset = -4

graph export "Prefigures/observations.svg", as(svg) ///
 	baselineshift(on) fontface("`font'") ///
 	name(observations) replace
