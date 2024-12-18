\set database_name sft_iwc_from_mongo

\set year_max 2023

DROP TABLE IF EXISTS IPT_SFTiwc.IPT_SFTiwc_HIDDENSPECIES;
DROP TABLE IF EXISTS IPT_SFTiwc.IPT_SFTiwc_DETAILSART;
DROP TABLE IF EXISTS IPT_SFTiwc.IPT_SFTiwc_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTiwc.IPT_SFTiwc_OCCURRENCE;
DROP TABLE IF EXISTS IPT_SFTiwc.IPT_SFTiwc_OCCURRENCE_TODELETE;
DROP TABLE IF EXISTS IPT_SFTiwc.IPT_SFTiwc_EVENTSNOOBS;
DROP TABLE IF EXISTS IPT_SFTiwc.IPT_SFTiwc_MEDOBS;
DROP TABLE IF EXISTS IPT_SFTiwc.IPT_SFTiwc_EMOF;

DROP SCHEMA IF EXISTS IPT_SFTiwc;
CREATE SCHEMA IPT_SFTiwc;

/* concat all the mebobs for one survey*/ 
CREATE TABLE IPT_SFTiwc.IPT_SFTiwc_MEDOBS AS
select site, yr, month, period, method, STRING_AGG(CONCAT('SFT:recorderId:', cast(Pe.anonymizedid as text)), '|') AS listpersons
from mongo_iwc_medobs MO LEFT JOIN mongo_persons Pe ON MO.person=Pe.persnr
WHERE MO.person<>'IWC-XXXX'
group by site, yr, month, period, method;



/* REMOVE some occurrences based on the field iwc_list_details */
/* first add a field */
ALTER TABLE mongo_totaliwc ADD COLUMN IF NOT EXISTS skip boolean DEFAULT false;
UPDATE mongo_totaliwc SET skip=false;


CREATE TABLE IPT_SFTiwc.IPT_SFTiwc_OCCURRENCE_TODELETE AS

/* species jan-2017 */
SELECT site, yr, datum, period, T.art, 'jan-2017' as rule
FROM mongo_totaliwc T, lists_module_biodiv E
WHERE T.art=E.art
AND period='Januari'
AND E.iwc_list_details='jan-2017'
AND T.datum < '20170101'

UNION 

/* species jan-2020 */
SELECT site, yr, datum, period, T.art, 'jan-2020' as rule
FROM mongo_totaliwc T, lists_module_biodiv E
WHERE T.art=E.art
AND period='Januari'
AND E.iwc_list_details='jan-2020'
AND T.datum < '20200101'

UNION 

/* species jan-2021 */
SELECT site, yr, datum, period, T.art, 'jan-2021' as rule
FROM mongo_totaliwc T, lists_module_biodiv E
WHERE T.art=E.art
AND period='Januari'
AND E.iwc_list_details='jan-2021'
AND T.datum < '20210101'

UNION 

/* species jan-2021 */
SELECT site, yr, datum, period, T.art, 'no' as rule
FROM mongo_totaliwc T, lists_module_biodiv E
WHERE T.art=E.art
AND period='Januari'
AND E.iwc_list_details=''
;

UPDATE mongo_totaliwc SET skip=true
FROM IPT_SFTiwc.IPT_SFTiwc_OCCURRENCE_TODELETE D
WHERE D.site=mongo_totaliwc.site
AND D.yr=mongo_totaliwc.yr 
AND D.datum=mongo_totaliwc.datum 
AND D.art=mongo_totaliwc.art 
AND D.period=mongo_totaliwc.period 
;



CREATE TABLE IPT_SFTiwc.IPT_SFTiwc_EVENTSNOOBS AS
select datum, persnr, site, yr, metod, period
from (
    select datum, persnr, site, yr, metod, period, COUNT(*) as tot from mongo_totaliwc 
    where skip=false
    group by datum, persnr, site, yr, metod, period
) as eventnoobs
where tot=1;

/* TO BE REPLACED WITH PROPER SKYDKLASS */

CREATE TABLE IPT_SFTiwc.IPT_SFTiwc_HIDDENSPECIES AS
SELECT * FROM lists_module_biodiv
WHERE protected_adb LIKE '4%' or protected_adb LIKE '5%'; 

/*INSERT INTO IPT_SFTiwc.IPT_SFTiwc_EVENTSNOOBS VALUES ('20210826', '491210-1', '01', '2020');*/


CREATE TABLE IPT_SFTiwc.IPT_SFTiwc_DETAILSART AS
SELECT art, suppliedname, SPLIT_PART(suppliedname, ' ', 1) as genus, SPLIT_PART(suppliedname, ' ', 2) as specificEpithet, SPLIT_PART(suppliedname, ' ', 3) as infraSpecificEpithet 
FROM lists_module_biodiv;
/* Manual fix of the art that ends with "L" or "Li" or "T" */
UPDATE IPT_SFTiwc.IPT_SFTiwc_DETAILSART
SET infraSpecificEpithet=''
WHERE LENGTH(infraSpecificEpithet)>0 AND LENGTH(infraSpecificEpithet)<3;
/* rebuild the suppliedname without the extra L and i */
UPDATE IPT_SFTiwc.IPT_SFTiwc_DETAILSART
SET suppliedname= trim(concat(genus, ' ', specificepithet, ' ', infraspecificepithet));

/*

To be fixed
 - convert startTime with timezone

*/

CREATE TABLE IPT_SFTiwc.IPT_SFTiwc_SAMPLING AS
SELECT 
distinct CONCAT('SFTssij:', T.datum, ':', T.site, ':', UPPER(LEFT(T.metod, 1))) as eventID,
CONCAT('SFTssij:', T.yr, ':January') as parentEventID,
'Swedish Bird Survey: Swedish waterbird census (January)' as datasetName,
'event' as eventType,
CASE 
    WHEN T.metod='båt' THEN 'from boat' 
    WHEN T.metod='flyg' THEN 'from aeroplane' 
    WHEN T.metod='land' THEN 'from land' 
    WHEN T.metod='X' THEN '' 
end AS samplingProtocol,
REPLACE(CAST(I.area AS text), '.', ',') as sampleSizeValue,
'square kilometres' as sampleSizeUnit,
CONCAT(CAST(TO_DATE(datum, 'YYYYMMDD') as text),'/',CAST(TO_DATE(datum, 'YYYYMMDD') as text)) AS eventDate,
TO_DATE(t.datum,'YYYYMMDD') AS eventDateTempForMinMax,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
'Note that the different methods used during different events can result in different numbers.' as eventRemarks,
I.stnregosid AS locationId,
CONCAT('SFTssi:siteId:', T.site) AS locality,
C.name AS county,
'EPSG:4326' AS geodeticDatum,
8000 AS coordinateUncertaintyInMeters,
'The coordinates supplied are for the central point of the counting sector.' AS locationRemarks,
I.decimallatitude AS decimalLatitude, 
I.decimallongitude AS decimalLongitude,
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Full access' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'false' as nullvisit,
I.ki as locationType, /* for EMOF */
T.ice as snowIceCover /* for EMOF */
FROM mongo_totaliwc T, mongo_sites I
LEFT JOIN county C ON I.lan=C.code
WHERE I.internalsiteid=T.site
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTiwc.IPT_SFTiwc_HIDDENSPECIES)
AND t.antal>0
AND T.period='Januari'
AND skip=false
AND T.yr<=:year_max


UNION

SELECT 
distinct CONCAT('SFTssij:', T.datum, ':', T.site, ':', UPPER(LEFT(T.metod, 1))) as eventID,
CONCAT('SFTssij:', T.yr, ':January') as parentEventID,
'Swedish Bird Survey: Swedish waterbird census (January)' as datasetName,
'event' as eventType,
CASE 
    WHEN T.metod='båt' THEN 'from boat' 
    WHEN T.metod='flyg' THEN 'from aeroplane' 
    WHEN T.metod='land' THEN 'from land' 
    WHEN T.metod='X' THEN '' 
end AS samplingProtocol,
REPLACE(CAST(I.area AS text), '.', ',') as sampleSizeValue,
'square kilometres' as sampleSizeUnit,
CONCAT(CAST(TO_DATE(datum, 'YYYYMMDD') as text),'/',CAST(TO_DATE(datum, 'YYYYMMDD') as text)) AS eventDate,
TO_DATE(t.datum,'YYYYMMDD') AS eventDateTempForMinMax,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
'Note that the different methods used during different events can result in different numbers.' as eventRemarks,
I.stnregosid AS locationId,
CONCAT('SFTssi:siteId:', T.site) AS locality,
C.name AS county,
'EPSG:4326' AS geodeticDatum,
8000 AS coordinateUncertaintyInMeters,
'The coordinates supplied are for the central point of the counting sector.' AS locationRemarks,
I.decimallatitude AS decimalLatitude, 
I.decimallongitude AS decimalLongitude,
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Full access' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'true' as nullvisit,
I.ki as locationType, /* for EMOF */
null as snowIceCover /* for EMOF */
FROM IPT_SFTiwc.IPT_SFTiwc_EVENTSNOOBS T, mongo_sites I
LEFT JOIN county C ON I.lan=C.code
WHERE I.internalsiteid=T.site
AND T.period='Januari'
AND T.yr<=:year_max

order by eventID;


/* add the SEASON events from the sampling table */
INSERT INTO IPT_SFTiwc.IPT_SFTiwc_sampling 
(eventID, datasetName, eventDate, eventType, country, countryCode, continent, institutionCode, ownerInstitutionCode)
SELECT
distinct parenteventid,
'Swedish Bird Survey: Swedish waterbird census (January)',
CONCAT(MIN(eventDateTempForMinMax), '/', MAX(eventDateTempForMinMax)), 
'season',
'Sweden',
'SE',
'EUROPE',
'Lund University',
'Swedish Environmental Protection Agency'
FROM IPT_SFTiwc.IPT_SFTiwc_sampling iss 
WHERE eventtype='event'
GROUP BY parenteventid
ORDER BY parenteventid;


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

CREATE TABLE IPT_SFTiwc.IPT_SFTiwc_OCCURRENCE AS
SELECT
CONCAT('SFTssij:', T.datum, ':', T.site, ':', UPPER(LEFT(T.metod, 1))) as eventID,
CONCAT('SFTssij:', T.datum, ':', T.site, ':', UPPER(LEFT(T.metod, 1)), ':', E.dyntaxa_id) as occurrenceID,
Pe.listpersons AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
T.antal AS individualCount,
T.antal AS organismQuantity,
'individuals' AS organismQuantityType,
DA.suppliedname AS scientificName,
E.arthela AS vernacularName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
DA.genus AS genus,
DA.specificepithet AS specificEpithet,
DA.infraspecificepithet AS infraSpecificEpithet,
'' AS scientificNameAuthorship,
E.eu_sp_code AS euTaxonID, /* for EMOF */
E.taxon_rank as taxonRank,
'SFTssij' AS collectionCode,
'present' AS occurrenceStatus,
'The number of individuals observed is the sum total from this site during this visit.' AS occurrenceRemarks
FROM lists_module_biodiv E, IPT_SFTiwc.IPT_SFTiwc_DETAILSART DA, mongo_sites I, mongo_totaliwc T
LEFT JOIN IPT_SFTiwc.IPT_SFTiwc_MEDOBS Pe ON Pe.site=T.site and Pe.yr=T.yr and Pe.period=T.period and Pe.method=t.metod
WHERE  T.art=E.art
AND DA.art=E.art
AND I.internalsiteid=T.site
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTiwc.IPT_SFTiwc_HIDDENSPECIES)
AND t.antal>0
AND T.period='Januari'
AND skip=false
AND T.yr<=:year_max

UNION

SELECT
CONCAT('SFTssij:', T.datum, ':', T.site, ':', UPPER(LEFT(T.metod, 1))) as eventID,
CONCAT('SFTssij:', T.datum, ':', T.site, ':', UPPER(LEFT(T.metod, 1)), ':4000104') as occurrenceID,
Pe.listpersons AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
0 AS individualCount,
0 AS organismQuantity,
'individuals' AS organismQuantityType,
'Aves' AS scientificName,
'SpeciesIncludedInSurvey' AS vernacularName,
'urn:lsid:dyntaxa.se:Taxon:4000104' AS taxonID,
'' AS genus,
'' AS specificEpithet,
'' AS infraSpecificEpithet,
'' AS scientificNameAuthorship,
'' AS euTaxonID, /* for EMOF */
'class' AS taxonRank,
'SFTssij' AS collectionCode,
'absent' AS occurrenceStatus,
'The number of individuals observed is the sum total from this site during this visit.' AS occurrenceRemarks
FROM mongo_sites I, IPT_SFTiwc.IPT_SFTiwc_EVENTSNOOBS T
LEFT JOIN IPT_SFTiwc.IPT_SFTiwc_MEDOBS Pe ON Pe.site=T.site and Pe.yr=T.yr and Pe.period=T.period  and Pe.method=t.metod
WHERE  I.internalsiteid=T.site
AND T.period='Januari'
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
 occurrenceID to SFTssij:19750412:500:nullobs. 
 // But there doesn'ät seem to be any events without observations.

*/

/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


CREATE TABLE IPT_SFTiwc.IPT_SFTiwc_EMOF AS 

SELECT 
DISTINCT eventID,
null as occurrenceID,
'locationProtected' AS measurementType,
'no' AS measurementValue
FROM IPT_SFTiwc.IPT_SFTiwc_SAMPLING
WHERE eventtype='event'

UNION 

SELECT
DISTINCT eventID,
null as occurrenceID,
'locationType' AS measurementType,
CASE
    WHEN locationType='K' THEN 'counting sector, coastal'
    WHEN locationType='I' THEN 'counting sector, inland'
END AS measurementValue
FROM IPT_SFTiwc.IPT_SFTiwc_SAMPLING
WHERE eventtype='event'

UNION

SELECT
DISTINCT eventID,
null as occurrenceID,
'snowIceCover' AS measurementType,
CONCAT(snowIceCover, ' ice') AS measurementValue
FROM IPT_SFTiwc.IPT_SFTiwc_SAMPLING
WHERE eventtype='event'
AND snowIceCover <>''

UNION 

SELECT
DISTINCT eventID,
null as occurrenceID,
'noObservations' AS measurementType,
nullvisit AS measurementValue
FROM IPT_SFTiwc.IPT_SFTiwc_SAMPLING
WHERE eventtype='event'

UNION


SELECT
null as eventID,
occurrenceID,
'euTaxonID' AS measurementType,
euTaxonID AS measurementValue
FROM IPT_SFTiwc.IPT_SFTiwc_OCCURRENCE
WHERE occurrenceStatus='present' and euTaxonID<>''
;
