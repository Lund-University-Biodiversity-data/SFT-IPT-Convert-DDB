/*\i lib/config.sql*/

/*\c :database_name*/
\set database_name sft_std_from_mongo

\set year_max 2023

DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK;
DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_ROUTES_WITH_REAL_COORDINATES;
DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_POINTDATA;
DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY;
DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_STARTENDTIME;
DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_OCCURRENCE;
DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_EVENTSNOOBS;
DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_POINTSNOOBS;
DROP TABLE IF EXISTS IPT_SFTspkt_protected.IPT_SFTspkt_protected_EMOF;

DROP SCHEMA IF EXISTS IPT_SFTspkt_protected;
CREATE SCHEMA IPT_SFTspkt_protected;


CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (
    taxonrank varchar(30) NOT NULL,
    taxonrank_se varchar(30) NOT NULL,
    PRIMARY KEY (taxonrank)
); 

INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('class', 'klass');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('family', 'familj');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('genus', 'släkte');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('genusAggregate', 'artkomplex');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('kingdom', 'rike');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('organismGroup', 'pseudotaxon');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('species', 'art');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('speciesAggregate', 'artkomplex');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('subfamily', 'underfamilj');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('subspecies', 'underart');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK (taxonrank, taxonrank_se) VALUES ('tribe', 'tribus');

CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (
    code varchar(2) NOT NULL,
    name varchar(255) NOT NULL,
    PRIMARY KEY (code)
); 

INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('AB', 'Stockholms län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('AC', 'Västerbottens län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('BD', 'Norrbottens län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('C', 'Uppsala län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('D', 'Södermanlands län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('E', 'Östergötlands län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('F', 'Jönköpings län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('G', 'Kronobergs län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('H', 'Kalmar län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('I', 'Gotlands län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('K', 'Blekinge län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('M', 'Skåne län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('N', 'Hallands län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('O', 'Västra Götalands län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('S', 'Värmlands län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('T', 'Örebro län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('U', 'Västmanlands län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('W', 'Dalarnas län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('X', 'Gävleborgs län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('Y', 'Västernorrlands län');
INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_CONVERT_COUNTY (code, name) VALUES ('Z', 'Jämtlands län');


CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_POINTDATA AS
SELECT persnr, rnr, datum, yr, 1 as indexpoint, art, p01 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 2 as indexpoint, art, p02 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000' 
UNION SELECT persnr, rnr, datum, yr, 3 as indexpoint, art, CAST(p03 as INTEGER) as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 4 as indexpoint, art, CAST(p04 as INTEGER) as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 5 as indexpoint, art, p05 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 6 as indexpoint, art, p06 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 7 as indexpoint, art, p07 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 8 as indexpoint, art, p08 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 9 as indexpoint, art, p09 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 10 as indexpoint, art, p10 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 11 as indexpoint, art, p11 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 12 as indexpoint, art, p12 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 13 as indexpoint, art, p13 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 14 as indexpoint, art, p14 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 15 as indexpoint, art, p15 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 16 as indexpoint, art, p16 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 17 as indexpoint, art, p17 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 18 as indexpoint, art, p18 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 19 as indexpoint, art, p19 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
UNION SELECT persnr, rnr, datum, yr, 20 as indexpoint, art, p20 as totcount, false as exactcoordinates, 0.0 as decimallatitude, 0.0 as decimallongitude FROM mongo_totalsommarpkt where art<>'000'
ORDER BY persnr, rnr, datum, art;

/* default mittpunkt koordinates */
UPDATE IPT_SFTspkt_protected.IPT_SFTspkt_protected_POINTDATA  IPD
set decimallatitude=I.decimallatitude, decimallongitude=I.decimallongitude
FROM mongo_sites I 
WHERE I.internalsiteid=CONCAT(IPD.persnr, '-', LPAD(CAST(IPD.rnr AS text), 2, '0'));

/* update koordinates when they exist for each point */
UPDATE IPT_SFTspkt_protected.IPT_SFTspkt_protected_POINTDATA  IPD
set decimallatitude=I.latitude, decimallongitude=I.longitude , exactcoordinates=true
FROM mongo_pkt_koordinater I
WHERE I.internalsiteid=CONCAT(IPD.persnr, '-', LPAD(CAST(IPD.rnr AS text), 2, '0'))
AND index=IPD.indexpoint;

CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_ROUTES_WITH_REAL_COORDINATES AS
SELECT DISTINCT persnr, rnr 
FROM IPT_SFTspkt_protected.IPT_SFTspkt_protected_POINTDATA
WHERE exactcoordinates=true;

/* a dd a column in the site table to store that */
ALTER TABLE mongo_sites ADD COLUMN IF NOT EXISTS exactcoordinates BOOLEAN DEFAULT false; 
UPDATE mongo_sites I SET exactcoordinates=true 
FROM IPT_SFTspkt_protected.IPT_SFTspkt_protected_ROUTES_WITH_REAL_COORDINATES RC
WHERE I.internalsiteid=CONCAT(RC.persnr, '-', LPAD(CAST(RC.rnr AS text), 2, '0'));

CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_EVENTSNOOBS AS
select datum, persnr, rnr, yr, indexpoint
from (
    select ispp.datum, ispp.persnr, ispp.rnr, t.yr, ispp.indexpoint, COUNT(*) as tot 
    from mongo_totalsommarpkt T, ipt_sftspkt_protected.ipt_sftspkt_protected_pointdata ispp 
    WHERE ispp.persnr=T.persnr and ispp.rnr=T.rnr and ispp.datum=T.datum
    AND T.yr<= :year_max
    group by ispp.datum, ispp.persnr, ispp.rnr, t.yr, ispp.indexpoint
) as eventnoobs
where tot=1; /* if one, then only row 000, then no observations !*/


CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_POINTSNOOBS AS
select datum, persnr, rnr, indexpoint
from (
    select ispp.datum, ispp.persnr, ispp.rnr, ispp.indexpoint , SUM(totcount) as tot
    from ipt_sftspkt_protected.ipt_sftspkt_protected_pointdata ispp 
    group by ispp.datum, ispp.persnr, ispp.rnr, ispp.indexpoint
) as eventnoobs
where tot=0; /* if one, then only row 000, then no observations !*/


/*
CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_DETAILSART AS
SELECT art, suppliedname, SPLIT_PART(suppliedname, ' ', 1) as genus, SPLIT_PART(suppliedname, ' ', 2) as specificEpithet, SPLIT_PART(suppliedname, ' ', 3) as infraSpecificEpithet 
FROM lists_module_biodiv;*/
/* Manual fix of the art that ends with "L" or "Li" or "T" 
UPDATE IPT_SFTspkt_protected.IPT_SFTspkt_protected_DETAILSART
SET infraSpecificEpithet=''
WHERE LENGTH(infraSpecificEpithet)>0 AND LENGTH(infraSpecificEpithet)<3;*/


/*INSERT INTO IPT_SFTspkt_protected.IPT_SFTspkt_protected_EVENTSNOOBS VALUES ('20210826', '491210-1', '01', '2020');*/

/* START TIME */
CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_STARTENDTIME AS
SELECT persnr, rnr, datum, p03 AS starttime, p04 AS endtime, 
/*SELECT persnr, rnr, datum, LPAD(CAST(p03 AS text), 4, '0') AS starttime, LPAD(CAST(p04 AS text), 4, '0') AS endtime*/
TO_DATE(datum,'YYYYMMDD') as startdate,
TO_DATE(datum,'YYYYMMDD') as enddate /* updated later in case of different dates! */
from mongo_totalsommarpkt
WHERE art='000';
/* change the enddate in case it's not the same day */
UPDATE IPT_SFTspkt_protected.IPT_SFTspkt_protected_STARTENDTIME
SET enddate=startDate +1
WHERE starttime<>'' AND endtime<>'' AND starttime is not null AND endtime is not null
AND CAST(LEFT(endtime, 2) AS INTEGER)<CAST(LEFT(starttime, 2) AS INTEGER);



CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_SAMPLING AS

/* RUUT */
SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
'' AS parentEventId,
CONCAT('SFT:recorderId:', Pe.anonymizedId) AS recordedBy, /* for EMOF ! */
'besök' AS eventType,
'punkttaxering' AS samplingProtocol,
'100 minuter' AS samplingEffort,
CONCAT(ST.startdate,'/',ST.enddate) AS eventDate,
CONCAT(ST.starttime,'/',ST.endtime) AS eventTime,
I.stnregosid AS locationId,
I.lan AS county,
'' as municipality,
CONCAT('SFTpkt:siteId:', cast(I.anonymizedId AS text)) AS locality,
ROUND(K.wgs84_lat::float8::numeric, 5) AS decimalLatitude, /* already diffused all locations 25 000 */
ROUND(K.wgs84_lon::float8::numeric, 5) AS decimalLongitude, /* already diffused all locations 25 000 */
'EPSG:4326' AS geodeticDatum,
CASE
    WHEN exactcoordinates THEN cast (null as integer)
    ELSE 17700
END AS coordinateUncertaintyInMeters,
'Angivna koordinater visar mittpunkten för den 25x25km-ruta som rutten finns inom.' AS locationRemarks,
null as accessRights
FROM mongo_sites I, mongo_centroidtopokartan K, mongo_totalsommarpkt T
left join IPT_SFTspkt_protected.IPT_SFTspkt_protected_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum
LEFT JOIN mongo_persons Pe ON Pe.persnr=T.persnr 
WHERE I.kartatx=K.kartatx
AND  I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art='000'
AND T.yr<= :year_max


UNION

/* PUNKT */
SELECT 
distinct CONCAT('SFTspkt:', CP.datum, ':', I.anonymizedId, ':P', LPAD(CAST(CP.indexpoint AS text), 2, '0')) as eventID,
CONCAT('SFTspkt:', CP.datum, ':', I.anonymizedId) as parentEventID,
CONCAT('SFT:recorderId:', Pe.anonymizedId) AS recordedBy, /* for EMOF ! */
'delbesök' AS eventType,
'punkttaxering' AS samplingProtocol,
'5 minuter' AS samplingEffort,
CONCAT(ST.startdate,'/',ST.enddate) AS eventDate,
CONCAT(ST.starttime,'/',ST.endtime) AS eventTime,
I.stnregosid AS locationId,
I.lan AS county,
'' as municipality,
CONCAT('SFTpkt:siteId:', cast(I.anonymizedId AS text)) AS locality,
ROUND(CP.decimallatitude, 5) AS decimalLatitude,
ROUND(CP.decimallongitude, 5) AS decimalLongitude,
/*
ROUND(CP.decimallatitude::float8::numeric, 5) AS decimalLatitude,
ROUND(CP.decimallongitude::float8::numeric, 5) AS decimalLongitude,
*/
'EPSG:4326' AS geodeticDatum,
CASE 
    WHEN CP.exactcoordinates THEN 2000
    ELSE 17700 
END AS coordinateUncertaintyInMeters,
CASE 
    WHEN CP.exactcoordinates THEN 'Koordinaterna anger punktens mitt.'
    ELSE 'Koordinaterna anger ruttens mittpunkt.' 
END  AS locationRemarks,
null as accessRights
FROM mongo_sites I, IPT_SFTspkt_protected.IPT_SFTspkt_protected_POINTDATA CP
left join IPT_SFTspkt_protected.IPT_SFTspkt_protected_STARTENDTIME ST on CP.persnr=ST.persnr AND CP.rnr=ST.rnr AND CP.datum=ST.datum
LEFT JOIN mongo_persons Pe ON Pe.persnr=CP.persnr 
WHERE  I.internalsiteid=CONCAT(CP.persnr, '-', LPAD(CAST(CP.rnr AS text), 2, '0'))
AND I.exactcoordinates = true /* only the lines with coordinates */
AND CP.yr<= :year_max

order by eventID;


CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_OCCURRENCE AS
SELECT
CONCAT('SFTspkt:', CP.datum, ':', I.anonymizedId, ':P', LPAD(CAST(CP.indexpoint AS text), 2, '0')) as eventID,
CONCAT('SFTspkt:', CP.datum, ':', I.anonymizedId, ':', E.dyntaxa_id, ':P', LPAD(CAST(CP.indexpoint AS text), 2, '0')) as occurrenceID,
'HumanObservation' AS basisOfRecord,
CP.totcount AS individualCount,
CP.totcount AS organismQuantity,
'individer' AS organismQuantityType,
CASE 
    WHEN CP.totcount>0 THEN 'observerad'
    ELSE 'inte observerad ' 
END AS occurrenceStatus,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
E.suppliedname AS scientificName,
E.arthela AS vernacularName,
TTR.taxonrank_se as taxonRank,
E.eu_sp_code AS euTaxonID
FROM mongo_sites I, IPT_SFTspkt_protected.IPT_SFTspkt_protected_POINTDATA CP,
lists_module_biodiv E LEFT JOIN IPT_SFTspkt_protected.IPT_SFTspkt_protected_TRANSLATE_TAXONRANK TTR ON E.taxon_rank=TTR.taxonrank
WHERE  CP.art=E.art
AND I.internalsiteid=CONCAT(CP.persnr, '-', LPAD(CAST(CP.rnr AS text), 2, '0'))
AND CP.yr<= :year_max
AND CP.totcount>0

/* with IPT_SFTspkt_protected_EVENTSNOOBS => nothing right now for spkt... */
UNION

SELECT
CONCAT('SFTspkt:', CP.datum, ':', I.anonymizedId, ':', CP.indexpoint) as eventID,
CONCAT('SFTspkt:', CP.datum, ':', I.anonymizedId, ':4000104:', CP.indexpoint) as occurrenceID,
'HumanObservation' AS basisOfRecord,
0 AS individualCount,
0 AS organismQuantity,
'individer' AS organismQuantityType,
'inte observerad 'AS occurrenceStatus,
'urn:lsid:dyntaxa.se:Taxon:4000104' AS taxonID,
'Aves' AS scientificName,
'BirdsIncludedInSurvey' AS vernacularName,
'rike' AS taxonRank,
'' AS euTaxonID
FROM mongo_sites I, 
IPT_SFTspkt_protected.IPT_SFTspkt_protected_EVENTSNOOBS CP
WHERE  I.internalsiteid=CONCAT(CP.persnr, '-', LPAD(CAST(CP.rnr AS text), 2, '0'))
AND CP.yr<= :year_max

ORDER BY eventID, taxonID;


/*
ver 1.2 // Add events without observations, set
 scientificName to Aves, 
 taxonId to 4000104, 
 vernacularName to BirdsIncludedInSurvey, 
 occurrenceStatus to absent, 
 organismQuantity to 0, 
 organismQuantityType to individuals, 
 basisOfRecord to HumanObservation, 
 occurrenceID to SFTspkt:19750412:500:nullobs. 
 // But there doesn'ät seem to be any events without observations.

*/

/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


CREATE TABLE IPT_SFTspkt_protected.IPT_SFTspkt_protected_EMOF AS

SELECT
DISTINCT eventID,
null as occurrenceID,
'locationProtected' AS measurementType,
'nej' AS measurementValue
FROM IPT_SFTspkt_protected.IPT_SFTspkt_protected_SAMPLING

UNION

SELECT
DISTINCT eventID,
null as occurrenceID,
'locationType' AS measurementType,
CASE
    WHEN eventtype = 'besök' THEN 'rutt' 
    ELSE 'punkt' 
END AS measurementValue
FROM IPT_SFTspkt_protected.IPT_SFTspkt_protected_SAMPLING

UNION 

SELECT
DISTINCT eventID,
null as occurrenceID,
'dimension' AS measurementType,
'2' AS measurementValue
FROM IPT_SFTspkt_protected.IPT_SFTspkt_protected_SAMPLING


UNION

SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
null as occurrenceID,
'transportMethod' AS measurementType,
CASE
    WHEN p01 = 1 THEN 'on foot or skis'
    WHEN p01 = 2 THEN 'by bike or moped'
    WHEN p01 = 3 THEN 'by car or motorcycle'
    WHEN p01 = 4 THEN 'other'
    ELSE ''
END AS measurementValue
FROM mongo_sites I, mongo_totalsommarpkt T
WHERE I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art='000'
AND T.yr<= :year_max
AND p01 IS NOT NULL

UNION

SELECT
DISTINCT eventID,
null as occurrenceID,
'noObservations' AS measurementType,
CASE 
    WHEN individualCount=0 THEN 'sant'
    ELSE 'falskt'
END AS measurementValue
FROM IPT_SFTspkt_protected.IPT_SFTspkt_protected_OCCURRENCE


UNION

SELECT
eventID,
occurrenceID,
'euTaxonID' AS measurementType,
CASE 
    WHEN individualCount=0 THEN ''
    ELSE euTaxonID
END AS measurementValue
FROM IPT_SFTspkt_protected.IPT_SFTspkt_protected_OCCURRENCE

UNION 

SELECT
DISTINCT eventID,
null as occurrenceID,
'recordedBy' AS measurementType,
recordedBy AS measurementValue
FROM IPT_SFTspkt_protected.IPT_SFTspkt_protected_SAMPLING

order by eventID, occurrenceID;
