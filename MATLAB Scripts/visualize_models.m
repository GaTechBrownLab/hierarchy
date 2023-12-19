%% Visualizing Dynamical Systems Models

clear; IntializeNotebook();
%% Styles

% SetStyles(); 
FontName = "Arial"; % "Lucida Sans OT";
%% Setup

% Data stored in separate files.
NTable = readtable("DynamicsN.csv");
MTable = readtable("DynamicsM.csv");
%% LasB Expression

figure;
TilesLasBExp = tiledlayout(4, 3, 'TileSpacing', 'compact');

nexttile(1, [ 2 2]);
Plot1 = plot( ...
    NTable.N, NTable.LasBReciprocal(:,1) / NTable.LasBReciprocal(1,1), ...
    NTable.N, NTable.LasBHierarchyPlus(:,1) / NTable.LasBHierarchyPlus(1,1), ...
    NTable.N, NTable.LasBIndependentPlus(:,1) / NTable.LasBIndependentPlus(1,1), ...
    'LineWidth', 3);
Plot1(1).Color = [44,49,114]/255;
Plot1(2).Color = [52,133,141]/255;
Plot1(3).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xlabel("Population Density (~ OD600)", 'FontName', FontName); xtickformat('%.1f')
ylabel("Fold-Change", 'FontName', FontName);
text(-0.1, 1.0, "A", 'FontName', FontName, 'FontWeight', 'bold', 'FontSize', 12, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment','bottom');
title("\it lasB\rm\bf Expression", 'FontName', FontName, 'FontSize', 13);

Legend = legend(["Reciprocal", "Hierarchical", "Independent"], 'FontName', FontName, 'Location', 'northwest');
title(Legend, "QS Architecture", 'FontName', FontName);

nexttile(7, [2 2]);
Plot2 = plot( ...
    MTable.M, 100*MTable.LasBReciprocal(:,1)/MTable.LasBReciprocal(1,1), ...
    MTable.M, 100*MTable.LasBHierarchyPlus(:,1)/MTable.LasBHierarchyPlus(1,1), ...
    MTable.M, 100*MTable.LasBIndependentPlus(:,1)/MTable.LasBIndependentPlus(1,1), ...
    'LineWidth', 3);
Plot2(1).Color = [44,49,114]/255;
Plot2(2).Color = [52,133,141]/255;
Plot2(3).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xlabel({'Mass Transfer Rate', '(Normalized to C_4-HSL Decay Rate)'}, 'FontName', FontName);
ylabel("Percent of Maximum", 'FontName', FontName); ytickformat('%g%%');
text(-0.1, 1.05, "B", 'FontName', FontName, 'FontWeight', 'bold', 'FontSize', 12, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment','bottom');

TilesC4Conc = tiledlayout(TilesLasBExp, 2, 1);
TilesC4Conc.Layout.Tile = 3;
TilesC4Conc.Layout.TileSpan = [2 1];
nexttile(TilesC4Conc);
Plot3 = plot( ...
    NTable.N, NTable.C4Reciprocal(:,1), ...
    NTable.N, NTable.C4HierarchyPlus(:,1), ...
    NTable.N, NTable.C4IndependentPlus(:,1), ...
    'LineWidth', 3);
Plot3(1).Color = [44,49,114]/255;
Plot3(2).Color = [52,133,141]/255;
Plot3(3).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Population Density", 'FontName', FontName, 'FontSize', 8);
text(1.1, 1.0, "C", 'FontName', FontName, 'FontWeight', 'bold', 'FontSize', 12, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment','bottom');
title("Signal Equilibrium        ", 'FontName', FontName, 'FontSize', 12);

nexttile(TilesC4Conc);
Plot4 = plot( ...
    MTable.M, MTable.C4Reciprocal(:,1), ...
    MTable.M, MTable.C4HierarchyPlus(:,1), ...
    MTable.M, MTable.C4IndependentPlus(:,1), ...
    'LineWidth', 3);
Plot4(1).Color = [44,49,114]/255;
Plot4(2).Color = [52,133,141]/255;
Plot4(3).Color = [165,205,144]/255;
Plot4(2).LineStyle = "--";
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Mass Transfer Rate", 'FontName', FontName, 'FontSize', 8);
xlim([0 max(MTable.M)])
text(1.1, 1.05, "D", 'FontName', FontName, 'FontWeight', 'bold', 'FontSize', 13, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment','bottom');
ylabel(TilesC4Conc, "C_4-HSL (μM)", 'FontName', FontName);

TilesC12Conc = tiledlayout(TilesLasBExp, 2, 1);
TilesC12Conc.Layout.Tile = 9;
TilesC12Conc.Layout.TileSpan = [2 1];
nexttile(TilesC12Conc);
Plot5 = plot( ...
    NTable.N, NTable.C12Reciprocal(:,1), ...
    NTable.N, NTable.C12HierarchyPlus(:,1), ...
    NTable.N, NTable.C12IndependentPlus(:,1), ...
    'LineWidth', 3);
Plot5(1).Color = [44,49,114]/255;
Plot5(2).Color = [52,133,141]/255;
Plot5(3).Color = [165,205,144]/255;
Plot5(3).LineStyle = "--";
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Population Density", 'FontName', FontName, 'FontSize', 8);
text(1.1, 1.0, "E", 'FontName', FontName, 'FontWeight', 'bold', 'FontSize', 12, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment','bottom');

nexttile(TilesC12Conc);
Plot6 = plot( ...
    MTable.M, MTable.C12Reciprocal(:,1), ...
    MTable.M, MTable.C12HierarchyPlus(:,1), ...
    MTable.M, MTable.C12IndependentPlus(:,1), ...
    'LineWidth', 3);
Plot6(1).Color = [44,49,114]/255;
Plot6(2).Color = [52,133,141]/255;
Plot6(3).Color = [165,205,144]/255;
Plot6(3).LineStyle = "--";
ax = gca;
ax.FontName = FontName;
xticks([]);
xlabel("Mass Transfer Rate", 'FontName', FontName, 'FontSize', 8);
xlim([0 max(MTable.M)])
text(1.1, 1.05, "F", 'FontName', FontName, 'FontWeight', 'bold', 'FontSize', 13, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment','bottom');
ylabel(TilesC12Conc, "3-oxo-C_{12}-HSL (μM)", 'FontName', FontName);

exportgraphics(TilesLasBExp, "../Prefigures/lasb_response.pdf", 'ContentType', 'vector');
%% LasB Expression (Unscaled)

figure;
TilesLasBExp2 = tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile;
Plot1 = plot( ...
    NTable.N, NTable.LasBReciprocal(:,1) / NTable.LasBReciprocal(1,1), ...
    NTable.N, NTable.LasBHierarchy(:,1) / NTable.LasBHierarchy(1,1), ...
    NTable.N, NTable.LasBIndependent(:,1) / NTable.LasBIndependent(1,1), ...
    'LineWidth', 3);
Plot1(1).Color = [44,49,114]/255;
Plot1(2).Color = [52,133,141]/255;
Plot1(3).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xlabel("Population Density (~ OD600)", 'FontName', FontName); xtickformat('%.1f')
ylabel("Fold-Change", 'FontName', FontName);
text(-0.1, 1.05, "A", 'FontName', FontName, 'FontWeight', 'bold', 'FontSize', 12, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment','bottom');

Legend = legend(["Reciprocal", "Hierarchical", "Independent"], 'FontName', FontName, 'Location', 'northeastoutside');
title(Legend, "QS Architecture", 'FontName', FontName);

nexttile;
Plot2 = plot( ...
    MTable.M, 100*MTable.LasBReciprocal(:,1)/MTable.LasBReciprocal(1,1), ...
    MTable.M, 100*MTable.LasBHierarchy(:,1)/MTable.LasBHierarchy(1,1), ...
    MTable.M, 100*MTable.LasBIndependent(:,1)/MTable.LasBIndependent(1,1), ...
    'LineWidth', 3);
Plot2(1).Color = [44,49,114]/255;
Plot2(2).Color = [52,133,141]/255;
Plot2(3).Color = [165,205,144]/255;
ax = gca;
ax.FontName = FontName;
xlabel({'Mass Transfer Rate', '(Normalized to C_4-HSL Decay Rate)'}, 'FontName', FontName);
ylabel("Percent of Maximum", 'FontName', FontName); ytickformat('%g%%');
text(-0.1, 1.05, "B", 'FontName', FontName, 'FontWeight', 'bold', 'FontSize', 12, 'Units', 'normalized', 'HorizontalAlignment', 'right', 'VerticalAlignment','bottom');

title(TilesLasBExp2, "\it lasB\rm Expression", 'FontName', FontName);

exportgraphics(TilesLasBExp2, "../Prefigures/lasb_response2.pdf", 'ContentType', 'vector');
%% Hypothetical Architectures

a0 = 1;
a = 10 * a0;
D = 300;
K = 1;
h = 5;
N = 1:100;
Sstar = zeros(100,3);
for N = 1:100
    Sstar(N,1) = max(roots([ ...
        -1 * D, ...                % S^2
        (a0 + a) * N - D * K, ...  % S^1
        a0 * K * N ...             % S^0
    ])) / 3;
    Sstar(N,2) = 0.5 * N^h / (N^h + 45^h);
    Sstar(N,3) = (1 - N^h / (N^h + 75^h)) * Sstar(N,2);
end

figure;
TilesRepression = tiledlayout(2, 1, 'TileSpacing', 'compact');
nexttile;
Plot1 = plot(Sstar, 'LineWidth', 3);
Plot1(1).Color = [44,49,114]/255;
Plot1(2).Color = [52,133,141]/255;
Plot1(3).Color = [165,205,144]/255;
xlabel("Population Density →", 'FontName', FontName); xticks({});
ylabel("Expression Level →", 'FontName', FontName); yticks({});
Legend = legend([ ...
    "Single System", ...
    "w/ Limiting System", ...
    "w/ Damping System" ...
    ], 'FontName', FontName, 'Location', 'northeastoutside');
title(Legend, "QS Architecture", 'FontName', FontName, 'FontWeight','normal');
title(TilesRepression, "Effect of Repressive QS System", 'FontName', FontName, 'FontWeight','normal');
exportgraphics(TilesRepression, "../Prefigures/repression.pdf", 'ContentType', 'vector');
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

function SetStyles()
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
