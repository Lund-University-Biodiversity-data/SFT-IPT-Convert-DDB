# config file
Create a lib/config.sql file, following the template lib/config_template.sql
To specify the configuration variables

# the scripts should be exectued against a PSQL table built from the mongo excel extract that you can download from the intranet

# duplicate tables from one database to another
sudo -u postgres pg_dump -t eurolist sft_20220525 | sudo -u postgres psql sft_std_from_mongo


### SFTstd-IPT-Convert-DDB
# Requirements :
 - records (coming from mongo excel extract, RECORDS) => mongo_totalstandard

-datum varchar(8)
-art varchar(3)
-Make sure that the art column contains 3 digits
´´´
UPDATE mongo_totalstandard SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´
 - sites (coming from mongo excel extract, SITES) => mongo_sites
 - persons  (coming from mongo excel extract, PERSONS) => mongo_persons
telnummer varcar(32)
persnr varchar(64)
+ CHECK THE NEW anonymized Ids. dit excel file with :
db.person.update({personId:'bf357895-d746-4a8e-b30e-e84a4889d773'},{$set:{anonymizedId:2825}});

 - cenntroidTopoKartan (ex koordinater_mittpunkt_topokartan, coming from excel custom extract) => mongo_centroidtopokartan


 - specieslist (ex-eurolist, coming from excel extract of lists.biodiversitydata.se, list dr627. WATCH OUT art as varchar3) => lists_module_biodiv
 concat with mammals. CHeck the same colomns. Rename suppliedname
´´´
UPDATE lists_module_biodiv SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´



### SFTspkt-IPT-Convert-DDB
# Requirements :
´´´
CREATE DATABASE sft_spkt_from_mongo;
´´´
 - records (coming from mongo excel extract, RECORDS. Watchout art varchar 3 and datum varchar 8, remove if double column final) => mongo_totalsommarpkt
Make sure that the art column contains 3 digits
´´´
UPDATE mongo_totalsommarpkt SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´
 - sites (coming from mongo excel extract, SITES) => mongo_sites
 - persons  (coming from mongo excel extract, PERSONS) => mongo_persons
 - specieslist (ex-eurolist, coming from excel extract of lists.biodiversitydata.se, list dr627. WATCH OUT art as varchar3, euring as varchar10, dyntaxa as varchar10, delete one of the 2 columns guid, rename suppliedname column header) => lists_module_biodiv
 - centroidTopoKartan (ex koordinater_mittpunkt_topokartan, coming from excel custom extract) => mongo_centroidtopokartan
´´´
UPDATE lists_module_biodiv SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´


### SFTvpkt-IPT-Convert-DDB
# Requirements :
´´´
CREATE DATABASE sft_vpkt_from_mongo;
´´´
 - records (coming from mongo excel extract, RECORDS. Watchout art varchar 3 and datum varchar 8) => mongo_totalvinterpkt
Make sure that the art column contains 3 digits
´´´
UPDATE mongo_totalvinterpkt SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´
 - sites (coming from mongo excel extract, SITES) => mongo_sites
 - persons  (coming from mongo excel extract, PERSONS) => mongo_persons
 - specieslist (ex-eurolist, coming from excel extract of lists.biodiversitydata.se, list dr627. WATCH OUT art as varchar3, euring as varchar10, dyntaxa as varchar10, delete one of the 2 columns guid, rename suppliedname column header) => lists_module_biodiv
 - cenntroidTopoKartan (ex koordinater_mittpunkt_topokartan, coming from excel custom extract) => mongo_centroidtopokartan


### SFTiwc-IPT-Convert-DDB
# Requirements :
´´´
CREATE DATABASE sft_iwc_from_mongo;
´´´
 - records (coming from mongo excel extract, RECORDS. Watchout art varchar 3 and datum varchar 8, skip field komm) => mongo_totaliwc
Make sure that the art column contains 3 digits
´´´
UPDATE mongo_totaliwc SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´
 - sites (coming from mongo excel extract, SITES. helcom_sub as varchar(20)) => mongo_sites
 - persons  (coming from mongo excel extract, PERSONS) => mongo_persons
 - specieslist (ex-eurolist, coming from excel extract of lists.biodiversitydata.se, list dr627. WATCH OUT art as varchar3, euring as varchar10, dyntaxa as varchar10, delete one of the 2 columns guid, rename suppliedname column header) => lists_module_biodiv
 - mongo_iwc_medobs (coming from mongo excel extract custom, iwc medobs) => mongo_iwc_medobs


### SFTkfr-IPT-Convert-DDB
# Requirements :
´´´
CREATE DATABASE sft_kfr_from_mongo;
´´´
 - medobs (coming from excel custom extract, KUST medobs) => mongo_medobs
(varchar(3) for the last 4 columns ja/nej)
 - sites (coming from mongo excel extract, SITES) => mongo_sites
 - records (coming from mongo excel extract, RECORDS) => mongo_totalkust
 (verificationStatus varchar(15), art(varchar(3)), datum as varchar(8))
´´´
UPDATE mongo_totalkust SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´
 - persons  (coming from mongo excel extract, PERSONS) => mongo_persons
 - specieslist (ex-eurolist, coming from excel extract of lists.biodiversitydata.se, list dr627. WATCH OUT art as varchar3, euring as varchar10, dyntaxa as varchar10, rename suppliedname column header) => lists_module_biodiv
´´´
UPDATE lists_eurolist_dr638_3mammals SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´




### scripts to canmove server


# STD

first make sure you have the last verison of the ecodata-mongo database
locally :

´´´
sudo -u postgres psql sft_std_from_mongo < toMongoAsMainDatabase/convert_std.sql
´´´
then export the whole database to canmoveapp
´´´
sudo -u postgres pg_dump sft_std_from_mongo -n ipt_sftstd  > sft_std_from_mongo_202XXXXXX.sql
tar cvzf sft_std_from_mongo_202XXXXXX.sql.tar.gz sft_std_from_mongo_202XXXXXX.sql
scp sft_std_from_mongo_202XXXXXX.sql.tar.gz  canmoveapp@canmove-app.ekol.lu.se:/home/canmoveapp/script_IPT_database/saves/
´´´
then on canmoveapp
´´´
cd script_IPT_database/saves/
tar xvf sft_std_from_mongo_202XXXXXX.sql.tar.gz
sudo -u postgres psql
DROP DATABASE ipt_sftstd;
CREATE DATABASE ipt_sftstd;
\q
sudo -u postgres psql ipt_sftstd < sft_std_from_mongo_202XXXXXX.sql
sudo -u postgres psql ipt_sftstd
GRANT USAGE ON SCHEMA ipt_sftstd TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftstd TO ipt_sql_20 ;
\q


´´´


# SPKT

locally :

´´´
sudo -u postgres psql sft_spkt_from_mongo < toMongoAsMainDatabase/convert_spkt.sql
´´´
then export the whole database to canmoveapp
´´´
sudo -u postgres pg_dump sft_spkt_from_mongo -n ipt_sftspkt  > sft_spkt_from_mongo_20240708.sql
tar cvzf sft_spkt_from_mongo_20240708.sql.tar.gz sft_spkt_from_mongo_20240708.sql
scp sft_spkt_from_mongo_20240708.sql.tar.gz  canmoveapp@canmove-app.ekol.lu.se:/home/canmoveapp/script_IPT_database/saves/
´´´
then on canmoveapp
´´´
cd script_IPT_database/saves/
tar xvf sft_spkt_from_mongo_20240708.sql.tar.gz
sudo -u postgres psql
DROP DATABASE ipt_sftspkt;
CREATE DATABASE ipt_sftspkt;
\q
sudo -u postgres psql ipt_sftspkt < sft_spkt_from_mongo_20240708.sql
sudo -u postgres psql ipt_sftspkt
GRANT USAGE ON SCHEMA ipt_sftspkt TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftspkt TO ipt_sql_20 ;
\q


´´´


# VPKT

locally :

´´´
sudo -u postgres psql sft_vpkt_from_mongo < toMongoAsMainDatabase/convert_vpkt.sql
´´´
then export the whole database to canmoveapp
´´´
sudo -u postgres pg_dump sft_vpkt_from_mongo -n ipt_sftvpkt  > sft_vpkt_from_mongo_20240708.sql
tar cvzf sft_vpkt_from_mongo_20240708.sql.tar.gz sft_vpkt_from_mongo_20240708.sql
scp sft_vpkt_from_mongo_20240708.sql.tar.gz  canmoveapp@canmove-app.ekol.lu.se:/home/canmoveapp/script_IPT_database/saves/
´´´
then on canmoveapp
´´´
cd script_IPT_database/saves/
tar xvf sft_vpkt_from_mongo_20240708.sql.tar.gz
sudo -u postgres psql
DROP DATABASE ipt_sftvpkt;
CREATE DATABASE ipt_sftvpkt;
\q
sudo -u postgres psql ipt_sftvpkt < sft_vpkt_from_mongo_20240708.sql
sudo -u postgres psql ipt_sftvpkt
GRANT USAGE ON SCHEMA ipt_sftvpkt TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftvpkt TO ipt_sql_20 ;
\q


´´´




# KFR

locally :

´´´
sudo -u postgres psql sft_kfr_from_mongo < toMongoAsMainDatabase/convert_kfr.sql
´´´
then export the whole database to canmoveapp
´´´
sudo -u postgres pg_dump sft_kfr_from_mongo -n ipt_sftkfr  > sft_kfr_from_mongo_XXXXXXXX.sql
tar cvzf sft_kfr_from_mongo_XXXXXXXX.sql.tar.gz sft_kfr_from_mongo_XXXXXXXX.sql
scp sft_kfr_from_mongo_XXXXXXXX.sql.tar.gz  canmoveapp@canmove-app.ekol.lu.se:/home/canmoveapp/script_IPT_database/saves/
´´´
then on canmoveapp
´´´
cd script_IPT_database/saves/
tar xvf sft_kfr_from_mongo_XXXXXXXX.sql.tar.gz
sudo -u postgres psql
DROP DATABASE ipt_sftkfr;
CREATE DATABASE ipt_sftkfr;
\q
sudo -u postgres psql ipt_sftkfr < sft_kfr_from_mongo_XXXXXXXX.sql
sudo -u postgres psql ipt_sftkfr
GRANT USAGE ON SCHEMA ipt_sftkfr TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftkfr TO ipt_sql_20 ;
\q


´´´


# IWC

locally :

´´´
sudo -u postgres psql sft_iwc_from_mongo < toMongoAsMainDatabase/convert_iwc.sql
´´´
then export the whole database to canmoveapp
´´´
sudo -u postgres pg_dump sft_iwc_from_mongo -n ipt_sftiwc  > sft_iwc_from_mongo_20241218.sql
tar cvzf sft_iwc_from_mongo_20241218.sql.tar.gz sft_iwc_from_mongo_20241218.sql
scp sft_iwc_from_mongo_20241218.sql.tar.gz  canmoveapp@canmove-app.ekol.lu.se:/home/canmoveapp/script_IPT_database/saves/
´´´
then on canmoveapp
´´´
cd script_IPT_database/saves/
tar xvf sft_iwc_from_mongo_20241218.sql.tar.gz
sudo -u postgres psql
DROP DATABASE ipt_sftiwc;
CREATE DATABASE ipt_sftiwc;
\q
sudo -u postgres psql ipt_sftiwc < sft_iwc_from_mongo_20241218.sql
sudo -u postgres psql ipt_sftiwc
GRANT USAGE ON SCHEMA ipt_sftiwc TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftiwc TO ipt_sql_20 ;
\q


´´´



select eventtype, count(*) from ipt_sftiwc.ipt_sftiwc_sampling ise group by eventtype
select measurementType, count(*) from ipt_sftiwc.ipt_sftiwc_emof ise group by measurementType