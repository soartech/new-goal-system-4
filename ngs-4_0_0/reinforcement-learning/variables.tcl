# TCL command to turn on/off RL
# TCL "bad" command
CORE_CreateMacroVar NGS_TAG_REWARD_SOURCE source
CORE_CreateMacroVar NGS_REWARD_LOCATION_TOP_STATE top-state
CORE_CreateMacroVar NGS_REWARD_LOCATION_ANY_STATE any-state
CORE_CreateMacroVar NGS_REWARD_LOCATION_SUB_STATE sub-state


CORE_CreateMacroVar NGS_RL_EXPAND_EXISTANCE   exists
CORE_CreateMacroVar NGS_RL_EXPAND_DISCRETE    discrete
CORE_CreateMacroVar NGS_RL_EXPAND_STATIC_BINS bin

CORE_CreateMacroVar NGS_RL_OP_PURPOSE_CREATE    create
CORE_CreateMacroVar NGS_RL_OP_PURPOSE_REMOVE    remove
