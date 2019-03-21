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

CORE_CreateMacroVar CORE_MATH_PI 3.14159265359
CORE_CreateMacroVar CORE_MATH_RAD_TO_DEG [expr 180.0 / $CORE_MATH_PI]
CORE_CreateMacroVar CORE_MATH_DEG_TO_RAD [expr $CORE_MATH_PI / 180.0]

proc MATH_Deg_to_Rad { degrees } { 
    variable CORE_MATH_PI
    return [expr $degrees * ($CORE_MATH_PI / 180.0)] 
}
proc MATH_Rad_to_Deg { radians } { 
    variable CORE_MATH_PI
    return [expr $radians * (180 / $CORE_MATH_PI)] 
}

proc MATH_Square { val } { 
    return "(* $val $val)" 
}

# Dot and cross products for 2D vectors
proc MATH_Vec_Magnitude2d { dx dy } {
    return "(sqrt (+ (* $dx $dx) (* $dy $dy)))"
}

# Dot product (by default it will not normalize the results)
# Not normalizing (or pre-normalizing the vectors) saves some computation.              
proc MATH_Vec_Dot2d { dx1 dy1 dx2 dy2 { normalize "" } } {
    variable NGS_YES
    if { $normalize == $NGS_YES } {
        return "( / [MATH_Vec_Dot2d $dx1 $dy1 $dx2 $dy2] (* [MATH_Vec_Magnitude2d $dx1 $dy1] [MATH_Vec_Magnitude2d $dx2 $dy2]))"
    } else {
        return "(+ (* $dx1 $dx2) (* $dy1 $dy2))"
    }
}
# Returns just the z component since a 2D vector cross is always in the positive or negative z direction
# Not normalizing saves some computation. Typically, you only need to know the sign of a 2D cross product
#  so you won't need to normalize the result (normalization just gives -1 or +1).
proc MATH_Vec_Cross2d { dx1 dy1 dx2 dy2 { normalize "" } } {
    variable NGS_YES
    if { $normalize == $NGS_YES } {
        return "( / [MATH_Vec_Cross2d $dx1 $dy1 $dx2 $dy2] (abs [MATH_Vec_Cross2d $dx1 $dy1 $dx2 $dy2]))"
    } else {
        return "(- (* $dx1 $dy2) (* $dy1 $dx2))"
    }
}

# Euclidian distance between two points
proc MATH_Distance2d { x1 y1 x2 y2 } {
    return "(sqrt (+ (* (- $x1 $x2) (- $x1 $x2)) (* (- $y1 $y2) (- $y1 $y2)) ))"
}

#
# p_x, p_y are the x and y coordinates of the point off of the line
#
# p1_x, p1_y are one point on the line
# p2_x, p2_y are the other point on the line
#
# A Soar-compliant mathematical expression is returned that can be used on the right hand
#  side of a Soar production. The value returned by the expression is the shortest distance
#  between the point (p_x, p_y) and the line defined by p1 and p2.
#
proc MATH_DistanceToLine2d { p_x p_y p1_x p1_y p2_x p2_y } {
    return "(/ (abs (+ (* (- $p2_y $p1_y) $p_x) (* (- $p1_x $p2_x) $p_y) (* $p2_x $p1_y) (* -1.0 (* $p2_y $p1_x)) )) [MATH_Distance2d $p1_x $p1_y $p2_x $p2_y])"

}

# f: a floating point number (constant or variable)
# returns an expression that rounds to the nearest integer
proc MATH_Round { f } {
    return "(int (+ 0.5 $f))"
}

## MATH_Sin_Deg:
## return the sine of a value/rhs-func given in degrees
proc MATH_Sin_Deg { a } {
   variable CORE_MATH_DEG_TO_RAD
   return "(sin (* $a $CORE_MATH_DEG_TO_RAD))"
}

## MATH_Cos_Deg:
## return the cosine of a value/rhs-func given in degrees
proc MATH_Cos_Deg { a } {
   variable CORE_MATH_DEG_TO_RAD
   return "(cos (* $a $CORE_MATH_DEG_TO_RAD))"
}

## MATH_Distance3dSquared:
## return the squared 3d distance between points (x0,y0,z0) and (x1,y1,z1),
## or the squared length of the vector (x0,y0,z0).
proc MATH_Distance3dSquared { x0 y0 z0 {x1 0} {y1 0} {z1 0} } {
   return "(+ (* (- $x0 $x1) (- $x0 $x1)) (* (- $y0 $y1) (- $y0 $y1)) (* (- $z0 $z1) (- $z0 $z1)))"
}

## MATH_Distance3d:
## return the 3d distance between points (x0,y0,z0) and (x1,y1,z1),
## or the length of the vector (x0,y0,z0).
proc MATH_Distance3d { x0 y0 z0 {x1 0} {y1 0} {z1 0} } {
   return "(sqrt [MATH_Distance3dSquared $x0 $y0 $z0 $x1 $y1 $z1])"
}

## MATH_DistanceEarth:
## Return the distance between two points on the idealized, spherical, Earth
## Defined by their latitudes and longitudes (in degrees)
proc MATH_DistanceEarth { lat1 long1 lat2 long2 } {
    return "[MATH_DistanceSpherical $lat1 $long1 $lat2 $long2 6378000.0]"
}


## MATH_DistanceSpherical:
## return the distance between two points on a sphere of radius R
## defined by their latitudes and longitudes (in degrees)
proc MATH_DistanceSpherical { lat1 long1 lat2 long2 radius } {
    return "(* $radius [MATH_Distance3d \
              [MATH_Sin_Deg $lat1] \
              "(* [MATH_Cos_Deg $lat1] [MATH_Cos_Deg $long1])" \
              "(* [MATH_Cos_Deg $lat1] [MATH_Sin_Deg $long1])" \
              [MATH_Sin_Deg $lat2] \
              "(* [MATH_Cos_Deg $lat2] [MATH_Cos_Deg $long2])" \
              "(* [MATH_Cos_Deg $lat2] [MATH_Sin_Deg $long2])" \
            ])"
}
