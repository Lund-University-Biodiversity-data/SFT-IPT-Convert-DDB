# config file
Create a lib/config.sql file, following the template lib/config_template.sql
To specify the configuration variables

# the scripts should be exectued against a PSQL table built from the mongo excel extract that you can download from the intranet

# duplicate tables from one database to another
sudo -u postgres pg_dump -t eurolist sft_20220525 | sudo -u postgres psql sft_std_from_mongo


### SFTstd-IPT-Convert-DDB
# Requirements :
 - totalstandard (coming from mongo excel extract, RECORDS) => mongo_totalstandard
Make sure that the art column contains 3 digits
´´´
UPDATE mongo_totalstandard SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´
 - sites (coming from mongo excel extract, SITES) => mongo_sites
 - persons  (coming from mongo excel extract, PERSONS) => mongo_persons
 - specieslist (ex-eurolist, coming from excel extract of lists.biodiversitydata.se, list dr627. WATCH OUT art as varchar3) => lists_eurolist


# eurolist import from lists
varchar(2) for 2 field euring
art as varchar (3) (make sure the csv contains 3 digits with 0. If not, use the formula =TEXT(B2, "000")  )
remove the space in "Supplied Name


# scripts
locally :

´´´
sudo -u postgres psql sft_std_from_mongo < toMongoAsMainDatabase/sft.sql
´´´
then export the whole database to canmoveapp
´´´
sudo -u postgres pg_dump sft_std_from_mongo -n ipt_sftstd  > sft_std_from_mongo_20220614.sql
tar cvzf sft_std_from_mongo_20220614.sql.tar.gz sft_std_from_mongo_20220614.sql
scp sft_std_from_mongo_20220614.sql.tar.gz  canmoveapp@canmove-app.ekol.lu.se:/home/canmoveapp/script_IPT_database/saves/
´´´
then on canmoveapp
´´´
cd script_IPT_database/saves/
tar xvf sft_std_from_mongo_20220614.sql.tar.gz
sudo -u postgres psql
DROP DATABASE ipt_sftstd;
CREATE DATABASE ipt_sftstd;
\q
sudo -u postgres psql ipt_sftstd < sft_std_from_mongo_20220614.sql
sudo -u postgres psql
\c ipt_sftstd
GRANT USAGE ON SCHEMA ipt_sftstd TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftstd TO ipt_sql_20 ;
\q


´´´


SFTstd-IPT-Convert-DDB

// save everythng before
sudo -u postgres pg_dump sft > sft_YYYYMMDD.sql 

sudo -u postgres psql sft < std_script_1_convert_data_before.sql 
sudo -u postgres psql sft < std_script_2_create_final_tables.sql 

// export juste le schema
sudo -u postgres pg_dump sft -n ipt_sftstd > sft_YYYYMMDD_ipt_sftstd.sql 

´´´
DROP DATABASE IF EXISTS ipt_sftstd;
CREATE DATABASE ipt_sftstd;
´´´
sudo -u postgres psql ipt_sftstd < sft_YYYYMMDD_ipt_sftstd.sql
´´´
\c ipt_sftstd
GRANT USAGE ON SCHEMA ipt_sftstd TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftstd TO ipt_sql_20 ;
´´´

