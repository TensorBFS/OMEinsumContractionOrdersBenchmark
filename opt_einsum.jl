using CairoMakie, CliqueTrees, JSON, Metis, OMEinsum, PythonCall
using OMEinsum.OMEinsumContractionOrders: optimize_hyper_nd

ctgr = pyimport("cotengrust")
ctg = pyimport("cotengra")
pickle = pyimport("pickle")

function read_py(name::String)
    path = joinpath("instances", "$name.pkl")
    format_string, tensors = open(file -> pickle.load(file), path)
    inputs, output = ctg.utils.eq_to_inputs_output(format_string)
    shapes = [x.shape for x in tensors]
    size_dict = ctg.utils.shapes_inputs_to_size_dict(shapes, inputs)
    
    inputs, output, size_dict, _ = ctg.utils.canonicalize_inputs(
        inputs=inputs, 
        output=output, 
        size_dict=size_dict,
    )

    return inputs, output, size_dict
end

function read_jl(name::String)
    py_inputs, py_output, py_size_dict = read_py(name)
    inputs = pyconvert(Vector{Vector{Char}}, py_inputs)
    output = pyconvert(Vector{Char}, py_output)
    size_dict = pyconvert(Dict{Char, Int}, py_size_dict)
    return inputs, output, size_dict
end

function printrow(circuit, algorithm, cost, time)
    print(" | ")
    print(rpad(circuit, 55))
    print(" | ")
    print(rpad(algorithm, 20))
    print(" | ")
    print(rpad(cost, 20))
    print(" | ")
    print(rpad(time, 20))
    print(" | ")
    println()
    return
end

costs_rg = Float64[]
times_rg = Float64[]
costs_nd = Float64[]
times_nd = Float64[]
sizes = Float64[]

printrow("network", "library", "contraction cost", "running time")

for file in readdir("instances")
    if endswith(file, ".pkl")
        name = file[begin:end - 4]
        inputs, output, size_dict = read_jl(name)

        # ensure dimensions are greater than 1
        flag = true

        for (i, dim) in size_dict
            if dim == 1
                flag = false
                break
            end
        end

        if flag
            # random-greedy
            inputs, output, size_dict = read_py(name)
            
            _, cost = ctgr.optimize_random_greedy_track_flops(
                inputs, 
                output, 
                size_dict, 
                ntrials=32, 
                use_ssa=true, 
                seed=0
            )
            
            time = @elapsed ctgr.optimize_random_greedy_track_flops(
                inputs, 
                output, 
                size_dict, 
                ntrials=32, 
                use_ssa=true, 
                seed=0
            )
        
            cost = pyconvert(Float64, cost) / log10(2)
            push!(costs_rg, cost)
            push!(times_rg, time)
            printrow(name, "CoTenGra", cost, time)
        
            # nested dissection
            inputs, output, size_dict = read_jl(name)
            
            path = optimize_hyper_nd(
                HyperND(; dis=METISND(), imbalances=130:1:130),
                inputs,
                output,
                size_dict;
                binary = false
            )
        
            time = @elapsed optimize_hyper_nd(
                HyperND(; dis=METISND(), imbalances=130:1:130),
                inputs,
                output,
                size_dict;
                binary = false
            )
        
            cc = contraction_complexity(path, size_dict)
            cost = cc.tc
            push!(costs_nd, cost)
            push!(times_nd, time)
            printrow(name, "CliqueTrees", cost, time)
        
            push!(sizes, length(inputs))
        end
    end
end

figure = Figure(size=(300, 400))

costs = costs_rg .- costs_nd
times = times_rg ./ times_nd

axis = Axis(figure[1, 1]; xscale = log10, ylabel = "contraction cost\nCoTenGra - CliqueTrees", xticksvisible = false, xticklabelsvisible = false)
xlims!(axis, 10,   10^6)
ylims!(axis, -50,   50)
scatter!(axis, sizes, costs)

axis = Axis(figure[2, 1]; xscale = log10, yscale = log10, xlabel = "number of tensors", ylabel = "running time\nCoTenGra / CliqueTrees")
xlims!(axis, 10,   10^6)
ylims!(axis, 10^-3, 10^3)
scatter!(axis, sizes, times)

figure