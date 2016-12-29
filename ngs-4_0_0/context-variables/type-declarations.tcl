##!
# @file
#
# @created jacobcrossman 20161226

# Base type for context variables
#
# name - (required) the name of the context variable
# value - (computed) the current value for the context variable  
#
NGS_DeclareType ContextVariable {
    name ""
    value ""
}

# Empty context variable for use 
#  for user-defined values.
#
# See user-defined-context-variable.tcl
#
NGS_DeclareType UserContextValue {
    type ContextVariable
}

# A context variable that gets or computes its value from a single source
#
# src-obj - the identifier for the source value
# src-attr - the attribute for the source value
#
NGS_DeclareType SingleSourceVariable {
    src-obj ""
    src-attr ""
}


# A context variable that computes its value from one or more sources
#
# sources - a set of SourceDescription objects that define each source
#
NGS_DeclareType MultiSourceVariable {
    sources ""
}

# A description of a source for multi source variables
#
# src - the source object identifier
# attr - the source attribute
# name - (Optional) the name of the source
#
NGS_DeclareType SourceDescription {
    src ""
    attr ""
    name ""
}

# A context variable that uses a delta value
#  to compute a min-max
#
# delta-type - One of either NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE or NGS_CTX_VAR_DELTA_TYPE_PERCENT
#               telling the system how to interpret the delta values (as absolute values or percentages) 
# delta - indicates that the variable uses a single, uniform delta
# min-delta/max-delta - provided together. Indicates that the variable uses separate minimum and maximum deltas
#                        Can also be genereted by library code from the uniform delta.
# delta-src-obj/delta-src-attr - provided together. Indicates that a single, uniform delta value should
#                        be obtained form tehg iven source object and attribute
#                                                                  
NGS_DeclareType DeltaValue {
    delta-type ""

    delta ""

    min-delta ""
    max-delta ""

    delta-src-obj ""
    delta-src-attr ""
}

# Stable value that changes only when a source value moves outside of a given bounds
#
# min-bound - (computed) The current, minimum bound for resampling the source.
# max-bound - (computed) The current, maximum bound for resampling the source.
NGS_DeclareType StableValue {
    type { ContextVariable SingleSourceVariable DeltaValue }

    min-bound ""
    max-bound ""
}

# Stores data required to implement a dynamically binned value
#
# bins - a set of DynamicBin objects
#
NGS_DeclareType DynamicBinnedValue {
    type { ContextVariable SingleSourceVariable DeltaValue }

    bins ""
}

# Stores data required to implement a dynamic bin
#
# name - required (this is assigned to the DynamicBinnedValue value attribute when selected)
# prev-bin - name of the previous bin (required)  
# 
# max-val - maximum bound of the bin (this can be set directly or through a source obj/attr) 
# max-src-obj/max-src-attr  - (optional) if you want the max to change dynamically
#
# All of the delta values at the bin level override the delta values at the variable level.
# They only need to be set if you want to create custom deltas for each bin.
#
# cur-min - (computed) the current minimum bound of the bin
# cur-max - (computed) the current maximum bound of the bin
#
NGS_DeclareType DynamicBin {

    type DeltaValue

    name ""
    prev-bin ""

    max-val ""

    max-src-obj ""
    max-src-attr ""

    cur-min ""
    cur-max ""
}

# A value that is computed from other values, typically with one or more
#  mathematical or other RHS functions
#
# This structure will be elaborated with many temporary variables that 
#  are specific to the specific function and sources used.
#
NGS_DeclareType ComputedValue {
    type { ContextVariable MultiSourceVariable }
}

# Time delayed context variable
# 
# Time delayed values sample a source after it is stable for a given delay time
#
# global-delay - The global delay factor (in milliseconds) that is used whenever a conditional delay is not available
# global-delay-src/attr - (Optional) Location from which to read the global delay value
#
# conditional-delays - (Optional) A set of delay specifications for specific values
# custom-delay - (Computed) Set when a conditional delay is active
# next-sample-time - (Computed) The next time (from [ngs-time <s> <time>]) that the source will be sampled 
# next-sample-val - (Computed) The next value that will be sampled
#           
# time-last-sampled - (Computed) Time the source was last sampled
# value-age - (Computed) Age of the value attribute (amount of time since last sampled)
# is-consistent-with-source - (Computed) NGS_YES if the current value is the same as the sourc evalue,
#          NGS_NO otherwise       
#                                                                                                  
NGS_DeclareType TimeDelayedValue {
    type { ContextVariable SingleSourceVariable }
    
    global-delay ""
    global-delay-src ""
    global-delay-attr ""

    conditional-delays ""
    custom-delay ""

    next-sample-time ""
    next-sample-val ""

    time-last-sampled ""
    value-age ""
    is-consistent-with-source ""
}

# Conditiona delay information
#
# This is used by Time Delayed Values
#
# delay - Delay (in milleseconds) to use under this condition
# delay-src/attr - (Optional) Location fromw which to read the delay
#
# comparison-value - (Optional) Make this delay active when the TimeDelayedValue's value 
#                       attribute equals this
# range-min/max - (Optional) Make this delay active when the TimeDelayedValue's value
#                       is between these two values [range-min, range-max). If only
#                       one of these is present it acts as a >= and < respectively.
# 
NGS_DeclareType ConditionalDelay {
    delay ""
    delay-src ""
    delay-attr ""

    comparison-value ""
    range-min ""
    range-max ""
}