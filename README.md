The new migration tool was developed in-house by the DevOps team to help primarily with schema migrations across environments. The tool is just a git repo that can be clone.

The new migration tool was developed in-house by the DevOps team to help primarily with schema migrations across environments. The tool is just a git repo that can be clone.

Repo: git@github.com:AylaNetworks/ayla-schema-migrations.git
Terminology: 

    Version: This basically means the db version which will be tracked by the DevOps team

    Migration: A task to be executed which is part of a version. A version can have multiple migrations.

Using the Tool

Below are some common commands for the tool.
cd to the local dir where you cloned your migration tool repo
cd /path/to/migratio_tool_repo
Create new local branch
git checkout -b <local-branch-name>

e.g., git checkout -b rules_srv_add_index_su314
Create Version  e.g, new version for ads (device) service
aylamig.sh -C version -s <service-name> 

e.g., aylamig.sh -C version -s ads , or ./aylamig.sh -C version -s rules

 
Check the version name
./aylamig.sh -C list -s <service-name>

e.g., ./aylamig.sh -C list -s ads

Or you can just ls the migrations dir like this:
ls -l migrations/<service-name>/

e.g., ls -l /migrations/ads

Copy the latest version folder that was just created here, as we are going to use it below to create a migration file as the value for -v . All versions start with V__20...
Create a migration
aylamig.sh -C create -s <service-name> -c <migration-description> -v <version-name>

To add a column to a table, you can run for example aylamig.sh -C create -s ads -c alter_table_tb1_add_column_title -v V__20221024060659

or to add an index to a table, you can run something like

aylamig.sh -C create -s ads -c alter_table_tb1_add_index_idx_col1_col2 -v V__20221024060659

NOTE: for the migration name, give a description that demonstrates what you want to do clearly just like a git commit. Always prefix with alter, create, drop, insert , update , delete . A version can have multiple migration files, which you can view using the next command below:

./aylamig.sh -C list -s <service-name> -v <version-name> 
View Migrations files in a specific version
./aylamig.sh -C list -s <service-name> -v <version-name>

e.g., ./aylamig.sh -C list -s ads -v V__20220823100033
Create Git Merge Request
git add -A
git commit -m "msg about what you did here"
git push    # or git push --set-upstream origin <local-branch-name>

This should create a MR request that you now need to edit from your browser. The link to your MR will 

look something like this once you push your changes from your local branch. In the example below, my local branch is rules_srv_add_index_su3:
root@qadelta:/opt/mysql/ayla-schema-migrations$ git push --set-upstream origin rules_srv_add_index_su314
Warning: Permanently added the ECDSA host key for IP address '140.82.112.3' to the list of known hosts.
Enumerating objects: 8, done.
Counting objects: 100% (8/8), done.
Delta compression using up to 2 threads
Compressing objects: 100% (5/5), done.
Writing objects: 100% (6/6), 544 bytes | 544.00 KiB/s, done.
Total 6 (delta 2), reused 0 (delta 0)
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
remote: 
remote: Create a pull request for 'rules_srv_add_index_su314' on GitHub by visiting:
remote:      https://github.com/AylaNetworks/ayla-schema-migrations/pull/new/rules_srv_add_index_su314
remote: 

So the https url above is what you need to copy into your web browser and add a fitting description there. The MR page will look like this:



---------- DBA PART 2

Using the Tool

 

Step 1: Review Merge Request (MR) from Engineers

So once the Engineers create a ticket and also a merge request (MR) with files including DDL/DML commands to make changes on the DB, the DevOps have to review these changes to ensure the syntax and the proposed changes are ok before approving and merging the MR. 

NOTE: Make sure the Mr is associated with a specific ticket. Ideally, you want engineers to first create a ticket so DevOps can review the SQL commands there and approve before they even create a MR. After that, the engineers will create a MR that might look like this: https://github.com/AylaNetworks/ayla-schema-migrations/pull/8/files, and DevOps can do a final review and merge the MR.

 

Step 2: Identifying Migrations files to Execute

cd to the local dir whe migration tool is located as root. For the DevOps, its located on every environments bastions on /opt/mysql/ayla-schema-migrations . For USDV, you can run without root access, but not the case for any other environment. No reason for this, so feel free to change if you so wish.

The make sure you have the latest version:

git pull

Then check for latest version of a particular service in the MR

ls -l /opt/mysql/ayla-schema-migrations/migrations/<service-name>

check for the version that matched version in the MR provided by the engineers. So on the MR, go to tab Files Changed , and if you click or put a link to the modified file as shown below, you can get the version number there, which always starts with V__20... .

Another way is to just ls -l the migrations for a service using the terminal as show above and look for the latest version created, and you can compare the files and SQL statements in that version to the ones included in the Jira ticket.
cobalt@usdv:~$ ls -l /opt/mysql/ayla-schema-migrations/migrations/msg
total 16
drwxrwxr-x 2 cobalt cobalt 4096 Sep  7 07:36 V__20220712002636
drwxrwxr-x 2 cobalt cobalt 4096 Sep  7 07:36 V__20220823070448
drwxrwxr-x 2 cobalt cobalt 4096 Sep 15 02:20 V__20220914120712
drwxrwxr-x 2 cobalt cobalt 4096 Dec 27 11:59 V__20221227171048

In the example above, the service name is msg (also commonly known as ams), and the migration version is V__20221227171048 .

Once you figure out what the version is, ls -l through that versions to see what migration files need to be executed. These migration files include SQL statements. Using the MR above, we can see that the db migration version only has one migration file as shown below, though in most cases, it will include one or more files:
cobalt@usdv:~$ ls -l /opt/mysql/ayla-schema-migrations/migrations/msg/V__20221227171048
total 4
-rw-rw-r-- 1 cobalt cobalt 117 Dec 27 11:59 20221227171549__alter_table_datastream.kinesis_metadata_add_index_destination_uuid.json
cobalt@usdv:~$

 

Step 3: Executing Migrations files 

Make sure you write down the migration version number, migration file name, Jira su number, and Application migration version which can be found in the Jira ticket as shown below using 

 

So the application migration number is 2.3.18 . So out list of things to track of using the above ticket as example would be:
DB migration version:  V__20221227171048
DB migration file:     20221227171549__alter_table_datastream.kinesis_metadata_add_index_destination_uuid.json
su number:             SU-5703
application version:   2.3.18

 

So to execute this migration file, do:
cd /opt/mysql/ayla-schema-migrations
./aylamig.sh -C migrate -s msg -umigtool -hmsgservice-owlue1-db.czfnzs5hvc9g.us-east-1.rds.amazonaws.com -d ams_db -c 20221227171549__alter_table_datastream.kinesis_metadata_add_index_destination_uuid.json -v V__20221227171048 -r SU-5703  -t 2.3.28

This will prompt you to confirm that you trully intend to perform this action, so enter Y to go ahead with the execution, otherwise enter n:

 

Step 4: Check the table to ensure changes have persisted

So log into the database and check the table to ensure the changes, in our example above, that the index was created:
SHOW CREATE TABLE <table-name>\G

Then also check the migration tool change log table to ensure the changes have been logged by running the query below:
select * from SCHEMA_CHANGE_LOGS where su_num = '<SU-NUM>';

Add the results from above two commands to the Jira ticket and notify the engineer that its been done.
