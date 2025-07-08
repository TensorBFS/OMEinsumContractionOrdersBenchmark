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

generate-codes:
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Generating codes for $${case}"; \
		julia --project=examples/$${case} -e "include(joinpath(\"examples\", \"$${case}\", \"main.jl\")); main(GreedyMethod(); folder=joinpath(\"examples\", \"$${case}\", \"codes\"))"; \
	done

run:
	$(JL) -e "include(\"runner.jl\"); run([GreedyMethod()])"

summarize-results:
	$(JL) -e "include(\"runner.jl\"); summarize_results()"

clean-results:
	find . -name "examples/*/results/*.json" -type f -print0 | xargs -0 /bin/rm -f

fig:
	for entry in "examples/qec/src/assets/"*.typ; do \
		echo compiling $$entry to $${entry%.typ}.pdf; \
		typst compile $$entry $${entry%.typ}.pdf; \
		pdf2svg $${entry%.typ}.pdf $${entry%.typ}.svg; \
	done

clean:
	rm -rf docs/build
	find . -name "*.cov" -type f -print0 | xargs -0 /bin/rm -f

.PHONY: init test coverage serve clean update