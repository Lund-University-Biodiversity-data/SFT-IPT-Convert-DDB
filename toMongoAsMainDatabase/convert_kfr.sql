\i lib/config.sql

\set year_max 2022

DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_HIDDENSPECIES;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_OCCURRENCE;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_EMOF;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_OBSERVERS;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_DETAILSART;

DROP SCHEMA IF EXISTS IPT_SFTkfr;
CREATE SCHEMA IPT_SFTkfr;

CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (
	code varchar(2) NOT NULL,
	name varchar(255) NOT NULL,
	PRIMARY KEY (code)
); 

INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('AB', 'Stockholms län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('AC', 'Västerbottens län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('BD', 'Norrbottens län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('C', 'Uppsala län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('D', 'Södermanlands län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('E', 'Östergötlands län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('F', 'Jönköpings län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('G', 'Kronobergs län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('H', 'Kalmar län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('I', 'Gotlands län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('K', 'Blekinge län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('M', 'Skåne län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('N', 'Hallands län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('O', 'Västra Götalands län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('S', 'Värmlands län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('T', 'Örebro län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('U', 'Västmanlands län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('W', 'Dalarnas län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('X', 'Gävleborgs län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('Y', 'Västernorrlands län');
INSERT INTO IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY (code, name) VALUES ('Z', 'Jämtlands län');

/* TEMPORARY FIX FOR FREDRIK ??
there is one site in 2022 that has "-1" as the sum of birds seen of a particular species (sillgrissla). This is Fredriks way of showing that he hasn't got the real number yet (and won't have perhaps until next year). So we just fill in occurrenceStatus with "present" and leave this and the next field empty.
*/
UPDATE mongo_totalkust SET ind=null WHERE ind=-1;


/* fix starttime / endtime who are 00:00 */
UPDATE mongo_totalkust 
SET surveystarttime=null, surveyfinishtime=null 
WHERE surveystarttime='00:00' and surveyfinishtime='00:00';

/* TO BE REPLACED WITH PROPER SKYDKLASS */
/* HIDDENSPECIES 045 */
CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_HIDDENSPECIES AS
SELECT * FROM lists_eurolist_dr638_3mammals
WHERE dyntaxa_id in ('100005', '100008', '100011', '100020', '100032', '100035', '100039', '100046', '100054', '100055', '100057', '100066', '100067', '100093', '100142', '100145', '103061', '103071', '205543', '267320'); 
/* and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTkfr.IPT_SFTkfr_HIDDENSPECIES) */


CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_DETAILSART AS
SELECT art, suppliedname, SPLIT_PART(suppliedname, ' ', 1) as genus, SPLIT_PART(suppliedname, ' ', 2) as specificEpithet, SPLIT_PART(suppliedname, ' ', 3) as infraSpecificEpithet 
FROM lists_eurolist_dr638_3mammals;


/* START TIME */
CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_OBSERVERS AS
select ruta, yr,
case 
	when medobs is null then CONCAT('SFT:recorderId:', cast(anonymizedId as VARCHAR))
	else medobs
end as observers
from (
	select t.persnr, iscp2.anonymizedId, t.ruta, t.yr, mo.medobs 
	from mongo_totalkust t
	left join mongo_persons iscp2 on iscp2.persnr = t.persnr
	left join (
		select yr, site, string_agg(CONCAT('SFT:recorderId:', cast(iscp.anonymizedId as VARCHAR)), '|') as medobs
		from mongo_medobs km
		left join mongo_persons iscp on iscp.persnr = km.person
		group by yr, site
	) mo on mo.yr=t.yr and t.ruta=mo.site 
	where art='000'
	AND t.yr<=:year_max
) allobservers;


/*

To be fixed
 - convert startTime with timezone

*/

CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_SAMPLING AS
SELECT 
distinct CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
'https://www.fageltaxering.lu.se/sites/default/files/files/Uppsatser/projektplankustfaglar_rev_2016.pdf' AS samplingProtocol,
CAST (round(K.area_m2) AS INTEGER) AS sampleSizeValue,
'square metre' AS sampleSizeUnit,
TO_DATE(T.datum,'YYYYMMDD') AS eventDate,
CASE 
	WHEN T.surveystarttime IS NULL THEN '' 
	WHEN T.surveyfinishtime IS NULL THEN CONCAT(T.surveystarttime, '/')
	ELSE CONCAT(T.surveystarttime, '/', T.surveyfinishtime)
END AS eventTime,
CAST (EXTRACT (doy from  TO_DATE(T.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST (EXTRACT (doy from  TO_DATE(T.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
K.staregppid AS locationId,
CONCAT('SFTkfr:siteId:', T.ruta) AS internalSiteId,
'The surveyor can opt to report numbers of birds seen on islands vs on open water, but the numbers included in this dataset are for the entire square. Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently this concerns one species only: White-tailed eagle (havsörn; Haliaeetus albicilla). In addition, data for razorbills (tordmule; Alca torda) on Stora Karlsö (square I0002) are at present not included in this dataset.' AS informationWithheld,
'EUROPE' AS continent,
'Sweden' AS country,
'SE' AS countryCode,
C.name AS county,
/*
K.mitt_5x5_sweref99_n AS verbatimLatitude,
K.mitt_5x5_sweref99_o AS verbatimLongitude,
'epsg:3006' AS verbatimSRS,
'epsg:4500' AS verbatimCoordinateSystem,
*/
'EPSG:4326' AS geodeticDatum,
3500 AS coordinateUncertaintyInMeters,
'The coordinates supplied are for the central point of a 5 x 5 km square, within which the central point of the curvey square is located.' AS locationRemarks,
ROUND(K.mitt_5x5_wgs84_lat::float8::numeric, 5) AS decimalLatitude, /* cast to float8 first, then to numeric in order to round */
ROUND(K.mitt_5x5_wgs84_lon::float8::numeric, 5) AS decimalLongitude, /* cast to float8 first, then to numeric in order to round */
'English' as language,
'Limited' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'false' as nullvisit,
pullicounted AS pullicounted_for_emof /* for emof only */
FROM mongo_sites K, mongo_totalkust T, IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY C
WHERE k.internalsiteid=T.ruta
and C.code=cast(K.lan as VARCHAR) 
AND T.art='000' 
AND T.yr<=:year_max
order by eventID;


/*
split in 4 parts
1- the birds adults in totalkustfagel
2- the young birds in pullicount
3- mammals
4- the 0 observation when there is a row with 000 but no other record
*/
CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_OCCURRENCE AS
SELECT
CONCAT('SFTkfr:', T.datum, ':', T.ruta, ':', E.dyntaxa_id, ':total:adult') as occurrenceID,
CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
'SFTkfr' AS CollectionCode,
'HumanObservation' AS basisOfRecord,
observers AS recordedBy,
T.ind AS individualCount,
T.ind AS organismQuantity,
'individuals' AS organismQuantityType,
'adult' AS lifeStage,
'present' AS occurrenceStatus,
E.dyntaxa_id AS taxonID,
'Animalia' AS kingdom,
E.suppliedname AS scientificName,
E.arthela AS vernacularName,
CASE 
	WHEN T.art IN ('245', '301', '302', '319') THEN 'genus' 
	WHEN T.art IN ('237', '260', '261', '504', '505', '508', '509', '526', '536', '566', '608', '609', '626', '636', '666', '731') THEN 'subspecies' 
	WHEN T.art IN ('418') THEN 'speciesAggregate' 
	ELSE 'species' 
END AS taxonRank,
DA.genus AS genus,
DA.specificepithet AS specificEpithet,
DA.infraspecificepithet AS infraSpecificEpithet
FROM mongo_sites K, lists_eurolist_dr638_3mammals E, IPT_SFTkfr.IPT_SFTkfr_DETAILSART DA, mongo_totalkust T
LEFT JOIN IPT_SFTkfr.IPT_SFTkfr_OBSERVERS Pe ON Pe.ruta=T.ruta and Pe.yr=T.yr 
WHERE k.internalsiteid=T.ruta
AND T.art=E.art
AND DA.art=E.art
AND T.art>'000' AND T.art<'700' 
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTkfr.IPT_SFTkfr_HIDDENSPECIES)
AND T.yr<=:year_max

UNION

select
CONCAT('SFTkfr:', T.datum, ':', T.ruta, ':102935:total:pulli') as occurrenceID,
CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
'SFTkfr' AS CollectionCode,
'HumanObservation' AS basisOfRecord,
observers AS recordedBy,
T.pullicount AS individualCount,
T.pullicount AS organismQuantity,
'individuals' AS organismQuantityType,
'pulli' AS lifeStage,
CASE 
	WHEN T.pullicount = 0 THEN 'absent'
	ELSE 'present' 
END AS occurrenceStatus,
'102935' AS taxonID,
'Animalia' AS kingdom,
'Somateria mollissima' AS scientificName,
'Ejder' AS vernacularName,
'species' AS taxonRank,
'Somateria' AS genus,
'mollissima' AS specificEpithet,
'' AS infraSpecificEpithet
FROM mongo_sites K, mongo_totalkust T
LEFT JOIN IPT_SFTkfr.IPT_SFTkfr_OBSERVERS Pe ON Pe.ruta=T.ruta and Pe.yr=T.yr 
WHERE k.internalsiteid=T.ruta
AND T.art='000'
and T.pullicounted='ja'
AND T.pullicount>=0
AND T.yr<=:year_max

UNION

SELECT
CONCAT('SFTkfr:', T.datum, ':', T.ruta, ':', E.dyntaxa_id) as occurrenceID,
CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
'SFTkfr' AS CollectionCode,
'HumanObservation' AS basisOfRecord,
observers AS recordedBy,
NULL AS individualCount,
NULL AS organismQuantity,
NULL AS organismQuantityType,
NULL AS lifeStage,
'present' AS occurrenceStatus,
E.dyntaxa_id AS taxonID,
'Animalia' AS kingdom,
E.suppliedname AS scientificName,
E.arthela AS vernacularName,
CASE 
	WHEN T.art IN ('245', '301', '302', '319') THEN 'genus' 
	WHEN T.art IN ('237', '260', '261', '504', '505', '508', '509', '526', '536', '566', '608', '609', '626', '636', '666', '731') THEN 'subspecies' 
	WHEN T.art IN ('418') THEN 'speciesAggregate' 
	ELSE 'species' 
END AS taxonRank,
DA.genus AS genus,
DA.specificepithet AS specificEpithet,
DA.infraspecificepithet AS infraSpecificEpithet
FROM mongo_sites K, lists_eurolist_dr638_3mammals E, IPT_SFTkfr.IPT_SFTkfr_DETAILSART DA, mongo_totalkust T
LEFT JOIN IPT_SFTkfr.IPT_SFTkfr_OBSERVERS Pe ON Pe.ruta=T.ruta and Pe.yr=T.yr 
WHERE k.internalsiteid=T.ruta
AND T.art=E.art
AND DA.art=E.art
AND (T.art='714' or (T.art='719' and T.yr>2020) or (T.art='709' and T.yr>2020))
and T.art NOT IN (SELECT DISTINCT art FROM IPT_SFTkfr.IPT_SFTkfr_HIDDENSPECIES)
AND T.yr<=:year_max

ORDER BY eventID, taxonID;





/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_EMOF AS

SELECT
DISTINCT eventID,
NULL as occurrenceID,
'Internal site Id' AS measurementType,
internalSiteId AS measurementValue
FROM IPT_SFTkfr.IPT_SFTkfr_SAMPLING

UNION 

SELECT
DISTINCT eventID,
NULL as occurrenceID,
'Location type' AS measurementType,
'Square' AS measurementValue
FROM IPT_SFTkfr.IPT_SFTkfr_SAMPLING

UNION

SELECT
DISTINCT eventID,
NULL as occurrenceID,
'Null visit' AS measurementType,
nullvisit AS measurementValue
FROM IPT_SFTkfr.IPT_SFTkfr_SAMPLING

UNION

SELECT 
eventID,
NULL as occurrenceID,
'Eider pulli counted' AS measurementType,
CASE 
	WHEN S.pullicounted_for_emof = 'ja' THEN 'yes'
	ELSE 'no'
END AS measurementValue
FROM IPT_SFTkfr.IPT_SFTkfr_SAMPLING S
WHERE EXTRACT(YEAR FROM S.eventdate)<=:year_max

UNION

SELECT 
distinct CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
NULL as occurrenceID,
'Square borders' AS measurementType,
CASE 
	WHEN K.routetype = 'Pragm' THEN 'redrawn'
	WHEN K.routetype = 'Strikt' THEN 'original'
END AS measurementValue
FROM mongo_totalkust T, mongo_sites K
WHERE k.internalsiteid=T.ruta 
AND T.yr<=:year_max

UNION


SELECT 
distinct CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
CONCAT('SFTkfr:', T.datum, ':', T.ruta, ':102935:total:pulli') as occurrenceID,
'Pulli size class' AS measurementType,
case 
  when pullisize=1 THEN '< 25% of the adult size'
  when pullisize=2 THEN '25-50% of the adult size'
  when pullisize=3 THEN '50-75% of the adult size'
  when pullisize=4 THEN '> 75%of the adult size'
  else ''
end AS measurementValue
FROM mongo_totalkust T
WHERE pullisize IS NOT NULL
AND T.yr<=:year_max
order by measurementType, eventID, occurrenceID;





