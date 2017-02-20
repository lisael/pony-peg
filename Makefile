PKG=peg
BUILD_DIR=build
PONYC=ponyc
PONY_SRC=$(shell find . -name "*.pony")
BIN_DIR=$(BUILD_DIR)/release
BIN=$(BIN_DIR)/example
DEBUG_DIR=$(BUILD_DIR)/debug
DEBUG=$(DEBUG_DIR)/example
TEST_SRC=$(PKG)/test
TEST_BIN=$(BUILD_DIR)/test
BENCH_SRC=$(PKG)/bench
BENCH_BIN=$(BUILD_DIR)/bench
prefix=/usr/local

all: $(BIN_DIR) test $(BIN) ## Run tests and build the package

run: $(BIN) ## Build and run the package
	$(BIN)

debug: $(DEBUG) ## Build a and run the package with --debug
	$(DEBUG)

test: $(TEST_BIN) runtest ## Build and run tests

$(TEST_BIN): $(BUILD_DIR) $(PONY_SRC)
	$(PONYC) -o $(BUILD_DIR) --path . $(TEST_SRC)

runtest: ## Run the tests
	$(TEST_BIN)

bench: $(BENCH_BIN) runbench ## Build and run benchmarks

$(BENCH_BIN): $(BUILD_DIR) $(PONY_SRC)
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

$(DEBUG): $(PONY_SRC) 
	$(PONYC) --debug -o $(DEBUG_DIR) $(PKG)/example

doc: $(PONY_SRC) ## Build the documentation 
	$(PONYC) -o $(BUILD_DIR) --docs --path . --pass=docs $(PKG)

clean: ## Remove all artifacts
	-rm -rf $(BUILD_DIR)
	-rm -rf venv


.PHONY: help

help: ## Show help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' Makefile | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

venv:
	virtualenv --python /usr/bin/python2 venv
	venv/bin/pip install fastidious

peg/parser.pony: venv bootstrap.py ## bootstrap the the peg parser
	venv/bin/python bootstrap.py > peg/parser.pony

build/bin:
	mkdir -p build/bin

build/bin/pony-peg-generate: peg/parser.pony build/bin $(PONY_SRC)
	ponyc -p . peg/pony-peg-generate -o build/bin/

generator: build/bin/pony-peg-generate
