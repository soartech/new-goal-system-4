#
# Copyright (c) 2015, Soar Technology, Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# 
# * Neither the name of Soar Technology, Inc. nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without the specific prior written permission of Soar Technology, Inc.
# 
# THIS SOFTWARE IS PROVIDED BY SOAR TECHNOLOGY, INC. AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL SOAR TECHNOLOGY, INC. OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

## since these definitions may vary per application,
## use macro expansion to define these universally

## echo "\n ... Loading file: [pwd]/standard-variables.tcl";

# determine if we're using jsoar or csoar
# we do this by looking to see if the script command is defined, as it's special to jsoar and unlikely to ever be implemented in csoar
CORE_CreateMacroVar CSOAR csoar
CORE_CreateMacroVar JSOAR jsoar
if { [info command script] eq "" } {
    CORE_CreateMacroVar SOAR_IMPLEMENTATION $CSOAR
} else {
    CORE_CreateMacroVar SOAR_IMPLEMENTATION $JSOAR
}

# Binding variables to use to reference common working memory items
CORE_CreateMacroVar WM_STATE "state"
CORE_CreateMacroVar WM_TOP_STATE "top-state"
CORE_CreateMacroVar WM_SUPERSTATE "superstate"
CORE_CreateMacroVar WM_INPUT_LINK "io.input-link"
CORE_CreateMacroVar WM_OUTPUT_LINK "io.output-link"
CORE_CreateMacroVar WM_SIM_TIME "$WM_INPUT_LINK.system.sim-time"
CORE_CreateMacroVar WM_CYCLE_COUNT "$WM_INPUT_LINK.system.cycle-count"
CORE_CreateMacroVar WM_REAL_TIME "$WM_INPUT_LINK.system.world-time"

CORE_CreateMacroVar WM_OUT_STATUS_COMPLETE "complete"


##########################################################
# Infrastructure use

CORE_CreateMacroVar CORE_var_creation_counter 0

#################################################
# Debug tracing categories. This will be a dictionary
CORE_CreateMacroVar CORE_trace_categories ""

#################################################
# Debug printing configuration

# Level 0: nothing is output
# Level 1: program level traces output (what you really want to see to know status)
# Level 2: program debugging only
# Level 3: system level (e.g. operators, goals, etc) output
CORE_CreateMacroVar CORE_DLVL_NO_DBG 0
CORE_CreateMacroVar CORE_DLVL_LOW 1
CORE_CreateMacroVar CORE_DLVL_MED 2
CORE_CreateMacroVar CORE_DLVL_HIGH 3

CORE_CreateMacroVar CORE_DEBUG_OUTPUT_LEVEL $CORE_DLVL_HIGH

CORE_CreateMacroVar CORE_DBG_PRODUCTION_DUMP_FILE ""
