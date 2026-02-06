function worker_folder_watch_requests(in_dir, poll_seconds)
% WORKER_FOLDER_WATCH_REQUESTS Watch a folder for *.in.json
%                              requests and write *.out.json results.
%   Request file format:
%     - filename: <base>.in.json
%     - contents: either { "type": "charging"|"k_values", "params": {...} }
%       or a bare params object (treated as "charging" by default).
%
%   Output:
%     - k_values: <base>.out.json as a single JSON object.
%     - charging: <base>.out.json as JSON lines (streamed) with time series.
%
%   This worker is safe to run in multiple processes: it claims inputs by
%   atomically renaming the *.in.json to *.processing.<id>.json.

    if nargin < 1 || isempty(in_dir)
        error('in_dir is required.');
    end
    if nargin < 2 || isempty(poll_seconds)
        poll_seconds = 0.5;
    else
        if ischar(poll_seconds) || isstring(poll_seconds)
            poll_seconds = str2double(poll_seconds);
        end
        if isnan(poll_seconds)
            error('poll_seconds must be numeric or a numeric string.');
        end
        poll_seconds = floor(poll_seconds);
    end

    if ~exist(in_dir, 'dir')
        error('Input directory does not exist: %s', in_dir);
    end

    worker_id = make_worker_id();

    while true
        files = dir(fullfile(in_dir, '*.in.json'));
        for k = 1:numel(files)
            in_path = fullfile(files(k).folder, files(k).name);
            [claimed_path, out_path] = try_claim(in_path, worker_id);
            if isempty(claimed_path)
                continue;
            end

            try
                req = jsondecode(fileread(claimed_path));
                [req_type, params] = parse_request(req);

                switch req_type
                    case "k_values"
                        K_Values = independant_k_values(params);
                        result = struct( ...
                            'type','k_values', ...
                            'status','ok', ...
                            'values',K_Values);
                        write_json(out_path, result);

                    case "charging"
                        stream_charging(out_path, params);

                    otherwise
                        error('Unknown request type: %s', req_type);
                end
            catch err
                is_det = is_deterministic_error(err);
                write_json(out_path, struct( ...
                    'type','error', ...
                    'message',err.message, ...
                    'deterministic',is_det, ...
                    'stack',{stack_to_cell(err.stack)}));
            end

            % Remove claimed input once processed.
            if exist(claimed_path, 'file') == 2
                delete(claimed_path);
            end
        end
        pause(poll_seconds);
    end
end

function [claimed_path, out_path] = try_claim(in_path, worker_id)
    claimed_path = '';
    out_path = '';

    [folder, name, ext] = fileparts(in_path); % name includes ".in"
    if ~endsWith(name, '.in')
        return;
    end

    claim_name = sprintf('%s.processing.%s%s', name, worker_id, ext);
    claimed_path_try = fullfile(folder, claim_name);

    try
        ok = movefile(in_path, claimed_path_try);
    catch
        ok = false;
    end
    if ~ok
        return;
    end

    base = erase(name, '.in');
    out_path = fullfile(folder, [base '.out.json']);
    claimed_path = claimed_path_try;
end

function [req_type, params] = parse_request(req)
    req_type = "";
    params = req;

    if isfield(req, 'params')
        params = req.params;
    end

    if isfield(req, 'request')
        req_type = string(req.request);
    elseif isfield(req, 'request_type')
        req_type = string(req.request_type);
    elseif isfield(req, 'type')
        req_type = string(req.type);
    end

    if req_type == ""
        req_type = "charging";
    end

    req_type = lower(req_type);
    if req_type == "kvalues"
        req_type = "k_values";
    end
end

function stream_charging(out_path, OB_GUI_parameters)
    dt = NaN;
    if isfield(OB_GUI_parameters, 'Delta_t')
        dt = OB_GUI_parameters.Delta_t;
    end

    write_line(out_path, struct('type','start','request','charging','dt',dt), 'w');

    on_json = @(s) write_line(out_path, s, 'a');
    alive_path = out_path_to_alive_path(out_path);
    should_stop = @() ~is_alive(alive_path, 5);
    opts = struct('on_json', on_json, 'plot', false, 'should_stop', should_stop);
    try
        Simulate(OB_GUI_parameters, opts);
        write_line(out_path, struct('type','end'));
    catch err
        is_det = is_deterministic_error(err);
        write_line(out_path, struct( ...
            'type','error', ...
            'message',err.message, ...
            'deterministic',is_det, ...
            'stack',{stack_to_cell(err.stack)}));
        write_line(out_path, struct('type','end'));
    end
end

function n = min_len(cell_arrays)
    n = inf;
    for c = 1:numel(cell_arrays)
        n = min(n, numel(cell_arrays{c}));
    end
    if isinf(n)
        n = 0;
    end
end

function v = safe_idx(arr, idx)
    if idx <= numel(arr)
        v = arr(idx);
    else
        v = NaN;
    end
end

function write_line(path, s, mode)
    if nargin < 3
        mode = 'a';
    end
    fid = fopen(path, mode);
    if fid == -1
        error('Failed to open output file: %s', path);
    end
    fprintf(fid, '%s\n', jsonencode(s));
    fclose(fid);
end

function write_json(path, obj)
    fid = fopen(path, 'w');
    if fid == -1
        error('Failed to open output file: %s', path);
    end
    fprintf(fid, '%s\n', jsonencode(obj));
    fclose(fid);
end

function id = make_worker_id()
    try
        pid = feature('getpid');
        id = sprintf('pid%d', pid);
    catch
        id = sprintf('rand%d', randi(1e9));
    end
end

function c = stack_to_cell(st)
    c = cell(numel(st),1);
    for k = 1:numel(st)
        c{k} = sprintf('%s:%d', st(k).file, st(k).line);
    end
end

function tf = is_deterministic_error(err)
    tf = false;
    try
        if isfield(err, 'identifier') && ~isempty(err.identifier)
            tf = startsWith(err.identifier, 'OB:Deterministic');
        end
    catch
        tf = false;
    end
end

function path = out_path_to_alive_path(out_path)
    [folder, name, ~] = fileparts(out_path);
    if endsWith(name, '.out')
        base = extractBefore(name, strlength(name) - strlength('.out') + 1);
    else
        base = name;
    end
    path = fullfile(folder, sprintf('%s.alive', base));
end

function alive = is_alive(path, ttl_seconds)
    if exist(path, 'file') ~= 2
        alive = false;
        return;
    end
    info = dir(path);
    if isempty(info)
        alive = false;
        return;
    end
    age_seconds = (now - info.datenum) * 86400;
    alive = age_seconds <= ttl_seconds;
end
