\i lib/config.sql

/*\c :database_name*/
\set database_name sft_vpkt_from_mongo_to_dwca

\set year_max 2021

DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_HIDDENSPECIES;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_STARTENDTIME;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_DETAILSART;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_OCCURRENCE;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_EMOF;

DROP SCHEMA IF EXISTS IPT_SFTvpkt;
CREATE SCHEMA IPT_SFTvpkt;

/* Make sure that the art column contains 3 digits */
UPDATE mongo_totalvinterpkt SET art = LPAD(art, 3, '0')
WHERE length(art)<3;
UPDATE lists_module_biodiv SET art = LPAD(art, 3, '0')
WHERE length(art)<3;

CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS AS
select datum, persnr, rnr, yr, per
from (
    select datum, persnr, rnr, yr, per, COUNT(*) as tot from mongo_totalvinterpkt 
    group by datum, persnr, yr, rnr, per
) as eventnoobs
where tot=1;

/* TO BE REPLACED WITH PROPER SKYDKLASS */

CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_HIDDENSPECIES AS
SELECT * FROM lists_module_biodiv
WHERE dyntaxa_id in ('100005', '100008', '100011', '100020', '100032', '100035', '100039', '100046', '100054', '100055', '100057', '100066', '100067', '100093', '100142', '100145', '103061', '103071', '205543', '267320'); 
/* and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTvpkt.IPT_SFTvpkt_HIDDENSPECIES) */


/*INSERT INTO IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS VALUES ('20210826', '491210-1', '01', '2020');*/

/* START TIME */
CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_STARTENDTIME AS
/*SELECT persnr, rnr, datum, per, LPAD(CAST(p03 AS text), 4, '0') AS startTime, LPAD(CAST(p04 AS text), 4, '0') AS endTime*/
SELECT persnr, rnr, datum, per, p03 AS startTime, p04 AS endTime
from mongo_totalvinterpkt
WHERE art='000';


CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_DETAILSART AS
SELECT art, suppliedname, SPLIT_PART(suppliedname, ' ', 1) as genus, SPLIT_PART(suppliedname, ' ', 2) as specificEpithet, SPLIT_PART(suppliedname, ' ', 3) as infraSpecificEpithet 
FROM lists_module_biodiv;
/* Manual fix of the art that ends with "L" or "Li" or "T" */
UPDATE IPT_SFTvpkt.IPT_SFTvpkt_DETAILSART
SET infraSpecificEpithet=''
WHERE LENGTH(infraSpecificEpithet)>0 AND LENGTH(infraSpecificEpithet)<3;
/* rebuild the suppliedname without the extra L and i */
UPDATE IPT_SFTvpkt.IPT_SFTvpkt_DETAILSART
SET suppliedname= trim(concat(genus, ' ', specificepithet, ' ', infraspecificepithet));

/*

To be fixed
 - convert startTime with timezone

*/

CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING AS
SELECT 
distinct CONCAT('SFTvpkt:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTvpkt:', T.yr, '-', (T.yr + 1), ':per', T.per) as parentEventID,
CONCAT('SFTvpkt:', T.yr, '-', (T.yr + 1)) as superparentEventID, /* ONLY FOR CREATING the season level */
/* T.per AS periodWinter, */
'event' as eventType,
'point transect survey' AS samplingProtocol,
CAST(TO_DATE(t.datum,'YYYYMMDD') AS TEXT) AS eventDate, /* cast as text to allow range later */
/*
CASE 
    WHEN ST.startTime IS NULL and ST.endTime IS NULL THEN ''
    WHEN ST.startTime IS NOT NULL and ST.endTime IS NULL THEN CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2), '/')
    WHEN ST.startTime IS NULL and ST.endTime IS NOT NULL THEN CONCAT('/',left(ST.endTime, length(cast(ST.endTime as text))-2), ':', right(ST.endTime, 2)) 
    ELSE CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),'/',left(ST.endTime, length(cast(ST.endTime as text))-2), ':', right(ST.endTime, 2))
END AS eventTime,
*/
CONCAT(ST.startTime,'/',ST.endTime) AS eventTime,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
I.staregosid AS locationId,
CONCAT('SFTpkt:siteId:', I.anonymizedId) AS internalSiteId,
I.lan AS county,
'EPSG:4326' AS geodeticDatum,
17700 AS coordinateUncertaintyInMeters,
'The coordinates supplied are for the central point of a 25 x 25 km survey grid square, within which the route is located.' AS locationRemarks,
CAST(ROUND(cast(K.wgs84_lat*10 as numeric), 4)/10 AS float) AS decimalLatitude, /* Trick to ROUND 5 figures after the comma! */
CAST(ROUND(cast(K.wgs84_lon*10 as numeric), 4)/10 AS float) AS decimalLongitude, /* Trick to ROUND 5 figures after the comma! */
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Limited' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently these species are: Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos),  Spotted eagle (större skrikörn; Clanga clanga), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Barn owl (tornuggla; Tyto alba), Eagle owl (berguv; Bubo bubo), Snowy owl (fjälluggla; Bubo scandiacus), and White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos). Some data about biotopes at each point on especially older sites is available on request from data provider (see more info in metadata).' AS informationWithheld,
'false' as nullvisit
FROM mongo_centroidtopokartan K, mongo_sites I, mongo_totalvinterpkt T
left join IPT_SFTvpkt.IPT_SFTvpkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum AND T.per=ST.per
WHERE I.kartatx=K.kartatx
AND I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTvpkt.IPT_SFTvpkt_HIDDENSPECIES)
AND t.ind>0
AND T.yr<=:year_max

UNION

SELECT 
distinct CONCAT('SFTvpkt:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTvpkt:', T.yr, '-', (T.yr + 1), ':per', T.per) as parentEventID,
CONCAT('SFTvpkt:', T.yr, '-', (T.yr + 1)) as superparentEventID, /* ONLY FOR CREATING the season level */
/* T.per AS periodWinter, */
'event' as eventType,
'point transect survey' AS samplingProtocol,
CAST(TO_DATE(t.datum,'YYYYMMDD') AS TEXT) AS eventDate, /* cast as text to allow range later */
CONCAT(ST.startTime,'/',ST.endTime) AS eventTime,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
I.staregosid AS locationId,
CONCAT('SFTpkt:siteId:', I.anonymizedId) AS internalSiteId,
I.lan AS county,
'EPSG:4326' AS geodeticDatum,
17700 AS coordinateUncertaintyInMeters,
'The coordinates supplied are for the central point of a 25 x 25 km survey grid square, within which the route is located.' AS locationRemarks,
CAST(ROUND(cast(K.wgs84_lat*10 as numeric), 4)/10 AS float) AS decimalLatitude, /* Trick to ROUND 5 figures after the comma! */
CAST(ROUND(cast(K.wgs84_lon*10 as numeric), 4)/10 AS float) AS decimalLongitude, /* Trick to ROUND 5 figures after the comma! */
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Limited' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently these species are: Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos),  Spotted eagle (större skrikörn; Clanga clanga), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Barn owl (tornuggla; Tyto alba), Eagle owl (berguv; Bubo bubo), Snowy owl (fjälluggla; Bubo scandiacus), and White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos). Some data about biotopes at each point on especially older sites is available on request from data provider (see more info in metadata).' AS informationWithheld,
'true' as nullvisit
FROM mongo_centroidtopokartan K, mongo_sites I, IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS T
left join IPT_SFTvpkt.IPT_SFTvpkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum AND T.per=ST.per
WHERE I.kartatx=K.kartatx
AND I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.yr<=:year_max

order by eventID;

/* add the PERIOD events from the sampling table */
INSERT INTO ipt_sftvpkt.ipt_sftvpkt_sampling (eventID, parentEventID, eventDate, eventType, country, countryCode, continent)
SELECT
distinct parenteventid,
superparenteventid,
CONCAT(MIN(eventdate), '/', MAX(eventdate)), 
'period',
'Sweden',
'SE',
'EUROPE'
FROM ipt_sftvpkt.ipt_sftvpkt_sampling iss 
GROUP BY parenteventid,superparenteventid
ORDER BY parenteventid;


/* add the SEASON events from the sampling table */
INSERT INTO ipt_sftvpkt.ipt_sftvpkt_sampling (eventID, eventDate, eventType, country, countryCode, continent)
SELECT
superparenteventid,
CONCAT(MIN(eventdate), '/', MAX(eventdate)), 
'season',
'Sweden',
'SE',
'EUROPE'
FROM ipt_sftvpkt.ipt_sftvpkt_sampling iss 
WHERE eventtype='event'
GROUP BY superparenteventid
ORDER BY superparenteventid;


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

CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_OCCURRENCE AS
SELECT
CONCAT('SFTvpkt:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTvpkt:', T.datum, ':', I.anonymizedId, ':', E.dyntaxa_id) as occurrenceID,
CONCAT('SFT:recorderId:', Pe.anonymizedId) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
T.ind AS individualCount,
T.ind AS organismQuantity,
'individuals' AS organismQuantityType,
DA.suppliedname AS scientificName,
E.arthela AS vernacularName,
E.dyntaxa_id AS taxonID,
DA.genus AS genus,
DA.specificepithet AS specificEpithet,
DA.infraspecificepithet AS infraSpecificEpithet,
CASE 
    WHEN T.art IN ('245', '301', '302', '319') THEN 'genus' 
    WHEN T.art IN ('237', '260', '261', '508', '509', '526', '536', '566', '608', '609', '626', '636', '666', '731') THEN 'subspecies' 
    WHEN T.art IN ('418') THEN 'speciesAggregate' 
    ELSE 'species' 
END AS taxonRank,
'SFTvpkt' AS collectionCode,
'present' AS occurrenceStatus,
'The number of individuals observed is the sum total from all of the twenty points on the route.' AS occurrenceRemarks
FROM lists_module_biodiv E, IPT_SFTvpkt.IPT_SFTvpkt_DETAILSART DA, mongo_sites I, mongo_totalvinterpkt T
LEFT JOIN mongo_persons Pe ON Pe.persnr=T.persnr 
WHERE  T.art=E.art
AND DA.art=E.art
AND I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTvpkt.IPT_SFTvpkt_HIDDENSPECIES)
AND t.ind>0
AND T.yr<=:year_max

UNION

SELECT
CONCAT('SFTvpkt:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTvpkt:', T.datum, ':', I.anonymizedId, ':4000104') as occurrenceID,
CONCAT('SFT:recorderId:', Pe.anonymizedId) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
0 AS individualCount,
0 AS organismQuantity,
'individuals' AS organismQuantityType,
'Aves' AS scientificName,
'SpeciesIncludedInSurvey' AS vernacularName,
'4000104' AS taxonID,
'' AS genus,
'' AS specificEpithet,
'' AS infraSpecificEpithet,
'class' AS taxonRank,
'SFTvpkt' AS collectionCode,
'absent' AS occurrenceStatus,
'The number of individuals observed is the sum total from all of the twenty points on the route.' AS occurrenceRemarks
FROM mongo_sites I, IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS T
LEFT JOIN mongo_persons Pe ON Pe.persnr=T.persnr 
WHERE  I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.yr<=:year_max

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
 occurrenceID to SFTvpkt:19750412:500:nullobs. 
 // But there doesn'ät seem to be any events without observations.

*/

/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_EMOF AS

SELECT
DISTINCT eventID,
'Internal site Id' AS measurementType,
internalSiteId AS measurementValue
FROM IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING
WHERE eventtype='event'

UNION 

SELECT
DISTINCT eventID,
'Location type' AS measurementType,
'Point' AS measurementValue
FROM IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING
WHERE eventtype='event'

UNION

SELECT
DISTINCT eventID,
'Null visit' AS measurementType,
nullvisit AS measurementValue
FROM IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING
WHERE eventtype='event'

UNION
/* REMOVE. This info is provided through parentEventIDs instead.
SELECT
DISTINCT eventID,
'Survey period' AS measurementType,
CAST(periodWinter AS text) AS measurementValue
FROM IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING

UNION
*/
SELECT 
distinct CONCAT('SFTvpkt:', T.datum, ':', I.anonymizedId) as eventID,
'Method of transport' AS measurementType,
CASE
    WHEN p01 = 1 THEN 'on foot or skis'
    WHEN p01 = 2 THEN 'by bike or moped'
    WHEN p01 = 3 THEN 'by car or motorcycle'
    WHEN p01 = 4 THEN 'other'
    ELSE ''
END AS measurementValue
FROM mongo_sites I, mongo_totalvinterpkt T
WHERE I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art='000'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTvpkt.IPT_SFTvpkt_HIDDENSPECIES)
AND T.yr<=:year_max
AND p01 IS NOT NULL

UNION

SELECT 
distinct CONCAT('SFTvpkt:', T.datum, ':', I.anonymizedId) as eventID,
'Snow on ground' AS measurementType,
CASE
    WHEN p02 = 1 THEN 'bare ground'
    WHEN p02 = 2 THEN 'snow covered ground'
    WHEN p02 = 3 THEN 'very thin or patchy cover of snow'
    ELSE ''
END AS measurementValue
FROM mongo_sites I, mongo_totalvinterpkt T
WHERE I.internalsiteid=CONCAT(T.persnr, '-', LPAD(CAST(T.rnr AS text), 2, '0'))
AND T.art='000'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTvpkt.IPT_SFTvpkt_HIDDENSPECIES)
AND T.yr<=:year_max
AND p02 IS NOT NULL
AND p02 IN (1,2,3) /* exclude the wrong values */
order by eventID;
