#import "@preview/cetz:0.4.0": canvas, draw
#import "@preview/cetz-plot:0.1.2": plot
#show link: set text(blue)

// Read the merged summary data
#let all_data = json("summary.json")

// Function to extract instance name from path
#let get_instance_name(instance_path) = {
  let parts = instance_path.split("/")
  let filename = parts.last()
  filename.replace(".json", "")
}

// Filter data for sycamore_53_20_0 only
#let filtered_data = all_data.filter(entry => {
  let instance_name = get_instance_name(entry.instance)
  instance_name == "sycamore_53_20_0"
})

// the cost function is a * sc + b * tc + c * rwc
#let plot-compare(dataset, x-max: auto, y-min: -3, y-max: 3.5, a: 1, b: 0, c: 0) = {
 plot.plot(
  size: (12, 8),
  x-label: "Log2 Contraction Cost",
  y-label: "Log10 Computing Time (seconds)",
  x-min: auto,
  y-min: y-min,
  y-max: y-max,
  x-max: x-max,
  legend: "inner-north-east",
    {
      // Automatically group points by optimizer
      let optimizer_groups = (:)
      
      // Collect all data points grouped by optimizer
      for entry in dataset {
        let sc = entry.contraction_complexity.sc
        let tc = entry.contraction_complexity.tc
        let rwc = entry.contraction_complexity.rwc
        let cost = a * sc + b * tc + c * rwc
        let time = calc.log(entry.time_elapsed, base: 10)
        let optimizer = entry.optimizer
        
        if optimizer not in optimizer_groups {
          optimizer_groups.insert(optimizer, ())
        }
        optimizer_groups.at(optimizer).push((cost, time))
      }
      
      // Define colors and markers for different optimizers
      let colors = (red, blue, green, purple, orange, black, aqua, gray, teal, maroon, navy, olive)
      let markers = ("o", "square", "triangle", "o", "square", "+", "x")
      
      // Plot each optimizer group (sorted by optimizer name)
      let sorted_optimizers = optimizer_groups.keys().sorted()
      let i = 0
      for optimizer in sorted_optimizers {
        let points = optimizer_groups.at(optimizer)
        let color = colors.at(calc.rem(i, colors.len()))
        let marker = markers.at(calc.rem(i, markers.len()))
        
        plot.add(
          points,
          style: (stroke: none, fill: color),
          mark: marker,
          mark-size: 0.15,
          mark-style: (fill: color, stroke: color),
          label: optimizer
        )
        i += 1
      }
    }
  )
}

#align(center, text(14pt)[
  = Sycamore 53 Qubits 20 Cycles Benchmark
  *Parameter Scan Results*
])
#v(20pt)

== Scan Configuration

All benchmarks are performed on CPU: Intel(R) Xeon(R) Gold 6226R CPU \@ 2.90GHz, restricted to single thread.

This report presents benchmarking results for the *sycamore_53_20_0* instance, comparing different tensor network contraction order optimizers with various parameter settings.

=== Parameter Configuration Table

#table(
  columns: 3,
  stroke: 0.5pt,
  align: (left, left, left),
  [*Optimizer*], [*Parameter*], [*Values*],
  
  // Julia Optimizers - Fixed
  [*Treewidth*], [algorithm], [MF, MMD, AMF],
  table.cell(rowspan: 2)[*KaHyParBipartite*], [sc_target], [25],
  [imbalances], [0.0:0.1:0.8],
  
  // Julia Optimizers - Scans
  table.cell(rowspan: 2)[*TreeSA*], [niters], [{1, 2, 4, 6, 8, 10, 20, 30, 40, 50}],
  [score], [TC (tc_weight=1), SC (sc_weight=1)],
  [*GreedyMethod*], [α], [{0.0, 0.1, 0.2, ..., 1.0}],
  table.cell(rowspan: 3)[*HyperND*], [variant], [base, METISND, KaHyParND],
  [imbalances], [100:10:800 (METISND/KaHyParND only)],
  [score], [TC (tc_weight=1), SC (sc_weight=1)],
  
  // Python Optimizers - Cotengra
  table.cell(rowspan: 2)[*cotengra_greedy*], [max_repeats], [{1, 5, 10, 20, 50}],
  [minimize], [flops, size],
  table.cell(rowspan: 2)[*cotengra_kahypar*], [imbalance], [{0.01, 0.1, 0.3, 0.5, 0.8}],
  [minimize], [flops, size],
)

#v(10pt)

*Note*: TC = Time Complexity (minimize FLOPs), SC = Space Complexity (minimize max tensor size)

#pagebreak()

== Results: Time Complexity Objective

#figure(
  canvas(length: 1cm, {
    plot-compare(filtered_data, a: 0, b: 1, c: 0, y-min: -2, y-max: 4)
  }),
  caption: [Scatter plot showing *time complexity* (log2 FLOPs) vs computing time for different optimizers on sycamore_53_20_0.]
)

#pagebreak()

== Results: Space Complexity Objective

#figure(
  canvas(length: 1cm, {
    plot-compare(filtered_data, a: 1, b: 0, c: 0, y-min: -2, y-max: 4)
  }),
  caption: [Scatter plot showing *space complexity* (log2 max tensor size) vs computing time for different optimizers on sycamore_53_20_0.]
)