\c sft

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
'http://www.fageltaxering.lu.se/inventera/metoder/punktrutter/metodik-sommarpunktrutter' AS samplingProtocol,
TO_DATE(t.datum,'YYYYMMDD') AS eventDate,
CONCAT(left(ST.startTime, length(cast(ST.startTime as text))-2), ':', right(ST.startTime, 2),'/',left(ST.endTime, length(cast(ST.endTime as text))-2), ':', right(ST.endTime, 2)) AS eventTime,
EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS startDayOfYear,
CONCAT('SFTpkt:siteId:', P.location_id) AS locationId,
P.lan AS county,
'WGS84' AS geodeticDatum,
ROUND(cast(K.wgs84_lat as numeric), 3) AS decimalLatitude,
ROUND(cast(K.wgs84_lon as numeric), 3) AS decimalLongitude,
'SE' AS countryCode,
'EUROPE' AS continent,
'Event' as type,
'English' as language,
'Free usage' as accessRights,
'Lund University' AS institutionCode
FROM koordinater_mittpunkt_topokartan K, punktrutter P, totalsommar_pkt T
left join IPT_SFTspkt.IPT_SFTspkt_STARTENDTIME ST on T.persnr=ST.persnr AND T.rnr=ST.rnr AND T.datum=ST.datum
WHERE K.kartatx=P.kartatx
AND P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND t.ind>0
AND T.yr<2020
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
'Animalia' AS kingdom,
T.ind AS individualCount,
E.latin AS scientificName,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
genus AS genus,
species AS specificEpithet,
CASE 
	WHEN T.art IN ('245', '301', '302', '319') THEN 'genus' 
	WHEN T.art IN ('237', '260', '261', '508', '509', '526', '536', '566', '608', '609', '626', '636', '666', '731') THEN 'subspecies' 
	WHEN T.art IN ('418') THEN 'speciesAggregate' 
	ELSE 'species' 
END AS taxonRank
FROM eurolist E, punktrutter P, totalsommar_pkt T
LEFT JOIN IPT_SFTspkt.IPT_SFTspkt_CONVERT_PERSON Pe ON Pe.persnr=T.persnr 
WHERE  T.art=E.art
AND P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art<>'000' and T.art<>'999'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND t.ind>0
AND T.yr<2020
ORDER BY eventID, taxonID;

/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


CREATE TABLE IPT_SFTspkt.IPT_SFTspkt_EMOF AS
SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', P.location_id) as eventID,
'Method of transport' AS measurementType,
p01 AS measurementValue
FROM punktrutter P, totalsommar_pkt T
WHERE P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art='000'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND T.yr<2020
AND p01 IS NOT NULL
UNION
SELECT 
distinct CONCAT('SFTspkt:', T.datum, ':', P.location_id) as eventID,
'Snow on ground' AS measurementType,
p02 AS measurementValue
FROM punktrutter P, totalsommar_pkt T
WHERE P.persnr=T.persnr
AND P.rnr=T.rnr
AND T.art='000'
and T.art NOT IN (SELECT DISTINCT art FROM eurolist WHERE skyddsklass_adb like '4%' or skyddsklass_adb like '5%')
AND T.yr<2020
AND p02 IS NOT NULL
order by eventID;
