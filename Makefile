JL = julia --project

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Instantiating $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.instantiate()"; \
	done

dev:
	$(JL) -e 'using Pkg; Pkg.develop("OMEinsumContractionOrders"); Pkg.instantiate()'
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Developing $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.develop(\"OMEinsumContractionOrders\"); Pkg.instantiate()"; \
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
		julia --project=examples/$${case} -e "include(joinpath(\"examples\", \"$${case}\", \"main.jl\")); main(joinpath(\"examples\", \"$${case}\", \"codes\"))"; \
	done

run:
	@echo "Running benchmarks with optimizer: $(optimizer)"
	$(JL) -e "include(\"runner.jl\"); run([$(optimizer); overwrite=${{overwrite:-false}}])"

summary:
	$(JL) -e "include(\"runner.jl\"); summarize_results()"

clean-results:
	find examples -name "*.json" -path "*/results/*" -type f -print0 | xargs -0 /bin/rm -f

report:
	typst compile report.typ report.pdf

.PHONY: init dev free update generate-codes run summarize-results clean-results report