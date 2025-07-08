solver_list = [
    GreedyMethod(),
    TreeSA(),
    KaHyParBipartite(),
]

for problem in [
    ("independentset", "ksg.json"),
    ("independentset", "rg3.json"),
    ("inference", "relational_3.json"),
    ("nqueens", "nqueens_n=28.json"),
    ("qec")
]
    for solver in solver_list
        main(solver; folder=joinpath(@__DIR__, "samples", problem[1], solver))
    end
end