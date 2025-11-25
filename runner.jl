using OMEinsumContractionOrders, OMEinsumContractionOrders.JSON, KaHyPar, Metis
using OMEinsumContractionOrders: MF, MMD, SafeRules, AMF, LexM, LexBFS, BFS, MCS, RCMMD, RCMGL, MCSM, METISND, KaHyParND
import TOML

# pirate the show_json for Base.Order.ForwardOrdering (required by HyperND)!!!!
JSON.show_json(io::JSON.Writer.SC, s::JSON.Writer.CS, ::Base.Order.ForwardOrdering) = JSON.show_json(io, s, "ForwardOrdering")
for T in [:MF, :MMD, :AMF, :LexM, :LexBFS, :BFS, :MCS, :RCMMD, :RCMGL, :MCSM, :TreeDecomp]
    @eval JSON.show_json(io::JSON.Writer.SC, s::JSON.Writer.CS, ::$(T)) = JSON.show_json(io, s, string($T))
end

function run_one(input_file, optimizer; overwrite=false)
    @assert endswith(input_file, ".json") "Input file must be a JSON file, got: $(input_file)"
    @info "Running: $(input_file) with $(optimizer)"
    _process_labels(ix::Vector) = Vector{Int}(ix)
    js = JSON.parsefile(input_file)
    code = OMEinsumContractionOrders.EinCode(_process_labels.(js["einsum"]["ixs"]), _process_labels(js["einsum"]["iy"]))
    sizes = Dict([(Base.parse(Int, k)=>Int(v)) for (k, v) in js["size"]])
    filename = joinpath(dirname(dirname(input_file)), "results", "$(paramhash((input_file, optimizer))).json")
    if isfile(filename) && !overwrite
        @info "Skipping: $(filename) (already exists)"
        return
    end
    mkpath(dirname(filename))
    optcode = optimize_code(code, sizes, optimizer)  # the first run is to avoid just-in-time compilation overhead
    time_elapsed = @elapsed optcode = optimize_code(code, sizes, optimizer)
    cc = OMEinsumContractionOrders.contraction_complexity(optcode, sizes)
    @info "Contraction complexity: $(cc), time cost: $(time_elapsed)s, saving to: $(filename)"
    js = JSON.json(Dict(
            "instance" => input_file,
            "optimizer" => string(typeof(optimizer).name.name),
            "optimizer_config" => optimizer,
            "contraction_complexity" => cc,
            "time_elapsed" => time_elapsed
        ))
    open(filename, "w") do f
        JSON.write(f, js)
    end
end

# hash by the content of an object
function paramhash(obj)
    if isprimitivetype(typeof(obj)) || obj isa String
        return hash(obj)
    elseif obj isa Vector
        return hash(map(paramhash, obj))
    else
        return hash(map(x -> paramhash(getfield(obj, x)), fieldnames(typeof(obj))), hash(typeof(obj)))
    end
end

# Load problem list from config.toml
function load_problem_list()
    config_path = joinpath(@__DIR__, "config.toml")
    if !isfile(config_path)
        error("Config file not found: $config_path")
    end
    
    config = TOML.parsefile(config_path)
    if !haskey(config, "instances") || !haskey(config["instances"], "files")
        error("Invalid config format. Expected [instances] section with 'files' array")
    end
    
    problem_list = []
    for file_entry in config["instances"]["files"]
        if length(file_entry) != 2
            error("Invalid file entry format: $file_entry. Expected [problem_name, instance_name]")
        end
        push!(problem_list, (file_entry[1], file_entry[2]))
    end
    
    return problem_list
end

function run(optimizer_list; overwrite=false, problem_list = load_problem_list())
    for (problem_name, instance_name) in problem_list
        for optimizer in optimizer_list
            run_one(joinpath(@__DIR__, "examples", problem_name, "codes", instance_name), optimizer; overwrite)
        end
    end
end

function summarize_results()
    problem_list = load_problem_list()
    results = []
    problems = unique(first.(problem_list))
    file_list = [joinpath(@__DIR__, "examples", problem_name, "codes", instance_name) for (problem_name, instance_name) in problem_list]
    for problem_name in problems
        @info "Summarizing: $(problem_name)"
        folder = joinpath(@__DIR__, "examples", problem_name, "results")
        for file in readdir(folder)
            if endswith(file, ".json")
                data = JSON.parsefile(joinpath(folder, file))
                data["problem_name"] = problem_name
                if data["instance"] in file_list
                    push!(results, data)
                end
            end
        end
    end
    @info "Writing summary to: $(joinpath(@__DIR__, "summary.json"))"
    open(joinpath(@__DIR__, "summary.json"), "w") do f
        JSON.write(f, JSON.json(results))
    end
end
