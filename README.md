A repository for benchmarking the performance of different optimizers in [OMEinsumContractionOrders](https://github.com/TensorBFS/OMEinsumContractionOrders.jl).

## Guide

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
```
It will read the `*.json` files in the `codes` folder of each example, and run the benchmarks.
The runner script is defined in the [`runner.jl`](runner.jl) file.

If you want to run a batch of jobs, just run
```bash
for niters in {1..5}; do optimizer="TreeSA(niters=$niters * 10)" make run; done
for niters in {0..10}; do optimizer="GreedyMethod(α=$niters * 0.1)" make run; done
```

To clean the results, run
```bash
make clean-results
```

#### 4. Generate report
To summarize the results (a necessary step for visualization), run
```bash
make summary
```
It will generate a file named `summary.json` in the root folder, which contains the results of all benchmarks.

To visualize the results, run
```bash
make report
```
It will generate a file named `report.pdf` in the root folder, which contains the report of the benchmarks.