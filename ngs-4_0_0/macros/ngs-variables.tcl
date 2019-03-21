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

# Working memory attributes that are commonly accessed
CORE_CreateMacroVar WM_GOAL_SET "goals"
CORE_CreateMacroVar WM_ACTIVE_GOAL "active-goal"

CORE_CreateMacroVar NGS_OP_ATTRIBUTE "operator"
CORE_CreateMacroVar NGS_OP_ID        "<o>"
CORE_CreateMacroVar NGS_GOAL_ATTRIBUTE "goal"
CORE_CreateMacroVar NGS_RETURN_VALUES "return-values"
CORE_CreateMacroVar NGS_SUBSTATE_PARAMS "params"
CORE_CreateMacroVar NGS_OUTPUT_COMMAND_ATTRIBUTE "command"

# Elements related to goal decisions
CORE_CreateMacroVar NGS_DECISION_ATTR "requested-decision"
CORE_CreateMacroVar NGS_DECIDES_ATTR "decides"
CORE_CreateMacroVar NGS_DECISION_RET_VAL_NAME "ngs*decision"
CORE_CreateMacroVar NGS_DECISION_ITEM_RET_VAL_NAME "ngs*decision-item"
CORE_CreateMacroVar NGS_ACTIVATION_STATUS_RET_VAL "ngs*activation-status"

# The prefix placed on all tags
CORE_CreateMacroVar NGS_TAG_PREFIX "__tagged*"

# Standard boolean and trilean values
CORE_CreateMacroVar NGS_YES "*YES*"
CORE_CreateMacroVar NGS_NO "*NO*"
CORE_CreateMacroVar NGS_UNKNOWN "*UNKNOWN*"

# Methods of creating objects
CORE_CreateMacroVar NGS_REPLACE_IF_EXISTS "ngs-replace"
CORE_CreateMacroVar NGS_ADD_TO_SET        "ngs-add-to-set"

# Goal States
CORE_CreateMacroVar NGS_GS_ACTIVE "active"
CORE_CreateMacroVar NGS_GS_ACHIEVED "achieved"

# Goal Behaviors
CORE_CreateMacroVar NGS_GB_ACHIEVE "achievement"
CORE_CreateMacroVar NGS_GB_MAINT   "maintenance"

# Types of operators. Atomic do some action, decide generate impasses
CORE_CreateMacroVar NGS_OP_ATOMIC   "atomic"
CORE_CreateMacroVar NGS_OP_SUBSTATE "no-change"
CORE_CreateMacroVar NGS_OP_FUNCTION "no-change-function"

# Operations used for side effects. 
CORE_CreateMacroVar NGS_SIDE_EFFECT_REMOVE "remove"
CORE_CreateMacroVar NGS_SIDE_EFFECT_ADD    "create"
CORE_CreateMacroVar NGS_SIDE_EFFECT_WRITE  "write"
CORE_CreateMacroVar NGS_SIDE_EFFECT_LOG    "log"

# log levels for ngs-log
CORE_CreateMacroVar NGS_TRACE "TRACE"
CORE_CreateMacroVar NGS_DEBUG "DEBUG"
CORE_CreateMacroVar NGS_INFO  "INFO"
CORE_CreateMacroVar NGS_WARN  "WARN"
CORE_CreateMacroVar NGS_ERROR "ERROR"

# these are the actual values that will be used for the log levels
# only intended for internal NGS usage
# note have to use variable here because this file is sourced from inside the CORE_InternalSource macro
variable SOAR_IMPLEMENTATION
variable JSOAR
if { $SOAR_IMPLEMENTATION eq $JSOAR } {
	CORE_CreateMacroVar NGS_TRACE_VALUE "TRACE"
	CORE_CreateMacroVar NGS_DEBUG_VALUE "DEBUG"
	CORE_CreateMacroVar NGS_INFO_VALUE  "INFO"
	CORE_CreateMacroVar NGS_WARN_VALUE  "WARN"
	CORE_CreateMacroVar NGS_ERROR_VALUE "ERROR"
} else {
    # note that csoar log channel numbers are limited to 1-100
    # using numbers in the middle (but not exactly the middle) under the assumption
    # that numbers at the ends (and nice numbers like 50) are more likely to be used by users directly
    CORE_CreateMacroVar NGS_TRACE_VALUE 61
	CORE_CreateMacroVar NGS_DEBUG_VALUE 62
	CORE_CreateMacroVar NGS_INFO_VALUE  63
	CORE_CreateMacroVar NGS_WARN_VALUE  64
	CORE_CreateMacroVar NGS_ERROR_VALUE 65
}

# create a dictionary mapping the trace values to the names for those values
# note there's no way to currently use CORE_CreateMacroVar for dictionaries,
# so this will have to be manually imported to procs with variable, but only
# internal NGS procs should need it
dict set NGS_LOG_LEVELS $NGS_TRACE $NGS_TRACE_VALUE
dict set NGS_LOG_LEVELS $NGS_DEBUG $NGS_DEBUG_VALUE
dict set NGS_LOG_LEVELS $NGS_INFO  $NGS_INFO_VALUE
dict set NGS_LOG_LEVELS $NGS_WARN  $NGS_WARN_VALUE
dict set NGS_LOG_LEVELS $NGS_ERROR $NGS_ERROR_VALUE

# default log level. Change with ngs-set-log-level
CORE_CreateMacroVar NGS_LOG_LEVEL $NGS_INFO

# Substate Tags
CORE_CreateMacroVar NGS_TAG_SUBSTATE_RESULT_RETURNED "ngs*substate-result-returned"
CORE_CreateMacroVar NGS_TAG_CONSTRUCTED 			 "ngs*constructed"
CORE_CreateMacroVar NGS_TAG_INTELLIGENT_CONSTRUCTION "ngs*intelligent-construction"
CORE_CreateMacroVar NGS_TAG_SHALLOW_COPY			 "ngs*shallow-copy"
CORE_CreateMacroVar NGS_TAG_COPY_COMPLETE			 "ngs*copy-complete"
CORE_CreateMacroVar NGS_TAG_GOAL_STACK_SELECTED	     "ngs*copied-level"
CORE_CreateMacroVar NGS_TAG_SOURCE_OBJ               "ngs*source-object"
CORE_CreateMacroVar NGS_TAG_FUNCTION_COMPLETE        "ngs*decision-complete"
CORE_CreateMacroVar	NGS_TAG_SELECTED_GOAL			 "ngs*selected-goal"
CORE_CreateMacroVar NGS_TAG_I_SUPPORTED              "ngs*i-supported"
CORE_CreateMacroVar NGS_TAG_ACTIVATE_ON_DECISION  	 "ngs*activate-on-decision"
CORE_CreateMacroVar NGS_TAG_ALREADY_ACTIVATED 		 "ngs*auto-activated"
CORE_CreateMacroVar NGS_TAG_SELECTION_STATUS  	     "ngs*selected-and-assigned"
CORE_CreateMacroVar NGS_TAG_DECISION_STATUS          "ngs*decision-value"
CORE_CreateMacroVar NGS_TAG_REQUIRES_DECISION 		 "ngs*requires-decision"
CORE_CreateMacroVar NGS_TAG_NO_OPTIONS 				 "ngs*no-decision-options"
CORE_CreateMacroVar NGS_TAG_ONE_OPTION 				 "ngs*one-decision-option"
CORE_CreateMacroVar NGS_TAG_STATUS_COMPLETE			 "ngs*status-complete"
CORE_CreateMacroVar NGS_TAG_ERROR                    "ngs*ERROR"
CORE_CreateMacroVar NGS_TAG_ERROR_STRING             "ngs*ERROR-string"
CORE_CreateMacroVar NGS_TAG_MARK_ACHIEVED            "ngs*mark-goal-achieved"
CORE_CreateMacroVar NGS_TAG_REMOVE_ACHIEVED          "ngs*remove-achieved-goal"
CORE_CreateMacroVar NGS_TAG_TYPE_POOL	             "ngs*goal-type-pool"
CORE_CreateMacroVar NGS_TAG_DECISION_POOL	         "ngs*goal-decision-pool"
CORE_CreateMacroVar GOAL_TAG_STACK_SELECTED			 "ngs*goal-stack-selected"
CORE_CreateMacroVar GOAL_TAG_STACK_ROOT              "ngs*goal-stack-root"
CORE_CreateMacroVar NGS_TAG_LAST_UPDATE_TIME         "ngs*last-update-time"

#######
# List of all ngs operator purpose tags
# You can use these in operator preferences to figure out what an operator is doing
# You can also bind to the operator's parameters using ngs-op-is-xyz macros
CORE_CreateMacroVar NGS_TAG_OP_CREATE_TYPED_OBJECT	    "ngs*op-create-typed-object"
CORE_CreateMacroVar NGS_TAG_OP_CREATE_PRIMITIVE	        "ngs*op-create-primitive"
CORE_CreateMacroVar NGS_TAG_OP_CREATE_TAG		        "ngs*op-create-tag"
CORE_CreateMacroVar NGS_TAG_OP_CREATE_GOAL              "ngs*op-create-goal"
CORE_CreateMacroVar NGS_TAG_OP_RETURN_VALUE             "ngs*op-set-return-value"
CORE_CreateMacroVar NGS_TAG_OP_RETURN_NEW_GOAL          "ngs*op-return-new-goal"
CORE_CreateMacroVar NGS_TAG_OP_REMOVE_ATTRIBUTE         "ngs*op-remove-attribute"
CORE_CreateMacroVar NGS_TAG_OP_REMOVE_GOAL              "ngs*op-remove-goal"
CORE_CreateMacroVar NGS_TAG_OP_REMOVE_TAG               "ngs*op-remove-tag"
CORE_CreateMacroVar NGS_TAG_OP_MAKE_CHOICE              "ngs*op-make-choice"
CORE_CreateMacroVar NGS_TAG_OP_CREATE_OUTPUT_COMMAND    "ngs*op-output-command"
CORE_CreateMacroVar NGS_TAG_OP_DEEP_COPY                "ngs*op-deep-copy"

# The name of the return variable used to return goals (may be multiple such return variables)
CORE_CreateMacroVar NGS_GOAL_RETURN_VALUE            "ngs*new-goal-to-return"

# Standard operators
CORE_CreateMacroVar NGS_OP_COPY_RETURN_VALUES   "ngs-op-copy-return-values-to-destination"
CORE_CreateMacroVar NGS_OP_DECIDE_GOAL          "ngs-op-decide-goal"

# Built-in Types
CORE_CreateMacroVar NGS_TYPE_STATE_RETURN_VALUE "NGS_StateReturnValue"
CORE_CreateMacroVar NGS_TYPE_DECISION_STRUCTURE "NGS_DecisionStructure"
CORE_CreateMacroVar NGS_TYPE_OUTPUT_COMMAND     "NGS_OutputCommand"
CORE_CreateMacroVar NGS_OP_SIDE_EFFECT          "NGS_SideEffect"

# LHS Test Types
CORE_CreateMacroVar NGS_TEST_EQUAL ""
CORE_CreateMacroVar NGS_TEST_NOT_EQUAL "<>"
CORE_CreateMacroVar NGS_TEST_LESS_THAN "<"
CORE_CreateMacroVar NGS_TEST_LESS_THAN_OR_EQUAL "<="
CORE_CreateMacroVar NGS_TEST_GREATER_THAN ">"
CORE_CreateMacroVar NGS_TEST_GREATER_THAN_OR_EQUAL ">="

## Batch operators
CORE_CreateMacroVar NGS_OP_BATCH                  batch

CORE_CreateMacroVar NGS_TAG_BOP_HAS_ITEMS         ngs*bop*has-items
CORE_CreateMacroVar NGS_TAG_BOP_DISABLED          ngs*bop*disabled

CORE_CreateMacroVar NGS_TAG_BOP_LAST_EX_CYCLE     ngs*bop*last-execution-cycle
CORE_CreateMacroVar NGS_TAG_BOP_NEXT_ACTIVE_CYCLE ngs*bop*next-active-cycle
CORE_CreateMacroVar NGS_TAG_BOP_LAST_EX_TIME      ngs*bop*last-execution-time
CORE_CreateMacroVar NGS_TAG_BOP_NEXT_ACTIVE_TIME  ngs*bop*next-active-time

CORE_CreateMacroVar NGS_BOP_PERIOD_DECISION_CYCLE ngs*bop*period*decision-cycle
CORE_CreateMacroVar NGS_BOP_PERIOD_TIME_IN_MS     ngs*bop*period*time-ms

CORE_CreateMacroVar NGS_BATCH_OP_CATEGORY          ngs
CORE_CreateMacroVar NGS_BATCH_OP_CTXVAR_STANDARD   set-ctx-var-values
CORE_CreateMacroVar NGS_BATCH_OP_GENERAL           general
CORE_CreateMacroVar NGS_BATCH_OP_GOAL_PROCESSING   goal-processing
CORE_CreateMacroVar NGS_CTX_VAR_DEF_BATCH_OP_PARAM "$NGS_BATCH_OP_CATEGORY $NGS_BATCH_OP_CTXVAR_STANDARD"
CORE_CreateMacroVar NGS_GOAL_DEF_BATCH_OP_PARAM    "$NGS_BATCH_OP_CATEGORY $NGS_BATCH_OP_GOAL_PROCESSING"
CORE_CreateMacroVar NGS_GENERAL_DEF_BATCH_OP_PARAM "$NGS_BATCH_OP_CATEGORY $NGS_BATCH_OP_GENERAL"

# Debug trace categories. You should put these in your debug.tcl file and
#  load this before loading NGS.
# CORE_ActivateTraceCategory NGS_TRACE_I_TYPED_OBJECTS
# CORE_ActivateTraceCategory NGS_TRACE_O_TYPED_OBJECTS
# CORE_ActivateTraceCategory NGS_TRACE_I_GOALS
# CORE_ActivateTraceCategory NGS_TRACE_O_GOALS
# CORE_ActivateTraceCategory NGS_TRACE_ATOMIC_OPERATORS
# CORE_ActivateTraceCategory NGS_TRACE_SUBSTATE_OPERATORS
# CORE_ActivateTraceCategory NGS_TRACE_SIDE_EFFECTS
# CORE_ActivateTraceCategory NGS_TRACE_TAGS
# CORE_ActivateTraceCategory NGS_TRACE_PRIMITIVES
# CORE_ActivateTraceCategory NGS_TRACE_RETURN_VALUES
# CORE_ActivateTraceCategory NGS_TRACE_DECISIONS
# CORE_ActivateTraceCategory NGS_TRACE_OUTPUT
# CORE_ActivateTraceCategory NGS_TRACE_ERRORS

