\c sft

DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_STARTENDTIME;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_OCCURRENCE;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_EMOF;
DROP TABLE IF EXISTS IPT_SFTkfr.IPT_SFTkfr_OBSERVERS;

/* START TIME */
CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_OBSERVERS AS
select ruta, yr,
case 
	when medobs is null then CONCAT('SFT:recorderId:', cast(idperson as VARCHAR))
	else CONCAT('SFT:recorderId:', cast(idperson as VARCHAR), '|', medobs)
end as observers
from (
	select t.persnr, iscp2.idperson, t.ruta, t.yr, mo.medobs 
	from totalkustfagel200 t
	left join IPT_SFTkfr.IPT_SFTkfr_CONVERT_PERSON iscp2 on iscp2.persnr = t.persnr
	left join (
		select yr, ruta, string_agg(CONCAT('SFT:recorderId:', cast(iscp.idperson as VARCHAR)), '|') as medobs
		from kustfagel200_medobs km
		left join IPT_SFTkfr.IPT_SFTkfr_CONVERT_PERSON iscp on iscp.persnr = km.persnr
		group by yr, ruta
	) mo on mo.yr=t.yr and t.ruta=mo.ruta 
	where art='000'
) allobservers;


/*

To be fixed
 - convert startTime with timezone

*/

CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_SAMPLING AS
SELECT 
distinct CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
'https://www.fageltaxering.lu.se/sites/default/files/files/Uppsatser/projektplankustfaglar_rev_2016.pdf' AS samplingProtocol,
K.area_m2 AS sampleSizeValue,
'square metre' AS sampleSizeUnit,
TO_DATE(T.datum,'YYYYMMDD') AS eventDate,
CASE 
	WHEN S.start IS NULL THEN '' 
	WHEN S.stopp IS NULL THEN to_char(S.start, 'HH24:MI')
	ELSE CONCAT(to_char(S.start, 'HH24:MI'), '/', to_char(S.stopp, 'HH24:MI'))
END AS eventTime,
EXTRACT (doy from  TO_DATE(T.datum,'YYYYMMDD')) AS startDayOfYear,
EXTRACT (doy from  TO_DATE(T.datum,'YYYYMMDD')) AS endDayOfYear,
CONCAT('SFTkfr:siteId:', T.ruta) AS locationId,
'EUROPE' AS continent,
'Sweden' AS country,
'SE' AS countryCode,
C.name AS county,
K.mitt_5x5_sweref99_n AS verbatimLatitude,
K.mitt_5x5_sweref99_o AS verbatimLongitude,
'epsg:3006' AS verbatimSRS,
'epsg:4500' AS verbatimCoordinateSystem,
/*
'WGS84' AS geodeticDatum,
ROUND(cast(K.wgs84_lat as numeric), 3) AS decimalLatitude,
ROUND(cast(K.wgs84_lon as numeric), 3) AS decimalLongitude,
*/
'Dataset' as type,
'English' as language,
'Free usage' as accessRights
FROM kustfagel200_koordinater K, kustfagel200_start_stopp S, totalkustfagel200 T, IPT_SFTkfr.IPT_SFTkfr_CONVERT_COUNTY C
WHERE K.ruta=T.ruta
AND T.ruta=S.ruta 
and T.datum = S.datum
and C.code=cast(K.lan as VARCHAR) 
AND T.art='000' 
order by eventID;

/* HIDDENSPECIES 045 */

/*
split in 4 parts
1- the birds adults in totalkustfagel
2- the young birds in kustfagel200_ejderungar
3- mammals
4- the 0 observation when there is a row with 000 but no other record
*/
CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_OCCURRENCE AS
SELECT
CONCAT('SFTsptk:', T.datum, ':', T.ruta, ':', E.dyntaxa_id, ':total:adult') as occurrenceID,
CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
'SFTkfr' AS CollectionCode,
'Lund University' AS institutionCode,
'HumanObservation' AS basisOfRecord,
observers AS recordedBy,
'The surveyor can opt to report numbers of birds seen on islands vs on open water, but the numbers included here are for the entire square.' AS informationWithheld,
T.ind AS organismQuantity,
'individuals' AS organismQuantityType,
'adult' AS lifeStage,
'present' AS occurrenceStatus,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
'Animalia' AS kingdom,
E.latin AS scientificName,
E.arthela AS vernacularName,
E.taxon_rank AS taxonRank
FROM kustfagel200_koordinater K, eurolist E, totalkustfagel200 T
LEFT JOIN IPT_SFTkfr.IPT_SFTkfr_OBSERVERS Pe ON Pe.ruta=T.ruta and Pe.yr=T.yr 
WHERE K.ruta=T.ruta
AND T.art=E.art
AND T.art>'000' AND T.art<'700' 
AND T.art<>'045'

UNION

select
CONCAT('SFTsptk:', T.datum, ':', T.ruta, ':102935:total:pulli') as occurrenceID,
CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
'SFTkfr' AS CollectionCode,
'Lund University' AS institutionCode,
'HumanObservation' AS basisOfRecord,
observers AS recordedBy,
'The surveyor can opt to report numbers of birds seen on islands vs on open water, but the numbers included here are for the entire square.' AS informationWithheld,
EJ.antal AS organismQuantity,
'individuals' AS organismQuantityType,
'pulli' AS lifeStage,
CASE 
	WHEN EJ.antal = 0 THEN 'absent' 
	ELSE 'present' 
end AS occurrenceStatus,
'urn:lsid:dyntaxa.se:Taxon:102935' AS taxonID,
'Animalia' AS kingdom,
'Somateria mollissima' AS scientificName,
'Ejder' AS vernacularName,
'species' AS taxonRank
FROM kustfagel200_koordinater K, kustfagel200_ejderungar EJ, totalkustfagel200 T
LEFT JOIN IPT_SFTkfr.IPT_SFTkfr_OBSERVERS Pe ON Pe.ruta=T.ruta and Pe.yr=T.yr 
WHERE K.ruta=T.ruta
and EJ.ruta=T.ruta 
and T.yr=EJ.yr
AND T.art='000'
and ej.ungar_inventerade='j'
AND T.art<>'045'

UNION

SELECT
CONCAT('SFTsptk:', T.datum, ':', T.ruta, ':', E.dyntaxa_id) as occurrenceID,
CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
'SFTkfr' AS CollectionCode,
'Lund University' AS institutionCode,
'HumanObservation' AS basisOfRecord,
observers AS recordedBy,
'The surveyor can opt to report numbers of birds seen on islands vs on open water, but the numbers included here are for the entire square.' AS informationWithheld,
NULL AS organismQuantity,
'individuals' AS organismQuantityType,
'adult' AS lifeStage,
'present' AS occurrenceStatus,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
'Animalia' AS kingdom,
E.latin AS scientificName,
E.arthela AS vernacularName,
E.taxon_rank AS taxonRank
FROM kustfagel200_koordinater K, eurolist E, totalkustfagel200 T
LEFT JOIN IPT_SFTkfr.IPT_SFTkfr_OBSERVERS Pe ON Pe.ruta=T.ruta and Pe.yr=T.yr 
WHERE K.ruta=T.ruta
AND T.art=E.art
AND (T.art='714' or (T.art='719' and T.yr>2020))
AND T.art<>'045'

ORDER BY eventID, taxonID;





/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


CREATE TABLE IPT_SFTkfr.IPT_SFTkfr_EMOF AS
SELECT 
distinct CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
NULL as occurrenceID,
'Eider pulli counted' AS measurementType,
CASE 
	WHEN EJ.ungar_inventerade = 'j' THEN 'yes'
	ELSE 'no'
END AS measurementValue
FROM totalkustfagel200 T, kustfagel200_ejderungar EJ
WHERE EJ.ruta=T.ruta 
and T.yr=EJ.yr
UNION
SELECT 
distinct CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
NULL as occurrenceID,
'Square borders' AS measurementType,
CASE 
	WHEN K.ruttyp = 'Pragm' THEN 'redrawn'
	WHEN K.ruttyp = 'Strikt' THEN 'original'
END AS measurementValue
FROM totalkustfagel200 T, kustfagel200_koordinater K
WHERE K.ruta=T.ruta 
UNION
SELECT 
distinct CONCAT('SFTkfr:', T.datum, ':', T.ruta) as eventID,
CONCAT('SFTsptk:', T.datum, ':', T.ruta, ':102935:total:pulli') as occurrenceID,
'Size class' AS measurementType,
cast(storlek as VARCHAR) AS measurementValue
FROM totalkustfagel200 T, kustfagel200_ejderungar EJ
WHERE EJ.ruta=T.ruta 
and T.yr=EJ.yr
and storlek IS NOT NULL
order by measurementType, eventID, occurrenceID;





