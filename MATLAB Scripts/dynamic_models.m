%% Dynamical Systems Models

clear; IntializeNotebook(Quiet=true);

%% Styles


% SetStyles(); 
FontName = "Arial"; % "Lucida Sans OT";

%% Setup


% Retrieve model parameter estimates. Since these values are
% used throughout the notebook, they're stored as global data
% to avoid Workspace clutter and verbose function signatures.

LoadModel();
% global Model; % uncomment this line to expose model to workspace

% Number of increments to calculate/show. Larger number
% for higher resolution at cost of more computation.
Steps = 500;

% Signal concentration in μM
Smin = 0;
Smax = 2;
C4Range = Smin : Smin + (Smax - Smin) / Steps : Smax;
C12Range = Smin : Smin + (Smax - Smin) / Steps : Smax;

% Secondary signal concentration
S2Steps = 5;
S2Range = Smin : Smin + (Smax - Smin) / S2Steps : Smax;

% Population density in units ~ 100 * OD
Nmin = 0;
Nmax = 100;
NRange = Nmin : Nmin + (Nmax - Nmin) / Steps : Nmax;

% DecayRate determined through manual calibration
DecayRate = 5000000;

% Mass transfer rates (relative to decay rate)
Mmin = 0;
Mmax = 5 * DecayRate;
MRange = Mmin : Mmin + (Mmax - Mmin) / Steps : Mmax;

%% LasI Expression Level for Model Variations

ColumnNames = [
    "C12", ...
    "LasIPlus" ...
    ];
for C4 = S2Range
    ColumnNames(end + 1) = "LasI(C4=" + string(C4) + ")"; %#ok<SAGROW>
end

LasIExpTable = table( ...
    'Size', [Steps + 1, length(ColumnNames)], ...
    'VariableTypes', repmat({'double'}, 1, length(ColumnNames)), ...
    'VariableNames', ColumnNames ...
    );

for C12idx = 1 : Steps + 1
    C12 = C12Range(C12idx);

    LasIExpTable{C12idx, "C12"} = C12;
    LasIExpTable{C12idx, "LasIPlus"} = LasIExp(0, C12, Scale=true);
    for C4 = S2Range
        Column = "LasI(C4=" + string(C4) + ")";
        LasIExpTable{C12idx, Column} = LasIExp(C4, C12);
    end
end

%% RhlI Expression Level for Model Variations

ColumnNames = [
    "C4", ...
    "RhlIPlus" ...
    ];
for C12 = S2Range
    ColumnNames(end + 1) = "RhlI(C12=" + string(C12) + ")"; %#ok<SAGROW>
end

RhlIExpTable = table( ...
    'Size', [Steps + 1, length(ColumnNames)], ...
    'VariableTypes', repmat({'double'}, 1, length(ColumnNames)), ...
    'VariableNames', ColumnNames ...
    );

for C4idx = 1 : Steps + 1
    C4 = C4Range(C4idx);

    RhlIExpTable{C4idx, "C4"} = C4;
    RhlIExpTable{C4idx, "RhlIPlus"} = RhlIExp(C4, 0, Scale=true);
    for C12 = S2Range
        Column = "RhlI(C12=" + string(C12) + ")";
        RhlIExpTable{C4idx, Column} = RhlIExp(C4, C12);
    end
end

%% Equilibrium Signal Concentrations by Density

% Solve for S* values using estimated parameters and
% scaled values of those parameters for independent
% and hierarchical architectures.

SolveOptions = optimoptions('fsolve', 'Display', 'none');

% Population density only; no mass transfer
ColumnNames = [
    "N", ...
    "C4Independent", "C12Independent", ...
    "C4Hierarchy",   "C12Hierarchy", ...
    "C4Reciprocal",  "C12Reciprocal", ...
    "C4IndependentPlus", "C12IndependentPlus", ...
    "C4HierarchyPlus",   "C12HierarchyPlus", ...
    "LasBIndependent", "LasBIndependentPlus", ...
    "LasBHierarchy", "LasBHierarchyPlus", ...
    "LasBReciprocal"
    ];
NTable = table( ...
    'Size', [Steps + 1, length(ColumnNames)], ...
    'VariableTypes', repmat({'double'}, 1, length(ColumnNames)), ...
    'VariableNames', ColumnNames ...
    );

M = Mmin;
for Nidx = 1 : Steps + 1
    N = NRange(Nidx);
    NTable{Nidx, "N"} = N / 100; % convert to ~ ODU

    % solve the dynamical system for equilibrium concentrations
    dS = @(S) Dynamics(S, N, Decay = DecayRate, MassTransfer = M);
    Sstar = fsolve(dS, [1, 1], SolveOptions);
    NTable{Nidx, "C4Reciprocal"} = Sstar(1);
    NTable{Nidx, "C12Reciprocal"} = Sstar(2);

    % for independent architecture, signal values can be found
    % from simple algebra - no need for dynamical system
    NTable{Nidx, "C4Independent"}   = C4Star(N, DecayRate, M);
    NTable{Nidx, "C12Independent"}  = C12Star(N, DecayRate, M);

    % for hierarchy, C12 is unaffected by C4, so C12 value is
    % same as in independent; with known C12, solving for C4
    % is again simple algebra
    NTable{Nidx, "C4Hierarchy"}  = C4Star(N, DecayRate, M, ...
        C12=NTable{Nidx, "C12Independent"});
    NTable{Nidx, "C12Hierarchy"} = NTable{Nidx, "C12Independent"};

    % artificially scaled values - same approach but artificially upscale
    % since the cross-signals effects on lasI and rhlI have been removed
    NTable{Nidx, "C4IndependentPlus"}   = C4Star(N, DecayRate, M, Scale=true);
    NTable{Nidx, "C12IndependentPlus"}  = C12Star(N, DecayRate, M, Scale=true);

    % don't artificially upscale C4 concentration in hierarchical model; 
    % in hierarchy, explicitly account for C12; C12, on the other hand,
    % needs upscaling because the influence of C4 on lasI has been removed.
    % That upscaling is incorporated in the value already calculated for
    % independent architecture.
    NTable{Nidx, "C4HierarchyPlus"}  = C4Star(N, DecayRate, M, C12=NTable{Nidx, "C12IndependentPlus"});
    NTable{Nidx, "C12HierarchyPlus"} = NTable{Nidx, "C12IndependentPlus"};
end

%% Equilibrium Signal Concentrations by Mass Transfer 

% Mass transfer only, population density at max value
ColumnNames(1) = "M";
MTable = table( ...
    'Size', [Steps + 1, length(ColumnNames)], ...
    'VariableTypes', repmat({'double'}, 1, length(ColumnNames)), ...
    'VariableNames', ColumnNames ...
    );

N = Nmax;
for Midx = 1 : Steps + 1
    M = MRange(Midx);
    MTable{Midx, "M"} = M / DecayRate;

    % solve the dynamical system for equilibrium concentrations
    dS = @(S) Dynamics(S, N, Decay = DecayRate, MassTransfer = M);
    Sstar = fsolve(dS, [1, 1], SolveOptions);
    MTable{Midx, "C4Reciprocal"} = Sstar(1);
    MTable{Midx, "C12Reciprocal"} = Sstar(2);

    % for independent architecture, signal values can be found
    % from simple algebra - no need for dynamical system
    MTable{Midx, "C4Independent"}   = C4Star(N, DecayRate, M);
    MTable{Midx, "C12Independent"}  = C12Star(N, DecayRate, M);

    % for hierarchy, C12 is unaffected by C4, so C12 value is
    % same as in independent; with known C12, solving for C4
    % is again simple algebra
    MTable{Midx, "C4Hierarchy"}  = C4Star(N, DecayRate, M, ...
        C12=MTable{Midx, "C12Independent"});
    MTable{Midx, "C12Hierarchy"} = MTable{Midx, "C12Independent"};

    % artificially scaled values - same approach but artificially upscale
    % since the cross-signals effects on lasI and rhlI have been removed
    MTable{Midx, "C4IndependentPlus"}   = C4Star(N, DecayRate, M, Scale=true);
    MTable{Midx, "C12IndependentPlus"}  = C12Star(N, DecayRate, M, Scale=true);

    % don't artificially upscale C4 concentration in hierarchical model; 
    % in hierarchy, explicitly account for C12; C12, on the other hand,
    % needs upscaling because the influence of C4 on lasI has been removed.
    % That upscaling is incorporated in the value already calculated for
    % independent architecture.
    MTable{Midx, "C4HierarchyPlus"}  = C4Star(N, DecayRate, M, C12=MTable{Midx, "C12IndependentPlus"});
    MTable{Midx, "C12HierarchyPlus"} = MTable{Midx, "C12IndependentPlus"};
end

%% LasB Expression Levels

NTable.LasBIndependent = arrayfun(@LasBExp, NTable.C4Independent, NTable.C12Independent);
NTable.LasBIndependentPlus = arrayfun(@LasBExp, NTable.C4IndependentPlus, NTable.C12IndependentPlus);
NTable.LasBHierarchy = arrayfun(@LasBExp, NTable.C4Hierarchy, NTable.C12Hierarchy);
NTable.LasBHierarchyPlus = arrayfun(@LasBExp, NTable.C4HierarchyPlus, NTable.C12HierarchyPlus);
NTable.LasBReciprocal = arrayfun(@LasBExp, NTable.C4Reciprocal, NTable.C12Reciprocal);

MTable.LasBIndependent = arrayfun(@LasBExp, MTable.C4Independent, MTable.C12Independent);
MTable.LasBIndependentPlus = arrayfun(@LasBExp, MTable.C4IndependentPlus, MTable.C12IndependentPlus);
MTable.LasBHierarchy = arrayfun(@LasBExp, MTable.C4Hierarchy, MTable.C12Hierarchy);
MTable.LasBHierarchyPlus = arrayfun(@LasBExp, MTable.C4HierarchyPlus, MTable.C12HierarchyPlus);
MTable.LasBReciprocal = arrayfun(@LasBExp, MTable.C4Reciprocal, MTable.C12Reciprocal);

%% Save Results

writetable(LasIExpTable, "LasIExpression.csv");
writetable(RhlIExpTable, "RhlIExpression.csv");
writetable(NTable, "DynamicsN.csv");
writetable(MTable, "DynamicsM.csv");

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

function LoadModel()
% LoadModel() retrieves and formats model parameters
    global Model; %#ok<*GVMIS> 

    Model = readtable("../Models/Summary.csv", 'ReadRowNames', true);
    GenesRegex = regexpPattern('lasI|rhlI|lasB');
    Model.Properties.RowNames = cellfun(@(str) ...
        extract(str, GenesRegex), Model.Properties.RowNames);
    Model = fillmissing(Model, 'constant', 0);

end

function Conc = C12Star(N, D, M, Options)
% Returns equilibrium concentration for C12 assuming no
% effect from C4
    arguments
        N double; % population density
        D double; % decay rate
        M double; % mass transfer rate
        Options.Ratio double = 1.7; % C12/C4 decay rates
        Options.Scale logical = false; % artificially scale?
    end
    global Model;

    % Account for difference in decay rates
    D = Options.Ratio * D;

    a0 = Model{"lasI", "a0"};
    a  = Model{"lasI", "a_c12"};
    K  = Model{"lasI", "K_c12"};

    if Options.Scale
        a = a + Model{"lasI", "a_c4"} + Model{"lasI", "aQ"};
    end

    %   0 = dS = [ a0 + a_c12 * S / (K_c12 + S) ] * N - [ D + M ] * S
    %   0 = a0 * N * (K + S) + a * N * S - (D + M) * S * (K + S)
    %   0 = (a0 * N * K) + (a0 * N) * S + (a * N) * S - 
    %       (D + M) * K * S - (D + M) * S^2
    Roots = roots([ ...
        -1 * (D + M), ...                % S^2
        (a0 + a) * N - (D + M) * K, ...  % S^1
        a0 * K * N ...                   % S^0
    ]);
    Conc = max(Roots);
end

function Conc = C4Star(N, D, M, Options)
% Returns equilibrium concentration for C4 assuming C4
% has no effect on C12
    arguments
        N double; % population density
        D double; % decay rate
        M double; % mass transfer rate
        Options.C12 double = 0; % C12 value (<0 to ignore)
        Options.Scale logical = false; % artificially scale?
    end
    global Model;

    a0 = Model{"rhlI", "a0"};
    a  = Model{"rhlI", "a_c4"};
    K  = Model{"rhlI", "K_c4"};

    % Adjust for non-zero C12. These calculation are simplificiations
    % based on the value of KQ_c4 and KQ_c12 being approximately zero.
    if (Options.C12 > 0)
        S2 = Options.C12;
        a2 = Model{"rhlI", "a_c12"};
        K2 = Model{"rhlI", "K_c12"};
        aQ = Model{"rhlI", "aQ"};
        a0 = a0 + a2 * S2 / (S2 + K2) + aQ;
    elseif Options.Scale
        a = a + Model{"rhlI", "a_c12"} + Model{"rhlI", "aQ"};
    end

    Roots = roots([ ...
        -1 * (D + M), ...                % S^2
        (a0 + a) * N - (D + M) * K, ...  % S^1
        a0 * K * N ...                   % S^0
    ]);
    Conc = max(Roots);
end

function RLU_OD = LasIExp(C4, C12, Options)
% LasIExp() estimates lasI expression level in RLU/OD
% from C4 and C12 concentrations using model parameters 
    arguments
        C4 double;   % C₄‑HSL concentration (μM)
        C12 double;  % 3‑oxo‑C₁₂‑HSL concentration (μM)
        Options.Scale logical = false; % artificially scale?
    end
    global Model;

    % Avoid 0/0 errors
    C4(C4 == 0) = sqrt(realmin);
    C12(C12 == 0) = sqrt(realmin);

    a0 = Model{"lasI", "a0"};
    a = Model{"lasI", "a_c12"};
    a2 = Model{"lasI", "a_c4"};
    aQ = Model{"lasI", "aQ"};

    if Options.Scale
        a = a + a2 + aQ;
        a2 = 0;
        aQ = 0;
    end

    RLU_OD = a0 + ...
        a  * C12 ./ (Model{"lasI", "K_c12"} + C12) + ...
        a2 * C4  ./ (Model{"lasI", "K_c4"}  + C4)  + ...
        aQ * C4 .* C12 ./ ( ...
            (Model{"lasI", "KQ_c4"}  + C4) .* (Model{"lasI", "KQ_c12"}  + C12) ...
        );
end

function RLU_OD = RhlIExp(C4, C12, Options)
% RhlIExp() estimates rhlI expression level in RLU/OD
% from C4 and C12 concentrations using model parameters 
    arguments
        C4 double;   % C₄‑HSL concentration (μM)
        C12 double;  % 3‑oxo‑C₁₂‑HSL concentration (μM)
        Options.Scale logical = false; % artificially scale?
    end
    global Model;

    % Avoid 0/0 errors
    C4(C4 == 0) = sqrt(realmin);
    C12(C12 == 0) = sqrt(realmin);

    a0 = Model{"rhlI", "a0"};
    a = Model{"rhlI", "a_c4"};
    a2 = Model{"rhlI", "a_c12"};
    aQ = Model{"rhlI", "aQ"};

    if Options.Scale
        a = a + a2 + aQ;
        a2 = 0;
        aQ = 0;
    end

    RLU_OD = a0 + ...
        a  * C4  ./ (Model{"rhlI", "K_c4"}  + C4)  + ...
        a2 * C12 ./ (Model{"rhlI", "K_c12"}  + C12) + ...
        aQ * C4 .* C12 ./ ( ...
            (Model{"rhlI", "KQ_c4"}  + C4) .* (Model{"rhlI", "KQ_c12"}  + C12) ...
        );
end

function RLU_OD = LasBExp(C4, C12)
% LasBExp() estimates lasI expression level in RLU/OD
% from C4 and C12 concentrations using model parameters 
    arguments
        C4 double;   % C₄‑HSL concentration (μM)
        C12 double;  % 3‑oxo‑C₁₂‑HSL concentration (μM)
    end
    global Model;

    % Avoid 0/0 errors
    C4(C4 == 0) = sqrt(realmin);
    C12(C12 == 0) = sqrt(realmin);

    RLU_OD = Model{"lasB", "a0"} + ...
        Model{"lasB", "a_c4"}  * C4    ./ (Model{"lasB", "K_c4"}  + C4)  + ...
        Model{"lasB", "a_c12"} * C12   ./ (Model{"lasB", "K_c12"} + C12) + ...
        Model{"lasB", "aQ"} * C4 .* C12 ./ ( ...
            (Model{"lasB", "KQ_c4"}  + C4) .* (Model{"lasB", "KQ_c12"}  + C12) ...
        );
end

function DeltaS = Dynamics(S, N, Options)
% Dynamics() calculates the dynamics of the system of two
% signals as the change in concentration for each signal
    arguments
        S (2, 1) double;  % [C4, C12] concentration
        N double;  % population size
        Options.Decay double; % C4 decay rate
        Options.MassTransfer double = 0;
        Options.Ratio double = 1.7; % C12/C4 decay rates
    end

    DeltaS = [ ...
        N * RhlIExp(S(1), S(2)) - ...
            S(1) * (Options.Decay + Options.MassTransfer);
        N * LasIExp(S(1), S(2)) - ...
            S(2) * (Options.Ratio * Options.Decay + Options.MassTransfer),
    ];

end
