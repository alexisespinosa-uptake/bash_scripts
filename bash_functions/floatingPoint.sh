#!/bin/bash
#
# Floating point number functions.
# Copied from: http://www.linuxjournal.com/content/floating-point-math-bash (float_eval, float_cond)
#              http://phodd.net/gnu-bc/bcfaq.html#bczeroes (truncTrailingZeros)
#
# The rounding function was copied from:
# http://unix.stackexchange.com/questions/89712/bash-float-to-integer
# using bc

#####################################################################
# Default scale used by float functions.
# The variable "float_scale" SHOULD be set in the calling script to have a different value
if [ -z ${float_scale+x} ]; then
   float_scale=6
fi


#####################################################################
# Truncate the trailing zeros. Downloaded (see above)

function truncTrailingZeros()
{
    local result=0
    local stat=0
    if [[ $# -gt 0 ]]; then
        result=$(echo "x=$*; scale=$float_scale; os=scale; for(scale=0;scale<=os;scale++) { if(x==x/1) {x/=1; break;}}; x" | bc -q 2>/dev/null)
        stat=$?
        if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
    fi
    echo $result
    return $stat
}

#####################################################################
# Floor to the lower integer. Mine (using the truncTrailinZeros method)

function float_floor()
{
    local result=0
    local stat=0
    if [[ $# -gt 0 ]]; then
        result=$(echo "x=$*; scale=0; x/=1; x" | bc -q 2>/dev/null)
        stat=$?
        if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
    fi
    echo $result
    return $stat
}

#####################################################################
# Ceiling to the upper integer. Mine (using the Floor function)

function float_ceil()
{
    local result=0
    local stat=0
    if [[ $# -gt 0 ]]; then
        result=$(echo "x=$*; scale=0; x/=1; x+1" | bc -q 2>/dev/null)
        stat=$?
        if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
    fi
    echo $result
    return $stat
}

#####################################################################
# Rounding to the closest integer. Copied (see above) and following Ceiling and Floor

function float_round2int()
{
    local result=0
    local stat=0
    if [[ $# -gt 0 ]]; then
        result=$(echo "x=$*; scale=0; x=(x+0.5)/1; x" | bc -q 2>/dev/null)
        stat=$?
        if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
    fi
    echo $result
    return $stat
}

#####################################################################
# Evaluate a floating point number expression. Downloaded (see above)

echo "Defining float_eval"
function float_eval()
{    
    local stat=0
    local result=0.0
    local resultTrunc=0.0
    if [[ $# -gt 0 ]]; then                
        result=$(echo "scale=${float_scale}; $*" | bc -q 2>/dev/null)
        stat=$?
        if [[ $stat -eq 0  &&  -z "$result" ]]; then stat=1; fi
    fi
    echo $result
    return $stat
}

#####################################################################
# Evaluate a floating point number conditional expression. Downloaded (see above)

function float_cond()
{
    local cond=0
    if [[ $# -gt 0 ]]; then
        cond=$(echo "$*" | bc -q 2>/dev/null)
        if [[ -z "$cond" ]]; then cond=0; fi
        if [[ "$cond" != 0  &&  "$cond" != 1 ]]; then cond=0; fi
    fi
    local stat=$((cond == 0))
    return $stat
}

#####################################################################
# Debugging messages
# Testing the definition of float_scale from the calling script
#AEG. echo "Function float_eval(), scale=${float_scale}"
