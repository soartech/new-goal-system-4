
# Print out the goal trees
proc nps { args } {

	if { $args != "" } {
		set goal_constraint [ngs-is-named <top-goal> "<< $args >>"]
	} else {
		set goal_constraint ""
	}

	# sp some productions
	sp "debug*print-isolated-goals
		[ngs-match-goal <s> <any-goal-name> <top-goal>]
		[ngs-is-not-subgoal <top-goal> <subgoal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)
		(write (crlf) |+ ISOLATED GOAL|)
		(write (crlf) |+ | <any-goal-name> |: | <top-goal>)"

	sp "debug*print-goal-stack*1
		[ngs-match-goal <s> <any-goal-name> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-named <sg1> <sg1-name>]
		[ngs-is-not-subgoal <sg1> <sg2>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-name> |: | <top-goal>)
		(write (crlf) |+   | <sg1-name> |: | <sg1>)"

	sp "debug*print-goal-stack*2
		[ngs-match-goal <s> <any-goal-name> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-named <sg1> <sg1-name>]
		[ngs-is-subgoal <sg1> <sg2>]
		[ngs-is-named <sg2> <sg2-name>]
		[ngs-is-not-subgoal <sg2> <sg3>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-name> |: | <top-goal>)
		(write (crlf) |+   | <sg1-name> |: | <sg1>)
		(write (crlf) |+     | <sg2-name> |: | <sg2>)"

	sp "debug*print-goal-stack*3
		[ngs-match-goal <s> <any-goal-name> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-named <sg1> <sg1-name>]
		[ngs-is-subgoal <sg1> <sg2>]
		[ngs-is-named <sg2> <sg2-name>]
		[ngs-is-subgoal <sg2> <sg3>]
		[ngs-is-named <sg3> <sg3-name>]
		[ngs-is-not-subgoal <sg3> <sg4>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-name> |: | <top-goal>)
		(write (crlf) |+   | <sg1-name> |: | <sg1>)
		(write (crlf) |+     | <sg2-name> |: | <sg2>)
		(write (crlf) |+       | <sg3-name> |: | <sg3>)"

	sp "debug*print-goal-stack*4
		[ngs-match-goal <s> <any-goal-name> <top-goal>]
		[ngs-is-not-supergoal <top-goal> <supergoal>]
		[ngs-is-subgoal <top-goal> <sg1>]
		[ngs-is-named <sg1> <sg1-name>]
		[ngs-is-subgoal <sg1> <sg2>]
		[ngs-is-named <sg2> <sg2-name>]
		[ngs-is-subgoal <sg2> <sg3>]
		[ngs-is-named <sg3> <sg3-name>]
		[ngs-is-subgoal <sg3> <sg4>]
		[ngs-is-named <sg4> <sg4-name>]
		[ngs-is-not-subgoal <sg4> <sg5>]
		$goal_constraint
	-->
		(write (crlf) |+---------------------------------------------------------------------------+|)		
		(write (crlf) |+ GOAL STACK|)
		(write (crlf) |+ | <any-goal-name> |: | <top-goal>)
		(write (crlf) |+   | <sg1-name> |: | <sg1>)
		(write (crlf) |+     | <sg2-name> |: | <sg2>)
		(write (crlf) |+       | <sg3-name> |: | <sg3>)
		(write (crlf) |+         | <sg4-name> |: | <sg4>)"

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

# NGS Print (depth defaults to 2)
proc np { id { depth 2 } } {

	p --tree --depth $depth $id

}

# NGS Print List (more than one identifier)
proc npl { depth args } {
	foreach id $args {
		echo "+---------------------------------------+"
		np $id $depth
	}
	echo "+---------------------------------------+"
}