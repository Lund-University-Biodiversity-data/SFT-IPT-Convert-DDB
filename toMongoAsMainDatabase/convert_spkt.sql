\i lib/config.sql

/*\c :database_name*/
\set database_name sft_spkt_from_mongo_to_dwca

\set year_max 2023

DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_DETAILSART;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_OCCURRENCE;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_EMOF;

DROP SCHEMA IF EXISTS IPT_SFTspkt;
CREATE SCHEMA IPT_SFTspkt;

CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES AS
SELECT * FROM lists_module_biodiv
WHERE protected_adb LIKE '4%' or protected_adb LIKE '5%'; 


CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS AS
select datum, persnr, rnr, yr
from (
    select datum, persnr, rnr, yr, COUNT(*) as tot from mongo_totalsommarpkt 
    WHERE yr<= :year_max
    group by datum, persnr, yr, rnr
) as eventnoobs
where tot=1; /* if one, then only row 000, then no observations !*/

CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_DETAILSART AS
SELECT art, suppliedname, SPLIT_PART(suppliedname, ' ', 1) as genus, SPLIT_PART(suppliedname, ' ', 2) as specificEpithet, SPLIT_PART(suppliedname, ' ', 3) as infraSpecificEpithet 
FROM lists_module_biodiv;
/* Manual fix of the art that ends with "L" or "Li" or "T" */
UPDATE IPT_SFTspkt.IPT_SFTspkt_DETAILSART
SET infraSpecificEpithet=''
WHERE LENGTH(infraSpecificEpithet)>0 AND LENGTH(infraSpecificEpithet)<3;



/*INSERT INTO IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS VALUES ('20210826', '491210-1', '01', '2020');*/

/* START TIME */
CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME AS
SELECT persnr, rnr, datum, p03 AS starttime, p04 AS endtime, 
/*SELECT persnr, rnr, datum, LPAD(CAST(p03 AS text), 4, '0') AS starttime, LPAD(CAST(p04 AS text), 4, '0') AS endtime*/
TO_DATE(datum,'YYYYMMDD') as startdate,
TO_DATE(datum,'YYYYMMDD') as enddate /* updated later in case of different dates! */
from mongo_totalsommarpkt
WHERE art='000';
/* change the enddate in case it's not the same day */
UPDATE IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME
SET enddate=startDate +1
WHERE starttime<>'' AND endtime<>'' AND starttime is not null AND endtime is not null
AND CAST(LEFT(endtime, 2) AS INTEGER)<CAST(LEFT(starttime, 2) AS INTEGER);

/*

To be fixed
 - convert starttime with timezone

*/

CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_SAMPLING AS
SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
'point transect survey' AS samplingProtocol,
CONCAT(ST.startdate,'/',ST.enddate) AS eventDate,
/*CONCAT(left(ST.starttime, length(cast(ST.starttime as text))-2), ':', right(ST.starttime, 2),'/',left(ST.endtime, length(cast(ST.endtime as text))-2), ':', right(ST.endtime, 2)) AS eventTime,*/
CONCAT(ST.starttime,'/',ST.endtime) AS eventTime,
CAST(EXTRACT (doy from ST.startdate) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from ST.enddate) AS INTEGER) AS endDayOfYear,
I.stnregosid AS locationId,
CONCAT('SFTpkt:siteId:', cast(anonymizedId AS text)) AS verbatimLocality,
I.lan AS county,
'EPSG:4326' AS geodeticDatum,
17700 AS coordinateUncertaintyInMeters,
'The coordinates supplied are for the central point of a 25 x 25 km survey grid square, within which the route is located.' AS locationRemarks,
/*CAST(ROUND(cast(K.wgs84_lat*10 as numeric), 4)/10 AS float) AS decimalLatitude,  Trick to ROUND 5 figures after the comma! */
/*CAST(ROUND(cast(K.wgs84_lon*10 as numeric), 4)/10 AS float) AS decimalLongitude,  Trick to ROUND 5 figures after the comma! */
ROUND(K.wgs84_lat::float8::numeric, 5) AS decimalLatitude, /* already diffused all locations 25 000 */
ROUND(K.wgs84_lon::float8::numeric, 5) AS decimalLongitude, /* already diffused all locations 25 000 */
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Limited' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently these species are: Black stork (svart stork; Ciconia nigra), Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos),  Spotted eagle (större skrikörn; Clanga clanga), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus),  Montagu’s harrier (ängshök; Circus pygargus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Eagle owl (berguv; Bubo bubo), and White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos). Some data about biotopes at each point on especially older sites is available on request from data provider (see more info in metadata).' AS informationWithheld,
'false' as nullvisit
FROM mongo_sites I, mongo_centroidtopokartan K, mongo_totalsommarpkt T
left join IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum
WHERE I.kartatx=K.kartatx
AND I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES)
AND t.ind>0
AND T.yr<= :year_max

UNION

SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
'point transect survey' AS samplingProtocol,
CONCAT(ST.startdate,'/',ST.enddate) AS eventDate,
'' AS eventTime,
CAST(EXTRACT (doy from ST.startdate) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from ST.enddate) AS INTEGER) AS endDayOfYear,
I.stnregosid AS locationId,
CONCAT('SFTpkt:siteId:', cast(anonymizedId AS text)) AS verbatimLocality,
I.lan AS county,
'EPSG:4326' AS geodeticDatum,
17700 AS coordinateUncertaintyInMeters,
'The coordinates supplied are for the central point of a 25 x 25 km survey grid square, within which the route is located.' AS locationRemarks,
/* CAST(ROUND(cast(K.wgs84_lat*10 as numeric), 4)/10 AS float) AS decimalLatitude,  Trick to ROUND 5 figures after the comma! */
/* CAST(ROUND(cast(K.wgs84_lon*10 as numeric), 4)/10 AS float) AS decimalLongitude,  Trick to ROUND 5 figures after the comma! */
ROUND(K.wgs84_lat::float8::numeric, 5) AS decimalLatitude, /* already diffused all locations 25 000 */
ROUND(K.wgs84_lon::float8::numeric, 5) AS decimalLongitude, /* already diffused all locations 25 000 */
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Limited' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently these species are: Black stork (svart stork; Ciconia nigra), Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos),  Spotted eagle (större skrikörn; Clanga clanga), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus),  Montagu’s harrier (ängshök; Circus pygargus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Eagle owl (berguv; Bubo bubo), and White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos). Some data about biotopes at each point on especially older sites is available on request from data provider (see more info in metadata).' AS informationWithheld,
'true' as nullvisit
FROM mongo_sites I, mongo_centroidtopokartan K, IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS T
left join IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum
WHERE I.kartatx=K.kartatx
AND I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.yr<= :year_max


order by eventID;


/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/
/*
OCCURRENCES

To be fixed :
 - pkind: new DwC-A for points ?

*/

/*
genus
Loxia sp => 245
Larus sp => 301
Passer sp => 302
Melanitta sp => 319.
*/

CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_OCCURRENCE AS
SELECT
CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId, ':', E.dyntaxa_id) as occurrenceID,
CONCAT('SFT:recorderId:', Pe.anonymizedId) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
T.ind AS individualCount,
T.ind AS organismQuantity,
'individuals' AS organismQuantityType,
DA.suppliedname AS scientificName,
E.arthela AS vernacularName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
DA.genus AS genus,
DA.specificepithet AS specificEpithet,
DA.infraspecificepithet AS infraSpecificEpithet,
E.taxon_rank as taxonRank,
'SFTspkt' AS collectionCode,
'present' AS occurrenceStatus,
'The number of individuals observed is the sum total from all of the twenty points on the route.' AS occurrenceRemarks
FROM lists_module_biodiv E, IPT_SFTspkt.IPT_SFTspkt_DETAILSART DA, mongo_sites I, mongo_totalsommarpkt T
LEFT JOIN mongo_persons Pe ON Pe.persnr=T.persnr 
WHERE  T.art=E.art
AND DA.art=E.art
AND I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES)
AND t.ind>0
AND T.yr<= :year_max

UNION

SELECT
CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId, ':4000104') as occurrenceID,
CONCAT('SFT:recorderId:', Pe.anonymizedId) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
0 AS individualCount,
0 AS organismQuantity,
'individuals' AS organismQuantityType,
'Aves' AS scientificName,
'BirdsIncludedInSurvey' AS vernacularName,
'urn:lsid:dyntaxa.se:Taxon:4000104' AS taxonID,
'' AS genus,
'' AS specificEpithet,
'' AS infraSpecificEpithet,
'kingdom' AS taxonRank,
'SFTspkt' AS collectionCode,
'absent' AS occurrenceStatus,
'The number of individuals observed is the sum total from all of the twenty points on the route.' AS occurrenceRemarks
FROM mongo_sites I, IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS T
LEFT JOIN mongo_persons Pe ON Pe.persnr=T.persnr 
WHERE  I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.yr<= :year_max

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


CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_EMOF AS

SELECT
DISTINCT eventID,
'Location type' AS measurementType,
'Point' AS measurementValue
FROM IPT_SFTspkt.IPT_SFTspkt_SAMPLING

UNION

SELECT
DISTINCT eventID,
'Null visit' AS measurementType,
nullvisit AS measurementValue
FROM IPT_SFTspkt.IPT_SFTspkt_SAMPLING

UNION

SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
'Method of transport' AS measurementType,
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
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES)
AND T.yr<= :year_max
AND p01 IS NOT NULL

UNION

SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
'Snow on ground' AS measurementType,
CASE
    WHEN p02 = 1 THEN 'bare ground'
    WHEN p02 = 2 THEN 'snow covered ground'
    WHEN p02 = 3 THEN 'very thin or patchy cover of snow'
    ELSE ''
END AS measurementValue
FROM mongo_sites I, mongo_totalsommarpkt T
WHERE I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art='000'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES)
AND T.yr<= :year_max
AND p02 IS NOT NULL
order by eventID;
