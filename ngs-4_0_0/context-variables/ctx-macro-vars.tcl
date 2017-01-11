##!
# @file
#
# @created jacobcrossman 20161226

# Global list of all context variables
CORE_CreateMacroVar NGS_CTX_ALL_VARIABLES ""

# Root pool off of the top state
CORE_CreateMacroVar WM_CTX_GLOBAL_POOLS "ctx-var-pools"

# Category when placing context variables wherever you want
CORE_CreateMacroVar NGS_CTX_VAR_USER_LOCATION "user-location"

# See ngs-suppress-context-variable-sampling
CORE_CreateMacroVar NGS_CTX_VAR_SUPPRESS_SAMPLING "suppress-sampling"
CORE_CreateMacroVar NGS_CTX_VAR_PASSTHROUGH_MODE "passthrough-mode"

# Types of deltas used for stable values
CORE_CreateMacroVar NGS_CTX_VAR_DELTA_TYPE_ABSOLUTE "absolute"
CORE_CreateMacroVar NGS_CTX_VAR_DELTA_TYPE_PERCENT  "percent"

# Tags
CORE_CreateMacroVar NGS_TAG_DYN_BIN_VAL_CUSTOM_DELTA "override-global-delta"
CORE_CreateMacroVar NGS_TAG_DYN_BINS_IS_STATIC "is-static-bin"

# Scopes
CORE_CreateMacroVar NGS_CTX_SCOPE_GLOBAL "global"
CORE_CreateMacroVar NGS_CTX_SCOPE_GOAL "goal"
CORE_CreateMacroVar NGS_CTX_SCOPE_USER "user"
