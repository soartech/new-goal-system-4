# cause unittest to fail if it reaches the specified number of decision cycles
proc FailAfterNDecisionCycles { numdcs } {
    
    # fail fast
    sp "soarunit*fail*too-long
       (state <s> ^io.input-link.soar-unit <su>)
       (<su> ^cycle-count $numdcs)
    -->
       (fail)
    "
}