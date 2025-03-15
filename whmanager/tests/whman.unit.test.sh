#!/bin/bash
#: Webhost manager test
#:
#: File : whman.test.sh
#
#
# Nexttop 2023-2025 (nexttop.se)
# Maintenance nexttop -> hossein a.t. (osxx.com)
#---------------------------------------
## Import libraries
TESTORIGINALSCRIPT_PATH=$( dirname $(realpath "$0") )
ORIGINALSCRIPT_PATH=$TESTORIGINALSCRIPT_PATH
SCRIPT_PATH=$( dirname "$0")

## Import libraries
[ -f $TESTORIGINALSCRIPT_PATH/helper.shinc ] &&
    . $TESTORIGINALSCRIPT_PATH/helper.shinc
[ -f $TESTORIGINALSCRIPT_PATH/whmanager.shinc ] &&
    . $TESTORIGINALSCRIPT_PATH/whmanager.shinc

[ -f $TESTORIGINALSCRIPT_PATH/whman.overloader.shinc ] &&
    . $TESTORIGINALSCRIPT_PATH/whman.overloader.shinc

#*
#*  @description    Test setup
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
function testSetup()
{
    [ ! -d "$TESTORIGINALSCRIPT_PATH/testdata" ] &&
        bash -c "cp -r $TESTORIGINALSCRIPT_PATH/../testdata $TESTORIGINALSCRIPT_PATH/"
    [ ! -d "$TESTORIGINALSCRIPT_PATH/templates" ] &&
        bash -c "cp -r $TESTORIGINALSCRIPT_PATH/../templates $TESTORIGINALSCRIPT_PATH/"
    return 0
}

#*
#*  @description    Test teardown
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
function testTeardown()
{
    return 0
}

#*
#*  @description    Test isExist
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_ISEXIST ()
{
    data_1=( 'sourcepath' '1' )
    data_2=( 'sourcepath' '0' )
    data_3=( 'sourcepath' '0' )
    arrTestData=( $(mockCreateDataList 'data_' 3) )

    for testData in ${arrTestData[@]};
    do
        ADDMOCK test $(mockCreateParamList {1,1,1,0,0,}) $(mockCreateParamList {'-',})

        eval sourcePath='"${'$testData'[0]}"'
        eval expectedExitCode='"${'$testData'[1]}"'

        output=$(isExist $sourcePath)
        isExistExitCode=$?

        echo "$sourcePath, $expectedExitCode <-> $isExistExitCode"
        [ $expectedExitCode -ne $isExistExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls test:5
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test createBackup
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_CREATEBACKUP ()
{
    ADDMOCK isExist $(mockCreateParamList {1,1,1,0,1,1,}) $(mockCreateParamList {'-',})
    ADDMOCK cp $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK mv $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})

    currentDate=$(date +"%d-%m-%Y")
    data_1=( 'sourcefile' 'cp' '1' "sourcefile-$currentDate")
    data_2=( 'sourcefile' 'cp' '0' "sourcefile-$currentDate")
    data_3=( 'sourcefile' 'mv' '1' "sourcefile-$currentDate.1")
    data_4=( 'sourcefile' 'mv' '0' "sourcefile-$currentDate")
    data_5=( 'sourcefile' 'invalid' '1' "sourcefile-$currentDate")
    arrTestData=( $(mockCreateDataList 'data_' 5) )

    for testData in ${arrTestData[@]};
    do
        eval sourceFilePath='"${'$testData'[0]}"'
        eval backoupMethod='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedOutput='"${'$testData'[3]}"'

        output=$(createBackup $backoupMethod $sourceFilePath)
        createBackupExitCode=$?

        echo "$sourceFilePath, $expectedExitCode <-> $createBackupExitCode"
        [ $expectedExitCode -ne $createBackupExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $createBackupExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "cp//$expectedOutput")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls isExist:6 cp:2 mv:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test isContainersUp
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_ISCONTAINERSUP ()
{
    ADDMOCK which $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','docker-path',})
    ADDMOCK docker $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','false','true',})

    data_1=( 'mycontainer' '1' '-' )
    data_2=( 'mycontainer' '1' '-' )
    data_3=( 'mycontainer' '1' '-' )
    data_4=( 'mycontainer' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )

    for testData in ${arrTestData[@]};
    do
        eval container='"${'$testData'[0]}"'
        eval expectedExitCode='"${'$testData'[1]}"'
        eval expectedOutput='"${'$testData'[2]}"'

        output=$(isContainersUp $container)
        isContainersUpExitCode=$?

        echo "$container, $expectedExitCode <-> $isContainersUpExitCode"
        [ $expectedExitCode -ne $isContainersUpExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls which:4 docker:3
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test findBasePath
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_FINDBASEPATH ()
{
    inspectOutput="[{bind<:>/path/webhost-dev/mycontainer/conf.d<:>/etc/mycontainer/conf.d<:>rw<:>true<:>rprivate}]"
    cutOutput="/path/webhost-dev/mycontainer/conf.d"
    ADDMOCK docker $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',$inspectOutput,})
    ADDMOCK cut $(mockCreateParamList {0,1,0,}) $(mockCreateParamList {$cutOutput,'-',$cutOutput,})
    ADDMOCK isDirExist $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})

    data_1=( 'mycontainer' '1' '-' )
    data_2=( 'mycontainer' '1' '-' )
    data_3=( 'mycontainer' '1' '-' )
    data_4=( 'mycontainer' '0' '/path/webhost-dev' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )

    for testData in ${arrTestData[@]};
    do
        eval container='"${'$testData'[0]}"'
        eval expectedExitCode='"${'$testData'[1]}"'
        eval expectedOutput='"${'$testData'[2]}"'

        output=$(findBasePath $container)
        findBasePathExitCode=$?

        echo "$container, $expectedExitCode <-> $findBasePathExitCode"
        [ $expectedExitCode -ne $findBasePathExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        [ $findBasePathExitCode -eq 0 ] && [ $output != $expectedOutput ] &&
            echo "The output is not matched! ($output != $expectedOutput)" &&
            return 1
    done

    ExpectCalls isDirExist:2 docker:4 cut:4
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test getContainerIP
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_GETCONTAINERIP ()
{
    inspectOutput="10.10.10.1"
    ADDMOCK docker $(mockCreateParamList {1,0,0,}) $(mockCreateParamList {'-','invalidip',$inspectOutput,})

    data_1=( 'mycontainer' '1' '-' )
    data_2=( 'mycontainer' '1' '-' )
    data_3=( 'mycontainer' '0' $inspectOutput )
    arrTestData=( $(mockCreateDataList 'data_' 3) )

    for testData in ${arrTestData[@]};
    do
        eval container='"${'$testData'[0]}"'
        eval expectedExitCode='"${'$testData'[1]}"'
        eval expectedOutput='"${'$testData'[2]}"'

        output=$(getContainerIP $container)
        getContainerIPExitCode=$?

        echo "$container, $expectedExitCode <-> $getContainerIPExitCode"
        [ $expectedExitCode -ne $getContainerIPExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        [ $getContainerIPExitCode -eq 0 ] && [ $output != $expectedOutput ] &&
            echo "The output is not matched! ($output != $expectedOutput)" &&
            return 1
    done

    ExpectCalls docker:3
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test containerExec
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_CONTAINEREXEC ()
{
    ADDMOCK docker $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','result',})

    data_1=( 'mycontainer' '1' '-' )
    data_2=( 'mycontainer' '0' 'result' )
    arrTestData=( $(mockCreateDataList 'data_' 2) )

    for testData in ${arrTestData[@]};
    do
        eval container='"${'$testData'[0]}"'
        eval expectedExitCode='"${'$testData'[1]}"'
        eval expectedOutput='"${'$testData'[2]}"'

        output=$(containerExec $container mycommand myparam1 myparam2)
        containerExecExitCode=$?

        echo "$container, $expectedExitCode <-> $containerExecExitCode"
        [ $expectedExitCode -ne $containerExecExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        [ $containerExecExitCode -eq 0 ] && [ $output != $expectedOutput ] &&
            echo "The output is not matched! ($output != $expectedOutput)" &&
            return 1
    done

    ExpectCalls docker:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test containersRestart
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_CONTAINERSRESTART ()
{
    ADDMOCK isContainersUp $(mockCreateParamList {1,1,0,0,0,}) $(mockCreateParamList {'-',})
    ADDMOCK docker $(mockCreateParamList {1,0,1,0,1,0,0,}) $(mockCreateParamList {'-',})

    data_1=( 'mycontainer' '1' '-' )
    data_2=( 'mycontainer' '0' '-' )
    data_3=( 'mycontainer' '1' '-' )
    data_4=( 'mycontainer' '1' '-' )
    data_5=( 'mycontainer' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 5) )

    for testData in ${arrTestData[@]};
    do
        eval containerName='"${'$testData'[0]}"'
        eval expectedExitCode='"${'$testData'[1]}"'

        output=$(containersRestart $containerName)
        containersRestartExitCode=$?

        echo "$containerName, $expectedExitCode <-> $containersRestartExitCode"
        [ $expectedExitCode -ne $containersRestartExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls isContainersUp:5 docker:7
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test startIDToRegEx
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_STARTIDTOREGEX ()
{
    data_1=( 'invalid9001' '1' 'null' )
    data_2=( '9001' '0' '[9][0-9][0-9][0-9]' )
    data_3=( '810' '0' '[8][1-9][0-9]' )
    arrTestData=( $(mockCreateDataList 'data_' 3) )

    for testData in ${arrTestData[@]};
    do
        eval startUID='"${'$testData'[0]}"'
        eval expectedExitCode='"${'$testData'[1]}"'
        eval expectedRegEx='"${'$testData'[2]}"'
        output=$(startIDToRegEx $startUID)
        startIDToRegExExitCode=$?

        echo "$startUID, $expectedExitCode <-> $startIDToRegExExitCode, $expectedRegEx <-> $output"
        [ $startIDToRegExExitCode -ne $expectedExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
        [ $output != $expectedRegEx ] &&
            echo "The output is not matched!" &&
            return 1
    done

    return 0
}

#*
#*  @description    Test findUID
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_FINDUID ()
{
    ADDMOCK isFileExist $(mockCreateParamList {1,1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail

    passwdFilePath=$TESTORIGINALSCRIPT_PATH/testdata/webhost/etc/passwd

    data_1=( 'invalid' 'invalid' '2' '-' )
    data_2=( 'invalid' 'sitea' '2' '-' )
    data_3=( "$passwdFilePath" 'sitea' '0' '9001' )
    data_4=( "$passwdFilePath" 'invalid' '1' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )

    for testData in ${arrTestData[@]};
    do
        eval passwdFilePath='"${'$testData'[0]}"'
        eval userName='"${'$testData'[1]}"'
        eval expectedExitcode='"${'$testData'[2]}"'
        eval expectedUID='"${'$testData'[3]}"'

        output=$(findUID $passwdFilePath $userName)
        findUIDExitcode=$?

        echo "$userName, $expectedExitcode <-> $findUIDExitcode, $expectedUID"
        [ $findUIDExitcode -ne $expectedExitcode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        [ $findUIDExitcode -eq 0 ] && [ $output != $expectedUID ] &&
            echo "The output is not matched! $output != $expectedUID" &&
            return 1
    done

    ExpectCalls isFileExist:4 grep:2 cut:2 tail:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test findFirstAvailableUID
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_FINDFIRSTAVAILABLEUID ()
{
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail

    passwdFilePath=$TESTORIGINALSCRIPT_PATH/testdata/webhost/etc/passwd

    data_1=( 'invalid' 'invalid' '1' '0' )
    data_2=( $passwdFilePath 'invalid' '1' '0' )
    data_3=( $passwdFilePath '7001' '0' '7001' )
    data_4=( $passwdFilePath '9001' '0' '9003' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )

    for testData in ${arrTestData[@]};
    do
        eval passwdFilePath='"${'$testData'[0]}"'
        eval startUID='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedAvailableUID='"${'$testData'[3]}"'

        output=$(findFirstAvailableUID $passwdFilePath $startUID)
        findFirstAvailableUIDExitCode=$?

        echo "$startUID, $expectedExitCode <-> $findFirstAvailableUIDExitCode, $expectedAvailableUID <-> $output"
        [ $findFirstAvailableUIDExitCode -ne $expectedExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        [ $findFirstAvailableUIDExitCode -eq 0 ] && [ $output != $expectedAvailableUID ] &&
            echo "The output is not matched! ($output <#> $expectedAvailableUID)" &&
            return 1
    done

    ExpectCalls grep:2 cut:2 tail:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test addUserToDb
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDUSERTODB ()
{
    ADDMOCK putToFile $(mockCreateParamList {0,1,}) $(mockCreateParamList {'-',})

    data_1=( 'userDBFile' '9001' 'sitea' '9001' '0' )
    data_2=( 'userDBFile' '9001' 'invalid' '9001' '1' )
    arrTestData=( $(mockCreateDataList 'data_' 2) )

    for testData in ${arrTestData[@]};
    do
        eval userDBFile='"${'$testData'[0]}"'
        eval userID='"${'$testData'[1]}"'
        eval userName='"${'$testData'[2]}"'
        eval groupID='"${'$testData'[3]}"'
        eval expectedExitCode='"${'$testData'[4]}"'

        output=$(addUserToDb $userDBFile $userID $userName $groupID)
        addUserToDbExitCode=$?

        echo "$userName, $expectedExitCode <-> $addUserToDbExitCode"
        [ $expectedExitCode -ne $addUserToDbExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls putToFile:2
    [ $? -ne 0 ] &&
        return 1
    return 0
}

#*
#*  @description    Test findGID
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_FINDGID ()
{
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail

    groupDbPath=$TESTORIGINALSCRIPT_PATH/testdata/webhost/etc/group

    data_1=( 'invalid' 'invalid' '2' '-' )
    data_2=( 'invalid' 'generalsite' '2' '-' )
    data_3=( $groupDbPath 'generalsite' '0' '9001' )
    data_4=( $groupDbPath 'invalid' '1' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )

    for testData in ${arrTestData[@]};
    do
        eval groupFilePath='"${'$testData'[0]}"'
        eval groupName='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedGID='"${'$testData'[3]}"'

        output=$(findGID  $groupFilePath $groupName)
        findGIDExitCode=$?

        echo "$groupName, $expectedExitCode <-> $findGIDExitCode, $expectedGID <-> $output"
        [ $findGIDExitCode -ne $expectedExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        [ $findGIDExitCode -lt 1 ] &&
            [ $output != $expectedGID ] &&
                echo "The output is not matched!" &&
                return 1
    done

    ExpectCalls grep:2 cut:2 tail:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test findFirstAvailableGID
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_FINDFIRSTAVAILABLEGID ()
{
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail

    groupDbPath=$TESTORIGINALSCRIPT_PATH/testdata/webhost/etc/group

    data_1=( 'invalid' 'invalid' '1' '0' )
    data_2=( 'invalid' '7001' '1' '0' )
    data_3=( $groupDbPath '9001' '0' '9003' )
    data_4=( $groupDbPath '8001' '0' '8001' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )

    for testData in ${arrTestData[@]};
    do
        eval groupFilePath='"${'$testData'[0]}"'
        eval startGID='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedAvailableGID='"${'$testData'[3]}"'

        output=$(findFirstAvailableGID $groupFilePath $startGID)
        findFirstAvailableGIDExitCode=$?

        echo "$startGID, $expectedExitCode <-> $findFirstAvailableGIDExitCode, $expectedAvailableGID <-> $output"
        [ $findFirstAvailableGIDExitCode -ne $expectedExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        [ $findFirstAvailableGIDExitCode -eq 0 ] && [ $output != $expectedAvailableGID ] &&
            echo "The output is not matched!" &&
            return 1
    done

    ExpectCalls grep:2 cut:2 tail:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test addGroupToDb
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDGROUPTODB ()
{
    ADDMOCK putToFile $(mockCreateParamList {0,1}) $(mockCreateParamList {'-',})

    data_1=( 'userDBFile' '9001' 'sitea' '0' )
    data_2=( 'userDBFile' '9001' 'invalid' '1' )
    arrTestData=( $(mockCreateDataList 'data_' 2) )

    for testData in ${arrTestData[@]};
    do
        eval groupDBFile='"${'$testData'[0]}"'
        eval groupID='"${'$testData'[1]}"'
        eval groupName='"${'$testData'[2]}"'
        eval expectedExitCode='"${'$testData'[3]}"'

        output=$(addGroupToDb $groupDBFile $groupID $groupName)
        addGroupToDbExitCode=$?

        echo "$userName, $expectedExitCode <-> $addGroupToDbExitCode"
        [ $expectedExitCode -ne $addGroupToDbExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls putToFile:2
    [ $? -ne 0 ] &&
        return 1
    return 0
}

#*
#*  @description    Test addUserToGroupDb
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDUSERTOGROUPDB ()
{
    ADDMOCK isFileExist $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK grep $(mockCreateParamList {1,1,0,}) $(mockCreateParamList {'-','-','generalsite:x:9001:','generalsite:x:9001:sitea',})
    ADDMOCK tail $(mockCreateParamList {1,1,0,}) $(mockCreateParamList {'-','-','generalsite:x:9001:','generalsite:x:9001:sitea',})
    ADDMOCK cut $(mockCreateParamList {0,}) $(mockCreateParamList {'-','sitea,',})
    ADDMOCK sed $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    
    data_1=( 'invalid' 'sitea' 'generalsite' '1' '' '' )
    data_2=( 'groupDBFile' 'invalid' 'invalid' '1' '' '' )
    data_3=( 'groupDBFile' 'sitea' 'generalsite' '0' 'generalsite:x:9001:' 'generalsite:x:9001:sitea' )
    data_4=( 'groupDBFile' 'siteb' 'generalsite' '0' 'generalsite:x:9001:sitea' 'generalsite:x:9001:sitea,siteb' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )
 
    for testData in ${arrTestData[@]};
    do
        eval groupDBFile='"${'$testData'[0]}"'
        eval userName='"${'$testData'[1]}"'
        eval groupName='"${'$testData'[2]}"'
        eval expectedExitCode='"${'$testData'[3]}"'
        eval expectedMockLogCut='"${'$testData'[4]}"'
        eval expectedMockLogSed='"${'$testData'[5]}"'
        output=$(addUserToGroupDb $groupDBFile $userName $groupName)
        addUserToGroupDbExitCode=$?

        echo "$groupDBFile, $userName, $groupName, $expectedExitCode <-> $addUserToGroupDbExitCode"
        [ $expectedExitCode -ne $addUserToGroupDbExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $addUserToGroupDbExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "-cut//$expectedMockLogCut" "sed//$expectedMockLogSed")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls isFileExist:0 grep:4 tail:4 cut:2 sed:2
    [ $? -ne 0 ] &&
        return 1
    return 0
}

#*
#*  @description    Test addUser
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDUSER ()
{
    ADDMOCK findUID $(mockCreateParamList {0,1,}) $(mockCreateParamList {'9001','-',})
    ADDMOCK findGID $(mockCreateParamList {1,1,1,0,}) $(mockCreateParamList {'-','-','-','9001',})
    ADDMOCK findFirstAvailableGID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9002',})
    ADDMOCK addGroupToDb $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK findFirstAvailableUID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9001',})
    ADDMOCK addUserToDb $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK addUserToGroupDb $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' )
    data_2=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' )
    data_3=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' )
    data_4=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' )
    data_5=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' )
    data_6=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' )
    data_7=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '0' )
    arrTestData=( $(mockCreateDataList 'data_' 7) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval startUID='"${'$testData'[1]}"'
        eval userName='"${'$testData'[2]}"'
        eval startGID='"${'$testData'[3]}"'
        eval groupName='"${'$testData'[4]}"'
        eval expectedExitCode='"${'$testData'[5]}"'

        output=$(addUser $basePath $startUID $userName $startGID $groupName)
        addUserExitCode=$?

        echo "$basePath, $startUID, $userName, $startGID, $groupName, $expectedExitCode <-> $addUserExitCode"
        [ $expectedExitCode -ne $addUserExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls findGID:6 findFirstAvailableGID:3 addGroupToDb:2 findUID:7 findFirstAvailableUID:4 addUserToDb:3 addUserToGroupDb:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test addConfNginx
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDCONFNGINX ()
{
    ADDMOCK isFileExist $(mockCreateParamList {0,1,1,1,1,1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK cp $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' 'sitea' 'generalsite' 'templatesTemporaryPath' '1' '-' )
    data_2=( 'basePath' 'sitea' 'generalsite' 'templatesTemporaryPath' '1' 'default.conf' )
    data_3=( 'basePath' 'sitea' 'generalsite' 'templatesTemporaryPath' '0' 'default.conf' )
    data_4=( 'basePath' 'sitea' 'generalsite' 'templatesTemporaryPath' '0' 'generalsite.conf' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )
 
    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval userName='"${'$testData'[1]}"'
        eval groupName='"${'$testData'[2]}"'
        eval templatesTemporaryPath='"${'$testData'[3]}"'
        eval expectedExitCode='"${'$testData'[4]}"'
        eval expectedMockLogCp='"${'$testData'[5]}"'

        output=$(addConfNginx $basePath $userName $groupName $templatesTemporaryPath)
        addConfNginxExitCode=$?

        echo "$basePath, $userName, $groupName, $templatesTemporaryPath, $expectedExitCode <-> $addConfNginxExitCode"
        [ $expectedExitCode -ne $addConfNginxExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $addConfNginxExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "cp//$expectedMockLogCp")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls isFileExist:7 cp:3
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test addConfPhpfpm
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDCONFPHPFPM ()
{
    ADDMOCK isFileExist $(mockCreateParamList {0,1,1,1,1,1,0,1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK cp $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK grep $(mockCreateParamList {0,1,}) $(mockCreateParamList {'-',})
    ADDMOCK putToFile $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK cat $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' '9001' 'sitea' '9001' 'generalsite' 'templatesTemporaryPath' '1' '-' '-' '-' )
    data_2=( 'basePath' '9001' 'sitea' '9001' 'generalsite' 'templatesTemporaryPath' '1' '-' '-' '-' )
    data_3=( 'basePath' '9001' 'sitea' '9001' 'generalsite' 'templatesTemporaryPath' '1' '-' '-' '-' )
    data_4=( 'basePath' '9001' 'sitea' '9001' 'generalsite' 'templatesTemporaryPath' '1' '-' '-' '-' )
    data_5=( 'basePath' '9001' 'sitea' '9001' 'generalsite' 'templatesTemporaryPath' '0' '-' '-' 'default.conf' )
    arrTestData=( $(mockCreateDataList 'data_' 5) )
 
    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval userID='"${'$testData'[1]}"'
        eval userName='"${'$testData'[2]}"'
        eval groupID='"${'$testData'[3]}"'
        eval groupName='"${'$testData'[4]}"'
        eval templatesTemporaryPath='"${'$testData'[5]}"'
        eval expectedExitCode='"${'$testData'[6]}"'
        eval expectedMockLogCp='"${'$testData'[7]}"'
        eval expectedMockLogGrep='"${'$testData'[8]}"'
        eval expectedMockLogCat='"${'$testData'[9]}"'

        output=$(addConfPhpfpm $basePath $userID $userName $groupID $groupName $templatesTemporaryPath)
        addConfPhpfpmExitCode=$?

        echo "$basePath, $userID, $userName, $groupID, $groupName, $templatesTemporaryPath, $expectedExitCode <-> $addConfPhpfpmExitCode"
        [ $expectedExitCode -ne $addConfPhpfpmExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $addConfPhpfpmExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "cp//$expectedMockLogCp" "grep//$expectedMockLogGrep" "cat//$expectedMockLogCat")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls isFileExist:9 cp:4 grep:2 cat:1 putToFile:1
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test addConfBind9
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDCONFBIND9 ()
{
    ADDMOCK isFileExist $(mockCreateParamList {0,1,1,0,1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK grep $(mockCreateParamList {0,1,0}) $(mockCreateParamList {'-',})
    ADDMOCK cat $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK putToFile $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK cp $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    
    data_1=( 'basePath' 'sitea' 'generalsite' 'templatesTemporaryPath' '0' '-' '-' '-' )
    data_2=( 'basePath' 'sitea' 'generalsite' 'templatesTemporaryPath' '0' '-' '-' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 2) )
 
    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval userName='"${'$testData'[1]}"'
        eval groupName='"${'$testData'[2]}"'
        eval templatesTemporaryPath='"${'$testData'[3]}"'
        eval expectedExitCode='"${'$testData'[4]}"'
        eval expectedMockLogCp='"${'$testData'[5]}"'
        eval expectedMockLogGrep='"${'$testData'[6]}"'
        eval expectedMockLogCat='"${'$testData'[7]}"'

        output=$(addConfBind9 $basePath $userName $groupName $templatesTemporaryPath)
        addConfBind9ExitCode=$?

        echo "$basePath, $userName,  $groupName, $templatesTemporaryPath, $expectedExitCode <-> $addConfBind9ExitCode"
        [ $expectedExitCode -ne $addConfBind9ExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $addConfBind9ExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "cp//$expectedMockLogCp" "grep//$expectedMockLogGrep" "cat//$expectedMockLogCat")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls isFileExist:8 cp:1 grep:2 cat:1 putToFile:1
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test addConfs
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDCONFS ()
{
    ADDMOCK findUID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9001',})
    ADDMOCK findGID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9001',})
    ADDMOCK find $(mockCreateParamList {0,}) $(mockCreateParamList {'file1',})
    ADDMOCK sed $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK addConfNginx $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK addConfPhpfpm $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK addConfBind9 $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' 'sitea' 'generalsite' 'templatesTemporaryPath' '1' '-' '-' )
    data_2=( 'basePath' 'sitea' 'generalsite' 'templatesTemporaryPath' '1' '-' '-' )
    data_3=( 'basePath' 'sitea' 'generalsite' 'templatesTemporaryPath' '0' '-' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 3) )
 
    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval userName='"${'$testData'[1]}"'
        eval groupName='"${'$testData'[2]}"'
        eval templatesTemporaryPath='"${'$testData'[3]}"'
        eval expectedExitCode='"${'$testData'[4]}"'
        eval expectedMockLogFind='"${'$testData'[5]}"'
        eval expectedMockLogSed='"${'$testData'[6]}"'

        output=$(addConfs $basePath $userName $groupName $templatesTemporaryPath)
        addConfsExitCode=$?

        echo "$basePath, $userName,  $groupName, $templatesTemporaryPath, $expectedExitCode <-> $addConfsExitCode"
        [ $expectedExitCode -ne $addConfsExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $addConfsExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "find//$expectedMockLogFind" "sed//$expectedMockLogSed")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls findUID:3 findGID:2 find:1 sed:1 addConfNginx:1 addConfPhpfpm:1 addConfBind9:1
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test createHome
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_CREATEHOME ()
{
    ADDMOCK findUID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9001',})
    ADDMOCK findGID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9001',})
    ADDMOCK stat $(mockCreateParamList {0,}) $(mockCreateParamList {'generalsite',})
    ADDMOCK mkdir $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK cp $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK chown $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK isFileExist $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK isDirExist $(mockCreateParamList {1,0,1,0,1,0,0,1,0,0,}) $(mockCreateParamList {'-',})
    ADDMOCK initializeSiteHome $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_2=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_3=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_4=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_5=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_6=( 'basePath' 'sitea' 'generalsite' '1' 'default' )
    data_7=( 'basePath' 'sitea' 'generalsite' '1' 'generalsite' )
    data_8=( 'basePath' 'sitea' 'generalsite' '0' 'generalsite' )
    arrTestData=( $(mockCreateDataList 'data_' 8) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval userName='"${'$testData'[1]}"'
        eval groupName='"${'$testData'[2]}"'
        eval expectedExitCode='"${'$testData'[3]}"'
        eval expectedMockLogCp='"${'$testData'[4]}"'

        output=$(createHome $basePath $userName $groupName)
        createHomeExitCode=$?

        echo "$basePath, $userName,  $groupName, $expectedExitCode <-> $createHomeExitCode"
        [ $expectedExitCode -ne $createHomeExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $createHomeExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "cp//$expectedMockLogCp")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls findUID:8 findGID:7 stat:2 mkdir:4 cp:3 chown:0 isFileExist:2 isDirExist:9
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test updateHomeOwner
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_UPDATEHOMEOWNER ()
{
    ADDMOCK findUID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9001',})
    ADDMOCK findGID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9001',})
    ADDMOCK isDirExist $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK isContainersUp $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK containerExec $(mockCreateParamList {1,0,1,0,1,0,0,1,0,0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_2=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_3=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_4=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_5=( 'basePath' 'sitea' 'generalsite' '1' '-' )
    data_6=( 'basePath' 'sitea' 'generalsite' '0' '/home/sitea' )
    arrTestData=( $(mockCreateDataList 'data_' 6) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval userName='"${'$testData'[1]}"'
        eval groupName='"${'$testData'[2]}"'
        eval expectedExitCode='"${'$testData'[3]}"'
        eval expectedMockLogContainerExec='"${'$testData'[4]}"'

        output=$(updateHomeOwner $basePath $userName $groupName)
        updateHomeOwnerExitCode=$?

        echo "$basePath, $userName,  $groupName, $expectedExitCode <-> $updateHomeOwnerExitCode"
        [ $expectedExitCode -ne $updateHomeOwnerExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $updateHomeOwnerExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "containerExec//$expectedMockLogContainerExec")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls findUID:6 findGID:5 isDirExist:4 isContainersUp:3 containerExec:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test addHost
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDHOST ()
{
    ADDMOCK isDirExist $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK addUser $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK mktemp $(mockCreateParamList {0,}) $(mockCreateParamList {'ttpath',})
    ADDMOCK cp $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK addConfs $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK rm $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK createHome $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK updateHomeOwner $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' '-' )
    data_2=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' '-' )
    data_3=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' '-' )
    data_4=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' '-' )
    data_5=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '1' '-' )
    data_6=( 'basePath' '9001' 'sitea' '9001' 'generalsite' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 6) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval startUID='"${'$testData'[1]}"'
        eval userName='"${'$testData'[2]}"'
        eval startGID='"${'$testData'[3]}"'
        eval groupName='"${'$testData'[4]}"'
        eval expectedExitCode='"${'$testData'[5]}"'
        eval expectedMockLogRm='"${'$testData'[6]}"'

        output=$(addHost $basePath $startUID $userName $startGID $groupName)
        addHostExitCode=$?

        echo "$basePath, $startUID, $userName, $startGID, $groupName, $expectedExitCode <-> $addHostExitCode"
        [ $expectedExitCode -ne $addHostExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $addHostExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "rm//$expectedMockLogRm")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls addUser:5 isDirExist:10 cp:4 addConfs:3 rm:3 createHome:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test addHost
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_VERIFYHOST ()
{
    ADDMOCK isDirExist $(mockCreateParamList {1,}) $(mockCreateParamList {'-',})
    ADDMOCK isFileExist $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK isContainersUp $(mockCreateParamList {0,}) $(mockCreateParamList {'true',})
    ADDMOCK containerExec $(mockCreateParamList {0,0,0,0,}) $(mockCreateParamList {'sitea','generalsite',})
    ADDMOCK grep $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

    basePath='basepath'
    userName=sitea
    groupName=generalsite
    output=$(verifyHost $basePath $userName $groupName 'A')
    verifyHostExitCode=$?

    [ $verifyHostExitCode -eq 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    ExpectCalls isDirExist:1 isFileExist:13 containerExec:0 grep:13
    [ $? -ne 0 ] &&
        return 1

    RESETMOCKS

    ADDMOCK isDirExist $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK isFileExist $(mockCreateParamList {1,1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK isContainersUp $(mockCreateParamList {0,}) $(mockCreateParamList {'true',})
    ADDMOCK containerExec $(mockCreateParamList {0,0,0,0,}) $(mockCreateParamList {'sitea','generalsite',})
    ADDMOCK grep $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

    userName=sitea
    groupName=generalsite
    output=$(verifyHost $basePath $userName $groupName 'A')
    verifyHostExitCode=$?

    [ $verifyHostExitCode -eq 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    ExpectCalls isDirExist:1 isFileExist:13 containerExec:2 grep:11
    [ $? -ne 0 ] &&
        return 1

    RESETMOCKS

    return 0
}

#*
#*  @description    Test setHostMode
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_SETHOSTMODE ()
{
    ADDMOCK isContainersUp $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK containerExec $(mockCreateParamList {1,0,1,0,0,0,0,1,0,0,0,0,0,0,}) $(mockCreateParamList {'-','-','-','-','siteb','-','sitea','-','-','sitea','-','-','sitea','-',})

    data_1=( 'sitea' 'protect' '1' '-' )
    data_2=( 'sitea' 'protect' '1' '-' )
    data_3=( 'sitea' 'protect' '1' '-' )
    data_4=( 'sitea' 'protect' '1' '-' )
    data_5=( 'sitea' 'protect' '1' '-' )
    data_6=( 'sitea' 'protect' '0' '700' )
    data_7=( 'sitea' 'open' '0' '777' )
    arrTestData=( $(mockCreateDataList 'data_' 7) )

    for testData in ${arrTestData[@]};
    do
        eval siteName='"${'$testData'[0]}"'
        eval siteNewMode='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedMockLogContainerExec='"${'$testData'[3]}"'
        
        output=$(setHostMode $siteName $siteNewMode)
        setHostModeExitCode=$?

        lastCallInfo=$(mockGetCallInfo "containerExec")
        echo "$siteName, $siteNewMode, $expectedExitCode <-> $setHostModeExitCode,'$lastCallInfo'"
        [ $expectedExitCode -ne $setHostModeExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $setHostModeExitCode -eq 0 ]; then
            expectExtraInfo=$(ExpectOutputs "containerExec//$expectedMockLogContainerExec")
            ExpectOutputsExitcode=$?
            [ "$expectExtraInfo" != "" ] &&
                echo -e "$expectExtraInfo"
            [ $ExpectOutputsExitcode -ne 0 ] &&
                return 1
        fi
    done

    ExpectCalls isContainersUp:7 containerExec:14
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test removeConfNginx
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_REMOVECONFNGINX ()
{
    ADDMOCK isFileExist $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK rm $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})

    data_1=( 'sitea' '2' '-' )
    data_2=( 'sitea' '1' '-' )
    data_3=( 'sitea' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 3) )

    for testData in ${arrTestData[@]};
    do
        eval siteName='"${'$testData'[0]}"'
        eval expectedExitCode='"${'$testData'[1]}"'

        output=$(removeConfNginx $siteName)
        removeConfNginxExitCode=$?

        echo "$siteName, $expectedExitCode <-> $removeConfNginxExitCode"
        [ $expectedExitCode -ne $removeConfNginxExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls isFileExist:3 rm:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test removeConfPhpfpm
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_REMOVECONFPHPFPM ()
{
    ADDMOCK findUID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9001',})
    ADDMOCK isFileExist $(mockCreateParamList {1,1,0,0,1,0,1,0,1,0,0,}) $(mockCreateParamList {'-',})
    ADDMOCK createBackup $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK grep $(mockCreateParamList {1,0,1,0,0,}) $(mockCreateParamList {'-',})
    ADDMOCK sed $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK rm $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' 'sitea' '1' '-' )
    data_2=( 'basePath' 'sitea' '2' '-' )
    data_3=( 'basePath' 'sitea' '1' '-' )
    data_4=( 'basePath' 'sitea' '2' '-' )
    data_5=( 'basePath' 'sitea' '2' '-' )
    data_6=( 'basePath' 'sitea' '2' '-' )
    data_7=( 'basePath' 'sitea' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 7) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval siteName='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'

        output=$(removeConfPhpfpm $basePath $siteName)
        removeConfPhpfpmExitCode=$?

        echo "$siteName, $expectedExitCode <-> $removeConfPhpfpmExitCode"
        [ $expectedExitCode -ne $removeConfPhpfpmExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls findUID:7 isFileExist:11 createBackup:5 grep:7 sed:5 rm:1
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test removeUser
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_REMOVEUSER ()
{
    ADDMOCK findUID $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','9001',})
    ADDMOCK grep $(mockCreateParamList {1,1,0,0,0,}) $(mockCreateParamList {'-','-','-','-','grepresult'})
    ADDMOCK createBackup $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK sed $(mockCreateParamList {1,0}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' 'sitea' '1' '-' )
    data_2=( 'basePath' 'sitea' '2' '-' )
    data_3=( 'basePath' 'sitea' '2' '-' )
    data_4=( 'basePath' 'sitea' '1' '-' )
    data_5=( 'basePath' 'sitea' '1' '-' )
    data_6=( 'basePath' 'sitea' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 6) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval userName='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'

        output=$(removeUser $basePath $userName)
        removeUserExitCode=$?

        echo "$userName, $expectedExitCode <-> $removeUserExitCode"
        [ $expectedExitCode -ne $removeUserExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls findUID:6 grep:8 createBackup:4 sed:3
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test removeConfBind9
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_REMOVECONFBIND9 ()
{
    ADDMOCK isFileExist $(mockCreateParamList {1,1,1,0,1,1,0,0,1,1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK grep $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','result',})
    ADDMOCK createBackup $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK sed $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK rm $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' 'sitea' '2' '-' )
    data_2=( 'basePath' 'sitea' '2' '-' )
    data_3=( 'basePath' 'sitea' '1' '-' )
    data_4=( 'basePath' 'sitea' '2' '-' )
    data_5=( 'basePath' 'sitea' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 5) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval siteName='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'

        output=$(removeConfBind9 $basePath $siteName)
        removeConfBind9ExitCode=$?

        echo "$siteName, $expectedExitCode <-> $removeConfBind9ExitCode"
        [ $expectedExitCode -ne $removeConfBind9ExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls isFileExist:13 grep:6 createBackup:4 sed:4 rm:1
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test removeHost
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_REMOVEHOST ()
{
    ADDMOCK removeConfNginx $(mockCreateParamList {1,2,0,}) $(mockCreateParamList {'-',})
    ADDMOCK removeConfPhpfpm $(mockCreateParamList {1,2,0,}) $(mockCreateParamList {'-',})
    ADDMOCK removeUser $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK removeConfBind9 $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK setHostMode $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK isDirExist $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK createBackup $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK isContainersUp $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK containerExec $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' 'sitea' '5' '-' )
    data_2=( 'basePath' 'sitea' '4' '-' )
    data_3=( 'basePath' 'sitea' '0' '-' )
    data_4=( 'basePath' 'sitea' '0' '-' )
    data_5=( 'basePath' 'sitea' '0' '-' )
    data_6=( 'basePath' 'sitea' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 6) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval siteName='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'

        output=$(removeHost $basePath $siteName)
        removeHostExitCode=$?

        echo "$siteName, $expectedExitCode <-> $removeHostExitCode"
        [ $expectedExitCode -ne $removeHostExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls removeConfNginx:6 removeConfPhpfpm:6 removeUser:6 removeConfBind9:6 setHostMode:6 isDirExist:6 createBackup:6
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test chmodHost
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_CHMODHOST ()
{
    return 0
}

#*
#*  @description    Test cleanUp
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_CLEANUP ()
{
    ADDMOCK isDirExist $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK find $(mockCreateParamList {0,}) $(mockCreateParamList {'file1\nfile2',})
    ADDMOCK rm $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK isContainersUp $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK basename $(mockCreateParamList {0,}) $(mockCreateParamList {'basename',})
    ADDMOCK containerExec $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})

    data_1=( 'basePath' '1' '-' )
    data_2=( 'basePath' '2' '-' )
    data_3=( 'basePath' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 3) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval expectedExitCode='"${'$testData'[1]}"'

        output=$(cleanUp $basePath)
        cleanUpExitCode=$?

        echo "$basePath, $expectedExitCode <-> $cleanUpExitCode"
        [ $expectedExitCode -ne $cleanUpExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls isDirExist:17 find:17 rm:30 isContainersUp:3 basename:4 containerExec:4
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test listHosts
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_LISTHOSTS ()
{
    ADDMOCK isFileExist $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-',})
    ADDMOCK grep $(mockCreateParamList {0,1,}) $(mockCreateParamList {'siteb:x:9002:9002:siteb:home:false','-'})
    ADDMOCK cut
    ADDMOCK sort

    data_1=( 'basePath' '9001' '1' '-' )
    data_2=( 'basePath' '9001' '0' 'siteb' )
    data_3=( 'basePath' '9101' '1' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 3) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval startUID='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedOutput='"${'$testData'[3]}"'

        output=$(listHosts $basePath $startUID)
        listHostsExitCode=$?

        echo "$basePath, $expectedExitCode <-> $listHostsExitCode"
        [ $expectedExitCode -ne $listHostsExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $listHostsExitCode -eq 0 ]; then
            [ $output != $expectedOutput ] &&
                return 1
        fi
    done

    ExpectCalls isFileExist:3 grep:2 cut:2 sort:2
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test verifyAllHosts
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_VERIFYALLHOSTS ()
{
    ADDMOCK listHosts $(mockCreateParamList {0,}) $(mockCreateParamList {'sitea\nsiteb',})
    ADDMOCK findUserGroup $(mockCreateParamList {1,0,}) $(mockCreateParamList {'-','wordpress'})
    ADDMOCK verifyHost $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK sort

    data_1=( 'basePath' '9001' 'A' '0' '-' )
    arrTestData=( $(mockCreateDataList 'data_' 1) )

    for testData in ${arrTestData[@]};
    do
        eval basePath='"${'$testData'[0]}"'
        eval startUID='"${'$testData'[1]}"'
        eval verifyMode='"${'$testData'[2]}"'
        eval expectedExitCode='"${'$testData'[3]}"'

        output=$(verifyAllHosts $basePath $startUID $verifyMode)
        verifyAllHostsExitCode=$?

        echo "$basePath, $expectedExitCode <-> $verifyAllHostsExitCode"
        [ $expectedExitCode -ne $verifyAllHostsExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1
    done

    ExpectCalls listHosts:1 findUserGroup:2 verifyHost:1
    [ $? -ne 0 ] &&
        return 1

    return 0

}

#*
#*  @description    Test whman
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*

function TEST_WHMAN ()
{
    return 0
}

# Main - run tests
#---------------------------------------
testGroup=""
#testGroup=WORKING

TEST_CASES=( $(grep -P -i -A1 "^#@TEST\s*$testGroup" $0 | grep '^\s*function' | cut -d' ' -f2) )

exitCode=0
$(testSetup)
for testCase in "${TEST_CASES[@]}"
do
    TESTWORK_DIR=$(bash -c "mktemp -d")
    export TESTWORK_TEMPORARYFOLDER=$TESTWORK_DIR

    echo -e "\n$testCase"

    echo "[RUN]"
    exitCode=1
    $testCase
    exitCode=$?
    [ $exitCode -ne 0 ] &&
        echo "[FAILED]" &&
        exitCode=1 &&
        break

    echo "[PASSED]"

    RESETMOCKS
    unset TESTWORK_TEMPORARYFOLDER
    bash -c "rm -r \"$TESTWORK_DIR\""
done
$(testTeardown)

[ $exitCode -ne 0 ] &&
    exit 1

exit 0
