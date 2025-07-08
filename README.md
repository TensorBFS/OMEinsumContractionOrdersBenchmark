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
make free  # switch back to the released version of OMEinsumContractionOrders for all examples
```

To update the dependencies of all examples, run
```bash
make update
```

#### Generate tensor network instances
To generate samples for all examples, run
```bash
make generate-samples
```

#### Run benchmarks

TBW