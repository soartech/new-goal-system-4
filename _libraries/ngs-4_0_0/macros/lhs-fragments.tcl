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


# get a binding to the tags on an object.
#
# Use for productions that change the achieve, suspended,
#  unachievable state of a goal
#
# e.g. sp "my-production
#         [ngs-match-tags <goal> <gtags>]
#         -->
#         [ngs-tag <gtags> newtag newvalue]
#
proc ngs-match-tags { object obj_tags } {
  return "($object ^tags $obj_tags)"
}

# Use to test an object for a type
#
# e.g. [ngs-is-type <mission> adjust-fire]
#
proc ngs-is-type { object_id type_name } {
  return "($object_id ^type $type_name)"
}
proc ngs-is-not-type { object_id type_name } {
  return "-{
            ($object_id ^type.type $type_name)
           }"
}

# Use to test an object (usuall operators/goals) for a name
#
# e.g. [ngs-is-named <o> send-message]
#
proc ngs-is-named { object_id name } {
  return "($object_id ^name $name)"
}
proc ngs-is-not-named { object_id name } {
  return "($object_id -^name $name)"
}

# Use to test an object for a tag
#
# The default tag value is NGS_YES (if none is provided)
#
# e.g. [ngs-is-tagged <mission> completed *yes*]
#
proc ngs-is-tagged { object_id tag_name {tag_val "" } } {
  CORE_RefMacroVars
  CORE_SetIfEmpty tag_val $NGS_YES
  return "($object_id ^tags.$tag_name $tag_val)"
}
proc ngs-is-not-tagged { object_id tag_name {tag_val "" } } {
  CORE_RefMacroVars
  CORE_SetIfEmpty tag_val $NGS_YES
  return "-{
             ($object_id ^tags.$tag_name $tag_val)
           }"
}

########################################################
## Goal states (normally don't need to test this way, but sometimes need to)
########################################################

# Use to find out if a goal is active or not
#
# Note that there can only be one active goal at a time. An active
#  goal is one that is associated with a "decide" operator that is
#  currently selected and in a sub-state.
#
# e.g. [ngs-is-not-active <goal>]
proc ngs-is-active { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-tagged $goal_id $NGS_GS_ACTIVE $NGS_YES]"
}
proc ngs-is-not-active { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-not-tagged $goal_id $NGS_GS_ACTIVE $NGS_YES]"
}


# Use to find out if a goal is achieved or not
#
# e.g. [ngs-is-achieved <goal>]
#
proc ngs-is-achieved { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-tagged $goal_id $NGS_GS_ACHIEVED $NGS_YES]"
}
proc ngs-is-not-achieved { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-not-tagged $goal_id $NGS_GS_ACHIEVED $NGS_YES]"
}


########################################################
##
########################################################
# NOTE: right now it is very hard to test for "not supergoal" and "not subgoal"

# Use to bind to a goal's supergoal
#
# e.g. [ngs-is-supergoal <goal> <potential-supergoal>]
#
proc ngs-is-supergoal { goal supergoal {supergoal_name ""} } {

  set main_test_line "($goal ^supergoal $supergoal)"
  if { $supergoal_name != "" } {
	   return "$main_test_line 
            [ngs-is-named $supergoal $supergoal_name]"
  } else {
      return $main_test_line
  }

}

# Use to bind to a goal's subgoal
#
# e.g. [ngs-is-subgoal <goal> <potential-subgoal> ]
#
proc ngs-is-subgoal { goal subgoal {subgoal_name ""} } {
  set main_test_line = "($goal ^subgoal $subgoal)"
  if { $subgoal_name != "" } {
    return "$main_test_line 
            [ngs-is-named $subgoal $subgoal_name]"
  } else {
    return $main_test_line
  }
}

# Use to start a production to create a new goal
# (binds to the NGS desired goals section
#
# If the goal_name is given, it binds to the id for the goal pool associated
#  with goals of that name. otherwise it binds one level higher at the master pool
#
# e.g. sp "my-production
#         [ngs-match-goalpool <goal-list> <s>]
#         -->
#         [ngs-create-achievement-goal <goal-list> ... ]
#
proc ngs-match-goalpool { state_id goal_pool {goal_name ""} } {
  CORE_RefMacroVars

  if {$goal_name != ""} {
    return "(state $state_id ^superstate nil 
                             ^$WM_GOAL_SET.$goal_name $goal_pool)"
  } else {
    return "(state $state_id ^superstate nil 
                             ^$WM_GOAL_SET $goal_pool)"
  } 
}

# start a production to bind to a goal in the goal pool
#
# Desired goals
#
# e.g. sp "my-production
#          [ngs-match-goal myGoalType <my-goal>]
#          -->
#          ...do something...
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.

proc ngs-match-goal { state_id
                      goal_name 
                      goal_id 
                      {behavior ""}
                      {goal_pool_id ""}} {
  CORE_RefMacroVars

  # Default value initialization
  CORE_GenVarIfEmpty goal_pool_id "goal-pool"
  CORE_SetIfEmpty behavior $NGS_GB_ACHIEVE

  if {$behavior == ""} {
    return "[ngs-match-goalpool $state_id $goal_pool_id $goal_name]
            ($goal_pool_id ^goal $goal_id)"
  } else {
    return "[ngs-match-goalpool $state_id $goal_pool_id $goal_name]
            ($goal_pool_id ^goal     $goal_id)
            ($goal_id   ^behavior $behavior)"
  }
}

# Create a condition that matches and binds within a substate.
#
# Optional paramaters let you bind to the top state and superstate respectively
#
# e.g. sp "my-production
#          [ngs-match-substate <ss> <top-state> <super-state>]
#
proc ngs-match-substate { substate_id {top_state_id ""} {superstate_id ""}} {

  CORE_RefMacroVars

  variable superstate_test
  variable top_state_test

  CORE_GenVarIfEmpty superstate_id "superstate"
  
  set superstate_test "^$WM_SUPERSTATE \{ $superstate_id <> nil \}"
  
  if {$top_state_id != ""} {
     set top_state_test "\n^$WM_TOP_STATE $top_state_id"
  } else {
     set top_state_test ""
  }

  return "(state $substate_id $superstate_test $top_state_test)"
}

# Start a production to bind to an active goal with a given most derived type
#
# Active goals have been selected for processing in a sub-state. This macro
#  binds to the sub-state and tests the WM_ACTIVE_GOAL attribute in the 
#  substate. If you want to bind through the top-state goal pool use
#  ngs-match-top-state-active-goal instead.
#
# e.g. sp "my-production
#          [ngs-match-active-goal myGoalName <my-goal> <ss>]
#          -->
#          ...do something...
proc ngs-match-active-goal { substate_id
                             goal_name 
                             {goal_id ""} 
                             {top_state_id ""}
                             {superstate_id ""} } {
  CORE_RefMacroVars

  # Default value initialization
  CORE_GenVarIfEmpty goal_id $goal_name

  return "[ngs-match-substate $substate_id $top_state_id $superstate_id]
          ($substate_id ^$WM_ACTIVE_GOAL $goal_id)
          [ngs-is-named $goal_id $goal_name]"
}

# Start a production to bind to an active goal at the top-state
#
# Active goals have been selected for processing in a sub-state, but this version
#  of the match macro binds to the top-state and tests for an active goal through
#  the top state goal pool. If you want to bind to the sub-state that processes
#  this active goal, use ngs-match-active-goal instead.
#
# e.g. sp "my-production
#          [ngs-match-active-goal myGoalName <my-goal> <ss>]
#          -->
#          ...do something...
#
proc ngs-match-top-state-active-goal { state_id
                                       goal_name 
                             	      {goal_id ""} } {
  CORE_RefMacroVars

  # Default value initialization
  CORE_GenVarIfEmpty goal_id $goal_name

  return "(state $state_id ^$WM_GOAL_SET.$goal_name $goal_id)
          [ngs-is-tagged $goal_id $NGS_GS_ACTIVE]"
}



# Return the bindings for an acceptable operator _proposal_
#
# This will not bind to a selected operator. 
#  
#
# e.g., sp "my-production
#          [ngs-match-proposed-operator <myoperator>]
#          ...
#
proc ngs-match-proposed-operator { state_id
                                   op_name
 								   {op_behavior ""}
                                   {op_id ""} 
                                   {goal_id ""}} {
  # Default value initialization
  CORE_GenVarIfEmpty op_id "o"

   set goal_test ""
   if {$goal_id != ""} { set $goal_test "\n($op_id ^goal $goal_id" }

  if {op_behavior == "" } {
    return "(state $state_id ^operator $op_id +)
            ($op_id ^name $op_name)"
  } else {
    return return "(state $state_id ^operator $op_id +)
                   ($op_id ^name $op_name)
                   ($op_id ^behavior $op_behavior) $goal_test"
  } 
}

# Return the bindings for two proposed-but-not-necessarily-selected operators
#
# e.g., sp "my-production
#          [ngs-match-two-proposed-operators myoperator1 myoperator2]
#          ...
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.

proc ngs-match-two-proposed-operators { state_id
                                        op1_name 
                                        op2_name 
                                        {op1_id ""} 
                                        {op2_id ""}
                                        {goal1_id ""}
                                        {goal2_id ""}
                                        {op1_behavior ""}
                                        {op2_behavior ""}} {

   # Default value initialization
   CORE_GenVarIfEmpty op1_id "o"
   CORE_GenVarIfEmpty op2_id "o"

   set goal1_test ""
   set goal2_test ""
   if {$goal1_id != ""} { set $goal1_test "\n($op1_id ^goal $goal1_id" }
   if {$goal2_id != ""} { set $goal2_test "\n($op2_id ^goal $goal2_id" }

   set behavior1_test ""
   set behavior2_test ""
   if {$behavior1_id != ""} { set $behavior1_test "\n($op1_id ^behavior $behavior1_id" }
   if {$behavior2_id != ""} { set $behavior2_test "\n($op2_id ^behavior $behavior2_id" }

   return "(state $state_id ^operator $op1_id + $op2_id +)
           ($op1_id ^name $op1_name)
           ($op2_id ^name $op2_name) $goal1_test $goal2_test $behavior1_test $behavior2_test"
}

# Use start a production to apply an operator
#
# e.g. sp "my-production
#         [ngs-operator-application MyOperator <o> <og> <og-tags> <s>]
#
proc ngs-match-selected-operator {state_id
                                  op_name 
                                  {op_id ""} 
                                  {goal_id ""} 
                                  {goal_tags_id ""}} {

  CORE_GenVarIfEmpty op_id "o"
  CORE_GenVarIfEmpty goal_id "goal"

  if {$goal_tags != ""} {
    return "(state $state_id ^operator $op_id)
            ($op_id          ^name $op_name
                             ^goal $goal_id)"
  } else {
    return "(state $state_id ^operator $op_id)
            ($op_id          ^name $op_name
                             ^goal $goal_id)
            ($goal_id        ^tags $goal_tags_id)"    
   }
  
}


# Use start a production to apply an operator
#
# e.g. sp "my-production
#         [ngs-operator-application MyOperator <o> <og> <og-tags> <s>]
#
proc ngs-match-selected-operator-on-top-state {state_id
                                               op_name 
                                               {op_id ""} 
                                               {goal_id ""} 
                                               {goal_tags_id ""} } {
 
  CORE_GenVarIfEmpty op_id "o"
  CORE_GenVarIfEmpty goal_id "goal"

  if {$goal_tags_id != ""} {
    return "(state $state_id ^superstate nil)
            ($state_id       ^operator $op_id)
            ($op_id          ^name $op_name
                             ^goal $goal_id)"
  } else {
    return "(state $state_id ^superstate nil)
            ($state_id       ^operator $op_id)
            ($op_id          ^name $op_name
                             ^goal $goal_id)
            ($goal_id        ^tags $goal_tags_id)"    
   }
  
}

# Use start a production to apply an operator
#
# e.g. sp "my-production
#         [ngs-operator-application MyOperator <o> <og> <og-tags> <s>]
#
proc ngs-match-selected-operator-in-substate {substate_id
                                              op_name 
                                              {op_id ""} 
                                              {goal_id ""} 
                                              {goal_tags_id ""} 
                                              {top_state_id ""}
                                              {superstate_id ""} } {

  CORE_GenVarIfEmpty top_state_id "top-state"
  CORE_GenVarIfEmpty superstate_id "superstate"
  
  CORE_GenVarIfEmpty op_id "o"
  CORE_GenVarIfEmpty goal_id "goal"

  if {$goal_tags_id != ""} {
    return "[ngs-match-substate $substate_id $top_state_id $superstate_id]
            (#substate_id    ^operator $op_id)
            ($op_id          ^name $op_name
                             ^goal $goal_id)"
  } else {
    return "[ngs-match-substate $substate_id $top_state_id $superstate_id]
            (#substate_id    ^operator $op_id)
            ($op_id          ^name $op_name
                             ^goal $goal_id)
            ($goal_id        ^tags $goal_tags_id)"    
   }
  
}
