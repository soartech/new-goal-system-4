#
# This file provides macro(s) for declaring goals. You must
#  declare a goal before trying to create and test for them, otherwise
#  there will be no goal pool for that goal name.
#
# Usage: at file scope
#  NGS_DeclareGoal MyGoalName1
#  NGS_DeclareGoal MygoalName2
# ...

# Declares a goal with a given name, setting up productions to
#  create a goal pool for that goal name and creates other maintenance
#  productions which manage the O-supported goal lifetimes
#
proc NGS_DeclareGoal { goal_name } {

  CORE_RefMacroVars

  # Creates a bin to store goals of the given type
  sp "ngs*core*goals*elaborate-goal-set-category*$goal_name
    [ngs-match-goalpool <goals>]
  -->
    (<goals> ^$goal_name <g>)
  "
    
  # Remove a goal from the pool, if its supergoal disappears
  sp "ngs*core*goals*mark-goal-achieved-if-supergoal-removed*$goal_name
    [ngs-match-goal <s> $goal_name <g> <goals>]
    [ngs-is-supergoal <g> <supergoal>]
    (<supergoal> -^name)
-->
    [ngs-tag <g> $NGS_GS_ACHIEVED]"

  # Proposes to remove a goal that is achieved. This only will fire
  #  if the goal is o-supported.
  sp "ngs*core*goals*propose-to-remove-achieved-goals*$goal_name
    [ngs-match-goal <s> $goal_name <g> $NGS_GB_ACHIEVE <goals>]
  -->
    [ngs-create-atomic-operator $NGS_OP_REMOVE_ACHIEVED
                                {
                                  {goal-set <goals>} 
                                  {goal <g>}
                                }]"
}
