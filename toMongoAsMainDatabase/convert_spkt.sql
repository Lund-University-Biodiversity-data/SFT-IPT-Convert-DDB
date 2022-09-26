\i lib/config.sql

/*\c :database_name*/
\set database_name sft_spkt_from_mongo_to_dwca


/* TO BE CHANGED TO Y-1 TO USE year_max<= instead of < */
\set year_max 2022

DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_OCCURRENCE;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_EMOF;

DROP SCHEMA IF EXISTS IPT_SFTspkt;
CREATE SCHEMA IPT_SFTspkt;


/* TO BE REPLACED WITH PROPER SKYDKLASS */

CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES AS
SELECT * FROM lists_eurolist
WHERE dyntaxa_id in ('100005', '100008', '100011', '100020', '100032', '100035', '100039', '100046', '100054', '100055', '100057', '100066', '100067', '100093', '100142', '100145', '103061', '103071', '205543', '267320'); 
/* and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES) */


CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS AS
select datum, persnr, rnr, yr
from (
    select datum, persnr, rnr, yr, COUNT(*) as tot from mongo_totalsommarpkt 
    WHERE art not in ('000', '999') 
    AND yr< :year_max
    group by datum, persnr, yr, rnr
) as eventnoobs
where tot=0;


/*INSERT INTO IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS VALUES ('20210826', '491210-1', '01', '2020');*/

/* START TIME */
CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME AS
/*SELECT persnr, rnr, datum, LPAD(CAST(p03 AS text), 4, '0') AS startTime, LPAD(CAST(p04 AS text), 4, '0') AS endTime*/
SELECT persnr, rnr, datum, p03 AS startTime, p04 AS endTime
from mongo_totalsommarpkt
WHERE art='000';


/*

To be fixed
 - convert startTime with timezone

*/

CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_SAMPLING AS
SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
'point transect survey' AS samplingProtocol,
TO_DATE(t.datum,'YYYYMMDD') AS eventDate,
/*CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),'/',left(ST.endTime, length(cast(ST.endTime as text))-2), ':', right(ST.endTime, 2)) AS eventTime,*/
CONCAT(ST.startTime,'/',ST.endTime) AS eventTime,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
I.staregosid AS locationId,
CONCAT('SFTpkt:siteId:', I.anonymizedId) AS internalSiteId,
I.lan AS county,
'EPSG:4326' AS geodeticDatum,
ROUND(cast(K.wgs84_lat as numeric), 5) AS decimalLatitude,
ROUND(cast(K.wgs84_lon as numeric), 5) AS decimalLongitude,
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Free usage' as accessRights,
'false' as nullvisit
FROM mongo_sites I, mongo_centroidtopokartan K, mongo_totalsommarpkt T
left join IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum
WHERE I.kartatx=K.kartatx
AND I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES)
AND t.ind>0
AND T.yr< :year_max

UNION

SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
'Point transect survey. http://www.fageltaxering.lu.se/inventera/metoder/punktrutter/metodik-sommarpunktrutter' AS samplingProtocol,
TO_DATE(t.datum,'YYYYMMDD') AS eventDate,
'' AS eventTime,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
I.staregosid AS locationId,
CONCAT('SFTpkt:siteId:', I.anonymizedId) AS internalSiteId,
I.lan AS county,
'EPSG:4326' AS geodeticDatum,
ROUND(cast(K.wgs84_lat as numeric), 5) AS decimalLatitude,
ROUND(cast(K.wgs84_lon as numeric), 5) AS decimalLongitude,
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Free usage' as accessRights,
'true' as nullvisit
FROM mongo_sites I, mongo_centroidtopokartan K, IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS T
left join IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum
WHERE I.kartatx=K.kartatx
AND I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.yr< :year_max


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
'The number of individuals observed is the sum total from all of the twenty points on the route. Some data about biotopes at each point on especially older sites is available on request from data provider (see more info in metadata). Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently these species are: Black stork (svart stork; Ciconia nigra), Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos),  Spotted eagle (större skrikörn; Clanga clanga), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus),  Montagu’s harrier (ängshök; Circus pygargus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Eagle owl (berguv; Bubo bubo), and White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos). The coordinates supplied are for the central point of a 25 x 25 km survey grid square, within which the route is located.' AS informationWithheld,
'Animalia' AS kingdom,
T.ind AS organismQuantity,
'individuals' AS organismQuantityType,
E.SuppliedName AS scientificName,
E.arthela AS vernacularName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
genus AS genus,
species AS specificEpithet,
CASE 
    WHEN T.art IN ('245', '301', '302', '319') THEN 'genus' 
    WHEN T.art IN ('237', '260', '261', '508', '509', '526', '536', '566', '608', '609', '626', '636', '666', '731') THEN 'subspecies' 
    WHEN T.art IN ('418') THEN 'speciesAggregate' 
    ELSE 'species' 
END AS taxonRank,
'SFTspkt' AS collectionCode,
'Lund University' AS institutionCode,
'present' AS occurrenceStatus
FROM lists_eurolist E, mongo_sites I, mongo_totalsommarpkt T
LEFT JOIN mongo_persons Pe ON Pe.persnr=T.persnr 
WHERE  T.art=E.art
AND I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTspkt.IPT_SFTspkt_HIDDENSPECIES)
AND t.ind>0
AND T.yr< :year_max

UNION

SELECT
CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTspkt:', T.datum, ':', I.anonymizedId, ':4000104') as occurrenceID,
CONCAT('SFT:recorderId:', Pe.anonymizedId) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'The number of individuals observed is the sum total from all of the twenty points on the route. Some data about biotopes at each point on especially older sites is available on request from data provider (see more info in metadata). Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently these species are: Black stork (svart stork; Ciconia nigra), Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos),  Spotted eagle (större skrikörn; Clanga clanga), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus),  Montagu’s harrier (ängshök; Circus pygargus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Eagle owl (berguv; Bubo bubo), and White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos). The coordinates supplied are for the central point of a 25 x 25 km survey grid square, within which the route is located.' AS informationWithheld,
'Animalia' AS kingdom,
0 AS organismQuantity,
'individuals' AS organismQuantityType,
'Aves' AS scientificName,
'BirdsIncludedInSurvey' AS vernacularName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:4000104') AS taxonID,
'' AS genus,
'' AS specificEpithet,
'kingdom' AS taxonRank,
'SFTspkt' AS collectionCode,
'Lund University' AS institutionCode,
'absent' AS occurrenceStatus
FROM mongo_sites I, IPT_SFTspkt.IPT_SFTspkt_EVENTSNOOBS T
LEFT JOIN mongo_persons Pe ON Pe.persnr=T.persnr 
WHERE  I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.yr< :year_max

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
'Internal site Id' AS measurementType,
internalSiteId AS measurementValue
FROM IPT_SFTspkt.IPT_SFTspkt_SAMPLING

UNION 

SELECT
DISTINCT eventID,
'Site geometry' AS measurementType,
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
AND T.yr< :year_max
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
AND T.yr< :year_max
AND p02 IS NOT NULL
order by eventID;