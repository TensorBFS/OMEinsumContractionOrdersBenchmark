using GenericTensorNetworks, GenericTensorNetworks.Graphs, OMEinsumContractionOrders
using OMEinsumContractionOrders.JSON
using Random

function main(folder::String)
    @info "Random 3-regular graph of size 200"
    graph = Graphs.random_regular_graph(200, 3; seed=42)
    single_run(graph; filename=joinpath(folder, "rg3.json"))

    @info "Random diagonal coupled graph (King's subgraph, or KSG) of size 40"
    graph = GenericTensorNetworks.random_diagonal_coupled_graph(40, 40, 0.8)
    single_run(graph; filename=joinpath(folder, "ksg.json"))
end

function single_run(graph; filename=nothing)
    Random.seed!(42)
    net = GenericTensorNetwork(IndependentSet(graph); optimizer=nothing)
    js = JSON.json(Dict("einsum" => net.code, "size" => uniformsize(net.code, 2)))
    filename !== nothing && write(filename, js)
end