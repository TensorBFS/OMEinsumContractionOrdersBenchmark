using TensorInference, OMEinsumContractionOrders, TensorInference.OMEinsum
using OMEinsumContractionOrders.JSON

# problem_sets = [
#     ("Alchemy", TreeSA(ntrials = 1, niters = 5, βs = 0.1:0.1:100)),
#     ("CSP", TreeSA(ntrials = 1, niters = 5, βs = 0.1:0.1:100)),
#     ("DBN", KaHyParBipartite(sc_target = 25)),
#     ("Grids", TreeSA(ntrials = 1, niters = 5, βs = 0.1:0.1:100)), # greedy also works
#     ("linkage", TreeSA(ntrials = 3, niters = 20, βs = 0.1:0.1:40)), # linkage_15 fails
#     ("ObjectDetection", TreeSA(ntrials = 1, niters = 5, βs = 1:0.1:100)),
#     ("Pedigree", TreeSA(ntrials = 1, niters = 5, βs = 0.1:0.1:100)), # greedy also works
#     ("Promedus", TreeSA(ntrials = 1, niters = 5, βs = 0.1:0.1:100)), # greedy also works
#     ("relational", TreeSA(ntrials=1, niters=5, βs=0.1:0.1:100)),
#     ("Segmentation", TreeSA(ntrials = 1, niters = 5, βs = 0.1:0.1:100))  # greedy also works
# ]

function main(folder::String)
    problems = dataset_from_artifact("uai2014")["MAR"]
    problem_set = [
        ("DBN", 13),
        ("relational", 3),
    ]
    for (problem_set_name, id) in problem_set
        problem = problems[problem_set_name][id]
        @info "Generating code for: $(problem_set_name)_$id"
        tn = TensorNetworkModel(read_model(problem); optimizer=GreedyMethod(), evidence=read_evidence(problem))
        @info contraction_complexity(tn.code, uniformsize(tn.code, 2))
        js = JSON.json(Dict("einsum" => OMEinsum.flatten(tn.code), "size" => uniformsize(tn.code, 2)))
        write(joinpath(folder, "$(problem_set_name)_$(id).json"), js)
    end
end