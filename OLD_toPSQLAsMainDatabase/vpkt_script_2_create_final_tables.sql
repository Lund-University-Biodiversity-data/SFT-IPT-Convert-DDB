\i lib/config.sql

\c :database_name

\set year_max 2020

DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_STARTENDTIME;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_OCCURENCE;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS;
DROP TABLE IF EXISTS IPT_SFTvpkt.IPT_SFTvpkt_EMOF;

CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS AS
select datum, persnr, rnr, yr, per
from (
    select datum, persnr, rnr, yr, per, COUNT(*) as tot from totalvinter_pkt 
    group by datum, persnr, yr, rnr, per
) as eventnoobs
where tot=1;


/*INSERT INTO IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS VALUES ('20210826', '491210-1', '01', '2020');*/

/* START TIME */
CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_STARTENDTIME AS
SELECT persnr, rnr, datum, per, LPAD(CAST(p03 AS text), 4, '0') AS startTime, LPAD(CAST(p04 AS text), 4, '0') AS endTime
from totalvinter_pkt
WHERE art='000';


/*

To be fixed
 - convert startTime with timezone

*/

CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING AS
SELECT 
distinct CONCAT('SFTvpkt:', T.datum, ':', P.location_id) as eventID,
'Point transect survey. http://www.fageltaxering.lu.se/inventera/metoder/punktrutter/metodik-sommarpunktrutter' AS samplingProtocol,
TO_DATE(t.datum,'YYYYMMDD') AS eventDate,
CASE 
    WHEN ST.startTime IS NULL and ST.endTime IS NULL THEN ''
    WHEN ST.startTime IS NOT NULL and ST.endTime IS NULL THEN CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2), '/')
    WHEN ST.startTime IS NULL and ST.endTime IS NOT NULL THEN CONCAT('/',left(ST.endTime, length(cast(ST.endTime as text))-2), ':', right(ST.endTime, 2)) 
    ELSE CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),'/',left(ST.endTime, length(cast(ST.endTime as text))-2), ':', right(ST.endTime, 2))
END AS eventTime,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
CONCAT('http://stationsregister.miljodatasamverkan.se/so/ef/environmentalmonitoringfacility/os/', P.nat_stn_reg) AS locationId,
CONCAT('SFTpkt:siteId:', P.location_id) AS internalSiteId,
P.lan AS county,
T.per AS periodWinter,
'EPSG:4326' AS geodeticDatum,
ROUND(cast(K.wgs84_lat as numeric), 5) AS decimalLatitude,
ROUND(cast(K.wgs84_lon as numeric), 5) AS decimalLongitude,
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'Dataset' as type,
'English' as language,
'Free usage' as accessRights,
'false' as nullvisit
FROM koordinater_mittpunkt_topokartan K, punktrutter P, totalvinter_pkt T
left join IPT_SFTvpkt.IPT_SFTvpkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum AND T.per=ST.per
WHERE K.kartatx=P.kartatx
AND P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND t.ind>0
AND T.yr< :year_max

UNION

SELECT 
distinct CONCAT('SFTvpkt:', T.datum, ':', P.location_id) as eventID,
'Point transect survey. http://www.fageltaxering.lu.se/inventera/metoder/punktrutter/metodik-sommarpunktrutter' AS samplingProtocol,
TO_DATE(t.datum,'YYYYMMDD') AS eventDate,
'' AS eventTime,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
CONCAT('http://stationsregister.miljodatasamverkan.se/so/ef/environmentalmonitoringfacility/os/', P.nat_stn_reg) AS locationId,
CONCAT('SFTpkt:siteId:', P.location_id) AS internalSiteId,
P.lan AS county,
T.per AS periodWinter,
'EPSG:4326' AS geodeticDatum,
ROUND(cast(K.wgs84_lat as numeric), 5) AS decimalLatitude,
ROUND(cast(K.wgs84_lon as numeric), 5) AS decimalLongitude,
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'Dataset' as type,
'English' as language,
'Free usage' as accessRights,
'true' as nullvisit
FROM koordinater_mittpunkt_topokartan K, punktrutter P, IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS T
left join IPT_SFTvpkt.IPT_SFTvpkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum AND T.per=ST.per
WHERE K.kartatx=P.kartatx
AND P.persnr=T.persnr
AND P.rnr=T.rnr
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

CREATE TABLE IPT_SFTvpkt.IPT_SFTvpkt_OCCURENCE AS
SELECT
CONCAT('SFTvpkt:', T.datum, ':', P.location_id) as eventID,
CONCAT('SFTvpkt:', T.datum, ':', P.location_id, ':', E.dyntaxa_id) as occurrenceID,
CONCAT('SFT:recorderId:', Pe.idPerson) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'The number of individuals observed is the sum total from all of the twenty points on the route. Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset. Currently these species are: Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos), Spotted eagle (större skrikörn; Clanga clanga), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Barn owl (tornuggla; Tyto alba), Eagle owl (berguv; Bubo bubo), Snowy owl (fjälluggla; Bubo scandiacus) and White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos). Some data about biotopes at each point on especially older sites is available on request from data provider (see more info in metadata).' AS informationWithheld,
'Animalia' AS kingdom,
T.ind AS organismQuantity,
'individuals' AS organismQuantityType,
E.latin AS scientificName,
E.arthela AS vernacularName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
genus AS genus,
species AS specificEpithet,
E.taxon_rank AS taxonRank,
'SFTvpkt' AS collectionCode,
'Lund University' AS institutionCode,
'present' AS occurrenceStatus
FROM eurolist E, punktrutter P, totalvinter_pkt T
LEFT JOIN IPT_SFTvpkt.IPT_SFTvpkt_CONVERT_PERSON Pe ON Pe.persnr=T.persnr 
WHERE  T.art=E.art
AND P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND t.ind>0
AND T.yr< :year_max

UNION

SELECT
CONCAT('SFTvpkt:', T.datum, ':', P.location_id) as eventID,
CONCAT('SFTvpkt:', T.datum, ':', P.location_id, ':4000104') as occurrenceID,
CONCAT('SFT:recorderId:', Pe.idPerson) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'The number of individuals observed is the sum total from all of the twenty points on the route. Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset. Currently these species are: Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos), Spotted eagle (större skrikörn; Clanga clanga), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Barn owl (tornuggla; Tyto alba), Eagle owl (berguv; Bubo bubo), Snowy owl (fjälluggla; Bubo scandiacus) and White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos). Some data about biotopes at each point on especially older sites is available on request from data provider (see more info in metadata).' AS informationWithheld,
'Animalia' AS kingdom,
0 AS organismQuantity,
'individuals' AS organismQuantityType,
'Aves' AS scientificName,
'SpeciesIncludedInSurvey' AS vernacularName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:4000104') AS taxonID,
'' AS genus,
'' AS specificEpithet,
'class' AS taxonRank,
'SFTvpkt' AS collectionCode,
'Lund University' AS institutionCode,
'absent' AS occurenceStatus
FROM punktrutter P, IPT_SFTvpkt.IPT_SFTvpkt_EVENTSNOOBS T
LEFT JOIN IPT_SFTvpkt.IPT_SFTvpkt_CONVERT_PERSON Pe ON Pe.persnr=T.persnr 
WHERE  P.persnr=T.persnr
AND P.rnr=T.rnr
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

UNION 

SELECT
DISTINCT eventID,
'Site geometry' AS measurementType,
'Point' AS measurementValue
FROM IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING

UNION

SELECT
DISTINCT eventID,
'Null visit' AS measurementType,
nullvisit AS measurementValue
FROM IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING

UNION

SELECT
DISTINCT eventID,
'Survey period' AS measurementType,
periodWinter AS measurementValue
FROM IPT_SFTvpkt.IPT_SFTvpkt_SAMPLING

UNION

SELECT 
distinct CONCAT('SFTvpkt:', T.datum, ':', P.location_id) as eventID,
'Method of transport' AS measurementType,
CASE
    WHEN p01 = 1 THEN '1. on foot or skis'
    WHEN p01 = 2 THEN '2. by bike or moped'
    WHEN p01 = 3 THEN '3. by car or motorcycle'
    WHEN p01 = 4 THEN '4. other'
    ELSE ''
END AS measurementValue
FROM punktrutter P, totalvinter_pkt T
WHERE P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art='000'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND T.yr< :year_max
AND p01 IS NOT NULL

UNION

SELECT 
distinct CONCAT('SFTvpkt:', T.datum, ':', P.location_id) as eventID,
'Snow on ground' AS measurementType,
CASE
    WHEN p02 = 1 THEN '1. bare ground'
    WHEN p02 = 2 THEN '2. snow covered ground'
    WHEN p02 = 3 THEN '3. very thin or patchy cover of snow'
    ELSE ''
END AS measurementValue
FROM punktrutter P, totalvinter_pkt T
WHERE P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art='000'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND T.yr< :year_max
AND p02 IS NOT NULL
order by eventID;
