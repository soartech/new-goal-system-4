
#
# This file provides macro(s) for declaring goals. You must
#  declare a goal before trying to create and test for them, otherwise
#  there will be no goal pool for that goal type.
#
# Usage: at file scope
#  NGS_DeclareGoal MyGoalType1
#  NGS_DeclareGoal MygoalType2 { attr1 foo attr2 $NGS_YES attr3 { 1 2 3} }
# ...

# Declare a global list of all goals
#
CORE_CreateMacroVar NGS_ALL_GOAL_TYPES ""

# Declares a goal with a given type, setting up productions to
#  create a goal pool for that goal type and creates other maintenance
#  productions which manage the O-supported goal lifetimes
#
# attribute_list - (Optional) List of attribute, value pairs for the given object. If attributes is a set
#                  (i.e. a multi-valued attribute), put the set values in a list.
#
proc NGS_DeclareGoal { goal_type {attribute_list ""} { batch_op_cat_and_name "" }} {

  variable NGS_YES
  variable NGS_TAG_CONSTRUCTED
  variable NGS_TAG_TYPE_POOL
  variable NGS_GB_ACHIEVE
  variable NGS_GS_ACHIEVED
  variable NGS_GS_ACTIVE
  variable NGS_TAG_I_SUPPORTED
  variable NGS_TAG_REMOVE_ACHIEVED
  variable GOAL_TAG_STACK_SELECTED
  variable GOAL_TAG_STACK_ROOT
  variable NGS_TAG_REQUIRES_DECISION
  variable NGS_TAG_NO_OPTIONS
  variable NGS_TAG_ONE_OPTION
  variable NGS_TAG_DECISION_STATUS
  variable NGS_OP_DECIDE_GOAL
  variable NGS_TAG_ACTIVATE_ON_DECISION
  variable NGS_TAG_ALREADY_ACTIVATED
  variable NGS_DECISION_ITEM_RET_VAL_NAME
  variable NGS_ACTIVATION_STATUS_RET_VAL
  variable NGS_TAG_SELECTION_STATUS
  variable NGS_ALL_GOAL_TYPES

  # Add to the global list of goals
  lappend NGS_ALL_GOAL_TYPES $goal_type

  # This is not technically necessary, as NGS_DeclareType already does this and its the only thing referencing attribute_list,
  # but this is just in case we ever use attribute_list elsewhere in this proc in the future.
  set attribute_list [strip_comments $attribute_list]

  NGS_DeclareType $goal_type $attribute_list

  # Creates a bin to store goals of the given type
  sp "ngs*core*goals*elaborate-goal-set-category*$goal_type
    [ngs-match-goalpool <s> <goals>]
  -->
    [ngs-create-typed-object <goals> $goal_type Set <g>]
    [ngs-tag <g> $NGS_TAG_CONSTRUCTED]
    [ngs-tag <g> $NGS_TAG_TYPE_POOL]"
  
  # Adds the sub-goal attribute to a supergoal
  sp "ngs*core*goals*link-subgoal*$goal_type
	[ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
	[ngs-is-supergoal <g> <supergoal>]
  -->
	(<supergoal> ^subgoal <g>)"

  # Remove a goal from the pool, if its supergoal disappears
  # The -^my-type check is a check for existance
  sp "ngs*core*goals*mark-goal-achieved-if-supergoal-removed-by-i-support*$goal_type
    [ngs-match-goal <s> $goal_type <g> $NGS_GB_ACHIEVE]
    [ngs-is-my-type <g> $goal_type]
    [ngs-is-supergoal <g> <supergoal>]
   -(<supergoal> ^my-type <supergoal-type>)
  -->
    [ngs-tag <g> $NGS_GS_ACHIEVED]"

  # Remove a goal from the pool, if its supergoal disappears
  # The -^my-type check is a check for existance
  sp "ngs*core*goals*mark-goal-achieved-if-supergoal-removed-by-o-support*$goal_type
    [ngs-match-goal <s> $goal_type <g> $NGS_GB_ACHIEVE]
    [ngs-is-my-type <g> $goal_type]
    [ngs-is-supergoal <g> <supergoal>]
    [ngs-is-my-type <supergoal> <supergoal-type>]
   -{
       [ngs-match-goal <s> <supergoal-type> <supergoal>]
    }
  -->
    [ngs-tag <g> $NGS_GS_ACHIEVED]"

  # Remove a goal from the pool, if its supergoal disappears
  # The -^my-type check is a check for existance
  sp "ngs*core*goals*mark-goal-achieved-if-supergoal-achieved*$goal_type
    [ngs-match-goal <s> $goal_type <g> $NGS_GB_ACHIEVE]
    [ngs-is-my-type <g> $goal_type]
    [ngs-is-supergoal <g> <supergoal>]
    [ngs-is-tagged <supergoal> $NGS_GS_ACHIEVED]
  -->
    [ngs-tag <g> $NGS_GS_ACHIEVED]"


  # Mark a goal active if its subgoal is active
  sp "ngs*core*goals*mark-goal-active-if-subgoal-active*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-is-supergoal <g> <supergoal>]
    [ngs-is-active <g>]
  -->
    [ngs-tag <supergoal> $NGS_GS_ACTIVE]" 

  # Proposes to remove a goal that is achieved. This only will fire
  #  if the goal is o-supported.
  sp "ngs*core*goals*propose-to-remove-achieved-goals*$goal_type
    [ngs-match-goal <s> $goal_type <g> $NGS_GB_ACHIEVE <goals>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-is-tagged <g> $NGS_GS_ACHIEVED]
    [ngs-is-not-tagged <g> $NGS_TAG_I_SUPPORTED]
  -->
    [ngs-create-atomic-operator <s> "(concat |remove-achieved-goal--| <g>)" <o>]
    [ngs-tag <o> $NGS_TAG_REMOVE_ACHIEVED]
    (<o> ^goal-set <goals> ^goal <g>)"

  #############################################################
  ## Productions that support alternate goal pooling

  # Pool based on sub-types
  sp "ngs*core*goals*copy-goal-to-supergoal-pool*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-match-goalpool <s> <other-pool> <other-type>]
    [ngs-neq <g> type $goal_type <other-type>]
  -->
    [ngs-create-attribute <other-pool> goal <g>]"

    # Set of productions to pool based on requested decisions

    # Step one, indicate that a pool is needed (allows multiple firings)
    sp "ngs*core*goal*create-tag-need-decision-pool*$goal_type
      [ngs-match-goal <s> $goal_type <g>]
      [ngs-is-my-type <g> $goal_type]
      [ngs-match-goalpool <s> <master-pool>]
      [ngs-has-requested-decision <g> <decision-name>]
    -->
      [ngs-tag <master-pool> need-pool-for-decision <decision-name>]"

    # Step two is separate (below the macro). It creates a decision goal pool
    
    # Step three, copy goals that request the given decision to the pool
    sp "ngs*core*goal*copy-goal-to-decision-pool*$goal_type
      [ngs-match-goal <s> $goal_type <g>]
      [ngs-is-my-type <g> $goal_type]
      [ngs-has-requested-decision <g> <decision-name>]
      [ngs-match-goalpool <s> <decision-pool> <decision-name>]
    -->
      (<decision-pool> ^goal <g>)"

  #############################################################
  ## Productions that support goal-based decision making
  set batch_category ""
  set batch_name ""
  if { $batch_op_cat_and_name != "" } {
    set batch_category [lindex $batch_op_cat_and_name 0]
    set batch_name     [lindex $batch_op_cat_and_name 1]
  }

  # Mark a goal as the root goal of a decision tree
  sp "ngs*core*goal*elaborate*is-root*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-has-requested-decision <g> <any-decision>]
    [ngs-is-not-supergoal <g> <sg>]
  -->
    [ngs-tag <g> $GOAL_TAG_STACK_ROOT]"

  # i-supported production to mark a goal as "goal-stack-selected" meaning that this goal
  #  and all other decision goals above it on the stack are selected.
  # JC: A selected goal stack just means that this goal level doesn't require any decision be made
  #    and its supergoal is stable (or is the root)
  sp "ngs*core*goal*elaborate-goal-stack-selected*root*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-is-tagged <g> $GOAL_TAG_STACK_ROOT]
    [ngs-not [ngs-requires-decision <g> <any-decision>]]       
  -->
    [ngs-tag <g> $GOAL_TAG_STACK_SELECTED]"

  sp "ngs*core*goal*elaborate-goal-stack-selected*parent-is-selected*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-is-tagged  <g> $NGS_TAG_SELECTION_STATUS]
    [ngs-is-supergoal <g> <supergoal>]
    [ngs-is-tagged <supergoal> $GOAL_TAG_STACK_SELECTED]
    [ngs-not [ngs-requires-decision <g> <any-decision>]]       
  -->
    [ngs-tag <g> $GOAL_TAG_STACK_SELECTED]"

  # i-supported production to mark a decision on this goal as being required
  sp "ngs*core*goal*elaborate-decision-is-required*undecided-exists*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-has-requested-decision <g> <decision-name> {} {} {} <decision-info>]
    [ngs-is-subgoal <g> <sub-goal>]
    [ngs-is-assigned-decision <sub-goal> <decision-name>]
    [ngs-has-not-decided <sub-goal>]
  -->
    [ngs-tag <decision-info> $NGS_TAG_REQUIRES_DECISION]"
  
  # Same as above, but looks for lack of a decided *yes*
  sp "ngs*core*goal*elaborate-decision-is-required*yes-does-not-exist*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-has-requested-decision <g> <decision-name> {} {} {} <decision-info>]
   -{
      [ngs-is-subgoal <g> <sub-goal>]
      [ngs-is-assigned-decision <sub-goal> <decision-name>]
      [ngs-has-decided <sub-goal> $NGS_YES]
    }
  -->
    [ngs-tag <decision-info> $NGS_TAG_REQUIRES_DECISION]"

  # Same as above, but looks for multiple decide yess
  sp "ngs*core*goal*elaborate-decision-is-required*more-than-one-yes*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-has-requested-decision <g> <decision-name> {} {} {} <decision-info>]
    [ngs-is-subgoal <g> <subgoal>]
    [ngs-is-assigned-decision <subgoal> <decision-name>]
    [ngs-is-tagged <subgoal> $NGS_TAG_DECISION_STATUS $NGS_YES]
    [ngs-is-subgoal <g> [ngs-this-not-that <subgoal2> <subgoal>]]
    [ngs-is-assigned-decision <subgoal2> <decision-name>]
    [ngs-is-tagged <subgoal2> $NGS_TAG_DECISION_STATUS $NGS_YES]
  -->
    [ngs-tag <decision-info> $NGS_TAG_REQUIRES_DECISION]"
  
  # i-supported production to mark a decision as not having any current options
  #  if there is no sub-goal that can make the decision
  sp "ngs*core*goal*elaborate-decision-no-decision-options*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-has-requested-decision <g> <decision-name> {} {} {} <decision-info>]
   -{
      [ngs-is-subgoal <g> <sub-goal>]
      [ngs-is-assigned-decision <sub-goal> <decision-name>]
    }
  -->
    [ngs-tag <decision-info> $NGS_TAG_NO_OPTIONS]"

  # i-supported production to mark a decision as having exactly one current
  #  option. These decision are made by default.
  sp "ngs*core*goal*elaborate-decision-one-decision-option*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-has-requested-decision <g> <decision-name> {} {} {} <decision-info>]
   
    [ngs-is-subgoal <g> <sub-goal>]
    [ngs-is-assigned-decision <sub-goal> <decision-name>]
   
   -{
      [ngs-is-subgoal <g> [ngs-this-not-that <sub-goal2> <sub-goal>]]
      [ngs-is-assigned-decision <sub-goal2> <decision-name>]
    }
  -->
    [ngs-tag <decision-info> $NGS_TAG_ONE_OPTION]"

  # if we are using batch operators, set up the left and right hand side additions
  if { $batch_op_cat_and_name != "" } {
	set lhs_batch "[ngs-bind-bop <s> <bo> $batch_category $batch_name]"
	set rhs_batch "[ngs-create-attribute-by-batch-operator <bo> <sub-goal> @$NGS_TAG_DECISION_STATUS $NGS_YES]"
  } else {
    set lhs_batch ""
    set rhs_batch "[ngs-create-tag-by-operator <s> <sub-goal> $NGS_TAG_DECISION_STATUS {} {} "< ="]"
  }

  # Operator proposal to make a decision if there is only one option
  sp "ngs*core*goal*propose-to-make-decision-if-only-one*$goal_type
    [ngs-match-goal <s> $goal_type <sub-goal>]
    [ngs-is-my-type <sub-goal> $goal_type]
    $lhs_batch
    [ngs-is-assigned-decision <sub-goal> <decision-name>]
    [ngs-is-supergoal <sub-goal> <supergoal>]
    [ngs-has-requested-decision <supergoal> <decision-name> {} {} {} <decision-info>]
    [ngs-is-tagged <decision-info> $NGS_TAG_REQUIRES_DECISION]
    [ngs-is-tagged <decision-info> $NGS_TAG_ONE_OPTION]
  -->
    $rhs_batch"


  # This marks the goal as selected only if it both has the "pre" selection flag and
  #  it is decided
  sp "ngs*core*goal*elaborate*selection-status*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-is-assigned-decision <g> <any-decision>]
    [ngs-is-tagged <g> $NGS_TAG_DECISION_STATUS <decision-value>]
  -->
    [ngs-tag <g> $NGS_TAG_SELECTION_STATUS <decision-value>]"

  # Operator proposal to make a decision if there are multiple options
  sp "ngs*core*goal*propose-to-create-substate-if-more-than-one-choice*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-has-requested-decision <g> <decision-name> {} {} {} <decision-info>]
    [ngs-is-tagged <decision-info> $NGS_TAG_REQUIRES_DECISION]
    [ngs-is-not-tagged <decision-info> $NGS_TAG_ONE_OPTION]
    [ngs-is-not-tagged <decision-info> $NGS_TAG_NO_OPTIONS]
  --> 
    [ngs-create-function-operator <s> $NGS_OP_DECIDE_GOAL <o> <ret-vals> <g> {} "< ="]
    (<o> ^decision-name <decision-name>)"

  # This can happen when a goal was selected, ends up being unassigned from a decision
  #  and then is reassigned to the decision. The next production should eliminate most
  #  (or all) instances of htis, but I have it here in case. It is the right thing to do
  #  if we have two "decided yes"
  sp "ngs*core*goal*propose-to-create-substate-if-two-decided-yes*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-has-requested-decision <g> <decision-name>]
    [ngs-is-subgoal <g> <subgoal>]
    [ngs-is-assigned-decision <subgoal> <decision-name>]
    [ngs-is-tagged <subgoal> $NGS_TAG_DECISION_STATUS $NGS_YES]
    [ngs-is-subgoal <g> [ngs-this-not-that <subgoal2> <subgoal>]]
    [ngs-is-assigned-decision <subgoal2> <decision-name>]
    [ngs-is-tagged <subgoal2> $NGS_TAG_DECISION_STATUS $NGS_YES]
  -->
    [ngs-create-function-operator <s> $NGS_OP_DECIDE_GOAL <o> <ret-vals> <g> {} "> ="]
    (<o> ^decision-name <decision-name>)
    (write (crlf) | --- WARNING: There are at least two goals with a decided flag set to *yes* - | <subgoal> |, | <subgoal2>)"

# if we are using batch operators, set up the left and right hand side additions
  if { $batch_op_cat_and_name != "" } {
    set lhs_batch "[ngs-bind-bop <s> <bo> $batch_category $batch_name]"
    set rhs_batch "[ngs-remove-attribute-by-batch-operator <bo> <g> @$NGS_TAG_DECISION_STATUS <decision-val>]"
  } else {
    set lhs_batch ""
    set rhs_batch "[ngs-remove-tag-by-operator <s> <g> $NGS_TAG_DECISION_STATUS <decision-val> "> ="]"
  }

  # We give this high priority since we want to set the state to be logically consistent as soon as possible
  sp "ngs*core*goal*propose-to-remove-status-flag*when-not-assigned-decision*$goal_type
    [ngs-match-goal <s> $goal_type <g>]
    [ngs-is-my-type <g> $goal_type]
    $lhs_batch
    [ngs-is-not-assigned-decision <g> <decision-name>]
    [ngs-is-tagged <g> $NGS_TAG_DECISION_STATUS <decision-val>]
  -->
    $rhs_batch"
        
  # Automatically activate a goal after selection if it is flagged for auto-activation
  sp "ngs*core*goal*activate-goal-after-selection*$goal_type
    [ngs-match-selected-goal <s> $goal_type <g> <obj> <attr> <behavior>]
    [ngs-is-my-type <g> $goal_type]
    [ngs-is-tagged <g> $NGS_TAG_ACTIVATE_ON_DECISION]
    [ngs-is-not-tagged <g> $NGS_TAG_ALREADY_ACTIVATED]
  -->
    [ngs-create-function-operator <s> [ngs-create-op-name execute-choice $goal_type <g>] <o> <ret-vals> <g>]
    [ngs-create-ret-val-in-place $NGS_DECISION_ITEM_RET_VAL_NAME <ret-vals> <obj> <attr> {} <behavior>]
    [ngs-create-ret-tag-in-place $NGS_ACTIVATION_STATUS_RET_VAL <ret-vals> <g> $NGS_TAG_ALREADY_ACTIVATED $NGS_YES]"

}


variable NGS_TAG_CONSTRUCTED
variable NGS_TAG_DECISION_POOL

## Additional productions that are not goal-type specific
# Create a goal pool for goals that request decisions
sp "ngs*core*goal*create-decision-based-goal-pool
  [ngs-match-goalpool <s> <master-pool>]
  [ngs-is-tagged <master-pool> need-pool-for-decision <decision-name>]
-->
  (<master-pool> ^<decision-name> <new-pool>)
  [ngs-tag <new-pool> $NGS_TAG_CONSTRUCTED]
  [ngs-tag <new-pool> $NGS_TAG_DECISION_POOL]"


