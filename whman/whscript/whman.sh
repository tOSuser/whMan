#!/bin/bash
#: Webhost Manager to use with Webhost containers
#:
#: File : whman.sh
#
#
# Nexttop 2023-2025 (nexttop.se)
# Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
#set -x

ORIGINALSCRIPT_PATH=$( dirname $(realpath "$0") )
SCRIPT_PATH=$( dirname "$0")

colormode=0
## Import libraries
[ -f $ORIGINALSCRIPT_PATH/helper.shinc ] &&
    . $ORIGINALSCRIPT_PATH/helper.shinc

[ -f $ORIGINALSCRIPT_PATH/whmanager.shinc ] &&
    . $ORIGINALSCRIPT_PATH/whmanager.shinc

declare -f isContainersUp 2>/dev/null 1>/dev/null
[ $? -ne 0 ] &&
    echo -e "${BGRED}${WHITE}Error: shinc libraries have not been loaded/found!${NC}" &&
    exit 1

isContainersUp 'nginx' 'php-fpm' 'bind9' 'whman'
[ $? -ne 0 ] &&
    echo -e "${BGRED}${WHITE}'docker' or conteiners were not found!${NC}" &&
    exit 1

## pre-default configurations
basePath=$(findBasePath nginx)
startUID=9001
startGID=9001
siteGroup=generalsite
adminMail=""
verifyMode='A'
siteMode='protect'
showCurrentSeting=1

## Import configurations
CONF_LOCALPATH=${SCRIPT_PATH}/whman.conf
CONF_PATH=/etc/whman.conf

if [ -f "$CONF_LOCALPATH" ]; then
    . ${CONF_LOCALPATH}
elif [ -f "$CONF_PATH" ]; then
    . ${CONF_PATH}
fi
#---------------------------------------
# Main
usageStr="Usage: $(basename $0) command [options]"

[ $# -lt 1 ] &&
    echo "$usageStr" &&
    exit 0

currentBasePath=$(findBasePath 'nginx' )
[ $? -eq 0 ] &&
    basePath=$currentBasePath

## Initialize values

argument_1=( '-group' 'siteGroup' )
argument_2=( '-name' 'siteName' )
argument_3=( '-basepath' 'basePath' )
argument_4=( '-startuid' 'startUID' )
argument_5=( '-startgid' 'startGID' )
argument_6=( '-verifymode' 'verifyMode' )
argument_7=( '-showsettings' 'showCurrentSeting' )
argument_8=( '-sitemode' 'siteMode' )
argumentArray=( $(createDataList 'argument_' 8) )
for argumentItem in ${argumentArray[@]};
do
    eval argumentDirective='"${'$argumentItem'[0]}"'
    eval argumentVariableName='"${'$argumentItem'[1]}"'

    nextitem=$(lookForArgument $argumentDirective "${@:2}")
    [ $? -eq 0 ] &&
        eval "$argumentVariableName=$nextitem"
done

verifyMode=${verifyMode^^}
([ $verifyMode != 'A' ] && [ $verifyMode != 'N' ]) &&
    verifyMode='A'

([ $showCurrentSeting != '0' ] && [ $showCurrentSeting != '1' ]) &&
    showCurrentSeting=1

([ "$basePath" == "" ] || [ ! -d "$basePath" ]) &&
    echo "The base path ($basePath) is invalid!" &&
    exit 1

cmd=$1

if [ $showCurrentSeting -eq 0 ]; then
    echo "Current default settings:"
    for argumentItem in ${argumentArray[@]};
    do
        eval argumentDirective='"${'$argumentItem'[0]}"'
        eval argumentVariableName='"${'$argumentItem'[1]}"'
        eval argumentVariableContent='"${'$argumentVariableName'}"'
        echo -e "\t$argumentVariableName($argumentDirective)=$argumentVariableContent"
    done
fi

exitCode=4
cmdArguments_1=( 'add' 'addHost' "$basePath,$startUID,$siteName,$startGID,$siteGroup" )
cmdArguments_2=( 'verify' 'verifyHost' "$basePath,$siteName,$siteGroup,$verifyMode" )
cmdArguments_3=( 'remove' 'removeHost' "$basePath,$siteName" )
cmdArguments_4=( 'purge' 'removeHost' "$basePath,$siteName,purge" )
cmdArguments_5=( 'setmode' 'setHostMode' "$siteName,$siteMode" )
cmdArguments_6=( 'cleanup' 'cleanUp' "$basePath" )
cmdArguments_7=( 'list' 'listSites' "$basePath,$startUID" )
cmdArguments_8=( 'verifyall' 'verifyAllHosts' "$basePath,$startUID,$verifyMode" )
cmdArgumentsArray=( $(createDataList 'cmdArguments_' 8) )
for cmdItem in ${cmdArgumentsArray[@]};
do
    eval cmdName='"${'$cmdItem'[0]}"'
    eval cmdCommand='"${'$cmdItem'[1]}"'
    eval cmdArguments='"${'$cmdItem'[2]}"'

    if [ $cmdName == ${cmd,,} ]; then
        if [ "$cmdArguments" != "${cmdArguments/,,/}" ]; then
            echo "some arguments are missing ($cmdArguments)"
            exitCode=1
        else
            eval $cmdCommand ${cmdArguments//,/ }
            exitCode=$?
        fi
        break
    fi
done

if [ $exitCode -eq 0 ]; then
    echo -e "${BGGREEN}${WHITE}SUCCESS!${NC}"
elif [ $exitCode -eq 1 ]; then
    echo -e "${BGRED}${WHITE}FAILURE($exitCode)${NC}"
elif [ $exitCode -eq 4 ]; then
    echo -e "${BGRED}${WHITE}INVALID COMMAND${NC}"
else
    echo -e "${BGBLUE}${WHITE}WARRNING($exitCode)${NC}"
fi
exit $exitCode

