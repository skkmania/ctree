drop table if exists loops;
CREATE TABLE loops(
  id  int not null primary key,
  loop_str text not null
) engine=InnoDB;

drop table if exists patterns;
CREATE TABLE patterns(
  pid  int not null primary key,
  pattern varchar(10000) not null,
  expression varchar(30000) not null,
  qformula varchar(1000) not null
) engine=InnoDB;
create index pattern_idx on patterns(pattern);

drop table if exists pat_length;
CREATE TABLE pat_length(
  pid  int not null,
  lid   int not null, 
  length int not null,
  foreign key(pid) REFERENCES patterns(pid)
) engine=InnoDB;

drop table if exists pat_num;
CREATE TABLE pat_num(
  pid  int not null,
  nid   int not null, 
  num_0 int not null,
  num_1 int not null,
  foreign key(pid) REFERENCES patterns(pid)
) engine=InnoDB;

drop table if exists loop_pat;
CREATE TABLE loop_pat(
  id  int not null, 
  pid  int not null,
  foreign key(id) REFERENCES loops(id),
  foreign key(pid) REFERENCES patterns(pid)
) engine=InnoDB;

drop table if exists loop_q;
CREATE TABLE loop_q(
  id  int not null,
  qid int not null,
  q   int not null,
  foreign key(id) references loops(id)
) engine=InnoDB;
