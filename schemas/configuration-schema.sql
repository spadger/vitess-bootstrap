create table post_id_seq(id bigint, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into post_id_seq(id, next_id, cache) values(0, 1, 10);

create table channel_id_seq(id bigint, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into channel_id_seq(id, next_id, cache) values(0, 1, 10);

create table comment_id_seq(id bigint, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into comment_id_seq(id, next_id, cache) values(0, 1, 10);