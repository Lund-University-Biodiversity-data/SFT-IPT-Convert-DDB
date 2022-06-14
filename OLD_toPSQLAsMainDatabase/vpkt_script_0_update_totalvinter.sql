CREATE UNIQUE INDEX totalvinter_pkt_persnr_idx ON public.totalvinter_pkt (persnr,rnr,datum,art);

ALTER TABLE public.totalvinter_pkt ALTER COLUMN art TYPE varchar(3) USING art::varchar;
ALTER TABLE public.totalvinter_pkt ALTER COLUMN rnr TYPE varchar(2) USING rnr::varchar;
ALTER TABLE public.totalvinter_pkt ALTER COLUMN per TYPE varchar(1) USING per::varchar;

update totalvinter_pkt  set art=LPAD(art, 3, '0') ;
update totalvinter_pkt  set rnr=LPAD(rnr, 2, '0') ;

update totalvinter_pkt  set p03=replace(p03, ':', '') where art='000' and p03<>'' and p03 is not null;
update totalvinter_pkt  set p03=NULL where p03='';

update totalvinter_pkt  set p04=replace(p04, ':', '') where art='000' and p04<>'' and p04 is not null;
update totalvinter_pkt  set p04=NULL where p04='';

ALTER TABLE public.totalvinter_pkt ALTER COLUMN p03 TYPE int4 USING p03::int4;
ALTER TABLE public.totalvinter_pkt ALTER COLUMN p04 TYPE int4 USING p04::int4;

update totalvinter_pkt  set datum=left(replace(datum, '-', ''), 8) ;

ALTER TABLE public.totalvinter_pkt ALTER COLUMN datum TYPE varchar(8) USING datum::varchar;

