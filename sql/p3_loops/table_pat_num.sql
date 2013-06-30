drop table if exists pat_num;
CREATE TABLE pat_num(
  pid  int not null,
  nid   int not null, 
  num_0 int not null,
  num_1 int not null,
  foreign key(pid) REFERENCES patterns(pid)
) engine=InnoDB;
