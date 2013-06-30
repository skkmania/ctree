drop table if exists loops;
CREATE TABLE loops(
  id  int not null primary key,
  loop_str text not null
) engine=InnoDB;
