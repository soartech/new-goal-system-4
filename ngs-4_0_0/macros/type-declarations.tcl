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


# Type used to create return values in substate
#
# This type is only needed internally by other NGS code and doesn't need
#  to be created by user code
#
# name - name of the return value (a string)
# destination-object - identifier for the object that should recieve the return value
# destination-attribute - name of the attribute to recieve the return value
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
# value - the return value itself (any type). Typically this is set separately from the return value structure
#           being created.
NGS_DeclareType $NGS_TYPE_STATE_RETURN_VALUE {

  id ""
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
# replacement_behavior - (Optional) One of NGS_REPLACE_IF_EXISTS (default) or NGS_ADD_TO_SET. The first 
#                        will remove any existing values for the given attribute while creating the new one. 
#                        The latter will leave any existing values for the same attribute in place.
#
NGS_DeclareType $NGS_TYPE_DECISION_STRUCTURE {
  id ""
  destination-object ""
  destination-attribute ""
  replacement-behavior $NGS_REPLACE_IF_EXISTS
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



