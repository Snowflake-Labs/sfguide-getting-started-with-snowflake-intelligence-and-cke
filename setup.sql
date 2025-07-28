use role accountadmin;

create role if not exists snowflake_intelligence_admin;
grant create integration on account to role snowflake_intelligence_admin;
grant create database on account to role snowflake_intelligence_admin;

set current_user = (SELECT CURRENT_USER());   
grant role snowflake_intelligence_admin to user IDENTIFIER($current_user);

use role snowflake_intelligence_admin;
create database if not exists snowflake_intelligence;
create schema if not exists snowflake_intelligence.agents;

grant ownership on database snowflake_intelligence to role snowflake_intelligence_admin;
grant ownership on schema snowflake_intelligence.agents to role snowflake_intelligence_admin;

alter user set default_role = snowflake_intelligence_admin;