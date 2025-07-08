#import "@preview/cetz:0.4.0": canvas, draw
#import "@preview/cetz-plot:0.1.2": plot

// Read the merged summary data
#let all_data = json("summary.json")

// Function to extract instance name from path
#let get_instance_name(instance_path) = {
  let parts = instance_path.split("/")
  let filename = parts.last()
  filename.replace(".json", "")
}


#let plot-compare(dataset, x-max: auto, y-min: -3, y-max: 3) = {
 plot.plot(
  size: (10, 7),
  x-label: "Log2 Contraction Space Complexity",
  y-label: "Log10 Computing Time (seconds)",
  x-min: 0,
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
        let time = calc.log(entry.time_elapsed, base: 10)
        let optimizer = entry.optimizer
        
        if optimizer not in optimizer_groups {
          optimizer_groups.insert(optimizer, ())
        }
        optimizer_groups.at(optimizer).push((sc, time))
      }
      
      // Define colors and markers for different optimizers
      let colors = (red, blue, green, purple, orange, black)
      let markers = ("o", "x", "square", "triangle", "+")
      
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
          label: optimizer
        )
        i += 1
      }
    }
  )
}

// Group data by problem name from summary file
#let problem_names = ("independentset", "inference", "nqueens", "qec", "quantumcircuit")
#let grouped_data = (:)

#for problem_name in problem_names {
  grouped_data.insert(problem_name, ())
}

#for entry in all_data {
  let problem_name = entry.problem_name
  if problem_name in grouped_data {
    grouped_data.at(problem_name).push(entry)
  }
}

#align(center, text(12pt)[= OMEinsum Contraction Orders Benchmark Results])
#v(30pt)

// Create individual plots for each problem type
#for problem_name in problem_names {
  if problem_name in grouped_data {
    let dataset = grouped_data.at(problem_name)
    figure(
      canvas(length: 1cm, {
        plot-compare(dataset)
      }),
      caption: [Scatter plot for *#problem_name* showing contraction space complexity vs computing time for different optimizers.]
    )
  }
}

#pagebreak()

// Summary statistics table
Summary of benchmark results showing space complexity, computing time, and efficiency ratio for each instance and optimizer.
#v(10pt)
#table(
  columns: 6,
  stroke: 0.5pt,
  [*Problem*], [*Instance*], [*Optimizer*], [*Space Complexity*], [*Computing Time (s)*], [*Efficiency*],
  ..for problem_name in problem_names {
    if problem_name in grouped_data {
      let dataset = grouped_data.at(problem_name)
      for entry in dataset {
      let sc = entry.contraction_complexity.sc
      let time = entry.time_elapsed
      let efficiency = calc.round(sc / time, digits: 1)
      let instance_name = get_instance_name(entry.instance)
      let optimizer = entry.optimizer
      (problem_name, instance_name, optimizer, str(sc), str(calc.round(time, digits: 4)), str(efficiency))
      }
    }
  }
)