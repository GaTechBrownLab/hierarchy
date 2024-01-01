%% Visualizing Dynamical Systems Models

clear; IntializeNotebook();
%% Styles

% SetStyles(); 
FontName = "Arial"; % "Lucida Sans OT";
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