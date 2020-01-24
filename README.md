# SFT-IPT-Convert-DDB
SFT-IPT-Convert-DDB


´´´
\c sft;
CREATE SCHEMA IPT_SFTstd;
´´´

// save everythng before
sudo -u postgres pg_dump sft > sft_YYYYMMDD.sql 

sudo -u postgres psql sft < IPT_convert_data_before.sql 
sudo -u postgres psql sft < IPT_create_tables.sql 

// export juste le schema
sudo -u postgres pg_dump sft -n ipt_sftstd > sft_YYYYMMDD_ipt_sftstd.sql 

sudo -u postgres psql sft < IPT_3_create_database_import.sql 

sudo -u postgres psql ipt_sftstd < sft_YYYYMMDD_ipt_sftstd.sql





/*
psql -U postgres sft -n IPT_SFTstd < script_convert_data_before.sql
psql -U postgres sft -n IPT_SFTstd < script_tables.sql
pg_dump -U postgres sft -n IPT_SFTstd > IPT_SFTstd.sql

´´´
CREATE DATABASE ipt_sftstd;
´´´

psql -U postgres ipt_sftstd < IPT_SFTstd.sql
*/
