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

########################################################################
# This file declares two functions that can be used to declare
#  and construct typed objects respectively. These are convenience
#  methods and are not required to use NGS.
#
# Example usage
#
# Construct a type Position and give it thee attributes
#  each of which has a default value of 0. This generates
#  no Soar code by itself, but is used by ngs-construct
#  to construct objects of this type.
#
# NGS_DeclareType Position {lat 0 lon 0 alt 0}
#
# Now the type can be used in a production using either
#  - ngs-i/ocreate-typed-object-in-place OR
#  - ngs-create-typed-object-by-operator
#
# In this example, we construct the internals of the Position object
#  using ngs-construct, overriding the default values for lat and lon
#  but using the default value (0) for alt
#
# sp "ProductionName
#   ...
# -->
#   [ngs-create-typed-object ... <new-obj-id>  {lat 49.123456 lon 48.55555}]"
#
########################################################################

# Takes a nested list of attribute value pairs
#  and replaces any variables with their variables
#
# This is a helper routine to help with things like
#  type declarations that takes lists of attribute
#  value pairs
#
proc expand_variables { var_list } {
	
    set var_list [strip_comments $var_list]

	# The variables in the list will not be declared in
	#  the scope of this procedure, so we need to reference
	#  each before we can substitute in the string
	foreach item $var_list {

		if { [string index $item 0] == "$" } {
			set val [string range $item 1 [string length $item]]
			variable $val
		}

	}

	# Use TCL's built in procedure to substitute the variables
	return [subst $var_list]

}

# this is a simple way of removing comments (adapted from http://wiki.tcl.tk/1669)
# it will not work if there is a value that actually contains the # character (e.g., it doesn't check for escaping, etc.)
# but that is extremely uncommon, so not be worth dealing with for now 
proc strip_comments { arg } {
    return [regsub -all {#.*?\n} $arg \n]
}


# Declares a type that can be used later in your code
#
# The only reason to declare types is to make it easier to
#  construct them. As part of the declaration you can specify
#  default values. An empty default value indicates that the
#  attribute should not be constructed by default. This way
#  you can specify all of the attributes for a type without
#  forcing all of them to be created by default.
#
# The following example creates a type named MyTypeName.
#  It contains the attributes attr1, attr2, and att3.
#  attr1 and attr2 have default values val1 and val2 respectively.
#  attr3 does not have a default value and will not be created
#  by default when constructing this type.
#
# NGS_DeclareType MyTypeName { attr1 val1 attr2 val2 attr3 {} }
#
# NOTE: This type declaration is not enforced. During or after
#  creation of objects of this type, you may add other attributes
#  that were not declared.
#
# typename - The name of the object type
# attribute_list - A list of attribute, value pairs to serve as
#  defaults for objects of this type.
#
proc NGS_DeclareType { typename attribute_list } {
	# Create a variable that holds the default values for
	#  the tyep's attribtues	
	variable NGS_TYPEINFO_$typename
	set NGS_TYPEINFO_$typename [expand_variables $attribute_list]

}

# Returns the Soar RHS code required to construct an object of the
#  given type
#
# object_id - id of the object to construct. Use one of the 
#   create-typed-object macros to create this.
# typename - name of the type of object you want to construct
# attribute_list - (optional) A list of attribute, values to set as initial
#  values. Note that you do not need to set any attributes for which
#  you want to use default values. If you specify an attribute
#  that is also specified in the defaults list, you will override
#  the default with the value passed here. You can also include
#  attributes that are not included in the type declaration.
# add_my_type - (optional) A TCL true/false value that indicates whether
#  the my-type attribute should be created and given the value $typename.
#  The default value is "true" which is the correct value when creating
#  a new type. When adding a new type to an object, the correct value is false.
#
proc ngs-construct { object_id typename { attribute_list "" } { add_my_type true }} {

	set ret_val "($object_id"

    if { $add_my_type } {
    	lappend attribute_list my-type $typename
	}

    # Expand tags in the attribute list (prefixed with @)
    set attribute_list [ngs-expand-tags $attribute_list]

	# These are the values that were passed in (if any)
	set new_vals [expand_variables $attribute_list]

	variable NGS_TYPEINFO_$typename
	if {[info exists NGS_TYPEINFO_$typename] != 0} {
	
		# If a type was declared we want to grab any
		#  default attribute values from its type definition
		set defaults [subst \$NGS_TYPEINFO_$typename]

		# Create each of the default attribute/value pairs
		# Defaults are created via NGS_DeclareType
		dict for {key val} $defaults {
			if { $val != "" } {
				# The "type" part is a hack to allow support for inheritance
				# Type infrastructure needs more work
				if {([dict exists $new_vals $key] == 0) || ($key == "type")} {
					set ret_val "$ret_val ^$key $val"
				} 
			}
		}

	} else {
		echo "WARNING: Type $typename was not declared. Did you type the right name?"		
	}	


	# Create all of the values being set in the construction process
	dict for {key val} $new_vals {
		if { $val != "" } {
			set ret_val "$ret_val ^$key $val"
		}
	}

	# If we've actually constructed an object, then return
	#  the relevant Soar code. Otherwise, return nothing.
	if {$ret_val != "($object_id"} {
		return "$ret_val)"
	} else {
		return ""
	}

}


