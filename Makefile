JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Instantiating $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.instantiate()"; \
	done

dev:
	$(JL) -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Developing $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.develop(path=\".\"); Pkg.instantiate()"; \
	done

free:
	$(JL) -e 'using Pkg; Pkg.free("OMEinsumContractionOrders")'
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Freeing $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.free(\"OMEinsumContractionOrders\")"; \
	done

update:
	$(JL) -e 'using Pkg; Pkg.update()'
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Updating $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.update()"; \
	done

generate-samples:
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Generating samples for $${case}"; \
		julia --project=examples/${case} -e "include(joinpath(\"examples\", \"${case}\", \"main.jl\")); main(GreedyMethod(); folder=joinpath(\"examples\", \"${case}\", \"samples\"))"; \
	done

showme-hypernd:  # QEC does not work with KaHyPar
	for case in inference quantumcircuit nqueens independentset; do \
		echo "Running $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.develop(path=\".\"); Pkg.instantiate(); include(joinpath(rootdir, \"main.jl\")); using KaHyPar; main(HyperND())"; \
	done

showme-treesa:  # QEC does not work with KaHyPar
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Running $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.develop(path=\".\"); Pkg.instantiate(); include(joinpath(rootdir, \"main.jl\")); main(TreeSA())"; \
	done

update-examples:  # QEC does not work with KaHyPar
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Running $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.update()"; \
	done

fig:
	for entry in "docs/src/assets/"*.typ; do \
		echo compiling $$entry to $${entry%.typ}.pdf; \
		typst compile $$entry $${entry%.typ}.pdf; \
		pdf2svg $${entry%.typ}.pdf $${entry%.typ}.svg; \
	done

clean:
	rm -rf docs/build
	find . -name "*.cov" -type f -print0 | xargs -0 /bin/rm -f

.PHONY: init test coverage serve clean update