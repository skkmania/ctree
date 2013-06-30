drop table if exists loop_pat;
CREATE TABLE loop_pat(
  id  int not null, 
  pid  int not null,
  foreign key(id) REFERENCES loops(id),
  foreign key(pid) REFERENCES patterns(pid)
) engine=InnoDB;
