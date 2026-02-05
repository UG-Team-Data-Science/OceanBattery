# OceanBattery API Worker

Folder-polling worker that runs the Ocean Battery simulation from MATLAB and
streams JSON lines results. Designed for use with multiple workers polling the
same folder. The simulation is a charge -> discharge cycle and streams JSONs
(as lines, i.e. jsonlines) to a file. This allows for wrapping into a streaming
API service in e.g. Python+fastAPI, while keeping the MATLAB code as-is (mostly)
to provide autonomy to the original researchers.


## Worker entrypoint

- `worker_folder_watch_requests.m`

The worker watches for `*.in.json` files, atomically claims them, and writes
`*.out.json` results. Requests support:

- `type: "charging"` (default if `type` is missing)
- `type: "k_values"`

## on_json streaming hook

The worker calls `Simulate` with an optional `opts.on_json` handler. The core
simulation invokes this handler to emit streaming events:

- `type: "timeseries"` with `phase: "charging"` or `phase: "discharging"`
- `type: "summary"` with per-phase totals

The handler receives a MATLAB `struct` and the worker writes each struct as one
JSON line to the output file.

If `opts.on_json` is not provided, the simulation behaves exactly as before.

## Building a worker binary

Compile with MATLAB Compiler (`mcc`), this can then be deployed to a server
using the matlab-runtime container.

```bash
mcc -m -v OceanBatteryAPIWorker/worker_folder_watch_requests.m \
  -a OceanBatteryWithMatlab/functions \
  -a OceanBatteryWithMatlab/functions/efficiency \
  -d OceanBatteryAPIWorker/dist
```

## Release script

If you build locally, you can package and upload the `dist/` folder to a GitHub
Release with:

```bash
bash OceanBatteryAPIWorker/release.sh v0.1.0 "Worker binary v0.1.0"
```

This script requires the GitHub CLI (`gh`) and assumes `dist/` already exists.

## Running examples

Examples to run are in `OceanBatteryAPIWorker/examples`. Start the polling service like this.
Replace `/usr/local/MATLAB/R2025b/` with the path to your MATLAB installation (e.g. `ls -lah \`which mcc\``).

```bash
mkdir work
./OceanBatteryAPIWorker/dist/run_worker_folder_watch_requests.sh /usr/local/MATLAB/R2025b/ work 1
```
Then trigger a job by copying an example into the `work` folder:

```bash
cp ./OceanBatteryAPIWorker/examples/example.k_values.in.json work
sleep 1
cat work/example.k_values.out.json 
```
