-- ========================================
-- Snowflake Cortex demo setup script
-- ========================================
-- This script sets up the necessary roles, database, schemas, and integrations
-- For using snowflake intelligence and cortex knowledge engine (cke)
--
-- There's great flexibility in how you organise the various components. for
-- this demo we use a single database with a schema for each major piece.

-- ========================================
-- Role setup and permissions
-- ========================================
-- Switch to accountadmin role to create new roles and
-- grant high-level permissions
use role accountadmin;

-- Create a dedicated role for managing cortex resources
create role if not exists cortex_admin;

-- Grant necessary account-level privileges to the new role
grant create database on account to role cortex_admin;
-- Allows creating databases
grant usage on warehouse compute_wh to role cortex_admin;
-- Allows using the default compute warehouse
grant create integration on account to role cortex_admin;
-- Allows creating notification integrations

-- ========================================
-- User role assignment
-- ========================================
-- Capture the current user's name as a variable
set current_user = current_user();

-- Grant the new role to the current user
grant role cortex_admin to user identifier($current_user);

-- Switch to the new role for the remaining operations
use role cortex_admin;

-- ========================================
-- Database and schema setup
-- ========================================
-- Create a single database for the entire cortex demo
create database if not exists snowflake_intelligence;

-- Use the new database for all subsequent operations
use database snowflake_intelligence;

-- Create schema for ai agents
create schema if not exists agents;
-- This schema will contain all snowflake intelligence agents

-- Create schema for custom tools and procedures
create schema if not exists tools;
-- This schema will contain custom functions like email integration

-- create schema for application data (if needed in future)
create schema if not exists data;
-- This schema can store application-specific tables and views

-- ========================================
-- Agent permissions
-- ========================================
-- Grant permission to create agents in the agents schema
grant create agent on schema snowflake_intelligence.agents
to role cortex_admin;

alter account set cortex_enabled_cross_region = 'AWS_US';

-- ========================================
-- Email integration setup
-- ========================================
-- Switch to the tools schema for creating custom tools
use schema tools;

-- Create a notification integration for sending emails
-- This allows snowflake to send emails through its built-in email service
create or replace notification integration snowflake_intelligence_email_integration
  type=email
  enabled=true
  default_subject = 'snowflake cortex demo';

-- ========================================
-- Email sending procedure
-- ========================================
-- Create a stored procedure that wraps snowflake's email sending functionality
-- This makes it easier for agents and applications to send emails
create or replace procedure send_email(
    recipient_email varchar,    -- Email address of the recipient
    subject varchar,            -- Email subject line
    body varchar                -- Email body content
)
returns varchar
language python
runtime_version = '3.12'
packages = ('snowflake-snowpark-python')
handler = 'send_email'
as
$$
def send_email(session, recipient_email, subject, body):
    """
    send an email using snowflake's built-in email integration.

    args:
        session: snowpark session object
        recipient_email: email address to send to
        subject: email subject line
        body: email body content

    returns:
        success or error message
    """
    try:
        # escape single quotes in the body to prevent sql injection
        escaped_body = body.replace("'", "''")

        # execute the system procedure call to send the email
        session.sql(f"""
            call system$send_email(
                'snowflake_intelligence_email_integration', -- Name of the notification integration
                '{recipient_email}',             -- Recipient email address
                '{subject}',                     -- Email subject
                '{escaped_body}'                 -- Email body (escaped)
            )
        """).collect()

        return "email sent successfully"
    except exception as e:
        return f"error sending email: {str(e)}"
$$;

-- ========================================
-- Display current configuration
-- ========================================
select 'cortex demo setup complete!' as status,
       current_database() as database_name,
       current_schema() as current_schema,
       current_role() as active_role
union all
select 'available schemas:' as status,
       'agents' as database_name,
       'for ai agents' as current_schema,
       '' as active_role
union all
select '' as status,
       'tools' as database_name,
       'for custom procedures' as current_schema,
       '' as active_role
union all
select '' as status,
       'data' as database_name,
       'for application data' as current_schema,
       '' as active_role;
