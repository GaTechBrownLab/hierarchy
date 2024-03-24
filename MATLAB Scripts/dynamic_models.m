%% Dynamical Systems Models

clear; IntializeNotebook(Quiet=true);
%% Styles

% SetStyles(); 
FontName   = "Arial"; % "Lucida Sans OT";
C4Color    = [237,176,129]/255;
C12Color   = [193,65,104]/255;
MixedColor = [229,113,94]/255;
LasBColor  = [44,49,114]/255;
LasIColor  = [165,205,144]/255;
RhlIColor  = [52,133,141]/255;
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
    Sstar = Equilibrium(N = N, c_d2 = c_d2);
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

% Check _lasB_ Expression

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
    Sstar = Equilibrium(N = AggregateData.od(i), c_d2 = c_d2);
    AggregateData.model(i) = LasBExp(C12 = Sstar(1), C4 = Sstar(2));
end


% Linear regression to map observed pixel intensity to estimated expression.
X = [ones(length(AggregateData.mean_expression), 1) AggregateData.mean_expression];
Y = AggregateData.model;
b = X \ Y;
Ypredict = X * b;
Rsq1 = 1 - sum((Y - Ypredict).^2)/sum((Y - mean(Y)).^2)

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
Ntable = table( ...
    'Size', [length(Architectures) * length(Nrange), height(Columns)], ...
    'VariableNames', Columns(:,1), ...
    'VariableTypes', Columns(:,2) ...
);

idx = 1;
for idxArch = 1 : length(Architectures)
    Architecture = Architectures{idxArch}{1};
    Scale = Architectures{idxArch}{2};
    S0 = [1, 1];
    for N = Nrange
        Sstar = Equilibrium(N = N, c_d2 = c_d2, Architecture = Architecture, Scale = Scale, S0 = S0);
        lasB = LasBExp(C12 = Sstar(1), C4 = Sstar(2));
        Ntable.Architecture(idx) = Architecture;
        Ntable.Scaled(idx) = Scale;
        Ntable.Density(idx) = N;
        Ntable.MassTransfer(idx) = 0;
        Ntable.C12(idx) = Sstar(1);
        Ntable.C4(idx) = Sstar(2);
        Ntable.lasB(idx) = lasB;
        idx = idx + 1;
        S0 = Sstar;
    end
end
% Varying Mass Transfer

Mrange = fliplr(0 : 0.05 : 5.0);
Mtable = table( ...
    'Size', [length(Architectures) * length(Mrange), height(Columns)], ...
    'VariableNames', Columns(:,1), ...
    'VariableTypes', Columns(:,2) ...
);
Nmax = 5;

idx = 1;
for idxArch = 1 : length(Architectures)
    Architecture = Architectures{idxArch}{1};
    Scale = Architectures{idxArch}{2};
    S0 = [5, 5];
    for M = Mrange
        Sstar = Equilibrium(N = Nmax, m = M, c_d2 = c_d2, Architecture = Architecture, Scale = Scale, S0 = S0);
        lasB = LasBExp(C12 = Sstar(1), C4 = Sstar(2));
        Mtable.Architecture(idx) = Architecture;
        Mtable.Scaled(idx) = Scale;
        Mtable.Density(idx) = Nmax;
        Mtable.MassTransfer(idx) = M;
        Mtable.C12(idx) = Sstar(1);
        Mtable.C4(idx) = Sstar(2);
        Mtable.lasB(idx) = lasB;
        idx = idx + 1;
        S0 = Sstar;
    end
end
% Visualize Results

Nr  = Ntable(Ntable.Architecture == "reciprocal", :);
Nhu = Ntable(Ntable.Architecture == "hierarchical" & ~Ntable.Scaled, :);
Nhs = Ntable(Ntable.Architecture == "hierarchical" & Ntable.Scaled, :);
Niu = Ntable(Ntable.Architecture == "independent" & ~Ntable.Scaled, :);
Nis = Ntable(Ntable.Architecture == "independent" & Ntable.Scaled, :);

Mr  = Mtable(Mtable.Architecture == "reciprocal", :);
Mhu = Mtable(Mtable.Architecture == "hierarchical" & ~Mtable.Scaled, :);
Mhs = Mtable(Mtable.Architecture == "hierarchical" & Mtable.Scaled, :);
Miu = Mtable(Mtable.Architecture == "independent" & ~Mtable.Scaled, :);
Mis = Mtable(Mtable.Architecture == "independent" & Mtable.Scaled, :);

FigureUnscaled = figure;
% Tiles = tiledlayout(2, 1);
% TilesUnscaled = tiledlayout(Tiles, 4, 3, 'TileSpacing', 'compact');
% TilesUnscaled.Layout.Tile = 1;
% TilesUnscaled.Layout.TileSpan = [1 1];

TilesUnscaled = tiledlayout(4, 3, 'TileSpacing', 'compact');

nexttile(TilesUnscaled, [ 2 2]);
Plot1 = plot( ...
    Niu.Density, Niu.lasB / min(Niu.lasB), ...
    Nhu.Density, Nhu.lasB / min(Nhu.lasB), ...
    Nr.Density, Nr.lasB / min(Nr.lasB), ...
    'LineWidth', 3);
Plot1(3).Color = [44,49,114]/255;
Plot1(2).Color = [52,133,141]/255;
Plot1(1).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xlabel("Population Density (~ OD600)", FontName=FontName);
xtickformat('%.1f')
ylabel("Fold-Change", FontName=FontName);
text(-0.1, 1.0, "A", FontName=FontName, FontWeight="bold", FontSize=12, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
title("\it lasB\rm\bf Expression", FontName=FontName, FontSize=13);

Legend = legend(["Independent", "Hierarchical", "Reciprocal"], FontName=FontName, Location="northwest", Direction="reverse");
title(Legend, "QS Architecture", FontName=FontName);

nexttile(7, [2 2]);
Plot2 = plot( ...
    Miu.MassTransfer, 100*Miu.lasB / max(Mr.lasB), ...
    Mhu.MassTransfer, 100*Mhu.lasB / max(Mr.lasB), ...
    Mr.MassTransfer,  100*Mr.lasB  / max(Mr.lasB), ...
    'LineWidth', 3);
Plot2(3).Color = [44,49,114]/255;
Plot2(2).Color = [52,133,141]/255;
Plot2(1).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xlabel({'Mass Transfer Rate', '(Normalized to C_{4}-HSL Decay Rate)'}, FontName=FontName);
ylabel("Percent of Maximum", FontName=FontName);
ytickformat('%g%%');
text(-0.1, 1.05, "B", FontName=FontName, FontWeight="bold", FontSize=12, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
NoteText = sprintf("For OD600 ≈ %2.1f", Nmax);
Note1 = annotation(FigureUnscaled, "textbox", [0 0 1 1], ...
    String=NoteText, ...
    FontName=FontName, FontSize=7, ...
    FitBoxToText="on");
Note1.Position(1) = 0.48;
Note1.Position(2) = -0.533;

TilesC4Unscaled = tiledlayout(TilesUnscaled, 2, 1);
TilesC4Unscaled.Layout.Tile = 3;
TilesC4Unscaled.Layout.TileSpan = [2 1];

nexttile(TilesC4Unscaled);
Plot3 = plot( ...
    Nr.Density,  Nr.C4,  ...
    Nhu.Density, Nhu.C4, ...
    Niu.Density, Niu.C4, ...
    'LineWidth', 3);
Plot3(1).Color = [44,49,114]/255;
Plot3(2).Color = [52,133,141]/255;
Plot3(3).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Population Density", FontName=FontName, FontSize=8);
text(1.1, 1.0, "C", FontName=FontName, FontWeight="bold", FontSize=12, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
title("Signal Equilibrium        ", FontName=FontName, FontSize=12);

nexttile(TilesC4Unscaled);
Plot4 = plot( ...
    Mr.MassTransfer,  Mr.C4,  ...
    Mhu.MassTransfer, Mhu.C4, ...
    Miu.MassTransfer, Miu.C4, ...
    'LineWidth', 3);
Plot4(1).Color = [44,49,114]/255;
Plot4(2).Color = [52,133,141]/255;
Plot4(3).Color = [165,205,144]/255;
Plot4(2).LineStyle = "--";
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Mass Transfer Rate", FontName=FontName, FontSize=8);
xlim([0 max(Mr.MassTransfer)])
text(1.1, 1.05, "D", FontName=FontName, FontWeight="bold", FontSize=13, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
ylabel(TilesC4Unscaled, "C_{4}-HSL (μM)", FontName=FontName);

TilesC12Unscaled = tiledlayout(TilesUnscaled, 2, 1);
TilesC12Unscaled.Layout.Tile = 9;
TilesC12Unscaled.Layout.TileSpan = [2 1];
nexttile(TilesC12Unscaled);
Plot5 = plot( ...
    Nr.Density,  Nr.C12,  ...
    Nhu.Density, Nhu.C12, ...
    Niu.Density, Niu.C12, ...
    'LineWidth', 3);
Plot5(1).Color = [44,49,114]/255;
Plot5(2).Color = [52,133,141]/255;
Plot5(3).Color = [165,205,144]/255;
Plot5(3).LineStyle = "--";
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Population Density", FontName=FontName, FontSize=8);
text(1.1, 1.0, "E", FontName=FontName, FontWeight="bold", FontSize=12, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");

nexttile(TilesC12Unscaled);
Plot6 = plot( ...
    Mr.MassTransfer,  Mr.C12,  ...
    Mhu.MassTransfer, Mhu.C12, ...
    Miu.MassTransfer, Miu.C12, ...
    'LineWidth', 3);
Plot6(1).Color = [44,49,114]/255;
Plot6(2).Color = [52,133,141]/255;
Plot6(3).Color = [165,205,144]/255;
Plot6(3).LineStyle = "--";
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Mass Transfer Rate", FontName=FontName, FontSize=8);
xlim([0 max(Mr.MassTransfer)])
text(1.1, 1.05, "F", FontName=FontName, FontWeight="bold", FontSize=13, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
ylabel(TilesC12Unscaled, "3-oxo-C_{12}-HSL (μM)", FontName=FontName);

exportgraphics(TilesUnscaled, "../Prefigures/lasb_responses.pdf", 'ContentType', 'vector');

% TilesScaled = tiledlayout(Tiles, 4, 3, 'TileSpacing', 'compact');
% TilesScaled.Layout.Tile = 2;
% TilesScaled.Layout.TileSpan = [1 1];

FigureScaled = figure;
TilesScaled = tiledlayout(4, 3, 'TileSpacing', 'compact');

nexttile(TilesScaled, [ 2 2]);
Plot7 = plot( ...
    Nis.Density, Nis.lasB / min(Nis.lasB), ...
    Nhs.Density, Nhs.lasB / min(Nhs.lasB), ...
    Nr.Density, Nr.lasB / min(Nr.lasB), ...
    'LineWidth', 3);
Plot7(3).Color = [44,49,114]/255;
Plot7(2).Color = [52,133,141]/255;
Plot7(1).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xlabel("Population Density (~ OD600)", FontName=FontName);
xtickformat('%.1f')
ylabel("Fold-Change", FontName=FontName);
text(-0.1, 1.0, "A", FontName=FontName, FontWeight="bold", FontSize=12, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
title("\it lasB\rm\bf Expression (Normalized)", FontName=FontName, FontSize=13);

Legend = legend(["Independent", "Hierarchical", "Reciprocal"], FontName=FontName, Location="northwest", Direction="reverse");
title(Legend, "QS Architecture", FontName=FontName);

Note2 = annotation(FigureScaled, "textbox", [0 0 1 1], ...
    String={ ...
        'Non-reciprocal architectures', ...
        'normalized to same maximum', ...
        'expression levels as Reciprocal', ...
        '(i.e. at N = ♾️, m = 0).'
    }, ...
    FontName=FontName, FontSize=7, ...
    FitBoxToText="on");
Note2.Position(1) = 0.41;
Note2.Position(2) = -0.315;
Note2.Margin = 3;

nexttile(7, [2 2]);
Plot8 = plot( ...
    Mis.MassTransfer, 100*Mis.lasB / max(Mr.lasB), ...
    Mhs.MassTransfer, 100*Mhs.lasB / max(Mr.lasB), ...
    Mr.MassTransfer,  100*Mr.lasB  / max(Mr.lasB), ...
    'LineWidth', 3);
Plot8(3).Color = [44,49,114]/255;
Plot8(2).Color = [52,133,141]/255;
Plot8(1).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xlabel({'Mass Transfer Rate', '(Normalized to C_{4}-HSL Decay Rate)'}, FontName=FontName);
ylabel("Percent of Maximum", FontName=FontName);
ytickformat('%g%%');
text(-0.1, 1.05, "B", FontName=FontName, FontWeight="bold", FontSize=12, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
Note3 = annotation(FigureScaled, "textbox", [0 0 1 1], ...
    String=NoteText, ...
    FontName=FontName, FontSize=7, ...
    FitBoxToText="on");
Note3.Position(1) = 0.48;
Note3.Position(2) = -0.533;

TilesC4Scaled = tiledlayout(TilesScaled, 2, 1);
TilesC4Scaled.Layout.Tile = 3;
TilesC4Scaled.Layout.TileSpan = [2 1];

nexttile(TilesC4Scaled);
Plot9 = plot( ...
    Nr.Density,  Nr.C4,  ...
    Nhs.Density, Nhs.C4, ...
    Nis.Density, Nis.C4, ...
    'LineWidth', 3);
Plot9(1).Color = [44,49,114]/255;
Plot9(2).Color = [52,133,141]/255;
Plot9(3).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Population Density", FontName=FontName, FontSize=8);
text(1.1, 1.0, "C", FontName=FontName, FontWeight="bold", FontSize=12, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
title("Signal Equilibrium        ", FontName=FontName, FontSize=12);

nexttile(TilesC4Scaled);
Plot10 = plot( ...
    Mr.MassTransfer,  Mr.C4,  ...
    Mhs.MassTransfer, Mhs.C4, ...
    Mis.MassTransfer, Mis.C4, ...
    'LineWidth', 3);
Plot10(1).Color = [44,49,114]/255;
Plot10(2).Color = [52,133,141]/255;
Plot10(3).Color = [165,205,144]/255;
Plot10(2).LineStyle = "--";
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Mass Transfer Rate", FontName=FontName, FontSize=8);
xlim([0 max(Mr.MassTransfer)])
text(1.1, 1.05, "D", FontName=FontName, FontWeight="bold", FontSize=13, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
ylabel(TilesC4Scaled, "C_{4}-HSL (μM)", FontName=FontName);

TilesC12Scaled = tiledlayout(TilesScaled, 2, 1);
TilesC12Scaled.Layout.Tile = 9;
TilesC12Scaled.Layout.TileSpan = [2 1];
nexttile(TilesC12Scaled);
Plot11 = plot( ...
    Nr.Density,  Nr.C12,  ...
    Nhs.Density, Nhs.C12, ...
    Nis.Density, Nis.C12, ...
    'LineWidth', 3);
Plot11(1).Color = [44,49,114]/255;
Plot11(2).Color = [52,133,141]/255;
Plot11(3).Color = [165,205,144]/255;
Plot11(3).LineStyle = "--";
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Population Density", FontName=FontName, FontSize=8);
text(1.1, 1.0, "E", FontName=FontName, FontWeight="bold", FontSize=12, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");

nexttile(TilesC12Scaled);
Plot12 = plot( ...
    Mr.MassTransfer,  Mr.C12,  ...
    Mhs.MassTransfer, Mhs.C12, ...
    Mis.MassTransfer, Mis.C12, ...
    'LineWidth', 3);
Plot12(1).Color = [44,49,114]/255;
Plot12(2).Color = [52,133,141]/255;
Plot12(3).Color = [165,205,144]/255;
Plot12(3).LineStyle = "--";
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Mass Transfer Rate", FontName=FontName, FontSize=8);
xlim([0 max(Mr.MassTransfer)])
text(1.1, 1.05, "F", FontName=FontName, FontWeight="bold", FontSize=13, Units="normalized", HorizontalAlignment="right", VerticalAlignment="bottom");
ylabel(TilesC12Scaled, "3-oxo-C_{12}-HSL (μM)", FontName=FontName);
% FigureScaled.Position(4) = FigureScaled.Position(4) * 2;
% exportgraphics(Tiles, "../Prefigures/lasb_responses.pdf", 'ContentType', 'vector');

exportgraphics(TilesScaled, "../Prefigures/lasb_responses2.pdf", 'ContentType', 'vector');
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
        Sstar = Equilibrium(N = Data.density(idx), c_d2 = c_d2);
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
        Args.m_d2 double = 0;            % mass transfer / C4 decay rate
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