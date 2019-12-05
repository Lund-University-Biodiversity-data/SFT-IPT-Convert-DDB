
DROP VIEW IF EXISTS IPT_SFT_HIDDENSPECIES;
DROP VIEW IF EXISTS IPT_SFT_SAMPLING;
DROP VIEW IF EXISTS IPT_SFT_OCCURENCE;


/* HIDDEN SPECIES */
CREATE VIEW IPT_SFT_HIDDENSPECIES AS
SELECT * FROM eurolist
WHERE dyntaxa_id in (100008, 100093, 100054, 100055, 100011, 103061, 100020, 100032, 205543, 100035, 100039, 100046, 100067, 103071, 100142, 267320, 100066, 100005, 100057, 100145); 




CREATE VIEW IPT_SFT_SAMPLING AS
SELECT distinct CONCAT(T.datum,':',T.karta) AS eventID, 
'Transect/Sling' AS samplingProtocol,
T.datum AS eventDate,
'WGS84' AS geodeticDatum,
wgs84_lat AS decimalLatitude,
wgs84_lon AS decimalLongitude,
'SE' AS countryCode
FROM totalstandard T, koordinater_mittpunkt_topokartan K
WHERE K.karta=T.karta
AND T.art<>'000' and T.art<>'999'
and T.art not in (select distinct art from IPT_SFT_HIDDENSPECIES H)
order by eventID

/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


CREATE VIEW IPT_SFT_OCCURENCE AS
SELECT CONCAT(T.datum,':',T.karta)  AS eventID, 
T.datum AS eventDate,
'HumanObservation' AS basisOfRecord,
'species' AS taxonRank,
'Animalia' AS kingdom,
T.lind AS individualCount,
E.englishname AS scientificName,
E.dyntaxa_id AS dyntaxa
FROM totalstandard T, koordinater_mittpunkt_topokartan K, eurolist E
WHERE  K.karta=T.karta
AND T.art=E.art
AND T.art<>'000' and T.art<>'999'
and T.art not in (select distinct art from IPT_SFT_HIDDENSPECIES H)
ORDER BY eventID, dyntaxa

/*
// hide the species to protect
TO BE added
AND spe_isconfidential = false
*/


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