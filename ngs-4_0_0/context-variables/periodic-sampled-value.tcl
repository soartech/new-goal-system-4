##!
# @file
#
# @created jacobcrossman 20161230

# Create a PeriodicSampledValue object
#
# Periodic sampled values are copies of another value, sampled at a given frequency.
# The sampling process can use a single period value (i.e. a "global period") or can use custom periods
#  that depend on the current value of the PeriodSampledValue. PeriodSampledValue are a way to create 
#  stable values for decision making that are guarranteed not to change faster than a given rate.
#
# If you are worried about eliminating small transient noise, see time-delayed-values.tcl
#
# An example for use might be sampling the velocity of a vehicle. The velocity is likely to change
#  fairly frequently (possibly at 100Hz or more). The value can be sampled in the input processing code to
#  give you the maximum possible sampling frequency that you may ever want, but you may wan to further
#  slow sampling, using the maximum rate at different speeds. For example, you might wan to use the 
#  maximum sampling rate (e.g. 10hz) when the vehicle is moving fast, but would rather use a slower sampling rate
#  for slower speeds. You can do this with periodic sampled values using custom delays as follows:
#
# A custom set of periodic sampling values is just a list of {condition, sample-period} pairs. In the example
#  just described we could set it up as follows:
# 
# { { { < 0.1 } 1000} { {0.1 3.0} 500 } { { >= 3.0 } 250 } } 
#
# Here sampling gets more frequent the faster the vehicle goes (from 1 hz to 2 hz to 4 hz)
#
# These value conditions can four different forms
#   equality: { 5 2000 }, sample every 2s if the value is 5
#   range:    { {5 10} 2000}, sample every 2s if the value is >= 5 and < 10
#   min:      { {>= 5} 2000}, sample every 2s if the value is >= 5 (NOTE: strict > is not currently allowed) 
#   max:      { {< 10} 2000}, sample every 2s if the value is < 10 (NOTE: <= is not currently allowed)
#
# Finally, the custom periods can also use a source. So, for example if you wan to use a dynamically changing
#  sampling when the vehicle is stopped you could use the following:
#
#  { { < 0.1 } { <obj> my-stopped-sample-period } } which would set the delay to whatever the value of 
#     <obj>.my-stopped-sample-period currently is.
#
# NOTE: you should never set the sampling period so low that all the system does is sample the value. Future
#        work may allow sampling rates of 0 to simply pass the value through (but this is not available yet).
#
# [ngs-create-periodic-sampled-value pool_id variable_name src_obj src_attr global_period (specialized_period_list) (variable_id)
#
# pool_id - Variable bound to the identifier for the category pool into which to place the new
#             stable value. Bind to this pool using one of the following macros:
#             ngs-match-to-create-context-variable or ngs-match-goal-to-create-context-variable
# variable_name - Name of the context variable that should be constructed
# src_obj - Variable bound to the object containing the value to be sampled
# src_attribute - Name of the attribute to sample (do NOT bind to this in the LHS)
# global_period - Either a constant/variable indicating the sampling period or the source id and source attribute
#                   for a WME that provides this value
# specialized_period_list - (Optional). A list of conditional periods (see examples above).
# variable_id - (Optional) If provided, a variable that is bound to the newly created periodic sampled value.
#                You can use this, for exmaple, to tag the variable.
# 
proc ngs-create-periodic-sampled-value { pool_id variable_name src_obj src_attr global_period {specialized_period_list ""} { variable_id "" } } {

    CORE_GenVarIfEmpty variable_id "variable"
    return "[ngs-create-typed-object $pool_id $variable_name PeriodicSampledValue $variable_id \
                                    "name $variable_name src-obj $src_obj src-attr $src_attr"]
            [ngs-ctx-var-help-construct-time-based-varible period $variable_id $global_period $specialized_period_list]"
}



# Declare and define the productions for a PeriodicSampledValue
# 
# Use this macro to declare and define the productions for a periodic sampled value. See
#  ngs-create-periodic-sampled-value for more information on these values.
#
# This macro instantiates productions that do the sampling of the source value at the given
#   global and/or specialized sampling rates. It also elaborates a few useful attributes:
#
# time-last-sampled - (Computed) Time the source was last sampled
# value-age - (Computed) Age of the value attribute (amount of time since last sampled)
# is-consistent-with-source - (Computed) NGS_YES if the current value is the same as the sourc evalue,
#          NGS_NO otherwise       
#
# You can test these value in your productions to respond to different sampling situations.
#
# You must call this macro for every periodic sampled value you wish to use in your program or
#  that value will not properly update.
#
# NGS_DefinePeriodicSampledValue pool_goal_or_path category_name variable_name
#
# pool_goal_or_path - A global context variable pool name, a goal type, or an arbitrary path rooted at the top state.
#  This is the location where the context variable will be stored.
# category_name - Name of the category into which to place the variable. Set to NGS_CTX_VAR_USER_LOCATION if you
#   are placing the context variable in an arbitrary location specified by a path (see parameter pool_goal_or_path)
# variable_name - Name of the variable
#
proc NGS_DefinePeriodicSampledValue { pool_goal_or_path category_name variable_name } {
    
    variable NGS_CTX_ALL_VARIABLES
    lappend NGS_CTX_ALL_VARIABLES [dict create pool $pool_goal_or_path category $category_name name $variable_name]

    set var_id  <variable>

    # Generate the root bindings shared by all productions in this macro
    set root_bind [ngs-ctx-var-gen-root-bindings $pool_goal_or_path $category_name $variable_name $var_id]

    # set the suffix for the template's names, removing any '.' charaters that appear (not allowed in production names)
    set production_name_suffix [ngs-ctx-var-gen-production-name-suffix $pool_goal_or_path $category_name $variable_name]

    variable NGS_SIDE_EFFECT_ADD
    variable NGS_CTX_VAR_SUPPRESS_SAMPLING
    variable NGS_CTX_VAR_PASSTHROUGH_MODE

    sp "ctxvar*periodic-sampled-value*propose*initialize*$production_name_suffix
        $root_bind
        [ngs-nex $var_id sampled-value]
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_PASSTHROUGH_MODE]
        [ngs-time <s> <time>]
        [ngs-ctx-var-source-val $var_id <src-val>]
    -->
        [ngs-create-attribute-by-operator <s> $var_id sampled-value <src-val>]
        [ngs-add-primitive-side-effect $NGS_SIDE_EFFECT_ADD $var_id time-last-sampled <time>]"

    # Change the value after the time limit changes
    sp "ctxvar*periodic-sampled-value*propose*resample*global*$production_name_suffix
        $root_bind
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_PASSTHROUGH_MODE]
        [ngs-bind $var_id global-period value-age:>=:<global-period>]
        [ngs-nex  $var_id custom-period]
        [ngs-ctx-var-source-val $var_id <src-val>]
        [ngs-time <s> <time>]
    -->
        [ngs-create-attribute-by-operator <s> $var_id sampled-value <src-val>]
        [ngs-add-primitive-side-effect $NGS_SIDE_EFFECT_ADD $var_id time-last-sampled <time>]"

    sp "ctxvar*periodic-sampled-value*propose*resample*custom*$production_name_suffix
        $root_bind
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_SUPPRESS_SAMPLING]
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_PASSTHROUGH_MODE]
        [ngs-bind $var_id custom-period value-age:>=:<custom-period>]
        [ngs-ctx-var-source-val $var_id <src-val>]
        [ngs-time <s> <time>]
    -->
        [ngs-create-attribute-by-operator <s> $var_id sampled-value <src-val>]
        [ngs-add-primitive-side-effect $NGS_SIDE_EFFECT_ADD $var_id time-last-sampled <time>]"

    sp "ctxvar*periodic-sampled-value*elaborate*value-from-sampled-value*$production_name_suffix
        $root_bind
        [ngs-bind $var_id sampled-value]
        [ngs-is-not-tagged $var_id $NGS_CTX_VAR_PASSTHROUGH_MODE]
    -->
        [ngs-create-attribute $var_id value <sampled-value>]"

    sp "ctxvar*periodic-sampled-value*elaborate*value-from-source*$production_name_suffix
        $root_bind
        [ngs-is-tagged $var_id $NGS_CTX_VAR_PASSTHROUGH_MODE]
        [ngs-ctx-var-source-val $var_id <src-val>]
    -->
        [ngs-create-attribute $var_id value <src-val>]"

    ngs-ctx-var-help-build-time-productions periodic-sampled-value period $production_name_suffix $root_bind $var_id

}


