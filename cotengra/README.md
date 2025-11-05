# Cotengra Benchmark Setup

This directory contains a **pure Python** implementation for benchmarking [cotengra](https://cotengra.readthedocs.io/) (Python) against OMEinsumContractionOrders.jl (Julia).

## What is Cotengra?

Cotengra uses a **hyper-optimization** approach: it samples different contraction algorithms (called **drivers** or **methods**) with varying **hyperparameters**, then uses an optimization library to intelligently search this space. See the [official advanced guide](https://cotengra.readthedocs.io/en/latest/advanced.html) for details.

## Quick Start

See the main [README.md](../README.md) for installation and usage instructions.

**All cotengra methods are automatically supported!** The benchmark script (`benchmark.py`) dynamically queries cotengra's `get_hyper_space()` to validate hyperparameters for each method. It uses `HyperOptimizer` with `optlib='random'` and `minimize='flops'` for consistent benchmarking.

To see all available methods and their hyperparameters:
```bash
uv run benchmark.py --list-methods
```

## Available Methods (Drivers)

Cotengra provides 9 contraction drivers, each using a different graph algorithm:

| Method | Algorithm Type | Dependencies | Best For |
|--------|---------------|--------------|----------|
| `kahypar` | Hypergraph partitioning | KaHyPar | Highest quality results |
| `greedy` | Random greedy | None | Fast baseline, reliable |
| `labels` | Community detection | None (pure Python) | Fallback, no dependencies |
| `spinglass` | igraph partition | python-igraph | Alternative partitioning |
| `labelprop` | igraph partition | python-igraph | Alternative partitioning |
| `betweenness` | igraph dendrogram | python-igraph | Hierarchical structure |
| `walktrap` | igraph dendrogram | python-igraph | Hierarchical structure |
| `quickbb` | Tree decomposition | - | Tree-width based |
| `flowcutter` | Tree decomposition | - | Tree-width based |

## Understanding Hyperparameters

Each method has internal **hyperparameters** that control its behavior. Cotengra's `HyperOptimizer` **automatically searches** these spaces using an optimization library (optuna, cmaes, etc.).

**Hyperparameter spaces by method:**

- **`kahypar`** (10 params): `cutoff`, `fix_output_nodes`, `parts`, `mode`, `imbalance`, `weight_edges`, `random_strength`, `objective`, `imbalance_decay`, `parts_decay`
- **`greedy`** (3 params): `random_strength`, `temperature`, `costmod`
- **`labels`** (10 params): `cutoff`, `pop_small_bias`, `parts`, `pop_big_bias`, `weight_edges`, `random_strength`, `memory`, `pop_decay`, `con_pow`, `final_sweep`
- **`spinglass`** (10 params): `cutoff`, `parts`, `start_temp`, `update_rule`, `weight_edges`, `random_strength`, `stop_temp`, `icool_fact`, `igamma`, `parts_decay`
- **`labelprop`** (5 params): `cutoff`, `parts`, `weight_edges`, `random_strength`, `parts_decay`
- **`betweenness`** (1 param): `random_strength`
- **`walktrap`** (2 params): `steps`, `random_strength`
- **`quickbb`** (1 param): `max_time`
- **`flowcutter`** (1 param): `max_time`

**Recommended settings by complexity:**

| Complexity | Methods | Suggested `max_repeats` | Suggested `optlib` |
|------------|---------|------------------------|-------------------|
| High (10 params) | kahypar, labels, spinglass | 30-50 | optuna (default) |
| Medium (3-5 params) | greedy, labelprop | 15-30 | optuna or cmaes |
| Low (1-2 params) | betweenness, walktrap, quickbb, flowcutter | 10-20 | random or cmaes |

Methods with more hyperparameters benefit from intelligent optimization (optuna) and higher trial counts. Simpler methods converge quickly and can use random sampling.

### Optimization Parameters

These control the hyper-optimization process (not the methods themselves):

#### `max_repeats` (default: 1)
Number of trials to run. Each trial samples different hyperparameters.
- **1**: Single trial, fastest
- **10-20**: Quick scans, good for testing
- **30-50**: Balanced quality
- **100+**: High-quality, thorough exploration

#### Optimization objective (fixed)
The optimization objective is **fixed to `"flops"`** (minimize total scalar operations) for consistent benchmarking across all methods and problems.

#### `optlib` (default: nothing = optuna)
Which optimization algorithm to use for hyperparameter search:
- **`nothing`** (default): Optuna's Tree of Parzen Estimators (high quality, medium speed)
- **`"cmaes"`**: CMAES algorithm (very fast, great for parallel execution)
- **`"nevergrad"`**: Evolutionary algorithms (very fast, good for parallelization)
- **`"random"`**: Random sampling (no optimization, minimal overhead)
- **`"skopt"`**: Gaussian processes (highest quality but slowest)

**When to use each:**
- Default (Optuna): General purpose, good balance for 10-30 trials
- CMAES/Nevergrad: When running many parallel trials (50+ workers)
- Random: Quick testing (5-10 trials) or when other libraries unavailable
- Skopt: Reference implementation for comparison (slow!)

#### `max_time` (default: nothing)
Time limit in seconds. Stops after this duration regardless of `max_repeats`.

#### `parallel` (default: nothing)
Whether to parallelize trials across multiple CPU cores.

#### Method-specific hyperparameters

Any additional parameters are treated as **fixed hyperparameters** for the method. The script automatically validates these against cotengra's `get_hyper_space()` to ensure only valid parameters are passed to each method.

Examples:
- `random_strength=0.5` for greedy, betweenness, labels, etc.
- `temperature=0.1` for greedy
- `parts=4` for kahypar, labels, spinglass, labelprop

These override the automatic hyperparameter search for those specific parameters. To see which parameters are valid for a given method, use `--list-methods`.

## Usage Examples

### Basic Usage

```bash
# Run with default settings (1 trial)
method=greedy params={} make run-cotengra
method=kahypar params={} make run-cotengra
method=labels params={} make run-cotengra

# With custom parameters (Python dict syntax)
method=greedy params="{'max_repeats': 10}" make run-cotengra
method=greedy params="{'random_strength': 0.1, 'temperature': 0.5}" make run-cotengra
method=kahypar params="{'parts': 8, 'imbalance': 0.1}" make run-cotengra
```

### Scanning Hyperparameters

```bash
# Greedy method hyperparameters
for rs in 0.001 0.01 0.1 0.5 1.0; do 
    method=greedy params="{'random_strength': $rs}" make run-cotengra
done

for temp in 0.001 0.01 0.1 0.5 1.0; do 
    method=greedy params="{'temperature': $temp}" make run-cotengra
done

for n in 1 5 10 20 50; do 
    method=greedy params="{'max_repeats': $n}" make run-cotengra
done

# KaHyPar method hyperparameters
for p in 2 4 8 16; do 
    method=kahypar params="{'parts': $p}" make run-cotengra
done

for imb in 0.01 0.1 0.5 1.0; do 
    method=kahypar params="{'imbalance': $imb}" make run-cotengra
done

# Multiple parameters at once
method=greedy params="{'max_repeats': 50, 'temperature': 0.5, 'random_strength': 0.1}" make run-cotengra
```

### Direct Python Script Usage

You can also run the benchmark script directly without the Makefile:

```bash
cd cotengra

# Basic usage
uv run benchmark.py greedy
uv run benchmark.py kahypar --max-repeats 10

# With hyperparameters
uv run benchmark.py greedy --random-strength 0.1 --temperature 0.5
uv run benchmark.py kahypar --parts 8 --imbalance 0.1

# Overwrite existing results
uv run benchmark.py greedy --max-repeats 50 --overwrite

# List all available methods
uv run benchmark.py --list-methods
```

## Output Format

Results are saved in `examples/{category}/results/` as JSON:

```json
{
  "instance": "examples/quantumcircuit/codes/sycamore_53_20_0.json",
  "optimizer": "cotengra_greedy",
  "optimizer_config": {
    "name": "cotengra_greedy",
    "kwargs": {"max_repeats": 10}
  },
  "contraction_complexity": {
    "tc": 28.5,   // log2(FLOPs)
    "sc": 25.3,   // log2(max tensor size)
    "rwc": 26.1   // log2(read-write complexity)
  },
  "time_elapsed": 1.234
}
```

All cotengra optimizer names are prefixed with `cotengra_` to distinguish them from Julia optimizers in the unified summary.

## Files in This Directory

- `benchmark.py` - Main benchmark script (pure Python)
- `pyproject.toml` - Python dependencies managed by `uv`
- `README.md` - This file
- `.python-version` - (auto-generated by uv)
- `uv.lock` - (auto-generated by uv)

## Troubleshooting

### KaHyPar Installation Issues

If KaHyPar fails to install (requires cmake and build tools):

```bash
# Ubuntu/Debian
sudo apt install cmake build-essential

# macOS
brew install cmake

# Then retry
cd cotengra && uv sync
```

Alternatively, use the pure Python `labels` method which provides similar functionality without external dependencies.

### Results Not Appearing

Make sure to run the summary command after benchmarking:
```bash
cd .. && make summary
```

This collects results from both Julia and cotengra into a unified `summary.json`.

## See Also

- [Cotengra Documentation](https://cotengra.readthedocs.io/) - Official documentation
- [Cotengra Advanced Guide](https://cotengra.readthedocs.io/en/latest/advanced.html) - Detailed configuration options
- [Main README](../README.md) - Installation and complete benchmark pipeline
