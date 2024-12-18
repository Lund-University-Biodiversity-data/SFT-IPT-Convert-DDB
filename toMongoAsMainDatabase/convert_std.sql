/*\i lib/config.sql*/

\set database_name sft_std_from_mongo


/* year_max<=  < */
\set year_max 2023

DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_TIMES;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY;

DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_STARTTIME;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_LISTTIME;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_OCCURRENCE;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_EMOF;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_EVENTSNOOBS;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_DETAILSART;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_STARTFINISHTIMES;

DROP SCHEMA IF EXISTS IPT_SFTstd;
CREATE SCHEMA IPT_SFTstd;



CREATE TABLE IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (
	code varchar(2) NOT NULL,
	name varchar(255) NOT NULL,
	PRIMARY KEY (code)
); 

INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('AB', 'Stockholms län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('AC', 'Västerbottens län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('BD', 'Norrbottens län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('C', 'Uppsala län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('D', 'Södermanlands län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('E', 'Östergötlands län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('F', 'Jönköpings län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('G', 'Kronobergs län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('H', 'Kalmar län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('I', 'Gotlands län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('K', 'Blekinge län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('M', 'Skåne län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('N', 'Hallands län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('O', 'Västra Götalands län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('S', 'Värmlands län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('T', 'Örebro län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('U', 'Västmanlands län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('W', 'Dalarnas län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('X', 'Gävleborgs län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('Y', 'Västernorrlands län');
INSERT INTO IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY (code, name) VALUES ('Z', 'Jämtlands län');



CREATE TABLE IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES AS
SELECT * FROM lists_module_biodiv
WHERE protected_adb LIKE '4%' or protected_adb LIKE '5%'; 


CREATE TABLE IPT_SFTstd.IPT_SFTstd_DETAILSART AS
SELECT art, suppliedname, SPLIT_PART(suppliedname, ' ', 1) as genus, SPLIT_PART(suppliedname, ' ', 2) as specificEpithet, SPLIT_PART(suppliedname, ' ', 3) as infraSpecificEpithet 
FROM lists_module_biodiv;

/* Manual fix of the species Columba livia f. domestica */
UPDATE IPT_SFTstd.IPT_SFTstd_DETAILSART
SET infraSpecificEpithet='', specificepithet='livia f. domestica'
WHERE suppliedname='Columba livia f. domestica';
/*WHERE LENGTH(infraSpecificEpithet)>0 AND LENGTH(infraSpecificEpithet)<3;*/

/* store all the survey start/finishtime */
CREATE TABLE IPT_SFTstd.IPT_SFTstd_STARTFINISHTIMES AS 
SELECT datum, karta, bcsurveystarttime, bcsurveyfinishtime
FROM mongo_totalstandard
where art='000';

CREATE TABLE IPT_SFTstd.IPT_SFTstd_EVENTSNOOBS AS
select datum, karta, persnr
from (
	select datum, karta, persnr, COUNT(*) as tot from mongo_totalstandard 
	WHERE art not in ('000', '999') 
	AND yr <= :year_max
	group by datum, karta, persnr
) as eventnoobs
where tot=0;

/* create a view without the timOfObservation=0 (not filled in) */
/* to avoid them in the LEAST function */
CREATE TABLE IPT_SFTstd.IPT_SFTstd_TIMES AS
SELECT karta, datum, p1, p2, p3, p4, p5, p6, p7, p8
FROM mongo_totalstandard
where art='000';

UPDATE IPT_SFTstd.IPT_SFTstd_TIMES 
SET p1=NULL WHERE p1=0;
UPDATE IPT_SFTstd.IPT_SFTstd_TIMES 
SET p2=NULL WHERE p2=0;
UPDATE IPT_SFTstd.IPT_SFTstd_TIMES 
SET p3=NULL WHERE p3=0;
UPDATE IPT_SFTstd.IPT_SFTstd_TIMES 
SET p4=NULL WHERE p4=0;
UPDATE IPT_SFTstd.IPT_SFTstd_TIMES 
SET p5=NULL WHERE p5=0;
UPDATE IPT_SFTstd.IPT_SFTstd_TIMES 
SET p6=NULL WHERE p6=0;
UPDATE IPT_SFTstd.IPT_SFTstd_TIMES 
SET p7=NULL WHERE p7=0;
UPDATE IPT_SFTstd.IPT_SFTstd_TIMES 
SET p8=NULL WHERE p8=0;

/* START TIME FROM LISTTIME */
CREATE TABLE IPT_SFTstd.IPT_SFTstd_LISTTIME AS
SELECT karta, datum, p1, p2, p3, p4, p5, p6, p7, p8
FROM mongo_totalstandard
where art='000'; 

/* exclude time = 0, to avoid empty/null, and never in the datbase any 00:00 as real time... */
UPDATE IPT_SFTstd.IPT_SFTstd_LISTTIME SET p1=NULL WHERE p1=0;
UPDATE IPT_SFTstd.IPT_SFTstd_LISTTIME SET p2=NULL WHERE p2=0;
UPDATE IPT_SFTstd.IPT_SFTstd_LISTTIME SET p3=NULL WHERE p3=0;
UPDATE IPT_SFTstd.IPT_SFTstd_LISTTIME SET p4=NULL WHERE p4=0;
UPDATE IPT_SFTstd.IPT_SFTstd_LISTTIME SET p5=NULL WHERE p5=0;
UPDATE IPT_SFTstd.IPT_SFTstd_LISTTIME SET p6=NULL WHERE p6=0;
UPDATE IPT_SFTstd.IPT_SFTstd_LISTTIME SET p7=NULL WHERE p7=0;
UPDATE IPT_SFTstd.IPT_SFTstd_LISTTIME SET p8=NULL WHERE p8=0;

CREATE TABLE IPT_SFTstd.IPT_SFTstd_STARTTIME AS
SELECT karta, datum, CAST(startTime AS text)
from (
	SELECT karta, datum, LPAD(cast(LEAST(p1, p2, p3, p4, p5, p6, p7, p8) as text), 4, '0') as startTime
	FROM IPT_SFTstd.IPT_SFTstd_LISTTIME
) ST;


CREATE TABLE IPT_SFTstd.IPT_SFTstd_SAMPLING AS
SELECT 
distinct CONCAT('SFTstd:', T.datum, ':', I.anonymizedId) as eventID,
'line transect survey' AS samplingProtocol,
CONCAT(CAST(TO_DATE(t.datum,'YYYYMMDD') AS TEXT), '/', CAST(TO_DATE(t.datum,'YYYYMMDD') AS TEXT)) AS eventDate,
CASE 
	WHEN SFT.bcsurveystarttime='00:00' THEN ''
	ELSE CONCAT(SFT.bcsurveystarttime, '/',SFT.bcsurveyfinishtime) 
END AS eventTime, 
/* CASE 
	WHEN ST.startTime is null THEN ''
	WHEN ST.startTime = '0999' THEN ''
	ELSE CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),':00') 
END AS eventTime, // art=000 find the minimum among P1-8. convert to time. No end time / no interval */ 
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
I.stnregosid AS locationId,
CONCAT('SFTstd:siteId:', cast(anonymizedId AS text)) AS verbatimLocality,
C.name AS county,
'EPSG:4326' AS geodeticDatum,
17700 AS coordinateUncertaintyInMeters,
'The coordinates supplied are for the central point of a 25 x 25 km survey grid square, within which the route is located.' AS locationRemarks,
ROUND(K.wgs84_lat::float8::numeric, 5) AS decimalLatitude, /* already diffused all locations 25 000 */
ROUND(K.wgs84_lon::float8::numeric, 5) AS decimalLongitude, /* already diffused all locations 25 000 */
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Limited' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently these species are: Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus),  Montagu’s harrier (ängshök; Circus pygargus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Eagle owl (berguv; Bubo bubo), White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos), Eurasian lynx (lo; Lynx lynx), Grey wolf (varg; Canis lupus lupus), Brown bear (brunbjörn; Ursus arctos), Wolverine (järv; Gulo gulo) and Arctic fox (fjällräv; Vulpes lagopus).' AS informationWithheld,
'false' AS nullvisit
FROM mongo_centroidtopokartan K, mongo_sites I, IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY C, IPT_SFTstd.IPT_SFTstd_STARTFINISHTIMES SFT, mongo_totalstandard T
left join IPT_SFTstd.IPT_SFTstd_STARTTIME ST on T.datum=ST.datum AND T.datum=ST.datum AND T.karta=ST.karta
WHERE T.karta=I.internalSiteId
AND I.internalsiteid=K.karta
AND SFT.karta=T.karta 
AND SFT.datum=T.datum
AND C.code=I.lan
AND T.art<>'000' and T.art<>'999'
and T.art not in (select distinct art from IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES H)
AND t.lind>0
AND T.yr <= :year_max

UNION 

SELECT 
distinct CONCAT('SFTstd:', T.datum, ':', I.anonymizedId) as eventID,
'line transect survey' AS samplingProtocol,
CONCAT(CAST(TO_DATE(t.datum,'YYYYMMDD') AS TEXT), '/', CAST(TO_DATE(t.datum,'YYYYMMDD') AS TEXT)) AS eventDate,
CASE 
	WHEN SFT.bcsurveystarttime='00:00' THEN ''
	ELSE CONCAT(SFT.bcsurveystarttime, '/',SFT.bcsurveyfinishtime) 
END AS eventTime, 
/* CASE 
	WHEN ST.startTime is null THEN ''
	WHEN ST.startTime = '0999' THEN ''
	ELSE CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),':00') 
END AS eventTime, // art=000 find the minimum among P1-8. convert to time. No end time / no interval */ 
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
I.stnregosid AS locationId,
CONCAT('SFTstd:siteId:', cast(anonymizedId AS text)) AS verbatimLocality,
C.name AS county,
'EPSG:4326' AS geodeticDatum,
17700 AS coordinateUncertaintyInMeters,
'The coordinates supplied are for the central point of a 25 x 25 km survey grid square, within which the route is located.' AS locationRemarks,
ROUND(cast(K.wgs84_lat as numeric), 5) AS decimalLatitude, /* already diffused all locations 25 000 */
ROUND(cast(K.wgs84_lon as numeric), 5) AS decimalLongitude, /* already diffused all locations 25 000 */
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Free usage' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently these species are: Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus),  Montagu’s harrier (ängshök; Circus pygargus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Eagle owl (berguv; Bubo bubo), White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos), Eurasian lynx (lo; Lynx lynx), Grey wolf (varg; Canis lupus lupus), Brown bear (brunbjörn; Ursus arctos), Wolverine (järv; Gulo gulo) and Arctic fox (fjällräv; Vulpes lagopus).' AS informationWithheld,
'true' AS nullvisit
FROM mongo_centroidtopokartan K, mongo_sites I, IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY C, IPT_SFTstd.IPT_SFTstd_STARTFINISHTIMES SFT, IPT_SFTstd.IPT_SFTstd_EVENTSNOOBS T
left join IPT_SFTstd.IPT_SFTstd_STARTTIME ST on T.datum=ST.datum AND T.datum=ST.datum AND T.karta=ST.karta
WHERE T.karta=I.internalSiteId
AND I.internalsiteid=K.karta
AND SFT.karta=T.karta 
AND SFT.datum=T.datum
AND C.code=I.lan


order by eventID;


CREATE TABLE IPT_SFTstd.IPT_SFTstd_OCCURRENCE AS
SELECT
CONCAT('SFTstd:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTstd:', T.datum, ':', I.anonymizedId, ':', E.dyntaxa_id, ':L') as occurrenceID,
CONCAT('SFT:recorderId:', P.anonymizedId) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
T.lind AS individualCount,
T.lind AS organismQuantity,
'individuals' AS organismQuantityType,
E.SuppliedName AS scientificName,
E.arthela AS vernacularName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
DA.genus AS genus,
DA.specificepithet AS specificEpithet,
DA.infraspecificepithet AS infraSpecificEpithet,
E.taxon_rank as taxonRank,
'SFTstd' AS collectionCode,
'present' AS occurrenceStatus,
'The number of individuals observed is the sum total from all the surveyed lines on the route.' AS occurrenceRemarks
FROM mongo_sites I, lists_module_biodiv E, IPT_SFTstd.IPT_SFTstd_DETAILSART DA, mongo_totalstandard T
LEFT JOIN mongo_persons P ON P.persnr=T.persnr 
WHERE  I.internalSiteId=T.karta
AND DA.art=E.art
AND T.art=E.art
AND T.art<>'000' and T.art<>'999'
and T.art not in (select distinct art from IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES H)
AND t.lind>0
AND T.yr <= :year_max

UNION 

SELECT 
CONCAT('SFTstd:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTstd:', T.datum, ':', I.anonymizedId, ':5000001', ':L') as occurrenceID,
CONCAT('SFT:recorderId:', P.anonymizedId) AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
0 AS individualCount,
0 AS organismQuantity,
'individuals' AS organismQuantityType,
'Animalia' AS scientificName,
'AnimalsIncludedInSurvey' AS vernacularName,
'5000001' AS taxonID,
'' AS genus,
'' AS specificEpithet,
'' AS infraSpecificEpithet,
'kingdom' AS taxonRank,
'SFTstd' AS collectionCode,
'absent' AS occurrenceStatus,
'The number of individuals observed is the sum total from all the surveyed lines on the route.' AS occurrenceRemarks
FROM mongo_sites I, IPT_SFTstd.IPT_SFTstd_EVENTSNOOBS T
LEFT JOIN mongo_persons P ON P.persnr=T.persnr 
WHERE  I.internalSiteId=T.karta

ORDER BY eventID, taxonID;




CREATE TABLE IPT_SFTstd.IPT_SFTstd_EMOF AS
SELECT
DISTINCT eventID,
'Location type' AS measurementType,
'Line' AS measurementValue
FROM IPT_SFTstd.IPT_SFTstd_SAMPLING
UNION 
SELECT
DISTINCT eventID,
'Null visit' AS measurementType,
nullvisit AS measurementValue
FROM IPT_SFTstd.IPT_SFTstd_SAMPLING;


