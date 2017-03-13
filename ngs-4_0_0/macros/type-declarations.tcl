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

variable NGS_TYPE_STATE_RETURN_VALUE
variable NGS_REPLACE_IF_EXISTS 
variable NGS_TYPE_DECISION_STRUCTURE
variable NGS_OP_SIDE_EFFECT
variable NGS_TYPE_OUTPUT_COMMAND

# A few basic types
#
# Set contains multi-valued attributes (it is technically a set)
#
# HierarchicalSet is a bag that contains a collection of sets, where each collection is named
#
# Bag contains a collection of values, each with a different name and possibly 
#  a different type. Bags are essentially hashtables in terms of structure/access.
#
# HierarchicalBag a bag where each member is itself a bag
#
# Tuple is just 2 or more values
# A pair is two values
#
NGS_DeclareType Set {}
NGS_DeclareType HierarchicalSet { }
NGS_DeclareType Bag {}
NGS_DeclareType HierarchicalBag { }
NGS_DeclareType Tuple { }
NGS_DeclareType Pair  { type Tuple }

# The standard system information structure (contains times and cycle-counts)
# The time attribute is computed using the productions in ngs-standard-time-elaborations.soar
# All times are milliseconds
# Wall time is the system clock (on the computer that is running)
# Sim time is the simulation time if running in simulation
# Cycle count is the number of decision cycles
#
# Time is the vlaue for time you should use in your program. It will
#  be as follows:
#  - cycle-count * 50 if there is no sim-time or wall-time
#  - sim-time if there is a sim-time
#  - wall-time if there is a wall-time and no sim-time
# 
NGS_DeclareType SystemInformation {
    cycle-count ""
    sim-time ""
    wall-time ""
    time ""
}

# Type to create context variable pools and indexes for these pools.
#
# See NGS_CreateGlobalContextVariablePool and NGS_CreateContextPoolCategories.
# These types are used internally and should need to be used by user code in
#  general.
#
NGS_DeclareType NGSContextVariablePool { type HierarchicalBag }
NGS_DeclareType NGSContextVariableCategory { type Bag }

# Type used for the global goal pool.
#
# User methods generally do not need to use this type at all, but if you
#  inspect the top state's goal pool, you will see this type.
#
NGS_DeclareType NGSGoalSet {
    type HierarchicalSet
}

# Type used to create return values in substate
#
# This type is only needed internally by other NGS code and doesn't need
#  to be created by user code
#
# name - name of the return value (a string)
# destination-object - identifier for the object that should recieve the return value
# destination-attribute - name of the attribute to recieve the return value
# replacement-behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
# value - the return value itself (any type). Typically this is set separately from the return value structure
#           being created.
NGS_DeclareType $NGS_TYPE_STATE_RETURN_VALUE {

  name ""
  destination-object ""
  destination-attribute ""
  replacement-behavior $NGS_REPLACE_IF_EXISTS
  value ""
}

# Type used to define a decision as part of a goal
#
# This type is only needed internally by other NGS code and doesn't need
#  to be created by user code
#
# Decision objects also get tagged by the NGS infrastructure with two main tags:
#  1. decision-required (a boolean) if there are open options for this decision
#  2. no-options (a boolean) if there are no current goals to make the decision
#
# See ngs-assign-decision
#
# name - name of the decision (just a user defined string)
# destination-object - identifier for the object that should recieve recieve the decided attribute
# destination-attribute - name of the attribute that represents the result of the decision
# replacement-behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
#
NGS_DeclareType $NGS_TYPE_DECISION_STRUCTURE {
  name ""
  destination-object ""
  destination-attribute ""
  replacement-behavior $NGS_REPLACE_IF_EXISTS
}

# Type used for operator side effects
#
# This type is used internally by NGS to track side effects on operators.
#
# Side effects are limited to simple primitive and shallow copy constructs
# See ngs-add-side-effect and ngs-has-side-effect for details on how to 
#  set up and use side effects.
#
# destination-object - identifier for the object that should recieve the value
# destination-attribute - name of the attribute to recieve the value
# replacement-behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
# value - the value to be set as a side effect of the operator
# action - one of NGS_SIDE_EFFECT_REMOVE or NGS_SIDE_EFFECT_ADD
#
NGS_DeclareType $NGS_OP_SIDE_EFFECT {
	destination-object ""
	destination-attribute ""
	replacement-behavior ""
	value ""
    action ""
}


# Type used for output commands
#
# The base output command only declares a set of tags that may be
#  placed on the output object by the output-link processing
#
# NGS_TAG_STATUS_COMPLETE - Set to NGS_YES after the output link processes
#      the command. This will trigger ngs to remove the output command
# NGS_TAG_ERROR - Set by the output link process if there is an error processing
#      the command. This is the error identifier.
# NGS_TAG_ERROR_STRING - Set by the output link proces sif there is an error processing
#      the command. This is the error description.
#
NGS_DeclareType $NGS_TYPE_OUTPUT_COMMAND {}
