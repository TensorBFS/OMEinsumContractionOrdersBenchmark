#!/usr/bin/env python3
"""Wrapper script to run cotengra benchmarks with dict parameters"""
import sys
import ast

def main():
    if len(sys.argv) < 3:
        print("Usage: python run.py METHOD PARAMS [OVERWRITE]")
        sys.exit(1)
    
    method = sys.argv[1]
    params = ast.literal_eval(sys.argv[2])
    overwrite = sys.argv[3].lower() == 'true' if len(sys.argv) > 3 else False
    
    # Import after arguments are parsed
    from pathlib import Path
    from benchmark import run_one, load_config
    
    # Load problem list
    root_dir = Path(__file__).parent.parent
    max_repeats = params.get('max_repeats', 1)
    minimize = params.get('minimize', 'flops')
    custom_problems = params.get('problems', None)
    hyperparams = {k: v for k, v in params.items() if k not in ['max_repeats', 'minimize', 'problems']}
    
    # Use custom problem list if provided, otherwise load from config
    if custom_problems:
        problems = custom_problems
        print(f"Using custom problem list: {len(problems)} problems")
    else:
        problems = load_config()
        print(f"Found {len(problems)} problems")
    
    # Run benchmarks
    for problem_name, instance_name in problems:
        json_path = root_dir / "examples" / problem_name / "codes" / instance_name
        run_one(json_path, method, max_repeats, minimize, overwrite, **hyperparams)

if __name__ == '__main__':
    main()

