
# Dumps RL rules to a specified file
#
# Call this method at the command line to dump the current RL rules (with their
#  updated numeric preferences)
# 
# filename - Path+ Name of the file to which to dump the rules. You do not need
#               to provide an extension.  The ".soar" extension is given.
#               The path can be relative to the current working directory or absolute.
#                                                                    
proc ngs-rl-save-productions { filename } {
    set productions_as_string [CORE_GetCommandOutput p --rl --full --internal]
    file rename -force ngs-temp.txt $filename.soar
    echo "Wrote RL rules to file $filename.soar"
}