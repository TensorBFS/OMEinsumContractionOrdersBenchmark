using TensorInference, OMEinsumContractionOrders

function main(optimizer; folder=nothing)
    @info "Running inference with optimizer: $(optimizer)"
    problems = dataset_from_artifact("uai2014")["MAR"]
    problem_set_name = "relational"
    tamaki = [251, 3, 8, 101, 11]
    selected_ids = [3]
    results = []
    for (id, problem) in problems[problem_set_name]
        if id ∉ selected_ids
            @info "Testing: $(problem_set_name)_$id"
            time_elapsed = @elapsed tn = TensorNetworkModel(read_model(problem); optimizer, evidence=read_evidence(problem))
            folder !== nothing && TensorInference.OMEinsum.writejson(joinpath(folder, "$(problem_set_name)_$(id).json"), tn.code)
            # does not optimize over open vertices
            @info "Contraction complexity: $(contraction_complexity(tn)) (tamaki tw = $(tamaki[id])), time cost: $(time_elapsed)s"
            push!(results, (id, contraction_complexity(tn), tamaki[id], time_elapsed))
        end
    end
    return results
end