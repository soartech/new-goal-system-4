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

# Standard boolean and trilean values
CORE_CreateMacroVar NGS_YES "*yes*"
CORE_CreateMacroVar NGS_NO "*no*"
CORE_CreateMacroVar NGS_UNKNOWN "*unknown*"

# Goal States
CORE_CreateMacroVar NGS_GS_ACTIVE "active"
CORE_CreateMacroVar NGS_GS_ACHIEVED "achieved"

# Goal Behaviors
CORE_CreateMacroVar NGS_GB_ACHIEVE "achievement"
CORE_CreateMacroVar NGS_GB_MAINT   "maintenance"

# Types of operators. Atomic do some action, decide generate impasses
CORE_CreateMacroVar NGS_OP_ATOMIC "atomic"
CORE_CreateMacroVar NGS_OP_DECIDE "decide"

# Standard operators
CORE_CreateMacroVar NGS_OP_REMOVE_ACHIEVED "ngs-std-remove-achieved-goal"
CORE_CreateMacroVar NGS_OP_CREATE_GOAL     "ngs-std-create-goal"