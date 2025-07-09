using TensorInference, OMEinsumContractionOrders, TensorInference.OMEinsum
using OMEinsumContractionOrders.JSON

function main(folder::String)
    problems = dataset_from_artifact("uai2014")["MAR"]
    problem_set_name = "relational"
    # tamaki = [251, 3, 8, 101, 11]  # the treewidth given by Tamaki's algorithm
    selected_ids = [3]
    for (id, problem) in problems[problem_set_name]
        if id ∈ selected_ids
            @info "Generating code for: $(problem_set_name)_$id"
            tn = TensorNetworkModel(read_model(problem); optimizer=GreedyMethod(), evidence=read_evidence(problem))
            js = JSON.json(Dict("einsum" => OMEinsum.flatten(tn.code), "size" => uniformsize(tn.code, 2)))
            write(joinpath(folder, "$(problem_set_name)_$(id).json"), js)
        end
    end
end