JL = julia --project --threads 1

init:
	$(JL) -e 'using Pkg; Pkg.instantiate()'
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Instantiating $${case}"; \
		$(JL) -e "rootdir=\"examples/$${case}\"; using Pkg; Pkg.activate(rootdir); Pkg.instantiate()"; \
	done

init-cotengra:
	@echo "Installing cotengra dependencies via uv"
	cd cotengra && uv sync

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

update-cotengra:
	@echo "Updating cotengra dependencies via uv"
	cd cotengra && uv sync --upgrade

generate-codes:
	for case in inference quantumcircuit nqueens independentset qec; do \
		echo "Generating codes for $${case}"; \
		julia --project=examples/$${case} -e "include(joinpath(\"examples\", \"$${case}\", \"main.jl\")); main(joinpath(\"examples\", \"$${case}\", \"codes\"))"; \
	done

generate-einsumorg-codes:
	mkdir -p examples/einsumorg/codes
	python3 examples/einsumorg/main.py

run:
	@echo "Running benchmarks with optimizer: $(optimizer)"
	$(JL) -e "include(\"runner.jl\"); run([$(optimizer)], overwrite=$${overwrite:-false})"

run-cotengra:
	@echo "Running cotengra: method=$(method), params=$(params)"
	cd cotengra && uv run run.py $(method) "$(params)" $${overwrite:-false}

run1:
	@echo "Running benchmarks with optimizer: $(optimizer)"
	$(JL) -e "include(\"runner.jl\"); run([$(optimizer)], overwrite=$${overwrite:-false}, problem_list=[(\"quantumcircuit\", \"sycamore_53_20_0.json\")])"

run1-cotengra:
	@echo "Running cotengra: method=$(method), params=$(params)"
	cd cotengra && uv run run.py $(method) "$(params)" $${overwrite:-false}


summary:
	@echo "Summarizing all results (Julia + cotengra)"
	$(JL) -e "include(\"runner.jl\"); summarize_results()"

clean-results:
	find examples -name "*.json" -path "*/results/*" -type f -print0 | xargs -0 /bin/rm -f

report:
	typst compile report.typ report.pdf

report-scan:
	typst compile report-scan.typ report-scan.pdf

figures:
	typst compile --root . figures/sycamore_53_20_0.typ figures/sycamore_53_20_0.svg

.PHONY: init init-cotengra dev free update update-cotengra generate-codes generate-einsumorg-codes run run-cotengra summary clean-results report report-scan figures