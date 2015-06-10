#
# Copyright (c) 2015, Soar Technology, Inc.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
# 
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
# 
# * Neither the name of Soar Technology, Inc. nor the names of its contributors
#   may be used to endorse or promote products derived from this software
#   without the specific prior written permission of Soar Technology, Inc.
# 
# THIS SOFTWARE IS PROVIDED BY SOAR TECHNOLOGY, INC. AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL SOAR TECHNOLOGY, INC. OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# This holds the most common variables used in macros. Things like the debug settings,
# the goal pool, etc. See CORE_MacroVariables.tcl
variable CORE_macro_var_list ""

# Use this like C's #ifdef statements - the 'code' parameter executes only if 
# the soar variable named '$var_name' has been defined.
#
# Like in C and C++, frequent use of CORE_IfDef and CORE_IfNDef will cause 
#   code readability issues and should be avoided.
#
# Example: CORE_IfDef varName "echo \"Hi my name is Fred\""
proc CORE_IfDef { var_name code } {
  if [uplevel 1 "info exists $var_name"] {
    uplevel 1 "$code"
  } else {
    return
  } 
}

# The inverse of CORE_IfDef.
# Same syntax and use - but code is only executed if the variable is NOT defined.
proc CORE_IfNDef { var_name code } {
  if [uplevel 1 "info exists $var_name" ] {
    return
  } else {
    uplevel 1 "$code"
  } 
}

# Use this like C's #ifeq statements - the 'code' parameter only happens if 
# the soar variable named '$var_name' has value equal to $check_val
#
# If the variable doesn't exist, $code won't be executed.
proc CORE_IfEQ { var_name check_val code } {
  if [uplevel 1 "info exists $var_name" ] {
    if "[expr [string compare [uplevel 1 set $var_name] $check_val] == 0]" {
      uplevel 1 "$code" 
    }
  }
}

# Use this like C's #ifneq statements - the 'code' parameter only does NOT happen if 
# the soar variable named '$var_name' has value equal to $check_val
#
# If the variable doesn't exist, $code WILL be executed.
proc CORE_IfNEQ { var_name check_val code } {
  if [uplevel 1 "info exists $var_name" ] {
    if "[expr [string compare [uplevel 1 set $var_name] $check_val] != 0]" {
      uplevel 1 "$code"
    } 
  } else {
    uplevel 1 "$code"
  }
}

# The 'code' parameter only happens if the soar variable named '$var_name
#  has a value GREATER THAN the given $check_val
#
# If the variable doesn't exist, $code will NOT be executed.
proc CORE_IfGT { var_name check_val code } {
  if [uplevel 1 "info exists $var_name" ] {
    if "[expr [uplevel 1 set $var_name] > $check_val]" {
      uplevel 1 "$code"
    } 
  } 
}

# The 'code' parameter only happens if the soar variable named '$var_name
#  has a value LESS THAN than the given $check_val
#
# If the variable doesn't exist, $code will NOT be executed.
proc CORE_IfLT { var_name check_val code } {
  if [uplevel 1 "info exists $var_name" ] {
    if "[expr [uplevel 1 set $var_name] < $check_val]" {
      uplevel 1 "$code"
    } 
  } 
}


##!
# @brief Pull in all of the globally available variables 
#
# @devnote The variables come from CORE_CreateMacroVar
proc CORE_RefMacroVars { } {
   variable CORE_macro_var_list
   foreach var $CORE_macro_var_list {
       uplevel 1 variable $var
   }
}

##!
# @brief Create a globally-avialable variable
proc CORE_CreateMacroVar { variable_name variable_value } {
   
   variable CORE_macro_var_list
   variable $variable_name
      
   if {[lsearch -exact $CORE_macro_var_list $variable_name ] == -1} {
     # echo "adding $variable_name to soar-var-list"
     lappend CORE_macro_var_list $variable_name
   } else {
     #echo \"$variable_name already exists!\"
     # do nothing 
   }
   
   # echo "Setting $variable_name to $variable_value"
   
   set "$variable_name" $variable_value
   
   # ... now reference the variable in our caller's context, too.
   uplevel 1 variable $variable_name
}

# A helper function to make it easier to set values for absent
#  macro parameters
proc CORE_SetIfEmpty { var val } {
  upvar 1 $var var_to_set
  if {$var_to_set == ""} {set var_to_set $val}
}

# A helper function to make it easier to set values for absent
#  macro parameters
proc CORE_GenVarIfEmpty { var base } {
  upvar 1 $var var_to_set
  if {$var_to_set == ""} {set var_to_set [CORE_GenVarName $base]}
}
  
# Generates a unique symbol that is typically used
#  to create new soar variables within macros
# This version creates a string of the form
#  baseNUMBER, where NUMBER is incremented each
#  time this procedure is called.
proc CORE_GenUniqueSym { base } {
   variable gsCounter
   if ![info exists gsCounter($base)] {
      set gsCounter($base) 0
   }
   return $base[incr gsCounter($base)]
}

# Generates a unique soar variable for use in macros
# The variable will start with the string provided by the
#  base parameter.
proc CORE_GenVarName { base } {
   return "<[CORE_GenUniqueSym $base]>"
}

# Source the global macro variables
source _CORE_MacroVariables.tcl

##
# Use this the way you would use bash's pushd
# 
# It will print out the usual "Loading files for,..." message
#
proc CORE_Pushd { directory } {
  CORE_RefMacroVars
  CORE_IfGT CORE_DEBUG_OUTPUT_LEVEL $CORE_DLVL_NO_DBG "echo \"Loading files for [pwd]/$directory \""
  pushd $directory
}

##
# Use this the way you would use the standard Soar source
# 
# It will print out the usual " ... Loading file, ..." message if debugging
#
proc CORE_Source { file } {
  CORE_RefMacroVars
  CORE_IfGT CORE_DEBUG_OUTPUT_LEVEL $CORE_DLVL_NO_DBG  "echo \" ... Loading file: [pwd]/$file \""
  source $file
}

# Use this instead of the following:
#
# echo-pushd directory
# CORE_echo-source load.soar
# popd
#
proc CORE_LoadDir { directory } {
  CORE_RefMacroVars
  CORE_Pushd $directory
    source "load.soar" 
  popd
}