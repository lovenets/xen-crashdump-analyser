# Name of the resulting executable
APP-NAME := xen-crashdump-analyser
APP-NAME-DEBUG := $(APP-NAME)-syms

# Set the default action to build the program
.PHONY: all
all: $(APP-NAME)

# Set up flags
COMMON_FLAGS := -Iinclude -g -Os -Wall -Werror -Wextra
CPPFLAGS := $(COMMON_FLAGS) -std=c++98 -fno-rtti -Weffc++
CFLAGS := $(COMMON_FLAGS) -std=c99
LDFLAGS := -g

# List of all the source files.  It gets filled by including Makefile's from subdirectories
SRC :=
include $(shell find ./src -type f -name "Makefile")

# List of all the object files, generated from the list of sorce files
OBJS := $(patsubst %.cpp, %.o, \
		$(patsubst %.c, %.o, $(SRC) ) \
	)

# Build individual object files from source files
%.o: %.cpp
	g++ $(CPPFLAGS) -c $< -o $@

# Ask g{cc,++} to generate depedencies for each source file.
# This has to be regenerated every single run, else changing a header file included in a header file
# included by a source file causes a broken build to occur.
.%.d:
	@g++ -MM -MP $(CPPFLAGS) $*.cpp 2>/dev/null | sed -e 's@^\(.*\)\.o:@$(dir $*.cpp).\1.d $(dir $*.cpp)\1.o:@' > $@

# Include all dependency files.  This generates a complete dependency graph
# Reason for the hacky foreach is because I cant find a nice way to transform a list of
# /sub/dir/%.o -> /sub/dir/.%.d
DEPS := $(patsubst %.o, %.d, $(foreach obj, $(OBJS), $(dir $(obj)).$(notdir $(obj))))
-include $(DEPS)

$(APP-NAME-DEBUG): $(OBJS)
	g++ -o $(APP-NAME-DEBUG) $(LDFLAGS) $(OBJS)

$(APP-NAME) : $(APP-NAME-DEBUG)
	cp $(APP-NAME-DEBUG) $@
	#strip -s $@

# The main build option
.PHONY: build
build: $(APP-NAME)

# Clean the project directory
.PHONY: clean
clean:
	rm -f $(OBJS) $(DEPS) $(APP-NAME) $(APP-NAME-DEBUG) $(SOURCE-ARCHIVE-NAME) dissasm $(SPEC-FILE)

.PHONY: veryclean
veryclean: clean
	find . -name "*~" | xargs rm -f
	rm -f $(wildcard cscope.*)

# Generate cscope indexes for the source code
.PHONY: cscope
cscope:
	rm -f $(wildcard cscope.*)
	find $(shell pwd) -type f \( -name "*.[ch]" -o -name "*.[ch]pp" \) > cscope.files
	find /usr/local/include -name "*.h" >> cscope.files
	cscope -b -q -I/usr/local/include -Iinclude

# Disassemble the program
.PHONY: disasm
dissasm: $(APP-NAME-DEBUG)
	objdump -d $(APP-NAME-DEBUG) -Mintel > dissasm

