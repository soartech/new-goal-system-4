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



# Use to test an object for a type
#
# e.g. [ngs-is-type <mission> adjust-fire]
#
proc ngs-is-type { object_id type_name } {
  return "($object_id ^type $type_name)"
}

# Use to test an object for a type
#
# e.g. [ngs-is-not-type <mission> adjust-fire]
#
proc ngs-is-not-type { object_id type_name } {
  return "-{
            ($object_id ^type.type $type_name)
           }"
}

# Use to test an object (usually operators) for a name
#
# e.g. [ngs-is-named <o> send-message]
#
proc ngs-is-named { object_id name } {
  return "($object_id ^name $name)"
}

# Use to test an object for a tag
#
# e.g. [ngs-is-tagged <mission> completed *yes*]
#
proc ngs-is-tagged { object_id tag_name {tag_val "" } } {
  return "($object_id ^tags.$tag_name $tag_val)"
}

# Use to test an object for the lack of a tag
#
# e.g. [ngs-is-not-tagged <mission> completed]
#
proc ngs-is-not-tagged { object_id tag_name {tag_val "" } } {
  return "-{
             ($object_id ^tags.$tag_name $tag_val)
           }"
}

########################################################
## Goal states (normally don't need to test this way, but sometimes need to)
########################################################

# Use to find out if a goal is active or not
#
# e.g. [ngs-is-not-active <goal>]
proc ngs-is-active { goal_id } {
   return "($goal_id ^tags.active *yes*)"
}
proc ngs-is-not-active { goal_id } {
  return "-{ [ngs-is-active $goal_id] }"
}


# Use to find out if a goal is achieved or not
#
# e.g. [ngs-is-achieved <goal>]
#
proc ngs-is-achieved { goal_id } {
   return "($goal_id ^tags.achieved *yes*)"
}
proc ngs-is-not-achieved { goal_id } {
  return "[ngs-is-not-tagged $goal_id achieved *yes*]"
}


########################################################
##
########################################################
# NOTE: right now it is very hard to test for "not parent-goal" and "not subgoal"

# Use to bind to a goal's parent-goal
#
# e.g. [ngs-is-parent-goal <goal> <potential-parent-goal>]
#
proc ngs-is-parent-goal { goal supergoal {supergoal_type ""} } {

  set main_test_line = "($goal ^parent-goal $supergoal)"
  if { $supergoal_type != "" } {
	return "$main_test_line 
            [ngs-is-type $supergoal $supergoal_type]"
  } else {
    return $main_test_line
  }

}

# Use to bind to a goal's subgoal
#
# e.g. [ngs-is-subgoal <goal> <potential-subgoal> ]
#
proc ngs-is-subgoal { goal subgoal {subgoal_type ""} } {
  set main_test_line = "($goal ^subgoal $subgoal)"
  if { $subgoal_type != "" } {
    return "$main_test_line 
            [ngs-is-type $subgoal $subgoal_type]"
  } else {
    return $main_test_line
  }
}

# Use to start a production to create a new goal
# (binds to the NGS desired goals section
#
# e.g. sp "my-production
#         [ngs-match-goalpool <goal-list> <s>]
#         -->
#         [ngs-create-achievement-goal <goal-list> ... ]
#
proc ngs-match-goalpool { goal_list {state_id <s>} } {
  CORE_RefMacroVars
  return "(state $state_id ^superstate nil 
                           ^$WM_GOAL_SET $goal_list)"
}

#
# Match to a named subgoal for a given goal.
#
# e.g., sp "my-production
#          [ngs-match-active-goal my-goal <my-goal>]
#          [ngs-match-subgoal <parentg> sub-name <sg-goal>]
#        --> ..."
#
proc ngs-match-subgoal { parent_goal_id subgoal_type { subgoal_id ""} } {

  if {$subgoal_id == ""} {set subgoal_id [CORE_GenVarName "subgoal"]}
  
    return "($parent_goal_id ^subgoal $subgoal_id)
            [ngs-is-type $subgoal_id $subgoal_type]"
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

proc ngs-match-goal { goal_type 
                     {goal_id ""} 
                     {state_id <s>} } {
  CORE_RefMacroVars

  # Default value initialization
  if {$goal_id == ""} {set goal_id [CORE_GenVarName $goal_type]}

  return "(state $state_id ^superstate   nil
                           ^$WM_GOAL_SET.$goal_type $goal_id)"
}

# Create a condition that matches and binds within a substate.
#
# Optional paramaters let you bind to the top state and superstate respectively
#
# e.g. sp "my-production
#          [ngs-match-substate <ss> <top-state> <super-state>]
#
proc ngs-match-substate { state_id {top_state_id ""} {superstate_id ""}} {

  CORE_RefMacroVars

  variable superstate_test
  variable top_state_test
  
  if {$superstate_id != ""} {
     set superstate_test "^$WM_SUPERSTATE $superstate_id"
  } else {
     set superstate_test "-^$WM_SUPERSTATE nil"
  }
  
  if {$top_state_id != ""} {
     set top_state_test "\n^$WM_TOP_STATE $top_state_id"
  } else {
     set top_state_test ""
  }

  return "(state $state_id $superstate_test $top_state_test)"
}

# Start a production to bind to an active goal with a given most derived type
#
# Active goals have been selected for processing in a sub-state
#
# e.g. sp "my-production
#          [ngs-match-active-goal myGoalType <my-goal> <ss>]
#          -->
#          ...do something...
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.

proc ngs-match-active-goal { goal_type 
                             {goal_id ""} 
                             {substate_id <ss>}
                             {top_state_id ""}
                             {superstate_id ""} {
  CORE_RefMacroVars

  # Default value initialization
  if {$goal_id == ""} {set goal_id [CORE_GenVarName $goal_type]}

  return "[ngs-match-substate $substate_id $top_state_id $superstate_id]
          ($substate_id ^$WM_ACTIVE_GOAL $goal_id)
          [ngs-is-type $goal_id $goal_type]"
}

# Start a production to bind to an active goal with a given most derived type
#
# Active goals have been selected for processing in a sub-state
#
# e.g. sp "my-production
#          [ngs-match-active-goal myGoalType <my-goal> <ss>]
#          -->
#          ...do something...
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.

proc ngs-match-top-stateactive-goal { goal_type 
                             	      {goal_id ""} 
                                      {state_id <s>} {
  CORE_RefMacroVars

  # Default value initialization
  if {$goal_id == ""} {set goal_id [CORE_GenVarName $goal_type]}

  return "(state $state_id ^$WM_GOAL_SET.$goal_type $goal_id)
          [ngs-is-tagged $goal_id $NGS_GS_ACTIVE]"
}

#
# create a condition that matches when there's no active goal of the given type
#
# e.g. sp "my-production
#         [ngs-no-active-goal <goal-name>]
#      -->
#         ...
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.

proc ngs-no-active-goal-of-type { goal_type  
                                  {state_id ""} } {
  CORE_RefMacroVars
 
  variable state_test
  if {$state_id == ""} {
    set state_id "<s>"
    set state_test "(state $state_id)\n"
  } else {
    set state_test ""
  }
  
  return "$state_test -{
  	        ($state_id ^$WM_GOAL_SET.$goal_type $goal_id)
            [ngs-is-tagged $goal_id $NGS_GS_ACTIVE]
           }"
}


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

# Return the bindings for a proposed-but-not-necessarily-selected operator
#
# e.g., sp "my-production
#          [ngs-match-proposed-operator <myoperator>]
#          ...
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.

proc ngs-match-proposed-operator { op_name
 								   {op_type ""}
                                   {op_id ""} 
                                   {state_id <s>}} {
  # Default value initialization
  if {$op1_id == ""} {set op1_id [CORE_GenVarName "operator-1"]}

   return "(state $state_id ^operator $op1_id +)
           ($op1_id ^name $operator1_name)"
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

proc ngs-match-two-proposed-operators { operator1_name operator2_name 
                                          {op1_id ""} 
                                          {op2_id ""} 
                                          {state_id <s>}} {

   # Default value initialization
   if {$op1_id == ""} {set op1_id [CORE_GenVarName "bound-operator"]}
   if {$op2_id == ""} {set op2_id [CORE_GenVarName "bound-operator"]}

   return "(state $state_id ^operator $op1_id + $op2_id +)
           ($op1_id ^name $operator1_name)
           ($op2_id ^name $operator2_name)"
}

# Match two operators with associated goals (by reference)
#
# e.g. sp "my-production
#         [ngs-match-two-operators-with-goals <o1> <o2> o1-type o2-type <og1> <og2> <s>]
#         -->
#         (<s> ^operator <o1> > <o2>)"
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.

proc ngs-match-two-operators-with-goals { op_id1 op_id2 
                                      {op_name1 ""} 
                                      {op_name2 ""} 
                                      {op_goal1 ""} 
                                      {op_goal2 ""}
                                      {state_id "<s>"} } {

  if {$op_name1 == ""} { set ot_line1 "" } else { set ot_line1 "[ngs-is-named $op_id1 $op_name1]" }
  if {$op_name2 == ""} { set ot_line2 "" } else { set ot_line2 "[ngs-is-named $op_id2 $op_name2]" }
  if {$op_goal1 == ""} { set og_line1 "" } else { set og_line1 "($op_id1 ^goal $op_goal1)" }
  if {$op_goal2 == ""} { set og_line2 "" } else { set og_line2 "($op_id2 ^goal $op_goal2)" }

  return "(state $state_id ^operator $op_id1 +
                             ^operator $op_id2 +)
          $ot_line1
          $ot_line2
          $og_line1
          $og_line2"
}

# Use start a production to apply an operator
#
# e.g. sp "my-production
#         [ngs-operator-application MyOperator <o> <og> <og-tags> <s>]
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.

proc ngs-match-operator {operator_name 
                                {operator_id ""} 
                                {goal_id ""} 
                                {goal_tags_id ""} 
                                {state_id "<s>"} } {

  # Default value initialization
  if {$operator_id == ""} {set operator_id [CORE_GenVarName "operator"]}
  if {$goal_id == ""} {set goal_id [CORE_GenVarName "goal"]}
  if {$goal_tags_id == ""} {set goal_tags_id [CORE_GenVarName "goal-tags"]}

  return "(state $state_id ^operator $operator_id)
          ($operator_id ^name $operator_name
                          ^goal $goal_id)
          ($goal_id     ^tags $goal_tags_id)"
}

# Use start a production to create a goal in an operator application
#
# e.g. sp "my-production
#         [ngs-match-operator-for-create-goal <goal-list> MyOperator <o> <og> <og-tags> <s>]
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.

proc ngs-match-operator-for-create-goal {goal_list operator_name 
                                             {operator_id ""} 
                                             {goal_id ""} 
                                             {goal_tags_id ""} 
                                             {state_id "<s>"} } {
  CORE_RefMacroVars

  # Default value initialization
  if {$operator_id == ""} {set operator_id [CORE_GenVarName "operator"]}
  if {$goal_id == ""} {set goal_id [CORE_GenVarName "goal"]}
  if {$goal_tags_id == ""} {set goal_tags_id [CORE_GenVarName "goal-tags"]}

  return "(state $state_id  ^$desired_goals $goal_list
                              ^operator $operator_id)
          ($operator_id     ^name $operator_name
                              ^goal $goal_id)
          ($goal_id         ^tags $goal_tags_id)"
}


############################################################
# test attribute sets

proc ngs-is-exactly-one { obj_id set_attribute set_item_attribute test_condition } {
  return "($obj_id ^$set_attribute.$set_item_attribute <obj1>)
          [eval $test_condition <obj1>]
          -{
             ($obj_id ^$set_attribute.$set_item_attribute { <obj2> <> <obj1> } )
             [eval $test_condition <obj2>]
           }
}

proc ngs-is-more-than-one { obj_id set_attribute set_item_attribute test_condition } {
  return "($obj_id ^$set_attribute.$set_item_attribute <obj1>)
          [eval $test_condition <obj1>]
          ($obj_id ^$set_attribute.$set_item_attribute { <obj2> <> <obj1> } )
          [eval $test_condition <obj2>]
}

# This should match in the case that we have one or more (obj ^attr ^test) matches,
# but should not produce a multimatch causing multiple rule firings.
proc ngs-is-at-least-one { obj_id set_attribute set_item_attribute test_condition } {
  return "-{
	     -{ [ngs-is-exactly-one $obj_id $set_attribute $set_item_attribute $test_condition] }
	   }"
}
