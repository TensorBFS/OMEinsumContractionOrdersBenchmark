A repository for benchmarking the performance of different optimizers in [OMEinsumContractionOrders](https://github.com/TensorBFS/OMEinsumContractionOrders.jl).

## Guide

#### Setup environment
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

#### Generate tensor network instances
To generate contraction codes for all examples, run
```bash
make generate-codes
```

#### Run benchmarks
To run benchmarks, run
```bash
make run
```

To summarize the results, run
```bash
make summarize-results
```
It will generate a file in the `results` folder of each example, named `summary.json`.

To clean the results, run
```bash
make clean-results
```

#### Visualize results
To visualize the results, run
```bash
make fig
```
It will generate a file in the `examples` folder of each example, named `*.svg`.