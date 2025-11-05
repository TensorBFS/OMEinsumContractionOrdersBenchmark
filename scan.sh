#!/bin/bash
# Benchmark scan script for sycamore_53_20_0 instance

# Julia optimizers (OMEinsumContractionOrders)
PROBLEM='[("quantumcircuit", "sycamore_53_20_0.json")]'
TCSCORE='ScoreFunction(tc_weight=1, sc_weight=0, rw_weight=0)'
SCSCORE='ScoreFunction(tc_weight=0, sc_weight=1, rw_weight=0)'

# optimizer="Treewidth(alg=MF())" problem_list="$PROBLEM" make run1
# optimizer="Treewidth(alg=MMD())" problem_list="$PROBLEM" make run1
# optimizer="Treewidth(alg=AMF())" problem_list="$PROBLEM" make run1
# optimizer="KaHyParBipartite(; sc_target=25)" problem_list="$PROBLEM" make run1
# optimizer="KaHyParBipartite(; sc_target=25, imbalances=0.0:0.1:0.8)" problem_list="$PROBLEM" make run1
# optimizer="HyperND(; score=$TCSCORE)" problem_list="$PROBLEM" make run1
# optimizer="HyperND(; dis=METISND(), score=$TCSCORE, width=50, imbalances=100:10:800)" problem_list="$PROBLEM" make run1
# optimizer="HyperND(; dis=KaHyParND(), score=$TCSCORE, width=50, imbalances=100:10:800)" problem_list="$PROBLEM" make run1
# optimizer="HyperND(; score=$SCSCORE)" problem_list="$PROBLEM" make run1
# optimizer="HyperND(; dis=METISND(), score=$SCSCORE, width=50, imbalances=100:10:800)" problem_list="$PROBLEM" make run1
# optimizer="HyperND(; dis=KaHyParND(), score=$SCSCORE, width=50, imbalances=100:10:800)" problem_list="$PROBLEM" make run1

# for niters in 1 2 4 6 8 10 20 30 40 50; do 
#     optimizer="TreeSA(niters=$niters, score=$TCSCORE)" problem_list="$PROBLEM" make run1
#     optimizer="TreeSA(niters=$niters, score=$SCSCORE)" problem_list="$PROBLEM" make run1
# done

# for niters in {0..10}; do 
#     alpha=$(echo "scale=1; $niters * 0.1" | bc)
#     optimizer="GreedyMethod(α=$alpha)" problem_list="$PROBLEM" make run1
# done

# Cotengra optimizers (Python)
COTENGRA_PROBLEMS="[['quantumcircuit', 'sycamore_53_20_0.json']]"

# # Scan parameters
# for n in 1 5 10 20 50; do 
#     method=greedy params="{'max_repeats': $n, 'problems': $COTENGRA_PROBLEMS, 'minimize': 'flops'}" make run1-cotengra
#     method=greedy params="{'max_repeats': $n, 'problems': $COTENGRA_PROBLEMS, 'minimize': 'size'}" make run1-cotengra
# done

for imb in 0.01 0.1 0.3 0.5 0.8; do
    method=kahypar params="{'imbalance': $imb, 'problems': $COTENGRA_PROBLEMS, 'minimize': 'flops'}" make run1-cotengra
    method=kahypar params="{'imbalance': $imb, 'problems': $COTENGRA_PROBLEMS, 'minimize': 'size'}" make run1-cotengra
done

# Generate summary and report after all benchmarks complete
echo ""
echo "Benchmarks complete! Generating summary and report..."
make summary
make report-scan
echo ""
echo "Report generated: report-scan.pdf"