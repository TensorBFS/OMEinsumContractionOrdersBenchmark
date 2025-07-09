A repository for benchmarking the performance of different optimizers in [OMEinsumContractionOrders](https://github.com/TensorBFS/OMEinsumContractionOrders.jl).

## Benchmark pipeline

#### 1. Setup environment
```bash
make init  # install all dependencies for all examples
```

If you want to benchmark with the developed version of `OMEinsumContractionOrders`, run
```bash
make dev   # develop the master branch of OMEinsumContractionOrders for all examples
```

To switch back to the released version of `OMEinsumContractionOrders`, run
```bash
make free  # switch back to the released version of OMEinsumContractionOrders
```

To update the dependencies of all examples, run
```bash
make update
```

#### 2. Generate tensor network instances
Examples are defined in the [`examples`](examples) folder. To generate contraction codes for all examples, run
```bash
make generate-codes
```
It will generate a file in the `codes` folder of each example, named `*.json`.
These instances are defined in the `main.jl` file of each example.

#### 3. Run benchmarks
To run benchmarks, run
```bash
optimizer="GreedyMethod()" make run
optimizer="TreeSA()" make run
optimizer="HyperND()" make run
optimizer="Treewidth(MF())" make run
```
It will read the `*.json` files in the `codes` folder of each example, and run the benchmarks (twice by default, to avoid just-in-time compilation overhead).
The runner script is defined in the [`runner.jl`](runner.jl) file.

If you want to run a batch of jobs, just run
```bash
for niters in {1..5}; do optimizer="TreeSA(niters=$niters * 10)" make run; done
for niters in {0..10}; do optimizer="GreedyMethod(α=$niters * 0.1)" make run; done
```

To remove the results of all benchmarks, run
```bash
make clean-results
```

#### 4. Generate report
To summarize the results (a necessary step for visualization), run
```bash
make summary
```
It will generate a file named `summary.json` in the root folder, which contains the results of all benchmarks.

To visualize the results, [typst](https://typst.app/) >= 0.13 is required. After installing typst just run
```bash
make report
```
It will generate a file named `report.pdf` in the root folder, which contains the report of the benchmarks.
Alternatively, you can use VSCode + `Tinymist typst` extension to directly preview it.

## Contribute more examples
The examples are defined in the [`examples`](examples) folder. To add a new example, you need to:
1. Add a new folder in the [`examples`](examples) folder, named after the problem.
2. Setup a independent environment in the new folder, and add the dependencies in the `Project.toml` file.
3. Add a new `main.jl` file in the new folder, which should contain the following functions:
   - `main(optimizer; folder=nothing)`: the main function to generate the contraction codes to the target folder. The codes must be stored with `OMEinsumContractionOrders.writejson` (or `OMEinsum.writejson` if the example uses `OMEinsum`).
