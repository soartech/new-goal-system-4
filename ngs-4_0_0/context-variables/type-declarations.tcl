##!
# @file
#
# @created jacobcrossman 20161226

# Base type for context variables
NGS_DeclareType ContextVariable {
    value ""
}

# Stable value. All of the items in the first
#  group always exist on a full instantiated
#  stable value. The items from one of the other
#  three will also exist, though which depends
#  on how it is instantiated.
NGS_DeclareType StableValue {
    type ContextVariable
    value ""
    src-obj ""
    src-attr ""
    min-bound ""
    max-bound ""
    delta-type ""

    delta ""

    min-delta ""
    max-delta ""

    delta-src-obj ""
    delta-src-attr ""
}
