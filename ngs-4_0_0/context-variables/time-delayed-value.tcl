##!
# @file
#
# @created jacobcrossman 20161228

# ngs-create-time-delayed-value <pool> var_name 1000 { { 5 2000 } { { > 5 } 4000 } { { 4 10 } 500 } }

NGS_DeclareType TimeDelayedValue {
    type { ContextVariable SingleSourceVariable }
    conditional-delays ""
    
    global-delay ""
    custom-delay ""

    next-sample-time ""
    next-sample-val ""
}

NGS_DeclareType ConditionalDelay {
    delay ""
    comparison-value ""
    range-min ""
    range-max ""
}

proc ngs-create-time-delayed-value { pool_id variable_name src_obj src_attr global_delay {specialized_delay_list ""} { variable_id "" } } {

    CORE_GenVarIfEmpty variable_id "variable"
    
    set root_obj "[ngs-icreate-typed-object-in-place $pool_id $variable_name TimeDelayedValue $variable_id \
                    "name $variable_name src-obj $src_obj src-attr $src_attr global-delay $global_delay"]"

    if { $specialized_delay_list != "" } {
        set delay_set_id [CORE_GenVarName "delay-set"]
        set cond_delays [ngs-icreate-typed-object-in-place $variable_id conditional-delays Set $delay_set_id]
    } else {
        set cond_delays ""
    }

    foreach delay_description $specialized_delay_list {

        set condition [lindex $delay_description 0]
        set delay     [lindex $delay_description 1]
        set delay_id  [CORE_GenVarName "conditional-delay"]
                               
        if { [llength $condition] == 1 } {
            set cond_delays "$cond_delays
                             [ngs-icreate-typed-object-in-place $delay_set_id condition ConditionalDelay $delay_id \
                                    "comparison-value $condition delay $delay"]"
        } else {
            set first_item [lindex $condition 0]
            set second_item [lindex $condition 1]
        
            if { [string is integer $first_item] == 1 || [string is double $first_item] == 1} {
                set cond_delays "$cond_delays
                                 [ngs-icreate-typed-object-in-place $delay_set_id condition ConditionalDelay $delay_id \
                                    "delay $delay range-min $first_item range-max $second_item"]"
            } else {
                if { $first_item == "<" } {
                    set cond_delays "$cond_delays
                                     [ngs-icreate-typed-object-in-place $delay_set_id condition ConditionalDelay $delay_id \
                                         "delay $delay range-max $second_item"]"
                } elseif { $first_item == ">=" } {
                    set cond_delays "$cond_delays
                                     [ngs-icreate-typed-object-in-place $delay_set_id condition ConditionalDelay $delay_id \
                                         "delay $delay range-min $second_item"]"
                } else {
                    echo "Time Delayed Values only support < and >= conditions ($variable_name from $src_obj.$src_attr)"
                }
            }
        }
    }

    return "$root_obj
            $cond_delays"
}

proc NGS_DefineTimeDelayedValue { pool_goal_or_path category_name variable_name } {
    
    set var_id  <variable>

    # Generate the root bindings shared by all productions in this macro
    set root_bind [ngs-ctx-var-gen-root-bindings $pool_goal_or_path $category_name $variable_name $var_id]

    # set the suffix for the template's names, removing any '.' charaters that appear (not allowed in production names)
    set production_name_suffix [ngs-ctx-var-gen-production-name-suffix $pool_goal_or_path $category_name $variable_name]

    variable NGS_SIDE_EFFECT_ADD

    # Set up times for next sampling. Must be o-supported or the time will keep updating every time the clock ticks
    sp "ctxvar*time-delayed-value*propose*next-sample-time*$production_name_suffix*use-specific
        $root_bind
        [ngs-neq $var_id next-val <src-val>]
        [ngs-time <s> <time>]
        [ngs-bind $var_id src-obj src-attr custom-delay]
        (<src-obj> ^<src-attr> <src-val>)
    -->
        [ngs-create-attribute-by-operator <s> $var_id next-val <src-val>]
        [ngs-add-primitive-side-effect $NGS_SIDE_EFFECT_ADD $var_id next-sample-time "(+ <time> <custom-delay>)"]"

    sp "ctxvar*time-delayed-value*propose*next-sample-time*$production_name_suffix*use-general
        $root_bind
        [ngs-neq $var_id next-val <src-val>]
        [ngs-time <s> <time>]
        [ngs-bind $var_id src-obj src-attr global-delay]
        [ngs-nex $var_id custom-delay]
        (<src-obj> ^<src-attr> <src-val>)
    -->
        [ngs-create-attribute-by-operator <s> $var_id next-val <src-val>]
        [ngs-add-primitive-side-effect $NGS_SIDE_EFFECT_ADD $var_id next-sample-time "(+ <time> <global-delay>)"]"

    # Change the value after the time limit changes
    sp "ctxvar*time-delayed-value*propose*resample*$production_name_suffix
        $root_bind
        [ngs-time <s> <time>]
        [ngs-bind $var_id value:<>:<next-val> next-val next-sample-time:<:<time>]
    -->
        [ngs-create-attribute-by-operator <s> $var_id value <next-val>]"

    sp "ctxvar*time-delayed-value*propose*initialize*$production_name_suffix
        $root_bind
        [ngs-nex $var_id value]
        [ngs-bind $var_id src-obj src-attr]
        (<src-obj> ^<src-attr> <src-val>)
    -->
        [ngs-create-attribute-by-operator <s> $var_id value <src-val>]"

    ############## PRODUCTIONS TO HANDLE CONDITIONAL DELAYS BASED ON THE VALUE OF SRC

    sp "ctxvar*time-delayed-value*elaborate*custom-delay*for-equality*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value conditional-delays.condition]
        [ngs-bind <condition> comparison-value:<value> delay]
    -->
        [ngs-create-attribute $var_id custom-delay <delay>]"

    sp "ctxvar*time-delayed-value*elaborate*custom-delay*for-range*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value conditional-delays.condition]
        [ngs-bind <condition> range-min:<=:<value> range-max:>:<value> delay]
    -->
        [ngs-create-attribute $var_id custom-delay <delay>]"

    sp "ctxvar*time-delayed-value*elaborate*custom-delay*for-lte*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value conditional-delays.condition]
        [ngs-bind <condition> range-max:>:<value> delay]
        [ngs-nex <condition> range-min]
    -->
        [ngs-create-attribute $var_id custom-delay <delay>]"

    sp "ctxvar*time-delayed-value*elaborate*custom-delay*for-gt*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value conditional-delays.condition]
        [ngs-bind <condition> range-min:<=:<value> delay]
        [ngs-nex <condition> range-max]
    -->
        [ngs-create-attribute $var_id custom-delay <delay>]"

}    