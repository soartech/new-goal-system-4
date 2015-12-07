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

# Evaluates to true if a decision has been made on this goal
#
# [ngs-has-decided goal_id (decision_value)]
#
# goal_id - variable bound to the goal identifer to check for a decision
# decision_value - (Optional) can be a variable or constant (NGS_YES/NGS_NO)
#      that binds to the value of the decision. NGS_YES means that this
#      goal _was_ selected to make the decision while NGS_NO means that the
#      goal was not selected to make the decision. Note that if this is not
#      provided, this macro will match either a YES or NO decision.
# 
proc ngs-has-decided { goal_id { decision_value "" } } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty decision_value "__decision-value"
  return "[ngs-is-tagged $goal_id $NGS_DECIDED_TAG $decision_value]"
}

# Evaluates to true if a decision has NOT been made on this goal
#
# [ngs-has-not-decided goal_id (decision_value)]
#
# goal_id - variable bound to the goal identifer to check for a decision
# decision_value - (Optional) can be a variable or constant (NGS_YES/NGS_NO)
#      that binds to the value of the decision. NGS_YES means that this
#      goal _was_ selected to make the decision while NGS_NO means that the
#      goal was not selected to make the decision. Note that if this is not
#      provided, this macro will match either a YES or NO decision.
# 
proc ngs-has-not-decided { goal_id { decision_value "" } } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty decision_value "__decision-value"
  return "[ngs-is-not-tagged $goal_id $NGS_DECIDED_TAG $decision_value]"
}

# Evaluates to true if the given goal has been assigned a given decision
#
# [ngs-is-assigned-decision goal_id decision_name]
#
# goal_id - goal to test for whether it has been assigned a decision
# decision_name - name of the decision to test foreach 
#
proc ngs-is-assigned-decision { goal_id decision_name } {
  CORE_RefMacroVars
  return "($goal_id ^$NGS_DECIDES_ATTR $decision_name)"
}

# Evaluates to true and binds to the decision information if the given
#  goal has requested a decision of the gien name
#
# The typical use for this macro is to create and act for goals that
#  make decisions. You would use this macro to determine whether a goal's
#  supergoal has requested a decision to be made. If necessary, you can
#  bind to the information about the decision to be made and get the
#  decision's object and attribute.
#
# [ngs-requested-decision goal_id decision_name (decision_obj) (decision_attr) (decision_info_id)]
#
# goal_id - variable bound to the goal for which to check for a requested decision
# decision_name - name of the decision to check for being requested
# decision_obj - (Optional) a variable to bind to the decision object (object that
#                  recieves the result of the decision)
# decision_attr - (Optional) a variable to bind to the decision attribute (attribute
#                  that recieves the result of the decision)
# decision_info_id - (Optional) a variable that is bound to the decision information object.
#                   Typically only ngs code needs to do this.
# 
proc ngs-requested-decision { goal_id 
                              decision_name 
                              { decision_obj ""  }
                              { decision_attr "" }
                              { replacement_behavior "" }
                              { decision_info_id ""} } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty decision_info_id "decision-info"

  set lhs_ret "($goal_id ^$NGS_DECISION_ATTR $decision_info_id)
               ($decision_info_id ^name $decision_name)"

  if { $decision_obj != "" } {
    set lhs_ret "$lhs_ret
                 ($decision_info_id ^destination-object $decision_obj)"
  }

  if { $decision_attr != "" } {
    set lhs_ret "$lhs_ret
                 ($decision_info_id ^destination-attribute $decision_attr)"
  }

  if { $replacement_behavior != "" } {
    set lhs_ret "$lhs_ret
                 ($decision_info_id ^replacement-behavior $replacement_behavior)"
  }

  return $lhs_ret
}

# Evaluates to true if the given choice is valid for the given sub-state
#
# Use this macro to bind to the choices in a decision substate for making
#  goal-based choices.
#
# [ngs-is-decision-chioce state_id choice_id (choice_name)]
#
# state_id - variable bound to a substate within which to check for a choice
# choice_id - variable bound (or to be bound) to the choice. Choices are
#              goal objects, each of which represents a choice.
# choice_name - (Optional) name of the choice to which to bind. This is
#                the goal name. If not provided, this will match any
#                choice.
#
proc ngs-is-decision-choice { state_id choice_id { choice_name ""} } {
  if { $choice_name == ""} {
    return "($state_id ^decision-choice $choice_id)"
  } else {
    return "($state_id ^decision-choice $choice_id)
            [ngs-is-named $choice_id $choice_name]"
  }
}

# Evaluates to true if the given choice is NOT valid for the given sub-state
#
# state_id - variable bound to a substate within which to check for a choice
# choice_id - variable bound to the choice. Choices are
#              goal objects, each of which represents a choice.
# choice_name - (Optional) name of the choice to check for. This is
#                the goal name. If not provided, this will match any
#                choice.
#
proc ngs-is-not-decision-choice { state_id choice_id { choice_name ""} } {
  if { $choice_name == ""} {
    return "($state_id -^decision-choice $choice_id)"
  } else {
    return "-{
              ($state_id ^decision-choice $choice_id)
              [ngs-is-named $choice_id $choice_name]
             }"
  }
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

# Binds to a specified return value, using the name of the return value as 
#  the principle match condition.
#
# It is not usually necessary to use this macro. It is used internally by ngs-match-to-set-return-typed-obj
#  which is the macro you will typically need to use when dealing with return values.
#
# This macro is most useful in a sub-state when you wish to test for the existance of
#  and/or bind to a return value. Return values are stored in NGS_TYPE_STATE_RETURN_VALUE objects.
#  This macro abstracts you from the details of this internal structure and allows you to
#  bind directly to the return value. If you like, you can also bind to the NGS_TYPE_STATE_RETURN_VALUE
#  wrapper object.
#
# [ngs-is-return-val ret_val_set_id ret_val_name *ret_value_id *ret_val_desc_id]
#
# ret_val_set_id: The identifier bound to the return value set on the sub-state (or operator). Typically
#  you would bind this using some other methods (e.g. (<s> ^$NGS_RETURN_VALUES <ret-vals>)). 
# ret_val_name: The name of the return value (a string)
# ret_value_id: (Optional) Identifier for the return value. This will bound to the return value object
#  if this macro matches.  This identifer can be used to modify or even remove the return value.
# ret_val_desc_id: (Optional) Identifier for the NGS_TYPE_STATE_RETURN_VALUE object that describes
#  the return value (you will rarely need to bind to this)
#
proc ngs-is-return-val { ret_val_set_id ret_val_name {ret_value_id ""} { ret_val_desc_id "" } } {
  
    CORE_RefMacroVars
    CORE_GenVarIfEmpty ret_val_desc_id "val-desc"

    set lhs_val "($ret_val_set_id  ^value-description $ret_val_desc_id)
                 ($ret_val_desc_id ^name $ret_val_name)
                 [ngs-is-tagged $ret_val_desc_id $NGS_TAG_CONSTRUCTED]"

    if { $ret_value_id != "" } {
        set lhs_val "$lhs_val
                     ($ret_val_desc_id ^value $ret_value_id)"
    }

    return $lhs_val
}

########################################################
##
########################################################

# Use to bind to a goal's supergoal
#
# This macro does not bind the subgoal. Use a different macro
#  (e.g. ngs-match-active-goal) to bind the subgoal.
# 
# [ngs-is-supergoal goal_id supergoal_id *supergoal_name]
#
# goal_id: Subgoal (already bound)
# supergoal_id: Supergoal of "goal_id." Will be bound by this macro
# supergoal_name: (Optional) If provided, the supergoal will only be bound
#                   if it has the given name.
#
proc ngs-is-supergoal { goal_id supergoal_id {supergoal_name ""} } {

  set main_test_line "($goal_id ^supergoal $supergoal_id)"
  if { $supergoal_name != "" } {
	   return "$main_test_line 
            [ngs-is-named $supergoal_id $supergoal_name]"
  } else {
      return $main_test_line
  }

}

# Use to bind to a goal's subgoal
#
# This macro does not bind the supegoal. Use a different macro
#  (e.g. ngs-match-active-goal) to bind the supergoal.
# 
# [ngs-is-subgoal goal_id subgoal_id *subgoal_name]
#
# goal_id: Supergoal (already bound)
# subgoal_id: Subgoal of "goal_id." Will be bound by this macro
# subgoal_name: (Optional) If provided, the subgoal will only be bound
#                   if it has the given name.
#
proc ngs-is-subgoal { goal_id subgoal_id {subgoal_name ""} } {
  set main_test_line "($goal_id ^subgoal $subgoal_id)"
  if { $subgoal_name != "" } {
    return "$main_test_line 
            [ngs-is-named $subgoal_id $subgoal_name]"
  } else {
    return $main_test_line
  }
}

#######################################################################################

#
# Basic match of the top state
#
proc ngs-match-top-state { state_id } {
    return "(state $state_id ^superstate nil)"
}

# Use to start a production to create a new goal
# (binds to the NGS desired goals section
#
# If the goal_name is given, it binds to the id for the goal pool associated
#  with goals of that name. otherwise it binds one level higher at the master pool
#
# e.g. sp "my-production
#         [ngs-match-goalpool <s> <goals> MyFavorouriteGoalType]
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
# [ngs-match-goal state_id goal_name goal_id (type) (goal_pool_id)]
#
# @devnote There's a slight danger of conflict here in using the hardcoded "<s>" as the state's ID - 
#          but <s> is such a convention in the soar community that it's unlikely to be 
#          anything else.
#
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
                 [ngs-is-type $goal_id $type]"
  }

  return $lhs_ret
}

# Start a production that acts after a goal is selected in a decision
#
# This will always match on the top state. In sub-state you can use
#
# [ngs-match-decided-goal state_id goal_name goal_id  decision_obj decision_attr (replacement_behavior) (decision_name) (type) (goal_pool_id)]
#
proc ngs-match-decided-goal { state_id
                              goal_name
                              goal_id
                              decision_obj
                              decision_attr
                              { replacement_behavior "" }
                              { decision_name "" }
                              { type "" } 
                              { goal_pool_id "" }} {
  
  CORE_RefMacroVars

  set supergoal_id [CORE_GenVarName "supergoal"]
  CORE_GenVarIfEmpty decision_name "decision-name"

  return "[ngs-match-goal $state_id $goal_name $goal_id $type $goal_pool_id]
          [ngs-has-decided $goal_id $NGS_YES]
          [ngs-is-assigned-decision $goal_id $decision_name]
          [ngs-is-supergoal $goal_id $supergoal_id]
          [ngs-requested-decision $supergoal_id $decision_name $decision_obj $decision_attr $replacement_behavior]"
}

# Start a production to create a subgoal of another goal
# 
# [ngs-match-goal-to-create-subgoal state_id supergoal_name supergoal_id subgoal_name subgoal_pool_id (supergoal_type)]
#
proc ngs-match-goal-to-create-subgoal { state_id 
                                        supergoal_name 
                                        supergoal_id 
                                        subgoal_name
                                        subgoal_pool_id 
                                        { supergoal_type "" } } {

  CORE_RefMacroVars

  set goal_pool_id      [CORE_GenVarName "goals"]
  set supergoal_pool_id [CORE_GenVarName "supergoals"]

  set lhs_ret "(state $state_id ^superstate nil
                                ^$WM_GOAL_SET    $goal_pool_id)
               ($goal_pool_id   ^$supergoal_name $supergoal_pool_id
                                ^$subgoal_name   $subgoal_pool_id)
               ($supergoal_pool_id ^goal         $supergoal_id)
               [ngs-is-tagged $supergoal_id      $NGS_TAG_CONSTRUCTED]"

  if { $supergoal_type != "" } {
    set lhs_ret "$lhs_ret
                 [ngs-is-type $supergoal_id $supergoal_type]"
  }

  echo $lhs_ret

  return $lhs_ret

}



# Create a condition that matches and binds within a substate.
#
# Optional paramaters let you bind to the top state and superstate respectively
#
# e.g. sp "my-production
#          [ngs-match-substate <ss> <top-state> <super-state>]
#
proc ngs-match-substate { substate_id {params_id ""} {top_state_id ""} {superstate_id ""}} {

  CORE_RefMacroVars

  variable superstate_test
  variable top_state_test
  variable params_test

  CORE_GenVarIfEmpty superstate_id "superstate"
  
  set superstate_test "^$WM_SUPERSTATE \{ $superstate_id <> nil \}"
  
  if {$top_state_id != ""} {
     set top_state_test "\n^$WM_TOP_STATE $top_state_id"
  } else {
     set top_state_test ""
  }

  if {$params_id != ""} {
     set params_test "\n^$NGS_SUBSTATE_PARAMS $params_id"
  } else {
     set params_test ""
  }

  return "(state $substate_id $superstate_test $top_state_test $params_test)"
}

# Start a production to bind to an active goal with a given most derived type
#
# Active goals have been selected for processing in a sub-state. This macro
#  binds to the sub-state and tests the WM_ACTIVE_GOAL attribute in the 
#  substate. If you want to bind through the top-state goal pool use
#  ngs-match-top-state-active-goal instead.
#
# [ngs-match-active-goal substate_id goal_name goal_id params_id top_state_id superstate_id]
#
# e.g. sp "my-production
#          [ngs-match-active-goal myGoalName <my-goal> <ss>]
#          -->
#          ...do something...
proc ngs-match-active-goal { substate_id
                             goal_name 
                             goal_id
                             {params_id ""}
                             {top_state_id ""}
                             {superstate_id ""} } {
  CORE_RefMacroVars

  set lhs_ret "[ngs-match-substate $substate_id $params_id $top_state_id $superstate_id]
               ($substate_id ^$WM_ACTIVE_GOAL $goal_id)
               [ngs-is-named $goal_id $goal_name]"

  return $lhs_ret
}

# Start a production that will propose an operator to make a decision
#  in a decision sub-state
#
# Typically you pair this match macro with the ngs-make-choice-by-operator RHS macro
#
# [ngs-match-to-make-choice substate_id decision_name decision_goal_id decision_goal_name (params_id) (top_state_id) (superstate_id)]
#
# substate_id - variable bound to the substate in which to make the choice
# decision_name - name of the decision being made
# decision_goal_id - variable to be bound to the id of the goal for which the decision is being made
# decision_goal_name - name of the goal for which the decision is being made
# params_id - (Optional) If provided, a variable that will be bound to the params structure in the substate
# top_state_id - (Optional) If provided, a variable that will be bound to the top state identifier
# superstate_id - (Optional) If provided, a variable that will be bound to the superstate identifier
#
proc ngs-match-to-make-choice { substate_id 
                                decision_name 
                                decision_goal_id
                                decision_goal_name
                                {params_id ""} 
                                {top_state_id ""} 
                                {superstate_id ""} } {

  CORE_RefMacroVars
  CORE_GenVarIfEmpty params_id "params"

  set return_value_desc_id [CORE_GenVarName "ret-vals"]

  return "[ngs-match-active-goal $substate_id $decision_goal_name $decision_goal_id $params_id $top_state_id $superstate_id]
          [ngs-is-named $substate_id $NGS_OP_DECIDE_GOAL]
          ($params_id ^decision-name $decision_name)
          ($substate_id ^$NGS_RETURN_VALUES.value-description $return_value_desc_id)
          ($return_value_desc_id    ^name  $NGS_DECISION_RET_VAL_NAME
                                   -^destination-object)"

}

# Start a production to set a return value to a typed object
#
# [ngs-match-to-set-return-typed-obj substate_id goal_name goal_id return_value_name (return_value_desc_id) (params_id) (top_state_id) (superstate_id)]
#
# e.g. sp "my-production
#          [ngs-match-active-goal myGoalName <my-goal> <ss>]
#          -->
#          ...do something...
proc ngs-match-to-set-return-typed-obj { substate_id
                                     goal_name 
                                     goal_id
                                     return_value_name
                                     {return_value_desc_id ""} 
                                     {params_id ""}
                                     {top_state_id ""}
                                     {superstate_id ""} } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty return_value_desc_id "val-desc"

  set lhs_ret "[ngs-match-active-goal $substate_id $goal_name $goal_id $params_id $top_state_id $superstate_id]
               ($substate_id ^$NGS_RETURN_VALUES.value-description $return_value_desc_id)
               ($return_value_desc_id    ^name  $return_value_name)
               [ngs-is-attr-not-constructed $return_value_desc_id value]"

  return $lhs_ret
}

# Start a production that will set a return value as a primitive
#
# This also works to set return values that are boolean tags
#
# [ngs-match-to-set-return-primitive substate_id goal_name goal_id return_value_name (return_value_desc_id) (params_id) (top_state_id) (superstate_id)]
#
# e.g. sp "my-production
#          [ngs-match-active-goal myGoalName <my-goal> <ss>]
#          -->
#          ...do something...
proc ngs-match-to-set-return-primitive { substate_id
                                         goal_name 
                                         goal_id
                                         return_value_name
                                         {return_value_desc_id ""} 
                                         {params_id ""}
                                         {top_state_id ""}
                                         {superstate_id ""} } {
  CORE_RefMacroVars
  CORE_GenVarIfEmpty return_value_desc_id "val-desc"

  set lhs_ret "[ngs-match-active-goal $substate_id $goal_name $goal_id $params_id $top_state_id $superstate_id]
               ($substate_id ^$NGS_RETURN_VALUES.value-description $return_value_desc_id)
               ($return_value_desc_id    ^name  $return_value_name
                                        -^value)"

  return $lhs_ret
}

# Use when you need to match a state so you can create a goal as a return value
#
proc ngs-match-to-create-return-goal { substate_id
                                       goal_name 
                                       goal_id
                                       new_goal_type
                                       {params_id ""}
                                       {top_state_id ""}
                                       {superstate_id ""} } {
  CORE_RefMacroVars
  set return_value_set [CORE_GenVarName "ret-vals"]
  set new_goal_id      [CORE_GenVarName "new-goal"]

  set lhs_ret "[ngs-match-active-goal $substate_id $goal_name $goal_id $params_id $top_state_id $superstate_id]
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
# [ngs-match-selected-operator state_id op_id op_name (goal_id)]
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
