local util = require 'sqlite.util'

local SCHEMA = [[
  create table if not exists user (
    user_id integer primary key,
    username text not null unique,
    hashed text not null,
    salt text not null,
    intro text default '',
    custom_css text default '',
    custom_title text default '',
    theme text default '',
    max_display_posts integer default 50,
    enable_toc integer default 1
  ) strict;

  create table if not exists post (
    post_id text primary key,
    user_id integer not null,
    title text default '',
    slug text default '',
    content text,
    content_size integer,
    created_time text not null default CURRENT_TIMESTAMP,
    modified_time text not null default CURRENT_TIMESTAMP,
    foreign key (user_id) references user(user_id)
  ) strict;
]]

local sql = util.openDatabase(SCHEMA, 'cms.sqlite')

return sql
