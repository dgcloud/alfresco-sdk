#set( $symbol_dollar = '$' )
@ECHO OFF

SET COMPOSE_FILE_PATH=%CD%\target\classes\docker\docker-compose.yml

IF [%M2_HOME%]==[] (
    SET MVN_EXEC=mvn
)

IF NOT [%M2_HOME%]==[] (
    SET MVN_EXEC=%M2_HOME%\bin\mvn
)

IF [%1]==[] (
    echo "Usage: %0 {build_start|start|stop|purge|tail|reload_share|reload_acs|build_test|test}"
    GOTO END
)

IF %1==build_start (
    CALL :down
    CALL :build
    CALL :start
    CALL :tail
    GOTO END
)
IF %1==start (
    CALL :start
    CALL :tail
    GOTO END
)
IF %1==stop (
    CALL :down
    GOTO END
)
IF %1==purge (
    CALL:down
    CALL:purge
    GOTO END
)
IF %1==tail (
    CALL :tail
    GOTO END
)
IF %1==reload_share (
    CALL :build_share
    CALL :start_share
    CALL :tail
    GOTO END
)
IF %1==reload_acs (
    CALL :build_acs
    CALL :start_acs
    CALL :tail
    GOTO END
)
IF %1==build_test (
    CALL :down
    CALL :build
    CALL :start
    CALL :test
    CALL :tail_all
    CALL :down
    GOTO END
)
IF %1==test (
    CALL :test
    GOTO END
)
echo "Usage: %0 {build_start|start|stop|purge|tail|reload_share|reload_acs|build_test|test}"
:END
EXIT /B %ERRORLEVEL%

:start
    docker volume create ${rootArtifactId}-acs-volume
    docker volume create ${rootArtifactId}-db-volume
    docker volume create ${rootArtifactId}-ass-volume
    docker-compose -f "%COMPOSE_FILE_PATH%" up --build -d
EXIT /B 0
:start_share
    docker-compose -f "%COMPOSE_FILE_PATH%" up --build -d ${rootArtifactId}-share
EXIT /B 0
:start_acs
    docker-compose -f "%COMPOSE_FILE_PATH%" up --build -d ${rootArtifactId}-acs
EXIT /B 0
:down
    docker-compose -f "%COMPOSE_FILE_PATH%" down
EXIT /B 0
:build
    docker rmi alfresco-content-services-${rootArtifactId}:development
    docker rmi alfresco-share-${rootArtifactId}:development
	call %MVN_EXEC% clean install -DskipTests
EXIT /B 0
:build_share
    docker-compose -f "%COMPOSE_FILE_PATH%" kill ${rootArtifactId}-share
    docker-compose -f "%COMPOSE_FILE_PATH%" rm -f ${rootArtifactId}-share
    docker rmi alfresco-share-${rootArtifactId}:development
	call %MVN_EXEC% clean install -DskipTests -pl ${rootArtifactId}-share-jar
EXIT /B 0
:build_acs
    docker-compose -f "%COMPOSE_FILE_PATH%" kill ${rootArtifactId}-acs
    docker-compose -f "%COMPOSE_FILE_PATH%" rm -f ${rootArtifactId}-acs
    docker rmi alfresco-content-services-${rootArtifactId}:development
	call %MVN_EXEC% clean install -DskipTests -pl ${rootArtifactId}-platform-jar
EXIT /B 0
:tail
    docker-compose -f "%COMPOSE_FILE_PATH%" logs -f
EXIT /B 0
:tail_all
    docker-compose -f "%COMPOSE_FILE_PATH%" logs --tail="all"
EXIT /B 0
:test
    call %MVN_EXEC% verify -pl integration-tests
EXIT /B 0
:purge
    docker volume rm ${rootArtifactId}-acs-volume
    docker volume rm ${rootArtifactId}-db-volume
    docker volume rm ${rootArtifactId}-ass-volume
EXIT /B 0