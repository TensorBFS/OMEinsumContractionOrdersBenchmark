#!/usr/bin/env -S uv run --quiet
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "cotengra>=0.7.5",
#     "numpy>=1.24",
# ]
# ///
"""
Pure Python benchmark script for cotengra optimizers.
Uses uv for fast dependency management.
"""

import json
import time
import hashlib
from pathlib import Path
import argparse
import sys

try:
    import cotengra as ctg
    import numpy as np
except ImportError as e:
    print(f"Error: {e}")
    print("Please install: pip install cotengra numpy")
    sys.exit(1)

def load_config():
    """Load problem list from config.toml"""
    config_path = Path(__file__).parent.parent / "config.toml"
    
    # Simple TOML parser for our use case
    problems = []
    with open(config_path) as f:
        in_files = False
        for line in f:
            line = line.strip()
            if line == "files = [":
                in_files = True
            elif in_files:
                if line == "]":
                    break
                # Parse ["problem", "instance.json"],
                line = line.strip('",[]')
                if line:
                    parts = [p.strip(' "') for p in line.split(',')]
                    if len(parts) == 2:
                        problems.append(tuple(parts))
    return problems

def load_problem(json_path):
    """Load problem from JSON file"""
    with open(json_path) as f:
        data = json.load(f)
    
    # Convert to cotengra format
    inputs = [[str(i) for i in ix] for ix in data['einsum']['ixs']]
    output = [str(i) for i in data['einsum']['iy']]
    size_dict = {str(k): int(v) for k, v in data['size'].items()}
    
    return inputs, output, size_dict

def param_hash(obj):
    """Hash an object for result filename"""
    s = json.dumps(obj, sort_keys=True)
    return hashlib.md5(s.encode()).hexdigest()

def run_one(json_path, method, max_repeats=10, overwrite=False, **hyperparams):
    """Run cotengra optimizer on one problem instance"""
    json_path = Path(json_path)
    print(f"Running: {json_path} with cotengra_{method}")
    
    # Load problem
    inputs, output, size_dict = load_problem(json_path)
    
    # Get valid hyperparameters for this method from cotengra
    hyper_space = ctg.get_hyper_space()
    if method not in hyper_space:
        print(f"Warning: Unknown method '{method}', will try anyway")
        valid_params = set(hyperparams.keys())
    else:
        valid_params = set(hyper_space[method].keys())
    
    # Filter hyperparameters to only include valid ones for this method
    method_hyperparams = {k: v for k, v in hyperparams.items() if k in valid_params}
    
    if hyperparams and not method_hyperparams:
        print(f"Warning: No valid hyperparameters provided for method '{method}'")
        print(f"  Valid parameters: {sorted(valid_params)}")
    
    # Create result filename
    optimizer_config = {
        "name": f"cotengra_{method}",
        "kwargs": {"max_repeats": max_repeats, **method_hyperparams}
    }
    result_hash = param_hash((str(json_path), optimizer_config))
    
    result_dir = json_path.parent.parent / "results"
    result_dir.mkdir(exist_ok=True)
    result_file = result_dir / f"{result_hash}.json"
    
    if result_file.exists() and not overwrite:
        print(f"Skipping: {result_file} (already exists)")
        return
    
    # Run optimizer
    try:
        # Create optimizer configuration
        opt_kwargs = {
            'methods': [method],
            'max_repeats': max_repeats,
            'minimize': 'flops',
            'optlib': 'random'
        }
        
        # Add method-specific configuration if valid hyperparameters are provided
        if method_hyperparams:
            opt_kwargs[f'{method}_conf'] = method_hyperparams
            print(f"Using hyperparameters: {method_hyperparams}")
        
        opt = ctg.HyperOptimizer(**opt_kwargs)
        
        # Warm-up
        tree = opt.search(inputs, output, size_dict)
        
        # Timed run
        start = time.time()
        tree = opt.search(inputs, output, size_dict)
        elapsed = time.time() - start
        
        # Extract results
        tc = np.log2(tree.contraction_cost())
        sc = np.log2(tree.max_size)
        rwc = np.log2(tree.total_write()) + 1  # +1 for read
        
        cc = {"tc": float(tc), "sc": float(sc), "rwc": float(rwc)}
        print(f"Complexity: {cc}, time: {elapsed:.3f}s")
        
        # Save result
        result = {
            "instance": str(json_path),
            "optimizer": f"cotengra_{method}",
            "optimizer_config": optimizer_config,
            "contraction_complexity": cc,
            "time_elapsed": elapsed
        }
        
        with open(result_file, 'w') as f:
            json.dump(result, f)
        
        print(f"Saved to: {result_file}")
        
    except Exception as e:
        print(f"Error running {method} on {json_path}: {e}")
        import traceback
        traceback.print_exc()

def list_methods():
    """List all available methods and their hyperparameters"""
    hyper_space = ctg.get_hyper_space()
    
    print("Available cotengra methods:")
    print("=" * 80)
    for method in sorted(hyper_space.keys()):
        params = hyper_space[method]
        print(f"\n{method} ({len(params)} hyperparameters):")
        for param_name in sorted(params.keys()):
            print(f"  --{param_name.replace('_', '-')}")
    print("\n" + "=" * 80)
    print(f"Total: {len(hyper_space)} methods")

def main():
    parser = argparse.ArgumentParser(
        description='Benchmark cotengra optimizers',
        epilog='Use --list-methods to see all available methods and their hyperparameters'
    )
    parser.add_argument('method', nargs='?', help='Optimizer method (greedy, kahypar, labels, etc.)')
    parser.add_argument('--list-methods', action='store_true',
                       help='List all available methods and exit')
    parser.add_argument('--max-repeats', type=int, default=10, 
                       help='Number of trials (default: 10)')
    parser.add_argument('--overwrite', action='store_true',
                       help='Overwrite existing results')
    
    # Common hyperparameters (used by multiple methods)
    parser.add_argument('--random-strength', type=float,
                       help='Random strength (greedy, betweenness, kahypar, labels, etc.)')
    parser.add_argument('--parts', type=int,
                       help='Number of partitions (kahypar, labels, spinglass, labelprop)')
    parser.add_argument('--mode', type=str,
                       help='Partitioning mode (kahypar, labels)')
    parser.add_argument('--cutoff', type=int,
                       help='Cutoff parameter (kahypar, labels, spinglass, labelprop)')
    parser.add_argument('--imbalance', type=float,
                       help='Imbalance tolerance (kahypar)')
    
    # Greedy-specific
    parser.add_argument('--temperature', type=float,
                       help='Temperature for greedy method')
    parser.add_argument('--costmod', type=str,
                       help='Cost modification tuple for greedy, e.g. "1.0,1.0"')
    
    # Other method-specific
    parser.add_argument('--max-time', type=float,
                       help='Time limit for quickbb/flowcutter methods (seconds)')
    parser.add_argument('--steps', type=int,
                       help='Steps for walktrap method')
    
    args = parser.parse_args()
    
    # Handle --list-methods
    if args.list_methods:
        list_methods()
        return
    
    # Method is required if not listing
    if not args.method:
        parser.error("method is required (or use --list-methods)")
    
    # Build hyperparameters dict from all non-None arguments
    hyperparams = {}
    if args.random_strength is not None:
        hyperparams['random_strength'] = args.random_strength
    if args.temperature is not None:
        hyperparams['temperature'] = args.temperature
    if args.costmod is not None:
        hyperparams['costmod'] = tuple(map(float, args.costmod.split(',')))
    if args.cutoff is not None:
        hyperparams['cutoff'] = args.cutoff
    if args.parts is not None:
        hyperparams['parts'] = args.parts
    if args.mode is not None:
        hyperparams['mode'] = args.mode
    if args.imbalance is not None:
        hyperparams['imbalance'] = args.imbalance
    if args.max_time is not None:
        hyperparams['max_time'] = args.max_time
    if args.steps is not None:
        hyperparams['steps'] = args.steps
    
    # Load problem list
    problems = load_config()
    print(f"Found {len(problems)} problems")
    
    # Run benchmarks
    root_dir = Path(__file__).parent.parent
    for problem_name, instance_name in problems:
        json_path = root_dir / "examples" / problem_name / "codes" / instance_name
        run_one(json_path, args.method, args.max_repeats, args.overwrite, **hyperparams)

if __name__ == '__main__':
    main()

