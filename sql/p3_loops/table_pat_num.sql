drop table if exists pat_num;
CREATE TABLE pat_num AS
  (SELECT pid,
          length(pattern) as len,
          length(replace(pattern,'1','')) as num_0,
          length(replace(pattern,'0','')) as num_1
     FROM patterns);
ALTER TABLE pat_num ADD FOREIGN KEY(pid) REFERENCES patterns(pid);
