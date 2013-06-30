drop table if exists loop_q;
CREATE TABLE loop_q(
  id  int not null,
  qid int not null,
  q   int not null,
  foreign key(id) references loops(id)
) engine=InnoDB;
