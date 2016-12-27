##!
# @file
#
# @created jacobcrossman 20161226

# Root pool off of the top state
CORE_CreateMacroVar WM_CTX_GLOBAL_POOLS "ctx-var-pools"

# See ngs-suppress-context-variable-sampling
CORE_CreateMacroVar NGS_CTX_VAR_SUPPRESS_SAMPLING "suppress-sampling"

# Types of deltas used for stable values
CORE_CreateMacroVar NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE "absolute"
CORE_CreateMacroVar NGS_CTX_VAR_DELTA_TYPE_PERCENT  "percent"

# Tags
CORE_CreateMacroVar NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA "override-global-delta"
CORE_CreateMacroVar NGS_TAG_DYN_BINS_IS_STATIC "is-static-bin"
