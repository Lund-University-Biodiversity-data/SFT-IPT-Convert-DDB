# SFT-IPT-Convert-DDB
SFT-IPT-Convert-DDB

// save everythng before
sudo -u postgres pg_dump sft > sft_YYYYMMDD.sql 

sudo -u postgres psql sft < script_1_convert_data_before.sql 
sudo -u postgres psql sft < script_2_create_final_tables.sql 

// export juste le schema
sudo -u postgres pg_dump sft -n ipt_sftstd > sft_YYYYMMDD_ipt_sftstd.sql 

´´´
DROP DATABASE IF EXISTS ipt_sftstd;
CREATE DATABASE ipt_sftstd;
\c ipt_sftstd
GRANT USAGE ON SCHEMA ipt_sftstd TO ipt_sql_20;
GRANT SELECT ON ALL TABLES IN SCHEMA ipt_sftstd TO ipt_sql_20 ;
´´´

sudo -u postgres psql ipt_sftstd < sft_YYYYMMDD_ipt_sftstd.sql

