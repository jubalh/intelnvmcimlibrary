#
# Copyright (c) 2015, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of Intel Corporation nor the names of its contributors
#     may be used to endorse or promote products derived from this software
#     without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#
# Makefile for CIM framework
#

# ---- BUILD ENVIRONMENT ---------------------------------------------------------------------------
ROOT_DIR = .
# sets up standard build variables
include $(ROOT_DIR)/build.mk

# ---- COMPONENTS ----------------------------------------------------------------------------------
ifdef BUILD_WINDOWS
	CIMOM = wmi
	CIMOMBUILD = wmi
endif
ifdef BUILD_LINUX
	# really open pegasus
	CIMOM = cmpi
	CIMOMBUILD = cmpi
endif
ifdef BUILD_ESX
	CIMOM = sfcb
	CIMOMBUILD = cmpi
endif

FRAMEWORK_DIR = framework
CIMOM_ROOT = cimom
CIMOM_DIR = $(CIMOM_ROOT)/$(CIMOMBUILD)
COMMON_DIR = common
RAPIDXML_DIR = external/rapidxml-1.13
CMPI_DIR = external/cmpi

CPP_MODULES = $(FRAMEWORK_DIR) $(CIMOM_DIR) $(COMMON_DIR)/logger
C_MODULES = $(COMMON_DIR)/string $(COMMON_DIR)/time
MODULES = $(CPP_MODULES) $(C_MODULES)

BUILD_INCLUDE_DIR = $(BUILD_DIR)/include/intel_cim_framework

# ---- FILES ---------------------------------------------------------------------------------------
CPP_SRC = $(foreach dir,$(CPP_MODULES),$(wildcard $(SRC_DIR)/$(dir)/*.cpp))
C_SRC = $(foreach dir,$(C_MODULES),$(wildcard $(SRC_DIR)/$(dir)/*.c))
SRC = $(C_SRC) $(CPP_SRC)
HEADERS = $(foreach dir,$(MODULES),$(wildcard $(SRC_DIR)/$(dir)/*.h))
HEADER_DIRS = $(MODULES) $(COMMON_DIR) $(CIMOM_ROOT) $(CIMOM_ROOT)/wmi $(CIMOM_ROOT)/cmpi

CPP_OBJS = $(patsubst $(SRC_DIR)/%.cpp,%.o,$(CPP_SRC))
C_OBJS = $(patsubst $(SRC_DIR)/%.c,%.o,$(C_SRC))
OBJS = $(C_OBJS) $(CPP_OBJS)
# add the resource file on windows
ifdef BUILD_WINDOWS
	OBJS += framework_resources.o
endif
OBJNAMES = $(addprefix $(OBJECT_DIR)/, $(OBJS))

# defines the location of each submodule's object files' path
MODULE_DIRS = $(foreach dir,$(MODULES),$(OBJECT_DIR)/$(dir))

# pull in any previously generated source dependency declarations (.d files)
# (hyphen preceeding the "include" keyword allows MAKE to continue if a .d file is not found)
CPP_DEPENDENCIES = $(patsubst $(SRC_DIR)/%.cpp,%.d,$(SRC))
DEPENDENCIES = $(patsubst $(SRC_DIR)/%.c,%.d,$(CPP_DEPENDENCIES))
-include $(addprefix $(OBJECT_DIR)/, $(DEPENDENCIES))

# Target library 'linker name'
TARGETBASE = libcimframework.$(LIB_SUFFIX)
# Target library 'soname'
TARGETSO = $(TARGETBASE).$(VERSION_MAJOR)
# Target library 'real name'
ifdef BUILD_WINDOWS
	TARGET = $(TARGETBASE)
else
	TARGET = $(TARGETSO).$(VERSION_MINOR).0
endif 
# Target library 'real name', prefixed with its output location
# This library is packaged as its own library, therefore output to build directory 
TARGETNAME = $(addprefix $(BUILD_DIR)/, $(TARGET))

# Linux Install Files
LIB_DIR ?= /usr/lib64
# files that get installed into /usr/lib64
LIB_FILES = libcimframework.so*
INCLUDE_DIR ?= /usr/include
# files that get installed into /usr/include/
FRAMEWORK_INCLUDE_DIR = intel_cim_framework

# ---- COMPILER PARAMETERS -------------------------------------------------------------------------
INCS = 	-I$(SRC_DIR) \
		-I$(SRC_DIR)/cimom         \
        -I$(SRC_DIR)/framework     \
        -I$(SRC_DIR)/common        \
        -I$(SRC_DIR)/common/logger \
        -I$(SRC_DIR)/common/string \
		-I$(EXTERN_DIR)/rapidxml-1.13

ifndef BUILD_WINDOWS
	INCS += -I$(EXTERN_DIR)/cmpi/include
endif

LIBS =

ifdef BUILD_WINDOWS
	LIBS += -lws2_32 -lmswsock -lShlwapi
	# these are needed to build the WMI COM stuff
	LIBS += -lkernel32 -luser32 -lgdi32 -lwinspool \
		-lcomdlg32 -ladvapi32 -lshell32 -lole32 -loleaut32 -luuid \
		-lodbc32 -lodbccp32 -lwbemuuid -lwbemcore -lwbemupgd
else ifdef BUILD_LINUX
	LIBS += -ldl -lm
else ifdef BUILD_ESX
	LIBS += -ldl -lm
endif

# Building a DLL - control exports
CPPFLAGS += $(BUILD_DLL_FLAG)
ifeq ($(CIMOMBUILD),cmpi)
	CPPFLAGS += -DCMPI_PLATFORM_LINUX_GENERIC_GNU=1 -DCMPI_VER_86=1
endif

# ---- RECIPES -------------------------------------------------------------------------------------
all: copy_headers $(TARGETNAME)
	
$(OBJECT_DIR):
	$(MKDIR) $(OBJECT_DIR)
	
$(BUILD_DIR):
	$(MKDIR) $(BUILD_DIR)
	
$(BUILD_INCLUDE_DIR): | $(BUILD_DIR)
	$(MKDIR) $(BUILD_INCLUDE_DIR)

copy_headers: $(HEADERS) | $(BUILD_INCLUDE_DIR)
	$(COPY) src/framework/*.h $(BUILD_INCLUDE_DIR)
	$(COPY) src/cimom/*.h $(BUILD_INCLUDE_DIR)
	$(COPY) src/cimom/$(CIMOMBUILD)/*.h $(BUILD_INCLUDE_DIR)
	$(COPY) src/common/logger/*.h $(BUILD_INCLUDE_DIR)
	$(COPY) src/common/string/s_str.h $(BUILD_INCLUDE_DIR)

	
$(MODULE_DIRS): | $(OBJECT_DIR)
	$(MKDIR) $@
	
$(TARGETNAME): $(OBJNAMES) | $(BUILD_DIR)
ifdef BUILD_WINDOWS
	$(CPP) $(CPPFLAGS) -shared $(OBJNAMES) $(LIBS) -o $@ 
else
	$(CPP) $(CPPFLAGS) -Wl,-rpath,$(ESX_SUPPORT_DIR) -shared $(OBJNAMES) $(LIBS) -Wl,-soname,$(TARGETSO) -o $@
	cd $(BUILD_DIR); $(RM) $(TARGETSO); $(SOFTLINK) $(TARGET) $(TARGETSO)
	cd $(BUILD_DIR); $(RM) $(TARGETBASE); $(SOFTLINK) $(TARGET) $(TARGETBASE)
endif

# suffix rule for .c -> .o
$(OBJECT_DIR)/%.o: $(SRC_DIR)/%.c | $(MODULE_DIRS)
	$(CC) $(CFLAGS) $(INCS) -c $< -o $@
	
# suffix rule for .cpp -> .o
$(OBJECT_DIR)/%.o: $(SRC_DIR)/%.cpp | $(MODULE_DIRS)
	$(CPP) $(CPPFLAGS) $(INCS) -c $< -o $@
	
# suffix rule for .rc -> .o
$(OBJECT_DIR)/%.o: $(SRC_DIR)/%.rc | $(MODULE_DIRS)
	$(RC) $(RCFLAGS) $(INCS) $< -o $@

clean:
	rm -f $(TARGETNAME) $(OBJNAMES)
	
clobber:
	$(RMDIR) $(OBJECT_DIR)
	$(RMDIR) $(BUILD_DIR)

install :
	# complete the paths for the files to be installed
	$(eval LIB_FILES := $(addprefix $(BUILD_DIR)/, $(LIB_FILES)))
	$(eval FRAMEWORK_INCLUDE_DIR := $(addprefix $(BUILD_DIR)/include/, $(FRAMEWORK_INCLUDE_DIR)))
	# install files into lib directory
	$(MKDIR) $(RPM_ROOT)$(LIB_DIR)
	$(COPY) $(LIB_FILES) $(RPM_ROOT)$(LIB_DIR)

	# install files into include directory
	$(MKDIR) $(RPM_ROOT)$(INCLUDE_DIR)
	$(COPY) $(FRAMEWORK_INCLUDE_DIR) $(RPM_ROOT)$(INCLUDE_DIR)

uninstall :
	$(eval LIB_FILES := $(addprefix $(RPM_ROOT)$(LIB_DIR)/, $(LIB_FILES)))
	$(eval FRAMEWORK_INCLUDE_DIR := $(addprefix $(RPM_ROOT)$(INCLUDE_DIR)/, $(FRAMEWORK_INCLUDE_DIR)))

	$(RM) $(LIB_FILES)
	$(RMDIR) $(FRAMEWORK_INCLUDE_DIR)

rpm :
	#Make the Directories
	$(MKDIR) $(RPMBUILD_DIR) $(RPMBUILD_DIR)/BUILD $(RPMBUILD_DIR)/SOURCES $(RPMBUILD_DIR)/RPMS \
				$(RPMBUILD_DIR)/SRPMS $(RPMBUILD_DIR)/SPECS $(RPMBUILD_DIR)/BUILDROOT \
				$(RPMBUILD_DIR)/BUILD/intel_cim_framework
	
	#Copy Spec File
	$(COPY) install/linux/$(LINUX_DIST)-release/*.spec $(RPMBUILD_DIR)/SPECS/intel_cim_framework.spec
	#Update the Spec file
	$(SED) -i 's/^%define rpm_name .*/%define rpm_name intel_cim_framework/g' $(RPMBUILD_DIR)/SPECS/intel_cim_framework.spec
	$(SED) -i 's/^%define build_version .*/%define build_version $(BUILDNUM)/g' $(RPMBUILD_DIR)/SPECS/intel_cim_framework.spec
	
	#Archive the directory
	git archive --format=tar --prefix="intel_cim_framework/" HEAD | bzip2 -c > $(RPMBUILD_DIR)/SOURCES/intel_cim_framework.tar.bz2
	#rpmbuild 
	$(RPMBUILD) -ba $(RPMBUILD_DIR)/SPECS/intel_cim_framework.spec --define "_topdir $(RPMBUILD_DIR)" 
	
.PHONY : all clean clobber qb_standard copy_headers install uninstall rpm
