drop table if exists pat_length;
CREATE TABLE pat_length(
  pid  int not null,
  lid   int not null, 
  length int not null,
  foreign key(pid) REFERENCES patterns(pid)
) engine=InnoDB;
