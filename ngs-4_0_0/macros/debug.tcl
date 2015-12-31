
# Print out the goal stacks
#
# Use to print out all goal stacks. Because this must be implemented
#  as productions, it will execute 1 elaboration cycle to trigger the productions
#  Depending on where  you are in the decision cycle when you pause, you may not see
#  a printout because one elaboration cycle may not trigger the productions. If you don't
#  see an output, execute the command again.
#
# Usage: nps (print all goal stacks)
# Usage: nps GoalName1 GoalName2 (print goal stacks rooted at GoalName1 and GoalName2)
#
# args - (Optional) Pass in space-separated list of goal types to only show goal stacks
#          that are rooted at the given goal type.
#
proc nps { args } {

	if { $args != "" } {
		set goal_constraint [ngs-is-my-type <top-goal> "<< $args >>"]
	} else {
		set goal_constraint ""
	}

	# sp some productions
	sp "debug*print-isolated-goals
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-subgoal <top-goal> <subgoal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)
		(write (crlf) |+ ISOLATED GOAL|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)"

	sp "debug*print-goal-stack*1
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-my-type <sg1> <sg1-type>]
		[ngs-is-not-subgoal <sg1> <sg2>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)
		(write (crlf) |+   | <sg1-type> |: | <sg1>)"

	sp "debug*print-goal-stack*2
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-my-type <sg1> <sg1-type>]
		[ngs-is-subgoal <sg1> <sg2>]
		[ngs-is-my-type <sg2> <sg2-type>]
		[ngs-is-not-subgoal <sg2> <sg3>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)
		(write (crlf) |+   | <sg1-type> |: | <sg1>)
		(write (crlf) |+     | <sg2-type> |: | <sg2>)"

	sp "debug*print-goal-stack*3
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-my-type <sg1> <sg1-type>]
		[ngs-is-subgoal <sg1> <sg2>]
		[ngs-is-my-type <sg2> <sg2-type>]
		[ngs-is-subgoal <sg2> <sg3>]
		[ngs-is-my-type <sg3> <sg3-type>]
		[ngs-is-not-subgoal <sg3> <sg4>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)
		(write (crlf) |+   | <sg1-type> |: | <sg1>)
		(write (crlf) |+     | <sg2-type> |: | <sg2>)
		(write (crlf) |+       | <sg3-type> |: | <sg3>)"

	sp "debug*print-goal-stack*4
		[ngs-match-goal <s> <any-goal-type> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-my-type <sg1> <sg1-type>]
		[ngs-is-subgoal <sg1> <sg2>]
		[ngs-is-my-type <sg2> <sg2-type>]
		[ngs-is-subgoal <sg2> <sg3>]
		[ngs-is-my-type <sg3> <sg3-type>]
		[ngs-is-subgoal <sg3> <sg4>]
		[ngs-is-my-type <sg4> <sg4-type>]
		[ngs-is-not-subgoal <sg4> <sg5>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-type> |: | <top-goal>)
		(write (crlf) |+   | <sg1-type> |: | <sg1>)
		(write (crlf) |+     | <sg2-type> |: | <sg2>)
		(write (crlf) |+       | <sg3-type> |: | <sg3>)
		(write (crlf) |+         | <sg4-type> |: | <sg4>)"

	# run -e 1
	run -e 1
	echo +---------------------------------------------------------------------------+

	# excise some productions
	watch 0
	excise debug*print-isolated-goals
	excise debug*print-goal-stack*1
	excise debug*print-goal-stack*2	
	excise debug*print-goal-stack*3
	excise debug*print-goal-stack*4
	watch 1
}

# NGS Print 
#
# This is a specialized version of Soar's p (or print) command.
# It defaults to printing as a tree and to depth 2. You can pass 
#  an optional depth number to change the printing depth.
#
# Usage: np s1 (print the top state to depth 2)
# Usage: np 3 s1 (print the top state to depth 3)
# Usage: np i2 i3 (print input and output links to depth 2)
# Usage: np 3 i2 i3 (print the input and output linkks to depth 3)
#
# args - An optional depth (integer) followed by identifiers. If the
#          depth is not provided, a default print depth of 2 is used.
#
proc np { args } {

	if { [llength $args] == 0} {
		echo "+---------------------------------------+"
		echo "Usage: np (depth=2) id1 id2 id3 ..."
	}

	set depth 2
	set first [lindex $args 0]

	if { [string is integer [string index $first 0]] == 1 } {
		set depth $first
		set args [lreplace $args 0 0]
	}

	foreach id $args {
		echo "+---------------------------------------+"
		echo "+ OBJECT: $id"
		p --tree --depth $depth $id
	}
	echo "+---------------------------------------+"

}




