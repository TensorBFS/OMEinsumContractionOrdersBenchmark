#import "@preview/cetz:0.4.0": canvas, draw
#import "@preview/cetz-plot:0.1.2": plot

// Read the merged summary data
#let all_data = json("summary.json")

// Function to extract problem type from instance path
#let get_problem_type(instance_path) = {
  if instance_path.contains("rg3") {
    "Independent Set (RG3)"
  } else if instance_path.contains("ksg") {
    "Independent Set (KSG)"
  } else if instance_path.contains("inference") {
    "Inference"
  } else if instance_path.contains("nqueens") {
    "N-Queens"
  } else if instance_path.contains("qec") {
    "QEC"
  } else if instance_path.contains("quantumcircuit") {
    "Quantum Circuit"
  } else {
    "Unknown"
  }
}

// Function to extract instance name from path
#let get_instance_name(instance_path) = {
  let parts = instance_path.split("/")
  let filename = parts.last()
  filename.replace(".json", "")
}


#let plot-compare(dataset) = {
plot.plot(
  size: (12, 8),
  x-label: "Log2 Contraction Space Complexity",
  y-label: "Log10 Computing Time (seconds)",
  x-min: 0,
  y-min: -5,
  y-max: 3,
  x-max: 60,
  legend: "inner-north-east",
    {
      // Group points by optimizer
      let greedy_points = ()
      let treesa_points = ()
      
      for entry in dataset {
        let sc = entry.contraction_complexity.sc
        let time = calc.log(entry.time_elapsed, base: 10)
        let optimizer = entry.optimizer
          
        if optimizer == "GreedyMethod" {
          greedy_points.push((sc, time))
        } else if optimizer == "HyperND" {
          treesa_points.push((sc, time))
        }
      }
      
      // Plot Greedy points
      if greedy_points.len() > 0 {
        plot.add(
          greedy_points,
          style: (stroke: none, fill: red),
          mark: "o",
          mark-size: 0.15,
          label: "GreedyMethod"
        )
      }
      
      // Plot TreeSA points  
      if treesa_points.len() > 0 {
        plot.add(
          treesa_points,
          style: (stroke: none, fill: blue),
          mark: "x",
          mark-size: 0.15,
          label: "HyperND"
        )
      }
    }
  )
}

// Group data by problem type
#let problem_types = ("Independent Set (RG3)", "Independent Set (KSG)", "Inference", "N-Queens", "QEC", "Quantum Circuit")
#let grouped_data = (:)

#for problem_type in problem_types {
  grouped_data.insert(problem_type, ())
}

#for entry in all_data {
  let problem_type = get_problem_type(entry.instance)
  if problem_type in grouped_data {
    grouped_data.at(problem_type).push(entry)
  }
}

#align(center, text(12pt)[= OMEinsum Contraction Orders Benchmark Results])
#v(30pt)

// Create individual plots for each problem type
#for problem_type in problem_types {
  if problem_type in grouped_data {
    let dataset = grouped_data.at(problem_type)
    figure(
      canvas(length: 1cm, {
        plot-compare(dataset)
      }),
      caption: [Scatter plot for #problem_type showing contraction space complexity vs computing time for different optimizers.]
    )
  }
}

// Summary statistics table
#figure(
  table(
    columns: 6,
    stroke: 0.5pt,
    [*Problem*], [*Instance*], [*Optimizer*], [*Space Complexity*], [*Computing Time (s)*], [*Efficiency*],
    ..for problem_type in problem_types {
      if problem_type in grouped_data {
        let dataset = grouped_data.at(problem_type)
        for entry in dataset {
        let sc = entry.contraction_complexity.sc
        let time = entry.time_elapsed
        let efficiency = calc.round(sc / time, digits: 1)
        let instance_name = get_instance_name(entry.instance)
        let optimizer = entry.optimizer
        (problem_type, instance_name, optimizer, str(sc), str(calc.round(time, digits: 4)), str(efficiency))
        }
      }
    }
  ),
  caption: "Summary of benchmark results showing space complexity, computing time, and efficiency ratio for each instance and optimizer."
)

#pagebreak()

// = Detailed Analysis

// The individual plots reveal several interesting patterns for each problem type:

// #for problem_type in problem_types {
//   let dataset = grouped_data.at(problem_type)
//   if dataset.len() > 0 {
//     [== #problem_type]
    
//     for entry in dataset {
//       let sc = entry.contraction_complexity.sc
//       let time = entry.time_elapsed
//       let efficiency = calc.round(sc / time, digits: 1)
//       let instance_name = get_instance_name(entry.instance)
//       let optimizer = entry.optimizer
      
//       [- #instance_name (#optimizer): Space complexity = #sc, Computing time = #calc.round(time, digits: 4) s, Efficiency = #efficiency]
//     }
    
//     // Compare optimizers if both are present
//     let greedy_results = dataset.filter(entry => entry.optimizer == "Greedy")
//     let treesa_results = dataset.filter(entry => entry.optimizer == "TreeSA")
    
//     if greedy_results.len() > 0 and treesa_results.len() > 0 {
//       let greedy_avg_time = greedy_results.map(entry => entry.time_elapsed).sum() / greedy_results.len()
//       let treesa_avg_time = treesa_results.map(entry => entry.time_elapsed).sum() / treesa_results.len()
//       let greedy_avg_sc = greedy_results.map(entry => entry.contraction_complexity.sc).sum() / greedy_results.len()
//       let treesa_avg_sc = treesa_results.map(entry => entry.contraction_complexity.sc).sum() / treesa_results.len()
      
//       [*Optimizer Comparison*: Greedy optimizer achieves average SC of #calc.round(greedy_avg_sc, digits: 1) in #calc.round(greedy_avg_time, digits: 4) s, while TreeSA achieves average SC of #calc.round(treesa_avg_sc, digits: 1) in #calc.round(treesa_avg_time, digits: 4) s.]
//     }
//   }
// }

= Overall Insights

1. *Optimizer Performance*: The visualization shows how different optimizers (Greedy vs TreeSA) perform on the same problem instances, revealing trade-offs between solution quality and computation time.

2. *Problem-Specific Patterns*: Each problem type exhibits unique characteristics, with some favoring one optimizer over another in terms of either time efficiency or solution quality.

3. *Instance Variation*: Multiple instances of the same problem type show how problem structure affects optimizer performance.

4. *Trade-off Analysis*: The dual-optimizer approach reveals the trade-offs between different optimization strategies, helping identify the best approach for specific problem characteristics.
