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

# Binds to an object's type, if it has a type attribute
#
# [ngs-is-type object_id type_name]
#
# If the object has more than one type, this will bind to them all
#  (though later tests may filter out some of the bindings)
#
proc ngs-is-type { object_id type_name } {
  return "($object_id ^type $type_name)"
}

# Evaluates to true if the given object is not of the given type
# 
# [ngs-is-not-type object_id typename]
#
proc ngs-is-not-type { object_id type_name } {
  return "-($object_id ^type $type_name)"
}

# Binds to an object's name, if it has a name attribute
#
# [ngs-is-named object_id name]
#
# Goals and operators are the standard NGS named objects
# NGS names are not required to be unique, and are typically designed
#  to be descriptive enough to help identify an object during debugging
#
proc ngs-is-named { object_id name } {
  return "($object_id ^name $name)"
}

# Evaluates to true if the given object does not have the given name
# 
# [ngs-is-not-named object_id typename]
#
proc ngs-is-not-named { object_id name } {
  return "($object_id -^name $name)"
}


# Binds to a given tag, if the tag exists.
#
# A list of the NGS built-in tags can be found in ngs-variables.tcl
#
# [ngs-is-tagged object_id tag_name *tag_val]
#
# If tag_val is not provided, it is defaulted to NGS_YES
#
# Tags are prefixed by a special string, so you cannot
proc ngs-is-tagged { object_id tag_name {tag_val "" } } {
  CORE_RefMacroVars
  CORE_SetIfEmpty tag_val $NGS_YES
  return "($object_id  ^[ngs-tag-for-name $tag_name] $tag_val)"
}

# Evaluates to true if the given object does not have the given tag
#
# A list of the NGS built-in tags can be found in ngs-variables.tcl
# 
# [ngs-is-not-tagged object_id typename]
#
proc ngs-is-not-tagged { object_id tag_name {tag_val "" } } {
  CORE_RefMacroVars
  CORE_SetIfEmpty tag_val $NGS_YES
  return "-($object_id ^[ngs-tag-for-name $tag_name] $tag_val)"
}

########################################################
## Goal states (normally don't need to test this way, but sometimes need to)
########################################################

# Evaluates to true if the given goal is active
#
# An Active goal is one that is bound to a selected decide operator
#  (i.e. that has no-changed to a sub-state) or one of its supergoals.
#
# This macro tests the goal's tags to see if it is active.
# Use some other macro to bind to the goal itself.
#
# Typically you will bind to active goals using ngs-match-active-goal
#  or ngs-match-top-state-active-goal.
#
# [ngs-is-active <goal>]
#
proc ngs-is-active { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-tagged $goal_id $NGS_GS_ACTIVE]"
}

# Evaluates to true if the given goal is NOT active
#
# An Active goal is one that is bound to a selected decide operator
#  (i.e. that has no-changed to a sub-state) or one of its supergoals.
#
# This macro tests the goal's tags to see if it is not active.
# You cannot use this macro to bind to the goal or to the active tag.
#
# [ngs-is-not-active goal_id]
#
proc ngs-is-not-active { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-not-tagged $goal_id $NGS_GS_ACTIVE]"
}


# Evaluates to true if the given goal is tagged NGS_GS_ACHIEVED
#
# O-supported goals are marked achieved using ngs-tag-goal-achieved (typically)
#  under domain-specific conditions for the given model)
#
# This macro tests the goas's tags and cannot be used to bind to the
#  goal itself. 
#
# Note that this macro will only ever evaluate to true for o-supported goals.
# I-supported goals are retracted when achieved.
#
# [ngs-is-achieved goal_id]
#
proc ngs-is-achieved { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-tagged $goal_id $NGS_GS_ACHIEVED]"
}

# Evaluates to true if the given goal is not tagged NGS_GS_ACHIEVED
#
# O-supported goals are marked achieved using ngs-tag-goal-achieved (typically)
#  under domain-specific conditions for the given model)
#
# This macro tests the goas's tags and cannot be used to bind to the
#  goal itself. 
#
# [ngs-is-achieved goal_id]
#
proc ngs-is-not-achieved { goal_id } {
  CORE_RefMacroVars
  return "[ngs-is-not-tagged $goal_id $NGS_GS_ACHIEVED]"
}

# Evaluates to true if the object linked to the given attribute
#  has been completely constructed (i.e. is tagged with NGS_TAG_CONSTRUCTED)
#
# IMPORTANT: You should ALWAYS use this macro instead of just testing for the
#  existance of the given attribute wme whenever you working with objects that
#  have structure (i.e. non-primitives). Otherwise your production is likely
#  to fire prematurely while the object is still being constructed.
#
# See also - ngs-is-obj-constructed for version where attribute already exists
#
# Upon matching, the "object_id" will be bound to the constructed object and can
#  be used elsewhere within the production.
#
# [ngs-is-attr-constructed parent_id attribute object_id]
#
proc ngs-is-attr-constructed { parent_id attribute object_id } {
  CORE_RefMacroVars
  return "($parent_id ^$attribute $object_id)
          [ngs-is-tagged $object_id $NGS_TAG_CONSTRUCTED]"
}

# Evaluates to true if the object linked to the given attribute
#  has NOT yet been completely constructed (i.e. is tagged with NGS_TAG_CONSTRUCTED)
#
# IMPORTANT: You should ALWAYS use this macro instead of just testing for the
#  existance of the given attribute wme whenever you working with objects that
#  have structure (i.e. non-primitives). Otherwise your production is likely
#  to fire prematurely while the object is still being constructed.
#
# See also - ngs-is-obj-not-constructed for version where attribute already exists
#
# The object_id parameter may be bound to the object even before the entire condition
#  is matched, thus it could be used for other tests in the production.
#
# [ngs-is-attr-not-constructed parent_id attribute object_id]
#
proc ngs-is-attr-not-constructed { parent_id attribute {object_id ""} } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty object_id "__new-obj"
  return "-{ [ngs-is-attr-constructed $parent_id $attribute $object_id] }"
}

# Evaluates to true if the object has been completely constructed 
#  (i.e. is tagged with NGS_TAG_CONSTRUCTED)
#
# IMPORTANT: You should ALWAYS use this macro instead of just testing for the
#  existance of the given attribute wme whenever you working with objects that
#  have structure (i.e. non-primitives). Otherwise your production is likely
#  to fire prematurely while the object is still being constructed.
#
# See also - ngs-is-attr-constructed for version when the attribute linking
#   the object to its parent may not exist.
#
# This version does not bind the object being tested. Use some other method
#  or macro to bind the object before testing it.
#
# [ngs-is-obj-constructed object_id]
#
proc ngs-is-obj-constructed { object_id } {
  CORE_RefMacroVars
  return "[ngs-is-tagged $object_id $NGS_TAG_CONSTRUCTED]"
}

# Evaluates to true if the object l has NOT yet been completely constructed 
#  (i.e. is tagged with NGS_TAG_CONSTRUCTED)
#
# IMPORTANT: You should ALWAYS use this macro instead of just testing for the
#  existance of the given attribute wme whenever you working with objects that
#  have structure (i.e. non-primitives). Otherwise your production is likely
#  to fire prematurely while the object is still being constructed.
#
# See also - ngs-is-attr-constructed for version when the attribute linking
#   the object to its parent may not exist.
#
# This version does not bind the object being tested. Use some other method
#  or macro to bind the object before testing it.
#
# [ngs-is-obj-not-constructed object_id]
#
proc ngs-is-obj-not-constructed { object_id } {
  return "-{ [ngs-is-obj-constructed $object_id] }"
}

proc ngs-is-return-val { ret_val_set_id ret_val_name {ret_value ""} { ret_val_desc_id "" } } {
  
    CORE_RefMacroVars
    CORE_GenVarIfEmpty ret_val_desc_id "val-desc"

    set lhs_val "($ret_val_set_id  ^value-description $ret_val_desc_id)
                 ($ret_val_desc_id ^name $ret_val_name)
                 [ngs-is-tagged $ret_val_desc_id $NGS_TAG_CONSTRUCTED]"

    if { $ret_value != "" } {
        set lhs_val "$lhs_val
                     ($ret_val_desc_id ^value $ret_value)"
    }

    return $lhs_val
}

proc ngs-is-not-return-val { ret_val_set_id ret_val_name {ret_value ""} { ret_val_desc_id "" } } {
    return "-{ [ngs-is-return-val $ret_val_set_id $ret_val_name $ret_value $ret_val_desc_id] }"
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
                      {type ""}
                      {goal_pool_id ""}} {
  CORE_RefMacroVars

  # Default value initialization
  CORE_GenVarIfEmpty goal_pool_id "goal-pool"

  set lhs_ret "[ngs-match-goalpool $state_id $goal_pool_id $goal_name]
               ($goal_pool_id ^goal $goal_id)
               [ngs-is-tagged $goal_id $NGS_TAG_CONSTRUCTED]"

  if { $type != "" } {
    set lhs_ret "$lhs_ret
                 ($goal_id ^type $type)"
  }

  return $lhs_ret
}

proc ngs-match-top-state { state_id } {
    return "(state <s> ^superstate nil)"
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
                             goal_id
                             {top_state_id ""}
                             {superstate_id ""} } {
  CORE_RefMacroVars

  set lhs_ret "[ngs-match-substate $substate_id $top_state_id $superstate_id]
               ($substate_id ^$WM_ACTIVE_GOAL $goal_id)
               [ngs-is-named $goal_id $goal_name]"

  return $lhs_ret
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
proc ngs-match-to-set-return-value { substate_id
                                     goal_name 
                                     goal_id
                                     return_value_name
                                     {return_value_desc_id ""} 
                                     {top_state_id ""}
                                     {superstate_id ""} } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty return_value_desc_id "val-desc"

  set lhs_ret "[ngs-match-active-goal $substate_id $goal_name $goal_id $top_state_id $superstate_id]
               ($substate_id ^$NGS_RETURN_VALUES.value-description $return_value_desc_id)
               ($return_value_desc_id    ^name  $return_value_name)
               [ngs-is-attr-not-constructed $return_value_desc_id value]"

  return $lhs_ret
}

# Use when you need to match a state so you can create a goal as a return value
#
proc ngs-match-to-create-return-goal { substate_id
                                       goal_name 
                                       goal_id
                                       new_goal_type
                                       {top_state_id ""}
                                       {superstate_id ""} } {
  CORE_RefMacroVars
  set return_value_set [CORE_GenVarName "ret-vals"]
  set new_goal_id      [CORE_GenVarName "new-goal"]

  set lhs_ret "[ngs-match-active-goal $substate_id $goal_name $goal_id $top_state_id $superstate_id]
               ($substate_id ^$NGS_RETURN_VALUES $return_value_set)
              -{
                  [ngs-is-return-val $return_value_set $NGS_GOAL_RETURN_VALUE $new_goal_id]
                  [ngs-is-named $new_goal_id $new_goal_type]
               }"

  return $lhs_ret
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
                             	       goal_id } {
  CORE_RefMacroVars

  set lhs_ret = "(state $state_id ^$WM_GOAL_SET.$goal_name $goal_id)
                 [ngs-is-active $goal_id]"

  return $lhs_ret
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
								   op_id
                                   {op_name ""}
                				   {goal_id ""}
                 				   {op_type ""} } {

  set lhs_ret "(state $state_id ^operator $op_id +)"

   if { $op_name != "" } {
     set lhs_ret "$lhs_ret
            	  ($op_id ^name $op_name)"
	} 

  if { $goal_id != ""} { 
	set lhs_ret "$lhs_ret
           		($op_id ^goal $goal_id)" 
  }

  if { $op_type != ""} { 
	set lhs_ret "$lhs_ret
                 ($op_id ^type $op_type)"
  }

  return $lhs_ret
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
                                        op1_id 
                                        op2_id
                                        {op1_name ""}
                                        {op2_name ""} 
                                        {goal1_id ""}
                                        {goal2_id ""}
                                        {op1_type ""}
                                        {op2_type ""} } {


   set lhs_ret "(state $state_id ^operator $op1_id +
							     ^operator $op2_id +)"


   if { $op1_name != "" } {
     set lhs_ret "$lhs_ret
            	  ($op1_id ^name $op1_name)"
	} 
   if { $op2_name != "" } {
     set lhs_ret "$lhs_ret
            	  ($op2_id ^name $op2_name)"
	} 

  if { $goal1_id != "" } { 
	set lhs_ret "$lhs_ret
           		($op1_id ^goal $goal1_id)" 
  }
  if { $goal2_id != "" } { 
	set lhs_ret "$lhs_ret
           		($op2_id ^goal $goal2_id)" 
  }

  if { $op1_type != "" } {
	set lhs_ret "$lhs_ret
                 ($op1_id ^type $op1_type)"
  }
  if { $op2_type != "" } { 
	set lhs_ret "$lhs_ret
                 ($op2_id ^type $op2_type)"
  }

  return $lhs_ret
}

# Use start a production to apply an operator
#
# e.g. sp "my-production
#         [ngs-operator-application MyOperator <o> <og> <og-tags> <s>]
#
proc ngs-match-selected-operator {state_id
                                  op_id
								  op_name 
                                  {goal_id ""} } {

  set lhs_ret "(state $state_id ^operator $op_id)
               ($op_id          ^name     $op_name)"

  if { $goal_id != "" } {

    set lhs_ret "$lhs_ret
                 ($op_id        ^goal     $goal_id)"

  }

  return $lhs_ret  
}


# Use start a production to apply an operator
#
# e.g. sp "my-production
#         [ngs-operator-application MyOperator <o> <og> <og-tags> <s>]
#
proc ngs-match-selected-operator-on-top-state {state_id
                                               op_id
											   op_name
                                               {goal_id ""} } {
 
  return "[ngs-match-selected-operator $state_id $op_id $op_name $goal_id]
          ($state_id ^superstate nil)"
}

# Use start a production to apply an operator
#
# e.g. sp "my-production
#         [ngs-operator-application MyOperator <o> <og> <og-tags> <s>]
#
proc ngs-match-selected-operator-in-substate {substate_id                                               
                                              op_id
											  op_name
                                              {goal_id ""} 
                                              {top_state_id ""}
                                              {superstate_id ""} } {

  CORE_GenVarIfEmpty top_state_id "top-state"
  CORE_GenVarIfEmpty superstate_id "superstate"
  
  return "[ngs-match-substate $substate_id $top_state_id $superstate_id]
          [ngs-match-selected-operator $substate_id $op_id $op_name $goal_id]"
  
}
