#
# This file provides macro(s) for declaring goals. You must
#  declare a goal before trying to create and test for them, otherwise
#  there will be no goal pool for that goal name.
#
# Usage: at file scope
#  NGS_DeclareGoal MyGoalName1
#  NGS_DeclareGoal MygoalName2 { attr1 foo attr2 $NGS_YES attr3 { 1 2 3} }
# ...

# Declares a goal with a given name, setting up productions to
#  create a goal pool for that goal name and creates other maintenance
#  productions which manage the O-supported goal lifetimes
#
# attribute_list - (Optional) List of attribute, value pairs for the given object. If attributes is a set
#                  (i.e. a multi-valued attribute), put the set values in a list.
#
proc NGS_DeclareGoal { goal_name {attribute_list ""} } {

  CORE_RefMacroVars

  NGS_DeclareType $goal_name $attribute_list

  # Creates a bin to store goals of the given type
  sp "ngs*core*goals*elaborate-goal-set-category*$goal_name
    [ngs-match-goalpool <s> <goals>]
  -->
    (<goals> ^$goal_name <g>)"
  
  # Adds the sub-goal attribute to a supergoal
  sp "ngs*core*goals*link-subgoal*$goal_name
	[ngs-match-goal <s> $goal_name <g>]
 	[ngs-is-supergoal <g> <supergoal>]
  -->
	(<supergoal> ^subgoal <g>)"

  # Remove a goal from the pool, if its supergoal disappears
  # The -^name check is a check for existance
  sp "ngs*core*goals*mark-goal-achieved-if-supergoal-removed-by-i-support*$goal_name
    [ngs-match-goal <s> $goal_name <g> $NGS_GB_ACHIEVE]
    [ngs-is-supergoal <g> <supergoal>]
   -(<supergoal> ^name <supergoal-name>)
  -->
    [ngs-tag <g> $NGS_GS_ACHIEVED]"

  # Remove a goal from the pool, if its supergoal disappears
  # The -^name check is a check for existance
  sp "ngs*core*goals*mark-goal-achieved-if-supergoal-removed-by-o-support*$goal_name
    [ngs-match-goal <s> $goal_name <g> $NGS_GB_ACHIEVE]
    [ngs-is-supergoal <g> <supergoal> <supergoal-name>]
   -{
       [ngs-match-goal <s> <supergoal-name> <supergoal>]
    }
  -->
    [ngs-tag <g> $NGS_GS_ACHIEVED]"

  # Remove a goal from the pool, if its supergoal disappears
  # The -^name check is a check for existance
  sp "ngs*core*goals*mark-goal-achieved-if-supergoal-achieved*$goal_name
    [ngs-match-goal <s> $goal_name <g> $NGS_GB_ACHIEVE]
    [ngs-is-supergoal <g> <supergoal>]
    [ngs-is-tagged <supergoal> $NGS_GS_ACHIEVED]
  -->
    [ngs-tag <g> $NGS_GS_ACHIEVED]"


  # Mark a goal active if its subgoal is active
  sp "ngs*core*goals*mark-goal-active-if-subgoal-active*$goal_name
    [ngs-match-goal <s> $goal_name <g>]
    [ngs-is-supergoal <g> <supergoal>]
    [ngs-is-active <g>]
  -->
    [ngs-tag <supergoal> $NGS_GS_ACTIVE]" 

  # Proposes to remove a goal that is achieved. This only will fire
  #  if the goal is o-supported.
  sp "ngs*core*goals*propose-to-remove-achieved-goals*$goal_name
    [ngs-match-goal <s> $goal_name <g> $NGS_GB_ACHIEVE <goals>]
    [ngs-is-tagged <g> $NGS_GS_ACHIEVED]
    [ngs-is-not-tagged <g> $NGS_TAG_I_SUPPORTED]
  -->
    [ngs-create-atomic-operator <s> $NGS_OP_REMOVE_ACHIEVED <o>]
    (<o> ^goal-set <goals> ^goal <g>)"

  #############################################################
  ## Productions that support goal-based decision making

  # i-supported production to mark a decision on this goal as being required
  sp "ngs*core*goal*elaborate-decision-is-required*$goal_name
    [ngs-match-goal <s> $goal_name <g>]
    [ngs-requested-decision <g> <decision-name> {} {} <decision-info>]
    [ngs-is-subgoal <g> <sub-goal>]
    [ngs-is-assigned-decision <sub-goal> <decision-name>]
    [ngs-has-not-decided <sub-goal>]
  -->
    [ngs-tag <decision-info> $NGS_TAG_REQUIRES_DECISION]"

  # i-supported production to mark a decision as not having any current options
  #  if there is no sub-goal that can make the decision
  sp "ngs*core*goal*elaborate-decision-no-decision-options*$goal_name
    [ngs-match-goal <s> $goal_name <g>]
    [ngs-requested-decision <g> <decision-name> {} {} <decision-info>]
   -{
      [ngs-is-subgoal <g> <sub-goal>]
      [ngs-is-assigned-decision <sub-goal> <decision-name>]
    }
  -->
    [ngs-tag <decision-info> $NGS_TAG_NO_OPTIONS]"

  # i-supported production to mark a decision as having exactly one current
  #  option. These decision are made by default.
  sp "ngs*core*goal*elaborate-decision-one-decision-option*$goal_name
    
    [ngs-match-goal <s> $goal_name <g>]
    [ngs-requested-decision <g> <decision-name> {} {} <decision-info>]
    [ngs-is-tagged <decision-info> $NGS_TAG_REQUIRES_DECISION]
   
    [ngs-is-subgoal <g> <sub-goal>]
    [ngs-is-assigned-decision <sub-goal> <decision-name>]
    [ngs-has-not-decided <sub-goal>]
   
   -{
      [ngs-is-subgoal <g> { <sub-goal2> <> <sub-goal> }]
      [ngs-is-assigned-decision <sub-goal> <decision-name>]
    }
  -->
    [ngs-tag <decision-info> $NGS_TAG_ONE_OPTION]"

  # Operator proposal to make a decision if there is only one option
  sp "ngs*core*goal*propose-to-make-decision-if-only-one*$goal_name
    
    [ngs-match-goal <s> $goal_name <g>]
    [ngs-requested-decision <g> <decision-name> {} {} <decision-info>]
    [ngs-is-tagged <decision-info> $NGS_TAG_REQUIRES_DECISION]
    [ngs-is-tagged <decision-info> $NGS_TAG_ONE_OPTION]

    [ngs-is-subgoal <g> <sub-goal>]
    [ngs-is-assigned-decision <sub-goal> <decision-name>]
  -->
    [ngs-create-tag-by-operator <s> <<g> $NGS_DECIDED_TAG]"

  # Operator proposal to make a decision if there are multiple options
  sp "ngs*core*goal*propose-to-make-decision-if-only-one*$goal_name
    [ngs-match-goal <s> $goal_name <g>]
    [ngs-requested-decision <g> <decision-name> {} {} <decision-info>]
    [ngs-is-tagged <decision-info> $NGS_TAG_REQUIRES_DECISION]
    [ngs-is-tagged <decision-info> $NGS_TAG_ONE_OPTION]
  -->
    [ngs-create-decide-operator <s> $NGS_OP_DECIDE_GOAL <o> <ret-vals> <g>]"
}
