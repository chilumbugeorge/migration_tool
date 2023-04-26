#!/bin/bash

RED=$'\e[1;31m'
GREEN=$'\e[1;32m'
BLUE=$'\e[1;34m'
CYAN=$'\e[1;36m'
MAG=$'\e[1;35m'
NC=$'\e[0m'

while getopts u:h:d:s:c:C:v:r:t:m:i:l: flag
do
    case "${flag}" in
        u) username=${OPTARG};;
        h) hostname=${OPTARG};;
        d) database=${OPTARG};;
        s) cluster=${OPTARG};;
        c) create=${OPTARG};;
        C) cmds=${OPTARG};;
        v) version=${OPTARG};;
        r) infdba=${OPTARG};;
        t) chg=${OPTARG};;
        m) migrate=${OPTARG};;
        i) info=${OPTARG};;
        l) list=${OPTARG};;
        \? )
           echo "Invalid Option: -$OPTARG" 1>&2
           exit 1
        ;;
    esac
done

__usage="
Usage: $(basename $0) [OPTIONS]

Options:
  -u, --username <n>              database username -u <uername>
  -h, --hostname <levels>         database hostname -h <host>
  -d, --database                  database schema name -d <db-name>
  -s, --cluster                   application service e.g. main, trades, ref etc -s <db-cluster>
  -c, --script                    file script with extension .json or .sql e.g. alter_table_employee_add_column_name.sql
  -v, --version                   to track database versions. Automatically created.
  -r, --infdba                    to track Jira infdba tickets -r <infdba>
  -t, --chg                       to track application migration version
  -C, --Command                   action control command -C [base | create | list | info | pull | push | migrate | rollback]
      base                        -C base -u <db-user> -h <db-host> -d <db-name>
      create                      -C create -s <db-cluster> -c <file-script> -v <version>
      info                        -C info -s <db-cluster> -u <db-user> -h <db-host> -d <db-name> -v <version>
      list                        -C list -s <db-cluster>
      migrate                     -C migrate -s <db-cluster> -u <db-user> -h <db-host> -d <db-name> -v <version> -r <chg> -t <infdba>
      pull                        -C pull -s <db-cluster> -u <db-user> -h <db-host> -d <db-name> 
      push                        -C pull -s <db-cluster> -u <db-user> -h <db-host> -d <db-name> 
      version                     -C version -s <db-cluster>
"


now=$(date +%Y%m%d%H%M%S)
alter_template="templates/alter.json"
clusterdir="migrations/$cluster"
versiondir="$clusterdir/$version"

if [ ! -z "$cmds" ] && [ ! -z "$cluster" ] && [ ! -z "$username" ] && [ ! -z "$hostname" ] && [ ! -z "$database" ] && [ ! -z "$create" ] && [ ! -z "$version" ] && [ ! -z "$chg" ] && [ ! -z "$infdba" ]; then
    if [ "$cmds" == "migrate" ]; then
        read -r -p "Are You Sure About Running Migration ${MAG}$create${NC}[Y/n] " input 
        case $input in
            [yY][eE][sS]|[yY]) echo "Yes"
            ;;
            [nN][oO]|[nN]) echo "No"
                exit 1
            ;;
            *)
                echo "Invalid input..."
                exit 1
            ;;
            esac

        printf "\n"
        ext="${create##*.}"
         
	read -p 'Enter DB password:' -s PASSWD
        echo
        password=$PASSWD

	if [ "$ext" == "json" ]; then
            T=$(jq -r '.table' $versiondir/$create)
            S=$(jq -r '.change' $versiondir/$create)
	    pt-online-schema-change --chunk-size 1000 -h ${hostname} --user ${username} --max-load Threads_running=1500 --critical-load Threads_running=1500 --no-drop-old-table --ask-pass --recursion-method=none --max-lag 4s --alter "${S}" D=${database},t=${T} --execute &&
            mysql -u${username} -h${hostname} -p${password} ${database} -e "INSERT INTO SCHEMA_CHANGE_LOGS VALUES(null,'$version','$chg','$infdba','$username','$T','ALTER TABLE','$create',NOW())";
	    exit 0
	elif [ "$ext" == "sql" ]; then
	    C=$(mysql -u${username} -h${hostname} -p${password} ${database} < $versiondir/$create);
                if [[ $? != 0 ]]; then
                    exit 1
                else
                    ddl_create=$(grep -ioP "(?<=create table )[^ ]+" $versiondir/$create | tr -d \( | tr '\n' ' ');
                    ddl_insert=$(grep -ioP "(?<=insert )[^ ]+" $versiondir/$create | tr -d \( | tr '\n' ' ');
                    ddl_update=$(grep -ioP "(?<=update )[^ ]+" $versiondir/$create | tr -d \( | tr '\n' ' ');
                    ddl_delete=$(grep -ioP "(?<=delete )[^ ]+" $versiondir/$create | tr -d \( | tr '\n' ' ');
                    ddl_drop=$(grep -ioP "(?<=drop table )[^ ]+" $versiondir/$create | tr -d \();
                    if [ ! -z "$ddl_create" ];then
                        echo $version

                        mysql -u${username} -h${hostname} -p${password} ${database} -e "INSERT INTO SCHEMA_CHANGE_LOGS VALUES(null,'$version','$chg','$infdba','$username','${ddl_create}','CREATE TABLE','$create',NOW())"; 2>&1 | grep -v "Warning: Using a password"

                        echo "Created Tables:" ${CYAN}$create${NC}
                        echo "Migration ${MAG}$create${NC} was executed successfully"
                        exit 0
                    elif [ ! -z "$ddl_drop" ];then
            
                        mysql -u${username} -h${hostname} -p${password} ${database} -e "INSERT INTO SCHEMA_CHANGE_LOGS VALUES(null,'$version','$chg','$infdba','$username','${ddl_drop//;}','DROP TABLE','$create',NOW())"; 2>&1 | grep -v "Warning: Using a password"


                        echo "Dropped Tables ${CYAN}$drop${NC}"
                        echo "Migration ${MAG}$create${NC} was executed successfully"
                        exit 0
                    elif [ ! -z "$ddl_insert" ];then
            
                        mysql -u${username} -h${hostname} -p${password} ${database} -e "INSERT INTO SCHEMA_CHANGE_LOGS VALUES(null,'$version','$chg','$infdba','$username','${ddl_insert//;}','INSERT','$create',NOW())"; 2>&1 | grep -v "Warning: Using a password"


                        echo "Records were inserted"
                        echo "Migration ${MAG}$create${NC} was executed successfully"
                        exit 0
                    elif [ ! -z "$ddl_update" ];then
            
                        mysql -u${username} -h${hostname} -p${password} ${database} -e "INSERT INTO SCHEMA_CHANGE_LOGS VALUES(null,'$version','$chg','$infdba','$username','${ddl_update//;}','UPDATE','$create',NOW())"; 2>&1 | grep -v "Warning: Using a password"


                        echo "Records were updated"
                        echo "Migration ${MAG}$create${NC} was executed successfully"
                        exit 0
                    elif [ ! -z "$ddl_delete" ];then
            
                        mysql -u${username} -h${hostname} -p${password} ${database} -e "INSERT INTO SCHEMA_CHANGE_LOGS VALUES(null,'$version','$chg','$infdba','$username','${ddl_delete//;}','DELETE','$create',NOW())"; 2>&1 | grep -v "Warning: Using a password"


                        echo "Records were deleted"
                        echo "Migration ${MAG}$create${NC} was executed successfully"
                        exit 0
                    else
                        echo "This DDL operation cannot be performed. Check to ensure its supported"             
                    fi
                fi  
        fi              

    else
        echo "To execute a migration, run: -C migrate -s <services-name> -v <version-name> -r <chg> -t <infdba> -c <migration> -u <db-user> -h <db-host> -d <db-name> " 
        exit 1
    fi	
elif [ ! -z "$cmds" ] && [ ! -z "$cluster" ] && [ ! -z "$username" ] && [ ! -z "$hostname" ] && [ ! -z "$database" ] && [ ! -z "$version" ]; then
    if [ "$cmds" == "info" ]; then
        #(ls -l $versiondir | awk '{print $9}')
        read -p 'Enter DB password:' -s PASSWD
        echo
        password=$PASSWD

        x=0
        while read line
        do
            A1[ $x ]=$(echo $line)
        (( x++ ))
        done < <(ls $versiondir | tr '\n' '\n')

        i=0
        mapfile result < <(mysql -u${username} -h${hostname} -p${password} ${database} -se "SELECT script FROM SCHEMA_CHANGE_LOGS" 2>&1 | grep -v "Warning: Using a password")
        while IFS=$'\t' read version
        do
            A2[ $i ]=$version
        (( i++ ))
        done  < <(mysql -u${username} -h${hostname} -p${password} ${database} -se "SELECT script FROM SCHEMA_CHANGE_LOGS" 2>&1 | grep -v "Warning: Using a password")

        A3=()
        for j in "${A1[@]}"; do
            skip=
            for k in "${A2[@]}"; do
                [[ $j == $k ]] && { skip=1; break; }
            done
            [[ -n $skip ]] || A3+=("$j")
        done

        # Display file names
        for z in "${A3[@]}"
        do
            pending=$(ls $versiondir | tr '\n' '\n' | grep $z)
            echo "${RED} Pending: ${NC}" $pending
        done

        A4=()
        for j in "${A1[@]}"; do
           skip=
           for k in "${A3[@]}"; do
              [[ $j == $k ]] && { skip=1; break; }
           done
           [[ -n $skip ]] || A4+=("$j")
        done

        # Display executed migrations
        for y in "${A4[@]}"
        do
            printf "${BLUE}Migrated: ${NC}"
            (ls $versiondir | tr '\n' '\n' | grep $y)
        done
    else
        echo "To list pending migrations, run: -C info -s <cluster> -v <version> -u <db-user> -h <db-host> -d <db-name>" 
        exit 1
    fi
elif [ ! -z "$cmds" ] && [ ! -z "$cluster" ] && [ ! -z "$username" ] && [ ! -z "$hostname" ] && [ ! -z "$database" ]; then
    init_schemas="defaults/$cluster/"
    if [ "$cmds" == "pull" ]; then

        read -p 'Enter DB password:' -s PASSWD
        echo
        password=$PASSWD

        mysqldump -u${username} -p${password}  -h${hostname} ${database} --compact --skip-comments --triggers --events --routines --set-gtid-purged=OFF > $init_schemas/init.sql &&
        echo "Data import for $database done"
	exit 0
    elif [ "$cmds" == "push" ]; then
        read -p 'Enter DB password:' -s PASSWD
        echo
        password=$PASSWD

        mysql -u${username} -p${password}  -h${hostname} ${database} < $init_schemas/$database.sql &&
        echo "Schema init for $database done"
    else
        echo "To restore data, run: -C push -s <services-name> -u <db-user> -h <db-host> -d <db-name>" 
        exit 1
    fi             
elif [ ! -z "$cmds" ] && [ ! -z "$username" ] && [ ! -z "$hostname" ] && [ ! -z "$database" ]; then
    if [ "$cmds" == "base" ]; then
        init_schemas="defaults/$cluster/"

        read -p 'Enter DB password:' -s PASSWD
        echo
        password=$PASSWD

        mysql -u${username} -p${password}  -h${hostname} ${database} < scripts/schema_change_logs.sql &&
        echo "Base SCHEMA_CHANGE_LOGS has been created"
    else
        echo "To restore data, run: -C base -s <services-name> -u <db-user> -h <db-host> -d <db-name>" 
        exit 1
    fi      
elif [ ! -z "$cmds" ] && [ ! -z "$cluster" ] && [ ! -z "$create" ] && [ ! -z "$version" ]; then
    if [ "$cmds" == "create" ]; then
        ddl_create=$(echo $create | grep -ioP create)
        ddl_alter=$(echo $create | grep -ioP alter)
        ddl_drop=$(echo $create | grep -ioP drop)

        json_script=$now"__"$create.json
        sql_script=$now"__"$create.sql

        if [[ ! -z "$ddl_create" ]]; then
            touch $versiondir/$sql_script
            echo "migration $sql_script for version $version has been created"
        elif [[ ! -z "$ddl_alter" ]]; then
            cat $alter_template > $versiondir/$json_script &&
            echo "migration $json_script has been created"
        elif [[ ! -z "$ddl_drop" ]]; then
            if [[ ! -z "$ddl_alter" ]]; then
                cat $alter_template > $versiondir/$json_script &&
                echo "migration $json_script has been created"
            else
                touch $versiondir/$sql_script
                echo "migration $sql_script has been created"
            fi
   
        else
            echo "Enter 1 to ALTER, or 2 to CREATE/DROP a Table"
            select yn in "Yes" "No"; do
            case $yn in
            Yes ) 
                cat $alter_template > $versiondir/$json_script &&
                echo "migration $json_script has been created"
            break;;
            No) 
                touch $versiondir/$sql_script
                echo "migration $sql_script has been created"
            break;;
            esac
            done
        fi   

    else
        echo "To create a new migration, run: -C create <migration-type> -s <services-name> -v <version-name>"
        exit 1
    fi
elif [ ! -z "$cmds" ] && [ ! -z "$cluster" ]; then
    if [ "$cmds" == "version" ]; then
        mkdir $clusterdir/"V__$now"
        echo "Migration version for $cluster has been created: " ${BLUE}$version${NC}
    elif [ "$cmds" == "list" ]; then
        (ls -l $versiondir | awk '{print $9}')
    else
        echo "To create a new version, run: -C version -s <cluster>"
        echo "To list existing versions, run: -C list -s <cluster>"
        exit 1
    fi
else
    echo "$__usage"
fi
