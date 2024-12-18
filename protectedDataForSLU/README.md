# config file
Create a lib/config.sql file, following the template lib/config_template.sql
To specify the configuration variables

# the scripts should be exectued against a PSQL table built from the mongo excel extract that you can download from the intranet


### SFTstd-IPT-Convert-DDB
# Requirements :

6 tables needed :
 - mongo_totalstandard
 - mongo_persons
 - mongo_sites
 - sftstd_punktkoordinater
 - lists_module_biodiv
 - standardrutter_koordinater

These 6 tables are created this way :

#### mongo_totalstandard
coming from mongo excel extract, RECORDS

-datum varchar(8)
-art varchar(3)
-Make sure that the art column contains 3 digits
´´´
UPDATE mongo_totalstandard SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´

#### mongo_totalsommarpkt
 - records (coming from mongo excel extract, RECORDS. Watchout art varchar 3 and datum varchar 8, remove if double column final) => mongo_totalsommarpkt

#### mongo_sites
coming from mongo excel extract, SITES

#### mongo_persons
coming from mongo excel extract, PERSONS

telnummer varcar(32)
persnr varchar(64)
+ CHECK THE NEW anonymized Ids. dit excel file with :
db.person.update({personId:'bf357895-d746-4a8e-b30e-e84a4889d773'},{$set:{anonymizedId:2825}});

#### lists_module_biodiv
ex-eurolist, coming from excel extract of lists.biodiversitydata.se, list dr627. 

WATCH OUT art as varchar3, varchar(20) for 2 field euring
Check the same colomns. 
Rename suppliedname
´´´
UPDATE lists_module_biodiv SET art = LPAD(art, 3, '0')
WHERE length(art)<3
´´´

#### standardrutter_koordinater
copy the table from SFT psql prod database
sudo -u postgres pg_dump -t standardrutter_koordinater sft_20220525 | sudo -u postgres psql sft_std_from_mongo


#### mongo_pkt_koordinater
download CSV from https://canmove-app.ekol.lu.se/intranet/tools/coordinates_site_punkt.php?display=coord
import and skip columns #, biocollectlink
rename fields to avoid quotes/spaces

### scripts to canmove server


# STD

first make sure you have the last verison of the ecodata-mongo database
locally :

´´´
sudo -u postgres psql sft_std_from_mongo < protectedDataForSLU/convert_std_protecteddata.sql
sudo -u postgres psql sft_spkt_from_mongo < protectedDataForSLU/convert_spkt_protecteddata.sql
´´´
then export the whole database to canmoveapp
´´´
sudo -u postgres pg_dump sft_std_from_mongo -n ipt_sftstd_protected  > sft_std_protected_from_mongo_202XXXXXX.sql
tar cvzf sft_std_protected_from_mongo_202XXXXXX.sql.tar.gz sft_std_protected_from_mongo_202XXXXXX.sql
scp sft_std_protected_from_mongo_202XXXXXX.sql.tar.gz  canmoveapp@canmove-app.ekol.lu.se:/home/canmoveapp/script_IPT_database/saves/
´´´
then on canmoveapp
´´´
cd script_IPT_database/saves/
tar xvf sft_std_protected_from_mongo_202XXXXXX.sql.tar.gz
sudo -u postgres psql
DROP DATABASE ipt_sftstd_protected;
CREATE DATABASE ipt_sftstd_protected;
\q
sudo -u postgres psql ipt_sftstd_protected < sft_std_protected_from_mongo_202XXXXXX.sql
sudo -u postgres psql ipt_sftstd_protected
GRANT USAGE ON SCHEMA ipt_sftstd_protected TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftstd_protected TO ipt_sql_20 ;
\q


´´´

DELETE FROM ipt_sftstd_protected.ipt_sftstd_protected_sampling WHERE eventid <> 'SFTstd:19990629:484:P1';
DELETE FROM ipt_sftstd_protected.ipt_sftstd_protected_occurrence WHERE eventid <> 'SFTstd:19990629:484:P1';
DELETE FROM ipt_sftstd_protected.ipt_sftstd_protected_emof WHERE eventid <> 'SFTstd:19990629:484:P1';
SELECT COUNT(*) FROM ipt_sftstd_protected.ipt_sftstd_protected_sampling;
SELECT COUNT(*) FROM ipt_sftstd_protected.ipt_sftstd_protected_occurrence;
SELECT COUNT(*) FROM ipt_sftstd_protected.ipt_sftstd_protected_emof;

UPDATE ipt_sftstd_protected.ipt_sftstd_protected_occurrence SET basisofrecord='HumanObservation';

DROP DATABASE WHEN FINISHED !!!

if needed 
sudo nano /etc/postgresql/11/main/pg_hba.conf


SELECT COUNT(*)  , measurementtype
from ipt_sftstd_protected.ipt_sftstd_protected_emof
group by measurementtype