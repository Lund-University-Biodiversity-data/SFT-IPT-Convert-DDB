\i lib/config.sql

\c :database_name

\set year_max 2021

DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_OCCURENCE;
DROP TABLE IF EXISTS IPT_SFTspkt.IPT_SFTspkt_EMOF;


/* START TIME */
CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME AS
SELECT persnr, rnr, datum, LPAD(CAST(p03 AS text), 4, '0') AS startTime, LPAD(CAST(p04 AS text), 4, '0') AS endTime
from totalsommar_pkt
WHERE art='000';

/*

To be fixed
 - convert startTime with timezone

*/

CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_SAMPLING AS
SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', P.location_id) as eventID,
'Point transect survey : http://www.fageltaxering.lu.se/inventera/metoder/punktrutter/metodik-sommarpunktrutter' AS samplingProtocol,
TO_DATE(t.datum,'YYYYMMDD') AS eventDate,
CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),'/',left(ST.endTime, length(cast(ST.endTime as text))-2), ':', right(ST.endTime, 2)) AS eventTime,
EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS startDayOfYear,
EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS endDayOfYear,
CONCAT('http://stationsregister.miljodatasamverkan.se/so/ef/environmentalmonitoringfacility/pp/', P.nat_stn_reg) AS locationId,
CONCAT('SFTspkt:siteId:', P.location_id) AS internalSiteId,
P.lan AS county,
'EPSG:4326' AS geodeticDatum,
ROUND(cast(K.wgs84_lat as numeric), 3) AS decimalLatitude,
ROUND(cast(K.wgs84_lon as numeric), 3) AS decimalLongitude,
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'Dataset' as type,
'English' as language,
'Free usage' as accessRights,
'false' as nullvisit
FROM koordinater_mittpunkt_topokartan K, punktrutter P, totalsommar_pkt T
left join IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum
WHERE K.kartatx=P.kartatx
AND P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND t.ind>0
AND T.yr< :year_max
order by eventID;


/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/
/*
OCCURENCES

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

CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_OCCURENCE AS
SELECT
CONCAT('SFTspkt:', T.datum, ':', P.location_id) as eventID,
CONCAT('SFTsptk:', T.datum, ':', P.location_id, ':', E.dyntaxa_id) as occurenceID,
CONCAT('SFT:recorderId:', Pe.idPerson) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'The number of individuals observed is the sum total from all of the twenty points on the route. Some data about biotopes at each point on especially older sites is available on request from data provider (see more info in metadata).' AS informationWithheld,
'Animalia' AS kingdom,
T.ind AS organismQuantity,
'individuals' AS organismQuantityType,
E.latin AS scientificName,
E.arthela AS vernacularName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
genus AS genus,
species AS specificEpithet,
E.taxon_rank AS taxonRank,
'SFTspkt' AS collectionCode,
'Lund University' AS institutionCode,
'present' AS occurenceStatus
FROM eurolist E, punktrutter P, totalsommar_pkt T
LEFT JOIN IPT_SFTspkt.IPT_SFTspkt_CONVERT_PERSON Pe ON Pe.persnr=T.persnr 
WHERE  T.art=E.art
AND P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND t.ind>0
AND T.yr< :year_max
ORDER BY eventID, taxonID;


/*
ver 1.2 // Add events without observations, set
 scientificName to Aves, taxonId to 4000104, 
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
distinct CONCAT('SFTspkt:', T.datum, ':', P.location_id) as eventID,
'Method of transport' AS measurementType,
CASE
    WHEN p01 = 1 THEN '1- on foot'
    WHEN p01 = 2 THEN '2- by bike or moped'
    WHEN p01 = 3 THEN '3- by car or motorcycle'
    WHEN p01 = 4 THEN '4- other'
    ELSE ''
END AS measurementValue
FROM punktrutter P, totalsommar_pkt T
WHERE P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art='000'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND T.yr< :year_max
AND p01 IS NOT NULL

UNION

SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', P.location_id) as eventID,
'Snow on ground' AS measurementType,
CASE
    WHEN p02 = 1 THEN '1- bare ground'
    WHEN p02 = 2 THEN '2- snow covered ground'
    WHEN p02 = 3 THEN '3- very thin or patchy cover of snow'
    ELSE ''
END AS measurementValue
FROM punktrutter P, totalsommar_pkt T
WHERE P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art='000'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND T.yr< :year_max
AND p02 IS NOT NULL
order by eventID;
