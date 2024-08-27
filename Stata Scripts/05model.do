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

capture program drop model_rlu_od
program define model_rlu_od

    tempvar predicted

    // Basal expression
    quietly {

        nl (rlu_od = exp({lna0})) ///
            if float(c4) == float(0) & float(c12) == float(0)
        nlcom (a0: exp(_b[/lna0]))

        local a0 = r(table)["b", "a0"]
        generate double a0 = r(table)["b", "a0"]
        generate double a0_ll = r(table)["ll", "a0"]
        generate double a0_ul = r(table)["ul", "a0"]
        label variable a0 "Basal expression (RLU/OD)"

        generate predicted = a0
        label variable predicted "Predicted expression (RLU/OD)"
        
        generate double residuals = rlu_od - predicted

    }

    // Expression from C4 alone
    quietly {

        nl (residuals = ///
            exp({lna_c4}) * c4 / (c4 + exp({lnK_c4}))) ///
            if float(c4) != float(0) & float(c12) == float(0)
        nlcom (a_c4: exp(_b[/lna_c4])) (K_c4: exp(_b[/lnK_c4])) ///
              (fc_c4: (exp(_b[/lna_c4]) + `a0') / `a0')

        generate double a_c4 = r(table)["b", "a_c4"]
        generate double a_c4_ll = r(table)["ll", "a_c4"]
        generate double a_c4_ul = r(table)["ul", "a_c4"]
        generate double K_c4 = r(table)["b", "K_c4"]
        generate double K_c4_ll = r(table)["ll", "K_c4"]
        generate double K_c4_ul = r(table)["ul", "K_c4"]
        generate double fc_c4 = r(table)["b", "fc_c4"]
        generate double fc_c4_ll = r(table)["ll", "fc_c4"]
        generate double fc_c4_ul = r(table)["ul", "fc_c4"]
        label variable a_c4 "Maximum expression level increase from C4 (RLU/OD)"
        label variable K_c4 "Half concentration for C4 (μM)"
        label variable fc_c4 "Maximum fold-change from C4"

        predictnl `predicted' = (a_c4 * c4 / (c4 + K_c4))
        replace predicted = predicted + `predicted'
        replace residuals = rlu_od - predicted
        drop `predicted'

    }

    // Expression from C12 alone
    quietly {

        nl (residuals = ///
            exp({lna_c12}) * c12 / (c12 + exp({lnK_c12}))) ///
            if float(c12) != float(0) & float(c4) == float(0)
        nlcom (a_c12: exp(_b[/lna_c12])) (K_c12: exp(_b[/lnK_c12])) ///
              (fc_c12: (exp(_b[/lna_c12]) + `a0') / `a0')

        generate double a_c12 = r(table)["b", "a_c12"]
        generate double a_c12_ll = r(table)["ll", "a_c12"]
        generate double a_c12_ul = r(table)["ul", "a_c12"]
        generate double K_c12 = r(table)["b", "K_c12"]
        generate double K_c12_ll = r(table)["ll", "K_c12"]
        generate double K_c12_ul = r(table)["ul", "K_c12"]
        generate double fc_c12 = r(table)["b", "fc_c12"]
        generate double fc_c12_ll = r(table)["ll", "fc_c12"]
        generate double fc_c12_ul = r(table)["ul", "fc_c12"]
        label variable a_c12 "Maximum expression level increase from C12 (RLU/OD)"
        label variable K_c12 "Half concentration for C12 (μM)"
        label variable fc_c12 "Maximum fold-change from C12"

        predictnl `predicted' = (a_c12 * c12 / (c12 + K_c12))
        replace predicted = predicted + `predicted'
        replace residuals = rlu_od - predicted
        drop `predicted'

    }

    // Expression from C4 & C12 combined
    quietly {
    
        nl (residuals = ///
             (exp({lnaQ}) * c4 * c12) / ///
             ((c4 + exp({lnKQ_c4})) * (c12 + exp({lnKQ_c12}))) ///
            ) ///
            if float(c4) != 0 & float(c12) != 0

        nlcom (aQ: exp(_b[/lnaQ])) ///
              (KQ_c4: exp(_b[/lnKQ_c4])) (KQ_c12: exp(_b[/lnKQ_c12])) ///
              (fcQ: (exp(_b[/lnaQ]) + `a0') / `a0')

        generate double aQ = r(table)["b", "aQ"]
        generate double aQ_ll = r(table)["ll", "aQ"]
        generate double aQ_ul = r(table)["ul", "aQ"]
        generate double KQ_c4 = r(table)["b", "KQ_c4"]
        generate double KQ_c4_ll = r(table)["ll", "KQ_c4"]
        generate double KQ_c4_ul = r(table)["ul", "KQ_c4"]
        generate double KQ_c12 = r(table)["b", "KQ_c12"]
        generate double KQ_c12_ll = r(table)["ll", "KQ_c12"]
        generate double KQ_c12_ul = r(table)["ul", "KQ_c12"]
        generate double fcQ = r(table)["b", "fcQ"]
        generate double fcQ_ll = r(table)["ll", "fcQ"]
        generate double fcQ_ul = r(table)["ul", "fcQ"]
        label variable aQ "Maximum expression level increase from C4 and C12 (RLU/OD)"
        label variable KQ_c4 "Cooperativity Half concentration for C4 (μM)"
        label variable KQ_c12 "Cooperativity Half concentration for C12 (μM)"
        label variable fcQ "Maximum fold-change from C4 and C12"

        predictnl `predicted' = ( ///
             (aQ * c4 * c12) / ///
             ((c4 + KQ_c4) * (c12 + KQ_c12)) ///
            )
        replace predicted = predicted + `predicted'
        replace residuals = rlu_od - predicted
        drop `predicted'

    }

	// Model assessment
	quietly {
		tempvar res_sq diff_sq
		generate double `res_sq' = residuals ^ 2
		summarize rlu_od, meanonly
		generate double `diff_sq' = (rlu_od - r(mean)) ^ 2
		summarize `res_sq'
		local ssr = r(sum)
		summarize `diff_sq'
		local ssd = r(sum)
		generate double R2 = 1 - (`ssr' / `ssd')
		label variable R2 "R²"
		
		drop `res_sq' `diff_sq'
	}
end

capture program drop show_model1
program define show_model1
	args gene signal color ytitle panel
	local gene_name = substr("`gene'", 1, 3) + upper(substr("`gene'", 4, 1))
	tempvar use_data

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

	twoway ///
        (line predicted `signal' if `use_data', lpattern(dash) lcolor("`color'")) ///
		(scatter rlu_od `signal' if `use_data', mcolor("`color'")) ///
        , ///
            xlabel(, labsize(8pt)) ///
            xtitle("[`signal_text'] (μM)", size(9pt)) ///
            ylabel("", nogrid labsize(8pt)) ///
            ytitle(`ytitle', size(8pt)) ///
            title("{it:`gene_name'} Expression", size(10pt) position(12) ring(1)) ///
            subtitle(`panel', size(10pt) position(11) ring(1)) ///
            note("[`null_signal']: 0 μM", ///
                size(8pt) position(5) ring(0)) ///
            legend(off) ///
            nodraw name(`gene'_`signal', replace)

	quietly drop `use_data'
end

capture program drop show_model2
program define show_model2
    args gene color
    local gene_name = substr("`gene'", 1, 3) + upper(substr("`gene'", 4, 1))
    
    quietly {
        summarize rlu_od, meanonly
        local max_expression = r(max)

        levelsof c12, local(c12_levels)
        forvalues i = `r(r)'(-1)1 {
            local c12_levels_reversed = "`c12_levels_reversed' " + ///
                word("`c12_levels'", `i')
        }
        levelsof c4, local(c4_levels)
        local num_cols = r(r)

        foreach c12 in `c12_levels_reversed' {
            foreach c4 in `c4_levels' {
                levelsof rlu_od if float(c4) == float(`c4') & float(c12) == float(`c12') & in_window, ///
                    local(observations)
                forvalues i = `r(r)'(-1)1 {
                    local points = "`points' " + word("`observations'", `i') + " 0 "
                }
                
                summarize predicted ///
                    if float(c4) == float(`c4') & float(c12) == float(`c12') & in_window & unique_treatment, meanonly
                local model_fit = r(mean)
                
                local graph_name = "`gene'_`=100*`c4''_`=100*`c12''"
                local graphs = "`graphs' `graph_name'"
                
                 dotplot rlu_od if float(c4) == float(`c4') & float(c12) == float(`c12') & in_window, ///
                     center ///
                     yline(`model_fit', lcolor("193 65 104") lwidth(1.5)) ///
                     yscale(lstyle(none) range(0 `max_expression')) ///
                     xscale(lstyle(none)) ///
                     ylabel("") ytitle("") ///
                     xlabel("") xtitle("") ///
                     mcolor("`color'") msize(2) ///
                     text(`=0.97*`max_expression'' 7.5 ///
                         "3–oxo–C{sub:12}–HSL: `c12' μM" "C{sub:4}–HSL: `c4' μM", ///
                         size(12pt) placement(sw) just(right) linegap(1.5)) ///
                     plotregion(style(none) margin(zero)) ///
                     graphregion(lwidth(0.25) lcolor(gray) lpattern(solid)) ///
                     nodraw name(`graph_name', replace)
            }
        }
        
         graph combine `graphs', ///
             cols(`num_cols') imargin(28 28 0 0) ///
             title("Observations and Model Predictions for {it:`gene_name'} Expression", size(7pt)) ///
             name("model_`gene'", replace)
    }
end

colorpalette crest, n(3) nograph
local lasi_color = r(p1)
local rhli_color = r(p2)
local lasb_color = r(p3)

local summary_vars a0 a0_ll a0_ul
local summary_vars = "`summary_vars' a_c4 a_c4_ll a_c4_ul"
local summary_vars = "`summary_vars' K_c4 K_c4_ll K_c4_ul"
local summary_vars = "`summary_vars' fc_c4 fc_c4_ll fc_c4_ul"
local summary_vars = "`summary_vars' a_c12 a_c12_ll a_c12_ul"
local summary_vars = "`summary_vars' K_c12 K_c12_ll K_c12_ul"
local summary_vars = "`summary_vars' fc_c12 fc_c12_ll fc_c12_ul"
local summary_vars = "`summary_vars' aQ aQ_ll aQ_ul"
local summary_vars = "`summary_vars' KQ_c4 KQ_c4_ll KQ_c4_ul"
local summary_vars = "`summary_vars' KQ_c12 KQ_c12_ll KQ_c12_ul"
local summary_vars = "`summary_vars' fcQ fcQ_ll fcQ_ul"
local summary_vars = "`summary_vars' R2"

frame create summary gene `summary_vars'
frame summary {
    quietly {
        label define gene_label 1 "{it: lasI}" 2 "{it: rhlI}" 3 "{it: lasB}"
        label values gene gene_label
    }
}

frame create lasi
frame lasi {
    quietly {
        use "Data/LasI.dta", clear
        keep if in_window
        egen mean_expression = mean(mean_rlu_od), by(c4 c12)
        label variable mean_expression "Mean RLU/OD for each concentration combination"
        model_rlu_od
        save "Models/LasIModel", replace
        export delimited c4 c12 predicted ///
            using "Models/LasIPredictions.csv" if unique_treatment, ///
            replace
        export delimited c4 c12 mean_expression ///
            using "Models/LasIMeans.csv" if unique_treatment, ///
            replace
        export delimited c4 c12 rlu_od ///
            using "Models/LasIObservations.csv", ///
            replace
        local post_vars = "(1)"
        foreach var of local summary_vars {
            local post_vars = "`post_vars' (`var'[1])"
        }
        frame post summary `post_vars'
    }

    show_model1 lasi c4 "`lasi_color'" "RLU/OD" "A"
	show_model1 lasi c12 "`lasi_color'" "RLU/OD" "D"
    show_model2 lasi "`lasi_color'"

}

graph export "Prefigures/model_lasi.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(model_lasi) replace

frame create rhli
frame rhli {
    quietly {
        use "Data/RhlI.dta", clear
        keep if in_window
        egen mean_expression = mean(mean_rlu_od), by(c4 c12)
        label variable mean_expression "Mean RLU/OD for each concentration combination"
        model_rlu_od
        save "Models/RhlIModel", replace
        export delimited c4 c12 predicted ///
            using "Models/RhlIPredictions.csv" if unique_treatment, ///
            replace
        export delimited c4 c12 mean_expression ///
            using "Models/RhlIMeans.csv" if unique_treatment, ///
            replace
        export delimited c4 c12 rlu_od ///
            using "Models/RhlIObservations.csv", ///
            replace
        local post_vars = "(2)"
        foreach var of local summary_vars {
            local post_vars = "`post_vars' (`var'[2])"
        }
        frame post summary `post_vars'
    }

    show_model1 rhli c4 "`rhli_color'" "" "B"
	show_model1 rhli c12 "`rhli_color'" "" "E"
    show_model2 rhli "`rhli_color'"
}

graph export "Prefigures/model_rhli.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(model_rhli) replace

frame create lasb
frame lasb {
    quietly {
        use "Data/LasB.dta", clear
        keep if in_window
        egen mean_expression = mean(mean_rlu_od), by(c4 c12)
        label variable mean_expression "Mean RLU/OD for each concentration combination"
        model_rlu_od
        save "Models/LasBModel", replace
        export delimited c4 c12 predicted ///
            using "Models/LasBPredictions.csv" if unique_treatment, ///
            replace
        export delimited c4 c12 mean_expression ///
            using "Models/LasBMeans.csv" if unique_treatment, ///
            replace
        export delimited c4 c12 rlu_od ///
            using "Models/LasBObservations.csv", ///
            replace
        local post_vars = "(3)"
        foreach var of local summary_vars {
            local post_vars = "`post_vars' (`var'[3])"
        }
        frame post summary `post_vars'
    }

    show_model1 lasb c4 "`lasb_color'" "" "C"
	show_model1 lasb c12 "`lasb_color'" "" "F"
    show_model2 lasb "`lasb_color'"
}

graph export "Prefigures/model_lasb.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(model_lasb) replace

graph combine lasi_c4 rhli_c4 lasb_c4 lasi_c12 rhli_c12 lasb_c12, ///
	ysize(3.125) ///
	name(model1, replace)

graph export "Prefigures/model1.svg", as(svg) ///
	baselineshift(on) fontface("`font'") ///
	name(model1) replace
    
frame change summary
label variable a0 "Basal expression (RLU/OD)"
label variable a_c4 "Maximum expression level increase from C4 (RLU/OD)"
label variable K_c4 "Half concentration for C4 (μM)"
label variable fc_c4 "Maximum fold-change from C4"
label variable a_c12 "Maximum expression level increase from C12 (RLU/OD)"
label variable K_c12 "Half concentration for C12 (μM)"
label variable fc_c12 "Maximum fold-change from C12"
label variable aQ "Maximum expression level increase from C4 and C12 (RLU/OD)"
label variable KQ_c4 "Cooperativity Half concentration for C4 (μM)"
label variable KQ_c12 "Cooperativity Half concentration for C12 (μM)"
label variable fcQ "Maximum fold-change from C4 and C12"
label variable R2 "R²"
quietly {
    save "Models/Summary", replace
    export delimited using "Models/Summary.csv", replace
}
