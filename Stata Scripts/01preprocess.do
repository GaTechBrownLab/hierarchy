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

// Import data for one gene
capture program drop import_data
program define import_data
	args filename
	quietly {
		// Although data files include RLU/OD values, in a private conversation
		// Aya indicated that the calculation may have been incorrect in early
		// versions. To be on the safe side, we simply recalculate it here.
		import excel "Raw Data/`filename'", sheet("All data") firstrow case(lower) clear
		keep c4 c12 od rlu time
		drop if missing(c4 - time)
		generate rlu_od = rlu / od
		drop rlu od
		by c4 c12 time, sort: egen mean_rlu_od = mean(rlu_od)
		egen unique_condition = tag(c4 c12 time)
	}
	label variable time "Time (hrs)"
	label variable c4 "C{sub:4}–HSL Concentration (μM)"
	label variable c12 "3–oxo–C{sub:12}–HSL Concentration (μM)"
	label variable rlu_od "Relative Light Units / Optical Density"
	label variable mean_rlu_od "Mean RLU/OD of Replicates"
	label variable unique_condition "Flag for unique combination of C4, C12, and Time"
end

// Show time series for current gene
capture program drop plot_time_series
program define plot_time_series, rclass
	args gene
	
	tempvar max_value
	egen `max_value' = max(mean_rlu_od), by(c4 c12)
	summarize time if mean_rlu_od == `max_value' & unique_condition, meanonly
	local t_peak = round(r(mean))
	drop `max_value'

    local panel_number = 65 // ASCII A

	foreach main_signal in c4 c12 {	
		
		tempvar major minor
		if "`main_signal'" == "c4" {
			quietly {
				generate `major' = c4
				generate `minor' = c12
				local major_signal = "C{sub:4}–HSL"
				local minor_signal = "3–oxo–C{sub:12}–HSL"
			}
		}
		else {
			quietly {
				generate `major' = c12
				generate `minor' = c4
				local major_signal = "3–oxo–C{sub:12}–HSL"
				local minor_signal = "C{sub:4}–HSL"
			}
		}

		local graphs = ""
		quietly levelsof `major', local(major_levels)
		local num_major_levels = r(r)
		quietly levelsof `minor', local(minor_levels)
		local num_minor_levels = r(r)
		local major_index = 0
		foreach major_value of local major_levels {
			local major_index = `major_index' + 1
			local graph_panel = ""
			local major_display : display %3.1f `major_value'
			local minor_index = 0
			foreach minor_value of local minor_levels {
				local minor_index = `minor_index' + 1
				colorpalette flare, n(`num_minor_levels') nograph
				local graph_panel `graph_panel' ( ///
					lowess mean_rlu_od time ///
					if float(`major') == float(`major_value') & ///
						float(`minor') == float(`minor_value') & ///
						unique_condition ///
					, ///
					bwidth(0.4) ///
					lcolor("`r(p`minor_index')'") ///
				)
			}
			twoway `graph_panel', ///
				xline(`t_peak', lwidth(8rs) lcolor(gs5%10)) ///
				legend(off) ///
				xlabel(, labsize(14pt)) ///
				xtitle(, size(14pt)) ///
				ylabel(, nolabels noticks nogrid) ///
				ytitle("Mean RLU/OD", size(14pt)) ///
                subtitle(`=char(`panel_number')', ///
                    size(10pt) position(11) ring(0)) ///
				note("[`major_signal']: `major_display' μM", ///
					size(10pt) position(1) ring(0)) ///
				nodraw name(`main_signal'_`major_index', replace)
			local graphs "`graphs' `main_signal'_`major_index'"
            local panel_number = `panel_number' + 1
		}

		local graph_panel = ""
		local minor_index = 0
		foreach minor_value of local minor_levels {
			local minor_index = `minor_index' + 1
			local minor_display : display %3.1f `minor_value'
			local legend_labels = `"`legend_labels' label(`minor_index' "`minor_display' μM") "'
			colorpalette flare, n(`num_minor_levels') nograph
			local graph_panel `graph_panel' ( ///
				line mean_rlu_od time ///
				if float(`major') == float(0) & ///
					float(`minor') == float(`minor_value') & ///
					unique_condition ///
				, ///
				color("`r(p`minor_index')'") ///
			)
		}
		twoway `graph_panel', ///
			legend(title("[`minor_signal']:", size(10pt)) size(10pt)) ///
			legend(`legend_labels') ///
			legend(rowgap(0) colgap(1) keygap(1) symxsize(6)) ///
			legend(position(12) ring(7)) ///
			plotregion(style(none)) ///
			xtitle("") xlabel("", nolabels noticks nogrid) xscale(off) ///
			ytitle("") ylabel("", nolabels noticks nogrid) yscale(off) ///
			nodraw name(common_legend, replace)
		local graphs "`graphs' common_legend"

		if "`main_signal'" == "c4" {
			local title = `""{it:`gene'} Expression", size(14pt)"'
		}
		else {
			local title = `""{dup 72:—}", size(7pt) color(gs10)"'
		}
	
		graph combine `graphs', ///
			ycommon ///
			title(`title') ///
			name(`gene'_`main_signal', replace)

		local i = `num_major_levels' + 1
		forvalues j = 1/`num_minor_levels' {
			gr_edit .plotregion1.graph`i'.plotregion1.plot`j'.draw_view.setstyle, style(no)
		}

		drop `major' `minor'
	}

	graph combine `gene'_c4 `gene'_c12, ///
		ycommon ysize(8) cols(1) imargin(zero) ///
		name(`gene', replace)

	return scalar t_peak = `t_peak'
end

// Focus on key observations
capture program drop focus_data
program define focus_data
	args t_peak

	generate in_window = (t_peak - 1.1) < time & time < (t_peak + 1.1)
	egen unique_treatment = tag(c4 c12) if in_window
	label variable unique_treatment "Flag for unique combination of C4 and C12 within peak expression window"

	by c4 c12, sort: egen treatment_rlu_od = mean(rlu_od) if unique_treatment
	label variable treatment_rlu_od "Mean RLU/OD for Treatment"
end


import_data "lasi all data.xlsx"
plot_time_series lasI
scalar t_peak = r(t_peak)
focus_data t_peak
quietly save "Data/LasI", replace
graph export "Prefigures/lasi_time.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(lasI) replace


import_data "Rhli all data.xlsx"
plot_time_series rhlI
scalar t_peak = r(t_peak)
focus_data t_peak
quietly save "Data/RhlI", replace
graph export "Prefigures/rhli_time.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(rhlI) replace

import_data "lasb all data.xlsx"
plot_time_series lasB
scalar t_peak = r(t_peak)
focus_data t_peak
quietly save "Data/LasB", replace
graph export "Prefigures/lasb_time.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(lasB) replace
