using TensorQEC, OMEinsumContractionOrders, TensorQEC.OMEinsum
using OMEinsumContractionOrders.JSON

function main(folder::String)
    for d in [9, 13, 17, 21]
        @info "Running surface code for d = $d"
        tanner = CSSTannerGraph(SurfaceCode(d, d))
        ct = compile(TNMAP(; optimizer=GreedyMethod()), tanner)
        js = JSON.json(Dict("einsum" => OMEinsum.flatten(ct.cd.net.code), "size" => uniformsize(ct.cd.net.code, 2)))
        write(joinpath(folder, "surfacecode_d=$(d).json"), js)
    end
    return nothing
end