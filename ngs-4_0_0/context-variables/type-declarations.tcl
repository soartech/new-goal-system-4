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

# A context variable that gets or computes its value from a single source
#
# src-obj - the identifier for the source value
# src-attr - the attribute for the source value
#
NGS_DeclareType SingleSourceVariable {
    src-obj ""
    src-attr ""
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