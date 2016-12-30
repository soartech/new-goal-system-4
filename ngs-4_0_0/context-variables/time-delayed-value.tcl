##!
# @file
#
# @created jacobcrossman 20161228


# Create a TimeDelayedValue object
#
# Time delayed values are copies of another value, sampled after the source value is unchanged for a given time.
# The sampling process can use a single value (i.e. a "global delay") or can use delay factors that depend
#  on the current time delayed value. TimeDelayedValues are a way to create stable values for decision making.
#  They throw out transient noise and only sample a value if it steady.
#
# An example for use might be to determine whether an entity is moving or stopped. If your vehicle is following
#  the vehicle you don't want to oscillate between moving and stopping due to noise in sensing. Therefore, you
#  may wish to first create a dynamic binned value indicating whether the entity is moving or stopped, then
#  delay sample this binned value. If the vehicle is in the stopped state for more than some time (e.g. 3s) you
#  might consider it really stopped and take appropriate action. 
#
# In aother example, you might want to know when a vehicle begins to "cruise" (i.e. have a steady velocity), so
#  you could create a TimeDelayedValue that samples a StableValue. This time delayed value would wait for the
#  StableValue to become steady, then set the cruise speed. You could then use the flag "is-consistent-with-source"
#  to determine if the vehicle is currently cruising and the value of the TimeDelayedValue to know the cruise speed.
#
# Custom (per value) delays
#
# You may want to change the delays based on the current value of the TimeDelayedValue. For example, you may want
#  to change from "moving" to "stopped" if the stopped state lasts for 5s. However, you may want to change from
#  "stopped" back to "moving" only if the entity is "moving" for 2s. To do this, you specify a specalized delay
#  list which is just a list of { condition delay } pairs.
# 
# For the given example, this list would be as follows: { { moving 5000 } { stopped 2000 } }; i.e. sample
#  after 5s if the value is currently set to moving and sample after 2s if the value is current set to stopped.
#
# These conditions can be more complex. If you are sampling a numeric value you can specify the condition in four ways
#   equality: { 5 2000 }, delay 2s if the value is 5
#   range:    { {5 10} 2000}, delay 2s if the value is >= 5 and < 10
#   min:      { {>= 5} 2000}, delay 2s if the value is >= 5 (NOTE: strict > is not currently allowed) 
#   max:      { {< 10} 2000}, delay 2s if the value is < 10 (NOTE: <= is not currently allowed)
#
# Finally, the custom delays can also use a source. So, for example if you wan to use a dynamically changing
#  delay when the vehicle is stopped you could use the following:
#
#  { stopped { <obj> my-stopped-delay } } which would set the delay to whatever the value of <obj>.my-stopped-delay
#       currently is.
#
# NOTE: you should never sample a continously varying value using a TimeDelayedValue. It will never get reset.
#    TimeDelay should only be used on values that are normally steady, but can have transients in them.
#
# [ngs-create-time-delayed-value pool_id variable_name src_obj src_attr global_delay (specialized_delay_list) (variable_ie)
#
# pool_id - Variable bound to the identifier for the category pool into which to place the new
#             stable value. Bind to this pool using one of the following macros:
#             ngs-match-to-create-context-variable or ngs-match-goal-to-create-context-variable
# variable_name - Name of the context variable that should be constructed
# src_obj - Variable bound to the object containing the value to be sampled
# src_attribute - Name of the attribute to sample (do NOT bind to this in the LHS)
# global_delay - Either a constant/variable indicating the amount of time the source value must remain steady
#          before sampling, or the source id and soure attribute for a WME that provides this value
# specialized_delay_list - (Optional). A list of conditional delays (see examples above).
# variable_id - (Optional) If provided, a variable that is bound to the newly created stable value.
#                You can use this, for exmaple, to tag the variable.
# 
proc ngs-create-time-delayed-value { pool_id variable_name src_obj src_attr global_delay {specialized_delay_list ""} { variable_id "" } } {

    CORE_GenVarIfEmpty variable_id "variable"
    return "[ngs-create-typed-object $pool_id $variable_name TimeDelayedValue $variable_id \
                                    "name $variable_name src-obj $src_obj src-attr $src_attr"]
            [ngs-ctx-var-help-construct-time-based-varible delay $variable_id $global_delay $specialized_delay_list]"
}

# Helper to construct the detailed elements of a time-period based context variable
#
# For internal use only
proc ngs-ctx-var-help-construct-time-based-varible { time_descriptor variable_id global_time_param specialized_param_list } {

    if { [llength $global_time_param] == 1 } {
        # It's just a constant value
        set global_constructs "[ngs-create-attribute $variable_id global-$time_descriptor $global_time_param]"
    } else {
        set global_constructs "[ngs-create-attribute $variable_id global-$time_descriptor-src  [lindex $global_time_param 0]]
                               [ngs-create-attribute $variable_id global-$time_descriptor-attr [lindex $global_time_param 1]]"
    }

    # Handle the specialized delay list (if it exists)
    if { $specialized_param_list != "" } {
        set cond_set_id [CORE_GenVarName "$time_descriptor-set"]
        set global_constructs "$global_constructs
                               [ngs-create-typed-object $variable_id conditional-${time_descriptor}s Set $cond_set_id]"
    } else {
        set conds_ret ""
    }

    foreach description $specialized_param_list {

        set condition      [lindex $description 0]
        set time_param     [lindex $description 1]
        set time_param_id  [CORE_GenVarName "conditional-$time_descriptor"]

        if { [llength $time_param] == 1 } {
            set time_param_creation "$time_descriptor $time_param"
        } else {
            set time_param_creation "$time_descriptor-src [lindex $time_param 0] $time_descriptor-attr [lindex $time_param 1]"
        }
                               
        if { [llength $condition] == 1 } {
            set conds_ret   "[ngs-create-typed-object $cond_set_id condition ConditionalDelay $time_param_id \
		                                             "$time_param_creation comparison-value $condition "]"
        } else {
            set first_item [lindex $condition 0]
            set second_item [lindex $condition 1]
        
            if { [string is integer $first_item] == 1 || [string is double $first_item] == 1} {
                set conds_ret   "[ngs-create-typed-object $cond_set_id condition ConditionalDelay $time_param_id \
                                                         "$time_param_creation range-min $first_item range-max $second_item"]"
            } else {
                if { $first_item == "<" } {
                    set conds_ret   "[ngs-create-typed-object $cond_set_id condition ConditionalDelay $time_param_id \
                                                             "$time_param_creation range-max $second_item"]"
                } elseif { $first_item == ">=" } {
                    set conds_ret   "[ngs-create-typed-object $cond_set_id condition ConditionalDelay $time_param_id \
                                                             "$time_param_creation range-min $second_item"]"
                } else {
                    echo "Time Delayed Values only support < and >= conditions ($variable_name)"
                }
            }
        }
    }

    return "$global_constructs
            $conds_ret"
}

# Declare and define the productions for a TimeDelayedValue
# 
# Use this macro to declare and define the productions for a time delayed value. See
#  ngs-create-time-delayed-value for more information on these values.
#
# This macro instantiates productions that do the sampling of the source value at the given
#   global and/or specialized delays. It also elaborates a few useful attributes:
#
# time-last-sampled - (Computed) Time the source was last sampled
# value-age - (Computed) Age of the value attribute (amount of time since last sampled)
# is-consistent-with-source - (Computed) NGS_YES if the current value is the same as the sourc evalue,
#          NGS_NO otherwise       
#
# You can test these value in your productions to respond to different sampling situations.
#
# You must call this macro for every time delayed value you wish to use in your program or
#  that value will not properly update.
#
# NGS_DefineTimeDelayedValue pool_goal_or_path category_name variable_name
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the variable
#
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
        [ngs-bind $var_id custom-delay]
        [ngs-ctx-var-source-val $var_id <src-val>]
    -->
        [ngs-create-attribute-by-operator <s> $var_id next-val <src-val>]
        [ngs-add-primitive-side-effect $NGS_SIDE_EFFECT_ADD $var_id next-sample-time "(+ <time> <custom-delay>)"]"

    sp "ctxvar*time-delayed-value*propose*next-sample-time*$production_name_suffix*use-general
        $root_bind
        [ngs-neq $var_id next-val <src-val>]
        [ngs-time <s> <time>]
        [ngs-bind $var_id global-delay]
        [ngs-nex $var_id custom-delay]
        [ngs-ctx-var-source-val $var_id <src-val>]
    -->
        [ngs-create-attribute-by-operator <s> $var_id next-val <src-val>]
        [ngs-add-primitive-side-effect $NGS_SIDE_EFFECT_ADD $var_id next-sample-time "(+ <time> <global-delay>)"]"

    # Change the value after the time limit changes
    variable NGS_CTX_VAR_SUPPRESS_SAMPLING
    sp "ctxvar*time-delayed-value*propose*resample*$production_name_suffix
        $root_bind
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-time <s> <time>]
        [ngs-bind $var_id value:<>:<next-val> next-val next-sample-time:<:<time>]
    -->
        [ngs-create-attribute-by-operator <s> $var_id value <next-val>]
        [ngs-add-primitive-side-effect $NGS_SIDE_EFFECT_ADD $var_id time-last-sampled <time>]"

    sp "ctxvar*time-delayed-value*propose*initialize*$production_name_suffix
        $root_bind
        [ngs-nex $var_id value]
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-time <s> <time>]
        [ngs-ctx-var-source-val $var_id <src-val>]
    -->
        [ngs-create-attribute-by-operator <s> $var_id value <src-val>]
        [ngs-add-primitive-side-effect $NGS_SIDE_EFFECT_ADD $var_id time-last-sampled <time>]"

    ngs-ctx-var-help-build-time-productions time-delayed-value delay $production_name_suffix $root_bind $var_id

}


proc ngs-ctx-var-help-build-time-productions { ctxvar_type time_descriptor production_name_suffix root_bind var_id } {

    ######################### PRODUCTIONS THAT HANDLE THE GLOBAL SOURCE
    set set_attr_name "conditional-${time_descriptor}s"

    # If I have a source for the global delay/period, elaborate it
    sp "ctxvar*$ctxvar_type*elaborate*global-$time_descriptor*$production_name_suffix
        $root_bind
        [ngs-bind $var_id global-$time_descriptor-src global-$time_descriptor-attr]
        (<global-$time_descriptor-src> ^<global-$time_descriptor-attr> <global-$time_descriptor-val>)
    -->
        [ngs-create-attribute $var_id global-$time_descriptor <global-$time_descriptor-val>]"

    # Handle sources for conditional delay/period
    sp "ctxvar*$ctxvar_type*elaborate*conditional-$time_descriptor*$production_name_suffix
       $root_bind
       [ngs-bind $var_id value $set_attr_name.condition]
       [ngs-bind <condition> $time_descriptor-src $time_descriptor-attr]
       (<$time_descriptor-src> ^<$time_descriptor-attr> <$time_descriptor-val>)
    -->        
       [ngs-create-attribute <condition> $time_descriptor <$time_descriptor-val>]"

    ########################## PRODUCTIONS THAT HANDLE ELABORATING TIMES

    sp "ctxvar*$ctxvar_type*elaborate*time-since-last-sampled*$production_name_suffix
        $root_bind
        [ngs-time <s> <time>]
        [ngs-bind $var_id time-last-sampled]
    -->
        [ngs-create-attribute $var_id value-age "(- <time> <time-last-sampled>)"]"

    variable NGS_YES
    variable NGS_NO

    sp "ctxvar*$ctxvar_type*elaborate*value-is-consistent*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value:<src-val>]
        [ngs-ctx-var-source-val $var_id <src-val>]
    -->
        [ngs-create-attribute $var_id is-consistent-with-source $NGS_YES]"

    sp "ctxvar*$ctxvar_type*elaborate*value-is-not-consistent*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value:<>:<src-val>]
        [ngs-ctx-var-source-val $var_id <src-val>]
    -->
        [ngs-create-attribute $var_id is-consistent-with-source $NGS_NO]"


    ############## PRODUCTIONS TO HANDLE CONDITIONAL DELAYS BASED ON THE VALUE OF SRC

    sp "ctxvar*$ctxvar_type*elaborate*custom-$time_descriptor*for-equality*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value $set_attr_name.condition]
        [ngs-bind <condition> comparison-value:<value> $time_descriptor]
    -->
        [ngs-create-attribute $var_id custom-$time_descriptor <$time_descriptor>]"

    sp "ctxvar*$ctxvar_type*elaborate*custom-$time_descriptor*for-range*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value $set_attr_name.condition]
        [ngs-bind <condition> range-min:<=:<value> range-max:>:<value> $time_descriptor]
    -->
        [ngs-create-attribute $var_id custom-$time_descriptor <$time_descriptor>]"

    sp "ctxvar*$ctxvar_type*elaborate*custom-$time_descriptor*for-lte*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value $set_attr_name.condition]
        [ngs-bind <condition> range-max:>:<value> $time_descriptor]
        [ngs-nex <condition> range-min]
    -->
        [ngs-create-attribute $var_id custom-$time_descriptor <$time_descriptor>]"

    sp "ctxvar*$ctxvar_type*elaborate*custom-$time_descriptor*for-gt*$production_name_suffix
        $root_bind
        [ngs-bind $var_id value $set_attr_name.condition]
        [ngs-bind <condition> range-min:<=:<value> $time_descriptor]
        [ngs-nex <condition> range-max]
    -->
        [ngs-create-attribute $var_id custom-$time_descriptor <$time_descriptor>]"

}