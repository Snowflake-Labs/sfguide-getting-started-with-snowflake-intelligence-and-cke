use role accountadmin;

create role if not exists snowflake_intelligence_admin;
grant create integration on account to role snowflake_intelligence_admin;
grant create database on account to role snowflake_intelligence_admin;
grant usage on warehouse compute_wh to role snowflake_intelligence_admin;

set current_user = (SELECT CURRENT_USER());   
grant role snowflake_intelligence_admin to user IDENTIFIER($current_user);
alter user set default_role = snowflake_intelligence_admin;

use role snowflake_intelligence_admin;

create database if not exists snowflake_intelligence;
create schema if not exists snowflake_intelligence.agents;

create database if not exists dash_si_cke;
create schema if not exists dash_si_cke.data;

use database dash_si_cke;
use schema data;

create or replace NOTIFICATION INTEGRATION email_integration
  TYPE=EMAIL
  ENABLED=TRUE
  DEFAULT_SUBJECT = 'Snowflake Intelligence';

create or replace PROCEDURE send_email(
    recipient_email VARCHAR,
    subject VARCHAR,
    body VARCHAR
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.12'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_email'
AS
$$
def send_email(session, recipient_email, subject, body):
    try:
        # Escape single quotes in the body
        escaped_body = body.replace("'", "''")
        
        # Execute the system procedure call
        session.sql(f"""
            CALL SYSTEM$SEND_EMAIL(
                'email_integration',
                '{recipient_email}',
                '{subject}',
                '{escaped_body}'
            )
        """).collect()
        
        return "Email sent successfully"
    except Exception as e:
        return f"Error sending email: {str(e)}"
$$;

select 'Congratulations! Snowflake Intelligence setup has completed successfully!' as status;

