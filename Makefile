PKG=peg
BUILD_DIR=build
PONYC=ponyc
PONY_SRC_BASE=$(shell find . -name "*.pony" | grep -v ./peg/parser.pony)
BIN_DIR=$(BUILD_DIR)/release
BIN=$(BIN_DIR)/ponypeg-gen
DEBUG_DIR=$(BUILD_DIR)/debug
DEBUG=$(DEBUG_DIR)/ponypeg-gen
TEST_SRC=$(PKG)/test
TEST_BIN=$(BUILD_DIR)/test
BENCH_SRC=$(PKG)/bench
BENCH_BIN=$(BUILD_DIR)/bench
GENERATOR_SRC=peg/pony-peg-generate/
GENERATOR_BIN=$(BIN_DIR)/pony-peg-generate
GENERATOR_OUTPUT_DIR=$(BUILD_DIR)/src
EXAMPLE_DIR=peg/example
PARSER_SRC=peg/parser.pony
PYTHON2=/usr/bin/python2
prefix=/usr/local

all: $(BIN_DIR) test $(BIN) ## Run tests and build the package

run: $(BIN) ## Build and run the package
	$(BIN)

debug: $(DEBUG) ## Build a and run the package with --debug
	$(DEBUG)

test: $(TEST_BIN) runtest ## Build and run tests

$(TEST_BIN): $(BUILD_DIR) peg_src
	$(PONYC) -o $(BUILD_DIR) --path . $(TEST_SRC)

runtest: ## Run the tests
	$(TEST_BIN)

bench: $(BENCH_BIN) runbench ## Build and run benchmarks

$(BENCH_BIN): $(BUILD_DIR) peg_src
	$(PONYC) -o $(BUILD_DIR) --path . $(BENCH_SRC)

runbench: ## Run benchmarks
	$(BENCH_BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BIN): $(PONY_SRC) 
	$(PONYC) -o $(BIN_DIR) -p . $(PKG)/example

$(DEBUG_DIR):
	mkdir -p $(DEBUG_DIR)

$(DEBUG): peg_src 
	$(PONYC) --debug -o $(DEBUG_DIR) $(PKG)/example

doc: peg_src ## Build the documentation 
	$(PONYC) -o $(BUILD_DIR) --docs --path . --pass=docs $(PKG)

clean: ## Remove all artifacts
	-rm -rf $(BUILD_DIR)
	-rm peg/parser.pony

clean_all: clean ## Remove all, even the python virtualenv
	-rm -rf venv

.PHONY: help clean clean_all

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

peg_src: $(PONY_SRC) $(PARSER_SRC)

venv:
	virtualenv --python $(PYTHON2) venv
	venv/bin/pip install fastidious

$(PARSER_SRC): venv bootstrap.py ## bootstrap the the peg parser
	venv/bin/python bootstrap.py > $(PARSER_SRC)

$(GENERATOR_OUTPUT_DIR):
	mkdir -p $(GENERATOR_OUTPUT_DIR)

$(GENERATOR_BIN): $(BIN_DIR) peg_src
	$(PONYC) -p . $(GENERATOR_SRC) -o $(BIN_DIR)

generator: $(GENERATOR_BIN)

CALC_PEG=$(EXAMPLE_DIR)/calculator/calculator.ponypeg
CALC_SRC_DIR=$(GENERATOR_OUTPUT_DIR)/calculator
CALC_SRC=$(CALC_SRC_DIR)/main.pony
CALC_BIN=$(BIN_DIR)/calculator

$(CALC_SRC_DIR):
	mkdir -p $(CALC_SRC_DIR)

$(CALC_SRC): generator $(CALC_SRC_DIR) $(CALC_PEG)
	$(GENERATOR_BIN) -i $(CALC_PEG) > $(CALC_SRC)

$(CALC_BIN): $(CALC_SRC)
	$(PONYC) -p . $(CALC_SRC_DIR) -o $(BIN_DIR)
	
calculator: $(CALC_BIN)
