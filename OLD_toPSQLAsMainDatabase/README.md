# config file
Create a lib/config.sql file, following the template lib/config_template.sql
To specify the configuration variables



# duplicate tables from one database to another
sudo -u postgres pg_dump -t eurolist sft_20220525 | sudo -u postgres psql sft_std_from_mongo
sudo -u postgres pg_dump -t standardrutter_oversikt sft_20220525 | sudo -u postgres psql sft_std_from_mongo
sudo -u postgres pg_dump -t koordinater_mittpunkt_topokartan sft_20220525 | sudo -u postgres psql sft_std_from_mongo


# SFTstd-IPT-Convert-DDB
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




# SFTspkt-IPT-Convert-DDB

// save everything before
sudo -u postgres pg_dump sft > sft_YYYYMMDD.sql 

sudo -u postgres psql sft < s-v-pkt_annex_create_natstnreg.sql 
sudo -u postgres psql sft < spkt_script_1_convert_data_before.sql 
sudo -u postgres psql sft < spkt_script_2_create_final_tables.sql 

// export juste le schema
sudo -u postgres pg_dump sft -n ipt_sftspkt > sft_YYYYMMDD_ipt_sftspkt.sql 

´´´
DROP DATABASE IF EXISTS ipt_sftspkt;
CREATE DATABASE ipt_sftspkt;
´´´
sudo -u postgres psql ipt_sftspkt < sft_YYYYMMDD_ipt_sftspkt.sql

´´´
\c ipt_sftspkt
GRANT USAGE ON SCHEMA ipt_sftspkt TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftspkt TO ipt_sql_20 ;
´´´

# SFTvpkt-IPT-Convert-DDB

// use the intranet to get the extract of the records + sites + persons
// save everything before
sudo -u postgres pg_dump sft_migration > sft_YYYYMMDD.sql 

sudo -u postgres psql sft_from_mongo_vpkt_dwca < s-v-pkt_annex_create_natstnreg.sql 
sudo -u postgres psql sft_from_mongo_vpkt_dwca < vpkt_script_0_convert_data_before.sql 
sudo -u postgres psql sft_from_mongo_vpkt_dwca < vpkt_script_1_convert_data_before.sql 
sudo -u postgres psql sft_from_mongo_vpkt_dwca < vpkt_script_2_create_final_tables.sql 

// export juste le schema
sudo -u postgres pg_dump sft_from_mongo_vpkt_dwca -n ipt_sftvpkt > sft_YYYYMMDD_ipt_sftvpkt.sql 

´´´
DROP DATABASE IF EXISTS ipt_sftvpkt;
CREATE DATABASE ipt_sftvpkt;
´´´
sudo -u postgres psql ipt_sftvpkt < sft_YYYYMMDD_ipt_sftvpkt.sql

´´´
\c ipt_sftvpkt
GRANT USAGE ON SCHEMA ipt_sftvpkt TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftvpkt TO ipt_sql_20 ;
´´´


# SFTkfr-IPT-Convert-DDB

// save everything before
sudo -u postgres pg_dump sft > sft_YYYYMMDD.sql 

sudo -u postgres psql sft < kfr_script_1_convert_data_before.sql 
sudo -u postgres psql sft < kfr_script_2_create_final_tables.sql 

// export juste le schema
sudo -u postgres pg_dump sft -n ipt_sftkfr > sft_YYYYMMDD_ipt_sftkfr.sql 

´´´
DROP DATABASE IF EXISTS ipt_sftkfr;
CREATE DATABASE ipt_sftkfr;
´´´
sudo -u postgres psql ipt_sftkfr < sft_YYYYMMDD_ipt_sftkfr.sql

´´´
\c ipt_sftkfr
GRANT USAGE ON SCHEMA ipt_sftkfr TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftkfr TO ipt_sql_20 ;
