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

argument_1=( '-group' 'siteGroup' 'Specify_site_group' )
argument_2=( '-name' 'siteName' 'Site_domain_name' )
argument_3=( '-basepath' 'basePath' 'The_path_of_the_root_of_data_folder_used_by_containers' )
argument_4=( '-startuid' 'startUID' 'Define_the_range_of_ids_to_use_for_sites_,_the_default_is_9001' )
argument_5=( '-startgid' 'startGID' 'Define_the_range_of_ids_to_use_for_site_groups_,_the_default_is_9001' )
argument_6=( '-verifymode' 'verifyMode' 'Used_with_verify_command,_it_can_be_A_or_N' )
argument_7=( '-showsettings' 'showCurrentSeting' 'Show_current_settings_used_by_the_command,_it_can_be_0_or_1' )
argument_8=( '-sitemode' 'siteMode' 'Set_access_permission_to_the_home_of_a_host._it_can_be_protect_or_open' )
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
containersRestart=0
cmdArguments_1=( 'add' 'addHost' '1'  "$basePath,$startUID,$siteName,$startGID,$siteGroup" 'Add_a_new_host' )
cmdArguments_2=( 'verify' 'verifyHost' '0' "$basePath,$siteName,$siteGroup,$verifyMode" 'Verify_a_host' )
cmdArguments_3=( 'remove' 'removeHost' '1' "$basePath,$siteName" 'Remove_a_host' )
cmdArguments_4=( 'purge' 'removeHost' '1' "$basePath,$siteName,purge" 'Purge_a_host' )
cmdArguments_5=( 'chmod' 'chmodHost' '0' "$basePath,$siteName,$siteMode" 'Set_the_home_folder_permissions_for_a_host' )
cmdArguments_6=( 'cleanup' 'cleanUp' '0' "$basePath" 'Clean_up_backup_files_and_non-used_home_folders' )
cmdArguments_7=( 'list' 'listHosts' '0' "$basePath,$startUID" 'List_all_registered_hosts' )
cmdArguments_8=( 'verifyall' 'verifyAllHosts' '0' "$basePath,$startUID,$verifyMode" 'Verify_all_registered_hosts' )
cmdArguments_8=( 'help' 'helpUsage' '0' "-" 'This help' )
cmdArgumentsArray=( $(createDataList 'cmdArguments_' 8) )

function helpUsage () #@ USAGE helpUsage
{
    echo "$usageStr"
    echo "commands:"
    for cmdItem in ${cmdArgumentsArray[@]};
    do
        eval cmdName='"${'$cmdItem'[0]}"'
        eval cmdHelp='"${'$cmdItem'[4]}"'
        echo -e "\t$cmdName : ${cmdHelp//_/ }"
    done
    echo "options:"
    for argumentItem in ${argumentArray[@]};
    do
        eval argumentDirective='"${'$argumentItem'[0]}"'
        eval argumentHelp='"${'$argumentItem'[2]}"'
        echo -e "\t$argumentDirective : ${argumentHelp//_/ }"
    done

}

for cmdItem in ${cmdArgumentsArray[@]};
do
    eval cmdName='"${'$cmdItem'[0]}"'
    eval cmdCommand='"${'$cmdItem'[1]}"'
    eval cmdRestartStatus='"${'$cmdItem'[2]}"'
    eval cmdArguments='"${'$cmdItem'[3]}"'

    if [ $cmdName == ${cmd,,} ]; then
        if [ "$cmdArguments" != "${cmdArguments/,,/}" ]; then
            echo "some arguments are missing ($cmdArguments)"
            exitCode=1
        else
            eval $cmdCommand ${cmdArguments//,/ }
            exitCode=$?
            containersRestart=$cmdRestartStatus
        fi
        break
    fi
done

if [ $exitCode -eq 0 ]; then
    [ $containersRestart -eq 1 ] &&
        containersRestart 'nginx' 'php-fpm' 'bind9'
    echo -e "${BGGREEN}${WHITE}SUCCESS!${NC}"
elif [ $exitCode -eq 1 ]; then
    echo -e "${BGRED}${WHITE}FAILURE($exitCode)${NC}"
elif [ $exitCode -eq 4 ]; then
    echo -e "${BGRED}${WHITE}INVALID COMMAND${NC}"
    helpUsage
else
    echo -e "${BGBLUE}${WHITE}WARRNING($exitCode)${NC}"
fi
exit $exitCode

