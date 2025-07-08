using OMEinsumContractionOrders, OMEinsumContractionOrders.JSON, KaHyPar
using OMEinsumContractionOrders: MF, MMD, SafeRules, AMF, LexM, LexBFS, BFS, MCS, RCMMD, RCMGL, MCSM

# pirate the show_json for Base.Order.ForwardOrdering (required by HyperND)!!!!
JSON.show_json(io::JSON.Writer.SC, s::JSON.Writer.CS, ::Base.Order.ForwardOrdering) = JSON.show_json(io, s, "ForwardOrdering")
for T in [:MF, :MMD, :AMF, :LexM, :LexBFS, :BFS, :MCS, :RCMMD, :RCMGL, :MCSM]
    @eval JSON.show_json(io::JSON.Writer.SC, s::JSON.Writer.CS, ::$(T)) = JSON.show_json(io, s, string($T))
end

function run_one(input_file, optimizer; overwrite=false)
    @assert endswith(input_file, ".json") "Input file must be a JSON file, got: $(input_file)"
    @info "Testing: $(input_file) with $(optimizer)"
    rawcode = OMEinsumContractionOrders.readjson(input_file)
    code = OMEinsumContractionOrders.EinCode(OMEinsumContractionOrders.getixsv(rawcode), OMEinsumContractionOrders.getiyv(rawcode))
    filename = joinpath(dirname(dirname(input_file)), "results", "$(paramhash((input_file, optimizer))).json")
    if isfile(filename) && !overwrite
        @info "Skipping: $(filename) (already exists)"
        return
    end
    mkpath(dirname(filename))
    sizes = uniformsize(code, 2)  # TODO: support non-uniform sizes
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

const problem_list = [
    ("independentset", "ksg.json"),
    ("independentset", "rg3.json"),
    ("inference", "relational_3.json"),
    ("nqueens", "nqueens_n=28.json"),
    ("qec", "surfacecode_d=21.json"),
    ("quantumcircuit", "sycamore_53_20_0.json"),
]

function run(optimizer_list; overwrite=false)
    for (problem_name, instance_name) in problem_list
        for optimizer in optimizer_list
            run_one(joinpath(@__DIR__, "examples", problem_name, "codes", instance_name), optimizer; overwrite)
        end
    end
end

function summarize_results()
    results = []
    for problem_name in unique(first.(problem_list))
        @info "Summarizing: $(problem_name)"
        folder = joinpath(@__DIR__, "examples", problem_name, "results")
        for file in readdir(folder)
            if endswith(file, ".json")
                data = JSON.parsefile(joinpath(folder, file))
                data["problem_name"] = problem_name
                push!(results, data)
            end
        end
    end
    @info "Writing summary to: $(joinpath(@__DIR__, "summary.json"))"
    open(joinpath(@__DIR__, "summary.json"), "w") do f
        JSON.write(f, JSON.json(results))
    end
end
