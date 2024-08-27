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

// Combine the LasI and RhlI data for ease of comparion
use "Data/LasI.dta", clear
rename (rlu_od mean_rlu_od) (lasi_rlu_od lasi_mean_rlu_od)
drop unique_treatment treatment_rlu_od in_window
quietly merge m:m c4 c12 time using "Data/RhlI.dta", keepusing(rlu_od mean_rlu_od) nogenerate
rename (rlu_od mean_rlu_od) (rhli_rlu_od rhli_mean_rlu_od)

capture program drop plot_time_series
program define plot_time_series
	args c4 c12 title graph

    preserve
    quietly keep if float(c4) == float(`c4') & float(c12) == float(`c12')

    colorpalette crest, n(3) nograph
    local lasi_color = r(p1)
    local rhli_color = r(p2)
    
    summarize lasi_mean_rlu_od, meanonly
    local max_lasi = r(max)
    summarize time if lasi_mean_rlu_od == `max_lasi', meanonly
    local max_lasi_time = r(mean)

    summarize rhli_mean_rlu_od, meanonly
    local max_rhli = r(max)
    summarize time if rhli_mean_rlu_od == `max_rhli', meanonly
    local max_rhli_time = r(mean)
    
    local peak_time = (`max_lasi_time' + `max_rhli_time') / 2

    twoway ///
        (scatter lasi_rlu_od time, mcolor("`lasi_color'")) ///
        (line lasi_mean_rlu_od time, lcolor("`lasi_color'")) ///
        (scatter rhli_rlu_od time, mcolor("`rhli_color'")) ///
        (line rhli_mean_rlu_od time, lcolor("`rhli_color'")) ///
        , ///
        xline(`peak_time', lwidth(30) lcolor(gs5%05)) ///
        xtitle(, size(8pt)) xlabel(, labsize(8pt)) ///
        ytitle("Expression", size(8pt)) ylabel(none) ///
        legend(order(3 "{it:rhlI}" 1 "{it:lasI}") size(7pt) rowgap(0) ///
            symxsize(4) cols(1) position(11) ring(0)) ///
        subtitle("3–oxo–C{sub:12}–HSL: `c12' μM" "C{sub:4}–HSL: `c4' μM", ///
            position(1) ring(0) size(7pt) linegap(1)) ///
        title("`title'", size(8pt) margin(b+1)) ///
        name(`graph', replace) nodraw
        
    restore
end


plot_time_series 0.1 5 "High 3–oxo–C{sub:12}–HSL, Low C{sub:4}–HSL" low
plot_time_series 1 1 "Moderate 3–oxo–C{sub:12}–HSL, Moderate C{sub:4}–HSL" medium
plot_time_series 5 0.1 "Low 3–oxo–C{sub:12}–HSL, High C{sub:4}–HSL" high

graph combine low medium high, ///
    ysize(1.55) cols(3) ///
	name(time_series, replace)
 
graph export "Prefigures/time_series.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(time_series) replace

