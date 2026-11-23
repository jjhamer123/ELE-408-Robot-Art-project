function d = penXY(which, varargin)
%PENXY  Load (and plot) a pen x,y CSV written by the Godot sim's PenXYLogger.
%
%   penXY            plot the most recent run
%   penXY(1)         same: 1 = last run, 2 = the one before, 3 = ...
%   penXY("pen_xy_2026-11-16T15-13-30")       by name, with or without .csv
%   penXY("pen_xy_2026_11_16T15_13_30")       MATLAB's import-style name works too
%   penXY("/full/path/to/some_file.csv")      any file on disk
%   penXY("list")    list the runs, newest first, with their numbers
%
%   d = penXY(...)   also returns a struct:
%       d.t  time (s)     d.x, d.y  pen position (m, ROS axes, robot base)
%       d.file  full path of the CSV that was read
%
%   Options (name, value):
%       "Folder"  where the CSVs are. Default: BOTH the logs folder of every
%                 Godot project under <this repo>/godot/ (Csv Path res://logs/...)
%                 and Godot's user folder (Csv Path user://logs/...)
%       "Plot"    true/false (default: true when called without an output)
%
%   Examples:
%       penXY(2)                          % plot the second to last run
%       d = penXY(1);  plot(d.t, d.x)     % x against time
%       penXY(1, "Folder", "~/Desktop/runs")

if nargin < 1 || isempty(which)
    which = 1;
end

p = inputParser;
p.addParameter("Folder", "");
p.addParameter("Plot", nargout == 0);
p.parse(varargin{:});
folder = char(p.Results.Folder);
if isempty(folder)
    folders = defaultFolders();
else
    if startsWith(folder, "~")
        folder = [homeDir(), folder(2:end)];
    end
    folders = {folder};
end
where = strjoin(folders, sprintf("\n    "));

% ---- list mode --------------------------------------------------------
if (ischar(which) || isstring(which)) && strcmpi(which, "list")
    runs = listRuns(folders);
    fprintf("Looked in:\n    %s\nPen x,y runs, newest first:\n", where);
    for k = 1:numel(runs)
        fprintf("  %3d  %s    (%s)\n", k, runs(k).name, runs(k).folder);
    end
    if nargout > 0, d = runs; end
    return
end

% ---- find the file ----------------------------------------------------
if isnumeric(which)
    n = round(double(which));
    runs = listRuns(folders);
    if isempty(runs)
        error("penXY:none", "No pen_xy_*.csv files in:\n    %s\nRun the sim with the PenXYLogger node, or pass ""Folder"".", where);
    end
    if n < 1 || n > numel(runs)
        error("penXY:range", "Asked for run %d but there are only %d runs (see penXY(""list"")).", n, numel(runs));
    end
    file = fullfile(runs(n).folder, runs(n).name);
else
    file = findByName(char(which), folders);
end

% ---- read it ----------------------------------------------------------
fid = fopen(file, "r");
if fid < 0
    error("penXY:open", "Can't open %s", file);
end
header = fgetl(fid);
fclose(fid);
cols = strtrim(strsplit(header, ","));
M = dlmread(file, ",", 1, 0);           % skip the header row
if isempty(M)
    error("penXY:empty", "%s has no rows yet.", file);
end

ti = find(strcmp(cols, "t_s"), 1);
xi = find(startsWith(cols, "x_"), 1);
yi = find(startsWith(cols, "y_"), 1);
if isempty(ti) || isempty(xi) || isempty(yi)
    error("penXY:format", "%s doesn't have t_s, x_..., y_... columns (header: %s)", file, header);
end
scale = 1;
if strcmp(cols{xi}, "x_mm"), scale = 1e-3; end    % logger was set to millimetres

d.t = M(:, ti);
d.x = M(:, xi) * scale;
d.y = M(:, yi) * scale;
d.file = file;

% ---- plot -------------------------------------------------------------
if p.Results.Plot
    [~, nm, ext] = fileparts(file);
    figure("Name", [nm ext]);
    plot(d.x * 1000, d.y * 1000, "LineWidth", 1);
    hold on
    plot(d.x(1) * 1000, d.y(1) * 1000, "go", "MarkerFaceColor", "g");     % start
    plot(d.x(end) * 1000, d.y(end) * 1000, "rs", "MarkerFaceColor", "r"); % end
    hold off
    axis equal; grid on
    xlabel("x (mm)"); ylabel("y (mm)");
    title(sprintf("%s   (%.1f s, %d points)", strrep(nm, '_', '\_'), d.t(end) - d.t(1), numel(d.t)));
    legend("pen path", "start", "end", "Location", "bestoutside");
end
if nargout == 0
    clear d
end
end


% ======================================================================

function runs = listRuns(folders)
% pen_xy_*.csv in all the folders, newest first. Sorted by the date and time in
% the name (pen_xy_YYYY-MM-DDTHH-MM-SS), because git/copying changes file dates.
% A run found in two folders is listed once (the first folder wins).
runs = [];
seen = {};
for f = 1:numel(folders)
    r = dir(fullfile(folders{f}, "pen_xy_*.csv"));
    for k = 1:numel(r)
        if ~any(strcmp(seen, r(k).name))
            seen{end + 1} = r(k).name; %#ok<AGROW>
            r(k).folder = folders{f};
            if isempty(runs), runs = r(k); else, runs(end + 1) = r(k); end %#ok<AGROW>
        end
    end
end
if isempty(runs), return; end
[~, order] = sort({runs.name});
runs = runs(fliplr(order));
end


function file = findByName(name, folders)
name = strtrim(name);
if ~endsWith(lower(name), ".csv")
    name = [name '.csv'];
end
% a path that exists as given (absolute, or relative to the current folder)
if exist(name, "file") == 2 && (contains(name, "/") || contains(name, '\') || isfile(fullfile(pwd, name)))
    file = name;
    if ~isAbsolute(file), file = fullfile(pwd, file); end
    return
end
% MATLAB's import turns "pen_xy_2026-11-16T15-13-30" into "pen_xy_2026_11_16T15_13_30":
% compare with '-' treated as '_'
want = strrep(lower(name), "-", "_");
for f = 1:numel(folders)
    files = dir(fullfile(folders{f}, "*.csv"));
    for k = 1:numel(files)
        if strcmp(strrep(lower(files(k).name), "-", "_"), want)
            file = fullfile(folders{f}, files(k).name);
            return
        end
    end
end
error("penXY:notfound", "Can't find %s in:\n    %s\nTry penXY(""list"") to see the runs.", name, strjoin(folders, sprintf("\n    ")));
end


function tf = isAbsolute(f)
tf = startsWith(f, "/") || (numel(f) > 1 && f(2) == ':');
end


function folders = defaultFolders()
% 1) <repo>/godot/<any project>/logs  (this file is in <repo>/matlab/scripts)
folders = {};
repo = fileparts(fileparts(fileparts(mfilename("fullpath"))));
g = dir(fullfile(repo, "godot"));
for k = 1:numel(g)
    if g(k).isdir && g(k).name(1) ~= '.'
        lf = fullfile(repo, "godot", g(k).name, "logs");
        if exist(lf, "dir") == 7, folders{end + 1} = char(lf); end %#ok<AGROW>
    end
end
if exist(fullfile(repo, "godot", "logs"), "dir") == 7
    folders{end + 1} = char(fullfile(repo, "godot", "logs"));
end
% 2) Godot's user:// folder
folders{end + 1} = userFolder();
end


function f = userFolder()
% the Godot project's user:// logs folder (project name: Mover6Simulation)
project = "Mover6Simulation";
if ispc
    f = fullfile(getenv("APPDATA"), "Godot", "app_userdata", project, "logs");
elseif ismac
    f = fullfile(homeDir(), "Library", "Application Support", "Godot", "app_userdata", project, "logs");
else
    f = fullfile(homeDir(), ".local", "share", "godot", "app_userdata", project, "logs");
end
f = char(f);
end


function h = homeDir()
h = getenv("HOME");
if isempty(h), h = getenv("USERPROFILE"); end
h = char(h);
end