
# Create the top level goal set for all NGS goals
sp {ngs*core*goals*elaborate-goal-set-on-top-state
  (state <s> ^superstate nil)
-->
  (<s> ^goals <gs>)
}

# Marks a goal with the NGS_GS_ACTIVE tag after that
#  goal is 
sp "ngs*core*goals*mark-goal-as-active
  [ngs-match-substate <ss> <top-state>]
  (<top-state> ^operator.goal <g>)
-->
  (<ss> ^$WM_ACTIVE_GOAL <g>)
  [ngs-tag <g> $NGS_GS_ACTIVE]
"

# This is the traditional way names are given to substates
sp "ngs*core*goals*set-substate-name
  [ngs-match-substate <ss> <top-state>]
  (<top-state> ^operator.name <name>)
-->
  (<ss> ^name <name>)"

# Generates the return value infrastructure when a subgoal is created
sp "ngs*core*goal*set-substate-return-values
  [ngs-match-substate <ss>]
-->
  (<ss> ^ret-values <ret-vals>)"

# Apply rule that cleans up an achieved goal
sp "ngs*core*goal*apply*$NGS_OP_REMOVE_ACHIEVED
  [ngs-match-selected-operator-on-top-state <s> $NGS_OP_REMOVE_ACHIEVED <o>]
  (<o> ^goal <g>
       ^goal-set <goals>)
-->
  (<goals> ^goal <g> -)"

# Every goal type should be declared
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
    [ngs-match-goal <s> $goal_name <g> <goals>]
  -->
    [ngs-create-atomic-operator $NGS_OP_REMOVE_ACHIEVED
                                {
                                  {goal-set <goals>} 
                                  {goal <g>}
                                }]"
}


