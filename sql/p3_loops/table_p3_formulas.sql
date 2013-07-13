drop table if exists p3_formulas;
CREATE TABLE p3_formulas(
  pid  int not null primary key,
  p3_formula varchar(500) not null,
  num  int not null,
  denom  int not null,
  foreign key(pid) references patterns(pid)
) engine=InnoDB;
