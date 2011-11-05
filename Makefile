
# all: clang_lookup_app
# clang_lookup_app: has_llvm has_clang

ifeq "$(DEBUG)" "1"
TARGETDIR = ./debug
else
TARGETDIR = ./release
endif

BUILD_PLATFORM = $(shell 'uname')
ifeq "$(BUILD_PLATFORM)" "Linux"
DLL_EXT = so
else
DLL_EXT = dylib
endif

all: $(TARGETDIR)/clang_lookup $(TARGETDIR)/clang_lookup.sh $(TARGETDIR)/libclang.$(DLL_EXT)

clean:
	@echo Cleaning target dirs ...
	rm -rfd debug release

CXXFLAGS = -I$(LLVM_INCLUDE_DIR) -I$(CLANG_INCLUDE_DIR)
LDFLAGS = -L $(LLVM_LIB_DIR)

# TODO: check which of those libs are needed
LLVM_LIBS = -lLLVMSupport -lLLVMBitWriter -lLLVMBitWriter -lLLVMmc
CLANG_LIBS = -lclang -lclangLex -lclangAST -lclangParse -lclangAnalysis -lclangRewrite -lclangBasic -lclangSema -lclangCodeGen -lclangSerialization -lclangDriver -lclangStaticAnalyzerCheckers -lclangFrontend -lclangStaticAnalyzerCore -lclangFrontendTool -lclangStaticAnalyzerFrontend -lclangIndex

LLVM_BASE_DIR = ./llvm
LLVM_INCLUDE_DIR = $(LLVM_BASE_DIR)/include

CLANG_BASE_DIR = ./llvm/tools/clang
CLANG_INCLUDE_DIR = $(CLANG_BASE_DIR)/include

ifeq "$(DEBUG)" "1"
LLVM_BIN_DIR = $(LLVM_BASE_DIR)/Debug/bin
LLVM_LIB_DIR = $(LLVM_BASE_DIR)/Debug/lib
else
LLVM_BIN_DIR = $(LLVM_BASE_DIR)/Release/bin
LLVM_LIB_DIR = $(LLVM_BASE_DIR)/Release/lib
endif

PATH := $(LLVM_BIN_DIR):$(PATH)

$(TARGETDIR)/exists:
	mkdir -p $(TARGETDIR)
	touch $@

$(TARGETDIR)/%.o: %.cpp $(TARGETDIR)/has_llvm $(TARGETDIR)/has_clang
	@echo Compiling $< ...
	$(CXX) -c $(CXXFLAGS) $< -o $@

$(TARGETDIR)/clang_lookup: $(TARGETDIR)/clang_lookup_app.o
	@echo Linking $@ ...
	$(CXX) $(LDFLAGS) $(LLVM_LIBS) $(CLANG_LIBS) $< -o $@

$(TARGETDIR)/clang_lookup.sh: $(TARGETDIR)/exists
	@echo Creating $@ ...
	echo '#!/usr/bin/env sh' > $@
	echo 'CLANG_LOOKUP_DIR=`dirname $$0`' >> $@
	echo 'CLANG_LOOKUP_DIR=`cd $${CLANG_LOOKUP_DIR}; pwd`' >> $@
	echo 'LD_LIBRARY_PATH=$${CLANG_LOOKUP_DIR} $${CLANG_LOOKUP_DIR}/clang_lookup $$@' >> $@
	echo 'exit $${EXITSTATUS}' >> $@
	chmod a+x $@

$(TARGETDIR)/libclang.dylib: $(LLVM_LIB_DIR)/libclang.dylib
	cp $< $@

$(TARGETDIR)/has_llvm: $(TARGETDIR)/exists
	@echo Checking if LLVM exists ...
	(which -s llvm-as) || (echo $(LLVM_INSTALL_HELP); exit 1)
	touch $@

$(TARGETDIR)/has_clang: $(TARGETDIR)/exists
	@echo Checking if Clang exists ...
	(which -s clang) || (echo $(LLVM_INSTALL_HELP); exit 1)
	touch $@



