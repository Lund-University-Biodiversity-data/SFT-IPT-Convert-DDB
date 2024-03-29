\i lib/config.sql

\c :database_name

\set year_max 2021

DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_STARTTIME;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_OCCURENCE;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_EMOF;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_EVENTSNOOBS;

/* HIDDEN SPECIES */
CREATE TABLE IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES AS
SELECT * FROM eurolist
WHERE dyntaxa_id in (100005, 100008, 100011, 100020, 100032, 100035, 100039, 100046, 100054, 100055, 100057, 100066, 100067, 100093, 100142, 100145, 103061, 103071, 205543, 267320); 


CREATE TABLE IPT_SFTstd.IPT_SFTstd_EVENTSNOOBS AS
select datum, karta, persnr
from (
	select datum, karta, persnr, COUNT(*) as tot from totalstandard 
	WHERE art not in ('000', '999') 
	AND yr< :year_max
	group by datum, karta, persnr
) as eventnoobs
where tot=0;


/*INSERT INTO IPT_SFTstd.IPT_SFTstd_EVENTSNOOBS VALUES ('20210826', '24K2H', '501126-1');*/

/* START TIME */
CREATE TABLE IPT_SFTstd.IPT_SFTstd_STARTTIME AS
SELECT karta, datum, CAST(startTime AS text)
from (
	SELECT karta, datum, art, LPAD(cast(LEAST(p1, p2, p3, p4, p5, p6, p7, p8) as text), 4, '0') as startTime
	FROM totalstandard
	where art='000'
) ST;

/*

To be fixed
 - convert startTime with timezone

*/

CREATE TABLE IPT_SFTstd.IPT_SFTstd_SAMPLING AS
SELECT 
distinct CONCAT('SFTstd:', T.datum, ':', I.idRutt) as eventID,
'Line transect survey. http://www.fageltaxering.lu.se/inventera/metoder/standardrutter/metodik-standardrutter' AS samplingProtocol,
TO_DATE(t.datum,'YYYYMMDD') AS eventDate,
CASE 
	WHEN ST.startTime is null THEN ''
	WHEN ST.startTime = '0999' THEN ''
	ELSE CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),':00') 
END AS eventTime, /* art=000 find the minimum among P1-8. convert to time. No end time / no interval */ 
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
CONCAT('http://stationsregister.miljodatasamverkan.se/so/ef/environmentalmonitoringfacility/pp/', O.nat_stn_reg) AS locationId,
CONCAT('SFTstd:siteId:', cast(idRutt AS text)) AS internalSiteId,
C.name AS county,
'EPSG:4326' AS geodeticDatum,
ROUND(cast(wgs84_lat as numeric), 3) AS decimalLatitude, /* already diffused all locations 25 000 */
ROUND(cast(wgs84_lon as numeric), 3) AS decimalLongitude, /* already diffused all locations 25 000 */
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'Dataset' as type,
'English' as language,
'Free usage' as accessRights,
'false' AS nullvisit
FROM standardrutter_oversikt O, koordinater_mittpunkt_topokartan K, IPT_SFTstd.IPT_SFTstd_CONVERT_KARTA I, IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY C, totalstandard T
left join IPT_SFTstd.IPT_SFTstd_STARTTIME ST on T.datum=ST.datum AND T.datum=ST.datum AND T.karta=ST.karta
WHERE O.karta=K.karta
AND K.karta=T.karta
AND I.karta=K.karta
AND C.code=O.lan
AND T.art<>'000' and T.art<>'999'
and T.art not in (select distinct art from IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES H)
AND t.lind>0
AND T.yr<:year_max

UNION 

SELECT 
distinct CONCAT('SFTstd:', T.datum, ':', I.idRutt) as eventID,
'Line transect survey : http://www.fageltaxering.lu.se/inventera/metoder/standardrutter/metodik-standardrutter' AS samplingProtocol,
TO_DATE(t.datum,'YYYYMMDD') AS eventDate,
CASE 
	WHEN ST.startTime is null THEN ''
	WHEN ST.startTime = '0999' THEN ''
	ELSE CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),':00') 
END AS eventTime, /* art=000 find the minimum among P1-8. convert to time. No end time / no interval */ 
EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS startDayOfYear,
EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS endDayOfYear,
CONCAT('http://stationsregister.miljodatasamverkan.se/so/ef/environmentalmonitoringfacility/pp/', O.nat_stn_reg) AS locationId,
CONCAT('SFTstd:siteId:', cast(idRutt AS text)) AS internalSiteId,
C.name AS county,
'EPSG:4326' AS geodeticDatum,
ROUND(cast(wgs84_lat as numeric), 3) AS decimalLatitude, /* already diffused all locations 25 000 */
ROUND(cast(wgs84_lon as numeric), 3) AS decimalLongitude, /* already diffused all locations 25 000 */
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'Dataset' as type,
'English' as language,
'Free usage' as accessRights,
'true' AS nullvisit
FROM standardrutter_oversikt O, koordinater_mittpunkt_topokartan K, IPT_SFTstd.IPT_SFTstd_CONVERT_KARTA I, IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY C, IPT_SFTstd.IPT_SFTstd_EVENTSNOOBS T
left join IPT_SFTstd.IPT_SFTstd_STARTTIME ST on T.datum=ST.datum AND T.datum=ST.datum AND T.karta=ST.karta
WHERE O.karta=K.karta
AND K.karta=T.karta
AND I.karta=K.karta
AND C.code=O.lan


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

CREATE TABLE IPT_SFTstd.IPT_SFTstd_OCCURENCE AS
SELECT
CONCAT('SFTstd:', T.datum, ':', I.idRutt) as eventID,
CONCAT('SFTstd:', T.datum, ':', I.idRutt, ':', E.dyntaxa_id, ':L') as occurenceID,
CONCAT('SFT:recorderId:', P.idPerson) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
T.lind AS organismQuantity,
'individuals' AS organismQuantityType,
E.latin AS scientificName,
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
'Lund University' AS institutionCode,
'SFTstd' AS collectionCode,
'present' AS occurenceStatus
FROM koordinater_mittpunkt_topokartan K, eurolist E, totalstandard T
LEFT JOIN IPT_SFTstd.IPT_SFTstd_CONVERT_PERSON P ON P.persnr=T.persnr 
LEFT JOIN IPT_SFTstd.IPT_SFTstd_CONVERT_KARTA I ON I.karta=T.karta 
WHERE  K.karta=T.karta
AND T.art=E.art
AND T.art<>'000' and T.art<>'999'
and T.art not in (select distinct art from IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES H)
AND t.lind>0
AND T.yr<:year_max

UNION 

SELECT 
CONCAT('SFTstd:', T.datum, ':', I.idRutt) as eventID,
CONCAT('SFTstd:', T.datum, ':', I.idRutt, ':5000001', ':L') as occurenceID,
CONCAT('SFT:recorderId:', P.idPerson) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
0 AS organismQuantity,
'individuals' AS organismQuantityType,
'Animalia' AS scientificName,
'AnimalsIncludedInSurvey' AS vernacularName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', '5000001') AS taxonID,
'' AS genus,
'' AS specificEpithet,
'kingdom' AS taxonRank,
'Lund University' AS institutionCode,
'SFTstd' AS collectionCode,
'absent' AS occurenceStatus
FROM koordinater_mittpunkt_topokartan K, IPT_SFTstd.IPT_SFTstd_EVENTSNOOBS T
LEFT JOIN IPT_SFTstd.IPT_SFTstd_CONVERT_PERSON P ON P.persnr=T.persnr 
LEFT JOIN IPT_SFTstd.IPT_SFTstd_CONVERT_KARTA I ON I.karta=T.karta 
WHERE  K.karta=T.karta

ORDER BY eventID, taxonID;

/*
ver 1.8 // Add events without observations, 
set scientificName to Animalia
, taxonId to 5000001, 
vernacularName to AnimalsIncludedInSurvey, 
occurrenceStatus to absent, 
organismQuantity to 0, 
organismQuantityType to individuals, 
basisOfRecord to HumanObservation, 
occurrenceID to ????.

*/

/*
CREATE A TEMPORARY TABLE WITH events without occurences
select COUNT(*) as tot, datum, karta from totalstandard WHERE art not in ('000', '999') group by datum, karta order by tot
AND then UNION TO create occurences

scientificName => Animalia
taxonID...

*/




/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


CREATE TABLE IPT_SFTstd.IPT_SFTstd_EMOF AS
SELECT
DISTINCT eventID,
'Site geometry' AS measurementType,
'Line' AS measurementValue
FROM IPT_SFTstd.IPT_SFTstd_SAMPLING
UNION 
SELECT
DISTINCT eventID,
'Internal site Id' AS measurementType,
internalSiteId AS measurementValue
FROM IPT_SFTstd.IPT_SFTstd_SAMPLING
UNION 
SELECT
DISTINCT eventID,
'Null visit' AS measurementType,
nullvisit AS measurementValue
FROM IPT_SFTstd.IPT_SFTstd_SAMPLING;
/*

select karta, datum, art, lind from totalstandard 
where art<>'000' and art<>'999'
order by datum, karta, art

select COUNT(*) from totalstandard T, koordinater_mittpunkt_topokartan K
where K.karta=T.karta
and art<>'000' and art<>'999'

SELECT COUNT(*)
FROM totalstandard T, koordinater_mittpunkt_topokartan K, eurolist E
WHERE  K.karta=T.karta
AND T.art=E.art
AND T.art<>'000' and T.art<>'999'


=> COUNT * => 361 092


select T.karta, T.datum, T.art, K.wgs84_lat, K.wgs84_lon, T.lind from totalstandard T, koordinater_mittpunkt_topokartan K
where K.karta=T.karta
and art<>'000' and art<>'999'
order by T.datum, T.karta, T.art

*/
