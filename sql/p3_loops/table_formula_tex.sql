drop table if exists formula_texs;
CREATE TABLE formula_texs(
  pid  int not null primary key,
  formula_tex varchar(1000) not null,
  foreign key(pid) references patterns(pid)
) engine=InnoDB;
