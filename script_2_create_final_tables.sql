\c sft

DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_STARTTIME;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_OCCURENCE;
DROP TABLE IF EXISTS IPT_SFTstd.IPT_SFTstd_EMOF;

/* HIDDEN SPECIES */
CREATE TABLE IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES AS
SELECT * FROM eurolist
WHERE dyntaxa_id in (100008, 100093, 100054, 100055, 100011, 103061, 100020, 100032, 205543, 100035, 100039, 100046, 100067, 103071, 100142, 267320, 100066, 100005, 100057, 100145); 


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
'http://www.fageltaxering.lu.se/inventera/metoder/standardrutter/metodik-standardrutter' AS samplingProtocol,
CONCAT(left(T.datum, 4), '-', left(right(T.datum, 4), 2), '-', right(T.datum, 2)) AS eventDate,
CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),':00') AS eventTime, /* art=000 find the minimum among P1-8. convert to time. No end time / no interval */ 
idRutt AS locationId,
C.name AS county,
'WGS84' AS geodeticDatum,
ROUND(cast(wgs84_lat as numeric), 3) AS decimalLatitude, /* already diffused all locations 25 000 */
ROUND(cast(wgs84_lon as numeric), 3) AS decimalLongitude, /* already diffused all locations 25 000 */
'SE' AS countryCode
FROM standardrutter_oversikt O, koordinater_mittpunkt_topokartan K, IPT_SFTstd.IPT_SFTstd_CONVERT_KARTA I, IPT_SFTstd.IPT_SFTstd_CONVERT_COUNTY C, totalstandard T
left join standardrutter_oversikt SO on SO.karta=T.karta
left join IPT_SFTstd.IPT_SFTstd_STARTTIME ST on T.datum=ST.datum AND T.datum=ST.datum AND T.karta=ST.karta
WHERE O.karta=K.karta
AND K.karta=T.karta
AND I.karta=K.karta
AND C.code=O.lan
AND T.art<>'000' and T.art<>'999'
and T.art not in (select distinct art from IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES H)
AND t.lind>0
AND T.yr<2019
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
CONCAT('SFTstd:', T.datum, ':', I.idRutt, ':', E.dyntaxa_id, ':l') as occurenceID,
P.idPerson AS recordedBy,
'HumanObservation' AS basisOfRecord,
'Animalia' AS kingdom,
T.lind AS individualCount,
E.latin AS scientificName,
E.dyntaxa_id AS taxonID,
genus AS genus,
species AS specificEpithet,
CASE 
	WHEN T.art IN ('245', '301', '302', '319') THEN 'genus' 
	WHEN T.art IN ('237', '260', '261', '508', '509', '526', '536', '566', '608', '609', '626', '636', '666', '731') THEN 'subspecies' 
	WHEN T.art IN ('418') THEN 'speciesAggregate' 
	ELSE 'species' 
END AS taxonRank
FROM koordinater_mittpunkt_topokartan K, eurolist E, totalstandard T
LEFT JOIN IPT_SFTstd.IPT_SFTstd_CONVERT_PERSON P ON P.persnr=T.persnr 
LEFT JOIN IPT_SFTstd.IPT_SFTstd_CONVERT_KARTA I ON I.karta=T.karta 
WHERE  K.karta=T.karta
AND T.art=E.art
AND T.art<>'000' and T.art<>'999'
and T.art not in (select distinct art from IPT_SFTstd.IPT_SFTstd_HIDDENSPECIES H)
AND t.lind>0
AND T.yr<2019
ORDER BY eventID, taxonID;

/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


CREATE TABLE IPT_SFTstd.IPT_SFTstd_EMOF AS
SELECT
DISTINCT eventID,
'Site type' AS measurementType,
'Lines' AS measurementValue,
'' AS measurementUnit
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
