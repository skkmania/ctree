drop table if exists patterns;
CREATE TABLE patterns(
  pid  int not null primary key,
  pattern varchar(10000) not,
  expression varchar(30000) not null,
  qformula varchar(1000) not null
) engine=InnoDB;
create index pattern_idx on patterns(pattern);
