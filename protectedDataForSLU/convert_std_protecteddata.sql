\i lib/config.sql

/*\c :database_name*/
\set database_name sft_std_from_mongo


/* TO BE CHANGED TO Y-1 TO USE year_max<= instead of < */
\set year_max 2023

DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY;

/*DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_STARTENDTIME;*/
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_SAMPLING;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_OCCURRENCE;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_EMOF;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_EVENTSNOOBS;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_DETAILSART;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_POINTSLINES_SURVEYED;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_DISTANCE_COVERED;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_COUNT_POINTLINES;
DROP TABLE IF EXISTS IPT_SFTstd_protected.IPT_SFTstd_protected_NULL_POINTLINES;

DROP SCHEMA IF EXISTS IPT_SFTstd_protected;
CREATE SCHEMA IPT_SFTstd_protected;


CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (
	code varchar(2) NOT NULL,
	name varchar(255) NOT NULL,
	PRIMARY KEY (code)
); 

INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('AB', 'Stockholms län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('AC', 'Västerbottens län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('BD', 'Norrbottens län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('C', 'Uppsala län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('D', 'Södermanlands län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('E', 'Östergötlands län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('F', 'Jönköpings län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('G', 'Kronobergs län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('H', 'Kalmar län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('I', 'Gotlands län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('K', 'Blekinge län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('M', 'Skåne län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('N', 'Hallands län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('O', 'Västra Götalands län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('S', 'Värmlands län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('T', 'Örebro län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('U', 'Västmanlands län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('W', 'Dalarnas län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('X', 'Gävleborgs län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('Y', 'Västernorrlands län');
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY (code, name) VALUES ('Z', 'Jämtlands län');


CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_DETAILSART AS
SELECT art, suppliedname, SPLIT_PART(suppliedname, ' ', 1) as genus, SPLIT_PART(suppliedname, ' ', 2) as specificEpithet, SPLIT_PART(suppliedname, ' ', 3) as infraSpecificEpithet 
FROM lists_module_biodiv;
/* Manual fix of the art that ends with "L" or "Li" or "T" */
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_DETAILSART
SET infraSpecificEpithet=''
WHERE LENGTH(infraSpecificEpithet)>0 AND LENGTH(infraSpecificEpithet)<3;

/* only the lines with 2 rows : 000 and 999 => event with no obs at all */
CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_EVENTSNOOBS AS
select datum, karta, persnr
from (
	select datum, karta, persnr, COUNT(*) as tot from mongo_totalstandard 
	WHERE yr< :year_max
	group by datum, karta, persnr
) as eventnoobs
where tot=2;

/* point eller line with no obs */
/* first we count the records per point/line */
CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_NULL_POINTLINES AS
SELECT karta, datum, 'P1' AS pointline, SUM(p1) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'P2' AS pointline, SUM(p2) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'P3' AS pointline, SUM(p3) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'P4' AS pointline, SUM(p4) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'P5' AS pointline, SUM(p5) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'P6' AS pointline, SUM(p6) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'P7' AS pointline, SUM(p7) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'P8' AS pointline, SUM(p8) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'L1' AS pointline, SUM(l1) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'L2' AS pointline, SUM(l2) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'L3' AS pointline, SUM(l3) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'L4' AS pointline, SUM(l4) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'L5' AS pointline, SUM(l5) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'L6' AS pointline, SUM(l6) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'L7' AS pointline, SUM(l7) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum 
UNION SELECT karta, datum, 'L8' AS pointline, SUM(l8) as totalIndiv FROM mongo_totalstandard where art<>'000' and art<>'999' GROUP BY karta, datum;
/* then we keep only the total = 0 */
/* DELETE FROM IPT_SFTstd_protected.IPT_SFTstd_protected_NULL_POINTLINES WHERE totalIndiv<>0; */


/* create a view without the timOfObservation=0 (not filled in) */
/* to avoid them in the LEAST function */
CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES AS
SELECT karta, datum, p1, p2, p3, p4, p5, p6, p7, p8
FROM mongo_totalstandard
where art='000';

UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES 
SET p1=NULL WHERE p1=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES 
SET p2=NULL WHERE p2=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES 
SET p3=NULL WHERE p3=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES 
SET p4=NULL WHERE p4=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES 
SET p5=NULL WHERE p5=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES 
SET p6=NULL WHERE p6=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES 
SET p7=NULL WHERE p7=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_TIMES 
SET p8=NULL WHERE p8=0;



/* START TIME FROM LISTTIME */
CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME AS
SELECT karta, datum, p1, p2, p3, p4, p5, p6, p7, p8
FROM mongo_totalstandard
where art='000'; 

UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
SET p1=null WHERE p1 ='999';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
SET p2=null WHERE p2 ='999';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
SET p3=null WHERE p3 ='999';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
SET p4=null WHERE p4 ='999';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
SET p5=null WHERE p5 ='999';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
SET p6=null WHERE p6 ='999';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
SET p7=null WHERE p7 ='999';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
SET p8=null WHERE p8 ='999';

/* exclude time = 0, to avoid empty/null, and never in the datbase any 00:00 as real time... */
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME SET p1=NULL WHERE p1=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME SET p2=NULL WHERE p2=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME SET p3=NULL WHERE p3=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME SET p4=NULL WHERE p4=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME SET p5=NULL WHERE p5=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME SET p6=NULL WHERE p6=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME SET p7=NULL WHERE p7=0;
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME SET p8=NULL WHERE p8=0;


/* create one row for each point/line surveyed */
CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_POINTSLINES_SURVEYED AS
SELECT karta, datum, 'P1' AS pointline, p1 as surveytime FROM mongo_totalstandard where art='000' AND p1 IS NOT NULL AND p1<>0
UNION SELECT karta, datum, 'P2' AS pointline, p2 as surveytime FROM mongo_totalstandard where art='000' AND p2 IS NOT NULL AND p2<>0 
UNION SELECT karta, datum, 'P3' AS pointline, p3 as surveytime FROM mongo_totalstandard where art='000' AND p3 IS NOT NULL AND p3<>0
UNION SELECT karta, datum, 'P4' AS pointline, p4 as surveytime FROM mongo_totalstandard where art='000' AND p4 IS NOT NULL AND p4<>0
UNION SELECT karta, datum, 'P5' AS pointline, p5 as surveytime FROM mongo_totalstandard where art='000' AND p5 IS NOT NULL AND p5<>0
UNION SELECT karta, datum, 'P6' AS pointline, p6 as surveytime FROM mongo_totalstandard where art='000' AND p6 IS NOT NULL AND p6<>0
UNION SELECT karta, datum, 'P7' AS pointline, p7 as surveytime FROM mongo_totalstandard where art='000' AND p7 IS NOT NULL AND p7<>0
UNION SELECT karta, datum, 'P8' AS pointline, p8 as surveytime FROM mongo_totalstandard where art='000' AND p8 IS NOT NULL AND p8<>0
UNION SELECT karta, datum, 'L1' AS pointline, l1 as surveytime FROM mongo_totalstandard where art='000' AND L1 IS NOT NULL AND l1<>0
UNION SELECT karta, datum, 'L2' AS pointline, l2 as surveytime FROM mongo_totalstandard where art='000' AND L2 IS NOT NULL AND l2<>0
UNION SELECT karta, datum, 'L3' AS pointline, l3 as surveytime FROM mongo_totalstandard where art='000' AND L3 IS NOT NULL AND l3<>0
UNION SELECT karta, datum, 'L4' AS pointline, l4 as surveytime FROM mongo_totalstandard where art='000' AND l4 IS NOT NULL AND l4<>0
UNION SELECT karta, datum, 'L5' AS pointline, l5 as surveytime FROM mongo_totalstandard where art='000' AND l5 IS NOT NULL AND l5<>0
UNION SELECT karta, datum, 'L6' AS pointline, l6 as surveytime FROM mongo_totalstandard where art='000' AND l6 IS NOT NULL AND l6<>0
UNION SELECT karta, datum, 'L7' AS pointline, l7 as surveytime FROM mongo_totalstandard where art='000' AND l7 IS NOT NULL AND l7<>0
UNION SELECT karta, datum, 'L8' AS pointline, l8 as surveytime FROM mongo_totalstandard where art='000' AND l8 IS NOT NULL AND l8<>0
ORDER BY karta, datum;

UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_POINTSLINES_SURVEYED
SET surveytime=null WHERE surveytime =999;

/* create one row for each point/line for the distance covered */
CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_DISTANCE_COVERED AS
SELECT karta, datum, 'P1' AS pointline, p1 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'P2' AS pointline, p2 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'P3' AS pointline, p3 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'P4' AS pointline, p4 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'P5' AS pointline, p5 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'P6' AS pointline, p6 as distance FROM mongo_totalstandard where art='999' 
UNION SELECT karta, datum, 'P7' AS pointline, p7 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'P8' AS pointline, p8 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'L1' AS pointline, l1 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'L2' AS pointline, l2 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'L3' AS pointline, l3 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'L4' AS pointline, l4 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'L5' AS pointline, l5 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'L6' AS pointline, l6 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'L7' AS pointline, l7 as distance FROM mongo_totalstandard where art='999'
UNION SELECT karta, datum, 'L8' AS pointline, l8 as distance FROM mongo_totalstandard where art='999'
ORDER BY karta, datum;

/* create one row for each point/line for the count */
CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_COUNT_POINTLINES AS
SELECT karta, datum, art, 'P1' AS pointline, p1 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and p1>0
UNION SELECT karta, datum, art, 'P2' AS pointline, p2 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and p2>0
UNION SELECT karta, datum, art, 'P3' AS pointline, p3 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and p3>0
UNION SELECT karta, datum, art, 'P4' AS pointline, p4 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and p4>0
UNION SELECT karta, datum, art, 'P5' AS pointline, p5 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and p5>0
UNION SELECT karta, datum, art, 'P6' AS pointline, p6 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and p6>0
UNION SELECT karta, datum, art, 'P7' AS pointline, p7 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and p7>0
UNION SELECT karta, datum, art, 'P8' AS pointline, p8 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and p8>0
UNION SELECT karta, datum, art, 'L1' AS pointline, l1 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and l1>0
UNION SELECT karta, datum, art, 'L2' AS pointline, l2 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and l2>0
UNION SELECT karta, datum, art, 'L3' AS pointline, l3 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and l3>0
UNION SELECT karta, datum, art, 'L4' AS pointline, l4 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and l4>0
UNION SELECT karta, datum, art, 'L5' AS pointline, l5 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and l5>0
UNION SELECT karta, datum, art, 'L6' AS pointline, l6 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and l6>0
UNION SELECT karta, datum, art, 'L7' AS pointline, l7 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and l7>0
UNION SELECT karta, datum, art, 'L8' AS pointline, l8 as count FROM mongo_totalstandard where art <>'000' AND art<>'999' and l8>0
ORDER BY karta, datum;


/* create one row for each point/line with coordinates  */
CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES AS
SELECT karta, CONCAT('P', punkt) AS pointline, CAST(lat AS text) as k1, CAST(lng AS text) as k2, staregppid FROM sftstd_punktkoordinater;

/* for the lines, create footprint coordinates with 2 points */
INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES (karta, pointline, k1, k2, staregppid)
SELECT C1.karta, 'L1' as pointline, CONCAT(C1.k1, ' ', C1.k2) AS k1, CONCAT(C2.k1, ' ', C2.k2) AS k2, '' AS staregppid
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C1, IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C2
WHERE C1.karta=C2.karta and C1.pointline='P1' and C2.pointline='P2';

INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES (karta, pointline, k1, k2, staregppid)
SELECT C1.karta, 'L2' as pointline, CONCAT(C1.k1, ' ', C1.k2) AS k1, CONCAT(C2.k1, ' ', C2.k2) AS k2, '' AS staregppid
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C1, IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C2
WHERE C1.karta=C2.karta and C1.pointline='P2' and C2.pointline='P3';

INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES (karta, pointline, k1, k2, staregppid)
SELECT C1.karta, 'L3' as pointline, CONCAT(C1.k1, ' ', C1.k2) AS k1, CONCAT(C2.k1, ' ', C2.k2) AS k2, '' AS staregppid
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C1, IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C2
WHERE C1.karta=C2.karta and C1.pointline='P3' and C2.pointline='P4';

INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES (karta, pointline, k1, k2, staregppid)
SELECT C1.karta, 'L4' as pointline, CONCAT(C1.k1, ' ', C1.k2) AS k1, CONCAT(C2.k1, ' ', C2.k2) AS k2, '' AS staregppid
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C1, IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C2
WHERE C1.karta=C2.karta and C1.pointline='P4' and C2.pointline='P5';

INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES (karta, pointline, k1, k2, staregppid)
SELECT C1.karta, 'L5' as pointline, CONCAT(C1.k1, ' ', C1.k2) AS k1, CONCAT(C2.k1, ' ', C2.k2) AS k2, '' AS staregppid
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C1, IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C2
WHERE C1.karta=C2.karta and C1.pointline='P5' and C2.pointline='P6';

INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES (karta, pointline, k1, k2, staregppid)
SELECT C1.karta, 'L6' as pointline, CONCAT(C1.k1, ' ', C1.k2) AS k1, CONCAT(C2.k1, ' ', C2.k2) AS k2, '' AS staregppid
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C1, IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C2
WHERE C1.karta=C2.karta and C1.pointline='P6' and C2.pointline='P7';

INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES (karta, pointline, k1, k2, staregppid)
SELECT C1.karta, 'L7' as pointline, CONCAT(C1.k1, ' ', C1.k2) AS k1, CONCAT(C2.k1, ' ', C2.k2) AS k2, '' AS staregppid
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C1, IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C2
WHERE C1.karta=C2.karta and C1.pointline='P7' and C2.pointline='P8';

INSERT INTO IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES (karta, pointline, k1, k2, staregppid)
SELECT C1.karta, 'L8' as pointline, CONCAT(C1.k1, ' ', C1.k2) AS k1, CONCAT(C2.k1, ' ', C2.k2) AS k2, '' AS staregppid
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C1, IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES C2
WHERE C1.karta=C2.karta and C1.pointline='P8' and C2.pointline='P1';

/* TEMPORARY AS LONG AS WE DON't HAVE THE RIGHT staregppid */
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES as coordL
SET staregppid=coordP.staregppid
from IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES coordP
where coordL.karta=coordP.karta
and coordL.pointline='L1' and coordP.pointline='P1';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES as coordL
SET staregppid=coordP.staregppid
from IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES coordP
where coordL.karta=coordP.karta
and coordL.pointline='L2' and coordP.pointline='P2';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES as coordL
SET staregppid=coordP.staregppid
from IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES coordP
where coordL.karta=coordP.karta
and coordL.pointline='L3' and coordP.pointline='P3';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES as coordL
SET staregppid=coordP.staregppid
from IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES coordP
where coordL.karta=coordP.karta
and coordL.pointline='L4' and coordP.pointline='P4';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES as coordL
SET staregppid=coordP.staregppid
from IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES coordP
where coordL.karta=coordP.karta
and coordL.pointline='L5' and coordP.pointline='P5';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES as coordL
SET staregppid=coordP.staregppid
from IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES coordP
where coordL.karta=coordP.karta
and coordL.pointline='L6' and coordP.pointline='P6';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES as coordL
SET staregppid=coordP.staregppid
from IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES coordP
where coordL.karta=coordP.karta
and coordL.pointline='L7' and coordP.pointline='P7';
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES as coordL
SET staregppid=coordP.staregppid
from IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES coordP
where coordL.karta=coordP.karta
and coordL.pointline='L8' and coordP.pointline='P8';


/* get the min time as startTime and max time as endTime */
/*
CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_STARTENDTIME AS
SELECT ST.karta, ST.datum, CAST(to_char(startTime::time,'HH24:MI') AS text) AS startTime, CAST(to_char(endTime::time,'HH24:MI') AS text) AS endTime, '' AS timeInterval
from (
	SELECT karta, datum, LPAD(cast(LEAST(p1, p2, p3, p4, p5, p6, p7, p8) as text), 4, '0') as startTime
	FROM IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
) ST, (
	SELECT karta, datum, LPAD(cast(GREATEST(p1, p2, p3, p4, p5, p6, p7, p8) as text), 4, '0') as endTime
	FROM IPT_SFTstd_protected.IPT_SFTstd_protected_LISTTIME
) ET
where ST.karta=ET.karta
and ST.datum=ET.datum;
*/

/* create the time interval field */
/*
UPDATE IPT_SFTstd_protected.IPT_SFTstd_protected_STARTENDTIME
SET timeInterval =
CASE 
	WHEN startTime is null AND startTime is null THEN ''
	ELSE CONCAT(startTime,'/',endTime) 
END
;
*/

CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_SAMPLING AS
/* SFTstd - rutt */
SELECT 
distinct CONCAT('SFTstd:', T.datum, ':', I.anonymizedId) as eventID,
'besök' AS eventType,
'' AS parentEventId,
CONCAT(CAST(TO_DATE(t.datum,'YYYYMMDD') as text), '/', CAST(TO_DATE(t.datum,'YYYYMMDD') as text)) AS eventDate,
CASE 
	WHEN T.BCSurveyStartTime='00:00' THEN ''
	ELSE CONCAT(T.BCSurveyStartTime, '/',T.BCSurveyFinishTime) 
END AS eventTime, 
CONCAT('SFT:recorderId:', P.anonymizedId) AS personAnonymizedId, /* used for emof only ! */
I.staregosid AS locationId,
CONCAT('SFTstd:siteId:', cast(I.anonymizedId AS text)) AS verbatimLocality,
CAST(null as numeric) as sampleSizeValue,
null as sampleSizeUnit,
'EPSG:4326' AS geodeticDatum,
ROUND(cast(K.mitt_wgs84_lat as numeric), 5) AS decimalLatitude, 
ROUND(cast(K.mitt_wgs84_lon as numeric), 5) AS decimalLongitude, 
'' as footprintWKT,
'' as footprintSRS,
C.name AS county,
'' AS municipality,
'Koordinaterna anger ruttens mittpunkt.' AS locationRemarks,
null AS samplingProtocol,
null AS samplingEffort,
CAST(null as numeric) AS coordinateUncertaintyInMeters
FROM standardrutter_koordinater K, mongo_sites I, IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY C, mongo_totalstandard T
LEFT JOIN mongo_persons P ON P.persnr=T.persnr 
WHERE T.karta=I.internalSiteId
AND I.internalsiteid=K.karta
AND C.code=I.lan
AND T.art='000'
AND T.yr<:year_max
AND ((T.yr=2015 AND T.karta = '03E2H') OR (T.yr=2015 AND T.karta = '04G2H') OR (T.yr=2000 AND T.karta = '05C2H') OR (T.yr=2005 AND T.karta = '06F7C') OR (T.yr=2022 AND T.karta = '16C2C') OR (T.yr=1999 AND T.karta = '22G7C'))

UNION

/* SFTstd - punkt/linje */
SELECT 
distinct CONCAT('SFTstd:', T.datum, ':', I.anonymizedId, ':', PL.pointline) as eventID,
'delbesök' AS eventType,
CONCAT('SFTstd:', T.datum, ':', I.anonymizedId) AS parentEventId,
null AS eventDate,
CASE
	WHEN LEFT(PL.pointline, 1) = 'P' and PL.surveytime is null
	THEN null
	WHEN LEFT(PL.pointline, 1) = 'P'
	THEN CONCAT(to_char(LPAD(cast(PL.surveytime as text), 4, '0')::time,'HH24:MI'),'/', CAST(to_char(LPAD(cast(PL.surveytime as text), 4, '0')::time + interval '5 minutes','HH24:MI') AS text)) 
	ELSE null
END AS eventTime, 
CONCAT('SFT:recorderId:', P.anonymizedId) AS personAnonymizedId, /* used for emof only ! */
PK.staregppid AS locationId,
CONCAT('SFTstd:siteId:', cast(I.anonymizedId AS text), ':', PL.pointline) AS verbatimLocality,
CASE
	WHEN LEFT(DC.pointline, 1) = 'L' and DC.distance is not null and DC.distance<>99
	THEN DC.distance*100
	ELSE null
END AS sampleSizeValue,
CASE
	WHEN LEFT(DC.pointline, 1) = 'L' and DC.distance is not null and DC.distance<>99
	THEN 'meter'
	ELSE null
END as sampleSizeUnit,
CASE
	WHEN LEFT(DC.pointline, 1) = 'P' 
	THEN 'EPSG:4326'
	ELSE null
END AS geodeticDatum,
CASE
	WHEN LEFT(DC.pointline, 1) = 'P' 
	THEN ROUND(cast(PK.k1 as numeric), 5)
	ELSE null
END AS decimalLatitude, 
CASE
	WHEN LEFT(DC.pointline, 1) = 'P' 
	THEN ROUND(cast(PK.k2 as numeric), 5)
	ELSE null
END AS decimalLongitude, 
CASE
	WHEN LEFT(DC.pointline, 1) = 'L' 
	THEN CONCAT('LINESTRING ((', PK.k1, ', ', PK.k2, '))')
	ELSE null
END  as footprintWKT,
CASE
	WHEN LEFT(DC.pointline, 1) = 'L' 
	THEN 'EPSG:4326'
	ELSE null
END AS footprintSRS,
'' AS county,
'' AS municipality,
CASE
	WHEN LEFT(DC.pointline, 1) = 'L' THEN 'Koordinaterna anger linjens start- och slutpunkt.'
	WHEN LEFT(DC.pointline, 1) = 'P' THEN 'Koordinaterna anger punktens mitt.'
	ELSE null
END AS locationRemarks,
CASE
	WHEN LEFT(DC.pointline, 1) = 'L' THEN 'linjetaxering'
	WHEN LEFT(DC.pointline, 1) = 'P' THEN 'punkttaxering'
	ELSE null
END AS samplingProtocol,
CASE
	WHEN LEFT(DC.pointline, 1) = 'L' and PL.surveytime<>0 and PL.surveytime<>99 THEN CONCAT(CAST(PL.surveytime as text), ' minuter')
	WHEN LEFT(DC.pointline, 1) = 'P' THEN '5 minuter'
	ELSE null
END AS samplingEffort,
2000 AS coordinateUncertaintyInMeters
FROM mongo_sites I, 
IPT_SFTstd_protected.IPT_SFTstd_protected_POINTSLINES_SURVEYED PL
left join IPT_SFTstd_protected.IPT_SFTstd_protected_COORDINATES PK ON PK.karta=PL.karta AND PK.pointline=PL.pointline,
IPT_SFTstd_protected.IPT_SFTstd_protected_DISTANCE_COVERED DC, mongo_totalstandard T
LEFT JOIN mongo_persons P ON P.persnr=T.persnr 
WHERE T.karta=I.internalSiteId
AND PL.karta=T.karta AND T.datum=PL.datum
AND DC.karta=T.karta AND T.datum=DC.datum
AND DC.pointline=PL.pointline
AND T.art='000'
AND T.yr<:year_max
AND ((T.yr=2015 AND T.karta = '03E2H') OR (T.yr=2015 AND T.karta = '04G2H') OR (T.yr=2000 AND T.karta = '05C2H') OR (T.yr=2005 AND T.karta = '06F7C') OR (T.yr=2022 AND T.karta = '16C2C') OR (T.yr=1999 AND T.karta = '22G7C'))

order by eventID;


/* save


CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS startDayOfYear,
CAST(EXTRACT (doy from  TO_DATE(t.datum,'YYYYMMDD')) AS INTEGER) AS endDayOfYear,
CONCAT('SFTstd:siteId:', cast(anonymizedId AS text)) AS internalSiteId,
'Sweden' AS country,
'SE' AS countryCode,
'EUROPE' AS continent,
'English' as language,
'Limited' as accessRights,
'Lund University' AS institutionCode,
'Swedish Environmental Protection Agency' AS ownerInstitutionCode,
'Species with a security class 4 or higher (according to the Swedish species information centre (Artdatabanken)) are not shown in this dataset at present. Currently these species are: Lesser white-fronted goose (fjällgås; Anser erythropus), Golden eagle (kungsörn; Aquila chrysaetos), White-tailed eagle (havsörn; Haliaeetus albicilla), Pallid harrier (stäpphök; Circus macrourus),  Montagu’s harrier (ängshök; Circus pygargus), Peregrine falcon (pilgrimsfalk; Falco peregrinus), Gyrfalcon (jaktfalk; Falco rusticolus), Eagle owl (berguv; Bubo bubo), Snowy owl (fjälluggla; Bubo scandiacus), White-backed woodpecker (vitryggig hackspett; Dendrocopos leucotos), Eurasian lynx (lo; Lynx lynx), Brown bear (brunbjörn; Ursus arctos), Wolverine (järv; Gulo gulo) and Arctic fox (fjällräv; Vulpes lagopus).' AS informationWithheld,
'false' AS nullvisit


for null visist avec une union : 
'true' AS nullvisit
FROM standardrutter_koordinater K, mongo_sites I, IPT_SFTstd_protected.IPT_SFTstd_protected_CONVERT_COUNTY C, IPT_SFTstd_protected.IPT_SFTstd_protected_EVENTSNOOBS T
left join IPT_SFTstd_protected.IPT_SFTstd_protected_STARTENDTIME ST on T.datum=ST.datum AND T.datum=ST.datum AND T.karta=ST.karta
WHERE T.karta=I.internalSiteId
AND I.internalsiteid=K.karta
AND C.code=I.lan
*/



CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_OCCURRENCE AS
SELECT
CONCAT('SFTstd:', T.datum, ':', I.anonymizedId, ':', PL.pointline) as eventID,
CONCAT('SFTstd:', T.datum, ':', I.anonymizedId, ':', E.dyntaxa_id, ':', PL.pointline) as occurrenceID,
'mänsklig observation' AS basisOfRecord,
CONCAT('urn:lsid:dyntaxa.se:Taxon:', E.dyntaxa_id) AS taxonID,
E.arthela AS vernacularName,
E.suppliedname AS scientificName,
/*CASE 
	WHEN T.art IN ('245', '301', '302', '319') THEN 'genus' 
	WHEN T.art IN ('237', '260', '261', '508', '509', '526', '536', '566', '608', '609', '626', '636', '666', '731') THEN 'subspecies' 
	WHEN T.art IN ('418') THEN 'speciesAggregate' 
	ELSE 'species' 
END AS taxonRank,*/
E.taxon_rank as taxonRank,
CASE 
	WHEN PC.count>0
	THEN 'observerad'
	ELSE 'inte observerad'
END AS occurrenceStatus,
PC.count AS individualCount,
PC.count AS organismQuantity,
'individer' AS organismQuantityType
FROM mongo_sites I, lists_module_biodiv E, IPT_SFTstd_protected.IPT_SFTstd_protected_DETAILSART DA, 
IPT_SFTstd_protected.IPT_SFTstd_protected_POINTSLINES_SURVEYED PL,
IPT_SFTstd_protected.IPT_SFTstd_protected_COUNT_POINTLINES PC,
mongo_totalstandard T
WHERE  I.internalSiteId=T.karta
AND PL.pointline=PC.pointline
AND DA.art=E.art
AND PL.karta=T.karta AND T.datum=PL.datum
AND PC.karta=T.karta AND T.datum=PC.datum AND PC.art=T.art
AND T.art=E.art
AND T.art<>'000' and T.art<>'999'
AND PC.count>0
AND T.yr<:year_max
AND ((T.yr=2015 AND T.karta = '03E2H') OR (T.yr=2015 AND T.karta = '04G2H') OR (T.yr=2000 AND T.karta = '05C2H') OR (T.yr=2005 AND T.karta = '06F7C') OR (T.yr=2022 AND T.karta = '16C2C') OR (T.yr=1999 AND T.karta = '22G7C'))
/*

'Animalia' AS kingdom,
DA.genus AS genus,
DA.specificepithet AS specificEpithet,
DA.infraspecificepithet AS infraSpecificEpithet,
CASE 
	WHEN T.art IN ('245', '301', '302', '319') THEN 'genus' 
	WHEN T.art IN ('237', '260', '261', '508', '509', '526', '536', '566', '608', '609', '626', '636', '666', '731') THEN 'subspecies' 
	WHEN T.art IN ('418') THEN 'speciesAggregate' 
	ELSE 'species' 
END AS taxonRank,
'SFTstd' AS collectionCode,
'The number of individuals observed is the sum total from all the surveyed lines on the route.' AS occurrenceRemarks

*/
 
/*
UNION

SELECT 
CONCAT('SFTstd:', T.datum, ':', I.anonymizedId) as eventID,
CONCAT('SFTstd:', T.datum, ':', I.anonymizedId, ':5000001', ':L') as occurrenceID,
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
FROM mongo_sites I, IPT_SFTstd_protected.IPT_SFTstd_protected_EVENTSNOOBS T
WHERE  I.internalSiteId=T.karta
*/
ORDER BY eventID, taxonID;




CREATE TABLE IPT_SFTstd_protected.IPT_SFTstd_protected_EMOF AS
SELECT
DISTINCT eventID,
null as occurrenceID,
'locationProtected' AS measurementType,
'ja' AS measurementValue
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_SAMPLING
UNION 
SELECT
DISTINCT eventID,
null as occurrenceID,
'locationType' AS measurementType,
CASE 
	WHEN samplingProtocol = 'linjetaxering' THEN 'linje'
	WHEN samplingProtocol = 'punkttaxering' THEN 'punkt'
	ELSE 'rutt'
END AS measurementValue
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_SAMPLING

UNION
SELECT
DISTINCT eventID,
null as occurrenceID,
'recordedBy' AS measurementType,
personAnonymizedId AS measurementValue
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_SAMPLING
where eventType='besök'

UNION 
SELECT
DISTINCT eventID,
null as occurrenceID,
'dimension' AS measurementType,
'2' AS measurementValue
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_SAMPLING

UNION 
/* point/line with no observation */
SELECT
CONCAT('SFTstd:', NO.datum, ':', I.anonymizedId, ':', PL.pointline) as eventID,
null as occurrenceID,
'noObservations' AS measurementType,
CASE
	WHEN totalIndiv=0 THEN 'sant'
	ELSE 'falskt'
END AS measurementValue
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_POINTSLINES_SURVEYED PL, 
IPT_SFTstd_protected.IPT_SFTstd_protected_NULL_POINTLINES NO,mongo_sites I
WHERE PL.karta=I.internalSiteId
AND PL.karta=NO.karta
AND PL.datum=NO.datum
AND PL.pointline=NO.pointline
/* TO BE REMOVED */
AND (CONCAT('SFTstd:', NO.datum, ':', I.anonymizedId, ':', PL.pointline) LIKE 'SFTstd:19990629:484:%'
	OR CONCAT('SFTstd:', NO.datum, ':', I.anonymizedId, ':', PL.pointline) LIKE 'SFTstd:20000608:44:%'
	OR CONCAT('SFTstd:', NO.datum, ':', I.anonymizedId, ':', PL.pointline) LIKE 'SFTstd:20050609:81:%'
	OR CONCAT('SFTstd:', NO.datum, ':', I.anonymizedId, ':', PL.pointline) LIKE 'SFTstd:20150601:16:%'
	OR CONCAT('SFTstd:', NO.datum, ':', I.anonymizedId, ':', PL.pointline) LIKE 'SFTstd:20150608:40:%'
	OR CONCAT('SFTstd:', NO.datum, ':', I.anonymizedId, ':', PL.pointline) LIKE 'SFTstd:20220614:320:%'
)


UNION
SELECT
eventID,
occurrenceID,
'euTaxonID' AS measurementType,
E.eu_sp_code AS measurementValue
FROM IPT_SFTstd_protected.IPT_SFTstd_protected_OCCURRENCE O, lists_module_biodiv E 
WHERE E.suppliedname=O.scientificName
AND E.eu_sp_code is not null and E.eu_sp_code<>''

;


