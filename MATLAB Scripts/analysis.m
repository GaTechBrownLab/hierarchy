%% Analysis of Dynamic System

clear; IntializeNotebook(Quiet=true);

% Constraints for each variable are defined but may be
% disabled (commented out) as they can significantly slow
% the solver.

% Signal concentrations: C12 and C4
S1 = sym("S_1"); assume(S1 >= 0); assumeAlso(S1, "real");
S2 = sym("S_2"); assume(S2 >- 0); assumeAlso(S2, "real");

% Basal expression level
a10 = sym("alpha_10"); assume(a10 >= 0); assumeAlso(a10, "real");
a20 = sym("alpha_20"); assume(a20 >= 0); assumeAlso(a20, "real");
E10 = a10;
E20 = a20;

% First order auto-induction for C12
a11 = sym("alpha_11"); assume(a11 >= 0); assumeAlso(a11, "real");
a12 = sym("alpha_12"); assume(a12 >= 0); assumeAlso(a12, "real");
K11 = sym("K_11"); assume(K11 >= 0); assumeAlso(K11, "real");
K12 = sym("K_12"); assume(K12 >= 0); assumeAlso(K12, "real");
E11 = a11 * S1 / (S1 + K11) + a12 * S2 / (S2 + K12);

% First order auto-induction for C4
a21 = sym("alpha_21"); assume(a21 >= 0); assumeAlso(a21, "real");
a22 = sym("alpha_22"); assume(a22 >= 0); assumeAlso(a22, "real");
K21 = sym("K_21"); assume(K21 >= 0); assumeAlso(K21, "real");
K22 = sym("K_22"); assume(K22 >= 0); assumeAlso(K22, "real");
E21 = a21 * S1 / (S1 + K21) + a22 * S2 / (S2 + K22);

% Second order auto-induction for C12
a112 = sym("alpha_112"); assume(a112 >= 0); assumeAlso(a112, "real");
KQ112 = sym("K_Q112"); assume(KQ112 >= 0); assumeAlso(KQ112, "real");
KQ121 = sym("K_Q121"); assume(KQ121 >= 0); assumeAlso(KQ121, "real");
E12 = a112 * S1 * S2 / ((S1 + KQ112) * (S2 + KQ121));

% Second order auto-induction for C4
a212 = sym("alpha_212"); assume(a212 >= 0); assumeAlso(a212, "real");
KQ212 = sym("K_Q212"); assume(KQ212 >= 0); assumeAlso(KQ212, "real");
KQ221 = sym("K_Q221"); assume(KQ221 >= 0); assumeAlso(KQ221, "real");
E22 = a212 * S1 * S2 / ((S1 + KQ212) * (S2 + KQ221));

% Expression level for each signal
E1 = E10 + E11 + E12;
E2 = E20 + E21 + E22;

% Environmental conditions: Population density and Mass transfer rate
N = sym("N"); assume(N > 0); assumeAlso(N, "real");
m = sym("m"); assume(m >= 0); assumeAlso(m, "real");

% Dynamics parameters
c1 = sym("c_1"); assume(c1 > 0); assumeAlso(c1, "real");
c2 = sym("c_2"); assume(c2 > 0); assumeAlso(c2, "real");
d1 = sym("delta_1"); assume(d1 > 0); assumeAlso(d1, "real");
d2 = sym("delta_2"); assume(d2 > 0); assumeAlso(d2, "real");

% Dynamics
dS1 = c1 * E1 * N - d1 * S1 - m * S1;
dS2 = c2 * E2 * N - d2 * S2 - m * S2;
dS = [dS1; dS2];

% Equilibrium, starting with the most general (reciprocal)
eqR = dS == [0; 0]

% Solve for reciprocal architecture first as that uses all
% parameters.
reciprocal = solve(eqR, [S1, S2], ReturnConditions=true);

% Remove (by setting to zero) parameters that are not part of
% hierarchical architecture.
alpha_12 = 0; alpha_112 = 0;
eqH = subs(eqR)
S1H = solve(eqH(1), S1, ReturnConditions=true);
S2H = solve(subs(eqH(2), S1, S1H.S_1), S2, ReturnConditions=true);

% Remove (by setting to zero) parameters that are not part of
% independent architecture.
alpha_21 = 0; alpha_212 = 0;
eqI = subs(eqH)

S1I = S1H;
S2I = solve(eqI(2), S2, ReturnConditions=true);

% Display solution
% Not really amenable to analysis

S1I.S_1(2)
%%
%% Local Functions

function IntializeNotebook(Options)
% InitializeNotebook() ensures that the live script notebook is in a known
% starting state. Its intent is to guarantee reproducability of the
% notebook results. Note that the `clear` command does not have full
% effect when implemented within a function. Consequently, the notebook
% should execute that command explicitly before calling this function.
%
% For documentation, this function will, by default, display version and
% platform information within the notebook.
    arguments
        Options.Quiet logical = false; % if true, don't show version info
    end

    % clear workspace elements
    clc; clf;

    % initialize environment
    rng default;  % set random number generator for reproducibility
    
    if ~Options.Quiet
        % show version/platform information
        disp(strcat("This notebook created on ", string(datetime)))
        % suppress needless warning message about product ''
        warning('off', 'MATLAB:ver:NotFound');
            ver '' % don't bother with unused toolboxes, etc.
        warning('on',  'MATLAB:ver:NotFound');
    end

end

function SetStyles() %#ok<DEFNU>
% Set styles such as fonts and colors for notebook.

    Settings = settings;
    Settings.matlab.fonts.editor.normal.Name.TemporaryValue = "Lucida Bright OT";
    Settings.matlab.fonts.editor.title.Name.TemporaryValue = "Lucida Sans OT";
    Settings.matlab.fonts.editor.heading1.Name.TemporaryValue = "Lucida Sans OT";
    Settings.matlab.fonts.editor.heading2.Name.TemporaryValue = "Lucida Sans OT";
    Settings.matlab.fonts.editor.heading3.Name.TemporaryValue = "Lucida Sans OT";
    Settings.matlab.fonts.editor.code.Name.TemporaryValue = "Lucida Console DK";
    Settings.matlab.fonts.codefont.Name.TemporaryValue = "Lucida Console DK";
end