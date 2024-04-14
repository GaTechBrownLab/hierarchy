%% Dynamical Systems Models

clear; IntializeNotebook(Quiet=true);
%% Styles

% Styles relevant for the notebook (live script) itself; not
% relevant for actual plots, so not essential
% SetStyles();

% Next styles used in plots, so useful even in standard scripts
% Define these as globals so that local functions can reference
% them if needed.

global FontName;
FontName   = "Arial"; % "Lucida Sans OT"

global C4Color C12Color MixedColor LasBColor LasIColor RhlIColor;
C4Color    = [237,176,129]/255;
C12Color   = [193,65,104]/255;
MixedColor = [229,113,94]/255;
LasBColor  = [44,49,114]/255;
LasIColor  = [165,205,144]/255;
RhlIColor  = [52,133,141]/255;

% Custom color maps
global crest flare;
load("crest.mat");
load("flare.mat");
%% Setup

% Retrieve model parameter estimates. Since these values are
% used throughout the notebook, they're stored as global data
% to avoid Workspace clutter and verbose function signatures.

LoadModel();
% global Model; % uncomment this line to expose model to workspace
%% Parameterize Dynamic Model

% In order to fully parameterize the dynamic model of Equation 3, we
% must estimate the proportionality constants that scale synthase
% expresssion level to per-capita signal production. Observations
% referenced in text provide data for those estimates.
% Get Observational Data

DensitySignalFile = "../Raw Data/ds5721-AHL-finalpredicted.csv";
% We don't need the entire contents of the file, so parse it to detect
% the options available and only retrieve the information we need.
DensitySignalOptions = detectImportOptions(DensitySignalFile);
% Get only the columns we need.
DensitySignalOptions.SelectedVariableNames = ["signal", "uM", "density"];
DensitySignalData = readtable(DensitySignalFile, DensitySignalOptions);
% Separate C4 and C12 data.
DensityC4Data = DensitySignalData(DensitySignalData.signal == "C4", :);
DensityC12Data = DensitySignalData(DensitySignalData.signal == "C12", :);
% Estimate Proportionality Constants

% Use non-linear least squares to estimate the constants

LSQFn = @(c_d2) DensitySignalObjectiveFn( ...
    c_d2 = c_d2, ...
    Data = DensitySignalData, ...
    mean_C12 = mean(DensityC12Data.uM), ...
    mean_C4 = mean(DensityC4Data.uM) ...
);
c_d2 = lsqnonlin( ...
    LSQFn, ...               % Objective function to minimize
    [0.00002, 0.00002], ...  % Starting guess for constants
    [0 0], ...               % Lower bounds for constants
    [Inf Inf], ...           % Upper bounds for constants
    optimoptions('lsqnonlin', Display = "off") ...  % No logging
);

% Predict Concentrations

Nmin = 0;
Nmax = max(0.8, 1.1 * max(DensitySignalData.density));
Nrange = Nmin : (Nmax - Nmin) / 100 : Nmax;
S1 = []; S2 = []; LasB = [];
for N = Nrange
    Sstar = Equilibrium(N = N, m_d2 = 0, c_d2 = c_d2);
    S1(end + 1) = Sstar(1); %#ok<SAGROW>
    S2(end + 1) = Sstar(2); %#ok<SAGROW>
    % Also estimate LasB while we're iterating through the range
    LasB(end + 1) = LasBExp(C12 = Sstar(1), C4 = Sstar(2)); %#ok<SAGROW>
end

% Compare Predictions and Observations

PlotConstants = plot( ...
    DensityC12Data.density, DensityC12Data.uM, "o", ...
    DensityC4Data.density, DensityC4Data.uM, "o", ...
    Nrange, S1, ":", ...
    Nrange, S2, ":", ...
    LineWidth = 2 ...
);
PlotConstants(1).Color = C12Color;
PlotConstants(2).Color = C4Color;
PlotConstants(3).Color = C12Color;
PlotConstants(4).Color = C4Color;
ax = gca;
ax.FontName = FontName;
xlabel("Population Density (~ OD600)", FontName=FontName, FontSize=14); 
xtickformat('%.1f')
ylabel("Concentration (μM)", FontName=FontName, FontSize=14);
title("Equilibrium Signal Concentration", FontName=FontName, FontSize=16);
legend(["3–oxo–C_{12}–HSL", "C_{4}-HSL", "", ""], FontName=FontName, FontSize=14, Location='northwest');
exportgraphics(ax, "../Prefigures/constants.pdf", 'ContentType', 'vector');
%% _lasB_ Expression

% Data from Rattray et al. 2022 (see text)
AggregateDataFile = "../Raw Data/Rattray.csv";
% We don't need the entire contents of the file, so parse it to detect
% the options available and only retrieve the information we need.
AggregateDataOptions = detectImportOptions(AggregateDataFile);
% Get only the columns we need.
AggregateDataOptions.SelectedVariableNames = ["od", "mean_expression"];
AggregateDataOptions.MissingRule = 'omitrow';
AggregateDataOptions.ImportErrorRule = 'omitrow';
AggregateData = readtable(AggregateDataFile, AggregateDataOptions);

% Calculate model estimate of lasB expression for measured densities
for i = 1: height(AggregateData)
    Sstar = Equilibrium(N = AggregateData.od(i), m_d2 = 0, c_d2 = c_d2);
    AggregateData.model(i) = LasBExp(C12 = Sstar(1), C4 = Sstar(2));
end

% Linear regression to map observed pixel intensity to estimated expression.
X = [ones(length(AggregateData.mean_expression), 1) AggregateData.mean_expression];
Y = AggregateData.model;
b = X \ Y;
Ypredict = X * b;

% Calculate (and show) coefficient of determination
R2 = 1 - sum((Y - Ypredict).^2)/sum((Y - mean(Y)).^2)

Xrange = [1 1; 2.25 13.25];
Yrange = Xrange' * b;

figure;

yyaxis left
plot(Nrange, LasB, LineWidth = 3, Color = LasBColor);
ax = gca;
ax.FontName = FontName;
ax.YColor = [0 0 0];
xlabel("Population Density (~ OD600)", FontName=FontName, FontSize=14);
xtickformat('%.1f')
ylabel("Predicted Per-Capita Expression (RLU/OD)", FontName=FontName, FontSize=14);
ylim(Yrange);

yyaxis right
scatter(AggregateData.od, AggregateData.mean_expression, 50, RhlIColor, LineWidth=2);
ylabel("Observed Per-Capita Response (Pixel Intensity)", FontName=FontName, FontSize=14);
ax = gca;
ax.FontName = FontName;
ax.YColor = [0 0 0];
ylim(Xrange(2,:));
title("\it lasB\rm\bf Expression", FontName=FontName, FontSize=16);
legend({"Model", "Observations"}, FontName=FontName, FontSize=14, Location='northwest');
exportgraphics(ax, "../Prefigures/lasb_response.pdf", 'ContentType', 'vector');
%% Visualize Full Models

% Now that the dynamic model is fully parameterized, explore its
% behavior under different conditions of population density and
% mass transfer. We consider a total of five different cases.
% For hierarhical and independent architectures, scaled and
% unscaled versions are options.

Architectures = {
    {"reciprocal",   false}, ...
    {"hierarchical", false}, ...
    {"hierarchical", true},  ...
    {"independent",  false}, ...
    {"independent",  true}
};

Columns = [
    ["Architecture", "string"]; ...
    ["Scaled",       "logical"]; ... 
    ["Density",      "double"]; ... 
    ["MassTransfer", "double"]; ...
    ["C12",          "double"]; ...
    ["C4",           "double"]; ...
    ["lasB",         "double"] ...
];

% Varying Population Density
Nrange = 0 : 0.01 : 1.0;

% Varying Mass Transfer
Mrange = 0 : 0.05 : 5.0;

NMtable = table( ...
    'Size', [length(Architectures) * length(Mrange) * length(Nrange), height(Columns)], ...
    'VariableNames', Columns(:,1), ...
    'VariableTypes', Columns(:,2) ...
);

idx = 1;
for idxArch = 1 : length(Architectures)
    Architecture = Architectures{idxArch}{1};
    Scale = Architectures{idxArch}{2};
    for N = Nrange
        S0 = [1, 1];
        for M = Mrange
            Sstar = Equilibrium(N = N, m_d2 = M, c_d2 = c_d2, Architecture = Architecture, Scale = Scale, S0 = S0);
            lasB = LasBExp(C12 = Sstar(1), C4 = Sstar(2));
            NMtable.Architecture(idx) = Architecture;
            NMtable.Scaled(idx) = Scale;
            NMtable.Density(idx) = N;
            NMtable.MassTransfer(idx) = M;
            NMtable.C12(idx) = Sstar(1);
            NMtable.C4(idx) = Sstar(2);
            NMtable.lasB(idx) = lasB;
            idx = idx + 1;
            S0 = Sstar;
        end
    end
end

% Extract lasB response as NxM matrix so it can be treated as
% a pixel image. Note that the data must be sorted appropriately
% so that the image is in row-major order with respect to mass
% transfer. That means mass-transfer will be the x-axis of the
% image. Also note that density is sorted in descending order
% so that higher density values are first, e.g. the "top" of
% the image and in their natural position for a y-axis.

Recip = reshape( ...
          sortrows( ...
            NMtable(NMtable.Architecture == "reciprocal", :), ...
            {'MassTransfer', 'Density'}, {'ascend', 'descend'} ...
          ).lasB, ...
          length(Nrange), length(Mrange) ...
        );
Hier  = reshape( ...
          sortrows( ...
            NMtable(NMtable.Architecture == "hierarchical" & ~NMtable.Scaled, :), ...
            {'MassTransfer', 'Density'}, {'ascend', 'descend'} ...
          ).lasB, ...
          length(Nrange), length(Mrange) ...
        );
Indep = reshape( ...
          sortrows( ...
            NMtable(NMtable.Architecture == "independent" & ~NMtable.Scaled, :), ...
            {'MassTransfer', 'Density'}, {'ascend', 'descend'} ...
          ).lasB, ...
          length(Nrange), length(Mrange) ...
        );
HierScaled  = reshape( ...
          sortrows( ...
            NMtable(NMtable.Architecture == "hierarchical" & NMtable.Scaled, :), ...
            {'MassTransfer', 'Density'}, {'ascend', 'descend'} ...
          ).lasB, ...
          length(Nrange), length(Mrange) ...
        );
IndepScaled = reshape( ...
          sortrows( ...
            NMtable(NMtable.Architecture == "independent" & NMtable.Scaled, :), ...
            {'MassTransfer', 'Density'}, {'ascend', 'descend'} ...
          ).lasB, ...
          length(Nrange), length(Mrange) ...
        );

% Use the same range for all heatmaps so that they can be compared 
% against each other easily. It's the max and min values from
% the reciprocal architcture

ExpRange=[min(Recip,[],"all"), max(Recip,[],"all")];

% Generate native heatmap to check results below. This heatmap isn't used
% in paper since low level functions provide better control over axes,
% etc., but it can be helpful to verify low level results, especially
% plot orientation. Note that MATLAB orients heatmaps so that rows are
% shown in descending order, so the y-axis will be flipped.

%figure
%heatmap(NMtable(NMtable.Architecture == "reciprocal", :), ...
%    "MassTransfer", "Density", ColorVariable="lasB", ...
%    GridVisible="off", Colormap=flare);

% Create the final heatmaps - unscaled versions first
Heatmaps = figure;
colormap(flare);

tiledlayout(1,3);
nexttile;
MakeHeatmap(expLevel=Recip, expRange=ExpRange, archName="Reciprocal", nRange=Nrange, mRange=Mrange);
nexttile;
MakeHeatmap(expLevel=Hier, expRange=ExpRange, archName="Hierarchical", nRange=Nrange, mRange=Mrange);
nexttile;
MakeHeatmap(expLevel=Indep, expRange=ExpRange, archName="Independent", nRange=Nrange, mRange=Mrange);

exportgraphics(Heatmaps, "../Prefigures/lasb_heatmaps.pdf", 'ContentType', 'vector');

% Repeat for scaled versions

ScaledHeatmaps = figure;
colormap(crest);

tiledlayout(1,3);
nexttile;
MakeHeatmap(expLevel=Recip, expRange=ExpRange, archName="Reciprocal", nRange=Nrange, mRange=Mrange);
nexttile;
MakeHeatmap(expLevel=HierScaled, expRange=ExpRange, archName="Rescaled Hierarchical", nRange=Nrange, mRange=Mrange);
nexttile;
MakeHeatmap(expLevel=IndepScaled, expRange=ExpRange, archName="Rescaled Independent", nRange=Nrange, mRange=Mrange);

exportgraphics(ScaledHeatmaps, "../Prefigures/lasb_scaled_heatmaps.pdf", 'ContentType', 'vector');
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
    global a10 a11 K11 a12 K12 a112 K112 K121;
    global a20 a21 K21 a22 K22 a212 K212 K221;
    global a30 a31 K31 a32 K32 a312 K312 K321;

    Model = readtable("../Models/Summary.csv", 'ReadRowNames', true);
    GenesRegex = regexpPattern('lasI|rhlI|lasB');
    Model.Properties.RowNames = cellfun(@(str) ...
        extract(str, GenesRegex), Model.Properties.RowNames);
    Model = fillmissing(Model, 'constant', 0);

    a10 = Model{"lasI", "a0"};
    a11 = Model{"lasI", "a_c12"};
    K11 = Model{"lasI", "K_c12"};
    a12 = Model{"lasI", "a_c4"};
    K12 = Model{"lasI", "K_c4"};
    a112 = Model{"lasI", "aQ"};
    K112 = Model{"lasI", "KQ_c12"};
    K121 = Model{"lasI", "KQ_c12"};

    a20 = Model{"rhlI", "a0"};
    a21 = Model{"rhlI", "a_c12"};
    K21 = Model{"rhlI", "K_c12"};
    a22 = Model{"rhlI", "a_c4"};
    K22 = Model{"rhlI", "K_c4"};
    a212 = Model{"rhlI", "aQ"};
    K212 = Model{"rhlI", "KQ_c12"};
    K221 = Model{"rhlI", "KQ_c12"};

    a30 = Model{"lasB", "a0"};
    a31 = Model{"lasB", "a_c12"};
    K31 = Model{"lasB", "K_c12"};
    a32 = Model{"lasB", "a_c4"};
    K32 = Model{"lasB", "K_c4"};
    a312 = Model{"lasB", "aQ"};
    K312 = Model{"lasB", "KQ_c12"};
    K321 = Model{"lasB", "KQ_c12"};
end

function RLU_OD = LasIExp(Args)
% LasIExp() estimates lasI expression level in RLU/OD
% from C4 and C12 concentrations using model parameters 
    arguments
        Args.C12 double;  % 3‑oxo‑C₁₂‑HSL concentration (μM)
        Args.C4 double;   % C₄‑HSL concentration (μM)
        Args.Architecture (1,:) char ... % QS architecture
            {mustBeMember(Args.Architecture,{'reciprocal', 'hierarchical', 'independent'})} ...
            = 'reciprocal'
        Args.Scale logical = false % Scale non-reciprocal architecture?
    end
    global a10 a11 K11 a12 K12 a112 K112 K121;

    C12 = Args.C12;
    C4 = Args.C4;

    % Avoid 0/0 errors
    C4(C4 == 0) = sqrt(realmin);
    C12(C12 == 0) = sqrt(realmin);

    if Args.Architecture == "reciprocal"
        RLU_OD = a10 + ...
            a11  * C12 ./ (K11 + C12)  + ...
            a12  * C4  ./ (K12  + C4)  + ...
            a112 * C4 .* C12 ./ ((K112 + C12) .* (K121 + C4));
    elseif ~Args.Scale % hierarchical and independent are the same for lasI
        RLU_OD = a10 + a11  * C12 ./ (K11 + C12);
    else
        RLU_OD = a10 + (a11 + a12 + a112) * C12 ./ (K11 + C12);
    end
end

function RLU_OD = RhlIExp(Args)
% RhlIExp() estimates rhlI expression level in RLU/OD
% from C4 and C12 concentrations using model parameters 
    arguments
        Args.C12 double;  % 3‑oxo‑C₁₂‑HSL concentration (μM)
        Args.C4 double;   % C₄‑HSL concentration (μM)
        Args.Architecture (1,:) char ... % QS architecture
            {mustBeMember(Args.Architecture,{'reciprocal', 'hierarchical', 'independent'})} ...
            = 'reciprocal'
        Args.Scale logical = false % Scale non-reciprocal architecture?
    end
    global a20 a21 K21 a22 K22 a212 K212 K221;

    C12 = Args.C12;
    C4 = Args.C4;

    % Avoid 0/0 errors
    C4(C4 == 0) = sqrt(realmin);
    C12(C12 == 0) = sqrt(realmin);

    % reciprocal and hierarchical are the same for rhlI
    if Args.Architecture == "reciprocal" || Args.Architecture == "hierarchical"
        RLU_OD = a20 + ...
            a21  * C12 ./ (K21 + C12)  + ...
            a22  * C4  ./ (K22  + C4)  + ...
            a212 * C4 .* C12 ./ ((K212 + C12) .* (K221 + C4));
    elseif ~Args.Scale
        RLU_OD = a20 + a22 * C4  ./ (K22  + C4);
    else
        RLU_OD = a20 + (a21 + a22 + a212) * C4  ./ (K22  + C4);
   end
end

function RLU_OD = LasBExp(Args)
% LasBExp() estimates lasI expression level in RLU/OD
% from C4 and C12 concentrations using model parameters 
    arguments
        Args.C12 double;  % 3‑oxo‑C₁₂‑HSL concentration (μM)
        Args.C4 double;   % C₄‑HSL concentration (μM)
    end
    global a30 a31 K31 a32 K32 a312 K312 K321;

    C12 = Args.C12;
    C4 = Args.C4;

    % Avoid 0/0 errors
    C4(C4 == 0) = sqrt(realmin);
    C12(C12 == 0) = sqrt(realmin);

    RLU_OD = a30 + ...
        a31  * C12 ./ (K31 + C12)  + ...
        a32  * C4  ./ (K32  + C4)  + ...
        a312 * C4 .* C12 ./ ((K312 + C12) .* (K321 + C4));
end

function Residuals = DensitySignalObjectiveFn(Args)
% DensitySignalObjective() calculates residuals for a objective function
% that predicts signal concentrations as a function of density for
% specific values of proportionality constants
    arguments
        Args.c_d2 (2, 1) double;  % [c1_d2, c2_d2] proposed parameter values
        Args.Data;                % Data table of observations
        Args.mean_C12 double;     % mean C12 concentration (for normalization)
        Args.mean_C4  double;     % mean C4 concentration (for normalization)
    end

    c_d2 = Args.c_d2;
    Data = Args.Data;
    mean_C12 = Args.mean_C12;
    mean_C4 = Args.mean_C4;

    Residuals = zeros(height(Data), 1);
    for idx = 1 : height(Data)
        Sstar = Equilibrium(N = Data.density(idx), m_d2 = 0, c_d2 = c_d2);
        if Data.signal(idx) == "C12"
            Residuals(idx, 1) = (Sstar(1) - Data.uM(idx)) / mean_C12;
        else
            Residuals(idx, 1) = (Sstar(2) - Data.uM(idx)) / mean_C4;
        end
    end
end

function Sstar = Equilibrium(Args)
% Equilibrium() returns equilibrium concentrations of signals [C12, C4]
    arguments (Input)
        Args.N double;                   % population size
        Args.m_d2 double;                % mass transfer / C4 decay rate
        Args.c_d2 (2, 1) double;         % [c1_d2, c2_d2] constants
        Args.Architecture (1,:) char ... % QS architecture
            {mustBeMember(Args.Architecture,{'reciprocal', 'hierarchical', 'independent'})} ...
            = 'reciprocal'
        Args.Scale logical = false       % Scale non-reciprocal architecture?
        Args.S0 (2, 1) double = [1, 1]   % Optional starting guess; see note below
    end

    % Note: Setting S0 to different values can help prevent the
    % optimization algorithm from converging on alternate solutions in
    % which the concentrations are negative. A possible enhancement would
    % be to use non-linear optimization instead of a fsolve so that
    % constraints can be defined, but this is simpler for now. As a
    % safety check to make sure that negative values are not returned,
    % we use output validation.
    arguments (Output)
        Sstar (2, 1) double {mustBeNonnegative}
    end

    N = Args.N;
    m_d2 = Args.m_d2;
    c_d2 = Args.c_d2;
    Architecture = Args.Architecture;
    Scale = Args.Scale;
    S0 = Args.S0; 

    SolveOptions = optimoptions('fsolve', 'Display', 'none');
    dS = @(S) dS_dt(S = S, N = N, m_d2 = m_d2, c_d2 = c_d2, Architecture = Architecture, Scale = Scale);
    Sstar = fsolve(dS, S0, SolveOptions);
end

function DeltaS_d2 = dS_dt(Args)
% dS_dt() calculates the dynamics of the system of two
% signals as the change in concentration for each signal
% over time interval of C4 decay rate.
    arguments
        Args.S (2, 1) double;      % [C12, C4] concentration
        Args.N double;             % population size
        Args.m_d2 double = 0;      % mass transfer / C4 decay rate
        Args.c_d2 (2, 1) double;   % [c1_d2, c2_d2] constants
        Args.Architecture (1,:) char ... % QS architecture
            {mustBeMember(Args.Architecture,{'reciprocal', 'hierarchical', 'independent'})} ...
            = 'reciprocal'
        Args.Scale logical = false % Scale non-reciprocal architecture?
    end

    S = Args.S;
    N = Args.N;
    m_d2 = Args.m_d2;
    c_d2 = Args.c_d2;
    Architecture = Args.Architecture;
    Scale = Args.Scale;
    LasI = LasIExp(C12=S(1), C4=S(2), Architecture=Architecture, Scale=Scale);
    RhlI = RhlIExp(C12=S(1), C4=S(2), Architecture=Architecture, Scale=Scale);

    DeltaS_d2 = [ ...
        c_d2(1) * LasI * N - S(1) * (1.7 + m_d2);
        c_d2(2) * RhlI * N - S(2) * (1.0 + m_d2)
    ];

end

function MakeHeatmap(Args)
% MakeHeatmap creates a heatmap of expression levels
    arguments
        Args.expLevel (:,:) double    % 2D expression level matrix
        Args.expRange (1, 2) double   % extent of expression levels
        Args.archName string          % type of architecture
        Args.nRange (:, 1) double     % range of densities
        Args.mRange (:, 1) double     % range of mass transfer rates
    end

    global FontName;

    expLevel = Args.expLevel;
    expRange = Args.expRange;
    archName = Args.archName;
    Nrange = Args.nRange;
    Mrange = Args.mRange;

    thresholds = [0.05, 0.5];
    tLevels = thresholds * (expRange(2) - expRange(1)) + expRange(1);
    tColors = {'black', 'white'};
    tX = zeros(length(tLevels), 2);
    tY = zeros(length(tLevels), 2);

    for tIdx = 1 : length(tLevels)
        t = tLevels(tIdx);
        for Midx = 1 : length(Mrange)
            [ ~, Nidx ] = min( abs( expLevel(:, Midx) - t ) );
            Nthresh = Nrange(length(Mrange) - Nidx + 1);
            Mthresh = Mrange(Midx);
    
            if Midx == 1
                t1 = [Mthresh, Nthresh];
            end
            if Nidx == 1
                if Midx == 1
                    t1 = [0, 0];
                    t2 = [0, 0];
                else
                    t2 = [Mthresh, Nthresh];
                end
                break;
            elseif Midx == length(Mrange)
                t2 = [Mthresh, Nthresh];
                % break; % not needed since loop terminates here anyway
            end
        end
        tX(tIdx, :) = [t1(1), t2(1)];
        tY(tIdx, :) = [t1(2), t2(2)];
    end

    if contains(archName, "Hierarchical")
        xLabel = {'Mass Transfer Rate', '(Normalized to C_{4}-HSL Decay Rate)'};
    else
        xLabel = "Mass Transfer Rate";
    end

    imagesc([0 5], [1 0], expLevel, expRange); set(gca, 'YDir','normal')
    hold on;
    xTicks = {'0', '1', '2', '3', '4', '5'};
    set(gca,'XTickLabel', xTicks, 'fontsize', 6, 'FontName', FontName);
    xlabel(xLabel, FontName=FontName, FontSize=9);
    if archName == "Reciprocal"
        ylabel("Population Density (~ OD600)", FontName=FontName, FontSize=9);
    end
    title(archName, FontName=FontName, FontSize=10);
    pbaspect([1 1 1]);
    
    for tIdx = 1 : length(tLevels)
        if sum(tX(tIdx, :) + tY(tIdx, :)) == 0
            continue;
        end
        plot(tX(tIdx, :), tY(tIdx, :), LineWidth=1, Color=tColors{tIdx});
        label = [num2str(round(100 * thresholds(tIdx))) '%'];
        text(median(tX(tIdx, :)), median(tY(tIdx, :)), label, ...
            Color=tColors{tIdx}, FontName=FontName, fontsize=9, ...
            VerticalAlignment='top' ...x = 0.05
        );
    end
    hold off;
    
    if contains(archName, "Independent")
        Colorbar = colorbar();
        Colorbar.Label.String = "\it lasB\rm\rm (RLU/OD)";
        Colorbar.Label.FontName = FontName;
        Colorbar.Label.FontSize = 9;
        ColorbarOverlay = axes('position', Colorbar.Position, 'ylim', Colorbar.Limits, 'color', 'none', 'visible','off');
        for tIdx = 1 : length(tLevels)
            line(ColorbarOverlay.XLim, tLevels(tIdx)*[1 1], 'lineWidth', 1, 'color', tColors{tIdx}, 'parent', ColorbarOverlay);
        end
    end
end