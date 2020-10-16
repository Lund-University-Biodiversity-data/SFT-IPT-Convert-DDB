ALTER TABLE eurolist ADD column taxon_rank VARCHAR(30);
ALTER TABLE eurolist ALTER column taxon_rank SET DEFAULT 'species';
UPDATE eurolist SET taxon_rank='species';

UPDATE eurolist SET taxon_rank='subspecies' WHERE dyntaxa_id='205978';
UPDATE eurolist SET taxon_rank='genus' WHERE dyntaxa_id='1001603';
UPDATE eurolist SET taxon_rank='subspecies' WHERE dyntaxa_id='205975';
UPDATE eurolist SET taxon_rank='subspecies' WHERE dyntaxa_id='205966';
UPDATE eurolist SET taxon_rank='genus' WHERE dyntaxa_id='1001508';
UPDATE eurolist SET taxon_rank='genus' WHERE dyntaxa_id='1001599';
UPDATE eurolist SET taxon_rank='genus' WHERE dyntaxa_id='1001450';
UPDATE eurolist SET taxon_rank='speciesAggregate' WHERE dyntaxa_id='266926';
UPDATE eurolist SET taxon_rank='speciesAggregate' WHERE dyntaxa_id='266774';
UPDATE eurolist SET taxon_rank='speciesAggregate' WHERE dyntaxa_id='266775';
UPDATE eurolist SET taxon_rank='speciesAggregate' WHERE dyntaxa_id='1001431';
UPDATE eurolist SET taxon_rank='subspecies' WHERE dyntaxa_id='205952';
UPDATE eurolist SET taxon_rank='speciesAggregate' WHERE dyntaxa_id='266842';
UPDATE eurolist SET taxon_rank='subspecies' WHERE dyntaxa_id='246283';
