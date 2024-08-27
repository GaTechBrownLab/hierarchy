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
            subtitle("Mean" "fold" "change", size(15pt) justification(left))) ///
		colors(flare, reverse) ///
		plotregion(style(none) margin(zero)) ///
		title("{it:`gene_name'} Expression", size(18pt) position(12) ring(1)) ///
        subtitle(`panel', size(18pt) position(11) ring(1)) ///
		xtitle("[C{sub:4}–HSL] (μM)", size(18pt)) ///
		xlabel(, format(%4.1f) labsize(14pt) noticks nogrid) ///
		xscale(noline) ///
		ytitle("[3–oxo–C{sub:12}–HSL] (μM)", size(18pt)) ///
		ylabel(, format(%4.1f) labsize(14pt) noticks nogrid) ///
		yscale(noline) ///
		name(`gene', replace)

    gr_edit .legend.plotregion1.label[1].style.editstyle size(14-pt) editcopy
    gr_edit .legend.plotregion1.label[27].style.editstyle size(14-pt) editcopy
    gr_edit .xaxis1.title.yoffset = -2

    matrix drop MFC
    restore
end

frame create lasi
frame lasi {
	use "Data/LasI.dta"
	plot_fold_change lasi "A"
}

frame create rhli
frame rhli {
	use "Data/RhlI.dta"
	plot_fold_change rhli "B"
}

frame create lasb
frame lasb {
	use "Data/LasB.dta"
	plot_fold_change lasb "A"
}

graph combine lasi rhli, ///
	cols(2) xsize(8.25in) ysize(3.75in) ///
	name(combined, replace)

graph export "Prefigures/combined.svg", as(svg) ///
 	baselineshift(on) fontface("`font'") ///
 	name(combined) replace

// create a blank graph as a filler
twoway scatteri 1 1,               ///
       msymbol(i)                  ///
       ylab("") xlab("")           ///
       ytitle("") xtitle("")       ///
       yscale(off) xscale(off)     ///
       plotregion(lpattern(blank)) ///
       name(blank, replace)

graph combine lasb blank, ///
	cols(2) xsize(8.25in) ysize(3.75in) ///
	name(lasb_heat, replace)

graph export "Prefigures/lasb_heat.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(lasb_heat) replace


