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
#*  @description    Test an invalid basepath
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDHOST_INVALID_BASEPATH ()
{
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail

    basePath=invalid
    startUID=9001
    startGID=9001
    userName=sitea
    groupName=generalsite

    output=$(addHost $basePath $startUID $userName $startGID $groupName)
    addHostExitCode=$?
    [ $addHostExitCode -eq 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    ExpectCalls grep:0 cut:0 tail:0
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test invalid passwd and group dbs
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDHOST_INVALID_DB ()
{
    #Test case 1
    ADDMOCK isFileExist $(mockCreateParamList {2,2,}) $(mockCreateParamList {'-',})
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail

    basePath=$TESTORIGINALSCRIPT_PATH/testdata/webhost
    startUID=9001
    startGID=9001
    userName=sitea
    groupName=generalsite

    output=$(addHost $basePath $startUID $userName $startGID $groupName)
    addHostExitCode=$?
    [ $addHostExitCode -eq 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    ExpectCalls isFileExist:2 grep:0 cut:0 tail:0
    [ $? -ne 0 ] &&
        return 1

    RESETMOCKS

    #Test case 2
    ADDMOCK isFileExist $(mockCreateParamList {2,0,}) $(mockCreateParamList {'-',})
    ADDMOCK findFirstAvailableGID $(mockCreateParamList {0,}) $(mockCreateParamList {'9003',})
    ADDMOCK addGroupToDb $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail

    output=$(addHost $basePath $startUID $userName $startGID $groupName)
    addHostExitCode=$?
    [ $addHostExitCode -eq 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    ExpectCalls isFileExist:2 grep:1 cut:1 tail:1
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test a given group does not exist, but user has already added
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDHOST_NEWGROUP_EXISTINGUSER ()
{
    ADDMOCK putToFile $(mockCreateParamList {0,}) $(mockCreateParamList {'-',})
    ADDMOCK addUserToGroupDb $(mockCreateParamList {1,}) $(mockCreateParamList {'-',})
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail

    basePath=$TESTORIGINALSCRIPT_PATH/testdata/webhost
    startUID=9001
    startGID=9001
    userName=sitea
    groupName=newgroup

    output=$(addHost $basePath $startUID $userName $startGID $groupName)
    addHostExitCode=$?
    [ $addHostExitCode -eq 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    ExpectCalls putToFile:0 addUserToGroupDb:0 grep:1 cut:1 tail:1
    [ $? -ne 0 ] &&
        return 1

    return 0
}

#*
#*  @description    Test adding a new host who does not exist
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_ADDHOST ()
{
    # Add a new host to a group who does not exist
    #----
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail
    ADDMOCK sed
    ADDMOCK cp
    ADDMOCK cat
    ADDMOCK find
    ADDMOCK mkdir
    ADDMOCK which $(mockCreateParamList {0,}) $(mockCreateParamList {'docker-path',})
    ADDMOCK docker $(mockCreateParamList {0,0,}) $(mockCreateParamList {'true','1.1.1.1'})

    basePath=$TESTORIGINALSCRIPT_PATH/testdata/webhost
    startUID=9001
    startGID=9001
    userName=sitec
    siteName=$userName
    groupName=newgroup

    output=$(addHost $basePath $startUID $siteName $startGID $groupName)
    addHostExitCode=$?
    [ $addHostExitCode -ne 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    expectExtraInfo=$(ExpectOutput "grep" "^sitec:.:.*:.*$" '1')
    ExpectOutputExitcode=$?
    [ "$expectExtraInfo" != "" ] &&
        echo -e "$expectExtraInfo"
    [ $ExpectOutputExitcode -ne 0 ] &&
        return 1

    expectExtraInfo=$(ExpectOutput "grep" "^newgroup:.:.*:.*$" '2')
    ExpectOutputExitcode=$?
    [ "$expectExtraInfo" != "" ] &&
        echo -e "$expectExtraInfo"
    [ $ExpectOutputExitcode -ne 0 ] &&
        return 1


    expectExtraInfo=$(ExpectOutput "sed" "s/newgroup:x:9003:/newgroup:x:9003:sitec/g" '1')
    ExpectOutputExitcode=$?
    [ "$expectExtraInfo" != "" ] &&
        echo -e "$expectExtraInfo"
    [ $ExpectOutputExitcode -ne 0 ] &&
        return 1

    expectExtraInfo=$(ExpectOutputs "grep//^newgroup:.:.*:.*$" "grep//etc/group")
    ExpectOutputsExitcode=$?
    [ "$expectExtraInfo" != "" ] &&
        echo -e "$expectExtraInfo"
    [ $ExpectOutputsExitcode -ne 0 ] &&
        return 1

    ExpectCalls grep:14 cut:11 tail:11 sed:12 cp:5 cat:3 mkdir:1 which:1 docker:2
    [ $? -ne 0 ] &&
        return 1

    RESETMOCKS

    # Add a new host to a group who exists
    #----
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK tail
    ADDMOCK sed
    ADDMOCK cp
    ADDMOCK cat
    ADDMOCK find
    ADDMOCK mkdir
    ADDMOCK which $(mockCreateParamList {0,}) $(mockCreateParamList {'docker-path',})
    ADDMOCK docker $(mockCreateParamList {0,0,}) $(mockCreateParamList {'true','1.1.1.1'})

    userName=sited
    siteName=$userName
    groupName=newgroup

    output=$(addHost $basePath $startUID $siteName $startGID $groupName)
    addHostExitCode=$?
    [ $addHostExitCode -ne 0 ] &&
        echo -e "---\n$output\n---\n" &&
        return 1

    expectExtraInfo=$(ExpectOutput "grep" "^sited:.:.*:.*$" '1')
    ExpectOutputExitcode=$?
    [ "$expectExtraInfo" != "" ] &&
        echo -e "$expectExtraInfo"
    [ $ExpectOutputExitcode -ne 0 ] &&
        return 1

    expectExtraInfo=$(ExpectOutput "grep" "^newgroup:.:.*:.*$" '2')
    ExpectOutputExitcode=$?
    [ "$expectExtraInfo" != "" ] &&
        echo -e "$expectExtraInfo"
    [ $ExpectOutputExitcode -ne 0 ] &&
        return 1

    expectExtraInfo=$(ExpectOutput "sed" "s/newgroup:x:9003:sitec/newgroup:x:9003:sitec,sited/g" '1')
    ExpectOutputExitcode=$?
    [ "$expectExtraInfo" != "" ] &&
        echo -e "$expectExtraInfo"
    [ $ExpectOutputExitcode -ne 0 ] &&
        return 1

    expectExtraInfo=$(ExpectOutputs "grep//^newgroup:.:.*:.*$" "grep//etc/group")
    ExpectOutputsExitcode=$?
    [ "$expectExtraInfo" != "" ] &&
        echo -e "$expectExtraInfo"
    [ $ExpectOutputsExitcode -ne 0 ] &&
        return 1

    ExpectCalls grep:13 cut:10 tail:10 sed:12 cp:5 cat:3 mkdir:1 which:1 docker:2
    [ $? -ne 0 ] &&
        return 1

    RESETMOCKS

    # Verify the added host
    #----
    ADDMOCK which $(mockCreateParamList {0,}) $(mockCreateParamList {'docker-path',})
    ADDMOCK docker $(mockCreateParamList {0,0,0,0,0,0,}) $(mockCreateParamList {'true','sitec','newgroup','true','sited','newgroup',})

    userName=sitec
    siteName=$userName
    VerifyOutput=$(verifyHost $basePath $siteName $groupName)
    verifyHostExitcode=$?
    [ $verifyHostExitcode -ne 0 ] &&
        echo -e "$VerifyOutput" &&
        return 1
    userName=sited
    siteName=$userName
    VerifyOutput=$(verifyHost $basePath $siteName $groupName)
    verifyHostExitcode=$?
    [ $verifyHostExitcode -ne 0 ] &&
        echo -e "$VerifyOutput" &&
        return 1

    ExpectCalls which:2 docker:6

    return 0
}

#*
#*  @description    Test removing a host/user
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_REMOVEHOST ()
{
    # Add hosts
    #----
    basePath=$TESTORIGINALSCRIPT_PATH/testdata/webhost
    startUID=9101
    startGID=9101

    data_1=( 'site1' 'newgroup1' '0' 'grep:14,cut:11,tail:11,sed:12,cp:5,cat:3,mkdir:1,which:1,docker:2' )
    data_2=( 'site2' 'newgroup1' '0' 'grep:13,cut:10,tail:10,sed:12,cp:5,cat:3,mkdir:1,which:1,docker:2' )
    data_3=( 'site3' 'newgroup2' '0' 'grep:14,cut:11,tail:11,sed:12,cp:5,cat:3,mkdir:1,which:1,docker:2' )
    data_4=( 'site1' 'newgroup2' '1' 'grep:1,cut:1,tail:1,sed:0,cp:0,cat:0,mkdir:0,which:0,docker:0' )
    data_5=( 'site4' 'newgroup1' '0' 'grep:13,cut:10,tail:10,sed:12,cp:5,cat:3,mkdir:1,which:1,docker:2' )
    arrTestData=( $(mockCreateDataList 'data_' 5) )

    for testData in ${arrTestData[@]};
    do
        eval siteName='"${'$testData'[0]}"'
        eval groupName='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedAddExpectCalls='"${'$testData'[3]}"'

        ADDMOCK grep
        ADDMOCK cut
        ADDMOCK tail
        ADDMOCK sed
        ADDMOCK cp
        ADDMOCK cat
        ADDMOCK find
        ADDMOCK mkdir
        ADDMOCK which $(mockCreateParamList {0,}) $(mockCreateParamList {'docker-path',})
        ADDMOCK docker $(mockCreateParamList {0,0,}) $(mockCreateParamList {'true','1.1.1.1'})

        echo "Add host ($siteName, $groupName)"
        output=$(addHost $basePath $startUID $siteName $startGID $groupName)
        addHostExitCode=$?
        [ $addHostExitCode -ne $expectedExitCode ] &&
            echo -e "---\n$output\n---\n" &&
            return 1

        if [ $expectedAddExpectCalls != '-' ]; then
            eval ExpectCalls ${expectedAddExpectCalls//,/ }
            [ $? -ne 0 ] &&
                return 1
        fi

        RESETMOCKS
    done

    # Verify hosts
    #----
    data_1=( 'site1' 'newgroup1' '0' 'which:1,docker:3,grep:13,cut:3,tail:3' )
    data_2=( 'site2' 'newgroup1' '0' 'which:1,docker:3,grep:13,cut:3,tail:3' )
    data_3=( 'site3' 'newgroup2' '0' 'which:1,docker:3,grep:13,cut:3,tail:3' )
    data_4=( 'site1' 'newgroup2' '1' 'which:1,docker:3,grep:13,cut:3,tail:3' )
    data_5=( 'site4' 'newgroup1' '0' 'which:1,docker:3,grep:13,cut:3,tail:3' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )

    for testData in ${arrTestData[@]};
    do
        eval siteName='"${'$testData'[0]}"'
        eval groupName='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedVerifyExpectCalls='"${'$testData'[3]}"'

        ADDMOCK which $(mockCreateParamList {0,}) $(mockCreateParamList {'docker-path',})
        ADDMOCK docker $(mockCreateParamList {0,0,0,0,}) $(mockCreateParamList {'true',$siteName,$groupName,})
        ADDMOCK grep
        ADDMOCK cut
        ADDMOCK tail

        echo "Verify host ($siteName, $groupName)"
        VerifyOutput=$(verifyHost $basePath $siteName $groupName 'A')
        verifyHostExitcode=$?
        [ $verifyHostExitcode -ne $expectedExitCode ] &&
            echo -e "$VerifyOutput" &&
            return 1

        if [ $expectedVerifyExpectCalls != '-' ]; then
            eval ExpectCalls ${expectedVerifyExpectCalls//,/ }
            [ $? -ne 0 ] &&
                return 1
        fi

        RESETMOCKS
    done

    # Count current available sites
    #----
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK sort
    echo "Count current available sites"
    listHostsOutput=$(listHosts $basePath $startUID)
    hostCounter=0
    for siteName in $listHostsOutput;
    do
        echo "Found host : $siteName"
        hostCounter=$(($hostCounter+1))
    done
    [ $hostCounter -ne 4 ] &&
        echo -e "Available hosts is not $hostCounter != 4!" &&
        return 1
    ExpectCalls grep:1 cut:1 sort:1
    [ $? -ne 0 ] &&
        return 1

    RESETMOCKS

    # Remove hosts
    #----
    data_1=( 'site1' 'newgroup1' '0' 'rm:3,grep:9,sed:7,cp:5,mv:1,cat:0,tail:2,cut:2,which:2,docker:5' )
    data_2=( 'site3' 'newgroup2' '0' 'rm:3,grep:9,sed:7,cp:5,mv:1,cat:0,tail:2,cut:2,which:2,docker:5' )
    data_3=( 'site1' 'newgroup2' '4' 'rm:0,grep:4,sed:0,cp:0,mv:0,cat:0,tail:2,cut:2,which:2,docker:5' )
    data_4=( 'site4' 'newgroup1' '0' 'rm:3,grep:9,sed:5,cp:5,mv:1,cat:0,tail:2,cut:2,which:2,docker:5' )
    arrTestData=( $(mockCreateDataList 'data_' 4) )

    for testData in ${arrTestData[@]};
    do
        eval siteName='"${'$testData'[0]}"'
        eval groupName='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedVerifyExpectCalls='"${'$testData'[3]}"'

        ADDMOCK rm
        ADDMOCK grep
        ADDMOCK sed
        ADDMOCK cp
        ADDMOCK mv
        ADDMOCK cat
        ADDMOCK tail
        ADDMOCK cut
        ADDMOCK which $(mockCreateParamList {0,}) $(mockCreateParamList {'docker-path',})
        ADDMOCK docker $(mockCreateParamList {0,0,0,0,0,}) $(mockCreateParamList {'true','-',$siteName,'-','true','-',})

        echo "Remove host ($siteName)"

        output=$(removeHost $basePath $siteName)
        removeHostExitCode=$?
        [ $removeHostExitCode -ne $expectedExitCode ] &&
            echo -e "---\n$removeHostExitCode : $output\n---\n" &&
            return 1

        if [ $expectedVerifyExpectCalls != '-' ]; then
            eval ExpectCalls ${expectedVerifyExpectCalls//,/ }
            [ $? -ne 0 ] &&
                return 1
        fi

        RESETMOCKS
    done

    # Verify removed hosts
    #----
    data_1=( 'site1' 'newgroup1' '0' 'which:0,docker:0,grep:5,cut:1,tail:1' )
    data_2=( 'site2' 'newgroup1' '1' 'which:0,docker:0,grep:5,cut:1,tail:1' )
    data_3=( 'site3' 'newgroup2' '0' 'which:0,docker:0,grep:5,cut:1,tail:1' )
    data_4=( 'site1' 'newgroup2' '0' 'which:0,docker:0,grep:5,cut:1,tail:1' )
    data_5=( 'site4' 'newgroup1' '0' 'which:0,docker:0,grep:5,cut:1,tail:1' )
    arrTestData=( $(mockCreateDataList 'data_' 5) )

    for testData in ${arrTestData[@]};
    do
        eval siteName='"${'$testData'[0]}"'
        eval groupName='"${'$testData'[1]}"'
        eval expectedExitCode='"${'$testData'[2]}"'
        eval expectedVerifyExpectCalls='"${'$testData'[3]}"'

        ADDMOCK which $(mockCreateParamList {0,}) $(mockCreateParamList {'docker-path',})
        ADDMOCK docker $(mockCreateParamList {0,0,0,0,}) $(mockCreateParamList {'true',$siteName,$groupName,})
        ADDMOCK grep
        ADDMOCK cut
        ADDMOCK tail

        echo "Verify removed host ($siteName, $groupName)"

        VerifyOutput=$(verifyHost $basePath $siteName $groupName 'N')
        verifyHostExitcode=$?
        [ $verifyHostExitcode -ne $expectedExitCode ] &&
            echo -e "$VerifyOutput" &&
            return 1

        if [ $expectedVerifyExpectCalls != '-' ]; then
            eval ExpectCalls ${expectedVerifyExpectCalls//,/ }
            [ $? -ne 0 ] &&
                return 1
        fi

        RESETMOCKS
    done

    # Count current available sites
    #----
    ADDMOCK grep
    ADDMOCK cut
    ADDMOCK sort
    echo "Count current available sites"
    listHostsOutput=$(listHosts $basePath $startUID)
    hostCounter=0
    for siteName in $listHostsOutput;
    do
        echo "Found host : $siteName"
        hostCounter=$(($hostCounter+1))
    done
    [ $hostCounter -ne 1 ] &&
        echo -e "Available hosts is not $hostCounter != 1!" &&
        return 1
    ExpectCalls grep:1 cut:1 sort:1
    [ $? -ne 0 ] &&
        return 1

    RESETMOCKS

    # Cleanup
    #----
    ADDMOCK find
    ADDMOCK rm
    ADDMOCK which $(mockCreateParamList {0,}) $(mockCreateParamList {'docker-path',})
    ADDMOCK docker $(mockCreateParamList {0,0,}) $(mockCreateParamList {'true','-',})

    echo "Cleanup"
    listHostsOutput=$(cleanUp $basePath)

    ExpectCalls find:6 rm:15 which:1 docker:4
    [ $? -ne 0 ] &&
        return 1

    RESETMOCKS

    return 0
}

#*
#*  @description    Test set a host mode (protect/open)
#*
#*  @param
#*
#*  @return            0 SUCCESS, > 0 FAILURE
#*
#@TEST
function TEST_WHMAN_SETHOSTMODE ()
{

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
