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

import cotengra as ctg
import numpy as np

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

def run_one(json_path, method, max_repeats=1, minimize='flops', overwrite=False, **hyperparams):
    """Run cotengra optimizer on one problem instance
    
    Args:
        minimize: cotengra objective - 'flops' (time), 'size' (space), 'write', 'combo'
    """
    json_path = Path(json_path)
    
    # Get valid hyperparameters for this method from cotengra
    hyper_space = ctg.get_hyper_space()
    if method not in hyper_space:
        valid_params = set(hyperparams.keys())
    else:
        valid_params = set(hyper_space[method].keys())
    
    # Filter hyperparameters to only include valid ones for this method
    method_hyperparams = {k: v for k, v in hyperparams.items() if k in valid_params}
    
    # Print configuration
    config = {"max_repeats": max_repeats, "minimize": minimize, **method_hyperparams}
    print(f"\n{json_path.name}: cotengra_{method} {config}")
    
    # Load problem
    inputs, output, size_dict = load_problem(json_path)
    
    # Create result filename
    optimizer_config = {
        "name": f"cotengra_{method}",
        "kwargs": {"max_repeats": max_repeats, "minimize": minimize, **method_hyperparams}
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
        # Create optimizer configuration (disable parallel to avoid hanging)
        opt_kwargs = {
            'methods': [method],
            'max_repeats': max_repeats,
            'minimize': minimize,
            'optlib': 'random',
            'parallel': False  # Disable parallelization to avoid issues
        }
        
        # Add method-specific configuration if valid hyperparameters are provided
        if method_hyperparams:
            opt_kwargs[f'{method}_conf'] = method_hyperparams
        
        opt = ctg.HyperOptimizer(**opt_kwargs)
        
        # Warm-up
        tree = opt.search(inputs, output, size_dict)
        
        # Timed run
        start = time.time()
        tree = opt.search(inputs, output, size_dict)
        elapsed = time.time() - start
        
        # Extract results - call methods and convert to float first, then log2
        contraction_cost = float(tree.contraction_cost())
        max_size = float(tree.max_size())
        total_write = float(tree.total_write())
        
        tc = np.log2(contraction_cost)
        sc = np.log2(max_size)
        rwc = np.log2(total_write) + 1  # +1 for read
        
        cc = {"tc": float(tc), "sc": float(sc), "rwc": float(rwc)}
        print(f"  -> tc={tc:.2f}, sc={sc:.2f}, rwc={rwc:.2f}, time={elapsed:.3f}s")
        
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