
// Standard script initialization
version 18          // Stata version used to create/execute this script
set more off        // disable pause of output display every full screen
clear all           // ensure clean slate
capture log close   // close any pending logs
set seed 123456789  // consistent random number generation

// Visualization settings
set scheme s1color  // graphics color scheme (theme)
local font = "Arial" // "Lucida Sans OT" for better typography
graph set window fontface "`font'"
quietly include "Stata Scripts/00colors.do"

// Get model parameters from the summary data file. Notation from paper Eq. 2
//   i  = 1, 2 (lasI, rhlI)
//   j  = 1, 2 (C12, C4)
//   j' = 1, 2 (C12, C4)
// Note that we ensure that all K values are non-zero to avoid 
// division-by-zero issues in calculations
quietly {
	use "Models/Summary.dta", clear
	
	// lasI basal expression
	summarize a0 if gene=="{it: lasI}":gene_label, meanonly
	scalar a10 = r(mean)
		
	// lasI first order C12
	summarize a_c12 if gene=="{it: lasI}":gene_label, meanonly
	scalar a11 = r(mean)
	summarize K_c12 if gene=="{it: lasI}":gene_label, meanonly
	scalar K11 = max(r(mean), smallestdouble())

	// lasI first order C4
	summarize a_c4 if gene=="{it: lasI}":gene_label, meanonly
	scalar a12 = r(mean)
	summarize K_c4 if gene=="{it: lasI}":gene_label, meanonly
	scalar K12 = max(r(mean), smallestdouble())

	// lasI second order
	summarize aQ if gene=="{it: lasI}":gene_label, meanonly
	scalar a112 = r(mean)
	summarize KQ_c12 if gene=="{it: lasI}":gene_label, meanonly
	scalar K112 = max(r(mean), smallestdouble())
	summarize KQ_c4 if gene=="{it: lasI}":gene_label, meanonly
	scalar K121 = max(r(mean), smallestdouble())

	// rhlI basal expression
	summarize a0 if gene=="{it: rhlI}":gene_label, meanonly
	scalar a20 = r(mean)
		
	// rhlI first order C12
	summarize a_c12 if gene=="{it: rhlI}":gene_label, meanonly
	scalar a21 = r(mean)
	summarize K_c12 if gene=="{it: rhlI}":gene_label, meanonly
	scalar K21 = max(r(mean), smallestdouble())

	// rhlI first order C4
	summarize a_c4 if gene=="{it: rhlI}":gene_label, meanonly
	scalar a22 = r(mean)
	summarize K_c4 if gene=="{it: rhlI}":gene_label, meanonly
	scalar K22 = max(r(mean), smallestdouble())

	// rhlI second order
	summarize aQ if gene=="{it: rhlI}":gene_label, meanonly
	scalar a212 = r(mean)
	summarize KQ_c12 if gene=="{it: rhlI}":gene_label, meanonly
	scalar K212 = max(r(mean), smallestdouble())
	summarize KQ_c4 if gene=="{it: lasI}":gene_label, meanonly
	scalar K221 = max(r(mean), smallestdouble())
}

// Program to estimate synthase expression level from signal concentrations
// Again, using notation from paper Equation 2
//   i  = 1, 2 (lasI, rhlI)
//   j  = 1, 2 (C12, C4)
// Results returned as r(E1) and r(E2)
capture program drop Expression
program define Expression, rclass
	args S1 S2 // concentration of C12 and C4, respectively
	return scalar E1 = a10 ///
	   + a11 * `S1' / (K11 + `S1') + a12 * `S2' / (K12 + `S2') ///
	   + a12 * `S1' * `S2' / ((K112 + `S1') * (K121 + `S2'))
	return scalar E2 = a20 ///
	   + a21 * `S1' / (K21 + `S1') + a22 * `S2' / (K22 + `S2') ///
	   + a22 * `S1' * `S2' / ((K212 + `S1') * (K221 + `S2'))
end

// Retrieve the experimental observations and expose the data points needed:
// the mean steady-state concentrations of C4 and C12 for a range of population
// densities.
quietly {
	import delimited "Raw Data/ds5721-AHL-finalpredicted.csv", case(lower) clear
	// Calculate the mean signal concentrations at each reference
	by ref, sort: egen S1 = mean(um) if signal=="C12"
	by ref, sort: egen S2 = mean(um) if signal=="C4"
	// Retain one value for each combination of signal and reference
	egen tag = tag(ref signal)
	keep if tag
	// Combine observations for C4 and C12
	sort ref signal
	replace S1 = S1[_n-1] if missing(S1)
	replace S2 = S2[_n+1] if missing(S2)
	keep if signal=="C4"
	// Retain variables of interest
	generate N = density
	keep N S1 S2
	format N %3.2f
	format S1 S2 %3.2f
	// Estimate synthase expression levels using the primary model
	generate double E1 = .
	generate double E2 = .
	local Nobs = _N
	forvalues n = 1/`Nobs' {
		Expression S1[`n'] S2[`n']
 		replace E1 = r(E1) in `n'
 		replace E2 = r(E2) in `n'
	}
}

// Use non-linear least squares to estimate values for proportionality constants
// in Equation 3: solve for equilibrium at dS/dt = 0, with m = 0, i.e.
//
//     0 = (1/𝛅2) * dSi/dt = ci/𝛅2 * Ei(S) * N - (𝛅i/𝛅2) * Si
//
//     N = (𝛅i/𝛅2) * Si / [ci/𝛅2 * Ei(S)]
//
// Note: 𝛅1/𝛅2 ≈ 1.7 (reference in paper)

nl (N = 1.7 * S1 / ({c1_d2} * E1)), initial(c1_d2 0.00002) nolog
quietly {
	scalar c1_d2 = _b[/c1_d2]
	predictnl N1 = 1.7 * S1 / (_b[/c1_d2] * E1)
}

nl (N = 1.0 * S2 / ({c2_d2} * E2)), initial(c2_d2 0.00002) nolog
quietly {
	scalar c2_d2 = _b[/c2_d2]
	predictnl N2 = 1.0 * S2 / (_b[/c2_d2] * E2)
}

quietly {
	generate c1 = c1_d2
	generate c2 = c2_d2
	keep c1 c2
	keep in 1
	export delimited using "Models/Dynamics.csv", replace
}
